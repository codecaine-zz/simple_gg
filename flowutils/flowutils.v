module flowutils

import math
import time

// ============================================================================
// 1. Rate Limiter (Token Bucket Algorithm)
// ============================================================================

// RateLimiter enforces request rate limits using the Token Bucket algorithm.
pub struct RateLimiter {
mut:
	capacity            f64
	tokens              f64
	refill_rate_per_sec f64
	last_refill         time.Time
}

// new_rate_limiter initializes a Token Bucket rate limiter with a bucket capacity and refill rate per second.
pub fn new_rate_limiter(capacity int, refill_rate_per_sec f64) !RateLimiter {
	if capacity <= 0 {
		return error('Rate limiter capacity must be greater than 0, got ${capacity}')
	}
	if refill_rate_per_sec <= 0.0 {
		return error('Refill rate must be greater than 0.0, got ${refill_rate_per_sec}')
	}

	return RateLimiter{
		capacity:            f64(capacity)
		tokens:              f64(capacity)
		refill_rate_per_sec: refill_rate_per_sec
		last_refill:         time.now()
	}
}

// allow attempts to consume 1 token. Returns true if allowed, false if limit exceeded.
pub fn (mut rl RateLimiter) allow() bool {
	return rl.allow_n(1)
}

// allow_n attempts to consume n tokens from the bucket.
pub fn (mut rl RateLimiter) allow_n(tokens int) bool {
	if tokens <= 0 {
		return true
	}
	rl.refill()
	if rl.tokens >= f64(tokens) {
		rl.tokens -= f64(tokens)
		return true
	}
	return false
}

// wait blocks the current thread until 1 token is available.
pub fn (mut rl RateLimiter) wait() ! {
	for !rl.allow() {
		sleep_ms := int(math.max(10.0, 1000.0 / rl.refill_rate_per_sec))
		time.sleep(time.millisecond * sleep_ms)
	}
}

// reset restores the bucket to maximum capacity.
pub fn (mut rl RateLimiter) reset() {
	rl.tokens = rl.capacity
	rl.last_refill = time.now()
}

// available_tokens returns the current number of available tokens in the bucket.
pub fn (mut rl RateLimiter) available_tokens() f64 {
	rl.refill()
	return rl.tokens
}

fn (mut rl RateLimiter) refill() {
	now := time.now()
	elapsed_sec := f64(now.unix_nano() - rl.last_refill.unix_nano()) / 1_000_000_000.0
	if elapsed_sec > 0.0 {
		new_tokens := elapsed_sec * rl.refill_rate_per_sec
		rl.tokens = math.min(rl.capacity, rl.tokens + new_tokens)
		rl.last_refill = now
	}
}

// ============================================================================
// 2. Circuit Breaker
// ============================================================================

// CircuitBreakerState represents the operational mode of a circuit breaker.
pub enum CircuitBreakerState {
	closed
	open
	half_open
}

// CircuitBreaker prevents cascading failures by temporarily blocking calls to failing dependencies.
pub struct CircuitBreaker {
mut:
	failure_threshold     int
	recovery_timeout      time.Duration
	state                 CircuitBreakerState
	failure_count         int
	last_failure_time     time.Time
	success_threshold     int
	consecutive_successes int
}

// new_circuit_breaker initializes a CircuitBreaker with a consecutive failure threshold and recovery timeout.
pub fn new_circuit_breaker(failure_threshold int, recovery_timeout time.Duration) !CircuitBreaker {
	if failure_threshold <= 0 {
		return error('Failure threshold must be greater than 0, got ${failure_threshold}')
	}
	return CircuitBreaker{
		failure_threshold:     failure_threshold
		recovery_timeout:      recovery_timeout
		state:                 .closed
		failure_count:         0
		last_failure_time:     time.Time{}
		success_threshold:     2
		consecutive_successes: 0
	}
}

// can_execute checks whether an operation is permitted to execute under current circuit breaker state.
pub fn (mut cb CircuitBreaker) can_execute() bool {
	if cb.state == .closed {
		return true
	}

	if cb.state == .open {
		if time.now().unix_nano() - cb.last_failure_time.unix_nano() >= cb.recovery_timeout.nanoseconds() {
			cb.state = .half_open
			cb.consecutive_successes = 0
			return true
		}
		return false
	}

	// In half-open state, probe executions are allowed
	return true
}

// record_success updates breaker state after a successful execution.
pub fn (mut cb CircuitBreaker) record_success() {
	if cb.state == .half_open {
		cb.consecutive_successes++
		if cb.consecutive_successes >= cb.success_threshold {
			cb.state = .closed
			cb.failure_count = 0
			cb.consecutive_successes = 0
		}
	} else if cb.state == .closed {
		cb.failure_count = 0
	}
}

// record_failure updates breaker state after a failed execution, tripping to open if threshold reached.
pub fn (mut cb CircuitBreaker) record_failure() {
	cb.last_failure_time = time.now()
	if cb.state == .half_open {
		cb.state = .open
		cb.consecutive_successes = 0
	} else if cb.state == .closed {
		cb.failure_count++
		if cb.failure_count >= cb.failure_threshold {
			cb.state = .open
		}
	}
}

// reset restores circuit breaker to closed healthy state.
pub fn (mut cb CircuitBreaker) reset() {
	cb.state = .closed
	cb.failure_count = 0
	cb.consecutive_successes = 0
}

// get_state returns current circuit state (.closed, .open, or .half_open).
pub fn (cb &CircuitBreaker) get_state() CircuitBreakerState {
	return cb.state
}

// is_closed returns true if the circuit is healthy and accepting traffic.
pub fn (cb &CircuitBreaker) is_closed() bool {
	return cb.state == .closed
}

// is_open returns true if the circuit is tripped and rejecting requests.
pub fn (cb &CircuitBreaker) is_open() bool {
	return cb.state == .open
}

// ============================================================================
// 3. Generic Fallback & Retry with Exponential Backoff
// ============================================================================

// retry executes action repeatedly up to attempts times using exponential backoff until successful.
pub fn retry[T](attempts int, base_delay time.Duration, factor f64, max_delay time.Duration, action fn () !T) !T {
	if attempts <= 0 {
		return error('Retry attempts must be at least 1, got ${attempts}')
	}

	mut current_delay := base_delay
	mut last_err := ''

	for i in 0 .. attempts {
		res := action() or {
			last_err = err.msg()
			if i + 1 < attempts {
				time.sleep(current_delay)
				current_ns := i64(current_delay)
				next_delay_ns := i64(f64(current_ns) * factor)
				max_delay_ns := i64(max_delay)
				current_delay = if next_delay_ns > max_delay_ns {
					max_delay
				} else {
					time.Duration(next_delay_ns)
				}
			}
			continue
		}
		return res
	}

	return error('Retry exhausted after ${attempts} attempts. Last error: ${last_err}')
}

// ============================================================================
// 4. Debouncer / Throttler
// ============================================================================

// Debouncer ensures an action cannot fire more frequently than a minimum interval.
pub struct Debouncer {
mut:
	interval     time.Duration
	last_trigger time.Time
}

// new_debouncer initializes a debouncer with the specified minimum interval between triggers.
pub fn new_debouncer(interval time.Duration) Debouncer {
	return Debouncer{
		interval:     interval
		last_trigger: time.Time{}
	}
}

// can_trigger returns true and records the timestamp if enough time has elapsed since the last trigger.
pub fn (mut d Debouncer) can_trigger() bool {
	now := time.now()
	if d.last_trigger.unix_nano() == 0 || now.unix_nano() - d.last_trigger.unix_nano() >= d.interval.nanoseconds() {
		d.last_trigger = now
		return true
	}
	return false
}

// reset clears the last trigger timestamp.
pub fn (mut d Debouncer) reset() {
	d.last_trigger = time.Time{}
}

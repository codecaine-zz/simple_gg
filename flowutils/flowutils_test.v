module flowutils

import time

fn test_rate_limiter_allow_and_refill() {
	mut rl := new_rate_limiter(2, 10.0)!
	assert rl.allow() == true
	assert rl.allow() == true
	assert rl.allow() == false // Bucket depleted

	time.sleep(time.millisecond * 120) // ~1 token refilled
	assert rl.allow() == true

	rl.reset()
	assert rl.available_tokens() >= 2.0
}

fn test_circuit_breaker_lifecycle() {
	mut cb := new_circuit_breaker(2, time.millisecond * 50)!
	assert cb.is_closed() == true
	assert cb.can_execute() == true

	cb.record_failure()
	assert cb.is_closed() == true

	cb.record_failure() // Threshold 2 reached
	assert cb.is_open() == true
	assert cb.can_execute() == false

	time.sleep(time.millisecond * 60) // Recovery timeout expires -> half-open
	assert cb.can_execute() == true
	assert cb.get_state() == .half_open

	// 2 consecutive successes close the circuit
	cb.record_success()
	assert cb.get_state() == .half_open
	cb.record_success()
	assert cb.is_closed() == true
}

struct RetryContext {
mut:
	count int
}

fn test_generic_retry() {
	mut ctx := &RetryContext{}
	res := retry[string](3, time.millisecond * 10, 2.0, time.millisecond * 50, fn [mut ctx] () !string {
		ctx.count++
		if ctx.count < 2 {
			return error('transient failure')
		}
		return 'success'
	}) or { '' }

	assert res == 'success'
	assert ctx.count == 2
}

fn test_debouncer() {
	mut d := new_debouncer(time.millisecond * 40)
	assert d.can_trigger() == true
	assert d.can_trigger() == false // Too soon

	time.sleep(time.millisecond * 50)
	assert d.can_trigger() == true
}

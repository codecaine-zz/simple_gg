module main

import flowutils
import time

fn main() {
	println('==================================================')
	println('                demo_flowutils                    ')
	println('==================================================')

	// 1. Rate Limiter (Token Bucket)
	println('1. RateLimiter (capacity=3, refill=2 tokens/sec):')
	mut rl := flowutils.new_rate_limiter(3, 2.0) or { panic(err) }
	println('  Initial available tokens: ${rl.available_tokens()}')
	println('  Request 1 allowed? ${rl.allow()}')
	println('  Request 2 allowed? ${rl.allow()}')
	println('  Request 3 allowed? ${rl.allow()}')
	println('  Request 4 allowed? ${rl.allow()} (bucket should be empty)')

	// 2. Circuit Breaker
	println('\n2. CircuitBreaker (failure_threshold=2):')
	mut cb := flowutils.new_circuit_breaker(2, 50 * time.millisecond) or { panic(err) }
	println('  Initial state: ${cb.get_state()} (can_execute: ${cb.can_execute()})')

	cb.record_failure()
	println('  After 1 failure: state=${cb.get_state()}')
	cb.record_failure()
	println('  After 2 failures: state=${cb.get_state()} (is_open: ${cb.is_open()})')
	println('  Can execute when open? ${cb.can_execute()}')

	time.sleep(60 * time.millisecond)
	println('  After recovery timeout: can_execute=${cb.can_execute()} (trips to half_open)')
	cb.record_success()
	cb.record_success()
	println('  After consecutive successes: state=${cb.get_state()}')

	// 3. Retry with Exponential Backoff
	println('\n3. Retry with Exponential Backoff:')
	mut attempts := [0]
	result := flowutils.retry[int](3, 10 * time.millisecond, 2.0, 100 * time.millisecond, fn [mut attempts] () !int {
		attempts[0]++
		if attempts[0] < 3 {
			return error('transient error at attempt ${attempts[0]}')
		}
		return 200
	}) or {
		eprintln('Retry failed: ${err}')
		0
	}
	println('  Retry succeeded with return value: ${result} after ${attempts[0]} attempts')

	// 4. Debouncer
	println('\n4. Debouncer (interval=50ms):')
	mut debouncer := flowutils.new_debouncer(50 * time.millisecond)
	println('  Trigger 1: ${debouncer.can_trigger()}')
	println('  Trigger 2 (immediate): ${debouncer.can_trigger()}')
	time.sleep(55 * time.millisecond)
	println('  Trigger 3 (after 55ms): ${debouncer.can_trigger()}')

	println('\n✔ flowutils demo completed successfully!')
}

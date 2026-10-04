module flowutils

import time

fn test_rate_limiter_time_until_available() {
	mut rl := new_rate_limiter(2, 10.0)!
	assert rl.allow()
	assert rl.allow()
	assert !rl.allow()
	wait := rl.time_until_available(1)
	assert wait > 0
	assert wait <= 110 * time.millisecond
}

fn test_rate_limiter_wait_blocks_until_token() {
	mut rl := new_rate_limiter(1, 50.0)!
	assert rl.allow()
	sw := time.new_stopwatch()
	rl.wait()!
	assert sw.elapsed() >= 5 * time.millisecond
}

fn test_sliding_window_remaining_and_retry_after() {
	mut sw := new_sliding_window_rate_limiter(3, 80 * time.millisecond)!
	assert sw.remaining() == 3
	assert sw.retry_after() == 0
	assert sw.allow()
	assert sw.allow()
	assert sw.remaining() == 1
	assert sw.allow()
	assert !sw.allow()
	assert sw.remaining() == 0
	ra := sw.retry_after()
	assert ra > 0
	assert ra <= 80 * time.millisecond
	time.sleep(ra + 5 * time.millisecond)
	assert sw.remaining() >= 1
	assert sw.allow()
}

fn test_sliding_window_rejects_invalid() {
	if _ := new_sliding_window_rate_limiter(0, time.second) {
		assert false
	}
	if _ := new_sliding_window_rate_limiter(1, 0) {
		assert false
	}
}

module asyncutils

import time

@[heap]
struct Counter {
mut:
	n int
}

fn parse_pos(x int) !int {
	if x < 0 {
		return error('negative: ${x}')
	}
	return x * 2
}

fn test_parallel_try_map_ok_and_err() {
	nums := []int{len: 100, init: index}
	out := parallel_try_map[int, int](nums, 4, parse_pos)!
	assert out.len == 100
	assert out[0] == 0
	assert out[99] == 198
	mut bad := nums.clone()
	bad[57] = -1
	if _ := parallel_try_map[int, int](bad, 4, parse_pos) {
		assert false
	} else {
		assert err.msg().contains('negative')
	}
	empty := parallel_try_map[int, int]([]int{}, 4, parse_pos)!
	assert empty.len == 0
}

fn test_parallel_reduce() {
	nums := []int{len: 1000, init: index + 1}
	assert parallel_reduce[int](nums, 8, 0, fn (a int, b int) int {
		return a + b
	}) == 500500
	assert parallel_reduce[int]([]int{}, 8, 7, fn (a int, b int) int {
		return a + b
	}) == 7
	assert parallel_reduce[int]([3, 9, 2], 0, -1, fn (a int, b int) int {
		return if a > b { a } else { b }
	}) == 9
}

fn test_with_timeout() {
	v := with_timeout[int](time.second, fn () int {
		return 42
	})!
	assert v == 42
	if _ := with_timeout[int](20 * time.millisecond, fn () int {
		time.sleep(300 * time.millisecond)
		return 1
	})
	{
		assert false, 'should time out'
	}
}

fn test_semaphore() {
	mut s := new_semaphore(2)!
	assert s.try_acquire()
	assert s.try_acquire()
	assert !s.try_acquire()
	assert !s.acquire_timeout(10 * time.millisecond)
	s.release()
	assert s.try_acquire()
	s.release()
	s.release()
	if _ := new_semaphore(0) {
		assert false
	}
}

fn test_once() {
	mut o := new_once()
	mut c := &Counter{}
	for _ in 0 .. 5 {
		o.do(fn [mut c] () {
			c.n++
		})
	}
	assert c.n == 1
}

fn test_submit_after_stop_errors() {
	mut pool := new_worker_pool(2, 4)!
	pool.stop()
	if _ := pool.submit(fn () {}) {
		assert false
	}
}

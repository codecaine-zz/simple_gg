module asyncutils

import time
import sync.stdatomic

fn test_parallel_map() {
	nums := [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
	doubled := parallel_map[int, int](nums, 4, fn (n int) int {
		return n * 2
	})
	assert doubled == [2, 4, 6, 8, 10, 12, 14, 16, 18, 20]

	empty := parallel_map[string, int]([]string{}, 2, fn (s string) int {
		return s.len
	})
	assert empty.len == 0

	single := parallel_map[int, int]([42], 4, fn (n int) int {
		return n + 1
	})
	assert single == [43]
}

fn test_parallel_filter() {
	nums := [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
	evens := parallel_filter[int](nums, 3, fn (n int) bool {
		return n % 2 == 0
	})
	assert evens == [2, 4, 6, 8, 10]

	odds := parallel_filter[int](nums, 1, fn (n int) bool {
		return n % 2 != 0
	})
	assert odds == [1, 3, 5, 7, 9]
}

struct SharedCounter {
pub mut:
	val u64
}

fn test_parallel_each() {
	nums := [10, 20, 30, 40]
	counter_ref := &SharedCounter{val: 0}
	parallel_each[int](nums, 2, fn [counter_ref] (n int) {
		stdatomic.add_u64(&counter_ref.val, n)
	})
	assert counter_ref.val == 100
}

fn test_waitgroup() {
	mut wg := new_waitgroup()
	counter_ref := &SharedCounter{val: 0}

	for _ in 0 .. 5 {
		wg.add(1)
		spawn fn (mut wg WaitGroup, c &SharedCounter) {
			time.sleep(10 * time.millisecond)
			stdatomic.add_u64(&c.val, 1)
			wg.done()
		}(mut wg, counter_ref)
	}

	wg.wait()
	assert counter_ref.val == 5
}

fn test_worker_pool() {
	mut pool := new_worker_pool(3, 10) or { panic(err) }
	defer {
		pool.stop()
	}

	counter_ref := &SharedCounter{val: 0}
	for _ in 0 .. 6 {
		pool.submit(fn [counter_ref] () {
			time.sleep(5 * time.millisecond)
			stdatomic.add_u64(&counter_ref.val, 1)
		}) or { panic(err) }
	}

	pool.wait_all()
	assert counter_ref.val == 6
}

module main

import asyncutils

fn main() {
	println('==================================================')
	println('               demo_asyncutils                    ')
	println('==================================================')

	// 1. Parallel Map
	println('1. Parallel Map:')
	nums := [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
	squares := asyncutils.parallel_map[int, int](nums, 4, fn (x int) int {
		return x * x
	})
	println('  Input:   ${nums}')
	println('  Squares: ${squares}')

	// 2. Parallel Filter
	println('\n2. Parallel Filter:')
	evens := asyncutils.parallel_filter[int](nums, 4, fn (x int) bool {
		return x % 2 == 0
	})
	println('  Even numbers: ${evens}')

	// 3. WaitGroup
	println('\n3. WaitGroup Synchronization:')
	mut wg := asyncutils.new_waitgroup()
	wg.add(3)
	for i in 1 .. 4 {

		// Do work
		spawn fn (id int, mut group asyncutils.WaitGroup) {
			group.done()
		}(i, mut wg)
	}
	wg.wait()
	println('  All 3 concurrent tasks completed via WaitGroup!')

	// 4. Worker Pool
	println('\n4. Bounded Worker Pool:')
	mut pool := asyncutils.new_worker_pool(3, 10) or { panic(err) }
	for i in 1 .. 6 {
		task_id := i
		pool.submit(fn [task_id] () {
			_ = task_id
		}) or { panic(err) }
	}
	pool.wait_all()
	pool.stop()
	println('  Submitted and executed 5 tasks across 3 worker threads!')

	println('\n✔ asyncutils demo completed successfully!')
}

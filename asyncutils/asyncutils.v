module asyncutils

import math
import sync

// ============================================================================
// 1. Parallel Collection Processing
// ============================================================================

fn worker_map[T, R](chunk []T, mapper fn (T) R) []R {
	mut res := []R{cap: chunk.len}
	for item in chunk {
		res << mapper(item)
	}
	return res
}

// parallel_map concurrently maps a slice of items using at most worker_count threads, preserving input order.
pub fn parallel_map[T, R](items []T, worker_count int, mapper fn (T) R) []R {
	if items.len == 0 {
		return []R{}
	}
	actual_workers := int(math.max(1, math.min(worker_count, items.len)))
	if actual_workers <= 1 {
		return worker_map[T, R](items, mapper)
	}

	chunk_size := (items.len + actual_workers - 1) / actual_workers
	mut threads := []thread []R{}

	for w in 0 .. actual_workers {
		start := w * chunk_size
		if start >= items.len {
			break
		}
		end := int(math.min(items.len, start + chunk_size))
		chunk := items[start..end]
		threads << spawn worker_map[T, R](chunk, mapper)
	}

	chunk_results := threads.wait()
	mut final_results := []R{cap: items.len}
	for chunk_list in chunk_results {
		final_results << chunk_list
	}
	return final_results
}

fn worker_filter[T](chunk []T, predicate fn (T) bool) []T {
	mut res := []T{cap: chunk.len}
	for item in chunk {
		if predicate(item) {
			res << item
		}
	}
	return res
}

// parallel_filter concurrently evaluates predicate on each item and returns matching items in order.
pub fn parallel_filter[T](items []T, worker_count int, predicate fn (T) bool) []T {
	if items.len == 0 {
		return []T{}
	}
	actual_workers := int(math.max(1, math.min(worker_count, items.len)))
	if actual_workers <= 1 {
		return worker_filter[T](items, predicate)
	}

	chunk_size := (items.len + actual_workers - 1) / actual_workers
	mut threads := []thread []T{}

	for w in 0 .. actual_workers {
		start := w * chunk_size
		if start >= items.len {
			break
		}
		end := int(math.min(items.len, start + chunk_size))
		chunk := items[start..end]
		threads << spawn worker_filter[T](chunk, predicate)
	}

	chunk_results := threads.wait()
	mut final_results := []T{}
	for chunk_list in chunk_results {
		final_results << chunk_list
	}
	return final_results
}

fn worker_each[T](chunk []T, action fn (T)) {
	for item in chunk {
		action(item)
	}
}

// parallel_each runs a side-effecting action concurrently across items using up to worker_count threads.
pub fn parallel_each[T](items []T, worker_count int, action fn (T)) {
	if items.len == 0 {
		return
	}
	actual_workers := int(math.max(1, math.min(worker_count, items.len)))
	if actual_workers <= 1 {
		worker_each[T](items, action)
		return
	}

	chunk_size := (items.len + actual_workers - 1) / actual_workers
	mut threads := []thread{}

	for w in 0 .. actual_workers {
		start := w * chunk_size
		if start >= items.len {
			break
		}
		end := int(math.min(items.len, start + chunk_size))
		chunk := items[start..end]
		threads << spawn worker_each[T](chunk, action)
	}
	threads.wait()
}

// ============================================================================
// 2. WaitGroup Synchronization
// ============================================================================

// WaitGroup waits for a collection of concurrent tasks to finish.
@[heap]
pub struct WaitGroup {
mut:
	wg sync.WaitGroup
}

// new_waitgroup creates and initializes a new WaitGroup.
pub fn new_waitgroup() &WaitGroup {
	return &WaitGroup{
		wg: sync.new_waitgroup()
	}
}

// add increments the WaitGroup counter by delta.
pub fn (mut wg WaitGroup) add(delta int) {
	wg.wg.add(delta)
}

// done decrements the WaitGroup counter by 1.
pub fn (mut wg WaitGroup) done() {
	wg.wg.done()
}

// wait blocks until the counter drops to 0.
pub fn (mut wg WaitGroup) wait() {
	wg.wg.wait()
}

// ============================================================================
// 3. Worker Pool
// ============================================================================

pub type TaskFn = fn ()

// WorkerPool dispatches tasks across a fixed number of worker threads via a bounded channel.
pub struct WorkerPool {
mut:
	tasks       chan TaskFn
	workers     int
	wg          sync.WaitGroup
	is_closed   bool
	worker_done sync.WaitGroup
}

// new_worker_pool initializes a bounded worker pool with worker_count threads and a queue capacity.
pub fn new_worker_pool(worker_count int, queue_size int) !&WorkerPool {
	if worker_count <= 0 {
		return error('Worker count must be greater than 0, got ${worker_count}')
	}
	q_size := if queue_size <= 0 { 64 } else { queue_size }
	mut pool := &WorkerPool{
		tasks:       chan TaskFn{cap: q_size}
		workers:     worker_count
		wg:          sync.new_waitgroup()
		is_closed:   false
		worker_done: sync.new_waitgroup()
	}

	pool.worker_done.add(worker_count)
	for _ in 0 .. worker_count {
		spawn pool.worker_loop()
	}

	return pool
}

fn (mut pool WorkerPool) worker_loop() {
	for {
		task := <-pool.tasks or { break }
		task()
		pool.wg.done()
	}
	pool.worker_done.done()
}

// submit queues a new task into the worker pool.
pub fn (mut pool WorkerPool) submit(task TaskFn) ! {
	if pool.is_closed {
		return error('Worker pool is closed')
	}
	pool.wg.add(1)
	pool.tasks <- task
}

// wait_all blocks until all submitted tasks have completed execution.
pub fn (mut pool WorkerPool) wait_all() {
	pool.wg.wait()
}

// stop closes the job queue and waits for all active worker threads to finish.
pub fn (mut pool WorkerPool) stop() {
	if pool.is_closed {
		return
	}
	pool.is_closed = true
	pool.tasks.close()
	pool.worker_done.wait()
}

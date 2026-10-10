module asyncutils

import sync
import time

// ============================================================================
// 4. Fallible parallel map, reduce, timeouts
// ============================================================================

struct TryChunk[R] {
	vals []R
	err  string
	ok   bool = true
}

fn worker_try_map[T, R](chunk []T, mapper fn (T) !R) TryChunk[R] {
	mut res := []R{cap: chunk.len}
	for item in chunk {
		v := mapper(item) or {
			return TryChunk[R]{
				err: err.msg()
				ok:  false
			}
		}
		res << v
	}
	return TryChunk[R]{
		vals: res
	}
}

// parallel_try_map maps items concurrently with a fallible mapper. Order is preserved.
// Returns the error of the first failing chunk (in input order) if any mapper fails.
pub fn parallel_try_map[T, R](items []T, worker_count int, mapper fn (T) !R) ![]R {
	if items.len == 0 {
		return []R{}
	}
	workers := if worker_count < 1 {
		1
	} else if worker_count > items.len {
		items.len
	} else {
		worker_count
	}
	chunk_size := (items.len + workers - 1) / workers
	mut threads := []thread TryChunk[R]{}
	mut start := 0
	for start < items.len {
		end := if start + chunk_size > items.len { items.len } else { start + chunk_size }
		threads << spawn worker_try_map[T, R](items[start..end], mapper)
		start = end
	}
	results := threads.wait()
	mut out := []R{cap: items.len}
	for r in results {
		if !r.ok {
			return error(r.err)
		}
		out << r.vals
	}
	return out
}

fn worker_reduce[T](chunk []T, identity T, op fn (T, T) T) T {
	mut acc := identity
	for item in chunk {
		acc = op(acc, item)
	}
	return acc
}

// parallel_reduce folds items concurrently. `op` must be associative and `identity`
// its neutral element (e.g. 0 for +, 1 for *), otherwise results are undefined.
pub fn parallel_reduce[T](items []T, worker_count int, identity T, op fn (T, T) T) T {
	if items.len == 0 {
		return identity
	}
	workers := if worker_count < 1 {
		1
	} else if worker_count > items.len {
		items.len
	} else {
		worker_count
	}
	if workers == 1 {
		return worker_reduce[T](items, identity, op)
	}
	chunk_size := (items.len + workers - 1) / workers
	mut threads := []thread T{}
	mut start := 0
	for start < items.len {
		end := if start + chunk_size > items.len { items.len } else { start + chunk_size }
		threads << spawn worker_reduce[T](items[start..end], identity, op)
		start = end
	}
	return worker_reduce[T](threads.wait(), identity, op)
}

fn run_into[T](ch chan T, f fn () T) {
	ch <- f()
}

// with_timeout runs `f` on a new thread and returns its result, or an error if it
// does not finish within `timeout`. Note: a timed-out task keeps running in the
// background (threads cannot be killed safely); make `f` cooperative if that matters.
pub fn with_timeout[T](timeout time.Duration, f fn () T) !T {
	ch := chan T{cap: 1}
	spawn run_into[T](ch, f)
	select {
		v := <-ch {
			return v
		}
		timeout {
			return error('operation timed out after ${timeout}')
		}
	}
	return error('operation timed out after ${timeout}')
}

// ============================================================================
// 5. Semaphore & Once
// ============================================================================

// Semaphore limits concurrent access to a resource to a fixed number of permits.
@[heap]
pub struct Semaphore {
mut:
	sem &sync.Semaphore = unsafe { nil }
}

// new_semaphore creates a semaphore with `permits` available slots.
pub fn new_semaphore(permits int) !&Semaphore {
	if permits <= 0 {
		return error('permits must be greater than 0, got ${permits}')
	}
	return &Semaphore{
		sem: sync.new_semaphore_init(u32(permits))
	}
}

// acquire blocks until a permit is available.
pub fn (mut s Semaphore) acquire() {
	s.sem.wait()
}

// try_acquire takes a permit if one is immediately available.
pub fn (mut s Semaphore) try_acquire() bool {
	return s.sem.try_wait()
}

// acquire_timeout waits up to `timeout` for a permit.
pub fn (mut s Semaphore) acquire_timeout(timeout time.Duration) bool {
	return s.sem.timed_wait(timeout)
}

// release returns a permit.
pub fn (mut s Semaphore) release() {
	s.sem.post()
}

// with_permit runs `f` while holding a permit, always releasing it afterwards.
pub fn (mut s Semaphore) with_permit(f fn ()) {
	s.sem.wait()
	defer {
		s.sem.post()
	}
	f()
}

// Once runs an initializer exactly once, even when called from many threads.
@[heap]
pub struct Once {
mut:
	once &sync.Once = unsafe { nil }
}

// new_once creates a fresh Once guard.
pub fn new_once() &Once {
	return &Once{
		once: sync.new_once()
	}
}

// do executes `f` only on the first call.
pub fn (mut o Once) do(f fn ()) {
	o.once.do(f)
}

module structutils

import math
import rand

struct Job {
	name string
	pri  int
}

fn test_priority_queue_matches_sort() {
	mut q := new_priority_queue[int](fn (a int, b int) bool {
		return a < b
	})
	rand.seed([u32(1), 2])
	mut ref := []int{}
	for _ in 0 .. 1000 {
		v := rand.intn(10000) or { 0 }
		q.push(v)
		ref << v
	}
	ref.sort()
	assert q.peek()? == ref[0]
	mut got := []int{}
	for !q.is_empty() {
		got << q.pop()?
	}
	assert got == ref
	assert q.pop() == none
	mut jobs := new_priority_queue[Job](fn (a Job, b Job) bool {
		return a.pri > b.pri
	})
	jobs.push(Job{'low', 1})
	jobs.push(Job{'high', 9})
	assert jobs.pop()?.name == 'high'
}

fn test_deque() {
	mut d := new_deque[int]()
	for i in 0 .. 20 {
		d.push_back(i)
		d.push_front(-i - 1)
	}
	assert d.len() == 40
	assert d.front()? == -20
	assert d.back()? == 19
	assert d.at(20)? == 0
	assert d.pop_front()? == -20
	assert d.pop_back()? == 19
	arr := d.to_array()
	assert arr.len == 38
	assert arr[0] == -19 && arr.last() == 18
	mut e := new_deque[string]()
	assert e.pop_front() == none
	e.push_front('x')
	assert e.pop_back()? == 'x'
}

fn test_trie() {
	mut t := new_trie()
	for w in ['car', 'card', 'care', 'cat', 'dog', 'café'] {
		t.insert(w)
	}
	assert !t.insert('car')
	assert t.len() == 6
	assert t.contains('card')
	assert !t.contains('ca')
	assert t.has_prefix('ca')
	assert t.with_prefix('car', 0) == ['car', 'card', 'care']
	assert t.with_prefix('ca', 2).len == 2
	assert t.with_prefix('caf', 0) == ['café']
	assert t.with_prefix('z', 0).len == 0
}

fn test_optimal_bloom_fp_rate() {
	mut b := new_optimal_bloom(10000, 0.01)!
	for i in 0 .. 10000 {
		b.add('item-${i}')
	}
	for i in 0 .. 10000 {
		assert b.contains('item-${i}')
	}
	mut fp := 0
	for i in 0 .. 10000 {
		if b.contains('other-${i}') {
			fp++
		}
	}
	assert fp < 200, 'false positives ${fp}/10000 exceed 2%'
	assert b.hash_count() == 7
}

fn test_hyperloglog() {
	mut h := new_hyperloglog(14)!
	for i in 0 .. 100000 {
		h.add('u${i}')
		h.add('u${i}') // duplicates must not count
	}
	est := f64(h.count())
	assert math.abs(est - 100000) / 100000 < 0.03, 'estimate ${est}'
	mut small := new_hyperloglog(10)!
	for i in 0 .. 50 {
		small.add('${i}')
	}
	assert math.abs(f64(small.count()) - 50) <= 3
	mut a := new_hyperloglog(12)!
	mut b := new_hyperloglog(12)!
	for i in 0 .. 5000 {
		a.add('a${i}')
		b.add('b${i}')
	}
	a.merge(b)!
	assert math.abs(f64(a.count()) - 10000) / 10000 < 0.05
	if _ := new_hyperloglog(3) {
		assert false
	}
}

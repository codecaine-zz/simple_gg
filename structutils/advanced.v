module structutils

import math
import hash.fnv1a

// ============================================================================
// PriorityQueue[T] — binary heap with a user comparator
// ============================================================================

// PriorityQueue pops the element for which `less(a, b)` ranks first
// (use `a < b` for a min-queue, `a > b` for a max-queue).
pub struct PriorityQueue[T] {
mut:
	data []T
	less fn (T, T) bool = unsafe { nil }
}

// new_priority_queue creates a queue ordered by `less`.
pub fn new_priority_queue[T](less fn (T, T) bool) PriorityQueue[T] {
	return PriorityQueue[T]{
		less: less
	}
}

// push inserts an item in O(log n).
pub fn (mut q PriorityQueue[T]) push(item T) {
	q.data << item
	mut i := q.data.len - 1
	for i > 0 {
		p := (i - 1) / 2
		if !q.less(q.data[i], q.data[p]) {
			break
		}
		q.data[i], q.data[p] = q.data[p], q.data[i]
		i = p
	}
}

// pop removes and returns the highest-priority item in O(log n).
pub fn (mut q PriorityQueue[T]) pop() ?T {
	if q.data.len == 0 {
		return none
	}
	top := q.data[0]
	last := q.data.pop()
	if q.data.len > 0 {
		q.data[0] = last
		mut i := 0
		n := q.data.len
		for {
			l := 2 * i + 1
			r := l + 1
			mut m := i
			if l < n && q.less(q.data[l], q.data[m]) {
				m = l
			}
			if r < n && q.less(q.data[r], q.data[m]) {
				m = r
			}
			if m == i {
				break
			}
			q.data[i], q.data[m] = q.data[m], q.data[i]
			i = m
		}
	}
	return top
}

// peek returns the highest-priority item without removing it.
pub fn (q PriorityQueue[T]) peek() ?T {
	if q.data.len == 0 {
		return none
	}
	return q.data[0]
}

// len returns the number of queued items.
pub fn (q PriorityQueue[T]) len() int {
	return q.data.len
}

// is_empty reports whether the queue is empty.
pub fn (q PriorityQueue[T]) is_empty() bool {
	return q.data.len == 0
}

// ============================================================================
// Deque[T] — growable ring buffer, O(1) amortized at both ends
// ============================================================================

// Deque is a double-ended queue.
pub struct Deque[T] {
mut:
	buf  []T
	head int
	size int
}

// new_deque creates an empty deque.
pub fn new_deque[T]() Deque[T] {
	return Deque[T]{}
}

fn (mut d Deque[T]) grow() {
	new_cap := if d.buf.len == 0 { 8 } else { d.buf.len * 2 }
	mut nb := []T{cap: new_cap}
	for i in 0 .. d.size {
		nb << d.buf[(d.head + i) % d.buf.len]
	}
	// Fill to capacity so indices are valid.
	for nb.len < new_cap {
		nb << if d.size > 0 { nb[0] } else { T{} }
	}
	d.buf = nb
	d.head = 0
}

// push_back appends to the back.
pub fn (mut d Deque[T]) push_back(item T) {
	if d.size == d.buf.len {
		if d.buf.len == 0 {
			d.buf = []T{len: 8, init: item}
		} else {
			d.grow()
		}
	}
	d.buf[(d.head + d.size) % d.buf.len] = item
	d.size++
}

// push_front prepends to the front.
pub fn (mut d Deque[T]) push_front(item T) {
	if d.size == d.buf.len {
		if d.buf.len == 0 {
			d.buf = []T{len: 8, init: item}
		} else {
			d.grow()
		}
	}
	d.head = (d.head - 1 + d.buf.len) % d.buf.len
	d.buf[d.head] = item
	d.size++
}

// pop_front removes from the front.
pub fn (mut d Deque[T]) pop_front() ?T {
	if d.size == 0 {
		return none
	}
	v := d.buf[d.head]
	d.head = (d.head + 1) % d.buf.len
	d.size--
	return v
}

// pop_back removes from the back.
pub fn (mut d Deque[T]) pop_back() ?T {
	if d.size == 0 {
		return none
	}
	d.size--
	return d.buf[(d.head + d.size) % d.buf.len]
}

// front peeks the front element.
pub fn (d Deque[T]) front() ?T {
	if d.size == 0 {
		return none
	}
	return d.buf[d.head]
}

// back peeks the back element.
pub fn (d Deque[T]) back() ?T {
	if d.size == 0 {
		return none
	}
	return d.buf[(d.head + d.size - 1) % d.buf.len]
}

// at returns the i-th element from the front.
pub fn (d Deque[T]) at(i int) ?T {
	if i < 0 || i >= d.size {
		return none
	}
	return d.buf[(d.head + i) % d.buf.len]
}

// len returns the element count.
pub fn (d Deque[T]) len() int {
	return d.size
}

// to_array returns elements front-to-back.
pub fn (d Deque[T]) to_array() []T {
	mut out := []T{cap: d.size}
	for i in 0 .. d.size {
		out << d.buf[(d.head + i) % d.buf.len]
	}
	return out
}

// ============================================================================
// Trie — prefix tree for autocomplete / prefix queries
// ============================================================================

@[heap]
struct TrieNode {
mut:
	children map[rune]&TrieNode
	terminal bool
}

// Trie stores strings for fast prefix lookups.
@[heap]
pub struct Trie {
mut:
	root  &TrieNode = &TrieNode{}
	count int
}

// new_trie creates an empty trie.
pub fn new_trie() &Trie {
	return &Trie{}
}

// insert adds a word; returns false if it was already present.
pub fn (mut t Trie) insert(word string) bool {
	mut n := t.root
	for r in word.runes() {
		if r !in n.children {
			n.children[r] = &TrieNode{}
		}
		n = n.children[r] or { return false }
	}
	if n.terminal {
		return false
	}
	n.terminal = true
	t.count++
	return true
}

fn (t &Trie) node_for(prefix string) ?&TrieNode {
	mut n := t.root
	for r in prefix.runes() {
		n = n.children[r] or { return none }
	}
	return n
}

// contains reports whether the exact word is stored.
pub fn (t &Trie) contains(word string) bool {
	n := t.node_for(word) or { return false }
	return n.terminal
}

// has_prefix reports whether any stored word starts with prefix.
pub fn (t &Trie) has_prefix(prefix string) bool {
	t.node_for(prefix) or { return false }
	return true
}

// with_prefix returns up to `limit` stored words starting with prefix, sorted
// (limit <= 0 means no limit).
pub fn (t &Trie) with_prefix(prefix string, limit int) []string {
	start := t.node_for(prefix) or { return [] }
	mut out := []string{}
	collect(start, prefix.runes(), mut out, limit)
	return out
}

fn collect(n &TrieNode, path []rune, mut out []string, limit int) {
	if limit > 0 && out.len >= limit {
		return
	}
	if n.terminal {
		out << path.string()
	}
	mut keys := n.children.keys()
	keys.sort()
	for k in keys {
		mut p := path.clone()
		p << k
		child := n.children[k] or { continue }
		collect(child, p, mut out, limit)
		if limit > 0 && out.len >= limit {
			return
		}
	}
}

// len returns the number of stored words.
pub fn (t &Trie) len() int {
	return t.count
}

// ============================================================================
// Optimal Bloom filter (Kirsch–Mitzenmacher double hashing over 64-bit FNV)
// ============================================================================

// OptimalBloom is a Bloom filter sized from expected item count and target
// false-positive rate.
pub struct OptimalBloom {
mut:
	bits  []u64
	m     u64
	k     int
	items int
}

// new_optimal_bloom sizes a filter for `expected_items` with false-positive rate `fp_rate`.
pub fn new_optimal_bloom(expected_items int, fp_rate f64) !OptimalBloom {
	if expected_items <= 0 {
		return error('expected_items must be > 0')
	}
	if fp_rate <= 0 || fp_rate >= 1 {
		return error('fp_rate must be in (0, 1)')
	}
	n := f64(expected_items)
	m := math.ceil(-n * math.log(fp_rate) / (math.ln2 * math.ln2))
	k := int(math.max(1.0, math.round(m / n * math.ln2)))
	words := int(math.ceil(m / 64.0))
	return OptimalBloom{
		bits: []u64{len: words}
		m:    u64(words) * 64
		k:    k
	}
}

fn bloom_hashes(item string) (u64, u64) {
	h1 := fnv1a.sum64_string(item)
	// Second independent-ish hash: splitmix64 finalizer of h1.
	mut z := h1 + 0x9e3779b97f4a7c15
	z = (z ^ (z >> 30)) * 0xbf58476d1ce4e5b9
	z = (z ^ (z >> 27)) * 0x94d049bb133111eb
	return h1, (z ^ (z >> 31)) | 1
}

// add inserts an item.
pub fn (mut b OptimalBloom) add(item string) {
	h1, h2 := bloom_hashes(item)
	for i in 0 .. b.k {
		bit := (h1 + u64(i) * h2) % b.m
		b.bits[bit / 64] |= u64(1) << (bit % 64)
	}
	b.items++
}

// contains returns false if definitely absent, true if probably present.
pub fn (b OptimalBloom) contains(item string) bool {
	h1, h2 := bloom_hashes(item)
	for i in 0 .. b.k {
		bit := (h1 + u64(i) * h2) % b.m
		if b.bits[bit / 64] & (u64(1) << (bit % 64)) == 0 {
			return false
		}
	}
	return true
}

// hash_count returns k; bit_count returns m.
pub fn (b OptimalBloom) hash_count() int {
	return b.k
}

// bit_count returns the number of bits in the filter.
pub fn (b OptimalBloom) bit_count() u64 {
	return b.m
}

// ============================================================================
// HyperLogLog — cardinality estimation in fixed memory (~1.04/sqrt(2^p) error)
// ============================================================================

// HyperLogLog estimates the number of distinct items seen.
pub struct HyperLogLog {
mut:
	p   int
	reg []u8
}

// new_hyperloglog creates an estimator with 2^precision registers (precision 4..16).
pub fn new_hyperloglog(precision int) !HyperLogLog {
	if precision < 4 || precision > 16 {
		return error('precision must be between 4 and 16')
	}
	return HyperLogLog{
		p:   precision
		reg: []u8{len: 1 << precision}
	}
}

// add records an item.
pub fn (mut h HyperLogLog) add(item string) {
	_, x := bloom_hashes(item)
	idx := x >> u64(64 - h.p)
	w := (x << u64(h.p)) | (u64(1) << u64(h.p - 1))
	mut rho := u8(1)
	mut v := w
	for v & (u64(1) << 63) == 0 {
		rho++
		v <<= 1
	}
	if rho > h.reg[idx] {
		h.reg[idx] = rho
	}
}

// count returns the estimated number of distinct items.
pub fn (h HyperLogLog) count() u64 {
	m := f64(h.reg.len)
	alpha := match h.reg.len {
		16 { 0.673 }
		32 { 0.697 }
		64 { 0.709 }
		else { 0.7213 / (1.0 + 1.079 / m) }
	}
	mut sum := 0.0
	mut zeros := 0
	for r in h.reg {
		sum += math.pow(2.0, -f64(r))
		if r == 0 {
			zeros++
		}
	}
	est := alpha * m * m / sum
	if est <= 2.5 * m && zeros > 0 {
		return u64(math.round(m * math.log(m / f64(zeros)))) // linear counting
	}
	return u64(math.round(est))
}

// merge folds another HyperLogLog of equal precision into this one (set union).
pub fn (mut h HyperLogLog) merge(other HyperLogLog) ! {
	if other.p != h.p {
		return error('cannot merge HyperLogLogs with different precision')
	}
	for i, r in other.reg {
		if r > h.reg[i] {
			h.reg[i] = r
		}
	}
}

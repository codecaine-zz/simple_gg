module structutils

import datatypes

// ============================================================================
// Generic Stack (LIFO)
// ============================================================================

// SimpleStack represents a generic Last-In-First-Out stack.
pub struct SimpleStack[T] {
mut:
	items []T
}

// new_stack initializes an empty generic stack.
pub fn new_stack[T]() SimpleStack[T] {
	return SimpleStack[T]{
		items: []T{}
	}
}

// push adds an item to the top of the stack.
pub fn (mut s SimpleStack[T]) push(item T) {
	s.items << item
}

// pop removes and returns the top item from the stack, or none if empty.
pub fn (mut s SimpleStack[T]) pop() ?T {
	if s.items.len == 0 {
		return none
	}
	item := s.items.last()
	s.items.delete(s.items.len - 1)
	return item
}

// peek returns the top item without removing it, or none if empty.
pub fn (s SimpleStack[T]) peek() ?T {
	if s.items.len == 0 {
		return none
	}
	return s.items.last()
}

// len returns the count of items currently in the stack.
pub fn (s SimpleStack[T]) len() int {
	return s.items.len
}

// is_empty returns whether the stack contains no items.
pub fn (s SimpleStack[T]) is_empty() bool {
	return s.items.len == 0
}

// clear removes all items from the stack.
pub fn (mut s SimpleStack[T]) clear() {
	s.items.clear()
}

// to_array returns a copy of the stack items as a standard slice.
pub fn (s SimpleStack[T]) to_array() []T {
	return s.items.clone()
}

// ============================================================================
// Generic Queue (FIFO)
// ============================================================================

// SimpleQueue represents a generic First-In-First-Out queue.
pub struct SimpleQueue[T] {
mut:
	items []T
}

// new_queue initializes an empty generic queue.
pub fn new_queue[T]() SimpleQueue[T] {
	return SimpleQueue[T]{
		items: []T{}
	}
}

// push adds an item to the end of the queue.
pub fn (mut q SimpleQueue[T]) push(item T) {
	q.items << item
}

// pop removes and returns the item at the front of the queue, or none if empty.
pub fn (mut q SimpleQueue[T]) pop() ?T {
	if q.items.len == 0 {
		return none
	}
	item := q.items[0]
	q.items.delete(0)
	return item
}

// peek returns the item at the front of the queue without removing it, or none if empty.
pub fn (q SimpleQueue[T]) peek() ?T {
	if q.items.len == 0 {
		return none
	}
	return q.items[0]
}

// len returns the number of items currently in the queue.
pub fn (q SimpleQueue[T]) len() int {
	return q.items.len
}

// is_empty returns whether the queue contains no items.
pub fn (q SimpleQueue[T]) is_empty() bool {
	return q.items.len == 0
}

// clear removes all items from the queue.
pub fn (mut q SimpleQueue[T]) clear() {
	q.items.clear()
}

// to_array returns a copy of the queue items as a standard slice.
pub fn (q SimpleQueue[T]) to_array() []T {
	return q.items.clone()
}

// ============================================================================
// Generic Ring Buffer (Circular Buffer)
// ============================================================================

// SimpleRingBuffer represents a fixed-capacity circular buffer that overwrites the oldest element when full.
pub struct SimpleRingBuffer[T] {
pub:
	capacity int
mut:
	items []T
}

// new_ring_buffer initializes a fixed-capacity circular buffer.
pub fn new_ring_buffer[T](capacity int) SimpleRingBuffer[T] {
	cap := if capacity > 0 { capacity } else { 1 }
	return SimpleRingBuffer[T]{
		capacity: cap
		items: []T{cap: cap}
	}
}

// push adds an item to the circular buffer. If capacity is reached, drops the oldest item.
pub fn (mut r SimpleRingBuffer[T]) push(item T) {
	if r.items.len >= r.capacity {
		r.items.delete(0)
	}
	r.items << item
}

// pop removes and returns the oldest item from the buffer, or none if empty.
pub fn (mut r SimpleRingBuffer[T]) pop() ?T {
	if r.items.len == 0 {
		return none
	}
	item := r.items[0]
	r.items.delete(0)
	return item
}

// get retrieves an element by index (0 being the oldest), or none if out of bounds.
pub fn (r SimpleRingBuffer[T]) get(idx int) ?T {
	if idx < 0 || idx >= r.items.len {
		return none
	}
	return r.items[idx]
}

// len returns the current number of elements stored.
pub fn (r SimpleRingBuffer[T]) len() int {
	return r.items.len
}

// is_full returns whether the buffer has filled its maximum capacity.
pub fn (r SimpleRingBuffer[T]) is_full() bool {
	return r.items.len >= r.capacity
}

// is_empty returns whether the buffer contains no items.
pub fn (r SimpleRingBuffer[T]) is_empty() bool {
	return r.items.len == 0
}

// to_array returns a copy of the elements in oldest-to-newest order.
pub fn (r SimpleRingBuffer[T]) to_array() []T {
	return r.items.clone()
}

// ============================================================================
// Min-Heap Priority Queue
// ============================================================================

// SimpleMinHeap is a binary min-heap priority queue for f64 values.
pub struct SimpleMinHeap {
mut:
	data []f64
}

// new_min_heap initializes an empty binary min-heap.
pub fn new_min_heap() SimpleMinHeap {
	return SimpleMinHeap{
		data: []f64{}
	}
}

// push inserts a value into the min-heap.
pub fn (mut h SimpleMinHeap) push(val f64) {
	h.data << val
	mut i := h.data.len - 1
	for i > 0 {
		parent := (i - 1) / 2
		if h.data[i] < h.data[parent] {
			temp := h.data[i]
			h.data[i] = h.data[parent]
			h.data[parent] = temp
			i = parent
		} else {
			break
		}
	}
}

// pop extracts and returns the minimum value from the heap, or none if empty.
pub fn (mut h SimpleMinHeap) pop() ?f64 {
	if h.data.len == 0 {
		return none
	}
	min_val := h.data[0]
	last_val := h.data.last()
	h.data.delete(h.data.len - 1)

	if h.data.len > 0 {
		h.data[0] = last_val
		mut i := 0
		for {
			left := 2 * i + 1
			right := 2 * i + 2
			mut smallest := i

			if left < h.data.len && h.data[left] < h.data[smallest] {
				smallest = left
			}
			if right < h.data.len && h.data[right] < h.data[smallest] {
				smallest = right
			}
			if smallest != i {
				temp := h.data[i]
				h.data[i] = h.data[smallest]
				h.data[smallest] = temp
				i = smallest
			} else {
				break
			}
		}
	}
	return min_val
}

// peek returns the minimum value without removing it, or none if empty.
pub fn (h SimpleMinHeap) peek() ?f64 {
	if h.data.len == 0 {
		return none
	}
	return h.data[0]
}

// len returns the count of items in the heap.
pub fn (h SimpleMinHeap) len() int {
	return h.data.len
}

// is_empty returns whether the heap is empty.
pub fn (h SimpleMinHeap) is_empty() bool {
	return h.data.len == 0
}

// ============================================================================
// Generic Set
// ============================================================================

// GenericSet represents a mathematical set of unique elements.
pub struct GenericSet[T] {
pub mut:
	set datatypes.Set[T]
}

// new_set creates an empty GenericSet.
pub fn new_set[T]() GenericSet[T] {
	return GenericSet[T]{
		set: datatypes.Set[T]{}
	}
}

// new_set_from_array creates a GenericSet populated with elements from an array.
pub fn new_set_from_array[T](items []T) GenericSet[T] {
	mut s := new_set[T]()
	s.add_all(items)
	return s
}

// add inserts an item into the set.
pub fn (mut s GenericSet[T]) add(item T) {
	s.set.add(item)
}

// add_all inserts multiple items into the set.
pub fn (mut s GenericSet[T]) add_all(items []T) {
	s.set.add_all(items)
}

// remove deletes an item from the set.
pub fn (mut s GenericSet[T]) remove(item T) {
	s.set.remove(item)
}

// contains returns true if item is present in the set.
pub fn (s GenericSet[T]) contains(item T) bool {
	return s.set.exists(item)
}

// size returns the number of unique elements in the set.
pub fn (s GenericSet[T]) size() int {
	return s.set.size()
}

// is_empty returns whether the set contains zero elements.
pub fn (s GenericSet[T]) is_empty() bool {
	return s.set.is_empty()
}

// to_array returns all elements of the set as a slice.
pub fn (s GenericSet[T]) to_array() []T {
	return s.set.array()
}

// clear removes all elements from the set.
pub fn (mut s GenericSet[T]) clear() {
	s.set.clear()
}

// ============================================================================
// Bloom Filter
// ============================================================================

fn hash_bloom_string(val string) u32 {
	mut hash := u32(2166136261)
	for ch in val {
		hash ^= u32(ch)
		hash *= 16777619
	}
	return hash
}

// BloomFilter provides fast probabilistic set membership testing.
pub struct BloomFilter {
mut:
	bf datatypes.BloomFilter[string]
}

// new_bloom_filter creates a BloomFilter with bit capacity and hash function count.
pub fn new_bloom_filter(size int, k int) !BloomFilter {
	b := datatypes.new_bloom_filter[string](hash_bloom_string, size, k)!
	return BloomFilter{
		bf: b
	}
}

// add inserts a string into the BloomFilter.
pub fn (mut b BloomFilter) add(item string) {
	b.bf.add(item)
}

// contains checks whether a string might be in the BloomFilter.
pub fn (b BloomFilter) contains(item string) bool {
	return b.bf.exists(item)
}

// ============================================================================
// Binary Search Tree
// ============================================================================

// BinarySearchTree stores ordered values and provides fast lookup and traversal.
pub struct BinarySearchTree[T] {
mut:
	bst datatypes.BSTree[T]
}

// new_bstree creates an empty BinarySearchTree.
pub fn new_bstree[T]() BinarySearchTree[T] {
	return BinarySearchTree[T]{
		bst: datatypes.BSTree[T]{}
	}
}

// insert adds an item to the BST.
pub fn (mut b BinarySearchTree[T]) insert(item T) {
	b.bst.insert(item)
}

// remove deletes an item from the BST.
pub fn (mut b BinarySearchTree[T]) remove(item T) {
	b.bst.remove(item)
}

// contains returns true if item is in the BST.
pub fn (b BinarySearchTree[T]) contains(item T) bool {
	return b.bst.contains(item)
}

// in_order returns a slice of elements in sorted ascending order.
pub fn (b BinarySearchTree[T]) in_order() []T {
	return b.bst.in_order_traversal()
}

// min returns the smallest value in the tree, or none if empty.
pub fn (b BinarySearchTree[T]) min() ?T {
	val := b.bst.min() or { return none }
	return val
}

// max returns the largest value in the tree, or none if empty.
pub fn (b BinarySearchTree[T]) max() ?T {
	val := b.bst.max() or { return none }
	return val
}

// is_empty returns whether the tree has no nodes.
pub fn (b BinarySearchTree[T]) is_empty() bool {
	return b.bst.is_empty()
}

// ============================================================================
// Linked Lists
// ============================================================================

// SinglyLinkedList represents a singly-linked sequence of generic elements.
pub struct SinglyLinkedList[T] {
mut:
	list datatypes.LinkedList[T]
}

// new_linked_list creates an empty SinglyLinkedList.
pub fn new_linked_list[T]() SinglyLinkedList[T] {
	return SinglyLinkedList[T]{
		list: datatypes.LinkedList[T]{}
	}
}

// push adds an item to the end of the list.
pub fn (mut l SinglyLinkedList[T]) push(item T) {
	l.list.push(item)
}

// pop removes and returns the last item from the list.
pub fn (mut l SinglyLinkedList[T]) pop() ?T {
	val := l.list.pop() or { return none }
	return val
}

// shift removes and returns the first item from the list.
pub fn (mut l SinglyLinkedList[T]) shift() ?T {
	val := l.list.shift() or { return none }
	return val
}

// to_array returns elements as a standard slice.
pub fn (l SinglyLinkedList[T]) to_array() []T {
	return l.list.array()
}

// len returns the count of items in the list.
pub fn (l SinglyLinkedList[T]) len() int {
	return l.list.len()
}

// DoublyLinkedList represents a doubly-linked list allowing bidirectional operations.
pub struct DoublyLinkedList[T] {
mut:
	list datatypes.DoublyLinkedList[T]
}

// new_doubly_linked_list creates an empty DoublyLinkedList.
pub fn new_doubly_linked_list[T]() DoublyLinkedList[T] {
	return DoublyLinkedList[T]{
		list: datatypes.DoublyLinkedList[T]{}
	}
}

// push_back adds an item to the back of the doubly linked list.
pub fn (mut d DoublyLinkedList[T]) push_back(item T) {
	d.list.push_back(item)
}

// push_front adds an item to the front of the doubly linked list.
pub fn (mut d DoublyLinkedList[T]) push_front(item T) {
	d.list.push_front(item)
}

// pop_back removes and returns the last item from the list.
pub fn (mut d DoublyLinkedList[T]) pop_back() ?T {
	val := d.list.pop_back() or { return none }
	return val
}

// pop_front removes and returns the first item from the list.
pub fn (mut d DoublyLinkedList[T]) pop_front() ?T {
	val := d.list.pop_front() or { return none }
	return val
}

// to_array returns elements as a standard slice.
pub fn (d DoublyLinkedList[T]) to_array() []T {
	return d.list.array()
}

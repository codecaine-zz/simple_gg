module structutils

fn test_stack() {
	mut s := new_stack[string]()
	assert s.is_empty()
	assert s.len() == 0

	s.push('first')
	s.push('second')
	s.push('third')

	assert s.len() == 3
	assert s.peek() or { '' } == 'third'

	pop1 := s.pop() or { '' }
	assert pop1 == 'third'
	assert s.len() == 2

	pop2 := s.pop() or { '' }
	assert pop2 == 'second'

	s.clear()
	assert s.is_empty()
	assert s.pop() == none
}

fn test_queue() {
	mut q := new_queue[int]()
	assert q.is_empty()

	q.push(10)
	q.push(20)
	q.push(30)

	assert q.len() == 3
	assert q.peek() or { 0 } == 10

	out1 := q.pop() or { 0 }
	assert out1 == 10
	assert q.len() == 2

	out2 := q.pop() or { 0 }
	assert out2 == 20
}

fn test_ring_buffer() {
	mut r := new_ring_buffer[string](3)
	assert r.capacity == 3
	assert r.is_empty()

	r.push('A')
	r.push('B')
	r.push('C')
	assert r.is_full()
	assert r.len() == 3

	// Pushing when full should drop the oldest ('A')
	r.push('D')
	assert r.len() == 3
	assert r.get(0) or { '' } == 'B'
	assert r.get(1) or { '' } == 'C'
	assert r.get(2) or { '' } == 'D'

	pop_b := r.pop() or { '' }
	assert pop_b == 'B'
	assert r.len() == 2
}

fn test_min_heap() {
	mut h := new_min_heap()
	assert h.is_empty()

	h.push(42.0)
	h.push(12.5)
	h.push(99.0)
	h.push(5.0)

	assert h.len() == 4
	assert h.peek() or { 0.0 } == 5.0

	assert h.pop() or { 0.0 } == 5.0
	assert h.pop() or { 0.0 } == 12.5
	assert h.pop() or { 0.0 } == 42.0
	assert h.pop() or { 0.0 } == 99.0
	assert h.is_empty()
}

fn test_generic_set() {
	mut s := new_set_from_array(['apple', 'banana', 'cherry', 'apple'])
	assert s.size() == 3
	assert s.contains('banana') == true
	assert s.contains('grape') == false

	s.add('grape')
	assert s.size() == 4
	assert s.contains('grape') == true

	s.remove('banana')
	assert s.size() == 3
	assert s.contains('banana') == false

	arr := s.to_array()
	assert arr.len == 3

	s.clear()
	assert s.is_empty()
}

fn test_bloom_filter() {
	mut bf := new_bloom_filter(64, 3) or { panic(err) }
	bf.add('antigravity')
	bf.add('vlang')

	assert bf.contains('antigravity') == true
	assert bf.contains('vlang') == true
	assert bf.contains('completely_unseen_token_xyz') == false
}

fn test_bstree() {
	mut bst := new_bstree[int]()
	assert bst.is_empty()

	bst.insert(10)
	bst.insert(5)
	bst.insert(15)
	bst.insert(3)
	bst.insert(7)

	assert bst.contains(7) == true
	assert bst.contains(99) == false

	assert bst.min() or { -1 } == 3
	assert bst.max() or { -1 } == 15

	order := bst.in_order()
	assert order == [3, 5, 7, 10, 15]

	bst.remove(3)
	assert bst.contains(3) == false
	assert bst.min() or { -1 } == 5
}

fn test_linked_lists() {
	// Singly linked list
	mut ll := new_linked_list[int]()
	ll.push(10)
	ll.push(20)
	ll.push(30)
	assert ll.len() == 3
	assert ll.to_array() == [10, 20, 30]

	shift1 := ll.shift() or { -1 }
	assert shift1 == 10
	assert ll.len() == 2

	pop1 := ll.pop() or { -1 }
	assert pop1 == 30
	assert ll.len() == 1

	// Doubly linked list
	mut dll := new_doubly_linked_list[string]()
	dll.push_back('center')
	dll.push_front('head')
	dll.push_back('tail')
	assert dll.to_array() == ['head', 'center', 'tail']

	pf := dll.pop_front() or { '' }
	assert pf == 'head'

	pb := dll.pop_back() or { '' }
	assert pb == 'tail'
	assert dll.to_array() == ['center']
}

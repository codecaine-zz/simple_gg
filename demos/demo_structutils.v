module main

import structutils

fn main() {
	println('==================================================')
	println('               demo_structutils                   ')
	println('==================================================')

	// 1. SimpleStack (LIFO)
	println('--- SimpleStack[string] ---')
	mut stack := structutils.new_stack[string]()
	stack.push('first')
	stack.push('second')
	stack.push('third')
	println('Stack size: ${stack.len()}, peek: ${stack.peek()?}')
	popped := stack.pop()?
	println('Popped: ${popped}, remaining: ${stack.len()}')
	assert popped == 'third'
	assert stack.len() == 2

	// 2. SimpleQueue (FIFO)
	println('\n--- SimpleQueue[int] ---')
	mut queue := structutils.new_queue[int]()
	queue.push(10)
	queue.push(20)
	queue.push(30)
	println('Queue size: ${queue.len()}, peek: ${queue.peek()?}')
	q_item := queue.pop()?
	println('Popped from queue: ${q_item}, remaining: ${queue.len()}')
	assert q_item == 10
	assert queue.len() == 2

	// 3. SimpleRingBuffer (Circular Buffer)
	println('\n--- SimpleRingBuffer[string] (capacity 3) ---')
	mut ring := structutils.new_ring_buffer[string](3)
	ring.push('log_1')
	ring.push('log_2')
	ring.push('log_3')
	ring.push('log_4') // Overwrites log_1
	ring_items := ring.to_array()
	println('Ring buffer items: ${ring_items}')
	assert ring_items == ['log_2', 'log_3', 'log_4']

	// 4. SimpleMinHeap (Priority Queue)
	println('\n--- SimpleMinHeap ---')
	mut heap := structutils.new_min_heap()
	heap.push(50.0)
	heap.push(10.0)
	heap.push(30.0)
	heap.push(5.0)
	min_val := heap.pop()?
	println('Min extracted from heap: ${min_val}, next min: ${heap.peek()?}')
	assert min_val == 5.0
	assert heap.peek()? == 10.0

	// 5. GenericSet
	println('\n--- GenericSet[string] ---')
	mut set := structutils.new_set[string]()
	set.add('apple')
	set.add('banana')
	set.add('apple')
	println('Set contains "apple": ${set.contains('apple')}, size: ${set.size()}')
	assert set.size() == 2

	// 6. BinarySearchTree[int]
	println('\n--- BinarySearchTree[int] ---')
	mut bst := structutils.new_bstree[int]()
	bst.insert(50)
	bst.insert(30)
	bst.insert(70)
	bst.insert(20)
	bst.insert(40)
	sorted := bst.in_order()
	println('BST in-order traversal (sorted): ${sorted}')
	assert sorted == [20, 30, 40, 50, 70]
	assert bst.min()? == 20
	assert bst.max()? == 70

	println('\n✔ structutils demo completed successfully!')
}

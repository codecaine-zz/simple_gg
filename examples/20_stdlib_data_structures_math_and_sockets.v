module main

import simplegui

fn main() {
	// Create window (Width: 740px, Height: 580px)
	mut win := simplegui.new_simple_window('V Stdlib Integrations, Data Structures & Math', 740, 580)
	win.set_theme('Apple Dark')

	win.add_heading('V Stdlib Integrations & Data Structures')
	win.add_subheading('Generic stacks, queues, min-heaps, thread sync, complex numbers, big integers, and string metrics')

	// 1. Generic Collections & Data Structures
	win.group('grp_collections', '1. Collections: Stack, Queue, Set & MinHeap', fn (mut win simplegui.SimpleWindow) {
		win.begin_row('row_coll_btns')

		win.add_button('btn_test_stack', 'Test Stack (LIFO)')
		win.on_click('btn_test_stack', fn (mut win simplegui.SimpleWindow) {
			mut stack := simplegui.new_stack[string]()
			stack.push('Page 1')
			stack.push('Page 2')
			stack.push('Page 3')
			top := stack.pop() or { 'empty' }
			win.push_toast('Stack Test', 'Pushed 3 items, popped LIFO top: "${top}"', 'info', 3000)
			win.append_console_log('console_stdlib', '[STACK] Pushed 3 items, popped: "${top}"')
		})

		win.add_button('btn_test_queue', 'Test Queue (FIFO)')
		win.on_click('btn_test_queue', fn (mut win simplegui.SimpleWindow) {
			mut queue := simplegui.new_queue[string]()
			queue.push('Task A')
			queue.push('Task B')
			queue.push('Task C')
			first := queue.pop() or { 'empty' }
			win.push_toast('Queue Test', 'Pushed 3 tasks, popped FIFO first: "${first}"', 'info', 3000)
			win.append_console_log('console_stdlib', '[QUEUE] Pushed 3 tasks, popped: "${first}"')
		})

		win.add_button('btn_test_heap', 'Test Min-Heap')
		win.on_click('btn_test_heap', fn (mut win simplegui.SimpleWindow) {
			mut heap := simplegui.new_min_heap[int]()
			heap.push(42)
			heap.push(10)
			heap.push(99)
			heap.push(5)
			min_val := heap.pop() or { 0 }
			win.push_toast('Min-Heap Test', 'Inserted [42, 10, 99, 5], min: ${min_val}', 'success', 3000)
			win.append_console_log('console_stdlib', '[MIN-HEAP] Extracted minimum value: ${min_val}')
		})

		win.end_row()
	})

	// 2. Advanced Math, BigInt & String Metrics
	win.group('grp_math', '2. Advanced Math, Statistics & String Distance', fn (mut win simplegui.SimpleWindow) {
		win.begin_row('row_math_btns')

		win.add_button('btn_test_math', 'Calculate Stats & BigInt')
		win.on_click('btn_test_math', fn (mut win simplegui.SimpleWindow) {
			dataset := [10.0, 20.0, 30.0, 40.0, 50.0]
			mean_val := win.stats_mean(dataset)
			std_dev := win.stats_sample_std_dev(dataset)

			mut b1 := simplegui.big_int_from_str('99999999999999999999')
			mut b2 := simplegui.big_int_from_int(1)
			b3 := b1.add(b2)

			win.append_console_log('console_stdlib', '[MATH] Mean: ${mean_val} | StdDev: ${std_dev:.2f}')
			win.append_console_log('console_stdlib', '[BIGINT] 99999999999999999999 + 1 = ${b3.str()}')
			win.push_toast('Math & Stats', 'Calculated dataset mean: ${mean_val}, BigInt sum computed', 'info', 3000)
		})

		win.add_button('btn_test_string', 'String Distance Metrics')
		win.on_click('btn_test_string', fn (mut win simplegui.SimpleWindow) {
			lev := win.string_levenshtein('kitten', 'sitting')
			jaro := win.string_jaro_winkler_similarity('dwayne', 'duane')

			win.append_console_log('console_stdlib', '[STRING] Levenshtein("kitten", "sitting") = ${lev}')
			win.append_console_log('console_stdlib', '[STRING] Jaro-Winkler("dwayne", "duane") = ${jaro:.4f}')
			win.push_toast('String Metrics', 'Levenshtein: ${lev}, Jaro-Winkler: ${jaro:.2f}', 'info', 3000)
		})

		win.end_row()
	})

	// Output Console Log
	win.add_console_view('console_stdlib', ['[STDLIB] V Standard Library wrapper subsystem initialized.'])
	win.set_control_width('console_stdlib', 700)
	win.set_control_height('console_stdlib', 140)

	win.run()
}

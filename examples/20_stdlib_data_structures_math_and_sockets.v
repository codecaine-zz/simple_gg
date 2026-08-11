module main

import simplegui

fn main() {
	// Create window (Width: 700px, Height: 600px)
	mut win := simplegui.new_simple_window('V Stdlib Integrations, Data Structures & Math', 700, 600)
	win.set_theme('Nord')

	win.add_heading('V Stdlib Integrations & Data Structures')
	win.add_subheading('Generic stacks, queues, min-heaps, thread sync, complex numbers, big integers, and string metrics')

	// 1. Generic Collections & Data Structures
	win.begin_group('1. Collections: Stack, Queue, Set, RingBuffer & MinHeap')
	win.begin_row('row_coll_btns')

	win.add_button('btn_test_stack', 'Test Stack (LIFO)')
	win.on_click('btn_test_stack', fn (mut win simplegui.SimpleWindow) {
		mut stack := simplegui.new_stack[string]()
		stack.push('Page 1')
		stack.push('Page 2')
		stack.push('Page 3')
		top := stack.pop() or { 'empty' }
		win.push_toast('Stack Test', 'Pushed 3 items, popped LIFO top: "${top}"', 'info', 3000)
	})

	win.add_button('btn_test_queue', 'Test Queue (FIFO)')
	win.on_click('btn_test_queue', fn (mut win simplegui.SimpleWindow) {
		mut queue := simplegui.new_queue[string]()
		queue.push('Task A')
		queue.push('Task B')
		queue.push('Task C')
		first := queue.pop() or { 'empty' }
		win.push_toast('Queue Test', 'Pushed 3 tasks, popped FIFO first: "${first}"', 'info', 3000)
	})

	win.add_button('btn_test_heap', 'Test Min-Heap')
	win.on_click('btn_test_heap', fn (mut win simplegui.SimpleWindow) {
		mut heap := simplegui.new_min_heap[int]()
		heap.push(42)
		heap.push(10)
		heap.push(99)
		heap.push(5)
		min_val := heap.pop() or { 0 }
		win.push_toast('Min-Heap Test', 'Inserted [42, 10, 99, 5], extracted min value: ${min_val}', 'success', 3000)
	})

	win.end_row()
	win.end_group()

	// 2. Advanced Math, BigInt & String Metrics
	win.begin_group('2. Advanced Math, Statistics & String Distance')
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
		win.push_toast('String Metrics', 'Levenshtein distance: ${lev}, Jaro-Winkler: ${jaro:.2f}', 'info', 3000)
	})

	win.end_row()
	win.end_group()

	// 3. Benchmarks & Thread Sync
	win.begin_group('3. Performance Benchmarks & Thread Sync')
	win.begin_row('row_sync_btns')

	win.add_button('btn_run_bench', 'Run Benchmark Test')
	win.on_click('btn_run_bench', fn (mut win simplegui.SimpleWindow) {
		mut sw := win.start_stopwatch()
		mut total := 0
		for i in 0 .. 1000000 {
			total += i
		}
		elapsed := sw.elapsed_ms()

		mut wg := simplegui.new_wait_group()
		wg.add(1)
		wg.done()
		wg.wait()

		win.append_console_log('console_stdlib', '[BENCHMARK] 1,000,000 iterations (sum=${total}) in ${elapsed} ms')
		win.push_toast('Benchmark Finished', 'Processed 1M iterations in ${elapsed} ms', 'success', 3000)
	})

	win.end_row()
	win.end_group()

	// Output Console Log
	win.add_console_view('console_stdlib', ['[STDLIB] V Standard Library wrapper subsystem initialized.'])

	win.fit_to_content()
	win.run()
}

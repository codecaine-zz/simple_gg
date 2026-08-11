module main

import simplegui
import time

fn main() {
	mut win := simplegui.new_simple_window('Interval Timers Showcase', 680, 650)
	win.set_theme('Nord')

	win.add_heading('Interval Timers & Delayed Timeouts')
	win.add_label('lbl_subtitle', 'Demonstrates recurring set_interval background updates, progress animation, clock polling, and set_timeout delays.')

	// 1. Live Digital Clock Section
	win.begin_group('1. Live Clock & Polling')
	win.add_label('lbl_clock', 'Current Time: Loading...')
	win.add_label('lbl_ticks', 'Ticks Elapsed: 0')
	win.end_group()

	// 2. Automated Progress Bar Timer Section
	win.begin_group('2. Progress Bar Auto-Increment')
	win.add_progress('prog_timer', 0)
	win.begin_row('row_timer_ctrls')
	win.add_button('btn_start', '[Play] Start Progress')
	win.add_button('btn_pause', '[Pause] Pause Progress')
	win.add_button('btn_reset', '[Reset] Reset Progress')
	win.end_row()
	win.end_group()

	// 3. One-Shot Timeout Section
	win.begin_group('3. One-Shot Timeout Alert')
	win.add_button('btn_delayed_alert', '[Timer] Trigger 3-Second Toast Delay')
	win.add_label('lbl_status', 'Status: Ready')
	win.end_group()

	mut tick_count := 0

	// Register recurring 1000ms clock timer
	win.set_interval('clock_timer', 1000, fn [mut tick_count] (mut win simplegui.SimpleWindow) {
		tick_count++
		t := time.now()
		win.set_text('lbl_clock', 'Current Time: ${t.format_ss()}')
		win.set_text('lbl_ticks', 'Ticks Elapsed: ${tick_count}')
	})

	// Register recurring 100ms progress increment timer
	win.set_interval('progress_timer', 100, fn (mut win simplegui.SimpleWindow) {
		mut val := win.get_value_int('prog_timer')
		val += 2
		if val > 100 {
			val = 0
		}
		win.set_value_int('prog_timer', val)
	})

	win.on_click('btn_start', fn (mut win simplegui.SimpleWindow) {
		win.start_timer('progress_timer')
		win.push_toast('Timer Resumed', 'Progress timer started.', 'info', 2000)
	})

	win.on_click('btn_pause', fn (mut win simplegui.SimpleWindow) {
		win.pause_timer('progress_timer')
		win.push_toast('Timer Paused', 'Progress timer paused.', 'warning', 2000)
	})

	win.on_click('btn_reset', fn (mut win simplegui.SimpleWindow) {
		win.set_value_int('prog_timer', 0)
		win.reset_timer('progress_timer')
		win.push_toast('Timer Reset', 'Progress reset to 0%.', 'info', 2000)
	})

	win.on_click('btn_delayed_alert', fn (mut win simplegui.SimpleWindow) {
		win.set_text('lbl_status', 'Status: Waiting 3 seconds...')
		win.set_timeout('alert_timeout', 3000, fn (mut win simplegui.SimpleWindow) {
			win.set_text('lbl_status', 'Status: Timeout Fired!')
			win.info('Timeout Triggered!', '3 seconds have elapsed since button click.')
		})
	})

	win.run()
}

module main

import simplegui

fn main() {
	// Create window (Width: 740px, Height: 540px)
	mut win := simplegui.new_simple_window('Extended OS System Calls & Resource Monitoring', 740, 540)
	win.set_theme('Apple Dark')

	win.add_heading('Extended OS System Calls & Hardware Subsystem')
	win.add_subheading('Monitor CPU, RAM pressure, environment variables, temp file creation, and zip archives')

	// 1. Hardware Specs & Live Metrics
	win.group('grp_hw', '1. Live Hardware & System Metrics', fn (mut win simplegui.SimpleWindow) {
		win.begin_row('row_metrics_btns')

		win.add_button('btn_poll_sys', 'Poll Hardware Metrics')
		win.on_click('btn_poll_sys', fn (mut win simplegui.SimpleWindow) {
			cpu_pct := win.get_cpu_usage_percent()
			l1, l5, l15 := win.get_load_average()
			mem_pres := win.get_memory_pressure()
			uptime := win.get_uptime_seconds()

			win.set_text('lbl_cpu_val', 'CPU Usage: ${cpu_pct:.1f}% | Load Avg: ${l1:.2f}, ${l5:.2f}, ${l15:.2f}')
			win.set_text('lbl_mem_val', 'Memory Pressure: ${mem_pres} | Uptime: ${uptime}s')
			win.push_toast('Metrics Polled', 'CPU: ${cpu_pct:.1f}%, Mem: ${mem_pres}', 'info', 2500)
		})

		win.end_row()
		win.add_label('lbl_cpu_val', 'CPU Usage: Click button to poll live telemetry')
		win.add_label('lbl_mem_val', 'Memory Pressure: Click button to poll live memory status')
	})

	// 2. Environment Variables & Audio
	win.group('grp_os_actions', '2. System Actions, Audio & Process Controls', fn (mut win simplegui.SimpleWindow) {
		win.begin_row('row_env_btns')

		win.add_button('btn_set_env', 'Set App Env Var')
		win.on_click('btn_set_env', fn (mut win simplegui.SimpleWindow) {
			win.set_env('SIMPLEGUI_DEMO_MODE', 'active')
			val := win.get_env('SIMPLEGUI_DEMO_MODE')
			win.push_toast('Environment Set', 'SIMPLEGUI_DEMO_MODE = ${val}', 'success', 3000)
		})

		win.add_button('btn_check_cmd', 'Check Git Installed')
		win.on_click('btn_check_cmd', fn (mut win simplegui.SimpleWindow) {
			has_git := win.exists_in_path('git')
			git_path := win.find_executable('git')
			win.push_toast('Command Check', 'git: ${has_git} (${git_path})', 'info', 2500)
		})

		win.add_button('btn_play_sound', 'Play System Beep')
		win.on_click('btn_play_sound', fn (mut win simplegui.SimpleWindow) {
			win.beep_n(1)
			win.push_toast('Audio Alert', 'Triggered system audio alert', 'info', 2000)
		})

		win.add_button('btn_temp_file', 'Create Temp File')
		win.on_click('btn_temp_file', fn (mut win simplegui.SimpleWindow) {
			tmp_path := win.create_temp_file('demo_', '.txt') or { return }
			win.write_file(tmp_path, 'Temporary file data content.')
			win.push_toast('Temp File', 'Created file: ${tmp_path}', 'success', 3000)
		})

		win.end_row()
	})

	win.run()
}

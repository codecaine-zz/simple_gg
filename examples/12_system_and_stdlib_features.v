module main

import simplegui

fn main() {
	mut win := simplegui.new_simple_window('System Call & Standard Library Toolkit', 960, 760)
	win.set_fullscreen(true)
	win.set_theme('Apple Dark')

	win.add_heading('💻 System Calls & Standard Library (sys.v / stdlib.v)')
	win.add_label('lbl_sub', 'Access OS execution, hardware specs, HTTP, cryptography, clipboard, and system paths.')

	// System Information Group
	win.group('grp_sys', '🖥️ System & Hardware Details', fn (mut win simplegui.SimpleWindow) {
		win.begin_row('row_sys_btns')
		win.add_button('btn_sys_info', 'Fetch Hardware Info')
		win.add_button('btn_notify', 'Trigger Desktop Notification')
		win.end_row()

		win.add_label('lbl_sys_out', 'Click a button above to inspect system specs...')
	})

	// Clipboard & Paths Group
	win.group('grp_clip', '📋 Clipboard & System Directory Lookup', fn (mut win simplegui.SimpleWindow) {
		win.add_form_field('Clip Input:', 'input_clip', 'Hello from simple_gg!')
		win.begin_row('row_clip_btns')
		win.add_button('btn_copy', 'Copy to Clipboard')
		win.add_button('btn_paste', 'Paste from Clipboard')
		win.end_row()
		win.add_label('lbl_clip_status', 'Status: Ready')
	})

	// Stdlib Helpers Group (Crypto, HTTP, Random)
	win.group('grp_stdlib', '🛠️ Standard Library (Crypto, RegEx & HTTP)', fn (mut win simplegui.SimpleWindow) {
		win.begin_row('row_stdlib_btns')
		win.add_button('btn_hash', 'Generate SHA256')
		win.add_button('btn_rand', 'Random Password')
		win.add_button('btn_http', 'Fetch HTTP IP')
		win.end_row()
		win.add_input('input_stdlib_out', 'Results will appear here...')
	})

	// Event Handlers
	win.on_click('btn_sys_info', fn (mut win simplegui.SimpleWindow) {
		cpu := win.get_cpu_info()
		ram := win.get_memory_info()
		cores := win.get_cpu_cores()
		home := win.get_system_path('home')
		win.set_text('lbl_sys_out', 'CPU: ${cpu} (${cores} cores) | RAM: ${ram} | Home: ${home}')
	})

	win.on_click('btn_notify', fn (mut win simplegui.SimpleWindow) {
		win.show_system_notification('simple_gg Alert', 'System extension call successful!')
		win.set_text('lbl_sys_out', 'System notification triggered successfully!')
	})

	win.on_click('btn_copy', fn (mut win simplegui.SimpleWindow) {
		val := win.get_text('input_clip')
		win.copy_to_clipboard(val)
		win.set_text('lbl_clip_status', 'Copied "${val}" to system clipboard!')
	})

	win.on_click('btn_paste', fn (mut win simplegui.SimpleWindow) {
		clip := win.get_clipboard_text()
		win.set_text('input_clip', clip)
		win.set_text('lbl_clip_status', 'Pasted "${clip}" from system clipboard!')
	})

	win.on_click('btn_hash', fn (mut win simplegui.SimpleWindow) {
		val := win.get_text('input_clip')
		hash := win.crypto_sha256(val)
		win.set_text('input_stdlib_out', 'SHA256: ${hash}')
	})

	win.on_click('btn_rand', fn (mut win simplegui.SimpleWindow) {
		pass := win.rand_string(16)
		win.set_text('input_stdlib_out', 'Generated Password: ${pass}')
	})

	win.on_click('btn_http', fn (mut win simplegui.SimpleWindow) {
		win.set_text('input_stdlib_out', 'Fetching IP via HTTP...')
		ip := win.http_get('https://api.ipify.org')
		win.set_text('input_stdlib_out', 'Public IP: ${ip}')
	})

	win.run()
}

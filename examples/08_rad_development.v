module main

import simplegui

fn main() {
	mut win := simplegui.new_window('RAD Rapid Application Development - simple_gg', 820, 520)
	win.set_theme('nord')

	win.add_header('RAD Desktop App Builder')
	win.add_text('Leveraging fluent batch operations, typed accessors, form JSON export, and OS system shortcuts!')

	win.begin_group('User Profile Form')
	win.add_form_field('Full Name:', 'txt_name', 'Ada Lovelace')
	win.add_form_field('Email Address:', 'txt_email', 'ada@lovelace.dev')
	win.add_form_dropdown('System Role:', 'dd_role', ['Administrator', 'Security Engineer', 'Core Developer', 'Auditor'], 'Administrator')
	win.end_group()

	win.begin_group('Batch & Form Operations')
	win.begin_row('row_form_btns')

	win.add_button('btn_save', 'Batch Read Form & Save')
	win.on_click('btn_save', fn (mut win simplegui.SimpleWindow) {
		form_map := win.get_all(['txt_name', 'txt_email', 'dd_role'])
		json_data := win.export_form_json(['txt_name', 'txt_email', 'dd_role'])
		win.info('Form Saved', 'Saved ${form_map.len} fields successfully!\nJSON: ${json_data}')
	})

	win.add_button('btn_clear', 'Clear Form')
	win.on_click('btn_clear', fn (mut win simplegui.SimpleWindow) {
		win.clear_all(['txt_name', 'txt_email'])
		win.info('Form Cleared', 'Reset input fields.')
	})

	win.add_button('btn_toggle', 'Toggle Controls (Disable/Enable)')
	win.on_click('btn_toggle', fn (mut win simplegui.SimpleWindow) {
		is_dis := win.get_control_enabled('txt_name')
		if is_dis {
			win.disable_controls(['txt_name', 'txt_email', 'dd_role'])
			win.warn('Form Locked', 'Inputs disabled.')
		} else {
			win.enable_controls(['txt_name', 'txt_email', 'dd_role'])
			win.info('Form Unlocked', 'Inputs enabled.')
		}
	})

	win.end_row()
	win.end_group()

	win.begin_group('System & Desktop Integration')
	win.begin_row('row_sys_btns')

	win.add_button('btn_notify', 'System Notification')
	win.on_click('btn_notify', fn (mut win simplegui.SimpleWindow) {
		win.show_system_notification('simple_gg RAD', 'Native OS desktop notification triggered!')
	})

	win.add_button('btn_clip', 'Copy Config Path to Clipboard')
	win.on_click('btn_clip', fn (mut win simplegui.SimpleWindow) {
		path := win.get_value('fp_config')
		win.copy_to_clipboard(path)
		win.info('Clipboard Updated', 'Copied path to clipboard!')
	})

	win.add_button('btn_ask', 'Native Confirm Ask Box')
	win.on_click('btn_ask', fn (mut win simplegui.SimpleWindow) {
		if win.ask('Confirm Action', 'Do you wish to open the project documentation online?') {
			win.open_url('https://github.com/codecaine-zz/vlang_simplegui')
		}
	})

	win.end_row()
	win.end_group()

	win.run()
}

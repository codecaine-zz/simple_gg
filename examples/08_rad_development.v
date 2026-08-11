module main

import simplegui

fn main() {
	mut win := simplegui.new_window('RAD Rapid Application Development - simple_gg', 800, 600)
	win.set_theme('nord')

	win.add_header('RAD Desktop App Builder')
	win.add_text('Leveraging fluent batch operations, typed accessors, form JSON export, and OS system shortcuts!')

	win.begin_group('User Profile Form')

	win.begin_row('row_names')
	win.add_form_input('txt_name', 'Full Name', 'Ada Lovelace')
	win.add_form_input('txt_email', 'Email Address', 'ada@lovelace.dev')
	win.end_row()

	win.begin_row('row_role')
	win.add_form_dropdown('dd_role', 'System Role', ['Administrator', 'Security Engineer', 'Core Developer', 'Auditor'], 'Administrator')
	win.add_form_file_picker('fp_config', 'Config File', win.get_system_path('documents'))
	win.end_row()

	win.end_group()

	win.begin_group('Batch & Form Operations')
	win.begin_row('row_form_btns')

	win.add_button('btn_save', 'Batch Read Form & Save')
	win.on_click('btn_save', fn (mut win simplegui.SimpleWindow) {
		form_map := win.get_all(['txt_name', 'txt_email', 'dd_role', 'fp_config'])
		json_data := win.export_form_json(['txt_name', 'txt_email', 'dd_role', 'fp_config'])
		win.info('Form Saved', 'Saved ${form_map.len} fields successfully!\nJSON: ${json_data}')
	})

	win.add_button('btn_clear', 'Clear Form')
	win.on_click('btn_clear', fn (mut win simplegui.SimpleWindow) {
		win.clear_all(['txt_name', 'txt_email', 'fp_config'])
		win.info('Form Cleared', 'Reset input fields.')
	})

	win.add_button('btn_toggle', 'Toggle Controls (Disable/Enable)')
	win.on_click('btn_toggle', fn (mut win simplegui.SimpleWindow) {
		is_dis := win.get_control_enabled('txt_name')
		if is_dis {
			win.disable_controls(['txt_name', 'txt_email', 'dd_role', 'fp_config'])
			win.warn('Form Locked', 'Inputs disabled.')
		} else {
			win.enable_controls(['txt_name', 'txt_email', 'dd_role', 'fp_config'])
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

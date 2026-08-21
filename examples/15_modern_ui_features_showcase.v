module main

import simplegui

fn main() {
	mut win := simplegui.new_simple_window('SimpleGUI Modern UI Improvements Showcase', 720, 560)
	win.set_theme('Apple Dark')

	win.add_heading('Modern UI Improvements Showcase')

	// 1. Tooltips
	win.add_button('btn_tip', '[Hover Me] Floating Tooltip Demo')
	win.set_control_tooltip('btn_tip', 'This is a rich floating tooltip overlay!')

	// 2. Modal Overlay Trigger
	win.add_button('btn_modal', '[Popup] Launch Backdrop Modal Dialog')
	win.on_click('btn_modal', fn (mut win simplegui.SimpleWindow) {
		win.show_modal(
			'Confirm Reset Action',
			'Are you sure you want to reset all user configuration settings?',
			'Confirm',
			'Cancel',
			fn (mut win simplegui.SimpleWindow) {
				win.push_toast('Action Confirmed', 'Settings have been reset.', 'success', 3000)
			}
		)
	})

	// 3. Live Form Validation Error Badges
	win.add_form_field('Email Address:', 'input_email', 'invalid_email')
	win.set_validation_error('input_email', 'Please enter a valid email address with @ domain')

	win.begin_row('row_val_btn')
	win.add_button('btn_validate', '[V] Fix Email')
	win.add_button('btn_clear_val', '[X] Clear Validation')
	win.end_row()

	win.on_click('btn_validate', fn (mut win simplegui.SimpleWindow) {
		win.set_text('input_email', 'ada@vlang.io')
		win.clear_validation_error('input_email')
		win.push_toast('Email Fixed', 'Valid email address entered', 'info', 2500)
	})

	win.on_click('btn_clear_val', fn (mut win simplegui.SimpleWindow) {
		win.clear_validation_error('input_email')
	})

	// 4. Skeleton Shimmer Loading Bar
	win.add_label('lbl_sk', 'Skeleton Shimmer Loading Bar:')
	win.add_skeleton('sk_loader', 400, 24)

	// 5. Tab Badges
	win.begin_tab_container('tabs_demo', ['Overview', 'Messages', 'Settings'])
	win.set_tab_badge('tabs_demo', 1, '5')
	win.set_tab_badge('tabs_demo', 2, 'NEW')

	win.begin_tab_page('tab_ov', 0)
	win.add_label('lbl_ov', 'Tab 1: Overview content panel')
	win.end_tab_page()

	win.begin_tab_page('tab_msg', 1)
	win.add_label('lbl_msg', 'Tab 2: Inbox messages panel (5 unread)')
	win.end_tab_page()

	win.begin_tab_page('tab_set', 2)
	win.add_label('lbl_set', 'Tab 3: Settings panel')
	win.end_tab_page()

	win.end_tab_container()

	// 6. Data Table Search Filtering
	headers := ['ID', 'User Name', 'Role', 'Status']
	rows := [
		['101', 'Ada Lovelace', 'System Architect', 'Active'],
		['102', 'Alan Turing', 'Lead Scientist', 'Active'],
		['103', 'Grace Hopper', 'Computer Scientist', 'Offline'],
	]
	win.add_table('tbl_search', headers, rows)
	win.set_control_width('tbl_search', 660)
	win.set_table_search_filter('tbl_search', 'Ada')

	win.run()
}

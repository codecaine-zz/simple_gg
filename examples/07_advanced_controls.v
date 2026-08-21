// Example 7: Advanced UI Controls & Window Shortcuts
// Demonstrates data tables, tab containers, tree views, file pickers, search bars, status badges, accordions, avatars, and Cmd+Q / Alt+F4 close hooks.

module main

import simplegui

fn main() {
	mut win := simplegui.new_simple_window('07 - Advanced Controls & Window Shortcuts', 640, 540)
	win.set_theme('Apple Dark')

	// Set window close listener callback
	win.on_close(fn (mut win simplegui.SimpleWindow) bool {
		println('Close shortcut triggered (Cmd+Q / Alt+F4)! Closing application window...')
		return true
	})

	win.add_heading('Advanced UI Controls Showcase')

	// Avatar and Status Badges
	win.begin_row('header_user')
	win.add_avatar('user_avatar', 'AL', 'Ada Lovelace (Lead Dev)')
	win.add_badge('status_online', 'Online', 'success')
	win.add_badge('status_build', 'v2.4.0-release', 'info')
	win.end_row()

	win.add_divider('Data Navigation')

	// Breadcrumb & Stepper
	win.add_breadcrumb('nav_path', ['Home', 'Workspace', 'Settings', 'Security'])
	win.add_stepper('setup_steps', ['Account', 'Permissions', 'API Keys', 'Finish'], 1)

	// Tabbed Container View
	win.begin_tab_container('tab_view', ['Data Table', 'Tree Explorer', 'Search & Tools'])

	// Tab 1: Data Table
	win.begin_tab_page('tab_table', 0)
	win.add_table('user_table', ['ID', 'Name', 'Role', 'Status'], [
		['101', 'Ada Lovelace', 'Administrator', 'Active'],
		['102', 'Alan Turing', 'Security Engineer', 'Active'],
		['103', 'Grace Hopper', 'System Architect', 'Away'],
		['104', 'Linus Torvalds', 'Core Developer', 'Busy'],
	])
	win.set_control_width('user_table', 580)
	win.on_row_click('user_table', fn (mut win simplegui.SimpleWindow) {
		selected := win.get_table_selected_row('user_table')
		println('Clicked table row #${selected}')
		win.show_toast('Row Selected', 'Selected table index ${selected}')
	})
	win.end_tab_page()

	// Tab 2: Tree Explorer
	win.begin_tab_page('tab_tree', 1)
	win.add_tree_view('file_tree', [
		simplegui.TreeNode{
			id: 'root_src'
			text: 'src/'
			icon: '[DIR]'
			expanded: true
			children: [
				simplegui.TreeNode{ id: 'f1', text: 'main.v', icon: '[FILE]' },
				simplegui.TreeNode{ id: 'f2', text: 'simplegui.v', icon: '[FILE]' },
			]
		},
		simplegui.TreeNode{
			id: 'root_assets'
			text: 'assets/'
			icon: '[DIR]'
			expanded: false
			children: [
				simplegui.TreeNode{ id: 'a1', text: 'logo.png', icon: '[IMG]' },
			]
		},
	])
	win.end_tab_page()

	// Tab 3: Search & File Tools
	win.begin_tab_page('tab_tools', 2)
	win.add_form_search('Search Query:', 'search_input', 'Type to search repositories...')
	win.add_form_file_picker('Target Bundle:', 'file_picker_input', '/usr/local/bin/app')
	win.add_accordion('acc_details', 'Advanced Configuration Details', 'Config options, environment flags, and debug output parameters go here.', false)
	win.end_tab_page()

	win.end_tab_container()

	win.add_divider('Application Actions')

	win.begin_row('action_buttons')
	win.add_button('btn_toast', 'Show Toast Notification')
	win.on_click('btn_toast', fn (mut win simplegui.SimpleWindow) {
		win.show_toast('System Event', 'Task finished successfully!')
	})
	win.add_button('btn_close', 'Close Window (Cmd+Q / Alt+F4)')
	win.on_click('btn_close', fn (mut win simplegui.SimpleWindow) {
		win.close()
	})
	win.end_row()

	win.run()
}

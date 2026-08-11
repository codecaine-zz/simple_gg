// Example 10: More Window UI Controls
// Demonstrates newly added developer/user-requested controls: icon buttons, toolbars,
// hyperlinks, checklists, chip groups (tag selectors), time pickers, password strength
// meters, and dropdown menu buttons.

module main

import simplegui

fn main() {
	mut win := simplegui.new_simple_window('10 - More Window UI Controls', 760, 760)
	win.set_theme('Apple Dark')

	win.add_heading('More Window UI Controls Showcase')

	// 1. Toolbar & Icon Buttons
	win.add_divider('Toolbar & Icon Buttons')
	win.add_toolbar('main_toolbar', [
		simplegui.ToolbarItem{
			icon: '[New]'
			tooltip: 'Create a new document'
			on_click: fn (mut win simplegui.SimpleWindow) {
				win.show_toast('Toolbar', 'New document created')
			}
		},
		simplegui.ToolbarItem{
			icon: '[Save]'
			tooltip: 'Save the current document'
			on_click: fn (mut win simplegui.SimpleWindow) {
				win.show_toast('Toolbar', 'Document saved')
			}
		},
		simplegui.ToolbarItem{
			icon: '[Del]'
			tooltip: 'Delete the current document'
			on_click: fn (mut win simplegui.SimpleWindow) {
				win.show_toast('Toolbar', 'Document deleted')
			}
		},
	])

	// 2. Hyperlink
	win.add_divider('Hyperlink')
	win.add_link('docs_link', 'Open SimpleGUI Documentation', 'https://vlang.io')

	// 3. Dropdown Menu Button
	win.add_divider('Menu Button')
	win.add_menu_button('file_menu', 'Actions', ['Export CSV', 'Export JSON', 'Print', 'Archive'])
	win.on_change('file_menu', fn (mut win simplegui.SimpleWindow) {
		selected := win.get_menu_selected('file_menu')
		win.show_toast('Menu Action', 'You picked: ${selected}')
	})

	// 4. Multi-select Checklist
	win.add_divider('Checklist (Multi-Select)')
	win.add_checklist('perms_checklist', ['Read', 'Write', 'Execute', 'Delete', 'Share'], [
		'Read',
		'Write',
	])
	win.on_change('perms_checklist', fn (mut win simplegui.SimpleWindow) {
		selected := win.get_checklist_selected('perms_checklist')
		println('Checklist selection: ${selected}')
	})

	// 5. Chip Group (Tag Selector)
	win.add_divider('Chip Group (Tag Selector)')
	win.add_chip_group('tags_chip_group', ['Urgent', 'Bug', 'Feature', 'Design', 'Backend'], [
		'Bug',
	])
	win.on_change('tags_chip_group', fn (mut win simplegui.SimpleWindow) {
		selected := win.get_chip_selected('tags_chip_group')
		println('Chip selection: ${selected}')
	})

	// 6. Time Picker
	win.add_divider('Time Picker')
	win.add_form_time_picker('Meeting Time:', 'meeting_time', '09:30')

	// 7. Password Strength Meter
	win.add_divider('Password Strength Meter')
	win.add_form_password('New Password:', 'new_password', '')
	win.add_password_strength('pwd_strength_meter', 'new_password')

	win.run()
}

// Example 10: More Window UI Controls
// Demonstrates newly added developer/user-requested controls: standard top menu bars, icon buttons,
// toolbars, hyperlinks, checklists, chip groups (tag selectors), time pickers, password strength
// meters, and dropdown menu buttons.

module main

import simplegui

fn main() {
	mut win := simplegui.new_simple_window('10 - More Window UI Controls', 700, 600)
	win.set_theme('Apple Dark')

	// Standard Desktop Top Menu Bar
	win.add_menu('File', [
		simplegui.MenuItem{
			title: 'New Document'
			shortcut: 'Ctrl+N'
			on_select: fn (mut win simplegui.SimpleWindow) {
				win.show_toast('Menu Bar', 'Created new document')
			}
		},
		simplegui.MenuItem{
			title: 'Open File...'
			shortcut: 'Ctrl+O'
			on_select: fn (mut win simplegui.SimpleWindow) {
				win.show_toast('Menu Bar', 'Opened file dialog')
			}
		},
		simplegui.MenuItem{
			is_separator: true
		},
		simplegui.MenuItem{
			title: 'Save'
			shortcut: 'Ctrl+S'
			on_select: fn (mut win simplegui.SimpleWindow) {
				win.show_toast('Menu Bar', 'Document saved successfully')
			}
		},
		simplegui.MenuItem{
			title: 'Exit'
			shortcut: 'Ctrl+Q'
			on_select: fn (mut win simplegui.SimpleWindow) {
				win.close()
			}
		},
	])

	win.add_menu('Edit', [
		simplegui.MenuItem{
			title: 'Undo'
			shortcut: 'Ctrl+Z'
			on_select: fn (mut win simplegui.SimpleWindow) {
				win.show_toast('Menu Bar', 'Undo action triggered')
			}
		},
		simplegui.MenuItem{
			title: 'Redo'
			shortcut: 'Ctrl+Y'
			on_select: fn (mut win simplegui.SimpleWindow) {
				win.show_toast('Menu Bar', 'Redo action triggered')
			}
		},
		simplegui.MenuItem{
			is_separator: true
		},
		simplegui.MenuItem{
			title: 'Preferences'
			shortcut: 'Ctrl+,'
			on_select: fn (mut win simplegui.SimpleWindow) {
				win.show_toast('Menu Bar', 'Opened Preferences')
			}
		},
	])

	win.add_menu('View', [
		simplegui.MenuItem{
			title: 'Toggle Theme'
			on_select: fn (mut win simplegui.SimpleWindow) {
				win.toggle_window_theme()
			}
		},
		simplegui.MenuItem{
			title: 'Toggle Fullscreen'
			shortcut: 'F11'
			on_select: fn (mut win simplegui.SimpleWindow) {
				win.toggle_fullscreen()
			}
		},
	])

	win.add_menu('Help', [
		simplegui.MenuItem{
			title: 'About SimpleGUI'
			on_select: fn (mut win simplegui.SimpleWindow) {
				win.show_dialog_info('About SimpleGUI', 'SimpleGUI - Modern Immediate-Mode GUI Framework for V')
			}
		},
	])

	win.add_heading('More Window UI Controls Showcase')

	// 1. Actions, Toolbar & Tags
	win.group('grp_tools', 'Toolbar, Actions & Tags', fn (mut win simplegui.SimpleWindow) {
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

		win.add_menu_button('file_menu', 'Export & Actions', ['Export CSV', 'Export JSON', 'Print', 'Archive'])
		win.on_change('file_menu', fn (mut win simplegui.SimpleWindow, selected string) {
			win.show_toast('Menu Action', 'You picked: ${selected}')
		})

		win.add_chip_group('tags_chip_group', ['Urgent', 'Bug', 'Feature', 'Design'], ['Bug'])
		win.add_link('docs_link', 'Open SimpleGUI Documentation', 'https://vlang.io')
	})

	// 2. Inputs, Permissions & Security
	win.group('grp_security', 'Permissions & Form Inputs', fn (mut win simplegui.SimpleWindow) {
		win.add_checklist('perms_checklist', ['Read Access', 'Write Access', 'Execute Script', 'Admin Role'], ['Read Access', 'Write Access'])
		win.add_form_time_picker('Meeting Time:', 'meeting_time', '09:30')
		win.add_form_password('New Password:', 'new_password', 'p@ssword123')
		win.add_password_strength('pwd_strength_meter', 'new_password')
	})

	win.run()
}


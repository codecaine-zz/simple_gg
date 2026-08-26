module simplegui

struct TestContext {
mut:
	str_val  string
	bool_val bool
}

fn test_theme_dropdown_on_change() {
	mut win := new_simple_window('Test Theme Change', 400, 300)
	themes := list_themes()
	win.add_dropdown('theme_picker', themes, 'Apple Light')

	mut ctx := &TestContext{}
	win.on_change('theme_picker', fn [mut ctx] (mut win SimpleWindow, selected string) {
		ctx.str_val = selected
		win.set_theme(selected)
	})

	mut ctrl := win.get_control_ptr('theme_picker') or { panic('missing control') }
	assert ctrl.text_value == 'Apple Light'

	// Simulate dropdown selection change
	ctrl.text_value = 'Nord'
	trigger_control_change(mut win, ctrl)

	assert ctx.str_val == 'Nord'
	assert win.theme.name == 'Nord'
}

fn test_tab_navigation_updates_focused_control() {
	mut win := new_simple_window('Test Tab Focus', 400, 300)
	win.add_input('first_name', 'Alan')
	win.add_input('last_name', 'Turing')
	win.add_input('designation', 'Senior Cryptographer')

	// Focus first control
	win.focus_control('first_name')
	assert win.focused_control == 'first_name'
	assert win.control('first_name').is_focused == true

	// Press Tab -> advances focus to last_name
	win.focus_next_control()
	assert win.focused_control == 'last_name'
	assert win.control('first_name').is_focused == false
	assert win.control('last_name').is_focused == true

	// Press Tab again -> advances focus to designation
	win.focus_next_control()
	assert win.focused_control == 'designation'
	assert win.control('last_name').is_focused == false
	assert win.control('designation').is_focused == true

	// Press Shift+Tab -> reverses focus to last_name
	win.focus_prev_control()
	assert win.focused_control == 'last_name'
	assert win.control('last_name').is_focused == true
}

fn test_date_picker_interactive() {
	mut win := new_simple_window('Test Date Picker', 400, 300)
	win.add_date_picker('event_date', '2026-08-11')

	mut ctx := &TestContext{}
	win.on_change('event_date', fn [mut ctx] (mut win SimpleWindow, new_val string) {
		ctx.str_val = new_val
	})

	mut ctrl := win.get_control_ptr('event_date') or { panic('missing date picker') }
	assert ctrl.kind == 'date_picker'
	assert ctrl.text_value == '2026-08-11'

	// Modify date value and trigger change
	ctrl.text_value = '2026-12-25'
	trigger_control_change(mut win, ctrl)

	assert ctx.str_val == '2026-12-25'
}

fn test_menubar_creation_and_selection() {
	mut win := new_simple_window('Test Menu Bar', 500, 400)
	mut ctx := &TestContext{}

	win.add_menu('File', [
		MenuItem{
			title: 'New'
			shortcut: 'Ctrl+N'
			on_select: fn [mut ctx] (mut win SimpleWindow) {
				ctx.bool_val = true
			}
		},
		MenuItem{
			is_separator: true
		},
		MenuItem{
			title: 'Exit'
			shortcut: 'Ctrl+Q'
		},
	])

	assert win.menu_bar_visible == true
	assert win.menu_categories.len == 1
	assert win.menu_categories[0].title == 'File'
	assert win.menu_categories[0].items.len == 3
	assert win.menu_categories[0].items[1].is_separator == true

	// Simulate selecting the menu item
	cb := win.menu_categories[0].items[0].on_select
	assert cb != unsafe { nil }
	cb(mut win)
	assert ctx.bool_val == true
}

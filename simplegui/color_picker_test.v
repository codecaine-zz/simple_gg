module simplegui

fn test_color_picker_registration() {
	mut win := new_simple_window('Test Window', 600, 400)
	win.add_color_picker('picker_accent', 'Theme Accent Color:', '#0a84ff')
	
	ctrl := win.control('picker_accent')
	assert ctrl.name == 'picker_accent'
	assert ctrl.kind == 'color_picker'
	assert ctrl.title == 'Theme Accent Color:'
	assert ctrl.text_value == '#0a84ff'
}

fn test_form_color_picker_registration() {
	mut win := new_simple_window('Test Window', 600, 400)
	win.add_form_color_picker('Theme Accent:', 'form_color', '#ff9500')

	ctrl := win.control('form_color')
	assert ctrl.name == 'form_color'
	assert ctrl.kind == 'color_picker'
	assert ctrl.text_value == '#ff9500'
}



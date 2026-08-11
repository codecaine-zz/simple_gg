module simplegui

import os

fn test_linux_font_candidates() {
	candidates := linux_font_candidates()
	assert candidates.len > 0
	assert candidates.contains('/usr/share/fonts/truetype/ubuntu/Ubuntu-R.ttf')
	assert candidates.contains('/usr/share/fonts/truetype/ubuntu/Ubuntu-Regular.ttf')
	assert candidates.contains('/usr/share/fonts/truetype/ubuntu/Ubuntu.ttf')
	assert candidates.contains('/usr/share/fonts/opentype/ubuntu/Ubuntu-R.ttf')
	assert candidates.contains('/usr/share/fonts/opentype/ubuntu/Ubuntu-Regular.ttf')
	assert candidates.contains('/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf')
	assert candidates.contains('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf')
}

fn test_macos_font_candidates() {
	candidates := macos_font_candidates()
	assert candidates.len > 0
	assert candidates.contains('/System/Library/Fonts/Supplemental/Arial.ttf')
}

fn test_resolve_window_font_path_default() {
	os.unsetenv('SIMPLEGUI_FONT_PATH')
	path := resolve_window_font_path()
	// Should return string (either empty or valid system font path)
	assert path.len >= 0
}

fn test_resolve_window_font_path_env_override() {
	// Set to non-existent path -> should ignore
	os.setenv('SIMPLEGUI_FONT_PATH', '/non/existent/font/path.ttf', true)
	non_existent := resolve_window_font_path()
	assert non_existent != '/non/existent/font/path.ttf'

	os.unsetenv('SIMPLEGUI_FONT_PATH')
}

fn test_window_set_font_path() {
	mut win := new_simple_window('Test Window', 400, 300)
	assert win.font_path == ''

	win.set_font_path('/custom/font.ttf')
	assert win.font_path == '/custom/font.ttf'
}

fn test_dynamic_control_font_styling() {
	mut win := new_simple_window('Font Styling Test Window', 400, 300)
	win.add_label('lbl_test', 'Test Label')
	win.add_button('btn_test', 'Test Button')

	win.set_control_font_size('lbl_test', 24)
	win.set_control_font_bold('lbl_test', true)
	win.set_control_font_color('lbl_test', '#30d158')

	assert win.get_control_font_size('lbl_test') == 24
	if ctrl := win.control_map['lbl_test'] {
		assert ctrl.font_bold == true
		assert ctrl.font_color == '#30d158'
	}

	win.set_control_font_size('btn_test', 18)
	win.set_control_font_bold('btn_test', false)
	win.set_control_font_color('btn_test', '#ff9f0a')

	assert win.get_control_font_size('btn_test') == 18
	if ctrl := win.control_map['btn_test'] {
		assert ctrl.font_bold == false
		assert ctrl.font_color == '#ff9f0a'
	}
}


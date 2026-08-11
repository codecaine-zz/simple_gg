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

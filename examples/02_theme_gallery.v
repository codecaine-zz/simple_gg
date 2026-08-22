// Example 2: Theme Gallery Demo
module main

import simplegui

fn main() {
	mut win := simplegui.new_simple_window('02 - Theme Gallery Demo', 560, 360)
	win.set_theme('Catppuccin Mocha')
	win.add_heading('Theme Gallery')

	all_themes := simplegui.list_themes()
	win.add_form_dropdown('Theme:', 'theme_picker', all_themes, 'Catppuccin Mocha')

	win.on_change('theme_picker', fn (mut win simplegui.SimpleWindow, selected_theme string) {
		win.set_theme(selected_theme)
		println('Applied theme: ${selected_theme}')
	})

	win.add_form_field('Sample Input:', 'sample', 'Theme preview text')
	win.add_switch('sample_sw', 'Sample Switch Toggle', true)
	win.add_slider('sample_sld', 80)
	win.add_rating('sample_rating', 5)

	win.add_button('btn_toggle', 'Toggle Light/Dark Theme')
	win.on_click('btn_toggle', fn (mut win simplegui.SimpleWindow) {
		win.toggle_window_theme()
	})

	win.run()
}

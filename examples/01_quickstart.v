// Example 1: Quickstart Starter App
module main

import simplegui

fn main() {
	mut win := simplegui.new_simple_window('01 - Quickstart Demo', 520, 260)
	win.set_theme('Apple Dark')
	win.add_heading('Welcome to SimpleGUI!')

	win.add_form_field('Your Name:', 'username', 'Ada Lovelace')
	win.add_checkbox('agree', 'I agree to the Terms of Service', true)

	win.add_button('btn_greet', 'Say Hello')
	win.on_click('btn_greet', fn (mut win simplegui.SimpleWindow) {
		name := win.get_text('username')
		agreed := win.get_bool('agree')
		println('Hello, ${name}! Terms agreed: ${agreed}')
	})

	win.run()
}

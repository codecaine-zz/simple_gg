// Example 5: Nameless Control Shortcuts
module main

import simplegui

fn main() {
	mut win := simplegui.new_simple_window('05 - Nameless Shortcuts', 500, 300)
	win.set_theme('GitHub Dark')

	win.add_heading('Nameless Control Shortcuts')

	win.add_label('lbl1', 'Enter your name:')
	win.input('Grace Hopper')

	win.add_label('lbl2', 'Choose quantity:')
	win.number(5)

	win.checkbox('Send email confirmation', true)

	win.button('Process Order')
	win.on_click('default_button', fn (mut win simplegui.SimpleWindow) {
		name := win.get_input()
		qty := win.get_number()
		confirmed := win.get_checkbox()
		println('Order Processed for ${name}: ${qty} items (Confirmed: ${confirmed})')
	})

	win.run()
}

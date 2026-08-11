// Example 3: Layout Containers Demo
module main

import simplegui

fn main() {
	mut win := simplegui.new_simple_window('03 - Layout Containers Demo', 640, 420)
	win.set_theme('Nord')

	win.add_heading('Layout & Group Containers')

	win.group('section_1', 'Personal Details', fn (mut win simplegui.SimpleWindow) {
		win.add_form_field('First Name:', 'fn', 'Alan')
		win.add_form_field('Last Name:', 'ln', 'Turing')
	})

	win.begin_row('row_actions')
	win.add_button('b1', 'Option A')
	win.add_button('b2', 'Option B')
	win.add_button('b3', 'Option C')
	win.end_row()

	win.begin_grid('grid_2col', 2, 12)
	win.add_checkbox('chk1', 'Enable Feature 1', true)
	win.add_checkbox('chk2', 'Enable Feature 2', false)
	win.end_grid()

	win.run()
}

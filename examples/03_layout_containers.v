// Example 3: Layout Containers Demo
module main

import simplegui

fn main() {
	mut win := simplegui.new_simple_window('03 - Layout Containers Demo', 660, 460)
	win.set_theme('Nord')

	win.add_heading('Layout & Group Containers')

	win.group('section_1', 'Personal Profile Details', fn (mut win simplegui.SimpleWindow) {
		win.add_form_field('First Name:', 'fn', 'Alan')
		win.add_form_field('Last Name:', 'ln', 'Turing')
		win.add_form_field('Designation:', 'desig', 'Senior Cryptographer')
	})

	win.group('section_2', 'Account Preferences & Actions', fn (mut win simplegui.SimpleWindow) {
		win.begin_grid('grid_2col', 2, 12)
		win.add_checkbox('chk1', 'Enable Hardware Accel', true)
		win.add_checkbox('chk2', 'Telemetry Sync', false)
		win.end_grid()

		win.begin_row('row_actions')
		win.add_button('b1', 'Save Profile')
		win.add_button('b2', 'Export JSON')
		win.add_button('b3', 'Reset')
		win.end_row()
	})

	win.run()
}

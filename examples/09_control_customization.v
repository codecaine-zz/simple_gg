module main

import simplegui

fn main() {
	mut win := simplegui.new_simple_window('Control Customization & Geometry Demo', 720, 600)
	win.set_theme('Apple Dark')

	win.add_heading('Control Customization & Geometry Demo')

	// 1. Fluent Chaining on &Control via win.control('name')
	win.add_label('lbl_fluent', '1. Fluent Control Chaining')
	win.add_button('btn_custom', 'Styled Hero Button')
	win.control('btn_custom')
		.set_width(280)
		.set_height(42)
		.set_margin_xy(0, 8)
		.set_padding_xy(16, 10)
		.set_font_size(16)
		.set_font_bold(true)
		.set_corner_radius(10.0)
		.set_bg_color('#0a84ff')
		.set_font_color('#ffffff')
		.set_border(2.0, '#58a6ff')
		.set_tooltip('Configured with fluent Control method chaining')

	// 2. Window-Level Control Setters
	win.add_label('lbl_win_setters', '2. Dynamic Window Control Setters')
	win.add_input('inp_name', 'John Doe')
	win.set_control_width('inp_name', 340)
	win.set_control_margin_xy('inp_name', 10, 6)
	win.set_control_padding_xy('inp_name', 12, 8)
	win.set_control_font_size('inp_name', 15)
	win.set_control_tooltip('inp_name', 'Enter your full legal name')

	win.add_button('btn_action', 'Secondary Action')
	win.set_control_width('btn_action', 220)
	win.set_control_height('btn_action', 38)
	win.set_control_corner_radius('btn_action', 6.0)
	win.set_control_bg_color('btn_action', '#34c759')
	win.set_control_margin_trbl('btn_action', 8, 0, 12, 0)

	win.run()
}

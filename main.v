module main

import simplegui

fn main() {
	mut win := simplegui.new_simple_window('Cross-Platform SimpleGUI (V gg)', 640, 560)
	win.set_theme('Apple Dark')
	win.add_heading('SimpleGUI Cross-Platform')
	win.add_form_field('Name:', 'username', 'Ada Lovelace')
	win.add_form_password('Password:', 'pwd', 'secret123')
	win.add_checkbox('subscribe', 'Subscribe to updates', true)
	win.add_switch('notify', 'Enable Desktop Notifications', true)
	win.add_slider('volume', 75)
	win.add_form_dropdown('Theme:', 'theme_select', [
		'Apple Dark',
		'Apple Light',
		'Cyberpunk',
		'Nord',
		'Dracula',
		'Catppuccin Mocha',
		'GitHub Dark',
	], 'Apple Dark')
	win.on_change('theme_select', fn (mut win simplegui.SimpleWindow) {
		sel := win.get_text('theme_select')
		win.set_theme(sel)
	})
	win.add_rating('star_rating', 4)
	win.add_metric_card('kpi', 'System Status', '99.9% Uptime', '+0.4%', 'All operational')
	win.begin_row('action_row')
	win.add_button('btn_save', 'Save Profile')
	win.on_click('btn_save', fn (mut win simplegui.SimpleWindow) {
		user := win.get_text('username')
		sub := win.get_bool('subscribe')
		vol := win.get_value_int('volume')
		rating := win.get_value_int('star_rating')
		println('Saved! User: ${user}, Subscribed: ${sub}, Volume: ${vol}, Rating: ${rating}')
	})
	win.add_button('btn_reset', 'Reset')
	win.on_click('btn_reset', fn (mut win simplegui.SimpleWindow) {
		win.set_text('username', 'Guest')
		win.set_bool('subscribe', false)
		win.set_value_int('volume', 50)
	})
	win.end_row()

	win.run()
}

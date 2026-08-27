// Example 4: Widgets & Form Controls Demo
module main

import simplegui

fn main() {
	mut win := simplegui.new_simple_window('04 - Widgets & Form Controls', 620, 630)
	win.set_theme('Dracula')

	win.add_heading('Form Controls & Component Gallery')

	win.add_form_field('Username:', 'user', 'developer_v')
	win.add_form_password('Password:', 'pass', 'supersecret')
	win.add_form_number('Quantity:', 'qty', 10)
	win.add_form_slider('Volume Level:', 'vol', 65)
	win.add_form_switch('Enable Sync:', 'sync', 'Cloud Sync', true)
	win.add_form_date_picker('Release Date:', 'r_date', '2026-08-11')

	win.add_rating('user_rating', 5)
	win.add_alert_banner('alert1', 'System Notification', 'Settings saved successfully!', 'info')
	win.add_metric_card('kpi1', 'Storage Usage', '42.5 GB / 100 GB', '42.5%', 'Optimal performance')

	win.begin_row('row_submit')
	win.add_button('btn_submit', 'Submit Form')
	win.on_click('btn_submit', fn (mut win simplegui.SimpleWindow) {
		user := win.get_text('user')
		qty := win.get_value_int('qty')
		vol := win.get_value_int('vol')
		rating := win.get_value_int('user_rating')
		r_date := win.get_text('r_date')
		if win.is_valid_date_str(r_date) {
			win.push_toast('Form Submitted', 'User: ${user} | Date: ${r_date} | Rating: ${rating}', 'success', 3000)
		} else {
			win.push_toast('Validation Warning', 'Please provide a valid date (YYYY-MM-DD)', 'warning', 3000)
		}
		println('Form Submitted! User: ${user}, Date: ${r_date}, Qty: ${qty}, Vol: ${vol}, Rating: ${rating}')
	})
	win.end_row()

	win.run()
}

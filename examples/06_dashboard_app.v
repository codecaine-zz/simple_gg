// Example 6: Interactive Application Dashboard
// A complete, real-world dashboard featuring metrics, trend charts, settings, and callbacks.

module main

import simplegui

fn main() {
	mut win := simplegui.new_simple_window('06 - Application Dashboard', 680, 500)
	win.set_theme('Apple Dark')

	win.add_heading('Analytics & System Dashboard')

	// Metric Cards in Grid
	win.begin_grid('kpi_grid', 2, 12)
	win.add_metric_card('kpi1', 'Active Sessions', '1,420 Users', '+12.4%', 'Real-time active users')
	win.add_metric_card('kpi2', 'Server Load', '38% CPU', '-2.1%', '8 cores operational')
	win.end_grid()

	// Line Trend Chart
	win.add_label('lbl_chart', 'Performance Trend (Last 7 Days):')
	win.add_chart('trend_chart', 'line', 90)
	win.set_chart_data('trend_chart', [20.0, 35.0, 45.0, 30.0, 65.0, 80.0, 95.0])

	// Controls & Action Row
	win.group('grp_config', 'Environment Settings', fn (mut win simplegui.SimpleWindow) {
		win.add_form_dropdown('Region:', 'region_select', ['US-East (N. Virginia)', 'US-West (Oregon)', 'EU-Central (Frankfurt)', 'AP-Southeast (Tokyo)'], 'US-East (N. Virginia)')
		win.add_switch('auto_scale', 'Auto-Scaling Active', true)
		win.add_slider('max_instances', 50)
	})

	win.begin_row('row_actions')
	win.add_button('btn_refresh', 'Refresh Metrics')
	win.on_click('btn_refresh', fn (mut win simplegui.SimpleWindow) {
		win.set_chart_data('trend_chart', [15.0, 40.0, 60.0, 25.0, 70.0, 85.0, 99.0])
		println('Metrics refreshed!')
	})
	win.add_button('btn_deploy', 'Deploy Changes')
	win.on_click('btn_deploy', fn (mut win simplegui.SimpleWindow) {
		reg := win.get_text('region_select')
		scale := win.get_bool('auto_scale')
		instances := win.get_value_int('max_instances')
		println('Deploying to ${reg}! Auto-scale: ${scale}, Max instances: ${instances}')
	})
	win.end_row()

	win.run()
}

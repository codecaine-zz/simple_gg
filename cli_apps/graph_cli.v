module main

import simplecli

fn main() {
	mut app := simplecli.new_app('graph-cli', '1.0.0')
	app.set_description('ASCII Bar & Trend Chart Terminal Visualizer CLI')

	app.add_flag_string('data', 'd', '15,32,48,65,92,78,54,88,100', 'Comma-separated dataset values')
	app.add_flag_string('labels', 'l', 'Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep', 'Comma-separated category labels')
	app.add_flag_string('title', 't', 'Monthly Throughput (kReq/s)', 'Chart title')
	app.add_flag_bool('interactive', 'x', false, 'Launch interactive graph visualizer')

	app.parse_cli() or { return }

	app.banner('Graph Studio CLI', 'v1.0.0 - Terminal ASCII Chart & Data Visualizer')

	if app.get_flag_bool('interactive') {
		run_interactive(mut app)
		return
	}

	data_str := app.get_flag_string('data')
	labels_str := app.get_flag_string('labels')
	title := app.get_flag_string('title')

	render_bar_chart(mut app, title, data_str, labels_str)
}

fn render_bar_chart(mut app simplecli.SimpleCli, title string, data_str string, labels_str string) {
	data_parts := data_str.split(',')
	label_parts := labels_str.split(',')

	mut max_val := 0.0
	mut values := []f64{}
	for p in data_parts {
		v := p.trim_space().f64()
		values << v
		if v > max_val {
			max_val = v
		}
	}

	if max_val == 0.0 {
		max_val = 1.0
	}

	app.panel(title, 'Scale: 0 to ${max_val:.1f} units')

	max_bar_width := 45
	for i, val in values {
		lbl := if i < label_parts.len { label_parts[i].trim_space() } else { 'Item ${i + 1}' }
		bar_len := int((val / max_val) * f64(max_bar_width))
		mut bar_str := ''
		for _ in 0 .. bar_len {
			bar_str += '█'
		}
		println('  ${lbl:12} │ ${app.cyan(bar_str)} ${val:.1f}')
	}
	println('')
}

fn run_interactive(mut app simplecli.SimpleCli) {
	app.panel('Graph Visualizer REPL', 'Render instant ASCII bar charts directly in terminal.')
	title := app.prompt('Chart Title', 'Server Latency Distribution')
	data := app.prompt('Dataset values (comma-separated)', '12, 18, 25, 42, 60, 55, 30')
	labels := app.prompt('Labels (comma-separated)', 'P10, P25, P50, P75, P90, P95, P99')
	render_bar_chart(mut app, title, data, labels)
}

module main

import simplecli

fn main() {
	mut app := simplecli.new_app('dot-cli', '1.0.0')
	app.set_description('Graphviz DOT Diagram & Network Graph Renderer CLI')

	app.add_flag_string('input', 'i', '', 'Input .dot graph source file path')
	app.add_flag_string('output', 'o', 'diagram.png', 'Output rendered image file path (png, svg, pdf)')
	app.add_flag_string('format', 'f', 'png', 'Output format: png, svg, pdf')
	app.add_flag_bool('interactive', 'x', false, 'Launch interactive Graphviz wizard')

	app.parse_cli() or { return }

	app.banner('Graphviz DOT Studio CLI', 'v1.0.0 - Diagram Rendering Engine')

	has_dot := app.command_exists('dot')
	if !has_dot {
		app.warn('dot binary not found. Install via "brew install graphviz".')
	}

	if app.get_flag_bool('interactive') {
		run_interactive(mut app, has_dot)
		return
	}

	input_path := app.get_flag_string('input')
	if input_path.len == 0 {
		app.warn('No .dot file specified. Run with -i <graph.dot> or -x for interactive mode.')
		app.print_help()
		return
	}

	if !app.file_exists(input_path) {
		app.error('File not found: ${input_path}')
		return
	}

	out_path := app.get_flag_string('output')
	fmt := app.get_flag_string('format')

	app.info('Rendering DOT diagram to ${out_path}...')
	app.reset_timer()
	out, code := app.exec_safe('dot', ['-T' + fmt, input_path, '-o', out_path])
	if code == 0 {
		app.success('Graph rendered in ${app.elapsed_ms()} ms -> ${out_path}')
	} else {
		app.error('Graphviz error (code ${code}):\n${out}')
	}
}

fn run_interactive(mut app simplecli.SimpleCli, has_dot bool) {
	app.panel('Graphviz DOT Wizard', 'Render diagrams from DOT graph specifications.')
	sample_dot := 'digraph G {
  rankdir=LR;
  node [shape=box, style=filled, fillcolor=lightblue];
  Client -> "API Gateway" [label="HTTPS"];
  "API Gateway" -> "Auth Service";
  "API Gateway" -> "Order Service";
  "Order Service" -> "PostgreSQL DB" [label="TCP 5432"];
}'
	app.info('Sample DOT Graph:\n${sample_dot}')
	temp_dot := 'temp_graph.dot'
	app.write_file(temp_dot, sample_dot)
	if has_dot {
		app.exec_safe('dot', ['-Tpng', temp_dot, '-o', 'sample_diagram.png'])
		app.success('Rendered sample diagram to sample_diagram.png')
	} else {
		app.warn('Install Graphviz via "brew install graphviz" to render images.')
	}
}

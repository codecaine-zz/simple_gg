module main

import simplecli

fn main() {
	mut app := simplecli.new_app('sed-cli', '1.0.0')
	app.set_description('Sed Stream Editor & Find/Replace CLI')

	app.add_flag_string('expr', 'e', 's/foo/bar/g', 'Sed substitution or command expression')
	app.add_flag_string('input', 'i', '', 'Input file path to process')
	app.add_flag_bool('interactive', 'x', false, 'Launch interactive Sed wizard')

	app.parse_cli() or { return }

	app.banner('Sed Studio CLI', 'v1.0.0 - Stream Transformation Engine')

	if app.get_flag_bool('interactive') {
		run_interactive(mut app)
		return
	}

	expr := app.get_flag_string('expr')
	input_file := app.get_flag_string('input')

	mut args := ['-e', expr]
	if input_file.len > 0 {
		args << input_file
	}

	out, code := app.exec_safe('sed', args)
	if code == 0 {
		println(out)
	} else {
		app.error('Sed execution failed (code ${code}):\n${out}')
	}
}

fn run_interactive(mut app simplecli.SimpleCli) {
	app.panel('Sed Stream Transformation', 'Quickly test regex search & replace expressions.')
	text := app.prompt('Enter sample line', 'http://localhost:8080/api/v1')
	find_str := app.prompt('Find string', 'localhost:8080')
	replace_str := app.prompt('Replace string', 'production.corp.internal')

	expr := 's/${find_str}/${replace_str}/g'
	out, _ := app.exec("echo '${text}' | sed '${expr}'")
	app.success('Transformed Result:')
	println(out)
}

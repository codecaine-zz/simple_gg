module main

import simplecli

fn main() {
	mut app := simplecli.new_app('cut-cli', '1.0.0')
	app.set_description('Cut Column & Field Delimiter Extractor CLI')

	app.add_flag_string('delimiter', 'd', '\t', 'Field delimiter character (e.g. , or :)')
	app.add_flag_string('fields', 'f', '1', 'Field index or list to extract (e.g. 1, 1-3, 2,4)')
	app.add_flag_string('input', 'i', '', 'Input file path to extract columns from')
	app.add_flag_bool('interactive', 'x', false, 'Launch interactive column extractor')

	app.parse_cli() or { return }

	app.banner('Cut Studio CLI', 'v1.0.0 - Column & Field Extractor Engine')

	if app.get_flag_bool('interactive') {
		run_interactive(mut app)
		return
	}

	delim := app.get_flag_string('delimiter')
	fields := app.get_flag_string('fields')
	input_file := app.get_flag_string('input')

	mut args := ['-d', delim, '-f', fields]
	if input_file.len > 0 {
		args << input_file
	}

	out, code := app.exec_safe('cut', args)
	if code == 0 {
		println(out)
	} else {
		app.error('Cut execution failed (code ${code}):\n${out}')
	}
}

fn run_interactive(mut app simplecli.SimpleCli) {
	app.panel('Cut Column Extractor', 'Extract specified fields from delimited datasets.')
	sample := "root:x:0:0:root:/root:/bin/bash\ndaemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin\nuser:x:1000:1000:User:/home/user:/bin/zsh"
	app.info('Sample Data (delimiter: ":"):\n${sample}')
	field := app.prompt('Enter field number to extract (1=username, 6=homedir, 7=shell)', '1')

	out, _ := app.exec("echo '${sample}' | cut -d: -f${field}")
	app.success('Extracted Column:\n${out}')
}

module main

import simplecli

fn main() {
	mut app := simplecli.new_app('sd-cli', '1.0.0')
	app.set_description('Intuitive Search & Replace (sd) CLI')

	app.add_flag_string('find', 'f', '', 'Find search pattern')
	app.add_flag_string('replace', 'r', '', 'Replacement string')
	app.add_flag_string('input', 'i', '', 'Input file path to modify in-place or display')
	app.add_flag_string('text', 't', '', 'Direct text input string')
	app.add_flag_bool('interactive', 'x', false, 'Launch interactive Search & Replace')

	app.parse_cli() or { return }

	app.banner('SD Studio CLI', 'v1.0.0 - Fast Search & Replace Engine')

	if app.get_flag_bool('interactive') {
		run_interactive(mut app)
		return
	}

	find_pat := app.get_flag_string('find')
	replace_str := app.get_flag_string('replace')
	direct_text := app.get_flag_string('text')
	input_file := app.get_flag_string('input')

	if find_pat.len == 0 {
		app.warn('No find pattern specified. Use -f <pattern> -r <replacement> or -x for interactive mode.')
		app.print_help()
		return
	}

	if input_file.len > 0 {
		if !app.file_exists(input_file) {
			app.error('File not found: ${input_file}')
			return
		}
		content := app.read_file(input_file)
		modified := content.replace(find_pat, replace_str)
		app.write_file(input_file, modified)
		app.success('Modified ${input_file} (replaced "${find_pat}" with "${replace_str}")')
		return
	}

	raw := if direct_text.len > 0 { direct_text } else { 'Welcome to development server on localhost:3000' }
	out := raw.replace(find_pat, replace_str)
	app.success('Output:')
	println(out)
}

fn run_interactive(mut app simplecli.SimpleCli) {
	app.panel('Search & Replace REPL', 'Fast string and token replacement.')
	sample := app.prompt('Input text', 'const API_URL = "http://localhost:8000";')
	find_str := app.prompt('Find text', 'http://localhost:8000')
	replace_str := app.prompt('Replace text', 'https://api.vlang.io')

	res := sample.replace(find_str, replace_str)
	app.success('Result:\n${res}')
}

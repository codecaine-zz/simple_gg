module main

import simplecli

fn main() {
	mut app := simplecli.new_app('regex-cli', '1.0.0')
	app.set_description('Regular Expression Tester & Match Extractor CLI')

	app.add_flag_string('pattern', 'p', '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$', 'Regular expression pattern')
	app.add_flag_string('text', 't', 'contact@vlang.io', 'Text to match against')
	app.add_flag_bool('interactive', 'x', false, 'Launch interactive Regex tester')

	app.parse_cli() or { return }

	app.banner('Regex Studio CLI', 'v1.0.0 - Regular Expression Workbench')

	if app.get_flag_bool('interactive') {
		run_interactive(mut app)
		return
	}

	pattern := app.get_flag_string('pattern')
	text := app.get_flag_string('text')

	app.reset_timer()
	matches := app.regex_match(pattern, text)
	elapsed := app.elapsed_ms()

	app.print_kv({
		'Regex Pattern': pattern,
		'Target Text': text,
		'Match Result': if matches { app.green('MATCHED (true)') } else { app.red('NO MATCH (false)') },
		'Evaluation Time': '${elapsed} ms',
	})
}

fn run_interactive(mut app simplecli.SimpleCli) {
	app.panel('Regex Interactive Tester', 'Test regular expressions against custom test vectors.')
	for {
		pat := app.prompt('Enter Regex Pattern', '^[0-9]{3}-[0-9]{3}-[0-9]{4}$')
		if pat == 'exit' || pat == 'q' {
			break
		}
		sample := app.prompt('Enter Test String', '555-123-4567')
		is_match := app.regex_match(pat, sample)
		if is_match {
			app.success('✓ String matches pattern.')
		} else {
			app.error('✖ String does NOT match pattern.')
		}
		if !app.confirm('Test another pattern?', true) {
			break
		}
	}
}

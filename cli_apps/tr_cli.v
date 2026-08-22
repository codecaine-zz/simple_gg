module main

import simplecli

fn main() {
	mut app := simplecli.new_app('tr-cli', '1.0.0')
	app.set_description('Character Translation, Squeezing & Deletion CLI')

	app.add_flag_string('from', 'f', '', 'Source character set to replace')
	app.add_flag_string('to', 't', '', 'Destination character set')
	app.add_flag_bool('upper', 'u', false, 'Translate text to UPPERCASE')
	app.add_flag_bool('lower', 'l', false, 'Translate text to lowercase')
	app.add_flag_string('delete', 'd', '', 'Delete specified characters')
	app.add_flag_string('input', 'i', '', 'Input text string')
	app.add_flag_bool('interactive', 'x', false, 'Launch interactive translator')

	app.parse_cli() or { return }

	app.banner('TR Studio CLI', 'v1.0.0 - Character Translation Engine')

	if app.get_flag_bool('interactive') {
		run_interactive(mut app)
		return
	}

	mut raw_input := app.get_flag_string('input')
	if raw_input.len == 0 {
		raw_input = 'Hello World from SimpleCLI!'
	}

	if app.get_flag_bool('upper') {
		app.success('Uppercase:\n' + raw_input.to_upper())
		return
	}

	if app.get_flag_bool('lower') {
		app.success('Lowercase:\n' + raw_input.to_lower())
		return
	}

	del_set := app.get_flag_string('delete')
	if del_set.len > 0 {
		out, _ := app.exec("echo '${raw_input}' | tr -d '${del_set}'")
		app.success('After Deletion:\n${out}')
		return
	}

	from_set := app.get_flag_string('from')
	to_set := app.get_flag_string('to')
	if from_set.len > 0 && to_set.len > 0 {
		out, _ := app.exec("echo '${raw_input}' | tr '${from_set}' '${to_set}'")
		app.success('Translation:\n${out}')
		return
	}

	app.println(app.dim('Run with --upper, --lower, -d <chars>, or -f <set1> -t <set2>.'))
}

fn run_interactive(mut app simplecli.SimpleCli) {
	app.panel('TR Character Workbench', 'Quick character set substitutions.')
	sample := app.prompt('Enter string', 'API_KEY=123-abc-XYZ')
	choice := app.select('Action:', ['To Uppercase', 'To Lowercase', 'Replace dashes with underscores'])

	match choice {
		'To Uppercase' {
			app.success(sample.to_upper())
		}
		'To Lowercase' {
			app.success(sample.to_lower())
		}
		else {
			app.success(sample.replace('-', '_'))
		}
	}
}

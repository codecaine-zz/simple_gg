module main

import simplecli

fn main() {
	mut app := simplecli.new_app('gawk-cli', '1.0.0')
	app.set_description('GAWK / AWK Pattern Scanning & Data Processing CLI')

	app.add_flag_string('script', 'e', '{print $0}', 'AWK program script expression')
	app.add_flag_string('delimiter', 'F', '', 'Field separator character (e.g. , or \t)')
	app.add_flag_string('input', 'i', '', 'Input file path (or stdin)')
	app.add_flag_bool('interactive', 'x', false, 'Launch interactive GAWK recipe wizard')

	app.parse_cli() or { return }

	app.banner('GAWK Studio CLI', 'v1.0.0 - Stream Pattern Processor & Aggregator')

	if app.get_flag_bool('interactive') {
		run_interactive(mut app)
		return
	}

	awk_script := app.get_flag_string('script')
	delim := app.get_flag_string('delimiter')
	input_file := app.get_flag_string('input')

	mut args := []string{}
	if delim.len > 0 {
		args << ['-F', delim]
	}
	args << awk_script
	if input_file.len > 0 {
		args << input_file
	}

	app_cmd := if app.command_exists('gawk') { 'gawk' } else { 'awk' }
	out, code := app.exec_safe(app_cmd, args)
	if code == 0 {
		println(out)
	} else {
		app.error('AWK execution failed (code ${code}):\n${out}')
	}
}

fn run_interactive(mut app simplecli.SimpleCli) {
	app.panel('GAWK Recipe Wizard', 'Select common text filtering recipes.')
	choice := app.select('Recipe:', [
		'Print Column 1 ($1)',
		'Sum Numeric Values in Column 2',
		'Print Lines Matching Pattern',
		'Count Total Number of Lines (NR)',
	])

	sample := 'user1 450 active\nuser2 820 pending\nuser3 120 active'
	app.info('Sample Data:\n${sample}')
	cmd := if app.command_exists('gawk') { 'gawk' } else { 'awk' }

	match choice {
		'Print Column 1 ($1)' {
			out, _ := app.exec("echo '${sample}' | ${cmd} '{print \$1}'")
			println(out)
		}
		'Sum Numeric Values in Column 2' {
			out, _ := app.exec("echo '${sample}' | ${cmd} '{sum += \$2} END {print \"Total Sum:\", sum}'")
			println(out)
		}
		'Count Total Number of Lines (NR)' {
			out, _ := app.exec("echo '${sample}' | ${cmd} 'END {print NR, \"lines\"}'")
			println(out)
		}
		else {
			out, _ := app.exec("echo '${sample}' | ${cmd} '/active/ {print \$0}'")
			println(out)
		}
	}
}

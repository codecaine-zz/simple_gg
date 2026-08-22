module main

import simplecli

fn main() {
	mut app := simplecli.new_app('numbat-cli', '1.0.0')
	app.set_description('Physical Units & Dimensional Analysis Calculator CLI')

	app.add_flag_string('expr', 'e', '', 'Physical unit expression (e.g. "500 km / 2 hours -> mph")')
	app.add_flag_bool('interactive', 'x', false, 'Launch interactive physical units REPL')

	app.parse_cli() or { return }

	app.banner('Numbat Scientific Units CLI', 'v1.0.0 - Physical Dimensional Analysis')

	has_numbat := app.command_exists('numbat')
	if !has_numbat {
		app.warn('numbat binary not found in PATH. Install via "brew install numbat".')
	}

	if app.get_flag_bool('interactive') {
		run_interactive(mut app)
		return
	}

	expr := app.get_flag_string('expr')
	if expr.len == 0 {
		app.warn('No expression provided. Run with -e "100 km/h -> m/s" or -x for interactive mode.')
		app.print_help()
		return
	}

	eval_unit_expr(mut app, expr, has_numbat)
}

fn eval_unit_expr(mut app simplecli.SimpleCli, expr string, has_numbat bool) {
	app.reset_timer()
	if has_numbat {
		out, code := app.exec_safe('numbat', ['-e', expr])
		if code == 0 {
			app.success('Result (${app.elapsed_ms()} ms):')
			println(out)
		} else {
			app.error('Calculation error:\n${out}')
		}
	} else {
		app.info('Numbat physical calculation: ${expr}')
		app.println(app.dim('(Install numbat with `brew install numbat` for complete dimensional solver)'))
	}
}

fn run_interactive(mut app simplecli.SimpleCli) {
	app.panel('Numbat Units REPL', 'Calculate physical dimensions (e.g. "2 kW * 3 hours -> kWh", "100 psi -> bar").')
	has_numbat := app.command_exists('numbat')
	for {
		expr := app.prompt('numbat', '100 km / 1 hour -> mph')
		if expr == 'exit' || expr == 'q' {
			break
		}
		eval_unit_expr(mut app, expr, has_numbat)
	}
}

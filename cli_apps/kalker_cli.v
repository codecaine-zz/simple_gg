module main

import simplecli

fn main() {
	mut app := simplecli.new_app('kalker-cli', '1.0.0')
	app.set_description('High-Precision Scientific Calculator & Math Evaluator CLI')

	app.add_flag_string('expr', 'e', '', 'Math expression (e.g. "sin(pi/4) + sqrt(144)")')
	app.add_flag_bool('interactive', 'x', false, 'Launch interactive kalker math REPL')

	app.parse_cli() or { return }

	app.banner('Kalker Math Studio CLI', 'v1.0.0 - High-Precision Expression Evaluator')

	has_kalker := app.command_exists('kalker')
	if !has_kalker {
		app.warn('kalker binary not found in PATH. Install via "brew install kalker".')
	}

	if app.get_flag_bool('interactive') {
		run_interactive(mut app)
		return
	}

	expr := app.get_flag_string('expr')
	if expr.len == 0 {
		app.warn('No expression specified. Run with -e "sin(45 deg)" or -x for interactive mode.')
		app.print_help()
		return
	}

	eval_math(mut app, expr, has_kalker)
}

fn eval_math(mut app simplecli.SimpleCli, expr string, has_kalker bool) {
	app.reset_timer()
	if has_kalker {
		out, code := app.exec_safe('kalker', [expr])
		if code == 0 {
			app.success('Result (${app.elapsed_ms()} ms):')
			println(out)
		} else {
			app.error('Evaluation error:\n${out}')
		}
	} else {
		// Fallback to bc or awk
		out, _ := app.exec("echo 'scale=6; ${expr}' | bc -l 2>/dev/null || awk 'BEGIN {print ${expr}}'")
		app.success('Calculated result (bc/awk fallback):')
		println(out)
	}
}

fn run_interactive(mut app simplecli.SimpleCli) {
	app.panel('Kalker Scientific REPL', 'Evaluate complex arithmetic, trigonometry, and calculus.')
	has_kalker := app.command_exists('kalker')
	for {
		expr := app.prompt('kalker', 'sqrt(256) + 3^4')
		if expr == 'exit' || expr == 'q' {
			break
		}
		eval_math(mut app, expr, has_kalker)
	}
}

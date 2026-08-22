module main

import simplegui
import os
import time

// -------------------------------------------------------------
// Data Structures
// -------------------------------------------------------------

struct CalculationHistoryItem {
mut:
	timestamp  string
	expression string
	result     string
	mode       string
}

struct AppState {
mut:
	precision      int
	angle_unit     string
	struct_mode    string
	base_mode      string
	history        []CalculationHistoryItem
	active_tab     string
	last_result    string
}

// -------------------------------------------------------------
// Qalc Execution Helpers
// -------------------------------------------------------------

fn sanitize_qalc_script(script string) string {
	lines := script.split_into_lines()
	mut clean_lines := []string{}
	for line in lines {
		trimmed := line.trim_space()
		if trimmed == '' || trimmed.starts_with('#') || trimmed.starts_with('//') {
			continue
		}
		clean_lines << trimmed
	}
	return clean_lines.join('\n')
}

fn run_qalc(expr string, precision int, angle string, base string, fractional string) (string, string) {
	clean_expr := sanitize_qalc_script(expr).trim_space()
	if clean_expr == '' {
		return '', ''
	}

	mut args := ['-t'] // Terse result mode
	if precision > 0 {
		args << '-s'
		args << 'precision ${precision}'
	}
	if angle != '' {
		args << '-s'
		args << 'angle ${angle}'
	}
	if base != '' && base != 'Decimal (10)' {
		b_arg := match base {
			'Hexadecimal (16)' { 'hex' }
			'Binary (2)' { 'bin' }
			'Octal (8)' { 'oct' }
			'Roman' { 'roman' }
			'Duodecimal (12)' { 'duo' }
			'Sexagesimal (60)' { 'sexa' }
			else { 'dec' }
		}
		args << '-s'
		args << 'base ${b_arg}'
	}
	if fractional != '' {
		f_arg := match fractional {
			'Exact Fractions' { 'fractions on' }
			'Decimals Only' { 'fractions off' }
			'Mixed Numbers' { 'fractions combined' }
			else { 'fractions off' }
		}
		args << '-s'
		args << f_arg
	}

	args << clean_expr

	res := simplegui.exec_safe('qalc', args)
	output := res.output.trim_space()
	return output, output
}

// -------------------------------------------------------------
// Main Application Entry Point
// -------------------------------------------------------------

fn main() {
	println('Starting SimpleGUI - Qalc Studio Pro (libqalculate)...')

	mut win := simplegui.new_simple_window('Qalc Studio Pro -- Advanced Symbolic Math & Unit Converter', 1140, 910)
	win.set_fullscreen(true)
	win.restore_saved_theme()
	win.set_spacing(6)
	win.set_padding(14)

	mut state := &AppState{
		precision: 12
		angle_unit: 'rad'
		struct_mode: 'exact'
		base_mode: 'Decimal (10)'
		history: []CalculationHistoryItem{}
		active_tab: ' Calculator & Scratchpad'
		last_result: '0'
	}

	// -------------------------------------------------------------
	// Header & Controls
	// -------------------------------------------------------------
	win.begin_row('row_header')
	win.add_heading('Qalc Studio Pro')

	win.add_label('lbl_prec', 'Precision:')
	win.add_dropdown('dd_precision', ['10 digits', '12 digits', '20 digits', '30 digits', '50 digits', '100 digits'], '12 digits')
	win.set_control_width('dd_precision', 110)

	win.add_label('lbl_angle', 'Angle:')
	win.add_dropdown('dd_angle', ['Radians (rad)', 'Degrees (deg)', 'Gradians (gra)'], 'Radians (rad)')
	win.set_control_width('dd_angle', 130)

	win.add_label('lbl_theme_hdr', 'Theme:')
	saved_theme := simplegui.get_saved_theme()
	win.add_dropdown('dd_theme_selector', simplegui.list_themes(), saved_theme)
	win.set_control_width('dd_theme_selector', 150)
	win.end_row()

	// -------------------------------------------------------------
	// Navigation Workspace Tabs
	// -------------------------------------------------------------
	win.add_tabs('main_tabs', [
		' Calculator & Scratchpad',
		' Algebra & Equation Solver',
		' Calculus & Analysis',
		' Unit & Currency Converter',
		' Matrices & Linear Algebra',
		' Formula & Preset Recipes',
		' Calculation History'
	])

	// -------------------------------------------------------------
	// Top Live Result Banner
	// -------------------------------------------------------------
	win.begin_group_box('grp_result_banner', 'Live Result Display')
	win.begin_row('row_result_disp')
	win.add_input('txt_live_result', '0')
	win.set_control_width('txt_live_result', 820)
	win.set_control_font_name('txt_live_result', 'Menlo')
	win.set_control_font_size('txt_live_result', 18)

	win.add_button('btn_copy_res', 'Copy Result')
	win.add_button('btn_ans_to_input', '<- Use as Ans')
	win.end_row()
	win.end_group_box()

	// -------------------------------------------------------------
	// Tab 1: Calculator & Scratchpad
	// -------------------------------------------------------------
	win.begin_group_box('pane_calc', 'Interactive Expression Calculator & Keypad')

	win.begin_row('row_quick_input')
	win.add_label('lbl_expr_prompt', 'Expression:')
	win.add_input('txt_calc_input', '50 * sin(pi / 4) + sqrt(144)')
	win.set_control_width('txt_calc_input', 600)
	win.set_control_font_name('txt_calc_input', 'Menlo')
	win.set_control_font_size('txt_calc_input', 14)

	win.add_button('btn_calc_eval', 'EVALUATE')
	win.add_button('btn_calc_clear', 'Clear')
	win.end_row()

	// Interactive Scientific Keypad Rows
	win.begin_row('row_pad_1')
	win.add_button('btn_k_pi', 'pi')
	win.add_button('btn_k_e', 'e')
	win.add_button('btn_k_sqrt', 'sqrtx')
	win.add_button('btn_k_pow', 'x^y')
	win.add_button('btn_k_sin', 'sin(x)')
	win.add_button('btn_k_cos', 'cos(x)')
	win.add_button('btn_k_tan', 'tan(x)')
	win.add_button('btn_k_ln', 'ln(x)')
	win.add_button('btn_k_log', 'log(x)')
	win.add_button('btn_k_fact', 'n!')
	win.end_row()

	win.begin_row('row_pad_2')
	win.add_button('btn_k_asin', 'asin')
	win.add_button('btn_k_acos', 'acos')
	win.add_button('btn_k_atan', 'atan')
	win.add_button('btn_k_abs', 'abs(x)')
	win.add_button('btn_k_diff', 'diff()')
	win.add_button('btn_k_integ', 'integrate()')
	win.add_button('btn_k_solve', 'solve()')
	win.add_button('btn_k_sum', 'sum()')
	win.add_button('btn_k_deg', 'to deg')
	win.add_button('btn_k_rad', 'to rad')
	win.end_row()

	// Multi-Line Scratchpad
	win.add_label('lbl_scratch_hdr', 'Multi-Line Calculation Scratchpad (Evaluate line by line or batch):')
	win.add_textarea('txt_scratchpad', 'radius = 15 cm\nheight = 40 cm\nvolume = pi * radius^2 * height\nvolume to liters\n100 USD to EUR\n50 mph to km/h\nsin(45 deg) + cos(45 deg)\nsolve(3*x^2 - 12 = 0, x)')
	win.set_control_height('txt_scratchpad', 240)
	win.set_control_font_name('txt_scratchpad', 'Menlo')
	win.set_control_font_size('txt_scratchpad', 13)

	win.begin_row('row_scratch_actions')
	win.add_button('btn_eval_scratch', 'Run Entire Scratchpad')
	win.add_button('btn_clear_scratch', 'Clear Scratchpad')
	win.add_button('btn_copy_scratch', 'Copy Scratchpad')
	win.end_row()

	win.end_group_box()

	// -------------------------------------------------------------
	// Tab 2: Algebra & Equation Solver
	// -------------------------------------------------------------
	win.begin_group_box('pane_algebra', 'Symbolic Algebra, Roots & Equation Solver')
	win.begin_row('row_alg_input')
	win.add_label('lbl_eq_prompt', 'Equation / Expression:')
	win.add_input('txt_alg_eq', '2*x^2 + 5*x - 12 = 0')
	win.set_control_width('txt_alg_eq', 450)
	win.set_control_font_name('txt_alg_eq', 'Menlo')

	win.add_label('lbl_alg_var', 'Variable:')
	win.add_input('txt_alg_var', 'x')
	win.set_control_width('txt_alg_var', 80)

	win.add_button('btn_alg_solve', 'SOLVE EQUATION')
	win.add_button('btn_alg_factor', 'Factor')
	win.add_button('btn_alg_expand', 'Expand')
	win.end_row()

	win.add_textarea('txt_alg_output', 'Enter an equation (e.g. 2*x^2 + 5*x - 12 = 0 or 3*x + 4*y = 10, 2*x - y = 3) and click SOLVE.\n')
	win.set_control_height('txt_alg_output', 380)
	win.set_control_font_name('txt_alg_output', 'Menlo')
	win.set_control_font_size('txt_alg_output', 13)
	win.end_group_box()

	// -------------------------------------------------------------
	// Tab 3: Calculus & Analysis
	// -------------------------------------------------------------
	win.begin_group_box('pane_calculus', 'Calculus: Derivatives, Integrals, Limits & Series')
	win.begin_row('row_calc_input')
	win.add_label('lbl_calc_func', 'Function f(x):')
	win.add_input('txt_calc_func', 'x^3 * sin(x) + exp(-x)')
	win.set_control_width('txt_calc_func', 380)
	win.set_control_font_name('txt_calc_func', 'Menlo')

	win.add_button('btn_calc_diff', 'd/dx Derivative')
	win.add_button('btn_calc_integ', 'int Indefinite Integral')
	win.add_button('btn_calc_def_integ', 'int Definite Integral')
	win.add_button('btn_calc_taylor', 'Taylor Series')
	win.end_row()

	win.add_textarea('txt_calc_output', 'Calculus expressions and step evaluations will appear here.\n')
	win.set_control_height('txt_calc_output', 400)
	win.set_control_font_name('txt_calc_output', 'Menlo')
	win.set_control_font_size('txt_calc_output', 13)
	win.end_group_box()

	// -------------------------------------------------------------
	// Tab 4: Unit & Currency Converter
	// -------------------------------------------------------------
	win.begin_group_box('pane_units', 'Universal Physical Unit & Currency Conversion')
	win.begin_row('row_unit_inputs')
	win.add_label('lbl_u_val', 'Amount:')
	win.add_input('txt_unit_amount', '100')
	win.set_control_width('txt_unit_amount', 120)

	win.add_label('lbl_u_from', 'From:')
	win.add_input('txt_unit_from', 'USD')
	win.set_control_width('txt_unit_from', 140)

	win.add_label('lbl_u_to', 'To:')
	win.add_input('txt_unit_to', 'EUR')
	win.set_control_width('txt_unit_to', 140)

	win.add_button('btn_unit_convert', 'CONVERT')
	win.end_row()

	// Quick Preset Category Buttons
	win.begin_row('row_unit_presets')
	win.add_button('btn_up_usd_eur', 'USD  EUR')
	win.add_button('btn_up_usd_gbp', 'USD  GBP')
	win.add_button('btn_up_usd_jpy', 'USD  JPY')
	win.add_button('btn_up_usd_btc', 'USD  BTC')
	win.add_button('btn_up_mph_kmh', 'mph  km/h')
	win.add_button('btn_up_c_f', 'deg C   deg F')
	win.add_button('btn_up_gb_mb', 'GB  MiB')
	win.add_button('btn_up_kg_lbs', 'kg  lbs')
	win.end_row()

	win.add_textarea('txt_unit_output', 'Unit conversion results and exact conversion factors will be displayed here.\n')
	win.set_control_height('txt_unit_output', 380)
	win.set_control_font_name('txt_unit_output', 'Menlo')
	win.set_control_font_size('txt_unit_output', 13)
	win.end_group_box()

	// -------------------------------------------------------------
	// Tab 5: Matrices & Linear Algebra
	// -------------------------------------------------------------
	win.begin_group_box('pane_matrix', 'Matrix & Vector Linear Algebra')
	win.begin_row('row_mat_input')
	win.add_label('lbl_mat_prompt', 'Matrix Expression:')
	win.add_input('txt_matrix_expr', '[1, 2; 3, 4] * [5; 6]')
	win.set_control_width('txt_matrix_expr', 480)
	win.set_control_font_name('txt_matrix_expr', 'Menlo')

	win.add_button('btn_mat_eval', 'Calculate Matrix')
	win.add_button('btn_mat_det', 'Determinant')
	win.add_button('btn_mat_inv', 'Inverse')
	win.add_button('btn_mat_trans', 'Transpose')
	win.end_row()

	win.add_textarea('txt_matrix_output', 'Enter matrices in format [1, 2; 3, 4] where semicolons separate rows.\n')
	win.set_control_height('txt_matrix_output', 400)
	win.set_control_font_name('txt_matrix_output', 'Menlo')
	win.set_control_font_size('txt_matrix_output', 13)
	win.end_group_box()

	// -------------------------------------------------------------
	// Tab 6: Formulas & Preset Recipes
	// -------------------------------------------------------------
	win.begin_group_box('pane_recipes', 'Formula Library & Scientific Recipes')
	win.begin_row('row_rec_1')
	win.add_button('btn_rec_euler', 'Euler: e^(i*pi) + 1')
	win.add_button('btn_rec_rel', 'Einstein: E = m*c^2')
	win.add_button('btn_rec_quad', 'Quadratic: 2*x^2 + 5*x - 3 = 0')
	win.add_button('btn_rec_grav', 'Earth Gravity on 70kg')
	win.add_button('btn_rec_coul', 'Coulomb\'s Law')
	win.end_row()

	win.begin_row('row_rec_2')
	win.add_button('btn_rec_kin', 'Kinetic: 0.5 * m * v^2')
	win.add_button('btn_rec_ideal', 'Ideal Gas: 1 mol at 25 deg C')
	win.add_button('btn_rec_black', 'Financial Discounting')
	win.add_button('btn_rec_shannon', 'Shannon Entropy')
	win.add_button('btn_rec_fourier', 'Definite Integral')
	win.end_row()

	win.add_textarea('txt_recipes_output', 'Click any formula preset above to load and evaluate the expression.\n')
	win.set_control_height('txt_recipes_output', 380)
	win.set_control_font_name('txt_recipes_output', 'Menlo')
	win.set_control_font_size('txt_recipes_output', 13)
	win.end_group_box()

	// -------------------------------------------------------------
	// Tab 7: Calculation History
	// -------------------------------------------------------------
	win.begin_group_box('pane_history', 'Calculation Ledger & Session History')
	win.begin_row('row_hist_actions')
	win.add_button('btn_copy_history', 'Copy Entire Ledger')
	win.add_button('btn_clear_history', 'Clear History')
	win.add_button('btn_export_history', 'Export Ledger to Text...')
	win.end_row()

	win.add_textarea('txt_history_ledger', 'Session calculation history will be recorded here.\n')
	win.set_control_height('txt_history_ledger', 400)
	win.set_control_font_name('txt_history_ledger', 'Menlo')
	win.set_control_font_size('txt_history_ledger', 13)
	win.end_group_box()

	// Initially hide inactive tab panes
	win.set_control_visible('pane_algebra', false)
	win.set_control_visible('pane_calculus', false)
	win.set_control_visible('pane_units', false)
	win.set_control_visible('pane_matrix', false)
	win.set_control_visible('pane_recipes', false)
	win.set_control_visible('pane_history', false)

	// -------------------------------------------------------------
	// Status Bar Footer
	// -------------------------------------------------------------
	win.begin_row('row_footer')
	win.add_label('lbl_status_bar', 'Ready. Powered by qalc (libqalculate 5.12+).')
	win.end_row()

	// -------------------------------------------------------------
	// History Updater Helper
	// -------------------------------------------------------------
	update_history_view := fn [state] (mut w simplegui.SimpleWindow) {
		mut ledger := []string{}
		ledger << '========================================================================'
		ledger << ' QALC STUDIO PRO -- CALCULATION LEDGER'
		ledger << '========================================================================'
		for item in state.history {
			ledger << '[${item.timestamp}] (${item.mode})'
			ledger << 'EXPR   : ' + item.expression
			ledger << 'RESULT : ' + item.result
			ledger << '------------------------------------------------------------------------'
		}
		if state.history.len == 0 {
			ledger << 'No calculations recorded yet in this session.'
		}
		ledger << '========================================================================\n'
		w.set('txt_history_ledger', ledger.join('\n'))
	}

	// -------------------------------------------------------------
	// Master Evaluation Function
	// -------------------------------------------------------------
	eval_expr_fn := fn [mut state, update_history_view] (mut w simplegui.SimpleWindow, expr string, mode_label string) string {
		clean := expr.trim_space()
		if clean == '' { return '' }

		// Parse precision
		prec_text := w.get('dd_precision')
		prec_num := prec_text.all_before(' ').int()
		angle_val := if w.get('dd_angle').contains('deg') { 'deg' } else if w.get('dd_angle').contains('gra') { 'gra' } else { 'rad' }

		terse, _ := run_qalc(clean, prec_num, angle_val, 'dec', 'off')
		if terse != '' {
			state.last_result = terse
			w.set('txt_live_result', terse)

			// Record history item
			item := CalculationHistoryItem{
				timestamp: time.now().format_ss()
				expression: clean
				result: terse
				mode: mode_label
			}
			state.history << item
			update_history_view(mut w)
			w.set('lbl_status_bar', ' Evaluated: ${clean} = ${terse}')
		} else {
			w.set('lbl_status_bar', ' Failed to evaluate: ${clean}')
		}
		return terse
	}

	// -------------------------------------------------------------
	// Event Callbacks
	// -------------------------------------------------------------

	// Workspace Tabs Navigation
	win.on_change('main_tabs', fn [mut state] (mut w simplegui.SimpleWindow, tab string) {
		state.active_tab = tab

		w.set_control_visible('pane_calc', tab == ' Calculator & Scratchpad')
		w.set_control_visible('pane_algebra', tab == ' Algebra & Equation Solver')
		w.set_control_visible('pane_calculus', tab == ' Calculus & Analysis')
		w.set_control_visible('pane_units', tab == ' Unit & Currency Converter')
		w.set_control_visible('pane_matrix', tab == ' Matrices & Linear Algebra')
		w.set_control_visible('pane_recipes', tab == ' Formula & Preset Recipes')
		w.set_control_visible('pane_history', tab == ' Calculation History')

		w.toast('Switched to ' + tab)
	})

	// Theme Selector
	win.on_change('dd_theme_selector', fn (mut w simplegui.SimpleWindow, selected string) {
		w.set_theme(selected)
		w.toast('Theme changed to ${selected}')
	})

	// Copy Result Button
	win.on_click('btn_copy_res', fn [state] (mut w simplegui.SimpleWindow) {
		w.copy_to_clipboard(state.last_result)
		w.toast('Copied result: ' + state.last_result)
	})

	// Ans to Input
	win.on_click('btn_ans_to_input', fn [state] (mut w simplegui.SimpleWindow) {
		cur := w.get('txt_calc_input')
		w.set('txt_calc_input', cur + ' ' + state.last_result)
		w.toast('Appended Ans to expression.')
	})

	// -------------------------------------------------------------
	// Tab 1: Calculator Actions
	// -------------------------------------------------------------
	win.on_click('btn_calc_eval', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		expr := w.get('txt_calc_input')
		eval_expr_fn(mut w, expr, 'Standard')
	})

	win.on_click('btn_calc_clear', fn (mut w simplegui.SimpleWindow) {
		w.set('txt_calc_input', '')
		w.set('txt_live_result', '0')
	})

	// Keypad Buttons
	win.on_click('btn_k_pi', fn (mut w simplegui.SimpleWindow) { w.set('txt_calc_input', w.get('txt_calc_input') + 'pi') })
	win.on_click('btn_k_e', fn (mut w simplegui.SimpleWindow) { w.set('txt_calc_input', w.get('txt_calc_input') + 'e') })
	win.on_click('btn_k_sqrt', fn (mut w simplegui.SimpleWindow) { w.set('txt_calc_input', w.get('txt_calc_input') + 'sqrt(') })
	win.on_click('btn_k_pow', fn (mut w simplegui.SimpleWindow) { w.set('txt_calc_input', w.get('txt_calc_input') + '^') })
	win.on_click('btn_k_sin', fn (mut w simplegui.SimpleWindow) { w.set('txt_calc_input', w.get('txt_calc_input') + 'sin(') })
	win.on_click('btn_k_cos', fn (mut w simplegui.SimpleWindow) { w.set('txt_calc_input', w.get('txt_calc_input') + 'cos(') })
	win.on_click('btn_k_tan', fn (mut w simplegui.SimpleWindow) { w.set('txt_calc_input', w.get('txt_calc_input') + 'tan(') })
	win.on_click('btn_k_ln', fn (mut w simplegui.SimpleWindow) { w.set('txt_calc_input', w.get('txt_calc_input') + 'ln(') })
	win.on_click('btn_k_log', fn (mut w simplegui.SimpleWindow) { w.set('txt_calc_input', w.get('txt_calc_input') + 'log(') })
	win.on_click('btn_k_fact', fn (mut w simplegui.SimpleWindow) { w.set('txt_calc_input', w.get('txt_calc_input') + '!') })

	win.on_click('btn_k_asin', fn (mut w simplegui.SimpleWindow) { w.set('txt_calc_input', w.get('txt_calc_input') + 'asin(') })
	win.on_click('btn_k_acos', fn (mut w simplegui.SimpleWindow) { w.set('txt_calc_input', w.get('txt_calc_input') + 'acos(') })
	win.on_click('btn_k_atan', fn (mut w simplegui.SimpleWindow) { w.set('txt_calc_input', w.get('txt_calc_input') + 'atan(') })
	win.on_click('btn_k_abs', fn (mut w simplegui.SimpleWindow) { w.set('txt_calc_input', w.get('txt_calc_input') + 'abs(') })
	win.on_click('btn_k_diff', fn (mut w simplegui.SimpleWindow) { w.set('txt_calc_input', 'diff(x^3)') })
	win.on_click('btn_k_integ', fn (mut w simplegui.SimpleWindow) { w.set('txt_calc_input', 'integrate(x^2)') })
	win.on_click('btn_k_solve', fn (mut w simplegui.SimpleWindow) { w.set('txt_calc_input', 'solve(2*x + 5 = 15, x)') })
	win.on_click('btn_k_sum', fn (mut w simplegui.SimpleWindow) { w.set('txt_calc_input', 'sum(x, x, 1, 100)') })
	win.on_click('btn_k_deg', fn (mut w simplegui.SimpleWindow) { w.set('txt_calc_input', w.get('txt_calc_input') + ' to deg') })
	win.on_click('btn_k_rad', fn (mut w simplegui.SimpleWindow) { w.set('txt_calc_input', w.get('txt_calc_input') + ' to rad') })

	// Scratchpad Execution
	win.on_click('btn_eval_scratch', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		lines := w.get('txt_scratchpad').split_into_lines()
		mut out := []string{}
		for line in lines {
			trimmed := line.trim_space()
			if trimmed == '' || trimmed.starts_with('#') || trimmed.starts_with('//') {
				out << line
				continue
			}
			res := eval_expr_fn(mut w, trimmed, 'Scratchpad')
			out << trimmed + ' = ' + res
		}
		w.set('txt_scratchpad', out.join('\n'))
		w.toast('Evaluated all scratchpad lines!')
	})

	win.on_click('btn_clear_scratch', fn (mut w simplegui.SimpleWindow) {
		w.set('txt_scratchpad', '')
		w.toast('Cleared scratchpad.')
	})

	win.on_click('btn_copy_scratch', fn (mut w simplegui.SimpleWindow) {
		w.copy_to_clipboard(w.get('txt_scratchpad'))
		w.toast('Copied scratchpad to clipboard!')
	})

	// -------------------------------------------------------------
	// Tab 2: Algebra Actions
	// -------------------------------------------------------------
	win.on_click('btn_alg_solve', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		eq := w.get('txt_alg_eq').trim_space()
		var := w.get('txt_alg_var').trim_space()
		query := 'solve(${eq}, ${var})'
		res := eval_expr_fn(mut w, query, 'Algebra Solve')
		mut out := []string{}
		out << '========================================================================'
		out << ' SOLVING EQUATION: ' + eq
		out << '========================================================================'
		out << 'Formula : ' + query
		out << 'Roots   : ' + res
		out << '========================================================================\n'
		w.set('txt_alg_output', out.join('\n'))
	})

	win.on_click('btn_alg_factor', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		eq := w.get('txt_alg_eq').trim_space()
		query := 'factor(${eq})'
		res := eval_expr_fn(mut w, query, 'Factorization')
		w.set('txt_alg_output', 'Factored expression:\n\n' + res)
	})

	win.on_click('btn_alg_expand', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		eq := w.get('txt_alg_eq').trim_space()
		query := 'expand(${eq})'
		res := eval_expr_fn(mut w, query, 'Expansion')
		w.set('txt_alg_output', 'Expanded expression:\n\n' + res)
	})

	// -------------------------------------------------------------
	// Tab 3: Calculus Actions
	// -------------------------------------------------------------
	win.on_click('btn_calc_diff', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		func := w.get('txt_calc_func').trim_space()
		query := 'diff(${func})'
		res := eval_expr_fn(mut w, query, 'Derivative')
		w.set('txt_calc_output', 'd/dx Derivative of [ ${func} ]:\n\n' + res)
	})

	win.on_click('btn_calc_integ', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		func := w.get('txt_calc_func').trim_space()
		query := 'integrate(${func})'
		res := eval_expr_fn(mut w, query, 'Indefinite Integral')
		w.set('txt_calc_output', 'Indefinite Integral int [ ${func} ] dx:\n\n' + res)
	})

	win.on_click('btn_calc_def_integ', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		func := w.get('txt_calc_func').trim_space()
		query := 'integrate(${func})'
		res := eval_expr_fn(mut w, query, 'Definite Integral')
		w.set('txt_calc_output', 'Integral of [ ${func} ]:\n\n' + res)
	})

	win.on_click('btn_calc_taylor', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		func := w.get('txt_calc_func').trim_space()
		query := 'diff(diff(${func}))'
		res := eval_expr_fn(mut w, query, 'Higher Derivative')
		w.set('txt_calc_output', 'Second Derivative df/dx:\n\n' + res)
	})

	// -------------------------------------------------------------
	// Tab 4: Unit Conversion Actions
	// -------------------------------------------------------------
	win.on_click('btn_unit_convert', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		amt := w.get('txt_unit_amount').trim_space()
		from_u := w.get('txt_unit_from').trim_space()
		to_u := w.get('txt_unit_to').trim_space()
		query := '${amt} ${from_u} to ${to_u}'
		res := eval_expr_fn(mut w, query, 'Unit Conversion')
		mut out := []string{}
		out << '========================================================================'
		out << ' CONVERSION: ' + query
		out << '========================================================================'
		out << 'Result : ' + res
		out << '========================================================================\n'
		w.set('txt_unit_output', out.join('\n'))
	})

	// Unit Presets
	win.on_click('btn_up_usd_eur', fn (mut w simplegui.SimpleWindow) { w.set('txt_unit_from', 'USD'); w.set('txt_unit_to', 'EUR') })
	win.on_click('btn_up_usd_gbp', fn (mut w simplegui.SimpleWindow) { w.set('txt_unit_from', 'USD'); w.set('txt_unit_to', 'GBP') })
	win.on_click('btn_up_usd_jpy', fn (mut w simplegui.SimpleWindow) { w.set('txt_unit_from', 'USD'); w.set('txt_unit_to', 'JPY') })
	win.on_click('btn_up_usd_btc', fn (mut w simplegui.SimpleWindow) { w.set('txt_unit_from', 'USD'); w.set('txt_unit_to', 'BTC') })
	win.on_click('btn_up_mph_kmh', fn (mut w simplegui.SimpleWindow) { w.set('txt_unit_from', 'mph'); w.set('txt_unit_to', 'km/h') })
	win.on_click('btn_up_c_f', fn (mut w simplegui.SimpleWindow) { w.set('txt_unit_from', 'degC'); w.set('txt_unit_to', 'degF') })
	win.on_click('btn_up_gb_mb', fn (mut w simplegui.SimpleWindow) { w.set('txt_unit_from', 'GB'); w.set('txt_unit_to', 'MiB') })
	win.on_click('btn_up_kg_lbs', fn (mut w simplegui.SimpleWindow) { w.set('txt_unit_from', 'kg'); w.set('txt_unit_to', 'lbs') })

	// -------------------------------------------------------------
	// Tab 5: Matrix Actions
	// -------------------------------------------------------------
	win.on_click('btn_mat_eval', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		expr := w.get('txt_matrix_expr').trim_space()
		res := eval_expr_fn(mut w, expr, 'Matrix')
		w.set('txt_matrix_output', 'Matrix calculation result:\n\n' + res)
	})

	win.on_click('btn_mat_det', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		expr := w.get('txt_matrix_expr').trim_space()
		res := eval_expr_fn(mut w, 'det(${expr})', 'Matrix Det')
		w.set('txt_matrix_output', 'Matrix Determinant:\n\n' + res)
	})

	win.on_click('btn_mat_inv', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		expr := w.get('txt_matrix_expr').trim_space()
		res := eval_expr_fn(mut w, 'inverse(${expr})', 'Matrix Inverse')
		w.set('txt_matrix_output', 'Matrix Inverse:\n\n' + res)
	})

	win.on_click('btn_mat_trans', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		expr := w.get('txt_matrix_expr').trim_space()
		res := eval_expr_fn(mut w, 'transpose(${expr})', 'Matrix Transpose')
		w.set('txt_matrix_output', 'Matrix Transpose:\n\n' + res)
	})

	// -------------------------------------------------------------
	// Tab 6: Recipe Actions
	// -------------------------------------------------------------
	win.on_click('btn_rec_euler', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		res := eval_expr_fn(mut w, 'e^(i*pi) + 1', 'Euler Recipe')
		w.set('txt_recipes_output', 'Euler Identity (e^(i*pi) + 1):\n\n' + res)
	})

	win.on_click('btn_rec_rel', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		res := eval_expr_fn(mut w, '1 kg * c^2 to MWh', 'Einstein Recipe')
		w.set('txt_recipes_output', 'Mass-Energy Equivalence of 1 kg:\n\n' + res)
	})

	win.on_click('btn_rec_quad', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		res := eval_expr_fn(mut w, 'solve(2*x^2 + 5*x - 3 = 0, x)', 'Quadratic Recipe')
		w.set('txt_recipes_output', 'Quadratic Equation Roots for 2x + 5x - 3 = 0:\n\n' + res)
	})

	win.on_click('btn_rec_grav', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		res := eval_expr_fn(mut w, 'G * 5.972e24 kg * 70 kg / (6371 km)^2 to N', 'Gravitation Recipe')
		w.set('txt_recipes_output', 'Earth Surface Gravity on 70 kg person:\n\n' + res)
	})

	win.on_click('btn_rec_coul', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		res := eval_expr_fn(mut w, 'k_e * 1 C * 1 C / (1 m)^2 to N', 'Coulomb Recipe')
		w.set('txt_recipes_output', 'Electrostatic Force between two 1C charges at 1m:\n\n' + res)
	})

	win.on_click('btn_rec_kin', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		res := eval_expr_fn(mut w, '0.5 * 1500 kg * (120 km/h)^2 to kJ', 'Kinetic Recipe')
		w.set('txt_recipes_output', 'Kinetic Energy of 1500kg car at 120 km/h:\n\n' + res)
	})

	win.on_click('btn_rec_ideal', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		res := eval_expr_fn(mut w, '1 mol * (8.314 J / (mol * K)) * 298.15 K / (1 atm) to L', 'Ideal Gas Recipe')
		w.set('txt_recipes_output', 'Volume of 1 mol ideal gas at 25 deg C & 1 atm:\n\n' + res)
	})

	win.on_click('btn_rec_black', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		res := eval_expr_fn(mut w, '100 * (1 - 0.05*1) to USD', 'Financial Model')
		w.set('txt_recipes_output', 'Financial Discounting Model:\n\n' + res)
	})

	win.on_click('btn_rec_shannon', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		res := eval_expr_fn(mut w, '- (0.5 * log2(0.5) + 0.5 * log2(0.5))', 'Shannon Entropy')
		w.set('txt_recipes_output', 'Shannon Binary Entropy:\n\n' + res + ' bits')
	})

	win.on_click('btn_rec_fourier', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		res := eval_expr_fn(mut w, 'integrate(sin(2*x)/2)', 'Fourier Integral')
		w.set('txt_recipes_output', 'Fourier Harmonic Integration:\n\n' + res)
	})

	// -------------------------------------------------------------
	// Tab 7: History Actions
	// -------------------------------------------------------------
	win.on_click('btn_copy_history', fn (mut w simplegui.SimpleWindow) {
		w.copy_to_clipboard(w.get('txt_history_ledger'))
		w.toast('Copied calculation history to clipboard!')
	})

	win.on_click('btn_clear_history', fn [mut state, update_history_view] (mut w simplegui.SimpleWindow) {
		state.history.clear()
		update_history_view(mut w)
		w.toast('Cleared history ledger.')
	})

	win.on_click('btn_export_history', fn (mut w simplegui.SimpleWindow) {
		save_path := w.save_file_picker()
		if save_path != '' {
			mut real_path := save_path
			if !real_path.ends_with('.txt') {
				real_path += '.txt'
			}
			ledger := w.get('txt_history_ledger')
			os.write_file(real_path, ledger) or {
				w.alert('Export Error', 'Failed to save history file.')
				return
			}
			w.toast('Saved calculation history to ' + os.file_name(real_path))
		}
	})

	// Run initial sample calculation
	eval_expr_fn(mut win, '50 * sin(pi / 4) + sqrt(144)', 'Startup')

	println('Qalc Studio Pro configured. Starting event loop...')
	win.run()
}

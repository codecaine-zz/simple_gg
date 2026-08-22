module main

import simplegui
import os
import time

// -------------------------------------------------------------
// Data Structures
// -------------------------------------------------------------

struct KalkerHistoryItem {
mut:
	timestamp  string
	expression string
	result     string
	mode       string
}

struct AppState {
mut:
	precision   int
	angle_unit  string
	eng_mode    bool
	history     []KalkerHistoryItem
	active_tab  string
	last_result string
}

// -------------------------------------------------------------
// Kalker Execution Helpers
// -------------------------------------------------------------

fn sanitize_kalker_script(script string) string {
	lines := script.split_into_lines()
	mut clean_lines := []string{}
	for line in lines {
		trimmed := line.trim_space()
		if trimmed == '' || trimmed.starts_with('//') || trimmed.starts_with('#') {
			continue
		}
		clean_lines << trimmed
	}
	return clean_lines.join('; ')
}

fn run_kalker(expr string, precision int, angle string, is_eng bool) (bool, string) {
	clean_expr := sanitize_kalker_script(expr).trim_space()
	if clean_expr == '' {
		return false, ''
	}

	mut args := []string{}
	if precision > 0 {
		args << '-p'
		args << '${precision}'
	}
	if angle == 'deg' || angle == 'rad' {
		args << '-a'
		args << angle
	}
	if is_eng {
		args << '--eng'
	}
	args << clean_expr

	res := simplegui.exec_safe('kalker', args)
	if res.exit_code == 0 {
		return true, res.output.trim_space()
	}
	return false, res.output.trim_space()
}

// -------------------------------------------------------------
// Main Application Entry Point
// -------------------------------------------------------------

fn main() {
	println('Starting SimpleGUI - Kalker Studio Pro (Pure Math & Calculus)...')

	mut win := simplegui.new_simple_window('Kalker Studio Pro -- Pure Math, Calculus & Natural Syntax', 1140, 910)
	win.set_fullscreen(true)
	win.restore_saved_theme()
	win.set_spacing(6)
	win.set_padding(14)

	mut state := &AppState{
		precision: 12
		angle_unit: 'rad'
		eng_mode: false
		history: []KalkerHistoryItem{}
		active_tab: ' Natural Calculus'
		last_result: '0'
	}

	// -------------------------------------------------------------
	// Header & Controls
	// -------------------------------------------------------------
	win.begin_row('row_header')
	win.add_heading('Kalker Studio Pro')

	win.add_label('lbl_prec', 'Precision:')
	win.add_dropdown('dd_precision', ['10 digits', '12 digits', '20 digits', '30 digits', '50 digits'], '12 digits')
	win.set_control_width('dd_precision', 110)

	win.add_label('lbl_angle', 'Angle:')
	win.add_dropdown('dd_angle', ['Radians (rad)', 'Degrees (deg)'], 'Radians (rad)')
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
		' Natural Calculus',
		' Complex Numbers & Math',
		' Matrix & Vector Algebra',
		' Interactive Scratchpad',
		' Pure Math & Theorem Recipes',
		' Calculation History'
	])

	// -------------------------------------------------------------
	// Top Live Result Banner
	// -------------------------------------------------------------
	win.begin_group_box('grp_result_banner', 'Live Result Display')
	win.begin_row('row_result_disp')
	win.add_input('txt_live_result', '~ 41.6666666667 ~ 41 + 2/3')
	win.set_control_width('txt_live_result', 820)
	win.set_control_font_name('txt_live_result', 'Menlo')
	win.set_control_font_size('txt_live_result', 18)

	win.add_button('btn_copy_res', 'Copy Result')
	win.add_button('btn_ans_to_input', '<- Use as Ans')
	win.end_row()
	win.end_group_box()

	// -------------------------------------------------------------
	// Tab 1: Natural Calculus
	// -------------------------------------------------------------
	win.begin_group_box('pane_calculus', 'Natural Calculus Syntax: Integrals int, Derivatives f\'(x), Limits')

	win.begin_row('row_calc_input')
	win.add_label('lbl_calc_prompt', 'Calculus Expression:')
	win.add_input('txt_calc_input', 'integrate(0, 5, x^2 dx)')
	win.set_control_width('txt_calc_input', 560)
	win.set_control_font_name('txt_calc_input', 'Menlo')
	win.set_control_font_size('txt_calc_input', 14)

	win.add_button('btn_calc_eval', 'EVALUATE')
	win.add_button('btn_calc_clear', 'Clear')
	win.end_row()

	// Quick Calculus Templates
	win.begin_row('row_calc_templates')
	win.add_button('btn_ct_integ', 'int(a, b, f(x) dx)')
	win.add_button('btn_ct_prime', 'f(x) = sin(x); f\'(2)')
	win.add_button('btn_ct_second_prime', 'f(x) = x^3; f\'\'(x)')
	win.add_button('btn_ct_sqrt', 'sqrt(x)')
	win.add_button('btn_ct_cbrt', 'cbrt(x)')
	win.add_button('btn_ct_gamma', 'gamma(x)')
	win.end_row()

	win.add_textarea('txt_calc_details', 'Natural calculus expressions will be parsed and evaluated with step approximations.\n')
	win.set_control_height('txt_calc_details', 360)
	win.set_control_font_name('txt_calc_details', 'Menlo')
	win.set_control_font_size('txt_calc_details', 13)
	win.end_group_box()

	// -------------------------------------------------------------
	// Tab 2: Complex Numbers & Math
	// -------------------------------------------------------------
	win.begin_group_box('pane_complex', 'Complex Numbers, Trigonometry & Natural Functions')
	win.begin_row('row_comp_input')
	win.add_label('lbl_comp_prompt', 'Expression:')
	win.add_input('txt_complex_input', '(3 + 4i) * (2 - 5i)')
	win.set_control_width('txt_complex_input', 540)
	win.set_control_font_name('txt_complex_input', 'Menlo')

	win.add_button('btn_comp_eval', 'Calculate')
	win.add_button('btn_comp_abs', '|z| Modulus')
	win.add_button('btn_comp_arg', 'arg(z) Angle')
	win.end_row()

	// Complex Presets
	win.begin_row('row_comp_presets')
	win.add_button('btn_cp_euler', 'e^(i*pi)')
	win.add_button('btn_cp_i_pow_i', 'i^i')
	win.add_button('btn_cp_sqrt_neg', 'sqrt(-16)')
	win.add_button('btn_cp_ln_neg', 'ln(-1)')
	win.add_button('btn_cp_sin_i', 'sin(i)')
	win.end_row()

	win.add_textarea('txt_complex_output', 'Complex arithmetic, phase/modulus, and transcendental evaluations will appear here.\n')
	win.set_control_height('txt_complex_output', 360)
	win.set_control_font_name('txt_complex_output', 'Menlo')
	win.set_control_font_size('txt_complex_output', 13)
	win.end_group_box()

	// -------------------------------------------------------------
	// Tab 3: Matrix & Vector Algebra
	// -------------------------------------------------------------
	win.begin_group_box('pane_matrix', 'Matrix & Vector Mathematics')
	win.begin_row('row_mat_input')
	win.add_label('lbl_mat_prompt', 'Matrix/Vector:')
	win.add_input('txt_matrix_input', '[1, 2; 3, 4] * [5; 6]')
	win.set_control_width('txt_matrix_input', 540)
	win.set_control_font_name('txt_matrix_input', 'Menlo')

	win.add_button('btn_mat_eval', 'Calculate')
	win.add_button('btn_mat_inv', 'Inverse')
	win.add_button('btn_mat_det', 'Determinant')
	win.end_row()

	win.begin_row('row_mat_presets')
	win.add_button('btn_mp_mult', '2x2 Matrix Mult')
	win.add_button('btn_mp_3x3', '3x3 Matrix')
	win.add_button('btn_mp_dot', 'Vector Dot (1,2,3).(4,5,6)')
	win.add_button('btn_mp_cross', 'Cross Product')
	win.end_row()

	win.add_textarea('txt_matrix_output', 'Matrix calculations and vector products will appear here.\n')
	win.set_control_height('txt_matrix_output', 360)
	win.set_control_font_name('txt_matrix_output', 'Menlo')
	win.set_control_font_size('txt_matrix_output', 13)
	win.end_group_box()

	// -------------------------------------------------------------
	// Tab 4: Interactive Scratchpad
	// -------------------------------------------------------------
	win.begin_group_box('pane_scratchpad', 'Multi-Line Calculation & Variable Scratchpad')
	win.add_label('lbl_scratch_info', 'Scratchpad lines (define functions f(x), variables, and evaluate multiple expressions):')
	win.add_textarea('txt_scratchpad', '// Function definition and derivative\nf(x) = x^3 - 3*x^2 + 2*x\nf(3)\nf\'(3)\n\n// Definite Integrals\nintegrate(0, 1, sqrt(1 - x^2) dx)\n\n// Complex arithmetic\nz1 = 4 + 3i\nz2 = 1 - 2i\nz1 * z2\nabs(z1)\n\n// Golden Ratio and Fibonacci\nphi = (1 + sqrt(5)) / 2\nphi^2 - phi - 1')
	win.set_control_height('txt_scratchpad', 260)
	win.set_control_font_name('txt_scratchpad', 'Menlo')
	win.set_control_font_size('txt_scratchpad', 13)

	win.begin_row('row_scratch_actions')
	win.add_button('btn_eval_scratch', 'Run Entire Scratchpad')
	win.add_button('btn_clear_scratch', 'Clear Scratchpad')
	win.add_button('btn_copy_scratch', 'Copy Scratchpad')
	win.end_row()
	win.end_group_box()

	// -------------------------------------------------------------
	// Tab 5: Pure Math Recipes
	// -------------------------------------------------------------
	win.begin_group_box('pane_recipes', 'Pure Mathematics & Theorem Recipes')
	win.begin_row('row_rec_1')
	win.add_button('btn_r_euler', 'Euler: e^(i*pi) + 1')
	win.add_button('btn_r_gaussian', 'Gaussian Integral')
	win.add_button('btn_r_basel', 'Basel Problem sum(1/n^2)')
	win.add_button('btn_r_fib', 'Binet Fibonacci Formula')
	win.end_row()

	win.begin_row('row_rec_2')
	win.add_button('btn_r_stirling', 'Stirling Factorial Approx')
	win.add_button('btn_r_gamma', '(1/2) = sqrt(pi)')
	win.add_button('btn_r_zeta', 'Riemann Zeta function')
	win.add_button('btn_r_fresnel', 'Fresnel Sine Integral')
	win.end_row()

	win.add_textarea('txt_recipes_output', 'Click any pure mathematics theorem recipe above to evaluate and explore.\n')
	win.set_control_height('txt_recipes_output', 380)
	win.set_control_font_name('txt_recipes_output', 'Menlo')
	win.set_control_font_size('txt_recipes_output', 13)
	win.end_group_box()

	// -------------------------------------------------------------
	// Tab 6: Calculation History
	// -------------------------------------------------------------
	win.begin_group_box('pane_history', 'Calculation Ledger & Session History')
	win.begin_row('row_hist_actions')
	win.add_button('btn_copy_history', 'Copy Entire Ledger')
	win.add_button('btn_clear_history', 'Clear History')
	win.add_button('btn_export_history', 'Export Ledger to Text...')
	win.end_row()

	win.add_textarea('txt_history_ledger', 'Session pure math calculation history will be recorded here.\n')
	win.set_control_height('txt_history_ledger', 400)
	win.set_control_font_name('txt_history_ledger', 'Menlo')
	win.set_control_font_size('txt_history_ledger', 13)
	win.end_group_box()

	// Initially hide inactive tab panes
	win.set_control_visible('pane_complex', false)
	win.set_control_visible('pane_matrix', false)
	win.set_control_visible('pane_scratchpad', false)
	win.set_control_visible('pane_recipes', false)
	win.set_control_visible('pane_history', false)

	// -------------------------------------------------------------
	// Status Bar Footer
	// -------------------------------------------------------------
	win.begin_row('row_footer')
	win.add_label('lbl_status_bar', 'Ready. Powered by kalker (Pure Math & Natural Calculus).')
	win.end_row()

	// -------------------------------------------------------------
	// History Updater Helper
	// -------------------------------------------------------------
	update_history_view := fn [state] (mut w simplegui.SimpleWindow) {
		mut ledger := []string{}
		ledger << '========================================================================'
		ledger << ' KALKER STUDIO PRO -- MATHEMATICS LEDGER'
		ledger << '========================================================================'
		for item in state.history {
			ledger << '[${item.timestamp}] (${item.mode})'
			ledger << 'EXPR   : ' + item.expression
			ledger << 'RESULT : ' + item.result
			ledger << '------------------------------------------------------------------------'
		}
		if state.history.len == 0 {
			ledger << 'No math calculations recorded yet in this session.'
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

		prec_text := w.get('dd_precision')
		prec_num := prec_text.all_before(' ').int()
		angle_val := if w.get('dd_angle').contains('deg') { 'deg' } else { 'rad' }

		ok, res := run_kalker(clean, prec_num, angle_val, false)
		if ok {
			state.last_result = res
			w.set('txt_live_result', res)

			item := KalkerHistoryItem{
				timestamp: time.now().format_ss()
				expression: clean
				result: res
				mode: mode_label
			}
			state.history << item
			update_history_view(mut w)
			w.set('lbl_status_bar', ' Evaluated: ${clean} = ${res}')
		} else {
			w.set('lbl_status_bar', ' Syntax / Evaluation error: ' + res)
		}
		return res
	}

	// -------------------------------------------------------------
	// Event Callbacks
	// -------------------------------------------------------------

	// Workspace Tabs Navigation
	win.on_change('main_tabs', fn [mut state] (mut w simplegui.SimpleWindow, tab string) {
		state.active_tab = tab

		w.set_control_visible('pane_calculus', tab == ' Natural Calculus')
		w.set_control_visible('pane_complex', tab == ' Complex Numbers & Math')
		w.set_control_visible('pane_matrix', tab == ' Matrix & Vector Algebra')
		w.set_control_visible('pane_scratchpad', tab == ' Interactive Scratchpad')
		w.set_control_visible('pane_recipes', tab == ' Pure Math & Theorem Recipes')
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
	// Tab 1: Calculus Actions
	// -------------------------------------------------------------
	win.on_click('btn_calc_eval', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		expr := w.get('txt_calc_input')
		res := eval_expr_fn(mut w, expr, 'Calculus')
		mut out := []string{}
		out << '========================================================================'
		out << ' CALCULUS EVALUATION: ' + expr
		out << '========================================================================'
		out << 'Result : ' + res
		out << '========================================================================\n'
		w.set('txt_calc_details', out.join('\n'))
	})

	win.on_click('btn_calc_clear', fn (mut w simplegui.SimpleWindow) {
		w.set('txt_calc_input', '')
		w.set('txt_live_result', '0')
	})

	win.on_click('btn_ct_integ', fn (mut w simplegui.SimpleWindow) { w.set('txt_calc_input', 'integrate(0, 1, sin(x)*x dx)') })
	win.on_click('btn_ct_prime', fn (mut w simplegui.SimpleWindow) { w.set('txt_calc_input', 'f(x) = sin(x); f\'(2)') })
	win.on_click('btn_ct_second_prime', fn (mut w simplegui.SimpleWindow) { w.set('txt_calc_input', 'f(x) = x^3 - 5*x; f\'\'(4)') })
	win.on_click('btn_ct_sqrt', fn (mut w simplegui.SimpleWindow) { w.set('txt_calc_input', 'sqrt(144) + sqrt(25)') })
	win.on_click('btn_ct_cbrt', fn (mut w simplegui.SimpleWindow) { w.set('txt_calc_input', 'cbrt(27)') })
	win.on_click('btn_ct_gamma', fn (mut w simplegui.SimpleWindow) { w.set('txt_calc_input', 'gamma(5)') })

	// -------------------------------------------------------------
	// Tab 2: Complex Numbers Actions
	// -------------------------------------------------------------
	win.on_click('btn_comp_eval', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		expr := w.get('txt_complex_input')
		res := eval_expr_fn(mut w, expr, 'Complex')
		w.set('txt_complex_output', 'Complex evaluation result:\n\n' + res)
	})

	win.on_click('btn_comp_abs', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		expr := w.get('txt_complex_input')
		res := eval_expr_fn(mut w, 'abs(${expr})', 'Modulus |z|')
		w.set('txt_complex_output', 'Complex Modulus |z|:\n\n' + res)
	})

	win.on_click('btn_comp_arg', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		expr := w.get('txt_complex_input')
		res := eval_expr_fn(mut w, 'arg(${expr})', 'Phase arg(z)')
		w.set('txt_complex_output', 'Complex Argument / Phase arg(z):\n\n' + res)
	})

	win.on_click('btn_cp_euler', fn (mut w simplegui.SimpleWindow) { w.set('txt_complex_input', 'e^(i*pi)') })
	win.on_click('btn_cp_i_pow_i', fn (mut w simplegui.SimpleWindow) { w.set('txt_complex_input', 'i^i') })
	win.on_click('btn_cp_sqrt_neg', fn (mut w simplegui.SimpleWindow) { w.set('txt_complex_input', 'sqrt(-16)') })
	win.on_click('btn_cp_ln_neg', fn (mut w simplegui.SimpleWindow) { w.set('txt_complex_input', 'ln(-1)') })
	win.on_click('btn_cp_sin_i', fn (mut w simplegui.SimpleWindow) { w.set('txt_complex_input', 'sin(i)') })

	// -------------------------------------------------------------
	// Tab 3: Matrix Actions
	// -------------------------------------------------------------
	win.on_click('btn_mat_eval', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		expr := w.get('txt_matrix_input')
		res := eval_expr_fn(mut w, expr, 'Matrix')
		w.set('txt_matrix_output', 'Matrix result:\n\n' + res)
	})

	win.on_click('btn_mat_inv', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		expr := w.get('txt_matrix_input')
		res := eval_expr_fn(mut w, 'inv(${expr})', 'Matrix Inv')
		w.set('txt_matrix_output', 'Matrix Inverse:\n\n' + res)
	})

	win.on_click('btn_mat_det', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		expr := w.get('txt_matrix_input')
		res := eval_expr_fn(mut w, 'det(${expr})', 'Matrix Det')
		w.set('txt_matrix_output', 'Matrix Determinant:\n\n' + res)
	})

	win.on_click('btn_mp_mult', fn (mut w simplegui.SimpleWindow) { w.set('txt_matrix_input', '[1, 2; 3, 4] * [5; 6]') })
	win.on_click('btn_mp_3x3', fn (mut w simplegui.SimpleWindow) { w.set('txt_matrix_input', '[1, 2, 3; 0, 1, 4; 5, 6, 0]') })
	win.on_click('btn_mp_dot', fn (mut w simplegui.SimpleWindow) { w.set('txt_matrix_input', '(1, 2, 3) . (4, 5, 6)') })
	win.on_click('btn_mp_cross', fn (mut w simplegui.SimpleWindow) { w.set('txt_matrix_input', '(1, 0, 0) x (0, 1, 0)') })

	// -------------------------------------------------------------
	// Tab 4: Scratchpad Actions
	// -------------------------------------------------------------
	win.on_click('btn_eval_scratch', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		lines := w.get('txt_scratchpad').split_into_lines()
		mut out := []string{}
		for line in lines {
			trimmed := line.trim_space()
			if trimmed == '' || trimmed.starts_with('//') || trimmed.starts_with('#') {
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
	// Tab 5: Recipe Actions
	// -------------------------------------------------------------
	win.on_click('btn_r_euler', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		res := eval_expr_fn(mut w, 'e^(i*pi) + 1', 'Euler Recipe')
		w.set('txt_recipes_output', ' Euler\'s Identity (e^(i*pi) + 1):\n\n' + res)
	})

	win.on_click('btn_r_gaussian', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		res := eval_expr_fn(mut w, 'integrate(0, 10, e^(-x^2) dx)', 'Gaussian Integral')
		w.set('txt_recipes_output', ' Gaussian Error Function Integral int[0, 10] e^(-x^2) dx (~ sqrt(pi)/2):\n\n' + res)
	})

	win.on_click('btn_r_basel', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		res := eval_expr_fn(mut w, 'pi^2 / 6', 'Basel Problem')
		w.set('txt_recipes_output', ' Euler\'s Basel Solution (sum 1/n^2 = pi^2 / 6):\n\n' + res)
	})

	win.on_click('btn_r_fib', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		res := eval_expr_fn(mut w, '(((1+sqrt(5))/2)^10 - ((1-sqrt(5))/2)^10) / sqrt(5)', 'Binet Fibonacci')
		w.set('txt_recipes_output', ' Binet\'s Formula for 10th Fibonacci Number (F_10 = 55):\n\n' + res)
	})

	win.on_click('btn_r_stirling', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		res := eval_expr_fn(mut w, 'sqrt(2*pi*10) * (10/e)^10', 'Stirling Approx')
		w.set('txt_recipes_output', ' Stirling\'s Approximation for 10!:\n\n' + res)
	})

	win.on_click('btn_r_gamma', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		res := eval_expr_fn(mut w, 'gamma(0.5)', 'Gamma(1/2)')
		w.set('txt_recipes_output', '(1/2) Gamma Function (exact sqrt(pi)):\n\n' + res)
	})

	win.on_click('btn_r_zeta', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		res := eval_expr_fn(mut w, 'pi^4 / 90', 'Zeta(4)')
		w.set('txt_recipes_output', '(4) Riemann Zeta Function:\n\n' + res)
	})

	win.on_click('btn_r_fresnel', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		res := eval_expr_fn(mut w, 'integrate(0, 1, sin(x^2) dx)', 'Fresnel Sine')
		w.set('txt_recipes_output', ' Fresnel Sine Integral int[0, 1] sin(x^2) dx:\n\n' + res)
	})

	// -------------------------------------------------------------
	// Tab 6: History Actions
	// -------------------------------------------------------------
	win.on_click('btn_copy_history', fn (mut w simplegui.SimpleWindow) {
		w.copy_to_clipboard(w.get('txt_history_ledger'))
		w.toast('Copied history ledger to clipboard!')
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

	// Initial evaluation
	eval_expr_fn(mut win, 'integrate(0, 5, x^2 dx)', 'Startup')

	println('Kalker Studio Pro configured. Starting event loop...')
	win.run()
}

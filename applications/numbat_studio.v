module main

import simplegui
import os
import time

// -------------------------------------------------------------
// Data Structures
// -------------------------------------------------------------

struct NumbatHistoryItem {
mut:
	timestamp  string
	expression string
	result     string
	mode       string
}

struct AppState {
mut:
	history     []NumbatHistoryItem
	active_tab  string
	last_result string
}

// -------------------------------------------------------------
// Numbat Execution Helpers
// -------------------------------------------------------------

fn sanitize_numbat_script(script string) string {
	lines := script.split_into_lines()
	mut clean_lines := []string{}
	for line in lines {
		trimmed := line.trim_space()
		if trimmed.starts_with('//') {
			clean_lines << '#' + trimmed.all_after('//')
		} else {
			clean_lines << line
		}
	}
	return clean_lines.join('\n')
}

fn run_numbat(expr string) (bool, string) {
	clean_expr := sanitize_numbat_script(expr).trim_space()
	if clean_expr == '' {
		return false, ''
	}

	res := simplegui.exec_safe('numbat', ['-e', clean_expr])
	if res.exit_code == 0 {
		return true, res.output.trim_space()
	}
	return false, res.output.trim_space()
}

// -------------------------------------------------------------
// Main Application Entry Point
// -------------------------------------------------------------

fn main() {
	println('Starting SimpleGUI - Numbat Studio Pro (Scientific & Dimensional Analysis)...')

	mut win := simplegui.new_simple_window('Numbat Studio Pro -- Scientific & Dimensional Analysis', 1160, 910)
	win.set_fullscreen(true)
	win.restore_saved_theme()
	win.set_spacing(6)
	win.set_padding(14)

	mut state := &AppState{
		history: []NumbatHistoryItem{}
		active_tab: 'Physical Calculator'
		last_result: '0'
	}

	// -------------------------------------------------------------
	// Header & Controls
	// -------------------------------------------------------------
	win.begin_row('row_header')
	win.add_heading('Numbat Studio Pro')
	win.add_label('lbl_info', 'Dimensional Analysis')
	win.add_label('lbl_theme_hdr', 'Theme:')
	saved_theme := simplegui.get_saved_theme()
	win.add_dropdown('dd_theme_selector', simplegui.list_themes(), saved_theme)
	win.set_control_width('dd_theme_selector', 160)
	win.end_row()

	// -------------------------------------------------------------
	// Navigation Workspace Tabs
	// -------------------------------------------------------------
	win.add_tabs('main_tabs', [
		'Physical Calculator',
		'Multi-Line Physics IDE',
		'Fundamental Constants',
		'Dimensional Unit Guide',
		'Physics & Engineering Recipes',
		'Calculation History'
	])

	// -------------------------------------------------------------
	// Top Live Result Banner
	// -------------------------------------------------------------
	win.begin_group_box('grp_result_banner', 'Live Result & Dimensional Type')
	win.begin_row('row_result_disp')
	win.add_input('txt_live_result', '15.69 km/h')
	win.set_control_width('txt_live_result', 560)
	win.set_control_font_name('txt_live_result', 'Menlo')
	win.set_control_font_size('txt_live_result', 16)

	win.add_button('btn_copy_res', 'Copy Result')
	win.add_button('btn_ans_to_input', '<- Use as Ans')
	win.end_row()
	win.end_group_box()

	// -------------------------------------------------------------
	// Tab 1: Physical Calculator
	// -------------------------------------------------------------
	win.begin_group_box('pane_calc', 'Quick Physical Expression & Dimensional Conversion')

	win.begin_row('row_quick_input')
	win.add_label('lbl_expr_prompt', 'Expression:')
	win.add_input('txt_calc_input', '5.23 km / 20 min -> km/h')
	win.set_control_width('txt_calc_input', 520)
	win.set_control_font_name('txt_calc_input', 'Menlo')
	win.set_control_font_size('txt_calc_input', 14)

	win.add_button('btn_calc_eval', 'EVALUATE')
	win.add_button('btn_calc_clear', 'Clear')
	win.end_row()

	// Interactive Unit Keypad Rows
	win.begin_row('row_pad_1')
	win.add_button('btn_u_arrow', ' (->)')
	win.add_button('btn_u_kmh', 'km/h')
	win.add_button('btn_u_mph', 'mph')
	win.add_button('btn_u_mps', 'm/s')
	win.add_button('btn_u_kj', 'kJ')
	win.end_row()

	win.begin_row('row_pad_2')
	win.add_button('btn_u_kwh', 'kWh')
	win.add_button('btn_u_watts', 'W')
	win.add_button('btn_u_hp', 'hp')
	win.add_button('btn_u_celsius', 'deg C')
	win.add_button('btn_u_fahrenheit', 'deg F')
	win.end_row()

	win.begin_row('row_pad_3')
	win.add_button('btn_u_newtons', 'N')
	win.add_button('btn_u_pascals', 'Pa')
	win.add_button('btn_u_psi', 'psi')
	win.add_button('btn_u_bar', 'bar')
	win.add_button('btn_u_atm', 'atm')
	win.end_row()

	win.begin_row('row_pad_4')
	win.add_button('btn_u_coulomb', 'C')
	win.add_button('btn_u_volts', 'V')
	win.add_button('btn_u_ohms', 'Ohms')
	win.add_button('btn_u_ev', 'eV')
	win.add_button('btn_u_ly', 'lightyear')
	win.end_row()

	// Live Detailed Result Box
	win.add_textarea('txt_calc_details', 'Enter a physical expression above with optional conversion (e.g. 100 kW * 2 hours -> kWh or 80 kg * (120 km/h)^2 * 0.5 -> kJ).\n')
	win.set_control_height('txt_calc_details', 260)
	win.set_control_font_name('txt_calc_details', 'Menlo')
	win.set_control_font_size('txt_calc_details', 13)

	win.end_group_box()

	// -------------------------------------------------------------
	// Tab 2: Multi-Line Physics IDE
	// -------------------------------------------------------------
	win.begin_group_box('pane_ide', 'Multi-Line Physics & Engineering Derivation IDE')
	win.add_label('lbl_ide_hdr', 'Script (define variables with let, perform derivations, convert to target units):')
	win.add_textarea('txt_ide_script', '# Orbital Mechanics Demo: Low Earth Orbit\nlet G = 6.67430e-11 N * m^2 / kg^2\nlet M_earth = 5.972e24 kg\nlet R_earth = 6371 km\nlet altitude = 400 km\nlet r = R_earth + altitude\nlet v_orbit = sqrt(G * M_earth / r) -> km/s\nlet period = 2 * pi * r / v_orbit -> minutes\n\n# Kinetic Energy of 1000kg Satellite\nlet m_sat = 1000 kg\nlet E_kin = 0.5 * m_sat * v_orbit^2 -> GJ\n\nperiod')
	win.set_control_height('txt_ide_script', 240)
	win.set_control_font_name('txt_ide_script', 'Menlo')
	win.set_control_font_size('txt_ide_script', 13)

	win.begin_row('row_ide_actions')
	win.add_button('btn_run_ide_script', 'RUN PHYSICS DERIVATION SCRIPT')
	win.add_button('btn_clear_ide', 'Clear')
	win.add_button('btn_copy_ide_script', 'Copy Script')
	win.end_row()

	win.add_textarea('txt_ide_output', 'Physics derivation results will appear here.\n')
	win.set_control_height('txt_ide_output', 180)
	win.set_control_font_name('txt_ide_output', 'Menlo')
	win.set_control_font_size('txt_ide_output', 13)
	win.end_group_box()

	// -------------------------------------------------------------
	// Tab 3: Fundamental Constants
	// -------------------------------------------------------------
	win.begin_group_box('pane_constants', 'Universal & Fundamental Physical Constants')
	win.begin_row('row_c_actions')
	win.add_button('btn_c_speed_light', 'c (Speed of Light)')
	win.add_button('btn_c_grav', 'G (Gravitational Constant)')
	win.add_button('btn_c_planck', 'hbar (Planck Constant)')
	win.add_button('btn_c_boltzmann', 'k_B (Boltzmann Constant)')
	win.add_button('btn_c_avogadro', 'N_A (Avogadro Constant)')
	win.end_row()

	win.begin_row('row_c_actions_2')
	win.add_button('btn_c_electron', 'e (Elementary Charge)')
	win.add_button('btn_c_m_electron', 'm_e (Electron Mass)')
	win.add_button('btn_c_m_proton', 'm_p (Proton Mass)')
	win.add_button('btn_c_eps0', 'eps_0 (Permittivity)')
	win.add_button('btn_c_mu0', 'mu_0 (Permeability)')
	win.end_row()

	win.add_textarea('txt_constants_output', 'Click any physical constant above to inspect its exact value, physical dimension, and SI units.\n')
	win.set_control_height('txt_constants_output', 380)
	win.set_control_font_name('txt_constants_output', 'Menlo')
	win.set_control_font_size('txt_constants_output', 13)
	win.end_group_box()

	// -------------------------------------------------------------
	// Tab 4: Dimensional Unit Guide
	// -------------------------------------------------------------
	win.begin_group_box('pane_units_guide', 'Dimensional Units Reference Guide')
	win.begin_row('row_guide_btns')
	win.add_button('btn_g_si', 'SI Base & Derived')
	win.add_button('btn_g_energy', 'Energy & Power')
	win.add_button('btn_g_pressure', 'Pressure & Force')
	win.add_button('btn_g_astro', 'Astronomical Units')
	win.add_button('btn_g_data', 'Digital Storage')
	win.end_row()

	win.add_textarea('txt_units_guide_output', 'Explore supported units and dimensional representations in Numbat.\n')
	win.set_control_height('txt_units_guide_output', 400)
	win.set_control_font_name('txt_units_guide_output', 'Menlo')
	win.set_control_font_size('txt_units_guide_output', 13)
	win.end_group_box()

	// -------------------------------------------------------------
	// Tab 5: Physics & Engineering Recipes
	// -------------------------------------------------------------
	win.begin_group_box('pane_recipes', 'Real-World Physics & Engineering Recipes')
	win.begin_row('row_p_rec_1')
	win.add_button('btn_pr_rel_energy', 'Mass-Energy: E = mc')
	win.add_button('btn_pr_ke', 'Kinetic Energy')
	win.add_button('btn_pr_elec_power', 'Electrical Power (VI)')
	win.add_button('btn_pr_photon', 'Photon Energy: E = h')
	win.end_row()

	win.begin_row('row_p_rec_2')
	win.add_button('btn_pr_grav_pe', 'Gravitational Potential')
	win.add_button('btn_pr_sound', 'Speed of Sound in Air')
	win.add_button('btn_pr_ideal_gas', 'Ideal Gas Law')
	win.add_button('btn_pr_stefan', 'Stefan-Boltzmann Radiation')
	win.end_row()

	win.add_textarea('txt_recipes_output', 'Click any real-world scientific recipe above to evaluate and explore.\n')
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

	win.add_textarea('txt_history_ledger', 'Session physical calculation history will be recorded here.\n')
	win.set_control_height('txt_history_ledger', 400)
	win.set_control_font_name('txt_history_ledger', 'Menlo')
	win.set_control_font_size('txt_history_ledger', 13)
	win.end_group_box()

	// Initially hide inactive tab panes
	win.set_control_visible('pane_ide', false)
	win.set_control_visible('pane_constants', false)
	win.set_control_visible('pane_units_guide', false)
	win.set_control_visible('pane_recipes', false)
	win.set_control_visible('pane_history', false)

	// -------------------------------------------------------------
	// Status Bar Footer
	// -------------------------------------------------------------
	win.begin_row('row_footer')
	win.add_label('lbl_status_bar', 'Ready. Powered by numbat (Statically-Typed Physical Analysis).')
	win.end_row()

	// -------------------------------------------------------------
	// History Updater Helper
	// -------------------------------------------------------------
	update_history_view := fn [state] (mut w simplegui.SimpleWindow) {
		mut ledger := []string{}
		ledger << '========================================================================'
		ledger << ' NUMBAT STUDIO PRO -- PHYSICAL CALCULATION LEDGER'
		ledger << '========================================================================'
		for item in state.history {
			ledger << '[${item.timestamp}] (${item.mode})'
			ledger << 'EXPR   : ' + item.expression
			ledger << 'RESULT : ' + item.result
			ledger << '------------------------------------------------------------------------'
		}
		if state.history.len == 0 {
			ledger << 'No physical calculations recorded yet in this session.'
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

		ok, res := run_numbat(clean)
		if ok {
			state.last_result = res
			w.set('txt_live_result', res)

			// Record history item
			item := NumbatHistoryItem{
				timestamp: time.now().format_ss()
				expression: clean
				result: res
				mode: mode_label
			}
			state.history << item
			update_history_view(mut w)
			w.set('lbl_status_bar', ' Evaluated: ${clean} = ${res}')
		} else {
			w.set('lbl_status_bar', ' Dimensional / Syntax error in expression')
		}
		return res
	}

	// -------------------------------------------------------------
	// Event Callbacks
	// -------------------------------------------------------------

	// Workspace Tabs Navigation
	win.on_change('main_tabs', fn [mut state] (mut w simplegui.SimpleWindow, tab string) {
		state.active_tab = tab

		w.set_control_visible('pane_calc', tab == 'Physical Calculator')
		w.set_control_visible('pane_ide', tab == 'Multi-Line Physics IDE')
		w.set_control_visible('pane_constants', tab == 'Fundamental Constants')
		w.set_control_visible('pane_units_guide', tab == 'Dimensional Unit Guide')
		w.set_control_visible('pane_recipes', tab == 'Physics & Engineering Recipes')
		w.set_control_visible('pane_history', tab == 'Calculation History')

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
		res := eval_expr_fn(mut w, expr, 'Physical Calc')
		mut out := []string{}
		out << '========================================================================'
		out << ' EXPRESSION: ' + expr
		out << '========================================================================'
		out << 'Result : ' + res
		out << '========================================================================\n'
		w.set('txt_calc_details', out.join('\n'))
	})

	win.on_click('btn_calc_clear', fn (mut w simplegui.SimpleWindow) {
		w.set('txt_calc_input', '')
		w.set('txt_live_result', '0')
	})

	// Unit Keypad Buttons
	win.on_click('btn_u_arrow', fn (mut w simplegui.SimpleWindow) { w.set('txt_calc_input', w.get('txt_calc_input') + ' -> ') })
	win.on_click('btn_u_kmh', fn (mut w simplegui.SimpleWindow) { w.set('txt_calc_input', w.get('txt_calc_input') + ' km/h') })
	win.on_click('btn_u_mph', fn (mut w simplegui.SimpleWindow) { w.set('txt_calc_input', w.get('txt_calc_input') + ' mph') })
	win.on_click('btn_u_mps', fn (mut w simplegui.SimpleWindow) { w.set('txt_calc_input', w.get('txt_calc_input') + ' m/s') })
	win.on_click('btn_u_kj', fn (mut w simplegui.SimpleWindow) { w.set('txt_calc_input', w.get('txt_calc_input') + ' kJ') })
	win.on_click('btn_u_kwh', fn (mut w simplegui.SimpleWindow) { w.set('txt_calc_input', w.get('txt_calc_input') + ' kWh') })
	win.on_click('btn_u_watts', fn (mut w simplegui.SimpleWindow) { w.set('txt_calc_input', w.get('txt_calc_input') + ' W') })
	win.on_click('btn_u_hp', fn (mut w simplegui.SimpleWindow) { w.set('txt_calc_input', w.get('txt_calc_input') + ' hp') })
	win.on_click('btn_u_celsius', fn (mut w simplegui.SimpleWindow) { w.set('txt_calc_input', w.get('txt_calc_input') + 'deg C') })
	win.on_click('btn_u_fahrenheit', fn (mut w simplegui.SimpleWindow) { w.set('txt_calc_input', w.get('txt_calc_input') + 'deg F') })

	win.on_click('btn_u_newtons', fn (mut w simplegui.SimpleWindow) { w.set('txt_calc_input', w.get('txt_calc_input') + ' N') })
	win.on_click('btn_u_pascals', fn (mut w simplegui.SimpleWindow) { w.set('txt_calc_input', w.get('txt_calc_input') + ' Pa') })
	win.on_click('btn_u_psi', fn (mut w simplegui.SimpleWindow) { w.set('txt_calc_input', w.get('txt_calc_input') + ' psi') })
	win.on_click('btn_u_bar', fn (mut w simplegui.SimpleWindow) { w.set('txt_calc_input', w.get('txt_calc_input') + ' bar') })
	win.on_click('btn_u_atm', fn (mut w simplegui.SimpleWindow) { w.set('txt_calc_input', w.get('txt_calc_input') + ' atm') })
	win.on_click('btn_u_coulomb', fn (mut w simplegui.SimpleWindow) { w.set('txt_calc_input', w.get('txt_calc_input') + ' C') })
	win.on_click('btn_u_volts', fn (mut w simplegui.SimpleWindow) { w.set('txt_calc_input', w.get('txt_calc_input') + ' V') })
	win.on_click('btn_u_ohms', fn (mut w simplegui.SimpleWindow) { w.set('txt_calc_input', w.get('txt_calc_input') + ' ohm') })
	win.on_click('btn_u_ev', fn (mut w simplegui.SimpleWindow) { w.set('txt_calc_input', w.get('txt_calc_input') + ' eV') })
	win.on_click('btn_u_ly', fn (mut w simplegui.SimpleWindow) { w.set('txt_calc_input', w.get('txt_calc_input') + ' ly') })

	// -------------------------------------------------------------
	// Tab 2: Multi-Line Physics IDE
	// -------------------------------------------------------------
	win.on_click('btn_run_ide_script', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		script := w.get('txt_ide_script')
		res := eval_expr_fn(mut w, script, 'Physics Script IDE')
		mut out := []string{}
		out << '========================================================================'
		out << ' PHYSICS SCRIPT EXECUTION RESULTS'
		out << '========================================================================'
		out << res
		out << '\n========================================================================\n'
		w.set('txt_ide_output', out.join('\n'))
		w.toast('Executed physics derivation script!')
	})

	win.on_click('btn_clear_ide', fn (mut w simplegui.SimpleWindow) {
		w.set('txt_ide_script', '')
		w.set('txt_ide_output', '')
	})

	win.on_click('btn_copy_ide_script', fn (mut w simplegui.SimpleWindow) {
		w.copy_to_clipboard(w.get('txt_ide_script'))
		w.toast('Copied script to clipboard!')
	})

	// -------------------------------------------------------------
	// Tab 3: Fundamental Constants
	// -------------------------------------------------------------
	win.on_click('btn_c_speed_light', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		res := eval_expr_fn(mut w, 'c -> km/s', 'Speed of Light')
		w.set('txt_constants_output', ' Speed of Light in Vacuum (c):\n\n' + res + '\nExact SI Definition: 299,792,458 m/s')
	})

	win.on_click('btn_c_grav', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		res := eval_expr_fn(mut w, 'G', 'Gravitational Constant')
		w.set('txt_constants_output', ' Universal Gravitational Constant (G):\n\n' + res)
	})

	win.on_click('btn_c_planck', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		res := eval_expr_fn(mut w, 'planck_constant -> eV * s', 'Planck Constant')
		w.set('txt_constants_output', ' Planck Constant (h):\n\n' + res)
	})

	win.on_click('btn_c_boltzmann', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		res := eval_expr_fn(mut w, 'k_B -> eV / K', 'Boltzmann Constant')
		w.set('txt_constants_output', ' Boltzmann Constant (k_B):\n\n' + res)
	})

	win.on_click('btn_c_avogadro', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		res := eval_expr_fn(mut w, 'N_A', 'Avogadro Constant')
		w.set('txt_constants_output', ' Avogadro Constant (N_A):\n\n' + res)
	})

	win.on_click('btn_c_electron', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		res := eval_expr_fn(mut w, 'elementary_charge -> C', 'Elementary Charge')
		w.set('txt_constants_output', ' Elementary Charge (e):\n\n' + res)
	})

	win.on_click('btn_c_m_electron', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		res := eval_expr_fn(mut w, 'electron_mass * c^2 -> MeV', 'Electron Mass')
		w.set('txt_constants_output', ' Electron Rest Mass Energy (m_e * c^2):\n\n' + res)
	})

	win.on_click('btn_c_m_proton', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		res := eval_expr_fn(mut w, 'proton_mass * c^2 -> GeV', 'Proton Mass')
		w.set('txt_constants_output', ' Proton Rest Mass Energy (m_p * c^2):\n\n' + res)
	})

	win.on_click('btn_c_eps0', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		res := eval_expr_fn(mut w, 'eps0', 'Vacuum Permittivity')
		w.set('txt_constants_output', ' Vacuum Electric Permittivity (eps0):\n\n' + res)
	})

	win.on_click('btn_c_mu0', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		res := eval_expr_fn(mut w, 'mu0', 'Vacuum Permeability')
		w.set('txt_constants_output', ' Vacuum Magnetic Permeability (mu0):\n\n' + res)
	})

	// -------------------------------------------------------------
	// Tab 4: Dimensional Unit Guide
	// -------------------------------------------------------------
	win.on_click('btn_g_si', fn (mut w simplegui.SimpleWindow) {
		mut out := []string{}
		out << '========================================================================'
		out << ' SI BASE & DERIVED PHYSICAL UNITS'
		out << '========================================================================'
		out << 'Length        : meter (m), kilometer (km), centimeter (cm), millimeter (mm)'
		out << 'Mass          : kilogram (kg), gram (g), milligram (mg), metric_ton (t)'
		out << 'Time          : second (s), minute (min), hour (h), day, year'
		out << 'Electric Cur. : ampere (A), milliampere (mA)'
		out << 'Temperature   : kelvin (K), degree_celsius ( deg C / celsius), degree_fahrenheit ( deg F / fahrenheit)'
		out << 'Substance     : mole (mol)'
		out << 'Luminous Int. : candela (cd), lumen (lm), lux (lx)'
		out << 'Frequency     : hertz (Hz), kilohertz (kHz), megahertz (MHz), gigahertz (GHz)'
		out << '========================================================================'
		w.set('txt_units_guide_output', out.join('\n'))
	})

	win.on_click('btn_g_energy', fn (mut w simplegui.SimpleWindow) {
		mut out := []string{}
		out << '========================================================================'
		out << ' ENERGY, WORK & POWER UNITS'
		out << '========================================================================'
		out << 'Energy        : joule (J), kilojoule (kJ), megajoule (MJ), gigajoule (GJ)'
		out << 'Electrical En.: watt_hour (Wh), kilowatt_hour (kWh), megawatt_hour (MWh)'
		out << 'Atomic Energy : electronvolt (eV), keV, MeV, GeV, TeV'
		out << 'Heat / Calorie: calorie (cal), kilocalorie (kcal), BTU'
		out << 'Power         : watt (W), kilowatt (kW), megawatt (MW), horsepower (hp)'
		out << '========================================================================'
		w.set('txt_units_guide_output', out.join('\n'))
	})

	win.on_click('btn_g_pressure', fn (mut w simplegui.SimpleWindow) {
		mut out := []string{}
		out << '========================================================================'
		out << ' FORCE, PRESSURE & MECHANICS UNITS'
		out << '========================================================================'
		out << 'Force         : newton (N), kilonewton (kN), pound_force (lbf), dyne'
		out << 'Pressure      : pascal (Pa), kilopascal (kPa), megapascal (MPa), bar, mbar'
		out << 'Atmosphere    : standard_atmosphere (atm), torr, mmHg, psi'
		out << 'Torque        : newton_meter (N*m), foot_pound (ft*lbf)'
		out << '========================================================================'
		w.set('txt_units_guide_output', out.join('\n'))
	})

	win.on_click('btn_g_astro', fn (mut w simplegui.SimpleWindow) {
		mut out := []string{}
		out << '========================================================================'
		out << ' ASTRONOMICAL & COSMOLOGICAL UNITS'
		out << '========================================================================'
		out << 'Distance      : astronomical_unit (AU), lightyear (ly), parsec (pc), kpc, Mpc'
		out << 'Solar Mass    : solar_mass (M_sun), earth_mass (M_earth), jupiter_mass'
		out << 'Solar Radius  : solar_radius (R_sun), earth_radius (R_earth)'
		out << 'Solar Luminos.: solar_luminosity (L_sun)'
		out << '========================================================================'
		w.set('txt_units_guide_output', out.join('\n'))
	})

	win.on_click('btn_g_data', fn (mut w simplegui.SimpleWindow) {
		mut out := []string{}
		out << '========================================================================'
		out << ' DIGITAL INFORMATION & DATA RATES'
		out << '========================================================================'
		out << 'Data Units    : bit, byte (B), kilobyte (kB), megabyte (MB), gigabyte (GB), terabyte (TB)'
		out << 'Binary IEC    : kibibyte (KiB), mebibyte (MiB), gibibyte (GiB), tebibyte (TiB)'
		out << 'Bandwidth     : bit/s, kbps, Mbps, Gbps, byte/s, MB/s, GB/s'
		out << '========================================================================'
		w.set('txt_units_guide_output', out.join('\n'))
	})

	// -------------------------------------------------------------
	// Tab 5: Physics Recipes
	// -------------------------------------------------------------
	win.on_click('btn_pr_rel_energy', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		res := eval_expr_fn(mut w, '1 g * c^2 -> kWh', 'Relativistic Energy')
		w.set('txt_recipes_output', ' Relativistic Mass-Energy (1 gram of matter converted to energy):\n\n' + res)
	})

	win.on_click('btn_pr_ke', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		res := eval_expr_fn(mut w, '0.5 * 1800 kg * (130 km/h)^2 -> kJ', 'Kinetic Energy')
		w.set('txt_recipes_output', ' Kinetic Energy of 1800kg vehicle at 130 km/h:\n\n' + res)
	})

	win.on_click('btn_pr_elec_power', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		res := eval_expr_fn(mut w, '240 V * 32 A -> kW', 'Electrical Power')
		w.set('txt_recipes_output', ' EV Charger Level 2 Power (240V, 32A):\n\n' + res)
	})

	win.on_click('btn_pr_photon', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		res := eval_expr_fn(mut w, 'planck_constant * (c / 550 nm) -> eV', 'Green Photon Energy')
		w.set('txt_recipes_output', ' Energy of Green Light Photon (wavelength = 550 nm):\n\n' + res)
	})

	win.on_click('btn_pr_grav_pe', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		res := eval_expr_fn(mut w, '80 kg * 9.81 m/s^2 * 100 m -> kJ', 'Gravitational PE')
		w.set('txt_recipes_output', ' Gravitational Potential Energy (80kg lifted 100m):\n\n' + res)
	})

	win.on_click('btn_pr_sound', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		res := eval_expr_fn(mut w, '331.3 m/s * sqrt((20  deg C -> K) / 273.15 K) -> km/h', 'Speed of Sound')
		w.set('txt_recipes_output', ' Speed of Sound in Dry Air at 20 deg C:\n\n' + res)
	})

	win.on_click('btn_pr_ideal_gas', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		res := eval_expr_fn(mut w, '1 mol * (8.314 J / (mol * K)) * (20  deg C -> K) / (1 atm) -> liters', 'Ideal Gas Law')
		w.set('txt_recipes_output', ' Molar Volume of Ideal Gas at 20 deg C & 1 atm:\n\n' + res)
	})

	win.on_click('btn_pr_stefan', fn [eval_expr_fn] (mut w simplegui.SimpleWindow) {
		res := eval_expr_fn(mut w, '5.670374e-8 W / (m^2 * K^4) * (5778 K)^4 -> MW / m^2', 'Stefan-Boltzmann')
		w.set('txt_recipes_output', ' Sun Surface Blackbody Emittance (T = 5778 K):\n\n' + res)
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
	eval_expr_fn(mut win, '5.23 km / 20 min -> km/h', 'Startup')

	println('Numbat Studio Pro configured. Starting event loop...')
	win.run()
}

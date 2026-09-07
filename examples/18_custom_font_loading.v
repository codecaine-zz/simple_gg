// Example 18: Custom Font Loading & Dynamic Typography Demo
module main

import math
import os
import simplegui

// get_platform_font_candidates returns categorized system font candidates on macOS, Linux, or Windows.
fn get_platform_font_candidates() []string {
	mut candidates := []string{}
	$if macos {
		for candidate in simplegui.macos_font_candidates() {
			if os.exists(candidate) {
				candidates << candidate
			}
		}
	} $else $if linux {
		for candidate in simplegui.linux_font_candidates() {
			if os.exists(candidate) {
				candidates << candidate
			}
		}
	}
	return candidates
}

// resolve_custom_font_for_platform detects the primary available system TTF font.
fn resolve_custom_font_for_platform() string {
	candidates := get_platform_font_candidates()
	if candidates.len > 0 {
		return candidates[0]
	}
	return simplegui.resolve_window_font_path()
}

// apply_typography_to_form dynamically updates font size, weight, family, and color across all interactive form elements.
fn apply_typography_to_form(mut win simplegui.SimpleWindow, font_path string, font_size int, is_bold bool, hex_color string) {
	font_filename := if font_path.len > 0 { os.file_name(font_path) } else { 'Default Font' }
	font_weight := if is_bold { 'Bold' } else { 'Regular' }

	win.set_font_path(font_path)
	win.set_state('active_font_path', font_path)
	win.set_state('active_font_name', font_filename)
	win.set_state_int('font_size', font_size)
	win.set_state_bool('font_bold', is_bold)
	win.set_state('font_color', hex_color)

	// 1. Form Header & Description
	win.set_control_font_size('lbl_form_header', font_size + 4)
	win.set_control_font_bold('lbl_form_header', true)
	win.set_control_font_color('lbl_form_header', hex_color)
	win.set_control_font_name('lbl_form_header', font_path)

	win.set_control_font_size('lbl_form_subhead', math.max(11, font_size - 3))
	win.set_control_font_bold('lbl_form_subhead', false)
	win.set_control_font_color('lbl_form_subhead', '#8e8e93')
	win.set_control_font_name('lbl_form_subhead', font_path)

	// 2. Form Field Labels
	form_labels := [
		'lbl_fname',
		'lbl_role',
		'lbl_email',
		'lbl_dept',
		'lbl_bio',
	]
	for lbl in form_labels {
		win.set_control_font_size(lbl, font_size)
		win.set_control_font_bold(lbl, is_bold)
		win.set_control_font_color(lbl, hex_color)
		win.set_control_font_name(lbl, font_path)
	}

	// 3. Form Interactive Inputs
	form_inputs := [
		'inp_fname',
		'inp_role',
		'inp_email',
		'inp_dept',
		'inp_bio',
	]
	for inp in form_inputs {
		win.set_control_font_size(inp, font_size)
		win.set_control_font_bold(inp, is_bold)
		win.set_control_font_color(inp, hex_color)
		win.set_control_font_name(inp, font_path)
	}

	// 4. Form Options (Checkbox & Switch)
	win.set_control_font_size('chk_newsletter', font_size)
	win.set_control_font_bold('chk_newsletter', is_bold)
	win.set_control_font_color('chk_newsletter', hex_color)
	win.set_control_font_name('chk_newsletter', font_path)

	win.set_control_font_size('sw_telemetry', font_size)
	win.set_control_font_bold('sw_telemetry', is_bold)
	win.set_control_font_color('sw_telemetry', hex_color)
	win.set_control_font_name('sw_telemetry', font_path)

	// 5. Form Action Buttons
	win.set_control_font_size('btn_submit', font_size)
	win.set_control_font_bold('btn_submit', true)
	win.set_control_font_name('btn_submit', font_path)

	win.set_control_font_size('btn_reset', font_size)
	win.set_control_font_bold('btn_reset', is_bold)
	win.set_control_font_name('btn_reset', font_path)

	win.set_control_font_size('btn_preview', font_size)
	win.set_control_font_bold('btn_preview', is_bold)
	win.set_control_font_name('btn_preview', font_path)

	// 6. Form Status Feedback Banner
	win.set_control_font_size('lbl_form_status', math.max(11, font_size - 2))
	win.set_control_font_bold('lbl_form_status', is_bold)
	win.set_control_font_color('lbl_form_status', hex_color)
	win.set_control_font_name('lbl_form_status', font_path)
	win.set_text('lbl_form_status', 'Form Status: Ready • Active Font: ${font_filename} (${font_size}px, ${font_weight})')

	// 7. Update Control Panel Status Labels
	win.set_text('lbl_active_font', 'Active System Font: ' + font_filename + ' (' + font_path + ')')
	win.set_text('lbl_style_status', 'Active: ${font_filename} | ${font_size}px | ${font_weight} | ${hex_color}')
}

fn main() {
	mut win := simplegui.new_simple_window('18 - Custom Font Loading & Live Form Typography', 1060, 980)
	win.set_theme('Apple Dark')

	// Initial font path configuration at startup
	initial_font_path := resolve_custom_font_for_platform()
	initial_font_name := if initial_font_path.len > 0 { os.file_name(initial_font_path) } else { 'Default TTF' }
	if initial_font_path.len > 0 {
		win.set_font_path(initial_font_path)
	}

	// Initialize state store
	win.set_state_int('font_size', 15)
	win.set_state_bool('font_bold', false)
	win.set_state('font_color', '#0a84ff')
	win.set_state('active_font_name', initial_font_name)
	win.set_state('active_font_path', if initial_font_path.len > 0 { initial_font_path } else { 'Default Sokol TTF' })

	win.add_heading('Custom Font Loading & Live Form Typography')
	win.add_label('lbl_subhead_guide', 'Dynamic Typography & Real-time Form Engine — Click any font, mode, size, or preset to update the form live.')
	win.control('lbl_subhead_guide').set_font_size(13).set_font_color('#98989d')

	// 1. Font Family & System Discovery
	active_path := win.get_state('active_font_path')
	win.group('grp_font_info', 'Font Family & Render Mode Selection', fn [active_path] (mut win simplegui.SimpleWindow) {
		win.add_label('lbl_active_font', 'Active System Font: ' + active_path)

		win.grid('grid_font_modes', 5, 8, fn (mut win simplegui.SimpleWindow) {
			win.add_button('btn_mode_sans', 'Sans-Serif')
			win.bind_click('btn_mode_sans', fn (mut win simplegui.SimpleWindow) {
				font_path := simplegui.resolve_font_path_by_category('sans')
				apply_typography_to_form(mut win, font_path, win.get_state_int('font_size'), win.get_state_bool('font_bold'), win.get_state('font_color'))
				win.push_toast('Render Mode', 'Switched to Proportional Sans-Serif', 'info', 2000)
			})

			win.add_button('btn_mode_mono', 'Monospace Code')
			win.bind_click('btn_mode_mono', fn (mut win simplegui.SimpleWindow) {
				font_path := simplegui.resolve_font_path_by_category('mono')
				apply_typography_to_form(mut win, font_path, win.get_state_int('font_size'), win.get_state_bool('font_bold'), win.get_state('font_color'))
				win.push_toast('Render Mode', 'Switched to Monospace Fixed-Width', 'info', 2000)
			})

			win.add_button('btn_mode_serif', 'Serif Classic')
			win.bind_click('btn_mode_serif', fn (mut win simplegui.SimpleWindow) {
				font_path := simplegui.resolve_font_path_by_category('serif')
				apply_typography_to_form(mut win, font_path, win.get_state_int('font_size'), win.get_state_bool('font_bold'), win.get_state('font_color'))
				win.push_toast('Render Mode', 'Switched to Serif Classic', 'info', 2000)
			})

			win.add_button('btn_mode_display', 'Display Impact')
			win.bind_click('btn_mode_display', fn (mut win simplegui.SimpleWindow) {
				font_path := simplegui.resolve_font_path_by_category('display')
				apply_typography_to_form(mut win, font_path, win.get_state_int('font_size'), win.get_state_bool('font_bold'), win.get_state('font_color'))
				win.push_toast('Render Mode', 'Switched to Display Impact', 'info', 2000)
			})

			win.add_button('btn_mode_casual', 'Casual Script')
			win.bind_click('btn_mode_casual', fn (mut win simplegui.SimpleWindow) {
				font_path := simplegui.resolve_font_path_by_category('casual')
				apply_typography_to_form(mut win, font_path, win.get_state_int('font_size'), win.get_state_bool('font_bold'), win.get_state('font_color'))
				win.push_toast('Render Mode', 'Switched to Casual Comic Style', 'info', 2000)
			})
		})

		candidates := get_platform_font_candidates()
		if candidates.len > 0 {
			win.add_label('lbl_cand_info', 'Discovered System TTF Fonts on this Machine (Click any to test live):')
			cols := math.min(6, candidates.len)
			win.grid('grid_font_candidates', cols, 8, fn [candidates] (mut win simplegui.SimpleWindow) {
				for idx, candidate in candidates {
					btn_id := 'btn_font_cand_${idx}'
					font_filename := os.file_name(candidate)
					lower := font_filename.to_lower()
					tag := if lower.contains('mono') || lower.contains('courier') {
						'[Mono] '
					} else if lower.contains('times') || lower.contains('georgia') || lower.contains('serif') {
						'[Serif] '
					} else if lower.contains('impact') {
						'[Display] '
					} else if lower.contains('comic') {
						'[Casual] '
					} else {
						'[Sans] '
					}
					font_base := font_filename.replace('.ttf', '').replace('.ttc', '').replace('.otf', '')
					win.add_button(btn_id, tag + font_base)
					win.bind_click(btn_id, fn [candidate, font_filename] (mut win simplegui.SimpleWindow) {
						apply_typography_to_form(mut win, candidate, win.get_state_int('font_size'), win.get_state_bool('font_bold'), win.get_state('font_color'))
						win.push_toast('Font Selected', 'Configured: ' + font_filename, 'success', 2500)
					})
				}
			})
		}
	})

	// 2. Dynamic Typography Style Controls (Sizes, Weights & Presets)
	win.group('grp_style_controls', 'Live Typography Controls (Size, Weight & Aesthetic Presets)', fn (mut win simplegui.SimpleWindow) {
		win.add_label('lbl_style_status', 'Active: Sans-Serif | 15px | Regular | #0a84ff')

		// Row 1: High-Contrast Dynamic Sizes & Bold Toggle
		win.grid('grid_size_controls', 5, 8, fn (mut win simplegui.SimpleWindow) {
			win.add_button('btn_size_13', '13px (Compact)')
			win.bind_click('btn_size_13', fn (mut win simplegui.SimpleWindow) {
				apply_typography_to_form(mut win, win.get_state('active_font_path'), 13, win.get_state_bool('font_bold'), win.get_state('font_color'))
			})

			win.add_button('btn_size_15', '15px (Standard)')
			win.bind_click('btn_size_15', fn (mut win simplegui.SimpleWindow) {
				apply_typography_to_form(mut win, win.get_state('active_font_path'), 15, win.get_state_bool('font_bold'), win.get_state('font_color'))
			})

			win.add_button('btn_size_18', '18px (Comfortable)')
			win.bind_click('btn_size_18', fn (mut win simplegui.SimpleWindow) {
				apply_typography_to_form(mut win, win.get_state('active_font_path'), 18, win.get_state_bool('font_bold'), win.get_state('font_color'))
			})

			win.add_button('btn_size_22', '22px (Large)')
			win.bind_click('btn_size_22', fn (mut win simplegui.SimpleWindow) {
				apply_typography_to_form(mut win, win.get_state('active_font_path'), 22, win.get_state_bool('font_bold'), win.get_state('font_color'))
			})

			win.add_button('btn_toggle_weight', 'Toggle Bold / Regular')
			win.bind_click('btn_toggle_weight', fn (mut win simplegui.SimpleWindow) {
				is_bold := win.toggle_state_bool('font_bold')
				apply_typography_to_form(mut win, win.get_state('active_font_path'), win.get_state_int('font_size'), is_bold, win.get_state('font_color'))
			})
		})

		// Row 2: Curated 1-Click Aesthetic Presets
		win.grid('grid_colors_presets', 5, 8, fn (mut win simplegui.SimpleWindow) {
			win.add_button('btn_preset_modern', 'Modern Tech')
			win.control('btn_preset_modern').set_bg_color('#0a84ff').set_font_color('#ffffff')
			win.bind_click('btn_preset_modern', fn (mut win simplegui.SimpleWindow) {
				font_path := simplegui.resolve_font_path_by_category('sans')
				apply_typography_to_form(mut win, font_path, 17, true, '#0a84ff')
				win.push_toast('Preset Applied', 'Modern Tech Sans (#0a84ff)', 'info', 2000)
			})

			win.add_button('btn_preset_code', 'Hacker Console')
			win.control('btn_preset_code').set_bg_color('#30d158').set_font_color('#ffffff')
			win.bind_click('btn_preset_code', fn (mut win simplegui.SimpleWindow) {
				font_path := simplegui.resolve_font_path_by_category('mono')
				apply_typography_to_form(mut win, font_path, 15, false, '#30d158')
				win.push_toast('Preset Applied', 'Hacker Console Monospace (#30d158)', 'info', 2000)
			})

			win.add_button('btn_preset_editorial', 'Warm Editorial')
			win.control('btn_preset_editorial').set_bg_color('#ff9f0a').set_font_color('#ffffff')
			win.bind_click('btn_preset_editorial', fn (mut win simplegui.SimpleWindow) {
				font_path := simplegui.resolve_font_path_by_category('serif')
				apply_typography_to_form(mut win, font_path, 17, true, '#ff9f0a')
				win.push_toast('Preset Applied', 'Warm Editorial Serif (#ff9f0a)', 'info', 2000)
			})

			win.add_button('btn_preset_casual', 'Playful Studio')
			win.control('btn_preset_casual').set_bg_color('#ff375f').set_font_color('#ffffff')
			win.bind_click('btn_preset_casual', fn (mut win simplegui.SimpleWindow) {
				font_path := simplegui.resolve_font_path_by_category('casual')
				apply_typography_to_form(mut win, font_path, 16, false, '#ff375f')
				win.push_toast('Preset Applied', 'Playful Studio Casual (#ff375f)', 'info', 2000)
			})

			win.add_button('btn_preset_cyber', 'Cyber Impact')
			win.control('btn_preset_cyber').set_bg_color('#bf5af2').set_font_color('#ffffff')
			win.bind_click('btn_preset_cyber', fn (mut win simplegui.SimpleWindow) {
				font_path := simplegui.resolve_font_path_by_category('display')
				apply_typography_to_form(mut win, font_path, 19, true, '#bf5af2')
				win.push_toast('Preset Applied', 'Cyber Violet Display (#bf5af2)', 'info', 2000)
			})
		})
	})

	// 3. Live Interactive Form (The Centerpiece of typography preview)
	win.group('grp_form_preview', 'Live Form Preview (Interactive Typography Testing)', fn (mut win simplegui.SimpleWindow) {
		win.add_label('lbl_form_header', 'Employee Onboarding & Account Verification')
		win.add_label('lbl_form_subhead', 'Fill out the fields below. Every input, label, checkbox, switch, and button updates live with the selected typography.')

		// 2-Column Form Fields
		win.begin_grid('grid_form_fields', 2, 10)
		win.add_label('lbl_fname', 'Full Legal Name:')
		win.add_label('lbl_role', 'Designation / Role:')
		win.add_input('inp_fname', 'Ada Lovelace')
		win.add_input('inp_role', 'Principal Algorithm Architect')

		win.add_label('lbl_email', 'Work Email:')
		win.add_label('lbl_dept', 'Department & Team:')
		win.add_input('inp_email', 'ada.lovelace@babbage-labs.io')
		win.add_input('inp_dept', 'Applied Mathematics & Computing')
		win.end_grid()

		// Full-Width Mission Bio Statement
		win.add_label('lbl_bio', 'Personal Mission Statement / Bio:')
		win.add_input('inp_bio', 'Pioneering analytical computing engines, algorithm designs, and dynamic typography systems.')
		win.control('inp_bio').set_expand_fill(true)

		// Form Option Toggles (2-column grid for clean separation)
		win.begin_grid('grid_form_options', 2, 16)
		win.add_checkbox('chk_newsletter', 'Subscribe to developer updates', true)
		win.add_switch('sw_telemetry', 'Enable real-time telemetry sync', true)
		win.end_grid()

		// Form Action Buttons
		win.begin_row('row_form_actions')
		win.add_button('btn_submit', 'Submit Registration')
		win.control('btn_submit').set_bg_color('#0a84ff').set_font_color('#ffffff').set_width(200)

		win.add_button('btn_reset', 'Reset Form')
		win.control('btn_reset').set_bg_color('#3a3a3c').set_font_color('#ffffff').set_width(150)

		win.add_button('btn_preview', 'Verify Profile')
		win.control('btn_preview').set_bg_color('#30d158').set_font_color('#ffffff').set_width(170)
		win.end_row()

		// Form Status Banner
		win.add_label('lbl_form_status', 'Form Status: Ready • All controls rendering in dynamic font')
		win.control('lbl_form_status').set_font_size(13).set_font_color('#30d158')

		// Button Event Handlers
		win.bind_click('btn_submit', fn (mut win simplegui.SimpleWindow) {
			fname := win.get_text('inp_fname')
			role := win.get_text('inp_role')
			email := win.get_text('inp_email')
			active_font := win.get_state('active_font_name')
			win.push_toast('Registration Submitted', '${fname} (${role}) submitted in ${active_font}!', 'success', 3500)
			win.set_text('lbl_form_status', 'Form Status: Submitted successfully! Profile verified for ${fname}')
			println('Form Submitted! Name: ${fname}, Role: ${role}, Email: ${email}, Font: ${active_font}')
		})

		win.bind_click('btn_reset', fn (mut win simplegui.SimpleWindow) {
			win.set_text('inp_fname', 'Ada Lovelace')
			win.set_text('inp_role', 'Principal Algorithm Architect')
			win.set_text('inp_email', 'ada.lovelace@babbage-labs.io')
			win.set_text('inp_dept', 'Applied Mathematics & Computing')
			win.set_text('inp_bio', 'Pioneering analytical computing engines, algorithm designs, and dynamic typography systems.')
			win.set_bool('chk_newsletter', true)
			win.set_bool('sw_telemetry', true)
			win.push_toast('Form Reset', 'All input fields restored to default values', 'info', 2500)
			win.set_text('lbl_form_status', 'Form Status: Reset to default values')
		})

		win.bind_click('btn_preview', fn (mut win simplegui.SimpleWindow) {
			fname := win.get_text('inp_fname')
			dept := win.get_text('inp_dept')
			active_font := win.get_state('active_font_name')
			size := win.get_state_int('font_size')
			win.push_toast('Profile Verification', '${fname} [${dept}] • Active Font: ${active_font} @ ${size}px', 'info', 3000)
		})
	})

	// Apply initial typography styling across all form controls
	apply_typography_to_form(mut win, initial_font_path, 15, false, '#0a84ff')

	win.run()
}

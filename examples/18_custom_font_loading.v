module main

import os
import simplegui

// get_platform_font_candidates returns available system font candidates on macOS or Linux.
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

// apply_typography_styles updates font size, weight, and color across interactive preview controls.
fn apply_typography_styles(mut win simplegui.SimpleWindow, font_size int, is_bold bool, hex_color string) {
	// Dynamically adjust preview controls
	win.set_control_font_size('lbl_preview_headline', font_size + 6)
	win.set_control_font_bold('lbl_preview_headline', is_bold)
	win.set_control_font_color('lbl_preview_headline', hex_color)

	win.set_control_font_size('lbl_preview_body', font_size)
	win.set_control_font_bold('lbl_preview_body', is_bold)
	win.set_control_font_color('lbl_preview_body', hex_color)

	win.set_control_font_size('btn_preview_cta', font_size)
	win.set_control_font_bold('btn_preview_cta', is_bold)

	win.set_control_font_size('inp_preview_sample', font_size)

	// Sync status display
	bold_status := if is_bold { 'Bold' } else { 'Regular' }
	font_name := win.get_state('active_font_name')
	win.set_text('lbl_style_status', 'Active: ${font_name} | ${font_size}px | ${bold_status} | ${hex_color}')
}

fn main() {
	mut win := simplegui.new_simple_window('Dynamic Font Changing & Cross-Platform Typography', 740, 680)
	win.set_theme('Apple Dark')

	// Initial font path resolution
	initial_font_path := resolve_custom_font_for_platform()
	initial_font_name := if initial_font_path.len > 0 { os.file_name(initial_font_path) } else { 'Default TTF' }
	if initial_font_path.len > 0 {
		win.set_font_path(initial_font_path)
	}

	// Initialize state store for dynamic control sync
	win.set_state_int('font_size', 18)
	win.set_state_bool('font_bold', true)
	win.set_state('font_color', '#0a84ff')
	win.set_state('active_font_name', initial_font_name)
	win.set_state('active_font_path', if initial_font_path.len > 0 { initial_font_path } else { 'Default Sokol TTF' })

	win.add_heading('Dynamic Font Changing & Live Typography Demo')
	win.add_subheading('Interactive runtime font path switching, sizing, weights, colors & presets')

	// 1. Font Resolution & Dynamic System Font Selector
	active_path := win.get_state('active_font_path')
	win.group('grp_font_info', 'System Font Path Selector', fn [active_path] (mut win simplegui.SimpleWindow) {
		win.add_label('lbl_active_font', 'Active Font: ' + active_path)

		candidates := get_platform_font_candidates()
		if candidates.len > 0 {
			// Arrange candidates in compact 3-column grid
			win.grid('grid_font_candidates', 3, 6, fn [candidates] (mut win simplegui.SimpleWindow) {
				for idx, candidate in candidates {
					btn_id := 'btn_font_cand_${idx}'
					font_filename := os.file_name(candidate)
					win.add_button(btn_id, font_filename)
					win.bind_click(btn_id, fn [candidate, font_filename] (mut win simplegui.SimpleWindow) {
						win.set_font_path(candidate)
						win.set_state('active_font_name', font_filename)
						win.set_state('active_font_path', candidate)

						// Update font family on preview controls
						win.set_control_font_name('lbl_preview_headline', font_filename)
						win.set_control_font_name('lbl_preview_body', font_filename)
						win.set_control_font_name('btn_preview_cta', font_filename)
						win.set_control_font_name('inp_preview_sample', font_filename)

						win.set_text('lbl_active_font', 'Active Font: ' + font_filename + ' (' + candidate + ')')
						apply_typography_styles(mut win, win.get_state_int('font_size'), win.get_state_bool('font_bold'), win.get_state('font_color'))
						win.push_toast('Font Family Changed', 'Loaded: ' + font_filename, 'info', 2000)
					})
				}
			})
		}
	})

	// 2. Dynamic Typography Style Controls (Size, Weight, Color & Presets)
	win.group('grp_style_controls', 'Dynamic Font Controls & Style Presets', fn (mut win simplegui.SimpleWindow) {
		win.add_label('lbl_style_status', 'Active: Arial.ttf | 18px | Bold | #0a84ff')

		// Row 1: Font Size Steppers & Weight Toggle
		win.begin_row('row_size_controls')
		win.add_button('btn_size_14', '14px')
		win.bind_click('btn_size_14', fn (mut win simplegui.SimpleWindow) {
			win.set_state_int('font_size', 14)
			apply_typography_styles(mut win, 14, win.get_state_bool('font_bold'), win.get_state('font_color'))
		})

		win.add_button('btn_size_18', '18px')
		win.bind_click('btn_size_18', fn (mut win simplegui.SimpleWindow) {
			win.set_state_int('font_size', 18)
			apply_typography_styles(mut win, 18, win.get_state_bool('font_bold'), win.get_state('font_color'))
		})

		win.add_button('btn_size_24', '24px')
		win.bind_click('btn_size_24', fn (mut win simplegui.SimpleWindow) {
			win.set_state_int('font_size', 24)
			apply_typography_styles(mut win, 24, win.get_state_bool('font_bold'), win.get_state('font_color'))
		})

		win.add_button('btn_size_32', '32px')
		win.bind_click('btn_size_32', fn (mut win simplegui.SimpleWindow) {
			win.set_state_int('font_size', 32)
			apply_typography_styles(mut win, 32, win.get_state_bool('font_bold'), win.get_state('font_color'))
		})

		win.add_button('btn_size_dec', '[-] Size')
		win.bind_click('btn_size_dec', fn (mut win simplegui.SimpleWindow) {
			curr := win.get_state_int('font_size')
			next_sz := if curr > 10 { curr - 2 } else { 10 }
			win.set_state_int('font_size', next_sz)
			apply_typography_styles(mut win, next_sz, win.get_state_bool('font_bold'), win.get_state('font_color'))
		})

		win.add_button('btn_size_inc', '[+] Size')
		win.bind_click('btn_size_inc', fn (mut win simplegui.SimpleWindow) {
			curr := win.get_state_int('font_size')
			next_sz := if curr < 44 { curr + 2 } else { 44 }
			win.set_state_int('font_size', next_sz)
			apply_typography_styles(mut win, next_sz, win.get_state_bool('font_bold'), win.get_state('font_color'))
		})

		win.add_button('btn_toggle_weight', 'Toggle Bold')
		win.bind_click('btn_toggle_weight', fn (mut win simplegui.SimpleWindow) {
			is_bold := win.toggle_state_bool('font_bold')
			apply_typography_styles(mut win, win.get_state_int('font_size'), is_bold, win.get_state('font_color'))
		})
		win.end_row()

		// Row 2: Color Swatches & Style Presets
		win.begin_row('row_colors_presets')
		win.add_button('btn_color_blue', 'Blue')
		win.control('btn_color_blue').set_bg_color('#0a84ff').set_font_color('#ffffff')
		win.bind_click('btn_color_blue', fn (mut win simplegui.SimpleWindow) {
			win.set_state('font_color', '#0a84ff')
			apply_typography_styles(mut win, win.get_state_int('font_size'), win.get_state_bool('font_bold'), '#0a84ff')
		})

		win.add_button('btn_color_green', 'Green')
		win.control('btn_color_green').set_bg_color('#30d158').set_font_color('#ffffff')
		win.bind_click('btn_color_green', fn (mut win simplegui.SimpleWindow) {
			win.set_state('font_color', '#30d158')
			apply_typography_styles(mut win, win.get_state_int('font_size'), win.get_state_bool('font_bold'), '#30d158')
		})

		win.add_button('btn_color_orange', 'Orange')
		win.control('btn_color_orange').set_bg_color('#ff9f0a').set_font_color('#ffffff')
		win.bind_click('btn_color_orange', fn (mut win simplegui.SimpleWindow) {
			win.set_state('font_color', '#ff9f0a')
			apply_typography_styles(mut win, win.get_state_int('font_size'), win.get_state_bool('font_bold'), '#ff9f0a')
		})

		win.add_button('btn_color_purple', 'Purple')
		win.control('btn_color_purple').set_bg_color('#bf5af2').set_font_color('#ffffff')
		win.bind_click('btn_color_purple', fn (mut win simplegui.SimpleWindow) {
			win.set_state('font_color', '#bf5af2')
			apply_typography_styles(mut win, win.get_state_int('font_size'), win.get_state_bool('font_bold'), '#bf5af2')
		})

		win.add_button('btn_preset_hero', 'Hero Preset')
		win.bind_click('btn_preset_hero', fn (mut win simplegui.SimpleWindow) {
			win.set_state_int('font_size', 26)
			win.set_state_bool('font_bold', true)
			win.set_state('font_color', '#0a84ff')
			apply_typography_styles(mut win, 26, true, '#0a84ff')
		})

		win.add_button('btn_preset_accent', 'Accent Preset')
		win.bind_click('btn_preset_accent', fn (mut win simplegui.SimpleWindow) {
			win.set_state_int('font_size', 18)
			win.set_state_bool('font_bold', true)
			win.set_state('font_color', '#30d158')
			apply_typography_styles(mut win, 18, true, '#30d158')
		})

		win.add_button('btn_preset_code', 'Monospace Code')
		win.bind_click('btn_preset_code', fn (mut win simplegui.SimpleWindow) {
			win.set_state_int('font_size', 16)
			win.set_state_bool('font_bold', false)
			win.set_state('font_color', '#bf5af2')

			win.set_control_font_name('lbl_preview_headline', 'Monaco')
			win.set_control_font_name('lbl_preview_body', 'Monaco')
			win.set_control_font_name('btn_preview_cta', 'Monaco')
			win.set_control_font_name('inp_preview_sample', 'Monaco')
			win.set_state('active_font_name', 'Monaco.ttf')
			apply_typography_styles(mut win, 16, false, '#bf5af2')
		})
		win.end_row()
	})

	// 3. Live Typography Preview Canvas
	win.group('grp_preview_canvas', 'Live Canvas Preview', fn (mut win simplegui.SimpleWindow) {
		win.add_label('lbl_preview_headline', 'Dynamic Headline Text Preview')
		win.control('lbl_preview_headline')
			.set_font_size(24)
			.set_font_bold(true)
			.set_font_color('#0a84ff')

		win.add_label('lbl_preview_body', 'Sample Body Text: Sphinx of black quartz, judge my vow 0123456789')
		win.control('lbl_preview_body')
			.set_font_size(18)
			.set_font_bold(true)
			.set_font_color('#0a84ff')

		win.add_button('btn_preview_cta', '[Aa] Styled Typography Button')
		win.control('btn_preview_cta')
			.set_width(320)
			.set_height(40)
			.set_font_size(18)
			.set_font_bold(true)
			.set_bg_color('#5e5ce6')
			.set_font_color('#ffffff')

		win.add_input('inp_preview_sample', '')
		win.set_control_placeholder('inp_preview_sample', 'Type custom text here to preview live rendering...')
		win.control('inp_preview_sample')
			.set_width(420)
			.set_font_size(18)

		// Live-sync text typing to preview labels
		win.bind_change('inp_preview_sample', fn (mut win simplegui.SimpleWindow) {
			typed := win.get_text('inp_preview_sample')
			if typed.len > 0 {
				win.set_text('lbl_preview_headline', typed)
				win.set_text('lbl_preview_body', typed)
				win.set_text('btn_preview_cta', '[Aa] ' + typed)
			} else {
				win.set_text('lbl_preview_headline', 'Dynamic Headline Text Preview')
				win.set_text('lbl_preview_body', 'Sample Body Text: Sphinx of black quartz, judge my vow 0123456789')
				win.set_text('btn_preview_cta', '[Aa] Styled Typography Button')
			}
		})
	})

	// 4. Instructions & Platform Guide
	win.group('grp_instructions', 'Platform Font Setup Instructions', fn (mut win simplegui.SimpleWindow) {
		win.add_label('lbl_mac_info', 'macOS: Searches /System/Library/Fonts/Supplemental & /Library/Fonts')
		win.add_label('lbl_prog_info', 'Programmatic: win.set_font_path("/path/to/font.ttf") dynamically changes active font')
	})

	win.run()
}

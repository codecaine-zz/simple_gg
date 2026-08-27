// Example 18: Custom Font Loading & Dynamic Typography Demo
module main

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

// apply_typography_styles updates font size, weight, monospace styling, and color across preview controls.
fn apply_typography_styles(mut win simplegui.SimpleWindow, font_size int, is_bold bool, is_mono bool, hex_color string) {
	font_mode_name := if is_mono { 'Monospace' } else { 'Sans-Serif' }

	// 1. Headline Label
	win.set_control_font_size('lbl_preview_headline', font_size + 8)
	win.set_control_font_bold('lbl_preview_headline', is_bold)
	win.set_control_font_color('lbl_preview_headline', hex_color)
	win.set_control_font_name('lbl_preview_headline', if is_mono { 'mono' } else { 'sans' })

	// 2. Subtitle / Body Label
	win.set_control_font_size('lbl_preview_body', font_size)
	win.set_control_font_bold('lbl_preview_body', is_bold)
	win.set_control_font_color('lbl_preview_body', hex_color)
	win.set_control_font_name('lbl_preview_body', if is_mono { 'mono' } else { 'sans' })

	// 3. CTA Action Button
	win.set_control_font_size('btn_preview_cta', font_size)
	win.set_control_font_bold('btn_preview_cta', is_bold)
	win.set_control_font_name('btn_preview_cta', if is_mono { 'mono' } else { 'sans' })

	// 4. Sample Input Field
	win.set_control_font_size('inp_preview_sample', font_size)
	win.set_control_font_bold('inp_preview_sample', is_bold)
	win.set_control_font_name('inp_preview_sample', if is_mono { 'mono' } else { 'sans' })

	// Update Status Summary
	bold_status := if is_bold { 'Bold' } else { 'Regular' }
	win.set_text('lbl_style_status', 'Active: ${font_mode_name} | ${font_size}px | ${bold_status} | ${hex_color}')
}

fn main() {
	mut win := simplegui.new_simple_window('18 - Custom Font Loading & Dynamic Typography', 820, 720)
	win.set_theme('Apple Dark')

	// Initial font path configuration at startup
	initial_font_path := resolve_custom_font_for_platform()
	initial_font_name := if initial_font_path.len > 0 { os.file_name(initial_font_path) } else { 'Default TTF' }
	if initial_font_path.len > 0 {
		win.set_font_path(initial_font_path)
	}

	// Initialize state store
	win.set_state_int('font_size', 20)
	win.set_state_bool('font_bold', true)
	win.set_state_bool('font_mono', false)
	win.set_state('font_color', '#0a84ff')
	win.set_state('active_font_name', initial_font_name)
	win.set_state('active_font_path', if initial_font_path.len > 0 { initial_font_path } else { 'Default Sokol TTF' })

	win.add_heading('Custom Font Loading & Dynamic Typography')
	win.add_alert_banner('alert_tip', 'Typography Architecture Guide',
		'Custom TTF/OTF fonts are loaded at window launch via win.set_font_path() or SIMPLEGUI_FONT_PATH. Dynamic sizes (12-38px), weights (Bold/Regular), Monospace/Sans modes, and colors update live at runtime.',
		'info')

	// 1. Font Family & Mode Selection
	active_path := win.get_state('active_font_path')
	win.group('grp_font_info', 'Font Family & Render Mode', fn [active_path] (mut win simplegui.SimpleWindow) {
		win.add_label('lbl_active_font', 'Startup TTF Font: ' + active_path)

		win.begin_row('row_font_modes')
		win.add_button('btn_mode_sans', '[Sans-Serif] Proportional Mode')
		win.add_button('btn_mode_mono', '[Monospace] Code & Terminal Mode')
		win.end_row()

		win.bind_click('btn_mode_sans', fn (mut win simplegui.SimpleWindow) {
			win.set_state_bool('font_mono', false)
			apply_typography_styles(mut win, win.get_state_int('font_size'), win.get_state_bool('font_bold'), false, win.get_state('font_color'))
			win.push_toast('Render Mode', 'Switched to Proportional Sans-Serif', 'info', 2000)
		})

		win.bind_click('btn_mode_mono', fn (mut win simplegui.SimpleWindow) {
			win.set_state_bool('font_mono', true)
			apply_typography_styles(mut win, win.get_state_int('font_size'), win.get_state_bool('font_bold'), true, win.get_state('font_color'))
			win.push_toast('Render Mode', 'Switched to Monospace Fixed-Width', 'info', 2000)
		})

		candidates := get_platform_font_candidates()
		if candidates.len > 0 {
			win.add_label('lbl_cand_info', 'Discovered System TTF Fonts on this Machine:')
			win.grid('grid_font_candidates', 3, 6, fn [candidates] (mut win simplegui.SimpleWindow) {
				for idx, candidate in candidates {
					btn_id := 'btn_font_cand_${idx}'
					font_filename := os.file_name(candidate)
					is_mono_cand := font_filename.to_lower().contains('mono') || font_filename.to_lower().contains('courier')
					tag := if is_mono_cand { '[Mono] ' } else { '[Sans] ' }
					win.add_button(btn_id, tag + font_filename)
					win.bind_click(btn_id, fn [candidate, font_filename, is_mono_cand] (mut win simplegui.SimpleWindow) {
						win.set_state('active_font_name', font_filename)
						win.set_state('active_font_path', candidate)
						win.set_state_bool('font_mono', is_mono_cand)
						win.set_text('lbl_active_font', 'Startup TTF Font: ' + font_filename + ' (' + candidate + ')')
						apply_typography_styles(mut win, win.get_state_int('font_size'), win.get_state_bool('font_bold'), is_mono_cand, win.get_state('font_color'))
						win.push_toast('Font Selected', 'Configured: ' + font_filename, 'success', 2500)
					})
				}
			})
		}
	})

	// 2. Dynamic Typography Style Controls (High-contrast Sizes, Weights, Colors)
	win.group('grp_style_controls', 'Live Typography Controls (Size, Weight & Color)', fn (mut win simplegui.SimpleWindow) {
		win.add_label('lbl_style_status', 'Active: Sans-Serif | 20px | Bold | #0a84ff')

		// Row 1: High-Contrast Dynamic Sizes
		win.grid('grid_size_controls', 5, 8, fn (mut win simplegui.SimpleWindow) {
			win.add_button('btn_size_12', '12px (Small)')
			win.bind_click('btn_size_12', fn (mut win simplegui.SimpleWindow) {
				win.set_state_int('font_size', 12)
				apply_typography_styles(mut win, 12, win.get_state_bool('font_bold'), win.get_state_bool('font_mono'), win.get_state('font_color'))
			})

			win.add_button('btn_size_16', '16px (Body)')
			win.bind_click('btn_size_16', fn (mut win simplegui.SimpleWindow) {
				win.set_state_int('font_size', 16)
				apply_typography_styles(mut win, 16, win.get_state_bool('font_bold'), win.get_state_bool('font_mono'), win.get_state('font_color'))
			})

			win.add_button('btn_size_22', '22px (Title)')
			win.bind_click('btn_size_22', fn (mut win simplegui.SimpleWindow) {
				win.set_state_int('font_size', 22)
				apply_typography_styles(mut win, 22, win.get_state_bool('font_bold'), win.get_state_bool('font_mono'), win.get_state('font_color'))
			})

			win.add_button('btn_size_30', '30px (Display)')
			win.bind_click('btn_size_30', fn (mut win simplegui.SimpleWindow) {
				win.set_state_int('font_size', 30)
				apply_typography_styles(mut win, 30, win.get_state_bool('font_bold'), win.get_state_bool('font_mono'), win.get_state('font_color'))
			})

			win.add_button('btn_toggle_weight', 'Toggle Bold / Regular')
			win.bind_click('btn_toggle_weight', fn (mut win simplegui.SimpleWindow) {
				is_bold := win.toggle_state_bool('font_bold')
				apply_typography_styles(mut win, win.get_state_int('font_size'), is_bold, win.get_state_bool('font_mono'), win.get_state('font_color'))
			})
		})

		// Row 2: Color Palette Swatches & 1-Click Presets
		win.grid('grid_colors_presets', 4, 8, fn (mut win simplegui.SimpleWindow) {
			win.add_button('btn_preset_hero', '★ Hero Display')
			win.control('btn_preset_hero').set_bg_color('#0a84ff').set_font_color('#ffffff')
			win.bind_click('btn_preset_hero', fn (mut win simplegui.SimpleWindow) {
				win.set_state_int('font_size', 30)
				win.set_state_bool('font_bold', true)
				win.set_state_bool('font_mono', false)
				win.set_state('font_color', '#0a84ff')
				apply_typography_styles(mut win, 30, true, false, '#0a84ff')
			})

			win.add_button('btn_preset_code', '⌨ Code Studio')
			win.control('btn_preset_code').set_bg_color('#30d158').set_font_color('#ffffff')
			win.bind_click('btn_preset_code', fn (mut win simplegui.SimpleWindow) {
				win.set_state_int('font_size', 16)
				win.set_state_bool('font_bold', false)
				win.set_state_bool('font_mono', true)
				win.set_state('font_color', '#30d158')
				apply_typography_styles(mut win, 16, false, true, '#30d158')
			})

			win.add_button('btn_preset_editorial', '✦ Warm Editorial')
			win.control('btn_preset_editorial').set_bg_color('#ff9f0a').set_font_color('#ffffff')
			win.bind_click('btn_preset_editorial', fn (mut win simplegui.SimpleWindow) {
				win.set_state_int('font_size', 22)
				win.set_state_bool('font_bold', true)
				win.set_state_bool('font_mono', false)
				win.set_state('font_color', '#ff9f0a')
				apply_typography_styles(mut win, 22, true, false, '#ff9f0a')
			})

			win.add_button('btn_preset_cyber', '⚡ Cyber Violet')
			win.control('btn_preset_cyber').set_bg_color('#bf5af2').set_font_color('#ffffff')
			win.bind_click('btn_preset_cyber', fn (mut win simplegui.SimpleWindow) {
				win.set_state_int('font_size', 26)
				win.set_state_bool('font_bold', true)
				win.set_state_bool('font_mono', true)
				win.set_state('font_color', '#bf5af2')
				apply_typography_styles(mut win, 26, true, true, '#bf5af2')
			})
		})
	})

	// 3. Live Typography Preview Canvas
	win.group('grp_preview_canvas', 'Live Typography Canvas Preview', fn (mut win simplegui.SimpleWindow) {
		win.add_label('lbl_preview_headline', 'Dynamic Headline Text Preview')
		win.control('lbl_preview_headline')
			.set_font_size(28)
			.set_font_bold(true)
			.set_font_color('#0a84ff')

		win.add_label('lbl_preview_body', 'Sample Body: The quick brown fox jumps over 13 lazy dogs. (0123456789)')
		win.control('lbl_preview_body')
			.set_font_size(18)
			.set_font_bold(true)
			.set_font_color('#0a84ff')

		win.add_button('btn_preview_cta', '[Aa] Interactive Styled Button')
		win.control('btn_preview_cta')
			.set_width(320)
			.set_height(40)
			.set_font_size(18)
			.set_font_bold(true)
			.set_bg_color('#5e5ce6')
			.set_font_color('#ffffff')

		win.add_input('inp_preview_sample', '')
		win.set_control_placeholder('inp_preview_sample', 'Type custom text here to preview live rendering across all elements...')
		win.control('inp_preview_sample')
			.set_width(460)
			.set_font_size(16)

		// Live-sync text typing to preview labels
		win.bind_change('inp_preview_sample', fn (mut win simplegui.SimpleWindow) {
			typed := win.get_text('inp_preview_sample')
			if typed.len > 0 {
				win.set_text('lbl_preview_headline', typed)
				win.set_text('lbl_preview_body', typed)
				win.set_text('btn_preview_cta', '[Aa] ' + typed)
			} else {
				win.set_text('lbl_preview_headline', 'Dynamic Headline Text Preview')
				win.set_text('lbl_preview_body', 'Sample Body: The quick brown fox jumps over 13 lazy dogs. (0123456789)')
				win.set_text('btn_preview_cta', '[Aa] Interactive Styled Button')
			}
		})
	})

	win.run()
}

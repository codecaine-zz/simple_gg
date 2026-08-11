module main

import os
import simplegui

// resolve_custom_font_for_platform detects available system TTF fonts on macOS and Linux.
fn resolve_custom_font_for_platform() string {
	$if macos {
		// Common macOS TTF system font candidate paths
		mac_candidates := [
			'/System/Library/Fonts/Supplemental/Arial.ttf',
			'/System/Library/Fonts/Supplemental/Helvetica.ttf',
			'/System/Library/Fonts/Supplemental/Times New Roman.ttf',
			'/System/Library/Fonts/Monaco.ttf',
			'/Library/Fonts/Arial.ttf',
		]
		for candidate in mac_candidates {
			if os.exists(candidate) {
				return candidate
			}
		}
	} $else $if linux {
		// Prioritized Linux distro system font candidate paths
		for candidate in simplegui.linux_font_candidates() {
			if os.exists(candidate) {
				return candidate
			}
		}
	}
	return simplegui.resolve_window_font_path()
}

fn main() {
	mut win := simplegui.new_simple_window('Custom Font Loading & Cross-Platform Typography', 760, 680)
	win.set_theme('Apple Dark')

	// 1. Programmatically set custom font path for macOS or Linux
	font_path := resolve_custom_font_for_platform()
	if font_path.len > 0 {
		win.set_font_path(font_path)
	}

	win.add_heading('Cross-Platform Custom Font Loading Demo')
	win.add_subheading('Optimized crisp font rendering for macOS and Linux distros')

	// Information card displaying resolved font details
	active_font_display := if font_path.len > 0 { font_path } else { 'Default Sokol TTF Font' }
	win.group('grp_font_info', 'Font Resolution Details', fn [active_font_display] (mut win simplegui.SimpleWindow) {
		win.add_label('lbl_active_font', 'Active Loaded Font: ' + active_font_display)
		win.add_label('lbl_env_override', 'Environment Variable Override: SIMPLEGUI_FONT_PATH')
	})

	// Typography & control font styling showcase
	win.group('grp_typography', 'Typography & Style Controls', fn (mut win simplegui.SimpleWindow) {
		win.add_label('lbl_hero', '1. Large Headline Label (22px Bold)')
		win.control('lbl_hero')
			.set_font_size(22)
			.set_font_bold(true)
			.set_font_color('#0a84ff')

		win.add_label('lbl_sub', '2. Sub-headline Styled Text (16px Medium)')
		win.control('lbl_sub')
			.set_font_size(16)
			.set_font_color('#30d158')

		win.add_button('btn_font_sample', '[Aa] Styled Typography Button')
		win.control('btn_font_sample')
			.set_width(320)
			.set_height(44)
			.set_font_size(16)
			.set_font_bold(true)
			.set_bg_color('#5e5ce6')
			.set_font_color('#ffffff')

		win.add_input('inp_sample', 'Type sample text here to test font rendering...')
		win.control('inp_sample')
			.set_width(400)
			.set_font_size(15)
	})

	// Platform configuration instructions
	win.group('grp_instructions', 'Platform Font Setup Instructions', fn (mut win simplegui.SimpleWindow) {
		win.add_label('lbl_mac_info', 'macOS: Searches /System/Library/Fonts/Supplemental & /Library/Fonts')
		win.add_label('lbl_linux_info', 'Linux: Searches Ubuntu, Liberation Sans, DejaVu Sans, Noto Sans & ~/.local/share/fonts')
		win.add_label('lbl_prog_info', 'Programmatic: win.set_font_path("/path/to/font.ttf")')
	})

	win.run()
}

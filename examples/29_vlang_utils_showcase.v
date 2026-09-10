module main

import time
import simplegui
import statutils
import strutils
import colorutils
import mockutils
import timeutils
import semverutils

fn main() {
	mut win := simplegui.new_simple_window('Vlang Utils Showcase - simple_gg', 1080, 760)
	win.set_theme('Executive Slate')

	win.add_heading('Vlang Developer Utility Toolkit Showcase')
	win.add_subheading('30 Production-Grade Utility Modules Integrated Directly into simple_gg')
	win.add_divider('Text & String Transformations')

	// 1. String & Text Case Conversions (strutils)
	sample_text := 'hello_vlang_developer_suite'
	camel_str := strutils.to_camel_case(sample_text)
	pascal_str := strutils.to_pascal_case(sample_text)
	kebab_str := strutils.to_kebab_case(sample_text)
	slug := strutils.slugify('Modern UI & Rapid V Development!')
	masked := strutils.mask_email('developer@example.com')

	win.add_label('lbl_str_sample', 'Original: "${sample_text}"')
	win.add_label('lbl_str_camel', '  - CamelCase: ${camel_str}')
	win.add_label('lbl_str_pascal', '  - PascalCase: ${pascal_str}')
	win.add_label('lbl_str_kebab', '  - kebab-case: ${kebab_str}')
	win.add_label('lbl_str_slug', '  - Slugify: "${slug}"')
	win.add_label('lbl_str_masked', '  - Masked Email: ${masked}')
	win.add_divider('Statistical Analytics')

	// 2. Statistical Analysis & Modeling (statutils)
	data_points := [12.0, 15.5, 18.0, 22.5, 25.0, 29.5, 34.0, 42.0]
	mean := statutils.stats_mean(data_points)
	median := statutils.stats_median(data_points)
	std_dev := statutils.stats_sample_std_dev(data_points)
	iqr := statutils.stats_iqr(data_points)

	win.add_label('lbl_stat_pts', 'Data Points: ${data_points}')
	win.add_label('lbl_stat_mean', '  - Mean: ${mean:.2f} | Median: ${median:.2f}')
	win.add_label('lbl_stat_std', '  - Sample Std Dev: ${std_dev:.2f} | IQR: ${iqr:.2f}')
	win.add_divider('Colors & WCAG 2.1 Contrast')

	// 3. Color Theory & Accessibility (colorutils)
	bg := colorutils.hex_to_rgb('#0f172a') or { colorutils.RGB{0, 0, 0} }
	fg := colorutils.hex_to_rgb('#38bdf8') or { colorutils.RGB{255, 255, 255} }
	contrast := colorutils.contrast_ratio(bg, fg)
	wcag_pass := colorutils.is_accessible(fg, bg, 'AA')

	win.add_label('lbl_col_info', 'Evaluating BG: #0f172a vs FG: #38bdf8')
	win.add_label('lbl_col_contrast', '  - Contrast Ratio: ${contrast:.2f}:1 (WCAG AA Normal Text: ${wcag_pass})')
	win.add_divider('Time, SemVer & Mock Data')

	// 4. Time, Semver & Synthetic Mock Data (timeutils, semverutils, mockutils)
	user := mockutils.mock_user()
	t_past := timeutils.from_iso8601('2026-01-01T12:00:00Z') or { time.now() }
	rel_time := timeutils.time_ago(t_past)
	v1 := semverutils.parse('2.1.0') or { semverutils.SemVer{} }
	v2 := semverutils.parse('2.0.4') or { semverutils.SemVer{} }
	is_gt := semverutils.compare(v1, v2) > 0

	win.add_label('lbl_mock_user', '  - Synthetic Mock User: ${user.name} (${user.email}) - Role: ${user.role}')
	win.add_label('lbl_rel_time', '  - Relative Time Since Jan 2026: ${rel_time}')
	win.add_label('lbl_semver', '  - SemVer Compare (${v1} > ${v2}): ${is_gt}')

	println('Vlang Utils Showcase Window initialized successfully.')
	win.run()
}

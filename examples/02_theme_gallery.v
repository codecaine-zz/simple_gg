// Example 2: Complete Theme & Controls Gallery
module main

import simplegui

const initial_theme = 'Catppuccin Mocha'

fn theme_summary(theme_name string) string {
	theme := simplegui.get_theme(theme_name)
	return '${theme.description} | Accent ${theme.accent_color} | Surface ${theme.surface_color} | Border ${theme.border_color}'
}

fn sync_theme_controls(mut win simplegui.SimpleWindow) {
	win.set_text('theme_picker', win.theme.name)
	win.set_text('theme_details', theme_summary(win.theme.name))
	win.set_status_bar_text('gallery_status', 'Applied theme: ${win.theme.name}')
}

fn main() {
	mut win := simplegui.new_simple_window('02 - Complete Theme & Controls Gallery', 1120, 820)
	win.set_theme(initial_theme)
	win.set_fullscreen(true)

	win.add_menu('Theme', [
		simplegui.MenuItem{
			title: 'Toggle Light / Dark'
			shortcut: 'Ctrl+T'
			on_select: fn (mut win simplegui.SimpleWindow) {
				win.toggle_window_theme()
				sync_theme_controls(mut win)
			}
		},
		simplegui.MenuItem{
			title: 'Reset to Catppuccin Mocha'
			on_select: fn (mut win simplegui.SimpleWindow) {
				win.set_theme(initial_theme)
				sync_theme_controls(mut win)
			}
		},
	])
	win.add_menu('Help', [
		simplegui.MenuItem{
			title: 'About Theme Gallery'
			on_select: fn (mut win simplegui.SimpleWindow) {
				win.show_dialog_info('Complete Theme Gallery', 'Use the theme combobox to preview every control with any built-in palette.')
			}
		},
	])

	win.add_heading('Complete Theme & Controls Gallery')
	win.add_label('gallery_intro', 'Switch among all 87 themes. The controls below update immediately using each palette.')

	all_themes := simplegui.list_themes()
	win.begin_row('theme_toolbar')
	win.add_label('theme_picker_label', 'Active theme:')
	win.control('theme_picker_label').set_width(110)
	win.add_combobox('theme_picker', all_themes, initial_theme)
	win.control('theme_picker').set_width(300)
	win.add_badge('theme_count', '${all_themes.len} themes', 'info')
	win.add_button('btn_toggle_theme', 'Toggle Light / Dark')
	win.control('btn_toggle_theme').set_width(180)
	win.end_row()

	win.add_label('theme_details', theme_summary(initial_theme))
	win.add_divider('')

	win.begin_tab_container('theme_gallery_tabs', [
		'Forms & Inputs',
		'Selection & Data',
		'Feedback & Advanced',
	])

	// Form controls
	win.begin_tab_page('forms_page', 0)
	win.begin_row('form_columns')
	win.group('text_inputs_group', 'Text & Value Inputs', fn (mut win simplegui.SimpleWindow) {
		win.add_form_field('Username:', 'sample_username', 'developer@example.com')
		win.add_form_password('Password:', 'sample_password', 'theme-preview')
		win.add_form_search('Search:', 'sample_search', 'Search controls...')
		win.add_form_textarea('Notes:', 'sample_notes', 'Every control inherits the active theme surface, border, text, and accent colors.')
		win.set_control_height('sample_notes', 76)
		win.add_form_number('Build count:', 'sample_number', 42)
	})
	win.group('pickers_group', 'Pickers & Progress', fn (mut win simplegui.SimpleWindow) {
		win.add_form_date_picker('Release date:', 'sample_date', '2026-09-13')
		win.add_form_time_picker('Deploy time:', 'sample_time', '13:30')
		win.add_form_color_picker('Brand color:', 'sample_color', '#7aa2f7')
		win.add_form_slider('Volume:', 'sample_slider', 68)
		win.add_form_progress('Upload:', 'sample_progress', 74)
		win.add_rating('sample_rating', 4)
	})
	win.end_row()

	win.begin_row('boolean_controls')
	win.add_checkbox('sample_checkbox', 'Enable notifications', true)
	win.add_switch('sample_switch', 'Live synchronization', true)
	win.add_segmented_control('sample_segmented', ['Design', 'Code', 'Preview'], 'Preview')
	win.end_row()
	win.end_tab_page()

	// Selection, collections, and structured data
	win.begin_tab_page('selection_page', 1)
	win.begin_row('selection_row')
	win.group('single_selection_group', 'Single Selection', fn (mut win simplegui.SimpleWindow) {
		win.add_dropdown('sample_dropdown', ['Production', 'Staging', 'Development'], 'Production')
		win.add_combobox('sample_combo', ['V', 'TypeScript', 'Rust', 'Go'], 'V')
		win.add_list_box_with_selected('sample_list', [
			'Apple Dark',
			'Nord',
			'Dracula',
			'Tokyo Night',
		], 'Tokyo Night')
		win.set_control_height('sample_list', 112)
	})
	win.group('multi_selection_group', 'Multiple Selection', fn (mut win simplegui.SimpleWindow) {
		win.add_multi_list_box('sample_multi_list', [
			'macOS',
			'Linux',
			'Windows',
			'WebAssembly',
		], ['macOS', 'Linux'])
		win.set_control_height('sample_multi_list', 112)
		win.add_chip_group('sample_chips', ['Bug', 'Feature', 'Design', 'Docs'], [
			'Feature',
		])
		win.add_color_palette('sample_palette', [
			'#3b82f6',
			'#10b981',
			'#ef4444',
			'#f59e0b',
			'#8b5cf6',
			'#ec4899',
		], '#8b5cf6')
	})
	win.end_row()

	win.add_table('sample_table', ['ID', 'Component', 'State', 'Coverage'], [
		['01', 'Theme catalog', 'Ready', '100%'],
		['02', 'Native renderer', 'Ready', '100%'],
		['03', 'Control gallery', 'Active', '87 themes'],
		['04', 'Accessibility contrast', 'Passing', 'AA'],
	])
	win.set_control_height('sample_table', 150)
	win.end_tab_page()

	// Navigation, feedback, metrics, and developer controls
	win.begin_tab_page('advanced_page', 2)
	win.begin_row('identity_row')
	win.add_avatar('sample_avatar', 'SG', 'SimpleGUI Theme Lab')
	win.add_badge('sample_success_badge', 'Online', 'success')
	win.add_badge('sample_warning_badge', 'Preview', 'warning')
	win.add_badge('sample_info_badge', 'v2 Theme Tokens', 'info')
	win.end_row()

	win.add_breadcrumb('sample_breadcrumb', ['Home', 'Examples', 'Themes', 'Preview'])
	win.add_stepper('sample_steps', ['Choose', 'Inspect', 'Validate', 'Ship'], 2)

	win.begin_row('metric_row')
	win.add_metric_card('sample_metric', 'Theme Coverage', '87 / 87', '+76 imported', 'Bun RAD Studio parity')
	win.add_metric_trend('sample_trend', 'Render Consistency', '100%', '+12 surfaces', true, [
		62.0,
		68.0,
		74.0,
		81.0,
		90.0,
		100.0,
	])
	win.end_row()

	win.add_alert_banner('sample_alert', 'Theme applied', 'Menus, dialogs, inputs, tables, cards, borders, and hover states share the active palette.', 'info')
	win.add_accordion('sample_accordion', 'Theme token details', 'Each Bun RAD Studio theme includes primary and secondary accents, card surfaces, borders, readable text, and derived hover colors.', true)
	win.add_code_editor('sample_code', "mut win := simplegui.new_simple_window('Themed App', 800, 600)\nwin.set_theme('codefreelance')\nwin.run()", 'v')
	win.set_control_height('sample_code', 92)

	win.begin_row('action_row')
	win.add_button('btn_success_toast', 'Success Toast')
	win.add_button('btn_warning_toast', 'Warning Toast')
	win.add_button('btn_theme_dialog', 'Open Themed Dialog')
	win.end_row()
	win.end_tab_page()

	win.end_tab_container()
	win.add_status_bar('gallery_status', 'Ready - choose a theme to update the complete gallery', '87 THEMES')

	win.on_change('theme_picker', fn (mut win simplegui.SimpleWindow, selected_theme string) {
		win.set_theme(selected_theme)
		sync_theme_controls(mut win)
		println('Applied theme: ${selected_theme}')
	})

	win.on_click('btn_toggle_theme', fn (mut win simplegui.SimpleWindow) {
		win.toggle_window_theme()
		sync_theme_controls(mut win)
	})

	win.on_click('btn_success_toast', fn (mut win simplegui.SimpleWindow) {
		win.push_toast('Theme Preview', 'Success feedback uses the active theme surface.', 'success', 3000)
	})
	win.on_click('btn_warning_toast', fn (mut win simplegui.SimpleWindow) {
		win.push_toast('Theme Preview', 'Warning feedback remains readable in every theme.', 'warning', 3000)
	})
	win.on_click('btn_theme_dialog', fn (mut win simplegui.SimpleWindow) {
		win.show_dialog_info('Themed Dialog', 'This dialog uses the active theme surface, border, text, and accent tokens.')
	})

	win.run()
}

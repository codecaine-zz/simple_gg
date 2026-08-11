module main

import simplegui

fn main() {
	mut win := simplegui.new_simple_window('RAD & Advanced Controls Suite Showcase', 1280, 850)
	win.set_responsive_layout(true)
	win.set_fullscreen(true)

	win.add_heading('🚀 RAD Development & Advanced Controls Suite')
	win.add_label('lbl_sub', 'High-productivity controls: ListBox, Multi-Select, ComboBox, Transfer List, Code Editor, Console Log, Color Palette, Range & Step Sliders, Status Bar, and Overlays.')
	win.add_divider('')

	win.begin_grid('rad_grid', 4, 16)

	// Column 1: Selection & List Controls
	win.add_group_box('grp_list_ctrls', '1. ListBox & Selection Controls')
	win.add_label('lbl_list', 'Single-Select Interactive ListBox:')
	win.add_list_box_with_selected('lst_single', ['Standard License', 'Developer Pro', 'Enterprise Tier', 'Unlimited Site'], 'Developer Pro')
	win.on_change('lst_single', fn (mut w simplegui.SimpleWindow) {
		sel := w.get_list_box_selected('lst_single')
		w.push_toast('ListBox Selection', 'Selected: ${sel}', 'info', 2000)
	})

	win.add_label('lbl_multi', 'Multi-Select ListBox (Toggle Selection):')
	win.add_multi_list_box('lst_multi', ['macOS Support', 'Linux Support', 'Windows Support', 'WebAssembly Export'], ['macOS Support', 'Linux Support'])

	win.add_label('lbl_combo', 'Auto-Complete ComboBox:')
	win.add_combobox('combo_opt', ['vlang/simple_gg', 'vlang/v', 'sokol/gg', 'ui/framework'], 'vlang/simple_gg')

	// Column 2: Data Transfer & Color Palette
	win.add_group_box('grp_transfer', '2. Dual Transfer List & Palette')
	win.add_label('lbl_trans', 'Dual Transfer List (Move Items):')
	win.add_transfer_list('trans_list', ['Component A', 'Component B', 'Component C'], ['Component D'])
	win.set_control_height('trans_list', 130)

	win.add_label('lbl_color_pal', 'Color Palette Swatch Grid:')
	win.add_color_palette('color_pal', ['#3b82f6', '#10b981', '#ef4444', '#f59e0b', '#8b5cf6', '#ec4899', '#06b6d4'], '#3b82f6')
	win.on_change('color_pal', fn (mut w simplegui.SimpleWindow) {
		c := w.get_color_selected('color_pal')
		w.push_toast('Color Selected', 'Picked hex color ${c}', 'info', 2000)
	})

	win.add_label('lbl_step', 'Discrete Step Slider (5 Ticks):')
	win.add_step_slider('step_slider', 4, 75.0)

	// Column 3: Complex Editors & Inspector
	win.add_group_box('grp_inputs', '3. Code & Property Grid')
	win.add_label('lbl_code', 'Monospace Code Editor with Line Numbers:')
	win.add_code_editor('my_code', 'fn main() {\n    mut win := new_simple_window("App", 500, 400)\n    win.run()\n}', 'v')
	win.set_control_height('my_code', 110)

	win.add_label('lbl_prop', 'Interactive Property Grid Inspector:')
	win.add_property_grid('my_inspector', [
		simplegui.PropertyGridItem{ name: 'App Theme', val: 'Dark Mode', kind: 'text' },
		simplegui.PropertyGridItem{ name: 'Debug Mode', val: 'true', kind: 'bool' },
		simplegui.PropertyGridItem{ name: 'Accent Color', val: '#3b82f6', kind: 'color' },
		simplegui.PropertyGridItem{ name: 'Auto Sync', val: 'true', kind: 'bool' },
	])
	win.set_control_height('my_inspector', 120)

	// Column 4: Console Output & Overlays
	win.add_group_box('grp_overlays', '4. Console Log & Overlays')
	win.add_label('lbl_console', 'Console Terminal Output Viewer:')
	win.add_console_view('app_console', [
		'[OK] Application initialized successfully',
		'[INFO] Loaded 17 production themes',
		'[WARN] GPU VSync enabled',
		'[OK] Ready for user interaction',
	])
	win.set_control_height('app_console', 110)

	win.add_label('lbl_actions', 'Interactive Overlay Triggers:')
	win.add_button('btn_toast', '🔔 Trigger Toast Alert')
	win.on_click('btn_toast', fn (mut w simplegui.SimpleWindow) {
		w.push_toast('Task Complete', 'Advanced Controls Suite deployed successfully!', 'success', 3000)
		w.append_console_log('app_console', '[OK] Toast notification triggered')
	})

	win.add_button('btn_palette', '🔍 Command Palette (Ctrl+K)')
	win.on_click('btn_palette', fn (mut w simplegui.SimpleWindow) {
		w.show_command_palette([
			simplegui.CommandItem{
				id: 'cmd_save'
				title: 'Save Project State'
				category: 'File'
				shortcut: 'Ctrl+S'
				on_execute: fn (mut win simplegui.SimpleWindow) {
					win.push_toast('Saved', 'Project state saved to disk.', 'info', 2500)
				}
			},
			simplegui.CommandItem{
				id: 'cmd_theme'
				title: 'Toggle Dark/Light Theme'
				category: 'View'
				shortcut: 'Ctrl+T'
				on_execute: fn (mut win simplegui.SimpleWindow) {
					win.set_theme(if win.theme.is_dark { 'light' } else { 'dark' })
				}
			},
		])
	})

	win.end_grid()

	win.add_status_bar('main_status', 'Status: SimpleGUI Ready | Memory: 14.2 MB | FPS: 60', 'SYSTEM OK')

	win.run()
}

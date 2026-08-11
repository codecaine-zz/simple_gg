module main

import simplegui

fn main() {
	mut win := simplegui.new_simple_window('RAD Controls Suite Showcase', 1280, 800)
	win.set_responsive_layout(true)
	win.set_fullscreen(true)

	win.add_heading('🚀 RAD Development Controls Suite')
	win.add_label('lbl_sub', 'High-productivity controls for developer tools, admin portals, and data dashboards. (Press ESC or Ctrl+Q to exit)')
	win.add_divider('')

	win.begin_grid('rad_grid', 3, 16)

	// Column 1: Complex Editors & Inputs
	win.add_group_box('grp_inputs', '1. Complex Editors & Inputs')
	win.add_label('lbl_tags', 'Multi-Select Tag Input (type text & Enter):')
	win.add_tag_input('my_tags', ['vlang', 'gui', 'rad', 'controls'])

	win.add_label('lbl_range', 'Dual-Thumb Range Slider (Min: 20, Max: 80):')
	win.add_range_slider('my_range', 0.0, 100.0, 20.0, 80.0)

	win.add_label('lbl_code', 'Monospace Code Editor with Line Numbers:')
	win.add_code_editor('my_code', 'fn main() {\n    mut app := new_app()\n    app.run()\n}', 'v')
	win.set_control_height('my_code', 140)

	win.add_label('lbl_drop', 'File Drag & Drop Target Zone:')
	win.add_drop_zone('my_drop', 'Drag & drop files here or click to browse')
	win.set_control_height('my_drop', 80)
	win.on_change('my_drop', fn (mut w simplegui.SimpleWindow) {
		files := w.get_dropped_files('my_drop')
		w.push_toast('Files Received', '${files.len} file(s): ${files.join(", ")}', 'info', 3000)
	})

	// Column 2: Property Inspector & Data Analytics
	win.add_group_box('grp_data', '2. Inspector & Micro-Data')
	win.add_label('lbl_prop', 'Interactive Property Grid Inspector:')
	win.add_property_grid('my_inspector', [
		simplegui.PropertyGridItem{ name: 'App Theme', val: 'Dark Mode', kind: 'text' },
		simplegui.PropertyGridItem{ name: 'Debug Mode', val: 'true', kind: 'bool' },
		simplegui.PropertyGridItem{ name: 'Accent Color', val: '#3b82f6', kind: 'color' },
		simplegui.PropertyGridItem{ name: 'Auto Sync', val: 'false', kind: 'bool' },
		simplegui.PropertyGridItem{ name: 'Max Threads', val: '8', kind: 'text' },
	])

	win.add_label('lbl_spark', 'High-Density Sparkline Trend Curve:')
	win.add_sparkline('my_sparkline', [15.0, 32.0, 28.0, 65.0, 48.0, 92.0, 75.0, 88.0])

	win.add_label('lbl_page', 'Pagination Bar:')
	win.add_pagination('my_pagination', 1, 10)

	// Column 3: Layout & Overlays
	win.add_group_box('grp_overlays', '3. Split View & Overlays')
	win.add_label('lbl_split', 'Draggable Split View Container Pane:')
	win.add_split_view('my_split', 0.5)
	win.set_control_height('my_split', 140)

	win.add_label('lbl_actions', 'Interactive Overlay Triggers:')
	win.add_button('btn_toast', '🔔 Trigger Toast Alert')
	win.on_click('btn_toast', fn (mut w simplegui.SimpleWindow) {
		w.push_toast('Task Complete', 'RAD Control Suite successfully deployed!', 'success', 3000)
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
			simplegui.CommandItem{
				id: 'cmd_export'
				title: 'Export Data Table as CSV'
				category: 'Data'
				shortcut: 'Ctrl+E'
				on_execute: fn (mut win simplegui.SimpleWindow) {
					win.push_toast('Exported', 'Data exported to build/output.csv', 'success', 2500)
				}
			},
		])
	})

	win.add_button('btn_context', '📍 Context Menu')
	win.on_click('btn_context', fn (mut w simplegui.SimpleWindow) {
		w.show_context_menu(w.mouse_x, w.mouse_y, [
			simplegui.ContextMenuItem{
				id: 'ctx_copy'
				title: 'Copy Selection'
				shortcut: 'Ctrl+C'
				on_select: fn (mut win simplegui.SimpleWindow) {
					win.push_toast('Copied', 'Selection copied to clipboard', 'info', 2000)
				}
			},
			simplegui.ContextMenuItem{
				id: 'ctx_delete'
				title: 'Delete Item'
				shortcut: 'Del'
				on_select: fn (mut win simplegui.SimpleWindow) {
					win.push_toast('Deleted', 'Item removed', 'warning', 2000)
				}
			},
		])
	})

	win.end_grid()

	win.run()
}

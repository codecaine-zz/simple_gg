module main

import simplegui

fn main() {
	mut win := simplegui.new_simple_window('RAD & Advanced Controls Suite Showcase', 740, 800)
	win.set_theme('Apple Dark')

	win.add_heading('RAD Development & Advanced Controls Suite')
	win.add_label('lbl_sub', 'High-productivity controls: ListBox, Multi-Select, ComboBox, Transfer List, Code Editor, Color Palette, and Status Bar.')
	win.add_divider('')

	// 1. Selection & Lists
	win.group('grp_list_ctrls', '1. Selection & Lists', fn (mut win simplegui.SimpleWindow) {
		win.begin_row('row_lists')
		win.add_list_box_with_selected('lst_single', ['Standard License', 'Developer Pro', 'Enterprise Tier', 'Unlimited Site'], 'Developer Pro')
		win.add_multi_list_box('lst_multi', ['macOS Support', 'Linux Support', 'Windows Support', 'WebAssembly Export'], ['macOS Support', 'Linux Support'])
		win.end_row()

		win.on_change('lst_single', fn (mut w simplegui.SimpleWindow, sel string) {
			w.push_toast('ListBox Selection', 'Selected: ${sel}', 'info', 2000)
		})

		win.add_combobox('combo_opt', ['vlang/simple_gg', 'vlang/v', 'sokol/gg', 'ui/framework'], 'vlang/simple_gg')
	})

	// 2. Transfer & Palette
	win.group('grp_transfer', '2. Transfer & Palette', fn (mut win simplegui.SimpleWindow) {
		win.add_transfer_list('trans_list', ['Component A', 'Component B', 'Component C'], ['Component D'])
		win.set_control_height('trans_list', 100)

		win.begin_row('row_pal_slider')
		win.add_color_palette('color_pal', ['#3b82f6', '#10b981', '#ef4444', '#f59e0b', '#8b5cf6', '#ec4899', '#06b6d4'], '#3b82f6')
		win.add_step_slider('step_slider', 4, 75.0)
		win.end_row()

		win.on_change('color_pal', fn (mut w simplegui.SimpleWindow, c string) {
			w.push_toast('Color Selected', 'Picked hex color ${c}', 'info', 2000)
		})
	})

	// 3. Code & Actions
	win.group('grp_inputs', '3. Code & Actions', fn (mut win simplegui.SimpleWindow) {
		win.add_code_editor('my_code', 'fn main() {\n    mut win := new_simple_window("App", 500, 400)\n    win.run()\n}', 'v')
		win.set_control_height('my_code', 80)

		win.begin_row('row_overlay_btns')
		win.add_button('btn_toast', 'Push Toast')
		win.on_click('btn_toast', fn (mut w simplegui.SimpleWindow) {
			w.push_toast('Notification', 'Operation completed successfully!', 'success', 3000)
		})

		win.add_button('btn_banner', 'Push Alert')
		win.on_click('btn_banner', fn (mut w simplegui.SimpleWindow) {
			w.push_toast('System Notice', 'System maintenance scheduled at 00:00 UTC.', 'warning', 3000)
		})
		win.end_row()
	})

	win.add_status_bar('main_status', 'Status: SimpleGUI Ready | Memory: 14.2 MB | FPS: 60', 'SYSTEM OK')

	win.run()
}


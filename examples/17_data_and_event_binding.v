module main

import simplegui

fn main() {
	// Create window (Width: 640px, Height: 540px)
	mut win := simplegui.new_simple_window('Data & Event Binding (`bind`) Showcase', 640, 540)
	win.set_theme('Apple Dark')

	win.add_heading('Two-Way Data Binding & Event Bindings')
	win.add_subheading('Controls bound with win.bind_state() sync automatically with the state store')

	// 1. Interactive Form with Two-Way State Store Binding
	win.begin_group('1. Two-Way State Store Binding')
	win.add_form_field('Username:', 'input_user', 'Ada Lovelace')
	win.add_checkbox('chk_notifications', 'Enable Desktop Push Notifications', true)
	win.add_slider('slider_volume', 80)

	// Bind controls to reactive state keys (Two-Way Data Binding)
	win.bind_state('input_user', 'user_name')
	win.bind_control('chk_notifications', 'notify_active')
	win.bind_value('slider_volume', 'master_volume')

	// Live status displays driven by reactive state
	win.add_label('lbl_live_user', 'State user_name: Ada Lovelace')
	win.add_label('lbl_live_notify', 'State notify_active: true')
	win.add_label('lbl_live_volume', 'State master_volume: 80')
	win.end_group()

	// Reactive state listeners update labels when state changes
	win.on_state_change('user_name', fn (mut win simplegui.SimpleWindow, val string) {
		win.set_text('lbl_live_user', 'State user_name: ${val}')
	})

	win.on_state_change('notify_active', fn (mut win simplegui.SimpleWindow, val string) {
		win.set_text('lbl_live_notify', 'State notify_active: ${val}')
	})

	win.on_state_change('master_volume', fn (mut win simplegui.SimpleWindow, val string) {
		win.set_text('lbl_live_volume', 'State master_volume: ${val}')
	})

	// 2. Programmatic State Updates (Syncs bound UI controls!)
	win.begin_group('2. Programmatic Sync Test')
	win.begin_row('row_sync_btns')

	win.add_button('btn_set_ada', 'Set to Ada')
	win.bind_click('btn_set_ada', fn (mut win simplegui.SimpleWindow) {
		win.set_state('user_name', 'Ada Lovelace')
	})

	win.add_button('btn_toggle_notify', 'Toggle Notifications')
	win.bind_click('btn_toggle_notify', fn (mut win simplegui.SimpleWindow) {
		win.toggle_state_bool('notify_active')
	})

	win.add_button('btn_reset_vol', 'Reset Vol to 50')
	win.bind_click('btn_reset_vol', fn (mut win simplegui.SimpleWindow) {
		win.set_state('master_volume', '50')
	})

	win.end_row()
	win.end_group()

	// 3. Key & Shortcut Bindings
	win.begin_group('3. Keyboard Key & Shortcut Bindings')
	win.add_label('lbl_shortcut_info', 'Press [F5] to Refresh Data or [F1] for Help')

	win.bind_shortcut('F5', fn (mut win simplegui.SimpleWindow) {
		win.push_toast('Shortcut F5 Pressed!', 'Refreshed application data state', 'info', 2000)
	})

	win.bind_shortcut('F1', fn (mut win simplegui.SimpleWindow) {
		win.info('Help Dialog', 'Press F5 to refresh state or Ctrl+K for Command Palette.')
	})

	win.end_group()

	win.fit_to_content()
	win.run()
}

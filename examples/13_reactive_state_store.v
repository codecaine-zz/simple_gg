module main

import simplegui

fn main() {
	mut win := simplegui.new_simple_window('Reactive State Management & Persistence', 960, 760)
	win.set_fullscreen(true)
	win.set_theme('Nord')

	win.add_heading('Reactive State Store & Persistence (state.v)')
	win.add_label('lbl_sub', 'Store key-value states, trigger reactive listeners, and save/load JSON state.')

	// State Listeners (Reactive UI Updates)
	win.on_state_change('counter', fn (mut win simplegui.SimpleWindow, val string) {
		win.set_text('lbl_counter_display', 'Current Counter Value: ${val}')
		win.set_text('badge_count', 'Count: ${val}')
	})

	win.on_state_change('user_role', fn (mut win simplegui.SimpleWindow, val string) {
		win.set_text('lbl_role_status', 'Active User Role: ${val}')
		win.set_text('input_role', val)
	})

	win.on_state_change('dark_mode', fn (mut win simplegui.SimpleWindow, val string) {
		is_dark := val.to_lower() == 'true' || val == '1'
		mode_name := if is_dark { 'Dark' } else { 'Light' }
		if is_dark {
			win.set_theme('Nord')
		} else {
			win.set_theme('Apple Light')
		}
		win.set_text('lbl_persist_status', 'Theme updated to: ${mode_name}')
	})

	// Initial State Setup (Fires state listeners immediately)
	win.set_state_int('counter', 42)
	win.set_state('user_role', 'Administrator')
	win.set_state_bool('dark_mode', true)

	// Reactive Counter Group
	win.group('grp_counter', 'Counter & Numeric State Operations', fn (mut win simplegui.SimpleWindow) {
		win.begin_row('row_cnt_btns')
		win.add_button('btn_dec', '[-] Decrement (-1)')
		win.add_button('btn_inc', '[+] Increment (+1)')
		win.add_button('btn_reset', '[R] Reset Counter')
		win.add_badge('badge_count', 'Count: 42', 'blue')
		win.end_row()
		win.add_label('lbl_counter_display', 'Current Counter Value: 42')
	})

	// String & Boolean State Operations
	win.group('grp_role', 'String & Boolean State Management', fn (mut win simplegui.SimpleWindow) {
		win.add_form_field('User Role:', 'input_role', 'Administrator')
		win.begin_row('row_role_btns')
		win.add_button('btn_update_role', 'Update Role')
		win.add_button('btn_toggle_mode', 'Toggle Dark Mode State')
		win.end_row()
		win.add_label('lbl_role_status', 'Active User Role: Administrator')
	})

	// Persistence Group
	win.group('grp_persist', 'State Serialization & JSON Disk Persistence', fn (mut win simplegui.SimpleWindow) {
		win.begin_row('row_save_btns')
		win.add_button('btn_save_state', 'Save State to JSON')
		win.add_button('btn_load_state', 'Load State from JSON')
		win.end_row()
		win.add_label('lbl_persist_status', 'State Status: Default in-memory state loaded.')
	})

	// Event Handlers
	win.on_click('btn_inc', fn (mut win simplegui.SimpleWindow) {
		win.increment_state_int('counter', 1)
	})

	win.on_click('btn_dec', fn (mut win simplegui.SimpleWindow) {
		win.increment_state_int('counter', -1)
	})

	win.on_click('btn_reset', fn (mut win simplegui.SimpleWindow) {
		win.set_state_int('counter', 0)
	})

	win.on_click('btn_update_role', fn (mut win simplegui.SimpleWindow) {
		new_role := win.get_text('input_role')
		win.set_state('user_role', new_role)
	})

	win.on_click('btn_toggle_mode', fn (mut win simplegui.SimpleWindow) {
		is_dark := win.toggle_state_bool('dark_mode')
		mode_str := if is_dark { 'Dark' } else { 'Light' }
		win.set_text('lbl_role_status', 'State dark_mode toggled to: ${mode_str}')
	})

	win.on_click('btn_save_state', fn (mut win simplegui.SimpleWindow) {
		win.save_state_json('app_state.json') or {
			win.set_text('lbl_persist_status', 'Error saving state: ${err}')
			return
		}
		win.set_text('lbl_persist_status', 'Saved state store to app_state.json!')
	})

	win.on_click('btn_load_state', fn (mut win simplegui.SimpleWindow) {
		win.load_state_json('app_state.json') or {
			win.set_text('lbl_persist_status', 'No app_state.json found or load error: ${err}')
			return
		}
		win.set_text('lbl_persist_status', 'Loaded state store from app_state.json!')
	})

	win.run()
}

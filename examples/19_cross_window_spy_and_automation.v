module main

import simplegui

fn main() {
	// Create window (Width: 740px, Height: 560px)
	mut win := simplegui.new_simple_window('Cross-Window Spy++ & Automation Demo', 740, 560)
	win.set_theme('Apple Dark')

	// Register current window in global application registry
	simplegui.sys_register_window(win)

	win.add_heading('Cross-Window Spy++ & OS Automation')
	win.add_subheading('Inspect application windows, subscribe to cross-window event bus, and automate external OS apps')

	// 1. Cross-Window Registry & Inspection
	win.group('grp_spy', '1. Window Registry & Control Inspection (Spy++)', fn (mut win simplegui.SimpleWindow) {
		win.begin_row('row_spy_btns')
		win.add_button('btn_list_wins', 'List Active App Windows')
		win.on_click('btn_list_wins', fn (mut win simplegui.SimpleWindow) {
			wins := simplegui.sys_list_app_windows()
			win.push_toast('Registered Windows', 'Active Windows (${wins.len}): ${wins.join(", ")}', 'info', 3000)
			win.append_console_log('console_output', '[SPY++] Discovered ${wins.len} registered windows: ${wins.join(", ")}')
		})

		win.add_button('btn_spy_self', 'Spy Current Window Controls')
		win.on_click('btn_spy_self', fn (mut win simplegui.SimpleWindow) {
			if ctrl_info := simplegui.sys_spy_window(win.get_title()) {
				win.push_toast('Spy++ Success', 'Discovered ${ctrl_info.len} registered controls', 'info', 3000)
				win.append_console_log('console_output', '[SPY++] Discovered ${ctrl_info.len} window controls:')
				for idx, info in ctrl_info {
					if idx < 4 {
						win.append_console_log('console_output', '  - ${info.name} (${info.kind}): "${info.value}"')
					}
				}
			}
		})
		win.end_row()
	})

	// 2. Cross-Window Event Bus & App Inspection
	win.group('grp_bus', '2. Cross-Window Live Event Bus & External Scan', fn (mut win simplegui.SimpleWindow) {
		simplegui.sys_subscribe_events(fn (win_title string, control_name string, event_name string, value string) {
			println('BUS MESSAGE: [${win_title}] ${control_name}.${event_name} = ${value}')
		})

		win.begin_row('row_bus_actions')
		win.add_button('btn_broadcast', 'Broadcast Event')
		win.on_click('btn_broadcast', fn (mut win simplegui.SimpleWindow) {
			simplegui.sys_broadcast_event(win.get_title(), 'tbl_data', 'row_selected', 'ID_101')
			win.push_toast('Event Broadcast', 'Transmitted event payload across bus', 'success', 2500)
			win.append_console_log('console_output', '[BUS EVENT] Broadcasted event: tbl_data.row_selected = ID_101')
		})

		win.add_button('btn_list_ext', 'Scan External GUI Apps')
		win.on_click('btn_list_ext', fn (mut win simplegui.SimpleWindow) {
			ext_apps := simplegui.sys_list_external_apps()
			win.push_toast('App Scanner', 'Found ${ext_apps.len} active external GUI apps', 'info', 3000)
			win.append_console_log('console_output', '[AXUIElement] Found ${ext_apps.len} running desktop apps:')
			for idx, app in ext_apps {
				if idx < 4 {
					win.append_console_log('console_output', '  - ${app.name} (PID: ${app.pid}) | Bundle: ${app.bundle_id}')
				}
			}
		})
		win.end_row()
	})

	// Console Output View
	win.add_console_view('console_output', ['[SYSTEM] Cross-Window Spy++ subsystem ready.'])
	win.set_control_width('console_output', 700)
	win.set_control_height('console_output', 130)

	win.run()
}

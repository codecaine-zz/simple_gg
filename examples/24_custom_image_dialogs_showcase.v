module main

import simplegui

fn main() {
	// Initialize high-res SimpleGUI desktop window (1140 x 640)
	mut win := simplegui.new_simple_window('RAD Custom Image Dialogs Showcase - SimpleGUI', 1140, 640)
	win.set_theme('Apple Dark')

	// Navigation Tabs
	win.begin_tab_container('dialog_tabs', [
		'Standard Alerts & Prompts',
		'Advanced RAD Developer Dialogs',
		'Custom Dialogs & Input Prompts',
	])

	// =========================================================================
	// TAB 1: Standard Alerts & Prompts
	// =========================================================================
	win.begin_tab_page('tab_std', 0)

	win.add_heading('Standard RAD System Dialogs with 3D Glossy Icon Badges')
	win.add_label('lbl_std_desc', 'Click any button below to trigger rich backdrop dialogs styled with custom rendered 3D glowing asset badges.')

	win.begin_row('row_std_1')
	win.add_button('btn_success', '[Success] Build Succeeded Dialog')
	win.add_button('btn_error', '[Error] DB Connection Failed Dialog')
	win.add_button('btn_warning', '[Warning] Unsaved Changes Dialog')
	win.end_row()

	win.begin_row('row_std_2')
	win.add_button('btn_info', '[Info] Software Update Dialog')
	win.add_button('btn_confirm', '[Confirm] Restart Engine Prompt')
	win.add_button('btn_danger', '[Danger] Drop Table Destructive Dialog')
	win.end_row()

	win.add_divider('Live Telemetry')
	win.add_heading('Live Action & Callback Telemetry')
	win.add_badge('status_telemetry', 'Dialog Engine: Ready', 'success')
	win.add_label('lbl_telemetry', 'No dialog action triggered yet.')

	win.end_tab_page()

	// =========================================================================
	// TAB 2: Advanced RAD Developer Dialogs
	// =========================================================================
	win.begin_tab_page('tab_adv', 1)

	win.add_heading('Domain-Specific RAD Workflow Dialogs')
	win.add_label('lbl_adv_desc', 'Specialized modal dialogs crafted for modern developer tools, cloud sync, databases, security, and onboarding.')

	win.begin_row('row_adv_1')
	win.add_button('btn_security', '[Security] Elevate Permissions Dialog')
	win.add_button('btn_db', '[Database] Schema Migration Dialog')
	win.end_row()

	win.begin_row('row_adv_2')
	win.add_button('btn_cloud', '[Cloud] Sync Remote Cluster Dialog')
	win.add_button('btn_tip', '[Tip] Developer Productivity Shortcut')
	win.end_row()

	win.end_tab_page()

	// =========================================================================
	// TAB 3: Custom Builder & Input Prompts
	// =========================================================================
	win.begin_tab_page('tab_custom', 2)

	win.add_heading('Fully-Customizable Dialogs with 3 Buttons, Checkboxes & Text Input')
	win.add_label('lbl_cust_desc', 'Create custom dialogs with custom image paths, detail traces, 3-button layouts (Confirm/Cancel/Neutral), and inline text inputs.')

	win.begin_row('row_cust_1')
	win.add_button('btn_input_dialog', '[Input] Prompt User for Branch Name')
	win.add_button('btn_detail_dialog', '[Custom] Error with Stack Detail')
	win.add_button('btn_three_btns', '[3-Button] Save, Discard & Cancel')
	win.end_row()

	win.end_tab_page()

	// =========================================================================
	// EVENT HANDLERS & CALLBACKS
	// =========================================================================

	// 1. Success Dialog
	win.on_click('btn_success', fn (mut win simplegui.SimpleWindow) {
		win.show_dialog_success(
			'Build Succeeded',
			'Compilation finished in 0.42s with zero warnings.\nAll 64 automated test suites passed successfully.',
			fn (mut win simplegui.SimpleWindow) {
				win.set_text('lbl_telemetry', 'Action: User acknowledged Build Succeeded dialog.')
				win.set_text('status_telemetry', 'Build Verified')
				win.push_toast('Build Deployed', 'Artifact published to target registry.', 'success', 2500)
			}
		)
	})

	// 2. Error Dialog
	win.on_click('btn_error', fn (mut win simplegui.SimpleWindow) {
		win.show_dialog_error(
			'Database Connection Error',
			'Failed to connect to PostgreSQL server at 127.0.0.1:5432.\nConnection timed out after 3 retries.',
			fn (mut win simplegui.SimpleWindow) {
				win.set_text('lbl_telemetry', 'Action: User dismissed Database Connection Error.')
				win.push_toast('Error Dismissed', 'Retrying connection in background...', 'error', 2500)
			}
		)
	})

	// 3. Warning Dialog
	win.on_click('btn_warning', fn (mut win simplegui.SimpleWindow) {
		win.show_dialog_warning(
			'Unsaved Changes in Staging',
			'You have 4 modified files that are not committed.\nDiscarding will revert local modifications.',
			'Proceed Anyway',
			'Keep Editing',
			fn (mut win simplegui.SimpleWindow) {
				win.set_text('lbl_telemetry', 'Action: User proceeded with warning override.')
				win.push_toast('Proceeding', 'Continuing with workspace reload...', 'warning', 2500)
			}
		)
	})

	// 4. Info Dialog
	win.on_click('btn_info', fn (mut win simplegui.SimpleWindow) {
		win.show_dialog_info(
			'SimpleGUI v2.5 Update Ready',
			'A new version of SimpleGUI is ready for install.\nIncludes 3D glossy modal dialogs and 60 FPS Sokol rendering.'
		)
		win.set_text('lbl_telemetry', 'Action: User opened Software Update info dialog.')
	})

	// 5. Confirm Dialog
	win.on_click('btn_confirm', fn (mut win simplegui.SimpleWindow) {
		win.show_dialog_confirm(
			'Restart Compiler Runtime?',
			'Restarting will terminate any running debug child processes\nand reload active IDE plugins.',
			fn (mut win simplegui.SimpleWindow) {
				win.set_text('lbl_telemetry', 'Action: User CONFIRMED runtime restart.')
				win.push_toast('Runtime Restarted', 'Compiler service re-initialized.', 'info', 2500)
			},
			fn (mut win simplegui.SimpleWindow) {
				win.set_text('lbl_telemetry', 'Action: User CANCELLED runtime restart.')
			}
		)
	})

	// 6. Danger / Destructive Dialog
	win.on_click('btn_danger', fn (mut win simplegui.SimpleWindow) {
		win.show_dialog_danger(
			'Drop Production Database?',
			'WARNING: This will permanently delete 12 schemas and 450 tables.\nThis action is irreversible and cannot be recovered.',
			'Permanently Drop Tables',
			fn (mut win simplegui.SimpleWindow) {
				win.set_text('lbl_telemetry', 'Action: User triggered DESTRUCTIVE database drop!')
				win.push_toast('Database Dropped', 'All schemas wiped.', 'error', 3000)
			}
		)
	})

	// 7. Security / Authentication Dialog
	win.on_click('btn_security', fn (mut win simplegui.SimpleWindow) {
		win.show_dialog_security(
			'Security Elevation Required',
			'Binding service to privileged port 443 requires root elevation.\nPlease grant administrative permissions.',
			fn (mut win simplegui.SimpleWindow) {
				win.set_text('lbl_telemetry', 'Action: User authenticated elevated security access.')
				win.push_toast('Access Granted', 'Privileged socket listening on :443.', 'success', 2500)
			}
		)
	})

	// 8. Database Schema Migration Dialog
	win.on_click('btn_db', fn (mut win simplegui.SimpleWindow) {
		win.show_dialog_database(
			'Apply Schema Migration #0042',
			'Target: PostgreSQL Cluster (us-east-1)\nChanges: 8 table alterations, 2 new indexes, 1 constraint.\nEstimated execution time: ~1.2s.',
			fn (mut win simplegui.SimpleWindow) {
				win.set_text('lbl_telemetry', 'Action: User initiated Database Migration #0042.')
				win.push_toast('Migration Executed', 'Schema updated to version 42.', 'success', 2500)
			}
		)
	})

	// 9. Cloud Sync Dialog
	win.on_click('btn_cloud', fn (mut win simplegui.SimpleWindow) {
		win.show_dialog_cloud(
			'Sync Local Workspace with Cloud',
			'Uploading 1,280 asset files to remote cluster storage.\nBandwidth: 48.2 MB/s (Direct fiber connection).',
			fn (mut win simplegui.SimpleWindow) {
				win.set_text('lbl_telemetry', 'Action: Cloud synchronization started.')
				win.push_toast('Sync Active', '1,280 files transferred.', 'info', 2500)
			}
		)
	})

	// 10. Developer Tip Dialog
	win.on_click('btn_tip', fn (mut win simplegui.SimpleWindow) {
		win.show_dialog_tip(
			'Pro-Tip: Command Palette Shortcut',
			'Press Ctrl+K or Cmd+K anywhere in SimpleGUI\nto instantly search all actions, commands, and jump to tabs.'
		)
		win.set_text('lbl_telemetry', 'Action: User opened Developer Productivity tip dialog.')
	})

	// 11. Text Input Dialog Prompt
	win.on_click('btn_input_dialog', fn (mut win simplegui.SimpleWindow) {
		win.show_dialog_input(
			'Create New Git Feature Branch',
			'Enter the branch name for your upcoming feature:',
			'feature/modern-dialogs',
			'e.g. feature/my-cool-feature',
			fn (mut win simplegui.SimpleWindow) {
				val := win.get_dialog_input()
				win.set_text('lbl_telemetry', 'Action: Created new Git branch: "${val}"')
				win.push_toast('Branch Created', 'Switched to git branch: ${val}', 'success', 3000)
			}
		)
	})

	// 12. Custom Dialog with Detail & Checkbox
	win.on_click('btn_detail_dialog', fn (mut win simplegui.SimpleWindow) {
		win.show_custom_dialog(simplegui.DialogConfig{
			kind: .error
			title: 'Unhandled Exception: ECONNREFUSED'
			message: 'A connection error occurred while querying analytics engine.'
			detail: 'ERR_SOCKET_TIMEOUT: at connection.v:184 [code 504]'
			checkbox_txt: 'Remember my choice and do not show this error again'
			confirm_txt: 'Dismiss'
			on_confirm: fn (mut win simplegui.SimpleWindow) {
				chk := win.get_dialog_checkbox()
				win.set_text('lbl_telemetry', 'Action: Error dismissed. Checkbox remember state: ${chk}')
				win.push_toast('Error Handled', 'Checkbox value was: ${chk}', 'info', 2500)
			}
		})
	})

	// 13. Three-Button Dialog (Save, Discard, Cancel)
	win.on_click('btn_three_btns', fn (mut win simplegui.SimpleWindow) {
		win.show_custom_dialog(simplegui.DialogConfig{
			kind: .warning
			title: 'Save Project Changes?'
			message: 'Do you want to save modifications to "main_pipeline.v" before closing?'
			confirm_txt: 'Save Changes'
			cancel_txt: 'Cancel'
			neutral_txt: 'Discard Changes'
			on_confirm: fn (mut win simplegui.SimpleWindow) {
				win.set_text('lbl_telemetry', 'Action: User clicked [Save Changes].')
				win.push_toast('Saved', 'File saved successfully.', 'success', 2500)
			}
			on_cancel: fn (mut win simplegui.SimpleWindow) {
				win.set_text('lbl_telemetry', 'Action: User clicked [Cancel]. Window remains open.')
			}
			on_neutral: fn (mut win simplegui.SimpleWindow) {
				win.set_text('lbl_telemetry', 'Action: User clicked [Discard Changes]. Modifications reverted.')
				win.push_toast('Discarded', 'Changes reverted.', 'warning', 2500)
			}
		})
	})

	// Launch SimpleGUI Application Event Loop
	win.run()
}

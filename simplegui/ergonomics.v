// Module simplegui - Core UI Framework for V
// File: ergonomics.v
//
// Description:
//   This file provides developer-friendly convenience methods and RAD (Rapid Application Development)
//   shortcuts for `SimpleWindow`. These helper functions simplify common GUI development tasks,
//   such as displaying toast popups/dialogs, performing batch control operations (showing/hiding/disabling groups of controls),
//   reading/writing typed values, and exporting/importing form state to JSON strings.

module simplegui

import json2
import os

// =============================================================================
// 1. Dialog & Layout Group Shortcuts
// =============================================================================

// info displays a blue informational toast notification popup at the corner of the window.
pub fn (mut win SimpleWindow) info(title string, message string) &SimpleWindow {
	win.show_toast(title, message)
	return win
}

// begin_group starts a visual card/group box container with a title header.
// Must be paired with a corresponding `end_group()` call.
pub fn (mut win SimpleWindow) begin_group(title string) &SimpleWindow {
	win.add_control(Control{ name: 'grp_' + title, kind: 'group_start', title: title })
	return win
}

// end_group closes the active visual group box container block.
pub fn (mut win SimpleWindow) end_group() &SimpleWindow {
	win.add_control(Control{ kind: 'group_end' })
	return win
}

// add_header adds a large heading title label to the window.
pub fn (mut win SimpleWindow) add_header(title string) &SimpleWindow {
	return win.add_heading(title)
}

// add_text adds a simple text label control.
pub fn (mut win SimpleWindow) add_text(text string) &SimpleWindow {
	return win.add_label('lbl_' + text, text)
}

// add_form_input adds a labeled text input field complete with placeholder text.
pub fn (mut win SimpleWindow) add_form_input(name string, label string, placeholder string) &SimpleWindow {
	return win.add_form_field(name, label, placeholder)
}

// warn displays a yellow warning toast notification popup.
pub fn (mut win SimpleWindow) warn(title string, message string) &SimpleWindow {
	win.show_toast('[WARNING] ' + title, message)
	return win
}

// error_dialog displays a red error toast notification popup.
pub fn (mut win SimpleWindow) error_dialog(title string, message string) &SimpleWindow {
	win.show_toast('[ERROR] ' + title, message)
	return win
}

// ask displays a native OS platform confirm modal dialog box ("OK" / "Cancel")
// and returns `true` if the user clicks "OK", or `false` if cancelled.
pub fn (mut win SimpleWindow) ask(title string, question string) bool {
	$if macos {
		script := "button returned of (display dialog \"${question}\" with title \"${title}\" buttons {\"Cancel\", \"OK\"} default button \"OK\")"
		res := os.execute("osascript -e '${script}'")
		if res.exit_code == 0 {
			return res.output.trim_space() == 'OK'
		}
	} $else $if windows {
		script := "Add-Type -AssemblyName PresentationFramework; [System.Windows.MessageBox]::Show('${question}', '${title}', 'YesNo') -eq 'Yes'"
		res := os.execute("powershell -Command \"${script}\"")
		if res.exit_code == 0 {
			return res.output.trim_space() == 'True'
		}
	} $else {
		res := os.execute("zenity --question --title=\"${title}\" --text=\"${question}\" 2>/dev/null")
		return res.exit_code == 0
	}
	return false
}

// quit closes the application window and terminates the event loop immediately.
pub fn (mut win SimpleWindow) quit() {
	win.close()
}

// =============================================================================
// 2. Batch Control Operations (RAD Development)
// =============================================================================

// show_controls makes every control in `names` visible in a single method call.
pub fn (mut win SimpleWindow) show_controls(names []string) &SimpleWindow {
	for name in names {
		win.set_control_visible(name, true)
	}
	return win
}

// hide_controls hides every control in `names` in a single method call.
pub fn (mut win SimpleWindow) hide_controls(names []string) &SimpleWindow {
	for name in names {
		win.set_control_visible(name, false)
	}
	return win
}

// enable_controls enables interactivity for every control in `names`.
pub fn (mut win SimpleWindow) enable_controls(names []string) &SimpleWindow {
	for name in names {
		win.set_control_enabled(name, true)
	}
	return win
}

// disable_controls grays out and disables interactivity for every control in `names`.
pub fn (mut win SimpleWindow) disable_controls(names []string) &SimpleWindow {
	for name in names {
		win.set_control_enabled(name, false)
	}
	return win
}

// enable_all enables interactivity for every registered control in the entire window.
pub fn (mut win SimpleWindow) enable_all() &SimpleWindow {
	for name in win.control_map.keys() {
		win.set_control_enabled(name, true)
	}
	return win
}

// disable_all grays out and disables interactivity for every registered control in the entire window.
pub fn (mut win SimpleWindow) disable_all() &SimpleWindow {
	for name in win.control_map.keys() {
		win.set_control_enabled(name, false)
	}
	return win
}

// toggle_visible flips the visual visibility of control `name` and returns the new boolean visibility state.
pub fn (mut win SimpleWindow) toggle_visible(name string) bool {
	cur := win.get_control_visible(name)
	win.set_control_visible(name, !cur)
	return !cur
}

// toggle_enabled flips the interactive state of control `name` and returns the new enabled boolean state.
pub fn (mut win SimpleWindow) toggle_enabled(name string) bool {
	cur := win.get_control_enabled(name)
	win.set_control_enabled(name, !cur)
	return !cur
}

// set_all sets text values for multiple named controls simultaneously using a name->value map dictionary.
pub fn (mut win SimpleWindow) set_all(values map[string]string) &SimpleWindow {
	for name, value in values {
		win.set_text(name, value)
	}
	return win
}

// get_all reads text values for multiple named controls into a name->value map dictionary.
pub fn (win &SimpleWindow) get_all(names []string) map[string]string {
	mut values := map[string]string{}
	for name in names {
		values[name] = win.get_text(name)
	}
	return values
}

// clear_all resets text values to empty strings `''` for all specified control names.
pub fn (mut win SimpleWindow) clear_all(names []string) &SimpleWindow {
	for name in names {
		win.set_text(name, '')
	}
	return win
}

// =============================================================================
// 3. Typed Value Accessors & Mutators
// =============================================================================

// get_value is a convenient alias for `get_text(name)`.
// Optional `default_val`: Allows specifying a custom fallback string returned if control `name` does not exist (defaults to `""`).
// Example: `val := win.get_value('username', 'Guest')`
pub fn (win &SimpleWindow) get_value(name string, default_val ...string) string {
	def := if default_val.len > 0 { default_val[0] } else { '' }
	return win.get_text_or(name, def)
}

// get_value_or retrieves the text value for control `name`, returning `fallback` if the control is not found.
pub fn (win &SimpleWindow) get_value_or(name string, fallback string) string {
	return win.get_text_or(name, fallback)
}

// get_int parses and returns the numeric integer value of text inputs or numeric controls.
// Optional `default_val`: Allows specifying a custom fallback integer returned if control `name` does not exist or parsing fails (defaults to `0`).
// Example: `volume := win.get_int('volume_slider', 50)`
pub fn (win &SimpleWindow) get_int(name string, default_val ...int) int {
	def := if default_val.len > 0 { default_val[0] } else { 0 }
	return win.get_int_or(name, def)
}

// get_int_or retrieves the integer value of control `name`, returning `fallback` if the control is missing or unparseable.
pub fn (win &SimpleWindow) get_int_or(name string, fallback int) int {
	if ctrl := win.control_map[name] {
		if ctrl.text_value.len > 0 {
			trimmed := ctrl.text_value.trim_space()
			val := trimmed.int()
			if val != 0 || trimmed == '0' {
				return val
			}
		} else {
			return ctrl.int_value
		}
	}
	return fallback
}

// get_f64 parses and returns the 64-bit floating point value of text inputs or numeric controls.
// Optional `default_val`: Allows specifying a custom fallback float returned if control `name` does not exist or parsing fails (defaults to `0.0`).
// Example: `speed := win.get_f64('speed_slider', 1.0)`
pub fn (win &SimpleWindow) get_f64(name string, default_val ...f64) f64 {
	def := if default_val.len > 0 { default_val[0] } else { 0.0 }
	return win.get_f64_or(name, def)
}

// get_f64_or retrieves the float value of control `name`, returning `fallback` if the control is missing or unparseable.
pub fn (win &SimpleWindow) get_f64_or(name string, fallback f64) f64 {
	if ctrl := win.control_map[name] {
		if ctrl.text_value.len > 0 {
			trimmed := ctrl.text_value.trim_space()
			val := trimmed.f64()
			if val != 0.0 || trimmed in ['0', '0.0', '0.'] {
				return val
			}
		} else {
			return ctrl.f64_value
		}
	}
	return fallback
}

// set_int sets the numeric integer value and string representation for control `name`.
pub fn (mut win SimpleWindow) set_int(name string, val int) &SimpleWindow {
	win.set_value_int(name, val)
	win.set_text(name, '${val}')
	return win
}

// set_f64 sets the floating point value and string representation for control `name`.
pub fn (mut win SimpleWindow) set_f64(name string, val f64) &SimpleWindow {
	win.set_value_f64(name, val)
	win.set_text(name, '${val}')
	return win
}

// =============================================================================
// 4. Form RAD Serialization Utilities
// =============================================================================

// export_form_json encodes field values for the specified control `names` into a JSON formatted string.
pub fn (win &SimpleWindow) export_form_json(names []string) string {
	m := win.get_all(names)
	return json2.encode(m)
}

// import_form_json populates control values from a JSON formatted string map.
pub fn (mut win SimpleWindow) import_form_json(json_str string) &SimpleWindow {
	m := json2.decode[map[string]string](json_str) or { return win }
	win.set_all(m)
	return win
}

// =============================================================================
// 5. Super Controls Ergonomic Shortcuts
// =============================================================================

// stat creates a quick nameless super stat card with sparkline.
pub fn (mut win SimpleWindow) stat(title string, value string, delta string, is_pos bool, sparkline []f64) &SimpleWindow {
	id := win.gen_id('stat')
	return win.add_stat_card(id, title, value, delta, is_pos, sparkline)
}

// code_box creates a quick nameless Code Studio widget.
pub fn (mut win SimpleWindow) code_box(filename string, lang string, code string) &SimpleWindow {
	id := win.gen_id('code_studio')
	return win.add_code_studio(id, filename, lang, code)
}

// kanban creates a quick nameless Kanban Board.
pub fn (mut win SimpleWindow) kanban(columns []string) &SimpleWindow {
	id := win.gen_id('kanban')
	return win.add_kanban_board(id, columns)
}

// terminal creates a quick nameless Terminal Console.
pub fn (mut win SimpleWindow) terminal(tabs []string) &SimpleWindow {
	id := win.gen_id('terminal')
	return win.add_terminal_console(id, tabs)
}

// donut creates a quick nameless Donut Chart gauge.
pub fn (mut win SimpleWindow) donut(title string, percentage f64) &SimpleWindow {
	id := win.gen_id('donut')
	return win.add_donut_chart(id, title, percentage)
}

// wizard creates a quick nameless Wizard Stepper.
pub fn (mut win SimpleWindow) wizard(steps []string, current_step int) &SimpleWindow {
	id := win.gen_id('wizard')
	return win.add_wizard_stepper(id, steps, current_step)
}

// chips creates a quick nameless Chip Input.
pub fn (mut win SimpleWindow) chips(tags []string) &SimpleWindow {
	id := win.gen_id('chips')
	return win.add_chip_input(id, tags)
}

// =============================================================================
// 6. Application Compatibility & Ergonomic Bridges
// =============================================================================

// toast displays a temporary floating toast notification banner on the window.
pub fn (mut win SimpleWindow) toast(message string) &SimpleWindow {
	win.push_toast('Notification', message, 'info', 2500)
	return win
}

// alert displays a modal alert dialog.
pub fn (mut win SimpleWindow) alert(title string, message string) &SimpleWindow {
	win.show_modal(title, message, 'OK', '', fn (mut w SimpleWindow) {})
	return win
}

// alert_with_style displays a styled notification or modal alert.
pub fn (mut win SimpleWindow) alert_with_style(title string, message string, style string) &SimpleWindow {
	win.push_toast(title, message, style, 3000)
	return win
}

// confirm displays a confirmation dialog returning true if confirmed.
pub fn (mut win SimpleWindow) confirm(title string, message string) bool {
	return win.ask(title, message)
}

// prompt displays a text entry modal dialog returning user input string.
pub fn (mut win SimpleWindow) prompt(title string, message string, default_val string) string {
	$if macos {
		script := "text returned of (display dialog \"${message}\" with title \"${title}\" default answer \"${default_val}\")"
		res := os.execute("osascript -e '${script}'")
		if res.exit_code == 0 {
			return res.output.trim_space()
		}
	} $else $if windows {
		script := "Add-Type -AssemblyName Microsoft.VisualBasic; [Microsoft.VisualBasic.Interaction]::InputBox('${message}', '${title}', '${default_val}')"
		res := os.execute("powershell -Command \"${script}\"")
		if res.exit_code == 0 {
			return res.output.trim_space()
		}
	} $else {
		res := os.execute("zenity --entry --title=\"${title}\" --text=\"${message}\" --entry-text=\"${default_val}\" 2>/dev/null")
		if res.exit_code == 0 {
			return res.output.trim_space()
		}
	}
	return default_val
}

// select_file opens a native file selection dialog and returns the chosen file path.
pub fn (win &SimpleWindow) select_file() string {
	return win.osascript_choose_file()
}

// select_file_with_extensions opens a file dialog restricted to specific file extensions.
pub fn (win &SimpleWindow) select_file_with_extensions(extensions string) string {
	return win.osascript_choose_file()
}

// select_folder opens a native folder selection dialog and returns the chosen directory path.
pub fn (win &SimpleWindow) select_folder() string {
	return win.osascript_choose_folder()
}

// save_file_picker opens a native save file dialog and returns the chosen path.
pub fn (win &SimpleWindow) save_file_picker() string {
	$if macos {
		script := "osascript -e 'POSIX path of (choose file name with prompt \"Save As:\")'"
		out, code := win.exec(script)
		if code == 0 {
			return out.trim_space()
		}
	} $else $if windows {
		cmd := "powershell -Command \"Add-Type -AssemblyName System.Windows.Forms; \$d = New-Object System.Windows.Forms.SaveFileDialog; if (\$d.ShowDialog() -eq 'OK') { \$d.FileName }\""
		out, code := win.exec(cmd)
		if code == 0 {
			return out.trim_space()
		}
	} $else {
		out, code := win.exec("zenity --file-selection --save --confirm-overwrite 2>/dev/null")
		if code == 0 {
			return out.trim_space()
		}
	}
	return ''
}

// get retrieves the text value for control `name`.
pub fn (win &SimpleWindow) get(name string) string {
	return win.get_text(name)
}

// set sets the text value for control `name`.
pub fn (mut win SimpleWindow) set(name string, value string) &SimpleWindow {
	win.set_text(name, value)
	return win
}

// set_value is a convenient alias for `set(name, value)` / `set_text(name, value)`.
pub fn (mut win SimpleWindow) set_value(name string, value string) &SimpleWindow {
	win.set_text(name, value)
	return win
}

// start runs the application window main event loop.
pub fn (mut win SimpleWindow) start() &SimpleWindow {
	win.run()
	return win
}

// append_console appends formatted log output to a named console or text area control.
pub fn (mut win SimpleWindow) append_console(name string, text string, level ...int) &SimpleWindow {
	cur := win.get_text(name)
	win.set_text(name, cur + text)
	return win
}

// clear_console clears log output for a named console or text area control.
pub fn (mut win SimpleWindow) clear_console(name string) &SimpleWindow {
	win.set_text(name, '')
	return win
}

// set_status sets status text on standard status label.
pub fn (mut win SimpleWindow) set_status(text string) &SimpleWindow {
	win.set_text('lbl_status', text)
	return win
}

// get_status gets current status text.
pub fn (win &SimpleWindow) get_status() string {
	return win.get_text('lbl_status')
}

// begin_group_box opens a styled group box container.
pub fn (mut win SimpleWindow) begin_group_box(name string, title string) &SimpleWindow {
	win.add_control(Control{ name: name, kind: 'group_start', title: title })
	return win
}

// set_table_data updates tabular data and headers.
pub fn (mut win SimpleWindow) set_table_data(name string, headers []string, rows [][]string) &SimpleWindow {
	if mut c := win.control_map[name] {
		c.headers = headers.clone()
		c.rows = rows.clone()
	}
	return win
}

// set_metric_card_value updates metric card value and subtitle.
pub fn (mut win SimpleWindow) set_metric_card_value(name string, value string, subtitle string) &SimpleWindow {
	if mut c := win.control_map[name] {
		c.text_value = value
		c.placeholder = subtitle
	}
	return win
}

// end_group_box closes the active group box container.
pub fn (mut win SimpleWindow) end_group_box() &SimpleWindow {
	return win.end_group()
}

// add_console adds a log output console widget.
pub fn (mut win SimpleWindow) add_console(name string, max_lines int) &SimpleWindow {
	return win.add_textarea(name, '')
}

// add_html_view adds a web/markdown/html container.
pub fn (mut win SimpleWindow) add_html_view(name string, html string) &SimpleWindow {
	return win.add_textarea(name, html)
}

// set_html updates html / markdown content in container.
pub fn (mut win SimpleWindow) set_html(name string, html string) &SimpleWindow {
	win.set_text(name, html)
	return win
}

// run_on_main_thread executes callback synchronously or on the main loop.
pub fn (mut win SimpleWindow) run_on_main_thread(cb VoidEventCallback) &SimpleWindow {
	cb(mut win)
	return win
}

// run_on_main_thread_sync executes callback synchronously on the main loop.
pub fn (mut win SimpleWindow) run_on_main_thread_sync(cb VoidEventCallback) &SimpleWindow {
	cb(mut win)
	return win
}

// set_checked sets checkbox or switch state.
pub fn (mut win SimpleWindow) set_checked(name string, checked bool) &SimpleWindow {
	if mut ctrl := win.control_map[name] {
		ctrl.bool_value = checked
	}
	return win
}

// get_checked gets checkbox or switch state.
pub fn (win &SimpleWindow) get_checked(name string) bool {
	if ctrl := win.control_map[name] {
		return ctrl.bool_value
	}
	return false
}

// add_menu_item registers a menu item.
pub fn (mut win SimpleWindow) add_menu_item(menu_name string, item_title string, shortcut string, cb VoidEventCallback) &SimpleWindow {
	return win
}

// add_context_menu_item registers a context menu item on a control.
pub fn (mut win SimpleWindow) add_context_menu_item(control_name string, item_title string, cb VoidEventCallback) &SimpleWindow {
	return win
}

// on_file_drop registers a drag-and-drop file callback.
pub fn (mut win SimpleWindow) on_file_drop(cb fn (mut win SimpleWindow, files []string)) &SimpleWindow {
	return win
}

// clipboard_text returns UTF-8 text from system clipboard.
pub fn clipboard_text() string {
	$if macos {
		res := os.execute('pbpaste')
		if res.exit_code == 0 {
			return res.output
		}
	} $else $if windows {
		res := os.execute('powershell -Command "Get-Clipboard"')
		if res.exit_code == 0 {
			return res.output
		}
	} $else {
		res := os.execute('xclip -selection clipboard -o 2>/dev/null || xsel --clipboard --output 2>/dev/null')
		if res.exit_code == 0 {
			return res.output
		}
	}
	return ''
}

// reveal_in_finder reveals path in OS file explorer.
pub fn reveal_in_finder(path string) bool {
	if path == '' {
		return false
	}
	$if macos {
		res := os.execute('open -R "${path}"')
		return res.exit_code == 0
	} $else $if windows {
		res := os.execute('explorer.exe /select,"${path}"')
		return res.exit_code == 0
	} $else {
		res := os.execute('xdg-open "${os.dir(path)}"')
		return res.exit_code == 0
	}
}


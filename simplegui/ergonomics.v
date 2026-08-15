// Module simplegui - Core UI Framework for V
// File: ergonomics.v
//
// Description:
//   This file provides developer-friendly convenience methods and RAD (Rapid Application Development)
//   shortcuts for `SimpleWindow`. These helper functions simplify common GUI development tasks,
//   such as displaying toast popups/dialogs, performing batch control operations (showing/hiding/disabling groups of controls),
//   reading/writing typed values, and exporting/importing form state to JSON strings.

module simplegui

import x.json2
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


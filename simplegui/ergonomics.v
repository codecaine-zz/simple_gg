module simplegui

import json
import os

// ergonomics.v - High-level ergonomic helpers & RAD shortcuts for SimpleWindow.
// Ported from vlang_simplegui to supercharge rapid desktop GUI development in simple_gg.

// ==========================================
// 1. Dialog Shortcuts
// ==========================================

// info displays an informational toast notification.
pub fn (mut win SimpleWindow) info(title string, message string) &SimpleWindow {
	win.show_toast(title, message)
	return win
}

// begin_group starts a visual group box container with a title.
pub fn (mut win SimpleWindow) begin_group(title string) &SimpleWindow {
	win.add_control(Control{ name: 'grp_' + title, kind: 'group_start', title: title })
	return win
}

// end_group ends a visual group box container.
pub fn (mut win SimpleWindow) end_group() &SimpleWindow {
	win.add_control(Control{ kind: 'group_end' })
	return win
}

// add_header adds a heading title label.
pub fn (mut win SimpleWindow) add_header(title string) &SimpleWindow {
	return win.add_heading(title)
}

// add_text adds a label control.
pub fn (mut win SimpleWindow) add_text(text string) &SimpleWindow {
	return win.add_label('lbl_' + text, text)
}

// add_form_input adds a labeled form text input.
pub fn (mut win SimpleWindow) add_form_input(name string, label string, placeholder string) &SimpleWindow {
	return win.add_form_field(name, label, placeholder)
}

// warn displays a warning toast notification.
pub fn (mut win SimpleWindow) warn(title string, message string) &SimpleWindow {
	win.show_toast('[WARNING] ' + title, message)
	return win
}

// error_dialog displays an error toast notification.
pub fn (mut win SimpleWindow) error_dialog(title string, message string) &SimpleWindow {
	win.show_toast('[ERROR] ' + title, message)
	return win
}

// ask displays a native system confirm prompt and returns true if confirmed.
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

// quit terminates the application window immediately.
pub fn (mut win SimpleWindow) quit() {
	win.close()
}

// ==========================================
// 2. Batch Control Operations (RAD Development)
// ==========================================

// show_controls makes every named control visible in one call.
pub fn (mut win SimpleWindow) show_controls(names []string) &SimpleWindow {
	for name in names {
		win.set_control_visible(name, true)
	}
	return win
}

// hide_controls hides every named control in one call.
pub fn (mut win SimpleWindow) hide_controls(names []string) &SimpleWindow {
	for name in names {
		win.set_control_visible(name, false)
	}
	return win
}

// enable_controls enables every named control in one call.
pub fn (mut win SimpleWindow) enable_controls(names []string) &SimpleWindow {
	for name in names {
		win.set_control_enabled(name, true)
	}
	return win
}

// disable_controls disables every named control in one call.
pub fn (mut win SimpleWindow) disable_controls(names []string) &SimpleWindow {
	for name in names {
		win.set_control_enabled(name, false)
	}
	return win
}

// enable_all enables every registered control in the window.
pub fn (mut win SimpleWindow) enable_all() &SimpleWindow {
	for name in win.control_map.keys() {
		win.set_control_enabled(name, true)
	}
	return win
}

// disable_all disables every registered control in the window.
pub fn (mut win SimpleWindow) disable_all() &SimpleWindow {
	for name in win.control_map.keys() {
		win.set_control_enabled(name, false)
	}
	return win
}

// toggle_visible flips the visibility of a control and returns the new state.
pub fn (mut win SimpleWindow) toggle_visible(name string) bool {
	cur := win.get_control_visible(name)
	win.set_control_visible(name, !cur)
	return !cur
}

// toggle_enabled flips the enabled state of a control and returns the new state.
pub fn (mut win SimpleWindow) toggle_enabled(name string) bool {
	cur := win.get_control_enabled(name)
	win.set_control_enabled(name, !cur)
	return !cur
}

// set_all sets text values for multiple named controls from a name->value map.
pub fn (mut win SimpleWindow) set_all(values map[string]string) &SimpleWindow {
	for name, value in values {
		win.set_text(name, value)
	}
	return win
}

// get_all reads text values for multiple named controls into a name->value map.
pub fn (win &SimpleWindow) get_all(names []string) map[string]string {
	mut values := map[string]string{}
	for name in names {
		values[name] = win.get_text(name)
	}
	return values
}

// clear_all clears text values for multiple named controls.
pub fn (mut win SimpleWindow) clear_all(names []string) &SimpleWindow {
	for name in names {
		win.set_text(name, '')
	}
	return win
}

// ==========================================
// 3. Typed Value Convenience Accessors
// ==========================================

// get_value is a convenient alias for get_text.
pub fn (win &SimpleWindow) get_value(name string) string {
	return win.get_text(name)
}

// get_int returns numeric value of text or numeric controls.
pub fn (win &SimpleWindow) get_int(name string) int {
	if ctrl := win.control_map[name] {
		if ctrl.text_value.len > 0 {
			return ctrl.text_value.trim_space().int()
		}
		return ctrl.int_value
	}
	return 0
}

// get_f64 returns f64 value of text or numeric controls.
pub fn (win &SimpleWindow) get_f64(name string) f64 {
	if ctrl := win.control_map[name] {
		if ctrl.text_value.len > 0 {
			return ctrl.text_value.trim_space().f64()
		}
		return ctrl.f64_value
	}
	return 0.0
}

// set_int sets numeric value for a named control.
pub fn (mut win SimpleWindow) set_int(name string, val int) &SimpleWindow {
	win.set_value_int(name, val)
	win.set_text(name, '${val}')
	return win
}

// set_f64 sets f64 value for a named control.
pub fn (mut win SimpleWindow) set_f64(name string, val f64) &SimpleWindow {
	win.set_value_f64(name, val)
	win.set_text(name, '${val}')
	return win
}

// ==========================================
// 4. Form RAD Serialization Utilities
// ==========================================

// export_form_json encodes form field values into a JSON string.
pub fn (win &SimpleWindow) export_form_json(names []string) string {
	m := win.get_all(names)
	return json.encode(m)
}

// import_form_json loads form field values from a JSON string.
pub fn (mut win SimpleWindow) import_form_json(json_str string) &SimpleWindow {
	m := json.decode(map[string]string, json_str) or { return win }
	win.set_all(m)
	return win
}

// Module simplegui - Core UI Framework for V
// File: state.v
//
// Description:
//   This file provides reactive state management and configuration persistence for SimpleGUI.
//   It allows developers to bind application state to key-value pairs (`set_state`, `get_state`),
//   listen for state changes with reactive listeners (`on_state_change`), convert state types (int, bool, f64),
//   and save/load state to JSON files on disk for settings persistence.

module simplegui

import json
import os

// StringEventCallback is a callback function invoked with a string parameter (e.g. state value change).
pub type StringEventCallback = fn (mut win SimpleWindow, value string)

// FileDropCallback is a callback function invoked when files are drag-and-dropped onto the window.
pub type FileDropCallback = fn (mut win SimpleWindow, files []string)

// CloseRequestedCallback is a callback function invoked when the user attempts to close the window.
// Returning `true` allows the window to close; returning `false` cancels window closure (e.g. unsaved changes prompt).
pub type CloseRequestedCallback = fn (mut win SimpleWindow) bool

// AnyEventCallback is a generic event handler invoked for any control event, passing control ID, event name, and value.
pub type AnyEventCallback = fn (mut win SimpleWindow, control_name string, event_name string, value string)

// WindowConfig represents serializable window configuration properties for storing window state.
pub struct WindowConfig {
pub mut:
	title                        string // Window title bar text
	width                        int    // Window width in pixels
	height                       int    // Window height in pixels
	padding                      int    // Inner padding spacing around window edge
	spacing                      int    // Spacing between controls
	background_color             string // Background canvas hex color
	font_color                   string // Primary font hex color
	always_on_top                bool   // Always-on-top window layering flag
	responsive_layout            bool   // Auto-calculating dynamic responsive layout flag
	resizable                    bool   // User window resizing flag
	minimizable                  bool   // Minimize button flag
	maximizable                  bool   // Maximize button flag
	closable                     bool   // Close button flag
	has_shadow                   bool   // Window shadow effect flag
	movable_by_window_background bool   // Drag window by clicking empty background canvas
	titlebar_visible             bool   // System titlebar visibility flag
	title_visible                bool   // Titlebar text title visibility flag
}

// WindowParams contains low-level parameter flags used during window creation and C interop.
pub struct WindowParams {
pub mut:
	title                        string
	width                        int
	height                       int
	padding                      int
	spacing                      int
	always_on_top                int
	responsive_layout            int
	resizable                    int
	minimizable                  int
	maximizable                  int
	closable                     int
	has_shadow                   int
	movable_by_window_background int
	titlebar_visible             int
	title_visible                int
}

// ControlInfo provides detailed state metadata export for inspecting a UI control.
pub struct ControlInfo {
pub mut:
	name             string // Unique control ID name
	kind             string // Control type identifier ('button', 'textbox', etc.)
	label            string // Control title or text label
	value            string // Current string value content
	checked          bool   // Boolean checked state
	number           int    // Numeric integer value
	enabled          bool   // Enabled interactivity state
	visible          bool   // Visual visibility state
	width            int    // Control width in pixels
	height           int    // Control height in pixels
	placeholder      string // Placeholder text hint
	error_text       string // Input validation error string
	tooltip          string // Popover tooltip hint
	background_color string // Background color hex string
	font_color       string // Text color hex string
	font_size        int    // Font size in points/pixels
}

// =============================================================================
// Reactive & Key-Value State Store API
// =============================================================================
// The State Store acts as a centralized reactive database for the window application.
// Any control or handler can update a key using `win.set_state("key", "val")` and
// registered listeners created via `win.on_state_change("key", callback)` automatically fire!

// set_state updates a key-value pair in the window's state store.
// If reactive listeners are registered for `key`, they are automatically invoked with the new value.
pub fn (mut win SimpleWindow) set_state(key string, val string) &SimpleWindow {
	win.state_store[key] = val

	// Trigger registered state listeners if any exist for this key
	if key in win.state_listeners {
		for cb in win.state_listeners[key] {
			cb(mut win, val)
		}
	}
	return win
}

// get_state retrieves the string value associated with `key` from the state store.
// Optional `default_val`: Allows specifying a custom fallback string if `key` is missing or empty (defaults to `""`).
// Example: `theme := win.get_state('theme', 'Apple Dark')`
pub fn (win &SimpleWindow) get_state(key string, default_val ...string) string {
	fallback := if default_val.len > 0 { default_val[0] } else { '' }
	return win.get_state_or(key, fallback)
}

// get_state_or retrieves the string value for `key`.
// Default Return Value: Returns custom `fallback` string if `key` is unset or contains an empty string `""`.
pub fn (win &SimpleWindow) get_state_or(key string, fallback string) string {
	val := win.state_store[key] or { '' }
	if val == '' {
		return fallback
	}
	return val
}

// has_state returns `true` if `key` exists in the state store dictionary.
pub fn (win &SimpleWindow) has_state(key string) bool {
	return key in win.state_store
}

// remove_state deletes a key-value entry from the state store.
pub fn (mut win SimpleWindow) remove_state(key string) &SimpleWindow {
	win.state_store.delete(key)
	return win
}

// clear_state removes all key-value entries from the state store.
pub fn (mut win SimpleWindow) clear_state() &SimpleWindow {
	win.state_store.clear()
	return win
}

// set_state_int converts an integer `val` to a string and stores it under `key`.
pub fn (mut win SimpleWindow) set_state_int(key string, val int) &SimpleWindow {
	return win.set_state(key, val.str())
}

// get_state_int retrieves the value of `key` parsed as an integer.
// Optional `default_val`: Allows specifying a custom fallback integer returned if `key` is missing or unparseable (defaults to `0`).
// Example: `counter := win.get_state_int('click_count', 10)`
pub fn (win &SimpleWindow) get_state_int(key string, default_val ...int) int {
	fallback := if default_val.len > 0 { default_val[0] } else { 0 }
	return win.get_state_int_or(key, fallback)
}

// get_state_int_or retrieves the value of `key` parsed as an integer, returning `fallback` if missing or unparseable.
pub fn (win &SimpleWindow) get_state_int_or(key string, fallback int) int {
	if key in win.state_store {
		str_val := win.state_store[key].trim_space()
		if str_val.len > 0 {
			parsed := str_val.int()
			if parsed != 0 || str_val == '0' {
				return parsed
			}
		}
	}
	return fallback
}

// set_state_bool converts a boolean `val` to a string ('true'/'false') and stores it under `key`.
pub fn (mut win SimpleWindow) set_state_bool(key string, val bool) &SimpleWindow {
	return win.set_state(key, val.str())
}

// get_state_bool retrieves the value of `key` as a boolean.
// Optional `default_val`: Allows specifying a custom fallback boolean returned if `key` is missing or unset (defaults to `false`).
// Example: `enabled := win.get_state_bool('feature_flag', true)`
pub fn (win &SimpleWindow) get_state_bool(key string, default_val ...bool) bool {
	fallback := if default_val.len > 0 { default_val[0] } else { false }
	return win.get_state_bool_or(key, fallback)
}

// get_state_bool_or retrieves the boolean state value of `key`, returning `fallback` if missing.
pub fn (win &SimpleWindow) get_state_bool_or(key string, fallback bool) bool {
	if key in win.state_store {
		val := win.state_store[key].to_lower().trim_space()
		if val == 'true' || val == '1' {
			return true
		} else if val == 'false' || val == '0' {
			return false
		}
	}
	return fallback
}

// set_state_f64 converts a floating point `val` to string and stores it under `key`.
pub fn (mut win SimpleWindow) set_state_f64(key string, val f64) &SimpleWindow {
	return win.set_state(key, val.str())
}

// get_state_f64 retrieves the value of `key` parsed as a 64-bit float.
// Optional `default_val`: Allows specifying a custom fallback float returned if `key` is missing or unparseable (defaults to `0.0`).
// Example: `ratio := win.get_state_f64('zoom_ratio', 1.0)`
pub fn (win &SimpleWindow) get_state_f64(key string, default_val ...f64) f64 {
	fallback := if default_val.len > 0 { default_val[0] } else { 0.0 }
	return win.get_state_f64_or(key, fallback)
}

// get_state_f64_or retrieves the float value of `key`, returning `fallback` if missing or unparseable.
pub fn (win &SimpleWindow) get_state_f64_or(key string, fallback f64) f64 {
	if key in win.state_store {
		str_val := win.state_store[key].trim_space()
		if str_val.len > 0 {
			parsed := str_val.f64()
			if parsed != 0.0 || str_val in ['0', '0.0', '0.'] {
				return parsed
			}
		}
	}
	return fallback
}

// toggle_state_bool flips the boolean state of `key` (true -> false, false -> true) and returns the new boolean value.
pub fn (mut win SimpleWindow) toggle_state_bool(key string) bool {
	curr := win.get_state_bool(key)
	next := !curr
	win.set_state_bool(key, next)
	return next
}

// increment_state_int adds `delta` to the current integer value of `key` and returns the new total.
pub fn (mut win SimpleWindow) increment_state_int(key string, delta int) int {
	curr := win.get_state_int(key)
	next := curr + delta
	win.set_state_int(key, next)
	return next
}

// on_state_change registers a reactive listener callback `cb` that executes whenever `key` changes in the state store.
// If `key` already has a value in the state store, the callback is executed immediately with the current value.
pub fn (mut win SimpleWindow) on_state_change(key string, cb StringEventCallback) &SimpleWindow {
	win.state_listeners[key] << cb
	if key in win.state_store {
		cb(mut win, win.state_store[key])
	}
	return win
}

// save_state_json serializes the entire state store dictionary to a JSON file at `file_path`.
pub fn (win &SimpleWindow) save_state_json(file_path string) ! {
	data := json.encode(win.state_store)
	os.write_file(file_path, data) or { return error(err.msg()) }
}

// load_state_json reads a JSON file from `file_path`, updates the state store, and triggers reactive listeners.
pub fn (mut win SimpleWindow) load_state_json(file_path string) ! {
	content := os.read_file(file_path) or { return error(err.msg()) }
	loaded := json.decode(map[string]string, content) or { return error(err.msg()) }
	for key, val in loaded {
		win.set_state(key, val)
	}
}



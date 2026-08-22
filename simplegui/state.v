// Module simplegui - Core UI Framework for V
// File: state.v
//
// Description:
//   This file provides reactive state management and configuration persistence for SimpleGUI.
//   It allows developers to bind application state to key-value pairs (`set_state`, `get_state`),
//   listen for state changes with reactive listeners (`on_state_change`), convert state types (int, bool, f64),
//   and save/load state to JSON files on disk for settings persistence.

module simplegui

import json2
import os
import time

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

// write_file_atomic writes data safely to a temporary file before atomically renaming it,
// ensuring that crashes, power cuts, or concurrent readers never observe corrupted partial files.
pub fn write_file_atomic(file_path string, content string) ! {
	resolved := resolve_user_path(file_path)
	parent_dir := os.dir(resolved)
	if parent_dir != '' && !os.exists(parent_dir) {
		os.mkdir_all(parent_dir) or { return error('Failed to create parent directory: ${parent_dir} (${err.msg()})') }
	}

	rand_id := '${os.getpid()}_${time.now().unix_nano()}'
	tmp_path := '${resolved}.${rand_id}.tmp'

	os.write_file(tmp_path, content) or {
		return error('Failed to write temporary state file: ${tmp_path} (${err.msg()})')
	}

	$if windows {
		if os.exists(resolved) {
			os.rm(resolved) or {}
		}
	}
	os.mv(tmp_path, resolved) or {
		os.rm(tmp_path) or {}
		return error('Failed to atomically rename state file to: ${resolved} (${err.msg()})')
	}
}

// save_state_to_file serializes a key-value state store dictionary to JSON at target path atomically.
pub fn save_state_to_file(file_path string, store map[string]string) ! {
	resolved := resolve_user_path(file_path)
	data := json2.encode(store)
	write_file_atomic(resolved, data) or { return error(err.msg()) }
}

// load_state_from_file reads and deserializes a JSON state map from disk.
pub fn load_state_from_file(file_path string) !map[string]string {
	resolved := resolve_user_path(file_path)
	if !os.exists(resolved) {
		return error('State file not found: ${resolved}')
	}
	content := os.read_file(resolved) or { return error(err.msg()) }
	if content.trim_space() == '' {
		return map[string]string{}
	}
	loaded := json2.decode[map[string]string](content) or { return error(err.msg()) }
	return loaded
}

// save_state_json serializes the entire state store dictionary to a JSON file at `file_path`.
// Automatically expands user home/env paths and writes atomically to prevent file corruption.
pub fn (win &SimpleWindow) save_state_json(file_path string) ! {
	save_state_to_file(file_path, win.state_store) or { return error(err.msg()) }
}

// load_state_json reads a JSON file from `file_path`, updates the state store, and triggers reactive listeners.
// Automatically expands user home/env paths.
pub fn (mut win SimpleWindow) load_state_json(file_path string) ! {
	loaded := load_state_from_file(file_path) or { return error(err.msg()) }
	for key, val in loaded {
		win.set_state(key, val)
	}
}

// save_app_state persists the window's state store into the recommended OS user state directory.
// Default target file: '<app_state_dir>/state.json'.
// Employs atomic file writing to prevent state corruption across crashes or interruptions.
pub fn (win &SimpleWindow) save_app_state(app_name string, file_name ...string) ! {
	fname := if file_name.len > 0 && file_name[0] != '' { file_name[0] } else { 'state.json' }
	target_file := get_app_state_file(app_name, fname)
	win.save_state_json(target_file) or { return error(err.msg()) }
}

// save_app_state_or persists the state store into the recommended OS user directory, returning a boolean success flag.
pub fn (win &SimpleWindow) save_app_state_or(app_name string, file_name ...string) bool {
	win.save_app_state(app_name, ...file_name) or { return false }
	return true
}

// load_app_state reads persisted JSON state from the recommended OS user state directory, updates the store,
// and invokes registered reactive listeners.
// Returns `true` if state was found and loaded, `false` if no saved state file existed.
pub fn (mut win SimpleWindow) load_app_state(app_name string, file_name ...string) !bool {
	fname := if file_name.len > 0 && file_name[0] != '' { file_name[0] } else { 'state.json' }
	target_file := get_app_state_file(app_name, fname)
	if !os.exists(target_file) {
		fallback_file := get_app_config_file(app_name, fname)
		if !os.exists(fallback_file) {
			return false
		}
		win.load_state_json(fallback_file) or { return error(err.msg()) }
		return true
	}
	win.load_state_json(target_file) or { return error(err.msg()) }
	return true
}

// load_app_state_or loads state from recommended OS user state directory, returning whether it succeeded.
pub fn (mut win SimpleWindow) load_app_state_or(app_name string, file_name ...string) bool {
	loaded := win.load_app_state(app_name, ...file_name) or { return false }
	return loaded
}

// has_saved_app_state checks whether a persisted state file exists in the recommended OS user state directory.
pub fn (win &SimpleWindow) has_saved_app_state(app_name string, file_name ...string) bool {
	fname := if file_name.len > 0 && file_name[0] != '' { file_name[0] } else { 'state.json' }
	target_file := get_app_state_file(app_name, fname)
	if os.exists(target_file) {
		return true
	}
	fallback_file := get_app_config_file(app_name, fname)
	return os.exists(fallback_file)
}

// clear_app_state deletes the persisted state file from the recommended OS user state directory.
pub fn (win &SimpleWindow) clear_app_state(app_name string, file_name ...string) ! {
	fname := if file_name.len > 0 && file_name[0] != '' { file_name[0] } else { 'state.json' }
	target_file := get_app_state_file(app_name, fname)
	if os.exists(target_file) {
		os.rm(target_file) or { return error('Failed to delete app state: ${err.msg()}') }
	}
	fallback_file := get_app_config_file(app_name, fname)
	if os.exists(fallback_file) {
		os.rm(fallback_file) or {}
	}
}

// save_window_session persists current window dimensions, active theme, and state keys to session.json.
pub fn (win &SimpleWindow) save_window_session(app_name string) ! {
	mut session_data := map[string]string{}
	for k, v in win.state_store {
		session_data[k] = v
	}
	session_data['__win_width'] = win.width.str()
	session_data['__win_height'] = win.height.str()
	session_data['__win_theme'] = win.theme.name
	session_data['__win_fullscreen'] = win.fullscreen.str()

	target_file := get_app_state_file(app_name, 'session.json')
	save_state_to_file(target_file, session_data) or { return error(err.msg()) }
}

// restore_window_session loads session.json and restores state, theme, and window dimensions.
pub fn (mut win SimpleWindow) restore_window_session(app_name string) bool {
	target_file := get_app_state_file(app_name, 'session.json')
	if !os.exists(target_file) {
		return false
	}
	loaded := load_state_from_file(target_file) or { return false }
	for k, v in loaded {
		if k == '__win_theme' {
			win.set_theme(v)
		} else if k == '__win_fullscreen' {
			if v == 'true' {
				win.set_fullscreen(true)
			}
		} else if k == '__win_width' {
			w := v.int()
			if w > 100 {
				win.width = w
			}
		} else if k == '__win_height' {
			h := v.int()
			if h > 100 {
				win.height = h
			}
		} else {
			win.set_state(k, v)
		}
	}
	return true
}

// enable_auto_save_state configures the window to automatically persist its state on window close.
pub fn (mut win SimpleWindow) enable_auto_save_state(app_name string, file_name ...string) &SimpleWindow {
	fname := if file_name.len > 0 && file_name[0] != '' { file_name[0] } else { 'state.json' }
	win.on_close(fn [app_name, fname] (mut w SimpleWindow) bool {
		w.save_app_state_or(app_name, fname)
		return true
	})
	return win
}

// =============================================================================
// Control & State Binding API (Two-Way Data Binding)
// =============================================================================

// bind_state establishes automatic two-way data binding between control `control_name` and state store `key`.
// Updates to state key automatically update the UI control value, and UI control edits automatically sync back to state key.
pub fn (mut win SimpleWindow) bind_state(control_name string, key string) &SimpleWindow {
	if key in win.state_store {
		win.set_text(control_name, win.state_store[key])
	} else {
		init_val := win.get_text(control_name)
		win.state_store[key] = init_val
	}

	win.on_state_change(key, fn [control_name] (mut win SimpleWindow, val string) {
		if win.get_text(control_name) != val {
			win.set_text(control_name, val)
		}
	})

	win.on_change(control_name, fn [key, control_name] (mut win SimpleWindow) {
		val := win.get_text(control_name)
		if win.get_state(key) != val {
			win.set_state(key, val)
		}
	})

	return win
}

// bind_control is an ergonomic alias for `bind_state`.
pub fn (mut win SimpleWindow) bind_control(control_name string, key string) &SimpleWindow {
	return win.bind_state(control_name, key)
}

// bind_value is an ergonomic alias for `bind_state`.
pub fn (mut win SimpleWindow) bind_value(control_name string, key string) &SimpleWindow {
	return win.bind_state(control_name, key)
}




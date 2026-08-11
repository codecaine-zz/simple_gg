module simplegui

import json
import os

// state.v - Reactive & Key-Value State Management and Window Configuration
// Ported from vlang_simplegui to simple_gg.

pub type StringEventCallback = fn (mut win SimpleWindow, value string)

pub type FileDropCallback = fn (mut win SimpleWindow, files []string)

pub type CloseRequestedCallback = fn (mut win SimpleWindow) bool

pub type AnyEventCallback = fn (mut win SimpleWindow, control_name string, event_name string, value string)

// WindowConfig represents serializable window configuration properties.
pub struct WindowConfig {
pub mut:
	title                        string
	width                        int
	height                       int
	padding                      int
	spacing                      int
	background_color             string
	font_color                   string
	always_on_top                bool
	responsive_layout            bool
	resizable                    bool
	minimizable                  bool
	maximizable                  bool
	closable                     bool
	has_shadow                   bool
	movable_by_window_background bool
	titlebar_visible             bool
	title_visible                bool
}

// WindowParams contains low-level parameters for window creation.
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

// ControlInfo provides detailed state metadata for a single UI control.
pub struct ControlInfo {
pub mut:
	name             string
	kind             string
	label            string
	value            string
	checked          bool
	number           int
	enabled          bool
	visible          bool
	width            int
	height           int
	placeholder      string
	error_text       string
	tooltip          string
	background_color string
	font_color       string
	font_size        int
}

// ==========================================
// Reactive & Key-Value State Store API
// ==========================================

// set_state sets a key-value state pair and notifies registered state listeners.
pub fn (mut win SimpleWindow) set_state(key string, val string) &SimpleWindow {
	win.state_store[key] = val

	// Trigger registered state listeners if any
	if key in win.state_listeners {
		for cb in win.state_listeners[key] {
			cb(mut win, val)
		}
	}
	return win
}

// get_state retrieves state value for a key, returning empty string if unset.
pub fn (win &SimpleWindow) get_state(key string) string {
	return win.state_store[key] or { '' }
}

// get_state_or retrieves state value for a key, returning fallback if unset.
pub fn (win &SimpleWindow) get_state_or(key string, fallback string) string {
	val := win.state_store[key] or { '' }
	if val == '' {
		return fallback
	}
	return val
}

// has_state checks if a key exists in the state store.
pub fn (win &SimpleWindow) has_state(key string) bool {
	return key in win.state_store
}

// remove_state deletes a key from the state store.
pub fn (mut win SimpleWindow) remove_state(key string) &SimpleWindow {
	win.state_store.delete(key)
	return win
}

// clear_state resets all key-value pairs in the state store.
pub fn (mut win SimpleWindow) clear_state() &SimpleWindow {
	win.state_store.clear()
	return win
}

// set_state_int sets an integer value in the state store.
pub fn (mut win SimpleWindow) set_state_int(key string, val int) &SimpleWindow {
	return win.set_state(key, val.str())
}

// get_state_int retrieves an integer value from the state store.
pub fn (win &SimpleWindow) get_state_int(key string) int {
	return win.get_state(key).int()
}

// set_state_bool sets a boolean value in the state store.
pub fn (mut win SimpleWindow) set_state_bool(key string, val bool) &SimpleWindow {
	return win.set_state(key, val.str())
}

// get_state_bool retrieves a boolean value from the state store.
pub fn (win &SimpleWindow) get_state_bool(key string) bool {
	val := win.get_state(key).to_lower()
	return val == 'true' || val == '1'
}

// set_state_f64 sets a floating-point value in the state store.
pub fn (mut win SimpleWindow) set_state_f64(key string, val f64) &SimpleWindow {
	return win.set_state(key, val.str())
}

// get_state_f64 retrieves a floating-point value from the state store.
pub fn (win &SimpleWindow) get_state_f64(key string) f64 {
	return win.get_state(key).f64()
}

// toggle_state_bool toggles a boolean state value and returns the new boolean value.
pub fn (mut win SimpleWindow) toggle_state_bool(key string) bool {
	curr := win.get_state_bool(key)
	next := !curr
	win.set_state_bool(key, next)
	return next
}

// increment_state_int increments an integer state value by delta and returns the new value.
pub fn (mut win SimpleWindow) increment_state_int(key string, delta int) int {
	curr := win.get_state_int(key)
	next := curr + delta
	win.set_state_int(key, next)
	return next
}

// on_state_change registers a listener callback for when a specific state key changes.
pub fn (mut win SimpleWindow) on_state_change(key string, cb StringEventCallback) &SimpleWindow {
	win.state_listeners[key] << cb
	if key in win.state_store {
		cb(mut win, win.state_store[key])
	}
	return win
}

// save_state_json serializes current state store to a JSON file on disk.
pub fn (win &SimpleWindow) save_state_json(file_path string) ! {
	data := json.encode(win.state_store)
	os.write_file(file_path, data) or { return error(err.msg()) }
}

// load_state_json deserializes state store from a JSON file on disk and notifies listeners.
pub fn (mut win SimpleWindow) load_state_json(file_path string) ! {
	content := os.read_file(file_path) or { return error(err.msg()) }
	loaded := json.decode(map[string]string, content) or { return error(err.msg()) }
	for key, val in loaded {
		win.set_state(key, val)
	}
}


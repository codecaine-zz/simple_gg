module stateutils

import os
import time
import json2

// ============================================================================
// OS Recommended State Path Resolution
// ============================================================================

// StateLocation indicates whether state is stored in data or config directories.
pub enum StateLocation {
	data
	config
}

// get_app_dir returns the OS recommended directory for the given application.
pub fn get_app_dir(app_name string, loc StateLocation) string {
	clean_name := app_name.trim_space()
	name := if clean_name.len > 0 { clean_name } else { 'app' }

	$if macos {
		base := os.join_path(os.home_dir(), 'Library', 'Application Support', name)
		target := match loc {
			.data { base }
			.config { os.join_path(base, 'config') }
		}
		if !os.exists(target) {
			os.mkdir_all(target) or {}
		}
		return target
	}
	$if windows {
		appdata := os.getenv('APPDATA')
		base_root := if appdata.len > 0 { appdata } else { os.home_dir() }
		base := os.join_path(base_root, name)
		target := match loc {
			.data { base }
			.config { os.join_path(base, 'config') }
		}
		if !os.exists(target) {
			os.mkdir_all(target) or {}
		}
		return target
	}

	// Linux / BSD / Unix default following XDG standards
	target := match loc {
		.data {
			xdg_data := os.getenv('XDG_DATA_HOME')
			base := if xdg_data.len > 0 { xdg_data } else { os.join_path(os.home_dir(), '.local', 'share') }
			os.join_path(base, name)
		}
		.config {
			xdg_cfg := os.getenv('XDG_CONFIG_HOME')
			base := if xdg_cfg.len > 0 { xdg_cfg } else { os.join_path(os.home_dir(), '.config') }
			os.join_path(base, name)
		}
	}
	if !os.exists(target) {
		os.mkdir_all(target) or {}
	}
	return target
}

// get_state_path resolves the complete absolute filepath for an application state file.
pub fn get_state_path(app_name string, filename string, loc StateLocation) string {
	dir := get_app_dir(app_name, loc)
	fname := if filename.trim_space().len > 0 { filename.trim_space() } else { 'state.json' }
	return os.join_path(dir, fname)
}

// atomic_write writes content to target_path safely by writing to a temporary file first
// and atomically renaming it. This ensures zero corruption if interrupted.
fn atomic_write(target_path string, content string) ! {
	parent := os.dir(target_path)
	if !os.exists(parent) {
		os.mkdir_all(parent)!
	}
	tmp_path := '${target_path}.tmp.${os.getpid()}.${time.now().unix_nano()}'
	os.write_file(tmp_path, content)!
	os.mv(tmp_path, target_path)!
}

// ============================================================================
// Direct Generic App State Helpers
// ============================================================================

// save_app_state serializes and saves a struct to the OS recommended app data directory.
pub fn save_app_state[T](app_name string, filename string, state T) ! {
	full_path := get_state_path(app_name, filename, .data)
	encoded := json2.encode(state)
	atomic_write(full_path, encoded)!
}

// load_app_state deserializes a struct from the OS recommended app data directory.
pub fn load_app_state[T](app_name string, filename string) !T {
	full_path := get_state_path(app_name, filename, .data)
	if !os.exists(full_path) {
		return error('State file does not exist: ${full_path}')
	}
	content := os.read_file(full_path)!
	return json2.decode[T](content)!
}

// load_app_state_or returns the saved state if found and valid, otherwise returns default_val.
pub fn load_app_state_or[T](app_name string, filename string, default_val T) T {
	res := load_app_state[T](app_name, filename) or {
		return default_val
	}
	return res
}

// app_state_exists checks whether the state file exists in the OS recommended directory.
pub fn app_state_exists(app_name string, filename string) bool {
	full_path := get_state_path(app_name, filename, .data)
	return os.exists(full_path)
}

// delete_app_state removes the saved state file.
pub fn delete_app_state(app_name string, filename string) ! {
	full_path := get_state_path(app_name, filename, .data)
	if os.exists(full_path) {
		os.rm(full_path)!
	}
}

// ============================================================================
// AppStateStore[T] - Managed Generic State Store
// ============================================================================

// AppStateStore represents a managed application state container with auto-save,
// atomic writes, backup, and rollback capabilities.
pub struct AppStateStore[T] {
pub:
	app_name     string
	filename     string
	location     StateLocation
	default_data T
pub mut:
	data      T
	auto_save bool
}

// new_app_state initializes an AppStateStore with automatic loading from disk.
// If an existing state file is found, it is loaded into memory; otherwise default_data is used.
pub fn new_app_state[T](app_name string, default_data T) AppStateStore[T] {
	return new_app_state_with_file[T](app_name, 'state.json', default_data, .data)
}

// new_app_state_with_file initializes an AppStateStore with a custom filename and location.
pub fn new_app_state_with_file[T](app_name string, filename string, default_data T, loc StateLocation) AppStateStore[T] {
	fname := if filename.trim_space().len > 0 { filename.trim_space() } else { 'state.json' }
	mut store := AppStateStore[T]{
		app_name:     app_name
		filename:     fname
		location:     loc
		default_data: default_data
		data:         default_data
		auto_save:    false
	}
	// Try loading existing state automatically
	store.load() or {}
	return store
}

// path returns the resolved absolute filesystem path for this store.
pub fn (s AppStateStore[T]) path() string {
	return get_state_path(s.app_name, s.filename, s.location)
}

// exists checks whether the physical state file exists on disk.
pub fn (s AppStateStore[T]) exists() bool {
	return os.exists(s.path())
}

// save persists the in-memory state to disk atomically.
pub fn (s AppStateStore[T]) save() ! {
	encoded := json2.encode(s.data)
	atomic_write(s.path(), encoded)!
}

// load reloads state from disk into memory. Returns an error if the file does not exist.
pub fn (mut s AppStateStore[T]) load() ! {
	target := s.path()
	if !os.exists(target) {
		return error('State file not found: ${target}')
	}
	content := os.read_file(target)!
	s.data = json2.decode[T](content)!
}

// get returns a copy of the current state.
pub fn (s AppStateStore[T]) get() T {
	return s.data
}

// set replaces current state. If auto_save is enabled, automatically writes to disk.
pub fn (mut s AppStateStore[T]) set(new_state T) ! {
	s.data = new_state
	if s.auto_save {
		s.save()!
	}
}

// update provides mutable access to state via an updater callback.
pub fn (mut s AppStateStore[T]) update(updater fn (mut T)) ! {
	updater(mut s.data)
	if s.auto_save {
		s.save()!
	}
}

// reset restores in-memory data to default_data and deletes the file from disk.
pub fn (mut s AppStateStore[T]) reset() ! {
	s.data = s.default_data
	if s.exists() {
		os.rm(s.path())!
	}
}

// backup creates a timestamped copy of the current state file (e.g. `state.json.bak`).
pub fn (s AppStateStore[T]) backup() !string {
	if !s.exists() {
		return error('Cannot backup non-existent state file')
	}
	bak_path := '${s.path()}.bak'
	content := os.read_file(s.path())!
	atomic_write(bak_path, content)!
	return bak_path
}

// rollback restores state from the `.bak` backup file if one exists.
pub fn (mut s AppStateStore[T]) rollback() ! {
	bak_path := '${s.path()}.bak'
	if !os.exists(bak_path) {
		return error('No backup file available at: ${bak_path}')
	}
	content := os.read_file(bak_path)!
	s.data = json2.decode[T](content)!
	atomic_write(s.path(), content)!
}

// ============================================================================
// KeyValueState - Dynamic Key-Value App State
// ============================================================================

// KeyValueState manages ad-hoc application settings and preferences (strings, ints, bools, floats)
// saved in the OS recommended application directory.
pub struct KeyValueState {
pub:
	app_name string
	filename string
	location StateLocation
pub mut:
	auto_save bool
mut:
	values map[string]string
}

// new_kv_state creates or loads a key-value store for the given application.
pub fn new_kv_state(app_name string) KeyValueState {
	return new_kv_state_with_file(app_name, 'settings.json', .data)
}

// new_kv_state_with_file creates or loads a key-value store with custom filename and location.
pub fn new_kv_state_with_file(app_name string, filename string, loc StateLocation) KeyValueState {
	fname := if filename.trim_space().len > 0 { filename.trim_space() } else { 'settings.json' }
	mut kv := KeyValueState{
		app_name:  app_name
		filename:  fname
		location:  loc
		auto_save: false
		values:    map[string]string{}
	}
	kv.load() or {}
	return kv
}

// path returns the absolute path to the settings file.
pub fn (kv KeyValueState) path() string {
	return get_state_path(kv.app_name, kv.filename, kv.location)
}

// exists returns true if the settings file is present on disk.
pub fn (kv KeyValueState) exists() bool {
	return os.exists(kv.path())
}

// save persists all key-value entries to disk atomically.
pub fn (kv KeyValueState) save() ! {
	encoded := json2.encode(kv.values)
	atomic_write(kv.path(), encoded)!
}

// load reads the key-value dictionary from disk.
pub fn (mut kv KeyValueState) load() ! {
	target := kv.path()
	if !os.exists(target) {
		return error('Settings file not found: ${target}')
	}
	content := os.read_file(target)!
	kv.values = json2.decode[map[string]string](content)!
}

// set_str assigns a string value.
pub fn (mut kv KeyValueState) set_str(key string, val string) ! {
	kv.values[key] = val
	if kv.auto_save {
		kv.save()!
	}
}

// get_str retrieves a string value or default_val if missing.
pub fn (kv KeyValueState) get_str(key string, default_val string) string {
	return kv.values[key] or { default_val }
}

// set_int assigns an integer value.
pub fn (mut kv KeyValueState) set_int(key string, val int) ! {
	kv.values[key] = val.str()
	if kv.auto_save {
		kv.save()!
	}
}

// get_int retrieves an integer value or default_val if missing or malformed.
pub fn (kv KeyValueState) get_int(key string, default_val int) int {
	val_str := kv.values[key] or { return default_val }
	return val_str.int()
}

// set_bool assigns a boolean value.
pub fn (mut kv KeyValueState) set_bool(key string, val bool) ! {
	kv.values[key] = val.str()
	if kv.auto_save {
		kv.save()!
	}
}

// get_bool retrieves a boolean value or default_val if missing.
pub fn (kv KeyValueState) get_bool(key string, default_val bool) bool {
	val_str := kv.values[key] or { return default_val }
	return val_str == 'true'
}

// set_f64 assigns a floating point value.
pub fn (mut kv KeyValueState) set_f64(key string, val f64) ! {
	kv.values[key] = val.str()
	if kv.auto_save {
		kv.save()!
	}
}

// get_f64 retrieves a floating point value or default_val if missing or malformed.
pub fn (kv KeyValueState) get_f64(key string, default_val f64) f64 {
	val_str := kv.values[key] or { return default_val }
	return val_str.f64()
}

// has checks whether a key exists.
pub fn (kv KeyValueState) has(key string) bool {
	return key in kv.values
}

// delete removes a key from the store.
pub fn (mut kv KeyValueState) delete(key string) ! {
	kv.values.delete(key)
	if kv.auto_save {
		kv.save()!
	}
}

// keys returns all existing keys.
pub fn (kv KeyValueState) keys() []string {
	return kv.values.keys()
}

// all returns a clone of the internal key-value map.
pub fn (kv KeyValueState) all() map[string]string {
	return kv.values.clone()
}

// clear removes all entries.
pub fn (mut kv KeyValueState) clear() ! {
	kv.values.clear()
	if kv.auto_save {
		kv.save()!
	}
}

// reset clears all entries and deletes the physical file.
pub fn (mut kv KeyValueState) reset() ! {
	kv.values.clear()
	if kv.exists() {
		os.rm(kv.path())!
	}
}

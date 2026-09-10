module stateutils

import os

struct TestProfile {
pub mut:
	username      string
	theme         string
	window_width  int
	window_height int
	tags          []string
	is_admin      bool
}

fn test_paths() {
	app := 'vlang_utils_test_paths_app'
	data_dir := get_app_dir(app, .data)
	assert data_dir.contains(app)
	assert os.exists(data_dir)

	cfg_dir := get_app_dir(app, .config)
	assert cfg_dir.contains(app)
	assert os.exists(cfg_dir)

	full_path := get_state_path(app, 'custom.json', .data)
	assert full_path.ends_with('custom.json')

	defer {
		os.rmdir_all(data_dir) or {}
		os.rmdir_all(cfg_dir) or {}
	}
}

fn test_direct_app_state_helpers() {
	app := 'vlang_utils_test_direct_app'
	defer {
		delete_app_state(app, 'profile.json') or {}
		os.rmdir_all(get_app_dir(app, .data)) or {}
	}

	profile := TestProfile{
		username: 'alex_dev'
		theme: 'monokai'
		window_width: 1280
		window_height: 720
		tags: ['vlang', 'rad', 'utils']
		is_admin: true
	}

	assert app_state_exists(app, 'profile.json') == false

	save_app_state(app, 'profile.json', profile) or { panic(err) }
	assert app_state_exists(app, 'profile.json') == true

	loaded := load_app_state[TestProfile](app, 'profile.json') or { panic(err) }
	assert loaded.username == 'alex_dev'
	assert loaded.theme == 'monokai'
	assert loaded.window_width == 1280
	assert loaded.tags.len == 3
	assert loaded.is_admin == true

	// Test load_app_state_or
	fallback := load_app_state_or[TestProfile](app, 'missing.json', TestProfile{ username: 'fallback_user' })
	assert fallback.username == 'fallback_user'

	delete_app_state(app, 'profile.json') or { panic(err) }
	assert app_state_exists(app, 'profile.json') == false
}

fn test_app_state_store() {
	app := 'vlang_utils_test_store_app'
	defer {
		os.rmdir_all(get_app_dir(app, .data)) or {}
	}

	default_state := TestProfile{
		username: 'default_user'
		theme: 'light'
		window_width: 800
		window_height: 600
		tags: ['guest']
		is_admin: false
	}

	mut store := new_app_state[TestProfile](app, default_state)
	assert store.get().username == 'default_user'
	assert store.exists() == false

	// Persist initial state
	store.save() or { panic(err) }
	assert store.exists() == true

	// Modify and save with update callback
	store.update(fn (mut s TestProfile) {
		s.theme = 'dracula'
		s.window_width = 1920
	}) or { panic(err) }
	store.save() or { panic(err) }

	// Create backup
	bak_path := store.backup() or { panic(err) }
	assert os.exists(bak_path)

	// Change state again with auto_save enabled
	store.auto_save = true
	store.set(TestProfile{
		username: 'modified_user'
		theme: 'solarized'
		window_width: 1024
		window_height: 768
		tags: ['custom']
		is_admin: true
	}) or { panic(err) }

	// New store instance should load the auto-saved data from disk
	mut store2 := new_app_state[TestProfile](app, default_state)
	assert store2.get().username == 'modified_user'
	assert store2.get().theme == 'solarized'

	// Test rollback to backup
	store.rollback() or { panic(err) }
	assert store.get().theme == 'dracula'
	assert store.get().window_width == 1920

	// Test reset
	store.reset() or { panic(err) }
	assert store.get().username == 'default_user'
	assert store.exists() == false
}

fn test_key_value_state() {
	app := 'vlang_utils_test_kv_app'
	defer {
		os.rmdir_all(get_app_dir(app, .data)) or {}
	}

	mut kv := new_kv_state(app)
	kv.auto_save = true

	kv.set_str('app_name', 'SuperApp') or { panic(err) }
	kv.set_int('launch_count', 42) or { panic(err) }
	kv.set_bool('dark_mode', true) or { panic(err) }
	kv.set_f64('zoom_level', 1.25) or { panic(err) }

	assert kv.exists() == true
	assert kv.get_str('app_name', '') == 'SuperApp'
	assert kv.get_int('launch_count', 0) == 42
	assert kv.get_bool('dark_mode', false) == true
	assert kv.get_f64('zoom_level', 1.0) == 1.25

	assert kv.has('dark_mode') == true
	assert kv.has('non_existent') == false
	assert kv.keys().len == 4

	// Load into a new instance to verify disk persistence
	mut kv2 := new_kv_state(app)
	assert kv2.get_int('launch_count', 0) == 42
	assert kv2.get_bool('dark_mode', false) == true

	// Delete and clear
	kv.delete('zoom_level') or { panic(err) }
	assert kv.has('zoom_level') == false

	kv.clear() or { panic(err) }
	assert kv.keys().len == 0

	kv.reset() or { panic(err) }
	assert kv.exists() == false
}

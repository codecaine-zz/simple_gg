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
		username:      'alex_dev'
		theme:         'monokai'
		window_width:  1280
		window_height: 720
		tags:          ['vlang', 'rad', 'utils']
		is_admin:      true
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
	fallback := load_app_state_or[TestProfile](app, 'missing.json', TestProfile{
		username: 'fallback_user'
	})
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
		username:      'default_user'
		theme:         'light'
		window_width:  800
		window_height: 600
		tags:          ['guest']
		is_admin:      false
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
		username:      'modified_user'
		theme:         'solarized'
		window_width:  1024
		window_height: 768
		tags:          ['custom']
		is_admin:      true
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

fn test_sqlite_direct_helpers() {
	app := 'vlang_utils_test_sqlite_direct_app'
	defer {
		delete_app_state_sqlite(app, 'profile.db') or {}
		os.rmdir_all(get_app_dir(app, .data)) or {}
	}

	profile := TestProfile{
		username:      'sqlite_alex'
		theme:         'nord'
		window_width:  1600
		window_height: 900
		tags:          ['sqlite', 'vlang', 'db']
		is_admin:      true
	}

	assert app_state_sqlite_exists(app, 'profile.db') == false

	save_app_state_sqlite(app, 'profile.db', profile) or { panic(err) }
	assert app_state_sqlite_exists(app, 'profile.db') == true

	loaded := load_app_state_sqlite[TestProfile](app, 'profile.db') or { panic(err) }
	assert loaded.username == 'sqlite_alex'
	assert loaded.theme == 'nord'
	assert loaded.window_width == 1600
	assert loaded.window_height == 900
	assert loaded.tags.len == 3
	assert loaded.is_admin == true

	// Test fallback
	fallback := load_app_state_sqlite_or[TestProfile](app, 'missing.db', TestProfile{
		username: 'fallback_sqlite'
	})
	assert fallback.username == 'fallback_sqlite'

	// Test backend switching helpers
	save_app_state_with_backend(app, 'unified.db', profile, .sqlite) or { panic(err) }
	assert app_state_sqlite_exists(app, 'unified.db') == true
	loaded_unified := load_app_state_with_backend[TestProfile](app, 'unified.db', .sqlite) or {
		panic(err)
	}
	assert loaded_unified.username == 'sqlite_alex'

	fallback_unified := load_app_state_with_backend_or[TestProfile](app, 'missing2.db', TestProfile{
		username: 'fb_backend'
	}, .sqlite)
	assert fallback_unified.username == 'fb_backend'

	delete_app_state_sqlite(app, 'profile.db') or { panic(err) }
	assert app_state_sqlite_exists(app, 'profile.db') == false
}

fn test_sqlite_app_state_store() {
	app := 'vlang_utils_test_sqlite_store_app'
	defer {
		os.rmdir_all(get_app_dir(app, .data)) or {}
	}

	default_state := TestProfile{
		username:      'default_sqlite'
		theme:         'light'
		window_width:  1024
		window_height: 768
		tags:          ['guest']
		is_admin:      false
	}

	mut store := new_sqlite_app_state[TestProfile](app, default_state)
	assert store.backend == .sqlite
	assert store.get().username == 'default_sqlite'
	assert store.exists() == false

	// Persist initial state
	store.save() or { panic(err) }
	assert store.exists() == true

	// Modify and save with update callback
	store.update(fn (mut s TestProfile) {
		s.theme = 'gruvbox'
		s.window_width = 2560
	}) or { panic(err) }
	store.save() or { panic(err) }

	// Create backup
	bak_path := store.backup() or { panic(err) }
	assert os.exists(bak_path)

	// Change state again with auto_save enabled
	store.auto_save = true
	store.set(TestProfile{
		username:      'modified_sqlite'
		theme:         'synthwave'
		window_width:  1920
		window_height: 1080
		tags:          ['sqlite_auto']
		is_admin:      true
	}) or { panic(err) }

	// New store instance should load the auto-saved data from disk
	mut store2 := new_sqlite_app_state[TestProfile](app, default_state)
	assert store2.get().username == 'modified_sqlite'
	assert store2.get().theme == 'synthwave'

	// Test rollback to backup
	store.rollback() or { panic(err) }
	assert store.get().theme == 'gruvbox'
	assert store.get().window_width == 2560

	// Test reset
	store.reset() or { panic(err) }
	assert store.get().username == 'default_sqlite'
	assert store.exists() == false
}

fn test_sqlite_key_value_state() {
	app := 'vlang_utils_test_sqlite_kv_app'
	defer {
		os.rmdir_all(get_app_dir(app, .data)) or {}
	}

	mut kv := new_sqlite_kv_state(app)
	assert kv.backend == .sqlite
	kv.auto_save = true

	kv.set_str('app_title', 'SqliteApp') or { panic(err) }
	kv.set_int('queries_count', 99) or { panic(err) }
	kv.set_bool('wal_mode', true) or { panic(err) }
	kv.set_f64('ratio', 3.1415) or { panic(err) }

	assert kv.exists() == true
	assert kv.get_str('app_title', '') == 'SqliteApp'
	assert kv.get_int('queries_count', 0) == 99
	assert kv.get_bool('wal_mode', false) == true
	assert kv.get_f64('ratio', 1.0) == 3.1415

	assert kv.has('wal_mode') == true
	assert kv.has('missing') == false
	assert kv.keys().len == 4

	// Load into a new instance to verify SQLite disk persistence
	mut kv2 := new_sqlite_kv_state(app)
	assert kv2.get_int('queries_count', 0) == 99
	assert kv2.get_bool('wal_mode', false) == true
	assert kv2.get_str('app_title', '') == 'SqliteApp'

	// Test backup and rollback
	bak := kv.backup() or { panic(err) }
	assert os.exists(bak)

	kv.set_str('app_title', 'OverwrittenTitle') or { panic(err) }
	assert kv.get_str('app_title', '') == 'OverwrittenTitle'

	kv.rollback() or { panic(err) }
	assert kv.get_str('app_title', '') == 'SqliteApp'

	// Delete and clear
	kv.delete('ratio') or { panic(err) }
	assert kv.has('ratio') == false

	kv.clear() or { panic(err) }
	assert kv.keys().len == 0

	kv.reset() or { panic(err) }
	assert kv.exists() == false
}

fn test_sqlite_custom_config_and_shared_db() {
	app := 'vlang_utils_test_shared_db_app'
	defer {
		os.rmdir_all(get_app_dir(app, .data)) or {}
	}

	// Share the exact same SQLite database file for two different tables
	shared_db := 'shared_app.db'

	mut user_kv := new_sqlite_kv_state_with_table(app, shared_db, 'user_prefs', .data)
	user_kv.auto_save = true
	user_kv.set_str('username', 'charlie') or { panic(err) }

	mut theme_kv := new_sqlite_kv_state_with_table(app, shared_db, 'theme_settings', .data)
	theme_kv.auto_save = true
	theme_kv.set_str('current_theme', 'cyberpunk') or { panic(err) }

	assert user_kv.path() == theme_kv.path()
	assert user_kv.get_str('username', '') == 'charlie'
	assert theme_kv.get_str('current_theme', '') == 'cyberpunk'

	// Re-load each from their respective tables
	mut user_kv_reload := new_sqlite_kv_state_with_table(app, shared_db, 'user_prefs', .data)
	assert user_kv_reload.get_str('username', '') == 'charlie'
	assert user_kv_reload.has('current_theme') == false

	mut theme_kv_reload := new_sqlite_kv_state_with_table(app, shared_db, 'theme_settings', .data)
	assert theme_kv_reload.get_str('current_theme', '') == 'cyberpunk'
	assert theme_kv_reload.has('username') == false
}

fn test_array_state_handling() {
	app := 'vlang_utils_test_array_app'
	defer {
		os.rmdir_all(get_app_dir(app, .data)) or {}
	}

	// 1. Root-level array state (AppStateStore[[]string])
	mut history_store := new_app_state[[]string](app, ['initial_entry'])
	history_store.auto_save = true
	assert history_store.get() == ['initial_entry']

	history_store.update(fn (mut list []string) {
		list << 'second_entry'
		list << 'third_entry'
	}) or { panic(err) }

	assert history_store.get().len == 3
	assert history_store.get()[1] == 'second_entry'

	// Reload from disk
	loaded_history := load_app_state[[]string](app, 'state.json') or { panic(err) }
	assert loaded_history.len == 3
	assert loaded_history[2] == 'third_entry'

	// 2. KeyValueState array helper (JSON)
	mut kv := new_kv_state(app)
	kv.set_strings('recent_files', ['/a/b.txt', '/c/d.txt']) or { panic(err) }
	files := kv.get_strings('recent_files', [])
	assert files.len == 2
	assert files[0] == '/a/b.txt'
	assert files[1] == '/c/d.txt'
	assert kv.get_strings('non_existent', ['fallback']) == ['fallback']

	// 3. KeyValueState array helper (SQLite)
	mut sqlite_kv := new_sqlite_kv_state(app)
	sqlite_kv.auto_save = true
	sqlite_kv.set_strings('bookmarks', ['https://vlang.io', 'https://github.com']) or { panic(err) }
	bookmarks := sqlite_kv.get_strings('bookmarks', [])
	assert bookmarks.len == 2
	assert bookmarks[0] == 'https://vlang.io'
}

struct TestSchemaV1 {
pub mut:
	app_id string
	port   int
}

struct TestSchemaV2 {
pub mut:
	app_id      string
	port        int
	debug_mode  bool              = true
	tags        []string          = []
	custom_meta map[string]string = map[string]string{}
}

fn test_struct_schema_evolution() {
	app := 'vlang_utils_test_evolution_app'
	defer {
		os.rmdir_all(get_app_dir(app, .data)) or {}
	}

	// 1. Save v1 state with original fields
	v1 := TestSchemaV1{
		app_id: 'my_service'
		port:   8080
	}
	save_app_state(app, 'state.json', v1) or { panic(err) }

	// 2. Load into v2 struct - original fields preserved, new fields get default values
	mut store_v2 := new_app_state[TestSchemaV2](app, TestSchemaV2{})
	assert store_v2.data.app_id == 'my_service'
	assert store_v2.data.port == 8080
	assert store_v2.data.debug_mode == true
	assert store_v2.data.tags.len == 0

	// 3. Mutate newly added fields & dynamic map
	store_v2.update(fn (mut s TestSchemaV2) {
		s.tags << 'api'
		s.tags << 'v2'
		s.custom_meta['region'] = 'us-east-1'
	}) or { panic(err) }
	store_v2.save() or { panic(err) }

	// 4. Reload v2 to verify persistence of all expanded data
	reloaded := load_app_state[TestSchemaV2](app, 'state.json') or { panic(err) }
	assert reloaded.app_id == 'my_service'
	assert reloaded.port == 8080
	assert reloaded.debug_mode == true
	assert reloaded.tags == ['api', 'v2']
	assert reloaded.custom_meta['region'] == 'us-east-1'
}



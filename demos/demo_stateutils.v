module main

import stateutils

struct WindowConfig {
pub mut:
	title  string
	width  int
	height int
	dark   bool
}

fn main() {
	println('==================================================')
	println('               demo_stateutils                    ')
	println('==================================================')

	app_name := 'vlang_utils_demo_window'
	default_cfg := WindowConfig{
		title:  'My Application'
		width:  1024
		height: 768
		dark:   false
	}

	mut store := stateutils.new_app_state[WindowConfig](app_name, default_cfg)
	defer {
		stateutils.delete_app_state(app_name, 'state.json') or {}
	}
	println('State path: ${store.path()}')

	// Update state
	store.data.title = 'Updated Title'
	store.data.dark = true
	store.save()!
	println('Saved state to disk. Exists on disk: ${store.exists()}')
	assert store.exists() == true

	// Reload state
	loaded := stateutils.load_app_state[WindowConfig](app_name, 'state.json')!
	println('Reloaded state: title="${loaded.title}", dark=${loaded.dark}')
	assert loaded.title == 'Updated Title'
	assert loaded.dark == true

	// KeyValueState demo (JSON)
	mut kv := stateutils.new_kv_state(app_name)
	defer {
		kv.reset() or {}
	}
	kv.set_str('user_name', 'dev_user')!
	kv.set_int('login_count', 42)!
	name := kv.get_str('user_name', '')
	logins := kv.get_int('login_count', 0)
	println('Dynamic KV (JSON): user_name=${name}, logins=${logins}')
	assert name == 'dev_user'
	assert logins == 42

	// SQLite Database Option Demo
	println('\n--- SQLite Database Backend ---')
	mut sqlite_store := stateutils.new_sqlite_app_state[WindowConfig](app_name, default_cfg)
	defer {
		sqlite_store.reset() or {}
	}
	println('SQLite State path: ${sqlite_store.path()}')
	sqlite_store.data.title = 'SQLite Powered Window'
	sqlite_store.data.dark = true
	sqlite_store.save()!
	assert sqlite_store.exists() == true

	loaded_sqlite := stateutils.load_app_state_sqlite[WindowConfig](app_name, 'state.db')!
	println('Reloaded SQLite state: title="${loaded_sqlite.title}", dark=${loaded_sqlite.dark}')
	assert loaded_sqlite.title == 'SQLite Powered Window'

	mut sqlite_kv := stateutils.new_sqlite_kv_state(app_name)
	defer {
		sqlite_kv.reset() or {}
	}
	sqlite_kv.auto_save = true
	sqlite_kv.set_str('database_engine', 'sqlite3')!
	sqlite_kv.set_int('wal_checkpoint', 100)!
	engine := sqlite_kv.get_str('database_engine', '')
	chk := sqlite_kv.get_int('wal_checkpoint', 0)
	println('Dynamic KV (SQLite): engine=${engine}, checkpoint=${chk}')
	assert engine == 'sqlite3'
	assert chk == 100

	println('\n✔ stateutils demo completed successfully!')
}

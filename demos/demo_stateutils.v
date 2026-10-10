module main

import stateutils

struct WindowConfig {
pub mut:
	title        string
	width        int
	height       int
	dark         bool
	recent_files []string
	tags         []string
}

fn main() {
	println('==================================================')
	println('               demo_stateutils                    ')
	println('==================================================')

	app_name := 'vlang_utils_demo_window'
	default_cfg := WindowConfig{
		title:        'My Application'
		width:        1024
		height:       768
		dark:         false
		recent_files: ['/docs/intro.md', '/src/main.v']
		tags:         ['desktop', 'gui']
	}

	mut store := stateutils.new_app_state[WindowConfig](app_name, default_cfg)
	defer {
		stateutils.delete_app_state(app_name, 'state.json') or {}
	}
	println('State path: ${store.path()}')

	// 1. Update state including arrays
	store.data.title = 'Updated Title'
	store.data.dark = true
	store.data.recent_files << '/docs/settings.md'
	store.update(fn (mut cfg WindowConfig) {
		cfg.tags << 'vlang'
	})!
	store.save()!
	println('Saved state with arrays to disk. Exists on disk: ${store.exists()}')
	assert store.exists() == true

	// Reload state and inspect array elements
	loaded := stateutils.load_app_state[WindowConfig](app_name, 'state.json')!
	println('Reloaded state: title="${loaded.title}", recent_files=${loaded.recent_files}, tags=${loaded.tags}')
	assert loaded.title == 'Updated Title'
	assert loaded.dark == true
	assert loaded.recent_files.len == 3
	assert loaded.tags.contains('vlang')

	// 2. Direct Root-Level Array State (e.g. list of recent searches or history)
	println('\n--- Root-Level Array State ---')
	history_app := 'vlang_utils_demo_history'
	mut history_store := stateutils.new_app_state[[]string](history_app, ['v run .'])
	defer {
		stateutils.delete_app_state(history_app, 'state.json') or {}
	}
	history_store.auto_save = true
	history_store.data << 'v test .'
	history_store.data << 'git status'
	history_store.save()!

	loaded_history := stateutils.load_app_state[[]string](history_app, 'state.json')!
	println('Loaded root array history (${loaded_history.len} items): ${loaded_history}')
	assert loaded_history.len == 3
	assert loaded_history[1] == 'v test .'

	// 3. KeyValueState demo (JSON) with Strings and String Arrays
	println('\n--- KeyValueState (JSON) ---')
	mut kv := stateutils.new_kv_state(app_name)
	defer {
		kv.reset() or {}
	}
	kv.set_str('user_name', 'dev_user')!
	kv.set_int('login_count', 42)!
	kv.set_strings('favorite_colors', ['#ff007f', '#00ffc8', '#7b2cbf'])!

	name := kv.get_str('user_name', '')
	logins := kv.get_int('login_count', 0)
	colors := kv.get_strings('favorite_colors', [])
	println('Dynamic KV: user_name=${name}, logins=${logins}, colors=${colors}')
	assert name == 'dev_user'
	assert logins == 42
	assert colors.len == 3
	assert colors[0] == '#ff007f'

	// 4. SQLite Database Option Demo
	println('\n--- SQLite Database Backend ---')
	mut sqlite_store := stateutils.new_sqlite_app_state[WindowConfig](app_name, default_cfg)
	defer {
		sqlite_store.reset() or {}
	}
	println('SQLite State path: ${sqlite_store.path()}')
	sqlite_store.data.title = 'SQLite Powered Window'
	sqlite_store.data.dark = true
	sqlite_store.data.recent_files << '/sqlite/config.db'
	sqlite_store.save()!
	assert sqlite_store.exists() == true

	loaded_sqlite := stateutils.load_app_state_sqlite[WindowConfig](app_name, 'state.db')!
	println('Reloaded SQLite state: title="${loaded_sqlite.title}", recent_files=${loaded_sqlite.recent_files}')
	assert loaded_sqlite.title == 'SQLite Powered Window'
	assert loaded_sqlite.recent_files.len == 3

	mut sqlite_kv := stateutils.new_sqlite_kv_state(app_name)
	defer {
		sqlite_kv.reset() or {}
	}
	sqlite_kv.auto_save = true
	sqlite_kv.set_str('database_engine', 'sqlite3')!
	sqlite_kv.set_int('wal_checkpoint', 100)!
	sqlite_kv.set_strings('active_plugins', ['syntax_hl', 'git_blame', 'linter'])!

	engine := sqlite_kv.get_str('database_engine', '')
	chk := sqlite_kv.get_int('wal_checkpoint', 0)
	plugins := sqlite_kv.get_strings('active_plugins', [])
	println('Dynamic KV (SQLite): engine=${engine}, checkpoint=${chk}, plugins=${plugins}')
	assert engine == 'sqlite3'
	assert chk == 100
	assert plugins.len == 3
	assert plugins[1] == 'git_blame'

	println('\n✔ stateutils demo completed successfully!')
}

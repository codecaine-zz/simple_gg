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
		title: 'My Application'
		width: 1024
		height: 768
		dark: false
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

	// KeyValueState demo
	mut kv := stateutils.new_kv_state(app_name)
	defer {
		kv.clear() or {}
	}
	kv.set_str('user_name', 'dev_user')!
	kv.set_int('login_count', 42)!
	name := kv.get_str('user_name', '')
	logins := kv.get_int('login_count', 0)
	println('Dynamic KV: user_name=${name}, logins=${logins}')
	assert name == 'dev_user'
	assert logins == 42

	println('\n✔ stateutils demo completed successfully!')
}

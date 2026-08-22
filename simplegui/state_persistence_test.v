module simplegui

import os

fn test_user_home_and_path_resolution() {
	home := get_user_home_dir()
	assert home.len > 0
	assert os.is_dir(home)

	// Tilde resolution
	resolved_home := resolve_user_path('~')
	assert resolved_home == home

	resolved_sub := resolve_user_path('~/test_sub_folder/file.json')
	assert resolved_sub == os.join_path(home, 'test_sub_folder', 'file.json')

	// Env variable resolution
	$if !windows {
		os.setenv('SIMPLEGUI_TEST_ENV', 'simple_val', true)
		env_resolved := resolve_user_path('/tmp/' + r'${SIMPLEGUI_TEST_ENV}' + '/data')
		assert env_resolved.contains('simple_val')

		env_var_resolved := resolve_user_path('/tmp/$SIMPLEGUI_TEST_ENV/data')
		assert env_var_resolved.contains('simple_val')
	}
}

fn test_app_directory_resolvers() {
	app := 'test_demo_app'

	config_dir := get_app_config_dir(app)
	assert config_dir.contains(app)

	data_dir := get_app_data_dir(app)
	assert data_dir.contains(app)

	cache_dir := get_app_cache_dir(app)
	assert cache_dir.contains(app)

	state_dir := get_app_state_dir(app)
	assert state_dir.contains(app)

	log_dir := get_app_log_dir(app)
	assert log_dir.contains(app)

	runtime_dir := get_app_runtime_dir(app)
	assert runtime_dir.contains(app)

	config_file := get_app_config_file(app, 'settings.json')
	assert config_file.ends_with('settings.json')

	state_file := get_app_state_file(app, 'state.json')
	assert state_file.ends_with('state.json')
}

fn test_atomic_file_writing() {
	tmp_test_dir := os.join_path(os.temp_dir(), 'simplegui_test_${os.getpid()}')
	defer {
		os.rmdir_all(tmp_test_dir) or {}
	}

	test_file := os.join_path(tmp_test_dir, 'nested', 'test_atomic.txt')
	write_file_atomic(test_file, 'hello atomic state') or {
		assert false
		return
	}

	assert os.exists(test_file)
	content := os.read_file(test_file) or { '' }
	assert content == 'hello atomic state'
}

struct StateTestContext {
mut:
	called bool
	val    string
}

fn test_app_state_persistence_lifecycle() {
	app_name := 'simplegui_unit_test_${os.getpid()}'

	mut win := new_simple_window('Test Window', 800, 600)
	defer {
		win.clear_app_state(app_name) or {}
	}

	assert !win.has_saved_app_state(app_name)

	win.set_state('user_name', 'Alice')
	win.set_state_int('login_count', 42)
	win.set_state_bool('logged_in', true)
	win.set_state_f64('ratio', 3.14)

	win.save_app_state(app_name) or {
		assert false
		return
	}

	assert win.has_saved_app_state(app_name)

	// Create second window and load saved state
	mut win2 := new_simple_window('Test Window 2', 800, 600)
	mut ctx := &StateTestContext{}

	win2.on_state_change('user_name', fn [mut ctx] (mut w SimpleWindow, val string) {
		ctx.called = true
		ctx.val = val
	})

	loaded := win2.load_app_state(app_name) or { false }
	assert loaded == true

	assert win2.get_state('user_name') == 'Alice'
	assert win2.get_state_int('login_count') == 42
	assert win2.get_state_bool('logged_in') == true
	assert win2.get_state_f64('ratio') == 3.14

	assert ctx.called == true
	assert ctx.val == 'Alice'

	// Test clear_app_state
	win.clear_app_state(app_name) or {
		assert false
		return
	}
	assert !win.has_saved_app_state(app_name)
}

fn test_window_session_persistence() {
	app_name := 'simplegui_session_unit_test_${os.getpid()}'

	mut win := new_simple_window('Session Window', 1024, 768)
	win.set_theme('Dracula')
	win.set_state('tab_index', '2')

	defer {
		session_file := get_app_state_file(app_name, 'session.json')
		if os.exists(session_file) {
			os.rm(session_file) or {}
		}
	}

	win.save_window_session(app_name) or {
		assert false
		return
	}

	mut win2 := new_simple_window('Session Window 2', 400, 300)
	restored := win2.restore_window_session(app_name)
	assert restored == true
	assert win2.theme.name == 'Dracula'
	assert win2.get_state('tab_index') == '2'
	assert win2.width == 1024
	assert win2.height == 768
}

fn test_theme_persistence_roundtrip() {
	orig_theme := get_saved_theme()
	defer {
		save_theme(orig_theme)
	}

	assert save_theme('Tokyo Night') == true
	assert get_saved_theme() == 'Tokyo Night'

	assert save_theme('Monokai Pro') == true
	assert get_saved_theme() == 'Monokai Pro'
}

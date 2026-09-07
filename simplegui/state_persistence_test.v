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

fn test_app_id_derivation() {
	mut win := new_simple_window('OmniTool Studio Pro', 1200, 800)
	assert win.get_app_id() == 'omnitool_studio_pro'

	win.set_app_id('custom_identifier_123')
	assert win.get_app_id() == 'custom_identifier_123'
}

fn test_control_persistence_filtering() {
	// Persistent controls
	input_ctrl := Control{ name: 'txt_workspace', kind: 'input', text_value: '/Users/test' }
	assert should_persist_control(&input_ctrl) == true

	chk_ctrl := Control{ name: 'chk_recursive', kind: 'checkbox', bool_value: true }
	assert should_persist_control(&chk_ctrl) == true

	dd_ctrl := Control{ name: 'dd_mode', kind: 'dropdown', text_value: 'Fast' }
	assert should_persist_control(&dd_ctrl) == true

	slider_ctrl := Control{ name: 'sl_depth', kind: 'slider', int_value: 5 }
	assert should_persist_control(&slider_ctrl) == true

	notes_ctrl := Control{ name: 'txt_notes', kind: 'textarea', text_value: 'my notes' }
	assert should_persist_control(&notes_ctrl) == true

	// Non-persistent controls: outputs, terminals, consoles
	output_ctrl := Control{ name: 'txt_output', kind: 'textarea', text_value: 'stale logs' }
	assert should_persist_control(&output_ctrl) == false

	stdout_ctrl := Control{ name: 'txt_stdout', kind: 'textarea', text_value: 'stale stdout' }
	assert should_persist_control(&stdout_ctrl) == false

	term_ctrl := Control{ name: 'term_console', kind: 'super_terminal' }
	assert should_persist_control(&term_ctrl) == false

	btn_ctrl := Control{ name: 'btn_run', kind: 'button', title: 'Run' }
	assert should_persist_control(&btn_ctrl) == false

	lbl_ctrl := Control{ name: 'lbl_info', kind: 'label', title: 'Ready' }
	assert should_persist_control(&lbl_ctrl) == false

	// Sensitive passwords
	pass_ctrl := Control{ name: 'txt_password', kind: 'password', text_value: 'secret123' }
	assert should_persist_control(&pass_ctrl) == false
}

fn test_form_state_persistence_roundtrip() {
	app_id := 'form_test_app_${os.getpid()}'
	orig_theme := get_saved_theme()
	defer {
		save_theme(orig_theme)
	}

	mut win := new_simple_window('Form Test App', 1050, 750)
	win.set_app_id(app_id)
	defer {
		win.clear_app_form_state() or {}
	}

	// Add various persistent and ephemeral controls
	win.add_input('txt_workspace', '/Users/dev/project')
	win.add_input('txt_search', 'fn main')
	win.add_checkbox('chk_hidden', 'Include Hidden', true)
	win.add_checkbox('chk_case', 'Case Sensitive', false)
	win.add_dropdown('dd_mode', ['Standard', 'Expert', 'Audit'], 'Expert')
	win.add_dropdown('dd_app_theme', list_themes(), 'Dracula')
	win.add_slider('sl_depth', 7)
	win.add_textarea('txt_notes', 'Project notes')
	win.add_textarea('txt_output', 'Command output: completed in 12ms') // Should NOT persist

	// Change theme via set_theme (should also persist globally)
	win.set_theme('Dracula')

	// Save form state
	win.save_app_form_state() or {
		assert false
		return
	}

	// Verify file exists
	state_file := get_app_state_file(app_id, 'form_state.json')
	assert os.exists(state_file)

	// Create fresh window and restore form state
	mut win2 := new_simple_window('Form Test App', 800, 600)
	win2.set_app_id(app_id)

	// Add empty/default controls to win2
	win2.add_input('txt_workspace', '')
	win2.add_input('txt_search', '')
	win2.add_checkbox('chk_hidden', 'Include Hidden', false)
	win2.add_checkbox('chk_case', 'Case Sensitive', false)
	win2.add_dropdown('dd_mode', ['Standard', 'Expert', 'Audit'], 'Standard')
	win2.add_dropdown('dd_app_theme', list_themes(), 'GitHub Dark')
	win2.add_slider('sl_depth', 1)
	win2.add_textarea('txt_notes', '')
	win2.add_textarea('txt_output', 'Initial empty output')

	restored := win2.restore_app_form_state()
	assert restored == true

	// Check restored form values
	assert win2.get_text('txt_workspace') == '/Users/dev/project'
	assert win2.get_text('txt_search') == 'fn main'
	assert win2.get_bool('chk_hidden') == true
	assert win2.get_bool('chk_case') == false
	assert win2.get_text('dd_mode') == 'Expert'
	assert win2.get_text('sl_depth') == '7'
	assert win2.get_text('txt_notes') == 'Project notes'

	// Ephemeral output must NOT be restored with stale output
	assert win2.get_text('txt_output') == 'Initial empty output'

	// Theme and theme dropdown must match Dracula
	assert win2.theme.name == 'Dracula'
	assert win2.get_text('dd_app_theme') == 'Dracula'

	// Window dimensions restored
	assert win2.width == 1050
	assert win2.height == 750
}


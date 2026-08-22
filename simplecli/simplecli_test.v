module simplecli

import os

fn test_simplecli_init_and_builder() {
	mut app := new_app('TestCLI', '2.5.0')
	app.set_author('Antigravity')
	app.set_description('Console utility testing')
	app.set_no_color(true)
	app.set_silent(true)

	assert app.app_name == 'TestCLI'
	assert app.version == '2.5.0'
	assert app.author == 'Antigravity'
	assert app.description == 'Console utility testing'
	assert app.no_color == true
	assert app.silent_mode == true
}

fn test_simplecli_flags_and_args() {
	mut app := new('FlagTest')
	app.set_silent(true)

	app.add_flag_string('config', 'c', 'default.json', 'Path to config')
	app.add_flag_int('port', 'p', 8080, 'Server port')
	app.add_flag_bool('dry-run', 'd', false, 'Dry run execution')

	raw_args := ['--config', 'custom.json', '-p', '9090', '-d', 'positional_arg1', 'positional_arg2']
	app.parse_args(raw_args) or { panic(err) }

	assert app.get_flag_string('config') == 'custom.json'
	assert app.get_flag_int('port') == 9090
	assert app.get_flag_bool('dry-run') == true
	assert app.get_positional_args() == ['positional_arg1', 'positional_arg2']
}

fn test_simplecli_logging_and_file() {
	mut app := new('LogTest')
	temp_log := os.join_path(os.temp_dir(), 'simplecli_log_test_${os.getpid()}.log')
	app.set_log_file(temp_log)
	app.set_log_level(.debug)
	app.set_silent(true)

	app.debug('Debug payload check')
	app.info('Server started')
	app.warn('High load warning')
	app.error('Recoverable connection error')

	assert os.exists(temp_log)
	log_content := os.read_file(temp_log) or { '' }
	assert log_content.contains('[DEBUG] Debug payload check')
	assert log_content.contains('[INFO] Server started')
	assert log_content.contains('[WARN] High load warning')
	assert log_content.contains('[ERROR] Recoverable connection error')

	os.rm(temp_log) or {}
}

fn test_simplecli_state_store() {
	mut app := new('StateTest')
	app.set_silent(true)

	app.set_state('user', 'Alice')
	app.set_state('count', '42')
	app.set_state('active', 'true')

	assert app.get_state('user', '') == 'Alice'
	assert app.get_state('missing', 'default') == 'default'
	assert app.get_state_int('count', 0) == 42
	assert app.get_state_bool('active', false) == true

	// Persistence
	temp_state_file := os.join_path(os.temp_dir(), 'simplecli_test_state_${os.getpid()}.json')
	app.save_state(temp_state_file) or { panic(err) }
	assert os.exists(temp_state_file)

	mut app2 := new('StateTest2')
	app2.set_silent(true)
	app2.load_state(temp_state_file) or { panic(err) }
	assert app2.get_state('user', '') == 'Alice'
	assert app2.get_state_int('count', 0) == 42
	assert app2.get_state_bool('active', false) == true

	os.rm(temp_state_file) or {}
}

fn test_simplecli_visual_components() {
	mut app := new('VisualTest')
	app.set_no_color(true)
	app.set_silent(true)

	// Banners, panels, tables, and progress bars should execute cleanly without error
	app.banner('My Tool', 'v1.0')
	app.panel('Status', 'All systems operational.\nCPU: OK\nRAM: OK')
	app.divider('-', 40)
	
	headers := ['ID', 'Task', 'Status']
	rows := [
		['1', 'Database Migration', 'Completed'],
		['2', 'Asset Optimization', 'In Progress'],
		['3', 'Deploy Artifacts', 'Pending'],
	]
	app.table(headers, rows)
	app.progress_bar(50, 100, 'Processing')
	app.print_kv({
		'Host': 'localhost',
		'Port': '8080',
		'Env':  'Test',
	})

	assert true
}

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

fn test_sparkline_and_charts() {
	app := new('ChartTest')
	
	// Sparklines
	spark := app.sparkline([1.0, 3.0, 5.0, 7.0, 10.0])
	assert spark.len > 0
	assert sparkline([10.0, 20.0, 30.0]).len > 0
	assert app.sparkline([]).len == 0
	
	// Bar chart
	app.bar_chart('Metrics', {
		'CPU': 45.0
		'RAM': 80.0
	}, 20)

	// Gauge
	app.gauge('Disk /', 45.0, 100.0, 'GB')
	app.gauge('RAM /', 95.0, 100.0, 'GB') // Threshold trigger

	assert true
}

fn test_tree_structure() {
	mut root := new_tree_node('app-root')
	mut db := root.add_child('database')
	db.add_child('postgres-primary')
	db.add_child('postgres-replica')
	root.add_child('cache')

	assert root.label == 'app-root'
	assert root.children.len == 2
	assert root.children[0].label == 'database'
	assert root.children[0].children.len == 2

	app := new('TreeTest')
	app.tree(root)
	tree(root)
	assert true
}

fn test_diff_and_text() {
	app := new('DiffTest')
	old_str := 'name: my-app\nversion: 1.0.0\nport: 8080'
	new_str := 'name: my-app\nversion: 1.1.0\nport: 8080\nenv: prod'

	diff_out := app.diff_text(old_str, new_str)
	assert diff_out.contains('version: 1.0.0')
	assert diff_out.contains('version: 1.1.0')
	assert diff_out.contains('env: prod')
	assert diff_out.contains('additions')

	app.diff(old_str, new_str)
	diff(old_str, new_str)
	assert true
}

fn test_badges_alerts_and_tasks() {
	app := new('BadgeAlertTest')
	
	b1 := app.badge('STATUS', 'ACTIVE', .info)
	assert b1.contains('STATUS: ACTIVE')
	b2 := badge('ENV', 'PROD', .error)
	assert b2.contains('ENV: PROD')

	app.alert(.info, 'Info Title', 'This is an information notice.')
	app.alert(.success, 'Success Title', 'Operation finished cleanly.')
	app.alert(.warning, 'Warning Title', 'Resource nearing limits.')
	app.alert(.caution, 'Caution Title', 'Destructive action ahead.')
	alert(.tip, 'Tip Title', 'Use flags for unattended mode.')

	app.task_item('Compile C sources', .done, 140)
	app.task_item('Run linter', .running, 0)
	app.task_item('Deploy image', .pending, 0)
	app.task_item('Integration check', .failed, 45)
	task_item('Optional sync', .skipped, 0)

	assert true
}

fn test_table_exporters_and_json_highlight() {
	app := new('ExportTest')
	headers := ['ID', 'Name', 'Role']
	rows := [
		['1', 'Alice, VP', 'Admin'],
		['2', 'Bob', 'Developer'],
	]

	// CSV
	csv_str := app.table_to_csv(headers, rows)
	assert csv_str.contains('"Alice, VP"')
	assert csv_str.contains('Admin')
	assert table_to_csv(headers, rows).contains('Bob')

	// Markdown
	md_str := app.table_to_markdown(headers, rows)
	assert md_str.contains('| ID | Name | Role |')
	assert md_str.contains('| :--- | :--- | :--- |')
	assert md_str.contains('| 1 | Alice, VP | Admin |')

	// JSON
	json_str := app.table_to_json(headers, rows)
	assert json_str.contains('"Name":"Bob"')
	assert json_str.contains('"Role":"Admin"')

	// JSON Highlight
	highlighted := app.json_highlight('{"name": "test", "count": 42, "active": true}')
	assert highlighted.len > 0

	// Markdown rendering
	app.render_markdown('# Headline\n## Subheader\n* Bullet 1\n* Bullet 2\n> Quoted note')
	render_markdown('## Section\n- item')

	assert true
}

fn test_pipeline_execution() {
	mut app := new('PipelineTest')
	app.set_silent(true)

	mut pipeline := app.new_pipeline('Test Pipeline')
	pipeline.add_step('Step 1', fn () bool {
		return true
	})
	pipeline.add_step('Step 2', fn () bool {
		return true
	})

	ok := pipeline.run()
	assert ok == true
}


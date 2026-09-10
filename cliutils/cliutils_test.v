module cliutils

fn test_ansi_styling() {
	b := bold('Hello')
	assert b.contains('Hello')
	assert b.starts_with('\x1b[1m')
	assert b.ends_with('\x1b[0m')

	r := red('Error')
	assert r.starts_with('\x1b[31m')

	g := green('Success')
	assert g.starts_with('\x1b[32m')

	stripped := strip_ansi(bold(green('Styled text')))
	assert stripped == 'Styled text'
}

fn test_progress_bar() {
	mut pb := new_progress_bar(100, 20)
	assert pb.current == 0

	pb.update(50)
	assert pb.current == 50

	rendered := pb.render()
	assert rendered.contains('50%')
	assert rendered.contains('(50/100)')
	assert rendered.starts_with('[')

	pb.update(100)
	r100 := pb.render()
	assert r100.contains('100%')
	assert r100.contains('(100/100)')
}

fn test_flag_parser() {
	mut fp := new_flag_parser('deployer', 'Automated deploy tool')
	fp.add_flag_string('config', 'c', 'app.json', 'Config path')
	fp.add_flag_int('port', 'p', 8080, 'Listen port')
	fp.add_flag_bool('dry-run', 'd', false, 'Dry run')

	fp.parse(['--config', 'prod.json', '-p', '9000', '--dry-run', 'target1', 'target2']) or {
		panic(err)
	}

	assert fp.get_string('config') == 'prod.json'
	assert fp.get_int('port') == 9000
	assert fp.get_bool('dry-run') == true

	pos := fp.get_positional()
	assert pos.len == 2
	assert pos[0] == 'target1'
	assert pos[1] == 'target2'

	help := fp.format_help()
	assert help.contains('Usage:')
	assert help.contains('--config')
}

fn test_pipeline() {
	mut p := new_pipeline('Test Pipeline')
	mut step1_executed := false
	mut step2_executed := false

	p.add_step('Step 1', fn [mut step1_executed] () bool {
		step1_executed = true
		return true
	})
	p.add_step('Step 2', fn [mut step2_executed] () bool {
		step2_executed = true
		return true
	})

	success := p.run()
	assert success == true
}

fn test_rad_visualizations() {
	// Sparkline
	values := [1.0, 3.0, 5.0, 7.0, 9.0]
	spark := sparkline(values)
	assert spark.len > 0

	// Bar chart
	chart := bar_chart('Test Chart', {
		'A': 10.0
		'B': 20.0
	}, 10)
	assert chart.contains('A')
	assert chart.contains('B')

	// Gauge
	g := gauge('CPU', 45.0, 100.0, '%')
	assert g.contains('45.0/100.0')

	// Tree
	mut root := new_tree_node('root')
	root.add_child('child1')
	root.add_child('child2')
	tree_text := render_tree(&root)
	assert tree_text.contains('root')
	assert tree_text.contains('child1')
	assert tree_text.contains('child2')

	// Diff
	diff_str := diff_text('line1\nline2', 'line1\nline2_modified')
	assert diff_str.contains('- line2')
	assert diff_str.contains('+ line2_modified')

	// Table converters
	headers := ['Name', 'Role']
	rows := [['Alice', 'Admin'], ['Bob', 'Dev']]

	md := table_to_markdown(headers, rows)
	assert md.contains('| Name | Role |')
	assert md.contains('| Alice | Admin |')

	csv := table_to_csv(headers, rows)
	assert csv.contains('Name,Role')
	assert csv.contains('Alice,Admin')

	js := table_to_json(headers, rows)
	assert js.contains('"Name": "Alice"')

	// Highlighting & containers
	highlighted := json_highlight('{"key": "val"}')
	assert highlighted.len > 0

	b := banner('Title', 'Subtitle')
	assert b.contains('Title')

	pnl := panel('Panel Title', 'Content')
	assert pnl.contains('Panel Title')
}

fn test_clipboard() {
	if is_clipboard_available() {
		original := read_from_clipboard()
		test_msg := 'antigravity_vlang_utils_test'
		if copy_to_clipboard(test_msg) {
			pasted := read_from_clipboard()
			assert pasted == test_msg
			copy_to_clipboard(original)
		}
	}
}


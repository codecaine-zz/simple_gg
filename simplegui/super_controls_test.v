module simplegui

fn test_super_stat_card() {
	mut win := new_simple_window('Stat Test', 800, 600)
	win.add_stat_card('kpi_rev', 'Total Revenue', '$148,200', '+18.4%', true, [12.0, 34.0, 56.0, 78.0, 95.0])
	
	assert win.has_control('kpi_rev')
	ctrl := win.control('kpi_rev')
	assert ctrl.kind == 'super_stat_card'
	assert ctrl.title == 'Total Revenue'
	assert ctrl.text_value == '$148,200'
	assert ctrl.placeholder == '+18.4%'
	assert ctrl.bool_value == true
	assert ctrl.f64_list.len == 5

	win.set_stat_card('kpi_rev', 'Updated Revenue', '$200,000', '+25.0%', true)
	ctrl2 := win.control('kpi_rev')
	assert ctrl2.title == 'Updated Revenue'
	assert ctrl2.text_value == '$200,000'
}

fn test_code_studio() {
	mut win := new_simple_window('Code Test', 800, 600)
	win.add_code_studio('studio', 'main.v', 'v', 'fn main() {\n\tprintln(\'Hello Super Controls!\')\n}')
	
	assert win.has_control('studio')
	ctrl := win.control('studio')
	assert ctrl.kind == 'code_studio'
	assert ctrl.title == 'main.v'
	assert ctrl.code_lang == 'v'
	assert ctrl.text_value.contains('Hello Super Controls!')

	win.set_code_studio('studio', 'app.v', 'v', 'fn main() {}')
	ctrl2 := win.control('studio')
	assert ctrl2.title == 'app.v'
	assert ctrl2.text_value == 'fn main() {}'
}

fn test_kanban_board() {
	mut win := new_simple_window('Kanban Test', 800, 600)
	win.add_kanban_board('board', ['Backlog', 'In Progress', 'Done'])
	win.add_kanban_card('board', 0, 'UI|HIGH|Design Super Controls')
	win.add_kanban_card('board', 1, 'CORE|MED|Implement Engine')
	win.add_kanban_card('board', 2, 'TEST|LOW|All Tests Passing')

	assert win.has_control('board')
	ctrl := win.control('board')
	assert ctrl.kind == 'kanban_board'
	assert ctrl.items.len == 3
	assert ctrl.items_selected.len == 3
	assert ctrl.items_selected[0].contains('Design Super Controls')
}

fn test_activity_feed() {
	mut win := new_simple_window('Feed Test', 800, 600)
	win.add_activity_feed('feed', [
		'DEPLOY|2m ago|Release v2.5 shipped to production',
		'ALERT|12m ago|Spike in database read queries',
	])
	win.add_feed_event('feed', 'New user registered', '1m ago', 'INFO')

	assert win.has_control('feed')
	ctrl := win.control('feed')
	assert ctrl.kind == 'activity_feed'
	assert ctrl.items.len == 3
}

fn test_donut_chart() {
	mut win := new_simple_window('Donut Test', 800, 600)
	win.add_donut_chart('cpu_gauge', 'CPU Load', 64.5)
	
	assert win.has_control('cpu_gauge')
	ctrl := win.control('cpu_gauge')
	assert ctrl.kind == 'donut_chart'
	assert ctrl.f64_value == 64.5

	win.set_donut_percentage('cpu_gauge', 88.0)
	assert win.control('cpu_gauge').f64_value == 88.0
}

fn test_terminal_console() {
	mut win := new_simple_window('Terminal Test', 800, 600)
	win.add_terminal_console('term', ['Output', 'Build', 'Debug'])
	win.log_terminal('term', '[INFO] Server initialized on port 3000')
	win.log_terminal('term', '[OK] Database connected in 4ms')
	win.log_terminal('term', '[WARN] Rate limit threshold at 80%')

	assert win.has_control('term')
	ctrl := win.control('term')
	assert ctrl.kind == 'super_terminal'
	assert ctrl.items.len == 3
	assert ctrl.items_selected.len == 3

	win.clear_terminal('term')
	assert win.control('term').items_selected.len == 0
}

fn test_smart_table() {
	mut win := new_simple_window('Smart Table Test', 800, 600)
	headers := ['ID', 'User', 'Status', 'MRR']
	rows := [
		['#101', 'Ada Lovelace', 'Active', '$499'],
		['#102', 'Grace Hopper', 'Pending', '$299'],
		['#103', 'Alan Turing', 'Done', '$899'],
	]
	win.add_smart_table('users_grid', headers, rows)

	assert win.has_control('users_grid')
	ctrl := win.control('users_grid')
	assert ctrl.kind == 'smart_table'
	assert ctrl.headers.len == 4
	assert ctrl.rows.len == 3
	assert ctrl.current_page == 1
}

fn test_wizard_stepper() {
	mut win := new_simple_window('Wizard Test', 800, 600)
	win.add_wizard_stepper('stepper', ['Account', 'Profile', 'Billing', 'Confirm'], 1)

	assert win.has_control('stepper')
	ctrl := win.control('stepper')
	assert ctrl.kind == 'wizard_stepper'
	assert ctrl.items.len == 4
	assert ctrl.int_value == 1

	win.wizard_next('stepper')
	assert win.control('stepper').int_value == 2

	win.wizard_prev('stepper')
	assert win.control('stepper').int_value == 1

	win.set_wizard_step('stepper', 3)
	assert win.control('stepper').int_value == 3
}

fn test_floating_toolbar_and_chips() {
	mut win := new_simple_window('Toolbar & Chips Test', 800, 600)
	win.add_floating_toolbar('hero_bar', 'Workspace', ['Overview', 'Analytics', 'Settings', 'Deploy'])
	win.add_chip_input('tags_cloud', ['VLang', 'UI', 'Fast', 'Native'])

	assert win.has_control('hero_bar')
	assert win.control('hero_bar').kind == 'floating_toolbar'
	assert win.control('hero_bar').items.len == 4

	assert win.has_control('tags_cloud')
	assert win.control('tags_cloud').kind == 'chip_cloud'
	assert win.control('tags_cloud').tags.len == 4

	win.add_chip('tags_cloud', 'SuperControls')
	assert win.control('tags_cloud').tags.len == 5
	assert 'SuperControls' in win.control('tags_cloud').tags

	win.remove_chip('tags_cloud', 'Fast')
	assert win.control('tags_cloud').tags.len == 4
	assert 'Fast' !in win.control('tags_cloud').tags
}

fn test_score_card() {
	mut win := new_simple_window('Score Test', 800, 600)
	win.add_score_card('score', 'Developer Happiness', 4.9, 1420, [88.0, 9.0, 2.0, 0.7, 0.3])

	assert win.has_control('score')
	ctrl := win.control('score')
	assert ctrl.kind == 'score_card'
	assert ctrl.f64_value == 4.9
	assert ctrl.int_value == 1420
	assert ctrl.f64_list.len == 5
}

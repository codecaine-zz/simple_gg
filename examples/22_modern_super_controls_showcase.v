module main

import simplegui

fn main() {
	// 1. Create Window with Nord dark theme
	mut win := simplegui.new_simple_window('Modern Super Controls Showcase - SimpleGUI', 960, 720)
	win.set_theme('Nord')

	// 2. Main Tabbed Layout Container for Clean Navigation
	win.begin_tab_container('main_tabs', [
		'Dashboard & Metrics',
		'Code Studio & Terminal',
		'Kanban & Smart Table',
	])

	// ==========================================
	// TAB 1: Dashboard & Metrics
	// ==========================================
	win.begin_tab_page('page_dashboard', 0)

	// Top Floating Action Pill Bar
	win.add_floating_toolbar('hero_bar', 'DevStudio Pro', [
		'Overview',
		'Real-time Stream',
		'Security Center',
		'Cloud Deploy',
	])

	// Deployment Wizard Stepper
	win.add_wizard_stepper('deploy_wizard', [
		'Configuration',
		'Build & Test',
		'Security Audit',
		'Production Deploy',
	], 1)

	// High-Impact KPI Row with Sparklines & Donut Meter
	win.begin_row('stats_row')
	win.add_stat_card('stat_revenue', 'Monthly Revenue', '$184,520', '+22.4% vs last mo', true, [
		20.0, 35.0, 30.0, 50.0, 45.0, 70.0, 85.0, 95.0,
	])
	win.add_stat_card('stat_latency', 'API Response Time', '14.2 ms', '-18.6% faster', true, [
		60.0, 55.0, 48.0, 40.0, 32.0, 24.0, 18.0, 14.0,
	])
	win.add_donut_chart('cpu_meter', 'CPU Core Load', 78.5)
	win.end_row()

	// Activity Feed & Score Card in a balanced row
	win.begin_row('feed_score_row')
	win.add_activity_feed('stream', [
		'DEPLOY|2m ago|Release v2.8 deployed to us-central-1',
		'OK|8m ago|All 42 automated tests passed in 1.4s',
		'WARN|22m ago|High memory watermark at 84%',
		'INFO|45m ago|Automated daily backup completed (2.4 GB)',
	])
	win.add_score_card('score', 'Developer Satisfaction', 4.95, 3840, [
		92.0, 6.0, 1.2, 0.5, 0.3,
	])
	win.end_row()

	// Removable Category Chips Cloud
	win.add_chip_input('tags', [
		'VLang',
		'Native UI',
		'Zero Dependencies',
		'Super Controls',
		'60 FPS Metal',
		'RAD Engine',
	])
	win.end_tab_page()

	// ==========================================
	// TAB 2: Code Studio & Terminal Console
	// ==========================================
	win.begin_tab_page('page_code_term', 1)

	win.add_code_studio('studio', 'main.v', 'v', 'module main\n\nimport simplegui\n\nfn main() {\n    mut win := simplegui.new_simple_window(\'Super App\', 800, 600)\n    win.stat(\'Revenue\', \'$184k\', \'+22%\', true, [20.0, 50.0, 85.0])\n    win.run()\n}')

	win.add_terminal_console('term_logs', [
		'Build Server',
		'Output Stream',
		'Debug Console',
	])
	win.log_terminal('term_logs', '[INFO] SimpleGUI v1.0.0 initializing graphics context...')
	win.log_terminal('term_logs', '[OK] Metal / OpenGL hardware acceleration active (60 FPS)')
	win.log_terminal('term_logs', '[INFO] Loaded 11 Modern Super Controls into window registry')
	win.log_terminal('term_logs', '[OK] Live state synchronized across all UI components')
	win.log_terminal('term_logs', '[SUCCESS] Ready for developer interactions!')
	win.end_tab_page()

	// ==========================================
	// TAB 3: Kanban & Smart Table
	// ==========================================
	win.begin_tab_page('page_kanban_table', 2)

	// Kanban Board
	win.add_kanban_board('kanban', ['Backlog', 'In Progress', 'Code Review', 'Shipped'])
	win.add_kanban_card('kanban', 0, 'UI|HIGH|Design Super Controls')
	win.add_kanban_card('kanban', 0, 'DOCS|MED|Update API.md Catalog')
	win.add_kanban_card('kanban', 1, 'CORE|HIGH|Implement Vector Render Engine')
	win.add_kanban_card('kanban', 2, 'TEST|MED|Run Automated Unit Tests')
	win.add_kanban_card('kanban', 3, 'PERF|LOW|Zero Allocation Passes')
	win.add_kanban_card('kanban', 3, 'RAD|LOW|Ergonomic Method Chaining')

	// Smart Data Table with Status Pills & Pagination
	headers := ['ID', 'Customer', 'Status', 'MRR Plan', 'Region']
	rows := [
		['#101', 'Ada Lovelace', 'Active', '$1,450 / mo', 'US-East'],
		['#102', 'Grace Hopper', 'Done', '$899 / mo', 'US-West'],
		['#103', 'Alan Turing', 'Pending', '$499 / mo', 'EU-Central'],
		['#104', 'Margaret Hamilton', 'Active', '$2,200 / mo', 'US-Central'],
		['#105', 'Claude Shannon', 'Review', '$299 / mo', 'AP-South'],
		['#106', 'Dennis Ritchie', 'Active', '$1,800 / mo', 'US-East'],
		['#107', 'Ken Thompson', 'Done', '$1,200 / mo', 'US-West'],
	]
	win.add_smart_table('customers_grid', headers, rows)
	win.end_tab_page()

	win.end_tab_container()

	// 3. Interactive Event Handlers
	win.on_click('deploy_wizard', fn (mut win simplegui.SimpleWindow) {
		step := win.control('deploy_wizard').int_value
		win.show_toast('Wizard Navigation', 'Active step is now: Step ${step + 1}')
	})

	win.on_click('hero_bar', fn (mut win simplegui.SimpleWindow) {
		tab := win.control('hero_bar').text_value
		win.show_toast('Floating Bar Action', 'Clicked: ${tab}')
	})

	// Run Application
	win.run()
}

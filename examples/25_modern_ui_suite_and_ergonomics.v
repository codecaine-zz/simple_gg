module main

import simplegui

fn main() {
	// 1. Create modern desktop window (Width: 1080px, Height: 780px)
	mut win := simplegui.new_simple_window('Modern UI Suite & Ergonomic Enhancements - SimpleGUI', 1080, 780)
	win.set_theme('Executive Slate')

	// 2. Setup Top Action Bar with Vector Icons & Soft Elevation
	win.begin_row('top_bar')
	win.add_heading('DevStudio Workspace Pro')
	win.control('heading_1').set_width(340)
	win.add_button('btn_drawer', '[=] Drawer')
	win.control('btn_drawer').set_elevation(2).set_vector_icon('menu').set_width(120)
	win.add_button('btn_zoom', '[+] Zoom (1.25x)')
	win.control('btn_zoom').set_elevation(1).set_vector_icon('search').set_width(140)
	win.add_button('btn_theme', '[*] Theme')
	win.control('btn_theme').set_elevation(1).set_vector_icon('refresh').set_width(110)
	win.end_row()

	// 3. Main Workspace Tab Container
	win.begin_tab_container('content_tabs', [
		'Analytics & Heatmap',
		'Tree Grid & Calendar',
		'Form UX & Markdown',
	])

	// ---------------------------------------------------------
	// TAB 1: Gradient Spline Charts, Heatmaps & Flow Layout
	// ---------------------------------------------------------
	win.begin_tab_page('tab_analytics', 0)
	win.begin_row('analytics_top_row')
	
	// Navigation Rail preview
	nav_items := [
		simplegui.SidebarItem{ id: 'dash', title: 'Dashboard', icon: 'home', is_active: true },
		simplegui.SidebarItem{ id: 'data', title: 'Cluster', icon: 'database', badge: '12' },
		simplegui.SidebarItem{ id: 'docs', title: 'Docs', icon: 'folder' },
		simplegui.SidebarItem{ id: 'settings', title: 'Config', icon: 'gear' },
	]
	win.add_nav_rail('app_rail', nav_items)

	// Gradient Spline Area Chart
	win.add_area_chart('spline_revenue', 'Monthly ARR Growth ($k)', [
		12.5, 18.0, 24.5, 42.0, 38.0, 65.0, 84.0, 96.5,
	]).set_elevation(2)
	win.control('spline_revenue').set_width(940)
	win.end_row()

	win.add_subheading('GitHub-Style Annual Activity Heatmap')
	mut matrix := [][]int{len: 7, init: []int{len: 26, init: 0}}
	matrix[1][3] = 3
	matrix[1][4] = 4
	matrix[2][8] = 2
	matrix[3][10] = 5
	matrix[4][15] = 4
	matrix[5][20] = 3
	win.add_activity_heatmap('gh_heatmap', 'Developer Contribution Matrix (Last 26 Weeks)', 26, matrix).set_elevation(2)

	win.add_subheading('Auto-Wrapping Flow Layout (Responsive Chip Cloud)')
	win.begin_flow_layout('flow_tags', 8)
	win.add_button('chip_1', 'V Language')
	win.control('chip_1').set_elevation(1).set_vector_icon('check')
	win.add_button('chip_2', '60 FPS Vector Graphics')
	win.control('chip_2').set_elevation(1).set_vector_icon('star')
	win.add_button('chip_3', 'Zero External Dependencies')
	win.control('chip_3').set_elevation(1).set_vector_icon('lock')
	win.add_button('chip_4', 'Elevation Shadows')
	win.control('chip_4').set_elevation(1).set_vector_icon('bell')
	win.add_button('chip_5', 'Spline Interpolation')
	win.control('chip_5').set_elevation(1).set_vector_icon('cloud')
	win.add_button('chip_6', 'Focus Trapping')
	win.control('chip_6').set_elevation(1).set_vector_icon('eye')
	win.add_button('chip_7', 'Tab Navigation')
	win.control('chip_7').set_elevation(1).set_vector_icon('arrow_right')
	win.end_flow_layout()
	win.end_tab_page()

	// ---------------------------------------------------------
	// TAB 2: Hierarchical Tree Table & Interactive Month Calendar
	// ---------------------------------------------------------
	win.begin_tab_page('tab_data_cal', 1)
	win.begin_row('data_cal_row')

	// Tree Table
	headers := ['Name', 'Size', 'Type']
	tree_nodes := [
		simplegui.TreeTableRow{
			id: 'src'
			values: ['src/', '--', 'Folder']
			is_expanded: true
			children: [
				simplegui.TreeTableRow{ id: 'main', values: ['main.v', '4.2 KB', 'V Source'] },
				simplegui.TreeTableRow{ id: 'render', values: ['render.v', '125.1 KB', 'V Source'] },
				simplegui.TreeTableRow{ id: 'events', values: ['events.v', '54.3 KB', 'V Source'] },
			]
		},
		simplegui.TreeTableRow{
			id: 'assets'
			values: ['assets/', '--', 'Folder']
			is_expanded: false
			children: [
				simplegui.TreeTableRow{ id: 'logo', values: ['logo.png', '48.0 KB', 'Image'] },
			]
		},
	]
	win.add_tree_table('tree_grid', headers, tree_nodes).set_elevation(2)

	// Month Calendar
	win.add_calendar('month_cal', 2026, 8, 21).set_elevation(2)
	win.end_row()
	win.end_tab_page()

	// ---------------------------------------------------------
	// TAB 3: Form UX (Masked Inputs, Inline Labels) & Markdown Viewport
	// ---------------------------------------------------------
	win.begin_tab_page('tab_form_md', 2)
	win.add_subheading('Form Ergonomics & Masked Inputs')
	
	win.begin_row('form_row_1')
	win.add_label('lbl_ph', 'Phone Number Mask:')
	win.control('lbl_ph').set_width(200)
	win.add_masked_input('input_phone', '(###) ###-####', '5551234567')
	win.end_row()

	win.begin_row('form_row_2')
	win.add_label('lbl_ip', 'Server IP Mask:')
	win.control('lbl_ip').set_width(200)
	win.add_masked_input('input_ip', '###.###.###.###', '192168001001')
	win.end_row()

	win.begin_row('form_row_3')
	win.add_label('lbl_edit', 'Click-to-Edit Project Name:')
	win.control('lbl_edit').set_width(200)
	win.add_inline_editable_label('proj_name', 'Cybernetic Cloud Cluster')
	win.end_row()

	win.add_subheading('Native Markdown Document Viewer')
	md_text := '# Release v2.5 Highlights\n> Lightweight zero-dependency desktop toolkit for V.\n- Procedural vector icon system (28+ glyphs)\n- Soft elevation shadows & focus rings\n- Stacks & auto-wrapping flow layout\n- Slide-over drawer panels & Tab navigation\n```v\nmut win := simplegui.new_simple_window("App", 800, 600)\nwin.run()\n```'
	win.add_markdown_view('doc_viewer', md_text).set_elevation(2)
	win.control('doc_viewer').set_height(220)
	win.end_tab_page()

	win.end_tab_container()

	// =========================================================
	// 4. Interactive Event Listeners & Ergonomic Interactions
	// =========================================================

	// Slide-over Drawer Handler with rich navigation items & sections
	win.on_click('btn_drawer', fn (mut win simplegui.SimpleWindow) {
		win.show_drawer('Workspace Services & Quick Actions', 380, 'right', fn (mut w simplegui.SimpleWindow) {
			w.add_drawer_section('Cloud Infrastructure')
			w.add_drawer_item(simplegui.DrawerItem{
				id: 'dr_cluster'
				title: 'Database Clusters'
				subtitle: '3 Active nodes running v16.2'
				icon: 'database'
				badge: 'PRO'
				is_active: true
				on_click: fn (mut win simplegui.SimpleWindow) {
					win.push_toast('Database Cluster', 'Switched to primary database cluster node.', 'info', 2000)
				}
			})
			w.add_drawer_item(simplegui.DrawerItem{
				id: 'dr_deploy'
				title: 'Cloud Deployments'
				subtitle: 'us-east-1 & eu-central-1 regions'
				icon: 'cloud'
				badge: 'LIVE'
				on_click: fn (mut win simplegui.SimpleWindow) {
					win.push_toast('Cloud Deployments', 'Syncing regional deployment status.', 'info', 2000)
				}
			})
			w.add_drawer_item(simplegui.DrawerItem{
				id: 'dr_sec'
				title: 'Security & Access Keys'
				subtitle: '2FA enforced, rotating certs'
				icon: 'lock'
				on_click: fn (mut win simplegui.SimpleWindow) {
					win.push_toast('Security Keys', 'Rotating temporary API session tokens.', 'warning', 2000)
				}
			})

			w.add_drawer_section('Workspace Tools')
			w.add_drawer_item(simplegui.DrawerItem{
				id: 'dr_repos'
				title: 'Repository Activity Log'
				subtitle: 'Latest commits & branch merges'
				icon: 'folder'
				badge: '24'
				on_click: fn (mut win simplegui.SimpleWindow) {
					win.push_toast('Repository Log', 'Loaded 24 commit entries for simple_gg.', 'info', 2000)
				}
			})
			w.add_drawer_item(simplegui.DrawerItem{
				id: 'dr_bell'
				title: 'Telemetry Notifications'
				subtitle: 'Real-time health alerts enabled'
				icon: 'bell'
				badge: 'NEW'
				on_click: fn (mut win simplegui.SimpleWindow) {
					win.push_toast('Notifications', 'All telemetry streams healthy.', 'info', 2000)
				}
			})
			w.add_drawer_item(simplegui.DrawerItem{
				id: 'dr_diag'
				title: 'System Diagnostics & Profiling'
				subtitle: 'Memory profiling & 60 FPS graphics'
				icon: 'gear'
				on_click: fn (mut win simplegui.SimpleWindow) {
					win.push_toast('Diagnostics', 'Memory usage nominal: 14.2 MB allocated.', 'info', 2000)
				}
			})
			w.add_drawer_item(simplegui.DrawerItem{
				id: 'dr_user'
				title: 'User Profile & Identity'
				subtitle: 'codecaine@workspace.dev'
				icon: 'user'
				on_click: fn (mut win simplegui.SimpleWindow) {
					win.push_toast('User Account', 'Logged in as codecaine.', 'info', 2000)
				}
			})
		})
	})

	// Zoom UI Scaling Handler
	win.on_click('btn_zoom', fn (mut win simplegui.SimpleWindow) {
		cur_scale := win.get_ui_scale()
		new_scale := if cur_scale >= 1.5 { 1.0 } else { cur_scale + 0.25 }
		win.set_ui_scale(new_scale)
		win.set_text('btn_zoom', '[+] Zoom Scale (${new_scale:.2f}x)')
		win.info('UI Zoom Scaled', 'Global scaling factor set to ${new_scale:.2f}x')
	})

	// Toggle Theme Handler
	win.on_click('btn_theme', fn (mut win simplegui.SimpleWindow) {
		if win.is_dark_theme() {
			win.set_theme('Enterprise Light')
		} else {
			win.set_theme('Executive Slate')
		}
	})

	// Calendar date selection listener
	win.on_change('month_cal', fn (mut win simplegui.SimpleWindow) {
		y, m, d := win.get_calendar_date('month_cal')
		win.push_toast('Calendar Date', 'Selected Date: ${y}-${m:02d}-${d:02d}', 'info', 2000)
	})

	// 5. Launch Event Loop
	win.run()
}

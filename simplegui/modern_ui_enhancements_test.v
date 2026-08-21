module simplegui

fn test_ui_scale() {
	mut win := new_simple_window('Scale Test', 800, 600)
	assert win.get_ui_scale() == 1.0
	win.set_ui_scale(1.25)
	assert win.get_ui_scale() == 1.25
	win.set_zoom(1.5)
	assert win.get_ui_scale() == 1.5
}

fn test_vector_icons_and_elevation() {
	mut win := new_simple_window('Vector Icon Test', 800, 600)
	mut icon_ctrl := win.add_vector_icon('ic_search', 'search', 24)
	icon_ctrl.set_elevation(2)
	assert icon_ctrl.icon_vector == 'search'
	assert icon_ctrl.elevation == 2
	assert icon_ctrl.w == 24.0
	assert icon_ctrl.h == 24.0
}

fn test_sidebar_and_nav_rail() {
	mut win := new_simple_window('Nav Test', 800, 600)
	items := [
		SidebarItem{ id: 'home', title: 'Dashboard', icon: 'home', is_active: true },
		SidebarItem{ id: 'settings', title: 'Settings', icon: 'gear', badge: 'NEW' },
		SidebarItem{ id: 'users', title: 'Users', icon: 'user' },
	]
	mut sb := win.add_sidebar('main_sidebar', items)
	assert sb.sidebar_items.len == 3
	assert sb.sidebar_items[0].is_active == true
	assert sb.is_collapsed == false
	assert sb.w == 220.0

	// Toggle collapse
	win.toggle_sidebar('main_sidebar')
	assert sb.is_collapsed == true
	assert sb.w == 64.0

	// Set active item
	win.set_sidebar_active('main_sidebar', 'settings')
	assert sb.sidebar_items[0].is_active == false
	assert sb.sidebar_items[1].is_active == true

	// Nav rail
	mut rail := win.add_nav_rail('main_rail', items)
	assert rail.kind == 'nav_rail'
	assert rail.is_collapsed == true
	assert rail.w == 64.0
}

fn test_stacks_and_flow_layout() {
	mut win := new_simple_window('Layouts Test', 800, 600)
	
	// Stacks
	win.vstack('stack_col', 'center', 10, fn (mut w SimpleWindow) {
		w.add_button('v_btn1', 'Item 1')
		w.add_button('v_btn2', 'Item 2')
	})
	assert win.has_control('stack_col_vstart')
	assert win.has_control('stack_col_vend')
	assert win.has_control('v_btn1')
	assert win.has_control('v_btn2')

	win.hstack('stack_row', 'left', 12, fn (mut w SimpleWindow) {
		w.add_button('h_btn1', 'Left')
		w.add_button('h_btn2', 'Right')
	})
	assert win.has_control('stack_row_hstart')
	assert win.has_control('stack_row_hend')

	// Flow layout
	win.begin_flow_layout('flow_panel', 8)
	win.add_button('fl_1', 'Tag A')
	win.add_button('fl_2', 'Tag B')
	win.end_flow_layout()
	assert win.has_control('flow_panel')
}

fn test_slide_over_drawer() {
	mut win := new_simple_window('Drawer Test', 800, 600)
	assert win.is_drawer_active() == false
	win.show_drawer('Quick Filters', 360, 'right', fn (mut w SimpleWindow) {
		w.add_drawer_section('Services')
		w.add_drawer_item(DrawerItem{
			id: 'd_cluster'
			title: 'Database Cluster'
			subtitle: 'Active node v16'
			icon: 'database'
			badge: 'PRO'
			is_active: true
		})
		w.add_drawer_item(DrawerItem{
			id: 'd_settings'
			title: 'Settings'
			icon: 'gear'
		})
	})
	assert win.is_drawer_active() == true
	assert win.drawer_title == 'Quick Filters'
	assert win.drawer_width == 360.0
	assert win.drawer_side == 'right'
	assert win.drawer_items.len == 3
	assert win.drawer_items[0].is_header == true
	assert win.drawer_items[1].is_active == true

	win.set_drawer_active_item('d_settings')
	assert win.drawer_items[1].is_active == false
	assert win.drawer_items[2].is_active == true

	win.hide_drawer()
	assert win.is_drawer_active() == false
	assert win.drawer_items.len == 0
}

fn test_area_chart_and_spline() {
	mut win := new_simple_window('Area Chart Test', 800, 600)
	data := [10.0, 25.0, 18.0, 45.0, 60.0, 85.0]
	mut chart := win.add_area_chart('area_rev', 'Quarterly Revenue', data)
	assert chart.kind == 'area_chart'
	assert chart.f64_list.len == 6
	assert chart.f64_list[3] == 45.0

	mut spline := win.add_spline_chart('spline_rev', 'Spline Trend', data)
	assert spline.kind == 'area_chart'
}

fn test_activity_heatmap_and_contribution_grid() {
	mut win := new_simple_window('Heatmap Test', 800, 600)
	mut matrix := [][]int{len: 7, init: []int{len: 26, init: 0}}
	matrix[1][4] = 3
	matrix[3][10] = 5
	mut hm := win.add_activity_heatmap('gh_heatmap', 'Commit Activity', 26, matrix)
	assert hm.kind == 'activity_heatmap'
	assert hm.int_value == 26
	assert hm.heatmap_data[1][4] == 3

	mut grid := win.add_contribution_grid('gh_grid', 'Contributions', 26, matrix)
	assert grid.kind == 'activity_heatmap'
}

fn test_tree_table() {
	mut win := new_simple_window('Tree Table Test', 800, 600)
	headers := ['Name', 'Size', 'Type']
	nodes := [
		TreeTableRow{
			id: 'root'
			values: ['src', '--', 'Folder']
			is_expanded: true
			children: [
				TreeTableRow{ id: 'main', values: ['main.v', '4.2 KB', 'V File'] },
				TreeTableRow{ id: 'utils', values: ['utils.v', '2.1 KB', 'V File'] },
			]
		}
	]
	mut tt := win.add_tree_table('code_tree', headers, nodes)
	assert tt.kind == 'tree_table'
	assert tt.headers.len == 3
	assert tt.tree_table_nodes.len == 1
	assert tt.tree_table_nodes[0].children.len == 2
}

fn test_calendar_and_markdown() {
	mut win := new_simple_window('Calendar Test', 800, 600)
	mut cal := win.add_calendar('cal_widget', 2026, 8, 21)
	assert cal.kind == 'calendar'
	y, m, d := win.get_calendar_date('cal_widget')
	assert y == 2026
	assert m == 8
	assert d == 21

	win.set_calendar_date('cal_widget', 2027, 1, 15)
	y2, m2, d2 := win.get_calendar_date('cal_widget')
	assert y2 == 2027
	assert m2 == 1
	assert d2 == 15

	// Markdown
	md_text := '# Header\n> Blockquote\n- Bullet 1\n- Bullet 2\n```v\nfn main() {}\n```'
	mut md_view := win.add_markdown_view('doc_view', md_text)
	assert md_view.kind == 'markdown_view'
	assert md_view.markdown_content.contains('Blockquote')

	win.set_markdown('doc_view', '## Updated Header')
	assert md_view.markdown_content == '## Updated Header'
}

fn test_masked_input_and_inline_label() {
	mut win := new_simple_window('Form UX Test', 800, 600)
	mut masked := win.add_masked_input('phone_in', '(###) ###-####', '5551234567')
	assert masked.kind == 'masked_input'
	assert masked.mask_pattern == '(###) ###-####'
	assert masked.text_value == '5551234567'

	mut inline_lbl := win.add_inline_editable_label('proj_name', 'My Project')
	assert inline_lbl.kind == 'inline_label'
	assert inline_lbl.title == 'My Project'
	assert inline_lbl.is_editing == false
}

fn test_easing_functions() {
	assert ease_out_cubic(0.0) == 0.0
	assert ease_out_cubic(1.0) == 1.0
	assert ease_in_out_quad(0.0) == 0.0
	assert ease_in_out_quad(1.0) == 1.0
	assert ease_out_quad(0.0) == 0.0
	assert ease_out_quad(1.0) == 1.0
}

fn test_tab_focus_navigation() {
	mut win := new_simple_window('Focus Test', 800, 600)
	win.add_input('in_1', 'First')
	win.add_input('in_2', 'Second')
	win.add_button('btn_1', 'Submit')

	win.focus_next_control()
	assert win.control('in_1').is_focused == true

	win.focus_next_control()
	assert win.control('in_2').is_focused == true

	win.focus_next_control()
	assert win.control('btn_1').is_focused == true

	win.focus_prev_control()
	assert win.control('in_2').is_focused == true

	win.focus_control('in_1')
	assert win.control('in_1').is_focused == true
	assert win.control('in_2').is_focused == false
}

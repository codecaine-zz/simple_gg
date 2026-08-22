module main

import simplegui
import os
import math
import time

// -------------------------------------------------------------
// String Padding Helpers
// -------------------------------------------------------------

fn pad_l(s string, width int) string {
	if s.len >= width { return s }
	return ' '.repeat(width - s.len) + s
}

fn pad_r(s string, width int) string {
	if s.len >= width { return s }
	return s + ' '.repeat(width - s.len)
}

// -------------------------------------------------------------
// Mathematical Function Expression Evaluator
// -------------------------------------------------------------

enum FuncType {
	fn_sin
	fn_cos
	fn_tan
	fn_sinc
	fn_exp
	fn_gaussian
	fn_sigmoid
	fn_damped_wave
	fn_poly
	fn_log
	fn_sqrt
	fn_abs
	fn_beats
}

fn eval_func(ft FuncType, x f64, p1 f64, p2 f64) f64 {
	match ft {
		.fn_sin {
			freq := if p1 > 0 { p1 } else { 1.0 }
			return math.sin(freq * x)
		}
		.fn_cos {
			freq := if p1 > 0 { p1 } else { 1.0 }
			return math.cos(freq * x)
		}
		.fn_tan {
			val := math.tan(x)
			return math.max(-20.0, math.min(20.0, val))
		}
		.fn_sinc {
			if math.abs(x) < 1e-7 { return 1.0 }
			pi_x := math.pi * x
			return math.sin(pi_x) / pi_x
		}
		.fn_exp {
			return math.exp(math.max(-20.0, math.min(10.0, -0.5 * x * x)))
		}
		.fn_gaussian {
			mu := p1
			sigma := if p2 > 0 { p2 } else { 1.0 }
			z := (x - mu) / sigma
			return (1.0 / (sigma * math.sqrt(2.0 * math.pi))) * math.exp(-0.5 * z * z)
		}
		.fn_sigmoid {
			k := if p1 > 0 { p1 } else { 1.0 }
			return 1.0 / (1.0 + math.exp(-k * x))
		}
		.fn_damped_wave {
			gamma := if p1 > 0 { p1 } else { 0.2 }
			freq := if p2 > 0 { p2 } else { 3.0 }
			return math.exp(-gamma * math.abs(x)) * math.cos(freq * x)
		}
		.fn_poly {
			return (x + 2.0) * (x - 1.0) * (x - 3.0) / 10.0
		}
		.fn_log {
			if x <= 0 { return -10.0 }
			return math.log(x)
		}
		.fn_sqrt {
			if x < 0 { return 0.0 }
			return math.sqrt(x)
		}
		.fn_abs {
			return math.abs(x)
		}
		.fn_beats {
			f1 := if p1 > 0 { p1 } else { 5.0 }
			f2 := if p2 > 0 { p2 } else { 5.5 }
			return 0.5 * (math.sin(f1 * x) + math.sin(f2 * x))
		}
	}
}

// -------------------------------------------------------------
// 2D ASCII Grid Plot Generator
// -------------------------------------------------------------

fn render_ascii_plot(title string, x_vals []f64, y_vals []f64, width int, height int) string {
	n := math.min(x_vals.len, y_vals.len)
	if n < 2 { return 'Insufficient data points to render 2D plot.\n' }

	mut min_x := x_vals[0]
	mut max_x := x_vals[0]
	mut min_y := y_vals[0]
	mut max_y := y_vals[0]

	for i in 0 .. n {
		if x_vals[i] < min_x { min_x = x_vals[i] }
		if x_vals[i] > max_x { max_x = x_vals[i] }
		if y_vals[i] < min_y { min_y = y_vals[i] }
		if y_vals[i] > max_y { max_y = y_vals[i] }
	}

	if max_y == min_y {
		max_y += 1.0
		min_y -= 1.0
	}
	if max_x == min_x {
		max_x += 1.0
		min_x -= 1.0
	}

	w := if width > 20 { width } else { 64 }
	h := if height > 10 { height } else { 18 }

	mut grid := [][]string{len: h, init: []string{len: w, init: ' '}}

	// Draw zero axes if in range
	if min_y <= 0 && max_y >= 0 {
		zero_row := int(math.round(f64(h - 1) * (max_y - 0.0) / (max_y - min_y)))
		if zero_row >= 0 && zero_row < h {
			for col in 0 .. w {
				grid[zero_row][col] = '-'
			}
		}
	}
	if min_x <= 0 && max_x >= 0 {
		zero_col := int(math.round(f64(w - 1) * (0.0 - min_x) / (max_x - min_x)))
		if zero_col >= 0 && zero_col < w {
			for row in 0 .. h {
				if grid[row][zero_col] == '-' {
					grid[row][zero_col] = ''
				} else {
					grid[row][zero_col] = '|'
				}
			}
		}
	}

	// Plot curve data points
	for i in 0 .. n {
		col := int(math.round(f64(w - 1) * (x_vals[i] - min_x) / (max_x - min_x)))
		row := int(math.round(f64(h - 1) * (max_y - y_vals[i]) / (max_y - min_y)))
		if row >= 0 && row < h && col >= 0 && col < w {
			grid[row][col] = ''
		}
	}

	mut lines := []string{}
	lines << '========================================================================'
	lines << ' 2D FUNCTION & CURVE PLOT: ' + title
	lines << '   * X-Range: [${min_x:.3f}  ${max_x:.3f}]  |  Y-Range: [${min_y:.3f}  ${max_y:.3f}]'
	lines << '   * Resolution: ${n} evaluation points'
	lines << '------------------------------------------------------------------------'

	for row in 0 .. h {
		y_level := max_y - f64(row) * (max_y - min_y) / f64(h - 1)
		row_str := grid[row].join('')
		lines << '${y_level:8.2f} |${row_str}|'
	}
	lines << '         ' + '-'.repeat(w) + ''
	min_str := '${min_x:.2f}'
	max_str := '${max_x:.2f}'
	space_len := if w > 24 { w - 24 } else { 4 }
	lines << '          ' + pad_r(min_str, 12) + ' '.repeat(space_len) + pad_l(max_str, 12)
	lines << '========================================================================\n'
	return lines.join('\n')
}

// -------------------------------------------------------------
// Network Graph Data Structures (Nodes & Edges)
// -------------------------------------------------------------

struct GraphEdge {
	from   string
	to     string
	weight f64
}

struct GraphData {
mut:
	nodes []string
	edges []GraphEdge
}

fn parse_graph(text string) GraphData {
	mut g := GraphData{}
	mut node_set := map[string]bool{}

	lines := text.split_into_lines()
	for raw_line in lines {
		line := raw_line.trim_space()
		if line == '' || line.starts_with('#') || line.starts_with('//') { continue }

		if line.contains('->') {
			parts := line.split('->')
			from_node := parts[0].trim_space()
			mut to_part := parts[1].trim_space()
			mut weight := 1.0

			if to_part.contains('[') && to_part.contains(']') {
				w_start := to_part.index('[') or { -1 }
				w_end := to_part.index(']') or { -1 }
				if w_start >= 0 && w_end > w_start {
					prop := to_part[w_start + 1 .. w_end].trim_space()
					if prop.contains('=') {
						weight_str := prop.split('=')[1].trim_space()
						weight = weight_str.f64()
					} else {
						weight = prop.f64()
					}
					to_part = to_part[0 .. w_start].trim_space()
				}
			}

			to_node := to_part.trim_space()
			if from_node != '' && to_node != '' {
				g.edges << GraphEdge{
					from: from_node
					to: to_node
					weight: if weight > 0 { weight } else { 1.0 }
				}
				node_set[from_node] = true
				node_set[to_node] = true
			}
		} else if line.contains('--') {
			parts := line.split('--')
			from_node := parts[0].trim_space()
			to_node := parts[1].trim_space()
			if from_node != '' && to_node != '' {
				g.edges << GraphEdge{from: from_node, to: to_node, weight: 1.0}
				g.edges << GraphEdge{from: to_node, to: from_node, weight: 1.0}
				node_set[from_node] = true
				node_set[to_node] = true
			}
		}
	}

	for k, _ in node_set {
		g.nodes << k
	}
	g.nodes.sort()
	return g
}

fn analyze_graph(g GraphData) string {
	if g.nodes.len == 0 {
		return 'No graph nodes or edges detected. Input edge statements like: A -> B [weight=5]\n'
	}

	mut lines := []string{}
	lines << '========================================================================'
	lines << ' NETWORK GRAPH TOPOLOGY & DEGREE CENTRALITY ANALYSIS'
	lines << '========================================================================'
	lines << ' GRAPH PROPERTIES:'
	lines << '   * Total Nodes (|V|)  : ${g.nodes.len}'
	lines << '   * Total Edges (|E|)  : ${g.edges.len}'
	density := if g.nodes.len > 1 { f64(g.edges.len) / f64(g.nodes.len * (g.nodes.len - 1)) } else { 0.0 }
	lines << '   * Graph Density      : ${density:.4f}'
	lines << '------------------------------------------------------------------------'
	lines << ' NODE DEGREE CENTRALITY METRICS:'
	lines << 'Node       | In-Degree | Out-Degree | Total Degree | Neighbors'
	lines << '------------------------------------------------------------------------'

	for node in g.nodes {
		mut in_deg := 0
		mut out_deg := 0
		mut neighbors := []string{}

		for e in g.edges {
			if e.from == node {
				out_deg++
				if e.to !in neighbors { neighbors << e.to }
			}
			if e.to == node {
				in_deg++
				if e.from !in neighbors { neighbors << e.from }
			}
		}
		tot := in_deg + out_deg
		in_str := pad_l('${in_deg}', 9)
		out_str := pad_l('${out_deg}', 10)
		tot_str := pad_l('${tot}', 12)
		lines << '  ' + pad_r(node, 10) + ' | ' + in_str + ' | ' + out_str + ' | ' + tot_str + ' | ' + neighbors.join(', ')
	}

	lines << '------------------------------------------------------------------------'
	lines << ' ADJACENCY MATRIX (Cost / Weights):'
	mut hdr := '       |'
	for n in g.nodes { hdr += ' ' + pad_l(n, 5) + ' |' }
	lines << hdr
	lines << '-------+' + '-------+'.repeat(g.nodes.len)

	for r in g.nodes {
		mut row_str := ' ' + pad_l(r, 5) + ' |'
		for c in g.nodes {
			mut edge_cost := 0.0
			mut found := false
			for e in g.edges {
				if e.from == r && e.to == c {
					edge_cost = e.weight
					found = true
					break
				}
			}
			if found {
				cost_str := pad_l('${edge_cost:.1f}', 5)
				row_str += ' ' + cost_str + ' |'
			} else if r == c {
				row_str += '0.0 |'
			} else {
				row_str += '     - |'
			}
		}
		lines << row_str
	}

	lines << '------------------------------------------------------------------------'
	lines << ' MERMAID DIAGRAM EXPORT SPECIFICATION:'
	lines << '```mermaid'
	lines << 'graph LR'
	for e in g.edges {
		lines << '    ${e.from} -->|${e.weight:.1f}| ${e.to}'
	}
	lines << '```'
	lines << '========================================================================\n'
	return lines.join('\n')
}

// -------------------------------------------------------------
// Main Application State & Window
// -------------------------------------------------------------

struct AppState {
mut:
	active_tab      string
	func_type       FuncType
	x_min           f64
	x_max           f64
	p1              f64
	p2              f64
	samples_count   int
	last_x_vals     []f64
	last_y_vals     []f64
	history_ledger  []string
}

fn main() {
	println('Starting SimpleGUI - Graph Studio Pro (2D Function Plotter & Network Graph Engine)...')

	mut win := simplegui.new_simple_window('Graph Studio Pro -- 2D Function Plotter & Network Topology Studio', 1180, 920)
	win.set_fullscreen(true)
	win.restore_saved_theme()
	win.set_spacing(6)
	win.set_padding(14)

	mut state := &AppState{
		active_tab: ' Function Plotter'
		func_type: .fn_sin
		x_min: -10.0
		x_max: 10.0
		p1: 1.0
		p2: 1.0
		samples_count: 100
		last_x_vals: []f64{}
		last_y_vals: []f64{}
		history_ledger: []string{}
	}

	// -------------------------------------------------------------
	// Header & Theme
	// -------------------------------------------------------------
	win.begin_row('row_header')
	win.add_heading('Graph Studio Pro')

	win.add_label('lbl_info', '2D Mathematical Curves, Series Visualizer & Network Graphs')

	win.add_label('lbl_theme_hdr', 'Theme:')
	saved_theme := simplegui.get_saved_theme()
	win.add_dropdown('dd_theme_selector', simplegui.list_themes(), saved_theme)
	win.set_control_width('dd_theme_selector', 160)
	win.end_row()

	// -------------------------------------------------------------
	// Navigation Workspace Tabs
	// -------------------------------------------------------------
	win.add_tabs('main_tabs', [
		' Function Plotter',
		' Data Series & Moving Average',
		' Network Graph Topology',
		' Category & Proportion Charts',
		' Curve Preset Gallery',
		' Plot Ledger'
	])

	// -------------------------------------------------------------
	// Top Key Metrics Overview Cards
	// -------------------------------------------------------------
	win.begin_group_box('grp_summary_cards', 'Real-Time Curve Metrics & Bounds')
	win.begin_row('row_metric_cards')
	win.add_metric_card('card_pts', 'Sample Points', '100', 'Resolution', 'Total Samples')
	win.add_metric_card('card_min_y', 'Global Min Y', '-1.000', 'Lower Bound', 'Minimum Value')
	win.add_metric_card('card_max_y', 'Global Max Y', '1.000', 'Upper Bound', 'Maximum Value')
	win.add_metric_card('card_integral', 'Definite Integral', '0.000', 'int f(x)dx', 'Area Under Curve')
	win.add_metric_card('card_rms', 'RMS Power', '0.707', 'Root Mean Sq', 'Signal Energy')
	win.end_row()
	win.end_group_box()

	// -------------------------------------------------------------
	// Tab 1: Mathematical Function Plotter
	// -------------------------------------------------------------
	win.begin_group_box('pane_func', 'Continuous Mathematical Function Plotter & Live Cocoa Chart')

	win.begin_row('row_func_select')
	win.add_label('lbl_fn_choice', 'Function Model f(x):')
	win.add_dropdown('dd_func_model', [
		'Sine Wave: f(x) = sin(k  x)',
		'Cosine Wave: f(x) = cos(k  x)',
		'Sinc Function: f(x) = sin(pix)/(pix)',
		'Gaussian Bell Curve: f(x) = (1/sqrt2pi) exp(-(x-)/2)',
		'Damped Harmonic Oscillator: f(x) = exp(-|x|) cos(x)',
		'Sigmoid Activation: f(x) = 1 / (1 + exp(-kx))',
		'Superimposed Beat Frequencies: f(x) = 0.5(sin(f1 x) + sin(f2 x))',
		'Cubic Polynomial: f(x) = (x+2)(x-1)(x-3)/10',
		'Gaussian Exponential: f(x) = exp(-x/2)',
		'Square Root: f(x) = sqrt(x)',
		'Natural Logarithm: f(x) = ln(x)',
		'Absolute Value: f(x) = |x|',
		'Tangent: f(x) = tan(x)'
	], 'Sine Wave: f(x) = sin(k  x)')
	win.set_control_width('dd_func_model', 330)

	win.add_label('lbl_p1', 'Param 1 (k///f1):')
	win.add_input('txt_param1', '1.0')
	win.set_control_width('txt_param1', 60)

	win.add_label('lbl_p2', 'Param 2 (//f2):')
	win.add_input('txt_param2', '1.0')
	win.set_control_width('txt_param2', 60)
	win.end_row()

	win.begin_row('row_func_range')
	win.add_label('lbl_xmin', 'X Min:')
	win.add_input('txt_xmin', '-10.0')
	win.set_control_width('txt_xmin', 70)

	win.add_label('lbl_xmax', 'X Max:')
	win.add_input('txt_xmax', '10.0')
	win.set_control_width('txt_xmax', 70)

	win.add_label('lbl_samples', 'Resolution (N):')
	win.add_input('txt_samples', '100')
	win.set_control_width('txt_samples', 70)

	win.add_button('btn_plot_func', 'PLOT FUNCTION')
	win.add_button('btn_copy_ascii_plot', 'Copy 2D Plot')
	win.end_row()

	// Native Cocoa Area Chart
	win.add_chart('chart_math', 'area', 140)

	win.add_textarea('txt_func_report', '2D Ascii Grid Curve Plot, Critical Points, Zeros/Roots and Calculus metrics will appear here.\n')
	win.set_control_height('txt_func_report', 240)
	win.set_control_font_name('txt_func_report', 'Menlo')
	win.set_control_font_size('txt_func_report', 11)
	win.end_group_box()

	// -------------------------------------------------------------
	// Tab 2: Data Series & Moving Average
	// -------------------------------------------------------------
	win.begin_group_box('pane_series', 'Numerical Data Series Visualizer & Moving Average Smoothing')

	win.add_label('lbl_series_input', 'Input Raw Data Series (comma or newline separated Y values):')
	win.add_textarea('txt_series_data', '12.4, 15.8, 14.2, 18.9, 22.1, 19.5, 25.4, 28.0, 26.2, 31.5, 35.8, 33.2, 38.9, 42.1, 39.8, 45.2, 48.9, 46.5, 52.1, 55.4')
	win.set_control_height('txt_series_data', 70)
	win.set_control_font_name('txt_series_data', 'Menlo')

	win.begin_row('row_series_actions')
	win.add_button('btn_plot_raw_series', 'Plot Raw Series')
	win.add_button('btn_smooth_sma3', '3-Point Moving Avg')
	win.add_button('btn_smooth_sma5', '5-Point Moving Avg')
	win.add_button('btn_series_diff', 'First Difference Y')
	win.add_button('btn_series_cum', 'Cumulative Sum Y')
	win.end_row()

	win.add_chart('chart_series', 'line', 130)

	win.add_textarea('txt_series_report', 'Data series statistics and smoothed curve tables will appear here.\n')
	win.set_control_height('txt_series_report', 220)
	win.set_control_font_name('txt_series_report', 'Menlo')
	win.set_control_font_size('txt_series_report', 11)
	win.end_group_box()

	// -------------------------------------------------------------
	// Tab 3: Network Graph Topology
	// -------------------------------------------------------------
	win.begin_group_box('pane_network', 'Network Graph Topology, Directed Edges & Adjacency Engine')

	win.add_label('lbl_net_prompt', 'Define Graph Edges (format: A -> B [weight=5.0] or A -- B):')
	win.add_textarea('txt_graph_spec', 'Router_Core -> Switch_A [weight=10.0]\nRouter_Core -> Switch_B [weight=10.0]\nSwitch_A -> Server_Alpha [weight=1.0]\nSwitch_A -> Server_Beta [weight=1.0]\nSwitch_B -> Server_Gamma [weight=1.0]\nSwitch_B -> Server_Delta [weight=1.0]\nServer_Alpha -> Storage_SAN [weight=2.5]\nServer_Beta -> Storage_SAN [weight=2.5]\nServer_Gamma -> Storage_SAN [weight=2.5]\nServer_Delta -> Storage_SAN [weight=2.5]')
	win.set_control_height('txt_graph_spec', 100)
	win.set_control_font_name('txt_graph_spec', 'Menlo')

	win.begin_row('row_net_actions')
	win.add_button('btn_analyze_graph', 'EVALUATE GRAPH TOPOLOGY')
	win.add_button('btn_load_sample_tree', 'Binary Tree')
	win.add_button('btn_load_sample_mesh', 'Mesh Network')
	win.add_button('btn_copy_mermaid', 'Copy Mermaid Diagram')
	win.end_row()

	win.add_textarea('txt_graph_report', 'Network density, degree centralities, adjacency matrix, and Mermaid diagram code will appear here.\n')
	win.set_control_height('txt_graph_report', 300)
	win.set_control_font_name('txt_graph_report', 'Menlo')
	win.set_control_font_size('txt_graph_report', 11)
	win.end_group_box()

	// -------------------------------------------------------------
	// Tab 4: Category & Proportion Charts
	// -------------------------------------------------------------
	win.begin_group_box('pane_proportions', 'Category Frequency, Allocation & Donut Charts')

	win.add_label('lbl_cat_prompt', 'Category Allocations (Label: Value):')
	win.add_textarea('txt_categories', 'Frontend UI / SimpleGUI: 42.5\nBackend Engine / POSIX: 28.0\nMathematical Calculus: 15.5\nNetwork Intelligence: 14.0')
	win.set_control_height('txt_categories', 70)
	win.set_control_font_name('txt_categories', 'Menlo')

	win.begin_row('row_prop_actions')
	win.add_button('btn_render_bars', 'Generate Horizontal Bar Charts')
	win.end_row()

	win.add_textarea('txt_proportions_report', 'Unicode bar charts and percentage distributions will appear here.\n')
	win.set_control_height('txt_proportions_report', 360)
	win.set_control_font_name('txt_proportions_report', 'Menlo')
	win.set_control_font_size('txt_proportions_report', 12)
	win.end_group_box()

	// -------------------------------------------------------------
	// Tab 5: Curve Preset Gallery
	// -------------------------------------------------------------
	win.begin_group_box('pane_presets', 'Preloaded Scientific Curve Presets')

	win.begin_row('row_preset_btns_1')
	win.add_button('btn_pre_damped', 'Damped Wave (e^-0.2x cos 3x)')
	win.add_button('btn_pre_sinc', 'Sinc Waveform (sin pix / pix)')
	win.add_button('btn_pre_gauss', 'Gaussian Bell (=0, =1.5)')
	win.end_row()

	win.begin_row('row_preset_btns_2')
	win.add_button('btn_pre_beats', 'Acoustic Beats (sin 5x + sin 5.5x)')
	win.add_button('btn_pre_sigmoid', 'Sigmoid Activation (1/(1+e^-x))')
	win.add_button('btn_pre_poly', '3-Root Polynomial')
	win.end_row()

	win.add_textarea('txt_preset_info', 'Click any preset above to instantly load parameters, plot the mathematical curve, and update metrics.\n')
	win.set_control_height('txt_preset_info', 360)
	win.set_control_font_name('txt_preset_info', 'Menlo')
	win.set_control_font_size('txt_preset_info', 12)
	win.end_group_box()

	// -------------------------------------------------------------
	// Tab 6: Plot Ledger
	// -------------------------------------------------------------
	win.begin_group_box('pane_history', 'Session Graphing & Plotting Ledger')

	win.begin_row('row_hist_actions')
	win.add_button('btn_copy_ledger', 'Copy Ledger')
	win.add_button('btn_clear_ledger', 'Clear Ledger')
	win.add_button('btn_export_ledger', 'Export Ledger...')
	win.end_row()

	win.add_textarea('txt_ledger', 'All function evaluations and graph analyses are recorded here.\n')
	win.set_control_height('txt_ledger', 380)
	win.set_control_font_name('txt_ledger', 'Menlo')
	win.set_control_font_size('txt_ledger', 12)
	win.end_group_box()

	// Initially hide inactive tab panes
	win.set_control_visible('pane_series', false)
	win.set_control_visible('pane_network', false)
	win.set_control_visible('pane_proportions', false)
	win.set_control_visible('pane_presets', false)
	win.set_control_visible('pane_history', false)

	// -------------------------------------------------------------
	// Status Bar Footer
	// -------------------------------------------------------------
	win.begin_row('row_footer')
	win.add_label('lbl_status_bar', 'Ready. 2D Function Plotter & Network Graph Engine active.')
	win.end_row()

	// -------------------------------------------------------------
	// Ledger Helper
	// -------------------------------------------------------------
	append_ledger := fn [mut state] (mut w simplegui.SimpleWindow, title string, summary string) {
		ts := time.now().format_ss()
		entry := '[${ts}] ${title}\n${summary}\n------------------------------------------------------------------------'
		state.history_ledger << entry
		mut content := []string{}
		content << '========================================================================'
		content << ' GRAPH STUDIO PRO -- PLOT LEDGER'
		content << '========================================================================'
		content << state.history_ledger.join('\n')
		content << '========================================================================\n'
		w.set('txt_ledger', content.join('\n'))
	}

	// -------------------------------------------------------------
	// Master Plot Function
	// -------------------------------------------------------------
	run_function_plot := fn [mut state, append_ledger] (mut w simplegui.SimpleWindow) {
		choice := w.get('dd_func_model')
		if choice.contains('Sine') { state.func_type = .fn_sin }
		else if choice.contains('Cosine') { state.func_type = .fn_cos }
		else if choice.contains('Sinc') { state.func_type = .fn_sinc }
		else if choice.contains('Gaussian Bell') { state.func_type = .fn_gaussian }
		else if choice.contains('Damped') { state.func_type = .fn_damped_wave }
		else if choice.contains('Sigmoid') { state.func_type = .fn_sigmoid }
		else if choice.contains('Beat') { state.func_type = .fn_beats }
		else if choice.contains('Polynomial') { state.func_type = .fn_poly }
		else if choice.contains('Exponential') { state.func_type = .fn_exp }
		else if choice.contains('Square Root') { state.func_type = .fn_sqrt }
		else if choice.contains('Logarithm') { state.func_type = .fn_log }
		else if choice.contains('Absolute') { state.func_type = .fn_abs }
		else { state.func_type = .fn_tan }

		state.x_min = w.get('txt_xmin').f64()
		state.x_max = w.get('txt_xmax').f64()
		state.p1 = w.get('txt_param1').f64()
		state.p2 = w.get('txt_param2').f64()
		n_samples := int(w.get('txt_samples').f64())
		state.samples_count = if n_samples >= 10 { n_samples } else { 100 }

		if state.x_max <= state.x_min {
			state.x_max = state.x_min + 1.0
		}

		dx := (state.x_max - state.x_min) / f64(state.samples_count - 1)
		mut x_vals := []f64{}
		mut y_vals := []f64{}
		mut min_y := 1e9
		mut max_y := -1e9
		mut integral := 0.0
		mut sum_sq := 0.0

		for i in 0 .. state.samples_count {
			x := state.x_min + f64(i) * dx
			y := eval_func(state.func_type, x, state.p1, state.p2)
			x_vals << x
			y_vals << y

			if y < min_y { min_y = y }
			if y > max_y { max_y = y }
			integral += y * dx
			sum_sq += y * y
		}

		state.last_x_vals = x_vals
		state.last_y_vals = y_vals

		rms := math.sqrt(sum_sq / f64(state.samples_count))

		// Update Top Metric Cards
		w.set_metric_card_value('card_pts', '${state.samples_count}', 'Resolution')
		w.set_metric_card_value('card_min_y', '${min_y:.3f}', 'Lower Bound')
		w.set_metric_card_value('card_max_y', '${max_y:.3f}', 'Upper Bound')
		w.set_metric_card_value('card_integral', '${integral:.3f}', 'int f(x)dx')
		w.set_metric_card_value('card_rms', '${rms:.3f}', 'Signal Energy')

		// Update Native Cocoa Chart
		w.set_chart_data('chart_math', y_vals)

		// Render 2D ASCII Grid Plot
		fn_label := choice.split(':')[0]
		ascii_plot := render_ascii_plot(fn_label, x_vals, y_vals, 64, 14)

		mut details := []string{}
		details << ascii_plot
		details << 'CRITICAL CHARACTERISTICS & METRICS:'
		details << '   * Global Minima Y : ${min_y:10.4f}'
		details << '   * Global Maxima Y : ${max_y:10.4f}'
		details << '   * Amplitude Span  : ${(max_y - min_y):10.4f}'
		details << '   * Definite Integral: ${integral:10.4f} (Riemann Sum across [${state.x_min:.2f}, ${state.x_max:.2f}])'
		details << '   * RMS Power Energy: ${rms:10.4f}'
		details << '========================================================================\n'

		w.set('txt_func_report', details.join('\n'))
		w.set('lbl_status_bar', ' Evaluated ${state.samples_count} points for ' + fn_label + '. Y  [${min_y:.3f}, ${max_y:.3f}]')
		append_ledger(mut w, 'Function Plot: ' + fn_label, 'X  [${state.x_min:.2f}, ${state.x_max:.2f}], Y  [${min_y:.3f}, ${max_y:.3f}], Integral = ${integral:.4f}')
	}

	// -------------------------------------------------------------
	// Event Callbacks
	// -------------------------------------------------------------

	// Workspace Tabs Navigation
	win.on_change('main_tabs', fn [mut state] (mut w simplegui.SimpleWindow, tab string) {
		state.active_tab = tab

		w.set_control_visible('pane_func', tab == ' Function Plotter')
		w.set_control_visible('pane_series', tab == ' Data Series & Moving Average')
		w.set_control_visible('pane_network', tab == ' Network Graph Topology')
		w.set_control_visible('pane_proportions', tab == ' Category & Proportion Charts')
		w.set_control_visible('pane_presets', tab == ' Curve Preset Gallery')
		w.set_control_visible('pane_history', tab == ' Plot Ledger')

		w.toast('Switched to ' + tab)
	})

	// Theme Selector
	win.on_change('dd_theme_selector', fn (mut w simplegui.SimpleWindow, selected string) {
		w.set_theme(selected)
		w.toast('Theme changed to ${selected}')
	})

	// Tab 1: Plot Button
	win.on_click('btn_plot_func', fn [run_function_plot] (mut w simplegui.SimpleWindow) {
		run_function_plot(mut w)
		w.toast('Rendered 2D curve plot!')
	})

	win.on_click('btn_copy_ascii_plot', fn (mut w simplegui.SimpleWindow) {
		w.copy_to_clipboard(w.get('txt_func_report'))
		w.toast('Copied 2D plot to clipboard!')
	})

	// -------------------------------------------------------------
	// Tab 2: Series Actions
	// -------------------------------------------------------------
	win.on_click('btn_plot_raw_series', fn [append_ledger] (mut w simplegui.SimpleWindow) {
		raw_txt := w.get('txt_series_data').replace(',', ' ').replace('\n', ' ')
		words := raw_txt.split(' ')
		mut nums := []f64{}
		for word in words {
			tw := word.trim_space()
			if tw != '' {
				v := tw.f64()
				if !math.is_nan(v) { nums << v }
			}
		}
		if nums.len < 2 {
			w.alert('Input Missing', 'Please enter at least 2 data points.')
			return
		}
		w.set_chart_data('chart_series', nums)

		mut x_idx := []f64{}
		for i in 0 .. nums.len { x_idx << f64(i + 1) }
		plot := render_ascii_plot('Raw Data Series (N=${nums.len})', x_idx, nums, 60, 12)

		w.set('txt_series_report', plot)
		w.set('lbl_status_bar', ' Rendered raw data series (N = ${nums.len})')
		append_ledger(mut w, 'Data Series Plot', 'Plotted raw sequence of ${nums.len} points')
		w.toast('Plotted series!')
	})

	win.on_click('btn_smooth_sma3', fn (mut w simplegui.SimpleWindow) {
		raw_txt := w.get('txt_series_data').replace(',', ' ').replace('\n', ' ')
		words := raw_txt.split(' ')
		mut nums := []f64{}
		for word in words {
			tw := word.trim_space()
			if tw != '' {
				v := tw.f64()
				if !math.is_nan(v) { nums << v }
			}
		}
		if nums.len < 3 { return }

		mut sma := []f64{}
		for i in 0 .. nums.len {
			if i == 0 {
				sma << (nums[0] + nums[1]) / 2.0
			} else if i == nums.len - 1 {
				sma << (nums[i - 1] + nums[i]) / 2.0
			} else {
				sma << (nums[i - 1] + nums[i] + nums[i + 1]) / 3.0
			}
		}
		w.set_chart_data('chart_series', sma)

		mut x_idx := []f64{}
		for i in 0 .. sma.len { x_idx << f64(i + 1) }
		plot := render_ascii_plot('3-Point Moving Average Smoothed (N=${sma.len})', x_idx, sma, 60, 12)
		w.set('txt_series_report', plot)
		w.toast('Computed 3-point SMA smoothing!')
	})

	win.on_click('btn_smooth_sma5', fn (mut w simplegui.SimpleWindow) {
		raw_txt := w.get('txt_series_data').replace(',', ' ').replace('\n', ' ')
		words := raw_txt.split(' ')
		mut nums := []f64{}
		for word in words {
			tw := word.trim_space()
			if tw != '' {
				v := tw.f64()
				if !math.is_nan(v) { nums << v }
			}
		}
		if nums.len < 5 { return }

		mut sma := []f64{}
		for i in 0 .. nums.len {
			mut sum := 0.0
			mut count := 0
			for k in -2 .. 3 {
				idx := i + k
				if idx >= 0 && idx < nums.len {
					sum += nums[idx]
					count++
				}
			}
			sma << (sum / f64(count))
		}
		w.set_chart_data('chart_series', sma)

		mut x_idx := []f64{}
		for i in 0 .. sma.len { x_idx << f64(i + 1) }
		plot := render_ascii_plot('5-Point Moving Average Smoothed (N=${sma.len})', x_idx, sma, 60, 12)
		w.set('txt_series_report', plot)
		w.toast('Computed 5-point SMA smoothing!')
	})

	win.on_click('btn_series_diff', fn (mut w simplegui.SimpleWindow) {
		raw_txt := w.get('txt_series_data').replace(',', ' ').replace('\n', ' ')
		words := raw_txt.split(' ')
		mut nums := []f64{}
		for word in words {
			tw := word.trim_space()
			if tw != '' {
				v := tw.f64()
				if !math.is_nan(v) { nums << v }
			}
		}
		if nums.len < 2 { return }

		mut diffs := []f64{}
		for i in 1 .. nums.len {
			diffs << (nums[i] - nums[i - 1])
		}
		w.set_chart_data('chart_series', diffs)

		mut x_idx := []f64{}
		for i in 0 .. diffs.len { x_idx << f64(i + 1) }
		plot := render_ascii_plot('First Difference Series Y (N=${diffs.len})', x_idx, diffs, 60, 12)
		w.set('txt_series_report', plot)
		w.toast('Computed first differences!')
	})

	win.on_click('btn_series_cum', fn (mut w simplegui.SimpleWindow) {
		raw_txt := w.get('txt_series_data').replace(',', ' ').replace('\n', ' ')
		words := raw_txt.split(' ')
		mut nums := []f64{}
		for word in words {
			tw := word.trim_space()
			if tw != '' {
				v := tw.f64()
				if !math.is_nan(v) { nums << v }
			}
		}
		if nums.len < 2 { return }

		mut cum := []f64{}
		mut acc := 0.0
		for x in nums {
			acc += x
			cum << acc
		}
		w.set_chart_data('chart_series', cum)

		mut x_idx := []f64{}
		for i in 0 .. cum.len { x_idx << f64(i + 1) }
		plot := render_ascii_plot('Cumulative Sum Series Y (N=${cum.len})', x_idx, cum, 60, 12)
		w.set('txt_series_report', plot)
		w.toast('Computed cumulative sum!')
	})

	// -------------------------------------------------------------
	// Tab 3: Network Graph Actions
	// -------------------------------------------------------------
	win.on_click('btn_analyze_graph', fn [append_ledger] (mut w simplegui.SimpleWindow) {
		spec := w.get('txt_graph_spec')
		g := parse_graph(spec)
		rep := analyze_graph(g)
		w.set('txt_graph_report', rep)
		w.set('lbl_status_bar', ' Evaluated network topology: |V| = ${g.nodes.len} nodes, |E| = ${g.edges.len} edges')
		append_ledger(mut w, 'Network Graph Analysis', 'Analyzed graph with ${g.nodes.len} nodes and ${g.edges.len} edges')
		w.toast('Evaluated network graph!')
	})

	win.on_click('btn_load_sample_tree', fn (mut w simplegui.SimpleWindow) {
		tree_spec := 'Root -> Node_Left\nRoot -> Node_Right\nNode_Left -> Leaf_L1\nNode_Left -> Leaf_L2\nNode_Right -> Leaf_R1\nNode_Right -> Leaf_R2'
		w.set('txt_graph_spec', tree_spec)
		g := parse_graph(tree_spec)
		w.set('txt_graph_report', analyze_graph(g))
		w.toast('Loaded Binary Tree Topology!')
	})

	win.on_click('btn_load_sample_mesh', fn (mut w simplegui.SimpleWindow) {
		mesh_spec := 'Node_1 -> Node_2 [weight=2.0]\nNode_2 -> Node_3 [weight=3.5]\nNode_3 -> Node_4 [weight=1.2]\nNode_4 -> Node_1 [weight=4.0]\nNode_1 -> Node_3 [weight=5.1]\nNode_2 -> Node_4 [weight=2.8]'
		w.set('txt_graph_spec', mesh_spec)
		g := parse_graph(mesh_spec)
		w.set('txt_graph_report', analyze_graph(g))
		w.toast('Loaded Mesh Topology!')
	})

	win.on_click('btn_copy_mermaid', fn (mut w simplegui.SimpleWindow) {
		spec := w.get('txt_graph_spec')
		g := parse_graph(spec)
		mut lines := []string{}
		lines << '```mermaid'
		lines << 'graph LR'
		for e in g.edges {
			lines << '    ${e.from} -->|${e.weight:.1f}| ${e.to}'
		}
		lines << '```'
		w.copy_to_clipboard(lines.join('\n'))
		w.toast('Copied Mermaid diagram to clipboard!')
	})

	// -------------------------------------------------------------
	// Tab 4: Category & Proportion Actions
	// -------------------------------------------------------------
	win.on_click('btn_render_bars', fn (mut w simplegui.SimpleWindow) {
		raw := w.get('txt_categories')
		lines := raw.split_into_lines()
		mut labels := []string{}
		mut vals := []f64{}
		mut total := 0.0

		for raw_l in lines {
			l := raw_l.trim_space()
			if l == '' { continue }
			if l.contains(':') {
				parts := l.split(':')
				label := parts[0].trim_space()
				val := parts[1].trim_space().f64()
				labels << label
				vals << val
				total += val
			}
		}

		if labels.len == 0 || total <= 0 {
			w.alert('Input Error', 'Please enter labels and values formatted as "Label: Value".')
			return
		}

		mut max_v := 0.0
		for v in vals {
			if v > max_v { max_v = v }
		}

		mut out := []string{}
		out << '========================================================================'
		out << ' CATEGORICAL ALLOCATION & PROPORTION BAR CHARTS'
		out << '========================================================================'
		out << ' Category / Label            | Value |  Share  | Visual Distribution Bar'
		out << '------------------------------------------------------------------------'

		for i in 0 .. labels.len {
			lbl := labels[i]
			v := vals[i]
			pct := (v / total) * 100.0
			bar_len := int((v / max_v) * 28.0)
			mut bar := ''
			for _ in 0 .. bar_len { bar += '#' }
			if bar == '' && v > 0 { bar = '=' }
			v_str := pad_l('${v:.1f}', 5)
			pct_str := pad_l('${pct:.1f}%', 6)
			out << ' ' + pad_r(lbl, 27) + ' | ' + v_str + ' | ' + pct_str + ' | ' + bar
		}
		out << '------------------------------------------------------------------------'
		out << ' TOTAL ALLOCATION SUM        : ${total:.2f}'
		out << '========================================================================\n'

		w.set('txt_proportions_report', out.join('\n'))
		w.toast('Rendered categorical bar distribution!')
	})

	// -------------------------------------------------------------
	// Tab 5: Presets
	// -------------------------------------------------------------
	win.on_click('btn_pre_damped', fn [run_function_plot] (mut w simplegui.SimpleWindow) {
		w.set('dd_func_model', 'Damped Harmonic Oscillator: f(x) = exp(-|x|) cos(x)')
		w.set('txt_xmin', '-10.0')
		w.set('txt_xmax', '10.0')
		w.set('txt_param1', '0.2')
		w.set('txt_param2', '3.0')
		w.set('txt_samples', '120')
		w.set('txt_preset_info', ' Loaded Damped Harmonic Oscillator: e^(-0.2|x|) cos(3x)\nModels physical wave decay, spring damper friction, and acoustic damping.')
		run_function_plot(mut w)
		w.toast('Loaded Damped Oscillator Preset!')
	})

	win.on_click('btn_pre_sinc', fn [run_function_plot] (mut w simplegui.SimpleWindow) {
		w.set('dd_func_model', 'Sinc Function: f(x) = sin(pix)/(pix)')
		w.set('txt_xmin', '-6.0')
		w.set('txt_xmax', '6.0')
		w.set('txt_param1', '1.0')
		w.set('txt_param2', '1.0')
		w.set('txt_samples', '120')
		w.set('txt_preset_info', ' Loaded Normalized Sinc Function: sin(pix)/(pix)\nFundamental brick-wall bandlimited filter kernel in signal processing and Fourier transforms.')
		run_function_plot(mut w)
		w.toast('Loaded Sinc Waveform Preset!')
	})

	win.on_click('btn_pre_gauss', fn [run_function_plot] (mut w simplegui.SimpleWindow) {
		w.set('dd_func_model', 'Gaussian Bell Curve: f(x) = (1/sqrt2pi) exp(-(x-)/2)')
		w.set('txt_xmin', '-5.0')
		w.set('txt_xmax', '5.0')
		w.set('txt_param1', '0.0')
		w.set('txt_param2', '1.5')
		w.set('txt_samples', '100')
		w.set('txt_preset_info', ' Loaded Gaussian Bell Curve:  = 0.0,  = 1.5\nStandard normal probability density distribution.')
		run_function_plot(mut w)
		w.toast('Loaded Gaussian Preset!')
	})

	win.on_click('btn_pre_beats', fn [run_function_plot] (mut w simplegui.SimpleWindow) {
		w.set('dd_func_model', 'Superimposed Beat Frequencies: f(x) = 0.5(sin(f1 x) + sin(f2 x))')
		w.set('txt_xmin', '-20.0')
		w.set('txt_xmax', '20.0')
		w.set('txt_param1', '5.0')
		w.set('txt_param2', '5.5')
		w.set('txt_samples', '200')
		w.set('txt_preset_info', ' Loaded Acoustic Beats Waveform: 0.5(sin(5x) + sin(5.5x))\nInterference pattern producing periodic amplitude modulation envelope.')
		run_function_plot(mut w)
		w.toast('Loaded Acoustic Beats Preset!')
	})

	win.on_click('btn_pre_sigmoid', fn [run_function_plot] (mut w simplegui.SimpleWindow) {
		w.set('dd_func_model', 'Sigmoid Activation: f(x) = 1 / (1 + exp(-kx))')
		w.set('txt_xmin', '-8.0')
		w.set('txt_xmax', '8.0')
		w.set('txt_param1', '1.0')
		w.set('txt_param2', '1.0')
		w.set('txt_samples', '100')
		w.set('txt_preset_info', ' Loaded Logistic Sigmoid Activation Function: 1 / (1 + e^-x)\nCore non-linear activation curve in neural network classifiers and logistic regression.')
		run_function_plot(mut w)
		w.toast('Loaded Sigmoid Preset!')
	})

	win.on_click('btn_pre_poly', fn [run_function_plot] (mut w simplegui.SimpleWindow) {
		w.set('dd_func_model', 'Cubic Polynomial: f(x) = (x+2)(x-1)(x-3)/10')
		w.set('txt_xmin', '-4.0')
		w.set('txt_xmax', '5.0')
		w.set('txt_param1', '1.0')
		w.set('txt_param2', '1.0')
		w.set('txt_samples', '100')
		w.set('txt_preset_info', ' Loaded Cubic Polynomial: (x+2)(x-1)(x-3)/10\nExhibits 3 distinct real roots at x = -2, x = 1, x = 3.')
		run_function_plot(mut w)
		w.toast('Loaded Cubic Polynomial Preset!')
	})

	// -------------------------------------------------------------
	// Tab 6: Ledger Actions
	// -------------------------------------------------------------
	win.on_click('btn_copy_ledger', fn (mut w simplegui.SimpleWindow) {
		w.copy_to_clipboard(w.get('txt_ledger'))
		w.toast('Copied plot ledger to clipboard!')
	})

	win.on_click('btn_clear_ledger', fn [mut state] (mut w simplegui.SimpleWindow) {
		state.history_ledger.clear()
		w.set('txt_ledger', 'Ledger cleared.\n')
		w.toast('Cleared ledger.')
	})

	win.on_click('btn_export_ledger', fn (mut w simplegui.SimpleWindow) {
		save_path := w.save_file_picker()
		if save_path != '' {
			mut real_path := save_path
			if !real_path.ends_with('.txt') {
				real_path += '.txt'
			}
			ledger := w.get('txt_ledger')
			os.write_file(real_path, ledger) or {
				w.alert('Export Error', 'Failed to save ledger file.')
				return
			}
			w.toast('Saved plot ledger to ' + os.file_name(real_path))
		}
	})

	// Initial Plot
	run_function_plot(mut win)

	println('Graph Studio Pro configured. Starting event loop...')
	win.run()
}

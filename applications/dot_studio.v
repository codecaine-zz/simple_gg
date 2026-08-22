module main

import os
import time
import simplegui

// Helper to find dot path
fn get_dot_bin() string {
	if path := os.find_abs_path_of_executable('dot') {
		return path
	}
	common_paths := [
		'/opt/homebrew/bin/dot',
		'/usr/local/bin/dot',
		'/usr/bin/dot',
	]
	for p in common_paths {
		if os.exists(p) {
			return p
		}
	}
	return 'dot'
}

const sample_dot_architecture = 'digraph SimpleGUIArchitecture {
    rankdir=LR;
    node [shape=box, style="filled,rounded", fillcolor="#22272e", fontcolor="#adbac7", color="#539bf5", fontname="Helvetica"];
    edge [color="#539bf5", fontcolor="#adbac7", fontname="Helvetica"];

    subgraph cluster_frontend {
        label = "Native macOS Cocoa Frontend";
        fontcolor="#539bf5";
        color="#30363d";
        
        App [label="SimpleGUI App\n(V Language)"];
        Controls [label="UI Controls & State\n(Buttons, Textarea, Dropdowns)"];
        Theming [label="Theme Engine\n(18 Curated Themes)"];
    }

    subgraph cluster_backend {
        label = "Non-Blocking Async Engine";
        fontcolor="#3fb950";
        color="#30363d";
        
        Workers [label="Async Goroutines\n(go fn [mut w])"];
        SafeExec [label="Secure Exec Safe\n(Argument Isolation)"];
        Telemetry [label="Console & Activity Log\n(Status, Duration, Memory)"];
    }

    subgraph cluster_cli {
        label = "High-Speed Engines & Tools";
        fontcolor="#f0883e";
        color="#30363d";
        
        Ripgrep [label="ripgrep (rg)"];
        FD [label="fd-find (fd)"];
        FFmpeg [label="ffmpeg / magick"];
        SQLite [label="sqlite3 / jq"];
    }

    App -> Controls;
    App -> Theming;
    Controls -> Workers;
    Workers -> SafeExec;
    SafeExec -> Telemetry;
    SafeExec -> Ripgrep;
    SafeExec -> FD;
    SafeExec -> FFmpeg;
    SafeExec -> SQLite;
}'

fn main() {
	println('Starting SimpleGUI - Graphviz & Diagram Studio Pro...')

	mut win := simplegui.new_simple_window('SimpleGUI - Graphviz & Diagram Studio Pro', 1080, 950)
	win.set_fullscreen(true)
	win.set_spacing(8)
	win.set_padding(16)

	saved_theme := simplegui.get_saved_theme()
	win.set_theme(saved_theme)

	// Top Banner / Diagnostics
	win.begin_row('row_dot_top')
	win.add_heading('Graphviz & Diagram Studio Pro')
	win.add_label('lbl_theme', 'Theme:')
	win.add_dropdown('dd_app_theme', simplegui.list_themes(), saved_theme)
	win.set_control_width('dd_app_theme', 150)
	win.end_row()

	win.on_change('dd_app_theme', fn (mut w simplegui.SimpleWindow, selected string) {
		w.set_theme(selected)
		w.toast('Theme changed to ${selected}')
	})

	dot_path := get_dot_bin()
	win.add_label('lbl_engine_info', 'Engine: ${dot_path} (Graphviz Suite)  |  Platform: macOS Cocoa  |  Mode: Async Compiler')

	// Diagram Configuration & Presets Bar
	win.begin_group_box('grp_diagram_config', 'Diagram Templates & Layout Engine Specification')
	
	win.begin_row('row_presets_bar')
	win.add_label('lbl_presets', 'Diagram Template:')
	win.add_dropdown('dd_dot_presets', [
		'1. SimpleGUI Microservice Architecture (DAG)',
		'2. Finite State Machine (FSM State Transitions)',
		'3. Git Branch & Merge History Flow',
		'4. Database Entity-Relationship (ER Diagram)',
		'5. Network Infrastructure Topology (Circular Circo)',
		'6. Binary Search Tree / AST Hierarchy',
		'7. User Authentication & JWT Flowchart'
	], '1. SimpleGUI Microservice Architecture (DAG)')
	win.set_control_width('dd_dot_presets', 380)

	win.add_label('lbl_engine', 'Layout Engine:')
	win.add_dropdown('dd_layout_engine', [
		'dot (Hierarchical Directed Graphs)',
		'neato (Spring / Energy Minimization)',
		'fdp (Force-Directed Graph Placement)',
		'sfdp (Large Scale Force-Directed)',
		'circo (Circular Ring Placement)',
		'twopi (Radial Concentric Layout)'
	], 'dot (Hierarchical Directed Graphs)')
	win.set_control_width('dd_layout_engine', 260)
	win.end_row()

	win.end_group_box()

	// Execution Actions Bar
	win.begin_row('row_actions_1')
	win.add_button('btn_render_diagram', 'Render & Preview Diagram')
	win.add_button('btn_open_in_viewer', 'Open SVG in Browser')
	win.add_button('btn_export_png', 'Export PNG...')
	win.add_button('btn_export_svg', 'Export SVG...')
	win.end_row()

	win.begin_row('row_actions_2')
	win.add_button('btn_export_pdf', 'Export PDF...')
	win.add_button('btn_copy_code', 'Copy DOT Code')
	win.add_button('btn_clear_code', 'Clear')
	win.end_row()

	// Dual Pane: DOT Code Editor & SVG Output / Text Representation
	win.begin_grid('grid_dual_pane', 2, 8)
	win.add_form_textarea('Graphviz DOT Source Code:', 'txt_dot_code', sample_dot_architecture)
	win.set_control_height('txt_dot_code', 320)
	win.add_form_textarea('Rendered Diagram Code / SVG Stream:', 'txt_svg_output', '')
	win.set_control_height('txt_svg_output', 320)
	win.end_grid()

	// Live Activity Console
	win.begin_group_box('grp_console', 'Graphviz Compilation & Layout Telemetry')
	win.add_console('dot_console', 110)
	win.end_group_box()

	// Status Row
	win.begin_row('row_stats')
	win.add_label('lbl_stats', 'Stats: Ready  |  Nodes: Detected  |  Duration: 0 ms')
	win.end_row()

	win.append_console('dot_console', ' Graphviz & Diagram Studio Pro Initialized.\n', 1)
	win.append_console('dot_console', ' Ready to compile and render DOT graphs into SVG, PNG, and PDF.\n', 4)

	// -------------------------------------------------------------
	// Event Handlers
	// -------------------------------------------------------------

	// Preset Selection Handler
	win.on_change('dd_dot_presets', fn (mut w simplegui.SimpleWindow, selected string) {
		if selected.starts_with('1.') {
			w.set('txt_dot_code', sample_dot_architecture)
			w.set('dd_layout_engine', 'dot (Hierarchical Directed Graphs)')
		} else if selected.starts_with('2.') {
			w.set('txt_dot_code', 'digraph FSM {
    rankdir=LR;
    node [shape=circle, style="filled", fillcolor="#22272e", fontcolor="#adbac7", color="#539bf5"];
    edge [color="#539bf5", fontcolor="#adbac7"];
    
    Idle -> Authenticating [label="User Login"];
    Authenticating -> Authenticated [label="Success (200)"];
    Authenticating -> Idle [label="Bad Credentials"];
    Authenticated -> Processing [label="Task Dispatch"];
    Processing -> Completed [label="Finished"];
    Processing -> Failed [label="Timeout / Error"];
    Failed -> Processing [label="Retry"];
    Completed -> Idle [label="Logout"];
}')
			w.set('dd_layout_engine', 'dot (Hierarchical Directed Graphs)')
		} else if selected.starts_with('3.') {
			w.set('txt_dot_code', 'digraph GitFlow {
    rankdir=LR;
    node [shape=box, style="filled,rounded", fillcolor="#22272e", fontcolor="#adbac7", color="#3fb950"];
    edge [color="#3fb950", fontcolor="#adbac7"];
    
    main_v1 [label="main (v1.0.0)"];
    main_v2 [label="main (v1.1.0)"];
    feat_1 [label="feature/dark-mode", color="#539bf5"];
    feat_2 [label="feature/async-worker", color="#f0883e"];
    
    main_v1 -> feat_1;
    main_v1 -> feat_2;
    feat_1 -> main_v2 [label="PR #42 (Merged)"];
    feat_2 -> main_v2 [label="PR #43 (Merged)"];
}')
		} else if selected.starts_with('4.') {
			w.set('txt_dot_code', 'digraph ERD {
    node [shape=record, style="filled", fillcolor="#22272e", fontcolor="#adbac7", color="#539bf5"];
    edge [color="#539bf5", fontcolor="#adbac7"];
    
    User [label="{User | + id: int (PK)\\l+ email: string\\l+ password_hash: string\\l+ created_at: datetime\\l}"];
    Order [label="{Order | + id: int (PK)\\l+ user_id: int (FK)\\l+ total_amount: float\\l+ status: string\\l}"];
    Item [label="{Item | + id: int (PK)\\l+ order_id: int (FK)\\l+ sku: string\\l+ price: float\\l}"];
    
    User -> Order [label="1 : N"];
    Order -> Item [label="1 : N"];
}')
		} else if selected.starts_with('5.') {
			w.set('txt_dot_code', 'graph NetworkTopology {
    layout=circo;
    node [shape=doublecircle, style="filled", fillcolor="#22272e", fontcolor="#adbac7", color="#6366f1"];
    edge [color="#6366f1"];
    
    CoreRouter -- Gateway_US_East;
    CoreRouter -- Gateway_EU_Central;
    CoreRouter -- Gateway_AP_Tokyo;
    Gateway_US_East -- WebApp_1;
    Gateway_US_East -- Database_Replica_1;
    Gateway_EU_Central -- WebApp_2;
    Gateway_EU_Central -- Database_Replica_2;
    Gateway_AP_Tokyo -- WebApp_3;
}')
			w.set('dd_layout_engine', 'circo (Circular Ring Placement)')
		} else if selected.starts_with('6.') {
			w.set('txt_dot_code', 'digraph BinaryTree {
    node [shape=circle, style="filled", fillcolor="#22272e", fontcolor="#adbac7", color="#10b981"];
    edge [color="#10b981"];
    
    50 -> 30;
    50 -> 70;
    30 -> 20;
    30 -> 40;
    70 -> 60;
    70 -> 80;
}')
		} else if selected.starts_with('7.') {
			w.set('txt_dot_code', 'digraph AuthFlow {
    rankdir=TB;
    node [shape=box, style="filled,rounded", fillcolor="#22272e", fontcolor="#adbac7", color="#f43f5e"];
    edge [color="#f43f5e", fontcolor="#adbac7"];
    
    Client [label="Client (Browser/App)"];
    API_Gateway [label="API Gateway / Proxy"];
    Auth_Service [label="OAuth2 / JWT Authority"];
    Resource_API [label="Protected Resource API"];
    
    Client -> API_Gateway [label="1. POST /login"];
    API_Gateway -> Auth_Service [label="2. Validate Credentials"];
    Auth_Service -> Client [label="3. Issue JWT Access Token"];
    Client -> Resource_API [label="4. GET /data (Bearer Token)"];
    Resource_API -> Client [label="5. Return JSON Payload"];
}')
		}
		w.toast('Loaded diagram template: ${selected.split("(")[0]}')
	})

	// Render Diagram Action
	win.on_click('btn_render_diagram', fn (mut w simplegui.SimpleWindow) {
		dot_code := w.get('txt_dot_code')
		if dot_code.trim_space() == '' {
			w.alert('DOT Code Required', 'Please enter or choose Graphviz DOT code to render.')
			return
		}

		dot_bin := get_dot_bin()
		layout_raw := w.get('dd_layout_engine')
		layout_prog := layout_raw.split(' ')[0]

		tmp_dot := os.join_path(os.temp_dir(), 'diagram_${time.ticks()}.dot')
		tmp_svg := os.join_path(os.temp_dir(), 'diagram_preview.svg')

		os.write_file(tmp_dot, dot_code) or {
			w.toast('Failed to write temp DOT file.')
			return
		}

		w.append_console('dot_console', ' Compiling DOT code with layout engine: ${layout_prog}...\n', 1)
		w.set_status('Rendering diagram...')

		go fn [mut w, dot_bin, layout_prog, tmp_dot, tmp_svg] () {
			t0 := time.ticks()
			res := simplegui.exec_safe(dot_bin, ['-K' + layout_prog, '-Tsvg', tmp_dot, '-o', tmp_svg])
			elapsed_ms := time.ticks() - t0

			w.run_on_main_thread(fn [res, elapsed_ms, tmp_svg] (mut win_main simplegui.SimpleWindow) {
				if res.exit_code == 0 && os.exists(tmp_svg) {
					svg_content := os.read_file(tmp_svg) or { '' }
					win_main.set('txt_svg_output', svg_content)
					win_main.append_console('dot_console', ' Diagram rendered to SVG in ${elapsed_ms} ms (${svg_content.len} bytes).\n', 4)
					win_main.set('lbl_stats', ' Stats: SUCCESS  |  SVG: ${svg_content.len} B  |  Duration: ${elapsed_ms} ms')
					win_main.set_status('Diagram compiled in ${elapsed_ms} ms.')
					win_main.toast('Diagram rendered successfully!')
				} else {
					win_main.append_console('dot_console', ' Graphviz Compiler Error:\n' + res.output + '\n', 3)
					win_main.set('lbl_stats', ' Stats: COMPILER ERROR (Exit ${res.exit_code})  |  Duration: ${elapsed_ms} ms')
					win_main.set_status('Graphviz compilation failed.')
					win_main.toast('Compilation error.')
				}
			})
		}()
	})

	// Open SVG in Browser
	win.on_click('btn_open_in_viewer', fn (mut w simplegui.SimpleWindow) {
		tmp_svg := os.join_path(os.temp_dir(), 'diagram_preview.svg')
		if os.exists(tmp_svg) {
			os.execute('open "${tmp_svg}"')
			w.toast('Opened rendered diagram in macOS viewer!')
			w.append_console('dot_console', ' Opened diagram: ${tmp_svg}\n', 4)
		} else {
			w.alert('Render Required', 'Please click "Render & Preview Diagram" first.')
		}
	})

	// Export PNG
	win.on_click('btn_export_png', fn (mut w simplegui.SimpleWindow) {
		dot_code := w.get('txt_dot_code')
		if dot_code.trim_space() == '' {
			w.toast('No DOT code to export.')
			return
		}
		save_path := w.save_file_picker()
		if save_path != '' {
			mut save_file := save_path
			if !save_file.ends_with('.png') { save_file += '.png' }
			dot_bin := get_dot_bin()
			layout_raw := w.get('dd_layout_engine')
			layout_prog := layout_raw.split(' ')[0]

			tmp_dot := os.join_path(os.temp_dir(), 'export_${time.ticks()}.dot')
			os.write_file(tmp_dot, dot_code) or { return }
			simplegui.exec_safe(dot_bin, ['-K' + layout_prog, '-Tpng', tmp_dot, '-o', save_file])
			os.rm(tmp_dot) or {}

			w.toast('Exported PNG to ' + os.file_name(save_file))
			w.append_console('dot_console', ' Saved PNG diagram: ${save_file}\n', 4)
		}
	})

	// Export SVG
	win.on_click('btn_export_svg', fn (mut w simplegui.SimpleWindow) {
		dot_code := w.get('txt_dot_code')
		if dot_code.trim_space() == '' {
			w.toast('No DOT code to export.')
			return
		}
		save_path := w.save_file_picker()
		if save_path != '' {
			mut save_file := save_path
			if !save_file.ends_with('.svg') { save_file += '.svg' }
			dot_bin := get_dot_bin()
			layout_raw := w.get('dd_layout_engine')
			layout_prog := layout_raw.split(' ')[0]

			tmp_dot := os.join_path(os.temp_dir(), 'export_${time.ticks()}.dot')
			os.write_file(tmp_dot, dot_code) or { return }
			simplegui.exec_safe(dot_bin, ['-K' + layout_prog, '-Tsvg', tmp_dot, '-o', save_file])
			os.rm(tmp_dot) or {}

			w.toast('Exported SVG to ' + os.file_name(save_file))
			w.append_console('dot_console', ' Saved SVG diagram: ${save_file}\n', 4)
		}
	})

	// Export PDF
	win.on_click('btn_export_pdf', fn (mut w simplegui.SimpleWindow) {
		dot_code := w.get('txt_dot_code')
		if dot_code.trim_space() == '' {
			w.toast('No DOT code to export.')
			return
		}
		save_path := w.save_file_picker()
		if save_path != '' {
			mut save_file := save_path
			if !save_file.ends_with('.pdf') { save_file += '.pdf' }
			dot_bin := get_dot_bin()
			layout_raw := w.get('dd_layout_engine')
			layout_prog := layout_raw.split(' ')[0]

			tmp_dot := os.join_path(os.temp_dir(), 'export_${time.ticks()}.dot')
			os.write_file(tmp_dot, dot_code) or { return }
			simplegui.exec_safe(dot_bin, ['-K' + layout_prog, '-Tpdf', tmp_dot, '-o', save_file])
			os.rm(tmp_dot) or {}

			w.toast('Exported PDF to ' + os.file_name(save_file))
			w.append_console('dot_console', ' Saved PDF diagram: ${save_file}\n', 4)
		}
	})

	// Copy DOT Code
	win.on_click('btn_copy_code', fn (mut w simplegui.SimpleWindow) {
		code := w.get('txt_dot_code')
		if code != '' {
			w.copy_to_clipboard(code)
			w.toast('DOT code copied to clipboard!')
		}
	})

	// Clear All
	win.on_click('btn_clear_code', fn (mut w simplegui.SimpleWindow) {
		w.set('txt_dot_code', '')
		w.set('txt_svg_output', '')
		w.clear_console('dot_console')
		w.toast('Cleared workspace.')
	})

	win.start()
}

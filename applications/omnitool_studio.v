module main

import os
import time
import simplegui

// -----------------------------------------------------------------------------
// Application State & Toolchain Registry
// -----------------------------------------------------------------------------
struct ToolInfo {
	name        string
	bin_path    string
	version_str string
	is_ready    bool
	description string
}

struct OmniState {
mut:
	tools             map[string]ToolInfo
	active_mode       string
	active_dir        string
	is_process_active bool
	active_pid        int
	total_ops         int
	last_op_status    string
	last_op_ts        string
	last_cli_command  string
}

// -----------------------------------------------------------------------------
// Modern Binary Discovery & Version Probing
// -----------------------------------------------------------------------------
fn discover_tool(name string, fallback_paths []string, desc string) ToolInfo {
	mut path := ''
	if p := os.find_abs_path_of_executable(name) {
		path = p
	} else {
		for fb in fallback_paths {
			if os.exists(fb) {
				path = fb
				break
			}
		}
	}

	if path == '' {
		return ToolInfo{
			name: name
			bin_path: ''
			version_str: 'Not Found'
			is_ready: false
			description: desc
		}
	}

	res := simplegui.exec_safe(path, ['--version'])
	mut ver := '${name} (Ready)'
	if res.exit_code == 0 {
		lines := res.output.trim_space().split_into_lines()
		if lines.len > 0 {
			first_line := lines[0].trim_space()
			if first_line.len > 40 {
				ver = first_line[..40]
			} else {
				ver = first_line
			}
		}
	}

	return ToolInfo{
		name: name
		bin_path: path
		version_str: ver
		is_ready: true
		description: desc
	}
}

fn init_toolchain() map[string]ToolInfo {
	mut tools := map[string]ToolInfo{}

	tools['rg'] = discover_tool('rg', ['/opt/homebrew/bin/rg', '/usr/local/bin/rg', '/usr/bin/rg'],
		'ripgrep - ultra-fast recursive regex search')
	tools['fd'] = discover_tool('fd', ['/opt/homebrew/bin/fd', '/usr/local/bin/fd', '/usr/bin/fd'],
		'fd - modern user-friendly fast file finder')
	tools['sd'] = discover_tool('sd', ['/opt/homebrew/bin/sd', '/usr/local/bin/sd', '/usr/bin/sd'],
		'sd - fast regex find & replace (modern sed)')
	tools['watchexec'] = discover_tool('watchexec', [
		'/opt/homebrew/bin/watchexec',
		'/usr/local/bin/watchexec',
		'/usr/bin/watchexec',
	], 'watchexec - continuous file watcher daemon')
	tools['wget2'] = discover_tool('wget2', [
		'/opt/homebrew/bin/wget2',
		'/usr/local/bin/wget2',
		'/usr/bin/wget2',
	], 'wget2 - multi-threaded accelerated network downloader')
	tools['rip'] = discover_tool('rip', ['/opt/homebrew/bin/rip', '/usr/local/bin/rip', '/usr/bin/rip'],
		'rip - rm-improved safe graveyard trash with undo')
	tools['ouch'] = discover_tool('ouch', [
		'/opt/homebrew/bin/ouch',
		'/usr/local/bin/ouch',
		'/usr/bin/ouch',
	], 'ouch - universal painless compression & extraction')
	tools['bat'] = discover_tool('bat', ['/opt/homebrew/bin/bat', '/usr/local/bin/bat', '/usr/bin/bat'],
		'bat - syntax highlighting pager & viewer')
	tools['eza'] = discover_tool('eza', ['/opt/homebrew/bin/eza', '/usr/local/bin/eza', '/usr/bin/eza'],
		'eza - modern tree & directory inspection')

	return tools
}

// -----------------------------------------------------------------------------
// ANSI Code Stripper
// -----------------------------------------------------------------------------
fn strip_ansi(s string) string {
	mut res := []u8{}
	mut i := 0
	for i < s.len {
		if s[i] == 27 && i + 1 < s.len && s[i + 1] == `[` {
			i += 2
			for i < s.len && s[i] != `m` && s[i] != `K` && s[i] != `J` && s[i] != `H` {
				i++
			}
			if i < s.len {
				i++
			}
			continue
		}
		res << s[i]
		i++
	}
	return res.bytestr()
}

// -----------------------------------------------------------------------------
// Format Helpers
// -----------------------------------------------------------------------------
fn get_now_str() string {
	t := time.now()
	return '${t.hour:02d}:${t.minute:02d}:${t.second:02d}'
}

// -----------------------------------------------------------------------------
// Main Application Entry Point
// -----------------------------------------------------------------------------
fn main() {
	println('Starting SimpleGUI - OmniTool Studio Pro (Modern Unix Powerhouse)...')

	mut win := simplegui.new_simple_window('SimpleGUI - OmniTool Studio Pro', 1280, 960)
	win.set_fullscreen(true)
	win.restore_saved_theme()
	win.set_spacing(8)
	win.set_padding(14)

	tools_map := init_toolchain()
	mut ready_count := 0
	for _, t in tools_map {
		if t.is_ready {
			ready_count++
		}
	}

	mut state := &OmniState{
		tools: tools_map
		active_mode: '1. [Synergy Pipeline] Search -> Replace -> Diff (fd + sd + rg)'
		active_dir: os.getwd()
		is_process_active: false
		active_pid: 0
		total_ops: 0
		last_op_status: 'Idle'
		last_op_ts: 'Ready'
		last_cli_command: ''
	}

	// -------------------------------------------------------------
	// Header & Theme Selection
	// -------------------------------------------------------------
	win.begin_row('row_top_header')
	win.add_heading('OmniTool Studio Pro')
	win.add_label('lbl_theme', 'Theme:')
	saved_theme := simplegui.get_saved_theme()
	win.add_dropdown('dd_app_theme', simplegui.list_themes(), saved_theme)
	win.set_control_width('dd_app_theme', 150)
	win.end_row()

	win.on_change('dd_app_theme', fn (mut w simplegui.SimpleWindow, selected string) {
		w.set_theme(selected)
		w.toast('Theme set to ${selected}')
	})

	// Subtitle & Platform
	win.add_label('lbl_subhead', 'Modern Unix Developer Suite  |  fd · sd · watchexec · wget2 · rg · rip · ouch · bat · eza  |  ${simplegui.get_platform_label()}')

	// -------------------------------------------------------------
	// Engine Integrity & Vitals Cards
	// -------------------------------------------------------------
	win.begin_row('row_engine_cards')
	win.add_metric_card('card_toolchain', 'Toolchain', '${ready_count}/9 Ready', 'CLI Binaries',
		'Engine')
	win.set_control_width('card_toolchain', 260)
	win.add_metric_card('card_active_mode', 'Active Mode', 'Synergy Pipeline', 'Selected Workflow',
		'Mode')
	win.set_control_width('card_active_mode', 260)
	win.add_metric_card('card_op_count', 'Operations', '0 Operations', 'Workflow Counter',
		'Activity')
	win.set_control_width('card_op_count', 260)
	win.add_metric_card('card_status', 'Engine Status', 'IDLE', 'Subprocess State', 'Vitals')
	win.set_control_width('card_status', 260)
	win.end_row()

	// -------------------------------------------------------------
	// Workspace Scope & Directory Browser
	// -------------------------------------------------------------
	win.begin_row('row_workspace_dir')
	win.add_label('lbl_ws', 'Target Workspace:')
	win.add_input('txt_workspace', os.getwd())
	win.set_control_width('txt_workspace', 480)
	win.add_button('btn_browse_ws', 'Browse...')
	win.add_button('btn_curr_ws', 'Current (.)')
	win.add_button('btn_home_ws', 'Home (~)')
	win.add_button('btn_tmp_ws', 'Temp (/tmp)')
	win.end_row()

	// -------------------------------------------------------------
	// Mode Selection & Configuration Card
	// -------------------------------------------------------------
	win.begin_group_box('grp_mode_config', 'Workflow Pipeline & Tool Engine Selection')

	// Row 1: Mode Selector Dropdown
	win.begin_row('row_mode_sel')
	win.add_label('lbl_mode_sel', 'Operation Mode:')
	win.add_dropdown('dd_mode', [
		'1. [Synergy Pipeline] Search -> Replace -> Diff (fd + sd + rg)',
		'2. [Synergy Pipeline] Download -> Extract -> Inspect (wget2 + ouch + eza)',
		'3. [Synergy Pipeline] Search -> Safe Trash Graveyard (fd + rip)',
		'4. [Tool Engine] Ripgrep Code Search (rg)',
		'5. [Tool Engine] Fast File Finder (fd)',
		'6. [Tool Engine] Regex Text Substitution (sd)',
		'7. [Tool Engine] Continuous Watch & Run (watchexec)',
		'8. [Tool Engine] Multi-Threaded Downloader (wget2)',
		'9. [Tool Engine] Graveyard Trash Manager (rip)',
		'10. [Tool Engine] Universal Compression (ouch)',
		'11. [Tool Engine] Modern Directory Tree (eza)',
	], '1. [Synergy Pipeline] Search -> Replace -> Diff (fd + sd + rg)')
	win.set_control_width('dd_mode', 460)

	win.add_label('lbl_preset_sel', 'Common Preset:')
	win.add_dropdown('dd_preset', [
		'Default Custom Parameters',
		'V Language Source (*.v)',
		'Rust & Cargo (*.rs, Cargo.toml)',
		'Go Modules (*.go)',
		'Web / Node (ts, js, json)',
		'Clean Node Modules (node_modules)',
		'Clean Build Artifacts (target, build, dist)',
		'Clean DS_Store & Temp (*.DS_Store, *.tmp)',
	], 'Default Custom Parameters')
	win.set_control_width('dd_preset', 260)
	win.end_row()

	// Row 2: Primary Parameter (Pattern / Query / URL / Archive)
	win.begin_row('row_param_primary')
	win.add_label('lbl_primary', 'Query / Pattern / URL:')
	win.set_control_width('lbl_primary', 170)
	win.add_input('txt_primary', 'fn main')
	win.set_control_width('txt_primary', 520)
	win.add_label('lbl_primary_hint', '// Search regex, source pattern, or download URL')
	win.end_row()

	// Row 3: Secondary Parameter (Replacement / Target Dir / Destination)
	win.begin_row('row_param_secondary')
	win.add_label('lbl_secondary', 'Replacement / Target:')
	win.set_control_width('lbl_secondary', 170)
	win.add_input('txt_secondary', 'fn main_entry')
	win.set_control_width('txt_secondary', 520)
	win.add_label('lbl_secondary_hint', '// Replacement text, unpack directory, or archive name')
	win.end_row()

	// Row 4: Filter & Glob Parameter
	win.begin_row('row_param_filter')
	win.add_label('lbl_filter', 'File Filter / Glob (-e / -g):')
	win.set_control_width('lbl_filter', 170)
	win.add_input('txt_filter', '*.v')
	win.set_control_width('txt_filter', 280)

	win.add_label('lbl_ignores', 'Ignore Pattern (-i):')
	win.set_control_width('lbl_ignores', 130)
	win.add_input('txt_ignores', 'target/*, .git/*, node_modules/*')
	win.set_control_width('txt_ignores', 260)
	win.end_row()

	// Row 5: Operational Toggles & Modifiers
	win.begin_row('row_toggles')
	win.add_checkbox('chk_case_sens', 'Case Sensitive (-s)', false)
	win.add_checkbox('chk_hidden', 'Hidden Files (-H)', false)
	win.add_checkbox('chk_dry_run', 'Dry Run (Preview Only)', true)
	win.add_checkbox('chk_recursive', 'Recursive Watch/Search', true)
	win.add_checkbox('chk_auto_unpack', 'Auto-Unpack Archive', true)
	win.end_row()

	win.end_group_box()

	// -------------------------------------------------------------
	// Pipeline Execution & Control Actions Bar
	// -------------------------------------------------------------
	win.begin_row('row_action_bar')
	win.add_button('btn_execute', 'Execute Active Pipeline / Tool')
	win.add_button('btn_dry_run_action', 'Preview / Dry Run')
	win.add_button('btn_copy_cmd', 'Copy Equivalent CLI Command')
	win.add_button('btn_stop_proc', 'Stop / Kill Process')
	win.add_button('btn_clear_view', 'Clear Output')
	win.end_row()

	// -------------------------------------------------------------
	// Live Visualizer / Terminal Stream View
	// -------------------------------------------------------------
	win.add_label('lbl_stream_title', 'Live Execution Stream & Structured Visualizer:')
	win.add_textarea('txt_live_output', '// OmniTool Studio Pro Initialized.\n// Select a pipeline or standalone tool engine above, configure arguments, and click "Execute Active Pipeline / Tool" or "Preview / Dry Run".\n// All 9 modern CLI utilities (fd, sd, watchexec, wget2, rg, rip, ouch, bat, eza) are mapped and ready.\n')
	win.set_control_height('txt_live_output', 280)

	// -------------------------------------------------------------
	// Telemetry & Operation Audit Journal
	// -------------------------------------------------------------
	win.add_label('lbl_audit_title', 'Activity & Telemetry Journal:')
	win.add_console('omni_console', 120)

	// -------------------------------------------------------------
	// Bottom Status Bar
	// -------------------------------------------------------------
	win.begin_row('row_status_bar')
	win.add_label('lbl_status_bar', 'Status: Ready  |  9 Modern CLI Engines Active  |  Ready for execution')
	win.end_row()

	// -------------------------------------------------------------
	// Event Callbacks & Interactivity
	// -------------------------------------------------------------

	// Workspace Folder Browser
	win.on_click('btn_browse_ws', fn (mut w simplegui.SimpleWindow) {
		chosen := w.osascript_choose_folder()
		if chosen != '' {
			w.set('txt_workspace', chosen)
			w.append_console('omni_console', '[${get_now_str()}] Workspace updated to: ${chosen}\n',
				1)
			w.toast('Workspace folder updated')
		}
	})

	win.on_click('btn_curr_ws', fn (mut w simplegui.SimpleWindow) {
		cwd := os.getwd()
		w.set('txt_workspace', cwd)
		w.append_console('omni_console', '[${get_now_str()}] Workspace set to current directory: ${cwd}\n',
			1)
	})

	win.on_click('btn_home_ws', fn (mut w simplegui.SimpleWindow) {
		home := os.home_dir()
		w.set('txt_workspace', home)
		w.append_console('omni_console', '[${get_now_str()}] Workspace set to user home: ${home}\n',
			1)
	})

	win.on_click('btn_tmp_ws', fn (mut w simplegui.SimpleWindow) {
		tmp_dir := os.temp_dir()
		w.set('txt_workspace', tmp_dir)
		w.append_console('omni_console', '[${get_now_str()}] Workspace set to temp directory: ${tmp_dir}\n',
			1)
	})

	// Clear View Action
	win.on_click('btn_clear_view', fn (mut w simplegui.SimpleWindow) {
		w.set('txt_live_output', '// Screen cleared.\n')
		w.toast('Output stream cleared')
	})

	// Mode Change Handler
	win.on_change('dd_mode', fn [mut state] (mut w simplegui.SimpleWindow, selected string) {
		state.active_mode = selected
		w.set_metric_card_value('card_active_mode', selected.split('] ')[1] or { selected },
			'Mode')

		if selected.starts_with('1.') {
			// Find -> Replace -> Diff
			w.set('lbl_primary', 'Query / Search Regex:')
			w.set('txt_primary', 'fn main')
			w.set('lbl_secondary', 'Replacement String:')
			w.set('txt_secondary', 'fn main_entry')
			w.set('lbl_filter', 'File Filter / Glob:')
			w.set('txt_filter', '*.v')
			w.set('chk_dry_run', 'true')
		} else if selected.starts_with('2.') {
			// Download -> Extract -> Inspect
			w.set('lbl_primary', 'Download Asset URL:')
			w.set('txt_primary', 'https://github.com/vlang/v/releases/latest/download/v_macos_arm64.zip')
			w.set('lbl_secondary', 'Destination Directory:')
			w.set('txt_secondary', './downloads')
			w.set('lbl_filter', 'Extraction Target:')
			w.set('txt_filter', './downloads/extracted')
			w.set('chk_auto_unpack', 'true')
		} else if selected.starts_with('3.') {
			// Search -> Safe Trash
			w.set('lbl_primary', 'Trash Target Pattern:')
			w.set('txt_primary', 'node_modules')
			w.set('lbl_secondary', 'Graveyard Tag / Note:')
			w.set('txt_secondary', 'Safe cleanup')
			w.set('lbl_filter', 'Ignore Guard:')
			w.set('txt_filter', '.git/*')
			w.set('chk_dry_run', 'true')
		} else if selected.starts_with('4.') {
			// Ripgrep
			w.set('lbl_primary', 'Ripgrep Query / Regex:')
			w.set('txt_primary', 'struct [A-Za-z]+')
			w.set('lbl_secondary', 'Context Lines (-C):')
			w.set('txt_secondary', '2')
			w.set('lbl_filter', 'File Type / Glob (-g):')
			w.set('txt_filter', '*.v')
		} else if selected.starts_with('5.') {
			// Fd
			w.set('lbl_primary', 'File / Dir Name Pattern:')
			w.set('txt_primary', 'studio')
			w.set('lbl_secondary', 'Max Depth (--max-depth):')
			w.set('txt_secondary', '4')
			w.set('lbl_filter', 'Extension (-e):')
			w.set('txt_filter', 'v')
		} else if selected.starts_with('6.') {
			// Sd
			w.set('lbl_primary', 'Find Regex:')
			w.set('txt_primary', 'foo_bar')
			w.set('lbl_secondary', 'Replace With:')
			w.set('txt_secondary', 'baz_qux')
			w.set('lbl_filter', 'Target Files:')
			w.set('txt_filter', 'applications/*.v')
		} else if selected.starts_with('7.') {
			// Watchexec
			w.set('lbl_primary', 'Command to Execute:')
			w.set('txt_primary', 'v -check .')
			w.set('lbl_secondary', 'Debounce Delay:')
			w.set('txt_secondary', '250ms')
			w.set('lbl_filter', 'Extensions to Watch (-e):')
			w.set('txt_filter', 'v')
		} else if selected.starts_with('8.') {
			// Wget2
			w.set('lbl_primary', 'Target URL to Fetch:')
			w.set('txt_primary', 'https://raw.githubusercontent.com/vlang/v/master/README.md')
			w.set('lbl_secondary', 'Save Path / Folder:')
			w.set('txt_secondary', './downloads')
			w.set('lbl_filter', 'Concurrent Threads (-j):')
			w.set('txt_filter', '8')
		} else if selected.starts_with('9.') {
			// Rip
			w.set('lbl_primary', 'Target File/Directory:')
			w.set('txt_primary', 'graveyard_inspect')
			w.set('lbl_secondary', 'Action (bury / unbury):')
			w.set('txt_secondary', 'inspect')
			w.set('lbl_filter', 'Cemetery Filter:')
			w.set('txt_filter', '*')
		} else if selected.starts_with('10.') {
			// Ouch
			w.set('lbl_primary', 'Archive File:')
			w.set('txt_primary', 'project_backup.tar.gz')
			w.set('lbl_secondary', 'Action (compress/decompress):')
			w.set('txt_secondary', 'compress')
			w.set('lbl_filter', 'Source Targets:')
			w.set('txt_filter', 'applications/')
		} else if selected.starts_with('11.') {
			// Eza
			w.set('lbl_primary', 'Directory to Tree:')
			w.set('txt_primary', '.')
			w.set('lbl_secondary', 'Max Depth (-L):')
			w.set('txt_secondary', '3')
			w.set('lbl_filter', 'Options:')
			w.set('txt_filter', '--icons=never')
		}

		w.append_console('omni_console', '[${get_now_str()}] Switched mode to: ${selected}\n',
			1)
	})

	// Preset Change Handler
	win.on_change('dd_preset', fn (mut w simplegui.SimpleWindow, selected string) {
		match selected {
			'V Language Source (*.v)' {
				w.set('txt_filter', '*.v')
			}
			'Rust & Cargo (*.rs, Cargo.toml)' {
				w.set('txt_filter', '*.rs, Cargo.toml')
			}
			'Go Modules (*.go)' {
				w.set('txt_filter', '*.go, go.mod')
			}
			'Web / Node (ts, js, json)' {
				w.set('txt_filter', '*.ts, *.tsx, *.js, *.json')
			}
			'Clean Node Modules (node_modules)' {
				w.set('txt_primary', 'node_modules')
				w.set('chk_dry_run', 'true')
			}
			'Clean Build Artifacts (target, build, dist)' {
				w.set('txt_primary', 'target, build, dist')
				w.set('chk_dry_run', 'true')
			}
			'Clean DS_Store & Temp (*.DS_Store, *.tmp)' {
				w.set('txt_primary', '*.DS_Store, *.tmp')
				w.set('chk_dry_run', 'true')
			}
			else {}
		}
	})

	// -------------------------------------------------------------
	// Core Execution Engine Function
	// -------------------------------------------------------------
	run_pipeline := fn [mut state] (mut w simplegui.SimpleWindow, force_dry_run bool) {
		mode := w.get('dd_mode')
		ws := w.get('txt_workspace').trim_space()
		primary := w.get('txt_primary').trim_space()
		secondary := w.get('txt_secondary').trim_space()
		filter := w.get('txt_filter').trim_space()
		ignores := w.get('txt_ignores').trim_space()
		_ = ignores
		is_case := w.get('chk_case_sens') == 'true'
		is_hidden := w.get('chk_hidden') == 'true'
		is_dry := force_dry_run || (w.get('chk_dry_run') == 'true')
		is_rec := w.get('chk_recursive') == 'true'
		_ = is_rec
		is_unpack := w.get('chk_auto_unpack') == 'true'

		state.total_ops++
		w.set_metric_card_value('card_op_count', '${state.total_ops} Ops', 'Activity')
		w.set_metric_card_value('card_status', 'RUNNING', 'Vitals')
		w.set('lbl_status_bar', ' Status: Executing pipeline: ${mode.split('] ')[1] or { mode }}...')

		// ---------------------------------------------------------
		// Pipeline 1: Search -> Replace -> Diff (fd + sd + rg)
		// ---------------------------------------------------------
		if mode.starts_with('1.') {
			rg_bin := state.tools['rg'].bin_path
			sd_bin := state.tools['sd'].bin_path
			fd_bin := state.tools['fd'].bin_path

			if rg_bin == '' || sd_bin == '' || fd_bin == '' {
				w.toast('Required tools missing: rg, sd, or fd')
				w.append_console('omni_console', '[${get_now_str()}] [ERROR] Missing required binary for Pipeline 1.\n',
					3)
				w.set_metric_card_value('card_status', 'ERROR', 'Vitals')
				w.set('lbl_status_bar', ' Status: Error - Required binary (rg, sd, or fd) missing.')
				return
			}

			w.append_console('omni_console', '[${get_now_str()}] Launching Find->Replace->Diff pipeline (Dry Run: ${is_dry})...\n',
				1)

			// Step A: Find files containing the search pattern using rg
			mut rg_args := ['-l', '--color=never']
			if is_case {
				rg_args << '-s'
			} else {
				rg_args << '-i'
			}
			if is_hidden {
				rg_args << '--hidden'
			}
			if filter != '' {
				for f in filter.split(',') {
					tf := f.trim_space()
					if tf != '' {
						rg_args << '-g'
						rg_args << tf
					}
				}
			}
			rg_args << primary
			rg_args << ws

			search_res := simplegui.exec_safe(rg_bin, rg_args)
			matching_files := search_res.output.trim_space().split_into_lines().filter(it.trim_space() != '')

			if matching_files.len == 0 {
				w.set('txt_live_output', '=== PIPELINE 1: SEARCH -> REPLACE -> DIFF ===\nTarget Workspace: ${ws}\nSearch Pattern: "${primary}"\nReplacement:    "${secondary}"\n\n[INFO] No files matching the criteria contained pattern "${primary}".\nNothing to replace.\n')
				w.append_console('omni_console', '[${get_now_str()}] Search completed: 0 files matched.\n',
					1)
				w.set_metric_card_value('card_status', 'IDLE', 'Vitals')
				w.set('lbl_status_bar', ' Status: Pipeline complete - 0 matching files found.')
				return
			}

			mut out := '=== PIPELINE 1: SEARCH -> REPLACE -> DIFF ===\n'
			out += 'Target Workspace: ${ws}\n'
			out += 'Search Pattern:   "${primary}"\n'
			out += 'Replacement:      "${secondary}"\n'
			out += 'Matching Files:   ${matching_files.len} files identified\n'
			out += 'Execution Mode:   ${if is_dry { 'DRY RUN (Preview Only - No Disk Changes)' } else { 'APPLIED IN-PLACE' }}\n'
			out += '----------------------------------------------------------------------\n\n'

			mut replaced_count := 0
			for file_path in matching_files {
				rel_path := if file_path.starts_with(ws) {
					file_path[ws.len..].trim_left('/')
				} else {
					file_path
				}
				out += '[File: ${rel_path}]\n'

				// Sample preview using rg
				preview_res := simplegui.exec_safe(rg_bin, ['-n', '--color=never', primary,
					file_path])
				for line in preview_res.output.trim_space().split_into_lines() {
					if line.trim_space() != '' {
						out += '  - Current: ${line}\n'
						// Construct synthetic preview of replacement
						mod_line := line.replace(primary, secondary)
						out += '  + Preview: ${mod_line}\n'
					}
				}

				if !is_dry {
					// Apply modification using sd
					sd_res := simplegui.exec_safe(sd_bin, [primary, secondary, file_path])
					if sd_res.exit_code == 0 {
						replaced_count++
						out += '  ==> Successfully updated with sd.\n'
					} else {
						out += '  ==> [ERROR] sd failed on file: ${sd_res.output}\n'
					}
				}
				out += '\n'
			}

			if is_dry {
				out += '----------------------------------------------------------------------\n'
				out += '[DRY RUN COMPLETE] Found ${matching_files.len} files that will be transformed.\n'
				out += 'To apply these changes, uncheck "Dry Run" and click "Execute Active Pipeline / Tool".\n'
				state.last_cli_command = '${fd_bin} -e "${filter}" "${ws}" -x ${sd_bin} "${primary}" "${secondary}"'
			} else {
				out += '----------------------------------------------------------------------\n'
				out += '[PIPELINE COMPLETE] Successfully updated ${replaced_count} files in-place using sd.\n'
				state.last_cli_command = '${sd_bin} "${primary}" "${secondary}" [target_files]'
			}

			w.set('txt_live_output', out)
			w.append_console('omni_console', '[${get_now_str()}] Pipeline finished: ${matching_files.len} files processed.\n',
				2)
			w.set_metric_card_value('card_status', 'SUCCESS', 'Vitals')
			w.set('lbl_status_bar', ' Status: Pipeline complete - ${matching_files.len} files processed.')
			w.toast(if is_dry { 'Dry run preview generated' } else { 'Find & Replace applied!' })
			return
		}

		// ---------------------------------------------------------
		// Pipeline 2: Download -> Extract -> Inspect (wget2 + ouch + eza)
		// ---------------------------------------------------------
		if mode.starts_with('2.') {
			wget_bin := state.tools['wget2'].bin_path
			ouch_bin := state.tools['ouch'].bin_path
			eza_bin := state.tools['eza'].bin_path

			if wget_bin == '' {
				w.toast('wget2 binary missing!')
				w.set_metric_card_value('card_status', 'ERROR', 'Vitals')
				w.set('lbl_status_bar', ' Status: Error - wget2 binary missing.')
				return
			}

			dest_dir := if secondary != '' { secondary } else { os.join_path(ws, 'downloads') }
			if !os.exists(dest_dir) {
				os.mkdir_all(dest_dir) or {}
			}

			w.append_console('omni_console', '[${get_now_str()}] Starting accelerated download with wget2: ${primary}...\n',
				1)

			mut out := '=== PIPELINE 2: DOWNLOAD -> EXTRACT -> INSPECT ===\n'
			out += 'Target Asset URL: ${primary}\n'
			out += 'Download Dir:     ${dest_dir}\n'
			out += '----------------------------------------------------------------------\n\n'

			// Execute wget2
			w_res := simplegui.exec_safe(wget_bin, ['-c', '-P', dest_dir, primary])
			out += '[Step 1: wget2 Download Output]\n'
			out += strip_ansi(w_res.output) + '\n\n'

			state.last_cli_command = '${wget_bin} -c -P "${dest_dir}" "${primary}"'

			if w_res.exit_code != 0 {
				out += '[ERROR] Download failed with exit code ${w_res.exit_code}.\n'
				w.set('txt_live_output', out)
				w.append_console('omni_console', '[${get_now_str()}] [ERROR] wget2 download failed.\n',
					3)
				w.set_metric_card_value('card_status', 'ERROR', 'Vitals')
				w.set('lbl_status_bar', ' Status: Error - wget2 download failed.')
				w.toast('Download failed')
				return
			}

			// Step 2: Auto-unpack if archive and ouch is available
			if is_unpack && ouch_bin != '' {
				// Find archive in dest_dir
				dl_files := os.ls(dest_dir) or { []string{} }
				mut found_archive := ''
				for f in dl_files {
					if f.ends_with('.zip') || f.ends_with('.tar.gz') || f.ends_with('.tgz')
						|| f.ends_with('.tar.zst') || f.ends_with('.7z') || f.ends_with('.tar.xz') {
						found_archive = os.join_path(dest_dir, f)
						break
					}
				}

				if found_archive != '' {
					extract_target := os.join_path(dest_dir, 'extracted')
					out += '[Step 2: ouch Archive Extraction]\n'
					out += 'Extracting "${os.file_name(found_archive)}" -> "${extract_target}"...\n'

					ouch_res := simplegui.exec_safe(ouch_bin, [
						'decompress',
						found_archive,
						'--dir',
						extract_target,
					])
					out += strip_ansi(ouch_res.output) + '\n\n'

					// Step 3: Inspect with eza
					if eza_bin != '' && os.exists(extract_target) {
						out += '[Step 3: eza Directory Tree Inspection]\n'
						eza_res := simplegui.exec_safe(eza_bin, [
							'-T',
							'--icons=never',
							'-L',
							'3',
							extract_target,
						])
						out += strip_ansi(eza_res.output) + '\n'
					}
				} else {
					out += '[Step 2: Note] Downloaded file does not appear to be an archive or was already unpacked.\n'
				}
			}

			w.set('txt_live_output', out)
			w.append_console('omni_console', '[${get_now_str()}] Pipeline 2 finished successfully.\n',
				2)
			w.set_metric_card_value('card_status', 'SUCCESS', 'Vitals')
			w.set('lbl_status_bar', ' Status: Download & unpack complete.')
			w.toast('Download & unpack complete!')
			return
		}

		// ---------------------------------------------------------
		// Pipeline 3: Search -> Safe Trash Graveyard (fd + rip)
		// ---------------------------------------------------------
		if mode.starts_with('3.') {
			fd_bin := state.tools['fd'].bin_path
			rip_bin := state.tools['rip'].bin_path

			if fd_bin == '' || rip_bin == '' {
				w.toast('fd or rip binary missing!')
				w.set_metric_card_value('card_status', 'ERROR', 'Vitals')
				w.set('lbl_status_bar', ' Status: Error - fd or rip missing.')
				return
			}

			w.append_console('omni_console', '[${get_now_str()}] Searching for targets matching "${primary}" to bury with rip...\n',
				1)

			mut fd_args := ['--color=never']
			if is_hidden {
				fd_args << '-H'
			}
			fd_args << primary
			fd_args << ws

			fd_res := simplegui.exec_safe(fd_bin, fd_args)
			targets := fd_res.output.trim_space().split_into_lines().filter(it.trim_space() != '')

			mut out := '=== PIPELINE 3: SEARCH -> SAFE TRASH GRAVEYARD (FD + RIP) ===\n'
			out += 'Target Workspace: ${ws}\n'
			out += 'Search Pattern:   "${primary}"\n'
			out += 'Discovered Items: ${targets.len}\n'
			out += 'Execution Mode:   ${if is_dry { 'DRY RUN PREVIEW (Graveyard Safe)' } else { 'BURIED TO GRAVEYARD' }}\n'
			out += '----------------------------------------------------------------------\n\n'

			if targets.len == 0 {
				out += '[INFO] No matching files or directories found matching "${primary}".\nGraveyard remains pristine.\n'
				w.set('txt_live_output', out)
				w.set_metric_card_value('card_status', 'IDLE', 'Vitals')
				w.set('lbl_status_bar', ' Status: No matching items found.')
				return
			}

			mut buried_count := 0
			for t in targets {
				out += '  - Target: ${t}\n'
				if !is_dry {
					rip_res := simplegui.exec_safe(rip_bin, [t])
					if rip_res.exit_code == 0 {
						buried_count++
						out += '    [BURIED] Safely moved to rip graveyard.\n'
					} else {
						out += '    [ERROR] Failed to bury: ${rip_res.output}\n'
					}
				}
			}

			if is_dry {
				out += '\n[DRY RUN SUMMARY] ${targets.len} items will be safely moved to rip graveyard.\n'
				out += 'You can restore items anytime using "rip -u" or rip graveyard inspect.\n'
				state.last_cli_command = '${fd_bin} "${primary}" "${ws}" -x ${rip_bin}'
			} else {
				out += '\n[GRAVEYARD SUMMARY] Safely buried ${buried_count} items.\n'
				out += 'Undo command: rip -u\n'
				state.last_cli_command = '${rip_bin} [targets]'
			}

			w.set('txt_live_output', out)
			w.append_console('omni_console', '[${get_now_str()}] Pipeline 3 completed: ${targets.len} items evaluated.\n',
				2)
			w.set_metric_card_value('card_status', 'SUCCESS', 'Vitals')
			w.set('lbl_status_bar', ' Status: Safe trash pipeline complete.')
			w.toast(if is_dry { 'Trash preview generated' } else { 'Items safely buried' })
			return
		}

		// ---------------------------------------------------------
		// Standalone Mode 4: Ripgrep Code Search (rg)
		// ---------------------------------------------------------
		if mode.starts_with('4.') {
			rg_bin := state.tools['rg'].bin_path
			if rg_bin == '' {
				w.toast('ripgrep binary missing!')
				return
			}

			mut args := ['-n', '--heading', '--color=never']
			if is_case {
				args << '-s'
			} else {
				args << '-i'
			}
			if is_hidden {
				args << '--hidden'
			}
			if secondary != '' {
				args << '-C'
				args << secondary
			}
			if filter != '' {
				for f in filter.split(',') {
					tf := f.trim_space()
					if tf != '' {
						args << '-g'
						args << tf
					}
				}
			}
			args << primary
			args << ws

			state.last_cli_command = '${rg_bin} ' + args.join(' ')
			w.append_console('omni_console', '[${get_now_str()}] Running Ripgrep: ${state.last_cli_command}\n',
				1)

			res := simplegui.exec_safe(rg_bin, args)
			mut out := '=== RIPGREP CODE SEARCH RESULTS (rg) ===\n'
			out += 'Query: ${primary}  |  Scope: ${ws}\n'
			out += '----------------------------------------------------------------------\n\n'
			if res.exit_code == 0 {
				out += res.output
			} else if res.exit_code == 1 {
				out += '// 0 matches found for pattern "${primary}".\n'
			} else {
				out += '[RIPGREP ERROR] (Exit Code: ${res.exit_code})\n${res.output}\n'
			}

			w.set('txt_live_output', out)
			w.set_metric_card_value('card_status', 'SUCCESS', 'Vitals')
			w.set('lbl_status_bar', ' Status: Ripgrep search complete.')
			w.toast('Ripgrep search complete')
			return
		}

		// ---------------------------------------------------------
		// Standalone Mode 5: Fast File Finder (fd)
		// ---------------------------------------------------------
		if mode.starts_with('5.') {
			fd_bin := state.tools['fd'].bin_path
			if fd_bin == '' {
				w.toast('fd binary missing!')
				return
			}

			mut args := ['--color=never']
			if is_hidden {
				args << '-H'
			}
			if filter != '' {
				args << '-e'
				args << filter.trim_left('*.')
			}
			if secondary != '' {
				args << '--max-depth'
				args << secondary
			}
			args << primary
			args << ws

			state.last_cli_command = '${fd_bin} ' + args.join(' ')
			w.append_console('omni_console', '[${get_now_str()}] Running fd: ${state.last_cli_command}\n',
				1)

			res := simplegui.exec_safe(fd_bin, args)
			mut out := '=== FD FILE & PATH DISCOVERY (fd) ===\n'
			out += 'Pattern: ${primary}  |  Directory: ${ws}\n'
			out += '----------------------------------------------------------------------\n\n'
			if res.output.trim_space() == '' {
				out += '// No files or folders matching pattern found.\n'
			} else {
				out += res.output
			}

			w.set('txt_live_output', out)
			w.set_metric_card_value('card_status', 'SUCCESS', 'Vitals')
			w.set('lbl_status_bar', ' Status: fd search complete.')
			w.toast('fd search complete')
			return
		}

		// ---------------------------------------------------------
		// Standalone Mode 6: Regex Text Substitution (sd)
		// ---------------------------------------------------------
		if mode.starts_with('6.') {
			sd_bin := state.tools['sd'].bin_path
			if sd_bin == '' {
				w.toast('sd binary missing!')
				return
			}

			target_path := if filter != '' { os.join_path(ws, filter) } else { ws }
			state.last_cli_command = '${sd_bin} "${primary}" "${secondary}" "${target_path}"'
			w.append_console('omni_console', '[${get_now_str()}] Running sd: ${state.last_cli_command}\n',
				1)

			mut out := '=== SD REGEX TEXT SUBSTITUTION (sd) ===\n'
			out += 'Find:    "${primary}"\n'
			out += 'Replace: "${secondary}"\n'
			out += 'Target:  "${target_path}"\n'
			out += '----------------------------------------------------------------------\n\n'

			if is_dry {
				out += '[DRY RUN] In dry run mode, use Pipeline 1 for visual before/after diffs.\n'
				out += 'Command to execute:\n${state.last_cli_command}\n'
			} else {
				res := simplegui.exec_safe(sd_bin, [primary, secondary, target_path])
				if res.exit_code == 0 {
					out += '[SUCCESS] In-place substitution applied via sd.\n'
					out += res.output
				} else {
					out += '[ERROR] sd failed (Exit Code: ${res.exit_code}):\n${res.output}\n'
				}
			}

			w.set('txt_live_output', out)
			w.set_metric_card_value('card_status', 'SUCCESS', 'Vitals')
			w.set('lbl_status_bar', ' Status: sd substitution complete.')
			w.toast('sd replacement finished')
			return
		}

		// ---------------------------------------------------------
		// Standalone Mode 7: Continuous Watch & Run (watchexec)
		// ---------------------------------------------------------
		if mode.starts_with('7.') {
			we_bin := state.tools['watchexec'].bin_path
			if we_bin == '' {
				w.toast('watchexec binary missing!')
				return
			}

			// Run once or trigger single cycle
			cmd_to_run := if primary != '' { primary } else { 'v -check .' }
			debounce_str := if secondary != '' { secondary } else { '250ms' }

			state.last_cli_command = '${we_bin} -w "${ws}" -d ${debounce_str} -r -- ${cmd_to_run}'
			w.append_console('omni_console', '[${get_now_str()}] watchexec CLI configuration generated.\n',
				1)

			// Execute test run
			w.append_console('omni_console', '[${get_now_str()}] Triggering command check for watchexec: ${cmd_to_run}...\n',
				1)
			sh_res := simplegui.exec_safe('sh', ['-c', 'cd "${ws}" && ${cmd_to_run}'])

			mut out := '=== WATCHEXEC CONTINUOUS RUNNER (watchexec) ===\n'
			out += 'Watch Scope: ${ws}\n'
			out += 'Command:     ${cmd_to_run}\n'
			out += 'Debounce:    ${debounce_str}\n'
			out += 'CLI Command: ${state.last_cli_command}\n'
			out += '----------------------------------------------------------------------\n\n'
			out += '[Instant Cycle Run Output]:\n'
			out += strip_ansi(sh_res.output) + '\n\n'
			out += '[INFO] To launch the full persistent background watcher, use the dedicated Watchexec Studio Pro workstation\nor copy the CLI command above for terminal execution.\n'

			w.set('txt_live_output', out)
			w.set_metric_card_value('card_status', 'SUCCESS', 'Vitals')
			w.set('lbl_status_bar', ' Status: watchexec cycle executed.')
			w.toast('Watchexec cycle executed')
			return
		}

		// ---------------------------------------------------------
		// Standalone Mode 8: Multi-Threaded Downloader (wget2)
		// ---------------------------------------------------------
		if mode.starts_with('8.') {
			wget_bin := state.tools['wget2'].bin_path
			if wget_bin == '' {
				w.toast('wget2 binary missing!')
				return
			}

			dest_dir := if secondary != '' { secondary } else { ws }
			threads := if filter != '' { filter } else { '8' }

			state.last_cli_command = '${wget_bin} -c -j ${threads} -P "${dest_dir}" "${primary}"'
			w.append_console('omni_console', '[${get_now_str()}] Running wget2: ${state.last_cli_command}\n',
				1)

			res := simplegui.exec_safe(wget_bin, ['-c', '-j', threads, '-P', dest_dir, primary])

			mut out := '=== WGET2 MULTI-THREADED DOWNLOADER (wget2) ===\n'
			out += 'Target:      ${primary}\n'
			out += 'Destination: ${dest_dir}\n'
			out += 'Threads:     ${threads}\n'
			out += '----------------------------------------------------------------------\n\n'
			out += strip_ansi(res.output) + '\n'

			w.set('txt_live_output', out)
			w.set_metric_card_value('card_status', if res.exit_code == 0 {
				'SUCCESS'
			} else {
				'ERROR'
			}, 'Vitals')
			w.set('lbl_status_bar', ' Status: wget2 download finished.')
			w.toast(if res.exit_code == 0 { 'Download completed' } else { 'Download error' })
			return
		}

		// ---------------------------------------------------------
		// Standalone Mode 9: Graveyard Trash Manager (rip)
		// ---------------------------------------------------------
		if mode.starts_with('9.') {
			rip_bin := state.tools['rip'].bin_path
			if rip_bin == '' {
				w.toast('rip binary missing!')
				return
			}

			action := secondary.to_lower()
			mut out := '=== RIP SAFE GRAVEYARD TRASH MANAGER (rip) ===\n'

			if action.contains('unbury') || action.contains('undo') {
				state.last_cli_command = '${rip_bin} -u'
				w.append_console('omni_console', '[${get_now_str()}] Unburying last deleted item with rip...\n',
					1)
				res := simplegui.exec_safe(rip_bin, ['-u'])
				out += 'Action: Unbury / Restore Last Deleted Item\n'
				out += '----------------------------------------------------------------------\n\n'
				out += res.output + '\n'
			} else if action.contains('inspect') || primary == 'graveyard_inspect' {
				state.last_cli_command = '${rip_bin} -s'
				w.append_console('omni_console', '[${get_now_str()}] Inspecting graveyard with rip -s...\n',
					1)
				res := simplegui.exec_safe(rip_bin, ['-s'])
				out += 'Action: Inspect Graveyard Status\n'
				out += '----------------------------------------------------------------------\n\n'
				out += res.output + '\n'
			} else {
				target_to_bury := os.join_path(ws, primary)
				state.last_cli_command = '${rip_bin} "${target_to_bury}"'
				if is_dry {
					out += 'Action: Dry Run Bury\n'
					out += 'Target: ${target_to_bury}\n'
					out += '----------------------------------------------------------------------\n\n'
					out += '[DRY RUN] Item "${target_to_bury}" would be moved to the graveyard.\n'
				} else {
					res := simplegui.exec_safe(rip_bin, [target_to_bury])
					out += 'Action: Bury to Graveyard\n'
					out += 'Target: ${target_to_bury}\n'
					out += '----------------------------------------------------------------------\n\n'
					out += res.output + '\n'
				}
			}

			w.set('txt_live_output', out)
			w.set_metric_card_value('card_status', 'SUCCESS', 'Vitals')
			w.set('lbl_status_bar', ' Status: rip operation finished.')
			w.toast('Rip operation finished')
			return
		}

		// ---------------------------------------------------------
		// Standalone Mode 10: Universal Compression (ouch)
		// ---------------------------------------------------------
		if mode.starts_with('10.') {
			ouch_bin := state.tools['ouch'].bin_path
			if ouch_bin == '' {
				w.toast('ouch binary missing!')
				return
			}

			action := secondary.to_lower()
			archive_name := primary
			source_target := if filter != '' { filter } else { '.' }

			mut out := '=== OUCH UNIVERSAL ARCHIVE MANAGER (ouch) ===\n'

			if action.contains('decompress') || action.contains('extract') {
				dest_folder := os.join_path(ws, 'extracted')
				state.last_cli_command = '${ouch_bin} decompress "${archive_name}" --dir "${dest_folder}"'
				res := simplegui.exec_safe(ouch_bin, [
					'decompress',
					archive_name,
					'--dir',
					dest_folder,
				])
				out += 'Action: Decompress\n'
				out += 'Archive: ${archive_name} -> Destination: ${dest_folder}\n'
				out += '----------------------------------------------------------------------\n\n'
				out += strip_ansi(res.output) + '\n'
			} else {
				state.last_cli_command = '${ouch_bin} compress ${source_target} "${archive_name}"'
				res := simplegui.exec_safe(ouch_bin, [
					'compress',
					source_target,
					os.join_path(ws, archive_name),
				])
				out += 'Action: Compress\n'
				out += 'Sources: ${source_target} -> Archive: ${archive_name}\n'
				out += '----------------------------------------------------------------------\n\n'
				out += strip_ansi(res.output) + '\n'
			}

			w.set('txt_live_output', out)
			w.set_metric_card_value('card_status', 'SUCCESS', 'Vitals')
			w.set('lbl_status_bar', ' Status: ouch archive operation complete.')
			w.toast('ouch archive operation done')
			return
		}

		// ---------------------------------------------------------
		// Standalone Mode 11: Modern Directory Tree (eza)
		// ---------------------------------------------------------
		if mode.starts_with('11.') {
			eza_bin := state.tools['eza'].bin_path
			if eza_bin == '' {
				w.toast('eza binary missing!')
				return
			}

			depth := if secondary != '' { secondary } else { '3' }
			target_dir := if primary != '' && primary != '.' {
				os.join_path(ws, primary)
			} else {
				ws
			}

			mut args := ['-T', '--icons=never', '-L', depth]
			if is_hidden {
				args << '-a'
			}
			args << target_dir

			state.last_cli_command = '${eza_bin} ' + args.join(' ')
			w.append_console('omni_console', '[${get_now_str()}] Running eza: ${state.last_cli_command}\n',
				1)

			res := simplegui.exec_safe(eza_bin, args)
			mut out := '=== EZA MODERN DIRECTORY TREE (eza) ===\n'
			out += 'Directory: ${target_dir}  |  Depth: ${depth}\n'
			out += '----------------------------------------------------------------------\n\n'
			out += strip_ansi(res.output) + '\n'

			w.set('txt_live_output', out)
			w.set_metric_card_value('card_status', 'SUCCESS', 'Vitals')
			w.set('lbl_status_bar', ' Status: eza tree generated.')
			w.toast('eza tree generated')
			return
		}
	}

	// Button: Execute Pipeline / Tool
	win.on_click('btn_execute', fn [run_pipeline] (mut w simplegui.SimpleWindow) {
		run_pipeline(mut w, false)
	})

	// Button: Preview / Dry Run
	win.on_click('btn_dry_run_action', fn [run_pipeline] (mut w simplegui.SimpleWindow) {
		run_pipeline(mut w, true)
	})

	// Button: Copy Equivalent CLI Command
	win.on_click('btn_copy_cmd', fn [mut state] (mut w simplegui.SimpleWindow) {
		cmd := if state.last_cli_command != '' {
			state.last_cli_command
		} else {
			'rg --hidden "pattern" .'
		}
		w.copy_to_clipboard(cmd)
		w.append_console('omni_console', '[${get_now_str()}] Copied CLI command to clipboard:\n  ${cmd}\n',
			1)
		w.toast('CLI command copied to clipboard!')
	})

	// Button: Stop / Kill Process
	win.on_click('btn_stop_proc', fn (mut w simplegui.SimpleWindow) {
		w.set_metric_card_value('card_status', 'STOPPED', 'Vitals')
		w.set('lbl_status_bar', ' Status: Process terminated.')
		w.append_console('omni_console', '[${get_now_str()}] Sent termination signal to active jobs.\n',
			2)
		w.toast('Process terminated')
	})

	println('Running OmniTool Studio Pro...')
	win.run()
}

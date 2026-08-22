module main

import simplegui
import os
import time

// -----------------------------------------------------------------------------
// Process Item Data Structure
// -----------------------------------------------------------------------------
struct ProcessItem {
	pid      string
	cpu_pct  f64
	mem_pct  f64
	rss_kb   u64
	state    string
	user     string
	comm     string
	full_cmd string
}

// Fetch live processes using POSIX ps
fn get_all_processes() []ProcessItem {
	res := simplegui.exec_safe('ps', ['-axo', 'pid,pcpu,pmem,rss,state,user,command'])
	if res.exit_code != 0 {
		return []
	}

	lines := res.output.split_into_lines()
	if lines.len <= 1 {
		return []
	}

	mut items := []ProcessItem{cap: lines.len}
	// Skip header line
	for i in 1 .. lines.len {
		line := lines[i].trim_space()
		if line == '' {
			continue
		}

		// Split by spaces up to 7 tokens
		tokens := line.split(' ').filter(it.trim_space() != '')
		if tokens.len >= 7 {
			pid := tokens[0]
			cpu := tokens[1].f64()
			mem := tokens[2].f64()
			rss := tokens[3].u64()
			state := tokens[4]
			user := tokens[5]
			full_cmd := tokens[6..].join(' ')
			
			// Extract clean short executable name
			raw_bin := tokens[6]
			comm := os.file_name(raw_bin)

			items << ProcessItem{
				pid: pid
				cpu_pct: cpu
				mem_pct: mem
				rss_kb: rss
				state: state
				user: user
				comm: if comm != '' { comm } else { raw_bin }
				full_cmd: full_cmd
			}
		}
	}
	return items
}

fn format_rss_mb(rss_kb u64) string {
	mb := f64(rss_kb) / 1024.0
	if mb >= 1024.0 {
		gb := mb / 1024.0
		return '${gb:.2f} GB'
	}
	return '${mb:.1f} MB'
}

fn main() {
	println('Starting SimpleGUI - Task Manager Pro (macOS Process & Hardware Monitor)...')

	mut win := simplegui.new_simple_window('Task Manager Pro -- macOS Process & Hardware Monitor', 1140, 920)
	win.set_fullscreen(true)
	win.restore_saved_theme()
	win.set_spacing(8)
	win.set_padding(16)

	// -------------------------------------------------------------
	// Header & Theme Selector
	// -------------------------------------------------------------
	win.begin_row('row_header')
	win.add_heading('Task Manager Pro')
	win.add_label('lbl_theme_hdr', 'Theme:')
	saved_theme := simplegui.get_saved_theme()
	win.add_dropdown('dd_theme_selector', simplegui.list_themes(), saved_theme)
	win.set_control_width('dd_theme_selector', 160)
	win.end_row()

	// -------------------------------------------------------------
	// Hardware & System Telemetry Cards
	// -------------------------------------------------------------
	win.begin_group_box('grp_telemetry', 'Hardware Telemetry & System Vitals')

	cpu_model := win.get_cpu_info()
	cores := win.get_cpu_cores()
	arch := win.get_cpu_architecture()
	mem_info := win.get_memory_info()

	initial_procs := get_all_processes()
	mut initial_rows := [][]string{cap: initial_procs.len}
	for p in initial_procs {
		initial_rows << [
			p.pid,
			p.comm,
			'${p.cpu_pct:.1f}%',
			format_rss_mb(p.rss_kb),
			p.state,
			p.user,
			p.full_cmd
		]
	}

	win.begin_row('row_sys_cards')
	win.add_metric_card('card_cpu', 'CPU Cores', '${cores} Cores (${arch})', cpu_model, 'Hardware')
	win.add_metric_card('card_ram', 'Total Memory', mem_info, 'Apple Unified Memory', 'RAM')
	win.add_metric_card('card_tasks', 'Active Tasks', '${initial_procs.len} Running', 'System Procs', 'Tasks')
	l1, l5, l15 := win.get_load_average()
	win.add_metric_card('card_load', 'Load Average', '${l1:.2f}, ${l5:.2f}, ${l15:.2f}', '1m, 5m, 15m', 'Vitals')
	win.end_row()
	win.end_group_box()

	// -------------------------------------------------------------
	// Process Filters & Search Bar
	// -------------------------------------------------------------
	win.begin_group_box('grp_controls', 'Process Filtering, Sorting & Search Scope')

	win.begin_row('row_filters')
	win.add_label('lbl_search', 'Search Process / PID:')
	win.add_input('txt_search', '')
	win.set_control_width('txt_search', 220)

	win.add_label('lbl_filter', 'Filter Scope:')
	win.add_dropdown('dd_filter', [
		'All Processes',
		'GUI Applications (.app)',
		'High CPU (> 2.0%)',
		'High Memory (> 100 MB)',
		'My User Processes',
		'System Daemons (root)'
	], 'All Processes')
	win.set_control_width('dd_filter', 180)

	win.add_label('lbl_sort', 'Sort By:')
	win.add_dropdown('dd_sort', [
		'CPU % (Highest First)',
		'Memory (Highest First)',
		'PID (Ascending)',
		'Process Name (A-Z)'
	], 'CPU % (Highest First)')
	win.set_control_width('dd_sort', 180)

	win.add_button('btn_refresh', 'Refresh')
	win.add_button('btn_act_mon', 'Activity Monitor')
	win.end_row()
	win.end_group_box()

	// -------------------------------------------------------------
	// Live Process Data Grid Table
	// -------------------------------------------------------------
	win.begin_group_box('grp_table', 'Live Process Tree & Resource Consumption')
	table_cols := ['PID', 'Process Name', 'CPU %', 'Memory (RSS)', 'State', 'User', 'Command Path']
	win.add_table('tbl_processes', table_cols, initial_rows)
	win.set_control_height('tbl_processes', 340)
	win.end_group_box()

	// -------------------------------------------------------------
	// Process Management Toolbar
	// -------------------------------------------------------------
	win.begin_row('row_actions_1')
	win.add_button('btn_force_kill', 'Force Kill (SIGKILL -9)')
	win.add_button('btn_terminate', 'Terminate (SIGTERM -15)')
	win.add_button('btn_pause', 'Suspend (SIGSTOP)')
	win.add_button('btn_resume', 'Resume (SIGCONT)')
	win.end_row()

	win.begin_row('row_actions_2')
	win.add_button('btn_inspect_ports', 'Inspect Open Ports & Files')
	win.add_button('btn_reveal_app', 'Reveal in Finder')
	win.add_button('btn_copy_pid', 'Copy PID')
	win.end_row()

	// -------------------------------------------------------------
	// Inspection & Details Console
	// -------------------------------------------------------------
	win.begin_group_box('grp_details', 'Selected Process Diagnostic Details & Open Sockets')
	win.add_textarea('txt_details', 'Select any process above to view diagnostic details, open ports, and command paths.\n')
	win.set_control_height('txt_details', 130)
	win.end_group_box()

	win.begin_row('row_status_bar')
	win.add_label('lbl_status', 'Status: Live  |  Processes: 0  |  Last Refreshed: Just now')
	win.end_row()

	// Helper to refresh and filter process table
	refresh_processes := fn (mut win simplegui.SimpleWindow) {
		search_query := win.get('txt_search').trim_space().to_lower()
		filter_scope := win.get('dd_filter')
		sort_mode := win.get('dd_sort')
		current_user := os.getenv('USER')

		mut procs := get_all_processes()

		// Filter
		mut filtered := []ProcessItem{cap: procs.len}
		for p in procs {
			// Search filter
			if search_query != '' {
				if !p.comm.to_lower().contains(search_query) && !p.pid.contains(search_query) && !p.full_cmd.to_lower().contains(search_query) {
					continue
				}
			}

			// Scope filter
			if filter_scope.contains('GUI Applications') {
				if !p.full_cmd.contains('.app/') && !p.full_cmd.contains('/Applications/') {
					continue
				}
			} else if filter_scope.contains('High CPU') {
				if p.cpu_pct < 2.0 {
					continue
				}
			} else if filter_scope.contains('High Memory') {
				if (f64(p.rss_kb) / 1024.0) < 100.0 {
					continue
				}
			} else if filter_scope.contains('My User') {
				if p.user != current_user {
					continue
				}
			} else if filter_scope.contains('System Daemons') {
				if p.user != 'root' && !p.user.starts_with('_') {
					continue
				}
			}

			filtered << p
		}

		// Sort
		if sort_mode.contains('CPU %') {
			filtered.sort(a.cpu_pct > b.cpu_pct)
		} else if sort_mode.contains('Memory') {
			filtered.sort(a.rss_kb > b.rss_kb)
		} else if sort_mode.contains('PID') {
			filtered.sort(a.pid.int() < b.pid.int())
		} else if sort_mode.contains('Process Name') {
			filtered.sort(a.comm.to_lower() < b.comm.to_lower())
		}

		// Build table rows
		mut rows := [][]string{cap: filtered.len}
		mut total_cpu := 0.0
		for p in filtered {
			total_cpu += p.cpu_pct
			rows << [
				p.pid,
				p.comm,
				'${p.cpu_pct:.1f}%',
				format_rss_mb(p.rss_kb),
				p.state,
				p.user,
				p.full_cmd
			]
		}

		win.set_table_rows('tbl_processes', rows)

		// Update telemetry cards
		l1, l5, l15 := win.get_load_average()
		win.set_stat_card('card_tasks', ' Active Tasks', '${filtered.len} / ${procs.len} Total', '${total_cpu:.1f}% Total CPU', true)
		win.set_stat_card('card_load', ' Load Average', '${l1:.2f}, ${l5:.2f}, ${l15:.2f}', '1m, 5m, 15m Load', true)

		now := time.now().format_ss()
		win.set('lbl_status', ' Status: Live  |  Processes Listed: ${filtered.len} (${procs.len} Total)  |  Last Refreshed: ${now}')
	}

	// -------------------------------------------------------------
	// Event Handlers
	// -------------------------------------------------------------

	// Theme Switching
	win.on_change('dd_theme_selector', fn (mut w simplegui.SimpleWindow, selected string) {
		w.set_theme(selected)
		w.toast('Theme changed to ${selected}')
	})

	// Refresh Button
	win.on_click('btn_refresh', fn [refresh_processes] (mut w simplegui.SimpleWindow) {
		refresh_processes(mut w)
		w.toast('Process list updated.')
	})

	// Filter / Sort changes
	win.on_change('dd_filter', fn [refresh_processes] (mut w simplegui.SimpleWindow, _ string) {
		refresh_processes(mut w)
	})
	win.on_change('dd_sort', fn [refresh_processes] (mut w simplegui.SimpleWindow, _ string) {
		refresh_processes(mut w)
	})

	// Search on text change
	win.on_change('txt_search', fn [refresh_processes] (mut w simplegui.SimpleWindow, _ string) {
		refresh_processes(mut w)
	})

	// Open Activity Monitor
	win.on_click('btn_act_mon', fn (mut w simplegui.SimpleWindow) {
		simplegui.exec_safe('open', ['-a', 'Activity Monitor'])
		w.toast('Opened macOS Activity Monitor.')
	})

	// Helper to get selected PID
	get_selected_pid_and_name := fn (mut win simplegui.SimpleWindow) (string, string, string) {
		row_idx := win.get_table_selected_row('tbl_processes')
		rows := win.get_table_rows('tbl_processes')
		if row_idx >= 0 && row_idx < rows.len && rows[row_idx].len >= 7 {
			return rows[row_idx][0], rows[row_idx][1], rows[row_idx][6]
		}
		return '', '', ''
	}

	// Force Kill (SIGKILL -9)
	win.on_click('btn_force_kill', fn [get_selected_pid_and_name, refresh_processes] (mut w simplegui.SimpleWindow) {
		pid, name, _ := get_selected_pid_and_name(mut w)
		if pid == '' {
			w.alert('No Process Selected', 'Please click on a process in the table first.')
			return
		}
		if pid == '1' || pid == '0' {
			w.alert('Protected Process', 'Cannot terminate critical macOS root system process (PID ${pid}).')
			return
		}

		if w.confirm('Force Kill Process', 'Are you sure you want to forcibly terminate "${name}" (PID ${pid}) with SIGKILL (-9)?') {
			res := simplegui.exec_safe('kill', ['-9', pid])
			if res.exit_code == 0 {
				w.toast('Forcibly killed ${name} (PID ${pid}).')
				refresh_processes(mut w)
			} else {
				w.alert('Kill Error', 'Failed to kill process PID ${pid}:\n${res.output}')
			}
		}
	})

	// Terminate (SIGTERM -15)
	win.on_click('btn_terminate', fn [get_selected_pid_and_name, refresh_processes] (mut w simplegui.SimpleWindow) {
		pid, name, _ := get_selected_pid_and_name(mut w)
		if pid == '' {
			w.alert('No Process Selected', 'Please click on a process in the table first.')
			return
		}

		res := simplegui.exec_safe('kill', ['-15', pid])
		if res.exit_code == 0 {
			w.toast('Sent SIGTERM to ${name} (PID ${pid}).')
			refresh_processes(mut w)
		} else {
			w.alert('Terminate Error', 'Failed to terminate PID ${pid}:\n${res.output}')
		}
	})

	// Suspend / Pause (SIGSTOP)
	win.on_click('btn_pause', fn [get_selected_pid_and_name, refresh_processes] (mut w simplegui.SimpleWindow) {
		pid, name, _ := get_selected_pid_and_name(mut w)
		if pid == '' {
			w.alert('No Process Selected', 'Please click on a process in the table first.')
			return
		}

		res := simplegui.exec_safe('kill', ['-STOP', pid])
		if res.exit_code == 0 {
			w.toast('Suspended ${name} (PID ${pid}).')
			refresh_processes(mut w)
		} else {
			w.alert('Suspend Error', 'Failed to suspend PID ${pid}:\n${res.output}')
		}
	})

	// Resume / Continue (SIGCONT)
	win.on_click('btn_resume', fn [get_selected_pid_and_name, refresh_processes] (mut w simplegui.SimpleWindow) {
		pid, name, _ := get_selected_pid_and_name(mut w)
		if pid == '' {
			w.alert('No Process Selected', 'Please click on a process in the table first.')
			return
		}

		res := simplegui.exec_safe('kill', ['-CONT', pid])
		if res.exit_code == 0 {
			w.toast('Resumed ${name} (PID ${pid}).')
			refresh_processes(mut w)
		} else {
			w.alert('Resume Error', 'Failed to resume PID ${pid}:\n${res.output}')
		}
	})

	// Inspect Open Ports & Sockets (lsof -p PID)
	win.on_click('btn_inspect_ports', fn [get_selected_pid_and_name] (mut w simplegui.SimpleWindow) {
		pid, name, path := get_selected_pid_and_name(mut w)
		if pid == '' {
			w.alert('No Process Selected', 'Please click on a process in the table first.')
			return
		}

		w.set_status('Inspecting process PID ${pid} (${name})...')
		w.toast('Inspecting PID ${pid}...')

		go fn [mut w, pid, name, path] () {
			res := simplegui.exec_safe('lsof', ['-nP', '-p', pid])
			
			mut details_text := ' Process: ${name} (PID: ${pid})\n'
			details_text += ' Executable: ${path}\n'
			details_text += '-----------------------------------------------------------------------------\n'
			if res.exit_code == 0 && res.output.trim_space() != '' {
				details_text += ' Open Network Sockets & File Descriptors:\n' + res.output
			} else {
				details_text += 'Tip: No network sockets or restricted descriptor access (requires sudo for root processes).'
			}

			w.run_on_main_thread(fn [details_text] (mut win_main simplegui.SimpleWindow) {
				win_main.set('txt_details', details_text)
				win_main.set_status('Inspection completed.')
			})
		}()
	})

	// Reveal in Finder
	win.on_click('btn_reveal_app', fn [get_selected_pid_and_name] (mut w simplegui.SimpleWindow) {
		_, _, path := get_selected_pid_and_name(mut w)
		if path == '' {
			w.alert('No Process Selected', 'Please select a process to reveal.')
			return
		}

		// Extract first executable token
		raw_exe := path.split(' ')[0].trim_space()
		if os.exists(raw_exe) {
			simplegui.reveal_in_finder(raw_exe)
			w.toast('Revealed in Finder.')
		} else {
			w.toast('Executable path not on disk or virtual: ' + raw_exe)
		}
	})

	// Copy PID
	win.on_click('btn_copy_pid', fn [get_selected_pid_and_name] (mut w simplegui.SimpleWindow) {
		pid, name, _ := get_selected_pid_and_name(mut w)
		if pid != '' {
			w.copy_to_clipboard(pid)
			w.toast('Copied PID ${pid} (${name}) to clipboard!')
		} else {
			w.toast('No process selected.')
		}
	})

	println('Task Manager Pro configured. Starting event loop...')
	win.run()
}

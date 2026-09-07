module main

import os
import time
import simplegui

// -----------------------------------------------------------------------------
// Application State & Telemetry Structs
// -----------------------------------------------------------------------------
struct WatcherState {
mut:
	is_watching     bool
	process_pid     int
	total_triggers  int
	last_trigger_ts string
	watchexec_bin   string
	active_command  string
	active_dir      string
	output_buffer   string
	should_stop     bool
}

// -----------------------------------------------------------------------------
// Binary Resolution Helper
// -----------------------------------------------------------------------------
fn find_watchexec() string {
	if path := os.find_abs_path_of_executable('watchexec') {
		return path
	}
	for p in [
		'/opt/homebrew/bin/watchexec',
		'/usr/local/bin/watchexec',
		'/usr/bin/watchexec',
	] {
		if os.exists(p) {
			return p
		}
	}
	return ''
}

fn get_watchexec_version(bin string) string {
	if bin == '' {
		return 'Not Installed'
	}
	res := simplegui.exec_safe(bin, ['--version'])
	if res.exit_code == 0 {
		lines := res.output.trim_space().split_into_lines()
		if lines.len > 0 {
			return lines[0].trim_space()
		}
	}
	return 'watchexec (Installed)'
}

// Helper to build the equivalent CLI string for clipboard copying
fn build_watchexec_cli(w &simplegui.SimpleWindow, bin string) string {
	watch_dir := w.get('txt_watch_dir').trim_space()
	exts := w.get('txt_extensions').trim_space()
	filters := w.get('txt_filters').trim_space()
	ignores := w.get('txt_ignores').trim_space()
	cmd := w.get('txt_command').trim_space()
	debounce := w.get('dd_debounce').split(' ')[0].trim_space()
	signal_str := w.get('dd_signal').split(' ')[0].trim_space()

	is_restart := w.get('chk_restart') == 'true'
	is_clear := w.get('chk_clear') == 'true'
	is_timings := w.get('chk_timings') == 'true'
	is_events := w.get('chk_print_events') == 'true'
	is_vcs := w.get('chk_vcs_ignore') == 'true'
	is_rec := w.get('chk_recursive') == 'true'

	exe_name := if bin != '' { os.file_name(bin) } else { 'watchexec' }
	mut parts := [exe_name]

	if is_rec {
		parts << '-w "${watch_dir}"'
	} else {
		parts << '-W "${watch_dir}"'
	}

	if exts != '' && exts != '*' {
		parts << '-e ${exts}'
	}

	if debounce != '' {
		parts << '-d ${debounce}'
	}

	if signal_str != '' && signal_str != 'SIGTERM' {
		parts << '-s ${signal_str}'
	}

	if is_restart {
		parts << '-r'
	}
	if is_clear {
		parts << '-c'
	}
	if is_timings {
		parts << '--timings'
	}
	if is_events {
		parts << '--print-events'
	}
	if !is_vcs {
		parts << '--no-vcs-ignore'
	}

	if filters != '' {
		for f in filters.split(',') {
			tf := f.trim_space()
			if tf != '' {
				parts << '-f "${tf}"'
			}
		}
	}

	if ignores != '' {
		for ig in ignores.split(',') {
			tig := ig.trim_space()
			if tig != '' {
				parts << '-i "${tig}"'
			}
		}
	}

	parts << '-- ${cmd}'
	return parts.join(' ')
}

// -----------------------------------------------------------------------------
// Main Application Entry Point
// -----------------------------------------------------------------------------
fn main() {
	println('Starting SimpleGUI - Watchexec Studio Pro (Reactive Build & Watch Workstation)...')

	mut win := simplegui.new_simple_window('SimpleGUI - Watchexec Studio Pro', 1140, 940)
	win.set_fullscreen(true)
	win.restore_saved_theme()
	win.set_spacing(8)
	win.set_padding(14)

	bin_path := find_watchexec()
	ver_str := get_watchexec_version(bin_path)

	mut state := &WatcherState{
		is_watching: false
		process_pid: 0
		total_triggers: 0
		last_trigger_ts: 'None'
		watchexec_bin: bin_path
		active_command: 'v -check .'
		active_dir: os.getwd()
		output_buffer: ''
		should_stop: false
	}

	// -------------------------------------------------------------
	// Header & Theme Selection
	// -------------------------------------------------------------
	win.begin_row('row_top')
	win.add_heading('Watchexec Studio Pro')
	win.add_label('lbl_theme', 'Theme:')
	saved_theme := simplegui.get_saved_theme()
	win.add_dropdown('dd_app_theme', simplegui.list_themes(), saved_theme)
	win.set_control_width('dd_app_theme', 150)
	win.end_row()

	win.on_change('dd_app_theme', fn (mut w simplegui.SimpleWindow, selected string) {
		w.set_theme(selected)
		w.toast('Theme changed to ${selected}')
	})

	win.add_label('lbl_engine_info', 'Engine: ${ver_str}  |  Platform: ${simplegui.get_platform_label()} (FSEvents Subsystem)  |  Mode: Async Daemon')

	// -------------------------------------------------------------
	// Status & Telemetry Cards
	// -------------------------------------------------------------
	win.begin_row('row_telemetry_cards')
	win.add_metric_card('card_status', 'Watcher Status', 'STOPPED', 'Engine Idle', 'Status')
	win.add_metric_card('card_triggers', 'Total Events', '0 Triggers', 'Trigger Counter', 'Events')
	win.add_metric_card('card_last_event', 'Last Run Event', 'None', 'Timestamp', 'Activity')
	win.add_metric_card('card_pid', 'Daemon Process', 'Idle', 'OS Subprocess PID', 'Process')
	win.end_row()

	// -------------------------------------------------------------
	// Watch Scope & File Filter Configuration
	// -------------------------------------------------------------
	win.begin_group_box('grp_watch_scope', 'Target Watch Scope & File Filter Rules')

	// Row 1: Watch Target Directory
	win.begin_row('row_watch_dir')
	win.add_label('lbl_target_dir', 'Watch Directory:')
	win.add_input('txt_watch_dir', os.getwd())
	win.set_control_width('txt_watch_dir', 420)
	win.add_button('btn_browse_dir', 'Browse...')
	win.add_button('btn_curr_dir', 'Current (.)')
	win.add_button('btn_home_dir', 'Home (~)')
	win.end_row()

	// Row 2: Extensions & Debounce
	win.begin_row('row_filters_1')
	win.add_label('lbl_ext_preset', 'Language Preset:')
	win.add_dropdown('dd_ext_preset', [
		'1. V Lang (*.v)',
		'2. Rust / Cargo (*.rs, Cargo.toml)',
		'3. Go (*.go, go.mod)',
		'4. TypeScript / Node (*.ts, *.tsx, *.js, *.json)',
		'5. Python (*.py, pyproject.toml)',
		'6. C / C++ (*.c, *.h, *.cpp, *.hpp)',
		'7. Web Frontend (*.html, *.css, *.js, *.ts)',
		'8. Markdown & Docs (*.md, *.txt, *.yaml)',
		'9. Shell Scripts (*.sh, *.bash)',
		'10. All Files (*)',
	], '1. V Lang (*.v)')
	win.set_control_width('dd_ext_preset', 260)

	win.add_label('lbl_exts', 'Extensions (-e):')
	win.add_input('txt_extensions', 'v')
	win.set_control_width('txt_extensions', 130)

	win.add_label('lbl_debounce', 'Debounce (-d):')
	win.add_dropdown('dd_debounce', [
		'50ms (Ultra Fast)',
		'100ms (Responsive)',
		'250ms (Balanced / Recommended)',
		'500ms (Conservative)',
		'1000ms (1 Second)',
		'2000ms (2 Seconds)',
	], '250ms (Balanced / Recommended)')
	win.set_control_width('dd_debounce', 180)
	win.end_row()

	// Row 3: Filter Globs, Ignore Globs & Termination Signal
	win.begin_row('row_filters_2')
	win.add_label('lbl_filters', 'Filter Globs (-f):')
	win.add_input('txt_filters', '')
	win.set_control_width('txt_filters', 180)

	win.add_label('lbl_ignores', 'Ignore Globs (-i):')
	win.add_input('txt_ignores', 'target/*, node_modules/*, .git/*, *.tmp, *.log')
	win.set_control_width('txt_ignores', 260)

	win.add_label('lbl_signal', 'Signal (-s):')
	win.add_dropdown('dd_signal', [
		'SIGTERM (15 - Graceful Termination)',
		'SIGKILL (9 - Immediate Kill)',
		'SIGINT (2 - Interrupt / Ctrl+C)',
		'SIGHUP (1 - Hangup / Reload)',
	], 'SIGTERM (15 - Graceful Termination)')
	win.set_control_width('dd_signal', 200)
	win.end_row()

	// Row 4: Operational Toggles
	win.begin_row('row_toggles')
	win.add_checkbox('chk_restart', 'Restart on Change (-r)', true)
	win.add_checkbox('chk_clear', 'Clear Screen (-c)', true)
	win.add_checkbox('chk_timings', 'Timings (--timings)', true)
	win.add_checkbox('chk_print_events', 'Print Events (--print-events)', true)
	win.add_checkbox('chk_vcs_ignore', 'Respect .gitignore', true)
	win.add_checkbox('chk_recursive', 'Recursive Watch (-w)', true)
	win.end_row()

	win.end_group_box()

	// -------------------------------------------------------------
	// Reactive Command Configuration & Action Buttons
	// -------------------------------------------------------------
	win.begin_group_box('grp_command_exec', 'Reactive Command Execution & Actions')

	win.begin_row('row_cmd_preset')
	win.add_label('lbl_cmd_preset', 'Command Preset:')
	win.add_dropdown('dd_cmd_preset', [
		'1. v -check . (Fast Syntax & Type Check)',
		'2. v run . (Run V Application)',
		'3. v test . (Run Unit Tests)',
		'4. cargo check (Fast Rust Check)',
		'5. cargo test (Rust Test Runner)',
		'6. cargo run (Build & Run Rust)',
		'7. go test ./... (Run All Go Tests)',
		'8. go run . (Run Go Application)',
		'9. npm test (Run Test Suite)',
		'10. npm run build (Web App Build)',
		'11. pytest (Python Test Suite)',
		'12. make test (Run Makefile Target)',
		'13. git status -s (Show Dirty Status)',
	], '1. v -check . (Fast Syntax & Type Check)')
	win.set_control_width('dd_cmd_preset', 320)

	win.add_label('lbl_command', 'Execution Command:')
	win.add_input('txt_command', 'v -check .')
	win.set_control_width('txt_command', 360)
	win.end_row()

	win.begin_row('row_action_buttons')
	win.add_button('btn_start_watcher', 'Start Watcher (Async)')
	win.add_button('btn_stop_watcher', 'Stop Watcher')
	win.add_button('btn_run_once', 'Manual Trigger (Run Once)')
	win.add_button('btn_copy_cli', 'Copy watchexec CLI Command')
	win.add_button('btn_clear_output', 'Clear Output')
	win.end_row()

	win.end_group_box()

	// -------------------------------------------------------------
	// Live Command Output & Event Journal
	// -------------------------------------------------------------
	// Live Execution Output
	win.begin_group_box('grp_live_output', 'Live Execution Output Stream')
	win.add_textarea('txt_live_output', 'Watchexec Studio Pro Initialized.\nConfigure your watch directory and command above, then click "Start Watcher (Async)".\n')
	win.set_control_height('txt_live_output', 180)
	win.end_group_box()

	// Event Journal & Telemetry Console
	win.begin_group_box('grp_event_journal', 'Event Journal & Execution Telemetry')
	win.add_console('watchexec_console', 110)
	win.end_group_box()

	// Status Row
	win.begin_row('row_status_bar')
	win.add_label('lbl_status_bar', 'Status: Ready  |  Binary: ${bin_path}  |  Platform: macOS')
	win.end_row()

	// Console startup banner
	win.append_console('watchexec_console', ' Watchexec Studio Pro Initialized.\n', 1)
	if bin_path != '' {
		win.append_console('watchexec_console', ' Engine located: ${bin_path} (${ver_str})\n', 4)
	} else {
		win.append_console('watchexec_console', ' [WARNING] watchexec binary not found in PATH or Homebrew. Install with: brew install watchexec\n', 3)
	}

	// -------------------------------------------------------------
	// Event Callbacks & Handlers
	// -------------------------------------------------------------

	// Language / Extension Preset Selection Handler
	win.on_change('dd_ext_preset', fn (mut w simplegui.SimpleWindow, selected string) {
		if selected.starts_with('1.') {
			w.set('txt_extensions', 'v')
			w.set('txt_command', 'v -check .')
		} else if selected.starts_with('2.') {
			w.set('txt_extensions', 'rs,toml')
			w.set('txt_command', 'cargo check')
		} else if selected.starts_with('3.') {
			w.set('txt_extensions', 'go,mod')
			w.set('txt_command', 'go test ./...')
		} else if selected.starts_with('4.') {
			w.set('txt_extensions', 'ts,tsx,js,jsx,json,css,html')
			w.set('txt_command', 'npm test')
		} else if selected.starts_with('5.') {
			w.set('txt_extensions', 'py,toml')
			w.set('txt_command', 'pytest')
		} else if selected.starts_with('6.') {
			w.set('txt_extensions', 'c,h,cpp,hpp')
			w.set('txt_command', 'make test')
		} else if selected.starts_with('7.') {
			w.set('txt_extensions', 'html,css,js,ts')
			w.set('txt_command', 'npm run build')
		} else if selected.starts_with('8.') {
			w.set('txt_extensions', 'md,txt,yaml')
			w.set('txt_command', 'git status -s')
		} else if selected.starts_with('9.') {
			w.set('txt_extensions', 'sh,bash,zsh')
			w.set('txt_command', 'bash -n')
		} else if selected.starts_with('10.') {
			w.set('txt_extensions', '*')
		}
		w.toast('Applied extension preset: ' + selected.split('(')[0].trim_space())
	})

	// Command Preset Selection Handler
	win.on_change('dd_cmd_preset', fn (mut w simplegui.SimpleWindow, selected string) {
		if selected.starts_with('1.') {
			w.set('txt_command', 'v -check .')
		} else if selected.starts_with('2.') {
			w.set('txt_command', 'v run .')
		} else if selected.starts_with('3.') {
			w.set('txt_command', 'v test .')
		} else if selected.starts_with('4.') {
			w.set('txt_command', 'cargo check')
		} else if selected.starts_with('5.') {
			w.set('txt_command', 'cargo test')
		} else if selected.starts_with('6.') {
			w.set('txt_command', 'cargo run')
		} else if selected.starts_with('7.') {
			w.set('txt_command', 'go test ./...')
		} else if selected.starts_with('8.') {
			w.set('txt_command', 'go run .')
		} else if selected.starts_with('9.') {
			w.set('txt_command', 'npm test')
		} else if selected.starts_with('10.') {
			w.set('txt_command', 'npm run build')
		} else if selected.starts_with('11.') {
			w.set('txt_command', 'pytest')
		} else if selected.starts_with('12.') {
			w.set('txt_command', 'make test')
		} else if selected.starts_with('13.') {
			w.set('txt_command', 'git status -s')
		}
		w.toast('Selected command: ' + selected.split('(')[0].trim_space())
	})

	// Directory Shortcut Buttons
	win.on_click('btn_curr_dir', fn (mut w simplegui.SimpleWindow) {
		wd := os.getwd()
		w.set('txt_watch_dir', wd)
		w.toast('Set watch directory to current working folder.')
	})

	win.on_click('btn_home_dir', fn (mut w simplegui.SimpleWindow) {
		hd := os.home_dir()
		w.set('txt_watch_dir', hd)
		w.toast('Set watch directory to user home.')
	})

	win.on_click('btn_browse_dir', fn (mut w simplegui.SimpleWindow) {
		chosen := w.osascript_choose_folder()
		if chosen != '' {
			w.set('txt_watch_dir', chosen)
			w.toast('Selected directory: ' + os.file_name(chosen))
		}
	})

	// Copy Equivalent CLI Command
	win.on_click('btn_copy_cli', fn [bin_path] (mut w simplegui.SimpleWindow) {
		cli := build_watchexec_cli(&w, bin_path)
		w.copy_to_clipboard(cli)
		w.toast('Copied CLI command to clipboard!')
		w.append_console('watchexec_console', ' [CLIPBOARD] ${cli}\n', 4)
	})

	// Clear Output
	win.on_click('btn_clear_output', fn (mut w simplegui.SimpleWindow) {
		w.set('txt_live_output', '')
		w.clear_console('watchexec_console')
		w.toast('Cleared output console.')
	})

	// Manual Trigger (Run Once)
	win.on_click('btn_run_once', fn [mut state] (mut w simplegui.SimpleWindow) {
		cmd := w.get('txt_command').trim_space()
		watch_dir := w.get('txt_watch_dir').trim_space()

		if cmd == '' {
			w.alert('Command Required', 'Please enter a command to execute.')
			w.toast('Command required')
			return
		}

		target_dir := if watch_dir != '' && os.exists(watch_dir) { watch_dir } else { os.getwd() }

		w.toast('Executing command manually...')
		w.append_console('watchexec_console', ' [MANUAL RUN] Executing: "${cmd}" in ${target_dir}...\n', 4)

		go fn [mut w, mut state, cmd, target_dir] () {
			t0 := time.ticks()
			res := simplegui.exec_safe('sh', ['-c', 'cd "${target_dir}" && ${cmd} 2>&1'])
			elapsed_ms := time.ticks() - t0

			w.run_on_main_thread(fn [mut state, res, elapsed_ms, cmd, target_dir] (mut win_main simplegui.SimpleWindow) {
				state.total_triggers++
				state.last_trigger_ts = time.now().format_ss()

				win_main.set_metric_card_value('card_triggers', '${state.total_triggers} Triggers', 'Events')
				win_main.set_metric_card_value('card_last_event', '${state.last_trigger_ts} (${elapsed_ms}ms)', 'Activity')

				mut banner := '========================================================================\n'
				banner += ' MANUAL TRIGGER RESULT: ${cmd}\n'
				banner += ' Directory : ${target_dir}\n'
				banner += ' Duration  : ${elapsed_ms} ms  |  Exit Code: ${res.exit_code}\n'
				banner += '========================================================================\n\n'

				out_text := if res.output.trim_space() != '' { res.output.trim_space() } else { '(Command exited with code ${res.exit_code} and produced no output)' }
				win_main.set('txt_live_output', banner + out_text + '\n\n')

				if res.exit_code == 0 {
					win_main.append_console('watchexec_console', ' [SUCCESS] Manual run finished in ${elapsed_ms} ms (Code 0)\n', 1)
					win_main.toast('Command succeeded (${elapsed_ms} ms)')
				} else {
					win_main.append_console('watchexec_console', ' [ERROR] Manual run exited with code ${res.exit_code}\n', 3)
					win_main.toast('Command failed with code ${res.exit_code}')
				}
			})
		}()
	})

	// Start Watcher Button (Async Daemon)
	win.on_click('btn_start_watcher', fn [bin_path, mut state] (mut w simplegui.SimpleWindow) {
		if bin_path == '' {
			w.alert('watchexec Missing', 'The "watchexec" command-line tool was not found.\n\nPlease install it using Homebrew:\n  brew install watchexec')
			w.toast('watchexec binary missing')
			return
		}

		if state.is_watching {
			w.toast('Watcher is already active!')
			return
		}

		watch_dir := w.get('txt_watch_dir').trim_space()
		if watch_dir == '' || !os.exists(watch_dir) {
			w.alert('Invalid Directory', 'The specified watch directory does not exist:\n${watch_dir}')
			w.toast('Directory does not exist')
			return
		}

		cmd := w.get('txt_command').trim_space()
		if cmd == '' {
			w.alert('Command Required', 'Please enter a command to execute on changes.')
			w.toast('Command required')
			return
		}

		exts := w.get('txt_extensions').trim_space()
		filters := w.get('txt_filters').trim_space()
		ignores := w.get('txt_ignores').trim_space()
		debounce := w.get('dd_debounce').split(' ')[0].trim_space()
		signal_str := w.get('dd_signal').split(' ')[0].trim_space()

		is_restart := w.get('chk_restart') == 'true'
		is_clear := w.get('chk_clear') == 'true'
		is_timings := w.get('chk_timings') == 'true'
		is_events := w.get('chk_print_events') == 'true'
		is_vcs := w.get('chk_vcs_ignore') == 'true'
		is_rec := w.get('chk_recursive') == 'true'

		mut args := []string{}

		if is_rec {
			args << '-w'
			args << watch_dir
		} else {
			args << '-W'
			args << watch_dir
		}

		if exts != '' && exts != '*' {
			args << '-e'
			args << exts
		}

		if debounce != '' {
			args << '-d'
			args << debounce
		}

		if signal_str != '' && signal_str != 'SIGTERM' {
			args << '-s'
			args << signal_str
		}

		if is_restart {
			args << '-r'
		}
		if is_clear {
			args << '-c'
		}
		if is_timings {
			args << '--timings'
		}
		if is_events {
			args << '--print-events'
		}
		if !is_vcs {
			args << '--no-vcs-ignore'
		}

		if filters != '' {
			for f in filters.split(',') {
				tf := f.trim_space()
				if tf != '' {
					args << '-f'
					args << tf
				}
			}
		}

		if ignores != '' {
			for ig in ignores.split(',') {
				tig := ig.trim_space()
				if tig != '' {
					args << '-i'
					args << tig
				}
			}
		}

		args << '--'
		args << 'sh'
		args << '-c'
		args << cmd

		state.is_watching = true
		state.should_stop = false
		state.active_command = cmd
		state.active_dir = watch_dir
		state.output_buffer = ''

		w.set_stat_card('card_status', 'ACTIVE WATCHING', 'RUNNING', 'Watcher Active', true)
		w.set('lbl_status_bar', ' Status: Launching watchexec daemon...')
		w.toast('Starting watchexec daemon...')
		w.append_console('watchexec_console', ' [DAEMON START] Launching watchexec on ${watch_dir}...\n', 1)

		// Launch background worker thread
		go fn [bin_path, args, watch_dir, mut state, mut w] () {
			mut p := os.new_process(bin_path)
			p.set_args(args)
			p.set_work_folder(watch_dir)
			p.set_redirect_stdio_merged()
			p.run()

			state.process_pid = p.pid

			w.run_on_main_thread(fn [mut state] (mut win_main simplegui.SimpleWindow) {
				win_main.set_metric_card_value('card_pid', 'PID ${state.process_pid}', 'Process')
				win_main.set_metric_card_value('card_status', 'WATCHING', 'Status')
				win_main.set('lbl_status_bar', ' Status: Active Watching (PID ${state.process_pid})  |  Target: ${state.active_dir}')
				win_main.append_console('watchexec_console', ' [DAEMON ACTIVE] Process PID ${state.process_pid} listening for file changes.\n', 4)
				win_main.toast('Watcher active (PID ${state.process_pid})')
			})

			for p.is_alive() {
				if state.should_stop {
					p.signal_pgkill()
					p.signal_kill()
					break
				}

				line := p.stdout_read()
				if line.len > 0 {
					w.run_on_main_thread(fn [mut state, line] (mut win_main simplegui.SimpleWindow) {
						state.output_buffer += line
						if state.output_buffer.len > 50000 {
							state.output_buffer = state.output_buffer[state.output_buffer.len - 35000..]
						}
						win_main.set('txt_live_output', state.output_buffer)

						// Analyze event triggers
						if line.contains('[Running:') {
							state.total_triggers++
							state.last_trigger_ts = time.now().format_ss()
							win_main.set_metric_card_value('card_triggers', '${state.total_triggers} Triggers', 'Events')
							win_main.set_metric_card_value('card_last_event', state.last_trigger_ts, 'Activity')
							win_main.append_console('watchexec_console', ' [EVENT #${state.total_triggers}] Triggered re-execution at ${state.last_trigger_ts}\n', 4)
						} else if line.contains('[Command was successful]') {
							win_main.append_console('watchexec_console', ' [PASS] Command executed successfully.\n', 1)
						} else if line.contains('failed') || line.contains('exited with') {
							win_main.append_console('watchexec_console', ' [ERROR] Command failure reported: ${line.trim_space()}\n', 3)
						}
					})
				}
				time.sleep(60 * time.millisecond)
			}

			p.wait()
			p.close()

			w.run_on_main_thread(fn [mut state] (mut win_main simplegui.SimpleWindow) {
				state.is_watching = false
				state.process_pid = 0
				win_main.set_metric_card_value('card_status', 'STOPPED', 'Status')
				win_main.set_metric_card_value('card_pid', 'Idle', 'Process')
				win_main.set('lbl_status_bar', ' Status: Stopped  |  Daemon is idle.')
				win_main.append_console('watchexec_console', ' [DAEMON STOPPED] Watchexec process terminated.\n', 2)
				win_main.toast('Watcher stopped.')
			})
		}()
	})

	// Stop Watcher Button
	win.on_click('btn_stop_watcher', fn [mut state] (mut w simplegui.SimpleWindow) {
		if !state.is_watching {
			w.toast('Watcher is not running.')
			return
		}
		state.should_stop = true
		if state.process_pid > 0 {
			simplegui.exec_safe('kill', ['-TERM', '${state.process_pid}'])
		}
		w.toast('Stopping watcher daemon...')
	})

	println('Watchexec Studio Pro configured. Starting event loop...')
	win.start()
}

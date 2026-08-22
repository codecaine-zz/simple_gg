module main

import os
import time
import simplegui

// Helper to find Homebrew binary
fn get_brew_bin() string {
	if path := os.find_abs_path_of_executable('brew') {
		return path
	}
	common_paths := [
		'/opt/homebrew/bin/brew',
		'/usr/local/bin/brew',
	]
	for p in common_paths {
		if os.exists(p) {
			return p
		}
	}
	return 'brew'
}

fn main() {
	println('Starting SimpleGUI - Homebrew Studio Pro (macOS Package & Service Manager)...')

	mut win := simplegui.new_simple_window('SimpleGUI - Homebrew Studio Pro', 1080, 950)
	win.set_fullscreen(true)
	win.set_spacing(8)
	win.set_padding(16)

	saved_theme := simplegui.get_saved_theme()
	win.set_theme(saved_theme)

	// Top Banner / Diagnostics
	win.begin_row('row_brew_top')
	win.add_heading('Homebrew Studio Pro')
	win.add_label('lbl_theme', 'Theme:')
	win.add_dropdown('dd_app_theme', simplegui.list_themes(), saved_theme)
	win.set_control_width('dd_app_theme', 150)
	win.end_row()

	win.on_change('dd_app_theme', fn (mut w simplegui.SimpleWindow, selected string) {
		w.set_theme(selected)
		w.toast('Theme changed to ${selected}')
	})

	brew_path := get_brew_bin()
	win.add_label('lbl_engine_info', 'Engine: ${brew_path}  |  Platform: Apple Silicon / Intel macOS  |  Mode: Async Worker')

	// Search & Quick Operation Bar
	win.begin_group_box('grp_brew_search', 'Package Search & Information Inspection')
	
	win.begin_row('row_search_bar')
	win.add_label('lbl_search', 'Package / Cask:')
	win.add_input('txt_search_pkg', 'ffmpeg')
	win.set_control_width('txt_search_pkg', 280)

	win.add_button('btn_search_brew', 'Search Formulae & Casks')
	win.add_button('btn_info_pkg', 'Tip: Package Details (brew info)')
	win.add_button('btn_install_pkg', 'Download Install Package')
	win.add_button('btn_uninstall_pkg', 'Uninstall Package')
	win.end_row()

	win.end_group_box()

	// Global Maintenance & Services Actions
	win.begin_group_box('grp_global_actions', 'Homebrew Ecosystem & Service Controls')
	
	win.begin_row('row_global_btns_1')
	win.add_button('btn_list_installed', 'All Installed')
	win.add_button('btn_list_formulae', 'Formulae Only')
	win.add_button('btn_list_casks', 'Casks Only')
	win.add_button('btn_check_outdated', 'Check Outdated')
	win.add_button('btn_brew_services', 'Background Services')
	win.end_row()

	win.begin_row('row_global_btns_2')
	win.add_button('btn_brew_update', 'Update (brew update)')
	win.add_button('btn_brew_upgrade', 'Upgrade All (brew upgrade)')
	win.add_button('btn_brew_cleanup', 'Cleanup Cache (-s)')
	win.add_button('btn_brew_doctor', 'System Doctor')
	win.add_button('btn_fix_casks', 'Fix Orphaned Casks')
	win.end_row()

	win.end_group_box()

	// Package Details / Query Output
	win.begin_group_box('grp_output_view', 'Homebrew Output & Information Stream')
	win.add_textarea('txt_brew_output', '')
	win.set_control_height('txt_brew_output', 320)
	win.end_group_box()

	// Live Activity Console
	win.begin_group_box('grp_console', 'Homebrew Activity & Execution Telemetry')
	win.add_console('brew_console', 110)
	win.end_group_box()

	// Status Row
	win.begin_row('row_stats')
	win.add_label('lbl_stats', 'Stats: Ready  |  Homebrew Engine: Ready  |  Duration: 0 ms')
	win.end_row()

	win.append_console('brew_console', ' Homebrew Studio Pro Initialized.\n', 1)
	win.append_console('brew_console', ' Ready to manage formulae, casks, and background services.\n', 4)

	// -------------------------------------------------------------
	// Async Execution Helper
	// -------------------------------------------------------------
	run_brew_cmd := fn (mut w simplegui.SimpleWindow, desc string, args []string) {
		brew_bin := get_brew_bin()
		w.append_console('brew_console', ' Executing: brew ${args.join(" ")}...\n', 1)
		w.set_status('Running brew ${args.join(" ")}...')
		w.toast(' ${desc}...')

		go fn [mut w, brew_bin, args, desc] () {
			t0 := time.ticks()
			res := simplegui.exec_safe(brew_bin, args)
			elapsed_ms := time.ticks() - t0

			w.run_on_main_thread(fn [res, elapsed_ms, desc] (mut win_main simplegui.SimpleWindow) {
				mut out := res.output.trim_space()
				
				// Strip stray cask errors if actual output was produced
				if out.contains('Error: Cask ') && out.contains('\n') {
					lines := out.split_into_lines()
					mut filtered := []string{}
					for l in lines {
						if !l.starts_with('Error: Cask ') {
							filtered << l
						}
					}
					out = filtered.join('\n')
				}

				win_main.set('txt_brew_output', out)

				lines_cnt := if out != '' { out.split_into_lines().len } else { 0 }
				if res.exit_code == 0 || (lines_cnt > 0 && !out.starts_with('Error:')) {
					win_main.append_console('brew_console', ' ${desc} completed in ${elapsed_ms} ms (${lines_cnt} lines output).\n', 4)
					win_main.set('lbl_stats', ' Stats: SUCCESS  |  Action: ${desc}  |  Lines: ${lines_cnt}  |  Duration: ${elapsed_ms} ms')
					win_main.set_status('${desc} complete.')
					win_main.toast('${desc} complete!')
				} else {
					win_main.append_console('brew_console', ' Notice / Error (Exit ${res.exit_code}):\n' + out + '\n', 3)
					win_main.set('lbl_stats', ' Stats: NOTICE (Exit ${res.exit_code})  |  Duration: ${elapsed_ms} ms')
					win_main.set_status('${desc} finished.')
				}
			})
		}()
	}

	// -------------------------------------------------------------
	// Event Handlers
	// -------------------------------------------------------------

	// Search Package
	win.on_click('btn_search_brew', fn [run_brew_cmd] (mut w simplegui.SimpleWindow) {
		pkg := w.get('txt_search_pkg').trim_space()
		if pkg == '' {
			w.alert('Search Term Required', 'Please enter a package or keyword to search.')
			return
		}
		run_brew_cmd(mut w, 'Search for "${pkg}"', ['search', pkg])
	})

	// Package Info
	win.on_click('btn_info_pkg', fn [run_brew_cmd] (mut w simplegui.SimpleWindow) {
		pkg := w.get('txt_search_pkg').trim_space()
		if pkg == '' {
			w.alert('Package Required', 'Please enter a package name to inspect.')
			return
		}
		run_brew_cmd(mut w, 'Info for "${pkg}"', ['info', pkg])
	})

	// Install Package
	win.on_click('btn_install_pkg', fn [run_brew_cmd] (mut w simplegui.SimpleWindow) {
		pkg := w.get('txt_search_pkg').trim_space()
		if pkg == '' {
			w.alert('Package Required', 'Please enter a package name to install.')
			return
		}
		if !w.confirm('Install Package', 'Are you sure you want to install "${pkg}" via Homebrew?') {
			return
		}
		run_brew_cmd(mut w, 'Install "${pkg}"', ['install', pkg])
	})

	// Uninstall Package
	win.on_click('btn_uninstall_pkg', fn [run_brew_cmd] (mut w simplegui.SimpleWindow) {
		pkg := w.get('txt_search_pkg').trim_space()
		if pkg == '' {
			w.alert('Package Required', 'Please enter a package name to uninstall.')
			return
		}
		if !w.confirm('Uninstall Package', 'Are you sure you want to uninstall "${pkg}"?') {
			return
		}
		run_brew_cmd(mut w, 'Uninstall "${pkg}"', ['uninstall', pkg])
	})

	// List All Installed (Formulae + Casks)
	win.on_click('btn_list_installed', fn (mut w simplegui.SimpleWindow) {
		brew_bin := get_brew_bin()
		w.append_console('brew_console', ' Querying all installed formulae and casks...\n', 1)
		w.set_status('Listing installed packages...')
		w.toast('Listing all installed packages...')

		go fn [mut w, brew_bin] () {
			t0 := time.ticks()
			res_f := simplegui.exec_safe(brew_bin, ['list', '--formula', '--versions'])
			res_c := simplegui.exec_safe(brew_bin, ['list', '--cask'])
			elapsed_ms := time.ticks() - t0

			w.run_on_main_thread(fn [res_f, res_c, elapsed_ms] (mut win_main simplegui.SimpleWindow) {
				formulae_lines := res_f.output.trim_space().split_into_lines()
				casks_lines := res_c.output.trim_space().split_into_lines()

				f_cnt := if res_f.output.trim_space() != '' { formulae_lines.len } else { 0 }
				c_cnt := if res_c.output.trim_space() != '' { casks_lines.len } else { 0 }

				mut out := '=======================================================\n'
				out += 'HOMEBREW INSTALLED PACKAGES (${f_cnt + c_cnt} Total)\n'
				out += '=======================================================\n\n'

				out += '---  Installed Formulae (${f_cnt} CLI tools & libraries) ---\n'
				out += res_f.output.trim_space() + '\n\n'

				out += '---  Installed Casks (${c_cnt} GUI applications) ---\n'
				out += res_c.output.trim_space() + '\n'

				win_main.set('txt_brew_output', out)
				win_main.append_console('brew_console', ' Listed ${f_cnt} formulae and ${c_cnt} casks in ${elapsed_ms} ms.\n', 4)
				win_main.set('lbl_stats', ' Stats: SUCCESS  |  Formulae: ${f_cnt}  |  Casks: ${c_cnt}  |  Duration: ${elapsed_ms} ms')
				win_main.set_status('Listed all installed packages.')
				win_main.toast('Listed all installed packages!')
			})
		}()
	})

	// List Formulae Only
	win.on_click('btn_list_formulae', fn [run_brew_cmd] (mut w simplegui.SimpleWindow) {
		run_brew_cmd(mut w, 'List Installed Formulae', ['list', '--formula', '--versions'])
	})

	// List Casks Only
	win.on_click('btn_list_casks', fn [run_brew_cmd] (mut w simplegui.SimpleWindow) {
		run_brew_cmd(mut w, 'List Installed Casks', ['list', '--cask'])
	})

	// Check Outdated
	win.on_click('btn_check_outdated', fn [run_brew_cmd] (mut w simplegui.SimpleWindow) {
		run_brew_cmd(mut w, 'Check Outdated Packages', ['outdated', '--verbose'])
	})

	// Brew Update
	win.on_click('btn_brew_update', fn [run_brew_cmd] (mut w simplegui.SimpleWindow) {
		run_brew_cmd(mut w, 'Update Homebrew Definitions', ['update'])
	})

	// Brew Upgrade
	win.on_click('btn_brew_upgrade', fn [run_brew_cmd] (mut w simplegui.SimpleWindow) {
		if !w.confirm('Upgrade All', 'Upgrade all outdated Homebrew formulae and casks?') {
			return
		}
		run_brew_cmd(mut w, 'Upgrade All Packages', ['upgrade'])
	})

	// Brew Services
	win.on_click('btn_brew_services', fn [run_brew_cmd] (mut w simplegui.SimpleWindow) {
		run_brew_cmd(mut w, 'List Background Services', ['services', 'list'])
	})

	// Brew Cleanup
	win.on_click('btn_brew_cleanup', fn [run_brew_cmd] (mut w simplegui.SimpleWindow) {
		run_brew_cmd(mut w, 'Cleanup Cache & Disk Space', ['cleanup', '-s'])
	})

	// Brew Doctor
	win.on_click('btn_brew_doctor', fn [run_brew_cmd] (mut w simplegui.SimpleWindow) {
		run_brew_cmd(mut w, 'System Health Check (Doctor)', ['doctor'])
	})

	// Fix Orphaned Casks
	win.on_click('btn_fix_casks', fn (mut w simplegui.SimpleWindow) {
		caskroom_dir := '/opt/homebrew/Caskroom'
		if !os.exists(caskroom_dir) {
			w.toast('Caskroom not found.')
			return
		}

		w.append_console('brew_console', ' Scanning for orphaned Caskroom entries without installed versions...\n', 1)
		
		entries := os.ls(caskroom_dir) or { []string{} }
		mut removed_cnt := 0
		for entry in entries {
			dir_path := os.join_path(caskroom_dir, entry)
			if os.is_dir(dir_path) {
				sub_entries := os.ls(dir_path) or { []string{} }
				mut has_version_dir := false
				for s in sub_entries {
					if s != '.metadata' && os.is_dir(os.join_path(dir_path, s)) {
						has_version_dir = true
						break
					}
				}
				if !has_version_dir {
					w.append_console('brew_console', ' Cleaning orphaned cask receipt: ${entry}\n', 3)
					os.rmdir_all(dir_path) or {}
					removed_cnt++
				}
			}
		}

		if removed_cnt > 0 {
			w.append_console('brew_console', ' Cleaned ${removed_cnt} orphaned cask directories.\n', 4)
			w.toast('Cleaned ${removed_cnt} orphaned casks!')
			w.alert('Orphaned Casks Cleaned', 'Successfully resolved ${removed_cnt} orphaned cask receipts. Homebrew list commands will now run cleanly.')
		} else {
			w.append_console('brew_console', ' All Caskroom directories are healthy.\n', 4)
			w.toast('Caskroom is healthy.')
		}
	})

	win.start()
}

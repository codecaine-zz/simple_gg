module main

import os
import time
import simplegui

fn main() {
	println('Starting SimpleGUI - Disk Space & Cleanup Studio Pro...')

	mut win := simplegui.new_simple_window('SimpleGUI - Disk Space & Cleanup Studio Pro', 1080, 950)
	win.set_fullscreen(true)
	win.set_spacing(8)
	win.set_padding(16)

	saved_theme := simplegui.get_saved_theme()
	win.set_theme(saved_theme)

	// Top Banner / Diagnostics
	win.begin_row('row_disk_top')
	win.add_heading('Disk Space & Cleanup Studio Pro')
	win.add_label('lbl_theme', 'Theme:')
	win.add_dropdown('dd_app_theme', simplegui.list_themes(), saved_theme)
	win.set_control_width('dd_app_theme', 150)
	win.end_row()

	win.on_change('dd_app_theme', fn (mut w simplegui.SimpleWindow, selected string) {
		w.set_theme(selected)
		w.toast('Theme changed to ${selected}')
	})

	win.add_label('lbl_engine_info', 'Engine: macOS APFS Core Utilities (du, df, find)  |  Platform: macOS Cocoa  |  Mode: Async')

	// Directory Scope Selector
	win.begin_group_box('grp_disk_scope', 'Target Directory & Filesystem Scope')
	
	win.begin_row('row_target_dir')
	win.add_label('lbl_dir', 'Directory:')
	win.add_input('txt_target_dir', os.home_dir())
	win.set_control_width('txt_target_dir', 420)

	win.add_button('btn_select_dir', 'Browse Folder...')
	win.add_button('btn_home_dir', 'Home (~)')
	win.add_button('btn_downloads_dir', 'Downloads')
	win.end_row()

	win.end_group_box()

	// Analysis & Cleanup Actions Bar
	win.begin_group_box('grp_disk_actions', 'Storage Telemetry & Cleanup Tools')
	
	win.begin_row('row_actions_btns')
	win.add_button('btn_analyze_usage', 'Directory Breakdown (du -sh)')
	win.add_button('btn_largest_files', 'Top 30 Largest Files')
	win.add_button('btn_df_volumes', 'APFS Volumes (df -h)')
	win.add_button('btn_scan_dev_junk', 'Scan Developer Junk (node_modules, caches)')
	win.add_button('btn_clean_xcode', 'Clean Xcode DerivedData')
	win.add_button('btn_copy_results', 'Copy Output')
	win.add_button('btn_clear_all', 'Clear')
	win.end_row()

	win.end_group_box()

	// Disk Storage Report Area
	win.begin_group_box('grp_output_view', 'Storage Analysis & Disk Hierarchy Report')
	win.add_textarea('txt_disk_output', '')
	win.set_control_height('txt_disk_output', 320)
	win.end_group_box()

	// Live Activity Console
	win.begin_group_box('grp_console', 'Storage Activity & Scan Telemetry Log')
	win.add_console('disk_console', 110)
	win.end_group_box()

	// Status Row
	win.begin_row('row_stats')
	win.add_label('lbl_stats', 'Stats: Ready  |  Target: ${os.home_dir()}  |  Duration: 0 ms')
	win.end_row()

	win.append_console('disk_console', ' Disk Space & Cleanup Studio Pro Initialized.\n', 1)
	win.append_console('disk_console', ' Ready to analyze directory sizes, top large files, and clean developer caches.\n', 4)

	// -------------------------------------------------------------
	// Event Handlers
	// -------------------------------------------------------------

	// Select Directory Picker
	win.on_click('btn_select_dir', fn (mut w simplegui.SimpleWindow) {
		path := w.select_folder()
		if path != '' && os.exists(path) {
			w.set('txt_target_dir', path)
			w.toast('Target set to: ' + os.file_name(path))
		}
	})

	// Home Dir Quick Action
	win.on_click('btn_home_dir', fn (mut w simplegui.SimpleWindow) {
		w.set('txt_target_dir', os.home_dir())
		w.toast('Target set to Home directory.')
	})

	// Downloads Dir Quick Action
	win.on_click('btn_downloads_dir', fn (mut w simplegui.SimpleWindow) {
		w.set('txt_target_dir', os.join_path(os.home_dir(), 'Downloads'))
		w.toast('Target set to Downloads directory.')
	})

	// Directory Breakdown Action
	win.on_click('btn_analyze_usage', fn (mut w simplegui.SimpleWindow) {
		target_dir := w.get('txt_target_dir').trim_space()
		if target_dir == '' || !os.exists(target_dir) {
			w.alert('Directory Required', 'Please select a valid directory on disk.')
			return
		}

		w.append_console('disk_console', ' Analyzing directory sizes for: ${target_dir}...\n', 1)
		w.set_status('Calculating disk space usage...')
		w.toast('Calculating disk usage...')

		go fn [mut w, target_dir] () {
			t0 := time.ticks()
			res := os.execute('du -sh "${target_dir}"/* 2>/dev/null | sort -hr | head -n 40')
			elapsed_ms := time.ticks() - t0

			w.run_on_main_thread(fn [res, elapsed_ms, target_dir] (mut win_main simplegui.SimpleWindow) {
				out := res.output.trim_space()
				win_main.set('txt_disk_output', out)

				lines_cnt := if out != '' { out.split_into_lines().len } else { 0 }
				win_main.append_console('disk_console', ' Directory breakdown complete in ${elapsed_ms} ms (${lines_cnt} entries sorted by size).\n', 4)
				win_main.set('lbl_stats', ' Stats: SUCCESS  |  Target: ${os.file_name(target_dir)}  |  Entries: ${lines_cnt}  |  Duration: ${elapsed_ms} ms')
				win_main.set_status('Disk usage analysis complete.')
				win_main.toast('Disk breakdown calculated!')
			})
		}()
	})

	// Top 30 Largest Files Action
	win.on_click('btn_largest_files', fn (mut w simplegui.SimpleWindow) {
		target_dir := w.get('txt_target_dir').trim_space()
		if target_dir == '' || !os.exists(target_dir) {
			w.alert('Directory Required', 'Please select a valid directory on disk.')
			return
		}

		w.append_console('disk_console', ' Searching for top largest files in: ${target_dir}...\n', 1)
		w.set_status('Finding largest files...')
		w.toast('Scanning for large files...')

		go fn [mut w, target_dir] () {
			t0 := time.ticks()
			cmd := 'find "${target_dir}" -type f -exec ls -lh {} + 2>/dev/null | awk \'{print $5, $9}\' | sort -hr | head -n 30'
			res := os.execute(cmd)
			elapsed_ms := time.ticks() - t0

			w.run_on_main_thread(fn [res, elapsed_ms, target_dir] (mut win_main simplegui.SimpleWindow) {
				out := res.output.trim_space()
				win_main.set('txt_disk_output', out)

				win_main.append_console('disk_console', ' Top largest files located in ${elapsed_ms} ms.\n', 4)
				win_main.set('lbl_stats', ' Stats: SUCCESS  |  Scope: ${os.file_name(target_dir)}  |  Duration: ${elapsed_ms} ms')
				win_main.set_status('Largest files found.')
				win_main.toast('Largest files located!')
			})
		}()
	})

	// APFS Volumes Telemetry
	win.on_click('btn_df_volumes', fn (mut w simplegui.SimpleWindow) {
		w.append_console('disk_console', ' Reading APFS mounted filesystem volumes (df -h)...\n', 1)
		w.set_status('Reading mounted filesystems...')

		go fn [mut w] () {
			t0 := time.ticks()
			res := os.execute('df -h')
			elapsed_ms := time.ticks() - t0

			w.run_on_main_thread(fn [res, elapsed_ms] (mut win_main simplegui.SimpleWindow) {
				win_main.set('txt_disk_output', res.output.trim_space())
				win_main.append_console('disk_console', ' APFS volume telemetry loaded in ${elapsed_ms} ms.\n', 4)
				win_main.set('lbl_stats', ' Stats: APFS MOUNTED VOLUMES  |  Duration: ${elapsed_ms} ms')
				win_main.set_status('Mounted volume stats loaded.')
			})
		}()
	})

	// Scan Developer Junk
	win.on_click('btn_scan_dev_junk', fn (mut w simplegui.SimpleWindow) {
		target_dir := w.get('txt_target_dir').trim_space()
		if target_dir == '' || !os.exists(target_dir) {
			w.alert('Directory Required', 'Please select a directory to scan.')
			return
		}

		w.append_console('disk_console', ' Scanning for developer junk (node_modules, target, .cache, __pycache__)...\n', 1)
		w.set_status('Scanning developer caches...')

		go fn [mut w, target_dir] () {
			t0 := time.ticks()
			cmd := 'find "${target_dir}" -maxdepth 4 -type d \\( -name "node_modules" -o -name "target" -o -name ".cache" -o -name "__pycache__" -o -name ".build" \\) -exec du -sh {} + 2>/dev/null'
			res := os.execute(cmd)
			elapsed_ms := time.ticks() - t0

			w.run_on_main_thread(fn [res, elapsed_ms] (mut win_main simplegui.SimpleWindow) {
				out := res.output.trim_space()
				win_main.set('txt_disk_output', if out != '' { out } else { 'No developer junk directories found in this path.' })
				win_main.append_console('disk_console', ' Developer junk scan complete in ${elapsed_ms} ms.\n', 4)
				win_main.set('lbl_stats', ' Stats: DEV JUNK SCAN COMPLETE  |  Duration: ${elapsed_ms} ms')
				win_main.set_status('Developer junk scan finished.')
				win_main.toast('Scan complete!')
			})
		}()
	})

	// Clean Xcode DerivedData
	win.on_click('btn_clean_xcode', fn (mut w simplegui.SimpleWindow) {
		derived_path := os.join_path(os.home_dir(), 'Library/Developer/Xcode/DerivedData')
		if !os.exists(derived_path) {
			w.alert('No DerivedData', 'Xcode DerivedData folder not found or already empty.')
			return
		}
		if !w.confirm('Clean Xcode DerivedData', 'Delete all Xcode DerivedData cache to reclaim disk space?') {
			return
		}
		w.append_console('disk_console', ' Cleaning Xcode DerivedData: ${derived_path}...\n', 1)
		os.execute('rm -rf "${derived_path}"/*')
		w.toast('Xcode DerivedData cleaned!')
		w.append_console('disk_console', ' Xcode DerivedData emptied.\n', 4)
	})

	// Copy Results
	win.on_click('btn_copy_results', fn (mut w simplegui.SimpleWindow) {
		out := w.get('txt_disk_output')
		if out != '' {
			w.copy_to_clipboard(out)
			w.toast('Disk report copied to clipboard!')
		} else {
			w.toast('No output to copy.')
		}
	})

	// Clear All
	win.on_click('btn_clear_all', fn (mut w simplegui.SimpleWindow) {
		w.set('txt_disk_output', '')
		w.clear_console('disk_console')
		w.toast('Cleared workspace.')
	})

	win.start()
}

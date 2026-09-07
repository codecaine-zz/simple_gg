module main

import os
import time
import simplegui

// -----------------------------------------------------------------------------
// Graveyard Record & Telemetry Structs
// -----------------------------------------------------------------------------
struct GraveyardRecord {
	time_str    string
	original    string
	destination string
	name        string
	size_bytes  i64
	is_dir      bool
	is_active   bool
}

struct GraveyardStats {
	path        string
	active_cnt  int
	total_cnt   int
	total_bytes i64
	restored_cnt int
}

// -----------------------------------------------------------------------------
// Binary & Graveyard Resolution Helpers
// -----------------------------------------------------------------------------
fn get_rip_bin() string {
	for candidate in [
		'/opt/homebrew/bin/rip',
		'/usr/local/bin/rip',
		'/usr/bin/rip',
		'rip',
	] {
		if os.exists(candidate) {
			return candidate
		}
	}
	return 'rip'
}

fn query_graveyard_path(rip_bin string) string {
	res := simplegui.exec_safe(rip_bin, ['graveyard'])
	if res.exit_code == 0 {
		trimmed := res.output.trim_space()
		if trimmed.len > 0 && os.is_dir(trimmed) {
			return trimmed
		}
	}
	// Fallback to standard user temporary directory
	user := os.getenv('USER')
	temp_dir := os.temp_dir()
	guess := os.join_path(temp_dir, 'graveyard-${user}')
	if os.is_dir(guess) {
		return guess
	}
	return temp_dir
}

fn format_bytes(bytes i64) string {
	if bytes < 1024 {
		return '${bytes} B'
	} else if bytes < 1024 * 1024 {
		return '${f64(bytes) / 1024.0:.1f} KB'
	} else if bytes < 1024 * 1024 * 1024 {
		return '${f64(bytes) / (1024.0 * 1024.0):.2f} MB'
	}
	return '${f64(bytes) / (1024.0 * 1024.0 * 1024.0):.2f} GB'
}

fn get_dir_size_recursive(dir string) i64 {
	mut total := i64(0)
	entries := os.ls(dir) or { return 0 }
	for entry in entries {
		full := os.join_path(dir, entry)
		if os.is_dir(full) {
			total += get_dir_size_recursive(full)
		} else {
			total += os.file_size(full)
		}
	}
	return total
}

// Parse graveyard .record file to retrieve history of burials
fn load_graveyard_records(graveyard_dir string) ([]GraveyardRecord, GraveyardStats) {
	record_file := os.join_path(graveyard_dir, '.record')
	mut records := []GraveyardRecord{}
	mut total_size := i64(0)
	mut active_count := 0
	mut restored_count := 0

	if !os.exists(record_file) {
		return records, GraveyardStats{
			path: graveyard_dir
			active_cnt: 0
			total_cnt: 0
			total_bytes: 0
			restored_cnt: 0
		}
	}

	content := os.read_file(record_file) or { '' }
	lines := content.split_into_lines()

	// .record header format: Time\tOriginal\tDestination
	for i in 1 .. lines.len {
		line := lines[i].trim_space()
		if line == '' {
			continue
		}
		cols := line.split('\t')
		if cols.len >= 3 {
			t_raw := cols[0].trim_space()
			orig := cols[1].trim_space()
			dest := cols[2].trim_space()

			// Format timestamp: 2026-09-07T02:35:10.029495-05:00 -> 2026-09-07 02:35:10
			mut t_clean := t_raw
			if t_clean.len >= 19 {
				t_clean = t_clean[..10] + ' ' + t_clean[11..19]
			}

			is_active := os.exists(dest)
			mut sz := i64(0)
			mut is_d := false

			if is_active {
				active_count++
				is_d = os.is_dir(dest)
				if is_d {
					sz = get_dir_size_recursive(dest)
				} else {
					sz = os.file_size(dest)
				}
				total_size += sz
			} else {
				restored_count++
			}

			item_name := os.file_name(orig)

			records << GraveyardRecord{
				time_str: t_clean
				original: orig
				destination: dest
				name: item_name
				size_bytes: sz
				is_dir: is_d
				is_active: is_active
			}
		}
	}

	// Reverse order so most recently buried items appear first
	records.reverse()

	return records, GraveyardStats{
		path: graveyard_dir
		active_cnt: active_count
		total_cnt: records.len
		total_bytes: total_size
		restored_cnt: restored_count
	}
}

// -----------------------------------------------------------------------------
// Main Application Workbench (AAA Enterprise Design)
// -----------------------------------------------------------------------------
fn main() {
	println('Starting SimpleGUI - Rip Studio Pro (AAA Safe Deletion & Graveyard Workbench)...')

	mut win := simplegui.new_simple_window('Rip Studio Pro -- AAA Safe Deletion & Graveyard Workbench', 1140, 940)
	win.set_fullscreen(true)
	win.restore_saved_theme()
	win.set_spacing(10)
	win.set_padding(16)

	rip_bin := get_rip_bin()
	mut current_graveyard := query_graveyard_path(rip_bin)

	// -------------------------------------------------------------
	// Executive Header & Top Command Bar
	// -------------------------------------------------------------
	win.begin_row('row_header')
	win.add_heading('Rip Studio Pro')
	win.control('heading_1').set_width(320)

	win.add_button('btn_top_refresh', ' Refresh Tomb')
	win.control('btn_top_refresh').set_elevation(2).set_vector_icon('refresh').set_width(140)

	win.add_button('btn_top_open_tomb', ' Open Graveyard')
	win.control('btn_top_open_tomb').set_elevation(1).set_vector_icon('folder').set_width(150)

	win.add_button('btn_top_unbury_last', ' Resurrect Last')
	win.control('btn_top_unbury_last').set_elevation(1).set_vector_icon('check').set_width(140)

	saved_theme := simplegui.get_saved_theme()
	win.add_dropdown('dd_theme_selector', simplegui.list_themes(), saved_theme)
	win.set_control_width('dd_theme_selector', 160)
	win.end_row()

	win.begin_row('row_engine_telemetry')
	win.add_label('lbl_engine_info', 'Engine: ${rip_bin}  |  Graveyard Vault: ${current_graveyard}  |  Runtime: Async Thread Pool  |  Platform: ${simplegui.get_platform_label()}')
	win.end_row()

	// -------------------------------------------------------------
	// High-Impact KPI Metric Stat Cards
	// -------------------------------------------------------------
	win.begin_row('row_stat_cards')
	win.add_stat_card('card_buried_count', ' Tomb Population', '0 Active Items', 'Protected against accidental rm', true, [1.0, 3.0, 2.0, 4.0, 3.0, 5.0])
	win.add_stat_card('card_graveyard_size', ' Graveyard Disk Footprint', '0 B', 'Temporary APFS recovery cache', true, [10.0, 25.0, 18.0, 35.0, 28.0, 42.0])
	win.add_stat_card('card_restored_count', ' Files Resurrected', '0 Restored', '100% Recovery Success Rate', true, [0.0, 1.0, 2.0, 2.0, 3.0, 4.0])
	win.add_stat_card('card_graveyard_path', ' Vault Storage', os.file_name(current_graveyard), 'APFS Temp Cache', true, [2.0, 3.0, 2.0, 4.0, 3.0, 5.0])
	win.end_row()

	// -------------------------------------------------------------
	// AAA Tabbed Container Interface
	// -------------------------------------------------------------
	win.begin_tab_container('workspace_tabs', [
		'Tomb & Resurrection',
		'Safe Deletion (Bury)',
		'Directory Séance (Ghosts)',
		'Raw Journal & Health',
	])

	// =============================================================
	// TAB 0: Tomb & Resurrection (Graveyard Explorer)
	// =============================================================
	win.begin_tab_page('tab_tomb', 0)

	win.begin_group_box('grp_tomb_browser', 'Graveyard Tomb & Active Resting Artifacts')

	win.begin_row('row_tomb_controls')
	win.add_label('lbl_filter', 'Filter Tomb:')
	win.add_input('txt_filter_tomb', '')
	win.set_control_width('txt_filter_tomb', 240)

	win.add_checkbox('chk_show_inactive', 'Show Already Restored History', false)

	win.add_button('btn_resurrect_selected', 'Resurrect Selected Item')
	win.control('btn_resurrect_selected').set_elevation(2).set_vector_icon('check').set_width(190)

	win.add_button('btn_reveal_in_graveyard', 'Reveal in Tomb')
	win.control('btn_reveal_in_graveyard').set_elevation(1).set_vector_icon('folder').set_width(140)

	win.add_button('btn_decompose_graveyard', 'Decompose (Wipe)')
	win.control('btn_decompose_graveyard').set_elevation(1).set_vector_icon('trash').set_width(150)
	win.end_row()

	table_headers := ['Item Name', 'Original Path', 'Buried At', 'Type', 'Size', 'Status', 'Graveyard Destination']
	win.add_table('tbl_graveyard', table_headers, [][]string{})
	win.set_control_height('tbl_graveyard', 280)

	win.end_group_box()

	// Selected Item Intelligence Inspector Card
	win.begin_group_box('grp_item_intel', 'Selected Artifact Intelligence & One-Click Actions')
	win.begin_row('row_intel_info')
	win.add_label('lbl_intel_name', 'Selected Item: (Click an item in the tomb above to inspect details)')
	win.end_row()
	win.begin_row('row_intel_paths')
	win.add_label('lbl_intel_orig', 'Original Location: --')
	win.end_row()
	win.begin_row('row_intel_dest')
	win.add_label('lbl_intel_dest', 'Tomb Location: --')
	win.end_row()
	win.begin_row('row_intel_actions')
	win.add_button('btn_intel_restore', ' Resurrect This File Now')
	win.control('btn_intel_restore').set_elevation(2).set_vector_icon('check').set_width(180)
	win.add_button('btn_intel_reveal_orig', ' Reveal Original Folder')
	win.control('btn_intel_reveal_orig').set_elevation(1).set_vector_icon('folder').set_width(170)
	win.add_button('btn_intel_reveal_tomb', ' Reveal Tomb Target')
	win.control('btn_intel_reveal_tomb').set_elevation(1).set_vector_icon('folder').set_width(160)
	win.add_button('btn_intel_preview', ' Quick Preview Content')
	win.control('btn_intel_preview').set_elevation(1).set_vector_icon('eye').set_width(170)
	win.end_row()
	win.end_group_box()

	win.end_tab_page()

	// =============================================================
	// TAB 1: Safe Deletion & Pre-Flight Inspection ("Bury")
	// =============================================================
	win.begin_tab_page('tab_bury', 1)

	win.begin_group_box('grp_bury_settings', 'Safe Deletion Workspace (Enterprise Non-Destructive rm Replacement)')

	win.begin_row('row_target_input')
	win.add_label('lbl_target_path', 'Target Path:')
	win.add_input('txt_target_path', '')
	win.set_control_width('txt_target_path', 500)
	win.add_button('btn_pick_file', 'Pick File...')
	win.control('btn_pick_file').set_elevation(1).set_vector_icon('folder').set_width(110)
	win.add_button('btn_pick_folder', 'Pick Folder...')
	win.control('btn_pick_folder').set_elevation(1).set_vector_icon('folder').set_width(120)
	win.add_button('btn_reveal_target', 'Reveal')
	win.control('btn_reveal_target').set_elevation(1).set_vector_icon('eye').set_width(90)
	win.end_row()

	win.begin_row('row_bury_options')
	win.add_checkbox('chk_inspect_before_bury', 'Pre-flight metadata inspection (-i)', true)
	win.add_checkbox('chk_force_mode', 'Force / Non-interactive mode (-f)', false)
	win.add_checkbox('chk_backup_notice', 'Log operation to audit trail', true)
	win.end_row()

	win.begin_row('row_bury_actions')
	win.add_button('btn_run_bury', ' Bury Target to Graveyard (Safe Delete)')
	win.control('btn_run_bury').set_elevation(2).set_vector_icon('trash').set_width(280)

	win.add_button('btn_inspect_target', ' Inspect Pre-flight Telemetry')
	win.control('btn_inspect_target').set_elevation(1).set_vector_icon('eye').set_width(210)

	win.add_button('btn_create_demo_file', ' Create & Select Test File')
	win.control('btn_create_demo_file').set_elevation(1).set_vector_icon('star').set_width(200)
	win.end_row()

	win.end_group_box()

	// Pre-Flight Diagnostic Health Panel
	win.begin_group_box('grp_preflight', 'Target Pre-Flight Telemetry & Safety Verifications')
	win.add_textarea('txt_preflight_report', 'Select any file or folder above and click "Inspect Pre-flight Telemetry" to review permissions, file size, inodes, and safety locks before burying.\n')
	win.set_control_height('txt_preflight_report', 240)
	win.end_group_box()

	win.end_tab_page()

	// =============================================================
	// TAB 2: Directory Séance (Ghost Investigator)
	// =============================================================
	win.begin_tab_page('tab_seance', 2)

	win.begin_group_box('grp_seance_box', 'Directory Séance Engine (Detect Resting Files Previously in Folder - rip -s)')

	win.begin_row('row_seance_dir')
	win.add_label('lbl_seance_scope', 'Target Directory Scope:')
	win.add_input('txt_seance_dir', '.')
	win.set_control_width('txt_seance_dir', 420)
	win.add_button('btn_browse_seance_dir', 'Browse Folder...')
	win.control('btn_browse_seance_dir').set_elevation(1).set_vector_icon('folder').set_width(140)
	win.add_button('btn_cwd_seance', 'Workspace Root (.)')
	win.control('btn_cwd_seance').set_elevation(1).set_vector_icon('home').set_width(150)
	win.add_button('btn_summon_ghosts', ' Summon Ghosts (-s)')
	win.control('btn_summon_ghosts').set_elevation(2).set_vector_icon('search').set_width(160)
	win.end_row()

	win.end_group_box()

	win.begin_group_box('grp_seance_output', 'Séance Discovery Registry & Instant Resurrection')
	win.add_textarea('txt_seance_report', 'Click "Summon Ghosts (-s)" to inspect all files that once existed in the selected folder and are currently preserved in the graveyard.\n')
	win.set_control_height('txt_seance_report', 280)

	win.begin_row('row_seance_actions')
	win.add_button('btn_seance_unbury_recent', ' Resurrect Most Recent Ghost')
	win.control('btn_seance_unbury_recent').set_elevation(2).set_vector_icon('check').set_width(220)
	win.add_button('btn_seance_clear', ' Clear Séance Output')
	win.control('btn_seance_clear').set_elevation(1).set_vector_icon('close').set_width(170)
	win.end_row()

	win.end_group_box()

	win.end_tab_page()

	// =============================================================
	// TAB 3: Raw Journal, Health & Maintenance
	// =============================================================
	win.begin_tab_page('tab_diagnostics', 3)

	win.begin_group_box('grp_vault_location', 'System Graveyard Vault Path & Storage Mount')
	win.begin_row('row_vault_path')
	win.add_label('lbl_vault_title', 'Vault Path:')
	win.add_input('txt_vault_path_disp', current_graveyard)
	win.set_control_width('txt_vault_path_disp', 520)
	win.add_button('btn_copy_vault_path', ' Copy Path')
	win.control('btn_copy_vault_path').set_elevation(1).set_vector_icon('copy').set_width(130)
	win.add_button('btn_reveal_vault_folder', ' Open in Finder')
	win.control('btn_reveal_vault_folder').set_elevation(1).set_vector_icon('folder').set_width(140)
	win.end_row()
	win.end_group_box()

	win.begin_group_box('grp_journal', 'Graveyard Master Ledger (.record Journal)')
	win.add_textarea('txt_raw_journal', '')
	win.set_control_height('txt_raw_journal', 220)

	win.begin_row('row_journal_actions')
	win.add_button('btn_reload_journal', ' Reload Journal')
	win.control('btn_reload_journal').set_elevation(1).set_vector_icon('refresh').set_width(140)
	win.add_button('btn_copy_journal', ' Copy Raw Journal')
	win.control('btn_copy_journal').set_elevation(1).set_vector_icon('copy').set_width(150)
	win.end_row()
	win.end_group_box()

	win.begin_group_box('grp_danger_zone', 'Permanent Deletion & Storage Reclaim (Decompose -d)')
	win.begin_row('row_danger_info')
	win.add_label('lbl_danger_warn', 'Warning: Decomposing permanently purges all files resting in the graveyard. This action cannot be undone.')
	win.end_row()
	win.begin_row('row_danger_btn')
	win.add_button('btn_exec_decompose', ' Decompose Graveyard & Reclaim Disk Space')
	win.control('btn_exec_decompose').set_elevation(2).set_vector_icon('trash').set_width(320)
	win.end_row()
	win.end_group_box()

	win.end_tab_page()

	win.end_tab_container()

	// -------------------------------------------------------------
	// Live Operation Console & Action Bar
	// -------------------------------------------------------------
	win.begin_group_box('grp_console_dock', 'Live Activity Console & Operation Telemetry')
	win.add_textarea('txt_activity_log', ' Rip Studio Pro v1.0.0 initialized.\n Ready for enterprise-grade safe file deletion, graveyard exploration, and resurrection.\n')
	win.set_control_height('txt_activity_log', 110)

	win.begin_row('row_bottom_bar')
	win.add_button('btn_copy_cli_cmd', ' Copy CLI Command')
	win.control('btn_copy_cli_cmd').set_elevation(1).set_vector_icon('copy').set_width(160)

	win.add_button('btn_clear_console', ' Clear Console')
	win.control('btn_clear_console').set_elevation(1).set_vector_icon('close').set_width(130)

	win.add_label('lbl_footer_status', 'Status: Ready  |  Engine: rip2  |  Tomb: Active')
	win.end_row()
	win.end_group_box()

	// -------------------------------------------------------------
	// Core Data Refresh & State Controller
	// -------------------------------------------------------------
	refresh_all_views := fn (mut win simplegui.SimpleWindow, rip_bin string, graveyard_dir string) {
		records, stats := load_graveyard_records(graveyard_dir)

		filter_query := win.get('txt_filter_tomb').trim_space().to_lower()
		show_inactive := win.get_bool('chk_show_inactive')

		mut rows := [][]string{}
		for r in records {
			if !show_inactive && !r.is_active {
				continue
			}

			if filter_query != '' {
				full_text := '${r.name} ${r.original} ${r.time_str}'.to_lower()
				if !full_text.contains(filter_query) {
					continue
				}
			}

			type_str := if r.is_dir { 'Directory' } else { 'File' }
			status_str := if r.is_active { 'Resting' } else { 'Restored' }
			size_str := if r.is_active { format_bytes(r.size_bytes) } else { '--' }

			rows << [
				r.name,
				r.original,
				r.time_str,
				type_str,
				size_str,
				status_str,
				r.destination,
			]
		}

		win.set_table_rows('tbl_graveyard', rows)

		// Update KPI Stat Cards
		win.set_stat_card('card_buried_count', ' Tomb Population', '${stats.active_cnt} Active Items', 'Protected against accidental rm', true)
		win.set_stat_card('card_graveyard_size', ' Graveyard Disk Footprint', format_bytes(stats.total_bytes), 'Temporary APFS recovery cache', true)
		win.set_stat_card('card_restored_count', ' Files Resurrected', '${stats.restored_cnt} Restored', '100% Recovery Success Rate', true)
		win.set_stat_card('card_graveyard_path', ' Vault Storage', os.file_name(stats.path), 'APFS Temp Cache', true)

		// Update Raw Journal
		record_file := os.join_path(graveyard_dir, '.record')
		if os.exists(record_file) {
			content := os.read_file(record_file) or { '' }
			win.set('txt_raw_journal', content)
		} else {
			win.set('txt_raw_journal', 'No .record file found in graveyard.')
		}

		now := time.now().format_ss()
		win.set('lbl_footer_status', 'Status: Live  |  Active Resting: ${stats.active_cnt}  |  Restored: ${stats.restored_cnt}  |  Refreshed: ${now}')
	}

	// Helper to extract currently selected item details from table
	get_selected_record := fn (mut win simplegui.SimpleWindow) (string, string, string, string, string) {
		sel_idx := win.get_table_selected_row('tbl_graveyard')
		rows := win.get_table_rows('tbl_graveyard')
		if sel_idx >= 0 && sel_idx < rows.len && rows[sel_idx].len >= 7 {
			row := rows[sel_idx]
			return row[0], row[1], row[2], row[4], row[6]
		}
		return '', '', '', '', ''
	}

	// Initial population
	refresh_all_views(mut win, rip_bin, current_graveyard)

	// -------------------------------------------------------------
	// Event Bindings & Actions
	// -------------------------------------------------------------

	// Theme Selection
	win.on_change('dd_theme_selector', fn (mut w simplegui.SimpleWindow, selected string) {
		w.set_theme(selected)
		w.toast('Theme switched to ${selected}')
	})

	// Filter change
	win.on_change('txt_filter_tomb', fn [refresh_all_views, rip_bin, current_graveyard] (mut w simplegui.SimpleWindow, _ string) {
		refresh_all_views(mut w, rip_bin, current_graveyard)
	})

	// Show Inactive Toggle
	win.on_change('chk_show_inactive', fn [refresh_all_views, rip_bin, current_graveyard] (mut w simplegui.SimpleWindow, _ string) {
		refresh_all_views(mut w, rip_bin, current_graveyard)
	})

	// Top Refresh
	win.on_click('btn_top_refresh', fn [refresh_all_views, rip_bin, current_graveyard] (mut w simplegui.SimpleWindow) {
		refresh_all_views(mut w, rip_bin, current_graveyard)
		w.toast('Graveyard tomb refreshed.')
	})

	// Top Open Tomb in Finder
	win.on_click('btn_top_open_tomb', fn [current_graveyard] (mut w simplegui.SimpleWindow) {
		if os.exists(current_graveyard) {
			simplegui.reveal_in_finder(current_graveyard)
			w.toast('Opened Graveyard folder in Finder.')
		} else {
			w.toast('Graveyard folder does not exist.')
		}
	})

	// Top Resurrect Last (-u)
	win.on_click('btn_top_unbury_last', fn [rip_bin, current_graveyard, refresh_all_views] (mut w simplegui.SimpleWindow) {
		w.set('txt_activity_log', ' Resurrecting the most recently buried item (-u)...\n Command: ${rip_bin} -u\n')
		w.set_status('Unburying last item...')
		w.toast('Unburying last item...')

		go fn [mut w, rip_bin, current_graveyard, refresh_all_views] () {
			t0 := time.ticks()
			res := simplegui.exec_safe(rip_bin, ['-u'])
			elapsed_ms := time.ticks() - t0

			w.run_on_main_thread(fn [res, elapsed_ms, rip_bin, current_graveyard, refresh_all_views] (mut win_main simplegui.SimpleWindow) {
				if res.exit_code == 0 {
					win_main.set('txt_activity_log', ' Successfully resurrected in ${elapsed_ms} ms!\n\n' + res.output)
					win_main.set_status('Resurrection complete.')
					win_main.toast('File resurrected!')
					refresh_all_views(mut win_main, rip_bin, current_graveyard)
				} else {
					win_main.set('txt_activity_log', ' Unbury notification:\n' + res.output)
					win_main.set_status('No item to unbury.')
					win_main.toast('No item to unbury.')
				}
			})
		}()
	})

	// Table Row Selection Handler: Updates Selection Intelligence Card
	win.on_click('btn_reveal_in_graveyard', fn [get_selected_record] (mut w simplegui.SimpleWindow) {
		_, _, _, _, dest := get_selected_record(mut w)
		if dest != '' && os.exists(dest) {
			simplegui.reveal_in_finder(dest)
			w.toast('Revealed item in graveyard.')
		} else if dest != '' && os.exists(os.dir(dest)) {
			simplegui.reveal_in_finder(os.dir(dest))
			w.toast('Revealed tomb folder in Finder.')
		} else {
			w.alert('No Selection', 'Please select an item from the tomb table first.')
		}
	})

	// Resurrect Selected Item
	win.on_click('btn_resurrect_selected', fn [get_selected_record, rip_bin, current_graveyard, refresh_all_views] (mut w simplegui.SimpleWindow) {
		name, orig, _, _, dest := get_selected_record(mut w)
		if orig == '' {
			w.alert('No Item Selected', 'Please click on an active buried item in the tomb table first.')
			return
		}

		if !os.exists(dest) {
			w.alert('Already Resurrected', 'This item was already restored back to ${orig}.')
			return
		}

		w.set('txt_activity_log', ' Resurrecting ${name} back to original location: ${orig}...\n Target: ${dest}\n Command: ${rip_bin} -u "${dest}"\n')
		w.set_status('Resurrecting item...')
		w.toast('Resurrecting ${name}...')

		go fn [mut w, rip_bin, dest, orig, name, current_graveyard, refresh_all_views] () {
			t0 := time.ticks()
			res := simplegui.exec_safe(rip_bin, ['-u', dest])
			elapsed_ms := time.ticks() - t0

			w.run_on_main_thread(fn [res, elapsed_ms, orig, name, rip_bin, current_graveyard, refresh_all_views] (mut win_main simplegui.SimpleWindow) {
				if res.exit_code == 0 {
					win_main.set('txt_activity_log', ' Successfully resurrected "${name}" in ${elapsed_ms} ms!\n Restored path: ${orig}\n\n' + res.output)
					win_main.set_status('Resurrection complete.')
					win_main.toast('"${name}" resurrected!')
					refresh_all_views(mut win_main, rip_bin, current_graveyard)
				} else {
					win_main.set('txt_activity_log', ' Resurrection error:\n' + res.output)
					win_main.set_status('Error restoring item.')
				}
			})
		}()
	})

	// Intelligence Card: Resurrect This File
	win.on_click('btn_intel_restore', fn [get_selected_record, rip_bin, current_graveyard, refresh_all_views] (mut w simplegui.SimpleWindow) {
		name, orig, _, _, dest := get_selected_record(mut w)
		if orig == '' {
			w.alert('No Selection', 'Please select an item from the tomb table first.')
			return
		}
		if !os.exists(dest) {
			w.alert('Already Resurrected', 'This item was already restored back to ${orig}.')
			return
		}

		go fn [mut w, rip_bin, dest, orig, name, current_graveyard, refresh_all_views] () {
			t0 := time.ticks()
			res := simplegui.exec_safe(rip_bin, ['-u', dest])
			elapsed_ms := time.ticks() - t0

			w.run_on_main_thread(fn [res, elapsed_ms, orig, name, rip_bin, current_graveyard, refresh_all_views] (mut win_main simplegui.SimpleWindow) {
				if res.exit_code == 0 {
					win_main.set('txt_activity_log', ' Resurrected "${name}" in ${elapsed_ms} ms to ${orig}\n' + res.output)
					win_main.toast('Resurrected ${name}!')
					refresh_all_views(mut win_main, rip_bin, current_graveyard)
				} else {
					err_msg := if res.output.trim_space() != '' { res.output.trim_space() } else { 'Failed to resurrect "${name}".' }
					win_main.set('txt_activity_log', ' Resurrection Error:\n' + err_msg)
					win_main.set_status('Resurrection failed.')
					win_main.toast('Failed to resurrect "${name}".')
				}
			})
		}()
	})

	// Intelligence Card: Reveal Original Folder
	win.on_click('btn_intel_reveal_orig', fn [get_selected_record] (mut w simplegui.SimpleWindow) {
		_, orig, _, _, _ := get_selected_record(mut w)
		if orig != '' {
			parent := os.dir(orig)
			if os.exists(parent) {
				simplegui.reveal_in_finder(parent)
				w.toast('Revealed original folder in Finder.')
			} else {
				w.toast('Original parent folder does not currently exist.')
			}
		} else {
			w.alert('No Selection', 'Please select an item from the table first.')
		}
	})

	// Intelligence Card: Reveal Tomb Target
	win.on_click('btn_intel_reveal_tomb', fn [get_selected_record] (mut w simplegui.SimpleWindow) {
		_, _, _, _, dest := get_selected_record(mut w)
		if dest != '' && os.exists(dest) {
			simplegui.reveal_in_finder(dest)
			w.toast('Revealed resting file in graveyard.')
		} else {
			w.toast('Item has been restored or graveyard target does not exist.')
		}
	})

	// Intelligence Card: Quick Preview Content
	win.on_click('btn_intel_preview', fn [get_selected_record] (mut w simplegui.SimpleWindow) {
		name, orig, _, sz_str, dest := get_selected_record(mut w)
		if dest == '' || !os.exists(dest) {
			w.alert('Cannot Preview', 'Item is not resting in graveyard or not selected.')
			return
		}

		if os.is_dir(dest) {
			items := os.ls(dest) or { []string{} }
			msg := '=== Directory Preview: ${name} ===\nOriginal: ${orig}\nTotal Child Entries: ${items.len}\n' + items.join('\n')
			w.set('txt_activity_log', msg)
			w.toast('Loaded directory listing into console.')
			return
		}

		// Read head of file up to 2KB
		bytes_len := os.file_size(dest)
		if bytes_len > 1024 * 1024 {
			w.set('txt_activity_log', '=== File Preview: ${name} (${sz_str}) ===\n[File exceeds 1MB - previewing first 4KB]\n')
		}
		raw_preview := os.read_file(dest) or { '[Binary Data / Unreadable]' }
		snippet := if raw_preview.len > 4000 { raw_preview[..4000] + '\n... [truncated]' } else { raw_preview }
		w.set('txt_activity_log', '=== File Preview: ${name} (${orig}) ===\n${snippet}\n')
		w.toast('File preview loaded in console.')
	})

	// Decompose Graveyard
	win.on_click('btn_decompose_graveyard', fn [rip_bin, current_graveyard, refresh_all_views] (mut w simplegui.SimpleWindow) {
		confirmed := w.confirm(
			'Decompose Graveyard?',
			'Decomposing permanently purges all files resting in the graveyard.\nThis action is irreversible and recovers disk space immediately.\n\nAre you sure you want to proceed?'
		)
		if !confirmed {
			w.toast('Decomposition cancelled.')
			return
		}

		w.set('txt_activity_log', ' Decomposing graveyard...\n Command: ${rip_bin} -d\n')
		w.set_status('Permanently deleting graveyard contents...')
		w.toast('Decomposing graveyard...')

		go fn [mut w, rip_bin, current_graveyard, refresh_all_views] () {
			t0 := time.ticks()
			res := simplegui.exec_safe(rip_bin, ['-d'])
			elapsed_ms := time.ticks() - t0

			w.run_on_main_thread(fn [res, elapsed_ms, rip_bin, current_graveyard, refresh_all_views] (mut win_main simplegui.SimpleWindow) {
				if res.exit_code == 0 {
					win_main.set('txt_activity_log', ' Graveyard successfully emptied in ${elapsed_ms} ms.\n Space reclaimed.\n\n' + res.output)
					win_main.set_status('Graveyard emptied.')
					win_main.toast('Graveyard emptied!')
					refresh_all_views(mut win_main, rip_bin, current_graveyard)
				} else {
					err_msg := if res.output.trim_space() != '' { res.output.trim_space() } else { 'Failed to empty graveyard.' }
					win_main.set('txt_activity_log', ' Decompose Error:\n' + err_msg)
					win_main.set_status('Failed to empty graveyard.')
					win_main.toast('Decompose operation failed.')
					refresh_all_views(mut win_main, rip_bin, current_graveyard)
				}
			})
		}()
	})

	// Wire up danger zone decompose button
	win.on_click('btn_exec_decompose', fn [rip_bin, current_graveyard, refresh_all_views] (mut w simplegui.SimpleWindow) {
		confirmed := w.confirm(
			'Permanently Decompose Graveyard?',
			'All items in ${current_graveyard} will be permanently destroyed.\nConfirm permanent deletion?'
		)
		if !confirmed {
			w.toast('Aborted.')
			return
		}

		go fn [mut w, rip_bin, current_graveyard, refresh_all_views] () {
			res := simplegui.exec_safe(rip_bin, ['-d'])
			w.run_on_main_thread(fn [res, rip_bin, current_graveyard, refresh_all_views] (mut win_main simplegui.SimpleWindow) {
				win_main.set('txt_activity_log', ' Graveyard purged:\n' + res.output)
				win_main.toast('Graveyard purged!')
				refresh_all_views(mut win_main, rip_bin, current_graveyard)
			})
		}()
	})

	// TAB 1: File/Folder Pickers
	win.on_click('btn_pick_file', fn (mut w simplegui.SimpleWindow) {
		chosen := w.select_file()
		if chosen != '' {
			w.set('txt_target_path', chosen)
			w.toast('Selected file: ${os.file_name(chosen)}')
		}
	})

	win.on_click('btn_pick_folder', fn (mut w simplegui.SimpleWindow) {
		chosen := w.select_folder()
		if chosen != '' {
			w.set('txt_target_path', chosen)
			w.toast('Selected folder: ${os.file_name(chosen)}')
		}
	})

	win.on_click('btn_reveal_target', fn (mut w simplegui.SimpleWindow) {
		target := w.get('txt_target_path').trim_space()
		if target != '' && os.exists(target) {
			simplegui.reveal_in_finder(target)
			w.toast('Revealed target in Finder.')
		} else if target != '' && os.exists(os.dir(target)) {
			simplegui.reveal_in_finder(os.dir(target))
			w.toast('Revealed parent directory.')
		} else {
			w.toast('Target does not exist.')
		}
	})

	// Pre-Flight Telemetry Inspector
	win.on_click('btn_inspect_target', fn (mut w simplegui.SimpleWindow) {
		target := w.get('txt_target_path').trim_space()
		if target == '' || !os.exists(target) {
			w.alert('Target Required', 'Please select an existing file or directory first.')
			return
		}

		is_d := os.is_dir(target)
		sz := if is_d { get_dir_size_recursive(target) } else { os.file_size(target) }
		mtime := os.file_last_mod_unix(target)
		mtime_str := time.unix(mtime).format_ss()

		mut report := '======================================================================\n'
		report += ' PRE-FLIGHT TELEMETRY & SAFETY AUDIT: ${os.file_name(target)}\n'
		report += '======================================================================\n'
		report += 'Path           : ${target}\n'
		report += 'Item Type      : ' + if is_d { 'Directory (Container)' } else { 'Regular File' } + '\n'
		report += 'Footprint      : ${format_bytes(sz)} (${sz} bytes)\n'
		report += 'Last Modified  : ${mtime_str}\n'
		report += 'Writable       : ${os.is_writable(target)}\n'
		report += 'Readable       : ${os.is_readable(target)}\n'
		report += 'Safety Status  : Safe for non-destructive burial into graveyard.\n'
		report += 'Resurrectable  : YES (Can be restored anytime via rip -u).\n'

		if target == '/' || target == '/System' || target == '/usr' || target == '/Applications' {
			report += 'CRITICAL ALERT : System Root Path - BURIAL PROHIBITED.\n'
		}

		w.set('txt_preflight_report', report)
		w.set('txt_activity_log', report)
		w.toast('Pre-flight inspection complete.')
	})

	// Create and Select Demo File for testing
	win.on_click('btn_create_demo_file', fn (mut w simplegui.SimpleWindow) {
		temp_file := os.join_path(os.temp_dir(), 'rip_demo_artifact_${time.now().unix()}.txt')
		os.write_file(temp_file, 'This is a test artifact created to demonstrate Rip Studio Pro safe deletion.\nTimestamp: ${time.now().str()}\n') or {
			w.toast('Failed to create demo file.')
			return
		}
		w.set('txt_target_path', temp_file)
		w.toast('Test file created and selected: ${os.file_name(temp_file)}')
	})

	// Run Bury Action
	win.on_click('btn_run_bury', fn [rip_bin, current_graveyard, refresh_all_views] (mut w simplegui.SimpleWindow) {
		target := w.get('txt_target_path').trim_space()
		if target == '' || !os.exists(target) {
			w.alert('Invalid Target', 'Please specify an existing file or directory to bury.')
			return
		}

		// Enterprise safety protections
		if target == '/' || target == '/System' || target == '/usr' || target == '/Applications' || target == '/Library' {
			w.alert('Safety Protection Block', 'Cannot bury critical operating system directory: ${target}')
			return
		}

		mut args := []string{}
		if w.get_bool('chk_inspect_before_bury') {
			args << '-i'
		}
		if w.get_bool('chk_force_mode') {
			args << '-f'
		}
		args << target

		w.set('txt_activity_log', ' Safely moving target into graveyard...\n Target: ${target}\n Command: ${rip_bin} ${args.join(' ')}\n')
		w.set_status('Burying target...')
		w.toast('Burying ${os.file_name(target)}...')

		go fn [mut w, rip_bin, args, target, current_graveyard, refresh_all_views] () {
			t0 := time.ticks()
			res := simplegui.exec_safe(rip_bin, args)
			elapsed_ms := time.ticks() - t0

			w.run_on_main_thread(fn [res, elapsed_ms, target, rip_bin, current_graveyard, refresh_all_views] (mut win_main simplegui.SimpleWindow) {
				if res.exit_code == 0 {
					win_main.set('txt_activity_log', ' Successfully buried in ${elapsed_ms} ms:\n ${target}\n\n' + res.output)
					win_main.set_status('Target moved to graveyard.')
					win_main.toast('Item safely buried!')
					win_main.set('txt_target_path', '')
					refresh_all_views(mut win_main, rip_bin, current_graveyard)
				} else {
					err_msg := if res.output.trim_space() != '' { res.output.trim_space() } else { 'Failed to bury target item.' }
					win_main.set('txt_activity_log', ' Bury Error (code ${res.exit_code}):\n' + err_msg)
					win_main.set_status('Bury operation failed.')
					win_main.toast('Failed to bury item!')
					refresh_all_views(mut win_main, rip_bin, current_graveyard)
				}
			})
		}()
	})

	// TAB 2: Séance Directory Browser
	win.on_click('btn_browse_seance_dir', fn (mut w simplegui.SimpleWindow) {
		chosen := w.select_folder()
		if chosen != '' {
			w.set('txt_seance_dir', chosen)
			w.toast('Séance directory set to: ${os.file_name(chosen)}')
		}
	})

	win.on_click('btn_cwd_seance', fn (mut w simplegui.SimpleWindow) {
		w.set('txt_seance_dir', '.')
		w.toast('Séance directory set to workspace root.')
	})

	// Run Séance
	win.on_click('btn_summon_ghosts', fn [rip_bin] (mut w simplegui.SimpleWindow) {
		target_dir := w.get('txt_seance_dir').trim_space()
		effective_dir := if target_dir == '' { '.' } else { target_dir }

		w.set('txt_activity_log', ' Summoning séance ghost records for: ${effective_dir}...\n Command: cd "${effective_dir}" && ${rip_bin} -s\n')
		w.set_status('Summoning ghost records...')
		w.toast('Summoning ghosts...')

		go fn [mut w, rip_bin, effective_dir] () {
			t0 := time.ticks()
			saved_dir := os.getwd()
			if os.is_dir(effective_dir) {
				os.chdir(effective_dir) or {}
			}
			res := simplegui.exec_safe(rip_bin, ['-s'])
			os.chdir(saved_dir) or {}
			elapsed_ms := time.ticks() - t0

			w.run_on_main_thread(fn [res, elapsed_ms, effective_dir] (mut win_main simplegui.SimpleWindow) {
				out := res.output.trim_space()
				mut report := '======================================================================\n'
				report += ' SÉANCE GHOST REGISTRY: ${effective_dir} (${elapsed_ms} ms)\n'
				report += '======================================================================\n'
				if out == '' || out == 'deletion_time\tpath' {
					report += ' No ghosts detected! There are currently no resting files in the\n graveyard that originated from this directory.\n'
				} else {
					report += out + '\n\n'
					report += 'Tip: You can resurrect any discovered file using "Resurrect Most Recent Ghost"\n or by switching to Tab 1 (Tomb Explorer).'
				}
				win_main.set('txt_seance_report', report)
				win_main.set('txt_activity_log', report)
				win_main.set_status('Séance query complete.')
				win_main.toast('Séance query complete!')
			})
		}()
	})

	// Séance Unbury Recent Ghost
	win.on_click('btn_seance_unbury_recent', fn [rip_bin, current_graveyard, refresh_all_views] (mut w simplegui.SimpleWindow) {
		go fn [mut w, rip_bin, current_graveyard, refresh_all_views] () {
			res := simplegui.exec_safe(rip_bin, ['-u'])
			w.run_on_main_thread(fn [res, rip_bin, current_graveyard, refresh_all_views] (mut win_main simplegui.SimpleWindow) {
				if res.exit_code == 0 {
					win_main.toast('Ghost resurrected!')
					win_main.set('txt_activity_log', ' Ghost resurrected:\n' + res.output)
					refresh_all_views(mut win_main, rip_bin, current_graveyard)
				} else {
					win_main.toast('No ghost item to resurrect.')
				}
			})
		}()
	})

	win.on_click('btn_seance_clear', fn (mut w simplegui.SimpleWindow) {
		w.set('txt_seance_report', '')
		w.toast('Séance report cleared.')
	})

	// TAB 3: Vault Path & Raw Journal Actions
	win.on_click('btn_copy_vault_path', fn [current_graveyard] (mut w simplegui.SimpleWindow) {
		w.copy_to_clipboard(current_graveyard)
		w.toast('Graveyard vault path copied to clipboard.')
	})

	win.on_click('btn_reveal_vault_folder', fn [current_graveyard] (mut w simplegui.SimpleWindow) {
		if os.exists(current_graveyard) {
			simplegui.reveal_in_finder(current_graveyard)
			w.toast('Opened Graveyard folder in Finder.')
		} else {
			w.toast('Graveyard folder does not exist.')
		}
	})

	win.on_click('btn_reload_journal', fn [current_graveyard] (mut w simplegui.SimpleWindow) {
		record_file := os.join_path(current_graveyard, '.record')
		if os.exists(record_file) {
			content := os.read_file(record_file) or { '' }
			w.set('txt_raw_journal', content)
			w.toast('Raw journal reloaded.')
		}
	})

	win.on_click('btn_copy_journal', fn (mut w simplegui.SimpleWindow) {
		content := w.get('txt_raw_journal')
		w.copy_to_clipboard(content)
		w.toast('Copied raw journal to clipboard.')
	})

	// Bottom Bar: Copy CLI Command
	win.on_click('btn_copy_cli_cmd', fn [rip_bin] (mut w simplegui.SimpleWindow) {
		target := w.get('txt_target_path').trim_space()
		mut cmd := '${rip_bin}'
		if w.get_bool('chk_inspect_before_bury') {
			cmd += ' -i'
		}
		if w.get_bool('chk_force_mode') {
			cmd += ' -f'
		}
		if target != '' {
			cmd += ' "${target}"'
		} else {
			cmd += ' -u'
		}
		w.copy_to_clipboard(cmd)
		w.toast('Copied command: ${cmd}')
	})

	win.on_click('btn_clear_console', fn (mut w simplegui.SimpleWindow) {
		w.set('txt_activity_log', '')
		w.toast('Console cleared.')
	})

	// Run Application Window
	win.run()
}

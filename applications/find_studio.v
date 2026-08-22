module main

import simplegui
import os
import time

// -----------------------------------------------------------------------------
// Find Preset Recipe Struct
// -----------------------------------------------------------------------------
struct FindRecipe {
	title        string
	category     string
	name_pat     string
	type_sel     string
	size_filter  string
	time_filter  string
	depth_max    string
	exclude_dirs string
	perm_filter  string
	desc         string
}

fn get_all_find_recipes() []FindRecipe {
	return [
		FindRecipe{
			title: ' Clean System Cruft (.DS_Store, *.tmp, *~, *.swp)'
			category: 'Maintenance'
			name_pat: '*.tmp, .DS_Store, *~, *.swp, *.bak'
			type_sel: 'Files (f)'
			size_filter: 'Any'
			time_filter: 'Any Time'
			depth_max: 'Unlimited'
			exclude_dirs: '.git'
			perm_filter: ''
			desc: 'Finds macOS metadata, editor swap files, and temporary leftover artifacts.'
		},
		FindRecipe{
			title: ' Enormous Large Files (>500MB Disk Cleanup)'
			category: 'Storage'
			name_pat: '*'
			type_sel: 'Files (f)'
			size_filter: '> 500 MB'
			time_filter: 'Any Time'
			depth_max: 'Unlimited'
			exclude_dirs: '.git'
			perm_filter: ''
			desc: 'Identifies space-consuming disk hogs, ISOs, virtual disks, and database dumps.'
		},
		FindRecipe{
			title: ' Recently Modified Files (Last 24 Hours)'
			category: 'Activity'
			name_pat: '*'
			type_sel: 'Files (f)'
			size_filter: 'Any'
			time_filter: 'Modified in last 24h (-1d)'
			depth_max: 'Unlimited'
			exclude_dirs: '.git, node_modules'
			perm_filter: ''
			desc: 'Discovers files created or modified within the past day.'
		},
		FindRecipe{
			title: ' Empty Files & Zero-Byte Artifacts'
			category: 'Maintenance'
			name_pat: '*'
			type_sel: 'Files (f)'
			size_filter: 'Empty (0 Bytes)'
			time_filter: 'Any Time'
			depth_max: 'Unlimited'
			exclude_dirs: '.git'
			perm_filter: ''
			desc: 'Finds blank files taking up inode space.'
		},
		FindRecipe{
			title: ' Node Modules & Build Folders'
			category: 'Storage'
			name_pat: 'node_modules, target, .build, bin, obj, dist'
			type_sel: 'Directories (d)'
			size_filter: 'Any'
			time_filter: 'Any Time'
			depth_max: 'Unlimited'
			exclude_dirs: '.git'
			perm_filter: ''
			desc: 'Finds heavy dependency and compiler build output directories.'
		},
		FindRecipe{
			title: ' Private Keys & Sensitive Env Files'
			category: 'Security'
			name_pat: '*.pem, *.key, id_rsa*, id_ed25519*, *.pfx, *.p12, .env*'
			type_sel: 'Files (f)'
			size_filter: 'Any'
			time_filter: 'Any Time'
			depth_max: 'Unlimited'
			exclude_dirs: '.git'
			perm_filter: ''
			desc: 'Audits sensitive security certificates, SSH private keys, and environment files.'
		},
		FindRecipe{
			title: ' Executable Binaries & Shell Scripts'
			category: 'Audit'
			name_pat: '*'
			type_sel: 'Files (f)'
			size_filter: 'Any'
			time_filter: 'Any Time'
			depth_max: 'Unlimited'
			exclude_dirs: '.git'
			perm_filter: 'Executable (+111)'
			desc: 'Finds runnable scripts and executable binaries across folders.'
		},
		FindRecipe{
			title: ' Stale Log Files (>30 Days Old)'
			category: 'Maintenance'
			name_pat: '*.log, *.out, *.trace'
			type_sel: 'Files (f)'
			size_filter: 'Any'
			time_filter: 'Older than 30 days (+30d)'
			depth_max: 'Unlimited'
			exclude_dirs: '.git'
			perm_filter: ''
			desc: 'Finds old unrotated log files ready for archiving or deletion.'
		},
		FindRecipe{
			title: ' Broken / Dangling Symbolic Links'
			category: 'Diagnostics'
			name_pat: '*'
			type_sel: 'Symlinks (l)'
			size_filter: 'Any'
			time_filter: 'Any Time'
			depth_max: 'Unlimited'
			exclude_dirs: '.git'
			perm_filter: ''
			desc: 'Lists all symbolic links across the directory tree.'
		},
		FindRecipe{
			title: ' Source Code Tree (.v, .rs, .go, .py, .ts, .c)'
			category: 'Developer'
			name_pat: '*.v, *.rs, *.go, *.py, *.ts, *.js, *.c, *.h, *.cpp'
			type_sel: 'Files (f)'
			size_filter: 'Any'
			time_filter: 'Any Time'
			depth_max: 'Unlimited'
			exclude_dirs: '.git, node_modules, target, .build'
			perm_filter: ''
			desc: 'Lists all software source files while skipping vendor/build trees.'
		}
	]
}

fn get_find_bin() string {
	for candidate in ['/usr/bin/find', '/bin/find', '/opt/homebrew/bin/gfind'] {
		if os.exists(candidate) {
			return candidate
		}
	}
	return 'find'
}

fn main() {
	println('Starting SimpleGUI - Find Studio Pro (POSIX/macOS find Filesystem Explorer)...')

	mut win := simplegui.new_simple_window('Find Studio Pro -- Advanced Filesystem Search & Filter Workbench', 1040, 920)
	win.set_fullscreen(true)
	win.restore_saved_theme()
	win.set_spacing(8)
	win.set_padding(16)

	find_bin := get_find_bin()
	all_recipes := get_all_find_recipes()

	// -------------------------------------------------------------
	// Header & Theme Selector
	// -------------------------------------------------------------
	win.begin_row('row_header')
	win.add_heading('Find Studio Pro')

	saved_theme := simplegui.get_saved_theme()
	win.add_dropdown('dd_theme_selector', simplegui.list_themes(), saved_theme)
	win.set_control_width('dd_theme_selector', 180)
	win.end_row()

	win.add_label('lbl_engine_info', 'Engine: ${find_bin} (POSIX/BSD find)  |  Platform: macOS Cocoa  |  Mode: Non-Blocking Safe Worker')

	// -------------------------------------------------------------
	// Scope & Target Directory
	// -------------------------------------------------------------
	win.begin_group_box('grp_scope', 'Search Root Scope & Path')

	win.begin_row('row_target_dir')
	win.add_label('lbl_dir', 'Target Directory:')
	win.add_input('txt_target_dir', os.getwd())
	win.set_control_width('txt_target_dir', 480)
	win.add_button('btn_browse_dir', 'Browse...')
	win.add_button('btn_home_dir', 'Home (~)')
	win.add_button('btn_tmp_dir', 'Temp (/tmp)')
	win.add_button('btn_reveal_dir', 'Reveal in Finder')
	win.end_row()
	win.end_group_box()

	// -------------------------------------------------------------
	// Preset Recipes
	// -------------------------------------------------------------
	win.begin_group_box('grp_recipes', 'Production Search & Maintenance Recipes')

	mut recipe_titles := ['-- Select a Preset Find Recipe --']
	for r in all_recipes {
		recipe_titles << '[${r.category}] ${r.title}'
	}

	win.begin_row('row_recipes_bar')
	win.add_label('lbl_rec_sel', 'Recipe:')
	win.add_dropdown('dd_recipe', recipe_titles, recipe_titles[0])
	win.set_control_width('dd_recipe', 480)
	win.add_button('btn_apply_recipe', 'Load Recipe')
	win.add_button('btn_run_recipe_now', 'Load & Find Now')
	win.end_row()

	win.begin_row('row_rec_desc')
	win.add_label('lbl_recipe_desc', 'Tip: Select a recipe to quickly search for large files, temp cruft, stale logs, or code.')
	win.end_row()
	win.end_group_box()

	// -------------------------------------------------------------
	// Search Criteria & Filters
	// -------------------------------------------------------------
	win.begin_group_box('grp_filters', 'Filter Criteria (Name, Inode Type, Size, Depth, Age)')

	win.begin_row('row_name_type')
	win.add_label('lbl_name', 'Name Pattern:')
	win.add_input('txt_name', '*')
	win.set_control_width('txt_name', 260)

	win.add_checkbox('chk_case_i', 'Case-Insensitive (-iname)', true)

	win.add_label('lbl_type', 'Entry Type:')
	win.add_dropdown('dd_type', [
		'All Entries',
		'Files (f)',
		'Directories (d)',
		'Symlinks (l)',
		'Sockets (s)',
		'Pipes (p)'
	], 'All Entries')
	win.set_control_width('dd_type', 140)
	win.end_row()

	win.begin_row('row_size_depth')
	win.add_label('lbl_size', 'Size Filter:')
	win.add_dropdown('dd_size', [
		'Any',
		'> 1 GB',
		'> 500 MB',
		'> 100 MB',
		'> 10 MB',
		'> 1 MB',
		'< 1 MB',
		'< 100 KB',
		'Empty (0 Bytes)'
	], 'Any')
	win.set_control_width('dd_size', 130)

	win.add_label('lbl_time', 'Modified Age:')
	win.add_dropdown('dd_time', [
		'Any Time',
		'Modified in last 60 mins (-60m)',
		'Modified in last 24h (-1d)',
		'Modified in last 7 days (-7d)',
		'Older than 30 days (+30d)',
		'Older than 90 days (+90d)',
		'Older than 1 year (+365d)'
	], 'Any Time')
	win.set_control_width('dd_time', 210)

	win.add_label('lbl_depth', 'Max Depth:')
	win.add_dropdown('dd_depth', [
		'Unlimited',
		'1 Level (Root only)',
		'2 Levels',
		'3 Levels',
		'5 Levels',
		'10 Levels'
	], 'Unlimited')
	win.set_control_width('dd_depth', 130)
	win.end_row()

	win.begin_row('row_excludes')
	win.add_label('lbl_exclude', 'Exclude Dirs:')
	win.add_input('txt_exclude', '.git, node_modules, .build, target')
	win.set_control_width('txt_exclude', 380)

	win.add_label('lbl_perm', 'Permission:')
	win.add_dropdown('dd_perm', [
		'Any',
		'Executable (+111)',
		'Readable (444)',
		'Writable (644)',
		'World Writable (+002)'
	], 'Any')
	win.set_control_width('dd_perm', 160)

	win.add_checkbox('chk_details', 'Detailed Info (-ls)', false)
	win.end_row()
	win.end_group_box()

	// -------------------------------------------------------------
	// Action Execution Toolbar
	// -------------------------------------------------------------
	win.begin_row('row_actions')
	win.add_button('btn_run_find', 'Run Find Search')
	win.add_button('btn_copy_paths', 'Copy Results to Clipboard')
	win.add_button('btn_copy_cmd', 'Copy Shell Command')
	win.add_button('btn_export_csv', 'Export Results (TXT/CSV)...')
	win.add_button('btn_clear_log', 'Clear Output')
	win.end_row()

	// -------------------------------------------------------------
	// Results Output Pane
	// -------------------------------------------------------------
	win.begin_group_box('grp_results', 'Search Output & Matched File / Directory Inodes')
	win.add_textarea('txt_results', '')
	win.set_control_height('txt_results', 280)
	win.end_group_box()

	win.begin_row('row_status')
	win.add_label('lbl_status', 'Status: Ready  |  Matches: 0  |  Elapsed: 0 ms')
	win.end_row()

	win.set('txt_results', ' Find Studio Pro ready. Select target scope and click "Run Find Search".\n')

	// Helper to assemble find arguments
	build_find_args := fn (win simplegui.SimpleWindow) []string {
		mut dir := win.get('txt_target_dir').trim_space()
		if dir == '' { dir = '.' }

		mut args := [dir]

		// Exclude directories (-name X -prune -o)
		excludes_str := win.get('txt_exclude').trim_space()
		if excludes_str != '' {
			ex_list := excludes_str.split(',').map(it.trim_space()).filter(it != '')
			for ex in ex_list {
				args << ['-name', ex, '-prune', '-o']
			}
		}

		// Depth
		depth_sel := win.get('dd_depth')
		if depth_sel.contains('1 Level') { args << ['-maxdepth', '1'] }
		else if depth_sel.contains('2 Levels') { args << ['-maxdepth', '2'] }
		else if depth_sel.contains('3 Levels') { args << ['-maxdepth', '3'] }
		else if depth_sel.contains('5 Levels') { args << ['-maxdepth', '5'] }
		else if depth_sel.contains('10 Levels') { args << ['-maxdepth', '10'] }

		// Type
		type_sel := win.get('dd_type')
		if type_sel.contains('Files') { args << ['-type', 'f'] }
		else if type_sel.contains('Directories') { args << ['-type', 'd'] }
		else if type_sel.contains('Symlinks') { args << ['-type', 'l'] }
		else if type_sel.contains('Sockets') { args << ['-type', 's'] }
		else if type_sel.contains('Pipes') { args << ['-type', 'p'] }

		// Name Patterns (supports comma separated list like "*.tmp, *.bak")
		name_input := win.get('txt_name').trim_space()
		case_i := win.get_bool('chk_case_i')
		name_flag := if case_i { '-iname' } else { '-name' }

		if name_input != '' && name_input != '*' {
			patterns := name_input.split(',').map(it.trim_space()).filter(it != '')
			if patterns.len == 1 {
				args << [name_flag, patterns[0]]
			} else if patterns.len > 1 {
				args << '('
				for i, p in patterns {
					if i > 0 { args << '-o' }
					args << [name_flag, p]
				}
				args << ')'
			}
		}

		// Size
		size_sel := win.get('dd_size')
		if size_sel.contains('> 1 GB') { args << ['-size', '+1G'] }
		else if size_sel.contains('> 500 MB') { args << ['-size', '+500M'] }
		else if size_sel.contains('> 100 MB') { args << ['-size', '+100M'] }
		else if size_sel.contains('> 10 MB') { args << ['-size', '+10M'] }
		else if size_sel.contains('> 1 MB') { args << ['-size', '+1M'] }
		else if size_sel.contains('< 1 MB') { args << ['-size', '-1M'] }
		else if size_sel.contains('< 100 KB') { args << ['-size', '-100k'] }
		else if size_sel.contains('Empty') { args << ['-size', '0'] }

		// Age / Modified Time
		time_sel := win.get('dd_time')
		if time_sel.contains('-60m') { args << ['-mmin', '-60'] }
		else if time_sel.contains('-1d') { args << ['-mtime', '-1'] }
		else if time_sel.contains('-7d') { args << ['-mtime', '-7'] }
		else if time_sel.contains('+30d') { args << ['-mtime', '+30'] }
		else if time_sel.contains('+90d') { args << ['-mtime', '+90'] }
		else if time_sel.contains('+365d') { args << ['-mtime', '+365'] }

		// Permissions
		perm_sel := win.get('dd_perm')
		if perm_sel.contains('+111') { args << ['-perm', '+111'] }
		else if perm_sel.contains('444') { args << ['-perm', '444'] }
		else if perm_sel.contains('644') { args << ['-perm', '644'] }
		else if perm_sel.contains('+002') { args << ['-perm', '+002'] }

		// Detailed Listing or Print
		if win.get_bool('chk_details') {
			args << '-ls'
		} else {
			args << '-print'
		}

		return args
	}

	// -------------------------------------------------------------
	// Event Handlers
	// -------------------------------------------------------------

	// Theme Switching
	win.on_change('dd_theme_selector', fn (mut w simplegui.SimpleWindow, selected string) {
		w.set_theme(selected)
		w.toast('Theme changed to ${selected}')
	})

	// Folder selection buttons
	win.on_click('btn_browse_dir', fn (mut w simplegui.SimpleWindow) {
		chosen := w.select_folder()
		if chosen != '' && os.is_dir(chosen) {
			w.set('txt_target_dir', chosen)
			w.toast('Target scope updated.')
		}
	})
	win.on_click('btn_home_dir', fn (mut w simplegui.SimpleWindow) {
		w.set('txt_target_dir', os.home_dir())
		w.toast('Scope set to Home folder.')
	})
	win.on_click('btn_tmp_dir', fn (mut w simplegui.SimpleWindow) {
		w.set('txt_target_dir', '/tmp')
		w.toast('Scope set to /tmp.')
	})
	win.on_click('btn_reveal_dir', fn (mut w simplegui.SimpleWindow) {
		dir := w.get('txt_target_dir').trim_space()
		if dir != '' && os.exists(dir) {
			simplegui.reveal_in_finder(dir)
			w.toast('Revealed in Finder.')
		}
	})

	// Recipe Selection Change
	win.on_change('dd_recipe', fn [all_recipes] (mut w simplegui.SimpleWindow, selected string) {
		for r in all_recipes {
			if selected.contains(r.title) {
				w.set('lbl_recipe_desc', 'Tip: ' + r.desc)
				break
			}
		}
	})

	// Apply Recipe
	win.on_click('btn_apply_recipe', fn [all_recipes] (mut w simplegui.SimpleWindow) {
		selected := w.get('dd_recipe')
		for r in all_recipes {
			if selected.contains(r.title) {
				w.set('txt_name', r.name_pat)
				w.set_text('dd_type', r.type_sel)
				w.set_text('dd_size', r.size_filter)
				w.set_text('dd_time', r.time_filter)
				w.set_text('dd_depth', r.depth_max)
				w.set('txt_exclude', r.exclude_dirs)
				if r.perm_filter != '' {
					w.set_text('dd_perm', r.perm_filter)
				} else {
					w.set_text('dd_perm', 'Any')
				}
				w.set('lbl_recipe_desc', 'Tip: ' + r.desc)
				w.toast('Loaded recipe: ' + r.title)
				return
			}
		}
		w.toast('Please select a recipe from the dropdown.')
	})

	// Run Find Search (Async Engine)
	win.on_click('btn_run_find', fn [find_bin, build_find_args] (mut w simplegui.SimpleWindow) {
		args := build_find_args(w)
		w.set_status('Running find filesystem scan in background...')
		w.toast('Searching filesystem...')

		go fn [mut w, find_bin, args] () {
			t0 := time.ticks()
			res := simplegui.exec_safe(find_bin, args)
			elapsed_ms := time.ticks() - t0

			w.run_on_main_thread(fn [res, elapsed_ms] (mut win_main simplegui.SimpleWindow) {
				if res.exit_code == 0 {
					lines := res.output.split_into_lines().filter(it.trim_space() != '')
					win_main.set('txt_results', res.output)
					win_main.set('lbl_status', ' Status: Search complete  |  Matches: ${lines.len}  |  Elapsed: ${elapsed_ms} ms')
					win_main.set_status('Find search completed.')
					win_main.toast('Found ${lines.len} matching items!')
				} else {
					win_main.set('txt_results', ' Find search error:\n' + res.output)
					win_main.set_status('Error executing find.')
				}
			})
		}()
	})

	// Load & Run Recipe Immediately
	win.on_click('btn_run_recipe_now', fn [all_recipes, find_bin, build_find_args] (mut w simplegui.SimpleWindow) {
		selected := w.get('dd_recipe')
		for r in all_recipes {
			if selected.contains(r.title) {
				w.set('txt_name', r.name_pat)
				w.set_text('dd_type', r.type_sel)
				w.set_text('dd_size', r.size_filter)
				w.set_text('dd_time', r.time_filter)
				w.set_text('dd_depth', r.depth_max)
				w.set('txt_exclude', r.exclude_dirs)
				if r.perm_filter != '' {
					w.set_text('dd_perm', r.perm_filter)
				} else {
					w.set_text('dd_perm', 'Any')
				}
				w.set('lbl_recipe_desc', 'Tip: ' + r.desc)

				args := build_find_args(w)
				w.set_status('Executing recipe scan...')
				w.toast('Running recipe...')

				go fn [mut w, find_bin, args] () {
					t0 := time.ticks()
					res := simplegui.exec_safe(find_bin, args)
					elapsed_ms := time.ticks() - t0

					w.run_on_main_thread(fn [res, elapsed_ms] (mut win_main simplegui.SimpleWindow) {
						if res.exit_code == 0 {
							lines := res.output.split_into_lines().filter(it.trim_space() != '')
							win_main.set('txt_results', res.output)
							win_main.set('lbl_status', ' Status: Recipe complete  |  Matches: ${lines.len}  |  Elapsed: ${elapsed_ms} ms')
							win_main.set_status('Recipe search complete.')
						}
					})
				}()
				return
			}
		}
		w.toast('Please select a recipe from the dropdown.')
	})

	// Copy Results to Clipboard
	win.on_click('btn_copy_paths', fn (mut w simplegui.SimpleWindow) {
		content := w.get('txt_results').trim_space()
		if content == '' {
			w.alert('Output Empty', 'No search results to copy.')
			return
		}
		w.copy_to_clipboard(content)
		w.toast('Results copied to clipboard!')
	})

	// Copy CLI Shell Command
	win.on_click('btn_copy_cmd', fn [find_bin, build_find_args] (mut w simplegui.SimpleWindow) {
		args := build_find_args(w)
		mut quoted_args := []string{}
		for a in args {
			quoted_args << simplegui.quote_arg(a)
		}
		cmd := '${find_bin} ${quoted_args.join(' ')}'
		w.copy_to_clipboard(cmd)
		w.toast('Command copied to clipboard!')
	})

	// Export Results to File
	win.on_click('btn_export_csv', fn (mut w simplegui.SimpleWindow) {
		content := w.get('txt_results').trim_space()
		if content == '' {
			w.alert('Output Empty', 'No results available to export.')
			return
		}
		out_path := w.save_file_picker()
		if out_path != '' {
			os.write_file(out_path, content) or {
				w.alert('Export Error', 'Failed to write output to ${out_path}')
				return
			}
			w.toast('Exported results to ' + os.file_name(out_path))
		}
	})

	// Clear Output
	win.on_click('btn_clear_log', fn (mut w simplegui.SimpleWindow) {
		w.set('txt_results', '')
		w.set('lbl_status', ' Status: Ready  |  Matches: 0  |  Elapsed: 0 ms')
		w.toast('Output cleared.')
	})

	println('Find Studio Pro configured. Starting event loop...')
	win.run()
}

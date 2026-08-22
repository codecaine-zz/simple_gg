module main

import os
import time
import simplegui

// Helper to find fd binary
fn get_fd_bin() string {
	if path := os.find_abs_path_of_executable('fd') {
		return path
	}
	common_paths := [
		'/opt/homebrew/bin/fd',
		'/usr/local/bin/fd',
		'/bin/fd',
		'/usr/bin/fdfind',
	]
	for p in common_paths {
		if os.exists(p) {
			return p
		}
	}
	return 'fd'
}

struct FdRecipe {
	title       string
	pattern     string
	ext         string
	file_type   string
	size_filter string
	time_filter string
	hidden      bool
	no_ignore   bool
	desc        string
}

fn get_all_fd_recipes() []FdRecipe {
	return [
		FdRecipe{
			title: ' All Source Code Files (*.v, *.go, *.rs, *.py, *.js, *.ts)'
			pattern: ''
			ext: 'v,go,rs,py,js,ts,c,h'
			file_type: 'f (Regular Files)'
			size_filter: ''
			time_filter: ''
			hidden: false
			no_ignore: false
			desc: 'Finds all programming source code files across project.'
		},
		FdRecipe{
			title: ' Large Files Exceeding 100MB (> 100M)'
			pattern: ''
			ext: ''
			file_type: 'f (Regular Files)'
			size_filter: '+100M'
			time_filter: ''
			hidden: false
			no_ignore: false
			desc: 'Finds disk-heavy files larger than 100 Megabytes.'
		},
		FdRecipe{
			title: ' Modified in the Past 24 Hours (Recent Changes)'
			pattern: ''
			ext: ''
			file_type: 'f (Regular Files)'
			size_filter: ''
			time_filter: '1d'
			hidden: false
			no_ignore: false
			desc: 'Finds any file modified within the last 24 hours.'
		},
		FdRecipe{
			title: ' Modified in the Past 7 Days (Recent Week)'
			pattern: ''
			ext: ''
			file_type: 'f (Regular Files)'
			size_filter: ''
			time_filter: '7d'
			hidden: false
			no_ignore: false
			desc: 'Finds files modified in the past 7 days.'
		},
		FdRecipe{
			title: ' Empty Files & Folders (Size 0)'
			pattern: ''
			ext: ''
			file_type: 'e (Empty Files/Dirs)'
			size_filter: ''
			time_filter: ''
			hidden: false
			no_ignore: false
			desc: 'Finds zero-byte empty files and empty directories.'
		},
		FdRecipe{
			title: ' Executable Binaries & Scripts (-t x)'
			pattern: ''
			ext: ''
			file_type: 'x (Executables)'
			size_filter: ''
			time_filter: ''
			hidden: false
			no_ignore: false
			desc: 'Finds executable binaries and executable scripts.'
		},
		FdRecipe{
			title: ' Media & Graphics Assets (PNG, JPG, WebP, MP4, GIF)'
			pattern: ''
			ext: 'png,jpg,jpeg,webp,gif,svg,mp4,mov,mkv'
			file_type: 'f (Regular Files)'
			size_filter: ''
			time_filter: ''
			hidden: false
			no_ignore: false
			desc: 'Finds images, graphics, and video files.'
		},
		FdRecipe{
			title: ' All Directories / Folders (-t d)'
			pattern: ''
			ext: ''
			file_type: 'd (Directories Only)'
			size_filter: ''
			time_filter: ''
			hidden: false
			no_ignore: false
			desc: 'Finds only directory paths.'
		},
		FdRecipe{
			title: ' Symbolic Links (-t l)'
			pattern: ''
			ext: ''
			file_type: 'l (Symlinks)'
			size_filter: ''
			time_filter: ''
			hidden: true
			no_ignore: false
			desc: 'Finds symbolic links across the filesystem.'
		},
		FdRecipe{
			title: ' Temporary, Backup & Log Files (*.log, *.tmp, *.bak)'
			pattern: ''
			ext: 'log,tmp,bak,swp'
			file_type: 'f (Regular Files)'
			size_filter: ''
			time_filter: ''
			hidden: true
			no_ignore: true
			desc: 'Finds clutter, cache, and backup files including hidden.'
		},
	]
}

fn main() {
	println('Starting SimpleGUI - FD Studio Pro (High-Speed File Finder)...')

	mut win := simplegui.new_simple_window('SimpleGUI - FD Studio Pro', 1040, 960)
	win.set_fullscreen(true)
	win.set_spacing(8)
	win.set_padding(16)

	saved_theme := simplegui.get_saved_theme()
	win.set_theme(saved_theme)

	// Top Banner
	win.begin_row('row_fd_top')
	win.add_heading('FD Studio Pro')
	win.add_label('lbl_theme', 'Theme:')
	win.add_dropdown('dd_app_theme', simplegui.list_themes(), saved_theme)
	win.set_control_width('dd_app_theme', 150)
	win.end_row()

	win.on_change('dd_app_theme', fn (mut w simplegui.SimpleWindow, selected string) {
		w.set_theme(selected)
		w.toast('Theme changed to ${selected}')
	})
	fd_path := get_fd_bin()
	win.add_label('lbl_engine_info', 'Engine: ${fd_path}  |  Platform: macOS Cocoa  |  Mode: Async Worker (Zero UI Freezes)')

	all_recipes := get_all_fd_recipes()

	// -------------------------------------------------------------
	// Search Target Path & Pattern
	// -------------------------------------------------------------
	win.begin_group_box('grp_search_scope', 'Search Scope & Target Criteria')
	
	win.begin_row('row_scope_1')
	win.add_label('lbl_pattern', 'Search Pattern (Regex / Glob):')
	win.add_input('txt_pattern', '')
	win.set_control_width('txt_pattern', 380)

	win.add_label('lbl_ext', 'Extensions (-e):')
	win.add_input('txt_ext', 'v,go,rs')
	win.set_control_width('txt_ext', 130)

	win.add_label('lbl_type', 'Type (-t):')
	win.add_dropdown('dd_type', [
		'All Types',
		'f (Regular Files)',
		'd (Directories Only)',
		'l (Symlinks)',
		'x (Executables)',
		'e (Empty Files/Dirs)'
	], 'f (Regular Files)')
	win.set_control_width('dd_type', 160)
	win.end_row()

	win.begin_row('row_scope_2')
	win.add_label('lbl_search_dir', 'Search Directory:')
	win.add_input('txt_search_dir', '.')
	win.set_control_width('txt_search_dir', 480)
	win.add_button('btn_browse_dir', 'Choose Folder...')
	win.add_button('btn_home_dir', 'Home Folder')
	win.add_button('btn_open_dir', 'Open in Finder')
	win.end_row()

	win.end_group_box()

	// -------------------------------------------------------------
	// Filters & Preset Recipes
	// -------------------------------------------------------------
	win.begin_group_box('grp_filters', 'Advanced Filters & Search Recipes')
	
	mut recipe_titles := ['-- Select a Fast Search Recipe --']
	for r in all_recipes {
		recipe_titles << r.title
	}

	win.begin_row('row_recipes')
	win.add_label('lbl_recipe', 'Quick Recipe:')
	win.add_dropdown('dd_recipe', recipe_titles, recipe_titles[0])
	win.set_control_width('dd_recipe', 480)
	win.add_button('btn_apply_recipe', 'Load Recipe')
	win.add_button('btn_run_recipe_now', 'Load & Search')
	win.end_row()

	win.begin_row('row_filter_params')
	win.add_label('lbl_size', 'Size (--size):')
	win.add_input('txt_size', '')
	win.set_control_width('txt_size', 90)

	win.add_label('lbl_changed', 'Changed Within:')
	win.add_input('txt_changed', '')
	win.set_control_width('txt_changed', 90)

	win.add_label('lbl_max_depth', 'Max Depth (-d):')
	win.add_input('txt_max_depth', '')
	win.set_control_width('txt_max_depth', 60)
	win.end_row()

	win.begin_row('row_filter_flags')
	win.add_checkbox('chk_hidden', 'Include Hidden (-H)', false)
	win.add_checkbox('chk_no_ignore', 'No Ignore (-I)', false)
	win.add_checkbox('chk_follow', 'Follow Links (-L)', false)
	win.add_checkbox('chk_case_s', 'Case Sensitive (-s)', false)
	win.end_row()

	win.end_group_box()

	// -------------------------------------------------------------
	// Actions & Live Execution Bar
	// -------------------------------------------------------------
	win.begin_row('row_actions')
	win.add_button('btn_run_search', 'Search Files Now')
	win.add_button('btn_copy_paths', 'Copy All Paths')
	win.add_button('btn_copy_filenames', 'Copy Basenames Only')
	win.add_button('btn_save_list', 'Save Results to File...')
	win.add_button('btn_clear_results', 'Clear Results')
	win.end_row()

	// -------------------------------------------------------------
	// Discovered Results Pane
	// -------------------------------------------------------------
	win.begin_group_box('grp_results', 'Discovered Files & Matches')
	win.add_textarea('txt_results', '')
	win.set_control_height('txt_results', 280)
	win.end_group_box()

	// Stats Row
	win.begin_row('row_stats')
	win.add_label('lbl_stats', 'Stats: Ready  |  Files Found: 0  |  Duration: 0 ms')
	win.end_row()

	// -------------------------------------------------------------
	// Core Search Engine (Async Non-Blocking)
	// -------------------------------------------------------------
	execute_fd_search := fn (mut win simplegui.SimpleWindow) {
		raw_search_dir := win.get('txt_search_dir').trim_space()
		mut search_dir := raw_search_dir
		if search_dir == '~' {
			search_dir = os.home_dir()
		} else if search_dir.starts_with('~/') {
			search_dir = os.join_path(os.home_dir(), search_dir[2..])
		}
		if search_dir == '' || !os.exists(search_dir) {
			win.alert('Directory Required', 'Please select a valid search directory.')
			return
		}

		fd := get_fd_bin()
		pattern := win.get('txt_pattern').trim_space()
		ext_val := win.get('txt_ext').trim_space()
		type_sel := win.get('dd_type')
		size_val := win.get('txt_size').trim_space()
		changed_val := win.get('txt_changed').trim_space()
		depth_val := win.get('txt_max_depth').trim_space()

		is_hidden := win.get('chk_hidden') == 'true'
		is_no_ignore := win.get('chk_no_ignore') == 'true'
		is_follow := win.get('chk_follow') == 'true'
		is_case_s := win.get('chk_case_s') == 'true'

		win.set_status('Searching filesystem with FD in background...')
		win.toast('Searching files...')

		go fn [mut win, fd, search_dir, pattern, ext_val, type_sel, size_val, changed_val, depth_val, is_hidden, is_no_ignore, is_follow, is_case_s] () {
			t0 := time.ticks()

			mut raw_args := []string{}

			if is_hidden { raw_args << '-H' }
			if is_no_ignore { raw_args << '-I' }
			if is_follow { raw_args << '-L' }
			if is_case_s { raw_args << '-s' }

			if type_sel.starts_with('f') { raw_args << ['-t', 'f'] }
			else if type_sel.starts_with('d') { raw_args << ['-t', 'd'] }
			else if type_sel.starts_with('l') { raw_args << ['-t', 'l'] }
			else if type_sel.starts_with('x') { raw_args << ['-t', 'x'] }
			else if type_sel.starts_with('e') { raw_args << ['-t', 'e'] }

			if ext_val != '' {
				exts := ext_val.split(',')
				for e in exts {
					trimmed := e.trim_space()
					if trimmed != '' {
						raw_args << ['-e', trimmed]
					}
				}
			}

			if size_val != '' {
				raw_args << ['--size', size_val]
			}

			if changed_val != '' {
				raw_args << ['--changed-within', changed_val]
			}

			if depth_val != '' && depth_val != '0' {
				raw_args << ['-d', depth_val]
			}

			if pattern != '' {
				if pattern.contains('/') {
					raw_args << '--full-path'
				}
				raw_args << pattern
			} else {
				raw_args << '.'
			}

			raw_args << search_dir

			res := simplegui.exec_safe(fd, raw_args)
			elapsed_ms := time.ticks() - t0

			win.run_on_main_thread(fn [res, elapsed_ms] (mut win_main simplegui.SimpleWindow) {
				if res.exit_code == 0 {
					out_str := res.output.trim_space()
					win_main.set('txt_results', out_str)
					
					mut count := 0
					if out_str != '' {
						count = out_str.split_into_lines().len
					}

					win_main.set('lbl_stats', ' Stats: SUCCESS  |  Files Found: ${count}  |  Duration: ${elapsed_ms} ms')
					win_main.set_status('Found ${count} matching files in ${elapsed_ms} ms.')
					win_main.toast('Found ${count} files in ${elapsed_ms} ms!')
				} else {
					win_main.set('txt_results', ' FD Search Error:\n\n' + res.output)
					win_main.set('lbl_stats', ' Stats: ERROR (Exit code ${res.exit_code})  |  Duration: ${elapsed_ms} ms')
					win_main.set_status('FD search returned an error.')
				}
			})
		}()
	}

	// -------------------------------------------------------------
	// Event Handlers
	// -------------------------------------------------------------

	// Browse Directory
	win.on_click('btn_browse_dir', fn (mut w simplegui.SimpleWindow) {
		dir := w.select_folder()
		if dir != '' && os.is_dir(dir) {
			w.set('txt_search_dir', dir)
			w.toast('Search folder updated.')
		}
	})

	// Home Folder
	win.on_click('btn_home_dir', fn (mut w simplegui.SimpleWindow) {
		w.set('txt_search_dir', '~')
		w.toast('Search folder set to Home (~).')
	})

	// Open in Finder
	win.on_click('btn_open_dir', fn (mut w simplegui.SimpleWindow) {
		raw_dir := w.get('txt_search_dir').trim_space()
		mut dir := raw_dir
		if dir == '~' {
			dir = os.home_dir()
		} else if dir.starts_with('~/') {
			dir = os.join_path(os.home_dir(), dir[2..])
		}
		if dir != '' && os.is_dir(dir) {
			os.execute('open "${dir}"')
		} else {
			os.execute('open .')
		}
		w.toast('Opened in Finder.')
	})

	// Clear Results
	win.on_click('btn_clear_results', fn (mut w simplegui.SimpleWindow) {
		w.set('txt_results', '')
		w.set('lbl_stats', ' Stats: Ready  |  Files Found: 0  |  Duration: 0 ms')
		w.toast('Results cleared.')
	})

	// Copy Paths
	win.on_click('btn_copy_paths', fn (mut w simplegui.SimpleWindow) {
		res := w.get('txt_results').trim_space()
		if res != '' {
			w.copy_to_clipboard(res)
			w.toast('Copied file paths to clipboard!')
		} else {
			w.toast('No paths to copy.')
		}
	})

	// Copy Basenames
	win.on_click('btn_copy_filenames', fn (mut w simplegui.SimpleWindow) {
		res := w.get('txt_results').trim_space()
		if res == '' {
			w.toast('No paths to format.')
			return
		}
		lines := res.split_into_lines()
		mut names := []string{}
		for l in lines {
			trimmed := l.trim_space()
			if trimmed != '' {
				names << os.file_name(trimmed)
			}
		}
		w.copy_to_clipboard(names.join('\n'))
		w.toast('Copied ${names.len} file names to clipboard!')
	})

	// Save List
	win.on_click('btn_save_list', fn (mut w simplegui.SimpleWindow) {
		res := w.get('txt_results').trim_space()
		if res == '' {
			w.toast('No results to save.')
			return
		}
		path := w.save_file_picker()
		if path != '' {
			os.write_file(path, res) or {
				w.alert('Save Error', 'Failed to save file: ' + err.str())
				return
			}
			w.toast('Saved results to ${path}')
		}
	})

	// Apply Recipe
	win.on_click('btn_apply_recipe', fn [all_recipes] (mut w simplegui.SimpleWindow) {
		sel := w.get('dd_recipe')
		for r in all_recipes {
			if sel.contains(r.title) {
				w.set('txt_pattern', r.pattern)
				w.set('txt_ext', r.ext)
				w.set_text('dd_type', r.file_type)
				w.set('txt_size', r.size_filter)
				w.set('txt_changed', r.time_filter)
				w.set('chk_hidden', r.hidden.str())
				w.set('chk_no_ignore', r.no_ignore.str())
				w.toast('Loaded recipe: ' + r.title)
				return
			}
		}
		w.toast('Please select a recipe from the dropdown.')
	})

	// Load & Search Recipe
	win.on_click('btn_run_recipe_now', fn [all_recipes, execute_fd_search] (mut w simplegui.SimpleWindow) {
		sel := w.get('dd_recipe')
		for r in all_recipes {
			if sel.contains(r.title) {
				w.set('txt_pattern', r.pattern)
				w.set('txt_ext', r.ext)
				w.set_text('dd_type', r.file_type)
				w.set('txt_size', r.size_filter)
				w.set('txt_changed', r.time_filter)
				w.set('chk_hidden', r.hidden.str())
				w.set('chk_no_ignore', r.no_ignore.str())
				execute_fd_search(mut w)
				return
			}
		}
		w.toast('Please select a recipe from the dropdown.')
	})

	// Search Button
	win.on_click('btn_run_search', fn [execute_fd_search] (mut w simplegui.SimpleWindow) {
		execute_fd_search(mut w)
	})

	println('FD Studio Pro configured. Starting event loop...')
	win.run()
}

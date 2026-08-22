module main

import os
import time
import simplegui

// Helper to find rg binary
fn get_rg_bin() string {
	if path := os.find_abs_path_of_executable('rg') {
		return path
	}
	common_paths := [
		'/opt/homebrew/bin/rg',
		'/usr/local/bin/rg',
		'/bin/rg',
		'/usr/bin/rg',
	]
	for p in common_paths {
		if os.exists(p) {
			return p
		}
	}
	return 'rg'
}

struct RgRecipe {
	title     string
	pattern   string
	type_filter string
	glob_filter string
	is_fixed  bool
	is_word   bool
	is_case_s bool
	desc      string
}

fn get_all_rg_recipes() []RgRecipe {
	return [
		RgRecipe{
			title: ' TODO / FIXME / BUG / HACK Comments'
			pattern: r'(TODO|FIXME|BUG|HACK|NOTE|XXX):?'
			type_filter: 'All Types'
			glob_filter: ''
			is_fixed: false
			is_word: false
			is_case_s: true
			desc: 'Finds technical debt, todos, and bug annotations across codebase.'
		},
		RgRecipe{
			title: ' Potential API Keys, Tokens & Secrets'
			pattern: r'(?i)(api[_-]?key|secret|token|password|bearer|auth[_-]?key)\s*[:=]\s*["\x27][A-Za-z0-9_\-]{8,}["\x27]'
			type_filter: 'All Types'
			glob_filter: '!*.lock'
			is_fixed: false
			is_word: false
			is_case_s: false
			desc: 'Finds hardcoded tokens, credentials, and API secret assignments.'
		},
		RgRecipe{
			title: ' URLs & Web Endpoints (http/https)'
			pattern: r'https?://[a-zA-Z0-9./?=_%&:-]+'
			type_filter: 'All Types'
			glob_filter: ''
			is_fixed: false
			is_word: false
			is_case_s: false
			desc: 'Finds all HTTP and HTTPS endpoints referenced in source files.'
		},
		RgRecipe{
			title: ' Function & Method Definitions (fn / func / def)'
			pattern: r'(pub\s+)?(fn|func|def|function)\s+([A-Za-z0-9_]+)'
			type_filter: 'All Types'
			glob_filter: ''
			is_fixed: false
			is_word: false
			is_case_s: true
			desc: 'Finds declared functions and methods across multiple languages.'
		},
		RgRecipe{
			title: ' Import & Module Dependencies'
			pattern: r'^(import|from|#include|require|use)\s+.*'
			type_filter: 'All Types'
			glob_filter: ''
			is_fixed: false
			is_word: false
			is_case_s: true
			desc: 'Finds all dependency imports and header includes.'
		},
		RgRecipe{
			title: ' Panic / Throw / Fatal Error Handlers'
			pattern: r'(panic|throw\s+new|fatal|assert|die)\('
			type_filter: 'All Types'
			glob_filter: ''
			is_fixed: false
			is_word: false
			is_case_s: false
			desc: 'Finds critical assertions, panics, and exception triggers.'
		},
		RgRecipe{
			title: ' Markdown Document Headings (#, ##, ###)'
			pattern: r'^#{1,6}\s+.*'
			type_filter: 'md (Markdown)'
			glob_filter: '*.md'
			is_fixed: false
			is_word: false
			is_case_s: false
			desc: 'Extracts section heading hierarchy from Markdown documentation.'
		},
		RgRecipe{
			title: ' Struct / Class / Interface Definitions'
			pattern: r'(pub\s+)?(struct|class|interface|type|enum)\s+([A-Za-z0-9_]+)'
			type_filter: 'All Types'
			glob_filter: ''
			is_fixed: false
			is_word: false
			is_case_s: true
			desc: 'Finds type, class, struct, and interface declarations.'
		},
	]
}

fn main() {
	println('Starting SimpleGUI - RG Studio Pro (ripgrep Code Search)...')

	mut win := simplegui.new_simple_window('SimpleGUI - RG Studio Pro', 1060, 960)
	win.set_fullscreen(true)
	win.set_spacing(8)
	win.set_padding(16)

	saved_theme := simplegui.get_saved_theme()
	win.set_theme(saved_theme)

	// Top Banner
	win.begin_row('row_rg_top')
	win.add_heading('RG Studio Pro')
	win.add_label('lbl_theme', 'Theme:')
	win.add_dropdown('dd_app_theme', simplegui.list_themes(), saved_theme)
	win.set_control_width('dd_app_theme', 150)
	win.end_row()

	win.on_change('dd_app_theme', fn (mut w simplegui.SimpleWindow, selected string) {
		w.set_theme(selected)
		w.toast('Theme changed to ${selected}')
	})

	rg_path := get_rg_bin()
	win.add_label('lbl_engine_info', 'Engine: ${rg_path} (ripgrep)  |  Platform: macOS Cocoa  |  Mode: Async Worker (Zero Freezes)')

	all_recipes := get_all_rg_recipes()

	// -------------------------------------------------------------
	// Search Query & Target Folder
	// -------------------------------------------------------------
	win.begin_group_box('grp_search_box', 'Search Pattern & Target Scope')
	
	win.begin_row('row_query')
	win.add_label('lbl_pattern', 'Search Pattern (Regex / Text):')
	win.add_input('txt_pattern', 'fn main')
	win.set_control_width('txt_pattern', 440)
	win.add_checkbox('chk_fixed', 'Fixed String (-F)', false)
	win.add_checkbox('chk_word', 'Whole Word (-w)', false)
	win.add_checkbox('chk_case_s', 'Case Sensitive (-s)', false)
	win.add_checkbox('chk_invert', 'Invert (-v)', false)
	win.end_row()

	win.begin_row('row_scope')
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
	win.begin_group_box('grp_filters', 'File Types, Glob Filters & Search Recipes')
	
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

	win.begin_row('row_filters_2')
	win.add_label('lbl_type', 'File Type (-t):')
	win.add_dropdown('dd_type', [
		'All Types',
		'v (V Language)',
		'rust (Rust)',
		'go (Go)',
		'python (Python)',
		'js (JavaScript)',
		'ts (TypeScript)',
		'c (C / C++)',
		'md (Markdown)',
		'json (JSON)',
		'html (HTML)',
		'css (CSS)',
		'sh (Shell Script)'
	], 'All Types')
	win.set_control_width('dd_type', 160)

	win.add_label('lbl_glob', 'Glob Filter (-g):')
	win.add_input('txt_glob', '')
	win.set_control_width('txt_glob', 140)

	win.add_label('lbl_context', 'Context (-C):')
	win.add_input('txt_context', '0')
	win.set_control_width('txt_context', 40)

	win.add_checkbox('chk_hidden', 'Hidden (--hidden)', false)
	win.add_checkbox('chk_no_ignore', 'No Ignore (--no-ignore)', false)
	win.add_checkbox('chk_files_only', 'Files Only (-l)', false)
	win.end_row()

	win.end_group_box()

	// -------------------------------------------------------------
	// Actions & Live Execution Bar
	// -------------------------------------------------------------
	win.begin_row('row_actions')
	win.add_button('btn_run_search', 'Search Matches Now')
	win.add_button('btn_copy_results', 'Copy All Results')
	win.add_button('btn_copy_files', 'Copy File List Only')
	win.add_button('btn_save_results', 'Save to File...')
	win.add_button('btn_clear_results', 'Clear')
	win.end_row()

	// -------------------------------------------------------------
	// Discovered Results Pane
	// -------------------------------------------------------------
	win.begin_group_box('grp_results', 'Search Matches & Code Snippets')
	win.add_textarea('txt_results', '')
	win.set_control_height('txt_results', 290)
	win.end_group_box()

	// Stats Row
	win.begin_row('row_stats')
	win.add_label('lbl_stats', 'Stats: Ready  |  Matches Found: 0  |  Duration: 0 ms')
	win.end_row()

	// -------------------------------------------------------------
	// Core ripgrep Search Engine (Async Non-Blocking)
	// -------------------------------------------------------------
	execute_rg_search := fn (mut win simplegui.SimpleWindow) {
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

		pattern := win.get('txt_pattern').trim_space()
		if pattern == '' {
			win.alert('Pattern Required', 'Please enter a search query or regex pattern.')
			return
		}

		rg := get_rg_bin()
		is_fixed := win.get('chk_fixed') == 'true'
		is_word := win.get('chk_word') == 'true'
		is_case_s := win.get('chk_case_s') == 'true'
		is_invert := win.get('chk_invert') == 'true'
		is_hidden := win.get('chk_hidden') == 'true'
		is_no_ignore := win.get('chk_no_ignore') == 'true'
		is_files_only := win.get('chk_files_only') == 'true'

		type_val := win.get('dd_type')
		glob_val := win.get('txt_glob').trim_space()
		ctx_val := win.get('txt_context').trim_space()

		win.set_status('Searching codebase with ripgrep in background...')
		win.toast('Searching matches...')

		go fn [mut win, rg, search_dir, pattern, is_fixed, is_word, is_case_s, is_invert, is_hidden, is_no_ignore, is_files_only, type_val, glob_val, ctx_val] () {
			t0 := time.ticks()

			mut raw_args := ['--color', 'never', '-n']

			if is_fixed { raw_args << '-F' }
			if is_word { raw_args << '-w' }
			if is_case_s { raw_args << '-s' } else { raw_args << '-S' } // Smart Case default
			if is_invert { raw_args << '-v' }
			if is_hidden { raw_args << '--hidden' }
			if is_no_ignore { raw_args << '--no-ignore' }
			if is_files_only { raw_args << '-l' }

			if ctx_val != '' && ctx_val != '0' {
				raw_args << ['-C', ctx_val]
			}

			if type_val != 'All Types' {
				t_name := type_val.all_before(' (').trim_space()
				if t_name != '' {
					raw_args << ['-t', t_name]
				}
			}

			if glob_val != '' {
				raw_args << ['-g', glob_val]
			}

			raw_args << ['-e', pattern]
			raw_args << search_dir

			res := simplegui.exec_safe(rg, raw_args)
			elapsed_ms := time.ticks() - t0

			win.run_on_main_thread(fn [res, elapsed_ms] (mut win_main simplegui.SimpleWindow) {
				if res.exit_code == 0 || res.exit_code == 1 {
					out_str := res.output.trim_space()
					win_main.set('txt_results', out_str)
					
					mut count := 0
					if out_str != '' {
						count = out_str.split_into_lines().len
					}

					win_main.set('lbl_stats', ' Stats: SUCCESS  |  Lines / Matches: ${count}  |  Duration: ${elapsed_ms} ms')
					win_main.set_status('Found ${count} lines matching query in ${elapsed_ms} ms.')
					win_main.toast('Found ${count} matches in ${elapsed_ms} ms!')
				} else {
					win_main.set('txt_results', ' Ripgrep Error:\n\n' + res.output)
					win_main.set('lbl_stats', ' Stats: ERROR (Exit code ${res.exit_code})  |  Duration: ${elapsed_ms} ms')
					win_main.set_status('Ripgrep returned an error.')
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
		w.set('lbl_stats', ' Stats: Ready  |  Matches Found: 0  |  Duration: 0 ms')
		w.toast('Results cleared.')
	})

	// Copy Results
	win.on_click('btn_copy_results', fn (mut w simplegui.SimpleWindow) {
		res := w.get('txt_results').trim_space()
		if res != '' {
			w.copy_to_clipboard(res)
			w.toast('Copied matches to clipboard!')
		} else {
			w.toast('No results to copy.')
		}
	})

	// Copy Files Only
	win.on_click('btn_copy_files', fn (mut w simplegui.SimpleWindow) {
		res := w.get('txt_results').trim_space()
		if res == '' {
			w.toast('No results to extract.')
			return
		}
		lines := res.split_into_lines()
		mut files := []string{}
		mut seen := map[string]bool{}
		for l in lines {
			parts := l.split(':')
			if parts.len > 0 {
				fpath := parts[0].trim_space()
				if fpath != '' && !seen[fpath] {
					seen[fpath] = true
					files << fpath
				}
			}
		}
		w.copy_to_clipboard(files.join('\n'))
		w.toast('Copied ${files.len} unique file paths!')
	})

	// Save Results
	win.on_click('btn_save_results', fn (mut w simplegui.SimpleWindow) {
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
				w.set_text('dd_type', r.type_filter)
				w.set('txt_glob', r.glob_filter)
				w.set('chk_fixed', r.is_fixed.str())
				w.set('chk_word', r.is_word.str())
				w.set('chk_case_s', r.is_case_s.str())
				w.toast('Loaded recipe: ' + r.title)
				return
			}
		}
		w.toast('Please select a recipe from the dropdown.')
	})

	// Load & Search Recipe
	win.on_click('btn_run_recipe_now', fn [all_recipes, execute_rg_search] (mut w simplegui.SimpleWindow) {
		sel := w.get('dd_recipe')
		for r in all_recipes {
			if sel.contains(r.title) {
				w.set('txt_pattern', r.pattern)
				w.set_text('dd_type', r.type_filter)
				w.set('txt_glob', r.glob_filter)
				w.set('chk_fixed', r.is_fixed.str())
				w.set('chk_word', r.is_word.str())
				w.set('chk_case_s', r.is_case_s.str())
				execute_rg_search(mut w)
				return
			}
		}
		w.toast('Please select a recipe from the dropdown.')
	})

	// Search Button
	win.on_click('btn_run_search', fn [execute_rg_search] (mut w simplegui.SimpleWindow) {
		execute_rg_search(mut w)
	})

	println('RG Studio Pro configured. Starting event loop...')
	win.run()
}

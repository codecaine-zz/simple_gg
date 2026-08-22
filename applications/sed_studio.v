module main

import simplegui
import os
import time

// -----------------------------------------------------------------------------
// Sed Preset Recipe Data Structure
// -----------------------------------------------------------------------------
struct SedRecipe {
	title      string
	category   string
	script     string
	extended   bool
	quiet      bool
	desc       string
	sample     string
}

fn get_all_sed_recipes() []SedRecipe {
	return [
		SedRecipe{
			title: ' Strip Trailing Whitespace'
			category: 'Cleaning'
			script: 's/[[:space:]]+$//g'
			extended: true
			quiet: false
			desc: 'Removes unnecessary trailing spaces and tabs from the end of every line.'
			sample: 'func main() {    \n    println("Hello") \t\t\n    return 0   \n}'
		},
		SedRecipe{
			title: ' Delete Empty & Blank Lines'
			category: 'Cleaning'
			script: '/^[[:space:]]*$/d'
			extended: true
			quiet: false
			desc: 'Deletes all empty lines or lines containing only whitespace characters.'
			sample: 'Line 1\n\n   \nLine 2\n\n\t\nLine 3'
		},
		SedRecipe{
			title: ' Strip Comment Lines (#)'
			category: 'Cleaning'
			script: '/^[[:space:]]*#/d'
			extended: true
			quiet: false
			desc: 'Removes shell, Python, YAML, or config comment lines starting with #.'
			sample: '# Configuration File\nport=8080\n# Database settings\ndb_host=localhost\n# db_port=5432'
		},
		SedRecipe{
			title: ' Strip HTML / XML Tags'
			category: 'Web & Text'
			script: 's/<[^>]*>//g'
			extended: true
			quiet: false
			desc: 'Removes all HTML/XML markup tags, leaving clean extracted plain text.'
			sample: '<div class="card"><h1>Title</h1><p>Welcome to <b>SimpleGUI</b>!</p></div>'
		},
		SedRecipe{
			title: ' Convert Windows CRLF (\\r\\n) to Unix LF'
			category: 'Normalization'
			script: 's/\\r$//'
			extended: false
			quiet: false
			desc: 'Strips trailing carriage returns (\\r) from Windows format files.'
			sample: 'Windows line 1\r\nWindows line 2\r\nWindows line 3\r\n'
		},
		SedRecipe{
			title: ' Extract First 10 Lines'
			category: 'Filtering'
			script: '1,10p'
			extended: false
			quiet: true
			desc: 'Prints only lines 1 through 10 (head utility equivalent in sed).'
			sample: 'Line 1\nLine 2\nLine 3\nLine 4\nLine 5\nLine 6\nLine 7\nLine 8\nLine 9\nLine 10\nLine 11\nLine 12'
		},
		SedRecipe{
			title: ' Delete Header / First 3 Lines'
			category: 'Filtering'
			script: '1,3d'
			extended: false
			quiet: false
			desc: 'Deletes the first 3 lines of the file or stream.'
			sample: '--- HEADER START ---\nAuthor: Team\nDate: 2026-08-22\n--- DATA ---\nRecord 1\nRecord 2'
		},
		SedRecipe{
			title: ' Extract Lines Containing Keyword'
			category: 'Filtering'
			script: '/ERROR/p'
			extended: false
			quiet: true
			desc: 'Filters and prints only log lines matching the pattern ERROR.'
			sample: 'INFO: Server started\nERROR: Connection timed out to redis\nINFO: Worker ready\nERROR: Out of memory in worker 4'
		},
		SedRecipe{
			title: ' Global Substring Replace'
			category: 'Transform'
			script: 's/http:\\/\\//https:\\/\\//g'
			extended: false
			quiet: false
			desc: 'Replaces all occurrences of http:// with https:// globally.'
			sample: 'Visit http://example.com or http://api.service.org for docs.'
		},
		SedRecipe{
			title: ' Prepend Line Prefix'
			category: 'Formatting'
			script: 's/^/[LOG] /'
			extended: false
			quiet: false
			desc: 'Prepends a tag or comment prefix to the beginning of each line.'
			sample: 'Booting kernel\nMounting filesystem\nInitializing network'
		},
		SedRecipe{
			title: ' Append Suffix to Every Line'
			category: 'Formatting'
			script: 's/$/;/'
			extended: false
			quiet: false
			desc: 'Appends a semicolon or delimiter to the end of every line.'
			sample: 'int a = 1\nint b = 2\nint c = 3'
		},
		SedRecipe{
			title: ' Swap Two Words / Delimited Columns'
			category: 'RegEx'
			script: 's/([a-zA-Z0-9_]+)[[:space:]]*=[[:space:]]*([a-zA-Z0-9_]+)/\\2 : \\1/g'
			extended: true
			quiet: false
			desc: 'Swaps key=value pairs into value : key format using backreferences.'
			sample: 'user=john\nrole=admin\nstatus=active'
		},
		SedRecipe{
			title: ' Transliterate Lowercase to Uppercase'
			category: 'Transform'
			script: 'y/abcdefghijklmnopqrstuvwxyz/ABCDEFGHIJKLMNOPQRSTUVWXYZ/'
			extended: false
			quiet: false
			desc: 'Transliterates every lowercase ASCII character to uppercase without regex.'
			sample: 'hello simplegui world! fast stream transformation with sed.'
		},
		SedRecipe{
			title: ' Extract Domain from URL'
			category: 'RegEx'
			script: 's/https?:\\/\\/([^\\/]+).*/\\1/p'
			extended: true
			quiet: true
			desc: 'Extracts domain hostname from full URL paths using pattern matching.'
			sample: 'https://github.com/vlang/v/issues/100\nhttps://developer.apple.com/documentation/cocoa\nhttps://news.ycombinator.com/item?id=42'
		},
		SedRecipe{
			title: ' Double-Space All Lines'
			category: 'Formatting'
			script: 'G'
			extended: false
			quiet: false
			desc: 'Inserts an empty blank line after each line (double spacing text).'
			sample: 'Paragraph one\nParagraph two\nParagraph three'
		}
	]
}

fn get_sed_bin() string {
	for candidate in ['/usr/bin/sed', '/bin/sed', '/opt/homebrew/bin/gsed', 'sed'] {
		if os.exists(candidate) {
			return candidate
		}
	}
	return 'sed'
}

fn main() {
	println('Starting SimpleGUI - Sed Studio Pro (Stream Editor & RegEx Workbench)...')

	mut win := simplegui.new_simple_window('Sed Studio Pro -- Stream Editor & RegEx Transformation Workbench', 1100, 940)
	win.set_fullscreen(true)
	win.restore_saved_theme()
	win.set_spacing(8)
	win.set_padding(16)

	sed_bin := get_sed_bin()
	recipes := get_all_sed_recipes()

	// -------------------------------------------------------------
	// Header & Theme Selector
	// -------------------------------------------------------------
	win.begin_row('row_header')
	win.add_heading('Sed Studio Pro')

	saved_theme := simplegui.get_saved_theme()
	win.add_dropdown('dd_theme_selector', simplegui.list_themes(), saved_theme)
	win.set_control_width('dd_theme_selector', 180)
	win.end_row()

	win.add_label('lbl_engine', 'Engine: ${sed_bin} (POSIX/BSD Stream Editor)  |  Dual-Pane Scratchpad & File In-Place Processor')

	// -------------------------------------------------------------
	// Script Builder & Preset Recipes
	// -------------------------------------------------------------
	win.begin_group_box('grp_script', 'Sed Expression & Production Recipes')

	mut recipe_titles := ['-- Select a Curated Sed Recipe (15 Built-in) --']
	for r in recipes {
		recipe_titles << '[${r.category}] ${r.title}'
	}

	win.begin_row('row_recipe')
	win.add_label('lbl_rec', 'Recipe Preset:')
	win.add_dropdown('dd_recipe', recipe_titles, recipe_titles[0])
	win.set_control_width('dd_recipe', 420)
	win.add_button('btn_apply_recipe', 'Apply Recipe')
	win.add_button('btn_load_sample', 'Load Sample')
	win.end_row()

	win.begin_row('row_rec_info')
	win.add_label('lbl_recipe_desc', 'Tip: Select any preset recipe above to load tested pattern expressions and flags.')
	win.end_row()

	win.begin_row('row_cmd_input')
	win.add_label('lbl_script', 'Sed Expression (-e):')
	win.add_input('txt_script', 's/[[:space:]]+$//g')
	win.set_control_width('txt_script', 520)

	win.add_checkbox('chk_extended', 'Extended RegEx (-E)', true)
	win.add_checkbox('chk_quiet', 'Quiet / Suppress Print (-n)', false)
	win.end_row()
	win.end_group_box()

	// -------------------------------------------------------------
	// Dual-Pane Interactive Scratchpad
	// -------------------------------------------------------------
	win.begin_group_box('grp_scratchpad', 'Dual-Pane Live Transformation Scratchpad')

	win.begin_row('row_in_header')
	win.add_label('lbl_in_title', 'Input Stream / Text Payload:')
	win.add_label('lbl_in_stats', '  (0 chars, 0 lines)')
	win.end_row()

	default_input := 'func main() {    \n    println("Hello, SimpleGUI") \t\t\n    val := 42   \n    return val   \n}\n'
	win.add_textarea('txt_input', default_input)
	win.set_control_height('txt_input', 160)

	win.begin_row('row_out_header')
	win.add_label('lbl_out_title', 'Transformed Output Stream:')
	win.add_label('lbl_out_stats', '  (0 chars, 0 lines)')
	win.end_row()

	win.add_textarea('txt_output', '')
	win.set_control_height('txt_output', 160)
	win.end_group_box()

	// -------------------------------------------------------------
	// Disk File & Batch Processing
	// -------------------------------------------------------------
	win.begin_group_box('grp_file_mode', 'Target Disk File Processing (Optional)')

	win.begin_row('row_file_in')
	win.add_label('lbl_file', 'Source File:')
	win.add_input('txt_file_path', '')
	win.set_control_width('txt_file_path', 480)
	win.add_button('btn_pick_file', 'Pick File...')
	win.add_button('btn_read_file_to_in', 'Load into Input')
	win.add_button('btn_reveal_file', 'Reveal')
	win.end_row()

	win.begin_row('row_file_actions')
	win.add_checkbox('chk_inplace', 'In-Place Edit File (-i \'\')', false)
	win.add_checkbox('chk_backup', 'Create .bak Backup', true)
	win.add_button('btn_process_file', 'Run sed on File')
	win.add_button('btn_save_out_to_file', 'Save Output to File...')
	win.end_row()
	win.end_group_box()

	// -------------------------------------------------------------
	// Action Execution Toolbar
	// -------------------------------------------------------------
	win.begin_row('row_actions')
	win.add_button('btn_run', 'Transform Text (Run sed)')
	win.add_button('btn_swap', 'Move Output to Input')
	win.add_button('btn_copy_out', 'Copy Output')
	win.add_button('btn_copy_cmd', 'Copy CLI Command')
	win.add_button('btn_clear', 'Clear Scratchpad')
	win.end_row()

	win.begin_row('row_status')
	win.add_label('lbl_status', 'Status: Ready  |  Engine: sed  |  Theme: GitHub Dark')
	win.end_row()

	// -------------------------------------------------------------
	// Core Execution Engine
	// -------------------------------------------------------------
	run_sed_transform := fn (mut win simplegui.SimpleWindow, sed_bin string) {
		input_text := win.get('txt_input')
		script_expr := win.get('txt_script').trim_space()
		use_extended := win.get_bool('chk_extended')
		use_quiet := win.get_bool('chk_quiet')

		if script_expr == '' {
			win.alert('Empty Script', 'Please enter a valid sed expression (e.g. s/find/replace/g).')
			return
		}

		// Write scratch payload to temporary file for safe isolation
		tmp_dir := os.join_path(os.temp_dir(), 'simplegui_sed')
		if !os.exists(tmp_dir) {
			os.mkdir_all(tmp_dir) or {}
		}
		tmp_file := os.join_path(tmp_dir, 'input_${os.getpid()}.txt')
		os.write_file(tmp_file, input_text) or {
			win.alert('File Error', 'Failed to prepare input payload buffer.')
			return
		}

		mut args := []string{}
		if use_extended { args << '-E' }
		if use_quiet { args << '-n' }
		args << ['-e', script_expr]

		t0 := time.ticks()
		res := simplegui.exec_safe_stdin(sed_bin, args, tmp_file)
		elapsed_ms := time.ticks() - t0

		// Clean temp file
		os.rm(tmp_file) or {}

		if res.exit_code == 0 {
			win.set('txt_output', res.output)

			in_lines := input_text.split_into_lines().len
			out_lines := res.output.split_into_lines().len
			win.set('lbl_in_stats', '  (${input_text.len} chars, ${in_lines} lines)')
			win.set('lbl_out_stats', '  (${res.output.len} chars, ${out_lines} lines)')
			win.set('lbl_status', ' Status: Transformed in ${elapsed_ms} ms  |  In: ${in_lines} lines  |  Out: ${out_lines} lines')
			win.toast('Stream processed in ${elapsed_ms} ms!')
		} else {
			win.set('txt_output', ' sed error (exit code ${res.exit_code}):\n' + res.output)
			win.set('lbl_status', ' sed execution error.')
			win.toast('sed execution error!')
		}
	}

	// -------------------------------------------------------------
	// Event Handlers
	// -------------------------------------------------------------

	// Theme Switching
	win.on_change('dd_theme_selector', fn (mut w simplegui.SimpleWindow, selected string) {
		w.set_theme(selected)
		w.toast('Theme changed to ${selected}')
	})

	// Recipe Selection Change
	win.on_change('dd_recipe', fn [recipes] (mut w simplegui.SimpleWindow, selected string) {
		for r in recipes {
			if selected.contains(r.title) {
				w.set('lbl_recipe_desc', 'Tip: ' + r.desc)
				break
			}
		}
	})

	// Apply Recipe
	win.on_click('btn_apply_recipe', fn [recipes] (mut w simplegui.SimpleWindow) {
		selected := w.get('dd_recipe')
		for r in recipes {
			if selected.contains(r.title) {
				w.set('txt_script', r.script)
				w.set_checked('chk_extended', r.extended)
				w.set_checked('chk_quiet', r.quiet)
				w.set('lbl_recipe_desc', 'Tip: ' + r.desc)
				w.toast('Applied recipe: ' + r.title)
				return
			}
		}
		w.toast('Please select a recipe from the dropdown.')
	})

	// Load Sample Data
	win.on_click('btn_load_sample', fn [recipes, run_sed_transform, sed_bin] (mut w simplegui.SimpleWindow) {
		selected := w.get('dd_recipe')
		for r in recipes {
			if selected.contains(r.title) {
				w.set('txt_script', r.script)
				w.set_checked('chk_extended', r.extended)
				w.set_checked('chk_quiet', r.quiet)
				w.set('txt_input', r.sample)
				w.set('lbl_recipe_desc', 'Tip: ' + r.desc)
				run_sed_transform(mut w, sed_bin)
				w.toast('Loaded sample for: ' + r.title)
				return
			}
		}
		w.toast('Please select a recipe from the dropdown first.')
	})

	// Run Transform
	win.on_click('btn_run', fn [run_sed_transform, sed_bin] (mut w simplegui.SimpleWindow) {
		run_sed_transform(mut w, sed_bin)
	})

	// Swap Output to Input
	win.on_click('btn_swap', fn (mut w simplegui.SimpleWindow) {
		out_text := w.get('txt_output')
		if out_text.trim_space() != '' && !out_text.starts_with('') {
			w.set('txt_input', out_text)
			w.toast('Output moved to Input scratchpad.')
		} else {
			w.toast('No valid output to swap.')
		}
	})

	// Copy Output
	win.on_click('btn_copy_out', fn (mut w simplegui.SimpleWindow) {
		out_text := w.get('txt_output')
		if out_text != '' {
			w.copy_to_clipboard(out_text)
			w.toast('Output copied to clipboard!')
		} else {
			w.toast('Output is empty.')
		}
	})

	// Copy CLI Command
	win.on_click('btn_copy_cmd', fn [sed_bin] (mut w simplegui.SimpleWindow) {
		script_expr := w.get('txt_script').trim_space()
		use_extended := w.get_bool('chk_extended')
		use_quiet := w.get_bool('chk_quiet')
		file_path := w.get('txt_file_path').trim_space()

		mut args := [sed_bin]
		if use_extended { args << '-E' }
		if use_quiet { args << '-n' }
		args << ['-e', simplegui.quote_arg(script_expr)]
		if file_path != '' {
			args << simplegui.quote_path(file_path)
		} else {
			args << 'input.txt'
		}

		cmd := args.join(' ')
		w.copy_to_clipboard(cmd)
		w.toast('CLI command copied to clipboard!')
	})

	// Clear
	win.on_click('btn_clear', fn (mut w simplegui.SimpleWindow) {
		w.set('txt_input', '')
		w.set('txt_output', '')
		w.set('lbl_in_stats', '  (0 chars, 0 lines)')
		w.set('lbl_out_stats', '  (0 chars, 0 lines)')
		w.toast('Scratchpad cleared.')
	})

	// Pick File
	win.on_click('btn_pick_file', fn (mut w simplegui.SimpleWindow) {
		file := w.select_file()
		if file != '' {
			w.set('txt_file_path', file)
			w.toast('Target file selected.')
		}
	})

	// Load file into input scratchpad
	win.on_click('btn_read_file_to_in', fn (mut w simplegui.SimpleWindow) {
		file := w.get('txt_file_path').trim_space()
		if file != '' && os.exists(file) {
			content := os.read_file(file) or { '' }
			w.set('txt_input', content)
			lines := content.split_into_lines().len
			w.set('lbl_in_stats', '  (${content.len} chars, ${lines} lines)')
			w.toast('Loaded ${lines} lines from file!')
		} else {
			w.alert('File Error', 'Target file does not exist.')
		}
	})

	// Reveal File
	win.on_click('btn_reveal_file', fn (mut w simplegui.SimpleWindow) {
		file := w.get('txt_file_path').trim_space()
		if file != '' && os.exists(file) {
			simplegui.reveal_in_finder(file)
			w.toast('Revealed in Finder.')
		}
	})

	// Process File on Disk
	win.on_click('btn_process_file', fn [sed_bin] (mut w simplegui.SimpleWindow) {
		file := w.get('txt_file_path').trim_space()
		script_expr := w.get('txt_script').trim_space()
		use_extended := w.get_bool('chk_extended')
		use_quiet := w.get_bool('chk_quiet')
		use_inplace := w.get_bool('chk_inplace')
		use_backup := w.get_bool('chk_backup')

		if file == '' || !os.exists(file) {
			w.alert('Invalid File', 'Please select an existing disk file to process.')
			return
		}
		if script_expr == '' {
			w.alert('Empty Script', 'Please provide a sed expression.')
			return
		}

		if use_inplace {
			if !w.confirm('In-Place Modification', 'Are you sure you want to modify "${os.file_name(file)}" in-place on disk?') {
				return
			}

			if use_backup {
				os.cp(file, file + '.bak') or {}
			}

			mut args := []string{}
			if use_extended { args << '-E' }
			if use_quiet { args << '-n' }
			args << ['-i', '']
			args << ['-e', script_expr]
			args << file

			res := simplegui.exec_safe(sed_bin, args)
			if res.exit_code == 0 {
				new_content := os.read_file(file) or { '' }
				w.set('txt_output', new_content)
				w.toast('File modified in-place!')
			} else {
				w.alert('sed Error', 'Failed to modify file:\n' + res.output)
			}
		} else {
			mut args := []string{}
			if use_extended { args << '-E' }
			if use_quiet { args << '-n' }
			args << ['-e', script_expr]
			args << file

			t0 := time.ticks()
			res := simplegui.exec_safe(sed_bin, args)
			elapsed_ms := time.ticks() - t0

			if res.exit_code == 0 {
				w.set('txt_output', res.output)
				out_lines := res.output.split_into_lines().len
				w.set('lbl_out_stats', '  (${res.output.len} chars, ${out_lines} lines)')
				w.toast('File processed in ${elapsed_ms} ms!')
			} else {
				w.set('txt_output', ' sed error:\n' + res.output)
			}
		}
	})

	// Save Output to File
	win.on_click('btn_save_out_to_file', fn (mut w simplegui.SimpleWindow) {
		out_text := w.get('txt_output')
		if out_text.trim_space() == '' || out_text.starts_with('') {
			w.alert('Empty Output', 'There is no valid output stream to save.')
			return
		}

		target_file := w.save_file_picker()
		if target_file != '' {
			os.write_file(target_file, out_text) or {
				w.alert('Save Error', 'Failed to write output to file.')
				return
			}
			w.toast('Saved output to ' + os.file_name(target_file))
		}
	})

	// Run initial transformation on default input
	run_sed_transform(mut win, sed_bin)

	println('Sed Studio Pro configured. Starting event loop...')
	win.run()
}

module main

import os
import time
import simplegui

// Helper to find cut binary
fn get_cut_bin() string {
	if path := os.find_abs_path_of_executable('cut') {
		return path
	}
	common_paths := [
		'/usr/bin/cut',
		'/bin/cut',
		'/opt/homebrew/bin/gcut',
		'/usr/local/bin/gcut',
	]
	for p in common_paths {
		if os.exists(p) {
			return p
		}
	}
	return 'cut'
}

struct CutRecipe {
	title       string
	mode        string // 'fields', 'chars', 'bytes'
	fields      string
	delim_type  string // 'comma', 'tab', 'colon', 'pipe', 'slash', 'semicolon', 'whitespace', 'custom'
	custom_delim string
	suppress_no_delim bool
	sample_data string
	desc        string
}

fn get_all_cut_recipes() []CutRecipe {
	return [
		CutRecipe{
			title: ' Extract Usernames from /etc/passwd (-d: -f1)'
			mode: 'fields'
			fields: '1'
			delim_type: 'colon'
			custom_delim: ':'
			suppress_no_delim: true
			sample_data: 'root:x:0:0:System Administrator:/var/root:/bin/sh\ndaemon:x:1:1:System Services:/var/root:/usr/bin/false\n_spotlight:x:89:89:Spotlight:/var/spotlight:/usr/bin/false\ndeveloper:x:501:20:Developer User:/Users/developer:/bin/zsh'
			desc: 'Cuts out the 1st field (username) from standard Unix passwd format.'
		},
		CutRecipe{
			title: ' Extract Username & Login Shell (-d: -f1,7)'
			mode: 'fields'
			fields: '1,7'
			delim_type: 'colon'
			custom_delim: ':'
			suppress_no_delim: true
			sample_data: 'root:x:0:0:System Administrator:/var/root:/bin/sh\ndaemon:x:1:1:System Services:/var/root:/usr/bin/false\ndeveloper:x:501:20:Developer User:/Users/developer:/bin/zsh'
			desc: 'Extracts username (col 1) and user shell (col 7).'
		},
		CutRecipe{
			title: ' Extract CSV Columns 1 to 3 (-d, -f1-3)'
			mode: 'fields'
			fields: '1-3'
			delim_type: 'comma'
			custom_delim: ','
			suppress_no_delim: false
			sample_data: 'id,name,role,department,salary,city\n101,Alice Smith,Principal Engineer,Core Infra,185000,San Francisco\n102,Bob Jones,Senior Designer,Product Design,145000,New York\n103,Charlie Brown,Security Analyst,SecOps,160000,Austin'
			desc: 'Cuts out the first 3 columns (id, name, role) from comma-separated data.'
		},
		CutRecipe{
			title: ' Extract Specific CSV Columns 2 & 4 (-d, -f2,4)'
			mode: 'fields'
			fields: '2,4'
			delim_type: 'comma'
			custom_delim: ','
			suppress_no_delim: false
			sample_data: 'id,name,role,department,salary,city\n101,Alice Smith,Principal Engineer,Core Infra,185000,San Francisco\n102,Bob Jones,Senior Designer,Product Design,145000,New York\n103,Charlie Brown,Security Analyst,SecOps,160000,Austin'
			desc: 'Cuts only name and department fields.'
		},
		CutRecipe{
			title: ' Extract TSV Tab-Separated Field 2 (-f2)'
			mode: 'fields'
			fields: '2'
			delim_type: 'tab'
			custom_delim: '\t'
			suppress_no_delim: false
			sample_data: "2026-08-21\tINFO\tServer worker pool spawned successfully\n2026-08-21\tWARN\tHigh memory pressure threshold reached\n2026-08-21\tERROR\tConnection reset by peer at port 8080"
			desc: 'Extracts the log level column from tab-separated log files.'
		},
		CutRecipe{
			title: ' Extract Domain from URLs (-d/ -f3)'
			mode: 'fields'
			fields: '3'
			delim_type: 'slash'
			custom_delim: '/'
			suppress_no_delim: true
			sample_data: 'https://github.com/vlang/v\nhttps://apple.com/macos/sequoia\nhttps://news.ycombinator.com/item?id=4000\nhttp://127.0.0.1:8080/api/v1/metrics'
			desc: 'Slices out the domain / host segment from full web URLs.'
		},
		CutRecipe{
			title: ' Extract ISO Date Part Only (-c1-10)'
			mode: 'chars'
			fields: '1-10'
			delim_type: 'none'
			custom_delim: ''
			suppress_no_delim: false
			sample_data: '2026-08-21T21:40:15.123Z [INFO] System started\n2026-08-22T04:12:00.000Z [METRICS] GC cycle finished\n2026-08-22T09:30:45.999Z [ALERT] Latency spike detected'
			desc: 'Cuts out exactly the first 10 characters (YYYY-MM-DD) from ISO timestamps.'
		},
		CutRecipe{
			title: ' Strip Leading 10 Characters (-c11-)'
			mode: 'chars'
			fields: '11-'
			delim_type: 'none'
			custom_delim: ''
			suppress_no_delim: false
			sample_data: '0000000001: Order item initialized\n0000000002: Payment verified via Stripe\n0000000003: Fulfillment dispatched'
			desc: 'Discards fixed-width leading IDs and retains remaining line content.'
		},
		CutRecipe{
			title: ' Parse Whitespace Columns (-w -f1,9)'
			mode: 'fields'
			fields: '1,9'
			delim_type: 'whitespace'
			custom_delim: ''
			suppress_no_delim: false
			sample_data: '-rwxr-xr-x   1 root  wheel    52340 Aug 21 12:00 /usr/bin/cut\n-rwxr-xr-x   1 root  wheel   184200 Aug 21 12:00 /usr/bin/grep\n-rwxr-xr-x   1 root  wheel  1204850 Aug 21 12:00 /opt/homebrew/bin/rg'
			desc: 'Parses space-separated ls -l output to extract file permissions and filename.'
		},
	]
}

fn main() {
	println('Starting SimpleGUI - Cut Studio Pro (Stream & Column Slicing Workbench)...')

	mut win := simplegui.new_simple_window('SimpleGUI - Cut Studio Pro', 1060, 960)
	win.set_fullscreen(true)
	win.set_spacing(8)
	win.set_padding(16)

	saved_theme := simplegui.get_saved_theme()
	win.set_theme(saved_theme)

	// Top Banner
	win.begin_row('row_cut_top')
	win.add_heading('Cut Studio Pro')
	win.add_label('lbl_theme', 'Theme:')
	win.add_dropdown('dd_app_theme', simplegui.list_themes(), saved_theme)
	win.set_control_width('dd_app_theme', 150)
	win.end_row()

	win.on_change('dd_app_theme', fn (mut w simplegui.SimpleWindow, selected string) {
		w.set_theme(selected)
		w.toast('Theme changed to ${selected}')
	})

	cut_path := get_cut_bin()
	win.add_label('lbl_engine_info', 'Engine: ${cut_path}  |  Platform: macOS Cocoa  |  Mode: Async Worker (Zero UI Freezes)')

	all_recipes := get_all_cut_recipes()

	// -------------------------------------------------------------
	// Cut Parameters & Slicing Mode
	// -------------------------------------------------------------
	win.begin_group_box('grp_params', 'Slicing Mode & Range Specification')
	
	win.begin_row('row_mode')
	win.add_label('lbl_mode', 'Cut Mode:')
	win.add_dropdown('dd_mode', [
		'Fields (-f)',
		'Character Columns (-c)',
		'Byte Positions (-b)'
	], 'Fields (-f)')
	win.set_control_width('dd_mode', 180)

	win.add_label('lbl_fields', 'Range / Fields List:')
	win.add_input('txt_fields', '1-3')
	win.set_control_width('txt_fields', 180)

	win.add_label('lbl_delim', 'Delimiter (-d):')
	win.add_dropdown('dd_delim', [
		'Comma (,)',
		'Tab (\\t)',
		'Colon (:)',
		'Pipe (|)',
		'Slash (/)',
		'Semicolon (;)',
		'Whitespace (-w)',
		'Custom Delimiter'
	], 'Comma (,)')
	win.set_control_width('dd_delim', 160)

	win.add_input('txt_custom_delim', ',')
	win.set_control_width('txt_custom_delim', 40)

	win.add_checkbox('chk_suppress', 'Only Delimited (-s)', false)
	win.end_row()

	win.end_group_box()

	// -------------------------------------------------------------
	// Recipes Bar & File Input
	// -------------------------------------------------------------
	win.begin_group_box('grp_recipes_files', 'Slicing Recipes & External File Source')
	
	mut recipe_titles := ['-- Select a Fast Slicing Recipe --']
	for r in all_recipes {
		recipe_titles << r.title
	}

	win.begin_row('row_recipes')
	win.add_label('lbl_recipe', 'Quick Recipe:')
	win.add_dropdown('dd_recipe', recipe_titles, recipe_titles[0])
	win.set_control_width('dd_recipe', 480)
	win.add_button('btn_apply_recipe', 'Load Recipe')
	win.add_button('btn_run_recipe_now', 'Load & Slice')
	win.end_row()

	win.begin_row('row_file_src')
	win.add_label('lbl_file', 'Or Disk File:')
	win.add_input('txt_file_path', '')
	win.set_control_width('txt_file_path', 480)
	win.add_button('btn_browse_file', 'Choose File...')
	win.add_button('btn_load_file_into_editor', 'Load into Editor')
	win.end_row()

	win.end_group_box()

	// -------------------------------------------------------------
	// Dual-Pane Interactive Stream Editor
	// -------------------------------------------------------------
	initial_data := 'id,name,role,department,salary,city\n101,Alice Smith,Principal Engineer,Core Infra,185000,San Francisco\n102,Bob Jones,Senior Designer,Product Design,145000,New York\n103,Charlie Brown,Security Analyst,SecOps,160000,Austin\n104,Diana Prince,Engineering Director,Security,210000,Seattle\n105,Evan Wright,Staff SRE,Reliability,175000,Denver'
	win.begin_grid('grid_panes', 2, 8)
	win.add_form_textarea('Input Data Stream:', 'txt_input_stream', initial_data)
	win.set_control_height('txt_input_stream', 260)
	win.add_form_textarea('Sliced Output Stream:', 'txt_output_stream', '')
	win.set_control_height('txt_output_stream', 260)
	win.end_grid()

	// -------------------------------------------------------------
	// Actions & Live Execution Bar
	// -------------------------------------------------------------
	win.begin_row('row_actions')
	win.add_button('btn_run_cut', 'Slice Stream Now')
	win.add_button('btn_copy_output', 'Copy Output')
	win.add_button('btn_save_output', 'Save Output...')
	win.add_button('btn_clear_all', 'Clear')
	win.end_row()

	// Stats Row
	win.begin_row('row_stats')
	win.add_label('lbl_stats', 'Stats: Ready  |  Output Lines: 0  |  Duration: 0 ms')
	win.end_row()

	// -------------------------------------------------------------
	// Core cut Slicing Engine (Async Non-Blocking)
	// -------------------------------------------------------------
	execute_cut_slice := fn (mut win simplegui.SimpleWindow) {
		cut := get_cut_bin()
		mode_val := win.get('dd_mode')
		fields_val := win.get('txt_fields').trim_space()
		if fields_val == '' {
			win.alert('Range Required', 'Please specify a range or field list (e.g. 1-3, 1,4, 2-).')
			return
		}

		delim_choice := win.get('dd_delim')
		custom_delim := win.get('txt_custom_delim')
		suppress_delim := win.get('chk_suppress') == 'true'
		file_path := win.get('txt_file_path').trim_space()
		input_stream := win.get('txt_input_stream')

		win.set_status('Slicing data stream with cut in background...')
		win.toast('Processing stream...')

		go fn [mut win, cut, mode_val, fields_val, delim_choice, custom_delim, suppress_delim, file_path, input_stream] () {
			t0 := time.ticks()

			mut raw_args := []string{}

			if mode_val.contains('Character') {
				raw_args << ['-c', fields_val]
			} else if mode_val.contains('Byte') {
				raw_args << ['-b', fields_val]
			} else {
				// Fields mode
				raw_args << ['-f', fields_val]
				
				if delim_choice.contains('Whitespace') {
					raw_args << '-w'
				} else if delim_choice.contains('Comma') {
					raw_args << ['-d', ',']
				} else if delim_choice.contains('Tab') {
					raw_args << ['-d', '\t']
				} else if delim_choice.contains('Colon') {
					raw_args << ['-d', ':']
				} else if delim_choice.contains('Pipe') {
					raw_args << ['-d', '|']
				} else if delim_choice.contains('Slash') {
					raw_args << ['-d', '/']
				} else if delim_choice.contains('Semicolon') {
					raw_args << ['-d', ';']
				} else if delim_choice.contains('Custom') {
					if custom_delim != '' {
						raw_args << ['-d', custom_delim]
					}
				}

				if suppress_delim {
					raw_args << '-s'
				}
			}

			tmp_input := os.join_path(os.temp_dir(), 'cut_input_${time.ticks()}.tmp')
			mut target_file := tmp_input

			if file_path != '' && os.exists(file_path) {
				target_file = file_path
			} else {
				os.write_file(tmp_input, input_stream) or {
					win.run_on_main_thread(fn [err] (mut win_main simplegui.SimpleWindow) {
						win_main.alert('IO Error', 'Failed to write temporary buffer: ' + err.str())
					})
					return
				}
			}

			raw_args << target_file
			res := simplegui.exec_safe(cut, raw_args)
			elapsed_ms := time.ticks() - t0

			if target_file == tmp_input && os.exists(tmp_input) {
				os.rm(tmp_input) or {}
			}

			win.run_on_main_thread(fn [res, elapsed_ms] (mut win_main simplegui.SimpleWindow) {
				if res.exit_code == 0 {
					out_str := res.output
					win_main.set('txt_output_stream', out_str)
					
					mut count := 0
					if out_str.trim_space() != '' {
						count = out_str.trim_space().split_into_lines().len
					}

					win_main.set('lbl_stats', ' Stats: SUCCESS  |  Output Lines: ${count}  |  Duration: ${elapsed_ms} ms')
					win_main.set_status('Stream sliced successfully (${count} lines in ${elapsed_ms} ms).')
					win_main.toast('Sliced ${count} lines in ${elapsed_ms} ms!')
				} else {
					win_main.set('txt_output_stream', ' Cut Slicing Error:\n\n' + res.output)
					win_main.set('lbl_stats', ' Stats: ERROR (Exit code ${res.exit_code})  |  Duration: ${elapsed_ms} ms')
					win_main.set_status('Cut command returned an error.')
				}
			})
		}()
	}

	// -------------------------------------------------------------
	// Event Handlers
	// -------------------------------------------------------------

	// Browse File
	win.on_click('btn_browse_file', fn (mut w simplegui.SimpleWindow) {
		f := w.select_file()
		if f != '' && os.exists(f) {
			w.set('txt_file_path', f)
			w.toast('Target file selected.')
		}
	})

	// Load file into input editor
	win.on_click('btn_load_file_into_editor', fn (mut w simplegui.SimpleWindow) {
		f := w.get('txt_file_path').trim_space()
		if f != '' && os.exists(f) {
			content := os.read_file(f) or {
				w.alert('Read Error', 'Failed to read file: ' + err.str())
				return
			}
			w.set('txt_input_stream', content)
			w.toast('Loaded ${content.split_into_lines().len} lines into editor.')
		} else {
			w.toast('Please select a valid file path first.')
		}
	})

	// Clear All
	win.on_click('btn_clear_all', fn (mut w simplegui.SimpleWindow) {
		w.set('txt_input_stream', '')
		w.set('txt_output_stream', '')
		w.set('txt_file_path', '')
		w.set('lbl_stats', ' Stats: Ready  |  Output Lines: 0  |  Duration: 0 ms')
		w.toast('Cleared panes.')
	})

	// Copy Output
	win.on_click('btn_copy_output', fn (mut w simplegui.SimpleWindow) {
		out := w.get('txt_output_stream').trim_space()
		if out != '' {
			w.copy_to_clipboard(out)
			w.toast('Copied output to clipboard!')
		} else {
			w.toast('No output to copy.')
		}
	})

	// Save Output
	win.on_click('btn_save_output', fn (mut w simplegui.SimpleWindow) {
		out := w.get('txt_output_stream').trim_space()
		if out == '' {
			w.toast('No output to save.')
			return
		}
		path := w.save_file_picker()
		if path != '' {
			os.write_file(path, out) or {
				w.alert('Save Error', 'Failed to save file: ' + err.str())
				return
			}
			w.toast('Saved output to ${path}')
		}
	})

	// Apply Recipe
	win.on_click('btn_apply_recipe', fn [all_recipes] (mut w simplegui.SimpleWindow) {
		sel := w.get('dd_recipe')
		for r in all_recipes {
			if sel.contains(r.title) {
				if r.mode == 'chars' {
					w.set_text('dd_mode', 'Character Columns (-c)')
				} else if r.mode == 'bytes' {
					w.set_text('dd_mode', 'Byte Positions (-b)')
				} else {
					w.set_text('dd_mode', 'Fields (-f)')
				}
				w.set('txt_fields', r.fields)
				
				if r.delim_type == 'comma' { w.set_text('dd_delim', 'Comma (,)') }
				else if r.delim_type == 'tab' { w.set_text('dd_delim', 'Tab (\\t)') }
				else if r.delim_type == 'colon' { w.set_text('dd_delim', 'Colon (:)') }
				else if r.delim_type == 'pipe' { w.set_text('dd_delim', 'Pipe (|)') }
				else if r.delim_type == 'slash' { w.set_text('dd_delim', 'Slash (/)') }
				else if r.delim_type == 'semicolon' { w.set_text('dd_delim', 'Semicolon (;)') }
				else if r.delim_type == 'whitespace' { w.set_text('dd_delim', 'Whitespace (-w)') }
				else if r.delim_type == 'custom' { 
					w.set_text('dd_delim', 'Custom Delimiter')
					w.set('txt_custom_delim', r.custom_delim)
				}

				w.set('chk_suppress', r.suppress_no_delim.str())
				if r.sample_data != '' {
					w.set('txt_input_stream', r.sample_data)
				}
				w.toast('Loaded recipe: ' + r.title)
				return
			}
		}
		w.toast('Please select a recipe from the dropdown.')
	})

	// Load & Slice Recipe
	win.on_click('btn_run_recipe_now', fn [all_recipes, execute_cut_slice] (mut w simplegui.SimpleWindow) {
		sel := w.get('dd_recipe')
		for r in all_recipes {
			if sel.contains(r.title) {
				if r.mode == 'chars' {
					w.set_text('dd_mode', 'Character Columns (-c)')
				} else if r.mode == 'bytes' {
					w.set_text('dd_mode', 'Byte Positions (-b)')
				} else {
					w.set_text('dd_mode', 'Fields (-f)')
				}
				w.set('txt_fields', r.fields)
				
				if r.delim_type == 'comma' { w.set_text('dd_delim', 'Comma (,)') }
				else if r.delim_type == 'tab' { w.set_text('dd_delim', 'Tab (\\t)') }
				else if r.delim_type == 'colon' { w.set_text('dd_delim', 'Colon (:)') }
				else if r.delim_type == 'pipe' { w.set_text('dd_delim', 'Pipe (|)') }
				else if r.delim_type == 'slash' { w.set_text('dd_delim', 'Slash (/)') }
				else if r.delim_type == 'semicolon' { w.set_text('dd_delim', 'Semicolon (;)') }
				else if r.delim_type == 'whitespace' { w.set_text('dd_delim', 'Whitespace (-w)') }

				w.set('chk_suppress', r.suppress_no_delim.str())
				if r.sample_data != '' {
					w.set('txt_input_stream', r.sample_data)
				}
				execute_cut_slice(mut w)
				return
			}
		}
		w.toast('Please select a recipe from the dropdown.')
	})

	// Slice Button
	win.on_click('btn_run_cut', fn [execute_cut_slice] (mut w simplegui.SimpleWindow) {
		execute_cut_slice(mut w)
	})

	println('Cut Studio Pro configured. Starting event loop...')
	win.run()
}

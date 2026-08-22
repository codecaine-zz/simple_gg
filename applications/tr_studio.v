module main

import os
import time
import simplegui

// Helper to find tr binary
fn get_tr_bin() string {
	if path := os.find_abs_path_of_executable('tr') {
		return path
	}
	common_paths := [
		'/usr/bin/tr',
		'/bin/tr',
		'/opt/homebrew/bin/gtr',
		'/usr/local/bin/gtr',
	]
	for p in common_paths {
		if os.exists(p) {
			return p
		}
	}
	return 'tr'
}

struct TrRecipe {
	title       string
	mode        string // 'translate', 'delete', 'squeeze', 'del_squeeze'
	str1        string
	str2        string
	complement  bool
	sample_data string
	desc        string
}

fn get_all_tr_recipes() []TrRecipe {
	return [
		TrRecipe{
			title: ' UPPERCASE Everything ([:lower:] -> [:upper:])'
			mode: 'translate'
			str1: '[:lower:]'
			str2: '[:upper:]'
			complement: false
			sample_data: 'the quick brown fox jumps over the lazy dog.\nsimplegui high performance macos desktop engine.'
			desc: 'Converts all lowercase letters to uppercase.'
		},
		TrRecipe{
			title: ' lowercase Everything ([:upper:] -> [:lower:])'
			mode: 'translate'
			str1: '[:upper:]'
			str2: '[:lower:]'
			complement: false
			sample_data: 'SYSTEM DIAGNOSTICS: MEMORY UTILIZATION AT 34.2%\nALL 18 THEME PALETTES CALIBRATED.'
			desc: 'Converts all uppercase letters to lowercase.'
		},
		TrRecipe{
			title: ' Strip Windows CRLF Line Endings (-d \\r)'
			mode: 'delete'
			str1: r'\r'
			str2: ''
			complement: false
			sample_data: "Line 1 with Windows CRLF\r\nLine 2 with Windows CRLF\r\nLine 3 with Windows CRLF\r\n"
			desc: 'Removes carriage returns (\\r) converting Windows files cleanly to Unix.'
		},
		TrRecipe{
			title: ' Squeeze Multiple Spaces into Single Space (-s " ")'
			mode: 'squeeze'
			str1: ' '
			str2: ''
			complement: false
			sample_data: 'Column1     Column2          Column3    Column4\nUser       Admin            Active     192.168.1.1'
			desc: 'Collapses redundant consecutive spaces into a single space.'
		},
		TrRecipe{
			title: ' Squeeze Multiple Blank Lines (-s \\n)'
			mode: 'squeeze'
			str1: r'\n'
			str2: ''
			complement: false
			sample_data: "Paragraph 1: Introduction\n\n\n\n\nParagraph 2: Implementation\n\n\n\n\nParagraph 3: Conclusion"
			desc: 'Collapses multiple consecutive newlines down to single line breaks.'
		},
		TrRecipe{
			title: ' Convert Newlines to Comma Separator (\\n -> ,)'
			mode: 'translate'
			str1: r'\n'
			str2: ','
			complement: false
			sample_data: "apple\nbanana\ncherry\ndate\nelderberry\nfig\ngrape"
			desc: 'Converts vertical list items into a single comma-separated row.'
		},
		TrRecipe{
			title: ' Convert Spaces to Newlines (Word Per Line)'
			mode: 'translate'
			str1: ' '
			str2: r'\n'
			complement: false
			sample_data: 'SimpleGUI provides fast intuitive native macOS controls in V language'
			desc: 'Splits space-delimited text into one word per line.'
		},
		TrRecipe{
			title: ' Strip All Non-Printable Characters (-cd [:print:]\\n)'
			mode: 'delete'
			str1: r'[:print:]\n'
			str2: ''
			complement: true
			sample_data: "Clean standard line\x01\x02\x03 with binary noise\x00 and control codes\x1b"
			desc: 'Deletes all non-printable/corrupted bytes, keeping only printable ASCII and newlines.'
		},
		TrRecipe{
			title: ' Extract Only Digits / Numbers (-cd [:digit:]\\n)'
			mode: 'delete'
			str1: r'[:digit:]\n'
			str2: ''
			complement: true
			sample_data: "Invoice #INV-2026-98124 | Amount: $18,450.00 USD\nOrder Reference: PO-88741-B | Tracking ID: 940011189956"
			desc: 'Deletes all letters and punctuation, extracting only numeric digits.'
		},
		TrRecipe{
			title: ' Classic ROT13 Cipher Translation'
			mode: 'translate'
			str1: 'A-Za-z'
			str2: 'N-ZA-Mn-za-m'
			complement: false
			sample_data: 'SimpleGUI is super fast and lightweight!'
			desc: 'Applies the 13-character Caesar rotation cipher (ROT13).'
		},
	]
}

fn main() {
	println('Starting SimpleGUI - TR Studio Pro (Character Translation & Cleansing Workbench)...')

	mut win := simplegui.new_simple_window('SimpleGUI - TR Studio Pro', 1060, 960)
	win.set_fullscreen(true)
	win.set_spacing(8)
	win.set_padding(16)

	saved_theme := simplegui.get_saved_theme()
	win.set_theme(saved_theme)

	// Top Banner
	win.begin_row('row_tr_top')
	win.add_heading('TR Studio Pro')
	win.add_label('lbl_theme', 'Theme:')
	win.add_dropdown('dd_app_theme', simplegui.list_themes(), saved_theme)
	win.set_control_width('dd_app_theme', 150)
	win.end_row()

	win.on_change('dd_app_theme', fn (mut w simplegui.SimpleWindow, selected string) {
		w.set_theme(selected)
		w.toast('Theme changed to ${selected}')
	})

	tr_path := get_tr_bin()
	win.add_label('lbl_engine_info', 'Engine: ${tr_path}  |  Platform: macOS Cocoa  |  Mode: Async Stream Worker (Zero UI Freezes)')

	all_recipes := get_all_tr_recipes()

	// -------------------------------------------------------------
	// Transformation Parameters & Mode
	// -------------------------------------------------------------
	win.begin_group_box('grp_params', 'Translation Mode & Character Set Mapping')
	
	win.begin_row('row_mode')
	win.add_label('lbl_op_mode', 'Operation Mode:')
	win.add_dropdown('dd_op_mode', [
		'Translate (Set1 -> Set2)',
		'Delete Characters (-d Set1)',
		'Squeeze Repeats (-s Set1)',
		'Delete & Squeeze (-ds Set1 Set2)'
	], 'Translate (Set1 -> Set2)')
	win.set_control_width('dd_op_mode', 220)

	win.add_label('lbl_set1', 'Set 1 (Input / Target):')
	win.add_input('txt_set1', '[:lower:]')
	win.set_control_width('txt_set1', 170)

	win.add_label('lbl_set2', 'Set 2 (Replacement):')
	win.add_input('txt_set2', '[:upper:]')
	win.set_control_width('txt_set2', 170)

	win.add_checkbox('chk_complement', 'Complement (-c)', false)
	win.end_row()

	win.end_group_box()

	// -------------------------------------------------------------
	// Recipes Bar & File Input
	// -------------------------------------------------------------
	win.begin_group_box('grp_recipes_files', 'Quick Cleansing Recipes & Disk File Source')
	
	mut recipe_titles := ['-- Select a Fast Cleansing Recipe --']
	for r in all_recipes {
		recipe_titles << r.title
	}

	win.begin_row('row_recipes')
	win.add_label('lbl_recipe', 'Quick Recipe:')
	win.add_dropdown('dd_recipe', recipe_titles, recipe_titles[0])
	win.set_control_width('dd_recipe', 480)
	win.add_button('btn_apply_recipe', 'Load Recipe')
	win.add_button('btn_run_recipe_now', 'Load & Translate')
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
	initial_data := 'the quick brown fox jumps over the lazy dog.\nsimplegui high performance macos desktop engine.'
	win.begin_grid('grid_panes', 2, 8)
	win.add_form_textarea('Input Character Stream:', 'txt_input_stream', initial_data)
	win.set_control_height('txt_input_stream', 260)
	win.add_form_textarea('Translated Output Stream:', 'txt_output_stream', '')
	win.set_control_height('txt_output_stream', 260)
	win.end_grid()

	// -------------------------------------------------------------
	// Actions & Live Execution Bar
	// -------------------------------------------------------------
	win.begin_row('row_actions')
	win.add_button('btn_run_tr', 'Translate Stream Now')
	win.add_button('btn_copy_output', 'Copy Output')
	win.add_button('btn_save_output', 'Save Output...')
	win.add_button('btn_clear_all', 'Clear')
	win.end_row()

	// Stats Row
	win.begin_row('row_stats')
	win.add_label('lbl_stats', 'Stats: Ready  |  Characters: 0  |  Duration: 0 ms')
	win.end_row()

	// -------------------------------------------------------------
	// Core tr Translation Engine (Async Non-Blocking)
	// -------------------------------------------------------------
	execute_tr_transform := fn (mut win simplegui.SimpleWindow) {
		tr := get_tr_bin()
		mode_val := win.get('dd_op_mode')
		set1_val := win.get('txt_set1').trim_space()
		set2_val := win.get('txt_set2').trim_space()

		if set1_val == '' {
			win.alert('Set Required', 'Please specify Character Set 1.')
			return
		}

		is_comp := win.get('chk_complement') == 'true'
		file_path := win.get('txt_file_path').trim_space()
		input_stream := win.get('txt_input_stream')

		win.set_status('Processing stream with tr in background...')
		win.toast('Transforming stream...')

		go fn [mut win, tr, mode_val, set1_val, set2_val, is_comp, file_path, input_stream] () {
			t0 := time.ticks()

			mut raw_args := []string{}

			if is_comp {
				raw_args << '-c'
			}

			if mode_val.contains('Delete & Squeeze') {
				raw_args << '-ds'
				raw_args << set1_val
				if set2_val != '' {
					raw_args << set2_val
				}
			} else if mode_val.contains('Delete') {
				raw_args << '-d'
				raw_args << set1_val
			} else if mode_val.contains('Squeeze') {
				raw_args << '-s'
				raw_args << set1_val
				if set2_val != '' {
					raw_args << set2_val
				}
			} else {
				// Translate mode
				raw_args << set1_val
				if set2_val != '' {
					raw_args << set2_val
				}
			}

			tmp_input := os.join_path(os.temp_dir(), 'tr_input_${time.ticks()}.tmp')
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

			res := simplegui.exec_safe_stdin(tr, raw_args, target_file)
			elapsed_ms := time.ticks() - t0

			if target_file == tmp_input && os.exists(tmp_input) {
				os.rm(tmp_input) or {}
			}

			win.run_on_main_thread(fn [res, elapsed_ms] (mut win_main simplegui.SimpleWindow) {
				if res.exit_code == 0 {
					out_str := res.output
					win_main.set('txt_output_stream', out_str)
					
					char_count := out_str.len
					line_count := if out_str.trim_space() != '' { out_str.trim_space().split_into_lines().len } else { 0 }

					win_main.set('lbl_stats', ' Stats: SUCCESS  |  Chars: ${char_count}  |  Lines: ${line_count}  |  Duration: ${elapsed_ms} ms')
					win_main.set_status('Stream translated successfully (${char_count} chars in ${elapsed_ms} ms).')
					win_main.toast('Translated ${char_count} chars in ${elapsed_ms} ms!')
				} else {
					win_main.set('txt_output_stream', ' TR Translation Error:\n\n' + res.output)
					win_main.set('lbl_stats', ' Stats: ERROR (Exit code ${res.exit_code})  |  Duration: ${elapsed_ms} ms')
					win_main.set_status('TR command returned an error.')
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
			w.toast('Loaded ${content.len} chars into editor.')
		} else {
			w.toast('Please select a valid file path first.')
		}
	})

	// Clear All
	win.on_click('btn_clear_all', fn (mut w simplegui.SimpleWindow) {
		w.set('txt_input_stream', '')
		w.set('txt_output_stream', '')
		w.set('txt_file_path', '')
		w.set('lbl_stats', ' Stats: Ready  |  Characters: 0  |  Duration: 0 ms')
		w.toast('Cleared panes.')
	})

	// Copy Output
	win.on_click('btn_copy_output', fn (mut w simplegui.SimpleWindow) {
		out := w.get('txt_output_stream')
		if out != '' {
			w.copy_to_clipboard(out)
			w.toast('Copied output to clipboard!')
		} else {
			w.toast('No output to copy.')
		}
	})

	// Save Output
	win.on_click('btn_save_output', fn (mut w simplegui.SimpleWindow) {
		out := w.get('txt_output_stream')
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
				if r.mode == 'delete' {
					w.set_text('dd_op_mode', 'Delete Characters (-d Set1)')
				} else if r.mode == 'squeeze' {
					w.set_text('dd_op_mode', 'Squeeze Repeats (-s Set1)')
				} else if r.mode == 'del_squeeze' {
					w.set_text('dd_op_mode', 'Delete & Squeeze (-ds Set1 Set2)')
				} else {
					w.set_text('dd_op_mode', 'Translate (Set1 -> Set2)')
				}

				w.set('txt_set1', r.str1)
				w.set('txt_set2', r.str2)
				w.set('chk_complement', r.complement.str())

				if r.sample_data != '' {
					w.set('txt_input_stream', r.sample_data)
				}
				w.toast('Loaded recipe: ' + r.title)
				return
			}
		}
		w.toast('Please select a recipe from the dropdown.')
	})

	// Load & Translate Recipe
	win.on_click('btn_run_recipe_now', fn [all_recipes, execute_tr_transform] (mut w simplegui.SimpleWindow) {
		sel := w.get('dd_recipe')
		for r in all_recipes {
			if sel.contains(r.title) {
				if r.mode == 'delete' {
					w.set_text('dd_op_mode', 'Delete Characters (-d Set1)')
				} else if r.mode == 'squeeze' {
					w.set_text('dd_op_mode', 'Squeeze Repeats (-s Set1)')
				} else if r.mode == 'del_squeeze' {
					w.set_text('dd_op_mode', 'Delete & Squeeze (-ds Set1 Set2)')
				} else {
					w.set_text('dd_op_mode', 'Translate (Set1 -> Set2)')
				}

				w.set('txt_set1', r.str1)
				w.set('txt_set2', r.str2)
				w.set('chk_complement', r.complement.str())

				if r.sample_data != '' {
					w.set('txt_input_stream', r.sample_data)
				}
				execute_tr_transform(mut w)
				return
			}
		}
		w.toast('Please select a recipe from the dropdown.')
	})

	// Translate Button
	win.on_click('btn_run_tr', fn [execute_tr_transform] (mut w simplegui.SimpleWindow) {
		execute_tr_transform(mut w)
	})

	println('TR Studio Pro configured. Starting event loop...')
	win.run()
}

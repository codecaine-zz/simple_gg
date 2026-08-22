module main

import os
import time
import simplegui

// Helper to find jq path
fn get_jq_bin() string {
	if path := os.find_abs_path_of_executable('jq') {
		return path
	}
	common_paths := [
		'/opt/homebrew/bin/jq',
		'/usr/local/bin/jq',
		'/bin/jq',
		'/usr/bin/jq',
	]
	for p in common_paths {
		if os.exists(p) {
			return p
		}
	}
	return 'jq'
}

const sample_json = '{
  "status": "success",
  "project": "SimpleGUI",
  "version": "1.4.0",
  "author": {
    "name": "Alex",
    "github": "https://github.com/vlang",
    "active": true
  },
  "metrics": {
    "stars": 4200,
    "forks": 380,
    "issues_open": 12,
    "license": "MIT"
  },
  "modules": [
    {"name": "controls", "lines": 4200, "status": "stable", "priority": 1},
    {"name": "window", "lines": 3500, "status": "stable", "priority": 2},
    {"name": "layout", "lines": 1200, "status": "beta", "priority": 3},
    {"name": "theming", "lines": 850, "status": "stable", "priority": 4},
    {"name": "designer", "lines": 2900, "status": "preview", "priority": 5}
  ],
  "tags": ["vlang", "gui", "macos", "cocoa", "fast", "native"]
}'

fn main() {
	println('Starting SimpleGUI - JQ Studio Pro (JSON Query & Transform Workbench)...')

	mut win := simplegui.new_simple_window('SimpleGUI - JQ Studio Pro', 1040, 920)
	win.set_fullscreen(true)
	win.set_spacing(8)
	win.set_padding(16)

	saved_theme := simplegui.get_saved_theme()
	win.set_theme(saved_theme)

	// Top Banner / Diagnostics
	win.begin_row('row_jq_top')
	win.add_heading('JQ Studio Pro')
	win.add_label('lbl_theme', 'Theme:')
	win.add_dropdown('dd_app_theme', simplegui.list_themes(), saved_theme)
	win.set_control_width('dd_app_theme', 150)
	win.end_row()

	win.on_change('dd_app_theme', fn (mut w simplegui.SimpleWindow, selected string) {
		w.set_theme(selected)
		w.toast('Theme changed to ${selected}')
	})

	jq_path := get_jq_bin()
	win.add_label('lbl_engine_info', 'Engine: ${jq_path}  |  Platform: macOS Cocoa  |  Mode: Async Worker (Non-Blocking)')

	// Filter & Query Configuration Bar
	win.begin_group_box('grp_query', 'JQ Filter Expression & Query Builder')
	
	win.begin_row('row_query_input')
	win.add_label('lbl_filter', 'JQ Filter:')
	win.add_input('txt_filter', '.')
	win.set_control_width('txt_filter', 360)

	win.add_label('lbl_presets', 'Recipes:')
	win.add_dropdown('dd_presets', [
		'1. Pretty-Print Identity (.)',
		'2. Extract Root Keys (keys)',
		'3. Map Module Names (.modules | map(.name))',
		'4. Filter Stable Modules (.modules[] | select(.status == "stable"))',
		'5. Project Custom Object ({app: .project, total_lines: ([.modules[].lines] | add)})',
		'6. Sort Modules by Lines (.modules | sort_by(.lines) | reverse)',
		'7. Top-Level Key-Value Pairs (to_entries[])',
		'8. Extract All Tags as CSV (.tags | join(", "))',
		'9. Filter Modules with Lines > 2000 (.modules[] | select(.lines > 2000))',
		'10. Total Lines Sum ([.modules[].lines] | add)',
		'11. Flatten Nested Structure (.. | strings)',
		'12. Group Modules by Status (.modules | group_by(.status))'
	], '1. Pretty-Print Identity (.)')
	win.set_control_width('dd_presets', 280)
	win.end_row()

	win.begin_row('row_query_flags')
	win.add_checkbox('chk_compact', 'Compact (-c)', false)
	win.add_checkbox('chk_raw', 'Raw Output (-r)', false)
	win.add_checkbox('chk_sort_keys', 'Sort Keys (-S)', false)
	win.add_checkbox('chk_slurp', 'Slurp Inputs (-s)', false)
	win.add_button('btn_load_sample', 'Load Sample JSON')
	win.add_button('btn_open_file', 'Open JSON File...')
	win.end_row()

	win.end_group_box()

	// Action Execution Controls
	win.begin_row('row_exec_bar_1')
	win.add_button('btn_run_jq', 'Execute JQ Query')
	win.add_button('btn_format_json', 'Format / Prettify')
	win.add_button('btn_minify_json', 'Minify')
	win.add_button('btn_copy_output', 'Copy Result')
	win.end_row()

	win.begin_row('row_exec_bar_2')
	win.add_button('btn_save_output', 'Save Output As...')
	win.add_button('btn_clear_all', 'Clear')
	win.end_row()

	// Dual Pane: Input JSON & Output JSON
	win.begin_grid('grid_dual_pane', 2, 8)
	win.add_form_textarea('Input JSON Data:', 'txt_input_json', sample_json)
	win.set_control_height('txt_input_json', 300)
	win.add_form_textarea('JQ Filtered Result:', 'txt_output_json', '')
	win.set_control_height('txt_output_json', 300)
	win.end_grid()

	// Telemetry & Console Log
	win.begin_group_box('grp_console', 'JQ Engine Activity & Telemetry')
	win.add_console('jq_console', 110)
	win.end_group_box()

	// Status & Metrics Row
	win.begin_row('row_stats')
	win.add_label('lbl_stats', 'Stats: Ready  |  Input Length: ${sample_json.len} bytes  |  Duration: 0 ms')
	win.end_row()

	win.append_console('jq_console', ' JQ Studio Pro initialized.\n', 1)
	win.append_console('jq_console', ' Ready to process high-speed JSON stream transformations.\n', 4)

	// -------------------------------------------------------------
	// Event Handlers
	// -------------------------------------------------------------

	// Preset Selection Handler
	win.on_change('dd_presets', fn (mut w simplegui.SimpleWindow, selected string) {
		mut filter := '.'
		if selected.starts_with('1.') { filter = '.' }
		else if selected.starts_with('2.') { filter = 'keys' }
		else if selected.starts_with('3.') { filter = '.modules | map(.name)' }
		else if selected.starts_with('4.') { filter = '.modules[] | select(.status == "stable")' }
		else if selected.starts_with('5.') { filter = '{app: .project, total_lines: ([.modules[].lines] | add)}' }
		else if selected.starts_with('6.') { filter = '.modules | sort_by(.lines) | reverse' }
		else if selected.starts_with('7.') { filter = 'to_entries[]' }
		else if selected.starts_with('8.') { filter = '.tags | join(", ")' }
		else if selected.starts_with('9.') { filter = '.modules[] | select(.lines > 2000)' }
		else if selected.starts_with('10.') { filter = '[.modules[].lines] | add' }
		else if selected.starts_with('11.') { filter = '.. | strings' }
		else if selected.starts_with('12.') { filter = '.modules | group_by(.status)' }
		w.set('txt_filter', filter)
		w.toast('Applied preset filter: ${filter}')
	})

	// Load Sample JSON
	win.on_click('btn_load_sample', fn (mut w simplegui.SimpleWindow) {
		w.set('txt_input_json', sample_json)
		w.set('txt_filter', '.')
		w.toast('Sample JSON loaded.')
		w.append_console('jq_console', ' Loaded standard demonstration JSON schema.\n', 1)
	})

	// Open File
	win.on_click('btn_open_file', fn (mut w simplegui.SimpleWindow) {
		path := w.select_file()
		if path != '' && os.exists(path) {
			content := os.read_file(path) or { '' }
			w.set('txt_input_json', content)
			w.toast('Loaded ${os.file_name(path)} (${content.len} bytes)')
			w.append_console('jq_console', ' Loaded file: ${path} (${content.len} bytes)\n', 1)
		}
	})

	// Execute JQ Query Logic
	exec_jq_fn := fn (mut w simplegui.SimpleWindow) {
		input_data := w.get('txt_input_json')
		if input_data.trim_space() == '' {
			w.alert('Input Required', 'Please enter or load JSON input data first.')
			return
		}

		filter_expr := w.get('txt_filter').trim_space()
		filter := if filter_expr == '' { '.' } else { filter_expr }
		jq_bin := get_jq_bin()

		is_compact := w.get('chk_compact') == 'true'
		is_raw := w.get('chk_raw') == 'true'
		is_sort := w.get('chk_sort_keys') == 'true'
		is_slurp := w.get('chk_slurp') == 'true'

		mut args := []string{}
		if is_compact { args << '-c' }
		if is_raw { args << '-r' }
		if is_sort { args << '-S' }
		if is_slurp { args << '-s' }
		args << filter

		w.append_console('jq_console', ' Executing: jq ${args.join(" ")}\n', 1)
		w.set_status('Running JQ query...')

		go fn [mut w, jq_bin, args, input_data] () {
			t0 := time.ticks()
			
			// Use temp file for safe stdin streaming
			tmp_path := os.join_path(os.temp_dir(), 'simplegui_jq_${time.ticks()}.json')
			os.write_file(tmp_path, input_data) or {
				w.run_on_main_thread(fn (mut win_main simplegui.SimpleWindow) {
					win_main.append_console('jq_console', ' Error writing temp file for JQ.\n', 3)
				})
				return
			}
			defer { os.rm(tmp_path) or {} }

			mut full_args := args.clone()
			full_args << tmp_path

			res := simplegui.exec_safe(jq_bin, full_args)
			elapsed_ms := time.ticks() - t0

			w.run_on_main_thread(fn [res, elapsed_ms, input_data] (mut win_main simplegui.SimpleWindow) {
				if res.exit_code == 0 {
					win_main.set('txt_output_json', res.output)
					lines_cnt := res.output.split_into_lines().len
					win_main.append_console('jq_console', ' Success: processed in ${elapsed_ms} ms (${res.output.len} bytes, ${lines_cnt} lines)\n', 4)
					win_main.set('lbl_stats', ' Stats: SUCCESS  |  Input: ${input_data.len}B  |  Output: ${res.output.len}B (${lines_cnt} lines)  |  Duration: ${elapsed_ms} ms')
					win_main.set_status('Query finished in ${elapsed_ms} ms.')
					win_main.toast('JQ query evaluated successfully!')
				} else {
					win_main.append_console('jq_console', ' JQ Error:\n' + res.output + '\n', 3)
					win_main.set('lbl_stats', ' Stats: ERROR (Exit ${res.exit_code})  |  Duration: ${elapsed_ms} ms')
					win_main.set_status('JQ evaluation error.')
					win_main.toast('JQ error encountered.')
				}
			})
		}()
	}

	win.on_click('btn_run_jq', fn [exec_jq_fn] (mut w simplegui.SimpleWindow) {
		exec_jq_fn(mut w)
	})

	// Prettify Quick Action
	win.on_click('btn_format_json', fn [exec_jq_fn] (mut w simplegui.SimpleWindow) {
		w.set('txt_filter', '.')
		w.set('chk_compact', 'false')
		exec_jq_fn(mut w)
	})

	// Minify Quick Action
	win.on_click('btn_minify_json', fn [exec_jq_fn] (mut w simplegui.SimpleWindow) {
		w.set('txt_filter', '.')
		w.set('chk_compact', 'true')
		exec_jq_fn(mut w)
	})

	// Copy Output
	win.on_click('btn_copy_output', fn (mut w simplegui.SimpleWindow) {
		out := w.get('txt_output_json')
		if out != '' {
			w.copy_to_clipboard(out)
			w.toast('Result copied to clipboard!')
		} else {
			w.toast('Output is empty.')
		}
	})

	// Save Output As
	win.on_click('btn_save_output', fn (mut w simplegui.SimpleWindow) {
		out := w.get('txt_output_json')
		if out.trim_space() == '' {
			w.toast('No output to save.')
			return
		}
		path := w.save_file_picker()
		if path != '' {
			mut save_file := path
			if !save_file.ends_with('.json') {
				save_file += '.json'
			}
			os.write_file(save_file, out) or {
				w.toast('Failed to save file.')
				return
			}
			w.toast('Saved to ${os.file_name(save_file)}')
			w.append_console('jq_console', ' Saved output to: ${save_file}\n', 1)
		}
	})

	// Clear All
	win.on_click('btn_clear_all', fn (mut w simplegui.SimpleWindow) {
		w.set('txt_input_json', '')
		w.set('txt_output_json', '')
		w.set('txt_filter', '.')
		w.clear_console('jq_console')
		w.toast('Cleared workspace.')
	})

	win.start()
}

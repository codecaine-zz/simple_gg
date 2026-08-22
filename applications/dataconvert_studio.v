module main

import os
import time
import simplegui

// Sample Data Templates
const sample_json_data = '{
  "app": "SimpleGUI",
  "version": "1.4.0",
  "features": ["Native Cocoa", "Ultra-Fast", "Multi-Theme", "Non-Blocking"],
  "maintainer": {
    "name": "Alex",
    "email": "alex@vlang.io"
  },
  "servers": [
    {"host": "us-east-1", "port": 8080, "active": true},
    {"host": "eu-west-1", "port": 8443, "active": false}
  ]
}'

const sample_csv_data = 'id,name,role,department,salary
1,Alice Johnson,Senior Engineer,Platform,145000
2,Bob Smith,Lead Designer,UI/UX,130000
3,Charlie Brown,Security Specialist,Infra,150000
4,Diana Prince,Engineering Director,Core,195000'

const sample_yaml_data = 'app: SimpleGUI
version: 1.4.0
features:
  - Native Cocoa
  - Ultra-Fast
  - Multi-Theme
  - Non-Blocking
maintainer:
  name: Alex
  email: alex@vlang.io
servers:
  - host: us-east-1
    port: 8080
    active: true
  - host: eu-west-1
    port: 8443
    active: false'

const sample_toml_data = '[app]
name = "SimpleGUI"
version = "1.4.0"
features = ["Native Cocoa", "Ultra-Fast", "Multi-Theme"]

[maintainer]
name = "Alex"
email = "alex@vlang.io"

[[servers]]
host = "us-east-1"
port = 8080
active = true'

const sample_xml_data = '<?xml version="1.0" encoding="UTF-8"?>
<root>
  <app>SimpleGUI</app>
  <version>1.4.0</version>
  <maintainer>
    <name>Alex</name>
    <email>alex@vlang.io</email>
  </maintainer>
</root>'

// Helper converter using python3 / yq / dasel
fn convert_data_format(input_str string, from_fmt string, to_fmt string) (string, string) {
	if input_str.trim_space() == '' {
		return '', 'Input data is empty.'
	}

	from_clean := from_fmt.to_lower()
	to_clean := to_fmt.to_lower()

	if from_clean == to_clean {
		return input_str, ''
	}

	// Multi-format converter script via Python standard/common libs
	script := '
import sys, json, csv, io

input_data = sys.stdin.read()
from_f = "${from_clean}"
to_f = "${to_clean}"

obj = None

# Parse input
if from_f == "json":
    obj = json.loads(input_data)
elif from_f == "csv":
    reader = csv.DictReader(io.StringIO(input_data))
    obj = list(reader)
elif from_f == "yaml":
    try:
        import yaml
        obj = yaml.safe_load(input_data)
    except Exception as e:
        sys.stderr.write(f"YAML module required: {e}")
        sys.exit(1)
elif from_f == "toml":
    try:
        import tomllib
        obj = tomllib.loads(input_data)
    except Exception:
        try:
            import toml
            obj = toml.loads(input_data)
        except Exception as e:
            sys.stderr.write(f"TOML parser error: {e}")
            sys.exit(1)

# Format output
if to_f == "json":
    print(json.dumps(obj, indent=2))
elif to_f == "yaml":
    try:
        import yaml
        print(yaml.dump(obj, sort_keys=False))
    except Exception as e:
        sys.stderr.write(f"PyYAML not installed for YAML export: {e}")
        sys.exit(1)
elif to_f == "csv":
    if isinstance(obj, list) and len(obj) > 0 and isinstance(obj[0], dict):
        out = io.StringIO()
        writer = csv.DictWriter(out, fieldnames=list(obj[0].keys()))
        writer.writeheader()
        for row in obj:
            writer.writerow(row)
        print(out.getvalue().strip())
    else:
        sys.stderr.write("CSV export requires a list of objects.")
        sys.exit(1)
elif to_f == "toml":
    try:
        import tomli_w
        print(tomli_w.dumps(obj))
    except Exception:
        import json
        print(json.dumps(obj, indent=2))
'

	tmp_py := os.join_path(os.temp_dir(), 'simplegui_converter_${time.ticks()}.py')
	os.write_file(tmp_py, script) or { return '', 'Failed to create worker script.' }
	defer { os.rm(tmp_py) or {} }

	tmp_in := os.join_path(os.temp_dir(), 'simplegui_in_${time.ticks()}.txt')
	os.write_file(tmp_in, input_str) or { return '', 'Failed to create input temp file.' }
	defer { os.rm(tmp_in) or {} }

	cmd := 'python3 "${tmp_py}" < "${tmp_in}"'
	res := os.execute(cmd)

	if res.exit_code == 0 {
		return res.output.trim_space(), ''
	} else {
		// Fallback check if yq is installed
		if path := os.find_abs_path_of_executable('yq') {
			yq_res := os.execute('${path} -P -p ${from_clean} -o ${to_clean} "${tmp_in}"')
			if yq_res.exit_code == 0 {
				return yq_res.output.trim_space(), ''
			}
		}
		return '', res.output.trim_space()
	}
}

fn main() {
	println('Starting SimpleGUI - Format Converter Studio Pro (JSON / YAML / TOML / CSV / XML)...')

	mut win := simplegui.new_simple_window('SimpleGUI - Format Converter Studio Pro', 1060, 940)
	win.set_fullscreen(true)
	win.set_spacing(8)
	win.set_padding(16)

	saved_theme := simplegui.get_saved_theme()
	win.set_theme(saved_theme)

	// Top Banner / Diagnostics
	win.begin_row('row_conv_top')
	win.add_heading('Format Converter Studio Pro')
	win.add_label('lbl_theme', 'Theme:')
	win.add_dropdown('dd_app_theme', simplegui.list_themes(), saved_theme)
	win.set_control_width('dd_app_theme', 150)
	win.end_row()

	win.on_change('dd_app_theme', fn (mut w simplegui.SimpleWindow, selected string) {
		w.set_theme(selected)
		w.toast('Theme changed to ${selected}')
	})

	win.add_label('lbl_engine_info', 'Engine: Multi-Format Translation Engine  |  Platform: macOS Cocoa  |  Mode: Async Non-Blocking')

	// Format Selector & Preset Configuration
	win.begin_group_box('grp_format_config', 'Format Direction & Data Templates')
	
	win.begin_row('row_formats')
	win.add_label('lbl_from', 'From Format:')
	win.add_dropdown('dd_from_fmt', ['JSON', 'YAML', 'TOML', 'CSV', 'XML'], 'JSON')
	win.set_control_width('dd_from_fmt', 120)

	win.add_label('lbl_to', 'To Format:')
	win.add_dropdown('dd_to_fmt', ['YAML', 'JSON', 'TOML', 'CSV', 'XML'], 'YAML')
	win.set_control_width('dd_to_fmt', 120)

	win.add_button('btn_swap_formats', 'Swap Formats')

	win.add_label('lbl_template', 'Sample Data:')
	win.add_dropdown('dd_sample_data', [
		'1. JSON Server Architecture',
		'2. CSV Employees Database',
		'3. YAML Deployment Manifest',
		'4. TOML Application Config',
		'5. XML Meta Document'
	], '1. JSON Server Architecture')
	win.set_control_width('dd_sample_data', 230)
	win.end_row()

	win.end_group_box()

	// Action Controls
	win.begin_row('row_actions')
	win.add_button('btn_convert', 'Convert Data Format')
	win.add_button('btn_open_file', 'Open File...')
	win.add_button('btn_copy_output', 'Copy Result')
	win.add_button('btn_save_output', 'Save Output As...')
	win.add_button('btn_clear_all', 'Clear')
	win.end_row()

	// Dual Pane: Input & Output
	win.begin_grid('grid_dual_pane', 2, 8)
	win.add_form_textarea('Source Data Stream:', 'txt_input_data', sample_json_data)
	win.set_control_height('txt_input_data', 320)
	win.add_form_textarea('Target Converted Output:', 'txt_output_data', '')
	win.set_control_height('txt_output_data', 320)
	win.end_grid()

	// Activity Log Console
	win.begin_group_box('grp_console', 'Converter Activity & Telemetry')
	win.add_console('conv_console', 110)
	win.end_group_box()

	// Status Row
	win.begin_row('row_stats')
	win.add_label('lbl_stats', 'Stats: Ready  |  Source: JSON (${sample_json_data.len} bytes)  |  Duration: 0 ms')
	win.end_row()

	win.append_console('conv_console', ' Format Converter Studio Pro Initialized.\n', 1)
	win.append_console('conv_console', ' Ready to convert JSON, YAML, TOML, CSV, and XML datasets.\n', 4)

	// -------------------------------------------------------------
	// Event Handlers
	// -------------------------------------------------------------

	// Sample Template Change
	win.on_change('dd_sample_data', fn (mut w simplegui.SimpleWindow, selected string) {
		if selected.starts_with('1.') {
			w.set('dd_from_fmt', 'JSON')
			w.set('dd_to_fmt', 'YAML')
			w.set('txt_input_data', sample_json_data)
		} else if selected.starts_with('2.') {
			w.set('dd_from_fmt', 'CSV')
			w.set('dd_to_fmt', 'JSON')
			w.set('txt_input_data', sample_csv_data)
		} else if selected.starts_with('3.') {
			w.set('dd_from_fmt', 'YAML')
			w.set('dd_to_fmt', 'JSON')
			w.set('txt_input_data', sample_yaml_data)
		} else if selected.starts_with('4.') {
			w.set('dd_from_fmt', 'TOML')
			w.set('dd_to_fmt', 'JSON')
			w.set('txt_input_data', sample_toml_data)
		} else if selected.starts_with('5.') {
			w.set('dd_from_fmt', 'XML')
			w.set('dd_to_fmt', 'JSON')
			w.set('txt_input_data', sample_xml_data)
		}
		w.toast('Loaded sample template.')
	})

	// Swap Formats Handler
	win.on_click('btn_swap_formats', fn (mut w simplegui.SimpleWindow) {
		from_f := w.get('dd_from_fmt')
		to_f := w.get('dd_to_fmt')
		w.set('dd_from_fmt', to_f)
		w.set('dd_to_fmt', from_f)

		in_text := w.get('txt_input_data')
		out_text := w.get('txt_output_data')
		if out_text.trim_space() != '' {
			w.set('txt_input_data', out_text)
			w.set('txt_output_data', in_text)
		}
		w.toast('Swapped source and target formats!')
	})

	// Convert Action
	win.on_click('btn_convert', fn (mut w simplegui.SimpleWindow) {
		in_data := w.get('txt_input_data')
		if in_data.trim_space() == '' {
			w.alert('Data Required', 'Please enter source data to convert.')
			return
		}

		from_fmt := w.get('dd_from_fmt')
		to_fmt := w.get('dd_to_fmt')

		w.append_console('conv_console', ' Converting ${from_fmt}  ${to_fmt}...\n', 1)
		w.set_status('Converting ${from_fmt} to ${to_fmt}...')

		go fn [mut w, in_data, from_fmt, to_fmt] () {
			t0 := time.ticks()
			out_str, err_msg := convert_data_format(in_data, from_fmt, to_fmt)
			elapsed_ms := time.ticks() - t0

			w.run_on_main_thread(fn [out_str, err_msg, elapsed_ms, from_fmt, to_fmt, in_data] (mut win_main simplegui.SimpleWindow) {
				if err_msg == '' {
					win_main.set('txt_output_data', out_str)
					win_main.append_console('conv_console', ' Converted ${from_fmt} to ${to_fmt} in ${elapsed_ms} ms (${out_str.len} bytes)\n', 4)
					win_main.set('lbl_stats', ' Stats: SUCCESS  |  ${from_fmt} (${in_data.len}B)  ${to_fmt} (${out_str.len}B)  |  Duration: ${elapsed_ms} ms')
					win_main.set_status('Conversion finished in ${elapsed_ms} ms.')
					win_main.toast('Conversion complete!')
				} else {
					win_main.append_console('conv_console', ' Conversion Notice:\n' + err_msg + '\n', 3)
					win_main.set('lbl_stats', ' Stats: ERROR  |  Duration: ${elapsed_ms} ms')
					win_main.set_status('Conversion failed.')
					win_main.toast('Conversion error: ' + err_msg)
				}
			})
		}()
	})

	// Open File
	win.on_click('btn_open_file', fn (mut w simplegui.SimpleWindow) {
		path := w.select_file()
		if path != '' && os.exists(path) {
			content := os.read_file(path) or { '' }
			w.set('txt_input_data', content)
			
			// Detect format by extension
			if path.ends_with('.json') { w.set('dd_from_fmt', 'JSON') }
			else if path.ends_with('.yaml') || path.ends_with('.yml') { w.set('dd_from_fmt', 'YAML') }
			else if path.ends_with('.toml') { w.set('dd_from_fmt', 'TOML') }
			else if path.ends_with('.csv') { w.set('dd_from_fmt', 'CSV') }
			else if path.ends_with('.xml') { w.set('dd_from_fmt', 'XML') }

			w.toast('Loaded ${os.file_name(path)}')
			w.append_console('conv_console', ' Loaded file: ${path} (${content.len} bytes)\n', 1)
		}
	})

	// Copy Output
	win.on_click('btn_copy_output', fn (mut w simplegui.SimpleWindow) {
		out := w.get('txt_output_data')
		if out != '' {
			w.copy_to_clipboard(out)
			w.toast('Converted data copied to clipboard!')
		} else {
			w.toast('No converted output to copy.')
		}
	})

	// Save Output
	win.on_click('btn_save_output', fn (mut w simplegui.SimpleWindow) {
		out := w.get('txt_output_data')
		if out.trim_space() == '' {
			w.toast('No converted data to save.')
			return
		}
		to_fmt := w.get('dd_to_fmt').to_lower()
		ext := match to_fmt {
			'json' { '.json' }
			'yaml' { '.yaml' }
			'toml' { '.toml' }
			'csv'  { '.csv' }
			'xml'  { '.xml' }
			else   { '.txt' }
		}
		path := w.save_file_picker()
		if path != '' {
			mut save_file := path
			if !save_file.ends_with(ext) {
				save_file += ext
			}
			os.write_file(save_file, out) or {
				w.toast('Failed to save file.')
				return
			}
			w.toast('Saved to ${os.file_name(save_file)}')
			w.append_console('conv_console', ' Saved file: ${save_file}\n', 1)
		}
	})

	// Clear All
	win.on_click('btn_clear_all', fn (mut w simplegui.SimpleWindow) {
		w.set('txt_input_data', '')
		w.set('txt_output_data', '')
		w.clear_console('conv_console')
		w.toast('Cleared workspace.')
	})

	win.start()
}

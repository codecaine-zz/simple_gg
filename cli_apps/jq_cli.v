module main

import os
import simplecli

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
  "project": "SimpleCLI",
  "version": "2.0.0",
  "author": {"name": "Alex", "github": "https://github.com/vlang", "active": true},
  "metrics": {"stars": 4200, "forks": 380, "issues_open": 12},
  "modules": [
    {"name": "cli", "status": "stable", "priority": 1},
    {"name": "sys", "status": "stable", "priority": 2},
    {"name": "stdlib", "status": "stable", "priority": 3}
  ],
  "tags": ["vlang", "cli", "json", "tooling"]
}'

fn main() {
	mut app := simplecli.new_app('jq-cli', '1.0.0')
	app.set_description('JQ JSON Query & Transformation CLI Utility')

	app.add_flag_string('filter', 'f', '.', 'JQ filter query expression')
	app.add_flag_string('file', 'i', '', 'Input JSON file path')
	app.add_flag_string('raw', 'r', '', 'Raw JSON string input')
	app.add_flag_bool('compact', 'c', false, 'Output compact instead of pretty-printed JSON')
	app.add_flag_bool('interactive', 'x', false, 'Launch interactive filter REPL')

	app.parse_cli() or { return }

	app.banner('JQ JSON Query & Transform CLI', 'v1.0.0')

	jq_bin := get_jq_bin()
	has_jq := app.command_exists(jq_bin)
	if !has_jq {
		app.warn('jq binary not found in PATH or standard Homebrew paths. Using built-in JSON fallback engine.')
	}

	is_interactive := app.get_flag_bool('interactive')
	mut filter_expr := app.get_flag_string('filter')
	file_path := app.get_flag_string('file')
	raw_input := app.get_flag_string('raw')
	compact := app.get_flag_bool('compact')

	mut json_data := sample_json
	if file_path.len > 0 {
		if !app.file_exists(file_path) {
			app.error('File not found: ${file_path}')
			return
		}
		json_data = app.read_file(file_path)
		app.info('Loaded JSON from file: ${file_path} (${json_data.len} bytes)')
	} else if raw_input.len > 0 {
		json_data = raw_input
	} else if is_interactive {
		app.info('No input specified, using built-in sample JSON dataset.')
	}

	if is_interactive {
		app.panel('Interactive JQ Query Workbench', 'Input JSON size: ${json_data.len} bytes\nType your JQ filter expressions below (e.g. .status, .metrics, .modules[].name, keys). Type "exit" or "q" to quit.')
		for {
			filter_expr = app.prompt('Enter JQ filter', '.')
			if filter_expr == 'exit' || filter_expr == 'q' {
				app.success('Exiting JQ Workbench.')
				break
			}
			run_jq_query(mut app, jq_bin, has_jq, json_data, filter_expr, compact)
		}
	} else {
		run_jq_query(mut app, jq_bin, has_jq, json_data, filter_expr, compact)
	}
}

fn run_jq_query(mut app simplecli.SimpleCli, jq_bin string, has_jq bool, json_data string, filter string, compact bool) {
	app.reset_timer()
	if has_jq {
		temp_file := os.temp_dir() + '/jq_input_${os.getpid()}.json'
		os.write_file(temp_file, json_data) or {
			app.error('Failed to write temp file: ${err}')
			return
		}
		defer { os.rm(temp_file) or {} }

		mut args := [filter, temp_file]
		if compact {
			args.prepend('-c')
		}
		out, code := app.exec_safe(jq_bin, args)
		elapsed := app.elapsed_ms()
		if code == 0 {
			app.success('Query "${filter}" executed in ${elapsed} ms:')
			println(out)
		} else {
			app.error('JQ query failed (code ${code}):\n${out}')
		}
	} else {
		app.info('Built-in fallback: pretty-printing JSON')
		formatted := app.json_pretty(json_data)
		println(formatted)
	}
}

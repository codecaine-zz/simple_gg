module main

import simplecli

fn main() {
	mut app := simplecli.new_app('fd-cli', '1.0.0')
	app.set_description('Fast Directory Traversal & File Search CLI')

	app.add_flag_string('pattern', 'p', '', 'Filename pattern / regex to find')
	app.add_flag_string('extension', 'e', '', 'Filter by extension (e.g. v, json, png)')
	app.add_flag_string('path', 'd', '.', 'Root search directory')
	app.add_flag_bool('interactive', 'x', false, 'Launch interactive file finder')

	app.parse_cli() or { return }

	app.banner('FD Studio CLI', 'v1.0.0 - Fast File Discovery Engine')

	if app.get_flag_bool('interactive') {
		run_interactive(mut app)
		return
	}

	pat := app.get_flag_string('pattern')
	ext := app.get_flag_string('extension')
	search_dir := app.get_flag_string('path')

	if app.command_exists('fd') {
		mut args := []string{}
		if ext.len > 0 {
			args << ['-e', ext]
		}
		if pat.len > 0 {
			args << pat
		}
		args << search_dir
		out, _ := app.exec_safe('fd', args)
		println(out)
	} else {
		// Built-in recursive scanner
		app.info('Using SimpleCLI built-in recursive file scanner...')
		ext_filter := if ext.len > 0 { '.' + ext.trim_left('.') } else { '' }
		files := app.list_files_recursive(search_dir, ext_filter)
		for f in files {
			if pat.len == 0 || f.contains(pat) {
				println(f)
			}
		}
		app.success('Found ${files.len} item(s).')
	}
}

fn run_interactive(mut app simplecli.SimpleCli) {
	app.panel('File Finder Wizard', 'Quickly discover files in workspace.')
	ext := app.prompt('Filter by extension (or blank)', 'v')
	path := app.prompt('Search root directory', '.')
	ext_filter := if ext.len > 0 { '.' + ext.trim_left('.') } else { '' }
	files := app.list_files_recursive(path, ext_filter)
	for f in files {
		println(f)
	}
	app.success('Discovered ${files.len} matching files.')
}

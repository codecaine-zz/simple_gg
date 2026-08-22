module main

import simplecli

fn main() {
	mut app := simplecli.new_app('find-cli', '1.0.0')
	app.set_description('POSIX Find File Hierarchy Traversal CLI')

	app.add_flag_string('path', 'd', '.', 'Root directory to search')
	app.add_flag_string('name', 'n', '', 'Filename wildcard pattern (e.g. *.v or *config*)')
	app.add_flag_string('type', 't', '', 'Filter by type: f (file), d (directory)')
	app.add_flag_bool('interactive', 'x', false, 'Launch interactive search')

	app.parse_cli() or { return }

	app.banner('Find Studio CLI', 'v1.0.0 - Hierarchy Search Engine')

	if app.get_flag_bool('interactive') {
		run_interactive(mut app)
		return
	}

	search_path := app.get_flag_string('path')
	name_pat := app.get_flag_string('name')
	type_flag := app.get_flag_string('type')

	mut args := [search_path]
	if type_flag.len > 0 {
		args << ['-type', type_flag]
	}
	if name_pat.len > 0 {
		args << ['-name', name_pat]
	}

	out, code := app.exec_safe('find', args)
	if code == 0 {
		println(out)
	} else {
		app.error('Find execution failed (code ${code}):\n${out}')
	}
}

fn run_interactive(mut app simplecli.SimpleCli) {
	app.panel('POSIX Find Wizard', 'Traverse directory hierarchies.')
	pat := app.prompt('Search pattern (e.g. *.png, *.json)', '*.v')
	path := app.prompt('Starting directory', '.')
	out, _ := app.exec_safe('find', [path, '-name', pat])
	println(out)
}

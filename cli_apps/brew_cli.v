module main

import os
import simplecli

fn get_brew_bin() string {
	if path := os.find_abs_path_of_executable('brew') {
		return path
	}
	common_paths := [
		'/opt/homebrew/bin/brew',
		'/usr/local/bin/brew',
	]
	for p in common_paths {
		if os.exists(p) {
			return p
		}
	}
	return 'brew'
}

fn main() {
	mut app := simplecli.new_app('brew-cli', '1.0.0')
	app.set_description('Homebrew Package & Service Inspector CLI')

	app.add_flag_string('search', 's', '', 'Search for formulae or casks')
	app.add_flag_string('info', 'i', '', 'Get detailed package information')
	app.add_flag_bool('outdated', 'o', false, 'Check for outdated packages')
	app.add_flag_bool('services', 'v', false, 'List running Homebrew background services')
	app.add_flag_bool('doctor', 'd', false, 'Run brew doctor diagnostic check')
	app.add_flag_bool('interactive', 'x', false, 'Launch interactive Homebrew wizard')

	app.parse_cli() or { return }

	app.banner('Homebrew Studio CLI', 'v1.0.0 - Package & Service Controller')

	brew_bin := get_brew_bin()
	if !app.command_exists(brew_bin) {
		app.error('Homebrew ("brew") is not installed or not found in PATH.')
		return
	}

	if app.get_flag_bool('interactive') {
		run_interactive(mut app, brew_bin)
		return
	}

	search_term := app.get_flag_string('search')
	if search_term.len > 0 {
		app.info('Searching Homebrew for "${search_term}"...')
		out, _ := app.exec_safe(brew_bin, ['search', search_term])
		println(out)
		return
	}

	info_pkg := app.get_flag_string('info')
	if info_pkg.len > 0 {
		app.info('Fetching info for package "${info_pkg}"...')
		out, _ := app.exec_safe(brew_bin, ['info', info_pkg])
		println(out)
		return
	}

	if app.get_flag_bool('outdated') {
		app.info('Checking for outdated formulae and casks...')
		out, _ := app.exec_safe(brew_bin, ['outdated'])
		if out.trim_space().len == 0 {
			app.success('All Homebrew packages are up to date!')
		} else {
			println(out)
		}
		return
	}

	if app.get_flag_bool('services') {
		app.info('Listing background services...')
		out, _ := app.exec_safe(brew_bin, ['services', 'list'])
		println(out)
		return
	}

	if app.get_flag_bool('doctor') {
		app.info('Running brew doctor...')
		out, _ := app.exec_safe(brew_bin, ['doctor'])
		println(out)
		return
	}

	// Default fallback: show summary
	app.info('Installed packages count:')
	out, _ := app.exec_safe(brew_bin, ['list', '--formula'])
	lines := out.split_into_lines().filter(it.len > 0)
	app.print_kv({
		'Homebrew Binary': brew_bin,
		'Installed Formulae': '${lines.len} packages',
	})
	app.println(app.dim('Tip: Use --search <name>, --info <pkg>, --outdated, or -x for interactive mode.'))
}

fn run_interactive(mut app simplecli.SimpleCli, brew_bin string) {
	app.panel('Homebrew Operations Wizard', 'Select an operation to perform:')
	choice := app.select('Action:', [
		'List Outdated Packages',
		'Search Formula / Cask',
		'List Background Services',
		'Run Doctor Diagnostics',
		'List All Installed Formulae',
	])

	match choice {
		'List Outdated Packages' {
			out, _ := app.exec_safe(brew_bin, ['outdated'])
			println(out)
		}
		'Search Formula / Cask' {
			query := app.prompt('Search query', 'ffmpeg')
			out, _ := app.exec_safe(brew_bin, ['search', query])
			println(out)
		}
		'List Background Services' {
			out, _ := app.exec_safe(brew_bin, ['services', 'list'])
			println(out)
		}
		'Run Doctor Diagnostics' {
			out, _ := app.exec_safe(brew_bin, ['doctor'])
			println(out)
		}
		else {
			out, _ := app.exec_safe(brew_bin, ['list', '--formula'])
			println(out)
		}
	}
}

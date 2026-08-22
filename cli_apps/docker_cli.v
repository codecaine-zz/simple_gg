module main

import simplecli

fn main() {
	mut app := simplecli.new_app('docker-cli', '1.0.0')
	app.set_description('Docker Container, Image & Service Controller CLI')

	app.add_flag_bool('ps', 'p', false, 'List running containers')
	app.add_flag_bool('all', 'a', false, 'List all containers (running & stopped)')
	app.add_flag_bool('images', 'i', false, 'List local docker images')
	app.add_flag_string('logs', 'l', '', 'View logs of container by name/ID')
	app.add_flag_string('stop', 's', '', 'Stop a running container by name/ID')
	app.add_flag_string('start', 'u', '', 'Start a stopped container by name/ID')
	app.add_flag_bool('interactive', 'x', false, 'Run interactive Docker manager')

	app.parse_cli() or { return }

	app.banner('Docker Studio CLI', 'v1.0.0 - Container & Image Controller')

	if !app.command_exists('docker') {
		app.error('Docker CLI ("docker") is not installed or not in PATH.')
		return
	}

	if app.get_flag_bool('interactive') {
		run_interactive(mut app)
		return
	}

	logs_target := app.get_flag_string('logs')
	if logs_target.len > 0 {
		app.info('Fetching last 50 log lines for container "${logs_target}"...')
		out, _ := app.exec_safe('docker', ['logs', '--tail', '50', logs_target])
		println(out)
		return
	}

	stop_target := app.get_flag_string('stop')
	if stop_target.len > 0 {
		app.info('Stopping container "${stop_target}"...')
		out, code := app.exec_safe('docker', ['stop', stop_target])
		if code == 0 {
			app.success('Container stopped: ${out.trim_space()}')
		} else {
			app.error('Failed to stop container: ${out}')
		}
		return
	}

	start_target := app.get_flag_string('start')
	if start_target.len > 0 {
		app.info('Starting container "${start_target}"...')
		out, code := app.exec_safe('docker', ['start', start_target])
		if code == 0 {
			app.success('Container started: ${out.trim_space()}')
		} else {
			app.error('Failed to start container: ${out}')
		}
		return
	}

	if app.get_flag_bool('images') {
		app.info('Docker Images:')
		out, _ := app.exec_safe('docker', ['images'])
		println(out)
		return
	}

	// Default or --ps / --all
	mut args := ['ps']
	if app.get_flag_bool('all') {
		args << '-a'
	}
	app.info('Docker Containers:')
	out, _ := app.exec_safe('docker', args)
	println(out)
}

fn run_interactive(mut app simplecli.SimpleCli) {
	app.panel('Docker Management REPL', 'Manage containers, view logs, and inspect local images.')
	choice := app.select('Select Docker Operation:', [
		'List Active Containers (docker ps)',
		'List All Containers (docker ps -a)',
		'List Local Images (docker images)',
		'Container System Disk Usage (docker system df)',
	])

	match choice {
		'List All Containers (docker ps -a)' {
			out, _ := app.exec_safe('docker', ['ps', '-a'])
			println(out)
		}
		'List Local Images (docker images)' {
			out, _ := app.exec_safe('docker', ['images'])
			println(out)
		}
		'Container System Disk Usage (docker system df)' {
			out, _ := app.exec_safe('docker', ['system', 'df'])
			println(out)
		}
		else {
			out, _ := app.exec_safe('docker', ['ps'])
			println(out)
		}
	}
}

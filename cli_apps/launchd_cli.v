module main

import simplecli

fn main() {
	mut app := simplecli.new_app('launchd-cli', '1.0.0')
	app.set_description('macOS Launchd Daemon & Cron Job Inspector CLI')

	app.add_flag_string('filter', 'f', '', 'Filter services by keyword/label')
	app.add_flag_bool('user', 'u', false, 'Show user LaunchAgents only')
	app.add_flag_bool('system', 's', false, 'Show system LaunchDaemons only')
	app.add_flag_bool('cron', 'c', false, 'Inspect user and system Crontab entries')
	app.add_flag_bool('interactive', 'x', false, 'Launch interactive launchd explorer')

	app.parse_cli() or { return }

	app.banner('Launchd & Cron Studio CLI', 'v1.0.0 - Service & Daemon Inspector')

	if app.get_flag_bool('interactive') {
		run_interactive(mut app)
		return
	}

	if app.get_flag_bool('cron') {
		app.info('Inspecting crontab entries...')
		out, code := app.exec('crontab -l 2>/dev/null')
		if code == 0 && out.trim_space().len > 0 {
			println(out)
		} else {
			app.warn('No active crontab entries found for user.')
		}
		return
	}

	filter_kw := app.get_flag_string('filter').to_lower()
	app.info('Querying launchctl services...')
	out, _ := app.exec('launchctl list')
	lines := out.split_into_lines().filter(it.len > 0)

	mut rows := [][]string{}
	for i in 1 .. lines.len {
		parts := lines[i].split('\t')
		if parts.len >= 3 {
			pid := parts[0].trim_space()
			status := parts[1].trim_space()
			label := parts[2].trim_space()

			if filter_kw.len == 0 || label.to_lower().contains(filter_kw) {
				rows << [pid, status, label]
			}
		}
	}

	app.table(['PID', 'Status Code', 'Service Label'], rows)
	app.info('Total matched services: ${rows.len}')
}

fn run_interactive(mut app simplecli.SimpleCli) {
	app.panel('Launchd & Cron Inspector', 'Explore background services, agent plists, and crontabs.')
	choice := app.select('Select Action:', [
		'List Active Apple LaunchDaemons',
		'List Active User LaunchAgents',
		'Inspect Crontab Schedules',
	])

	match choice {
		'Inspect Crontab Schedules' {
			out, code := app.exec('crontab -l 2>/dev/null')
			if code == 0 && out.len > 0 {
				println(out)
			} else {
				app.warn('No user crontab configured.')
			}
		}
		else {
			out, _ := app.exec('launchctl list | head -n 25')
			println(out)
		}
	}
}

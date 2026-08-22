module main

import simplecli

fn main() {
	mut app := simplecli.new_app('disk-cli', '1.0.0')
	app.set_description('Disk Space Analyzer & Filesystem Mount Explorer')

	app.add_flag_string('path', 'p', '/', 'Target directory/mount path to inspect')
	app.add_flag_bool('mounts', 'm', false, 'Show all mounted filesystems and partitions')
	app.add_flag_bool('large', 'l', false, 'Find largest items in target path')
	app.add_flag_bool('interactive', 'x', false, 'Launch interactive disk explorer')

	app.parse_cli() or { return }

	app.banner('Disk Space Studio CLI', 'v1.0.0 - Storage Prober & Telemetry')

	if app.get_flag_bool('interactive') {
		run_interactive(mut app)
		return
	}

	target_path := app.get_flag_string('path')

	if app.get_flag_bool('mounts') {
		app.info('Mounted filesystems:')
		out, _ := app.exec('df -h')
		println(out)
		return
	}

	if app.get_flag_bool('large') {
		app.info('Scanning top 10 largest entries in "${target_path}"...')
		out, _ := app.exec("du -sh ${target_path}/* 2>/dev/null | sort -hr | head -n 10")
		println(out)
		return
	}

	// Default disk telemetry
	stats := app.get_disk_usage(target_path) or {
		app.error('Failed to get disk stats for "${target_path}": ${err}')
		return
	}

	total_gb := f64(stats.total_bytes) / (1024.0 * 1024.0 * 1024.0)
	used_gb := f64(stats.used_bytes) / (1024.0 * 1024.0 * 1024.0)
	free_gb := f64(stats.free_bytes) / (1024.0 * 1024.0 * 1024.0)

	app.print_kv({
		'Target Path': target_path,
		'Total Capacity': '${total_gb:.2f} GB',
		'Used Space': '${used_gb:.2f} GB',
		'Free Space': '${free_gb:.2f} GB',
		'Utilization': '${stats.percent:.1f} %',
	})

	app.progress_bar(used_gb, total_gb, 'Disk Utilization (${target_path})')
}

fn run_interactive(mut app simplecli.SimpleCli) {
	app.panel('Disk Storage Wizard', 'Inspect partition sizes, mounts, and top disk consumers.')
	choice := app.select('Inspect Category:', [
		'Root Partition Utilization (/)',
		'User Home Directory Usage (~)',
		'Mounted Filesystems (df -h)',
		'Top 10 Largest Items in Home',
	])

	match choice {
		'User Home Directory Usage (~)' {
			stats := app.get_disk_usage(simplecli.get_user_home_dir()) or { return }
			total_gb := f64(stats.total_bytes) / (1024.0 * 1024.0 * 1024.0)
			free_gb := f64(stats.free_bytes) / (1024.0 * 1024.0 * 1024.0)
			app.print_kv({
				'Path': '~',
				'Total': '${total_gb:.2f} GB',
				'Free': '${free_gb:.2f} GB',
				'Used': '${stats.percent:.1f} %',
			})
		}
		'Mounted Filesystems (df -h)' {
			out, _ := app.exec('df -h')
			println(out)
		}
		'Top 10 Largest Items in Home' {
			out, _ := app.exec("du -sh ~/* 2>/dev/null | sort -hr | head -n 10")
			println(out)
		}
		else {
			stats := app.get_disk_usage('/') or { return }
			total_gb := f64(stats.total_bytes) / (1024.0 * 1024.0 * 1024.0)
			free_gb := f64(stats.free_bytes) / (1024.0 * 1024.0 * 1024.0)
			app.print_kv({
				'Path': '/',
				'Total': '${total_gb:.2f} GB',
				'Free': '${free_gb:.2f} GB',
				'Used': '${stats.percent:.1f} %',
			})
		}
	}
}

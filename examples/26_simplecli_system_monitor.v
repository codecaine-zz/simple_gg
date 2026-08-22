module main

import simplecli

fn main() {
	mut app := simplecli.new_app('System Monitor RAD Utility', '1.0.0')
	app.set_author('SimpleCLI')
	app.set_description('Headless OS hardware and resource monitoring console utility')

	// 1. Render ASCII banner header
	app.banner('SimpleCLI Hardware & System Monitor', 'v1.0.0 • Headless Console Suite')

	// 2. Inspect Hardware Specs
	app.step(1, 'Hardware & Architecture Information')
	cpu := app.get_cpu_info()
	cores := app.get_cpu_cores()
	arch := app.get_cpu_architecture()
	ram := app.get_memory_info()
	locale := app.get_system_locale()
	theme := app.get_system_theme()
	pid := app.get_pid()
	uptime_sec := app.get_uptime_seconds()

	app.print_kv({
		'CPU Model':       cpu
		'CPU Cores':       '${cores} logical cores'
		'Architecture':    arch
		'System RAM':      ram
		'OS Locale':       locale
		'System Theme':    theme
		'Process PID':     '${pid}'
		'System Uptime':   '${uptime_sec / 3600}h ${(uptime_sec % 3600) / 60}m ${uptime_sec % 60}s'
	})

	// 3. Live Resource Metrics
	app.step(2, 'Live Resource Metrics')
	cpu_pct := app.get_cpu_usage_percent()
	l1, l5, l15 := app.get_load_average()
	batt := app.get_battery_percent()
	is_ac := app.is_on_ac_power()
	procs := app.get_running_process_count()
	files := app.get_open_file_count()

	metric_headers := ['Resource Metric', 'Current Value', 'Status']
	metric_rows := [
		['CPU Load Usage', '${cpu_pct:.1f}%', if cpu_pct > 80.0 { 'HIGH' } else { 'NORMAL' }],
		['System Load (1m, 5m, 15m)', '${l1:.2f}, ${l5:.2f}, ${l15:.2f}', 'ACTIVE'],
		['Running Processes', '${procs}', 'NORMAL'],
		['Open File Descriptors', '${files}', 'HEALTHY'],
		['Battery Power', if batt >= 0 { '${batt}%' } else { 'Desktop / AC' }, if is_ac { 'Charging / Plugged In' } else { 'Discharging' }],
	]
	app.table(metric_headers, metric_rows)

	// 4. Storage & Standard User Paths
	app.step(3, 'Standard Directories & Disk Usage')
	disk := app.get_disk_usage('/') or { simplecli.DiskStats{} }
	
	app.panel('Root Filesystem Disk Usage', 
		'Total Disk Space: ${f64(disk.total_bytes) / 1073741824.0:.1f} GB\n' +
		'Used Disk Space:  ${f64(disk.used_bytes) / 1073741824.0:.1f} GB (${disk.percent:.1f}%)\n' +
		'Free Disk Space:  ${f64(disk.free_bytes) / 1073741824.0:.1f} GB'
	)

	app.print_kv({
		'Home Directory':      app.get_system_path('home')
		'Documents':           app.get_system_path('documents')
		'Desktop':             app.get_system_path('desktop')
		'Downloads':           app.get_system_path('downloads')
		'Application Config':  app.get_system_path('config')
		'Application State':   app.get_system_path('state')
	})

	app.divider('─', 70)
	app.success('System monitor diagnostics completed successfully.')
	app.print_elapsed()
}

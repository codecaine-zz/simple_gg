// DevOps Infrastructure Sentinel & System Health Guardian
// Production Console Application built with SimpleCLI
//
// Usage:
//   v run cli_apps/devops_sentinel.v
//   v run cli_apps/devops_sentinel.v --interval 5 --alert
//   v run cli_apps/devops_sentinel.v --export report.json

module main

import time
import simplecli

struct ServiceTarget {
	name string
	host string
	port int
}

fn main() {
	mut app := simplecli.new_app('DevOps-Sentinel', '1.0.0')
	app.set_description('Enterprise Infrastructure Sentinel & System Health Guardian')

	// CLI Flags
	app.add_flag_int('interval', 'i', 3, 'Health check interval in seconds')
	app.add_flag_bool('alert', 'a', false, 'Enable desktop audio and popup alerts on high load')
	app.add_flag_string('export', 'e', '', 'Export health snapshot to JSON file')
	app.add_flag_string('log', 'l', '', 'Save continuous structured log to file')
	app.add_flag_bool('interactive', 'x', false, 'Run in interactive diagnosis wizard mode')

	app.parse_cli() or { return }

	// Structured file logging if requested
	log_path := app.get_flag_string('log')
	if log_path.len > 0 {
		app.set_log_file(log_path)
		app.set_log_level(.debug)
	}

	app.banner('DevOps Infrastructure Sentinel', 'v1.0.0 - Production Health Guardian')

	if app.get_flag_bool('interactive') {
		run_interactive_wizard(mut app)
		return
	}

	run_sentinel_monitor(mut app)
}

fn run_sentinel_monitor(mut app simplecli.SimpleCli) {
	enable_alerts := app.get_flag_bool('alert')
	export_file := app.get_flag_string('export')

	// Defined critical services to probe
	services := [
		ServiceTarget{ name: 'DNS Gateway (Cloudflare)', host: '1.1.1.1', port: 53 },
		ServiceTarget{ name: 'DNS Gateway (Google)', host: '8.8.8.8', port: 53 },
		ServiceTarget{ name: 'Local PostgreSQL', host: '127.0.0.1', port: 5432 },
		ServiceTarget{ name: 'Local MySQL / MariaDB', host: '127.0.0.1', port: 3306 },
		ServiceTarget{ name: 'Local Redis Cache', host: '127.0.0.1', port: 6379 },
		ServiceTarget{ name: 'Local Web Server', host: '127.0.0.1', port: 8080 },
	]

	app.step(1, 'Inspecting Hardware Baseline & System Topology')
	cpu_info := app.get_cpu_info()
	cores := app.get_cpu_cores()
	arch := app.get_cpu_architecture()
	ram := app.get_memory_info()
	local_ip := app.get_local_ip()
	mac := app.get_mac_address()
	gateway := app.get_default_gateway()
	uptime := app.get_uptime_seconds()

	app.print_kv({
		'CPU Model':     cpu_info,
		'Cores / Arch':  '${cores} Cores (${arch})',
		'Total Memory':  ram,
		'Local IP / MAC': '${local_ip} (${mac})',
		'Default Gateway': gateway,
		'Uptime':        '${uptime / 3600}h ${(uptime % 3600) / 60}m ${uptime % 60}s',
	})

	app.step(2, 'Probing Critical Network & Backend Service Endpoints')
	mut svc_rows := [][]string{}
	mut healthy_services := 0

	for svc in services {
		is_up := app.ping_tcp_port(svc.host, svc.port, 500)
		status_text := if is_up {
			healthy_services++
			app.green('● ACTIVE / ONLINE')
		} else {
			app.dim('○ INACTIVE / CLOSED')
		}
		svc_rows << [svc.name, '${svc.host}:${svc.port}', status_text]
	}

	app.table(['Service Name', 'Target Address', 'Reachability Status'], svc_rows)

	app.step(3, 'Evaluating System Load Metrics & Disk Partitions')
	cpu_usage := app.get_cpu_usage_percent()
	l1, l5, l15 := app.get_load_average()
	disk_stats := app.get_disk_usage('/') or {
		simplecli.DiskStats{ total_bytes: 1, free_bytes: 1, used_bytes: 0, percent: 0.0 }
	}
	battery := app.get_battery_percent()
	batt_str := if battery >= 0 { '${battery}%' } else { 'Desktop / AC Power' }

	disk_gb_used := f64(disk_stats.used_bytes) / 1073741824.0
	disk_gb_total := f64(disk_stats.total_bytes) / 1073741824.0

	app.progress_bar(disk_stats.percent, 100.0, 'Root Partition (/) Storage: ${disk_gb_used:.1f} GB / ${disk_gb_total:.1f} GB')

	app.print_kv({
		'CPU Utilization': '${cpu_usage:.1f}%',
		'Load Averages':   '${l1:.2f} (1m), ${l5:.2f} (5m), ${l15:.2f} (15m)',
		'Disk Used %':     '${disk_stats.percent:.1f}% (${disk_gb_used:.1f} / ${disk_gb_total:.1f} GB)',
		'Power Status':    batt_str,
	})

	// Threshold Warnings
	if cpu_usage > 85.0 || disk_stats.percent > 90.0 {
		app.warn('High system utilization threshold breached!')
		if enable_alerts {
			app.play_system_sound('Hero')
			app.notify('Sentinel Alert', 'System load high: CPU ${cpu_usage:.1f}%, Disk ${disk_stats.percent:.1f}%')
		}
	} else {
		app.success('All system health parameters within standard tolerances.')
	}

	// Optional JSON Export
	if export_file.len > 0 {
		app.step(4, 'Exporting Health Report to JSON')
		report := '{\n  "timestamp": "${time.now().format_ss()}",\n  "cpu": "${cpu_info}",\n  "cores": ${cores},\n  "ram": "${ram}",\n  "cpu_usage_pct": ${cpu_usage},\n  "load_1m": ${l1},\n  "disk_usage_pct": ${disk_stats.percent},\n  "healthy_services": ${healthy_services}\n}\n'
		app.write_file(export_file, report)
		app.success('Exported report successfully to: ${export_file}')
	}

	app.divider('─', 64)
	app.info('Sentinel check completed in ${app.elapsed_ms()} ms.')
}

fn run_interactive_wizard(mut app simplecli.SimpleCli) {
	app.panel('Sentinel Interactive Configuration Wizard', 'Configure automated threshold triggers and monitoring rules.')

	target_host := app.prompt('Enter custom host or IP to monitor', '127.0.0.1')
	target_port := app.prompt_number('Enter port number', 8080, 1, 65535)
	alert_email := app.prompt_email('Enter alert notification recipient email', 'ops@company.com')

	app.info('Initiating live connectivity test against ${target_host}:${target_port}...')
	app.spinner('Testing socket reachability', 800)

	is_open := app.ping_tcp_port(target_host, target_port, 1000)
	if is_open {
		app.success('Successfully connected to ${target_host}:${target_port}!')
	} else {
		app.error('Port ${target_port} on ${target_host} is not currently responding.')
	}

	if app.confirm('Save this monitoring profile into state store?', true) {
		app.set_state('monitor_host', target_host)
		app.set_state('monitor_port', '${target_port}')
		app.set_state('alert_email', alert_email)
		save_path := app.get_system_path('config') + '/sentinel_state.json'
		app.save_state(save_path) or {}
		app.success('Profile saved to: ${save_path}')
	}
}

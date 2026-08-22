module main

import simplecli

fn main() {
	mut app := simplecli.new_app('nmap-cli', '1.0.0')
	app.set_description('Network Port Scanner & Service Prober CLI')

	app.add_flag_string('host', 'h', '127.0.0.1', 'Target hostname or IP address')
	app.add_flag_string('ports', 'p', '21,22,80,443,3306,5432,6379,8080', 'Comma-separated port list or range (e.g. 80,443 or 8000-8010)')
	app.add_flag_int('timeout', 't', 800, 'Connection timeout per port in milliseconds')
	app.add_flag_bool('interactive', 'x', false, 'Launch interactive network scanner')

	app.parse_cli() or { return }

	app.banner('Nmap Port Scanner CLI', 'v1.0.0 - Network Security Prober')

	if app.get_flag_bool('interactive') {
		run_interactive(mut app)
		return
	}

	host := app.get_flag_string('host')
	ports_str := app.get_flag_string('ports')
	timeout_ms := app.get_flag_int('timeout')

	scan_target(mut app, host, ports_str, timeout_ms)
}

fn scan_target(mut app simplecli.SimpleCli, host string, ports_str string, timeout_ms int) {
	app.info('Scanning target: ${host} (timeout: ${timeout_ms}ms)...')
	app.reset_timer()

	mut ports_to_scan := []int{}
	if ports_str.contains('-') {
		parts := ports_str.split('-')
		if parts.len == 2 {
			start_p := parts[0].int()
			end_p := parts[1].int()
			for p := start_p; p <= end_p; p++ {
				ports_to_scan << p
			}
		}
	} else {
		parts := ports_str.split(',')
		for p in parts {
			val := p.trim_space().int()
			if val > 0 {
				ports_to_scan << val
			}
		}
	}

	if ports_to_scan.len == 0 {
		ports_to_scan = [21, 22, 80, 443, 3306, 5432, 6379, 8080]
	}

	mut rows := [][]string{}
	mut open_count := 0

	for i, port in ports_to_scan {
		app.progress_bar(f64(i + 1), f64(ports_to_scan.len), 'Scanning port ${port} on ${host}')
		service_name := get_common_service_name(port)
		is_open := app.ping_tcp_port(host, port, timeout_ms)
		status := if is_open { app.green('OPEN') } else { app.dim('CLOSED') }
		if is_open {
			open_count++
		}
		rows << ['${port}', service_name, status]
	}

	println('')
	app.table(['Port', 'Service', 'Status'], rows)
	app.success('Scan complete in ${app.elapsed_ms()} ms. Found ${open_count} open port(s) on ${host}.')
}

fn get_common_service_name(port int) string {
	return match port {
		21 { 'FTP' }
		22 { 'SSH' }
		25 { 'SMTP' }
		53 { 'DNS' }
		80 { 'HTTP' }
		443 { 'HTTPS' }
		3000 { 'Dev Server' }
		3306 { 'MySQL' }
		5432 { 'PostgreSQL' }
		6379 { 'Redis' }
		8080 { 'HTTP Alt' }
		8443 { 'HTTPS Alt' }
		9000 { 'Sonar / PHP' }
		27017 { 'MongoDB' }
		else { 'Custom' }
	}
}

fn run_interactive(mut app simplecli.SimpleCli) {
	app.panel('Interactive Port Scanner', 'Scan localhost or remote servers for exposed TCP ports.')
	target := app.prompt('Enter target host/IP', '127.0.0.1')
	ports := app.prompt('Enter ports to probe', '22,80,443,3000,5432,6379,8080')
	scan_target(mut app, target, ports, 600)
}

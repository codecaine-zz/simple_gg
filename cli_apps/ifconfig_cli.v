module main

import simplecli

fn main() {
	mut app := simplecli.new_app('ifconfig-cli', '1.0.0')
	app.set_description('Network Interface, Routing & Adapter Diagnostics CLI')

	app.add_flag_bool('all', 'a', false, 'Show full hardware interface details')
	app.add_flag_bool('wifi', 'w', false, 'Inspect Wi-Fi connection and signal status')
	app.add_flag_bool('routes', 'r', false, 'Show IP routing table and gateway')
	app.add_flag_bool('interactive', 'x', false, 'Launch interactive network explorer')

	app.parse_cli() or { return }

	app.banner('IFConfig Studio CLI', 'v1.0.0 - Network Adapter Diagnostics')

	if app.get_flag_bool('interactive') {
		run_interactive(mut app)
		return
	}

	if app.get_flag_bool('wifi') {
		app.info('Wi-Fi Diagnostics:')
		app.print_kv({
			'Connected SSID': app.get_wifi_ssid(),
			'Local Adapter IP': app.get_local_ip(),
			'Public IP': app.get_public_ip(),
			'MAC Address': app.get_mac_address(),
		})
		return
	}

	if app.get_flag_bool('routes') {
		app.info('Routing & DNS Configuration:')
		app.print_kv({
			'Default Gateway': app.get_default_gateway(),
			'DNS Servers': app.get_dns_servers().join(', '),
			'Online Status': if app.is_online() { app.green('Connected') } else { app.red('Offline') },
		})
		return
	}

	// Default overview
	app.print_kv({
		'Local IPv4': app.get_local_ip(),
		'Public IP': app.get_public_ip(),
		'Default Gateway': app.get_default_gateway(),
		'DNS Nameservers': app.get_dns_servers().join(', '),
		'Wi-Fi SSID': app.get_wifi_ssid(),
		'MAC Address': app.get_mac_address(),
		'Active TCP Listeners': '${app.get_listening_ports().len} ports',
	})

	if app.get_flag_bool('all') {
		app.panel('Raw ifconfig adapter dump', app.exec_or('ifconfig', ''))
	}
}

fn run_interactive(mut app simplecli.SimpleCli) {
	app.panel('Network Diagnostics REPL', 'Inspect adapter interfaces, routes, and public IP.')
	choice := app.select('Diagnostics Category:', [
		'Network Overview & Telemetry',
		'Wi-Fi Connection Details',
		'Routing & DNS Resolvers',
		'Raw Adapter Details (ifconfig)',
	])

	match choice {
		'Wi-Fi Connection Details' {
			app.print_kv({
				'SSID': app.get_wifi_ssid(),
				'MAC': app.get_mac_address(),
			})
		}
		'Routing & DNS Resolvers' {
			app.print_kv({
				'Gateway': app.get_default_gateway(),
				'DNS': app.get_dns_servers().join(', '),
			})
		}
		'Raw Adapter Details (ifconfig)' {
			out, _ := app.exec('ifconfig | head -n 30')
			println(out)
		}
		else {
			app.print_kv({
				'Local IP': app.get_local_ip(),
				'Public IP': app.get_public_ip(),
				'Gateway': app.get_default_gateway(),
			})
		}
	}
}

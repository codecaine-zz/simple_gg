module main

import simplecli

fn main() {
	mut app := simplecli.new_app('recon-cli', '1.0.0')
	app.set_description('Target Intelligence & OSINT Reconnaissance CLI')

	app.add_flag_string('target', 't', 'google.com', 'Target domain or host to analyze')
	app.add_flag_bool('whois', 'w', false, 'Run WHOIS domain registration lookup')
	app.add_flag_bool('headers', 'H', false, 'Inspect HTTP security response headers')
	app.add_flag_bool('interactive', 'x', false, 'Launch interactive reconnaissance wizard')

	app.parse_cli() or { return }

	app.banner('Recon Studio CLI', 'v1.0.0 - Target Intelligence & OSINT')

	if app.get_flag_bool('interactive') {
		run_interactive(mut app)
		return
	}

	target := app.get_flag_string('target')

	if app.get_flag_bool('whois') {
		app.info('Performing WHOIS lookup for "${target}"...')
		out, _ := app.exec('whois ${target} | grep -E "Registrar:|Creation Date:|Registry Expiry Date:|Domain Name:" | head -n 10')
		println(out)
		return
	}

	if app.get_flag_bool('headers') {
		app.info('Probing HTTP security headers for https://${target}...')
		out, _ := app.exec('curl -s -I -L https://${target} | head -n 25')
		println(out)
		return
	}

	// Full comprehensive recon
	app.info('Running baseline intelligence audit on ${target}...')
	ip_out, _ := app.exec('dig +short ${target}')
	primary_ip := ip_out.split_into_lines().filter(it.len > 0)[0] or { 'Unknown' }

	headers_out, _ := app.exec('curl -s -I -L https://${target} | head -n 10')

	app.print_kv({
		'Target Host': target,
		'Primary Resolved IP': primary_ip,
		'HTTPS Available': '${app.ping_tcp_port(target, 443, 1000)}',
		'HTTP Available': '${app.ping_tcp_port(target, 80, 1000)}',
	})

	app.panel('HTTP Response Headers', headers_out)
}

fn run_interactive(mut app simplecli.SimpleCli) {
	app.panel('Recon Wizard', 'Discover host DNS, WHOIS registration, and security headers.')
	target := app.prompt('Enter target domain', 'vlang.io')
	choice := app.select('Recon Activity:', [
		'Comprehensive Audit',
		'WHOIS Registration Lookup',
		'HTTP Security Headers Check',
	])

	match choice {
		'WHOIS Registration Lookup' {
			out, _ := app.exec('whois ${target} | head -n 30')
			println(out)
		}
		'HTTP Security Headers Check' {
			out, _ := app.exec('curl -s -I -L https://${target}')
			println(out)
		}
		else {
			out, _ := app.exec('dig +short ${target}')
			app.success('Resolved IPs:\n${out}')
		}
	}
}

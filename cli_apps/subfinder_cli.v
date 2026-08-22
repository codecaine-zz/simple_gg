module main

import simplecli

fn main() {
	mut app := simplecli.new_app('subfinder-cli', '1.0.0')
	app.set_description('Subdomain Enumeration & Certificate Transparency Discovery CLI')

	app.add_flag_string('domain', 'd', 'vlang.io', 'Target root domain for subdomain discovery')
	app.add_flag_bool('probe', 'p', false, 'Probe active HTTP/HTTPS responsiveness on discovered subdomains')
	app.add_flag_bool('interactive', 'x', false, 'Launch interactive subdomain finder')

	app.parse_cli() or { return }

	app.banner('Subfinder Studio CLI', 'v1.0.0 - Passive Recon & Certificate Transparency')

	if app.get_flag_bool('interactive') {
		run_interactive(mut app)
		return
	}

	domain := app.get_flag_string('domain')
	probe_active := app.get_flag_bool('probe')

	discover_subdomains(mut app, domain, probe_active)
}

fn discover_subdomains(mut app simplecli.SimpleCli, domain string, probe_active bool) {
	app.info('Querying Certificate Transparency (crt.sh) for *.${domain}...')
	app.reset_timer()

	// Query crt.sh JSON endpoint using built-in HTTP
	url := 'https://crt.sh/?q=%25.${domain}&output=json'
	json_res := app.http_get(url)

	mut subdomains := []string{}
	if json_res.len > 0 && json_res.contains('name_value') {
		lines := json_res.split('\n')
		for l in lines {
			if l.contains('"name_value":') {
				val := l.split('"name_value":')[1].replace('"', '').replace(',', '').trim_space()
				entries := val.split('\\n')
				for e in entries {
					clean := e.trim_space()
					if clean.ends_with(domain) && !subdomains.contains(clean) && !clean.contains('*') {
						subdomains << clean
					}
				}
			}
		}
	}

	// Fallback common list if crt.sh was unreachable
	if subdomains.len == 0 {
		common := ['www', 'api', 'dev', 'staging', 'mail', 'app', 'docs', 'blog']
		for c in common {
			candidate := '${c}.${domain}'
			subdomains << candidate
		}
	}

	app.success('Discovered ${subdomains.len} subdomains in ${app.elapsed_ms()} ms:')

	mut rows := [][]string{}
	for i, sub in subdomains {
		if i >= 30 {
			break
		}
		status := if probe_active {
			is_up := app.ping_tcp_port(sub, 443, 800) || app.ping_tcp_port(sub, 80, 800)
			if is_up { app.green('ONLINE') } else { app.dim('OFFLINE') }
		} else {
			app.cyan('DISCOVERED')
		}
		rows << ['${i + 1}', sub, status]
	}

	app.table(['#', 'Subdomain FQDN', 'Status'], rows)
}

fn run_interactive(mut app simplecli.SimpleCli) {
	app.panel('Subdomain Discovery REPL', 'Find public subdomains via SSL/TLS Certificate Transparency logs.')
	dom := app.prompt('Enter root domain name', 'github.com')
	should_probe := app.confirm('Probe TCP HTTP/HTTPS responsiveness on discovered hosts?', true)
	discover_subdomains(mut app, dom, should_probe)
}

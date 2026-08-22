module main

import simplecli

fn main() {
	mut app := simplecli.new_app('dns-cli', '1.0.0')
	app.set_description('DNS Resolver & SSL Certificate Inspector CLI')

	app.add_flag_string('domain', 'd', 'vlang.io', 'Domain name to inspect')
	app.add_flag_string('type', 't', 'A', 'DNS record type: A, AAAA, MX, NS, TXT, ANY')
	app.add_flag_bool('ssl', 's', false, 'Inspect SSL/TLS certificate details')
	app.add_flag_bool('interactive', 'x', false, 'Launch interactive DNS workbench')

	app.parse_cli() or { return }

	app.banner('DNS & SSL Studio CLI', 'v1.0.0 - Domain & Certificate Inspector')

	if app.get_flag_bool('interactive') {
		run_interactive(mut app)
		return
	}

	domain := app.get_flag_string('domain')
	rec_type := app.get_flag_string('type').to_upper()

	if app.get_flag_bool('ssl') {
		inspect_ssl(mut app, domain)
		return
	}

	resolve_dns(mut app, domain, rec_type)
}

fn resolve_dns(mut app simplecli.SimpleCli, domain string, rec_type string) {
	app.info('Resolving DNS records for "${domain}" (type: ${rec_type})...')
	app.reset_timer()

	out, code := app.exec('dig +short ${rec_type} ${domain}')
	if code == 0 && out.trim_space().len > 0 {
		records := out.split_into_lines().filter(it.len > 0)
		mut rows := [][]string{}
		for r in records {
			rows << [domain, rec_type, r]
		}
		app.table(['Domain', 'Type', 'Record Value'], rows)
		app.success('Resolved in ${app.elapsed_ms()} ms.')
	} else {
		// Fallback to nslookup
		ns_out, _ := app.exec('nslookup -type=${rec_type} ${domain}')
		println(ns_out)
	}
}

fn inspect_ssl(mut app simplecli.SimpleCli, domain string) {
	app.info('Inspecting SSL/TLS certificate for ${domain}:443...')
	cmd := "openssl s_client -connect ${domain}:443 -servername ${domain} 2>/dev/null | openssl x509 -noout -dates -subject -issuer 2>/dev/null"
	out, code := app.exec(cmd)
	if code == 0 && out.trim_space().len > 0 {
		app.success('SSL Certificate Information:')
		println(out)
	} else {
		app.warn('Could not establish TLS connection to ${domain}:443')
	}
}

fn run_interactive(mut app simplecli.SimpleCli) {
	app.panel('DNS & SSL Studio REPL', 'Query domain name system servers and verify TLS certificates.')
	target := app.prompt('Enter target domain name', 'github.com')
	choice := app.select('Action:', [
		'Resolve All DNS Records (A, MX, TXT)',
		'Inspect SSL/TLS Certificate',
	])

	match choice {
		'Inspect SSL/TLS Certificate' {
			inspect_ssl(mut app, target)
		}
		else {
			resolve_dns(mut app, target, 'A')
			resolve_dns(mut app, target, 'MX')
			resolve_dns(mut app, target, 'TXT')
		}
	}
}

module main

import os
import strings
import time
import simplegui

fn format_dig_output(raw string, domain string, rec_type string, server_str string, elapsed_ms i64) string {
	lines := raw.split_into_lines()
	mut answers := []string{}
	mut stats := []string{}

	for line in lines {
		trimmed := line.trim_space()
		if trimmed.starts_with(';; Query time:') || trimmed.starts_with(';; SERVER:') || trimmed.starts_with(';; WHEN:') || trimmed.starts_with(';; MSG SIZE') {
			stats << trimmed.replace(';; ', '')
		} else if trimmed.starts_with(';') {
			continue
		} else if trimmed.len > 0 {
			mut tokens := []string{}
			for t in trimmed.split(' ') {
				for sub in t.split('\t') {
					if sub.trim_space().len > 0 {
						tokens << sub.trim_space()
					}
				}
			}
			if tokens.len >= 5 {
				p_name := tokens[0]
				p_ttl := tokens[1]
				p_type := tokens[3]
				p_data := tokens[4..].join(' ')
				ttl_str := '${p_ttl}s'
				answers << '${p_type:-6s} | ${p_name:-28s} | ${ttl_str:-8s} | ${p_data}'
			} else {
				answers << trimmed
			}
		}
	}

	mut sb := strings.new_builder(512)
	sb.writeln('========================================================================')
	sb.writeln(' DNS LOOKUP RESULTS: ${domain} [Record: ${rec_type}]')
	if server_str.len > 0 {
		sb.writeln(' Nameserver     : ${server_str}')
	}
	sb.writeln(' Resolution Time: ${elapsed_ms} ms')
	sb.writeln('========================================================================\n')

	if answers.len > 0 {
		sb.writeln('TYPE   | NAME                         | TTL      | VALUE / TARGET')
		sb.writeln('-------+------------------------------+----------+----------------------------------')
		for ans in answers {
			sb.writeln(ans)
		}
		sb.writeln('')
	} else {
		sb.writeln('No answer records returned.\n')
	}

	if stats.len > 0 {
		sb.writeln('--- Resolver Diagnostics ---')
		for st in stats {
			sb.writeln('  * ' + st)
		}
	}

	return sb.str().trim_space()
}

// Helper to find dig / openssl path
fn get_dig_bin() string {
	if path := os.find_abs_path_of_executable('dig') {
		return path
	}
	common_paths := [
		'/opt/homebrew/bin/dig',
		'/usr/local/bin/dig',
		'/usr/bin/dig',
		'/bin/dig',
	]
	for p in common_paths {
		if os.exists(p) {
			return p
		}
	}
	return 'dig'
}

fn get_openssl_bin() string {
	if path := os.find_abs_path_of_executable('openssl') {
		return path
	}
	common_paths := [
		'/opt/homebrew/bin/openssl',
		'/usr/local/bin/openssl',
		'/usr/bin/openssl',
	]
	for p in common_paths {
		if os.exists(p) {
			return p
		}
	}
	return 'openssl'
}

fn main() {
	println('Starting SimpleGUI - DNS & SSL Studio Pro (DNS Records & Certificate Inspector)...')

	mut win := simplegui.new_simple_window('SimpleGUI - DNS & SSL Studio Pro', 1060, 940)
	win.set_fullscreen(true)
	win.set_spacing(8)
	win.set_padding(16)

	saved_theme := simplegui.get_saved_theme()
	win.set_theme(saved_theme)

	// Top Banner / Diagnostics
	win.begin_row('row_dns_top')
	win.add_heading('DNS & SSL Studio Pro')
	win.add_label('lbl_theme', 'Theme:')
	win.add_dropdown('dd_app_theme', simplegui.list_themes(), saved_theme)
	win.set_control_width('dd_app_theme', 150)
	win.end_row()

	win.on_change('dd_app_theme', fn (mut w simplegui.SimpleWindow, selected string) {
		w.set_theme(selected)
		w.toast('Theme changed to ${selected}')
	})

	dig_path := get_dig_bin()
	openssl_path := get_openssl_bin()
	win.add_label('lbl_engine_info', 'DNS Engine: ${dig_path}  |  TLS Engine: ${openssl_path}  |  Mode: Async Worker')

	// Query Controls
	win.begin_group_box('grp_dns_scope', 'Target Domain & Query Parameters')
	
	win.begin_row('row_target_bar')
	win.add_label('lbl_domain', 'Domain Name:')
	win.add_input('txt_domain', 'github.com')
	win.set_control_width('txt_domain', 280)

	win.add_label('lbl_record_type', 'Record Type:')
	win.add_dropdown('dd_record_type', [
		'ANY (All Records)',
		'A (IPv4 Address)',
		'AAAA (IPv6 Address)',
		'CNAME (Canonical Name)',
		'MX (Mail Exchange)',
		'TXT (SPF / DKIM / Verification)',
		'NS (Name Servers)',
		'SOA (Start of Authority)',
		'PTR (Reverse DNS)',
		'CAA (Certificate Authority Auth)'
	], 'ANY (All Records)')
	win.set_control_width('dd_record_type', 210)

	win.add_label('lbl_server', 'DNS Server (@):')
	win.add_dropdown('dd_nameserver', [
		'Default System DNS',
		'Cloudflare (1.1.1.1)',
		'Google (8.8.8.8)',
		'Quad9 (9.9.9.9)',
		'OpenDNS (208.67.222.222)',
		'AdGuard (94.140.14.14)'
	], 'Default System DNS')
	win.set_control_width('dd_nameserver', 180)
	win.end_row()

	win.begin_row('row_options_bar')
	win.add_checkbox('chk_short', 'Short Output (+short)', false)
	win.add_checkbox('chk_trace', 'DNS Root Trace (+trace)', false)
	win.add_checkbox('chk_dnssec', 'Validate DNSSEC (+dnssec)', false)
	win.add_checkbox('chk_noall', 'Clean Answer Only (+noall +answer)', true)
	win.end_row()

	win.end_group_box()

	// Execution Actions Bar
	win.begin_row('row_actions')
	win.add_button('btn_resolve_dns', 'Resolve DNS Records')
	win.add_button('btn_inspect_ssl', 'Inspect TLS / SSL Certificate')
	win.add_button('btn_check_email_auth', 'Check SPF / DKIM / DMARC')
	win.add_button('btn_copy_output', 'Copy Output')
	win.add_button('btn_save_output', 'Save Output...')
	win.add_button('btn_clear_output', 'Clear')
	win.end_row()

	// Output Report
	win.begin_group_box('grp_results', 'DNS Resolution & SSL Certificate Analysis')
	win.add_textarea('txt_results', '')
	win.set_control_height('txt_results', 320)
	win.end_group_box()

	// Console Log
	win.begin_group_box('grp_console', 'DNS & SSL Activity Log')
	win.add_console('dns_console', 120)
	win.end_group_box()

	// Status Row
	win.begin_row('row_stats')
	win.add_label('lbl_stats', 'Stats: Ready  |  Target: None  |  Latency: 0 ms')
	win.end_row()

	win.append_console('dns_console', ' DNS & SSL Studio Pro Initialized.\n', 1)
	win.append_console('dns_console', ' Ready to inspect DNS records, authoritative name servers, and X.509 certificates.\n', 4)

	// -------------------------------------------------------------
	// Event Handlers
	// -------------------------------------------------------------

	// Resolve DNS Handler
	win.on_click('btn_resolve_dns', fn (mut w simplegui.SimpleWindow) {
		domain := w.get('txt_domain').trim_space()
		if domain == '' {
			w.alert('Domain Required', 'Please enter a target domain name.')
			return
		}

		dig_bin := get_dig_bin()
		rec_type_raw := w.get('dd_record_type')
		rec_type := rec_type_raw.split(' ')[0]

		server_raw := w.get('dd_nameserver')
		mut server_arg := ''
		if server_raw.contains('1.1.1.1') { server_arg = '@1.1.1.1' }
		else if server_raw.contains('8.8.8.8') { server_arg = '@8.8.8.8' }
		else if server_raw.contains('9.9.9.9') { server_arg = '@9.9.9.9' }
		else if server_raw.contains('208.67.222.222') { server_arg = '@208.67.222.222' }
		else if server_raw.contains('94.140.14.14') { server_arg = '@94.140.14.14' }

		is_short := w.get('chk_short') == 'true'
		is_trace := w.get('chk_trace') == 'true'
		is_dnssec := w.get('chk_dnssec') == 'true'
		is_clean := w.get('chk_noall') == 'true'

		mut args := []string{}
		args << '+nocmd'
		if server_arg != '' { args << server_arg }
		args << domain
		if rec_type != 'ANY' { args << rec_type }

		if is_short {
			args << '+short'
		} else if is_trace {
			args << '+trace'
		} else if is_clean {
			args << ['+noall', '+answer', '+stats']
		}

		if is_dnssec {
			args << '+dnssec'
		}

		w.append_console('dns_console', ' Resolving DNS: dig ${args.join(" ")}\n', 1)
		w.set_status('Querying DNS records for ${domain}...')

		go fn [mut w, dig_bin, args, domain, rec_type, server_raw, is_short, is_trace] () {
			t0 := time.ticks()
			res := simplegui.exec_safe(dig_bin, args)
			elapsed_ms := time.ticks() - t0

			w.run_on_main_thread(fn [res, elapsed_ms, domain, rec_type, server_raw, is_short, is_trace] (mut win_main simplegui.SimpleWindow) {
				out := res.output.trim_space()
				formatted := if is_short || is_trace {
					out
				} else {
					format_dig_output(out, domain, rec_type, server_raw, elapsed_ms)
				}
				win_main.set('txt_results', formatted)

				if res.exit_code == 0 {
					win_main.append_console('dns_console', ' DNS query completed for ${domain} (${rec_type}) in ${elapsed_ms} ms.\n', 4)
					win_main.set('lbl_stats', ' Stats: SUCCESS  |  Domain: ${domain}  |  Record: ${rec_type}  |  Duration: ${elapsed_ms} ms')
					win_main.set_status('DNS query completed in ${elapsed_ms} ms.')
					win_main.toast('DNS records resolved!')
				} else {
					win_main.append_console('dns_console', ' DNS Query Error:\n' + out + '\n', 3)
					win_main.set('lbl_stats', ' Stats: ERROR (Exit ${res.exit_code})  |  Duration: ${elapsed_ms} ms')
					win_main.set_status('DNS query failed.')
				}
			})
		}()
	})

	// Inspect SSL Certificate Handler
	win.on_click('btn_inspect_ssl', fn (mut w simplegui.SimpleWindow) {
		domain := w.get('txt_domain').trim_space()
		if domain == '' {
			w.alert('Domain Required', 'Please enter a target domain name.')
			return
		}

		openssl_bin := get_openssl_bin()
		target_host := '${domain}:443'
		w.append_console('dns_console', ' Connecting to TLS endpoint: ${target_host}...\n', 1)
		w.set_status('Retrieving SSL/TLS certificate for ${domain}...')

		go fn [mut w, openssl_bin, target_host, domain] () {
			t0 := time.ticks()
			cmd := 'echo | ${openssl_bin} s_client -connect ${target_host} -servername ${domain} 2>/dev/null | ${openssl_bin} x509 -text -noout'
			res := os.execute(cmd)
			elapsed_ms := time.ticks() - t0

			w.run_on_main_thread(fn [res, elapsed_ms, domain] (mut win_main simplegui.SimpleWindow) {
				out := res.output.trim_space()
				if out != '' {
					win_main.set('txt_results', out)
					win_main.append_console('dns_console', ' TLS Certificate extracted for ${domain} in ${elapsed_ms} ms.\n', 4)
					win_main.set('lbl_stats', ' Stats: SSL CERT LOADED  |  Target: ${domain}  |  Duration: ${elapsed_ms} ms')
					win_main.set_status('SSL certificate retrieved in ${elapsed_ms} ms.')
					win_main.toast('SSL Certificate loaded!')
				} else {
					win_main.append_console('dns_console', ' Failed to connect to SSL on port 443.\n', 3)
					win_main.set_status('SSL connection failed.')
				}
			})
		}()
	})

	// Check SPF / DKIM / DMARC Email Auth
	win.on_click('btn_check_email_auth', fn (mut w simplegui.SimpleWindow) {
		domain := w.get('txt_domain').trim_space()
		if domain == '' {
			w.alert('Domain Required', 'Please enter a target domain name.')
			return
		}

		dig_bin := get_dig_bin()
		w.append_console('dns_console', ' Checking SPF, DMARC, and MX records for ${domain}...\n', 1)
		w.set_status('Checking email authentication records...')

		go fn [mut w, dig_bin, domain] () {
			t0 := time.ticks()
			
			mx_res := simplegui.exec_safe(dig_bin, [domain, 'MX', '+short'])
			spf_res := simplegui.exec_safe(dig_bin, [domain, 'TXT', '+short'])
			dmarc_res := simplegui.exec_safe(dig_bin, ['_dmarc.' + domain, 'TXT', '+short'])

			elapsed_ms := time.ticks() - t0

			mut report := '===================================================\n'
			report += 'Email Authentication Security Report: ${domain}\n'
			report += '===================================================\n\n'

			report += '--- 1. MX (Mail Exchange) Servers ---\n'
			report += if mx_res.output.trim_space() != '' { mx_res.output.trim_space() } else { 'No MX records found.' }
			report += '\n\n--- 2. SPF (Sender Policy Framework) ---\n'
			mut has_spf := false
			for line in spf_res.output.split_into_lines() {
				if line.contains('v=spf1') {
					report += line + '\n'
					has_spf = true
				}
			}
			if !has_spf { report += ' No SPF (v=spf1) record detected!\n' }

			report += '\n--- 3. DMARC Policy (_dmarc.${domain}) ---\n'
			if dmarc_res.output.trim_space() != '' {
				report += dmarc_res.output.trim_space() + '\n'
			} else {
				report += ' No DMARC record found for _dmarc.${domain}!\n'
			}

			w.run_on_main_thread(fn [report, elapsed_ms, domain] (mut win_main simplegui.SimpleWindow) {
				win_main.set('txt_results', report)
				win_main.append_console('dns_console', ' Email authentication report generated for ${domain} in ${elapsed_ms} ms.\n', 4)
				win_main.set('lbl_stats', ' Stats: EMAIL AUTH CHECKED  |  Domain: ${domain}  |  Duration: ${elapsed_ms} ms')
				win_main.set_status('Email security analysis complete.')
				win_main.toast('Email authentication report ready!')
			})
		}()
	})

	// Copy Output
	win.on_click('btn_copy_output', fn (mut w simplegui.SimpleWindow) {
		out := w.get('txt_results')
		if out != '' {
			w.copy_to_clipboard(out)
			w.toast('Output copied to clipboard!')
		} else {
			w.toast('No output to copy.')
		}
	})

	// Save Output
	win.on_click('btn_save_output', fn (mut w simplegui.SimpleWindow) {
		out := w.get('txt_results')
		if out.trim_space() == '' {
			w.toast('No results to save.')
			return
		}
		path := w.save_file_picker()
		if path != '' {
			mut save_file := path
			if !save_file.ends_with('.txt') {
				save_file += '.txt'
			}
			os.write_file(save_file, out) or {
				w.toast('Failed to save file.')
				return
			}
			w.toast('Saved report to ${os.file_name(save_file)}')
			w.append_console('dns_console', ' Saved report to: ${save_file}\n', 1)
		}
	})

	// Clear
	win.on_click('btn_clear_output', fn (mut w simplegui.SimpleWindow) {
		w.set('txt_results', '')
		w.clear_console('dns_console')
		w.toast('Cleared output.')
	})

	win.start()
}

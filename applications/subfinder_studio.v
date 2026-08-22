module main

import os
import time
import simplegui

// Helper to find subfinder path
fn get_subfinder_bin() string {
	if path := os.find_abs_path_of_executable('subfinder') {
		return path
	}
	common_paths := [
		'/opt/homebrew/bin/subfinder',
		'/usr/local/bin/subfinder',
		'/bin/subfinder',
	]
	for p in common_paths {
		if os.exists(p) {
			return p
		}
	}
	return 'subfinder'
}

fn main() {
	println('Starting SimpleGUI - Subfinder Studio Pro (Passive Reconnaissance Workbench)...')

	mut win := simplegui.new_simple_window('SimpleGUI - Subfinder Studio Pro', 1020, 930)
	win.set_fullscreen(true)
	win.set_spacing(8)
	win.set_padding(16)

	saved_theme := simplegui.get_saved_theme()
	win.set_theme(saved_theme)

	// Top Banner / Diagnostics
	win.begin_row('row_subfinder_top')
	win.add_heading('Subfinder Studio Pro')
	win.add_label('lbl_theme', 'Theme:')
	win.add_dropdown('dd_app_theme', simplegui.list_themes(), saved_theme)
	win.set_control_width('dd_app_theme', 150)
	win.end_row()

	win.on_change('dd_app_theme', fn (mut w simplegui.SimpleWindow, selected string) {
		w.set_theme(selected)
		w.toast('Theme changed to ${selected}')
	})
	subfinder_path := get_subfinder_bin()
	win.add_label('lbl_engine_info', 'Engine: ${subfinder_path}  |  Platform: macOS Cocoa  |  Mode: Async Worker (Non-Blocking)')

	// -------------------------------------------------------------
	// Target Domain Scope & Input
	// -------------------------------------------------------------
	win.begin_group_box('grp_target', 'Target Domain & Scope Configuration')
	
	win.begin_row('row_target')
	win.add_label('lbl_domain', 'Target Domain:')
	win.add_input('txt_domain', 'github.com')
	win.set_control_width('txt_domain', 320)
	win.add_button('btn_load_domain_file', 'Load Domain List (File)...')
	win.add_label('lbl_mode', 'Mode:')
	win.add_dropdown('dd_mode', [
		'Fast Passive (Default Sources)',
		'All Sources (Comprehensive -all)',
		'Recursive Subdomains (-recursive)',
		'Active DNS Validation (-active -oI)'
	], 'Fast Passive (Default Sources)')
	win.set_control_width('dd_mode', 230)
	win.end_row()

	win.begin_row('row_filters')
	win.add_label('lbl_resolvers', 'Resolvers (-r):')
	win.add_input('txt_resolvers', '1.1.1.1, 8.8.8.8, 9.9.9.9')
	win.set_control_width('txt_resolvers', 220)

	win.add_label('lbl_rate_limit', 'Rate Limit (req/s):')
	win.add_input('txt_rate_limit', '0')
	win.set_control_width('txt_rate_limit', 50)

	win.add_label('lbl_timeout', 'Timeout (sec):')
	win.add_input('txt_timeout', '30')
	win.set_control_width('txt_timeout', 50)

	win.add_checkbox('chk_silent', 'Silent Mode (-silent)', true)
	win.add_checkbox('chk_sources', 'Include Sources (-cs)', false)
	win.end_row()

	win.end_group_box()

	// -------------------------------------------------------------
	// Live Command Preview & Execution Controls
	// -------------------------------------------------------------
	win.begin_row('row_exec_bar')
	win.add_button('btn_run_subfinder', 'Start Subdomain Discovery')
	win.add_button('btn_list_sources', 'List All Available Sources')
	win.add_button('btn_copy_results', 'Copy Subdomains')
	win.add_button('btn_copy_urls', 'Copy as HTTPS URLs')
	win.add_button('btn_save_results', 'Save Results to File...')
	win.add_button('btn_clear_results', 'Clear')
	win.end_row()

	// -------------------------------------------------------------
	// Discovered Subdomains List & Explorer
	// -------------------------------------------------------------
	win.begin_group_box('grp_results', 'Discovered Subdomains & Asset Explorer')
	win.add_textarea('txt_subdomains', '')
	win.set_control_height('txt_subdomains', 260)
	win.end_group_box()

	// -------------------------------------------------------------
	// Live Activity & Telemetry Console
	// -------------------------------------------------------------
	win.begin_group_box('grp_console', 'Subfinder Activity & Source Telemetry Log')
	win.add_console('subfinder_console', 140)
	win.end_group_box()

	// Stats Row
	win.begin_row('row_stats')
	win.add_label('lbl_stats', 'Stats: Ready  |  Discovered Subdomains: 0  |  Duration: 0 ms')
	win.end_row()

	win.append_console('subfinder_console', ' Subfinder Studio Pro Initialized.\n', 1)
	win.append_console('subfinder_console', ' Ready to discover passive subdomains via Certificate Transparency, DNS, and Web Archives.\n', 4)

	// -------------------------------------------------------------
	// Event Handlers & Async Engine
	// -------------------------------------------------------------

	// Load Domain List from File
	win.on_click('btn_load_domain_file', fn (mut w simplegui.SimpleWindow) {
		path := w.select_file()
		if path != '' && os.exists(path) {
			w.set('txt_domain', '@' + path)
			w.append_console('subfinder_console', ' Target domain list loaded from: ${path}\n', 1)
			w.toast('Loaded domain list from file.')
		}
	})

	// List Available Sources
	win.on_click('btn_list_sources', fn (mut w simplegui.SimpleWindow) {
		subfinder := get_subfinder_bin()
		w.append_console('subfinder_console', ' Querying all available Subfinder sources (-ls)...\n', 1)
		w.set_status('Fetching available OSINT sources...')
		w.toast('Listing sources...')

		go fn [mut w, subfinder] () {
			res := os.execute('${subfinder} -ls')
			w.run_on_main_thread(fn [res] (mut win_main simplegui.SimpleWindow) {
				win_main.append_console('subfinder_console', res.output + '\n', 4)
				win_main.set_status('Sources listed successfully.')
			})
		}()
	})

	// Start Subdomain Discovery (Async Non-Blocking)
	win.on_click('btn_run_subfinder', fn (mut w simplegui.SimpleWindow) {
		domain_input := w.get('txt_domain').trim_space()
		if domain_input == '' {
			w.alert('Domain Required', 'Please enter a target domain (e.g. example.com).')
			return
		}

		subfinder := get_subfinder_bin()
		mode_sel := w.get('dd_mode')
		resolvers := w.get('txt_resolvers').trim_space()
		rate_limit := w.get('txt_rate_limit').trim_space()
		timeout := w.get('txt_timeout').trim_space()
		is_silent := w.get('chk_silent') == 'true'
		is_sources := w.get('chk_sources') == 'true'

		mut raw_args := []string{}

		if domain_input.starts_with('@') {
			list_path := domain_input[1..]
			raw_args << ['-dL', list_path]
		} else {
			raw_args << ['-d', domain_input]
		}

		if mode_sel.contains('All Sources') {
			raw_args << '-all'
		} else if mode_sel.contains('Recursive') {
			raw_args << '-recursive'
		} else if mode_sel.contains('Active DNS') {
			raw_args << '-nW'
			raw_args << '-oI'
		}

		if resolvers != '' {
			raw_args << ['-r', resolvers]
		}

		if rate_limit != '' && rate_limit != '0' {
			raw_args << ['-rl', rate_limit]
		}

		if timeout != '' && timeout != '30' {
			raw_args << ['-timeout', timeout]
		}

		if is_silent {
			raw_args << '-silent'
		}

		if is_sources {
			raw_args << '-cs'
		}

		raw_args << '-nc' // No color for clean text parsing

		w.append_console('subfinder_console', ' Executing in background with secure argument isolation\n', 1)
		w.set_status('Enumerating subdomains for ${domain_input} in background...')
		w.toast('Discovery started in background...')

		go fn [mut w, subfinder, raw_args, domain_input] () {
			t0 := time.ticks()
			res := simplegui.exec_safe(subfinder, raw_args)
			elapsed_ms := time.ticks() - t0

			w.run_on_main_thread(fn [res, elapsed_ms, domain_input] (mut win_main simplegui.SimpleWindow) {
				if res.exit_code == 0 {
					out_str := res.output.trim_space()
					win_main.set('txt_subdomains', out_str)
					
					mut count := 0
					if out_str != '' {
						count = out_str.split_into_lines().len
					}
					
					win_main.append_console('subfinder_console', ' Completed! Found ${count} subdomains for ${domain_input} in ${elapsed_ms} ms.\n', 4)
					win_main.set('lbl_stats', ' Stats: SUCCESS  |  Target: ${domain_input}  |  Subdomains Found: ${count}  |  Duration: ${elapsed_ms} ms')
					win_main.set_status('Discovery completed: ${count} subdomains found.')
					win_main.toast('Found ${count} subdomains in ${elapsed_ms} ms!')
				} else {
					win_main.append_console('subfinder_console', ' Subfinder Error:\n' + res.output + '\n', 3)
					win_main.set('lbl_stats', ' Stats: ERROR (Exit code ${res.exit_code})  |  Duration: ${elapsed_ms} ms')
					win_main.set_status('Subfinder reported an error.')
				}
			})
		}()
	})

	// Copy Results
	win.on_click('btn_copy_results', fn (mut w simplegui.SimpleWindow) {
		res := w.get('txt_subdomains').trim_space()
		if res != '' {
			w.copy_to_clipboard(res)
			w.toast('Subdomains copied to clipboard!')
		} else {
			w.toast('No subdomains to copy.')
		}
	})

	// Copy as HTTPS URLs
	win.on_click('btn_copy_urls', fn (mut w simplegui.SimpleWindow) {
		res := w.get('txt_subdomains').trim_space()
		if res == '' {
			w.toast('No subdomains to format.')
			return
		}
		lines := res.split_into_lines()
		mut urls := []string{}
		for line in lines {
			l := line.trim_space()
			if l != '' {
				// Strip any trailing IP or source info if present
				host := l.split(' ')[0].split('\t')[0]
				urls << 'https://' + host
			}
		}
		formatted := urls.join('\n')
		w.copy_to_clipboard(formatted)
		w.toast('Copied ${urls.len} HTTPS URLs to clipboard!')
	})

	// Save Results to File
	win.on_click('btn_save_results', fn (mut w simplegui.SimpleWindow) {
		res := w.get('txt_subdomains').trim_space()
		if res == '' {
			w.toast('No results to save.')
			return
		}
		path := w.save_file_picker()
		if path != '' {
			os.write_file(path, res) or {
				w.alert('Save Error', 'Failed to save file: ' + err.str())
				return
			}
			w.toast('Saved subdomains to ${path}')
			w.append_console('subfinder_console', ' Saved results to: ${path}\n', 4)
		}
	})

	// Clear Results
	win.on_click('btn_clear_results', fn (mut w simplegui.SimpleWindow) {
		w.set('txt_subdomains', '')
		w.clear_console('subfinder_console')
		w.set('lbl_stats', ' Stats: Ready  |  Discovered Subdomains: 0  |  Duration: 0 ms')
		w.toast('Cleared results.')
	})

	println('Subfinder Studio Pro configured. Starting event loop...')
	win.run()
}

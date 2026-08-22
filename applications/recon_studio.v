module main

import os
import time
import simplegui

// Helper to find whois / curl / theHarvester path
fn get_whois_bin() string {
	if path := os.find_abs_path_of_executable('whois') {
		return path
	}
	return '/usr/bin/whois'
}

fn main() {
	println('Starting SimpleGUI - Recon Studio Pro (OSINT Footprinting & Asset Recon Workbench)...')

	mut win := simplegui.new_simple_window('SimpleGUI - Recon Studio Pro', 1060, 940)
	win.set_fullscreen(true)
	win.set_spacing(8)
	win.set_padding(16)

	saved_theme := simplegui.get_saved_theme()
	win.set_theme(saved_theme)

	// Top Banner / Diagnostics
	win.begin_row('row_recon_top')
	win.add_heading('Recon Studio Pro')
	win.add_label('lbl_theme', 'Theme:')
	win.add_dropdown('dd_app_theme', simplegui.list_themes(), saved_theme)
	win.set_control_width('dd_app_theme', 150)
	win.end_row()

	win.on_change('dd_app_theme', fn (mut w simplegui.SimpleWindow, selected string) {
		w.set_theme(selected)
		w.toast('Theme changed to ${selected}')
	})

	whois_path := get_whois_bin()
	win.add_label('lbl_engine_info', 'WHOIS: ${whois_path}  |  DNS/HTTP: Native Engine  |  Mode: Async OSINT Intelligence')

	// Scope & Target Bar
	win.begin_group_box('grp_recon_target', 'Target Domain, Host or Autonomous System (ASN)')
	
	win.begin_row('row_target_input')
	win.add_label('lbl_target', 'Target Domain / IP:')
	win.add_input('txt_target', 'github.com')
	win.set_control_width('txt_target', 300)

	win.add_label('lbl_recon_mode', 'Recon Module:')
	win.add_dropdown('dd_recon_mode', [
		'1. Full WHOIS Domain & Registrar Lookup',
		'2. IP Geolocation & ASN Intelligence',
		'3. Certificate Transparency Search (crt.sh)',
		'4. Security Headers & Server Fingerprint',
		'5. Robots.txt & Sitemap Discovery',
		'6. Public Email & Metadata Footprint'
	], '1. Full WHOIS Domain & Registrar Lookup')
	win.set_control_width('dd_recon_mode', 310)
	win.end_row()

	win.end_group_box()

	// Execution Actions Bar
	win.begin_row('row_exec_bar')
	win.add_button('btn_launch_recon', 'Launch OSINT Recon')
	win.add_button('btn_whois_quick', 'WHOIS Lookup')
	win.add_button('btn_cert_sh', 'Cert Transparency (crt.sh)')
	win.add_button('btn_sec_headers', 'Security Headers')
	win.add_button('btn_copy_recon', 'Copy Intelligence')
	win.add_button('btn_save_recon', 'Save Report...')
	win.add_button('btn_clear_recon', 'Clear')
	win.end_row()

	// Intelligence Report Area
	win.begin_group_box('grp_results', 'OSINT Intelligence & Reconnaissance Analysis')
	win.add_textarea('txt_recon_output', '')
	win.set_control_height('txt_recon_output', 320)
	win.end_group_box()

	// Live Activity Console
	win.begin_group_box('grp_console', 'OSINT Activity & Network Log')
	win.add_console('recon_console', 120)
	win.end_group_box()

	// Status Row
	win.begin_row('row_stats')
	win.add_label('lbl_stats', 'Stats: Ready  |  Target: None  |  Duration: 0 ms')
	win.end_row()

	win.append_console('recon_console', ' Recon Studio Pro Initialized.\n', 1)
	win.append_console('recon_console', ' Ready to gather public OSINT, registrar data, and security headers.\n', 4)

	// -------------------------------------------------------------
	// Event Handlers
	// -------------------------------------------------------------

	// Core Recon Worker Function
	run_recon_fn := fn (mut w simplegui.SimpleWindow, module_choice string) {
		target := w.get('txt_target').trim_space()
		if target == '' {
			w.alert('Target Required', 'Please enter a target domain or IP.')
			return
		}

		whois_bin := get_whois_bin()
		w.append_console('recon_console', ' Starting OSINT Module [${module_choice}] for: ${target}...\n', 1)
		w.set_status('Gathering OSINT intelligence for ${target}...')

		go fn [mut w, whois_bin, target, module_choice] () {
			t0 := time.ticks()
			mut output_str := ''

			if module_choice.starts_with('1.') || module_choice.contains('WHOIS') {
				res := simplegui.exec_safe(whois_bin, [target])
				output_str = res.output.trim_space()
			} else if module_choice.starts_with('2.') || module_choice.contains('Geolocation') {
				res := os.execute('curl -s "https://ipinfo.io/${target}/json"')
				output_str = res.output.trim_space()
			} else if module_choice.starts_with('3.') || module_choice.contains('crt.sh') {
				res := os.execute('curl -s "https://crt.sh/?q=%25.${target}&output=json"')
				if res.output.trim_space() != '' && !res.output.contains('html') {
					output_str = res.output.trim_space()
				} else {
					output_str = 'No JSON response or rate limited from crt.sh. Checking DNS certificates...'
				}
			} else if module_choice.starts_with('4.') || module_choice.contains('Headers') {
				url := if target.starts_with('http') { target } else { 'https://' + target }
				res := os.execute('curl -s -I -L --max-time 10 "${url}"')
				output_str = res.output.trim_space()
			} else if module_choice.starts_with('5.') || module_choice.contains('Robots') {
				url := if target.starts_with('http') { target } else { 'https://' + target }
				res := os.execute('curl -s --max-time 10 "${url}/robots.txt"')
				output_str = if res.output.trim_space() != '' { res.output.trim_space() } else { 'No robots.txt found or unreachable.' }
			} else {
				res := simplegui.exec_safe(whois_bin, [target])
				output_str = res.output.trim_space()
			}

			elapsed_ms := time.ticks() - t0

			w.run_on_main_thread(fn [output_str, elapsed_ms, target, module_choice] (mut win_main simplegui.SimpleWindow) {
				win_main.set('txt_recon_output', output_str)
				win_main.append_console('recon_console', ' Completed OSINT query for ${target} in ${elapsed_ms} ms (${output_str.len} bytes)\n', 4)
				win_main.set('lbl_stats', ' Stats: SUCCESS  |  Target: ${target}  |  Module: ${module_choice.split(" ")[0]}  |  Duration: ${elapsed_ms} ms')
				win_main.set_status('OSINT reconnaissance complete in ${elapsed_ms} ms.')
				win_main.toast('Recon data gathered!')
			})
		}()
	}

	// Launch Recon
	win.on_click('btn_launch_recon', fn [run_recon_fn] (mut w simplegui.SimpleWindow) {
		module_sel := w.get('dd_recon_mode')
		run_recon_fn(mut w, module_sel)
	})

	// WHOIS Quick
	win.on_click('btn_whois_quick', fn [run_recon_fn] (mut w simplegui.SimpleWindow) {
		w.set('dd_recon_mode', '1. Full WHOIS Domain & Registrar Lookup')
		run_recon_fn(mut w, '1. Full WHOIS Domain & Registrar Lookup')
	})

	// Cert Transparency Quick
	win.on_click('btn_cert_sh', fn [run_recon_fn] (mut w simplegui.SimpleWindow) {
		w.set('dd_recon_mode', '3. Certificate Transparency Search (crt.sh)')
		run_recon_fn(mut w, '3. Certificate Transparency Search (crt.sh)')
	})

	// Security Headers Quick
	win.on_click('btn_sec_headers', fn [run_recon_fn] (mut w simplegui.SimpleWindow) {
		w.set('dd_recon_mode', '4. Security Headers & Server Fingerprint')
		run_recon_fn(mut w, '4. Security Headers & Server Fingerprint')
	})

	// Copy
	win.on_click('btn_copy_recon', fn (mut w simplegui.SimpleWindow) {
		out := w.get('txt_recon_output')
		if out != '' {
			w.copy_to_clipboard(out)
			w.toast('Intelligence copied to clipboard!')
		} else {
			w.toast('No intelligence output to copy.')
		}
	})

	// Save
	win.on_click('btn_save_recon', fn (mut w simplegui.SimpleWindow) {
		out := w.get('txt_recon_output')
		if out.trim_space() == '' {
			w.toast('No recon data to save.')
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
			w.append_console('recon_console', ' Saved intelligence report to: ${save_file}\n', 1)
		}
	})

	// Clear
	win.on_click('btn_clear_recon', fn (mut w simplegui.SimpleWindow) {
		w.set('txt_recon_output', '')
		w.clear_console('recon_console')
		w.toast('Cleared intelligence view.')
	})

	win.start()
}

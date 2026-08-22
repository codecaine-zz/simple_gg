module main

import os
import time
import simplegui

// Helper to find nmap / rustscan path
fn get_nmap_bin() string {
	if path := os.find_abs_path_of_executable('nmap') {
		return path
	}
	common_paths := [
		'/opt/homebrew/bin/nmap',
		'/usr/local/bin/nmap',
		'/usr/bin/nmap',
	]
	for p in common_paths {
		if os.exists(p) {
			return p
		}
	}
	return 'nmap'
}

fn main() {
	println('Starting SimpleGUI - Nmap Studio Pro (Port Scanner & Network Security Workbench)...')

	mut win := simplegui.new_simple_window('SimpleGUI - Nmap Studio Pro', 1060, 940)
	win.set_fullscreen(true)
	win.set_spacing(8)
	win.set_padding(16)

	saved_theme := simplegui.get_saved_theme()
	win.set_theme(saved_theme)

	// Top Banner / Diagnostics
	win.begin_row('row_nmap_top')
	win.add_heading('Nmap Studio Pro')
	win.add_label('lbl_theme', 'Theme:')
	win.add_dropdown('dd_app_theme', simplegui.list_themes(), saved_theme)
	win.set_control_width('dd_app_theme', 150)
	win.end_row()

	win.on_change('dd_app_theme', fn (mut w simplegui.SimpleWindow, selected string) {
		w.set_theme(selected)
		w.toast('Theme changed to ${selected}')
	})

	nmap_path := get_nmap_bin()
	win.add_label('lbl_engine_info', 'Engine: ${nmap_path}  |  Platform: macOS Cocoa  |  Mode: Async Worker')

	// Target & Scan Profile Scope
	win.begin_group_box('grp_target', 'Target Specification & Scan Profiles')
	
	win.begin_row('row_target_input')
	win.add_label('lbl_target', 'Target Host / CIDR:')
	win.add_input('txt_target', 'scanme.nmap.org')
	win.set_control_width('txt_target', 300)

	win.add_label('lbl_ports', 'Ports (-p):')
	win.add_input('txt_ports', '80,443,22,8080,3000,8443')
	win.set_control_width('txt_ports', 220)

	win.add_label('lbl_profile', 'Profile:')
	win.add_dropdown('dd_scan_profile', [
		'1. Quick Scan (Top 100 Ports -F)',
		'2. Standard Service Version Scan (-sV)',
		'3. Comprehensive OS & Scripts (-A)',
		'4. Ping Sweep / Host Discovery (-sn)',
		'5. Vulnerability Assessment (--script vuln)',
		'6. SSL / TLS Certificate Check (--script ssl-cert)',
		'7. Full 65,535 Ports Scan (-p-)',
		'8. Fast SYN / TCP Connect Scan (-sT -T4)'
	], '2. Standard Service Version Scan (-sV)')
	win.set_control_width('dd_scan_profile', 260)
	win.end_row()

	win.begin_row('row_scan_options')
	win.add_checkbox('chk_service_version', 'Service Version (-sV)', true)
	win.add_checkbox('chk_os_detect', 'OS Detection (-O)', false)
	win.add_checkbox('chk_no_ping', 'Skip Ping (-Pn)', true)
	win.add_checkbox('chk_timing_fast', 'Aggressive Timing (-T4)', true)
	win.add_checkbox('chk_verbose', 'Verbose Output (-v)', true)
	win.add_button('btn_localhost', 'Scan Localhost (127.0.0.1)')
	win.end_row()

	win.end_group_box()

	// Execution Bar
	win.begin_row('row_exec_bar')
	win.add_button('btn_start_scan', 'Launch Port Scan')
	win.add_button('btn_copy_output', 'Copy Scan Results')
	win.add_button('btn_save_scan', 'Save Report As...')
	win.add_button('btn_clear_scan', 'Clear Output')
	win.end_row()

	// Scan Results Output
	win.begin_group_box('grp_results', 'Open Ports & Service Discovery Report')
	win.add_textarea('txt_scan_results', '')
	win.set_control_height('txt_scan_results', 320)
	win.end_group_box()

	// Live Activity Console
	win.begin_group_box('grp_console', 'Nmap Activity & Telemetry Log')
	win.add_console('nmap_console', 120)
	win.end_group_box()

	// Status Row
	win.begin_row('row_stats')
	win.add_label('lbl_stats', 'Stats: Ready  |  Target: None  |  Scan Duration: 0 ms')
	win.end_row()

	win.append_console('nmap_console', ' Nmap Studio Pro Initialized.\n', 1)
	win.append_console('nmap_console', ' Ready to scan network interfaces and remote targets.\n', 4)

	// -------------------------------------------------------------
	// Event Handlers
	// -------------------------------------------------------------

	// Localhost Quick Action
	win.on_click('btn_localhost', fn (mut w simplegui.SimpleWindow) {
		w.set('txt_target', '127.0.0.1')
		w.set('txt_ports', '22,80,443,3000,5000,8000,8080,9000')
		w.toast('Target set to localhost (127.0.0.1)')
	})

	// Profile Change Handler
	win.on_change('dd_scan_profile', fn (mut w simplegui.SimpleWindow, selected string) {
		if selected.starts_with('1.') {
			w.set('txt_ports', '')
			w.set('chk_service_version', 'false')
		} else if selected.starts_with('2.') {
			w.set('txt_ports', '80,443,22,8080,3000,8443')
			w.set('chk_service_version', 'true')
		} else if selected.starts_with('3.') {
			w.set('chk_service_version', 'true')
			w.set('chk_os_detect', 'true')
		} else if selected.starts_with('4.') {
			w.set('txt_ports', '')
		} else if selected.starts_with('7.') {
			w.set('txt_ports', '1-65535')
		}
		w.toast('Applied profile: ${selected}')
	})

	// Run Scan Worker
	win.on_click('btn_start_scan', fn (mut w simplegui.SimpleWindow) {
		target := w.get('txt_target').trim_space()
		if target == '' {
			w.alert('Target Required', 'Please enter a target host, IP, or network CIDR (e.g. scanme.nmap.org or 192.168.1.0/24).')
			return
		}

		nmap_bin := get_nmap_bin()
		profile := w.get('dd_scan_profile')
		ports := w.get('txt_ports').trim_space()
		is_sv := w.get('chk_service_version') == 'true'
		is_os := w.get('chk_os_detect') == 'true'
		is_pn := w.get('chk_no_ping') == 'true'
		is_t4 := w.get('chk_timing_fast') == 'true'
		is_v := w.get('chk_verbose') == 'true'

		mut args := []string{}

		if profile.starts_with('1.') {
			args << '-F'
		} else if profile.starts_with('3.') {
			args << '-A'
		} else if profile.starts_with('4.') {
			args << '-sn'
		} else if profile.starts_with('5.') {
			args << ['--script', 'vuln']
		} else if profile.starts_with('6.') {
			args << ['--script', 'ssl-cert']
		}

		if is_sv && !profile.starts_with('3.') && !profile.starts_with('4.') {
			args << '-sV'
		}
		if is_os && !profile.starts_with('4.') {
			args << '-O'
		}
		if is_pn {
			args << '-Pn'
		}
		if is_t4 {
			args << '-T4'
		}
		if is_v {
			args << '-v'
		}

		if ports != '' && !profile.starts_with('1.') && !profile.starts_with('4.') {
			args << ['-p', ports]
		}

		args << target

		w.append_console('nmap_console', ' Launching Nmap: nmap ${args.join(" ")}\n', 1)
		w.set_status('Scanning target ${target} in background...')
		w.toast('Port scan started...')

		go fn [mut w, nmap_bin, args, target] () {
			t0 := time.ticks()
			res := simplegui.exec_safe(nmap_bin, args)
			elapsed_ms := time.ticks() - t0

			w.run_on_main_thread(fn [res, elapsed_ms, target] (mut win_main simplegui.SimpleWindow) {
				out := res.output.trim_space()
				win_main.set('txt_scan_results', out)

				if res.exit_code == 0 {
					win_main.append_console('nmap_console', ' Scan completed for ${target} in ${elapsed_ms} ms.\n', 4)
					win_main.set('lbl_stats', ' Stats: SUCCESS  |  Target: ${target}  |  Duration: ${elapsed_ms} ms')
					win_main.set_status('Scan completed in ${elapsed_ms} ms.')
					win_main.toast('Port scan finished successfully!')
				} else {
					win_main.append_console('nmap_console', ' Nmap Scan Notice (Exit ${res.exit_code}):\n' + out + '\n', 3)
					win_main.set('lbl_stats', ' Stats: COMPLETED (Exit ${res.exit_code})  |  Duration: ${elapsed_ms} ms')
					win_main.set_status('Scan completed with notices.')
				}
			})
		}()
	})

	// Copy Output
	win.on_click('btn_copy_output', fn (mut w simplegui.SimpleWindow) {
		out := w.get('txt_scan_results')
		if out != '' {
			w.copy_to_clipboard(out)
			w.toast('Results copied to clipboard!')
		} else {
			w.toast('No scan output to copy.')
		}
	})

	// Save Report
	win.on_click('btn_save_scan', fn (mut w simplegui.SimpleWindow) {
		out := w.get('txt_scan_results')
		if out.trim_space() == '' {
			w.toast('No scan results to save.')
			return
		}
		path := w.save_file_picker()
		if path != '' {
			mut save_file := path
			if !save_file.ends_with('.txt') && !save_file.ends_with('.nmap') {
				save_file += '.txt'
			}
			os.write_file(save_file, out) or {
				w.toast('Failed to save file.')
				return
			}
			w.toast('Saved report to ${os.file_name(save_file)}')
			w.append_console('nmap_console', ' Saved scan report to: ${save_file}\n', 1)
		}
	})

	// Clear Scan
	win.on_click('btn_clear_scan', fn (mut w simplegui.SimpleWindow) {
		w.set('txt_scan_results', '')
		w.clear_console('nmap_console')
		w.toast('Cleared output.')
	})

	win.start()
}

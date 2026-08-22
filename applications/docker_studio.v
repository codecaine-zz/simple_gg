module main

import os
import time
import simplegui

// Helper to find docker / podman binary
fn get_container_bin() string {
	if path := os.find_abs_path_of_executable('docker') {
		return path
	}
	if path := os.find_abs_path_of_executable('podman') {
		return path
	}
	common_paths := [
		'/usr/local/bin/docker',
		'/opt/homebrew/bin/docker',
		'/opt/homebrew/bin/podman',
		'/usr/bin/docker',
	]
	for p in common_paths {
		if os.exists(p) {
			return p
		}
	}
	return 'docker'
}

fn main() {
	println('Starting SimpleGUI - Docker & Container Studio Pro...')

	mut win := simplegui.new_simple_window('SimpleGUI - Docker Studio Pro', 1080, 950)
	win.set_fullscreen(true)
	win.set_spacing(8)
	win.set_padding(16)

	saved_theme := simplegui.get_saved_theme()
	win.set_theme(saved_theme)

	// Top Banner / Diagnostics
	win.begin_row('row_docker_top')
	win.add_heading('Docker Studio Pro')
	win.add_label('lbl_theme', 'Theme:')
	win.add_dropdown('dd_app_theme', simplegui.list_themes(), saved_theme)
	win.set_control_width('dd_app_theme', 160)
	win.end_row()

	win.on_change('dd_app_theme', fn (mut w simplegui.SimpleWindow, selected string) {
		w.set_theme(selected)
		w.toast('Theme changed to ${selected}')
	})

	container_bin := get_container_bin()
	win.add_label('lbl_engine_info', 'Engine: ${container_bin} (Docker/Podman Daemon)  |  Platform: macOS  |  Mode: Async Worker')

	// Container & Image Target Selection
	win.begin_group_box('grp_target_box', 'Target Container / Image Specification')
	
	win.begin_row('row_target_input')
	win.add_label('lbl_id', 'Container ID / Image Name:')
	win.add_input('txt_target_id', '')
	win.set_control_width('txt_target_id', 380)
	win.end_row()

	win.begin_row('row_target_actions')
	win.add_button('btn_start_cnt', 'Start Container')
	win.add_button('btn_stop_cnt', 'Stop Container')
	win.add_button('btn_restart_cnt', 'Restart')
	win.add_button('btn_view_logs', 'View Logs')
	win.end_row()

	win.end_group_box()

	// Operations Bar
	win.begin_group_box('grp_operations', 'Container & Image Management Actions')
	
	win.begin_row('row_ops_btns1')
	win.add_button('btn_list_containers', 'Active Containers (ps)')
	win.add_button('btn_list_all_containers', 'All Containers (ps -a)')
	win.add_button('btn_list_images', 'Docker Images (ls)')
	win.add_button('btn_container_stats', 'Live Stats (CPU/RAM)')
	win.end_row()

	win.begin_row('row_ops_btns2')
	win.add_button('btn_volume_ls', 'Volumes')
	win.add_button('btn_network_ls', 'Networks')
	win.add_button('btn_system_prune', 'Prune Unused (Cache)')
	win.end_row()

	win.end_group_box()

	// Container Output Stream
	win.begin_group_box('grp_output_view', 'Container Telemetry, Logs & Process Output')
	win.add_textarea('txt_docker_output', '')
	win.set_control_height('txt_docker_output', 320)
	win.end_group_box()

	// Activity Log Console
	win.begin_group_box('grp_console', 'Docker Daemon Operations & Log')
	win.add_console('docker_console', 110)
	win.end_group_box()

	// Status Row
	win.begin_row('row_stats')
	win.add_label('lbl_stats', 'Stats: Ready  |  Engine: ${container_bin}  |  Duration: 0 ms')
	win.end_row()

	win.append_console('docker_console', ' Docker Studio Pro Initialized.\n', 1)
	win.append_console('docker_console', ' Ready to manage local containers, microservices, and images.\n', 4)

	// -------------------------------------------------------------
	// Async Execution Helper
	// -------------------------------------------------------------
	run_docker_cmd := fn (mut w simplegui.SimpleWindow, desc string, args []string) {
		bin_path := get_container_bin()
		w.append_console('docker_console', ' Executing: ${os.file_name(bin_path)} ${args.join(" ")}...\n', 1)
		w.set_status('Running ${desc}...')
		w.toast(' ${desc}...')

		go fn [mut w, bin_path, args, desc] () {
			t0 := time.ticks()
			res := simplegui.exec_safe(bin_path, args)
			elapsed_ms := time.ticks() - t0

			w.run_on_main_thread(fn [res, elapsed_ms, desc] (mut win_main simplegui.SimpleWindow) {
				out := res.output.trim_space()
				win_main.set('txt_docker_output', out)

				lines_cnt := if out != '' { out.split_into_lines().len } else { 0 }
				if res.exit_code == 0 {
					win_main.append_console('docker_console', ' ${desc} completed in ${elapsed_ms} ms (${lines_cnt} lines output).\n', 4)
					win_main.set('lbl_stats', ' Stats: SUCCESS  |  Action: ${desc}  |  Lines: ${lines_cnt}  |  Duration: ${elapsed_ms} ms')
					win_main.set_status('${desc} complete.')
					win_main.toast('${desc} complete!')
				} else {
					win_main.append_console('docker_console', ' Docker Notice / Error (Exit ${res.exit_code}):\n' + out + '\n', 3)
					win_main.set('lbl_stats', ' Stats: NOTICE (Exit ${res.exit_code})  |  Duration: ${elapsed_ms} ms')
					win_main.set_status('${desc} finished.')
				}
			})
		}()
	}

	// -------------------------------------------------------------
	// Event Handlers
	// -------------------------------------------------------------

	// List Active Containers
	win.on_click('btn_list_containers', fn [run_docker_cmd] (mut w simplegui.SimpleWindow) {
		run_docker_cmd(mut w, 'List Active Containers', ['ps', '--format', 'table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}\t{{.Names}}'])
	})

	// List All Containers
	win.on_click('btn_list_all_containers', fn [run_docker_cmd] (mut w simplegui.SimpleWindow) {
		run_docker_cmd(mut w, 'List All Containers (ps -a)', ['ps', '-a', '--format', 'table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}'])
	})

	// List Images
	win.on_click('btn_list_images', fn [run_docker_cmd] (mut w simplegui.SimpleWindow) {
		run_docker_cmd(mut w, 'List Local Images', ['images', '--format', 'table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedSince}}'])
	})

	// Container Stats
	win.on_click('btn_container_stats', fn [run_docker_cmd] (mut w simplegui.SimpleWindow) {
		run_docker_cmd(mut w, 'Container Resource Usage', ['stats', '--no-stream', '--format', 'table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}'])
	})

	// Volumes
	win.on_click('btn_volume_ls', fn [run_docker_cmd] (mut w simplegui.SimpleWindow) {
		run_docker_cmd(mut w, 'List Volumes', ['volume', 'ls'])
	})

	// Networks
	win.on_click('btn_network_ls', fn [run_docker_cmd] (mut w simplegui.SimpleWindow) {
		run_docker_cmd(mut w, 'List Networks', ['network', 'ls'])
	})

	// Start Container
	win.on_click('btn_start_cnt', fn [run_docker_cmd] (mut w simplegui.SimpleWindow) {
		target := w.get('txt_target_id').trim_space()
		if target == '' {
			w.alert('Target Required', 'Please enter a container ID or name.')
			return
		}
		run_docker_cmd(mut w, 'Start Container "${target}"', ['start', target])
	})

	// Stop Container
	win.on_click('btn_stop_cnt', fn [run_docker_cmd] (mut w simplegui.SimpleWindow) {
		target := w.get('txt_target_id').trim_space()
		if target == '' {
			w.alert('Target Required', 'Please enter a container ID or name.')
			return
		}
		run_docker_cmd(mut w, 'Stop Container "${target}"', ['stop', target])
	})

	// Restart Container
	win.on_click('btn_restart_cnt', fn [run_docker_cmd] (mut w simplegui.SimpleWindow) {
		target := w.get('txt_target_id').trim_space()
		if target == '' {
			w.alert('Target Required', 'Please enter a container ID or name.')
			return
		}
		run_docker_cmd(mut w, 'Restart Container "${target}"', ['restart', target])
	})

	// View Logs
	win.on_click('btn_view_logs', fn [run_docker_cmd] (mut w simplegui.SimpleWindow) {
		target := w.get('txt_target_id').trim_space()
		if target == '' {
			w.alert('Target Required', 'Please enter a container ID or name.')
			return
		}
		run_docker_cmd(mut w, 'Logs for "${target}"', ['logs', '--tail', '100', target])
	})

	// Prune System
	win.on_click('btn_system_prune', fn [run_docker_cmd] (mut w simplegui.SimpleWindow) {
		if !w.confirm('Prune Docker System', 'Remove all stopped containers, unused networks, and dangling images?') {
			return
		}
		run_docker_cmd(mut w, 'Prune Docker System', ['system', 'prune', '-f'])
	})

	win.start()
}

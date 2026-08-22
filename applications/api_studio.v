module main

import os
import time
import simplegui

// Helper to find curl path
fn get_curl_bin() string {
	if path := os.find_abs_path_of_executable('curl') {
		return path
	}
	common_paths := [
		'/opt/homebrew/bin/curl',
		'/usr/local/bin/curl',
		'/usr/bin/curl',
		'/bin/curl',
	]
	for p in common_paths {
		if os.exists(p) {
			return p
		}
	}
	return 'curl'
}

const sample_request_body = '{
  "title": "SimpleGUI Test Post",
  "body": "Native macOS GUI workstation testing via curl",
  "userId": 1
}'

fn main() {
	println('Starting SimpleGUI - API Studio Pro (REST API Client & Curl Workbench)...')

	mut win := simplegui.new_simple_window('SimpleGUI - API Studio Pro', 1060, 940)
	win.set_fullscreen(true)
	win.set_spacing(8)
	win.set_padding(16)

	saved_theme := simplegui.get_saved_theme()
	win.set_theme(saved_theme)

	// Top Banner / Diagnostics
	win.begin_row('row_api_top')
	win.add_heading('API Studio Pro')
	win.add_label('lbl_theme', 'Theme:')
	win.add_dropdown('dd_app_theme', simplegui.list_themes(), saved_theme)
	win.set_control_width('dd_app_theme', 160)
	win.end_row()

	win.on_change('dd_app_theme', fn (mut w simplegui.SimpleWindow, selected string) {
		w.set_theme(selected)
		w.toast('Theme changed to ${selected}')
	})

	curl_path := get_curl_bin()
	win.add_label('lbl_engine_info', 'Engine: ${curl_path}  |  Platform: macOS  |  Mode: Async Non-Blocking Worker')

	// Request URL & Method Bar
	win.begin_group_box('grp_request_url', 'Target Endpoint & HTTP Method')
	
	win.begin_row('row_url_bar')
	win.add_label('lbl_method', 'Method:')
	win.add_dropdown('dd_http_method', [
		'GET',
		'POST',
		'PUT',
		'PATCH',
		'DELETE',
		'HEAD',
		'OPTIONS'
	], 'GET')
	win.set_control_width('dd_http_method', 110)

	win.add_label('lbl_url', 'URL:')
	win.add_input('txt_url', 'https://jsonplaceholder.typicode.com/posts/1')
	win.set_control_width('txt_url', 420)

	win.add_label('lbl_templates', 'Presets:')
	win.add_dropdown('dd_api_presets', [
		'1. JSONPlaceholder GET Post',
		'2. JSONPlaceholder POST Create',
		'3. HTTPBin GET Headers & IP',
		'4. HTTPBin POST JSON Echo',
		'5. GitHub Public API (User Info)',
		'6. CoinGecko Crypto Ticker (BTC)',
		'7. IPInfo Geolocation Query',
		'8. Cat Facts Random API'
	], '1. JSONPlaceholder GET Post')
	win.set_control_width('dd_api_presets', 210)
	win.end_row()

	win.begin_row('row_options_bar')
	win.add_label('lbl_timeout', 'Timeout (s):')
	win.add_input('txt_timeout', '15')
	win.set_control_width('txt_timeout', 45)

	win.add_checkbox('chk_follow_redirects', 'Follow Redirects (-L)', true)
	win.add_checkbox('chk_include_headers', 'Show Resp Headers (-i)', true)
	win.add_checkbox('chk_insecure_ssl', 'Insecure SSL (-k)', false)
	win.add_checkbox('chk_silent', 'Silent Mode (-s)', true)
	win.end_row()

	win.end_group_box()

	// Request Configuration: Headers & Body
	win.begin_grid('grid_req_config', 2, 8)
	win.add_form_textarea('Request Headers (Key: Value):', 'txt_headers', 'Accept: application/json\nContent-Type: application/json\nUser-Agent: SimpleGUI-API-Studio/1.0')
	win.set_control_height('txt_headers', 120)

	win.add_form_textarea('Request Body (JSON / Text / Form):', 'txt_request_body', sample_request_body)
	win.set_control_height('txt_request_body', 120)
	win.end_grid()

	// Execution Actions Bar
	win.begin_row('row_actions')
	win.add_button('btn_send_request', 'Send HTTP Request')
	win.add_button('btn_copy_curl', 'Copy as cURL Command')
	win.add_button('btn_copy_response', 'Copy Response Body')
	win.add_button('btn_save_response', 'Save Response As...')
	win.add_button('btn_clear_response', 'Clear Response')
	win.end_row()

	// Response Viewer
	win.begin_group_box('grp_response', 'HTTP Response & Telemetry')
	win.add_textarea('txt_response_output', '')
	win.set_control_height('txt_response_output', 280)
	win.end_group_box()

	// Activity & Diagnostics Console
	win.begin_group_box('grp_console', 'Request Telemetry & Curl Debug Log')
	win.add_console('api_console', 100)
	win.end_group_box()

	// Status Row
	win.begin_row('row_stats')
	win.add_label('lbl_stats', 'Stats: Ready  |  Status: None  |  Latency: 0 ms  |  Size: 0 bytes')
	win.end_row()

	win.append_console('api_console', ' API Studio Pro initialized.\n', 1)
	win.append_console('api_console', ' Ready to dispatch HTTP/REST requests.\n', 4)

	// -------------------------------------------------------------
	// Event Handlers
	// -------------------------------------------------------------

	// Presets Handler
	win.on_change('dd_api_presets', fn (mut w simplegui.SimpleWindow, selected string) {
		if selected.starts_with('1.') {
			w.set('dd_http_method', 'GET')
			w.set('txt_url', 'https://jsonplaceholder.typicode.com/posts/1')
			w.set('txt_request_body', '')
		} else if selected.starts_with('2.') {
			w.set('dd_http_method', 'POST')
			w.set('txt_url', 'https://jsonplaceholder.typicode.com/posts')
			w.set('txt_request_body', sample_request_body)
		} else if selected.starts_with('3.') {
			w.set('dd_http_method', 'GET')
			w.set('txt_url', 'https://httpbin.org/headers')
			w.set('txt_request_body', '')
		} else if selected.starts_with('4.') {
			w.set('dd_http_method', 'POST')
			w.set('txt_url', 'https://httpbin.org/post')
			w.set('txt_request_body', sample_request_body)
		} else if selected.starts_with('5.') {
			w.set('dd_http_method', 'GET')
			w.set('txt_url', 'https://api.github.com/users/vlang')
			w.set('txt_request_body', '')
		} else if selected.starts_with('6.') {
			w.set('dd_http_method', 'GET')
			w.set('txt_url', 'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum&vs_currencies=usd')
			w.set('txt_request_body', '')
		} else if selected.starts_with('7.') {
			w.set('dd_http_method', 'GET')
			w.set('txt_url', 'https://ipinfo.io/json')
			w.set('txt_request_body', '')
		} else if selected.starts_with('8.') {
			w.set('dd_http_method', 'GET')
			w.set('txt_url', 'https://catfact.ninja/fact')
			w.set('txt_request_body', '')
		}
		w.toast('Loaded preset: ${selected}')
	})

	// Helper to assemble curl arguments
	build_curl_args := fn (w &simplegui.SimpleWindow) ([]string, string) {
		method := w.get('dd_http_method')
		url := w.get('txt_url').trim_space()
		timeout := w.get('txt_timeout').trim_space()
		headers_raw := w.get('txt_headers')
		body := w.get('txt_request_body')

		follow_redirects := w.get('chk_follow_redirects') == 'true'
		include_headers := w.get('chk_include_headers') == 'true'
		insecure_ssl := w.get('chk_insecure_ssl') == 'true'
		silent := w.get('chk_silent') == 'true'

		mut args := []string{}
		if silent { args << '-s' }
		if include_headers { args << '-i' }
		if follow_redirects { args << '-L' }
		if insecure_ssl { args << '-k' }
		if timeout != '' && timeout != '0' { args << ['--max-time', timeout] }

		args << ['-X', method]

		// Add custom headers
		for line in headers_raw.split_into_lines() {
			trimmed := line.trim_space()
			if trimmed != '' && trimmed.contains(':') {
				args << ['-H', trimmed]
			}
		}

		// Add body if applicable
		if (method == 'POST' || method == 'PUT' || method == 'PATCH') && body.trim_space() != '' {
			args << ['--data-raw', body]
		}

		args << url
		return args, url
	}

	// Send Request Handler
	win.on_click('btn_send_request', fn [build_curl_args] (mut w simplegui.SimpleWindow) {
		url := w.get('txt_url').trim_space()
		if url == '' {
			w.alert('URL Required', 'Please enter a target HTTP/HTTPS URL.')
			return
		}

		args, target_url := build_curl_args(w)
		curl_bin := get_curl_bin()

		method := w.get('dd_http_method')
		w.append_console('api_console', ' Sending [${method}] ${target_url}...\n', 1)
		w.set_status('Sending ${method} request to ${target_url}...')

		go fn [mut w, curl_bin, args, method] () {
			t0 := time.ticks()
			res := simplegui.exec_safe(curl_bin, args)
			elapsed_ms := time.ticks() - t0

			w.run_on_main_thread(fn [res, elapsed_ms, method] (mut win_main simplegui.SimpleWindow) {
				out := res.output.trim_space()
				win_main.set('txt_response_output', out)

				// Extract status line if available
				mut status_code := '200 OK'
				for line in out.split_into_lines() {
					if line.starts_with('HTTP/') {
						parts := line.split(' ')
						if parts.len >= 2 {
							status_code = parts[1..].join(' ')
						}
					}
				}

				if res.exit_code == 0 {
					win_main.append_console('api_console', ' Response received in ${elapsed_ms} ms (${out.len} bytes)\n', 4)
					win_main.set('lbl_stats', ' Stats: SUCCESS  |  Status: ${status_code}  |  Latency: ${elapsed_ms} ms  |  Size: ${out.len} B')
					win_main.set_status('Completed ${method} in ${elapsed_ms} ms.')
					win_main.toast('Response received in ${elapsed_ms} ms!')
				} else {
					win_main.append_console('api_console', ' Curl Error (Exit ${res.exit_code}):\n' + out + '\n', 3)
					win_main.set('lbl_stats', ' Stats: ERROR (Exit ${res.exit_code})  |  Latency: ${elapsed_ms} ms')
					win_main.set_status('Request failed.')
					win_main.toast('Request error.')
				}
			})
		}()
	})

	// Copy as cURL
	win.on_click('btn_copy_curl', fn [build_curl_args] (mut w simplegui.SimpleWindow) {
		args, _ := build_curl_args(w)
		mut cmd := 'curl'
		for a in args {
			if a.contains(' ') || a.contains('"') || a.contains('\n') || a.contains('{') {
				escaped := a.replace('"', '\\"')
				cmd += ' "${escaped}"'
			} else {
				cmd += ' ' + a
			}
		}
		w.copy_to_clipboard(cmd)
		w.toast('cURL command copied to clipboard!')
		w.append_console('api_console', ' Exported cURL command to clipboard.\n', 1)
	})

	// Copy Response
	win.on_click('btn_copy_response', fn (mut w simplegui.SimpleWindow) {
		resp := w.get('txt_response_output')
		if resp != '' {
			w.copy_to_clipboard(resp)
			w.toast('Response copied to clipboard!')
		} else {
			w.toast('No response to copy.')
		}
	})

	// Save Response As
	win.on_click('btn_save_response', fn (mut w simplegui.SimpleWindow) {
		resp := w.get('txt_response_output')
		if resp.trim_space() == '' {
			w.toast('No response to save.')
			return
		}
		path := w.save_file_picker()
		if path != '' {
			os.write_file(path, resp) or {
				w.toast('Failed to save file.')
				return
			}
			w.toast('Saved to ${os.file_name(path)}')
			w.append_console('api_console', ' Saved response to: ${path}\n', 1)
		}
	})

	// Clear Response
	win.on_click('btn_clear_response', fn (mut w simplegui.SimpleWindow) {
		w.set('txt_response_output', '')
		w.clear_console('api_console')
		w.toast('Cleared response.')
	})

	win.start()
}

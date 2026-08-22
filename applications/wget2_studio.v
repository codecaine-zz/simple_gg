module main

import os
import time
import simplegui

// Helper to find wget2 or wget binary
fn get_wget2_bin() string {
	if path := os.find_abs_path_of_executable('wget2') {
		return path
	}
	common_paths := [
		'/opt/homebrew/bin/wget2',
		'/usr/local/bin/wget2',
		'/opt/homebrew/bin/wget',
		'/usr/local/bin/wget',
		'/usr/bin/wget',
	]
	for p in common_paths {
		if os.exists(p) {
			return p
		}
	}
	return 'wget2'
}

fn get_default_download_dir() string {
	home := os.home_dir()
	dl_dir := os.join_path(home, 'Downloads', 'Wget2_Downloads')
	if !os.exists(dl_dir) {
		os.mkdir_all(dl_dir) or {}
	}
	return dl_dir
}

fn main() {
	println('Starting SimpleGUI - Wget2 Studio Pro (High-Speed Downloader & Site Mirror)...')

	mut win := simplegui.new_simple_window('SimpleGUI - Wget2 Studio Pro', 1040, 960)
	win.set_fullscreen(true)
	win.set_spacing(8)
	win.set_padding(16)

	saved_theme := simplegui.get_saved_theme()
	win.set_theme(saved_theme)

	// Top Banner
	win.begin_row('row_wget_top')
	win.add_heading('Wget2 Studio Pro')
	win.add_label('lbl_theme', 'Theme:')
	win.add_dropdown('dd_app_theme', simplegui.list_themes(), saved_theme)
	win.set_control_width('dd_app_theme', 150)
	win.end_row()

	win.on_change('dd_app_theme', fn (mut w simplegui.SimpleWindow, selected string) {
		w.set_theme(selected)
		w.toast('Theme changed to ${selected}')
	})
	wget2_path := get_wget2_bin()
	win.add_label('lbl_engine_info', 'Engine: ${wget2_path}  |  Platform: macOS Cocoa  |  Mode: Async Multi-Threaded Worker')

	// -------------------------------------------------------------
	// Target URL & Destination Configuration
	// -------------------------------------------------------------
	win.begin_group_box('grp_target_box', 'Target URL & Destination Location')
	
	win.begin_row('row_target_url')
	win.add_label('lbl_url', 'Target URL:')
	win.add_input('txt_url', 'https://proof.ovh.net/files/100Mb.dat')
	win.set_control_width('txt_url', 520)
	win.add_button('btn_paste_url', 'Paste URL')
	win.add_button('btn_batch_file', 'Batch URLs File (-i)...')
	win.end_row()

	win.begin_row('row_dest_dir')
	win.add_label('lbl_dest_dir', 'Save Folder (-P):')
	win.add_input('txt_dest_dir', '~/Downloads/Wget2_Downloads')
	win.set_control_width('txt_dest_dir', 520)
	win.add_button('btn_choose_dir', 'Choose Folder...')
	win.add_button('btn_open_dir', 'Open in Finder')
	win.end_row()

	win.end_group_box()

	// -------------------------------------------------------------
	// Download Task Presets & Modes
	// -------------------------------------------------------------
	win.begin_group_box('grp_presets_box', 'Download Task Presets & Crawling Modes')
	
	win.begin_row('row_presets')
	win.add_label('lbl_preset', 'Download Preset:')
	win.add_dropdown('dd_preset', [
		' Turbo Multi-Threaded File Download (Max Speed)',
		' Complete Website Offline Mirror (--mirror)',
		' Recursive Asset Scraper (PDFs, Docs, ZIPs)',
		' Image Gallery Scraper (JPG, PNG, WebP, SVG)',
		' Resume Interrupted Download (--continue)',
		' Stealth Browser Crawl (Chrome UA + HTTP/2)'
	], ' Turbo Multi-Threaded File Download (Max Speed)')
	win.set_control_width('dd_preset', 400)

	win.add_label('lbl_threads', 'Threads (-t):')
	win.add_dropdown('dd_threads', ['1 (Single)', '2', '4', '8 (Recommended)', '16 (Max Turbo)'], '8 (Recommended)')
	win.set_control_width('dd_threads', 140)

	win.add_label('lbl_depth', 'Depth (-l):')
	win.add_input('txt_depth', '2')
	win.set_control_width('txt_depth', 50)
	win.end_row()

	win.begin_row('row_filter_options')
	win.add_label('lbl_accept', 'Accept Types (-A):')
	win.add_input('txt_accept', '')
	win.set_control_width('txt_accept', 140)

	win.add_label('lbl_reject', 'Reject Types (-R):')
	win.add_input('txt_reject', '')
	win.set_control_width('txt_reject', 120)

	win.add_label('lbl_rate', 'Rate Limit:')
	win.add_input('txt_rate_limit', '')
	win.set_control_width('txt_rate_limit', 80)

	win.add_label('lbl_ua', 'User-Agent:')
	win.add_dropdown('dd_ua', [
		'Default (Wget2)',
		'Chrome macOS',
		'Safari macOS',
		'Firefox macOS',
		'iPhone Mobile'
	], 'Chrome macOS')
	win.set_control_width('dd_ua', 130)
	win.end_row()

	win.begin_row('row_checkboxes')
	win.add_checkbox('chk_continue', 'Resume Broken (-c)', true)
	win.add_checkbox('chk_page_req', 'Page Requisites (-p)', true)
	win.add_checkbox('chk_convert_links', 'Convert Links (-k)', true)
	win.add_checkbox('chk_no_parent', 'No Parent (--no-parent)', true)
	win.add_checkbox('chk_no_check_cert', 'Ignore SSL Errors', false)
	win.end_row()

	win.end_group_box()

	// -------------------------------------------------------------
	// Execution & Live Control Bar
	// -------------------------------------------------------------
	win.begin_row('row_actions')
	win.add_button('btn_start_wget', 'Start Wget2 Download')
	win.add_button('btn_quick_100mb', 'Test 100MB Speed Test')
	win.add_button('btn_quick_1gb', 'Test 1GB Speed Test')
	win.add_button('btn_clear_log', 'Clear Log')
	win.end_row()

	// -------------------------------------------------------------
	// Live Download Activity & Console
	// -------------------------------------------------------------
	win.begin_group_box('grp_console_box', 'Live Download Activity & Transfer Telemetry')
	win.add_console('wget_console', 280)
	win.end_group_box()

	// Stats Row
	win.begin_row('row_stats')
	win.add_label('lbl_stats', 'Status: Ready  |  Active Transfers: 0  |  Duration: 0 ms')
	win.end_row()

	win.append_console('wget_console', ' Wget2 Studio Pro Initialized.\n', 1)
	win.append_console('wget_console', ' Ready for high-speed multi-threaded transfers and recursive website mirroring.\n', 4)

	// -------------------------------------------------------------
	// Event Handlers & Async Engine
	// -------------------------------------------------------------

	// Paste URL
	win.on_click('btn_paste_url', fn (mut w simplegui.SimpleWindow) {
		clip := simplegui.clipboard_text().trim_space()
		if clip != '' {
			w.set('txt_url', clip)
			w.toast('Pasted URL from clipboard.')
			w.append_console('wget_console', ' URL loaded: ' + clip + '\n', 1)
		} else {
			w.toast('Clipboard is empty.')
		}
	})

	// Load Batch URLs from File
	win.on_click('btn_batch_file', fn (mut w simplegui.SimpleWindow) {
		path := w.select_file()
		if path != '' && os.exists(path) {
			w.set('txt_url', '@' + path)
			w.toast('Loaded batch URLs file: ' + os.file_name(path))
			w.append_console('wget_console', ' Batch URLs file: ' + path + '\n', 1)
		}
	})

	// Choose Directory
	win.on_click('btn_choose_dir', fn (mut w simplegui.SimpleWindow) {
		dir := w.select_folder()
		if dir != '' && os.is_dir(dir) {
			w.set('txt_dest_dir', dir)
			w.toast('Destination directory updated.')
			w.append_console('wget_console', ' Save directory set to: ' + dir + '\n', 1)
		}
	})

	// Open in Finder
	win.on_click('btn_open_dir', fn (mut w simplegui.SimpleWindow) {
		raw_dir := w.get('txt_dest_dir').trim_space()
		mut dir := raw_dir
		if dir == '~' {
			dir = os.home_dir()
		} else if dir.starts_with('~/') {
			dir = os.join_path(os.home_dir(), dir[2..])
		}
		if dir != '' && os.is_dir(dir) {
			os.execute('open "${dir}"')
		} else {
			os.execute('open .')
		}
		w.toast('Opened folder in Finder.')
	})

	// Clear Log
	win.on_click('btn_clear_log', fn (mut w simplegui.SimpleWindow) {
		w.clear_console('wget_console')
		w.set('lbl_stats', ' Status: Ready  |  Active Transfers: 0  |  Duration: 0 ms')
	})

	// Preset Selection Change
	win.on_change('dd_preset', fn (mut w simplegui.SimpleWindow, selected string) {
		if selected.contains('Turbo Multi-Threaded') {
			w.set('txt_accept', '')
			w.set('txt_reject', '')
			w.set_text('dd_threads', '8 (Recommended)')
			w.toast('Configured for Turbo multi-threaded single/batch file download.')
		} else if selected.contains('Website Offline Mirror') {
			w.set('chk_convert_links', 'true')
			w.set('chk_page_req', 'true')
			w.set('chk_no_parent', 'true')
			w.set('txt_depth', '3')
			w.toast('Configured for full offline website mirroring.')
		} else if selected.contains('Recursive Asset Scraper') {
			w.set('txt_accept', 'pdf,epub,zip,tar.gz,docx')
			w.set('txt_depth', '3')
			w.toast('Configured to scrape documents & archives.')
		} else if selected.contains('Image Gallery Scraper') {
			w.set('txt_accept', 'jpg,jpeg,png,webp,gif,svg')
			w.set('txt_depth', '3')
			w.toast('Configured to scrape images.')
		}
	})

	// Quick 100MB Speed Test
	win.on_click('btn_quick_100mb', fn (mut w simplegui.SimpleWindow) {
		w.set('txt_url', 'https://proof.ovh.net/files/100Mb.dat')
		w.set_text('dd_preset', ' Turbo Multi-Threaded File Download (Max Speed)')
		w.toast('Loaded 100MB high-speed benchmark file.')
	})

	// Quick 1GB Speed Test
	win.on_click('btn_quick_100mb', fn (mut w simplegui.SimpleWindow) {
		w.set('txt_url', 'https://proof.ovh.net/files/1Gb.dat')
		w.set_text('dd_preset', ' Turbo Multi-Threaded File Download (Max Speed)')
		w.toast('Loaded 1GB benchmark file.')
	})

	// Start Wget2 Download (Async Non-Blocking Engine)
	win.on_click('btn_start_wget', fn (mut w simplegui.SimpleWindow) {
		url := w.get('txt_url').trim_space()
		if url == '' {
			w.alert('URL Required', 'Please provide a valid target URL or batch file.')
			return
		}

		raw_dest := w.get('txt_dest_dir').trim_space()
		mut dest_dir := raw_dest
		if dest_dir == '~' {
			dest_dir = os.home_dir()
		} else if dest_dir.starts_with('~/') {
			dest_dir = os.join_path(os.home_dir(), dest_dir[2..])
		}
		if dest_dir == '' {
			w.alert('Destination Required', 'Please specify a save folder.')
			return
		}
		if !os.exists(dest_dir) {
			os.mkdir_all(dest_dir) or {}
		}

		wget2 := get_wget2_bin()
		preset := w.get('dd_preset')
		threads_val := w.get('dd_threads').split(' ')[0]
		depth := w.get('txt_depth').trim_space()
		accept_ext := w.get('txt_accept').trim_space()
		reject_ext := w.get('txt_reject').trim_space()
		rate_limit := w.get('txt_rate_limit').trim_space()
		ua_sel := w.get('dd_ua')

		is_continue := w.get('chk_continue') == 'true'
		is_page_req := w.get('chk_page_req') == 'true'
		is_convert_links := w.get('chk_convert_links') == 'true'
		is_no_parent := w.get('chk_no_parent') == 'true'
		is_no_check_cert := w.get('chk_no_check_cert') == 'true'

		mut raw_args := []string{}

		// Save Directory
		raw_args << ['-P', dest_dir]

		// Threads
		if threads_val != '' && threads_val != '1' {
			raw_args << '--max-threads=${threads_val}'
		}

		// Preset Logic
		if preset.contains('Website Offline Mirror') {
			raw_args << '--mirror'
			if is_convert_links { raw_args << '--convert-links' }
			if is_page_req { raw_args << '--page-requisites' }
			if is_no_parent { raw_args << '--no-parent' }
			if depth != '' && depth != '0' { raw_args << '--level=${depth}' }
		} else if preset.contains('Recursive Asset') || preset.contains('Image Gallery') {
			raw_args << '-r'
			if is_no_parent { raw_args << '--no-parent' }
			if depth != '' && depth != '0' { raw_args << ['-l', depth] }
		}

		if is_continue {
			raw_args << '-c'
		}

		if accept_ext != '' {
			raw_args << ['-A', accept_ext]
		}

		if reject_ext != '' {
			raw_args << ['-R', reject_ext]
		}

		if rate_limit != '' {
			raw_args << '--limit-rate=${rate_limit}'
		}

		// User Agent selection
		if ua_sel.contains('Chrome') {
			raw_args << '--user-agent=Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36'
		} else if ua_sel.contains('Safari') {
			raw_args << '--user-agent=Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Safari/605.1.15'
		} else if ua_sel.contains('Firefox') {
			raw_args << '--user-agent=Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:128.0) Gecko/20100101 Firefox/128.0'
		} else if ua_sel.contains('iPhone') {
			raw_args << '--user-agent=Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1'
		}

		if is_no_check_cert {
			raw_args << '--no-check-certificate'
		}

		// Target (single or batch file)
		if url.starts_with('@') {
			list_path := url[1..]
			raw_args << ['-i', list_path]
		} else {
			raw_args << url
		}

		w.append_console('wget_console', ' Starting Wget2 securely in background...\n', 1)
		w.set_status('Wget2 transferring data in background...')
		w.toast('Wget2 transfer started...')
		w.set('lbl_stats', ' Status: DOWNLOADING  |  Target: ${url}  |  Threads: ${threads_val}')

		go fn [mut w, wget2, raw_args, dest_dir] () {
			t0 := time.ticks()
			res := simplegui.exec_safe(wget2, raw_args)
			elapsed_ms := time.ticks() - t0
			sec := f64(elapsed_ms) / 1000.0

			w.run_on_main_thread(fn [res, sec, dest_dir] (mut win_main simplegui.SimpleWindow) {
				if res.exit_code == 0 {
					win_main.append_console('wget_console', ' Transfer Completed Successfully in ${sec:.1f}s!\n' + res.output + '\n', 4)
					win_main.set('lbl_stats', ' Status: COMPLETED (in ${sec:.1f}s)  |  Saved in: ${dest_dir}')
					win_main.set_status('Wget2 completed in ${sec:.1f}s.')
					win_main.toast('Wget2 download completed successfully!')
				} else {
					win_main.append_console('wget_console', ' Wget2 Error:\n' + res.output + '\n', 3)
					win_main.set('lbl_stats', ' Status: ERROR (Exit code ${res.exit_code})')
					win_main.set_status('Wget2 reported an error.')
				}
			})
		}()
	})

	println('Wget2 Studio Pro configured. Starting event loop...')
	win.run()
}

module main

import os
import time
import simplegui

// Helper to find yt-dlp binary
fn get_yt_dlp_bin() string {
	if path := os.find_abs_path_of_executable('yt-dlp') {
		return path
	}
	common_paths := [
		'/opt/homebrew/bin/yt-dlp',
		'/usr/local/bin/yt-dlp',
		'/bin/yt-dlp',
	]
	for p in common_paths {
		if os.exists(p) {
			return p
		}
	}
	return 'yt-dlp'
}

fn get_default_download_dir() string {
	home := os.home_dir()
	dl_dir := os.join_path(home, 'Downloads', 'Media')
	if !os.exists(dl_dir) {
		os.mkdir_all(dl_dir) or {}
	}
	return dl_dir
}

fn main() {
	println('Starting SimpleGUI - yt-dlp Studio Pro (Media Downloader & Archiver)...')

	mut win := simplegui.new_simple_window('SimpleGUI - yt-dlp Studio Pro', 1040, 960)
	win.set_fullscreen(true)
	win.set_spacing(8)
	win.set_padding(16)

	saved_theme := simplegui.get_saved_theme()
	win.set_theme(saved_theme)

	// Top Banner
	win.begin_row('row_ytdlp_top')
	win.add_heading('yt-dlp Studio Pro')
	win.add_label('lbl_theme', 'Theme:')
	win.add_dropdown('dd_app_theme', simplegui.list_themes(), saved_theme)
	win.set_control_width('dd_app_theme', 150)
	win.end_row()

	win.on_change('dd_app_theme', fn (mut w simplegui.SimpleWindow, selected string) {
		w.set_theme(selected)
		w.toast('Theme changed to ${selected}')
	})
	ytdlp_path := get_yt_dlp_bin()
	win.add_label('lbl_engine_info', 'Engine: ${ytdlp_path}  |  Platform: macOS Cocoa  |  Mode: Async Worker (Zero UI Freezes)')

	// -------------------------------------------------------------
	// URL Input & Destination Directory
	// -------------------------------------------------------------
	win.begin_group_box('grp_url_box', 'Target Media URL & Save Location')
	
	win.begin_row('row_url')
	win.add_label('lbl_url', 'Media / Playlist URL:')
	win.add_input('txt_url', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ')
	win.set_control_width('txt_url', 520)
	win.add_button('btn_paste_url', 'Paste URL')
	win.add_button('btn_load_batch_urls', 'Batch URLs File...')
	win.end_row()

	win.begin_row('row_out_dir')
	win.add_label('lbl_out_dir', 'Save Folder:')
	win.add_input('txt_out_dir', '~/Downloads/Media')
	win.set_control_width('txt_out_dir', 520)
	win.add_button('btn_browse_out_dir', 'Choose Folder...')
	win.add_button('btn_open_folder', 'Open in Finder')
	win.end_row()

	win.end_group_box()

	// -------------------------------------------------------------
	// Format, Quality & Audio Suite Presets
	// -------------------------------------------------------------
	win.begin_group_box('grp_quality_box', 'Quality, Container & Audio Presets')
	
	win.begin_row('row_preset_sel')
	win.add_label('lbl_format_preset', 'Download Preset:')
	win.add_dropdown('dd_preset', [
		' Best Video + Best Audio (Auto MP4/MKV)',
		' 4K UHD 2160p (Best MP4)',
		' 1080p Full HD (Best MP4)',
		' 720p HD (Fast / Low Bandwidth)',
		' Audio Only: MP3 (320kbps High Quality)',
		' Audio Only: FLAC (Lossless Audio)',
		' Audio Only: AAC / M4A (256kbps Apple Native)',
		' Audio Only: Opus (Best Voice / Podcast Codec)',
		' Audio Only: WAV (Uncompressed PCM)'
	], ' Best Video + Best Audio (Auto MP4/MKV)')
	win.set_control_width('dd_preset', 380)

	win.add_label('lbl_container', 'Remux Container:')
	win.add_dropdown('dd_container', ['mp4', 'mkv', 'webm', 'mov', 'flv', 'avi'], 'mp4')
	win.set_control_width('dd_container', 90)

	win.add_label('lbl_cookies', 'Cookies From:')
	win.add_dropdown('dd_cookies', ['None', 'chrome', 'safari', 'firefox', 'brave', 'edge'], 'None')
	win.set_control_width('dd_cookies', 110)
	win.end_row()

	win.begin_row('row_extra_opts')
	win.add_checkbox('chk_embed_thumb', 'Embed Thumbnail', true)
	win.add_checkbox('chk_embed_meta', 'Embed Metadata & Chapters', true)
	win.add_checkbox('chk_embed_subs', 'Embed Subtitles (en)', false)
	win.add_checkbox('chk_auto_subs', 'Write Auto-Subs', false)
	win.add_checkbox('chk_sponsorblock', 'Remove SponsorBlock', false)
	win.end_row()

	win.begin_row('row_advanced_filter')
	win.add_label('lbl_trim_section', 'Time Slice (*00:01:00-00:03:00):')
	win.add_input('txt_time_slice', '')
	win.set_control_width('txt_time_slice', 160)

	win.add_label('lbl_speed_limit', 'Rate Limit (e.g. 5M):')
	win.add_input('txt_rate_limit', '')
	win.set_control_width('txt_rate_limit', 90)

	win.add_label('lbl_playlist_range', 'Playlist Items (1-10):')
	win.add_input('txt_playlist_range', '')
	win.set_control_width('txt_playlist_range', 90)
	win.end_row()

	win.end_group_box()

	// -------------------------------------------------------------
	// Actions & Live Execution Controls
	// -------------------------------------------------------------
	win.begin_row('row_actions')
	win.add_button('btn_start_download', 'Download Start Download')
	win.add_button('btn_inspect_formats', 'Inspect Formats & Streams (-F)')
	win.add_button('btn_fetch_metadata', 'Tip: Fetch Title & Info (JSON)')
	win.add_button('btn_update_ytdlp', 'Update yt-dlp (-U)')
	win.add_button('btn_clear_log', 'Clear Log')
	win.end_row()

	// -------------------------------------------------------------
	// Live Download Activity & Console
	// -------------------------------------------------------------
	win.begin_group_box('grp_console_box', 'Live Download Activity & Engine Telemetry')
	win.add_console('dl_console', 280)
	win.end_group_box()

	// Stats Row
	win.begin_row('row_stats')
	win.add_label('lbl_dl_stats', 'Status: Ready  |  Active Downloads: 0  |  Speed: --  |  ETA: --')
	win.end_row()

	win.append_console('dl_console', ' yt-dlp Studio Pro Initialized.\n', 1)
	win.append_console('dl_console', ' Ready to download and extract media streams from YouTube, Vimeo, Twitter, Twitch, Soundcloud, and 1,000+ sites.\n', 4)

	// -------------------------------------------------------------
	// Event Handlers & Async Engine
	// -------------------------------------------------------------

	// Paste URL
	win.on_click('btn_paste_url', fn (mut w simplegui.SimpleWindow) {
		clip := simplegui.clipboard_text().trim_space()
		if clip != '' {
			w.set('txt_url', clip)
			w.toast('Pasted URL from clipboard.')
			w.append_console('dl_console', ' URL loaded: ' + clip + '\n', 1)
		} else {
			w.toast('Clipboard is empty.')
		}
	})

	// Load Batch URLs from File
	win.on_click('btn_load_batch_urls', fn (mut w simplegui.SimpleWindow) {
		path := w.select_file()
		if path != '' && os.exists(path) {
			w.set('txt_url', '@' + path)
			w.toast('Loaded batch URLs file: ' + os.file_name(path))
			w.append_console('dl_console', ' Batch URLs file: ' + path + '\n', 1)
		}
	})

	// Browse Output Directory
	win.on_click('btn_browse_out_dir', fn (mut w simplegui.SimpleWindow) {
		dir := w.select_folder()
		if dir != '' && os.is_dir(dir) {
			w.set('txt_out_dir', dir)
			w.toast('Download destination updated.')
			w.append_console('dl_console', ' Save directory set to: ' + dir + '\n', 1)
		}
	})

	// Open in Finder
	win.on_click('btn_open_folder', fn (mut w simplegui.SimpleWindow) {
		raw_dir := w.get('txt_out_dir').trim_space()
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
		w.clear_console('dl_console')
		w.set('lbl_dl_stats', ' Status: Ready  |  Active Downloads: 0  |  Speed: --  |  ETA: --')
	})

	// Inspect Formats (-F)
	win.on_click('btn_inspect_formats', fn (mut w simplegui.SimpleWindow) {
		url := w.get('txt_url').trim_space()
		if url == '' {
			w.alert('URL Required', 'Please provide a valid video URL to inspect.')
			return
		}
		ytdlp := get_yt_dlp_bin()
		w.append_console('dl_console', ' Inspecting streams & formats securely in background...\n', 1)
		w.set_status('Inspecting stream formats in background...')
		w.toast('Inspecting stream formats...')

		go fn [mut w, ytdlp, url] () {
			res := simplegui.exec_safe(ytdlp, ['-F', url])
			w.run_on_main_thread(fn [res] (mut win_main simplegui.SimpleWindow) {
				if res.exit_code == 0 {
					win_main.append_console('dl_console', res.output + '\n', 4)
					win_main.set_status('Formats inspection completed.')
				} else {
					win_main.append_console('dl_console', ' Error inspecting formats:\n' + res.output + '\n', 3)
					win_main.set_status('Failed to inspect formats.')
				}
			})
		}()
	})

	// Fetch Metadata & Title
	win.on_click('btn_fetch_metadata', fn (mut w simplegui.SimpleWindow) {
		url := w.get('txt_url').trim_space()
		if url == '' {
			w.alert('URL Required', 'Please provide a valid video URL.')
			return
		}
		ytdlp := get_yt_dlp_bin()
		w.append_console('dl_console', ' Fetching media title & metadata in background...\n', 1)
		w.set_status('Fetching video metadata...')
		w.toast('Fetching video metadata...')

		go fn [mut w, ytdlp, url] () {
			res := simplegui.exec_safe(ytdlp, ['--print', 'title', '--print', 'duration_string', '--print', 'uploader', url])
			w.run_on_main_thread(fn [res] (mut win_main simplegui.SimpleWindow) {
				if res.exit_code == 0 {
					lines := res.output.split_into_lines()
					title := if lines.len > 0 { lines[0] } else { 'Unknown' }
					uploader := if lines.len > 2 { lines[2] } else { '' }
					dur := if lines.len > 1 { lines[1] } else { '' }
					win_main.append_console('dl_console', ' Title: ${title} | Channel: ${uploader} | Duration: ${dur}\n', 4)
					win_main.set_status('Title: ' + title)
					win_main.toast('Loaded metadata: ' + title)
				} else {
					win_main.append_console('dl_console', ' Error fetching metadata: ' + res.output + '\n', 3)
					win_main.set_status('Failed to fetch metadata.')
				}
			})
		}()
	})

	// Update yt-dlp (-U)
	win.on_click('btn_update_ytdlp', fn (mut w simplegui.SimpleWindow) {
		ytdlp := get_yt_dlp_bin()
		w.append_console('dl_console', ' Updating yt-dlp engine to latest version...\n', 1)
		w.set_status('Checking and updating yt-dlp in background...')
		w.toast('Updating yt-dlp...')

		go fn [mut w, ytdlp] () {
			res := simplegui.exec_safe(ytdlp, ['-U'])
			w.run_on_main_thread(fn [res] (mut win_main simplegui.SimpleWindow) {
				win_main.append_console('dl_console', res.output + '\n', 4)
				win_main.set_status('yt-dlp update process completed.')
				win_main.toast('yt-dlp update checked!')
			})
		}()
	})

	// Start Media Download (Async Non-Blocking Engine)
	win.on_click('btn_start_download', fn (mut w simplegui.SimpleWindow) {
		url := w.get('txt_url').trim_space()
		if url == '' {
			w.alert('URL Required', 'Please enter a valid target URL or batch file.')
			return
		}

		raw_out := w.get('txt_out_dir').trim_space()
		mut out_dir := raw_out
		if out_dir == '~' {
			out_dir = os.home_dir()
		} else if out_dir.starts_with('~/') {
			out_dir = os.join_path(os.home_dir(), out_dir[2..])
		}
		if out_dir == '' {
			w.alert('Destination Required', 'Please specify a download folder.')
			return
		}
		if !os.exists(out_dir) {
			os.mkdir_all(out_dir) or {}
		}

		preset := w.get('dd_preset')
		container := w.get('dd_container')
		cookies := w.get('dd_cookies')

		embed_thumb := w.get('chk_embed_thumb') == 'true'
		embed_meta := w.get('chk_embed_meta') == 'true'
		embed_subs := w.get('chk_embed_subs') == 'true'
		auto_subs := w.get('chk_auto_subs') == 'true'
		sponsorblock := w.get('chk_sponsorblock') == 'true'

		time_slice := w.get('txt_time_slice').trim_space()
		rate_limit := w.get('txt_rate_limit').trim_space()
		playlist_range := w.get('txt_playlist_range').trim_space()

		ytdlp := get_yt_dlp_bin()
		mut raw_args := []string{}

		// Output template
		out_tmpl := os.join_path(out_dir, '%(title)s [%(id)s].%(ext)s')
		raw_args << ['-o', out_tmpl]

		// Preset format selector
		if preset.contains('Best Video + Best Audio') {
			raw_args << ['-f', 'bv*+ba/b', '--merge-output-format', container]
		} else if preset.contains('4K UHD') {
			raw_args << ['-f', 'bv*[height<=2160]+ba/b', '--merge-output-format', container]
		} else if preset.contains('1080p') {
			raw_args << ['-f', 'bv*[height<=1080]+ba/b', '--merge-output-format', container]
		} else if preset.contains('720p') {
			raw_args << ['-f', 'bv*[height<=720]+ba/b', '--merge-output-format', container]
		} else if preset.contains('Audio Only: MP3') {
			raw_args << ['-x', '--audio-format', 'mp3', '--audio-quality', '320k']
		} else if preset.contains('Audio Only: FLAC') {
			raw_args << ['-x', '--audio-format', 'flac']
		} else if preset.contains('Audio Only: AAC') {
			raw_args << ['-x', '--audio-format', 'm4a', '--audio-quality', '256k']
		} else if preset.contains('Audio Only: Opus') {
			raw_args << ['-x', '--audio-format', 'opus']
		} else if preset.contains('Audio Only: WAV') {
			raw_args << ['-x', '--audio-format', 'wav']
		}

		if cookies != 'None' && cookies != '' {
			raw_args << ['--cookies-from-browser', cookies]
		}

		if embed_thumb {
			raw_args << '--embed-thumbnail'
		}

		if embed_meta {
			raw_args << ['--embed-metadata', '--embed-chapters']
		}

		if embed_subs {
			raw_args << ['--embed-subs', '--sub-langs', 'en.*,en']
		}

		if auto_subs {
			raw_args << ['--write-auto-subs', '--sub-langs', 'en.*,en']
		}

		if sponsorblock {
			raw_args << ['--sponsorblock-remove', 'all']
		}

		if time_slice != '' {
			raw_args << ['--download-sections', time_slice]
		}

		if rate_limit != '' {
			raw_args << ['--limit-rate', rate_limit]
		}

		if playlist_range != '' {
			if playlist_range.contains('-') {
				parts := playlist_range.split('-')
				if parts.len >= 2 {
					raw_args << ['--playlist-start', parts[0].trim_space(), '--playlist-end', parts[1].trim_space()]
				}
			} else {
				raw_args << ['--playlist-items', playlist_range]
			}
		}

		raw_args << '--newline'
		raw_args << '--no-mtime'

		// URL input (single or batch file)
		if url.starts_with('@') {
			list_path := url[1..]
			raw_args << ['-a', list_path]
		} else {
			raw_args << url
		}

		w.append_console('dl_console', ' Starting Download in background securely...\n', 1)
		w.set_status('Downloading media in background...')
		w.toast('Download started...')
		w.set('lbl_dl_stats', ' Status: DOWNLOADING  |  Target: ${url}  |  Engine: Running')

		go fn [mut w, ytdlp, raw_args, out_dir] () {
			t0 := time.ticks()
			res := simplegui.exec_safe(ytdlp, raw_args)
			elapsed_ms := time.ticks() - t0
			sec := f64(elapsed_ms) / 1000.0

			w.run_on_main_thread(fn [res, sec, out_dir] (mut win_main simplegui.SimpleWindow) {
				if res.exit_code == 0 {
					win_main.append_console('dl_console', ' Download Completed Successfully in ${sec:.1f}s!\n' + res.output + '\n', 4)
					win_main.set('lbl_dl_stats', ' Status: COMPLETED (in ${sec:.1f}s)  |  Saved in: ${out_dir}')
					win_main.set_status('Download finished in ${sec:.1f}s.')
					win_main.toast('Download finished successfully!')
				} else {
					win_main.append_console('dl_console', ' Download Error:\n' + res.output + '\n', 3)
					win_main.set('lbl_dl_stats', ' Status: ERROR (Exit code ${res.exit_code})')
					win_main.set_status('Download encountered an error.')
				}
			})
		}()
	})

	println('yt-dlp Studio Pro configured. Starting event loop...')
	win.run()
}

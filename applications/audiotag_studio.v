module main

import os
import time
import simplegui

// Helper to find ffmpeg / tag tools
fn get_ffmpeg_bin() string {
	if path := os.find_abs_path_of_executable('ffmpeg') {
		return path
	}
	common_paths := [
		'/opt/homebrew/bin/ffmpeg',
		'/usr/local/bin/ffmpeg',
		'/usr/bin/ffmpeg',
	]
	for p in common_paths {
		if os.exists(p) {
			return p
		}
	}
	return 'ffmpeg'
}

fn get_ffprobe_bin() string {
	if path := os.find_abs_path_of_executable('ffprobe') {
		return path
	}
	common_paths := [
		'/opt/homebrew/bin/ffprobe',
		'/usr/local/bin/ffprobe',
		'/usr/bin/ffprobe',
	]
	for p in common_paths {
		if os.exists(p) {
			return p
		}
	}
	return 'ffprobe'
}

fn run_probe_audio(mut w simplegui.SimpleWindow, audio_path string) {
	if audio_path == '' || !os.exists(audio_path) {
		w.alert('File Required', 'Please select a valid audio file on disk.')
		return
	}

	ffprobe_bin := get_ffprobe_bin()
	w.append_console('audio_console', ' Probing audio stream for: ${os.file_name(audio_path)}...\n', 1)
	w.set_status('Extracting audio metadata...')

	go fn [mut w, ffprobe_bin, audio_path] () {
		t0 := time.ticks()
		res := simplegui.exec_safe(ffprobe_bin, [
			'-v', 'quiet',
			'-print_format', 'json',
			'-show_format',
			'-show_streams',
			audio_path
		])
		elapsed_ms := time.ticks() - t0

		w.run_on_main_thread(fn [res, elapsed_ms, audio_path] (mut win_main simplegui.SimpleWindow) {
			out := res.output.trim_space()
			win_main.set('txt_stream_info', out)

			if res.exit_code == 0 {
				win_main.append_console('audio_console', ' Audio stream probed in ${elapsed_ms} ms.\n', 4)
				win_main.set('lbl_stats', ' Stats: SUCCESS  |  File: ${os.file_name(audio_path)}  |  Duration: ${elapsed_ms} ms')
				win_main.set_status('Audio metadata loaded.')
				win_main.toast('Loaded ' + os.file_name(audio_path))
			} else {
				win_main.append_console('audio_console', ' Error probing audio stream.\n', 3)
			}
		})
	}()
}

fn main() {
	println('Starting SimpleGUI - Audio Tag & Lossless Studio Pro...')

	mut win := simplegui.new_simple_window('SimpleGUI - Audio Tag & Lossless Studio Pro', 1080, 950)
	win.set_fullscreen(true)
	win.set_spacing(8)
	win.set_padding(16)

	saved_theme := simplegui.get_saved_theme()
	win.set_theme(saved_theme)

	// Top Banner / Diagnostics
	win.begin_row('row_audio_top')
	win.add_heading('Audio Tag & Lossless Studio Pro')
	win.add_label('lbl_theme', 'Theme:')
	win.add_dropdown('dd_app_theme', simplegui.list_themes(), saved_theme)
	win.set_control_width('dd_app_theme', 150)
	win.end_row()

	win.on_change('dd_app_theme', fn (mut w simplegui.SimpleWindow, selected string) {
		w.set_theme(selected)
		w.toast('Theme changed to ${selected}')
	})

	ff_path := get_ffmpeg_bin()
	win.add_label('lbl_engine_info', 'Engine: ${ff_path} (FFmpeg & macOS CoreAudio)  |  Platform: macOS Cocoa')

	// File Selection Bar
	win.begin_group_box('grp_file_scope', 'Target Audio File (MP3, FLAC, M4A, AAC, WAV, OGG, AIFF)')
	
	win.begin_row('row_file_bar')
	win.add_label('lbl_audio_file', 'Audio File:')
	win.add_input('txt_audio_path', '')
	win.set_control_width('txt_audio_path', 400)

	win.add_button('btn_select_audio', 'Open Audio...')
	win.add_button('btn_inspect_tags', 'Inspect Metadata')
	win.add_button('btn_play_audio', 'Play Track (afplay)')
	win.add_button('btn_stop_audio', 'Stop')
	win.end_row()

	win.end_group_box()

	// Tag Fields Editor
	win.begin_group_box('grp_tags_editor', 'Audio Tag & Metadata Fields')
	
	win.begin_row('row_tags_1')
	win.add_label('lbl_title', 'Track Title:')
	win.add_input('txt_title', '')
	win.set_control_width('txt_title', 280)

	win.add_label('lbl_artist', 'Artist:')
	win.add_input('txt_artist', '')
	win.set_control_width('txt_artist', 240)

	win.add_label('lbl_album', 'Album:')
	win.add_input('txt_album', '')
	win.set_control_width('txt_album', 240)
	win.end_row()

	win.begin_row('row_tags_2')
	win.add_label('lbl_genre', 'Genre:')
	win.add_dropdown('dd_genre', [
		'Electronic',
		'Synthwave',
		'Lo-Fi / Chillhop',
		'Ambient',
		'Rock',
		'Jazz',
		'Classical',
		'Hip Hop',
		'Pop',
		'Soundtrack / OST',
		'Podcast',
		'Audiobook',
		'Other / Custom'
	], 'Electronic')
	win.set_control_width('dd_genre', 180)

	win.add_label('lbl_year', 'Year:')
	win.add_input('txt_year', '2026')
	win.set_control_width('txt_year', 70)

	win.add_label('lbl_track', 'Track #:')
	win.add_input('txt_track_num', '1')
	win.set_control_width('txt_track_num', 50)

	win.add_label('lbl_comment', 'Comment:')
	win.add_input('txt_comment', '')
	win.set_control_width('txt_comment', 240)
	win.end_row()

	win.begin_row('row_tag_actions')
	win.add_button('btn_write_tags', 'Save Tags to Audio File')
	win.add_button('btn_extract_cover', 'Extract Album Cover Art')
	win.add_button('btn_strip_tags', 'Strip All Audio Tags')
	win.add_button('btn_copy_info', 'Copy Audio Info')
	win.add_button('btn_clear_all', 'Clear Fields')
	win.end_row()

	win.end_group_box()

	// Audio Stream & Metadata Details Output
	win.begin_group_box('grp_stream_info', 'Technical Audio Stream & Format Telemetry')
	win.add_textarea('txt_stream_info', '')
	win.set_control_height('txt_stream_info', 280)
	win.end_group_box()

	// Activity Log Console
	win.begin_group_box('grp_console', 'Audio Tag Studio Activity Log')
	win.add_console('audio_console', 100)
	win.end_group_box()

	// Status Row
	win.begin_row('row_stats')
	win.add_label('lbl_stats', 'Stats: Ready  |  Bitrate: None  |  Sample Rate: None  |  Channels: None')
	win.end_row()

	win.append_console('audio_console', ' Audio Tag & Lossless Studio Pro Initialized.\n', 1)
	win.append_console('audio_console', ' Ready to inspect and edit ID3v2, Vorbis, and MP4 tags.\n', 4)

	// -------------------------------------------------------------
	// Event Handlers
	// -------------------------------------------------------------

	// Select Audio Picker
	win.on_click('btn_select_audio', fn (mut w simplegui.SimpleWindow) {
		path := w.select_file()
		if path != '' && os.exists(path) {
			w.set('txt_audio_path', path)
			run_probe_audio(mut w, path)
		}
	})

	// Inspect Metadata Action
	win.on_click('btn_inspect_tags', fn (mut w simplegui.SimpleWindow) {
		path := w.get('txt_audio_path').trim_space()
		run_probe_audio(mut w, path)
	})

	// Play Audio via macOS afplay (Non-blocking async worker)
	win.on_click('btn_play_audio', fn (mut w simplegui.SimpleWindow) {
		path := w.get('txt_audio_path').trim_space()
		if path == '' || !os.exists(path) {
			w.alert('File Required', 'Please select an audio file to play.')
			return
		}
		w.toast('Playing: ' + os.file_name(path))
		w.append_console('audio_console', ' Playing audio track via afplay: ${path}\n', 4)
		w.set_status('Playing audio: ' + os.file_name(path))

		go fn [mut w, path] () {
			os.execute('killall afplay 2>/dev/null')
			simplegui.exec_safe('/usr/bin/afplay', [path])
			w.run_on_main_thread(fn (mut win_main simplegui.SimpleWindow) {
				win_main.set_status('Playback finished.')
			})
		}()
	})

	// Stop Audio (Non-blocking async worker)
	win.on_click('btn_stop_audio', fn (mut w simplegui.SimpleWindow) {
		w.toast('Audio playback stopped.')
		w.append_console('audio_console', ' Audio stopped.\n', 1)
		w.set_status('Audio stopped.')

		go fn () {
			os.execute('killall afplay 2>/dev/null')
		}()
	})

	// Write Tags Handler
	win.on_click('btn_write_tags', fn (mut w simplegui.SimpleWindow) {
		path := w.get('txt_audio_path').trim_space()
		if path == '' || !os.exists(path) {
			w.alert('File Required', 'Please select an audio file to edit.')
			return
		}

		title := w.get('txt_title').trim_space()
		artist := w.get('txt_artist').trim_space()
		album := w.get('txt_album').trim_space()
		year := w.get('txt_year').trim_space()
		genre := w.get('dd_genre')
		track := w.get('txt_track_num').trim_space()
		comment := w.get('txt_comment').trim_space()

		ffmpeg_bin := get_ffmpeg_bin()
		ext := os.file_ext(path)
		tmp_out := os.join_path(os.temp_dir(), 'tagged_${time.ticks()}${ext}')

		mut args := ['-y', '-i', path, '-codec', 'copy']
		if title != '' {
			args << '-metadata'
			args << 'title=' + title
		}
		if artist != '' {
			args << '-metadata'
			args << 'artist=' + artist
		}
		if album != '' {
			args << '-metadata'
			args << 'album=' + album
		}
		if year != '' {
			args << '-metadata'
			args << 'date=' + year
		}
		if genre != '' {
			args << '-metadata'
			args << 'genre=' + genre
		}
		if track != '' {
			args << '-metadata'
			args << 'track=' + track
		}
		if comment != '' {
			args << '-metadata'
			args << 'comment=' + comment
		}
		args << tmp_out

		w.append_console('audio_console', ' Writing metadata tags...\n', 1)
		w.set_status('Saving tags...')

		go fn [mut w, ffmpeg_bin, args, tmp_out, path] () {
			res := simplegui.exec_safe(ffmpeg_bin, args)
			w.run_on_main_thread(fn [res, tmp_out, path] (mut win_main simplegui.SimpleWindow) {
				if res.exit_code == 0 && os.exists(tmp_out) {
					os.rm(path) or {}
					os.cp(tmp_out, path) or {}
					os.rm(tmp_out) or {}

					win_main.append_console('audio_console', ' Audio tags written successfully!\n', 4)
					win_main.toast('Tags updated!')
					run_probe_audio(mut win_main, path)
				} else {
					win_main.append_console('audio_console', ' Error writing tags: ' + res.output + '\n', 3)
					win_main.toast('Failed to write tags.')
				}
			})
		}()
	})

	// Extract Album Cover Art
	win.on_click('btn_extract_cover', fn (mut w simplegui.SimpleWindow) {
		path := w.get('txt_audio_path').trim_space()
		if path == '' || !os.exists(path) {
			w.alert('File Required', 'Please select an audio file first.')
			return
		}

		save_path := w.save_file_picker()
		if save_path != '' {
			mut save_file := save_path
			if !save_file.ends_with('.jpg') && !save_file.ends_with('.png') {
				save_file += '.jpg'
			}
			ffmpeg_bin := get_ffmpeg_bin()
			res := simplegui.exec_safe(ffmpeg_bin, ['-y', '-i', path, '-an', '-vcodec', 'copy', save_file])
			if res.exit_code == 0 && os.exists(save_file) {
				w.toast('Cover art extracted to ' + os.file_name(save_file))
				w.append_console('audio_console', ' Album cover art saved: ${save_file}\n', 4)
			} else {
				w.alert('No Cover Art', 'No embedded artwork found in this audio file.')
			}
		}
	})

	// Strip Tags
	win.on_click('btn_strip_tags', fn (mut w simplegui.SimpleWindow) {
		path := w.get('txt_audio_path').trim_space()
		if path == '' || !os.exists(path) {
			w.alert('File Required', 'Please select an audio file.')
			return
		}

		ffmpeg_bin := get_ffmpeg_bin()
		ext := os.file_ext(path)
		tmp_out := os.join_path(os.temp_dir(), 'clean_${time.ticks()}${ext}')

		w.append_console('audio_console', ' Stripping all metadata tags (-map_metadata -1)...\n', 1)
		w.set_status('Clearing tags...')

		go fn [mut w, ffmpeg_bin, tmp_out, path] () {
			res := simplegui.exec_safe(ffmpeg_bin, ['-y', '-i', path, '-map_metadata', '-1', '-codec', 'copy', tmp_out])
			w.run_on_main_thread(fn [res, tmp_out, path] (mut win_main simplegui.SimpleWindow) {
				if res.exit_code == 0 && os.exists(tmp_out) {
					os.rm(path) or {}
					os.cp(tmp_out, path) or {}
					os.rm(tmp_out) or {}

					win_main.append_console('audio_console', ' All tags removed.\n', 4)
					win_main.toast('Metadata removed!')
					run_probe_audio(mut win_main, path)
				} else {
					win_main.append_console('audio_console', ' Error removing tags.\n', 3)
				}
			})
		}()
	})

	// Copy Info
	win.on_click('btn_copy_info', fn (mut w simplegui.SimpleWindow) {
		info := w.get('txt_stream_info')
		if info != '' {
			w.copy_to_clipboard(info)
			w.toast('Audio stream info copied!')
		} else {
			w.toast('No audio stream info to copy.')
		}
	})

	// Clear All
	win.on_click('btn_clear_all', fn (mut w simplegui.SimpleWindow) {
		w.set('txt_audio_path', '')
		w.set('txt_title', '')
		w.set('txt_artist', '')
		w.set('txt_album', '')
		w.set('txt_comment', '')
		w.set('txt_stream_info', '')
		w.clear_console('audio_console')
		w.toast('Cleared fields.')
	})

	win.start()
}

module main

import os
import time
import simplegui

// Helper to find exiftool path
fn get_exiftool_bin() string {
	if path := os.find_abs_path_of_executable('exiftool') {
		return path
	}
	common_paths := [
		'/opt/homebrew/bin/exiftool',
		'/usr/local/bin/exiftool',
		'/usr/bin/exiftool',
	]
	for p in common_paths {
		if os.exists(p) {
			return p
		}
	}
	return 'exiftool'
}

fn main() {
	println('Starting SimpleGUI - ExifTool Metadata Studio Pro...')

	mut win := simplegui.new_simple_window('SimpleGUI - ExifTool Metadata Studio Pro', 1080, 950)
	win.set_fullscreen(true)
	win.set_spacing(8)
	win.set_padding(16)

	saved_theme := simplegui.get_saved_theme()
	win.set_theme(saved_theme)

	// Top Banner / Diagnostics
	win.begin_row('row_exif_top')
	win.add_heading('ExifTool Metadata Studio Pro')
	win.add_label('lbl_theme', 'Theme:')
	win.add_dropdown('dd_app_theme', simplegui.list_themes(), saved_theme)
	win.set_control_width('dd_app_theme', 150)
	win.end_row()

	win.on_change('dd_app_theme', fn (mut w simplegui.SimpleWindow, selected string) {
		w.set_theme(selected)
		w.toast('Theme changed to ${selected}')
	})

	exiftool_path := get_exiftool_bin()
	win.add_label('lbl_engine_info', 'Engine: ${exiftool_path}  |  Platform: macOS Cocoa  |  Mode: Async Non-Blocking')

	// Media File Selection Bar
	win.begin_group_box('grp_file_scope', 'Target Media File (JPEG, PNG, HEIC, TIFF, RAW, MP4, MOV)')
	
	win.begin_row('row_file_select')
	win.add_label('lbl_media_file', 'Media File:')
	win.add_input('txt_media_path', '')
	win.set_control_width('txt_media_path', 440)

	win.add_button('btn_select_file', 'Open Image / Video...')
	win.add_button('btn_inspect_exif', 'Inspect Metadata')
	win.add_button('btn_view_gps', 'Open GPS in Maps')
	win.end_row()

	win.end_group_box()

	// Tag Modification & Privacy Scrubber
	win.begin_group_box('grp_tag_tools', 'Privacy Scrubber & Metadata Tag Editor')
	
	win.begin_row('row_tag_inputs')
	win.add_label('lbl_artist', 'Artist / Author:')
	win.add_input('txt_artist', '')
	win.set_control_width('txt_artist', 170)

	win.add_label('lbl_copyright', 'Copyright:')
	win.add_input('txt_copyright', '')
	win.set_control_width('txt_copyright', 170)

	win.add_label('lbl_desc', 'Description / Title:')
	win.add_input('txt_description', '')
	win.set_control_width('txt_description', 220)
	win.end_row()

	win.begin_row('row_mod_actions')
	win.add_button('btn_write_tags', 'Apply Custom Tags')
	win.add_button('btn_strip_all', 'Strip All Metadata (Privacy Mode)')
	win.add_button('btn_export_json', 'Export Metadata as JSON')
	win.add_button('btn_copy_report', 'Copy Report')
	win.add_button('btn_clear_all', 'Clear')
	win.end_row()

	win.end_group_box()

	// Metadata Display Report
	win.begin_group_box('grp_metadata_view', 'EXIF / IPTC / XMP Metadata Report')
	win.add_textarea('txt_metadata_report', '')
	win.set_control_height('txt_metadata_report', 320)
	win.end_group_box()

	// Activity & Diagnostics Console
	win.begin_group_box('grp_console', 'ExifTool Activity & Operations Log')
	win.add_console('exif_console', 110)
	win.end_group_box()

	// Status Row
	win.begin_row('row_stats')
	win.add_label('lbl_stats', 'Stats: Ready  |  File: None  |  GPS: Not Detected  |  Duration: 0 ms')
	win.end_row()

	win.append_console('exif_console', ' ExifTool Metadata Studio Pro Initialized.\n', 1)
	win.append_console('exif_console', ' Select an image or video to inspect camera EXIF, GPS location, and color profiles.\n', 4)

	// -------------------------------------------------------------
	// Event Handlers
	// -------------------------------------------------------------

	// Inspect Metadata Action
	win.on_click('btn_inspect_exif', fn (mut w simplegui.SimpleWindow) {
		file_path := w.get('txt_media_path').trim_space()
		if file_path == '' || !os.exists(file_path) {
			w.alert('File Required', 'Please select a valid image or media file on disk.')
			return
		}

		exiftool_bin := get_exiftool_bin()
		w.append_console('exif_console', ' Reading EXIF metadata for: ${os.file_name(file_path)}...\n', 1)
		w.set_status('Extracting metadata...')

		go fn [mut w, exiftool_bin, file_path] () {
			t0 := time.ticks()
			res := simplegui.exec_safe(exiftool_bin, [file_path])
			elapsed_ms := time.ticks() - t0

			w.run_on_main_thread(fn [res, elapsed_ms, file_path] (mut win_main simplegui.SimpleWindow) {
				out := res.output.trim_space()
				win_main.set('txt_metadata_report', out)

				has_gps := out.contains('GPS Position') || out.contains('GPS Latitude')
				gps_status := if has_gps { 'GPS Detected ' } else { 'No GPS' }

				if res.exit_code == 0 {
					lines_cnt := if out != '' { out.split_into_lines().len } else { 0 }
					win_main.append_console('exif_console', ' Extracted ${lines_cnt} metadata tags in ${elapsed_ms} ms (${gps_status}).\n', 4)
					win_main.set('lbl_stats', ' Stats: SUCCESS  |  File: ${os.file_name(file_path)}  |  Tags: ${lines_cnt}  |  ${gps_status}  |  Duration: ${elapsed_ms} ms')
					win_main.set_status('Metadata extracted in ${elapsed_ms} ms.')
					win_main.toast('Metadata extracted successfully!')
				} else {
					win_main.append_console('exif_console', ' ExifTool Notice:\n' + out + '\n', 3)
					win_main.set('lbl_stats', ' Stats: NOTICE (Exit ${res.exit_code})  |  Duration: ${elapsed_ms} ms')
					win_main.set_status('ExifTool completed with notices.')
				}
			})
		}()
	})

	// Select File Picker
	win.on_click('btn_select_file', fn (mut w simplegui.SimpleWindow) {
		path := w.select_file()
		if path != '' && os.exists(path) {
			w.set('txt_media_path', path)
			// Trigger inspect
			exiftool_bin := get_exiftool_bin()
			res := simplegui.exec_safe(exiftool_bin, [path])
			w.set('txt_metadata_report', res.output.trim_space())
			w.toast('Loaded ' + os.file_name(path))
		}
	})

	// Open GPS in Maps
	win.on_click('btn_view_gps', fn (mut w simplegui.SimpleWindow) {
		path := w.get('txt_media_path').trim_space()
		if path == '' || !os.exists(path) {
			w.alert('File Required', 'Please select an image file first.')
			return
		}

		exiftool_bin := get_exiftool_bin()
		res := simplegui.exec_safe(exiftool_bin, ['-c', '%.6f', '-GPSPosition', '-s3', path])
		coords := res.output.trim_space()

		if coords != '' {
			clean_coords := coords.replace(' ', '+')
			maps_url := 'https://maps.apple.com/?q=${clean_coords}'
			os.execute('open "${maps_url}"')
			w.toast('Opened coordinates in Apple Maps: ${coords}')
			w.append_console('exif_console', ' GPS Coordinates: ${coords}  Launched Maps\n', 4)
		} else {
			w.alert('No GPS Found', 'This media file does not contain embedded GPS latitude/longitude metadata.')
		}
	})

	// Apply Custom Tags
	win.on_click('btn_write_tags', fn (mut w simplegui.SimpleWindow) {
		path := w.get('txt_media_path').trim_space()
		if path == '' || !os.exists(path) {
			w.alert('File Required', 'Please select an image file to modify.')
			return
		}

		artist := w.get('txt_artist').trim_space()
		copyright := w.get('txt_copyright').trim_space()
		desc := w.get('txt_description').trim_space()

		if artist == '' && copyright == '' && desc == '' {
			w.alert('No Tags', 'Please enter at least one tag (Artist, Copyright, or Description) to write.')
			return
		}

		exiftool_bin := get_exiftool_bin()
		mut args := []string{}
		args << '-overwrite_original'
		if artist != '' {
			args << '-Artist=' + artist
			args << '-By-line=' + artist
		}
		if copyright != '' {
			args << '-Copyright=' + copyright
			args << '-CopyrightNotice=' + copyright
		}
		if desc != '' {
			args << '-Description=' + desc
			args << '-ImageDescription=' + desc
			args << '-Title=' + desc
		}
		args << path

		w.append_console('exif_console', ' Writing custom EXIF/IPTC tags...\n', 1)
		w.set_status('Updating metadata...')

		go fn [mut w, exiftool_bin, args, path] () {
			res := simplegui.exec_safe(exiftool_bin, args)
			w.run_on_main_thread(fn [res, path, exiftool_bin] (mut win_main simplegui.SimpleWindow) {
				if res.exit_code == 0 {
					win_main.append_console('exif_console', ' Tags written successfully.\n', 4)
					win_main.toast('Metadata tags updated!')
					re_res := simplegui.exec_safe(exiftool_bin, [path])
					win_main.set('txt_metadata_report', re_res.output.trim_space())
				} else {
					win_main.append_console('exif_console', ' Error writing tags: ' + res.output + '\n', 3)
					win_main.toast('Failed to write tags.')
				}
			})
		}()
	})

	// Strip All Metadata (Privacy Mode)
	win.on_click('btn_strip_all', fn (mut w simplegui.SimpleWindow) {
		path := w.get('txt_media_path').trim_space()
		if path == '' || !os.exists(path) {
			w.alert('File Required', 'Please select a media file to scrub.')
			return
		}

		exiftool_bin := get_exiftool_bin()
		w.append_console('exif_console', ' Stripping ALL metadata and GPS tags (-all= -overwrite_original)...\n', 1)
		w.set_status('Scrubbing metadata...')

		go fn [mut w, exiftool_bin, path] () {
			res := simplegui.exec_safe(exiftool_bin, ['-all=', '-overwrite_original', path])
			w.run_on_main_thread(fn [res, path, exiftool_bin] (mut win_main simplegui.SimpleWindow) {
				if res.exit_code == 0 {
					win_main.append_console('exif_console', ' Privacy Scrub Complete: All EXIF/GPS metadata removed.\n', 4)
					win_main.toast('File completely scrubbed!')
					re_res := simplegui.exec_safe(exiftool_bin, [path])
					win_main.set('txt_metadata_report', re_res.output.trim_space())
				} else {
					win_main.append_console('exif_console', ' Error stripping metadata: ' + res.output + '\n', 3)
				}
			})
		}()
	})

	// Export JSON
	win.on_click('btn_export_json', fn (mut w simplegui.SimpleWindow) {
		path := w.get('txt_media_path').trim_space()
		if path == '' || !os.exists(path) {
			w.toast('Please select a media file first.')
			return
		}
		save_path := w.save_file_picker()
		if save_path != '' {
			mut save_file := save_path
			if !save_file.ends_with('.json') { save_file += '.json' }
			exiftool_bin := get_exiftool_bin()
			res := simplegui.exec_safe(exiftool_bin, ['-json', path])
			os.write_file(save_file, res.output) or {
				w.toast('Failed to save JSON.')
				return
			}
			w.toast('Saved JSON to ${os.file_name(save_file)}')
			w.append_console('exif_console', ' Exported JSON metadata to: ${save_file}\n', 1)
		}
	})

	// Copy Report
	win.on_click('btn_copy_report', fn (mut w simplegui.SimpleWindow) {
		report := w.get('txt_metadata_report')
		if report != '' {
			w.copy_to_clipboard(report)
			w.toast('Metadata report copied to clipboard!')
		} else {
			w.toast('No report to copy.')
		}
	})

	// Clear All
	win.on_click('btn_clear_all', fn (mut w simplegui.SimpleWindow) {
		w.set('txt_media_path', '')
		w.set('txt_artist', '')
		w.set('txt_copyright', '')
		w.set('txt_description', '')
		w.set('txt_metadata_report', '')
		w.clear_console('exif_console')
		w.toast('Cleared workspace.')
	})

	win.start()
}

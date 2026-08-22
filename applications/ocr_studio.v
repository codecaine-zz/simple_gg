module main

import os
import time
import simplegui

// Helper to find tesseract path
fn get_tesseract_bin() string {
	if path := os.find_abs_path_of_executable('tesseract') {
		return path
	}
	common_paths := [
		'/opt/homebrew/bin/tesseract',
		'/usr/local/bin/tesseract',
		'/usr/bin/tesseract',
	]
	for p in common_paths {
		if os.exists(p) {
			return p
		}
	}
	return 'tesseract'
}

fn main() {
	println('Starting SimpleGUI - Tesseract OCR Studio Pro (Optical Character Recognition)...')

	mut win := simplegui.new_simple_window('SimpleGUI - Tesseract OCR Studio Pro', 1080, 950)
	win.set_fullscreen(true)
	win.set_spacing(8)
	win.set_padding(16)

	saved_theme := simplegui.get_saved_theme()
	win.set_theme(saved_theme)

	// Top Banner / Diagnostics
	win.begin_row('row_ocr_top')
	win.add_heading('Tesseract OCR Studio Pro')
	win.add_label('lbl_theme', 'Theme:')
	win.add_dropdown('dd_app_theme', simplegui.list_themes(), saved_theme)
	win.set_control_width('dd_app_theme', 150)
	win.end_row()

	win.on_change('dd_app_theme', fn (mut w simplegui.SimpleWindow, selected string) {
		w.set_theme(selected)
		w.toast('Theme changed to ${selected}')
	})

	tesseract_path := get_tesseract_bin()
	win.add_label('lbl_engine_info', 'Engine: ${tesseract_path}  |  Platform: macOS Cocoa  |  Mode: Async OCR Pipeline')

	// File Selection & Language Scope
	win.begin_group_box('grp_ocr_source', 'Source Document / Image & Language Configuration')
	
	win.begin_row('row_source_input')
	win.add_label('lbl_file', 'Image / Document:')
	win.add_input('txt_image_path', '')
	win.set_control_width('txt_image_path', 380)

	win.add_button('btn_select_image', 'Open Image (PNG, JPG, TIFF, PDF)...')
	
	win.add_label('lbl_lang', 'Language (-l):')
	win.add_dropdown('dd_ocr_lang', [
		'eng (English)',
		'spa (Spanish)',
		'fra (French)',
		'deu (German)',
		'chi_sim (Simplified Chinese)',
		'chi_tra (Traditional Chinese)',
		'jpn (Japanese)',
		'rus (Russian)',
		'ita (Italian)',
		'por (Portuguese)',
		'ara (Arabic)',
		'kor (Korean)',
		'osd (Orientation & Script Detection)'
	], 'eng (English)')
	win.set_control_width('dd_ocr_lang', 200)
	win.end_row()

	win.begin_row('row_psm_bar')
	win.add_label('lbl_psm', 'Page Segmentation (--psm):')
	win.add_dropdown('dd_ocr_psm', [
		'3 - Fully automatic page segmentation (Default)',
		'6 - Single uniform block of text (Documents/Books)',
		'7 - Single text line (Banners / Headers)',
		'8 - Single word (Badges / Signage)',
		'11 - Sparse text (Receipts / Invoices / Diagrams)',
		'1 - Automatic page segmentation with OSD'
	], '3 - Fully automatic page segmentation (Default)')
	win.set_control_width('dd_ocr_psm', 380)

	win.add_label('lbl_output_format', 'Format:')
	win.add_dropdown('dd_ocr_out_fmt', [
		'Plain Text (stdout / .txt)',
		'Searchable PDF (.pdf)',
		'HOCR HTML (.hocr)',
		'TSV Tabular Positions (.tsv)'
	], 'Plain Text (stdout / .txt)')
	win.set_control_width('dd_ocr_out_fmt', 220)
	win.end_row()

	win.end_group_box()

	// Execution Actions Bar
	win.begin_row('row_actions')
	win.add_button('btn_run_ocr', 'Extract Text (Run OCR)')
	win.add_button('btn_copy_text', 'Copy Extracted Text')
	win.add_button('btn_save_txt', 'Save as Text (.txt)...')
	win.add_button('btn_save_pdf', 'Export Searchable PDF...')
	win.add_button('btn_list_langs', 'List Installed Languages')
	win.add_button('btn_clear_all', 'Clear')
	win.end_row()

	// Extracted Text View Area
	win.begin_group_box('grp_text_out', 'Extracted Document Text & Transcription')
	win.add_textarea('txt_ocr_output', '')
	win.set_control_height('txt_ocr_output', 320)
	win.end_group_box()

	// Live Activity Console
	win.begin_group_box('grp_console', 'Tesseract Activity & OCR Engine Telemetry')
	win.add_console('ocr_console', 110)
	win.end_group_box()

	// Status Row
	win.begin_row('row_stats')
	win.add_label('lbl_stats', 'Stats: Ready  |  Words: 0  |  Characters: 0  |  Duration: 0 ms')
	win.end_row()

	win.append_console('ocr_console', ' Tesseract OCR Studio Pro Initialized.\n', 1)
	win.append_console('ocr_console', ' Ready to extract text and generate searchable PDFs from scanned images.\n', 4)

	// -------------------------------------------------------------
	// Event Handlers
	// -------------------------------------------------------------

	// Select Image Picker
	win.on_click('btn_select_image', fn (mut w simplegui.SimpleWindow) {
		path := w.select_file()
		if path != '' && os.exists(path) {
			w.set('txt_image_path', path)
			w.toast('Selected ' + os.file_name(path))
			w.append_console('ocr_console', ' Target document loaded: ${path}\n', 1)
		}
	})

	// List Installed Languages
	win.on_click('btn_list_langs', fn (mut w simplegui.SimpleWindow) {
		tess_bin := get_tesseract_bin()
		res := simplegui.exec_safe(tess_bin, ['--list-langs'])
		w.append_console('ocr_console', ' Installed Tesseract Language Packs:\n' + res.output + '\n', 4)
		w.toast('Listed installed languages in console.')
	})

	// Run OCR Worker
	win.on_click('btn_run_ocr', fn (mut w simplegui.SimpleWindow) {
		img_path := w.get('txt_image_path').trim_space()
		if img_path == '' || !os.exists(img_path) {
			w.alert('Image Required', 'Please select a valid image or document file on disk.')
			return
		}

		tess_bin := get_tesseract_bin()
		lang_raw := w.get('dd_ocr_lang')
		lang := lang_raw.split(' ')[0]

		psm_raw := w.get('dd_ocr_psm')
		psm := psm_raw.split(' ')[0]

		mut args := []string{}
		args << img_path
		args << 'stdout'
		args << '-l'
		args << lang
		args << '--psm'
		args << psm

		w.append_console('ocr_console', ' Running OCR (Lang: ${lang}, PSM: ${psm}) on ${os.file_name(img_path)}...\n', 1)
		w.set_status('Extracting text with Tesseract...')
		w.toast('Extracting text...')

		go fn [mut w, tess_bin, args, img_path] () {
			t0 := time.ticks()
			res := simplegui.exec_safe(tess_bin, args)
			elapsed_ms := time.ticks() - t0

			w.run_on_main_thread(fn [res, elapsed_ms, img_path] (mut win_main simplegui.SimpleWindow) {
				out := res.output.trim_space()
				win_main.set('txt_ocr_output', out)

				words_cnt := if out != '' { out.split(' ').len } else { 0 }
				chars_cnt := out.len

				if res.exit_code == 0 {
					win_main.append_console('ocr_console', ' OCR Extraction Complete: ${words_cnt} words (${chars_cnt} chars) in ${elapsed_ms} ms.\n', 4)
					win_main.set('lbl_stats', ' Stats: SUCCESS  |  File: ${os.file_name(img_path)}  |  Words: ${words_cnt}  |  Chars: ${chars_cnt}  |  Duration: ${elapsed_ms} ms')
					win_main.set_status('OCR finished in ${elapsed_ms} ms.')
					win_main.toast('Text extracted successfully!')
				} else {
					win_main.append_console('ocr_console', ' Tesseract OCR Notice:\n' + out + '\n', 3)
					win_main.set('lbl_stats', ' Stats: NOTICE (Exit ${res.exit_code})  |  Duration: ${elapsed_ms} ms')
					win_main.set_status('OCR completed with notices.')
				}
			})
		}()
	})

	// Save Searchable PDF Action
	win.on_click('btn_save_pdf', fn (mut w simplegui.SimpleWindow) {
		img_path := w.get('txt_image_path').trim_space()
		if img_path == '' || !os.exists(img_path) {
			w.alert('Image Required', 'Please select an input image first.')
			return
		}

		save_path := w.save_file_picker()
		if save_path != '' {
			mut base_out := save_path
			if base_out.ends_with('.pdf') {
				base_out = base_out[..base_out.len - 4]
			}

			tess_bin := get_tesseract_bin()
			lang_raw := w.get('dd_ocr_lang')
			lang := lang_raw.split(' ')[0]

			w.append_console('ocr_console', ' Generating Searchable PDF: ${base_out}.pdf...\n', 1)
			w.set_status('Compiling PDF...')

			go fn [mut w, tess_bin, img_path, base_out, lang] () {
				t0 := time.ticks()
				res := simplegui.exec_safe(tess_bin, [img_path, base_out, '-l', lang, 'pdf'])
				elapsed_ms := time.ticks() - t0

				w.run_on_main_thread(fn [res, elapsed_ms, base_out] (mut win_main simplegui.SimpleWindow) {
					if res.exit_code == 0 {
						pdf_name := os.file_name(base_out) + '.pdf'
						win_main.append_console('ocr_console', ' Searchable PDF generated: ${base_out}.pdf in ${elapsed_ms} ms\n', 4)
						win_main.toast('Saved ${pdf_name}!')
						win_main.set_status('PDF saved successfully.')
					} else {
						win_main.append_console('ocr_console', ' Error compiling PDF: ' + res.output + '\n', 3)
					}
				})
			}()
		}
	})

	// Copy Text
	win.on_click('btn_copy_text', fn (mut w simplegui.SimpleWindow) {
		out := w.get('txt_ocr_output')
		if out != '' {
			w.copy_to_clipboard(out)
			w.toast('Extracted text copied to clipboard!')
		} else {
			w.toast('No extracted text to copy.')
		}
	})

	// Save Text As
	win.on_click('btn_save_txt', fn (mut w simplegui.SimpleWindow) {
		out := w.get('txt_ocr_output')
		if out.trim_space() == '' {
			w.toast('No text to save.')
			return
		}
		path := w.save_file_picker()
		if path != '' {
			mut save_file := path
			if !save_file.ends_with('.txt') { save_file += '.txt' }
			os.write_file(save_file, out) or {
				w.toast('Failed to save file.')
				return
			}
			w.toast('Saved text to ${os.file_name(save_file)}')
			w.append_console('ocr_console', ' Saved document text: ${save_file}\n', 1)
		}
	})

	// Clear All
	win.on_click('btn_clear_all', fn (mut w simplegui.SimpleWindow) {
		w.set('txt_image_path', '')
		w.set('txt_ocr_output', '')
		w.clear_console('ocr_console')
		w.toast('Cleared OCR workspace.')
	})

	win.start()
}

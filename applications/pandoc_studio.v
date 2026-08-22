module main

import os
import time
import simplegui

// Helper to find pandoc binary
fn get_pandoc_bin() string {
	if path := os.find_abs_path_of_executable('pandoc') {
		return path
	}
	common_paths := [
		'/opt/homebrew/bin/pandoc',
		'/usr/local/bin/pandoc',
		'/bin/pandoc',
	]
	for p in common_paths {
		if os.exists(p) {
			return p
		}
	}
	return 'pandoc'
}

fn get_sample_markdown() string {
	return '---
title: "Universal Document Publishing with Pandoc"
author: "Engineering Team"
date: "August 2026"
---

# Introduction

Pandoc is the Swiss-army knife for converting between markup formats.

## Key Features

- **Multi-format Support**: Markdown, HTML, LaTeX, Docx, EPUB, PDF, Typst
- **Math Support**: $\\int_{a}^{b} f(x) dx = F(b) - F(a)$ and $E = mc^2$
- **Code Highlighting**: Full syntax highlighting for 100+ languages

```v
fn main() {
    println("Hello from Native V SimpleGUI!")
}
```

## Data Table

| Feature | Support | Performance |
| :--- | :---: | :--- |
| PDF Export |  Yes | Instant |
| Word Docx |  Yes | High Fidelity |
| EPUB eBook |  Yes | Standalone |

> "Simplicity is prerequisite for reliability." -- Edsger W. Dijkstra
'
}

fn main() {
	println('Starting SimpleGUI - Pandoc Studio Pro (Universal Document Converter)...')

	mut win := simplegui.new_simple_window('SimpleGUI - Pandoc Studio Pro', 1040, 960)
	win.set_fullscreen(true)
	win.set_spacing(8)
	win.set_padding(16)

	saved_theme := simplegui.get_saved_theme()
	win.set_theme(saved_theme)

	// Top Banner
	win.begin_row('row_pandoc_top')
	win.add_heading('Pandoc Studio Pro')
	win.add_label('lbl_theme', 'Theme:')
	win.add_dropdown('dd_app_theme', simplegui.list_themes(), saved_theme)
	win.set_control_width('dd_app_theme', 150)
	win.end_row()

	win.on_change('dd_app_theme', fn (mut w simplegui.SimpleWindow, selected string) {
		w.set_theme(selected)
		w.toast('Theme changed to ${selected}')
	})
	pandoc_path := get_pandoc_bin()
	win.add_label('lbl_engine_info', 'Engine: ${pandoc_path}  |  Platform: macOS Cocoa  |  Mode: Async Worker (Zero UI Freezes)')

	// -------------------------------------------------------------
	// Format Selection & Transformation Matrix
	// -------------------------------------------------------------
	win.begin_group_box('grp_format_box', 'Format Conversion Matrix & Publishing Presets')
	
	win.begin_row('row_formats')
	win.add_label('lbl_from', 'Input Format (-f):')
	win.add_dropdown('dd_from', [
		'markdown (GitHub Flavored)',
		'markdown_strict',
		'commonmark',
		'html',
		'latex',
		'rst (reStructuredText)',
		'org (Emacs Org-mode)',
		'textile',
		'mediawiki',
		'typst',
		'json (Pandoc AST)'
	], 'markdown (GitHub Flavored)')
	win.set_control_width('dd_from', 230)

	win.add_label('lbl_to', 'Output Format (-t):')
	win.add_dropdown('dd_to', [
		'html5 (Modern HTML)',
		'markdown (Clean MD)',
		'latex (TeX Document)',
		'typst (Typst Document)',
		'docx (MS Word Document)',
		'epub (EPUB 3 eBook)',
		'pptx (PowerPoint Slides)',
		'revealjs (HTML5 Slides)',
		'beamer (LaTeX Slides)',
		'plain (Clean Text)',
		'man (Unix Man Page)',
		'rtf (Rich Text Format)',
		'json (AST Structure)'
	], 'html5 (Modern HTML)')
	win.set_control_width('dd_to', 220)

	win.add_label('lbl_highlight', 'Syntax Theme:')
	win.add_dropdown('dd_theme', [
		'pygments',
		'tango',
		'espresso',
		'zenburn',
		'kate',
		'monochrome',
		'breezeDark'
	], 'pygments')
	win.set_control_width('dd_theme', 110)
	win.end_row()

	win.begin_row('row_toggles')
	win.add_checkbox('chk_standalone', 'Standalone (-s)', true)
	win.add_checkbox('chk_toc', 'Table of Contents (--toc)', true)
	win.add_checkbox('chk_number_sec', 'Number Sections (-N)', false)
	win.add_checkbox('chk_embed_res', 'Embed CSS/Resources', true)
	win.add_checkbox('chk_mathjax', 'MathJax Math (--mathjax)', true)
	win.end_row()

	win.end_group_box()

	// -------------------------------------------------------------
	// Dual Pane: Input Document & Output Preview
	// -------------------------------------------------------------
	win.begin_group_box('grp_input_pane', 'Input Document (Markdown, HTML, LaTeX, or Raw Source)')
	win.begin_row('row_in_actions')
	win.add_button('btn_load_sample', 'Load Sample Markdown')
	win.add_button('btn_load_in_file', 'Load File from Disk...')
	win.add_button('btn_paste_in', 'Paste Clipboard')
	win.add_button('btn_clear_in', 'Clear Input')
	win.end_row()
	win.add_textarea('txt_input_data', get_sample_markdown())
	win.set_control_height('txt_input_data', 150)
	win.end_group_box()

	// -------------------------------------------------------------
	// Actions & Live Execution Controls
	// -------------------------------------------------------------
	win.begin_row('row_actions')
	win.add_button('btn_convert_now', 'Convert Document')
	win.add_button('btn_copy_output', 'Copy Converted Output')
	win.add_button('btn_save_output', 'Save Output File...')
	win.add_button('btn_direct_file_pub', 'Publish File on Disk (PDF/Docx/EPUB)...')
	win.add_button('btn_clear_out', 'Clear Output')
	win.end_row()

	// -------------------------------------------------------------
	// Output Pane & Statistics Banner
	// -------------------------------------------------------------
	win.begin_group_box('grp_output_pane', 'Converted Output Stream & Publishing Preview')
	win.add_textarea('txt_output_data', '')
	win.set_control_height('txt_output_data', 160)
	win.end_group_box()

	// Stats Row
	win.begin_row('row_stats')
	win.add_label('lbl_stats', 'Stats: Ready  |  Input Length: 0  |  Output Length: 0  |  Duration: 0 ms')
	win.end_row()

	// -------------------------------------------------------------
	// Core Conversion Engine (Async Non-Blocking)
	// -------------------------------------------------------------
	execute_pandoc := fn (mut win simplegui.SimpleWindow) {
		input_text := win.get('txt_input_data')
		if input_text.trim_space() == '' {
			win.alert('Input Empty', 'Please provide a document to convert.')
			return
		}

		pandoc := get_pandoc_bin()
		from_fmt := win.get('dd_from').split(' ')[0]
		to_fmt := win.get('dd_to').split(' ')[0]
		theme := win.get('dd_theme')

		is_standalone := win.get('chk_standalone') == 'true'
		is_toc := win.get('chk_toc') == 'true'
		is_num_sec := win.get('chk_number_sec') == 'true'
		is_embed_res := win.get('chk_embed_res') == 'true'
		is_mathjax := win.get('chk_mathjax') == 'true'

		win.set_status('Converting document with Pandoc in background...')
		win.toast('Pandoc converting...')

		go fn [mut win, pandoc, from_fmt, to_fmt, theme, input_text, is_standalone, is_toc, is_num_sec, is_embed_res, is_mathjax] () {
			t0 := time.ticks()

			tmp_in := os.join_path(os.temp_dir(), 'pandoc_studio_in_${time.ticks()}.txt')
			os.write_file(tmp_in, input_text) or {}

			mut raw_args := ['-f', from_fmt, '-t', to_fmt]

			if is_standalone { raw_args << '-s' }
			if is_toc { raw_args << '--toc' }
			if is_num_sec { raw_args << '-N' }
			if is_embed_res { raw_args << '--embed-resources' }
			if is_mathjax { raw_args << '--mathjax' }
			if theme != '' && theme != 'none' { raw_args << '--highlight-style=${theme}' }

			raw_args << tmp_in

			res := simplegui.exec_safe(pandoc, raw_args)
			elapsed_ms := time.ticks() - t0

			if os.exists(tmp_in) {
				os.rm(tmp_in) or {}
			}

			win.run_on_main_thread(fn [res, elapsed_ms, from_fmt, to_fmt] (mut win_main simplegui.SimpleWindow) {
				if res.exit_code == 0 {
					out_str := res.output
					win_main.set('txt_output_data', out_str)
					win_main.set('lbl_stats', ' Stats: SUCCESS  |  ${from_fmt}  ${to_fmt}  |  Out Size: ${out_str.len} bytes  |  Duration: ${elapsed_ms} ms')
					win_main.set_status('Converted ${from_fmt} to ${to_fmt} in ${elapsed_ms} ms.')
					win_main.toast('Document converted in ${elapsed_ms} ms!')
				} else {
					win_main.set('txt_output_data', ' Pandoc Conversion Error:\n\n' + res.output)
					win_main.set('lbl_stats', ' Stats: ERROR (Exit code ${res.exit_code})  |  Duration: ${elapsed_ms} ms')
					win_main.set_status('Pandoc reported a conversion error.')
				}
			})
		}()
	}

	// -------------------------------------------------------------
	// Event Handlers
	// -------------------------------------------------------------

	// Load Sample Markdown
	win.on_click('btn_load_sample', fn (mut w simplegui.SimpleWindow) {
		w.set('txt_input_data', get_sample_markdown())
		w.set_text('dd_from', 'markdown (GitHub Flavored)')
		w.set_text('dd_to', 'html5 (Modern HTML)')
		w.toast('Loaded sample Markdown document.')
	})

	// Load File from Disk
	win.on_click('btn_load_in_file', fn (mut w simplegui.SimpleWindow) {
		path := w.select_file()
		if path != '' && os.exists(path) {
			content := os.read_file(path) or { '' }
			w.set('txt_input_data', content)
			
			// Auto-detect format from extension
			ext := os.file_ext(path).to_lower()
			if ext in ['.md', '.markdown'] {
				w.set_text('dd_from', 'markdown (GitHub Flavored)')
			} else if ext in ['.html', '.htm'] {
				w.set_text('dd_from', 'html')
			} else if ext in ['.tex', '.latex'] {
				w.set_text('dd_from', 'latex')
			} else if ext in ['.rst'] {
				w.set_text('dd_from', 'rst (reStructuredText)')
			} else if ext in ['.org'] {
				w.set_text('dd_from', 'org (Emacs Org-mode)')
			}
			w.toast('Loaded ${os.file_name(path)}')
		}
	})

	// Paste Clipboard
	win.on_click('btn_paste_in', fn (mut w simplegui.SimpleWindow) {
		clip := simplegui.clipboard_text()
		if clip != '' {
			w.set('txt_input_data', clip)
			w.toast('Pasted clipboard into editor.')
		} else {
			w.toast('Clipboard is empty.')
		}
	})

	// Clear Input
	win.on_click('btn_clear_in', fn (mut w simplegui.SimpleWindow) {
		w.set('txt_input_data', '')
		w.toast('Input cleared.')
	})

	// Clear Output
	win.on_click('btn_clear_out', fn (mut w simplegui.SimpleWindow) {
		w.set('txt_output_data', '')
		w.toast('Output cleared.')
	})

	// Copy Output
	win.on_click('btn_copy_output', fn (mut w simplegui.SimpleWindow) {
		out := w.get('txt_output_data')
		if out != '' {
			w.copy_to_clipboard(out)
			w.toast('Converted document copied to clipboard!')
		} else {
			w.toast('Output is empty.')
		}
	})

	// Save Output File
	win.on_click('btn_save_output', fn (mut w simplegui.SimpleWindow) {
		out := w.get('txt_output_data')
		if out == '' {
			w.toast('Output is empty.')
			return
		}
		path := w.save_file_picker()
		if path != '' {
			os.write_file(path, out) or {
				w.alert('Save Error', 'Failed to save file: ' + err.str())
				return
			}
			w.toast('Saved to ${path}')
		}
	})

	// Direct File-to-File Publisher (e.g. Markdown -> PDF / Docx / EPUB)
	win.on_click('btn_direct_file_pub', fn (mut w simplegui.SimpleWindow) {
		in_path := w.select_file()
		if in_path == '' || !os.exists(in_path) {
			return
		}
		out_path := w.save_file_picker()
		if out_path == '' {
			return
		}

		pandoc := get_pandoc_bin()
		theme := w.get('dd_theme')
		is_standalone := w.get('chk_standalone') == 'true'
		is_toc := w.get('chk_toc') == 'true'
		is_num_sec := w.get('chk_number_sec') == 'true'

		mut args := [pandoc, '"${in_path}"', '-o "${out_path}"']
		if is_standalone { args << '-s' }
		if is_toc { args << '--toc' }
		if is_num_sec { args << '-N' }
		if theme != '' { args << '--highlight-style=${theme}' }

		// PDF engine check
		if out_path.ends_with('.pdf') {
			if _ := os.find_abs_path_of_executable('typst') {
				args << '--pdf-engine=typst'
			} else if _ := os.find_abs_path_of_executable('xelatex') {
				args << '--pdf-engine=xelatex'
			} else if _ := os.find_abs_path_of_executable('wkhtmltopdf') {
				args << '--pdf-engine=wkhtmltopdf'
			}
		}

		cmd := args.join(' ')
		w.set_status('Publishing file directly with Pandoc...')
		w.toast('Publishing file in background...')

		go fn [mut w, cmd, out_path] () {
			t0 := time.ticks()
			res := os.execute(cmd)
			elapsed_ms := time.ticks() - t0

			w.run_on_main_thread(fn [res, out_path, elapsed_ms] (mut win_main simplegui.SimpleWindow) {
				if res.exit_code == 0 {
					sz := os.file_size(out_path)
					kb := f64(sz) / 1024.0
					win_main.set_status('Published ${os.file_name(out_path)} (${kb:.1f} KB) in ${elapsed_ms} ms.')
					win_main.toast('Published: ${os.file_name(out_path)} (${kb:.1f} KB)!')
					win_main.alert('Publish Success', 'Successfully compiled document to:\n${out_path}\n\nSize: ${kb:.1f} KB\nTime: ${elapsed_ms} ms')
				} else {
					win_main.alert('Pandoc Error', 'Error publishing file: ' + res.output)
					win_main.set_status('Error publishing file.')
				}
			})
		}()
	})

	// Convert Button
	win.on_click('btn_convert_now', fn [execute_pandoc] (mut w simplegui.SimpleWindow) {
		execute_pandoc(mut w)
	})

	println('Pandoc Studio Pro configured. Starting event loop...')
	win.run()
}

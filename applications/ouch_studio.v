module main

import simplegui
import os
import time

// -----------------------------------------------------------------------------
// Ouch Preset Recipe Struct
// -----------------------------------------------------------------------------
struct OuchRecipe {
	title       string
	category    string
	mode        string
	format_ext  string
	level_opt   string
	hidden_opt  bool
	git_opt     bool
	desc        string
}

fn get_all_ouch_recipes() []OuchRecipe {
	return [
		OuchRecipe{
			title: ' Fast Modern Zstandard Archive (.tar.zst)'
			category: 'Modern'
			mode: 'Compress'
			format_ext: '.tar.zst'
			level_opt: 'Fast (--fast)'
			hidden_opt: false
			git_opt: true
			desc: 'High-speed modern compression with incredible decompression performance.'
		},
		OuchRecipe{
			title: ' Universal Web / Linux Release Tarball (.tar.gz)'
			category: 'Standard'
			mode: 'Compress'
			format_ext: '.tar.gz'
			level_opt: 'Balanced (Default)'
			hidden_opt: true
			git_opt: true
			desc: 'Standard POSIX distribution archive for servers, Docker, and GitHub releases.'
		},
		OuchRecipe{
			title: ' Cross-Platform Compatibility ZIP (.zip)'
			category: 'Standard'
			mode: 'Compress'
			format_ext: '.zip'
			level_opt: 'Balanced (Default)'
			hidden_opt: true
			git_opt: false
			desc: 'Compatible with all versions of Windows, macOS, Android, and iOS.'
		},
		OuchRecipe{
			title: ' Maximum Cold Storage 7-Zip (.7z - Ultra Ratio)'
			category: 'High Ratio'
			mode: 'Compress'
			format_ext: '.7z'
			level_opt: 'Maximum (--slow)'
			hidden_opt: false
			git_opt: false
			desc: 'Dense, high-compression archive for cold backups and long-term storage.'
		},
		OuchRecipe{
			title: ' High-Compression Source Code Tarball (.tar.xz)'
			category: 'High Ratio'
			mode: 'Compress'
			format_ext: '.tar.xz'
			level_opt: 'Maximum (--slow)'
			hidden_opt: true
			git_opt: true
			desc: 'Smaller tarball footprint ideal for open-source releases and software packages.'
		},
		OuchRecipe{
			title: ' Rapid Single File Compressor (.zst)'
			category: 'Single File'
			mode: 'Compress'
			format_ext: '.zst'
			level_opt: 'Fast (--fast)'
			hidden_opt: false
			git_opt: false
			desc: 'Compresses a single large database or log file rapidly with Zstandard.'
		},
		OuchRecipe{
			title: ' Extract Archive into Destination Folder'
			category: 'Decompress'
			mode: 'Decompress'
			format_ext: ''
			level_opt: ''
			hidden_opt: false
			git_opt: false
			desc: 'Unpacks any archive (.zip, .tar.gz, .7z, .zst, .rar) cleanly into target folder.'
		},
		OuchRecipe{
			title: ' Inspect Archive Tree & File Layout'
			category: 'Inspect'
			mode: 'List Tree'
			format_ext: ''
			level_opt: ''
			hidden_opt: false
			git_opt: false
			desc: 'Lists internal directory structure and uncompressed file sizes without extracting.'
		}
	]
}

fn get_ouch_bin() string {
	for candidate in ['/opt/homebrew/bin/ouch', '/usr/local/bin/ouch', '/usr/bin/ouch', 'ouch'] {
		if os.exists(candidate) {
			return candidate
		}
	}
	return 'ouch'
}

fn main() {
	println('Starting SimpleGUI - Ouch Studio Pro (Universal Archive & Compression Workbench)...')

	mut win := simplegui.new_simple_window('Ouch Studio Pro -- Universal Archive & Compression Workbench', 1060, 940)
	win.set_fullscreen(true)
	win.restore_saved_theme()
	win.set_spacing(8)
	win.set_padding(16)

	ouch_bin := get_ouch_bin()
	all_recipes := get_all_ouch_recipes()

	// -------------------------------------------------------------
	// Header & Theme Selector
	// -------------------------------------------------------------
	win.begin_row('row_header')
	win.add_heading('Ouch Studio Pro')

	saved_theme := simplegui.get_saved_theme()
	win.add_dropdown('dd_theme_selector', simplegui.list_themes(), saved_theme)
	win.set_control_width('dd_theme_selector', 180)
	win.end_row()

	win.add_label('lbl_engine_info', 'Engine: ${ouch_bin} (Ouch Fast Archive Helper)  |  Formats: tar, zip, gz, 7z, xz, zst, bz2, rar, lz4  |  Async Worker')

	// -------------------------------------------------------------
	// Mode Selector & Quick Presets
	// -------------------------------------------------------------
	win.begin_group_box('grp_mode', 'Operation Mode & Production Presets')

	mut recipe_titles := ['-- Select a Fast Archive Preset --']
	for r in all_recipes {
		recipe_titles << '[${r.category}] ${r.title}'
	}

	win.begin_row('row_modes')
	win.add_label('lbl_op_mode', 'Action Mode:')
	win.add_dropdown('dd_op_mode', [
		' Compress (Create Archive)',
		' Decompress (Extract Archive)',
		' List Archive Contents (--tree)'
	], ' Compress (Create Archive)')
	win.set_control_width('dd_op_mode', 260)

	win.add_label('lbl_recipe', 'Preset Recipe:')
	win.add_dropdown('dd_recipe', recipe_titles, recipe_titles[0])
	win.set_control_width('dd_recipe', 420)
	win.add_button('btn_apply_recipe', 'Apply')
	win.end_row()

	win.begin_row('row_rec_desc')
	win.add_label('lbl_recipe_desc', 'Tip: Select Compress to package files, Decompress to extract, or List Tree to inspect.')
	win.end_row()
	win.end_group_box()

	// -------------------------------------------------------------
	// Input Source Files / Folders
	// -------------------------------------------------------------
	win.begin_group_box('grp_source', 'Input Source Files / Folders / Archives')

	win.begin_row('row_in_path')
	win.add_label('lbl_src', 'Source Path:')
	win.add_input('txt_src_path', './data')
	win.set_control_width('txt_src_path', 500)
	win.add_button('btn_pick_file', 'Pick File...')
	win.add_button('btn_pick_folder', 'Pick Folder...')
	win.add_button('btn_reveal_src', 'Reveal')
	win.end_row()
	win.end_group_box()

	// -------------------------------------------------------------
	// Destination & Format Configuration
	// -------------------------------------------------------------
	win.begin_group_box('grp_dest', 'Destination Path & Archive Format')

	win.begin_row('row_out_path')
	win.add_label('lbl_dest', 'Output Target:')
	default_archive := './archive.tar.zst'
	win.add_input('txt_dest_path', default_archive)
	win.set_control_width('txt_dest_path', 500)
	win.add_button('btn_pick_dest', 'Choose Output...')
	win.add_button('btn_reveal_dest', 'Reveal')
	win.end_row()

	win.begin_row('row_formats')
	win.add_label('lbl_fmt', 'Archive Format:')
	formats := [
		'.tar.zst (Zstandard - Blazing Fast & Modern)',
		'.tar.gz (Gzip - Universal Linux/macOS Standard)',
		'.zip (Zip - Cross-Platform Windows/Mac)',
		'.7z (7-Zip - Maximum Dense Compression)',
		'.tar.xz (XZ - High Compression Ratio)',
		'.tar.bz2 (Bzip2 Archive)',
		'.zst (Single File Zstandard)',
		'.gz (Single File Gzip)'
	]
	win.add_dropdown('dd_format', formats, formats[0])
	win.set_control_width('dd_format', 360)

	win.add_label('lbl_level', 'Compression Level:')
	win.add_dropdown('dd_level', [
		'Balanced (Default)',
		'Fast (--fast)',
		'Maximum (--slow)'
	], 'Balanced (Default)')
	win.set_control_width('dd_level', 180)
	win.end_row()

	win.begin_row('row_options')
	win.add_checkbox('chk_hidden', 'Ignore Hidden (-H)', true)
	win.add_checkbox('chk_gitignore', 'Respect .gitignore (-g)', true)
	win.add_checkbox('chk_symlinks', 'Follow Symlinks (-S)', false)
	win.add_checkbox('chk_remove_src', 'Remove Source on Decompress (-r)', false)

	win.add_label('lbl_pwd', 'Password (Optional):')
	win.add_password('txt_password', '')
	win.set_control_width('txt_password', 140)
	win.end_row()
	win.end_group_box()

	// -------------------------------------------------------------
	// Action Execution Toolbar
	// -------------------------------------------------------------
	win.begin_row('row_actions')
	win.add_button('btn_run_compress', 'Compress / Create Archive')
	win.add_button('btn_run_decompress', 'Decompress / Extract')
	win.add_button('btn_run_list', 'Inspect Archive Tree')
	win.add_button('btn_copy_cmd', 'Copy CLI Command')
	win.add_button('btn_clear_log', 'Clear Output')
	win.end_row()

	// -------------------------------------------------------------
	// Results & Activity Console
	// -------------------------------------------------------------
	win.begin_group_box('grp_results', 'Operation Log & Archive Tree Output')
	win.add_textarea('txt_log', ' Ouch Studio Pro ready. Select source path and click "Compress", "Decompress", or "Inspect Tree".\n')
	win.set_control_height('txt_log', 240)
	win.end_group_box()

	win.begin_row('row_status')
	win.add_label('lbl_status', 'Status: Ready  |  Engine: ouch  |  Platform: macOS Cocoa')
	win.end_row()

	// Helper to auto-update output path extension when format dropdown changes
	update_dest_extension := fn (mut win simplegui.SimpleWindow) {
		mode := win.get('dd_op_mode')
		if !mode.contains('Compress') {
			return
		}
		dest := win.get('txt_dest_path').trim_space()
		if dest == '' { return }

		fmt_sel := win.get('dd_format')
		mut new_ext := '.tar.zst'
		if fmt_sel.contains('.tar.gz') { new_ext = '.tar.gz' }
		else if fmt_sel.contains('.zip') { new_ext = '.zip' }
		else if fmt_sel.contains('.7z') { new_ext = '.7z' }
		else if fmt_sel.contains('.tar.xz') { new_ext = '.tar.xz' }
		else if fmt_sel.contains('.tar.bz2') { new_ext = '.tar.bz2' }
		else if fmt_sel.contains('.zst') { new_ext = '.zst' }
		else if fmt_sel.contains('.gz') { new_ext = '.gz' }

		// Strip known archive extensions
		mut base := dest
		for ext_to_strip in ['.tar.zst', '.tar.gz', '.tar.xz', '.tar.bz2', '.zip', '.7z', '.zst', '.gz', '.xz', '.bz2', '.rar'] {
			if base.ends_with(ext_to_strip) {
				base = base[..base.len - ext_to_strip.len]
				break
			}
		}
		win.set('txt_dest_path', base + new_ext)
	}

	// -------------------------------------------------------------
	// Event Handlers
	// -------------------------------------------------------------

	// Theme Switching
	win.on_change('dd_theme_selector', fn (mut w simplegui.SimpleWindow, selected string) {
		w.set_theme(selected)
		w.toast('Theme changed to ${selected}')
	})

	// Format selection change
	win.on_change('dd_format', fn [update_dest_extension] (mut w simplegui.SimpleWindow, _ string) {
		update_dest_extension(mut w)
	})

	// Source pickers
	win.on_click('btn_pick_file', fn [update_dest_extension] (mut w simplegui.SimpleWindow) {
		chosen := w.select_file()
		if chosen != '' {
			w.set('txt_src_path', chosen)
			w.toast('Source file selected.')

			mode := w.get('dd_op_mode')
			if mode.contains('Decompress') || mode.contains('List') {
				w.set('txt_dest_path', os.dir(chosen))
			} else {
				base := os.join_path(os.dir(chosen), os.file_name(chosen))
				w.set('txt_dest_path', base + '.tar.zst')
				update_dest_extension(mut w)
			}
		}
	})

	win.on_click('btn_pick_folder', fn [update_dest_extension] (mut w simplegui.SimpleWindow) {
		chosen := w.select_folder()
		if chosen != '' {
			w.set('txt_src_path', chosen)
			w.toast('Source folder selected.')

			mode := w.get('dd_op_mode')
			if mode.contains('Decompress') || mode.contains('List') {
				w.set('txt_dest_path', chosen)
			} else {
				dir_name := os.file_name(chosen)
				base := os.join_path(os.dir(chosen), dir_name)
				w.set('txt_dest_path', base + '.tar.zst')
				update_dest_extension(mut w)
			}
		}
	})

	win.on_click('btn_pick_dest', fn (mut w simplegui.SimpleWindow) {
		mode := w.get('dd_op_mode')
		if mode.contains('Decompress') {
			dir := w.select_folder()
			if dir != '' {
				w.set('txt_dest_path', dir)
				w.toast('Extraction folder set.')
			}
		} else {
			save_path := w.save_file_picker()
			if save_path != '' {
				w.set('txt_dest_path', save_path)
				w.toast('Destination archive set.')
			}
		}
	})

	win.on_click('btn_reveal_src', fn (mut w simplegui.SimpleWindow) {
		p := w.get('txt_src_path').trim_space()
		if p != '' && os.exists(p) {
			simplegui.reveal_in_finder(p)
			w.toast('Revealed in Finder.')
		}
	})

	win.on_click('btn_reveal_dest', fn (mut w simplegui.SimpleWindow) {
		p := w.get('txt_dest_path').trim_space()
		if p != '' && os.exists(p) {
			simplegui.reveal_in_finder(p)
			w.toast('Revealed in Finder.')
		} else if p != '' && os.exists(os.dir(p)) {
			simplegui.reveal_in_finder(os.dir(p))
			w.toast('Revealed parent folder in Finder.')
		}
	})

	// Recipe Selection Change
	win.on_change('dd_recipe', fn [all_recipes] (mut w simplegui.SimpleWindow, selected string) {
		for r in all_recipes {
			if selected.contains(r.title) {
				w.set('lbl_recipe_desc', 'Tip: ' + r.desc)
				break
			}
		}
	})

	// Apply Recipe
	win.on_click('btn_apply_recipe', fn [all_recipes, update_dest_extension] (mut w simplegui.SimpleWindow) {
		selected := w.get('dd_recipe')
		for r in all_recipes {
			if selected.contains(r.title) {
				if r.mode == 'Compress' {
					w.set_text('dd_op_mode', ' Compress (Create Archive)')
					for fmt_str in [
						'.tar.zst (Zstandard - Blazing Fast & Modern)',
						'.tar.gz (Gzip - Universal Linux/macOS Standard)',
						'.zip (Zip - Cross-Platform Windows/Mac)',
						'.7z (7-Zip - Maximum Dense Compression)',
						'.tar.xz (XZ - High Compression Ratio)',
						'.tar.bz2 (Bzip2 Archive)',
						'.zst (Single File Zstandard)',
						'.gz (Single File Gzip)'
					] {
						if fmt_str.starts_with(r.format_ext) {
							w.set_text('dd_format', fmt_str)
							break
						}
					}
					if r.level_opt != '' {
						w.set_text('dd_level', r.level_opt)
					}
				} else if r.mode == 'Decompress' {
					w.set_text('dd_op_mode', ' Decompress (Extract Archive)')
				} else if r.mode == 'List Tree' {
					w.set_text('dd_op_mode', ' List Archive Contents (--tree)')
				}

				w.set_checked('chk_hidden', r.hidden_opt)
				w.set_checked('chk_gitignore', r.git_opt)
				w.set('lbl_recipe_desc', 'Tip: ' + r.desc)
				update_dest_extension(mut w)
				w.toast('Applied recipe: ' + r.title)
				return
			}
		}
		w.toast('Please select a recipe first.')
	})

	// Compress Action
	win.on_click('btn_run_compress', fn [ouch_bin] (mut w simplegui.SimpleWindow) {
		src := w.get('txt_src_path').trim_space()
		dest := w.get('txt_dest_path').trim_space()

		if src == '' || !os.exists(src) {
			w.alert('Invalid Source', 'Please select an existing file or directory to compress.')
			return
		}
		if dest == '' {
			w.alert('Invalid Destination', 'Please specify an output archive path.')
			return
		}

		mut args := ['compress', '-y']
		if w.get_bool('chk_hidden') { args << '-H' }
		if w.get_bool('chk_gitignore') { args << '-g' }
		if w.get_bool('chk_symlinks') { args << '-S' }

		level := w.get('dd_level')
		if level.contains('Fast') { args << '--fast' }
		else if level.contains('Maximum') { args << '--slow' }

		pwd := w.get('txt_password').trim_space()
		if pwd != '' { args << ['-p', pwd] }

		args << src
		args << dest

		w.set('txt_log', ' Compressing ${src} -> ${dest}...\n')
		w.set_status('Compressing archive in background...')
		w.toast('Compressing archive...')

		go fn [mut w, ouch_bin, args, dest] () {
			t0 := time.ticks()
			res := simplegui.exec_safe(ouch_bin, args)
			elapsed_ms := time.ticks() - t0

			w.run_on_main_thread(fn [res, elapsed_ms, dest] (mut win_main simplegui.SimpleWindow) {
				if res.exit_code == 0 && os.exists(dest) {
					sz := os.file_size(dest)
					mb := f64(sz) / (1024.0 * 1024.0)
					msg := ' Successfully compressed archive in ${elapsed_ms} ms!\n Archive: ${dest} (${mb:.2f} MB)\n\n' + res.output
					win_main.set('txt_log', msg)
					win_main.set_status('Compression completed successfully.')
					win_main.toast('Archive created (${mb:.2f} MB)!')
				} else {
					win_main.set('txt_log', ' Compression error:\n' + res.output)
					win_main.set_status('Error compressing archive.')
				}
			})
		}()
	})

	// Decompress Action
	win.on_click('btn_run_decompress', fn [ouch_bin] (mut w simplegui.SimpleWindow) {
		src := w.get('txt_src_path').trim_space()
		dest_dir := w.get('txt_dest_path').trim_space()

		if src == '' || !os.exists(src) {
			w.alert('Invalid Archive', 'Please select an existing archive file to extract.')
			return
		}

		mut args := ['decompress', '-y']
		if dest_dir != '' && os.is_dir(dest_dir) {
			args << ['--dir', dest_dir]
		}
		if w.get_bool('chk_remove_src') { args << '-r' }
		if w.get_bool('chk_hidden') { args << '-H' }
		if w.get_bool('chk_gitignore') { args << '-g' }

		pwd := w.get('txt_password').trim_space()
		if pwd != '' { args << ['-p', pwd] }

		args << src

		w.set('txt_log', ' Decompressing ${src}...\n')
		w.set_status('Extracting archive in background...')
		w.toast('Extracting archive...')

		go fn [mut w, ouch_bin, args, src] () {
			t0 := time.ticks()
			res := simplegui.exec_safe(ouch_bin, args)
			elapsed_ms := time.ticks() - t0

			w.run_on_main_thread(fn [res, elapsed_ms, src] (mut win_main simplegui.SimpleWindow) {
				if res.exit_code == 0 {
					msg := ' Successfully extracted archive in ${elapsed_ms} ms!\n Source: ${src}\n\n' + res.output
					win_main.set('txt_log', msg)
					win_main.set_status('Decompression finished.')
					win_main.toast('Extraction completed!')
				} else {
					win_main.set('txt_log', ' Decompression error:\n' + res.output)
					win_main.set_status('Error extracting archive.')
				}
			})
		}()
	})

	// List Tree Action
	win.on_click('btn_run_list', fn [ouch_bin] (mut w simplegui.SimpleWindow) {
		src := w.get('txt_src_path').trim_space()
		if src == '' || !os.exists(src) {
			w.alert('Invalid Archive', 'Please select an existing archive file to inspect.')
			return
		}

		mut args := ['list', '--tree', '-y']
		if w.get_bool('chk_hidden') { args << '-H' }

		pwd := w.get('txt_password').trim_space()
		if pwd != '' { args << ['-p', pwd] }

		args << src

		w.set('txt_log', ' Inspecting archive structure for ${src}...\n')
		w.set_status('Listing archive tree in background...')
		w.toast('Reading archive tree...')

		go fn [mut w, ouch_bin, args, src] () {
			t0 := time.ticks()
			res := simplegui.exec_safe(ouch_bin, args)
			elapsed_ms := time.ticks() - t0

			w.run_on_main_thread(fn [res, elapsed_ms, src] (mut win_main simplegui.SimpleWindow) {
				if res.exit_code == 0 {
					mut msg := ' Archive Tree for: ${os.file_name(src)} (Retrieved in ${elapsed_ms} ms)\n'
					msg += '-----------------------------------------------------------------------------\n'
					msg += res.output
					win_main.set('txt_log', msg)
					win_main.set_status('Archive inspection complete.')
					win_main.toast('Archive tree loaded!')
				} else {
					win_main.set('txt_log', ' List error:\n' + res.output)
					win_main.set_status('Error listing archive.')
				}
			})
		}()
	})

	// Copy Shell Command
	win.on_click('btn_copy_cmd', fn [ouch_bin] (mut w simplegui.SimpleWindow) {
		mode := w.get('dd_op_mode')
		src := w.get('txt_src_path').trim_space()
		dest := w.get('txt_dest_path').trim_space()

		mut args := []string{}
		if mode.contains('Decompress') {
			args << ['decompress', '-y']
			if dest != '' && os.is_dir(dest) { args << ['--dir', dest] }
			args << src
		} else if mode.contains('List') {
			args << ['list', '--tree', '-y', src]
		} else {
			args << ['compress', '-y']
			level := w.get('dd_level')
			if level.contains('Fast') { args << '--fast' }
			else if level.contains('Maximum') { args << '--slow' }
			args << src
			args << dest
		}

		mut quoted := [ouch_bin]
		for a in args {
			quoted << simplegui.quote_arg(a)
		}
		cmd := quoted.join(' ')
		w.copy_to_clipboard(cmd)
		w.toast('Command copied to clipboard!')
	})

	// Clear Output
	win.on_click('btn_clear_log', fn (mut w simplegui.SimpleWindow) {
		w.set('txt_log', '')
		w.toast('Log cleared.')
	})

	println('Ouch Studio Pro configured. Starting event loop...')
	win.run()
}

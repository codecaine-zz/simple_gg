module main

import os
import simplegui

// Helper to find magick / convert and identify binaries
fn get_magick_bin() string {
	if path := os.find_abs_path_of_executable('magick') {
		return path
	}
	common_paths := [
		'/opt/homebrew/bin/magick',
		'/opt/homebrew/opt/imagemagick-full/bin/magick',
		'/usr/local/bin/magick',
		'/opt/homebrew/bin/convert',
		'/opt/homebrew/opt/imagemagick-full/bin/convert',
		'/usr/local/bin/convert',
	]
	for p in common_paths {
		if os.exists(p) {
			return p
		}
	}
	return 'magick'
}

fn get_identify_bin() string {
	if path := os.find_abs_path_of_executable('identify') {
		return path
	}
	common_paths := [
		'/opt/homebrew/bin/identify',
		'/opt/homebrew/opt/imagemagick-full/bin/identify',
		'/usr/local/bin/identify',
	]
	for p in common_paths {
		if os.exists(p) {
			return p
		}
	}
	return 'identify'
}

fn main() {
	println('Starting SimpleGUI - ImageMagick Studio Pro (Async Non-Blocking)...')

	mut win := simplegui.new_simple_window('SimpleGUI - ImageMagick Studio Pro', 960, 890)
	win.set_fullscreen(true)
	win.set_spacing(8)
	win.set_padding(16)

	saved_theme := simplegui.get_saved_theme()
	win.set_theme(saved_theme)

	// Top Banner & Info
	win.begin_row('row_magick_top')
	win.add_heading('ImageMagick Studio Pro')
	win.add_label('lbl_theme', 'Theme:')
	win.add_dropdown('dd_app_theme', simplegui.list_themes(), saved_theme)
	win.set_control_width('dd_app_theme', 150)
	win.end_row()

	win.on_change('dd_app_theme', fn (mut w simplegui.SimpleWindow, selected string) {
		w.set_theme(selected)
		w.toast('Theme changed to ${selected}')
	})
	magick_path := get_magick_bin()
	identify_path := get_identify_bin()
	win.add_label('lbl_engine_info', 'Engine: ${magick_path}  |  Identify: ${identify_path}')

	// -------------------------------------------------------------
	// File Selection Group
	// -------------------------------------------------------------
	win.begin_group_box('grp_files', 'Image Input & Output')
	
	// Input File Row
	win.begin_row('row_input')
	win.add_label('lbl_input', 'Input Image:')
	win.add_input('txt_input', '')
	win.set_control_width('txt_input', 500)
	win.add_button('btn_browse_in', 'Browse...')
	win.add_button('btn_identify', 'Info / EXIF')
	win.add_button('btn_batch_mode', 'Batch Folder')
	win.end_row()

	// Output File Row
	win.begin_row('row_output')
	win.add_label('lbl_output', 'Output Image:')
	win.add_input('txt_output', '')
	win.set_control_width('txt_output', 500)
	win.add_button('btn_browse_out', 'Save As...')
	win.add_button('btn_auto_out', 'Auto Name')
	win.end_row()

	win.end_group_box()

	// -------------------------------------------------------------
	// Operation Tabs (Expanded Suite)
	// -------------------------------------------------------------
	win.add_tabs('tabs_mode', [
		' Resize & Scale',
		' Web Formats & Icons',
		' Social & Presets',
		' Remove Background',
		' Crop & Shadow',
		' Filters & Enhance',
		' Text Watermark',
		' PDF & Stitching',
		' Batch Transcode',
	])

	// Tab 1: Resize & Scale
	win.begin_group_box('pane_resize', 'Image Resizing, Aspect Ratio & DPI')
	win.begin_row('row_res_1')
	win.add_label('lbl_preset_size', 'Scaling Mode:')
	win.add_dropdown('dd_res_preset', [
		'Original Size',
		'Scale 50% (Half Size)',
		'Scale 25% (Quarter Size)',
		'Scale 200% (2x Upscale)',
		'1920x1080 (FHD 16:9)',
		'1280x720 (HD 720p)',
		'3840x2160 (4K UHD)',
		'Custom Dimensions'
	], 'Original Size')
	win.add_label('lbl_dpi', 'Target DPI:')
	win.add_dropdown('dd_dpi', ['Original', '72 DPI (Web Screen)', '150 DPI (Balanced)', '300 DPI (High-Res Print)'], 'Original')
	win.end_row()

	win.begin_row('row_res_2')
	win.add_label('lbl_custom_w', 'Custom Width:')
	win.add_input('txt_custom_w', '1920')
	win.add_label('lbl_custom_h', 'Custom Height:')
	win.add_input('txt_custom_h', '1080')
	win.add_dropdown('dd_aspect_mode', ['Fit within (Preserve Aspect Ratio)', 'Exact Dimensions (Stretch)', 'Crop & Fill Center'], 'Fit within (Preserve Aspect Ratio)')
	win.end_row()
	win.end_group_box()

	// Tab 2: Modern Web Formats & Favicons
	win.begin_group_box('pane_format', 'Modern Web Formats, Favicon.ico & Privacy Optimization')
	win.begin_row('row_fmt_1')
	win.add_label('lbl_format', 'Target Format:')
	win.add_dropdown('dd_format', ['webp (Modern Web)', 'avif (Ultra High Compression)', 'jpeg (Universal)', 'png (Lossless Alpha)', 'ico (Multi-Res Favicon)', 'svg (Rasterize)', 'pdf (Single Document)', 'tiff', 'bmp'], 'webp (Modern Web)')
	win.add_label('lbl_quality', 'Quality / Compression:')
	win.add_dropdown('dd_quality', ['95% (Maximum Quality)', '85% (High Quality Web)', '75% (Standard Balance)', '60% (Compact Size)', '40% (Max Compression)'], '85% (High Quality Web)')
	win.end_row()

	win.begin_row('row_fmt_2')
	win.add_checkbox('chk_strip', 'Strip EXIF Metadata, GPS & Color Profiles (Protects privacy & saves KB)', true)
	win.add_checkbox('chk_interlace', 'Progressive Interlaced Rendering', true)
	win.end_row()
	win.end_group_box()

	// Tab 3: Social Media & Platform Presets
	win.begin_group_box('pane_social', 'Social Media, App Store & Web Banner Presets')
	win.begin_row('row_soc_1')
	win.add_label('lbl_soc_preset', 'Platform Preset:')
	win.add_dropdown('dd_soc_preset', [
		'Instagram Square Post (1:1 1080x1080)',
		'Instagram Story / Reel / TikTok (9:16 1080x1920)',
		'YouTube Video Thumbnail (16:9 1280x720)',
		'Twitter / X Post (16:9 1200x675)',
		'Twitter / X Header Banner (3:1 1500x500)',
		'Facebook Link Preview (1.91:1 1200x630)',
		'LinkedIn Background Banner (1584x396)',
		'Apple App Store Icon (1024x1024)',
		'Favicon Multi-Size ICO (16, 32, 48, 64px)'
	], 'Instagram Square Post (1:1 1080x1080)')
	win.end_row()

	win.begin_row('row_soc_2')
	win.add_checkbox('chk_pad_black', 'Pad Canvas to Aspect Ratio (Prevents cropping content)', false)
	win.end_row()
	win.end_group_box()

	// Tab 4: Background Removal & Transparency
	win.begin_group_box('pane_bg_remove', 'Magic Background Color Removal & Transparency')
	win.begin_row('row_bg_1')
	win.add_label('lbl_bg_color', 'Color to Make Transparent:')
	win.add_dropdown('dd_bg_color', ['white (Solid White Background)', 'black (Solid Black Background)', '#00ff00 (Chroma Green Screen)', '#0000ff (Chroma Blue Screen)'], 'white (Solid White Background)')
	win.add_label('lbl_fuzz', 'Color Tolerance (Fuzz):')
	win.add_dropdown('dd_fuzz', ['5% (Strict Match)', '10% (Recommended)', '20% (Broader)', '35% (Aggressive)'], '10% (Recommended)')
	win.end_row()

	win.begin_row('row_bg_2')
	win.add_checkbox('chk_trim_alpha', 'Auto-trim Transparent Margins after Background Removal', true)
	win.end_row()
	win.end_group_box()

	// Tab 5: Crop, Shadow & Frame
	win.begin_group_box('pane_crop', 'Cropping, Drop Shadows & Frame Styling')
	win.begin_row('row_crop_1')
	win.add_label('lbl_crop_w', 'Crop Width:')
	win.add_input('txt_crop_w', '800')
	win.add_label('lbl_crop_h', 'Crop Height:')
	win.add_input('txt_crop_h', '600')
	win.add_label('lbl_gravity', 'Gravity:')
	win.add_dropdown('dd_gravity', ['Center', 'North (Top)', 'South (Bottom)', 'East (Right)', 'West (Left)', 'NorthWest', 'SouthEast'], 'Center')
	win.end_row()

	win.begin_row('row_crop_2')
	win.add_checkbox('chk_dropshadow', 'Add Elegant Floating Drop Shadow (Ideal for screenshots & product mockups)', false)
	win.add_checkbox('chk_autotrim', 'Auto-trim Solid Borders (-trim)', false)
	win.end_row()
	win.end_group_box()

	// Tab 6: Filters & Artistic Enhancements
	win.begin_group_box('pane_effects', 'Artistic Filters, Color Corrections & Rotations')
	win.begin_row('row_eff_1')
	win.add_label('lbl_filter', 'Filter / Correction:')
	win.add_dropdown('dd_filter', [
		'None',
		'Auto-Level & Auto-Contrast (Magic Enhance)',
		'Normalize Color Tone',
		'Grayscale / Monochrome',
		'Sepia Tone (Warm Vintage)',
		'Gaussian Blur (Soft 0x4)',
		'Heavy Blur (Privacy / Background 0x16)',
		'Sharpen Detail',
		'Invert / Negative',
		'Charcoal Sketch Effect',
		'Oil Painting Effect',
		'Vignette (Radial Shadow)'
	], 'None')
	win.add_label('lbl_rotate', 'Rotation / Orientation:')
	win.add_dropdown('dd_rotate', ['None', 'Rotate 90 deg  CW', 'Rotate 90 deg  CCW', 'Rotate 180 deg ', 'Flip Horizontal', 'Flip Vertical', 'Auto-Orient from EXIF'], 'None')
	win.end_row()

	win.begin_row('row_eff_2')
	win.add_label('lbl_border', 'Border Width:')
	win.add_dropdown('dd_border_w', ['0 (No border)', '5px', '10px', '20px', '40px'], '0 (No border)')
	win.add_label('lbl_border_col', 'Border Color:')
	win.add_dropdown('dd_border_col', ['white', 'black', '#1e293b (Slate)', '#3b82f6 (Blue)', '#ef4444 (Red)', '#10b981 (Emerald)'], 'white')
	win.end_row()
	win.end_group_box()

	// Tab 7: Text & Watermarking
	win.begin_group_box('pane_watermark', 'Branding, Copyright & Watermark Overlay')
	win.begin_row('row_wm_1')
	win.add_label('lbl_wm_text', 'Watermark Text:')
	win.add_input('txt_wm_text', ' 2026 Studio')
	win.set_control_width('txt_wm_text', 400)
	win.add_label('lbl_wm_pos', 'Position:')
	win.add_dropdown('dd_wm_pos', ['SouthEast (Bottom-Right)', 'Center', 'South (Bottom-Center)', 'NorthEast (Top-Right)', 'SouthWest (Bottom-Left)'], 'SouthEast (Bottom-Right)')
	win.end_row()

	win.begin_row('row_wm_2')
	win.add_label('lbl_wm_size', 'Font Size (pt):')
	win.add_dropdown('dd_wm_size', ['18', '24', '32', '48', '64', '96'], '32')
	win.add_label('lbl_wm_color', 'Color:')
	win.add_dropdown('dd_wm_color', ['rgba(255,255,255,0.75) (White Semi-Transparent)', 'white', 'black', 'rgba(0,0,0,0.6) (Black Semi-Transparent)', 'gold', 'red'], 'rgba(255,255,255,0.75) (White Semi-Transparent)')
	win.end_row()
	win.end_group_box()

	// Tab 8: PDF & Stitching / Collage
	win.begin_group_box('pane_pdf', 'PDF Page Extraction & Image Stitching (Montage)')
	win.begin_row('row_pdf_1')
	win.add_label('lbl_pdf_mode', 'PDF / Stitch Mode:')
	win.add_dropdown('dd_pdf_mode', [
		'Convert PDF to High-Res Images (300 DPI)',
		'Combine Folder Images into Single Multi-Page PDF',
		'Stitch Images Horizontally Side-by-Side (+append)',
		'Stitch Images Vertically Stacked (-append)',
		'2x2 Grid Montage Collage'
	], 'Convert PDF to High-Res Images (300 DPI)')
	win.end_row()
	win.end_group_box()

	// Tab 9: Batch Folder Transcoder
	win.begin_group_box('pane_batch', 'Bulk Image Folder Processor')
	win.begin_row('row_batch_1')
	win.add_label('lbl_batch_dir', 'Input Folder:')
	win.add_input('txt_batch_dir', '')
	win.set_control_width('txt_batch_dir', 480)
	win.add_button('btn_browse_batch_in', 'Select Folder...')
	win.end_row()

	win.begin_row('row_batch_2')
	win.add_label('lbl_batch_action', 'Batch Action:')
	win.add_dropdown('dd_batch_action', [
		'Convert All Images to WebP (Quality 85%)',
		'Convert All Images to AVIF',
		'Convert All Images to PNG',
		'Convert All Images to JPEG',
		'Resize All Images 50%',
		'Strip EXIF from All Images'
	], 'Convert All Images to WebP (Quality 85%)')
	win.add_button('btn_run_batch', 'Run Batch Queue')
	win.end_row()
	win.end_group_box()

	// Initial Tab visibility
	win.set_control_visible('pane_resize', true)
	win.set_control_visible('pane_format', false)
	win.set_control_visible('pane_social', false)
	win.set_control_visible('pane_bg_remove', false)
	win.set_control_visible('pane_crop', false)
	win.set_control_visible('pane_effects', false)
	win.set_control_visible('pane_watermark', false)
	win.set_control_visible('pane_pdf', false)
	win.set_control_visible('pane_batch', false)

	// -------------------------------------------------------------
	// Live Command Preview
	// -------------------------------------------------------------
	win.begin_group_box('grp_cmd', 'Live ImageMagick Command Preview')
	win.begin_row('row_cmd')
	win.add_input('txt_command', 'magick input.jpg output.webp')
	win.set_control_width('txt_command', 660)
	win.add_button('btn_build_cmd', 'Refresh')
	win.add_button('btn_copy_cmd', 'Copy')
	win.end_row()
	win.end_group_box()

	// -------------------------------------------------------------
	// Execution & Console
	// -------------------------------------------------------------
	win.begin_row('row_actions')
	win.add_button('btn_run', 'Process Image')
	win.add_button('btn_reveal', 'Reveal Output in Finder')
	win.add_button('btn_clear_log', 'Clear Log')
	win.end_row()

	win.add_console('log_console', 160)

	// Initial log
	win.append_console('log_console', ' SimpleGUI ImageMagick Studio Pro Initialized (Async Non-Blocking Engine).\n', 1)
	win.append_console('log_console', ' Detected Magick CLI: ' + magick_path + '\n', 4)
	win.append_console('log_console', ' Detected Identify CLI: ' + identify_path + '\n', 4)

	// -------------------------------------------------------------
	// Command Builder Logic Helper
	// -------------------------------------------------------------
	build_command := fn (win &simplegui.SimpleWindow) string {
		magick := get_magick_bin()
		in_file := win.get('txt_input').trim_space()
		out_file := win.get('txt_output').trim_space()

		if in_file == '' {
			return '${magick} <input_file> <output_file>'
		}

		current_tab := win.get('tabs_mode')
		mut cmd_parts := [magick, '"${in_file}"']

		if current_tab.contains('Resize') || current_tab == '' {
			preset := win.get('dd_res_preset')
			if preset.contains('50%') {
				cmd_parts << ['-resize', '50%']
			} else if preset.contains('25%') {
				cmd_parts << ['-resize', '25%']
			} else if preset.contains('200%') {
				cmd_parts << ['-resize', '200%']
			} else if preset.contains('1920x1080') {
				cmd_parts << ['-resize', '1920x1080\\>']
			} else if preset.contains('1280x720') {
				cmd_parts << ['-resize', '1280x720\\>']
			} else if preset.contains('3840x2160') {
				cmd_parts << ['-resize', '3840x2160\\>']
			} else if preset.contains('Custom') {
				w := win.get('txt_custom_w').trim_space()
				h := win.get('txt_custom_h').trim_space()
				aspect := win.get('dd_aspect_mode')
				if w != '' && h != '' {
					if aspect.contains('Fit') {
						cmd_parts << ['-resize', '${w}x${h}\\>']
					} else if aspect.contains('Exact') {
						cmd_parts << ['-resize', '${w}x${h}!']
					} else {
						cmd_parts << ['-resize', '${w}x${h}^', '-gravity', 'center', '-extent', '${w}x${h}']
					}
				}
			}

			dpi := win.get('dd_dpi')
			if dpi.contains('72') { cmd_parts << ['-density', '72'] }
			else if dpi.contains('150') { cmd_parts << ['-density', '150'] }
			else if dpi.contains('300') { cmd_parts << ['-density', '300'] }
		} else if current_tab.contains('Web Formats') {
			q_sel := win.get('dd_quality')
			mut q := '85'
			if q_sel.contains('95') { q = '95' }
			else if q_sel.contains('75') { q = '75' }
			else if q_sel.contains('60') { q = '60' }
			else if q_sel.contains('40') { q = '40' }

			fmt := win.get('dd_format')
			if fmt.contains('ico') {
				cmd_parts << ['-define', 'icon:auto-resize=64,48,32,16']
			} else {
				cmd_parts << ['-quality', q, '-strip', '-interlace', 'Plane']
			}
		} else if current_tab.contains('Social') {
			soc_preset := win.get('dd_soc_preset')
			if soc_preset.contains('1080x1080') {
				cmd_parts << ['-resize', '1080x1080^', '-gravity', 'center', '-extent', '1080x1080']
			} else if soc_preset.contains('1080x1920') {
				cmd_parts << ['-resize', '1080x1920^', '-gravity', 'center', '-extent', '1080x1920']
			} else if soc_preset.contains('1280x720') {
				cmd_parts << ['-resize', '1280x720^', '-gravity', 'center', '-extent', '1280x720']
			} else if soc_preset.contains('1200x675') {
				cmd_parts << ['-resize', '1200x675^', '-gravity', 'center', '-extent', '1200x675']
			} else if soc_preset.contains('1500x500') {
				cmd_parts << ['-resize', '1500x500^', '-gravity', 'center', '-extent', '1500x500']
			} else if soc_preset.contains('1200x630') {
				cmd_parts << ['-resize', '1200x630^', '-gravity', 'center', '-extent', '1200x630']
			} else if soc_preset.contains('1584x396') {
				cmd_parts << ['-resize', '1584x396^', '-gravity', 'center', '-extent', '1584x396']
			} else if soc_preset.contains('1024x1024') {
				cmd_parts << ['-resize', '1024x1024!']
			} else if soc_preset.contains('Favicon') {
				cmd_parts << ['-define', 'icon:auto-resize=64,48,32,16']
			}
		} else if current_tab.contains('Remove Background') {
			bg_col := if win.get('dd_bg_color').contains('black') { 'black' } else if win.get('dd_bg_color').contains('Green') { '#00ff00' } else { 'white' }
			fuzz_val := if win.get('dd_fuzz').contains('5%') { '5%' } else if win.get('dd_fuzz').contains('20%') { '20%' } else if win.get('dd_fuzz').contains('35%') { '35%' } else { '10%' }
			
			cmd_parts << ['-fuzz', fuzz_val, '-transparent', bg_col]
			cmd_parts << ['-trim', '+repage']
		} else if current_tab.contains('Crop') || current_tab.contains('Shadow') {
			cw := win.get('txt_crop_w').trim_space()
			ch := win.get('txt_crop_h').trim_space()
			grav := win.get('dd_gravity')
			
			mut g := 'Center'
			if grav.contains('NorthWest') { g = 'NorthWest' }
			else if grav.contains('SouthEast') { g = 'SouthEast' }
			else if grav.contains('North') { g = 'North' }
			else if grav.contains('South') { g = 'South' }
			else if grav.contains('East') { g = 'East' }
			else if grav.contains('West') { g = 'West' }

			cmd_parts << ['-gravity', g]
			if cw != '' && ch != '' {
				cmd_parts << ['-crop', '${cw}x${ch}+0+0', '+repage']
			}
		} else if current_tab.contains('Filters') || current_tab.contains('Enhance') {
			filt := win.get('dd_filter')
			if filt.contains('Auto-Level') {
				cmd_parts << ['-auto-level', '-auto-gamma']
			} else if filt.contains('Normalize') {
				cmd_parts << ['-normalize']
			} else if filt.contains('Grayscale') {
				cmd_parts << ['-colorspace', 'Gray']
			} else if filt.contains('Sepia') {
				cmd_parts << ['-sepia-tone', '80%']
			} else if filt.contains('Soft') {
				cmd_parts << ['-blur', '0x4']
			} else if filt.contains('Heavy') {
				cmd_parts << ['-blur', '0x16']
			} else if filt.contains('Sharpen') {
				cmd_parts << ['-sharpen', '0x3']
			} else if filt.contains('Invert') {
				cmd_parts << ['-negate']
			} else if filt.contains('Charcoal') {
				cmd_parts << ['-charcoal', '2']
			} else if filt.contains('Oil') {
				cmd_parts << ['-paint', '4']
			} else if filt.contains('Vignette') {
				cmd_parts << ['-vignette', '0x20']
			}

			rot := win.get('dd_rotate')
			if rot.contains('90 deg  CW') { cmd_parts << ['-rotate', '90'] }
			else if rot.contains('90 deg  CCW') { cmd_parts << ['-rotate', '-90'] }
			else if rot.contains('180 deg ') { cmd_parts << ['-rotate', '180'] }
			else if rot.contains('Flip Horizontal') { cmd_parts << ['-flop'] }
			else if rot.contains('Flip Vertical') { cmd_parts << ['-flip'] }
			else if rot.contains('Auto-Orient') { cmd_parts << ['-auto-orient'] }

			bw := win.get('dd_border_w')
			if !bw.contains('0') && bw != '' {
				bpx := if bw.contains('5px') { '5x5' } else if bw.contains('10px') { '10x10' } else if bw.contains('20px') { '20x20' } else { '40x40' }
				bcol := win.get('dd_border_col').all_before(' ')
				cmd_parts << ['-bordercolor', bcol, '-border', bpx]
			}
		} else if current_tab.contains('Text Watermark') {
			text := win.get('txt_wm_text').trim_space()
			pos := win.get('dd_wm_pos')
			mut g := 'SouthEast'
			if pos.contains('Center') { g = 'Center' }
			else if pos.contains('South') { g = 'South' }
			else if pos.contains('NorthEast') { g = 'NorthEast' }
			else if pos.contains('SouthWest') { g = 'SouthWest' }

			sz := win.get('dd_wm_size')
			pt := if sz != '' { sz } else { '32' }
			col := win.get('dd_wm_color').all_before(' ')

			if text != '' {
				cmd_parts << ['-gravity', g, '-pointsize', pt, '-fill', '"${col}"', '-annotate', '+20+20', '"${text}"']
			}
		} else if current_tab.contains('PDF') {
			mode := win.get('dd_pdf_mode')
			if mode.contains('Convert PDF') {
				cmd_parts = [magick, '-density', '300', '"${in_file}"', '-quality', '100']
			} else if mode.contains('Stitch Images Horizontally') {
				cmd_parts = [magick, '+append', '"${in_file}"']
			} else if mode.contains('Stitch Images Vertically') {
				cmd_parts = [magick, '-append', '"${in_file}"']
			}
		}

		target_out := if out_file != '' { '"${out_file}"' } else { '"output.webp"' }
		cmd_parts << target_out
		return cmd_parts.join(' ')
	}

	// -------------------------------------------------------------
	// Event Handlers
	// -------------------------------------------------------------

	// Tab switching callback
	win.on_change('tabs_mode', fn (mut w simplegui.SimpleWindow, val string) {
		w.set_control_visible('pane_resize', val.contains('Resize'))
		w.set_control_visible('pane_format', val.contains('Web Formats'))
		w.set_control_visible('pane_social', val.contains('Social'))
		w.set_control_visible('pane_bg_remove', val.contains('Remove Background'))
		w.set_control_visible('pane_crop', val.contains('Crop'))
		w.set_control_visible('pane_effects', val.contains('Filters'))
		w.set_control_visible('pane_watermark', val.contains('Text Watermark'))
		w.set_control_visible('pane_pdf', val.contains('PDF'))
		w.set_control_visible('pane_batch', val.contains('Batch'))
	})

	// Input Browse Button
	win.on_click('btn_browse_in', fn (mut w simplegui.SimpleWindow) {
		path := w.select_file()
		if path != '' {
			w.set('txt_input', path)
			w.append_console('log_console', ' Selected Image: ${path}\n', 1)
			
			dir := os.dir(path)
			file_stem := os.file_name(path).all_before_last('.')
			default_out := os.join_path(dir, '${file_stem}_optimized.webp')
			if w.get('txt_output') == '' {
				w.set('txt_output', default_out)
			}
		}
	})

	// Output Save As Button
	win.on_click('btn_browse_out', fn (mut w simplegui.SimpleWindow) {
		path := w.save_file_picker()
		if path != '' {
			w.set('txt_output', path)
			w.append_console('log_console', ' Target Output: ${path}\n', 1)
		}
	})

	// Auto Name Button
	win.on_click('btn_auto_out', fn (mut w simplegui.SimpleWindow) {
		in_path := w.get('txt_input').trim_space()
		if in_path == '' {
			w.toast('Please select an input image first.')
			return
		}
		dir := os.dir(in_path)
		stem := os.file_name(in_path).all_before_last('.')
		current_tab := w.get('tabs_mode')
		
		mut ext := 'webp'
		if current_tab.contains('Web Formats') {
			fmt := w.get('dd_format')
			if fmt.contains('ico') { ext = 'ico' }
			else if fmt.contains('avif') { ext = 'avif' }
			else if fmt.contains('png') { ext = 'png' }
			else if fmt.contains('jpeg') { ext = 'jpg' }
			else if fmt.contains('pdf') { ext = 'pdf' }
			else { ext = 'webp' }
		} else if current_tab.contains('Remove Background') {
			ext = 'png'
		} else if current_tab.contains('Social') && w.get('dd_soc_preset').contains('Favicon') {
			ext = 'ico'
		} else {
			ext = os.file_ext(in_path).trim_left('.')
			if ext == '' { ext = 'webp' }
		}

		new_out := os.join_path(dir, '${stem}_processed.${ext}')
		w.set('txt_output', new_out)
		w.toast('Auto-configured output filename.')
	})

	// Identify / Metadata Inspector (Async)
	win.on_click('btn_identify', fn (mut w simplegui.SimpleWindow) {
		in_path := w.get('txt_input').trim_space()
		if in_path == '' || !os.exists(in_path) {
			w.toast('Select a valid input image to inspect.')
			return
		}
		identify := get_identify_bin()
		magick := get_magick_bin()
		w.append_console('log_console', ' Inspecting image: ${in_path}...\n', 1)
		w.set_status('Extracting image EXIF & channels...')

		go fn [mut w, in_path, identify, magick] () {
			res := simplegui.exec_safe(identify, ['-verbose', in_path])
			w.run_on_main_thread(fn [res, in_path, magick] (mut win_main simplegui.SimpleWindow) {
				if res.exit_code == 0 {
					win_main.append_console('log_console', '=== IMAGE METADATA & CHANNELS ===\n' + res.output + '\n', 4)
				} else {
					mres := simplegui.exec_safe(magick, ['identify', in_path])
					win_main.append_console('log_console', mres.output + '\n', 1)
				}
				win_main.set_status('Image inspection ready.')
				win_main.toast('Image metadata inspection complete.')
			})
		}()
	})

	// Batch Directory Picker
	win.on_click('btn_browse_batch_in', fn (mut w simplegui.SimpleWindow) {
		folder := w.select_folder()
		if folder != '' {
			w.set('txt_batch_dir', folder)
			w.append_console('log_console', ' Selected Batch Folder: ${folder}\n', 1)
		}
	})

	// Batch Execution (Async Non-Blocking Queue)
	win.on_click('btn_run_batch', fn (mut w simplegui.SimpleWindow) {
		dir := w.get('txt_batch_dir').trim_space()
		if dir == '' || !os.is_dir(dir) {
			w.alert('Folder Required', 'Please select a valid folder for batch processing.')
			return
		}
		magick := get_magick_bin()
		files := os.ls(dir) or { []string{} }
		action := w.get('dd_batch_action')

		w.append_console('log_console', ' Starting image batch processing on folder: ${dir} (Async Background Queue)...\n', 1)
		w.set_status('Batch image queue running in background...')

		go fn [mut w, dir, files, action, magick] () {
			mut processed := 0
			for f in files {
				ext := os.file_ext(f).to_lower()
				if ext in ['.png', '.jpg', '.jpeg', '.webp', '.tiff', '.bmp', '.gif', '.heic', '.avif'] {
					full_in := os.join_path(dir, f)
					stem := f.all_before_last('.')
					
					mut raw_args := [full_in]
					mut full_out := ''
					if action.contains('AVIF') {
						full_out = os.join_path(dir, '${stem}_batch.avif')
						raw_args << ['-quality', '80', '-strip', full_out]
					} else if action.contains('PNG') {
						full_out = os.join_path(dir, '${stem}_batch.png')
						raw_args << ['-strip', full_out]
					} else if action.contains('JPEG') {
						full_out = os.join_path(dir, '${stem}_batch.jpg')
						raw_args << ['-quality', '85', '-strip', full_out]
					} else if action.contains('50%') {
						full_out = os.join_path(dir, '${stem}_50pct' + ext)
						raw_args << ['-resize', '50%', full_out]
					} else if action.contains('Strip') {
						full_out = os.join_path(dir, '${stem}_clean' + ext)
						raw_args << ['-strip', full_out]
					} else {
						full_out = os.join_path(dir, '${stem}_batch.webp')
						raw_args << ['-quality', '85', '-strip', full_out]
					}

					w.run_on_main_thread(fn [f] (mut win_main simplegui.SimpleWindow) {
						win_main.append_console('log_console', ' Processing image: ${f}...\n', 1)
					})

					res := simplegui.exec_safe(magick, raw_args)
					if res.exit_code == 0 {
						processed++
						w.run_on_main_thread(fn [f] (mut win_main simplegui.SimpleWindow) {
							win_main.append_console('log_console', ' Finished: ${f}\n', 4)
						})
					} else {
						w.run_on_main_thread(fn [f] (mut win_main simplegui.SimpleWindow) {
							win_main.append_console('log_console', ' Failed: ${f}\n', 3)
						})
					}
				}
			}

			w.run_on_main_thread(fn [processed] (mut win_main simplegui.SimpleWindow) {
				win_main.append_console('log_console', ' Batch Complete! Processed ${processed} images.\n', 4)
				win_main.set_status('Batch image queue finished.')
				win_main.toast('Batch processing complete: ${processed} images.')
			})
		}()
	})

	// Refresh Command
	win.on_click('btn_build_cmd', fn [build_command] (mut w simplegui.SimpleWindow) {
		cmd := build_command(w)
		w.set('txt_command', cmd)
		w.toast('Command string refreshed.')
	})

	// Copy Command
	win.on_click('btn_copy_cmd', fn [build_command] (mut w simplegui.SimpleWindow) {
		mut cmd := w.get('txt_command').trim_space()
		if cmd == '' || cmd.contains('<input_file>') {
			cmd = build_command(w)
			w.set('txt_command', cmd)
		}
		w.copy_to_clipboard(cmd)
		w.toast('Command copied to clipboard!')
	})

	// Clear Log
	win.on_click('btn_clear_log', fn (mut w simplegui.SimpleWindow) {
		w.clear_console('log_console')
		w.set_status('Log cleared.')
	})

	// Reveal in Finder
	win.on_click('btn_reveal', fn (mut w simplegui.SimpleWindow) {
		out_path := w.get('txt_output').trim_space()
		if out_path == '' || !os.exists(out_path) {
			w.toast('Output file does not exist yet.')
			return
		}
		os.execute('open -R "${out_path}"')
		w.toast('Revealed in Finder.')
	})

	// Run Process Image (Async Non-Blocking Thread)
	win.on_click('btn_run', fn [build_command] (mut w simplegui.SimpleWindow) {
		in_path := w.get('txt_input').trim_space()
		out_path := w.get('txt_output').trim_space()

		if in_path == '' || !os.exists(in_path) {
			w.alert('Input Error', 'Please select an existing input image first.')
			return
		}

		if out_path == '' {
			w.alert('Output Error', 'Please specify a destination output path.')
			return
		}

		mut cmd := w.get('txt_command').trim_space()
		if cmd == '' || cmd.contains('<input_file>') {
			cmd = build_command(w)
			w.set('txt_command', cmd)
		}

		w.append_console('log_console', '----------------------------------------\n', 1)
		w.append_console('log_console', ' Executing in Background: ${cmd}\n', 1)
		w.set_status('ImageMagick processing running asynchronously (UI responsive)...')
		w.toast('Image processing started in background!')

		// Spawn background thread to prevent beach ball
		go fn [mut w, cmd, out_path] () {
			res := os.execute(cmd)

			w.run_on_main_thread(fn [res, out_path] (mut win_main simplegui.SimpleWindow) {
				if res.exit_code == 0 {
					win_main.append_console('log_console', ' Image Processed Successfully!\n', 4)
					if os.exists(out_path) {
						size_bytes := os.file_size(out_path)
						size_kb := f64(size_bytes) / 1024.0
						win_main.append_console('log_console', ' Output Created: ${out_path} (${size_kb:.1f} KB)\n', 4)
					}
					win_main.set_status('Image task completed with success.')
					win_main.toast('Image processing finished successfully!')
				} else {
					win_main.append_console('log_console', ' Error during execution (Exit code ${res.exit_code}):\n' + res.output + '\n', 3)
					win_main.set_status('Error executing ImageMagick.')
					win_main.alert('ImageMagick Error', 'Failed to process image. Check console logs for details.')
				}
			})
		}()
	})

	println('ImageMagick Studio Pro configured. Starting event loop...')
	win.run()
}

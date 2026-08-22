module main

import os
import time
import simplegui

struct IconPreset {
	label string
	file  string
}

fn get_icon_presets() []IconPreset {
	return [
		IconPreset{'Default App (icon.png)', 'icon.png'},
		IconPreset{'Terminal / CLI (terminal.png)', 'terminal.png'},
		IconPreset{'Developer Tools (developer.png)', 'developer.png'},
		IconPreset{'Package / Archive (package_manager.png)', 'package_manager.png'},
		IconPreset{'Security & Privacy (security.png)', 'security.png'},
		IconPreset{'System Utility (utility.png)', 'utility.png'},
		IconPreset{'System Monitor (system_monitor.png)', 'system_monitor.png'},
		IconPreset{'Media & Video (media.png)', 'media.png'},
		IconPreset{'Video Editor (video_editor.png)', 'video_editor.png'},
		IconPreset{'Audio & Sound (audio_editor.png)', 'audio_editor.png'},
		IconPreset{'Voice Recorder (voice_recorder.png)', 'voice_recorder.png'},
		IconPreset{'Design & Graphics (design.png)', 'design.png'},
		IconPreset{'Image Viewer (image_viewer.png)', 'image_viewer.png'},
		IconPreset{'Image Optimizer (image_optimizer.png)', 'image_optimizer.png'},
		IconPreset{'Database (database.png)', 'database.png'},
		IconPreset{'Database Admin (database_admin.png)', 'database_admin.png'},
		IconPreset{'Network & API (network_analyzer.png)', 'network_analyzer.png'},
		IconPreset{'API Client (api_client.png)', 'api_client.png'},
		IconPreset{'Text & Code Editor (text_editor.png)', 'text_editor.png'},
		IconPreset{'Markdown Editor (markdown_editor.png)', 'markdown_editor.png'},
		IconPreset{'Calculator & Math (calculator.png)', 'calculator.png'},
		IconPreset{'Spreadsheet & Data (spreadsheet.png)', 'spreadsheet.png'},
		IconPreset{'CSV Editor (csv_editor.png)', 'csv_editor.png'},
		IconPreset{'Task & Scheduler (task_scheduler.png)', 'task_scheduler.png'},
		IconPreset{'Container & Docker (container_manager.png)', 'container_manager.png'},
		IconPreset{'Docker Monitor (docker_monitor.png)', 'docker_monitor.png'},
		IconPreset{'Cloud Storage (cloud_storage.png)', 'cloud_storage.png'},
		IconPreset{'Git GUI (git_gui.png)', 'git_gui.png'},
		IconPreset{'File Manager (file_manager.png)', 'file_manager.png'},
		IconPreset{'Disk Utility (disk_utility.png)', 'disk_utility.png'},
		IconPreset{'Archive Manager (archive_manager.png)', 'archive_manager.png'},
		IconPreset{'AI Chat Assistant (ai_chat.png)', 'ai_chat.png'},
		IconPreset{'Web Browser (browser.png)', 'browser.png'},
		IconPreset{'Game Engine (game.png)', 'game.png'},
	]
}

struct IconDimension {
	name string
	size int
}

fn generate_icns_file(src_png string, out_icns_path string) (bool, string) {
	if !os.exists(src_png) {
		return false, 'Source icon file does not exist: ${src_png}'
	}

	temp_dir := os.join_path(os.temp_dir(), 'appbundler_${time.now().unix_milli()}')
	iconset_dir := os.join_path(temp_dir, 'AppIcon.iconset')
	os.mkdir_all(iconset_dir) or {
		return false, 'Failed to create temp iconset directory: ${err}'
	}
	defer {
		os.rmdir_all(temp_dir) or {}
	}

	dims := [
		IconDimension{'icon_16x16.png', 16},
		IconDimension{'icon_16x16@2x.png', 32},
		IconDimension{'icon_32x32.png', 32},
		IconDimension{'icon_32x32@2x.png', 64},
		IconDimension{'icon_128x128.png', 128},
		IconDimension{'icon_128x128@2x.png', 256},
		IconDimension{'icon_256x256.png', 256},
		IconDimension{'icon_256x256@2x.png', 512},
		IconDimension{'icon_512x512.png', 512},
		IconDimension{'icon_512x512@2x.png', 1024},
	]

	for d in dims {
		out_p := os.join_path(iconset_dir, d.name)
		cmd := 'sips -s format png -z ${d.size} ${d.size} ${os.quoted_path(src_png)} --out ${os.quoted_path(out_p)}'
		res := os.execute(cmd)
		if res.exit_code != 0 {
			return false, 'sips failed on ${d.name}: ${res.output.trim_space()}'
		}
	}

	cmd_iconutil := 'iconutil -c icns ${os.quoted_path(iconset_dir)} -o ${os.quoted_path(out_icns_path)}'
	res_iconutil := os.execute(cmd_iconutil)
	if res_iconutil.exit_code != 0 {
		return false, 'iconutil failed: ${res_iconutil.output.trim_space()}'
	}

	return true, ''
}

fn build_info_plist(app_name string, exe_name string, bundle_id string, version string, category string, high_dpi bool, dark_mode bool) string {
	cat_str := if category.len > 0 { category } else { 'public.app-category.utilities' }
	dpi_str := if high_dpi { 'true' } else { 'false' }
	dark_str := if dark_mode { 'false' } else { 'true' } // NSRequiresAquaSystemAppearance=false means support dark mode

	return '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleExecutable</key>
	<string>${exe_name}</string>
	<key>CFBundleIconFile</key>
	<string>AppIcon</string>
	<key>CFBundleIdentifier</key>
	<string>${bundle_id}</string>
	<key>CFBundleName</key>
	<string>${app_name}</string>
	<key>CFBundleDisplayName</key>
	<string>${app_name}</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleSignature</key>
	<string>????</string>
	<key>CFBundleShortVersionString</key>
	<string>${version}</string>
	<key>CFBundleVersion</key>
	<string>${version}</string>
	<key>LSMinimumSystemVersion</key>
	<string>11.0</string>
	<key>LSApplicationCategoryType</key>
	<string>${cat_str}</string>
	<key>NSHighResolutionCapable</key>
	<${dpi_str}/>
	<key>NSRequiresAquaSystemAppearance</key>
	<${dark_str}/>
	<key>NSPrincipalClass</key>
	<string>NSApplication</string>
</dict>
</plist>
'
}

fn clean_alphanumeric(raw string) string {
	mut clean := ''
	for c in raw {
		if c.is_alnum() {
			clean += c.ascii_str()
		}
	}
	return clean.to_lower()
}

fn format_display_title(raw string) string {
	mut result := []string{}
	mut cleaned := ''
	for c in raw {
		if c in [`-`, `_`, `.`] {
			cleaned += ' '
		} else {
			cleaned += c.ascii_str()
		}
	}
	for word in cleaned.split(' ') {
		if word.len > 0 {
			result << word[0..1].to_upper() + word[1..]
		}
	}
	return result.join(' ')
}

fn inspect_binary(bin_path string) string {
	if !os.exists(bin_path) {
		return '[ERROR] File does not exist at "${bin_path}"'
	}

	mut sb := []string{}
	sb << '======================================================================'
	sb << 'Mach-O Binary Inspection Report: ${os.file_name(bin_path)}'
	sb << '======================================================================'
	sb << 'Path         : ${bin_path}'
	sz := os.file_size(bin_path)
	sb << 'Size         : ${f64(sz) / 1024.0 / 1024.0:.2f} MB (${sz} bytes)'
	
	// File command check
	file_res := os.execute('file ${os.quoted_path(bin_path)}')
	if file_res.exit_code == 0 {
		sb << 'Type / Arch  : ${file_res.output.trim_space()}'
	}

	// Lipo check
	lipo_res := os.execute('lipo -info ${os.quoted_path(bin_path)}')
	if lipo_res.exit_code == 0 {
		sb << 'Architectures: ${lipo_res.output.trim_space()}'
	}

	// Codesign check
	cs_res := os.execute('codesign -dvvv ${os.quoted_path(bin_path)} 2>&1')
	sb << 'Signature    : ' + if cs_res.exit_code == 0 { 'Signed' } else { 'Ad-hoc / Unsigned' }
	if cs_res.output.len > 0 {
		sb << '  ' + cs_res.output.trim_space().replace('\n', '\n  ')
	}

	// Otool dylibs check
	otool_res := os.execute('otool -L ${os.quoted_path(bin_path)}')
	if otool_res.exit_code == 0 {
		sb << '\nLinked Dynamic Libraries (otool -L):'
		lines := otool_res.output.split_into_lines()
		for i, l in lines {
			if i > 0 && l.trim_space().len > 0 {
				sb << '  - ' + l.trim_space()
			}
		}
	}
	sb << '======================================================================'

	return sb.join('\n')
}

fn main() {
	println('Starting SimpleGUI - App Bundler Studio Pro...')

	mut win := simplegui.new_simple_window('SimpleGUI - App Bundler Studio Pro', 1140, 960)
	win.set_fullscreen(true)
	win.set_spacing(8)
	win.set_padding(16)

	saved_theme := simplegui.get_saved_theme()
	win.set_theme(saved_theme)

	// Top Banner / Diagnostics
	win.begin_row('row_top_banner')
	win.add_heading('App Bundler Studio Pro')
	win.add_label('lbl_theme', 'Theme:')
	win.add_dropdown('dd_app_theme', simplegui.list_themes(), saved_theme)
	win.set_control_width('dd_app_theme', 150)
	win.end_row()

	win.on_change('dd_app_theme', fn (mut w simplegui.SimpleWindow, selected string) {
		w.set_theme(selected)
		w.toast('Theme changed to ${selected}')
	})

	sips_ok := os.find_abs_path_of_executable('sips') or { '' } != ''
	iconutil_ok := os.find_abs_path_of_executable('iconutil') or { '' } != ''
	codesign_ok := os.find_abs_path_of_executable('codesign') or { '' } != ''

	win.add_label('lbl_sys_status', 'Subsystems: sips [${sips_ok}] | iconutil [${iconutil_ok}] | codesign [${codesign_ok}]  |  Target: macOS Cocoa Application (.app)')

	// 1. Source Binary Selection
	win.begin_group_box('grp_binary_input', '1. Source Mach-O Executable / CLI Binary')

	win.begin_row('row_bin_selector')
	win.add_label('lbl_bin_path', 'Binary File:')
	win.add_input('txt_bin_path', '')
	win.set_control_width('txt_bin_path', 480)
	win.add_button('btn_browse_bin', 'Select Binary...')
	win.add_button('btn_inspect_bin', 'Inspect Mach-O')
	win.add_button('btn_load_sample', 'Load Sample')
	win.end_row()

	win.end_group_box()

	// 2. Metadata & Bundle Settings
	win.begin_group_box('grp_meta_settings', '2. Application Metadata & Info.plist Configuration')

	win.begin_row('row_meta_row1')
	win.add_label('lbl_app_name', 'App Display Name:')
	win.add_input('txt_app_name', 'My Studio App')
	win.set_control_width('txt_app_name', 200)

	win.add_label('lbl_exe_name', 'Executable Name:')
	win.add_input('txt_exe_name', 'mystudioapp')
	win.set_control_width('txt_exe_name', 160)

	win.add_label('lbl_version', 'Version:')
	win.add_input('txt_version', '1.0.0')
	win.set_control_width('txt_version', 80)
	win.end_row()

	win.begin_row('row_meta_row2')
	win.add_label('lbl_bundle_id', 'Bundle Identifier:')
	win.add_input('txt_bundle_id', 'com.simplegui.mystudioapp')
	win.set_control_width('txt_bundle_id', 260)

	win.add_label('lbl_category', 'Category:')
	categories := [
		'public.app-category.developer-tools',
		'public.app-category.utilities',
		'public.app-category.productivity',
		'public.app-category.graphics-design',
		'public.app-category.video',
		'public.app-category.music',
		'public.app-category.finance',
		'public.app-category.education',
		'public.app-category.games',
	]
	win.add_dropdown('dd_category', categories, 'public.app-category.developer-tools')
	win.set_control_width('dd_category', 260)
	win.end_row()

	win.begin_row('row_meta_toggles')
	win.add_checkbox('chk_high_dpi', 'Retina High-DPI Support', true)
	win.add_checkbox('chk_dark_mode', 'Dark Mode Appearance', true)
	win.add_checkbox('chk_codesign', 'Ad-Hoc Code Sign (-s -)', true)
	win.add_checkbox('chk_quarantine', 'Clear Quarantine (xattr -cr)', true)
	win.add_checkbox('chk_terminal_wrapper', 'Terminal Launcher Mode', false)
	win.end_row()

	win.end_group_box()

	// 3. Icon Selection & Assets
	win.begin_group_box('grp_icon_settings', '3. Application Icon (.icns Generator & Preset Selector)')

	win.begin_row('row_icon_preview_and_presets')
	win.add_label('lbl_icon_preview_title', 'Icon Preview:')
	win.add_image_box('img_icon_preview', 'resources/icon.png', 72, 72)

	win.add_label('lbl_presets', 'Preset Icons Menu:')
	presets := get_icon_presets()
	mut preset_labels := []string{}
	for p in presets {
		preset_labels << p.label
	}
	win.add_dropdown('dd_icon_preset', preset_labels, preset_labels[0])
	win.set_control_width('dd_icon_preset', 320)
	win.add_button('btn_apply_preset', 'Apply Preset')
	win.add_button('btn_gen_icns_only', 'Export .icns Only')
	win.end_row()

	win.begin_row('row_icon_custom')
	win.add_label('lbl_icon_path', 'Custom Icon File (PNG/ICNS):')
	win.add_input('txt_icon_path', 'resources/icon.png')
	win.set_control_width('txt_icon_path', 440)
	win.add_button('btn_browse_icon', 'Browse Icon...')
	win.add_button('btn_preview_plist', 'Preview Info.plist')
	win.end_row()

	win.end_group_box()

	// 4. Output Destination & Primary Action Bar
	win.begin_group_box('grp_output_actions', '4. Destination & Build Operations')

	default_out := './bin'
	win.begin_row('row_out_dest')
	win.add_label('lbl_out_dir', 'Output Directory:')
	win.add_input('txt_out_dir', default_out)
	win.set_control_width('txt_out_dir', 480)
	win.add_button('btn_browse_out', 'Choose Destination...')
	win.end_row()

	win.begin_row('row_action_buttons')
	win.add_button('btn_package_app', 'Package macOS .app Bundle')
	win.add_button('btn_reveal_finder', 'Reveal in Finder')
	win.add_button('btn_launch_app', 'Launch Packaged App')
	win.add_button('btn_copy_plist', 'Copy Info.plist')
	win.add_button('btn_clear_log', 'Clear Logs')
	win.end_row()

	win.end_group_box()

	// 5. Logs & Telemetry View
	win.begin_group_box('grp_logs', '5. Bundler Activity & Diagnostic Console')
	win.add_textarea('txt_bundler_log', 'Welcome to App Bundler Studio Pro!\n\n1. Select any Mach-O binary or CLI tool (e.g. from /usr/local/bin, /opt/homebrew/bin, or your project bin/ folder).\n2. Customize display name, bundle ID, icon, and categories.\n3. Click "Package macOS .app Bundle" to generate a fully compliant, self-contained macOS .app bundle with Retina iconset and Info.plist.\n')
	win.set_control_height('txt_bundler_log', 240)
	win.end_group_box()

	// -------------------------------------------------------------------------
	// Event Handlers
	// -------------------------------------------------------------------------

	// Auto-fill names when binary path changes
	win.on_change('txt_bin_path', fn (mut w simplegui.SimpleWindow, val string) {
		trimmed := val.trim_space()
		if trimmed.len > 0 {
			fname := os.file_name(trimmed)
			clean_id := clean_alphanumeric(fname)
			disp_name := format_display_title(fname)

			w.set_value('txt_app_name', disp_name)
			w.set_value('txt_exe_name', fname)
			w.set_value('txt_bundle_id', 'com.simplegui.${clean_id}')
		}
	})

	// Select Binary File
	win.on_click('btn_browse_bin', fn (mut w simplegui.SimpleWindow) {
		selected := w.select_file()
		if selected != '' {
			w.set_value('txt_bin_path', selected)
			fname := os.file_name(selected)
			clean_id := clean_alphanumeric(fname)
			disp_name := format_display_title(fname)

			w.set_value('txt_app_name', disp_name)
			w.set_value('txt_exe_name', fname)
			w.set_value('txt_bundle_id', 'com.simplegui.${clean_id}')
			w.toast('Selected binary: ${fname}')
		}
	})

	// Load Sample Binary (e.g. jq_studio or current list_windows)
	win.on_click('btn_load_sample', fn (mut w simplegui.SimpleWindow) {
		cwd := os.getwd()
		sample_candidates := [
			os.join_path(cwd, 'bin', 'jq'),
			os.join_path(cwd, 'tools', 'list_windows'),
			'/opt/homebrew/bin/jq',
			'/usr/bin/tar',
		]
		for c in sample_candidates {
			if os.exists(c) {
				w.set_value('txt_bin_path', c)
				fname := os.file_name(c)
				clean_id := clean_alphanumeric(fname)
				disp_name := format_display_title(fname)
				w.set_value('txt_app_name', disp_name)
				w.set_value('txt_exe_name', fname)
				w.set_value('txt_bundle_id', 'com.simplegui.${clean_id}')
				w.toast('Loaded sample: ${fname}')
				return
			}
		}
		w.toast('No default sample found.')
	})

	// Inspect Mach-O Binary
	win.on_click('btn_inspect_bin', fn (mut w simplegui.SimpleWindow) {
		bin_p := w.get_value('txt_bin_path').trim_space()
		if bin_p == '' {
			w.alert('No Binary Selected', 'Please enter or select a target Mach-O binary file first.')
			return
		}
		report := inspect_binary(bin_p)
		w.set_value('txt_bundler_log', report)
		w.toast('Binary inspection complete.')
	})

	// Live update icon preview when preset dropdown changes
	win.on_change('dd_icon_preset', fn (mut w simplegui.SimpleWindow, selected string) {
		presets_list := get_icon_presets()
		for p in presets_list {
			if p.label == selected {
				full_path := os.join_path(os.getwd(), 'resources', p.file)
				target_path := if os.exists(full_path) { full_path } else { p.file }
				w.set_value('txt_icon_path', target_path)
				w.set_value('img_icon_preview', target_path)
				w.toast('Selected icon preset: ${p.file}')
				return
			}
		}
	})

	// Live update icon preview when custom icon path text changes
	win.on_change('txt_icon_path', fn (mut w simplegui.SimpleWindow, val string) {
		trimmed := val.trim_space()
		if trimmed.len > 0 && os.exists(trimmed) {
			w.set_value('img_icon_preview', trimmed)
		}
	})

	// Select Icon File (Browse dialog)
	win.on_click('btn_browse_icon', fn (mut w simplegui.SimpleWindow) {
		selected := w.select_file_with_extensions('png,jpg,jpeg,icns')
		if selected != '' {
			w.set_value('txt_icon_path', selected)
			w.set_value('img_icon_preview', selected)
			w.toast('Selected icon: ${os.file_name(selected)}')
		}
	})

	// Apply Preset Icon
	win.on_click('btn_apply_preset', fn (mut w simplegui.SimpleWindow) {
		selected_label := w.get_value('dd_icon_preset')
		presets_list := get_icon_presets()
		for p in presets_list {
			if p.label == selected_label {
				full_path := os.join_path(os.getwd(), 'resources', p.file)
				target_path := if os.exists(full_path) { full_path } else { p.file }
				w.set_value('txt_icon_path', target_path)
				w.set_value('img_icon_preview', target_path)
				w.toast('Applied icon preset: ${p.file}')
				return
			}
		}
	})

	// Select Output Directory
	win.on_click('btn_browse_out', fn (mut w simplegui.SimpleWindow) {
		selected := w.select_folder()
		if selected != '' {
			w.set_value('txt_out_dir', selected)
			w.toast('Output folder updated.')
		}
	})

	// Preview Info.plist
	win.on_click('btn_preview_plist', fn (mut w simplegui.SimpleWindow) {
		app_name := w.get_value('txt_app_name').trim_space()
		exe_name := w.get_value('txt_exe_name').trim_space()
		bundle_id := w.get_value('txt_bundle_id').trim_space()
		version := w.get_value('txt_version').trim_space()
		category := w.get_value('dd_category')
		high_dpi := w.get_checked('chk_high_dpi')
		dark_mode := w.get_checked('chk_dark_mode')

		plist := build_info_plist(app_name, exe_name, bundle_id, version, category, high_dpi, dark_mode)
		w.set_value('txt_bundler_log', '======================================================================\nGenerated Info.plist Preview\n======================================================================\n' + plist)
		w.toast('Info.plist preview generated.')
	})

	// Copy Info.plist
	win.on_click('btn_copy_plist', fn (mut w simplegui.SimpleWindow) {
		app_name := w.get_value('txt_app_name').trim_space()
		exe_name := w.get_value('txt_exe_name').trim_space()
		bundle_id := w.get_value('txt_bundle_id').trim_space()
		version := w.get_value('txt_version').trim_space()
		category := w.get_value('dd_category')
		high_dpi := w.get_checked('chk_high_dpi')
		dark_mode := w.get_checked('chk_dark_mode')

		plist := build_info_plist(app_name, exe_name, bundle_id, version, category, high_dpi, dark_mode)
		simplegui.clipboard_copy(plist)
		w.toast('Info.plist copied to clipboard!')
	})

	// Export .icns Only
	win.on_click('btn_gen_icns_only', fn (mut w simplegui.SimpleWindow) {
		icon_src := w.get_value('txt_icon_path').trim_space()
		out_dir := w.get_value('txt_out_dir').trim_space()
		app_name := w.get_value('txt_app_name').trim_space()

		resolved_icon := if os.is_abs_path(icon_src) {
			icon_src
		} else {
			os.join_path(os.getwd(), icon_src)
		}

		if !os.exists(resolved_icon) {
			w.alert('Icon Missing', 'Source icon file "${resolved_icon}" not found.')
			return
		}

		os.mkdir_all(out_dir) or {}
		clean_name := if app_name != '' { app_name.replace(' ', '_') } else { 'AppIcon' }
		dest_icns := os.join_path(out_dir, '${clean_name}.icns')

		ok, err_msg := generate_icns_file(resolved_icon, dest_icns)
		if ok {
			sz := os.file_size(dest_icns)
			w.set_value('txt_bundler_log', '[SUCCESS] Successfully generated standalone .icns icon:\n   Path: ${dest_icns}\n   Size: ${f64(sz)/1024.0:.1f} KB\n')
			w.toast('ICNS icon generated!')
		} else {
			w.set_value('txt_bundler_log', '[ERROR] Failed to generate .icns icon:\n   ${err_msg}')
			w.alert('Icon Generation Failed', err_msg)
		}
	})

	// Clear Logs
	win.on_click('btn_clear_log', fn (mut w simplegui.SimpleWindow) {
		w.set_value('txt_bundler_log', '')
		w.toast('Logs cleared.')
	})

	// Reveal in Finder
	win.on_click('btn_reveal_finder', fn (mut w simplegui.SimpleWindow) {
		app_name := w.get_value('txt_app_name').trim_space()
		out_dir := w.get_value('txt_out_dir').trim_space()
		target_app := os.join_path(out_dir, '${app_name}.app')

		if os.exists(target_app) {
			os.execute('open -R ${os.quoted_path(target_app)}')
			w.toast('Revealed in Finder.')
		} else if os.exists(out_dir) {
			os.execute('open ${os.quoted_path(out_dir)}')
			w.toast('Opened output folder.')
		} else {
			w.alert('Not Found', 'No packaged app found at "${target_app}".')
		}
	})

	// Test Launch App
	win.on_click('btn_launch_app', fn (mut w simplegui.SimpleWindow) {
		app_name := w.get_value('txt_app_name').trim_space()
		out_dir := w.get_value('txt_out_dir').trim_space()
		target_app := os.join_path(out_dir, '${app_name}.app')

		if os.exists(target_app) {
			os.execute('open ${os.quoted_path(target_app)}')
			w.toast('Launched ${app_name}.app!')
		} else {
			w.alert('Application Not Found', 'Please build the .app bundle first before launching.')
		}
	})

	// PRIMARY ACTION: Package macOS .app Bundle
	win.on_click('btn_package_app', fn (mut w simplegui.SimpleWindow) {
		t0 := time.now()

		bin_path := w.get_value('txt_bin_path').trim_space()
		app_name := w.get_value('txt_app_name').trim_space()
		mut exe_name := w.get_value('txt_exe_name').trim_space()
		bundle_id := w.get_value('txt_bundle_id').trim_space()
		version := w.get_value('txt_version').trim_space()
		category := w.get_value('dd_category')
		icon_src := w.get_value('txt_icon_path').trim_space()
		out_dir := w.get_value('txt_out_dir').trim_space()

		high_dpi := w.get_checked('chk_high_dpi')
		dark_mode := w.get_checked('chk_dark_mode')
		do_codesign := w.get_checked('chk_codesign')
		do_quarantine := w.get_checked('chk_quarantine')
		is_terminal_wrapper := w.get_checked('chk_terminal_wrapper')

		if bin_path == '' {
			w.alert('Validation Error', 'Please select or enter the path to the target Mach-O binary.')
			return
		}

		if !os.exists(bin_path) {
			w.alert('File Not Found', 'Target binary not found at:\n${bin_path}')
			return
		}

		if app_name == '' {
			w.alert('Validation Error', 'Please specify an App Display Name.')
			return
		}

		if exe_name == '' {
			exe_name = clean_alphanumeric(app_name)
		}

		resolved_out_dir := if os.is_abs_path(out_dir) { out_dir } else { os.join_path(os.getwd(), out_dir) }
		os.mkdir_all(resolved_out_dir) or {
			w.alert('Filesystem Error', 'Failed to create output directory: ${err}')
			return
		}

		app_bundle := os.join_path(resolved_out_dir, '${app_name}.app')
		contents_dir := os.join_path(app_bundle, 'Contents')
		macos_dir := os.join_path(contents_dir, 'MacOS')
		resources_dir := os.join_path(contents_dir, 'Resources')

		mut logs := []string{}
		logs << '======================================================================'
		logs << 'Starting macOS .app Packaging Pipeline'
		logs << '======================================================================'
		logs << '* Target Application : ${app_name}.app'
		logs << '* Executable Name    : ${exe_name}'
		logs << '* Bundle Identifier  : ${bundle_id}'
		logs << '* Version String     : ${version}'
		logs << '* Category           : ${category}'
		logs << '* Source Binary      : ${bin_path}'
		logs << '* Output Bundle Path : ${app_bundle}'
		logs << '----------------------------------------------------------------------'

		// 1. Clean existing bundle
		if os.exists(app_bundle) {
			logs << 'Removing existing bundle at ${app_bundle}...'
			os.rmdir_all(app_bundle) or {
				logs << '[ERROR] Failed to delete old app bundle: ${err}'
				w.set_value('txt_bundler_log', logs.join('\n'))
				w.alert('Build Error', 'Failed to remove old app bundle: ${err}')
				return
			}
		}

		// 2. Setup directory hierarchy
		os.mkdir_all(macos_dir) or {
			logs << '[ERROR] Failed to create MacOS folder: ${err}'
			w.set_value('txt_bundler_log', logs.join('\n'))
			return
		}
		os.mkdir_all(resources_dir) or {
			logs << '[ERROR] Failed to create Resources folder: ${err}'
			w.set_value('txt_bundler_log', logs.join('\n'))
			return
		}
		logs << 'Created bundle structure: Contents/{MacOS, Resources}'

		// 3. Process & Copy Executable
		target_bin := os.join_path(macos_dir, exe_name)

		if is_terminal_wrapper {
			// Terminal launcher wrapper script
			logs << 'Creating Terminal.app launcher wrapper...'
			cli_bin := os.join_path(resources_dir, exe_name)
			os.cp(bin_path, cli_bin) or {
				logs << '[ERROR] Failed to copy CLI binary to Resources: ${err}'
				w.set_value('txt_bundler_log', logs.join('\n'))
				return
			}
			os.chmod(cli_bin, 0o755) or {}

			wrapper_script := '#!/bin/bash
DIR="$(cd "$(dirname "$0")/../Resources" && pwd)"
osascript -e "tell application \\"Terminal\\" to do script \\"\'${cli_bin}\' ; exit\\""
'
			os.write_file(target_bin, wrapper_script) or {
				logs << '[ERROR] Failed to write wrapper script: ${err}'
				w.set_value('txt_bundler_log', logs.join('\n'))
				return
			}
			os.chmod(target_bin, 0o755) or {}
			logs << '[SUCCESS] Configured Terminal wrapper launcher'
		} else {
			logs << 'Copying Mach-O binary into Contents/MacOS/${exe_name}...'
			os.cp(bin_path, target_bin) or {
				logs << '[ERROR] Failed to copy binary: ${err}'
				w.set_value('txt_bundler_log', logs.join('\n'))
				w.alert('Copy Error', 'Failed to copy binary: ${err}')
				return
			}
			os.chmod(target_bin, 0o755) or {}
			logs << '[SUCCESS] Executable permissions applied (chmod +x)'
		}

		// 4. Generate Info.plist
		plist_content := build_info_plist(app_name, exe_name, bundle_id, version, category, high_dpi, dark_mode)
		plist_path := os.join_path(contents_dir, 'Info.plist')
		os.write_file(plist_path, plist_content) or {
			logs << '[ERROR] Failed to write Info.plist: ${err}'
			w.set_value('txt_bundler_log', logs.join('\n'))
			return
		}
		logs << '[SUCCESS] Generated Info.plist (${plist_content.len} bytes)'

		// 5. Generate PkgInfo
		pkginfo_path := os.join_path(contents_dir, 'PkgInfo')
		os.write_file(pkginfo_path, 'APPL????') or {}
		logs << '[SUCCESS] Generated PkgInfo'

		// 6. Generate Icon (.icns)
		mut icon_resolved := if os.is_abs_path(icon_src) {
			icon_src
		} else {
			os.join_path(os.getwd(), icon_src)
		}
		if !os.exists(icon_resolved) {
			icon_resolved = os.join_path(os.getwd(), 'resources', 'icon.png')
		}

		if os.exists(icon_resolved) {
			dest_icns := os.join_path(resources_dir, 'AppIcon.icns')
			if icon_resolved.ends_with('.icns') {
				os.cp(icon_resolved, dest_icns) or {}
				logs << 'Copied pre-built .icns asset directly'
			} else {
				logs << 'Compiling multi-resolution iconset via sips & iconutil...'
				ok_icns, icns_err := generate_icns_file(icon_resolved, dest_icns)
				if ok_icns {
					icns_sz := os.file_size(dest_icns)
					logs << '[SUCCESS] Compiled AppIcon.icns (${f64(icns_sz)/1024.0:.1f} KB)'
				} else {
					logs << '[WARNING] Icon compilation warning: ${icns_err}'
				}
			}
		} else {
			logs << '[INFO] No icon specified (using default macOS generic icon)'
		}

		// 7. Ad-hoc Codesign
		if do_codesign {
			logs << 'Applying Ad-Hoc Code Signature (codesign --force --deep --sign -)...'
			cs_cmd := 'codesign --force --deep --sign - ${os.quoted_path(app_bundle)}'
			cs_res := os.execute(cs_cmd)
			if cs_res.exit_code == 0 {
				logs << '[SUCCESS] Code signing succeeded'
			} else {
				logs << '[WARNING] Code signing warning: ${cs_res.output.trim_space()}'
			}
		}

		// 8. Clear Quarantine Attributes
		if do_quarantine {
			logs << 'Stripping macOS quarantine attributes (xattr -cr)...'
			os.execute('xattr -cr ${os.quoted_path(app_bundle)}')
			logs << '[SUCCESS] Quarantine attributes cleared'
		}

		elapsed := time.since(t0)
		total_size := os.file_size(target_bin)

		logs << '----------------------------------------------------------------------'
		logs << 'BUILD COMPLETE: ${app_name}.app'
		logs << 'Total Time : ${elapsed.milliseconds()}ms (${elapsed.seconds():.2f}s)'
		logs << 'Bundle Size: ${f64(total_size)/1024.0/1024.0:.2f} MB'
		logs << 'Location   : ${app_bundle}'
		logs << '======================================================================'

		w.set_value('txt_bundler_log', logs.join('\n'))
		w.toast('Successfully packaged ${app_name}.app!')
	})

	println('Launching App Bundler Studio Pro Window...')
	win.run()
}

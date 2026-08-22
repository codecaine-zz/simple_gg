#!/usr/bin/env -S v run

import os
import time

struct AppConfig {
	display_name string
	icon_file    string
	bundle_id    string
}

struct IconSize {
	name string
	size int
}

struct Task {
	index        int
	total        int
	app_id       string
	src_path     string
	out_dir      string
	display_name string
	icon_file    string
	bundle_id    string
	is_prod      bool
	bin_only     bool
	c_only       bool
	target_os    string
	target_arch  string
	extra_flags  string
}

struct TaskResult {
	index        int
	total        int
	app_id       string
	display_name string
	out_target   string
	success      bool
	elapsed_ms   i64
	size_mb      f64
	err_msg      string
}

fn get_app_maps() map[string]AppConfig {
	mut m := map[string]AppConfig{}
	m['api_studio.v'] = AppConfig{'API Studio', 'api_client.png', 'com.simplegui.apistudio'}
	m['audiotag_studio.v'] = AppConfig{'Audio Tag Studio', 'audio_editor.png', 'com.simplegui.audiotagstudio'}
	m['brew_studio.v'] = AppConfig{'Brew Studio', 'package_manager.png', 'com.simplegui.brewstudio'}
	m['crypto_studio.v'] = AppConfig{'Crypto Studio', 'security.png', 'com.simplegui.cryptostudio'}
	m['cut_studio.v'] = AppConfig{'Cut Studio', 'utility.png', 'com.simplegui.cutstudio'}
	m['dataconvert_studio.v'] = AppConfig{'Data Convert Studio', 'csv_editor.png', 'com.simplegui.dataconvertstudio'}
	m['disk_studio.v'] = AppConfig{'Disk Studio', 'disk_utility.png', 'com.simplegui.diskstudio'}
	m['dns_studio.v'] = AppConfig{'DNS Studio', 'network_analyzer.png', 'com.simplegui.dnsstudio'}
	m['docker_studio.v'] = AppConfig{'Docker Studio', 'docker_monitor.png', 'com.simplegui.dockerstudio'}
	m['dot_studio.v'] = AppConfig{'Graphviz Studio', 'diagram_maker.png', 'com.simplegui.graphvizstudio'}
	m['exif_studio.v'] = AppConfig{'Exif Studio', 'image_viewer.png', 'com.simplegui.exifstudio'}
	m['fd_studio.v'] = AppConfig{'FD Studio', 'file_manager.png', 'com.simplegui.fdstudio'}
	m['ffmpeg_studio.v'] = AppConfig{'FFmpeg Studio', 'video_editor.png', 'com.simplegui.ffmpegstudio'}
	m['find_studio.v'] = AppConfig{'Find Studio', 'file_manager.png', 'com.simplegui.findstudio'}
	m['gawk_studio.v'] = AppConfig{'GAWK Studio', 'snippet_manager.png', 'com.simplegui.gawkstudio'}
	m['graph_studio.v'] = AppConfig{'Graph Studio', 'drawing_board.png', 'com.simplegui.graphstudio'}
	m['ifconfig_studio.v'] = AppConfig{'IFConfig Studio', 'network_analyzer.png', 'com.simplegui.ifconfigstudio'}
	m['imagemagick_studio.v'] = AppConfig{'ImageMagick Studio', 'image_optimizer.png', 'com.simplegui.imagemagickstudio'}
	m['jq_studio.v'] = AppConfig{'JQ Studio', 'dom_explorer.png', 'com.simplegui.jqstudio'}
	m['kalker_studio.v'] = AppConfig{'Kalker Studio', 'calculator.png', 'com.simplegui.kalkerstudio'}
	m['launchd_studio.v'] = AppConfig{'Launchd Studio', 'task_scheduler.png', 'com.simplegui.launchdstudio'}
	m['media_studio_hub.v'] = AppConfig{'Media Studio Hub', 'media.png', 'com.simplegui.mediastudiohub'}
	m['nmap_studio.v'] = AppConfig{'Nmap Studio', 'security.png', 'com.simplegui.nmapstudio'}
	m['numbat_studio.v'] = AppConfig{'Numbat Studio', 'calculator.png', 'com.simplegui.numbatstudio'}
	m['ocr_studio.v'] = AppConfig{'OCR Studio', 'transcription.png', 'com.simplegui.ocrstudio'}
	m['ouch_studio.v'] = AppConfig{'Ouch Studio', 'archive_manager.png', 'com.simplegui.ouchstudio'}
	m['pandoc_studio.v'] = AppConfig{'Pandoc Studio', 'markdown_editor.png', 'com.simplegui.pandocstudio'}
	m['programmer_calculator.v'] = AppConfig{'Programmer Calculator', 'calculator.png', 'com.simplegui.programmercalculator'}
	m['qalc_studio.v'] = AppConfig{'Qalc Studio', 'calculator.png', 'com.simplegui.qalcstudio'}
	m['recon_studio.v'] = AppConfig{'Recon Studio', 'security.png', 'com.simplegui.reconstudio'}
	m['regex_studio.v'] = AppConfig{'Regex Studio', 'regex_tester.png', 'com.simplegui.regexstudio'}
	m['rg_studio.v'] = AppConfig{'RG Studio', 'snippet_manager.png', 'com.simplegui.rgstudio'}
	m['say_studio.v'] = AppConfig{'Say Studio', 'voice_recorder.png', 'com.simplegui.saystudio'}
	m['sd_studio.v'] = AppConfig{'SD Studio', 'text_editor.png', 'com.simplegui.sdstudio'}
	m['sed_studio.v'] = AppConfig{'Sed Studio', 'text_editor.png', 'com.simplegui.sedstudio'}
	m['sqlite_studio.v'] = AppConfig{'SQLite Studio', 'database_admin.png', 'com.simplegui.sqlitestudio'}
	m['statistics_studio.v'] = AppConfig{'Statistics Studio', 'spreadsheet.png', 'com.simplegui.statisticsstudio'}
	m['subfinder_studio.v'] = AppConfig{'Subfinder Studio', 'network_analyzer.png', 'com.simplegui.subfinderstudio'}
	m['task_manager.v'] = AppConfig{'Task Manager', 'system_monitor.png', 'com.simplegui.taskmanager'}
	m['text_editor.v'] = AppConfig{'Text Editor', 'text_editor.png', 'com.simplegui.texteditor'}
	m['tr_studio.v'] = AppConfig{'TR Studio', 'utility.png', 'com.simplegui.trstudio'}
	m['wget2_studio.v'] = AppConfig{'Wget2 Studio', 'cloud_storage.png', 'com.simplegui.wget2studio'}
	m['yt_dlp_studio.v'] = AppConfig{'YT-DLP Studio', 'screen_recorder.png', 'com.simplegui.ytdlpstudio'}
	return m
}

fn get_host_arch() string {
	$if arm64 {
		return 'arm64'
	} $else $if amd64 {
		return 'x86_64'
	} $else $if arm32 {
		return 'arm'
	} $else $if i386 {
		return 'x86'
	} $else {
		u := os.uname()
		m := u.machine.to_lower()
		if m == 'aarch64' || m == 'arm64' {
			return 'arm64'
		} else if m == 'x86_64' || m == 'amd64' || m == 'x64' {
			return 'x86_64'
		} else if m.len > 0 {
			return m
		}
		return 'x86_64'
	}
}

fn is_wsl_environment() bool {
	if os.getenv('WSL_DISTRO_NAME').len > 0 || os.getenv('WSL_INTEROP').len > 0 {
		return true
	}
	if os.exists('/proc/version') {
		content := os.read_file('/proc/version') or { '' }
		if content.to_lower().contains('microsoft') || content.to_lower().contains('wsl') {
			return true
		}
	}
	return false
}

fn to_clean_identifier(raw string) string {
	mut clean := ''
	for c in raw {
		if c.is_alnum() {
			clean += c.ascii_str()
		}
	}
	return clean.to_lower()
}

fn format_friendly_name(raw string) string {
	mut result := []string{}
	mut cleaned := ''
	for c in raw {
		if c in [`-`, `_`, ` `] {
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

fn ensure_icon_icns(icon_name string, cache_dir string) string {
	if icon_name == '' {
		return ''
	}

	src_png := if os.is_abs_path(icon_name) {
		icon_name
	} else {
		os.join_path(os.getwd(), 'resources', icon_name)
	}

	if !os.exists(src_png) {
		fallback_png := os.join_path(os.getwd(), 'resources', 'icon.png')
		if !os.exists(fallback_png) {
			return ''
		}
		return ensure_icon_icns('icon.png', cache_dir)
	}

	clean_name := os.file_name(src_png).replace('.png', '')
	icns_file := os.join_path(cache_dir, '${clean_name}.icns')

	if os.exists(icns_file) {
		return icns_file
	}

	iconset_dir := os.join_path(cache_dir, '${clean_name}.iconset')
	os.mkdir_all(iconset_dir) or { return '' }

	icon_sizes := [
		IconSize{'icon_16x16.png', 16},
		IconSize{'icon_16x16@2x.png', 32},
		IconSize{'icon_32x32.png', 32},
		IconSize{'icon_32x32@2x.png', 64},
		IconSize{'icon_128x128.png', 128},
		IconSize{'icon_128x128@2x.png', 256},
		IconSize{'icon_256x256.png', 256},
		IconSize{'icon_256x256@2x.png', 512},
		IconSize{'icon_512x512.png', 512},
		IconSize{'icon_512x512@2x.png', 1024},
	]

	for sz_info in icon_sizes {
		out_p := os.join_path(iconset_dir, sz_info.name)
		sips_cmd := 'sips -s format png -z ${sz_info.size} ${sz_info.size} ${os.quoted_path(src_png)} --out ${os.quoted_path(out_p)} > /dev/null 2>&1'
		os.execute(sips_cmd)
	}

	iconutil_cmd := 'iconutil -c icns ${os.quoted_path(iconset_dir)} -o ${os.quoted_path(icns_file)} > /dev/null 2>&1'
	res := os.execute(iconutil_cmd)
	os.rmdir_all(iconset_dir) or {}

	if res.exit_code == 0 && os.exists(icns_file) {
		return icns_file
	}
	return ''
}

fn compile_app(t Task, cached_icns_path string) TaskResult {
	t0 := time.now()

	is_macos_target := t.target_os == 'macos' || t.target_os == 'darwin'
	is_windows_target := t.target_os == 'windows' || t.target_os == 'win'
	host_is_macos := os.user_os() == 'macos'
	make_app_bundle := is_macos_target && host_is_macos && !t.bin_only && !t.c_only

	// 1. C-Only / Transpilation Mode
	if t.c_only {
		out_c := os.join_path(t.out_dir, '${t.app_id}.c')
		mut cmd := 'v '
		if t.is_prod {
			cmd += '-prod -gc none '
		}
		if t.target_os.len > 0 && t.target_os != os.user_os() {
			cmd += '-os ${t.target_os} '
		}
		if t.target_arch.len > 0 {
			cmd += '-arch ${t.target_arch} '
		}
		if t.extra_flags.len > 0 {
			cmd += '${t.extra_flags} '
		}
		cmd += '-o ${os.quoted_path(out_c)} ${os.quoted_path(t.src_path)}'

		res := os.execute(cmd)
		elapsed := time.since(t0)

		if res.exit_code == 0 && os.exists(out_c) {
			sz := os.file_size(out_c)
			return TaskResult{
				index: t.index
				total: t.total
				app_id: t.app_id
				display_name: t.display_name
				out_target: out_c
				success: true
				elapsed_ms: elapsed.milliseconds()
				size_mb: f64(sz) / 1024.0 / 1024.0
				err_msg: ''
			}
		}

		return TaskResult{
			index: t.index
			total: t.total
			app_id: t.app_id
			display_name: t.display_name
			out_target: out_c
			success: false
			elapsed_ms: elapsed.milliseconds()
			size_mb: 0.0
			err_msg: res.output.trim_space()
		}
	}

	// 2. Binary Output Mode (non-macOS, CLI, cross-compile, or --raw)
	if !make_app_bundle {
		bin_ext := if is_windows_target { '.exe' } else { '' }
		out_bin := os.join_path(t.out_dir, '${t.app_id}${bin_ext}')

		mut cmd := 'v '
		if t.is_prod {
			cmd += '-prod -gc none '
		}
		if t.target_os.len > 0 && t.target_os != os.user_os() {
			cmd += '-os ${t.target_os} '
		}
		if t.target_arch.len > 0 {
			cmd += '-arch ${t.target_arch} '
		}
		if t.extra_flags.len > 0 {
			cmd += '${t.extra_flags} '
		}
		cmd += '${os.quoted_path(t.src_path)} -o ${os.quoted_path(out_bin)}'

		res := os.execute(cmd)
		elapsed := time.since(t0)

		if res.exit_code == 0 && os.exists(out_bin) {
			sz := os.file_size(out_bin)
			return TaskResult{
				index: t.index
				total: t.total
				app_id: t.app_id
				display_name: t.display_name
				out_target: out_bin
				success: true
				elapsed_ms: elapsed.milliseconds()
				size_mb: f64(sz) / 1024.0 / 1024.0
				err_msg: ''
			}
		}

		return TaskResult{
			index: t.index
			total: t.total
			app_id: t.app_id
			display_name: t.display_name
			out_target: out_bin
			success: false
			elapsed_ms: elapsed.milliseconds()
			size_mb: 0.0
			err_msg: res.output.trim_space()
		}
	}

	// 3. macOS .app Bundle Setup
	app_bundle := os.join_path(t.out_dir, '${t.display_name}.app')
	contents_dir := os.join_path(app_bundle, 'Contents')
	macos_dir := os.join_path(contents_dir, 'MacOS')
	resources_dir := os.join_path(contents_dir, 'Resources')

	if os.exists(app_bundle) {
		os.rmdir_all(app_bundle) or {}
	}

	os.mkdir_all(macos_dir) or {
		return TaskResult{
			index: t.index
			total: t.total
			app_id: t.app_id
			display_name: t.display_name
			out_target: app_bundle
			success: false
			elapsed_ms: 0
			size_mb: 0.0
			err_msg: 'Failed to create MacOS directory: ${err}'
		}
	}
	os.mkdir_all(resources_dir) or {}

	// Copy AppIcon.icns
	mut has_icon := false
	if cached_icns_path != '' && os.exists(cached_icns_path) {
		dest_icns := os.join_path(resources_dir, 'AppIcon.icns')
		os.cp(cached_icns_path, dest_icns) or {}
		has_icon = true
	}

	// Generate Info.plist
	mut plist_content := '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>English</string>
    <key>CFBundleExecutable</key>
    <string>${t.app_id}</string>
'
	if has_icon {
		plist_content += '    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
'
	}
	plist_content += '    <key>CFBundleIdentifier</key>
    <string>${t.bundle_id}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${t.display_name}</string>
    <key>CFBundleDisplayName</key>
    <string>${t.display_name}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
'
	plist_path := os.join_path(contents_dir, 'Info.plist')
	os.write_file(plist_path, plist_content) or {}

	// Compile Binary into MacOS/
	target_bin := os.join_path(macos_dir, t.app_id)
	mut cmd := 'v '
	if t.is_prod {
		cmd += '-prod -gc none '
	}
	if t.target_arch.len > 0 {
		cmd += '-arch ${t.target_arch} '
	}
	if t.extra_flags.len > 0 {
		cmd += '${t.extra_flags} '
	}
	cmd += '${os.quoted_path(t.src_path)} -o ${os.quoted_path(target_bin)}'

	res := os.execute(cmd)
	if res.exit_code != 0 || !os.exists(target_bin) {
		elapsed := time.since(t0)
		return TaskResult{
			index: t.index
			total: t.total
			app_id: t.app_id
			display_name: t.display_name
			out_target: app_bundle
			success: false
			elapsed_ms: elapsed.milliseconds()
			size_mb: 0.0
			err_msg: res.output.trim_space()
		}
	}

	os.execute('chmod +x ${os.quoted_path(target_bin)}')

	// Code sign & clear quarantine attributes
	os.execute('codesign --force --deep --sign - ${os.quoted_path(app_bundle)} > /dev/null 2>&1')
	os.execute('xattr -cr ${os.quoted_path(app_bundle)} > /dev/null 2>&1')

	elapsed := time.since(t0)
	sz := os.file_size(target_bin)

	return TaskResult{
		index: t.index
		total: t.total
		app_id: t.app_id
		display_name: t.display_name
		out_target: app_bundle
		success: true
		elapsed_ms: elapsed.milliseconds()
		size_mb: f64(sz) / 1024.0 / 1024.0
		err_msg: ''
	}
}

fn print_help() {
	println('======================================================================')
	println('  SimpleGUI Batch Applications Compiler & Packaging Tool')
	println('======================================================================')
	println('Usage: v run compile_apps.vsh [options] [filter]')
	println('')
	println('Target Platform Options:')
	println('  --os <target>           Target OS: macos, linux, windows (default: host OS)')
	println('  --mac, --macos          Target macOS (.app bundles with icons when on macOS)')
	println('  --linux                 Target Linux')
	println('  --wsl                   Target Windows Subsystem for Linux (WSL/WSLg)')
	println('  --win, --windows        Target Windows (.exe binaries)')
	println('')
	println('Architecture Options:')
	println('  --arch <arch>           Target CPU arch: arm64, x86_64, x64, arm, x86')
	println('  --arm64, --aarch64      Target ARM64 (Apple Silicon / Linux ARM64)')
	println('  --x86_64, --x64         Target x86_64 / Intel 64-bit')
	println('  --x86, --m32            Target 32-bit x86')
	println('')
	println('Build & Output Options:')
	println('  -prod, --prod           Compile in optimized production mode (-prod -gc none)')
	println('  --raw, --bin-only       Force raw CLI binary output (no macOS .app bundle)')
	println('  -c, --c-only, --trans   Translate/export to standalone C source code (.c)')
	println('  -cc <compiler>          Set C compiler (e.g. -cc gcc, -cc clang, -cc zig)')
	println('  --flags <flags>         Pass additional flags directly to V compiler')
	println('  -j, --jobs <n>          Number of concurrent compilation jobs (default: 6)')
	println('  -o, --out <dir>         Override output directory (default: bin/<os>_<arch>/)')
	println('  -h, --help              Show this help information')
	println('')
	println('Default Output Directories (by OS & Architecture):')
	println('  macOS ARM64            -> bin/macos_arm64/')
	println('  macOS x86_64           -> bin/macos_x86_64/')
	println('  Linux x86_64           -> bin/linux_x86_64/')
	println('  Linux ARM64            -> bin/linux_arm64/')
	println('  WSL (Linux on Windows) -> bin/wsl_x86_64/')
	println('  Windows x86_64         -> bin/windows_x86_64/')
	println('')
	println('Examples:')
	println('  ./compile_apps.vsh                              # Builds into bin/macos_arm64/')
	println('  ./compile_apps.vsh --prod                       # Production build into bin/macos_arm64/')
	println('  ./compile_apps.vsh --wsl                        # Builds for WSL into bin/wsl_x86_64/')
	println('  ./compile_apps.vsh --wsl --c-only               # Transpiles C code into bin/wsl_x86_64/')
	println('  ./compile_apps.vsh --linux --c-only             # Transpiles C code into bin/linux_x86_64/')
	println('  ./compile_apps.vsh --windows -cc zig            # Cross-compiles into bin/windows_x86_64/')
	println('  ./compile_apps.vsh crypto_studio                # Builds single target')
	println('======================================================================')
}

fn main() {
	mut is_prod := false
	mut bin_only := false
	mut c_only := false
	mut is_wsl_flag := false
	mut target_os := os.user_os()
	mut target_arch := ''
	mut extra_flags := ''
	mut batch_size := 6
	mut target_filter := ''
	mut out_dir_arg := ''

	mut i := 1
	for i < os.args.len {
		arg := os.args[i]
		if arg == '-h' || arg == '--help' || arg == 'help' {
			print_help()
			exit(0)
		} else if arg == '-prod' || arg == '--prod' {
			is_prod = true
		} else if arg == '--raw' || arg == '--bin-only' {
			bin_only = true
		} else if arg == '-c' || arg == '--c-only' || arg == '--trans' || arg == '--transpile' {
			c_only = true
		} else if arg == '--wsl' {
			target_os = 'linux'
			is_wsl_flag = true
		} else if arg == '--linux' {
			target_os = 'linux'
		} else if arg == '--win' || arg == '--windows' {
			target_os = 'windows'
		} else if arg == '--mac' || arg == '--macos' || arg == '--darwin' {
			target_os = 'macos'
		} else if arg == '-os' || arg == '--os' {
			if i + 1 < os.args.len {
				i++
				target_os = os.args[i].to_lower()
				if target_os == 'wsl' {
					target_os = 'linux'
					is_wsl_flag = true
				}
			}
		} else if arg == '--arm64' || arg == '--aarch64' {
			target_arch = 'arm64'
		} else if arg == '--x86_64' || arg == '--x64' {
			target_arch = 'x86_64'
		} else if arg == '--x86' || arg == '--m32' {
			target_arch = 'x86'
		} else if arg == '-arch' || arg == '--arch' {
			if i + 1 < os.args.len {
				i++
				target_arch = os.args[i].to_lower()
			}
		} else if arg == '-cc' || arg == '--cc' {
			if i + 1 < os.args.len {
				i++
				extra_flags += ' -cc ' + os.args[i]
			}
		} else if arg == '--flags' || arg == '-flags' {
			if i + 1 < os.args.len {
				i++
				extra_flags += ' ' + os.args[i]
			}
		} else if arg == '-j' || arg == '--jobs' || arg == '-b' || arg == '--batch' {
			if i + 1 < os.args.len {
				i++
				batch_size = os.args[i].int()
				if batch_size < 1 {
					batch_size = 1
				}
			}
		} else if arg.starts_with('-j') {
			batch_size = arg.replace('-j', '').int()
			if batch_size < 1 {
				batch_size = 1
			}
		} else if arg == '-o' || arg == '--out' {
			if i + 1 < os.args.len {
				i++
				out_dir_arg = os.args[i]
			}
		} else if !arg.starts_with('-') {
			target_filter = arg
		}
		i++
	}

	println('======================================================================')
	println('  SimpleGUI Batch Applications Compiler (Multi-Platform)')
	println('======================================================================')

	is_wsl_env := is_wsl_flag || (target_os == 'linux' && is_wsl_environment())
	effective_os_tag := if is_wsl_env { 'wsl' } else { target_os }
	effective_os_display := if is_wsl_env { 'WSL (Linux on Windows)' } else { target_os.to_upper() }

	effective_arch := if target_arch.len > 0 {
		target_arch
	} else if target_os == os.user_os() {
		get_host_arch()
	} else {
		'x86_64'
	}

	cwd := os.getwd()
	app_dir := os.join_path(cwd, 'applications')
	
	platform_folder := '${effective_os_tag}_${effective_arch}'
	out_dir := if out_dir_arg.len > 0 {
		if os.is_abs_path(out_dir_arg) { out_dir_arg } else { os.join_path(cwd, out_dir_arg) }
	} else {
		os.join_path(cwd, 'bin', platform_folder)
	}

	icon_cache_dir := os.join_path(cwd, 'bin', '.icon_cache')

	os.mkdir_all(out_dir) or {
		eprintln('Failed to create output directory: ${out_dir}')
		exit(1)
	}

	raw_files := os.ls(app_dir) or {
		eprintln('Failed to list applications directory: ${app_dir}')
		exit(1)
	}

	mut app_files := []string{}
	for f in raw_files {
		if f.ends_with('.v') && !f.ends_with('_test.v') {
			if target_filter.len == 0 || f.contains(target_filter) {
				app_files << f
			}
		}
	}
	app_files.sort()

	if app_files.len == 0 {
		println('No matching application files found in ${app_dir}')
		exit(0)
	}

	app_maps := get_app_maps()
	host_is_macos := os.user_os() == 'macos'
	is_app_mode := target_os == 'macos' && host_is_macos && !bin_only && !c_only

	// Preflight Linux ARM64 cross-compiler check
	if target_os == 'linux' && effective_arch == 'arm64' && os.user_os() != 'linux' && !c_only {
		eprintln('\n❌ Notice: V\'s bundled sysroot for direct Linux cross-compilation on macOS supports `-arch x86_64` (amd64).')
		eprintln('To build for Linux ARM64 (Raspberry Pi, ARM servers, AWS Graviton):')
		eprintln('1. Export standalone C source files (Recommended):')
		eprintln('   ./compile_apps.vsh --linux --arm64 --c-only')
		eprintln('   (Copy bin/linux_arm64/*.c to your ARM64 device and compile with `gcc`)\n')
		eprintln('2. Or compile natively inside an ARM64 Linux machine / Docker container:')
		eprintln('   ./compile_apps.vsh\n')
		exit(1)
	}

	// Preflight Windows cross-compiler check
	if target_os == 'windows' && os.user_os() != 'windows' && !c_only {
		has_zig := os.exists_in_system_path('zig')
		has_mingw := os.exists_in_system_path('x86_64-w64-mingw32-gcc')
		if extra_flags.contains('zig') && !has_zig {
			eprintln('\n❌ Error: `zig` was requested (`-cc zig`) but was not found in your PATH!')
			eprintln('To cross-compile for Windows via Zig, install it with Homebrew:')
			eprintln('   brew install zig')
			eprintln('\nAlternatively, export standalone C source files without needing cross-compilers:')
			eprintln('   ./compile_apps.vsh --windows --c-only\n')
			exit(1)
		} else if !has_zig && !has_mingw {
			eprintln('\n❌ Error: No Windows cross-compiler found (neither `zig` nor `x86_64-w64-mingw32-gcc`).')
			eprintln('To cross-compile Windows .exe binaries from macOS, install a cross-compiler:')
			eprintln('   brew install zig')
			eprintln('   # or:')
			eprintln('   brew install mingw-w64')
			eprintln('\nAlternatively, export standalone C source files without needing cross-compilers:')
			eprintln('   ./compile_apps.vsh --windows --c-only\n')
			exit(1)
		}
	}

	// Pre-generate / cache required icons (only if generating macOS bundles)
	mut icon_lookup := map[string]string{}
	if is_app_mode {
		os.mkdir_all(icon_cache_dir) or {}
		println('🎨 Pre-generating and caching application .icns icons...')
		for f in app_files {
			config := app_maps[f] or {
				AppConfig{format_friendly_name(f.replace('.v', '')), 'icon.png', 'com.simplegui.${to_clean_identifier(f.replace('.v', ''))}'}
			}
			if config.icon_file !in icon_lookup {
				icns_path := ensure_icon_icns(config.icon_file, icon_cache_dir)
				icon_lookup[config.icon_file] = icns_path
			}
		}
		println('   Cached ${icon_lookup.len} unique .icns icon assets.')
	}

	mode_str := if is_prod { 'PRODUCTION (-prod)' } else { 'FAST BUILD' }

	target_type_str := if c_only {
		'C Source Translation (.c files)'
	} else if is_app_mode {
		'macOS Native .app Bundles'
	} else if target_os == 'windows' || target_os == 'win' {
		'Windows Binaries (.exe)'
	} else if is_wsl_env {
		'WSL / Linux Binaries (ELF)'
	} else if target_os == 'linux' {
		'Linux Binaries (ELF)'
	} else {
		'CLI Binaries (${target_os})'
	}

	println('Source Directory : ${app_dir}')
	println('Target Platform  : ${effective_os_display} (${effective_arch.to_upper()})')
	println('Output Directory : ${out_dir}')
	println('Target Format    : ${target_type_str}')
	println('Build Mode       : ${mode_str}')
	if extra_flags.len > 0 {
		println('Compiler Flags   :${extra_flags}')
	}
	println('Concurrent Batch : ${batch_size} parallel jobs')
	println('Total Targets    : ${app_files.len}')
	println('----------------------------------------------------------------------')

	mut tasks := []Task{}
	for idx, f in app_files {
		raw_id := f.replace('.v', '')
		config := app_maps[f] or {
			AppConfig{format_friendly_name(raw_id), 'icon.png', 'com.simplegui.${to_clean_identifier(raw_id)}'}
		}

		tasks << Task{
			index: idx + 1
			total: app_files.len
			app_id: raw_id
			src_path: os.join_path('applications', f)
			out_dir: out_dir
			display_name: config.display_name
			icon_file: config.icon_file
			bundle_id: config.bundle_id
			is_prod: is_prod
			bin_only: bin_only
			c_only: c_only
			target_os: target_os
			target_arch: target_arch
			extra_flags: extra_flags
		}
	}

	mut success_count := 0
	mut fail_count := 0
	mut had_cross_egl_fail := false
	start_total := time.now()

	// Process in concurrent batches
	mut offset := 0
	for offset < tasks.len {
		end := if offset + batch_size > tasks.len { tasks.len } else { offset + batch_size }
		batch_tasks := tasks[offset..end].clone()
		batch_num := (offset / batch_size) + 1
		total_batches := ((tasks.len + batch_size - 1) / batch_size)

		println('--> Launching Batch ${batch_num}/${total_batches} (${batch_tasks.len} apps concurrent)...')

		mut threads := []thread TaskResult{}
		for t in batch_tasks {
			cached_icns := icon_lookup[t.icon_file] or { '' }
			threads << spawn compile_app(t, cached_icns)
		}

		results := threads.wait()
		for r in results {
			target_name := if c_only {
				'${r.app_id}.c'
			} else if is_app_mode {
				'${r.display_name}.app'
			} else if target_os == 'windows' || target_os == 'win' {
				'${r.app_id}.exe'
			} else {
				r.app_id
			}

			if r.success {
				println('   [${r.index:02d}/${r.total:02d}] OK   ${target_name:-30s} (${r.elapsed_ms}ms, ${r.size_mb:.2f} MB)')
				success_count++
			} else {
				println('   [${r.index:02d}/${r.total:02d}] FAIL ${target_name:-30s} (${r.elapsed_ms}ms)')
				if r.err_msg.len > 0 {
					eprintln('        Error: ${r.err_msg}')
				}
				if r.err_msg.contains('EGL/egl.h') || r.err_msg.contains('X11') || r.err_msg.contains('mingw') {
					had_cross_egl_fail = true
				}
				fail_count++
			}
		}

		offset = end
	}

	total_elapsed := time.since(start_total)
	println('======================================================================')
	println('Build Summary:')
	println('  Success   : ${success_count} / ${app_files.len}')
	if fail_count > 0 {
		println('  Failed    : ${fail_count}')
	}
	println('  Total Time: ${total_elapsed.milliseconds()}ms (${total_elapsed.seconds():.2f}s)')
	println('  Output    : ${out_dir}/')
	println('======================================================================')

	if had_cross_egl_fail {
		println('\n💡 Note on WSL / Linux Cross-Compilation:')
		println('  SimpleGUI utilizes Sokol & OpenGL/Metal which require target OS system graphics headers.')
		println('  When compiling for WSL / Linux:')
		println('  1. Generate standalone C source files with --c-only:')
		println('     ./compile_apps.vsh --wsl --c-only')
		println('     (You can compile directly inside WSL with gcc!)')
		println('  2. Inside WSL, install graphics development libraries:')
		println('     sudo apt update && sudo apt install -y libx11-dev libxi-dev libxcursor-dev libgl-dev libegl1-mesa-dev libasound2-dev')
		println('  3. Compile natively inside WSL:')
		println('     ./compile_apps.vsh --wsl')
		println('======================================================================\n')
	}

	if fail_count > 0 {
		exit(1)
	}
}

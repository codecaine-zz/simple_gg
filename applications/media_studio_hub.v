module main

import os
import simplegui

fn check_bin(name string, fallbacks []string) (bool, string) {
	if path := os.find_abs_path_of_executable(name) {
		return true, path
	}
	for p in fallbacks {
		if os.exists(p) {
			return true, p
		}
	}
	return false, 'Not found'
}

fn main() {
	println('Starting SimpleGUI - Media & Data Studio Hub (Async Non-Blocking Engine)...')

	mut win := simplegui.new_simple_window('SimpleGUI - Media & Data Studio Hub', 1180, 980)
	win.set_fullscreen(true)
	win.restore_saved_theme()
	win.set_spacing(6)
	win.set_padding(14)

	// -------------------------------------------------------------
	// Top Header Section
	// -------------------------------------------------------------
	win.begin_row('row_hub_top')
	win.add_heading('SimpleGUI Media & Data Studio Hub')
	win.add_label('lbl_theme_select', 'Theme:')
	saved_theme := simplegui.get_saved_theme()
	win.add_dropdown('dd_hub_theme', simplegui.list_themes(), saved_theme)
	win.set_control_width('dd_hub_theme', 160)
	win.end_row()

	win.add_label('lbl_sub', 'Unified macOS Native Engineering Suite for Media, Security, Data, DevOps & Computing (45 Workstations)')

	// -------------------------------------------------------------
	// System Diagnostics Bar
	// -------------------------------------------------------------
	has_ffmpeg, ffmpeg_path := check_bin('ffmpeg', ['/opt/homebrew/bin/ffmpeg', '/opt/homebrew/opt/ffmpeg-full/bin/ffmpeg', '/usr/local/bin/ffmpeg'])
	has_ffprobe, ffprobe_path := check_bin('ffprobe', ['/opt/homebrew/bin/ffprobe', '/opt/homebrew/opt/ffmpeg-full/bin/ffprobe', '/usr/local/bin/ffprobe'])
	has_magick, magick_path := check_bin('magick', ['/opt/homebrew/bin/magick', '/opt/homebrew/opt/imagemagick-full/bin/magick', '/usr/local/bin/magick', '/opt/homebrew/bin/convert', '/usr/local/bin/convert'])
	_, identify_path := check_bin('identify', ['/opt/homebrew/bin/identify', '/opt/homebrew/opt/imagemagick-full/bin/identify', '/usr/local/bin/identify'])
	has_gawk, _ := check_bin('gawk', ['/opt/homebrew/bin/gawk', '/usr/local/bin/gawk', '/usr/bin/awk', '/bin/awk'])
	has_sd, _ := check_bin('sd', ['/opt/homebrew/bin/sd', '/usr/local/bin/sd', '/bin/sd'])
	has_subfinder, _ := check_bin('subfinder', ['/opt/homebrew/bin/subfinder', '/usr/local/bin/subfinder', '/bin/subfinder'])
	has_ytdlp, _ := check_bin('yt-dlp', ['/opt/homebrew/bin/yt-dlp', '/usr/local/bin/yt-dlp', '/bin/yt-dlp'])
	has_wget2, _ := check_bin('wget2', ['/opt/homebrew/bin/wget2', '/usr/local/bin/wget2', '/opt/homebrew/bin/wget', '/usr/local/bin/wget', '/bin/wget'])
	has_pandoc, _ := check_bin('pandoc', ['/opt/homebrew/bin/pandoc', '/usr/local/bin/pandoc', '/bin/pandoc'])
	has_fd, _ := check_bin('fd', ['/opt/homebrew/bin/fd', '/usr/local/bin/fd', '/bin/fd', '/usr/bin/fdfind'])
	has_rg, _ := check_bin('rg', ['/opt/homebrew/bin/rg', '/usr/local/bin/rg', '/bin/rg', '/usr/bin/rg'])
	has_cut, _ := check_bin('cut', ['/usr/bin/cut', '/bin/cut', '/opt/homebrew/bin/gcut'])
	has_tr, _ := check_bin('tr', ['/usr/bin/tr', '/bin/tr', '/opt/homebrew/bin/gtr'])
	has_say, _ := check_bin('say', ['/usr/bin/say', '/bin/say'])
	has_find, _ := check_bin('find', ['/usr/bin/find', '/bin/find', '/opt/homebrew/bin/gfind'])
	has_ouch, _ := check_bin('ouch', ['/opt/homebrew/bin/ouch', '/usr/local/bin/ouch', '/usr/bin/ouch'])
	has_sed, _ := check_bin('sed', ['/usr/bin/sed', '/bin/sed', '/opt/homebrew/bin/gsed'])
	has_qalc, _ := check_bin('qalc', ['/opt/homebrew/bin/qalc', '/usr/local/bin/qalc', '/usr/bin/qalc'])
	has_numbat, _ := check_bin('numbat', ['/opt/homebrew/bin/numbat', '/usr/local/bin/numbat'])
	has_kalker, _ := check_bin('kalker', ['/opt/homebrew/bin/kalker', '/usr/local/bin/kalker'])

	win.begin_group_box('grp_env', 'Core CLI Engines & macOS Subsystems Status')
	win.begin_row('row_env_1')
	win.add_label('lbl_stat_ffmpeg', if has_ffmpeg { ' FFmpeg' } else { ' FFmpeg' })
	win.add_label('lbl_stat_ffprobe', if has_ffprobe { ' FFprobe' } else { ' FFprobe' })
	win.add_label('lbl_stat_magick', if has_magick { ' ImageMagick' } else { ' Magick' })
	win.add_label('lbl_stat_gawk', if has_gawk { ' GAWK' } else { ' GAWK' })
	win.add_label('lbl_stat_sd', if has_sd { ' SD' } else { ' SD' })
	win.add_label('lbl_stat_say', if has_say { ' Say' } else { ' Say' })
	win.add_label('lbl_stat_find', if has_find { ' find' } else { ' find' })
	win.add_label('lbl_stat_cut', if has_cut { ' cut' } else { ' cut' })
	win.add_label('lbl_stat_tr', if has_tr { ' tr' } else { ' tr' })
	win.add_label('lbl_stat_rg', if has_rg { ' ripgrep' } else { ' ripgrep' })
	win.add_label('lbl_stat_fd', if has_fd { ' FD' } else { ' FD' })
	win.add_label('lbl_stat_sed', if has_sed { ' sed' } else { ' sed' })
	win.add_label('lbl_stat_ouch', if has_ouch { ' ouch' } else { ' ouch' })
	win.add_label('lbl_stat_subf', if has_subfinder { ' Subfinder' } else { ' Subfinder' })
	win.add_label('lbl_stat_ytdlp', if has_ytdlp { ' yt-dlp' } else { ' yt-dlp' })
	win.add_label('lbl_stat_wget2', if has_wget2 { ' Wget2' } else { ' Wget2' })
	win.add_label('lbl_stat_pandoc', if has_pandoc { ' Pandoc' } else { ' Pandoc' })
	win.add_label('lbl_stat_qalc', if has_qalc { ' qalc' } else { ' qalc' })
	win.add_label('lbl_stat_numbat', if has_numbat { ' numbat' } else { ' numbat' })
	win.add_label('lbl_stat_kalker', if has_kalker { ' kalker' } else { ' kalker' })
	win.end_row()
	win.end_group_box()

	// -------------------------------------------------------------
	// Dedicated Studio Workstations (5 Categorized Workstation Blocks)
	// -------------------------------------------------------------
	win.begin_group_box('grp_launchers', 'Dedicated Studio Workstations (Click to Launch Independent Workspace)')
	
	// Category 1: Files, Search & Text Processing
	win.begin_row('row_apps_1')
	win.add_label('lbl_cat_1', 'Files & Text:')
	win.add_button('btn_launch_editor', 'Text Editor')
	win.add_button('btn_launch_taskman', 'Task Manager')
	win.add_button('btn_launch_ouch', 'Ouch Archives')
	win.add_button('btn_launch_sed', 'Sed Studio')
	win.add_button('btn_launch_cut', 'Cut Studio')
	win.add_button('btn_launch_tr', 'TR Studio')
	win.add_button('btn_launch_rg', 'Ripgrep')
	win.add_button('btn_launch_fd', 'FD Finder')
	win.add_button('btn_launch_find', 'Find Inodes')
	win.end_row()

	// Category 2: Media, Creative & Publishing
	win.begin_row('row_apps_2')
	win.add_label('lbl_cat_2', 'Media & Creative:')
	win.add_button('btn_launch_ffmpeg', 'FFmpeg Studio')
	win.add_button('btn_launch_magick', 'ImageMagick')
	win.add_button('btn_launch_ytdlp', 'Download yt-dlp Archiver')
	win.add_button('btn_launch_audiotag', 'Audio Tag Studio')
	win.add_button('btn_launch_ocr', 'Tesseract OCR')
	win.add_button('btn_launch_exif', 'ExifTool Studio')
	win.add_button('btn_launch_say', 'Say Voiceover')
	win.add_button('btn_launch_pandoc', 'Pandoc Docs')
	win.end_row()

	// Category 3: Data Engineering & Querying
	win.begin_row('row_apps_3')
	win.add_label('lbl_cat_3', 'Data & Query:')
	win.add_button('btn_launch_jq', 'JQ Studio')
	win.add_button('btn_launch_convert', 'Format Converter')
	win.add_button('btn_launch_sqlite', 'SQLite Studio')
	win.add_button('btn_launch_regex', 'Regex Studio')
	win.add_button('btn_launch_gawk', 'GAWK Engine')
	win.add_button('btn_launch_sd', 'SD Replace')
	win.add_button('btn_launch_dot', 'Graphviz Studio')
	win.end_row()

	// Category 4: Security, Network & DevOps
	win.begin_row('row_apps_4')
	win.add_label('lbl_cat_4', 'Security & DevOps:')
	win.add_button('btn_launch_api', 'API Studio')
	win.add_button('btn_launch_nmap', 'Nmap Scanner')
	win.add_button('btn_launch_dns', 'DNS & SSL')
	win.add_button('btn_launch_recon', 'Recon Studio')
	win.add_button('btn_launch_subfinder', 'Subfinder')
	win.add_button('btn_launch_ifconfig', 'IFConfig IP')
	win.add_button('btn_launch_crypto', 'Crypto & Hash')
	win.add_button('btn_launch_brew', 'Homebrew')
	win.add_button('btn_launch_docker', 'Docker')
	win.add_button('btn_launch_disk', 'Disk Space')
	win.add_button('btn_launch_launchd', 'Launchd & Cron')
	win.end_row()

	// Category 5: Mathematics, Science & Computation
	win.begin_row('row_apps_5')
	win.add_label('lbl_cat_5', 'Math & Science:')
	win.add_button('btn_launch_progcalc', 'Prog Calc Pro')
	win.add_button('btn_launch_graph', 'Graph Studio Pro')
	win.add_button('btn_launch_stats', 'Statistics Studio')
	win.add_button('btn_launch_qalc', 'Qalc Symbolic')
	win.add_button('btn_launch_numbat', 'Numbat Physics')
	win.add_button('btn_launch_kalker', 'Kalker Calculus')
	win.add_button('btn_launch_wget2', 'Wget2 Accelerator')
	win.end_row()

	win.end_group_box()

	// -------------------------------------------------------------
	// Quick Tools Suite
	// -------------------------------------------------------------
	win.begin_group_box('grp_quick', 'Instant Quick Tools (Async Non-Blocking)')
	
	win.begin_row('row_quick_in')
	win.add_label('lbl_quick_file', 'Target File:')
	win.add_input('txt_quick_in', '')
	win.set_control_width('txt_quick_in', 580)
	win.add_button('btn_quick_browse', 'Pick File...')
	win.add_button('btn_q_info', 'Inspect')
	win.end_row()

	// Video & Audio Quick Tools
	win.begin_row('row_quick_btns_1')
	win.add_button('btn_q_mp4', 'Convert to MP4')
	win.add_button('btn_q_discord', 'Discord Size (<10MB)')
	win.add_button('btn_q_reels', 'TikTok / Reels (9:16)')
	win.add_button('btn_q_mp3', 'Extract MP3')
	win.add_button('btn_q_loudnorm', 'Loudnorm Audio')
	win.end_row()

	// Image & Graphic Quick Tools
	win.begin_row('row_quick_btns_2')
	win.add_button('btn_q_webp', 'Compress to WebP')
	win.add_button('btn_q_ico', 'Make Favicon.ico')
	win.add_button('btn_q_nobg', 'Remove White BG')
	win.add_button('btn_q_gif', 'Video to HD GIF')
	win.add_button('btn_q_resize', 'Resize 50%')
	win.end_row()
	win.end_group_box()

	// -------------------------------------------------------------
	// Activity & Operations Log
	// -------------------------------------------------------------
	win.begin_row('row_log_head')
	win.add_label('lbl_log', 'Activity & Operations Log:')
	win.add_button('btn_open_finder', 'Open Containing Folder')
	win.add_button('btn_clear_hub_log', 'Clear')
	win.end_row()

	win.add_console('hub_log', 135)

	win.append_console('hub_log', ' SimpleGUI Media & Data Studio Hub Initialized.\n', 1)
	if has_ffmpeg && has_magick && has_gawk {
		win.append_console('hub_log', ' All engineering CLI engines are online and ready!\n', 4)
	} else {
		win.append_console('hub_log', 'Tip: Some tools may require brew install.\n', 2)
	}

	// -------------------------------------------------------------
	// Events & Logic (All Async Background Dispatched)
	// -------------------------------------------------------------

	// Theme Change
	win.on_change('dd_hub_theme', fn (mut w simplegui.SimpleWindow, selected string) {
		w.set_theme(selected)
		w.toast('Theme changed to ${selected}')
	})

	// Launch Text Editor
	win.on_click('btn_launch_editor', fn (mut w simplegui.SimpleWindow) {
		app_path := os.join_path(os.dir(@FILE), 'text_editor.v')
		w.append_console('hub_log', ' Launching Text Editor Pro in background...\n', 1)
		go fn [app_path] () {
			simplegui.exec_safe('v', ['run', app_path])
		}()
		w.toast('Text Editor Pro launched!')
	})

	// Launch Task Manager
	win.on_click('btn_launch_taskman', fn (mut w simplegui.SimpleWindow) {
		app_path := os.join_path(os.dir(@FILE), 'task_manager.v')
		w.append_console('hub_log', ' Launching Task Manager Pro in background...\n', 1)
		go fn [app_path] () {
			simplegui.exec_safe('v', ['run', app_path])
		}()
		w.toast('Task Manager Pro launched!')
	})

	// Launch Sed Studio
	win.on_click('btn_launch_sed', fn (mut w simplegui.SimpleWindow) {
		app_path := os.join_path(os.dir(@FILE), 'sed_studio.v')
		w.append_console('hub_log', ' Launching Sed Studio Pro in background...\n', 1)
		go fn [app_path] () {
			simplegui.exec_safe('v', ['run', app_path])
		}()
		w.toast('Sed Studio Pro launched!')
	})

	// Launch Ouch Studio
	win.on_click('btn_launch_ouch', fn (mut w simplegui.SimpleWindow) {
		app_path := os.join_path(os.dir(@FILE), 'ouch_studio.v')
		w.append_console('hub_log', ' Launching Ouch Studio Pro in background...\n', 1)
		go fn [app_path] () {
			simplegui.exec_safe('v', ['run', app_path])
		}()
		w.toast('Ouch Studio Pro launched!')
	})

	// Launch Cut Studio
	win.on_click('btn_launch_cut', fn (mut w simplegui.SimpleWindow) {
		app_path := os.join_path(os.dir(@FILE), 'cut_studio.v')
		w.append_console('hub_log', ' Launching Cut Studio Pro in background...\n', 1)
		go fn [app_path] () {
			simplegui.exec_safe('v', ['run', app_path])
		}()
		w.toast('Cut Studio Pro launched!')
	})

	// Launch TR Studio
	win.on_click('btn_launch_tr', fn (mut w simplegui.SimpleWindow) {
		app_path := os.join_path(os.dir(@FILE), 'tr_studio.v')
		w.append_console('hub_log', ' Launching TR Studio Pro in background...\n', 1)
		go fn [app_path] () {
			simplegui.exec_safe('v', ['run', app_path])
		}()
		w.toast('TR Studio Pro launched!')
	})

	// Launch ripgrep Studio
	win.on_click('btn_launch_rg', fn (mut w simplegui.SimpleWindow) {
		app_path := os.join_path(os.dir(@FILE), 'rg_studio.v')
		w.append_console('hub_log', ' Launching RG Studio Pro in background...\n', 1)
		go fn [app_path] () {
			simplegui.exec_safe('v', ['run', app_path])
		}()
		w.toast('RG Studio Pro launched!')
	})

	// Launch FD Studio
	win.on_click('btn_launch_fd', fn (mut w simplegui.SimpleWindow) {
		app_path := os.join_path(os.dir(@FILE), 'fd_studio.v')
		w.append_console('hub_log', ' Launching FD Studio Pro in background...\n', 1)
		go fn [app_path] () {
			simplegui.exec_safe('v', ['run', app_path])
		}()
		w.toast('FD Studio Pro launched!')
	})

	// Launch Find Studio
	win.on_click('btn_launch_find', fn (mut w simplegui.SimpleWindow) {
		app_path := os.join_path(os.dir(@FILE), 'find_studio.v')
		w.append_console('hub_log', ' Launching Find Studio Pro in background...\n', 1)
		go fn [app_path] () {
			simplegui.exec_safe('v', ['run', app_path])
		}()
		w.toast('Find Studio Pro launched!')
	})

	// Launch IFConfig Studio
	win.on_click('btn_launch_ifconfig', fn (mut w simplegui.SimpleWindow) {
		app_path := os.join_path(os.dir(@FILE), 'ifconfig_studio.v')
		w.append_console('hub_log', ' Launching IFConfig Studio Pro in background...\n', 1)
		go fn [app_path] () {
			simplegui.exec_safe('v', ['run', app_path])
		}()
		w.toast('IFConfig Studio Pro launched!')
	})

	// Launch Qalc Studio
	win.on_click('btn_launch_qalc', fn (mut w simplegui.SimpleWindow) {
		app_path := os.join_path(os.dir(@FILE), 'qalc_studio.v')
		w.append_console('hub_log', ' Launching Qalc Studio Pro in background...\n', 1)
		go fn [app_path] () {
			simplegui.exec_safe('v', ['run', app_path])
		}()
		w.toast('Qalc Studio Pro launched!')
	})

	// Launch Numbat Studio
	win.on_click('btn_launch_numbat', fn (mut w simplegui.SimpleWindow) {
		app_path := os.join_path(os.dir(@FILE), 'numbat_studio.v')
		w.append_console('hub_log', ' Launching Numbat Studio Pro in background...\n', 1)
		go fn [app_path] () {
			simplegui.exec_safe('v', ['run', app_path])
		}()
		w.toast('Numbat Studio Pro launched!')
	})

	// Launch Kalker Studio
	win.on_click('btn_launch_kalker', fn (mut w simplegui.SimpleWindow) {
		app_path := os.join_path(os.dir(@FILE), 'kalker_studio.v')
		w.append_console('hub_log', ' Launching Kalker Studio Pro in background...\n', 1)
		go fn [app_path] () {
			simplegui.exec_safe('v', ['run', app_path])
		}()
		w.toast('Kalker Studio Pro launched!')
	})

	// Launch Statistics Studio
	win.on_click('btn_launch_stats', fn (mut w simplegui.SimpleWindow) {
		app_path := os.join_path(os.dir(@FILE), 'statistics_studio.v')
		w.append_console('hub_log', ' Launching Statistics Studio Pro in background...\n', 1)
		go fn [app_path] () {
			simplegui.exec_safe('v', ['run', app_path])
		}()
		w.toast('Statistics Studio Pro launched!')
	})

	// Launch Programmer's Calculator
	win.on_click('btn_launch_progcalc', fn (mut w simplegui.SimpleWindow) {
		app_path := os.join_path(os.dir(@FILE), 'programmer_calculator.v')
		w.append_console('hub_log', ' Launching Programmer\'s Calculator Pro in background...\n', 1)
		go fn [app_path] () {
			simplegui.exec_safe('v', ['run', app_path])
		}()
		w.toast('Programmer\'s Calculator Pro launched!')
	})

	// Launch Graph Studio
	win.on_click('btn_launch_graph', fn (mut w simplegui.SimpleWindow) {
		app_path := os.join_path(os.dir(@FILE), 'graph_studio.v')
		w.append_console('hub_log', ' Launching Graph Studio Pro in background...\n', 1)
		go fn [app_path] () {
			simplegui.exec_safe('v', ['run', app_path])
		}()
		w.toast('Graph Studio Pro launched!')
	})

	// Launch FFmpeg Studio
	win.on_click('btn_launch_ffmpeg', fn (mut w simplegui.SimpleWindow) {
		app_path := os.join_path(os.dir(@FILE), 'ffmpeg_studio.v')
		w.append_console('hub_log', ' Launching FFmpeg Studio Pro in background...\n', 1)
		go fn [app_path] () {
			simplegui.exec_safe('v', ['run', app_path])
		}()
		w.toast('FFmpeg Studio Pro launched!')
	})

	// Launch ImageMagick Studio
	win.on_click('btn_launch_magick', fn (mut w simplegui.SimpleWindow) {
		app_path := os.join_path(os.dir(@FILE), 'imagemagick_studio.v')
		w.append_console('hub_log', ' Launching ImageMagick Studio Pro in background...\n', 1)
		go fn [app_path] () {
			simplegui.exec_safe('v', ['run', app_path])
		}()
		w.toast('ImageMagick Studio Pro launched!')
	})

	// Launch GAWK Studio
	win.on_click('btn_launch_gawk', fn (mut w simplegui.SimpleWindow) {
		app_path := os.join_path(os.dir(@FILE), 'gawk_studio.v')
		w.append_console('hub_log', ' Launching GAWK Studio Pro in background...\n', 1)
		go fn [app_path] () {
			simplegui.exec_safe('v', ['run', app_path])
		}()
		w.toast('GAWK Studio Pro launched!')
	})

	// Launch SD Studio
	win.on_click('btn_launch_sd', fn (mut w simplegui.SimpleWindow) {
		app_path := os.join_path(os.dir(@FILE), 'sd_studio.v')
		w.append_console('hub_log', ' Launching SD Studio Pro in background...\n', 1)
		go fn [app_path] () {
			simplegui.exec_safe('v', ['run', app_path])
		}()
		w.toast('SD Studio Pro launched!')
	})

	// Launch Say Studio
	win.on_click('btn_launch_say', fn (mut w simplegui.SimpleWindow) {
		app_path := os.join_path(os.dir(@FILE), 'say_studio.v')
		w.append_console('hub_log', ' Launching Say Studio Pro in background...\n', 1)
		go fn [app_path] () {
			simplegui.exec_safe('v', ['run', app_path])
		}()
		w.toast('Say Studio Pro launched!')
	})

	// Launch Subfinder Studio
	win.on_click('btn_launch_subfinder', fn (mut w simplegui.SimpleWindow) {
		app_path := os.join_path(os.dir(@FILE), 'subfinder_studio.v')
		w.append_console('hub_log', ' Launching Subfinder Studio Pro in background...\n', 1)
		go fn [app_path] () {
			simplegui.exec_safe('v', ['run', app_path])
		}()
		w.toast('Subfinder Studio Pro launched!')
	})

	// Launch yt-dlp Studio
	win.on_click('btn_launch_ytdlp', fn (mut w simplegui.SimpleWindow) {
		app_path := os.join_path(os.dir(@FILE), 'yt_dlp_studio.v')
		w.append_console('hub_log', ' Launching yt-dlp Studio Pro in background...\n', 1)
		go fn [app_path] () {
			simplegui.exec_safe('v', ['run', app_path])
		}()
		w.toast('yt-dlp Studio Pro launched!')
	})

	// Launch Wget2 Studio
	win.on_click('btn_launch_wget2', fn (mut w simplegui.SimpleWindow) {
		app_path := os.join_path(os.dir(@FILE), 'wget2_studio.v')
		w.append_console('hub_log', ' Launching Wget2 Studio Pro in background...\n', 1)
		go fn [app_path] () {
			simplegui.exec_safe('v', ['run', app_path])
		}()
		w.toast('Wget2 Studio Pro launched!')
	})

	// Launch Pandoc Studio
	win.on_click('btn_launch_pandoc', fn (mut w simplegui.SimpleWindow) {
		app_path := os.join_path(os.dir(@FILE), 'pandoc_studio.v')
		w.append_console('hub_log', ' Launching Pandoc Studio Pro in background...\n', 1)
		go fn [app_path] () {
			simplegui.exec_safe('v', ['run', app_path])
		}()
		w.toast('Pandoc Studio Pro launched!')
	})

	// Launch API Studio
	win.on_click('btn_launch_api', fn (mut w simplegui.SimpleWindow) {
		app_path := os.join_path(os.dir(@FILE), 'api_studio.v')
		w.append_console('hub_log', ' Launching API Studio Pro in background...\n', 1)
		go fn [app_path] () {
			simplegui.exec_safe('v', ['run', app_path])
		}()
		w.toast('API Studio Pro launched!')
	})

	// Launch Nmap Studio
	win.on_click('btn_launch_nmap', fn (mut w simplegui.SimpleWindow) {
		app_path := os.join_path(os.dir(@FILE), 'nmap_studio.v')
		w.append_console('hub_log', ' Launching Nmap Studio Pro in background...\n', 1)
		go fn [app_path] () {
			simplegui.exec_safe('v', ['run', app_path])
		}()
		w.toast('Nmap Studio Pro launched!')
	})

	// Launch DNS & SSL Studio
	win.on_click('btn_launch_dns', fn (mut w simplegui.SimpleWindow) {
		app_path := os.join_path(os.dir(@FILE), 'dns_studio.v')
		w.append_console('hub_log', ' Launching DNS & SSL Studio Pro in background...\n', 1)
		go fn [app_path] () {
			simplegui.exec_safe('v', ['run', app_path])
		}()
		w.toast('DNS & SSL Studio Pro launched!')
	})

	// Launch Recon Studio
	win.on_click('btn_launch_recon', fn (mut w simplegui.SimpleWindow) {
		app_path := os.join_path(os.dir(@FILE), 'recon_studio.v')
		w.append_console('hub_log', ' Launching Recon Studio Pro in background...\n', 1)
		go fn [app_path] () {
			simplegui.exec_safe('v', ['run', app_path])
		}()
		w.toast('Recon Studio Pro launched!')
	})

	// Launch Crypto Studio
	win.on_click('btn_launch_crypto', fn (mut w simplegui.SimpleWindow) {
		app_path := os.join_path(os.dir(@FILE), 'crypto_studio.v')
		w.append_console('hub_log', ' Launching Crypto & Hash Studio Pro in background...\n', 1)
		go fn [app_path] () {
			simplegui.exec_safe('v', ['run', app_path])
		}()
		w.toast('Crypto & Hash Studio Pro launched!')
	})

	// Launch JQ Studio
	win.on_click('btn_launch_jq', fn (mut w simplegui.SimpleWindow) {
		app_path := os.join_path(os.dir(@FILE), 'jq_studio.v')
		w.append_console('hub_log', ' Launching JQ Studio Pro in background...\n', 1)
		go fn [app_path] () {
			simplegui.exec_safe('v', ['run', app_path])
		}()
		w.toast('JQ Studio Pro launched!')
	})

	// Launch Format Converter
	win.on_click('btn_launch_convert', fn (mut w simplegui.SimpleWindow) {
		app_path := os.join_path(os.dir(@FILE), 'dataconvert_studio.v')
		w.append_console('hub_log', ' Launching Format Converter Studio in background...\n', 1)
		go fn [app_path] () {
			simplegui.exec_safe('v', ['run', app_path])
		}()
		w.toast('Format Converter Studio launched!')
	})

	// Launch SQLite Studio
	win.on_click('btn_launch_sqlite', fn (mut w simplegui.SimpleWindow) {
		app_path := os.join_path(os.dir(@FILE), 'sqlite_studio.v')
		w.append_console('hub_log', ' Launching SQLite Studio Pro in background...\n', 1)
		go fn [app_path] () {
			simplegui.exec_safe('v', ['run', app_path])
		}()
		w.toast('SQLite Studio Pro launched!')
	})

	// Launch Regex Studio
	win.on_click('btn_launch_regex', fn (mut w simplegui.SimpleWindow) {
		app_path := os.join_path(os.dir(@FILE), 'regex_studio.v')
		w.append_console('hub_log', ' Launching Regex Studio Pro in background...\n', 1)
		go fn [app_path] () {
			simplegui.exec_safe('v', ['run', app_path])
		}()
		w.toast('Regex Studio Pro launched!')
	})

	// Launch ExifTool Studio
	win.on_click('btn_launch_exif', fn (mut w simplegui.SimpleWindow) {
		app_path := os.join_path(os.dir(@FILE), 'exif_studio.v')
		w.append_console('hub_log', ' Launching ExifTool Studio Pro in background...\n', 1)
		go fn [app_path] () {
			simplegui.exec_safe('v', ['run', app_path])
		}()
		w.toast('ExifTool Studio Pro launched!')
	})

	// Launch Tesseract OCR
	win.on_click('btn_launch_ocr', fn (mut w simplegui.SimpleWindow) {
		app_path := os.join_path(os.dir(@FILE), 'ocr_studio.v')
		w.append_console('hub_log', ' Launching Tesseract OCR Studio in background...\n', 1)
		go fn [app_path] () {
			simplegui.exec_safe('v', ['run', app_path])
		}()
		w.toast('Tesseract OCR Studio launched!')
	})

	// Launch Audio Tag Studio
	win.on_click('btn_launch_audiotag', fn (mut w simplegui.SimpleWindow) {
		app_path := os.join_path(os.dir(@FILE), 'audiotag_studio.v')
		w.append_console('hub_log', ' Launching Audio Tag Studio in background...\n', 1)
		go fn [app_path] () {
			simplegui.exec_safe('v', ['run', app_path])
		}()
		w.toast('Audio Tag Studio launched!')
	})

	// Launch Graphviz Studio
	win.on_click('btn_launch_dot', fn (mut w simplegui.SimpleWindow) {
		app_path := os.join_path(os.dir(@FILE), 'dot_studio.v')
		w.append_console('hub_log', ' Launching Graphviz Studio in background...\n', 1)
		go fn [app_path] () {
			simplegui.exec_safe('v', ['run', app_path])
		}()
		w.toast('Graphviz Studio launched!')
	})

	// Launch Homebrew Studio
	win.on_click('btn_launch_brew', fn (mut w simplegui.SimpleWindow) {
		app_path := os.join_path(os.dir(@FILE), 'brew_studio.v')
		w.append_console('hub_log', ' Launching Homebrew Studio in background...\n', 1)
		go fn [app_path] () {
			simplegui.exec_safe('v', ['run', app_path])
		}()
		w.toast('Homebrew Studio launched!')
	})

	// Launch Docker Studio
	win.on_click('btn_launch_docker', fn (mut w simplegui.SimpleWindow) {
		app_path := os.join_path(os.dir(@FILE), 'docker_studio.v')
		w.append_console('hub_log', ' Launching Docker Studio in background...\n', 1)
		go fn [app_path] () {
			simplegui.exec_safe('v', ['run', app_path])
		}()
		w.toast('Docker Studio launched!')
	})

	// Launch Disk Space Studio
	win.on_click('btn_launch_disk', fn (mut w simplegui.SimpleWindow) {
		app_path := os.join_path(os.dir(@FILE), 'disk_studio.v')
		w.append_console('hub_log', ' Launching Disk Space Studio in background...\n', 1)
		go fn [app_path] () {
			simplegui.exec_safe('v', ['run', app_path])
		}()
		w.toast('Disk Space Studio launched!')
	})

	// Launch Launchd & Cron Studio
	win.on_click('btn_launch_launchd', fn (mut w simplegui.SimpleWindow) {
		app_path := os.join_path(os.dir(@FILE), 'launchd_studio.v')
		w.append_console('hub_log', ' Launching Launchd & Cron Studio in background...\n', 1)
		go fn [app_path] () {
			simplegui.exec_safe('v', ['run', app_path])
		}()
		w.toast('Launchd & Cron Studio launched!')
	})

	// Browse File
	win.on_click('btn_quick_browse', fn (mut w simplegui.SimpleWindow) {
		chosen := w.select_file()
		if chosen != '' {
			w.set('txt_quick_in', chosen)
			w.toast('File selected: ' + os.file_name(chosen))
		}
	})

	// Open in Finder
	win.on_click('btn_open_finder', fn (mut w simplegui.SimpleWindow) {
		file_path := w.get('txt_quick_in')
		if file_path != '' && os.exists(file_path) {
			simplegui.reveal_in_finder(file_path)
			w.toast('Revealed in Finder.')
		} else {
			simplegui.reveal_in_finder(os.getwd())
			w.toast('Opened current workspace folder.')
		}
	})

	// Clear Console
	win.on_click('btn_clear_hub_log', fn (mut w simplegui.SimpleWindow) {
		w.clear_console('hub_log')
		w.toast('Activity log cleared.')
	})

	// Inspect Media
	win.on_click('btn_q_info', fn [has_ffprobe, ffprobe_path, identify_path] (mut w simplegui.SimpleWindow) {
		file_path := w.get('txt_quick_in')
		if file_path == '' || !os.exists(file_path) {
			w.alert('File Required', 'Please select an existing media/image file.')
			return
		}
		w.append_console('hub_log', ' Inspecting: ${file_path}...\n', 1)

		go fn [mut w, file_path, has_ffprobe, ffprobe_path, identify_path] () {
			mut out := ''
			if has_ffprobe {
				res := simplegui.exec_safe(ffprobe_path, ['-hide_banner', '-i', file_path])
				out = res.output
			} else {
				res := simplegui.exec_safe(identify_path, [file_path])
				out = res.output
			}
			w.run_on_main_thread(fn [out] (mut win_main simplegui.SimpleWindow) {
				win_main.append_console('hub_log', out + '\n', 0)
				win_main.toast('Inspection complete.')
			})
		}()
	})

	// 1. Convert to MP4
	win.on_click('btn_q_mp4', fn [has_ffmpeg, ffmpeg_path] (mut w simplegui.SimpleWindow) {
		file_path := w.get('txt_quick_in')
		if file_path == '' || !os.exists(file_path) {
			w.alert('File Required', 'Please pick an input video file.')
			return
		}
		if !has_ffmpeg {
			w.alert('Missing FFmpeg', 'FFmpeg binary was not found.')
			return
		}

		out_file := file_path + '.converted.mp4'
		w.append_console('hub_log', ' Converting ${os.file_name(file_path)} to MP4...\n', 1)
		w.set_status('Converting video in background...')

		go fn [mut w, ffmpeg_path, file_path, out_file] () {
			res := simplegui.exec_safe(ffmpeg_path, ['-y', '-i', file_path, '-c:v', 'libx264', '-crf', '22', '-preset', 'fast', '-c:a', 'aac', '-b:a', '192k', out_file])
			w.run_on_main_thread(fn [res, out_file] (mut win_main simplegui.SimpleWindow) {
				if res.exit_code == 0 {
					win_main.append_console('hub_log', ' Successfully created: ${out_file}\n', 4)
					win_main.set_status('Conversion finished!')
					win_main.toast('Converted to MP4!')
				} else {
					win_main.append_console('hub_log', ' Error:\n' + res.output + '\n', 2)
					win_main.set_status('Conversion failed.')
				}
			})
		}()
	})

	// 2. Discord Limit (<10MB)
	win.on_click('btn_q_discord', fn [has_ffmpeg, ffmpeg_path] (mut w simplegui.SimpleWindow) {
		file_path := w.get('txt_quick_in')
		if file_path == '' || !os.exists(file_path) {
			w.alert('File Required', 'Please pick an input video file.')
			return
		}
		if !has_ffmpeg {
			w.alert('Missing FFmpeg', 'FFmpeg binary was not found.')
			return
		}

		out_file := file_path + '.discord_10mb.mp4'
		w.append_console('hub_log', ' Compressing for Discord (<10MB): ${os.file_name(file_path)}...\n', 1)
		w.set_status('Compressing for Discord...')

		go fn [mut w, ffmpeg_path, file_path, out_file] () {
			res := simplegui.exec_safe(ffmpeg_path, ['-y', '-i', file_path, '-c:v', 'libx264', '-crf', '28', '-vf', 'scale=-2:720', '-c:a', 'aac', '-b:a', '96k', out_file])
			w.run_on_main_thread(fn [res, out_file] (mut win_main simplegui.SimpleWindow) {
				if res.exit_code == 0 {
					sz := os.file_size(out_file)
					mb := f64(sz) / (1024.0 * 1024.0)
					win_main.append_console('hub_log', ' Discord Video created: ${out_file} (${mb:.2f} MB)\n', 4)
					win_main.set_status('Discord compression done!')
					win_main.toast('Discord video ready (${mb:.2f} MB)!')
				} else {
					win_main.append_console('hub_log', ' Error:\n' + res.output + '\n', 2)
					win_main.set_status('Discord compression failed.')
				}
			})
		}()
	})

	// 3. TikTok / Reels 9:16 Vertical
	win.on_click('btn_q_reels', fn [has_ffmpeg, ffmpeg_path] (mut w simplegui.SimpleWindow) {
		file_path := w.get('txt_quick_in')
		if file_path == '' || !os.exists(file_path) {
			w.alert('File Required', 'Please pick an input video file.')
			return
		}
		if !has_ffmpeg {
			w.alert('Missing FFmpeg', 'FFmpeg binary was not found.')
			return
		}

		out_file := file_path + '.vertical_9_16.mp4'
		w.append_console('hub_log', ' Cropping to 9:16 Vertical Video: ${os.file_name(file_path)}...\n', 1)
		w.set_status('Cropping 9:16 vertical...')

		go fn [mut w, ffmpeg_path, file_path, out_file] () {
			crop_filter := 'crop=ih*(9/16):ih'
			res := simplegui.exec_safe(ffmpeg_path, ['-y', '-i', file_path, '-vf', crop_filter, '-c:a', 'copy', out_file])
			w.run_on_main_thread(fn [res, out_file] (mut win_main simplegui.SimpleWindow) {
				if res.exit_code == 0 {
					win_main.append_console('hub_log', ' Vertical 9:16 video saved: ${out_file}\n', 4)
					win_main.set_status('Vertical crop done!')
					win_main.toast('TikTok / Reels 9:16 ready!')
				} else {
					win_main.append_console('hub_log', ' Error:\n' + res.output + '\n', 2)
					win_main.set_status('Crop failed.')
				}
			})
		}()
	})

	// 4. Extract MP3 Audio
	win.on_click('btn_q_mp3', fn [has_ffmpeg, ffmpeg_path] (mut w simplegui.SimpleWindow) {
		file_path := w.get('txt_quick_in')
		if file_path == '' || !os.exists(file_path) {
			w.alert('File Required', 'Please pick an input video/audio file.')
			return
		}
		if !has_ffmpeg {
			w.alert('Missing FFmpeg', 'FFmpeg binary was not found.')
			return
		}

		out_file := file_path + '.extracted.mp3'
		w.append_console('hub_log', ' Extracting MP3 Audio (320kbps): ${os.file_name(file_path)}...\n', 1)
		w.set_status('Extracting MP3 audio...')

		go fn [mut w, ffmpeg_path, file_path, out_file] () {
			res := simplegui.exec_safe(ffmpeg_path, ['-y', '-i', file_path, '-vn', '-c:a', 'libmp3lame', '-b:a', '320k', out_file])
			w.run_on_main_thread(fn [res, out_file] (mut win_main simplegui.SimpleWindow) {
				if res.exit_code == 0 {
					win_main.append_console('hub_log', ' Extracted 320kbps MP3: ${out_file}\n', 4)
					win_main.set_status('Audio extraction done!')
					win_main.toast('Extracted MP3!')
				} else {
					win_main.append_console('hub_log', ' Error:\n' + res.output + '\n', 2)
					win_main.set_status('Audio extraction failed.')
				}
			})
		}()
	})

	// 5. Loudnorm Audio
	win.on_click('btn_q_loudnorm', fn [has_ffmpeg, ffmpeg_path] (mut w simplegui.SimpleWindow) {
		file_path := w.get('txt_quick_in')
		if file_path == '' || !os.exists(file_path) {
			w.alert('File Required', 'Please pick an audio/video file.')
			return
		}
		if !has_ffmpeg {
			w.alert('Missing FFmpeg', 'FFmpeg binary was not found.')
			return
		}

		out_file := file_path + '.loudnorm.wav'
		w.append_console('hub_log', ' Normalizing audio to EBU R128 (-14 LUFS): ${os.file_name(file_path)}...\n', 1)
		w.set_status('Normalizing audio...')

		go fn [mut w, ffmpeg_path, file_path, out_file] () {
			res := simplegui.exec_safe(ffmpeg_path, ['-y', '-i', file_path, '-af', 'loudnorm=I=-14:LRA=7:TP=-1.5', out_file])
			w.run_on_main_thread(fn [res, out_file] (mut win_main simplegui.SimpleWindow) {
				if res.exit_code == 0 {
					win_main.append_console('hub_log', ' Broadcast Master Loudnorm Audio: ${out_file}\n', 4)
					win_main.set_status('Loudnorm done!')
					win_main.toast('EBU R128 Audio Normalized!')
				} else {
					win_main.append_console('hub_log', ' Error:\n' + res.output + '\n', 2)
					win_main.set_status('Normalizing failed.')
				}
			})
		}()
	})

	// 6. Image to WebP
	win.on_click('btn_q_webp', fn [has_magick, magick_path] (mut w simplegui.SimpleWindow) {
		file_path := w.get('txt_quick_in')
		if file_path == '' || !os.exists(file_path) {
			w.alert('File Required', 'Please pick an image file.')
			return
		}
		if !has_magick {
			w.alert('Missing ImageMagick', 'ImageMagick binary was not found.')
			return
		}

		out_file := file_path + '.optimized.webp'
		w.append_console('hub_log', ' Compressing image to WebP (Quality 85): ${os.file_name(file_path)}...\n', 1)
		w.set_status('Converting to WebP...')

		go fn [mut w, magick_path, file_path, out_file] () {
			res := simplegui.exec_safe(magick_path, [file_path, '-quality', '85', '-define', 'webp:lossless=false', out_file])
			w.run_on_main_thread(fn [res, out_file] (mut win_main simplegui.SimpleWindow) {
				if res.exit_code == 0 {
					sz := os.file_size(out_file)
					kb := f64(sz) / 1024.0
					win_main.append_console('hub_log', ' WebP image saved: ${out_file} (${kb:.1f} KB)\n', 4)
					win_main.set_status('WebP conversion done!')
					win_main.toast('WebP saved (${kb:.1f} KB)!')
				} else {
					win_main.append_console('hub_log', ' Error:\n' + res.output + '\n', 2)
					win_main.set_status('WebP conversion failed.')
				}
			})
		}()
	})

	// 7. Make Favicon.ico
	win.on_click('btn_q_ico', fn [has_magick, magick_path] (mut w simplegui.SimpleWindow) {
		file_path := w.get('txt_quick_in')
		if file_path == '' || !os.exists(file_path) {
			w.alert('File Required', 'Please pick a square PNG/JPG logo file.')
			return
		}
		if !has_magick {
			w.alert('Missing ImageMagick', 'ImageMagick binary was not found.')
			return
		}

		out_file := file_path + '.favicon.ico'
		w.append_console('hub_log', ' Generating multi-size favicon.ico (16,32,48,64): ${os.file_name(file_path)}...\n', 1)
		w.set_status('Generating favicon.ico...')

		go fn [mut w, magick_path, file_path, out_file] () {
			res := simplegui.exec_safe(magick_path, [file_path, '-define', 'icon:auto-resize=64,48,32,16', out_file])
			w.run_on_main_thread(fn [res, out_file] (mut win_main simplegui.SimpleWindow) {
				if res.exit_code == 0 {
					win_main.append_console('hub_log', ' Multi-resolution Favicon created: ${out_file}\n', 4)
					win_main.set_status('Favicon done!')
					win_main.toast('Favicon.ico created!')
				} else {
					win_main.append_console('hub_log', ' Error:\n' + res.output + '\n', 2)
					win_main.set_status('Favicon creation failed.')
				}
			})
		}()
	})

	// 8. Remove White Background
	win.on_click('btn_q_nobg', fn [has_magick, magick_path] (mut w simplegui.SimpleWindow) {
		file_path := w.get('txt_quick_in')
		if file_path == '' || !os.exists(file_path) {
			w.alert('File Required', 'Please pick an image file with a solid white background.')
			return
		}
		if !has_magick {
			w.alert('Missing ImageMagick', 'ImageMagick binary was not found.')
			return
		}

		out_file := file_path + '.transparent.png'
		w.append_console('hub_log', ' Removing white background: ${os.file_name(file_path)}...\n', 1)
		w.set_status('Removing white background...')

		go fn [mut w, magick_path, file_path, out_file] () {
			res := simplegui.exec_safe(magick_path, [file_path, '-fuzz', '15%', '-transparent', 'white', out_file])
			w.run_on_main_thread(fn [res, out_file] (mut win_main simplegui.SimpleWindow) {
				if res.exit_code == 0 {
					win_main.append_console('hub_log', ' Transparent PNG saved: ${out_file}\n', 4)
					win_main.set_status('Transparency applied!')
					win_main.toast('White background removed!')
				} else {
					win_main.append_console('hub_log', ' Error:\n' + res.output + '\n', 2)
					win_main.set_status('Transparency failed.')
				}
			})
		}()
	})

	// 9. Video to HD GIF
	win.on_click('btn_q_gif', fn [has_ffmpeg, ffmpeg_path] (mut w simplegui.SimpleWindow) {
		file_path := w.get('txt_quick_in')
		if file_path == '' || !os.exists(file_path) {
			w.alert('File Required', 'Please pick a short video clip.')
			return
		}
		if !has_ffmpeg {
			w.alert('Missing FFmpeg', 'FFmpeg binary was not found.')
			return
		}

		out_file := file_path + '.2pass_hd.gif'
		w.append_console('hub_log', ' Generating 2-pass HD animated GIF: ${os.file_name(file_path)}...\n', 1)
		w.set_status('Rendering HD GIF...')

		go fn [mut w, ffmpeg_path, file_path, out_file] () {
			filter := 'fps=15,scale=480:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse'
			res := simplegui.exec_safe(ffmpeg_path, ['-y', '-i', file_path, '-vf', filter, out_file])
			w.run_on_main_thread(fn [res, out_file] (mut win_main simplegui.SimpleWindow) {
				if res.exit_code == 0 {
					sz := os.file_size(out_file)
					mb := f64(sz) / (1024.0 * 1024.0)
					win_main.append_console('hub_log', ' HD Animated GIF created: ${out_file} (${mb:.2f} MB)\n', 4)
					win_main.set_status('HD GIF finished!')
					win_main.toast('2-Pass HD GIF created (${mb:.2f} MB)!')
				} else {
					win_main.append_console('hub_log', ' Error:\n' + res.output + '\n', 2)
					win_main.set_status('GIF rendering failed.')
				}
			})
		}()
	})

	// 10. Resize Image 50%
	win.on_click('btn_q_resize', fn [has_magick, magick_path] (mut w simplegui.SimpleWindow) {
		file_path := w.get('txt_quick_in')
		if file_path == '' || !os.exists(file_path) {
			w.alert('File Required', 'Please pick an image file.')
			return
		}
		if !has_magick {
			w.alert('Missing ImageMagick', 'ImageMagick binary was not found.')
			return
		}

		out_file := file_path + '.resized_50pct.png'
		w.append_console('hub_log', ' Resizing image to 50%: ${os.file_name(file_path)}...\n', 1)
		w.set_status('Resizing image...')

		go fn [mut w, magick_path, file_path, out_file] () {
			res := simplegui.exec_safe(magick_path, [file_path, '-resize', '50%', out_file])
			w.run_on_main_thread(fn [res, out_file] (mut win_main simplegui.SimpleWindow) {
				if res.exit_code == 0 {
					win_main.append_console('hub_log', ' Resized image saved: ${out_file}\n', 4)
					win_main.set_status('Resize completed!')
					win_main.toast('Resized to 50%!')
				} else {
					win_main.append_console('hub_log', ' Error:\n' + res.output + '\n', 2)
					win_main.set_status('Resize failed.')
				}
			})
		}()
	})

	println('Media & Data Studio Hub configured. Starting event loop...')
	win.run()
}

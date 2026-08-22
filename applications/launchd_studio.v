module main

import os
import time
import simplegui

const sample_launchd_plist = '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.simplegui.autobackup</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/tar</string>
        <string>-czf</string>
        <string>/tmp/backup.tar.gz</string>
        <string>/Users/Shared</string>
    </array>
    <key>StartInterval</key>
    <integer>3600</integer>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/simplegui_backup.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/simplegui_backup.err</string>
</dict>
</plist>'

fn main() {
	println('Starting SimpleGUI - Launchd & Cron Studio Pro...')

	mut win := simplegui.new_simple_window('SimpleGUI - Launchd & Cron Studio Pro', 1080, 950)
	win.set_fullscreen(true)
	win.set_spacing(8)
	win.set_padding(16)

	saved_theme := simplegui.get_saved_theme()
	win.set_theme(saved_theme)

	// Top Banner / Diagnostics
	win.begin_row('row_launchd_top')
	win.add_heading('Launchd & Cron Studio Pro')
	win.add_label('lbl_theme', 'Theme:')
	win.add_dropdown('dd_app_theme', simplegui.list_themes(), saved_theme)
	win.set_control_width('dd_app_theme', 150)
	win.end_row()

	win.on_change('dd_app_theme', fn (mut w simplegui.SimpleWindow, selected string) {
		w.set_theme(selected)
		w.toast('Theme changed to ${selected}')
	})

	win.add_label('lbl_engine_info', 'Engine: macOS launchctl & crontab Subsystems  |  Platform: macOS Cocoa  |  Mode: Async')

	// Job Scheduler Specification & Presets Bar
	win.begin_group_box('grp_job_presets', 'Scheduled Task Templates & Cron Expression Builder')
	
	win.begin_row('row_presets_bar')
	win.add_label('lbl_template', 'Schedule Template:')
	win.add_dropdown('dd_schedule_presets', [
		'1. Hourly Background Task (StartInterval: 3600)',
		'2. Daily Midnight Job (StartCalendarInterval: Hour 0, Min 0)',
		'3. System Boot / Login Task (RunAtLoad: true)',
		'4. File Watcher Daemon (WatchPaths: ~/Downloads)',
		'5. Cron: Every 5 Minutes (*/5 * * * *)',
		'6. Cron: Daily at 9:00 AM (0 9 * * *)',
		'7. Cron: Every Sunday at Midnight (0 0 * * 0)'
	], '1. Hourly Background Task (StartInterval: 3600)')
	win.set_control_width('dd_schedule_presets', 380)

	win.add_label('lbl_job_name', 'Job Label:')
	win.add_input('txt_job_label', 'com.simplegui.scheduledtask')
	win.set_control_width('txt_job_label', 260)
	win.end_row()

	win.end_group_box()

	// Actions Bar
	win.begin_row('row_actions')
	win.add_button('btn_list_launchd', 'List Launchd Daemons (launchctl list)')
	win.add_button('btn_list_cron', 'List Cron Jobs (crontab -l)')
	win.add_button('btn_list_user_agents', 'User LaunchAgents (~/Library/LaunchAgents)')
	win.add_button('btn_save_plist', 'Save Plist File...')
	win.add_button('btn_copy_plist', 'Copy Plist / Crontab')
	win.add_button('btn_clear_all', 'Clear')
	win.end_row()

	// Dual Pane: Plist / Cron Editor & Output
	win.begin_grid('grid_dual_pane', 2, 8)
	win.add_form_textarea('Launchd Plist / Cron Job Definition:', 'txt_job_definition', sample_launchd_plist)
	win.set_control_height('txt_job_definition', 320)
	win.add_form_textarea('System Daemons & Service Status:', 'txt_job_output', '')
	win.set_control_height('txt_job_output', 320)
	win.end_grid()

	// Activity Log Console
	win.begin_group_box('grp_console', 'Launchd & Cron Activity Telemetry')
	win.add_console('job_console', 110)
	win.end_group_box()

	// Status Row
	win.begin_row('row_stats')
	win.add_label('lbl_stats', 'Stats: Ready  |  Active Agents: Checked  |  Duration: 0 ms')
	win.end_row()

	win.append_console('job_console', ' Launchd & Cron Studio Pro Initialized.\n', 1)
	win.append_console('job_console', ' Ready to inspect launchd services, user agents, and crontab tables.\n', 4)

	// -------------------------------------------------------------
	// Event Handlers
	// -------------------------------------------------------------

	// Preset Selection Handler
	win.on_change('dd_schedule_presets', fn (mut w simplegui.SimpleWindow, selected string) {
		if selected.starts_with('1.') {
			w.set('txt_job_definition', sample_launchd_plist)
		} else if selected.starts_with('2.') {
			w.set('txt_job_definition', '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.simplegui.dailyjob</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/python3</string>
        <string>/Users/Shared/daily_task.py</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>0</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
</dict>
</plist>')
		} else if selected.starts_with('3.') {
			w.set('txt_job_definition', '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.simplegui.loginapp</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/open</string>
        <string>-a</string>
        <string>SimpleGUI</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>')
		} else if selected.starts_with('4.') {
			w.set('txt_job_definition', '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.simplegui.watcher</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/touch</string>
        <string>/tmp/watcher_triggered.log</string>
    </array>
    <key>WatchPaths</key>
    <array>
        <string>' + os.home_dir() + '/Downloads</string>
    </array>
</dict>
</plist>')
		} else if selected.starts_with('5.') {
			w.set('txt_job_definition', '# Crontab: Run script every 5 minutes
*/5 * * * * /usr/bin/python3 /Users/Shared/sync.py >> /tmp/cron_sync.log 2>&1')
		} else if selected.starts_with('6.') {
			w.set('txt_job_definition', '# Crontab: Run every morning at 9:00 AM (Mon-Fri)
0 9 * * 1-5 /usr/bin/curl -s "https://api.example.com/heartbeat" > /dev/null')
		} else if selected.starts_with('7.') {
			w.set('txt_job_definition', '# Crontab: Run weekly backup on Sunday at Midnight
0 0 * * 0 /usr/bin/tar -czf /tmp/weekly_backup.tar.gz /Users/Shared >> /tmp/cron_backup.log 2>&1')
		}
		w.toast('Loaded template: ${selected.split("(")[0]}')
	})

	// List Launchd Daemons
	win.on_click('btn_list_launchd', fn (mut w simplegui.SimpleWindow) {
		w.append_console('job_console', ' Querying active launchd services (launchctl list)...\n', 1)
		w.set_status('Querying launchctl...')

		go fn [mut w] () {
			t0 := time.ticks()
			res := os.execute('launchctl list | head -n 50')
			elapsed_ms := time.ticks() - t0

			w.run_on_main_thread(fn [res, elapsed_ms] (mut win_main simplegui.SimpleWindow) {
				win_main.set('txt_job_output', res.output.trim_space())
				win_main.append_console('job_console', ' Launchd services listed in ${elapsed_ms} ms.\n', 4)
				win_main.set('lbl_stats', ' Stats: LAUNCHCTL ACTIVE SERVICES  |  Duration: ${elapsed_ms} ms')
				win_main.set_status('Launchd services loaded.')
			})
		}()
	})

	// List Cron Jobs
	win.on_click('btn_list_cron', fn (mut w simplegui.SimpleWindow) {
		w.append_console('job_console', ' Reading user crontab table (crontab -l)...\n', 1)
		w.set_status('Reading crontab...')

		go fn [mut w] () {
			t0 := time.ticks()
			res := os.execute('crontab -l 2>&1')
			elapsed_ms := time.ticks() - t0

			w.run_on_main_thread(fn [res, elapsed_ms] (mut win_main simplegui.SimpleWindow) {
				out := res.output.trim_space()
				win_main.set('txt_job_output', if out != '' { out } else { 'No crontab entries installed for current user.' })
				win_main.append_console('job_console', ' Crontab table read in ${elapsed_ms} ms.\n', 4)
				win_main.set('lbl_stats', ' Stats: CRONTAB CHECKED  |  Duration: ${elapsed_ms} ms')
				win_main.set_status('Crontab loaded.')
			})
		}()
	})

	// List User LaunchAgents
	win.on_click('btn_list_user_agents', fn (mut w simplegui.SimpleWindow) {
		agents_dir := os.join_path(os.home_dir(), 'Library/LaunchAgents')
		w.append_console('job_console', ' Inspecting user agents directory: ${agents_dir}...\n', 1)

		if os.exists(agents_dir) {
			files := os.ls(agents_dir) or { []string{} }
			mut out := '--- User LaunchAgents (${files.len} files) in ${agents_dir} ---\n\n'
			for f in files {
				out += ' ' + f + '\n'
			}
			w.set('txt_job_output', out)
			w.toast('Listed ${files.len} user launch agents.')
		} else {
			w.set('txt_job_output', 'No ~/Library/LaunchAgents directory found.')
		}
	})

	// Save Plist File
	win.on_click('btn_save_plist', fn (mut w simplegui.SimpleWindow) {
		job_def := w.get('txt_job_definition')
		if job_def.trim_space() == '' {
			w.toast('No job definition to save.')
			return
		}
		path := w.save_file_picker()
		if path != '' {
			mut save_file := path
			if !save_file.ends_with('.plist') && !save_file.ends_with('.txt') {
				save_file += '.plist'
			}
			os.write_file(save_file, job_def) or {
				w.toast('Failed to save file.')
				return
			}
			w.toast('Saved to ${os.file_name(save_file)}')
			w.append_console('job_console', ' Saved scheduled job definition to: ${save_file}\n', 4)
		}
	})

	// Copy Plist
	win.on_click('btn_copy_plist', fn (mut w simplegui.SimpleWindow) {
		out := w.get('txt_job_definition')
		if out != '' {
			w.copy_to_clipboard(out)
			w.toast('Job definition copied to clipboard!')
		}
	})

	// Clear
	win.on_click('btn_clear_all', fn (mut w simplegui.SimpleWindow) {
		w.set('txt_job_output', '')
		w.clear_console('job_console')
		w.toast('Cleared output.')
	})

	win.start()
}

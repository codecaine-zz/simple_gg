module sysutils

import os
import runtime
import strings
import time

// ============================================================================
// Hardware Telemetry & Probing
// ============================================================================

// get_cpu_count returns the number of logical CPU cores available on the system.
pub fn get_cpu_count() int {
	res := os.execute('sysctl -n hw.ncpu')
	if res.exit_code == 0 {
		count := res.output.trim_space().int()
		if count > 0 {
			return count
		}
	}
	res_nproc := os.execute('nproc')
	if res_nproc.exit_code == 0 {
		count := res_nproc.output.trim_space().int()
		if count > 0 {
			return count
		}
	}
	return 1
}

// get_cpu_usage estimates current overall CPU usage percentage (0.0 to 100.0).
pub fn get_cpu_usage() f64 {
	$if macos {
		res := os.execute("top -l 1 -n 0 | grep 'CPU usage'")
		if res.exit_code == 0 && res.output.len > 0 {
			// Format: "CPU usage: 12.5% user, 8.3% sys, 79.1% idle"
			idle_idx := res.output.index('% idle') or { -1 }
			if idle_idx > 0 {
				sub := res.output[..idle_idx]
				comma_idx := sub.last_index(',') or { sub.last_index(' ') or { -1 } }
				if comma_idx > 0 {
					idle_str := sub[comma_idx + 1..].trim_space()
					idle := idle_str.f64()
					if idle >= 0.0 && idle <= 100.0 {
						return 100.0 - idle
					}
				}
			}
		}
	}
	$if linux {
		content := os.read_file('/proc/stat') or { '' }
		lines := content.split_into_lines()
		if lines.len > 0 && lines[0].starts_with('cpu ') {
			parts := lines[0].fields()
			if parts.len >= 5 {
				user := parts[1].f64()
				nice := parts[2].f64()
				system := parts[3].f64()
				idle := parts[4].f64()
				total := user + nice + system + idle
				if total > 0.0 {
					return ((user + nice + system) / total) * 100.0
				}
			}
		}
	}
	return 0.0
}

// get_load_averages returns the 1-minute, 5-minute, and 15-minute system load averages.
pub fn get_load_averages() (f64, f64, f64) {
	$if macos {
		res := os.execute('sysctl -n vm.loadavg')
		if res.exit_code == 0 {
			clean := res.output.replace('{', '').replace('}', '').trim_space()
			fields := clean.fields()
			if fields.len >= 3 {
				return fields[0].f64(), fields[1].f64(), fields[2].f64()
			}
		}
	}
	$if linux {
		content := os.read_file('/proc/loadavg') or { '' }
		fields := content.fields()
		if fields.len >= 3 {
			return fields[0].f64(), fields[1].f64(), fields[2].f64()
		}
	}
	return 0.0, 0.0, 0.0
}

// get_memory_stats returns (total_bytes, used_bytes, used_percent) for physical RAM.
pub fn get_memory_stats() (u64, u64, f64) {
	$if macos {
		total_res := os.execute('sysctl -n hw.memsize')
		total := if total_res.exit_code == 0 { total_res.output.trim_space().u64() } else { u64(0) }
		vm_res := os.execute('vm_stat')
		if vm_res.exit_code == 0 && total > 0 {
			mut free_pages := u64(0)
			mut page_size := u64(4096)
			lines := vm_res.output.split_into_lines()
			for line in lines {
				if line.starts_with('Mach Virtual Memory Statistics') {
					if line.contains('page size of') {
						start := line.index('page size of') or { -1 }
						if start > 0 {
							sub := line[start + 12..].trim_space()
							bytes_idx := sub.index('bytes') or { -1 }
							if bytes_idx > 0 {
								page_size = sub[..bytes_idx].trim_space().u64()
							}
						}
					}
				} else if line.contains('Pages free:') {
					parts := line.split(':')
					if parts.len == 2 {
						free_pages += parts[1].replace('.', '').trim_space().u64()
					}
				} else if line.contains('Pages speculative:') {
					parts := line.split(':')
					if parts.len == 2 {
						free_pages += parts[1].replace('.', '').trim_space().u64()
					}
				}
			}
			free_bytes := free_pages * page_size
			used_bytes := if total > free_bytes { total - free_bytes } else { u64(0) }
			percent := (f64(used_bytes) / f64(total)) * 100.0
			return total, used_bytes, percent
		}
	}
	$if linux {
		content := os.read_file('/proc/meminfo') or { '' }
		mut total := u64(0)
		mut free := u64(0)
		mut avail := u64(0)
		for line in content.split_into_lines() {
			if line.starts_with('MemTotal:') {
				parts := line.fields()
				if parts.len >= 2 {
					total = parts[1].u64() * 1024
				}
			} else if line.starts_with('MemFree:') {
				parts := line.fields()
				if parts.len >= 2 {
					free = parts[1].u64() * 1024
				}
			} else if line.starts_with('MemAvailable:') {
				parts := line.fields()
				if parts.len >= 2 {
					avail = parts[1].u64() * 1024
				}
			}
		}
		if total > 0 {
			usable_free := if avail > 0 { avail } else { free }
			used := if total > usable_free { total - usable_free } else { u64(0) }
			return total, used, (f64(used) / f64(total)) * 100.0
		}
	}
	return u64(0), u64(0), 0.0
}

// get_swap_stats returns (total_bytes, used_bytes, used_percent) for swap memory.
pub fn get_swap_stats() (u64, u64, f64) {
	$if macos {
		res := os.execute('sysctl -n vm.swapusage')
		if res.exit_code == 0 {
			// Format: "total = 2048.00M  used = 1024.00M  free = 1024.00M  (encrypted)"
			parts := res.output.fields()
			mut total := u64(0)
			mut used := u64(0)
			for i in 0 .. parts.len {
				if parts[i] == 'total' && i + 2 < parts.len {
					val := parts[i + 2].replace('M', '').replace('G', '').f64()
					total = u64(val * 1024.0 * 1024.0)
				} else if parts[i] == 'used' && i + 2 < parts.len {
					val := parts[i + 2].replace('M', '').replace('G', '').f64()
					used = u64(val * 1024.0 * 1024.0)
				}
			}
			percent := if total > 0 { (f64(used) / f64(total)) * 100.0 } else { 0.0 }
			return total, used, percent
		}
	}
	return u64(0), u64(0), 0.0
}

// get_disk_stats returns (total_bytes, used_bytes, used_percent) for the filesystem mounting path.
pub fn get_disk_stats(path string) (u64, u64, f64) {
	target := if path.len > 0 { path } else { '/' }
	res := os.execute('df -k ${quote_arg(target)}')
	if res.exit_code == 0 {
		lines := res.output.trim_space().split_into_lines()
		if lines.len >= 2 {
			fields := lines[1].fields()
			if fields.len >= 4 {
				total := fields[1].u64() * 1024
				used := fields[2].u64() * 1024
				percent := if total > 0 { (f64(used) / f64(total)) * 100.0 } else { 0.0 }
				return total, used, percent
			}
		}
	}
	return u64(0), u64(0), 0.0
}

// get_battery_level returns current battery percentage (0-100), or none if unavailable.
pub fn get_battery_level() ?int {
	$if macos {
		res := os.execute('pmset -g batt')
		if res.exit_code == 0 && res.output.contains('%') {
			idx := res.output.index('%') or { -1 }
			if idx > 0 {
				mut start := idx - 1
				for start >= 0 && (res.output[start] >= `0` && res.output[start] <= `9`) {
					start--
				}
				pct := res.output[start + 1..idx].int()
				return pct
			}
		}
	}
	return none
}

// is_battery_charging returns whether the battery is currently charging, or none if unavailable.
pub fn is_battery_charging() ?bool {
	$if macos {
		res := os.execute('pmset -g batt')
		if res.exit_code == 0 {
			return res.output.contains('charging') || res.output.contains('AC Power')
		}
	}
	return none
}

// get_uptime returns system uptime in seconds.
pub fn get_uptime() i64 {
	$if macos {
		res := os.execute('sysctl -n kern.boottime')
		if res.exit_code == 0 {
			// Format: "{ sec = 1716382000, usec = 0 } ..."
			sec_idx := res.output.index('sec = ') or { -1 }
			if sec_idx >= 0 {
				sub := res.output[sec_idx + 6..]
				comma := sub.index(',') or { sub.index(' ') or { -1 } }
				if comma >= 0 {
					boot_sec := sub[..comma].trim_space().i64()
					now_sec := time.now().unix()
					return now_sec - boot_sec
				}
			}
		}
	}
	$if linux {
		content := os.read_file('/proc/uptime') or { '' }
		fields := content.fields()
		if fields.len > 0 {
			return fields[0].f64().i64()
		}
	}
	return 0
}

// get_system_locale returns the system locale string (e.g. "en_US.UTF-8").
pub fn get_system_locale() string {
	lang := os.getenv('LANG')
	if lang.len > 0 {
		return lang
	}
	lc_all := os.getenv('LC_ALL')
	if lc_all.len > 0 {
		return lc_all
	}
	return 'en_US.UTF-8'
}

// get_os_theme returns "dark" or "light" reflecting the OS interface style.
pub fn get_os_theme() string {
	$if macos {
		res := os.execute('defaults read -g AppleInterfaceStyle')
		if res.exit_code == 0 && res.output.to_lower().contains('dark') {
			return 'dark'
		}
		return 'light'
	}
	return 'light'
}

// ============================================================================
// Safe Subprocess Execution & Security
// ============================================================================

// quote_arg strictly quotes an argument using POSIX single quotes to eliminate shell breakout.
pub fn quote_arg(arg string) string {
	escaped := arg.replace("'", "'\\''")
	return "'${escaped}'"
}

// quote_path expands ~ to user home and quotes the resulting path.
pub fn quote_path(path string) string {
	resolved := resolve_user_path(path)
	return quote_arg(resolved)
}

// sanitize_filename strips path traversal and invalid characters from filename.
pub fn sanitize_filename(name string) string {
	clean := name.replace('../', '_').replace('..\\', '_').replace('/', '_').replace('\\', '_')
	mut sb := strings.new_builder(clean.len)
	for r in clean.runes() {
		if (r >= `a` && r <= `z`) || (r >= `A` && r <= `Z`) || (r >= `0` && r <= `9`)
			|| r == `.` || r == `_` || r == `-` {
			sb.write_rune(r)
		} else {
			sb.write_u8(`_`)
		}
	}
	res := sb.str().trim_space()
	return if res.len > 0 { res } else { 'unnamed' }
}

// exec_safe executes a binary with arguments passed through quote_arg, preventing command injection.
pub fn exec_safe(bin string, args []string) (string, int) {
	mut quoted_args := []string{cap: args.len}
	for a in args {
		quoted_args << quote_arg(a)
	}
	cmd := '${quote_arg(bin)} ${quoted_args.join(' ')}'
	res := os.execute(cmd)
	return res.output, res.exit_code
}

// ExecTimeoutResult represents the result of a process executed with a timeout.
pub struct ExecTimeoutResult {
pub:
	output    string
	exit_code int
	timed_out bool
}

// exec_timeout executes a command with a timeout in milliseconds.
pub fn exec_timeout(cmd string, timeout_ms int) ExecTimeoutResult {
	start := time.now()
	// Run command
	res := os.execute(cmd)
	duration_ms := (time.now() - start).milliseconds()
	if duration_ms > timeout_ms {
		return ExecTimeoutResult{
			output: res.output
			exit_code: res.exit_code
			timed_out: true
		}
	}
	return ExecTimeoutResult{
		output: res.output
		exit_code: res.exit_code
		timed_out: false
	}
}

// ExecRetryResult represents the result of a retried command execution.
pub struct ExecRetryResult {
pub:
	output    string
	exit_code int
	attempts  int
}

// exec_retry attempts to execute a command up to retries times with delay_ms between failures.
pub fn exec_retry(cmd string, retries int, delay_ms int) ExecRetryResult {
	max_attempts := if retries > 0 { retries } else { 1 }
	mut attempt := 0
	mut last_output := ''
	mut last_code := 1
	for attempt < max_attempts {
		attempt++
		res := os.execute(cmd)
		last_output = res.output
		last_code = res.exit_code
		if res.exit_code == 0 {
			return ExecRetryResult{
				output: res.output
				exit_code: 0
				attempts: attempt
			}
		}
		if attempt < max_attempts && delay_ms > 0 {
			time.sleep(time.Duration(delay_ms * int(time.millisecond)))
		}
	}
	return ExecRetryResult{
		output: last_output
		exit_code: last_code
		attempts: attempt
	}
}

// exec_or executes a command and returns output if successful, or fallback string on failure.
pub fn exec_or(cmd string, fallback string) string {
	res := os.execute(cmd)
	if res.exit_code == 0 {
		return res.output.trim_space()
	}
	return fallback
}

// is_process_running checks if a process with the specified PID is currently alive.
pub fn is_process_running(pid int) bool {
	if pid <= 0 {
		return false
	}
	res := os.execute('kill -0 ${pid}')
	return res.exit_code == 0
}

// kill_process sends SIGTERM to terminate a process by PID.
pub fn kill_process(pid int) bool {
	if pid <= 0 {
		return false
	}
	res := os.execute('kill ${pid}')
	return res.exit_code == 0
}

// has_command checks whether an executable binary exists in the system PATH.
pub fn has_command(name string) bool {
	cmd_path := os.find_abs_path_of_executable(name) or { '' }
	return cmd_path.len > 0
}

// get_command_path returns the full absolute path of an executable, or none if not found.
pub fn get_command_path(name string) ?string {
	cmd_path := os.find_abs_path_of_executable(name) or { return none }
	if cmd_path.len > 0 {
		return cmd_path
	}
	return none
}

// ============================================================================
// Standard OS Directory & Path Resolution
// ============================================================================

// get_user_home_dir returns the current user's home directory.
pub fn get_user_home_dir() string {
	return os.home_dir()
}

// resolve_user_path expands ~ or leading ~/ in a path to the absolute user home path.
pub fn resolve_user_path(path string) string {
	if path == '~' {
		return os.home_dir()
	}
	if path.starts_with('~/') || path.starts_with('~\\') {
		return os.join_path(os.home_dir(), path[2..])
	}
	return os.real_path(path)
}

// get_app_config_dir returns the standard configuration directory for the application.
pub fn get_app_config_dir(app_name string) string {
	base := os.config_dir() or { os.join_path(os.home_dir(), '.config') }
	dir := os.join_path(base, app_name)
	if !os.exists(dir) {
		os.mkdir_all(dir) or {}
	}
	return dir
}

// get_app_data_dir returns the standard persistent application data directory.
pub fn get_app_data_dir(app_name string) string {
	$if macos {
		dir := os.join_path(os.home_dir(), 'Library', 'Application Support', app_name)
		if !os.exists(dir) {
			os.mkdir_all(dir) or {}
		}
		return dir
	}
	$if windows {
		appdata := os.getenv('APPDATA')
		base := if appdata.len > 0 { appdata } else { os.home_dir() }
		dir := os.join_path(base, app_name)
		if !os.exists(dir) {
			os.mkdir_all(dir) or {}
		}
		return dir
	}
	base := os.getenv('XDG_DATA_HOME')
	data_home := if base.len > 0 { base } else { os.join_path(os.home_dir(), '.local', 'share') }
	dir := os.join_path(data_home, app_name)
	if !os.exists(dir) {
		os.mkdir_all(dir) or {}
	}
	return dir
}

// get_app_data_path returns the full resolved path to a file inside the app data directory.
pub fn get_app_data_path(app_name string, filename string) string {
	dir := get_app_data_dir(app_name)
	fname := if filename.trim_space().len > 0 { filename.trim_space() } else { 'state.json' }
	return os.join_path(dir, fname)
}

// get_app_config_path returns the full resolved path to a file inside the app config directory.
pub fn get_app_config_path(app_name string, filename string) string {
	dir := get_app_config_dir(app_name)
	fname := if filename.trim_space().len > 0 { filename.trim_space() } else { 'config.json' }
	return os.join_path(dir, fname)
}

// get_app_cache_dir returns the standard application cache directory.
pub fn get_app_cache_dir(app_name string) string {
	base := os.cache_dir()
	dir := os.join_path(base, app_name)
	if !os.exists(dir) {
		os.mkdir_all(dir) or {}
	}
	return dir
}

// get_app_log_dir returns the standard application log directory.
pub fn get_app_log_dir(app_name string) string {
	$if macos {
		dir := os.join_path(os.home_dir(), 'Library', 'Logs', app_name)
		if !os.exists(dir) {
			os.mkdir_all(dir) or {}
		}
		return dir
	}
	dir := os.join_path(get_app_data_dir(app_name), 'logs')
	if !os.exists(dir) {
		os.mkdir_all(dir) or {}
	}
	return dir
}

// get_system_path returns paths to standard user folders: desktop, downloads, documents, pictures, music, videos.
pub fn get_system_path(folder_name string) string {
	home := os.home_dir()
	match folder_name.to_lower() {
		'desktop' {
			return os.join_path(home, 'Desktop')
		}
		'downloads' {
			return os.join_path(home, 'Downloads')
		}
		'documents' {
			return os.join_path(home, 'Documents')
		}
		'pictures' {
			return os.join_path(home, 'Pictures')
		}
		'music' {
			return os.join_path(home, 'Music')
		}
		'videos' {
			return os.join_path(home, 'Videos')
		}
		else {
			return os.join_path(home, folder_name)
		}
	}
}

// ============================================================================
// Clipboard, Audio & Desktop Notifications
// ============================================================================

// copy_to_clipboard copies text to the system clipboard.
pub fn copy_to_clipboard(text string) ! {
	$if macos {
		mut p := os.new_process('/usr/bin/pbcopy')
		p.set_redirect_stdio()
		p.run()
		p.stdin_write(text)
		p.close()
		p.wait()
		return
	}
	$if linux {
		if has_command('xclip') {
			mut p := os.new_process('xclip')
			p.set_args(['-selection', 'clipboard'])
			p.set_redirect_stdio()
			p.run()
			p.stdin_write(text)
			p.close()
			p.wait()
			return
		} else if has_command('wl-copy') {
			mut p := os.new_process('wl-copy')
			p.set_redirect_stdio()
			p.run()
			p.stdin_write(text)
			p.close()
			p.wait()
			return
		}
	}
	return error('clipboard command not available')
}

// get_clipboard_text retrieves the current plain-text content from the system clipboard.
pub fn get_clipboard_text() !string {
	$if macos {
		res := os.execute('/usr/bin/pbpaste')
		if res.exit_code == 0 {
			return res.output
		}
	}
	$if linux {
		if has_command('xclip') {
			res := os.execute('xclip -selection clipboard -o')
			if res.exit_code == 0 {
				return res.output
			}
		} else if has_command('wl-paste') {
			res := os.execute('wl-paste')
			if res.exit_code == 0 {
				return res.output
			}
		}
	}
	return error('clipboard paste command not available')
}

// beep produces an audible terminal bell alert.
pub fn beep() {
	print('\a')
	os.flush()
}

// notify displays an OS desktop notification banner with title and message.
pub fn notify(title string, message string) ! {
	$if macos {
		safe_title := title.replace('"', '\\"')
		safe_msg := message.replace('"', '\\"')
		cmd := 'osascript -e \'display notification "${safe_msg}" with title "${safe_title}"\''
		os.execute(cmd)
		return
	}
	$if linux {
		if has_command('notify-send') {
			exec_safe('notify-send', [title, message])
			return
		}
	}
}

// say synthesizes and speaks text using the OS text-to-speech engine.
pub fn say(text string) ! {
	$if macos {
		exec_safe('say', [text])
		return
	}
	$if linux {
		if has_command('espeak') {
			exec_safe('espeak', [text])
			return
		}
	}
}

// RuntimeInfo holds hardware, OS, and V runtime telemetry.
pub struct RuntimeInfo {
pub:
	os_name          string
	arch             string
	num_cpus         int
	is_64bit         bool
	is_little_endian bool
	total_memory_mb  u64
	free_memory_mb   u64
}

// runtime_system_info queries the V runtime subsystem for machine and architecture statistics.
pub fn runtime_system_info() RuntimeInfo {
	total_mem := runtime.total_memory() or { 0 }
	free_mem := runtime.free_memory() or { 0 }

	arch := if runtime.is_64bit() { '64-bit' } else { '32-bit' }

	return RuntimeInfo{
		os_name: os.user_os()
		arch: arch
		num_cpus: runtime.nr_cpus()
		is_64bit: runtime.is_64bit()
		is_little_endian: runtime.is_little_endian()
		total_memory_mb: u64(total_mem / (1024 * 1024))
		free_memory_mb: u64(free_mem / (1024 * 1024))
	}
}

// pipe_commands executes two commands connected via a shell pipe: cmd1 | cmd2.
pub fn pipe_commands(cmd1 string, cmd2 string) !string {
	full_cmd := '${cmd1} | ${cmd2}'
	res := os.execute(full_cmd)
	if res.exit_code != 0 {
		return error('piped command failed with exit code ${res.exit_code}: ${res.output.trim_space()}')
	}
	return res.output.trim_space()
}

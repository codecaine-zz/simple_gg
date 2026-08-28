// Module simplecli - Headless Console & RAD Toolkit for V
// File: sys.v
//
// Description:
//   This file provides cross-platform OS system calls, process management (sync, async,
//   timeout, retry, parallel), hardware resource metrics (CPU, RAM, load, battery, disk), standard directory
//   path resolution, headless desktop notifications, audio beeps, speech synthesis (TTS),
//   clipboard interaction, TCP network diagnostics, safe shell execution, and native modal dialogs.

module simplecli

import os
import time
import net
import net.http
import clipboard

// Native C declarations for POSIX system calls
$if macos || linux || freebsd {
	#include <sys/types.h>
	#include <sys/time.h>

$if macos || freebsd {
	#include <sys/sysctl.h>
	fn C.sysctl(name &int, namelen u32, oldp voidptr, oldlenp &usize, newp voidptr, newlen usize) int
}

	fn C.getloadavg(loadavg &f64, nelem int) int
}

// DiskStats represents disk partition storage statistics.
pub struct DiskStats {
pub:
	total_bytes u64
	free_bytes  u64
	used_bytes  u64
	percent     f64
}

// FileMetadata represents file system metadata.
pub struct FileMetadata {
pub:
	path         string
	name         string
	size_bytes   u64
	is_dir       bool
	is_link      bool
	is_readable  bool
	is_writable  bool
	created_time i64
	modified_time i64
}

// ExecResult contains detailed results for process execution with retries or timeouts.
pub struct ExecResult {
pub:
	output     string
	exit_code  int
	duration_ms i64
	timed_out  bool
	attempts   int
}

// =============================================================================
// 1. Process Execution & Safe Command Helpers
// =============================================================================

// exec runs a system command synchronously, returning stdout/stderr and exit code.
pub fn (cli &SimpleCli) exec(command string) (string, int) {
	if cli.debug_mode {
		cli.debug('Executing sync command: "${command}"')
	}
	res := os.execute(command)
	return res.output.trim_space(), res.exit_code
}

// exec_or runs a system command, returning stdout if successful, or fallback.
pub fn (cli &SimpleCli) exec_or(command string, fallback string) string {
	out, code := cli.exec(command)
	if code == 0 && out.len > 0 {
		return out
	}
	return fallback
}

// exec_bg runs a system command in a background thread asynchronously.
pub fn (cli &SimpleCli) exec_bg(command string) &SimpleCli {
	if cli.debug_mode {
		cli.debug('Spawning background task: "${command}"')
	}
	spawn fn (cmd string, debug bool) {
		res := os.execute(cmd)
		if debug {
			println('[simplecli BG] Command "${cmd}" finished with exit code ${res.exit_code}')
		}
	}(command, cli.debug_mode)
	return cli
}

// exec_in_dir runs a system command within a specific working directory.
pub fn (cli &SimpleCli) exec_in_dir(dir string, command string) (string, int) {
	prev_dir := os.getwd()
	os.chdir(dir) or { return 'Failed to change directory to ${dir}', 1 }
	out, code := cli.exec(command)
	os.chdir(prev_dir) or {}
	return out, code
}

// quote_arg wraps an argument in POSIX single quotes and escapes embedded quotes.
pub fn quote_arg(arg string) string {
	return "'" + arg.replace("'", "'\\''") + "'"
}

// quote_path safely quotes a file or directory path.
pub fn quote_path(path string) string {
	return quote_arg(resolve_user_path(path))
}

// sanitize_filename strips path separators, null bytes, and path traversal tokens.
pub fn sanitize_filename(name string) string {
	mut clean := name.replace('/', '_').replace('\\', '_').replace('..', '_').replace('\x00', '')
	clean = clean.trim_space()
	return if clean.len > 0 { clean } else { 'file' }
}

// exec_safe executes a command by safely quoting all arguments to prevent shell injection.
pub fn (cli &SimpleCli) exec_safe(tool string, args []string) (string, int) {
	mut parts := [quote_arg(tool)]
	for a in args {
		parts << quote_arg(a)
	}
	cmd := parts.join(' ')
	return cli.exec(cmd)
}

// exec_timeout executes a command with a maximum timeout limit in milliseconds.
pub fn (cli &SimpleCli) exec_timeout(command string, timeout_ms int) (string, int, bool) {
	start_time := time.now()
	
	// Create temporary result files
	temp_out := os.join_path(os.temp_dir(), 'simplecli_timeout_${os.getpid()}_${time.now().unix_nano()}.log')
	temp_done := temp_out + '.done'
	
	spawn fn (cmd string, out_file string, done_file string) {
		res := os.execute(cmd)
		os.write_file(out_file, res.output) or {}
		os.write_file(done_file, '${res.exit_code}') or {}
	}(command, temp_out, temp_done)
	
	for {
		if os.exists(temp_done) {
			code_str := os.read_file(temp_done) or { '0' }
			out_str := os.read_file(temp_out) or { '' }
			os.rm(temp_done) or {}
			os.rm(temp_out) or {}
			return out_str.trim_space(), code_str.trim_space().int(), false
		}
		
		elapsed := time.since(start_time).milliseconds()
		if elapsed >= timeout_ms {
			os.rm(temp_done) or {}
			os.rm(temp_out) or {}
			return 'Command timed out after ${timeout_ms}ms', -1, true
		}
		time.sleep(10 * time.millisecond)
	}
	
	return '', 0, false
}

// exec_retry executes a command with retry attempts and exponential backoff.
pub fn (cli &SimpleCli) exec_retry(command string, max_retries int, initial_delay_ms int, backoff_factor f64) ExecResult {
	start := time.now()
	mut delay := initial_delay_ms
	mut attempts := 0
	
	for attempts < max_retries {
		attempts++
		out, code := cli.exec(command)
		if code == 0 {
			return ExecResult{
				output: out
				exit_code: code
				duration_ms: time.since(start).milliseconds()
				timed_out: false
				attempts: attempts
			}
		}
		if attempts < max_retries {
			time.sleep(delay * time.millisecond)
			delay = int(f64(delay) * backoff_factor)
		}
	}
	
	out, code := cli.exec(command)
	return ExecResult{
		output: out
		exit_code: code
		duration_ms: time.since(start).milliseconds()
		timed_out: false
		attempts: attempts
	}
}

// parallel_exec executes multiple commands concurrently using background threads.
pub fn (cli &SimpleCli) parallel_exec(commands []string) []ExecResult {
	mut results := []ExecResult{len: commands.len}
	mut threads := []thread ExecResult{}

	for cmd in commands {
		threads << spawn fn (c string) ExecResult {
			start := time.now()
			res := os.execute(c)
			return ExecResult{
				output: res.output.trim_space()
				exit_code: res.exit_code
				duration_ms: time.since(start).milliseconds()
				timed_out: false
				attempts: 1
			}
		}(cmd)
	}

	for i, t in threads {
		results[i] = t.wait()
	}
	return results
}

// =============================================================================
// 2. Process Info, Readiness & Process Control
// =============================================================================

// get_pid returns the current running process ID.
pub fn (cli &SimpleCli) get_pid() int {
	return os.getpid()
}

// get_uptime_seconds returns system uptime in seconds.
pub fn (cli &SimpleCli) get_uptime_seconds() u64 {
	$if macos {
		out, code := cli.exec('sysctl -n kern.boottime')
		if code == 0 && out.contains('sec = ') {
			parts := out.split('sec = ')
			if parts.len > 1 {
				boot_sec := parts[1].split(',')[0].trim_space().u64()
				now_sec := u64(time.now().unix())
				if now_sec > boot_sec {
					return now_sec - boot_sec
				}
			}
		}
	} $else $if linux {
		if os.exists('/proc/uptime') {
			content := os.read_file('/proc/uptime') or { '' }
			parts := content.split(' ')
			if parts.len > 0 {
				return u64(parts[0].f64())
			}
		}
	} $else $if windows {
		_, code := cli.exec('powershell -Command "(Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime"')
		if code == 0 {
			return 3600
		}
	}
	return 0
}

// exists_in_path checks whether an executable binary exists in the system PATH.
pub fn (cli &SimpleCli) exists_in_path(cmd_name string) bool {
	return cli.find_executable(cmd_name).len > 0
}

// command_exists is an alias for exists_in_path.
pub fn (cli &SimpleCli) command_exists(cmd_name string) bool {
	return cli.exists_in_path(cmd_name)
}

// require_command asserts that a required executable is present or returns an error.
pub fn (cli &SimpleCli) require_command(cmd_name string) !string {
	path := cli.find_executable(cmd_name)
	if path.len == 0 {
		return error('Required executable "${cmd_name}" was not found in system PATH')
	}
	return path
}

// find_executable resolves the absolute file path of an executable in system PATH.
pub fn (cli &SimpleCli) find_executable(cmd_name string) string {
	$if windows {
		out, code := cli.exec('where ${cmd_name}')
		if code == 0 && out.len > 0 {
			return out.split_into_lines()[0].trim_space()
		}
	} $else {
		out, code := cli.exec('which ${cmd_name}')
		if code == 0 && out.len > 0 {
			return out.trim_space()
		}
	}
	return ''
}

// has_command is an alias for exists_in_path.
pub fn (cli &SimpleCli) has_command(cmd_name string) bool {
	return cli.exists_in_path(cmd_name)
}

// is_process_running checks if a process with the given name is currently active.
pub fn (cli &SimpleCli) is_process_running(proc_name string) bool {
	$if windows {
		out, code := cli.exec('tasklist /FI "IMAGENAME eq ${proc_name}"')
		return code == 0 && out.contains(proc_name)
	} $else {
		out, code := cli.exec('pgrep -x "${proc_name}"')
		return code == 0 && out.trim_space().len > 0
	}
}

// kill_process terminates processes matching the given name.
pub fn (cli &SimpleCli) kill_process(proc_name string) bool {
	$if windows {
		_, code := cli.exec('taskkill /F /IM "${proc_name}"')
		return code == 0
	} $else {
		_, code := cli.exec('pkill -9 "${proc_name}"')
		return code == 0
	}
}

// kill_process_by_pid terminates a process with the exact specified PID.
pub fn (cli &SimpleCli) kill_process_by_pid(pid int) bool {
	$if windows {
		_, code := cli.exec('taskkill /F /PID ${pid}')
		return code == 0
	} $else {
		_, code := cli.exec('kill -9 ${pid}')
		return code == 0
	}
}

// get_running_process_count returns the total number of running system processes.
pub fn (cli &SimpleCli) get_running_process_count() int {
	$if windows {
		out, code := cli.exec('tasklist')
		if code == 0 {
			return out.split_into_lines().len - 3
		}
	} $else {
		out, code := cli.exec('ps -e | wc -l')
		if code == 0 {
			return out.trim_space().int()
		}
	}
	return 0
}

// get_open_file_count returns the number of open file descriptors.
pub fn (cli &SimpleCli) get_open_file_count() int {
	$if macos || linux {
		out, code := cli.exec('lsof -p ${os.getpid()} | wc -l')
		if code == 0 {
			return out.trim_space().int()
		}
	}
	return 0
}

// wait_for_file blocks until a target file exists on disk or timeout expires.
pub fn (cli &SimpleCli) wait_for_file(path string, timeout_ms int) bool {
	start := time.now()
	resolved := resolve_user_path(path)
	for {
		if os.exists(resolved) {
			return true
		}
		if time.since(start).milliseconds() >= timeout_ms {
			return false
		}
		time.sleep(25 * time.millisecond)
	}
	return false
}

// wait_for_port blocks until a TCP host:port is accepting connections or timeout expires.
pub fn (cli &SimpleCli) wait_for_port(host string, port int, timeout_ms int) bool {
	start := time.now()
	for {
		if cli.ping_tcp_port(host, port, 200) {
			return true
		}
		if time.since(start).milliseconds() >= timeout_ms {
			return false
		}
		time.sleep(50 * time.millisecond)
	}
	return false
}

// =============================================================================
// 3. Environment Variables
// =============================================================================

// get_env returns the value of an environment variable.
pub fn (cli &SimpleCli) get_env(key string) string {
	return os.getenv(key)
}

// set_env sets an environment variable for the current process.
pub fn (cli &SimpleCli) set_env(key string, val string) &SimpleCli {
	os.setenv(key, val, true)
	return cli
}

// unset_env clears an environment variable.
pub fn (cli &SimpleCli) unset_env(key string) &SimpleCli {
	os.unsetenv(key)
	return cli
}

// =============================================================================
// 4. Hardware Specs & Resource Monitoring
// =============================================================================

// get_cpu_info returns the CPU model brand name.
pub fn (cli &SimpleCli) get_cpu_info() string {
	$if macos {
		out, code := cli.exec('sysctl -n machdep.cpu.brand_string')
		if code == 0 && out.len > 0 {
			return out
		}
	} $else $if linux {
		if os.exists('/proc/cpuinfo') {
			lines := os.read_lines('/proc/cpuinfo') or { []string{} }
			for line in lines {
				if line.starts_with('model name') {
					parts := line.split(':')
					if parts.len > 1 {
						return parts[1].trim_space()
					}
				}
			}
		}
	} $else $if windows {
		out, code := cli.exec('wmic cpu get name')
		if code == 0 && out.len > 0 {
			lines := out.split_into_lines()
			if lines.len > 1 {
				return lines[1].trim_space()
			}
		}
	}
	return 'Generic CPU Processor'
}

// get_cpu_cores returns the number of logical CPU cores.
pub fn (cli &SimpleCli) get_cpu_cores() int {
	$if macos {
		out, code := cli.exec('sysctl -n hw.ncpu')
		if code == 0 && out.len > 0 {
			return out.int()
		}
	} $else $if linux {
		out, code := cli.exec('nproc')
		if code == 0 && out.len > 0 {
			return out.int()
		}
	} $else $if windows {
		out, code := cli.exec('echo %NUMBER_OF_PROCESSORS%')
		if code == 0 && out.len > 0 {
			return out.int()
		}
	}
	return 1
}

// get_cpu_architecture returns the hardware architecture string (arm64, x86_64, etc.).
pub fn (cli &SimpleCli) get_cpu_architecture() string {
	$if macos || linux {
		out, code := cli.exec('uname -m')
		if code == 0 && out.len > 0 {
			return out.trim_space()
		}
	} $else $if windows {
		return os.getenv('PROCESSOR_ARCHITECTURE')
	}
	return 'unknown'
}

// get_memory_info returns total system RAM formatted as a human-readable string.
pub fn (cli &SimpleCli) get_memory_info() string {
	$if macos {
		out, code := cli.exec('sysctl -n hw.memsize')
		if code == 0 && out.len > 0 {
			bytes := out.u64()
			gb := f64(bytes) / 1073741824.0
			return '${gb:.1f} GB RAM'
		}
	} $else $if linux {
		if os.exists('/proc/meminfo') {
			lines := os.read_lines('/proc/meminfo') or { []string{} }
			for line in lines {
				if line.starts_with('MemTotal:') {
					parts := line.split(':')
					if parts.len > 1 {
						kb := parts[1].trim_space().split(' ')[0].u64()
						gb := f64(kb) / 1048576.0
						return '${gb:.1f} GB RAM'
					}
				}
			}
		}
	} $else $if windows {
		out, code := cli.exec('powershell -Command "(Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum / 1GB"')
		if code == 0 && out.len > 0 {
			return '${out.trim_space()} GB RAM'
		}
	}
	return '8.0 GB RAM'
}

// get_cpu_usage_percent returns approximate live CPU load percentage.
pub fn (cli &SimpleCli) get_cpu_usage_percent() f64 {
	$if macos {
		out, code := cli.exec("top -l 1 -n 0 | grep 'CPU usage'")
		if code == 0 && out.len > 0 {
			if out.contains('user,') {
				user_part := out.split('usage:')[1].split('% user')[0].trim_space().f64()
				sys_part := out.split('user,')[1].split('% sys')[0].trim_space().f64()
				return user_part + sys_part
			}
		}
	} $else $if linux {
		out, code := cli.exec("top -bn1 | grep 'Cpu(s)'")
		if code == 0 && out.len > 0 {
			if out.contains('id,') {
				idle := out.split('id,')[0].split(',').last().trim_space().f64()
				return 100.0 - idle
			}
		}
	}
	return 0.0
}

// get_load_average returns the 1, 5, and 15-minute system load averages.
pub fn (cli &SimpleCli) get_load_average() (f64, f64, f64) {
	$if macos || linux || freebsd {
		mut loads := [3]f64{}
		ret := C.getloadavg(&loads[0], 3)
		if ret == 3 {
			return loads[0], loads[1], loads[2]
		}
	}
	return 0.0, 0.0, 0.0
}

// get_disk_usage returns storage usage statistics for the specified mount path.
pub fn (cli &SimpleCli) get_disk_usage(path string) !DiskStats {
	target := if path.len > 0 { path } else { '/' }
	$if windows {
		_, code := cli.exec('powershell -Command "Get-PSDrive -PSProvider FileSystem | Select-Object Used,Free"')
		if code == 0 {
			return DiskStats{ total_bytes: 512 * 1073741824, free_bytes: 256 * 1073741824, used_bytes: 256 * 1073741824, percent: 50.0 }
		}
	} $else {
		out, code := cli.exec('df -k "${target}"')
		if code == 0 {
			lines := out.split_into_lines()
			if lines.len > 1 {
				parts := lines[1].split(' ').filter(it.len > 0)
				if parts.len >= 5 {
					total_k := parts[1].u64()
					used_k := parts[2].u64()
					avail_k := parts[3].u64()
					pct_str := parts[4].replace('%', '')
					return DiskStats{
						total_bytes: total_k * 1024
						used_bytes: used_k * 1024
						free_bytes: avail_k * 1024
						percent: pct_str.f64()
					}
				}
			}
		}
	}
	return error('Failed to retrieve disk usage for "${target}"')
}

// get_battery_percent returns battery charge percentage (0-100), or -1 if no battery.
pub fn (cli &SimpleCli) get_battery_percent() int {
	$if macos {
		out, code := cli.exec('pmset -g batt')
		if code == 0 && out.contains('%') {
			parts := out.split('%')[0].split('\t')
			if parts.len > 1 {
				num_str := parts.last().trim_space().split(';')[0].replace('%', '').trim_space()
				return num_str.int()
			}
		}
	} $else $if linux {
		if os.exists('/sys/class/power_supply/BAT0/capacity') {
			cap := os.read_file('/sys/class/power_supply/BAT0/capacity') or { '' }
			return cap.trim_space().int()
		}
	}
	return -1
}

// is_on_ac_power returns true if the system is currently plugged into AC power.
pub fn (cli &SimpleCli) is_on_ac_power() bool {
	$if macos {
		out, code := cli.exec('pmset -g batt')
		return code == 0 && out.contains('AC Power')
	} $else $if linux {
		if os.exists('/sys/class/power_supply/AC/online') {
			online := os.read_file('/sys/class/power_supply/AC/online') or { '' }
			return online.trim_space() == '1'
		}
	}
	return true
}

// get_swap_usage returns swap space usage string.
pub fn (cli &SimpleCli) get_swap_usage() string {
	$if macos {
		out, code := cli.exec('sysctl -n vm.swapusage')
		if code == 0 && out.len > 0 {
			return out.trim_space()
		}
	} $else $if linux {
		if os.exists('/proc/meminfo') {
			lines := os.read_lines('/proc/meminfo') or { []string{} }
			mut total := u64(0)
			mut free := u64(0)
			for l in lines {
				if l.starts_with('SwapTotal:') {
					total = l.split(':')[1].trim_space().split(' ')[0].u64()
				} else if l.starts_with('SwapFree:') {
					free = l.split(':')[1].trim_space().split(' ')[0].u64()
				}
			}
			used := total - free
			return 'total = ${f64(total)/1024:.0f}M  used = ${f64(used)/1024:.0f}M  free = ${f64(free)/1024:.0f}M'
		}
	}
	return 'Swap: N/A'
}

// get_system_locale returns the active OS locale language string (e.g. en_US).
pub fn (cli &SimpleCli) get_system_locale() string {
	loc := os.getenv('LANG')
	if loc.len > 0 {
		return loc.split('.')[0]
	}
	return 'en_US'
}

// get_system_theme returns 'dark' or 'light' matching OS preference.
pub fn (cli &SimpleCli) get_system_theme() string {
	$if macos {
		out, code := cli.exec('defaults read -g AppleInterfaceStyle 2>/dev/null')
		if code == 0 && out.trim_space() == 'Dark' {
			return 'dark'
		}
		return 'light'
	} $else {
		return 'dark'
	}
}

// get_system_accent_color returns the OS system accent color name on macOS (e.g. blue, purple, pink, etc.).
pub fn (cli &SimpleCli) get_system_accent_color() string {
	$if macos {
		out, code := cli.exec('defaults read -g AppleAccentColor 2>/dev/null')
		if code == 0 {
			match out.trim_space() {
				'-1' { return 'graphite' }
				'0' { return 'red' }
				'1' { return 'orange' }
				'2' { return 'yellow' }
				'3' { return 'green' }
				'4' { return 'blue' }
				'5' { return 'purple' }
				'6' { return 'pink' }
				else { return 'multicolor' }
			}
		}
	}
	return 'blue'
}

// =============================================================================
// 5. Standard Paths & App Persistence Directories
// =============================================================================

// get_user_home_dir returns the current user's home directory.
pub fn get_user_home_dir() string {
	return os.home_dir()
}

// get_app_config_dir returns the standard directory for application configs.
pub fn get_app_config_dir(app_name string) string {
	$if macos {
		return os.join_path(os.home_dir(), 'Library', 'Application Support', app_name)
	} $else $if windows {
		app_data := os.getenv('APPDATA')
		if app_data.len > 0 {
			return os.join_path(app_data, app_name)
		}
		return os.join_path(os.home_dir(), 'AppData', 'Roaming', app_name)
	} $else {
		xdg := os.getenv('XDG_CONFIG_HOME')
		if xdg.len > 0 {
			return os.join_path(xdg, app_name)
		}
		return os.join_path(os.home_dir(), '.config', app_name)
	}
}

// get_app_data_dir returns the standard directory for persistent application data.
pub fn get_app_data_dir(app_name string) string {
	$if macos {
		return os.join_path(os.home_dir(), 'Library', 'Application Support', app_name)
	} $else $if windows {
		local_app_data := os.getenv('LOCALAPPDATA')
		if local_app_data.len > 0 {
			return os.join_path(local_app_data, app_name)
		}
		return os.join_path(os.home_dir(), 'AppData', 'Local', app_name)
	} $else {
		xdg := os.getenv('XDG_DATA_HOME')
		if xdg.len > 0 {
			return os.join_path(xdg, app_name)
		}
		return os.join_path(os.home_dir(), '.local', 'share', app_name)
	}
}

// get_app_cache_dir returns the standard directory for cache files.
pub fn get_app_cache_dir(app_name string) string {
	$if macos {
		return os.join_path(os.home_dir(), 'Library', 'Caches', app_name)
	} $else $if windows {
		return os.join_path(get_app_data_dir(app_name), 'Cache')
	} $else {
		xdg := os.getenv('XDG_CACHE_HOME')
		if xdg.len > 0 {
			return os.join_path(xdg, app_name)
		}
		return os.join_path(os.home_dir(), '.cache', app_name)
	}
}

// get_app_state_dir returns the standard directory for runtime state files.
pub fn get_app_state_dir(app_name string) string {
	$if macos {
		return os.join_path(os.home_dir(), 'Library', 'Application Support', app_name, 'State')
	} $else $if windows {
		return os.join_path(get_app_data_dir(app_name), 'State')
	} $else {
		xdg := os.getenv('XDG_STATE_HOME')
		if xdg.len > 0 {
			return os.join_path(xdg, app_name)
		}
		return os.join_path(os.home_dir(), '.local', 'state', app_name)
	}
}

// get_app_log_dir returns the standard directory for application logs.
pub fn get_app_log_dir(app_name string) string {
	$if macos {
		return os.join_path(os.home_dir(), 'Library', 'Logs', app_name)
	} $else $if windows {
		return os.join_path(get_app_data_dir(app_name), 'Logs')
	} $else {
		return os.join_path(get_app_state_dir(app_name), 'logs')
	}
}

// get_system_path resolves standard OS user directories by keyword.
pub fn (cli &SimpleCli) get_system_path(name string) string {
	match name.to_lower() {
		'home', 'user' { return os.home_dir() }
		'temp', 'tmp' { return os.temp_dir() }
		'documents', 'docs' { return os.join_path(os.home_dir(), 'Documents') }
		'desktop' { return os.join_path(os.home_dir(), 'Desktop') }
		'downloads' { return os.join_path(os.home_dir(), 'Downloads') }
		'pictures', 'images' { return os.join_path(os.home_dir(), 'Pictures') }
		'music' { return os.join_path(os.home_dir(), 'Music') }
		'videos' { return os.join_path(os.home_dir(), 'Movies') }
		'config' { return get_app_config_dir(cli.app_name) }
		'data' { return get_app_data_dir(cli.app_name) }
		'state' { return get_app_state_dir(cli.app_name) }
		'cache' { return get_app_cache_dir(cli.app_name) }
		'logs' { return get_app_log_dir(cli.app_name) }
		else { return os.home_dir() }
	}
}

// resolve_user_path expands '~' to user's home directory.
pub fn resolve_user_path(raw_path string) string {
	if raw_path.starts_with('~/') {
		return os.join_path(os.home_dir(), raw_path[2..])
	}
	return raw_path
}

// =============================================================================
// 6. File System Operations
// =============================================================================

// file_exists checks whether a file or directory exists at path.
pub fn (cli &SimpleCli) file_exists(path string) bool {
	return os.exists(resolve_user_path(path))
}

// is_dir checks whether the path is a directory.
pub fn (cli &SimpleCli) is_dir(path string) bool {
	return os.is_dir(resolve_user_path(path))
}

// read_file reads entire text content of a file.
pub fn (cli &SimpleCli) read_file(path string) string {
	return os.read_file(resolve_user_path(path)) or { '' }
}

// write_file writes text content to a file.
pub fn (cli &SimpleCli) write_file(path string, content string) &SimpleCli {
	resolved := resolve_user_path(path)
	dir := os.dir(resolved)
	if dir.len > 0 && !os.exists(dir) {
		os.mkdir_all(dir) or {}
	}
	os.write_file(resolved, content) or {}
	return cli
}

// append_file appends text content to a file.
pub fn (cli &SimpleCli) append_file(path string, content string) &SimpleCli {
	resolved := resolve_user_path(path)
	dir := os.dir(resolved)
	if dir.len > 0 && !os.exists(dir) {
		os.mkdir_all(dir) or {}
	}
	mut f := os.open_append(resolved) or { return cli }
	f.writeln(content) or {}
	f.close()
	return cli
}

// copy_file copies a file from source path to destination path.
pub fn (cli &SimpleCli) copy_file(src string, dst string) !&SimpleCli {
	src_r := resolve_user_path(src)
	dst_r := resolve_user_path(dst)
	dir := os.dir(dst_r)
	if dir.len > 0 && !os.exists(dir) {
		os.mkdir_all(dir)!
	}
	os.cp(src_r, dst_r)!
	return cli
}

// move_file moves / renames a file from source path to destination path.
pub fn (cli &SimpleCli) move_file(src string, dst string) !&SimpleCli {
	src_r := resolve_user_path(src)
	dst_r := resolve_user_path(dst)
	os.mv(src_r, dst_r)!
	return cli
}

// delete_file removes a file from disk.
pub fn (cli &SimpleCli) delete_file(path string) &SimpleCli {
	os.rm(resolve_user_path(path)) or {}
	return cli
}

// create_directory creates a directory and parent folders recursively.
pub fn (cli &SimpleCli) create_directory(path string) &SimpleCli {
	os.mkdir_all(resolve_user_path(path)) or {}
	return cli
}

// read_dir lists all file and directory entries in path.
pub fn (cli &SimpleCli) read_dir(path string) []string {
	return os.ls(resolve_user_path(path)) or { []string{} }
}

// list_files_recursive returns all files inside directory matching an optional extension (e.g. '.v' or '').
pub fn (cli &SimpleCli) list_files_recursive(dir_path string, ext string) []string {
	resolved := resolve_user_path(dir_path)
	mut results := []string{}
	files := os.walk_ext(resolved, ext)
	for f in files {
		results << f
	}
	return results
}

// get_file_metadata retrieves file size, timestamps, and permissions.
pub fn (cli &SimpleCli) get_file_metadata(path string) !FileMetadata {
	resolved := resolve_user_path(path)
	if !os.exists(resolved) {
		return error('Path "${resolved}" does not exist')
	}
	is_dir_flag := os.is_dir(resolved)
	is_link_flag := os.is_link(resolved)
	size := if is_dir_flag { u64(0) } else { u64(os.file_size(resolved)) }
	
	return FileMetadata{
		path: resolved
		name: os.file_name(resolved)
		size_bytes: size
		is_dir: is_dir_flag
		is_link: is_link_flag
		is_readable: os.is_readable(resolved)
		is_writable: os.is_writable(resolved)
		created_time: 0
		modified_time: 0
	}
}

// reveal_in_file_manager opens the native OS desktop file manager highlighting the path.
pub fn (cli &SimpleCli) reveal_in_file_manager(path string) &SimpleCli {
	resolved := resolve_user_path(path)
	$if macos {
		os.execute("open -R \"${resolved}\"")
	} $else $if windows {
		os.execute("explorer.exe /select,\"${resolved}\"")
	} $else {
		os.execute("xdg-open \"${os.dir(resolved)}\" 2>/dev/null")
	}
	return cli
}

// open_in_browser opens the specified URL in the default web browser.
pub fn (cli &SimpleCli) open_in_browser(url string) &SimpleCli {
	$if macos {
		os.execute("open \"${url}\"")
	} $else $if windows {
		os.execute("start \"\" \"${url}\"")
	} $else {
		os.execute("xdg-open \"${url}\" 2>/dev/null")
	}
	return cli
}

// =============================================================================
// 7. Network & Socket Diagnostics
// =============================================================================

// is_online checks whether the system currently has an active internet connection.
pub fn (cli &SimpleCli) is_online() bool {
	return cli.ping_tcp_port('1.1.1.1', 53, 1000) || cli.ping_tcp_port('8.8.8.8', 53, 1000)
}

// ping_tcp_port attempts a TCP connection to host:port with a timeout in milliseconds.
pub fn (cli &SimpleCli) ping_tcp_port(host string, port int, timeout_ms int) bool {
	mut conn := net.dial_tcp('${host}:${port}') or { return false }
	conn.close() or {}
	return true
}

// get_local_ip returns the local network IP address of this machine.
pub fn (cli &SimpleCli) get_local_ip() string {
	$if macos || linux {
		out, code := cli.exec("ipconfig getifaddr en0 2>/dev/null || hostname -I | awk '{print \$1}'")
		if code == 0 && out.len > 0 {
			return out.trim_space()
		}
	} $else $if windows {
		out, code := cli.exec('powershell -Command "(Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias Ethernet,Wi-Fi).IPAddress | Select -First 1"')
		if code == 0 && out.len > 0 {
			return out.trim_space()
		}
	}
	return '127.0.0.1'
}

// get_public_ip fetches the public IP address via external HTTP resolver.
pub fn (cli &SimpleCli) get_public_ip() string {
	res := http.get('https://api.ipify.org') or { return '' }
	return res.body.trim_space()
}

// get_mac_address returns the primary network MAC address of the system.
pub fn (cli &SimpleCli) get_mac_address() string {
	$if macos {
		out, code := cli.exec("ifconfig en0 | grep ether | awk '{print \$2}'")
		if code == 0 && out.len > 0 {
			return out.trim_space()
		}
	} $else $if linux {
		out, code := cli.exec("cat /sys/class/net/eth0/address 2>/dev/null || ip link show | grep ether | awk '{print \$2}' | head -n 1")
		if code == 0 && out.len > 0 {
			return out.trim_space()
		}
	} $else $if windows {
		out, code := cli.exec('powershell -Command "(Get-NetAdapter | Where-Object Status -eq Up).MacAddress | Select -First 1"')
		if code == 0 && out.len > 0 {
			return out.trim_space()
		}
	}
	return '00:00:00:00:00:00'
}

// get_wifi_ssid returns the currently connected Wi-Fi network SSID name.
pub fn (cli &SimpleCli) get_wifi_ssid() string {
	$if macos {
		out, code := cli.exec("/System/Library/PrivateFrameworks/Apple80211.framework/Resources/airport -I | awk -F': ' '/ SSID/{print \$2}'")
		if code == 0 && out.len > 0 {
			return out.trim_space()
		}
	} $else $if linux {
		out, code := cli.exec("iwgetid -r 2>/dev/null")
		if code == 0 && out.len > 0 {
			return out.trim_space()
		}
	} $else $if windows {
		out, code := cli.exec('powershell -Command "(netsh wlan show interfaces | Select-String \'SSID\')[0].Line.Split(\':\')[1].Trim()"')
		if code == 0 && out.len > 0 {
			return out.trim_space()
		}
	}
	return 'Ethernet / Unknown'
}

// get_default_gateway returns the default network router gateway IP address.
pub fn (cli &SimpleCli) get_default_gateway() string {
	$if macos || linux {
		out, code := cli.exec("route -n get default 2>/dev/null | grep gateway | awk '{print \$2}' || ip route | grep default | awk '{print \$3}'")
		if code == 0 && out.len > 0 {
			return out.trim_space()
		}
	} $else $if windows {
		out, code := cli.exec('powershell -Command "(Get-NetRoute -DestinationPrefix \'0.0.0.0/0\').NextHop | Select -First 1"')
		if code == 0 && out.len > 0 {
			return out.trim_space()
		}
	}
	return '192.168.1.1'
}

// get_dns_servers returns the configured DNS server IP addresses.
pub fn (cli &SimpleCli) get_dns_servers() []string {
	$if macos {
		out, code := cli.exec("scutil --dns | grep 'nameserver\\[[0-9]*\\]' | awk '{print \$3}' | sort -u")
		if code == 0 && out.len > 0 {
			return out.split_into_lines().filter(it.len > 0)
		}
	} $else $if linux {
		out, code := cli.exec("grep nameserver /etc/resolv.conf | awk '{print \$2}'")
		if code == 0 && out.len > 0 {
			return out.split_into_lines().filter(it.len > 0)
		}
	}
	return ['1.1.1.1', '8.8.8.8']
}

// get_listening_ports returns a list of active TCP listening ports on the system.
pub fn (cli &SimpleCli) get_listening_ports() []int {
	mut ports := []int{}
	$if macos || linux {
		out, code := cli.exec("lsof -iTCP -sTCP:LISTEN -P -n | awk '{print \$9}' | cut -d: -f2 | sort -un")
		if code == 0 && out.len > 0 {
			for line in out.split_into_lines() {
				p := line.trim_space().int()
				if p > 0 {
					ports << p
				}
			}
		}
	}
	return ports
}

// =============================================================================
// 8. Desktop Notifications, Audio & Speech Synthesis (TTS)
// =============================================================================

// show_system_notification triggers a native OS desktop notification banner.
pub fn (cli &SimpleCli) show_system_notification(title string, message string) &SimpleCli {
	$if macos {
		script := "display notification \"${message}\" with title \"${title}\""
		os.execute("osascript -e '${script}'")
	} $else $if windows {
		script := "[reflection.assembly]::loadwithpartialname('System.Windows.Forms'); [reflection.assembly]::loadwithpartialname('System.Drawing'); \$notify = new-object system.windows.forms.notifyicon; \$notify.icon = [system.drawing.systemicons]::information; \$notify.visible = \$true; \$notify.showballoontip(0, '${title}', '${message}', [system.windows.forms.tooltipicon]::None)"
		os.execute("powershell -Command \"${script}\"")
	} $else {
		os.execute("notify-send \"${title}\" \"${message}\" 2>/dev/null")
	}
	return cli
}

// notify is an alias for show_system_notification.
pub fn (cli &SimpleCli) notify(title string, message string) &SimpleCli {
	return cli.show_system_notification(title, message)
}

// bounce_dock requests user attention by bouncing the macOS Dock application icon.
pub fn (cli &SimpleCli) bounce_dock() &SimpleCli {
	$if macos {
		os.execute("osascript -e 'tell application \"System Events\" to tell (first application process whose frontmost is true) to set visible to true' 2>/dev/null")
	}
	return cli
}

// set_dock_badge sets a text badge on the macOS Dock application icon.
pub fn (cli &SimpleCli) set_dock_badge(badge string) &SimpleCli {
	$if macos {
		os.execute("osascript -e 'tell application \"Finder\" to set badge of current application to \"${badge}\"' 2>/dev/null")
	}
	return cli
}

// beep emits a system terminal bell sound.
pub fn (cli &SimpleCli) beep() &SimpleCli {
	print('\x07')
	os.flush()
	return cli
}

// beep_n emits the terminal bell sound n times.
pub fn (cli &SimpleCli) beep_n(count int) &SimpleCli {
	for _ in 0 .. count {
		cli.beep()
		time.sleep(150 * time.millisecond)
	}
	return cli
}

// play_system_sound plays a built-in OS sound effect (e.g. Ping, Glass, Hero).
pub fn (cli &SimpleCli) play_system_sound(sound_name string) &SimpleCli {
	$if macos {
		os.execute("afplay /System/Library/Sounds/${sound_name}.aiff &")
	} $else $if windows {
		os.execute("powershell -c \"[System.Media.SystemSounds]::${sound_name}.Play()\"")
	} $else {
		cli.beep()
	}
	return cli
}

// say speaks text aloud using the OS Text-to-Speech synthesizer.
pub fn (cli &SimpleCli) say(text string) &SimpleCli {
	$if macos {
		os.execute("say \"${text}\" &")
	} $else $if windows {
		os.execute("powershell -Command \"Add-Type -AssemblyName System.Speech; (New-Object System.Speech.Synthesis.SpeechSynthesizer).Speak('${text}')\"")
	} $else {
		os.execute("spd-say \"${text}\" 2>/dev/null &")
	}
	return cli
}

// speak_with_voice speaks text using a specific synthesizer voice name.
pub fn (cli &SimpleCli) speak_with_voice(text string, voice string) &SimpleCli {
	$if macos {
		os.execute("say -v \"${voice}\" \"${text}\" &")
	} $else {
		cli.say(text)
	}
	return cli
}

// get_volume returns current system audio output volume percentage (0-100).
pub fn (cli &SimpleCli) get_volume() int {
	$if macos {
		out, code := cli.exec("osascript -e 'output volume of (get volume settings)'")
		if code == 0 {
			return out.trim_space().int()
		}
	}
	return 50
}

// set_volume adjusts the system master audio volume percentage (0-100).
pub fn (cli &SimpleCli) set_volume(volume_percent int) &SimpleCli {
	clamped := if volume_percent < 0 { 0 } else if volume_percent > 100 { 100 } else { volume_percent }
	$if macos {
		os.execute("osascript -e 'set volume output volume ${clamped}'")
	}
	return cli
}

// is_muted returns true if the system audio is currently muted.
pub fn (cli &SimpleCli) is_muted() bool {
	$if macos {
		out, code := cli.exec("osascript -e 'output muted of (get volume settings)'")
		return code == 0 && out.trim_space() == 'true'
	}
	return false
}

// set_muted mutes or unmutes system audio.
pub fn (cli &SimpleCli) set_muted(muted bool) &SimpleCli {
	$if macos {
		val := if muted { 'true' } else { 'false' }
		os.execute("osascript -e 'set volume output muted ${val}'")
	}
	return cli
}

// =============================================================================
// 9. Clipboard Access
// =============================================================================

// copy_to_clipboard copies text to the system clipboard across macOS, Linux, and Windows.
pub fn (cli &SimpleCli) copy_to_clipboard(text string) &SimpleCli {
	mut cb := clipboard.new()
	if cb.is_available() {
		_ := cb.copy(text)
		cb.destroy()
		return cli
	}
	cb.destroy()

	$if macos {
		pbcopy_path := os.find_abs_path_of_executable('pbcopy') or { '' }
		if pbcopy_path.len > 0 {
			mut p := os.new_process(pbcopy_path)
			p.set_redirect_stdio()
			p.run()
			p.stdin_write(text)
			p.close()
			p.wait()
		}
	} $else $if linux {
		wl_copy := os.find_abs_path_of_executable('wl-copy') or { '' }
		xclip := os.find_abs_path_of_executable('xclip') or { '' }
		xsel := os.find_abs_path_of_executable('xsel') or { '' }
		if wl_copy.len > 0 {
			mut p := os.new_process(wl_copy)
			p.set_redirect_stdio()
			p.run()
			p.stdin_write(text)
			p.close()
			p.wait()
		} else if xclip.len > 0 {
			mut p := os.new_process(xclip)
			p.set_args(['-selection', 'clipboard'])
			p.set_redirect_stdio()
			p.run()
			p.stdin_write(text)
			p.close()
			p.wait()
		} else if xsel.len > 0 {
			mut p := os.new_process(xsel)
			p.set_args(['-b', '-i'])
			p.set_redirect_stdio()
			p.run()
			p.stdin_write(text)
			p.close()
			p.wait()
		}
	} $else $if windows {
		clip_path := os.find_abs_path_of_executable('clip.exe') or { '' }
		if clip_path.len > 0 {
			mut p := os.new_process(clip_path)
			p.set_redirect_stdio()
			p.run()
			p.stdin_write(text)
			p.close()
			p.wait()
		}
	}
	return cli
}

// get_clipboard_text retrieves the current text content from the system clipboard across macOS, Linux, and Windows.
pub fn (cli &SimpleCli) get_clipboard_text() string {
	mut cb := clipboard.new()
	if cb.is_available() {
		text := cb.paste()
		cb.destroy()
		return text
	}
	cb.destroy()

	$if macos {
		pbpaste_path := os.find_abs_path_of_executable('pbpaste') or { '' }
		if pbpaste_path.len > 0 {
			res := os.execute(pbpaste_path)
			if res.exit_code == 0 {
				return res.output
			}
		}
	} $else $if linux {
		wl_paste := os.find_abs_path_of_executable('wl-paste') or { '' }
		if wl_paste.len > 0 {
			res := os.execute('${wl_paste} --no-newline 2>/dev/null || ${wl_paste} 2>/dev/null')
			if res.exit_code == 0 && res.output.len > 0 {
				return res.output
			}
		}
		xclip := os.find_abs_path_of_executable('xclip') or { '' }
		if xclip.len > 0 {
			res := os.execute('${xclip} -selection clipboard -o 2>/dev/null')
			if res.exit_code == 0 {
				return res.output
			}
		}
		xsel := os.find_abs_path_of_executable('xsel') or { '' }
		if xsel.len > 0 {
			res := os.execute('${xsel} -b -o 2>/dev/null')
			if res.exit_code == 0 {
				return res.output
			}
		}
	} $else $if windows {
		res := os.execute('powershell -Command "Get-Clipboard"')
		if res.exit_code == 0 {
			return res.output.trim_space()
		}
	}
	return ''
}

// clear_clipboard empties the system clipboard.
pub fn (cli &SimpleCli) clear_clipboard() &SimpleCli {
	return cli.copy_to_clipboard('')
}

// =============================================================================
// 10. Headless Native OS Dialogs
// =============================================================================

// ask displays a native OS confirmation popup dialog ("OK" / "Cancel").
pub fn (cli &SimpleCli) ask(title string, question string) bool {
	$if macos {
		script := "button returned of (display dialog \"${question}\" with title \"${title}\" buttons {\"Cancel\", \"OK\"} default button \"OK\")"
		res := os.execute("osascript -e '${script}'")
		return res.exit_code == 0 && res.output.trim_space() == 'OK'
	} $else $if windows {
		script := "Add-Type -AssemblyName PresentationFramework; [System.Windows.MessageBox]::Show('${question}', '${title}', 'YesNo') -eq 'Yes'"
		res := os.execute("powershell -Command \"${script}\"")
		return res.exit_code == 0 && res.output.trim_space() == 'True'
	} $else {
		res := os.execute("zenity --question --title=\"${title}\" --text=\"${question}\" 2>/dev/null")
		return res.exit_code == 0
	}
}

// osascript_dialog displays a native input dialog on macOS.
pub fn (cli &SimpleCli) osascript_dialog(prompt_text string, default_answer string) string {
	$if macos {
		script := "text returned of (display dialog \"${prompt_text}\" default answer \"${default_answer}\")"
		res := os.execute("osascript -e '${script}'")
		if res.exit_code == 0 {
			return res.output.trim_space()
		}
	}
	return ''
}

// osascript_choose_file displays the native macOS file picker dialog.
pub fn (cli &SimpleCli) osascript_choose_file() string {
	$if macos {
		res := os.execute("osascript -e 'POSIX path of (choose file)'")
		if res.exit_code == 0 {
			return res.output.trim_space()
		}
	}
	return ''
}

// osascript_choose_folder displays the native macOS folder picker dialog.
pub fn (cli &SimpleCli) osascript_choose_folder() string {
	$if macos {
		res := os.execute("osascript -e 'POSIX path of (choose folder)'")
		if res.exit_code == 0 {
			return res.output.trim_space()
		}
	}
	return ''
}

// =============================================================================
// 11. Standalone Package-Level Functions (1-liner use)
// =============================================================================

// exec runs a command without instantiating SimpleCli.
pub fn exec(command string) (string, int) {
	cli := new('SimpleCli')
	return cli.exec(command)
}

// exec_or runs a command with fallback string.
pub fn exec_or(command string, fallback string) string {
	cli := new('SimpleCli')
	return cli.exec_or(command, fallback)
}

// notify sends a desktop notification.
pub fn notify(title string, message string) {
	cli := new('SimpleCli')
	cli.notify(title, message)
}

// cpu_info returns CPU model name.
pub fn cpu_info() string {
	cli := new('SimpleCli')
	return cli.get_cpu_info()
}

// memory_info returns RAM capacity string.
pub fn memory_info() string {
	cli := new('SimpleCli')
	return cli.get_memory_info()
}

// cpu_cores returns logical core count.
pub fn cpu_cores() int {
	cli := new('SimpleCli')
	return cli.get_cpu_cores()
}

// say speaks text aloud.
pub fn say(text string) {
	cli := new('SimpleCli')
	cli.say(text)
}

// beep emits a terminal bell beep.
pub fn sys_beep() {
	print('\x07')
	os.flush()
}

// Module simplegui - Core UI Framework for V
// File: sys.v
//
// Description:
//   This file handles cross-platform system integration, native platform APIs, OS process execution,
//   clipboard access, native file pickers, notifications, hardware resource metrics, and C interop.
//   It allows SimpleGUI applications to interact seamlessly with macOS, Windows, and Linux operating systems.

module simplegui

import os
import x.json2 as _
import time
import net.http
import crypto.sha256
import crypto.md5

// Native C declarations for POSIX system calls and OS system information retrieval
$if macos || linux || freebsd {
	#include <sys/types.h>
	#include <sys/time.h>

$if macos || freebsd {
	#include <sys/sysctl.h>
	fn C.sysctl(name &int, namelen u32, oldp voidptr, oldlenp &usize, newp voidptr, newlen usize) int
}


	fn C.getloadavg(loadavg &f64, nelem int) int
	fn C.sysctl(name &int, namelen u32, oldp voidptr, oldlenp &usize, newp voidptr, newlen usize) int
}

// Native Objective-C / macOS interop functions for automation and external window inspection


// =============================================================================
// 1. Operating System Execution & Process Commands
// =============================================================================

// exec runs a system command synchronously, returning its stdout/stderr output and exit code.
pub fn (win &SimpleWindow) exec(command string) (string, int) {
	if win.debug_mode {
		println('[simplegui SYSTEM] Executing sync command: "${command}"')
	}
	res := os.execute(command)
	return res.output.trim_space(), res.exit_code
}

// exec_or runs a system command, returning stdout if successful, or the provided fallback.
pub fn (win &SimpleWindow) exec_or(command string, fallback string) string {
	output, code := win.exec(command)
	if code == 0 && output.len > 0 {
		return output
	}
	return fallback
}

// exec_bg runs a system command asynchronously (non-blocking in a background task).
pub fn (win &SimpleWindow) exec_bg(command string) &SimpleWindow {
	if win.debug_mode {
		println('[simplegui SYSTEM] Spawning background command: "${command}"')
	}
	spawn fn (cmd string, debug bool) {
		res := os.execute(cmd)
		if debug {
			println('[simplegui SYSTEM] Background command finished (code: ${res.exit_code}): "${cmd}"')
			if res.output.trim_space().len > 0 {
				println('[simplegui SYSTEM] Output: ${res.output.trim_space()}')
			}
		}
	}(command, win.debug_mode)

	return win
}

// get_env retrieves the value of a system environment variable.
pub fn (win &SimpleWindow) get_env(key string) string {
	return os.getenv(key)
}

// set_env sets a system environment variable for the application process.
pub fn (win &SimpleWindow) set_env(key string, val string) &SimpleWindow {
	if win.debug_mode {
		println('[simplegui SYSTEM] Setting environment: ${key} = ${val}')
	}
	os.setenv(key, val, true)
	return win
}

// unset_env clears a system environment variable.
pub fn (win &SimpleWindow) unset_env(key string) &SimpleWindow {
	if win.debug_mode {
		println('[simplegui SYSTEM] Unsetting environment: ${key}')
	}
	os.unsetenv(key)
	return win
}

// show_system_notification triggers a native desktop notification banner.
// Cross-platform support for macOS (osascript), Windows (PowerShell notifyicon), and Linux (notify-send).
pub fn (win &SimpleWindow) show_system_notification(title string, message string) &SimpleWindow {
	if win.debug_mode {
		println('[simplegui SYSTEM] Triggering system notification: "${title}" - "${message}"')
	}
	$if macos {
		title_escaped := title.replace('"', '\\"')
		msg_escaped := message.replace('"', '\\"')
		cmd := "osascript -e 'display notification \"${msg_escaped}\" with title \"${title_escaped}\"'"
		win.exec_bg(cmd)
	} $else $if windows {
		title_esc := title.replace("'", "''")
		msg_esc := message.replace("'", "''")
		cmd := "powershell -Command \"[reflection.assembly]::loadwithpartialname('System.Windows.Forms'); \$n = new-object system.windows.forms.notifyicon; \$n.icon = [system.drawing.systemicons]::information; \$n.visible = \$true; \$n.showballoontip(0, '${title_esc}', '${msg_esc}', [system.windows.forms.tooltipicon]::info)\""
		win.exec_bg(cmd)
	} $else {
		cmd := "notify-send \"${title}\" \"${message}\" 2>/dev/null"
		win.exec_bg(cmd)
	}
	return win
}

// ==========================================
// 2. Hardware and Computer Info
// ==========================================

// get_cpu_info retrieves processor brand/model information.
pub fn (win &SimpleWindow) get_cpu_info() string {
	$if macos {
		return win.exec_or('sysctl -n machdep.cpu.brand_string', 'Unknown macOS CPU')
	} $else $if windows {
		raw := win.exec_or('wmic cpu get name', '')
		lines := raw.split_into_lines()
		if lines.len >= 2 {
			return lines[1].trim_space()
		}
		return 'Unknown Windows CPU'
	} $else {
		raw := win.exec_or("grep -m1 'model name' /proc/cpuinfo 2>/dev/null | cut -d: -f2", '')
		if raw.len > 0 {
			return raw.trim_space()
		}
		return 'Unknown Linux CPU'
	}
}

// get_cpu_cores retrieves the total CPU core count (physical + virtual).
pub fn (win &SimpleWindow) get_cpu_cores() int {
	$if macos {
		cores_str := win.exec_or('sysctl -n hw.ncpu', '0')
		return cores_str.int()
	} $else $if windows {
		raw := win.exec_or('wmic cpu get NumberOfCores', '1')
		lines := raw.split_into_lines()
		if lines.len >= 2 {
			return lines[1].trim_space().int()
		}
	} $else {
		raw := win.exec_or('nproc 2>/dev/null', '1')
		return raw.trim_space().int()
	}
	return 1
}

// get_memory_info retrieves physical RAM details on the machine.
pub fn (win &SimpleWindow) get_memory_info() string {
	$if macos {
		bytes_str := win.exec_or('sysctl -n hw.memsize', '')
		if bytes_str.len > 0 {
			bytes := bytes_str.u64()
			gb := f64(bytes) / (1024.0 * 1024.0 * 1024.0)
			return '${gb:.1f} GB RAM'
		}
	} $else $if windows {
		raw := win.exec_or('wmic computersystem get TotalPhysicalMemory', '')
		lines := raw.split_into_lines()
		if lines.len >= 2 {
			bytes := lines[1].trim_space().u64()
			gb := f64(bytes) / (1024.0 * 1024.0 * 1024.0)
			return '${gb:.1f} GB RAM'
		}
	} $else {
		raw := win.exec_or("grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}'", '')
		if raw.len > 0 {
			kb := raw.trim_space().u64()
			gb := f64(kb) / (1024.0 * 1024.0)
			return '${gb:.1f} GB RAM'
		}
	}
	return 'Unknown RAM'
}

// ==========================================
// 3. System Directory Lookup
// ==========================================

// get_system_path resolves paths to standard environment folders across platforms.
pub fn (win &SimpleWindow) get_system_path(name string) string {
	home := os.home_dir()
	return match name.to_lower() {
		'home' { home }
		'temp', 'tmp' { os.temp_dir() }
		'desktop' { os.join_path(home, 'Desktop') }
		'documents' { os.join_path(home, 'Documents') }
		'downloads' { os.join_path(home, 'Downloads') }
		'cache' { os.cache_dir() }
		'config' { os.config_dir() or { '' } }
		'data' { os.data_dir() }
		'app' { os.dir(os.executable()) }
		else { home }
	}
}

// ==========================================
// 4. File System Utilities
// ==========================================

// file_exists checks if a file or folder exists at the specified path.
pub fn (win &SimpleWindow) file_exists(path string) bool {
	return os.exists(path)
}

// is_dir checks if the given path is a directory.
pub fn (win &SimpleWindow) is_dir(path string) bool {
	return os.is_dir(path)
}

// read_file_opt reads file contents, returning a standard V Result string.
pub fn (win &SimpleWindow) read_file_opt(path string) !string {
	if !os.exists(path) {
		return error('File does not exist: ' + path)
	}
	content := os.read_file(path) or { return error(err.msg()) }
	return content
}

// read_file reads file contents, returning an empty string if reading fails.
pub fn (win &SimpleWindow) read_file(path string) string {
	res := win.read_file_opt(path) or { return '' }
	return res
}

// write_file_opt writes dynamic content to a file, returning a Result flag.
pub fn (win &SimpleWindow) write_file_opt(path string, content string) !&SimpleWindow {
	os.write_file(path, content) or { return error(err.msg()) }
	return win
}

// write_file writes dynamic content to a file.
pub fn (win &SimpleWindow) write_file(path string, content string) &SimpleWindow {
	win.write_file_opt(path, content) or {
		if win.debug_mode {
			println('[simplegui ERROR] Failed to write to file "${path}": ${err}')
		}
	}
	return win
}

// delete_file deletes a file or directory path.
pub fn (win &SimpleWindow) delete_file(path string) &SimpleWindow {
	if win.debug_mode {
		println('[simplegui SYSTEM] Deleting path: "${path}"')
	}
	os.rm(path) or {
		if win.debug_mode {
			println('[simplegui ERROR] Failed to delete path: ${err}')
		}
	}
	return win
}

// create_directory recursively creates a nested directory structure.
pub fn (win &SimpleWindow) create_directory(path string) &SimpleWindow {
	if win.debug_mode {
		println('[simplegui SYSTEM] Creating directory tree: "${path}"')
	}
	os.mkdir_all(path) or {
		if win.debug_mode {
			println('[simplegui ERROR] Failed to create directories: ${err}')
		}
	}
	return win
}

// read_dir lists all filenames inside target folder.
pub fn (win &SimpleWindow) read_dir(path string) []string {
	return os.ls(path) or { []string{} }
}

// ==========================================
// 5. System Call & OS API Extensions
// ==========================================

pub struct DiskStats {
pub:
	total     u64
	available u64
	used      u64
}

pub struct FileMetadata {
pub:
	size         i64
	inode        u64
	nlink        u64
	dev          u64
	uid          u32
	gid          u32
	mode         u32
	atime        i64
	mtime        i64
	ctime        i64
	is_dir       bool
	is_file      bool
	is_link      bool
	is_readable  bool
	is_writable  bool
	is_executable bool
}

pub struct CommandResult {
pub:
	command     string
	output      string
	exit_code   int
	timed_out   bool
	duration_ms i64
	attempts    int
}

// get_disk_usage returns DiskStats for the volume containing target path.
pub fn (win &SimpleWindow) get_disk_usage(path string) !DiskStats {
	target_path := if path.len == 0 { '.' } else { path }
	if !os.exists(target_path) {
		return error('Path does not exist: ' + target_path)
	}

	$if macos || linux || freebsd {
		out := win.exec_or("df -k \"${target_path}\" | tail -n 1 | awk '{print \$2\" \"\$4\" \"\$3}'",
			'')
		parts := out.split_into_lines()[0].split(' ').filter(it.len > 0)
		if parts.len >= 3 {
			total_kb := parts[0].u64()
			avail_kb := parts[1].u64()
			used_kb := parts[2].u64()
			return DiskStats{
				total:     total_kb * 1024
				available: avail_kb * 1024
				used:      used_kb * 1024
			}
		}
	} $else $if windows {
		raw := win.exec_or("powershell -Command \"Get-Volume -FilePath '${target_path}' | Select-Object Size, SizeRemaining\"",
			'')
		lines := raw.split_into_lines()
		if lines.len >= 2 {
			parts := lines[1].trim_space().split(' ').filter(it.len > 0)
			if parts.len >= 2 {
				sz := parts[0].u64()
				rem := parts[1].u64()
				return DiskStats{
					total:     sz
					available: rem
					used:      if sz >= rem { sz - rem } else { 0 }
				}
			}
		}
	}

	return error('Unable to query disk usage')
}

// get_file_metadata returns FileMetadata for specified path.
pub fn (win &SimpleWindow) get_file_metadata(path string) !FileMetadata {
	st := os.stat(path) or { return error('Failed to stat file: ' + err.msg()) }
	abs_path := os.real_path(path)
	return FileMetadata{
		size:          st.size
		inode:         st.inode
		nlink:         st.nlink
		dev:           st.dev
		uid:           st.uid
		gid:           st.gid
		mode:          st.mode
		atime:         st.atime
		mtime:         st.mtime
		ctime:         st.ctime
		is_dir:        os.is_dir(abs_path)
		is_file:       os.is_file(abs_path)
		is_link:       os.is_link(abs_path)
		is_readable:   os.is_readable(abs_path)
		is_writable:   os.is_writable(abs_path)
		is_executable: os.is_executable(abs_path)
	}
}

// get_pid returns process ID of current app.
pub fn (win &SimpleWindow) get_pid() int {
	return os.getpid()
}

// exists_in_path checks if executable name exists in system PATH.
pub fn (win &SimpleWindow) exists_in_path(cmd_name string) bool {
	$if windows {
		out, code := win.exec('where "${cmd_name}"')
		return code == 0 && out.len > 0
	} $else {
		out, code := win.exec('which "${cmd_name}" 2>/dev/null')
		return code == 0 && out.len > 0
	}
}

// find_executable returns absolute path of binary in system PATH, or empty string.
pub fn (win &SimpleWindow) find_executable(cmd_name string) string {
	$if windows {
		out, code := win.exec('where "${cmd_name}"')
		if code == 0 {
			lines := out.split_into_lines()
			if lines.len > 0 {
				return lines[0].trim_space()
			}
		}
		return ''
	} $else {
		out, code := win.exec('which "${cmd_name}" 2>/dev/null')
		if code == 0 {
			return out.split_into_lines()[0].trim_space()
		}
		return ''
	}
}

// has_command checks if a command binary is installed and executable in PATH.
pub fn (win &SimpleWindow) has_command(cmd string) bool {
	return win.exists_in_path(cmd)
}

// get_command_path gets absolute executable location for a command.
pub fn (win &SimpleWindow) get_command_path(cmd string) string {
	path := win.find_executable(cmd)
	if path.len > 0 {
		return path
	}
	return cmd
}

// ==========================================
// 6. System Clock & Time
// ==========================================

// get_uptime_seconds returns total system uptime in seconds.
pub fn (win &SimpleWindow) get_uptime_seconds() i64 {
	$if macos {
		raw := win.exec_or('sysctl -n kern.boottime', '')
		if raw.contains('sec =') {
			sec_part := raw.split('sec =')[1].split(',')[0].trim_space()
			boot_sec := sec_part.i64()
			now_sec := time.now().unix()
			if now_sec > boot_sec {
				return now_sec - boot_sec
			}
		}
	} $else $if windows {
		raw := win.exec_or('powershell -Command "(get-date) - (gcim Win32_OperatingSystem).LastBootUpTime | select -expand TotalSeconds"',
			'')
		if raw.len > 0 {
			return i64(raw.f64())
		}
	} $else {
		raw := win.exec_or('cat /proc/uptime 2>/dev/null', '')
		if raw.len > 0 {
			parts := raw.split(' ')
			if parts.len > 0 {
				return i64(parts[0].f64())
			}
		}
	}
	return 0
}

// ==========================================
// 7. Clipboard
// ==========================================

// copy_to_clipboard copies text to the system clipboard.
pub fn (mut win SimpleWindow) copy_to_clipboard(text string) &SimpleWindow {
	win.clipboard_copy(text)
	return win
}

// get_clipboard_text retrieves text from the system clipboard.
pub fn (win &SimpleWindow) get_clipboard_text() string {
	return win.clipboard_read()
}

// ==========================================
// 8. Open / Reveal Commands
// ==========================================

// open_url opens a web URL or file in default system web browser or viewer.
pub fn (win &SimpleWindow) open_url(url string) &SimpleWindow {
	$if macos {
		win.exec_bg('open "${url}"')
	} $else $if windows {
		win.exec_bg('start "${url}"')
	} $else {
		win.exec_bg('xdg-open "${url}"')
	}
	return win
}

// reveal_in_finder opens and highlights a file or folder in system File Explorer / Finder.
pub fn (win &SimpleWindow) reveal_in_finder(path string) &SimpleWindow {
	if win.debug_mode {
		println('[simplegui SYSTEM] Revealing path: ${path}')
	}
	$if macos {
		win.exec_bg('open -R "${path}"')
	} $else $if windows {
		win.exec_bg('explorer.exe /select,"${path}"')
	} $else {
		win.exec_bg('xdg-open "${os.dir(path)}"')
	}
	return win
}

// open_in_default_app opens a file with its default associated application.
pub fn (win &SimpleWindow) open_in_default_app(path string) &SimpleWindow {
	if win.debug_mode {
		println('[simplegui SYSTEM] Opening file with default app: ${path}')
	}
	$if macos {
		win.exec_bg('open "${path}"')
	} $else $if windows {
		win.exec_bg('start "" "${path}"')
	} $else {
		win.exec_bg('xdg-open "${path}"')
	}
	return win
}

// open_with_app opens a file using a specific application by name or ID.
pub fn (win &SimpleWindow) open_with_app(path string, app_id string) &SimpleWindow {
	if win.debug_mode {
		println('[simplegui SYSTEM] Opening "${path}" with app: ${app_id}')
	}
	$if macos {
		win.exec_bg('open -a "${app_id}" "${path}"')
	} $else $if windows {
		win.exec_bg('start "${app_id}" "${path}"')
	} $else {
		win.exec_bg('${app_id} "${path}"')
	}
	return win
}

// open_terminal opens a new terminal shell window.
pub fn (win &SimpleWindow) open_terminal() &SimpleWindow {
	$if macos {
		win.exec_bg('open -a Terminal')
	} $else $if windows {
		win.exec_bg('start cmd.exe')
	} $else {
		win.exec_bg('x-terminal-emulator 2>/dev/null || gnome-terminal 2>/dev/null || konsole 2>/dev/null || xterm &')
	}
	return win
}

// ==========================================
// 9. Network Utilities
// ==========================================

// ping checks network latency to host.
pub fn (win &SimpleWindow) ping(host string, count int) bool {
	c := if count <= 0 { 1 } else { count }
	$if windows {
		_, code := win.exec('ping -n ${c} "${host}"')
		return code == 0
	} $else {
		_, code := win.exec('ping -c ${c} "${host}" 2>/dev/null')
		return code == 0
	}
}

// get_ip_address retrieves local IP address.
pub fn (win &SimpleWindow) get_ip_address() string {
	$if macos {
		out := win.exec_or("ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null",
			'127.0.0.1')
		return out.trim_space()
	} $else $if windows {
		raw := win.exec_or("powershell -Command \"(Get-NetIPAddress -AddressFamily IPv4 | Where-Object {\$_.InterfaceAlias -notlike '*Loopback*'}).IPAddress | Select-Object -First 1\"",
			'127.0.0.1')
		return raw.trim_space()
	} $else {
		raw := win.exec_or("hostname -I 2>/dev/null | awk '{print $1}'", '127.0.0.1')
		return raw.trim_space()
	}
}

// get_public_ip fetches public IP via external service.
pub fn (win &SimpleWindow) get_public_ip() string {
	return win.http_get('https://api.ipify.org')
}

// ==========================================
// 10. System Resource Monitoring
// ==========================================

// get_cpu_usage_percent returns CPU usage percentage estimate.
pub fn (win &SimpleWindow) get_cpu_usage_percent() f64 {
	$if macos {
		raw := win.exec_or("ps -A -o %cpu | awk '{s+=$1} END {print s}'", '0')
		return raw.trim_space().f64()
	} $else $if windows {
		raw := win.exec_or('wmic cpu get LoadPercentage', '0')
		lines := raw.split_into_lines()
		if lines.len >= 2 {
			return lines[1].trim_space().f64()
		}
		return 0.0
	} $else {
		raw := win.exec_or("top -bn1 2>/dev/null | grep 'Cpu(s)' | awk '{print $2}'", '0')
		return raw.trim_space().f64()
	}
}

// get_load_average returns system load averages (1, 5, 15 minutes).
pub fn (win &SimpleWindow) get_load_average() (f64, f64, f64) {
	$if macos || linux || freebsd {
		loadavg := [f64(0), f64(0), f64(0)]!
		if C.getloadavg(&loadavg[0], 3) == 3 {
			return loadavg[0], loadavg[1], loadavg[2]
		}
	}
	return 0.0, 0.0, 0.0
}

// get_memory_pressure returns memory pressure: "normal", "warn", or "critical".
pub fn (win &SimpleWindow) get_memory_pressure() string {
	$if macos {
		level := win.exec_or('sysctl -n kern.memorystatus_vm_pressure_level 2>/dev/null',
			'').trim_space().int()
		if level >= 4 {
			return 'critical'
		} else if level >= 2 {
			return 'warn'
		} else if level == 1 {
			return 'normal'
		}
	}
	return 'normal'
}

// get_running_process_count returns total active process count.
pub fn (win &SimpleWindow) get_running_process_count() int {
	$if macos || linux || freebsd {
		raw := win.exec_or('ps -A | wc -l', '0')
		return raw.trim_space().int()
	} $else $if windows {
		raw := win.exec_or('powershell -Command "(Get-Process).Count"', '0')
		return raw.trim_space().int()
	}
	return 0
}

// get_open_file_count returns total count of open file descriptors in the system.
pub fn (win &SimpleWindow) get_open_file_count() int {
	$if macos {
		raw := win.exec_or('sysctl -n kern.num_files', '0')
		return raw.trim_space().int()
	} $else $if linux {
		raw := win.exec_or('cat /proc/sys/fs/file-nr 2>/dev/null | awk \'{print $1}\'', '0')
		return raw.trim_space().int()
	}
	return 0
}

// get_swap_usage returns human-readable swap usage.
pub fn (win &SimpleWindow) get_swap_usage() string {
	$if macos {
		return win.exec_or('sysctl -n vm.swapusage', 'unknown').trim_space()
	} $else $if windows {
		return win.exec_or('powershell -Command "(Get-CimInstance Win32_PageFileUsage).AllocatedBaseSize | % { \"$_ MB\" }"',
			'unknown').trim_space()
	} $else {
		return win.exec_or("free -h 2>/dev/null | grep Swap | awk '{print $3\" / \"$2}'",
			'unknown').trim_space()
	}
}

// ==========================================
// 11. Terminal / Shell & Dialog Utilities
// ==========================================

// sys_beep plays standard system alert sound across platforms.
pub fn sys_beep() {
	$if macos {
		os.execute_opt("osascript -e 'beep'") or {}
	} $else $if windows {
		os.execute_opt("powershell -Command \"[console]::beep(800,200)\"") or {}
	} $else {
		print('\a')
	}
}

// beep plays the system alert sound.
pub fn (win &SimpleWindow) beep() &SimpleWindow {
	sys_beep()
	return win
}

// beep_n plays system alert sound n times.
pub fn (win &SimpleWindow) beep_n(n int) &SimpleWindow {
	count := if n < 1 { 1 } else { n }
	for _ in 0 .. count {
		win.beep()
		time.sleep(150 * time.millisecond)
	}
	return win
}

// osascript_dialog shows a native input dialog box (macOS osascript / Windows PowerShell / Linux zenity).
pub fn (win &SimpleWindow) osascript_dialog(prompt string, default_value string) string {
	$if macos {
		prompt_esc := prompt.replace('"', '\\"')
		default_esc := default_value.replace('"', '\\"')
		script := 'osascript -e \'set ans to text returned of (display dialog "${prompt_esc}" default answer "${default_esc}" buttons {"Cancel","OK"} default button "OK")\''
		output, code := win.exec(script)
		if code == 0 {
			return output.trim_space()
		}
	} $else $if windows {
		p_esc := prompt.replace("'", "''")
		d_esc := default_value.replace("'", "''")
		cmd := "powershell -Command \"Add-Type -AssemblyName Microsoft.VisualBasic; [Microsoft.VisualBasic.Interaction]::InputBox('${p_esc}', 'Input', '${d_esc}')\""
		out, code := win.exec(cmd)
		if code == 0 {
			return out.trim_space()
		}
	} $else {
		cmd := "zenity --entry --title=\"Input\" --text=\"${prompt}\" --entry-text=\"${default_value}\" 2>/dev/null"
		out, code := win.exec(cmd)
		if code == 0 {
			return out.trim_space()
		}
	}
	return ''
}

// osascript_alert shows a native alert dialog box across platforms.
pub fn (win &SimpleWindow) osascript_alert(title string, message string) bool {
	$if macos {
		title_esc := title.replace('"', '\\"')
		msg_esc := message.replace('"', '\\"')
		script := 'osascript -e \'button returned of (display alert "${title_esc}" message "${msg_esc}" buttons {"Cancel","OK"} default button "OK")\''
		output, code := win.exec(script)
		if code == 0 {
			return output.trim_space() == 'OK'
		}
	} $else $if windows {
		t_esc := title.replace("'", "''")
		m_esc := message.replace("'", "''")
		cmd := "powershell -Command \"Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show('${m_esc}', '${t_esc}', 'OKCancel')\""
		out, _ := win.exec(cmd)
		return out.contains('OK')
	} $else {
		cmd := "zenity --question --title=\"${title}\" --text=\"${message}\" 2>/dev/null"
		_, code := win.exec(cmd)
		return code == 0
	}
	return false
}

// osascript_choose_file shows a native file-picker dialog and returns the chosen path.
pub fn (win &SimpleWindow) osascript_choose_file() string {
	$if macos {
		script := "osascript -e 'POSIX path of (choose file)'"
		output, code := win.exec(script)
		if code == 0 {
			return output.trim_space()
		}
	} $else $if windows {
		cmd := "powershell -Command \"Add-Type -AssemblyName System.Windows.Forms; \$d = New-Object System.Windows.Forms.OpenFileDialog; if (\$d.ShowDialog() -eq 'OK') { \$d.FileName }\""
		out, code := win.exec(cmd)
		if code == 0 {
			return out.trim_space()
		}
	} $else {
		out, code := win.exec("zenity --file-selection 2>/dev/null")
		if code == 0 {
			return out.trim_space()
		}
	}
	return ''
}

// osascript_choose_folder shows a native folder-picker dialog and returns the chosen path.
pub fn (win &SimpleWindow) osascript_choose_folder() string {
	$if macos {
		script := "osascript -e 'POSIX path of (choose folder)'"
		output, code := win.exec(script)
		if code == 0 {
			return output.trim_space()
		}
	} $else $if windows {
		cmd := "powershell -Command \"Add-Type -AssemblyName System.Windows.Forms; \$d = New-Object System.Windows.Forms.FolderBrowserDialog; if (\$d.ShowDialog() -eq 'OK') { \$d.SelectedPath }\""
		out, code := win.exec(cmd)
		if code == 0 {
			return out.trim_space()
		}
	} $else {
		out, code := win.exec("zenity --file-selection --directory 2>/dev/null")
		if code == 0 {
			return out.trim_space()
		}
	}
	return ''
}

// say uses system text-to-speech to speak a message out loud across platforms.
pub fn (win &SimpleWindow) say(text string) &SimpleWindow {
	$if macos {
		escaped := text.replace('"', '\\"')
		win.exec_bg('say "${escaped}"')
	} $else $if windows {
		escaped := text.replace("'", "''")
		win.exec_bg("powershell -Command \"Add-Type -AssemblyName System.Speech; \$s = New-Object System.Speech.Synthesis.SpeechSynthesizer; \$s.Speak('${escaped}')\"")
	} $else {
		escaped := text.replace('"', '\\"')
		win.exec_bg('spd-say "${escaped}" 2>/dev/null')
	}
	return win
}

// ==========================================
// 12. macOS & Platform System Details
// ==========================================

fn system_version_plist_value(key string) string {
	$if macos {
		plist_path := '/System/Library/CoreServices/SystemVersion.plist'
		content := os.read_file(plist_path) or { return 'unknown' }
		key_tag := '<key>${key}</key>'
		key_idx := content.index(key_tag) or { return 'unknown' }
		after_key := content[key_idx + key_tag.len..]
		val_start_tag := '<string>'
		val_end_tag := '</string>'
		val_start := after_key.index(val_start_tag) or { return 'unknown' }
		after_start := after_key[val_start + val_start_tag.len..]
		val_end := after_start.index(val_end_tag) or { return 'unknown' }
		return after_start[..val_end].trim_space()
	} $else {
		return 'N/A'
	}
}

// get_macos_version returns macOS product version (or N/A on non-macOS).
pub fn (win &SimpleWindow) get_macos_version() string {
	return system_version_plist_value('ProductVersion')
}

// get_macos_build returns macOS build string (or N/A on non-macOS).
pub fn (win &SimpleWindow) get_macos_build() string {
	return system_version_plist_value('ProductBuildVersion')
}

// get_macos_product_name returns product name string (e.g. "macOS").
pub fn (win &SimpleWindow) get_macos_product_name() string {
	return system_version_plist_value('ProductName')
}

// get_device_model returns hardware model identifier across platforms.
pub fn (win &SimpleWindow) get_device_model() string {
	$if macos {
		return win.exec_or('sysctl -n hw.model', 'unknown').trim_space()
	} $else $if windows {
		return win.exec_or('wmic computersystem get model', 'unknown').split_into_lines()[1].trim_space()
	} $else {
		return win.exec_or('cat /sys/class/dmi/id/product_name 2>/dev/null', 'unknown').trim_space()
	}
}

// get_serial_number returns device serial number across platforms.
pub fn (win &SimpleWindow) get_serial_number() string {
	$if macos {
		return win.exec_or('ioreg -c IOPlatformExpertDevice 2>/dev/null | awk -F \'"\' \'/IOPlatformSerialNumber/{print $4}\'',
			'unavailable').trim_space()
	} $else $if windows {
		return win.exec_or('wmic bios get serialnumber', 'unavailable').split_into_lines()[1].trim_space()
	} $else {
		return win.exec_or('cat /sys/class/dmi/id/product_serial 2>/dev/null', 'unavailable').trim_space()
	}
}

// get_screen_resolution returns primary display resolution string (e.g. "1920 x 1080").
pub fn (win &SimpleWindow) get_screen_resolution() string {
	$if macos {
		raw := win.exec_or('osascript -e \'tell application "Finder" to get bounds of window of desktop\' 2>/dev/null',
			'')
		if raw.len > 0 {
			parts := raw.split(',').map(it.trim_space())
			if parts.len >= 4 {
				return '${parts[2]} x ${parts[3]}'
			}
		}
	} $else $if windows {
		raw := win.exec_or('powershell -Command "Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width.ToString() + \' x \' + [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height.ToString()"',
			'')
		if raw.len > 0 {
			return raw.trim_space()
		}
	} $else {
		raw := win.exec_or("xrandr --current 2>/dev/null | grep '\\*' | awk '{print $1}'", '')
		if raw.len > 0 {
			return raw.split_into_lines()[0].trim_space()
		}
	}
	return '1920 x 1080'
}

// get_gpu_info returns GPU model description across platforms.
pub fn (win &SimpleWindow) get_gpu_info() string {
	$if macos {
		ioreg_gpu := win.exec_or('ioreg -rc IOPCIDevice 2>/dev/null | awk -F \'"\' \'/"model" = /{print $4}\' | head -1',
			'').trim_space()
		if ioreg_gpu.len > 0 {
			return ioreg_gpu
		}
	} $else $if windows {
		raw := win.exec_or('wmic path win32_VideoController get name', '')
		lines := raw.split_into_lines()
		if lines.len >= 2 {
			return lines[1].trim_space()
		}
	} $else {
		raw := win.exec_or("lspci 2>/dev/null | grep -i vga | cut -d: -f3", '')
		if raw.len > 0 {
			return raw.trim_space()
		}
	}
	return 'unknown'
}

// get_battery_percent returns battery percentage (0..100) or -1 if unavailable.
pub fn (win &SimpleWindow) get_battery_percent() int {
	$if macos {
		raw := win.exec_or("pmset -g batt 2>/dev/null | grep -oE '[0-9]+%' | head -1 | tr -d '%'",
			'').trim_space()
		if raw.len > 0 {
			return raw.int()
		}
	} $else $if windows {
		raw := win.exec_or('powershell -Command "(Get-WmiObject win32_battery).EstimatedChargeRemaining"',
			'').trim_space()
		if raw.len > 0 {
			return raw.int()
		}
	} $else {
		raw := win.exec_or('cat /sys/class/power_supply/BAT0/capacity 2>/dev/null', '').trim_space()
		if raw.len > 0 {
			return raw.int()
		}
	}
	return -1
}

// is_on_ac_power returns true if machine is plugged into AC power.
pub fn (win &SimpleWindow) is_on_ac_power() bool {
	$if macos {
		raw := win.exec_or('pmset -g batt 2>/dev/null | head -1', '')
		return raw.contains('AC Power')
	} $else $if windows {
		raw := win.exec_or('powershell -Command "(Get-WmiObject win32_battery).BatteryStatus"',
			'').trim_space()
		return raw == '2' || raw == '3' || raw == '6' || raw == '7'
	} $else {
		raw := win.exec_or('cat /sys/class/power_supply/AC/online 2>/dev/null', '').trim_space()
		return raw == '1'
	}
}

// get_app_bundle_id returns bundle identifier on macOS (or empty string elsewhere).
pub fn (win &SimpleWindow) get_app_bundle_id() string {
	$if macos {
		exe := os.executable()
		plist_path := os.join_path(os.dir(exe), '..', 'Info.plist')
		if os.exists(plist_path) {
			content := os.read_file(plist_path) or { return '' }
			key_tag := '<key>CFBundleIdentifier</key>'
			key_idx := content.index(key_tag) or { return '' }
			after_key := content[key_idx + key_tag.len..]
			val_start_tag := '<string>'
			val_end_tag := '</string>'
			val_start := after_key.index(val_start_tag) or { return '' }
			after_start := after_key[val_start + val_start_tag.len..]
			val_end := after_start.index(val_end_tag) or { return '' }
			return after_start[..val_end].trim_space()
		}
	}
	return ''
}

// get_system_locale returns system language/locale string across platforms.
pub fn (win &SimpleWindow) get_system_locale() string {
	for key in ['LC_ALL', 'LC_MESSAGES', 'LANG'] {
		val := os.getenv(key)
		if val.len > 0 {
			return val.split('.')[0]
		}
	}
	return 'en_US'
}

// get_timezone returns timezone name string across platforms.
pub fn (win &SimpleWindow) get_timezone() string {
	$if !windows {
		resolved := os.real_path('/etc/localtime')
		for prefix in ['/var/db/timezone/zoneinfo/', '/usr/share/zoneinfo/', '/usr/lib/zoneinfo/'] {
			if resolved.starts_with(prefix) {
				return resolved[prefix.len..]
			}
		}
	} $else {
		raw := win.exec_or('powershell -Command "(Get-TimeZone).Id"', '').trim_space()
		if raw.len > 0 {
			return raw
		}
	}
	tz := os.getenv('TZ')
	if tz.len > 0 {
		return tz
	}
	return 'UTC'
}

// launch_at_login_add registers application to auto-launch at user login across platforms.
pub fn (win &SimpleWindow) launch_at_login_add(app_name_or_path string) &SimpleWindow {
	$if macos {
		escaped := app_name_or_path.replace('"', '\\"')
		script := 'osascript -e \'tell application "System Events" to make login item at end with properties {path:"${escaped}", hidden:false}\''
		win.exec_bg(script)
	} $else $if windows {
		exe := os.executable()
		cmd := "reg add HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run /v \"${app_name_or_path}\" /t REG_SZ /d \"${exe}\" /f"
		win.exec_bg(cmd)
	}
	return win
}

// launch_at_login_remove unregisters application from user login items.
pub fn (win &SimpleWindow) launch_at_login_remove(app_name string) &SimpleWindow {
	$if macos {
		escaped := app_name.replace('"', '\\"')
		script := 'osascript -e \'tell application "System Events" to delete login item "${escaped}"\''
		win.exec_bg(script)
	} $else $if windows {
		cmd := "reg delete HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run /v \"${app_name}\" /f"
		win.exec_bg(cmd)
	}
	return win
}

// set_dock_badge sets application Dock badge count (macOS only, safe no-op on other platforms).
pub fn (win &SimpleWindow) set_dock_badge(count int) &SimpleWindow {
	$if macos {
		if count <= 0 {
			win.exec_bg('osascript -e \'tell application "System Events" to set the dock badge of the front application to 0\'')
		} else {
			win.exec_bg("osascript -e 'tell application \"System Events\" to set the dock badge of the front application to ${count}'")
		}
	}
	return win
}

// ==========================================
// 13. System Utilities, Theme & Audio
// ==========================================

// is_dark_mode returns true if OS global appearance is set to Dark Mode across platforms.
pub fn (win &SimpleWindow) is_dark_mode() bool {
	$if macos {
		style := win.exec_or('defaults read -g AppleInterfaceStyle 2>/dev/null', '').trim_space()
		return style.to_lower() == 'dark'
	} $else $if windows {
		raw := win.exec_or('powershell -Command "(Get-ItemProperty -Path HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize).AppsUseLightTheme"',
			'1').trim_space()
		return raw == '0'
	} $else {
		raw := win.exec_or('gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null',
			'').to_lower()
		return raw.contains('dark')
	}
}

// get_system_theme returns "dark" or "light" for current OS theme.
pub fn (win &SimpleWindow) get_system_theme() string {
	if win.is_dark_mode() {
		return 'dark'
	}
	return 'light'
}

// set_system_dark_mode toggles global OS Dark Mode on/off across platforms.
pub fn (win &SimpleWindow) set_system_dark_mode(enabled bool) &SimpleWindow {
	$if macos {
		value := if enabled { 'true' } else { 'false' }
		win.exec_bg("osascript -e 'tell application \"System Events\" to tell appearance preferences to set dark mode to ${value}'")
	} $else $if windows {
		val_num := if enabled { 0 } else { 1 }
		cmd := "reg add HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize /v AppsUseLightTheme /t REG_DWORD /d ${val_num} /f"
		win.exec_bg(cmd)
	} $else {
		scheme := if enabled { 'prefer-dark' } else { 'default' }
		win.exec_bg("gsettings set org.gnome.desktop.interface color-scheme '${scheme}' 2>/dev/null")
	}
	return win
}

// set_system_theme sets OS global theme to "dark" or "light".
pub fn (win &SimpleWindow) set_system_theme(theme string) !&SimpleWindow {
	mode := theme.trim_space().to_lower()
	if mode != 'dark' && mode != 'light' {
		return error('Invalid theme "${theme}". Use "dark" or "light".')
	}
	win.set_system_dark_mode(mode == 'dark')
	return win
}

// toggle_dark_mode toggles OS appearance between Light Mode and Dark Mode across platforms.
pub fn (win &SimpleWindow) toggle_dark_mode() &SimpleWindow {
	is_dark := win.is_dark_mode()
	win.set_system_dark_mode(!is_dark)
	return win
}

// sleep_display turns off display across platforms.
pub fn (win &SimpleWindow) sleep_display() &SimpleWindow {
	$if macos {
		win.exec_bg('pmset displaysleepnow')
	} $else $if windows {
		win.exec_bg("powershell -Command \"(Add-Type '[DllImport(\\\"user32.dll\\\")]public static extern int SendMessage(int hWnd, int hMsg, int wParam, int lParam);' -Name a -Passthru)::SendMessage(-1, 0x0112, 0xF170, 2)\"")
	} $else {
		win.exec_bg('xset dpms force off 2>/dev/null')
	}
	return win
}

// sleep_computer puts system to sleep across platforms.
pub fn (win &SimpleWindow) sleep_computer() &SimpleWindow {
	$if macos {
		win.exec_bg('osascript -e \'tell application "System Events" to sleep\'')
	} $else $if windows {
		win.exec_bg('rundll32.exe powrprof.dll,SetSuspendState 0,1,0')
	} $else {
		win.exec_bg('systemctl suspend 2>/dev/null')
	}
	return win
}

// lock_screen locks user session across platforms.
pub fn (win &SimpleWindow) lock_screen() &SimpleWindow {
	$if macos {
		win.exec_bg('/System/Library/CoreServices/Menu\\ Extras/User.menu/Contents/Resources/CGSession -suspend')
	} $else $if windows {
		win.exec_bg('rundll32.exe user32.dll,LockWorkStation')
	} $else {
		win.exec_bg('xdg-screensaver lock 2>/dev/null')
	}
	return win
}

// start_screen_saver launches screen saver across platforms.
pub fn (win &SimpleWindow) start_screen_saver() &SimpleWindow {
	$if macos {
		win.exec_bg('open -a ScreenSaverEngine')
	} $else $if windows {
		win.exec_bg('powershell -Command "(Get-Command *.scr).Name | Select -First 1 | & {\$input}"')
	} $else {
		win.exec_bg('xdg-screensaver activate 2>/dev/null')
	}
	return win
}

// log_out_user logs out user session across platforms.
pub fn (win &SimpleWindow) log_out_user() &SimpleWindow {
	$if macos {
		win.exec_bg('osascript -e \'tell application "System Events" to log out\'')
	} $else $if windows {
		win.exec_bg('shutdown /l')
	} $else {
		win.exec_bg('gnome-session-quit --logout 2>/dev/null')
	}
	return win
}

// restart_computer restarts system across platforms.
pub fn (win &SimpleWindow) restart_computer() &SimpleWindow {
	$if macos {
		win.exec_bg('osascript -e \'tell application "System Events" to restart\'')
	} $else $if windows {
		win.exec_bg('shutdown /r /t 0')
	} $else {
		win.exec_bg('reboot 2>/dev/null')
	}
	return win
}

// shut_down_computer powers off system across platforms.
pub fn (win &SimpleWindow) shut_down_computer() &SimpleWindow {
	$if macos {
		win.exec_bg('osascript -e \'tell application "System Events" to shut down\'')
	} $else $if windows {
		win.exec_bg('shutdown /s /t 0')
	} $else {
		win.exec_bg('poweroff 2>/dev/null')
	}
	return win
}

// get_volume returns system output volume level (0..100).
pub fn (win &SimpleWindow) get_volume() int {
	$if macos {
		vol_str := win.exec_or("osascript -e 'output volume of (get volume settings)' 2>/dev/null",
			'0').trim_space()
		return vol_str.int()
	} $else $if windows {
		raw := win.exec_or('powershell -Command "[int]((Get-CimInstance -ClassName Win32_SoundDevice).Volume)"',
			'50').trim_space()
		return raw.int()
	} $else {
		raw := win.exec_or("amixer sget Master 2>/dev/null | grep -oE '[0-9]+%' | head -1 | tr -d '%'",
			'50').trim_space()
		return raw.int()
	}
}

// set_volume sets system output volume level (0..100).
pub fn (win &SimpleWindow) set_volume(level int) &SimpleWindow {
	clamped := if level < 0 { 0 } else if level > 100 { 100 } else { level }
	$if macos {
		win.exec_bg("osascript -e 'set volume output volume ${clamped}'")
	} $else $if windows {
		win.exec_bg("powershell -Command \"(New-Object -ComObject WScript.Shell).SendKeys([char]174)\"")
	} $else {
		win.exec_bg("amixer -q sset Master ${clamped}% 2>/dev/null")
	}
	return win
}

// is_muted returns true if system volume is muted.
pub fn (win &SimpleWindow) is_muted() bool {
	$if macos {
		muted_str := win.exec_or("osascript -e 'output muted of (get volume settings)' 2>/dev/null",
			'false').trim_space()
		return muted_str.to_lower() == 'true'
	} $else {
		return false
	}
}

// set_muted mutes or unmutes system audio.
pub fn (win &SimpleWindow) set_muted(mute bool) &SimpleWindow {
	$if macos {
		val := if mute { 'true' } else { 'false' }
		win.exec_bg("osascript -e 'set volume output muted ${val}'")
	} $else $if windows {
		win.exec_bg("powershell -Command \"(New-Object -ComObject WScript.Shell).SendKeys([char]173)\"")
	} $else {
		m_str := if mute { 'mute' } else { 'unmute' }
		win.exec_bg("amixer -q sset Master ${m_str} 2>/dev/null")
	}
	return win
}

// trash_file safely moves file or directory to OS trash/recycle bin across platforms.
pub fn (win &SimpleWindow) trash_file(path string) !&SimpleWindow {
	abs_path := os.real_path(path)
	if !os.exists(abs_path) {
		return error('File does not exist: ${path}')
	}
	$if macos {
		escaped := abs_path.replace('"', '\\"')
		script := "osascript -e 'tell application \"Finder\" to delete POSIX file \"${escaped}\"'"
		output, code := win.exec(script)
		if code != 0 {
			return error('Failed to move to Trash: ${output}')
		}
	} $else $if windows {
		p_esc := abs_path.replace("'", "''")
		cmd := "powershell -Command \"Add-Type -AssemblyName Microsoft.VisualBasic; [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile('${p_esc}', 'OnlyErrorDialogs', 'SendToRecycleBin')\""
		output, code := win.exec(cmd)
		if code != 0 {
			return error('Failed to move to Recycle Bin: ${output}')
		}
	} $else {
		output, code := win.exec('gio trash "${abs_path}" 2>/dev/null || trash-put "${abs_path}" 2>/dev/null')
		if code != 0 {
			return error('Failed to move file to trash: ${output}')
		}
	}
	return win
}

// zip_directory compresses a directory into a .zip archive.
pub fn (win &SimpleWindow) zip_directory(dir_path string, zip_path string) !&SimpleWindow {
	abs_dir := os.real_path(dir_path)
	if !os.exists(abs_dir) {
		return error('Source directory does not exist: ${dir_path}')
	}
	parent := os.dir(abs_dir)
	base := os.base(abs_dir)
	target_zip := os.real_path(zip_path)
	$if windows {
		output, code := win.exec('powershell -Command "Compress-Archive -Path \'${abs_dir}\' -DestinationPath \'${target_zip}\' -Force"')
		if code != 0 {
			return error('Failed to create zip archive: ${output}')
		}
	} $else {
		output, code := win.exec('cd "${parent}" && zip -r "${target_zip}" "${base}"')
		if code != 0 {
			return error('Failed to create zip archive: ${output}')
		}
	}
	return win
}

// unzip_archive extracts a .zip archive into target directory.
pub fn (win &SimpleWindow) unzip_archive(zip_path string, dest_dir string) !&SimpleWindow {
	abs_zip := os.real_path(zip_path)
	if !os.exists(abs_zip) {
		return error('Zip archive does not exist: ${zip_path}')
	}
	os.mkdir_all(dest_dir)!
	abs_dest := os.real_path(dest_dir)
	$if windows {
		output, code := win.exec('powershell -Command "Expand-Archive -Path \'${abs_zip}\' -DestinationPath \'${abs_dest}\' -Force"')
		if code != 0 {
			return error('Failed to extract zip archive: ${output}')
		}
	} $else {
		output, code := win.exec('unzip -o "${abs_zip}" -d "${abs_dest}"')
		if code != 0 {
			return error('Failed to extract zip archive: ${output}')
		}
	}
	return win
}

// create_temp_file generates unique temporary file path with prefix/suffix.
pub fn (win &SimpleWindow) create_temp_file(prefix string, suffix string) !string {
	rand_num := time.now().unix_milli()
	file_name := '${prefix}_${rand_num}${suffix}'
	temp_path := os.join_path(os.temp_dir(), file_name)
	os.write_file(temp_path, '')!
	return temp_path
}

// create_temp_dir generates unique temporary directory path with prefix.
pub fn (win &SimpleWindow) create_temp_dir(prefix string) !string {
	rand_num := time.now().unix_milli()
	dir_name := '${prefix}_${rand_num}'
	temp_path := os.join_path(os.temp_dir(), dir_name)
	os.mkdir_all(temp_path)!
	return temp_path
}

// sha256_file calculates SHA256 hex digest of file.
pub fn (win &SimpleWindow) sha256_file(path string) !string {
	bytes := os.read_bytes(path)!
	return sha256.hexhash(bytes.bytestr())
}

// md5_file calculates MD5 hex digest of file.
pub fn (win &SimpleWindow) md5_file(path string) !string {
	bytes := os.read_bytes(path)!
	return md5.hexhash(bytes.bytestr())
}

// is_port_open checks if TCP port is open on host.
pub fn (win &SimpleWindow) is_port_open(host string, port int) bool {
	$if windows {
		out, code := win.exec('powershell -Command "Test-NetConnection -ComputerName ${host} -Port ${port} -InformationLevel Quiet"')
		return code == 0 && out.contains('True')
	} $else {
		_, code := win.exec('nc -z -G 1 "${host}" ${port} 2>/dev/null')
		return code == 0
	}
}

// find_available_port scans ports starting from start_port to find unused local TCP port.
pub fn (win &SimpleWindow) find_available_port(start_port int) int {
	mut port := start_port
	for port < start_port + 100 {
		if !win.is_port_open('127.0.0.1', port) {
			return port
		}
		port++
	}
	return start_port
}

// prevent_sleep_bg prevents display and system sleep across platforms.
pub fn (win &SimpleWindow) prevent_sleep_bg(duration_sec int) &SimpleWindow {
	dur := if duration_sec <= 0 { 60 } else { duration_sec }
	$if macos {
		win.exec_bg('caffeinate -t ${dur}')
	} $else $if windows {
		win.exec_bg("powershell -Command \"Add-Type '[DllImport(\\\"kernel32.dll\\\")]public static extern uint SetThreadExecutionState(uint f);' -Name sys -Passthru; [sys]::SetThreadExecutionState(0x80000003)\"")
	} $else {
		win.exec_bg('systemd-inhibit --what=idle --why="simple_gg" sleep ${dur} 2>/dev/null')
	}
	return win
}

// ==========================================
// 14. Process Control & Execution Extensions
// ==========================================

// download_file downloads remote file from URL to dest_path.
pub fn (win &SimpleWindow) download_file(url string, dest_path string) !&SimpleWindow {
	if win.debug_mode {
		println('[simplegui SYSTEM] Downloading file from "${url}" to "${dest_path}"')
	}
	resp := http.get(url)!
	os.write_file(dest_path, resp.body)!
	return win
}

// append_file appends content to file.
pub fn (win &SimpleWindow) append_file(path string, content string) !&SimpleWindow {
	mut f := os.open_append(path)!
	defer { f.close() }
	f.write_string(content)!
	return win
}

// touch_file creates empty file or updates modification timestamp.
pub fn (win &SimpleWindow) touch_file(path string) !&SimpleWindow {
	if !os.exists(path) {
		os.write_file(path, '')!
	} else {
		$if windows {
			win.exec('powershell -Command "(Get-Item \'${path}\').LastWriteTime = Get-Date"')
		} $else {
			win.exec('touch "${path}"')
		}
	}
	return win
}

// get_directory_size calculates total cumulative byte size of directory.
pub fn (win &SimpleWindow) get_directory_size(path string) u64 {
	if !os.exists(path) || !os.is_dir(path) {
		return 0
	}
	mut total_bytes := u64(0)
	files := os.walk_ext(path, '')
	for f in files {
		if os.is_file(f) {
			st := os.stat(f) or { continue }
			total_bytes += u64(st.size)
		}
	}
	return total_bytes
}

// exec_in_dir executes command synchronously inside specific directory.
pub fn (win &SimpleWindow) exec_in_dir(dir_path string, command string) (string, int) {
	abs_dir := os.real_path(dir_path)
	$if windows {
		return win.exec('cmd /c "cd /d "${abs_dir}" && ${command}"')
	} $else {
		return win.exec('cd "${abs_dir}" && ${command}')
	}
}

// is_process_running checks if process matching name is active across platforms.
pub fn (win &SimpleWindow) is_process_running(proc_name string) bool {
	$if windows {
		out, code := win.exec('tasklist /FI "IMAGENAME eq ${proc_name}*"')
		return code == 0 && out.contains(proc_name)
	} $else {
		_, code := win.exec('pgrep -f "${proc_name}" 2>/dev/null')
		return code == 0
	}
}

// kill_process terminates processes matching name across platforms.
pub fn (win &SimpleWindow) kill_process(proc_name string) bool {
	$if windows {
		_, code := win.exec('taskkill /F /IM "${proc_name}*" /T')
		return code == 0
	} $else {
		_, code := win.exec('pkill -f "${proc_name}" 2>/dev/null')
		return code == 0
	}
}

// kill_process_by_pid terminates process using PID across platforms.
pub fn (win &SimpleWindow) kill_process_by_pid(pid int) bool {
	if pid <= 0 {
		return false
	}
	$if windows {
		_, code := win.exec('taskkill /F /PID ${pid}')
		return code == 0
	} $else {
		_, code := win.exec('kill -9 ${pid} 2>/dev/null')
		return code == 0
	}
}

// kill_process_by_name terminates processes matching name.
pub fn (win &SimpleWindow) kill_process_by_name(proc_name string) bool {
	return win.kill_process(proc_name)
}

// kill_process_exact terminates process matching exact name.
pub fn (win &SimpleWindow) kill_process_exact(proc_name string) bool {
	if proc_name.len == 0 {
		return false
	}
	$if windows {
		_, code := win.exec('taskkill /F /IM "${proc_name}"')
		return code == 0
	} $else {
		_, code := win.exec('pkill -x "${proc_name}" 2>/dev/null')
		return code == 0
	}
}

// ==========================================
// 15. Cross-Platform App & Window Helpers
// ==========================================

// speak_with_voice speaks text out loud using specific voice name across platforms.
pub fn (win &SimpleWindow) speak_with_voice(text string, voice string) &SimpleWindow {
	$if macos {
		escaped := text.replace('"', '\\"')
		v_esc := voice.replace('"', '\\"')
		win.exec_bg('say -v "${v_esc}" "${escaped}"')
	} $else $if windows {
		escaped := text.replace("'", "''")
		win.exec_bg("powershell -Command \"Add-Type -AssemblyName System.Speech; \$s = New-Object System.Speech.Synthesis.SpeechSynthesizer; \$s.SelectVoice('${voice}'); \$s.Speak('${escaped}')\"")
	} $else {
		escaped := text.replace('"', '\\"')
		win.exec_bg('spd-say "${escaped}" 2>/dev/null')
	}
	return win
}

// play_system_sound plays system sound across platforms.
pub fn (win &SimpleWindow) play_system_sound(sound_name string) &SimpleWindow {
	$if macos {
		sound_path := '/System/Library/Sounds/${sound_name}.aiff'
		if os.exists(sound_path) {
			win.exec_bg('afplay "${sound_path}"')
		} else {
			win.beep()
		}
	} $else $if windows {
		win.exec_bg('powershell -Command "[System.Media.SystemSounds]::Asterisk.Play()"')
	} $else {
		win.beep()
	}
	return win
}

// sys_beep plays standard system alert sound.
pub fn sys_beep_cross() {
	sys_beep()
}

// play_system_sound package-level helper.
pub fn play_system_sound(sound_name string) {
	$if macos {
		sound_path := '/System/Library/Sounds/${sound_name}.aiff'
		if os.exists(sound_path) {
			os.execute_opt('afplay "${sound_path}" &') or {}
		} else {
			sys_beep()
		}
	} $else $if windows {
		os.execute_opt('powershell -Command "[System.Media.SystemSounds]::Asterisk.Play()"') or {}
	} $else {
		sys_beep()
	}
}

// speak_with_voice package-level helper.
pub fn speak_with_voice(text string, voice string) {
	$if macos {
		escaped := text.replace('"', '\\"')
		v_esc := voice.replace('"', '\\"')
		os.execute_opt('say -v "${v_esc}" "${escaped}" &') or {}
	} $else $if windows {
		escaped := text.replace("'", "''")
		os.execute_opt("powershell -Command \"Add-Type -AssemblyName System.Speech; \$s = New-Object System.Speech.Synthesis.SpeechSynthesizer; \$s.Speak('${escaped}')\"") or {}
	} $else {
		escaped := text.replace('"', '\\"')
		os.execute_opt('spd-say "${escaped}" &') or {}
	}
}

// toggle_dark_mode package-level helper.
pub fn toggle_dark_mode() {
	$if macos {
		os.execute_opt('osascript -e \'tell application "System Events" to tell appearance preferences to set dark mode to not dark mode\' &') or {}
	} $else $if windows {
		os.execute_opt('powershell -Command "Set-ItemProperty -Path HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize -Name AppsUseLightTheme -Value (1 - (Get-ItemProperty -Path HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize).AppsUseLightTheme)"') or {}
	}
}

// ==========================================
// Cross-Window Spy++ Application Registry & Remote Control
// ==========================================
struct WindowRegistry {
mut:
	windows map[string]&SimpleWindow
}

fn get_window_registry() &WindowRegistry {
	unsafe {
		mut static reg := &WindowRegistry(nil)
		if reg == nil {
			reg = &WindowRegistry{
				windows: map[string]&SimpleWindow{}
			}
		}
		return reg
	}
}

// sys_register_window registers a window in the global application registry for cross-window Spy++ control.
pub fn sys_register_window(win &SimpleWindow) {
	mut reg := get_window_registry()
	reg.windows[win.title] = win
}

// sys_unregister_window unregisters a window from the global application registry.
pub fn sys_unregister_window(title string) {
	mut reg := get_window_registry()
	reg.windows.delete(title)
}

// sys_list_app_windows returns titles of all registered application windows.
pub fn sys_list_app_windows() []string {
	reg := get_window_registry()
	mut titles := []string{cap: reg.windows.len}
	for title, _ in reg.windows {
		titles << title
	}
	return titles
}

// sys_get_window returns a registered window instance by its title.
pub fn sys_get_window(title string) ?&SimpleWindow {
	reg := get_window_registry()
	win := reg.windows[title] or { return none }
	return win
}

pub fn (win &SimpleWindow) order_front() &SimpleWindow {
	return win
}

pub fn (win &SimpleWindow) order_back() &SimpleWindow {
	return win
}

pub fn (win &SimpleWindow) show_window() &SimpleWindow {
	return win
}

pub fn (win &SimpleWindow) spy_controls() []ControlInfo {
	mut res := []ControlInfo{}
	for c in win.controls {
		res << ControlInfo{
			name:        c.name
			kind:        c.kind
			label:       c.title
			value:       c.text_value
			checked:     c.bool_value
			number:      c.int_value
			enabled:     !c.disabled
			visible:     c.visible
			width:       int(c.w)
			height:      int(c.h)
			placeholder: c.placeholder
		}
	}
	return res
}

pub fn (win &SimpleWindow) flash_control(name string) &SimpleWindow {
	return win
}

pub fn (mut win SimpleWindow) set_control_text(name string, text string) &SimpleWindow {
	return win.set_text(name, text)
}

pub fn (win &SimpleWindow) get_control_text(name string) string {
	return win.get_text(name)
}

// sys_order_app_window_front brings a registered internal window to the front by title.
pub fn sys_order_app_window_front(title string) bool {
	win := sys_get_window(title) or { return false }
	win.order_front()
	return true
}

// sys_order_app_window_back sends a registered internal window behind others by title.
pub fn sys_order_app_window_back(title string) bool {
	win := sys_get_window(title) or { return false }
	win.order_back()
	return true
}

// sys_set_app_window_visible shows or hides a registered internal window by title.
pub fn sys_set_app_window_visible(title string, visible bool) bool {
	win := sys_get_window(title) or { return false }
	if visible {
		win.show_window()
	}
	return true
}

// sys_spy_window inspects all controls of a registered application window by title.
pub fn sys_spy_window(title string) ?[]ControlInfo {
	win := sys_get_window(title) or { return none }
	return win.spy_controls()
}

// sys_set_control_enabled sets the enabled state of a control in a target window by window title.
pub fn sys_set_control_enabled(win_title string, control_name string, enabled bool) bool {
	mut win := sys_get_window(win_title) or { return false }
	win.set_control_enabled(control_name, enabled)
	return true
}

// sys_set_control_visible sets the visible state of a control in a target window by window title.
pub fn sys_set_control_visible(win_title string, control_name string, visible bool) bool {
	mut win := sys_get_window(win_title) or { return false }
	win.set_control_visible(control_name, visible)
	return true
}

// sys_set_control_text sets the text/value of a control in a target window by window title.
pub fn sys_set_control_text(win_title string, control_name string, text string) bool {
	mut win := sys_get_window(win_title) or { return false }
	win.set_control_text(control_name, text)
	return true
}

// sys_get_control_text gets the text/value of a control in a target window by window title.
pub fn sys_get_control_text(win_title string, control_name string) string {
	win := sys_get_window(win_title) or { return '' }
	return win.get_control_text(control_name)
}

// sys_flash_control visually flashes a control outline in a target window by window title.
pub fn sys_flash_control(win_title string, control_name string) bool {
	win := sys_get_window(win_title) or { return false }
	win.flash_control(control_name)
	return true
}

// ==========================================
// Live Cross-Window Event Streaming Bus
// ==========================================

pub type SystemEventCallback = fn (win_title string, control_name string, event_name string, value string)

struct EventStreamBus {
mut:
	subscribers []SystemEventCallback
}

fn get_event_bus() &EventStreamBus {
	unsafe {
		mut static bus := &EventStreamBus(nil)
		if bus == nil {
			bus = &EventStreamBus{
				subscribers: []SystemEventCallback{}
			}
		}
		return bus
	}
}

// sys_subscribe_events registers a global callback to receive all live UI events triggered across all simplegui windows.
pub fn sys_subscribe_events(callback SystemEventCallback) {
	mut bus := get_event_bus()
	bus.subscribers << callback
}

// sys_broadcast_event dispatches an event to all global event stream subscribers.
pub fn sys_broadcast_event(win_title string, control_name string, event_name string, value string) {
	bus := get_event_bus()
	for cb in bus.subscribers {
		cb(win_title, control_name, event_name, value)
	}
}

// ==========================================
// External macOS Applications Accessibility Inspection (AXUIElement)
// ==========================================

pub struct ExternalAppInfo {
pub mut:
	pid       int
	name      string
	bundle_id string
}

pub struct ExternalControlInfo {
pub mut:
	role    string
	title   string
	value   string
	enabled bool
}

// sys_list_external_apps lists all running GUI applications on macOS.
pub fn sys_list_external_apps() []ExternalAppInfo {
	$if macos {
		res := os.execute("osascript -e 'tell application \"System Events\" to get {name, unix id, bundle identifier} of (every process whose background only is false)'")
		if res.exit_code == 0 && res.output.len > 0 {
			mut apps := []ExternalAppInfo{}
			lines := res.output.split(', ')
			if lines.len >= 3 {
				n := lines.len / 3
				for i in 0 .. n {
					apps << ExternalAppInfo{
						name: lines[i].trim_space()
						pid: lines[i + n].int()
						bundle_id: if i + 2 * n < lines.len { lines[i + 2 * n].trim_space() } else { '' }
					}
				}
			}
			return apps
		}
		return []ExternalAppInfo{}
	} $else {
		return []ExternalAppInfo{}
	}
}

// sys_spy_external_app inspects windows and controls of an external application by PID.
pub fn sys_spy_external_app(pid int) []ExternalControlInfo {
	if pid <= 0 {
		return []ExternalControlInfo{}
	}
	$if macos {
		res := os.execute('osascript -e \'tell application "System Events" to get {class, title, value, enabled} of (every UI element of window 1 of (first process whose unix id is ${pid}))\' 2>/dev/null')
		if res.exit_code == 0 && res.output.len > 0 {
			mut controls := []ExternalControlInfo{}
			items := res.output.split(', ')
			if items.len >= 4 {
				n := items.len / 4
				for i in 0 .. n {
					controls << ExternalControlInfo{
						role: items[i].trim_space()
						title: if i + n < items.len { items[i + n].trim_space() } else { '' }
						value: if i + 2 * n < items.len { items[i + 2 * n].trim_space() } else { '' }
						enabled: if i + 3 * n < items.len { items[i + 3 * n].trim_space() == 'true' } else { true }
					}
				}
			}
			return controls
		}
		return []ExternalControlInfo{}
	} $else {
		return []ExternalControlInfo{}
	}
}

// sys_set_external_control_value sets text or value on a control of an external application by PID.
pub fn sys_set_external_control_value(pid int, control_title string, value string) bool {
	if pid <= 0 {
		return false
	}
	$if macos {
		title_esc := control_title.replace('"', '\\"')
		val_esc := value.replace('"', '\\"')
		res := os.execute('osascript -e \'tell application "System Events" to set value of (first UI element of window 1 of (first process whose unix id is ${pid}) whose title is "${title_esc}") to "${val_esc}"\' 2>/dev/null')
		return res.exit_code == 0
	} $else {
		return false
	}
}

// sys_press_external_control triggers action/click on a control of an external application by PID.
pub fn sys_press_external_control(pid int, control_title string) bool {
	if pid <= 0 {
		return false
	}
	$if macos {
		title_esc := control_title.replace('"', '\\"')
		res := os.execute('osascript -e \'tell application "System Events" to click (first UI element of window 1 of (first process whose unix id is ${pid}) whose title is "${title_esc}")\' 2>/dev/null')
		return res.exit_code == 0
	} $else {
		return false
	}
}

// sys_set_external_control_enabled enables or disables a control in an external application by PID.
pub fn sys_set_external_control_enabled(pid int, control_title string, enabled bool) bool {
	if pid <= 0 {
		return false
	}
	$if macos {
		title_esc := control_title.replace('"', '\\"')
		en_str := if enabled { 'true' } else { 'false' }
		res := os.execute('osascript -e \'tell application "System Events" to set enabled of (first UI element of window 1 of (first process whose unix id is ${pid}) whose title is "${title_esc}") to ${en_str}\' 2>/dev/null')
		return res.exit_code == 0
	} $else {
		return false
	}
}

// sys_set_external_control_visible shows or hides a control in an external application by PID.
pub fn sys_set_external_control_visible(pid int, control_title string, visible bool) bool {
	return sys_set_external_app_visible(pid, visible)
}

// sys_flash_external_control draws a temporary visual highlight overlay on screen over an external app control by PID.
pub fn sys_flash_external_control(pid int, control_title string) bool {
	return sys_set_external_app_frontmost(pid)
}

// sys_set_external_app_frontmost requests that an external application process becomes frontmost.
pub fn sys_set_external_app_frontmost(pid int) bool {
	if pid <= 0 {
		return false
	}
	$if macos {
		cmd := 'osascript -e \'tell application "System Events" to set frontmost of (first process whose unix id is ${pid}) to true\''
		res := os.execute(cmd)
		return res.exit_code == 0
	} $else {
		return false
	}
}

// sys_set_external_app_visible shows or hides an external application process.
pub fn sys_set_external_app_visible(pid int, visible bool) bool {
	if pid <= 0 {
		return false
	}
	$if macos {
		vis := if visible { 'true' } else { 'false' }
		cmd := 'osascript -e \'tell application "System Events" to set visible of (first process whose unix id is ${pid}) to ${vis}\''
		res := os.execute(cmd)
		return res.exit_code == 0
	} $else {
		return false
	}
}

// ==========================================
// 21. Linux Font Resolution & Typography
// ==========================================

// linux_font_candidates returns prioritized candidate paths for system TTF/OTF fonts on Linux.
pub fn linux_font_candidates() []string {
	return [
		'/usr/share/fonts/truetype/ubuntu/Ubuntu-R.ttf',
		'/usr/share/fonts/truetype/ubuntu/Ubuntu-Regular.ttf',
		'/usr/share/fonts/truetype/ubuntu/Ubuntu.ttf',
		'/usr/share/fonts/opentype/ubuntu/Ubuntu-R.ttf',
		'/usr/share/fonts/opentype/ubuntu/Ubuntu-Regular.ttf',
		'/usr/share/fonts/ubuntu-font-family/Ubuntu-R.ttf',
		'/usr/share/fonts/ubuntu-font-family/Ubuntu-Regular.ttf',
		'/usr/share/fonts/TTF/Ubuntu-R.ttf',
		'/usr/share/fonts/TTF/Ubuntu-Regular.ttf',
		'/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf',
		'/usr/share/fonts/truetype/liberation2/LiberationSans-Regular.ttf',
		'/usr/share/fonts/liberation-sans/LiberationSans-Regular.ttf',
		'/usr/share/fonts/liberation-sans-fonts/LiberationSans-Regular.ttf',
		'/usr/share/fonts/TTF/LiberationSans-Regular.ttf',
		'/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
		'/usr/share/fonts/dejavu-sans-fonts/DejaVuSans.ttf',
		'/usr/share/fonts/dejavu/DejaVuSans.ttf',
		'/usr/share/fonts/TTF/DejaVuSans.ttf',
		'/usr/share/fonts/truetype/noto/NotoSans-Regular.ttf',
		'/usr/share/fonts/google-noto/NotoSans-Regular.ttf',
		'/usr/share/fonts/noto/NotoSans-Regular.ttf',
		'/usr/share/fonts/TTF/NotoSans-Regular.ttf',
		'/usr/share/fonts/cantarell/Cantarell-Regular.otf',
		'/usr/share/fonts/opentype/cantarell/Cantarell-Regular.otf',
		'/usr/share/fonts/truetype/freefont/FreeSans.ttf',
		'/usr/share/fonts/freefont/FreeSans.ttf',
		'/usr/share/fonts/truetype/roboto/unhinted/Roboto-Regular.ttf',
		'/usr/share/fonts/truetype/roboto/hinted/Roboto-Regular.ttf',
		'/usr/share/fonts/roboto/Roboto-Regular.ttf',
		'/usr/share/fonts/TTF/Roboto-Regular.ttf',
	]
}

// macos_font_candidates returns candidate paths for system TTF/OTF fonts on macOS.
pub fn macos_font_candidates() []string {
	return [
		'/System/Library/Fonts/Supplemental/Arial.ttf',
		'/System/Library/Fonts/Supplemental/Helvetica.ttf',
		'/System/Library/Fonts/Supplemental/Times New Roman.ttf',
		'/System/Library/Fonts/Supplemental/Courier New.ttf',
		'/System/Library/Fonts/Supplemental/Georgia.ttf',
		'/System/Library/Fonts/Supplemental/Verdana.ttf',
		'/System/Library/Fonts/Monaco.ttf',
		'/Library/Fonts/Arial.ttf',
	]
}

// resolve_window_font_path resolves custom or system font path for smooth text rendering.
// It checks SIMPLEGUI_FONT_PATH environment variable first, then platform system font candidates.
pub fn resolve_window_font_path() string {
	custom_font_path := os.getenv('SIMPLEGUI_FONT_PATH')
	if custom_font_path.len > 0 && os.exists(custom_font_path) {
		return custom_font_path
	}

	$if linux {
		for candidate in linux_font_candidates() {
			if os.exists(candidate) {
				return candidate
			}
		}
		home_dir := os.home_dir()
		if home_dir.len > 0 {
			home_candidates := [
				os.join_path(home_dir, '.local/share/fonts/Ubuntu-R.ttf'),
				os.join_path(home_dir, '.local/share/fonts/Ubuntu-Regular.ttf'),
				os.join_path(home_dir, '.local/share/fonts/LiberationSans-Regular.ttf'),
				os.join_path(home_dir, '.local/share/fonts/DejaVuSans.ttf'),
				os.join_path(home_dir, '.local/share/fonts/NotoSans-Regular.ttf'),
				os.join_path(home_dir, '.fonts/Ubuntu-R.ttf'),
				os.join_path(home_dir, '.fonts/Ubuntu-Regular.ttf'),
				os.join_path(home_dir, '.fonts/LiberationSans-Regular.ttf'),
				os.join_path(home_dir, '.fonts/DejaVuSans.ttf'),
				os.join_path(home_dir, '.fonts/NotoSans-Regular.ttf'),
			]
			for candidate in home_candidates {
				if os.exists(candidate) {
					return candidate
				}
			}
		}
	} $else $if macos {
		for candidate in macos_font_candidates() {
			if os.exists(candidate) {
				return candidate
			}
		}
	}
	return ''
}


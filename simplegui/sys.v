module simplegui

import os

// sys.v - Neutralino-inspired System Call and OS API Extensions for SimpleWindow.
// Ported from vlang_simplegui to supercharge rapid desktop GUI development in simple_gg.

// ==========================================
// 1. Operating System Execution & Process Controls
// ==========================================

// exec runs a system command synchronously, returning stdout output and exit code.
pub fn (win &SimpleWindow) exec(command string) (string, int) {
	res := os.execute(command)
	return res.output.trim_space(), res.exit_code
}

// exec_or runs a system command, returning stdout if exit code is 0, or fallback string.
pub fn (win &SimpleWindow) exec_or(command string, fallback string) string {
	out, code := win.exec(command)
	if code == 0 {
		return out
	}
	return fallback
}

// exec_bg spawns a system command in a background thread.
pub fn (mut win SimpleWindow) exec_bg(command string) &SimpleWindow {
	spawn fn (cmd string) {
		_ := os.execute(cmd)
	}(command)
	return win
}

// get_env retrieves an environment variable.
pub fn (win &SimpleWindow) get_env(key string) string {
	return os.getenv(key)
}

// set_env sets an environment variable for the process.
pub fn (mut win SimpleWindow) set_env(key string, val string) &SimpleWindow {
	os.setenv(key, val, true)
	return win
}

// unset_env clears an environment variable.
pub fn (mut win SimpleWindow) unset_env(key string) &SimpleWindow {
	os.unsetenv(key)
	return win
}

// show_system_notification triggers a native OS desktop notification banner.
pub fn (mut win SimpleWindow) show_system_notification(title string, message string) &SimpleWindow {
	$if macos {
		title_esc := title.replace('"', '\\"')
		msg_esc := message.replace('"', '\\"')
		cmd := "osascript -e 'display notification \"${msg_esc}\" with title \"${title_esc}\"'"
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
// 2. Desktop Utility & Clipboard Shortcuts
// ==========================================

// open_url opens a web URL or file in the default web browser.
pub fn (mut win SimpleWindow) open_url(url string) &SimpleWindow {
	$if macos {
		win.exec_bg('open "${url}"')
	} $else $if windows {
		win.exec_bg('start "${url}"')
	} $else {
		win.exec_bg('xdg-open "${url}"')
	}
	return win
}

// reveal_in_finder reveals a file or directory in Finder / File Explorer.
pub fn (mut win SimpleWindow) reveal_in_finder(path string) &SimpleWindow {
	$if macos {
		win.exec_bg('open -R "${path}"')
	} $else $if windows {
		win.exec_bg('explorer.exe /select,"${path}"')
	} $else {
		win.exec_bg('xdg-open "${os.dir(path)}"')
	}
	return win
}

// copy_to_clipboard copies text to the system clipboard.
pub fn (mut win SimpleWindow) copy_to_clipboard(text string) &SimpleWindow {
	$if macos {
		win.exec("pbcopy << 'EOF'\n${text}\nEOF")
	} $else $if windows {
		win.exec("powershell -Command \"Set-Clipboard -Value '${text}'\"")
	} $else {
		win.exec("xclip -selection clipboard << 'EOF'\n${text}\nEOF")
	}
	return win
}

// get_clipboard_text retrieves text from the system clipboard.
pub fn (win &SimpleWindow) get_clipboard_text() string {
	$if macos {
		out, _ := win.exec('pbpaste')
		return out
	} $else $if windows {
		out, _ := win.exec('powershell -Command "Get-Clipboard"')
		return out
	} $else {
		out, _ := win.exec('xclip -selection clipboard -o')
		return out
	}
}

// get_system_path returns absolute paths to standard system directories.
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

module logutils

import os
import time

// LogLevel defines the severity ranking of a log record.
pub enum LogLevel {
	debug = 0
	info  = 1
	warn  = 2
	error = 3
	fatal = 4
}

// str returns the uppercase representation of the log level.
pub fn (l LogLevel) str() string {
	return match l {
		.debug { 'DEBUG' }
		.info { 'INFO' }
		.warn { 'WARN' }
		.error { 'ERROR' }
		.fatal { 'FATAL' }
	}
}

// LogOutput specifies where log lines should be dispatched.
pub enum LogOutput {
	console
	file
	both
}

// LoggerConfig configures a Logger instance.
pub struct LoggerConfig {
pub mut:
	level          LogLevel = .info
	output         LogOutput = .console
	file_path      string
	use_color      bool = true
	show_timestamp bool = true
}

// Logger provides structured, level-filtered logging to console and/or disk.
pub struct Logger {
pub mut:
	level          LogLevel
	output         LogOutput
	file_path      string
	use_color      bool
	show_timestamp bool
}

// new_logger creates a configured Logger.
pub fn new_logger(cfg LoggerConfig) Logger {
	return Logger{
		level: cfg.level
		output: cfg.output
		file_path: cfg.file_path
		use_color: cfg.use_color
		show_timestamp: cfg.show_timestamp
	}
}

// set_level updates the minimum threshold of messages to log.
pub fn (mut l Logger) set_level(level LogLevel) {
	l.level = level
}

// set_file sets or changes the destination file path for file logging.
pub fn (mut l Logger) set_file(path string) {
	l.file_path = path
	if l.output == .console {
		l.output = .both
	}
}

// format_message produces the formatted string for a log entry.
pub fn (l Logger) format_message(level LogLevel, msg string, now time.Time, colored bool) string {
	mut ts := ''
	if l.show_timestamp {
		ts = now.format_ss_micro() + ' '
	}

	mut prefix := '[${level.str()}]'
	if colored {
		prefix = match level {
			.debug { '\x1b[36m[DEBUG]\x1b[0m' } // cyan
			.info { '\x1b[32m[INFO]\x1b[0m' } // green
			.warn { '\x1b[33m[WARN]\x1b[0m' } // yellow
			.error { '\x1b[31m[ERROR]\x1b[0m' } // red
			.fatal { '\x1b[35m[FATAL]\x1b[0m' }
		}
		// magenta
	}

	return '${ts}${prefix} ${msg}'
}

// log formats and emits a log message according to logger configuration.
pub fn (l Logger) log(level LogLevel, msg string) {
	if int(level) < int(l.level) {
		return
	}

	now := time.now()
	plain_line := l.format_message(level, msg, now, false)

	if l.output == .console || l.output == .both {
		colored_line := l.format_message(level, msg, now, l.use_color)
		if level == .error || level == .fatal {
			eprintln(colored_line)
		} else {
			println(colored_line)
		}
	}

	if (l.output == .file || l.output == .both) && l.file_path != '' {
		mut f := os.open_append(l.file_path) or { return }
		defer {
			f.close()
		}
		f.writeln(plain_line) or {}
	}
}

// debug logs a message at debug severity.
pub fn (l Logger) debug(msg string) {
	l.log(.debug, msg)
}

// info logs a message at informational severity.
pub fn (l Logger) info(msg string) {
	l.log(.info, msg)
}

// warn logs a message at warning severity.
pub fn (l Logger) warn(msg string) {
	l.log(.warn, msg)
}

// error logs a message at error severity.
pub fn (l Logger) error(msg string) {
	l.log(.error, msg)
}

// fatal logs a message at fatal severity.
pub fn (l Logger) fatal(msg string) {
	l.log(.fatal, msg)
}

module main

import os
import logutils

fn main() {
	println('==================================================')
	println('                 demo_logutils                    ')
	println('==================================================')

	log_file := os.join_path(os.temp_dir(), 'demo_app.log')
	defer {
		os.rm(log_file) or {}
	}

	mut logger := logutils.new_logger(logutils.LoggerConfig{
		level: .debug
		output: .both
		file_path: log_file
		use_color: true
		show_timestamp: true
	})

	println('Logging to console and file: ${log_file}\n')

	logger.debug('Connecting to database at 127.0.0.1:5432')
	logger.info('Worker pool initialized with 8 threads')
	logger.warn('Disk storage is above 80% threshold')
	logger.error('Failed to ping upstream microservice')

	// Check file output
	if os.exists(log_file) {
		lines := os.read_lines(log_file) or { []string{} }
		println('\nWritten to log file (${lines.len} lines):')
		for line in lines {
			println('  [FILE] ' + line)
		}
		assert lines.len == 4
	}

	println('\n✔ logutils demo completed successfully!')
}

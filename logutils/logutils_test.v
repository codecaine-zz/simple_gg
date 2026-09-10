module logutils

import os
import time

fn test_logger_levels() {
	mut l := new_logger(
		level: .warn
		output: .console
		use_color: false
		show_timestamp: false
	)
	assert l.level == .warn
	l.set_level(.debug)
	assert l.level == .debug

	now := time.now()
	formatted := l.format_message(.info, 'test message', now, false)
	assert formatted.contains('[INFO] test message')
}

fn test_logger_file_output() {
	tmp_file := os.join_path(os.temp_dir(), 'test_vlang_utils_logger.log')
	if os.exists(tmp_file) {
		os.rm(tmp_file) or {}
	}
	defer {
		if os.exists(tmp_file) {
			os.rm(tmp_file) or {}
		}
	}

	mut l := new_logger(
		level: .info
		output: .file
		file_path: tmp_file
		use_color: false
		show_timestamp: false
	)

	l.debug('this should not be written')
	l.info('application started')
	l.warn('check configuration')
	l.error('an alert occurred')

	assert os.exists(tmp_file)
	content := os.read_file(tmp_file) or { '' }
	assert !content.contains('this should not be written')
	assert content.contains('[INFO] application started')
	assert content.contains('[WARN] check configuration')
	assert content.contains('[ERROR] an alert occurred')
}

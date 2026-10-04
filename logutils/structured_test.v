module logutils

import os
import time
import json2

struct Rec {
	level string
	msg   string
	user  string
	token string
}

fn test_parse_level() {
	assert parse_level('WARNING')! == .warn
	assert parse_level(' err ')! == .error
	assert parse_level('critical')! == .fatal
	if _ := parse_level('loud') {
		assert false
	}
}

fn test_logfmt() {
	assert format_logfmt({
		'b':   'two words'
		'a':   '1'
		'q':   'say "hi"'
		'nil': ''
	}) == 'a=1 b="two words" nil="" q="say \\"hi\\""'
}

fn test_json_record_is_valid_json_and_redacted() {
	now := time.unix(0)
	line := format_json_record(.warn, 'line1\n"quoted"', redact_fields({
		'user':  'ann'
		'token': 'abc'
	}, default_secret_keys), now)
	r := json2.decode[Rec](line)!
	assert r.level == 'warn'
	assert r.msg == 'line1\n"quoted"'
	assert r.user == 'ann'
	assert r.token == '[REDACTED]'
	assert line.starts_with('{"ts":"1970-01-01T00:00:00')
}

fn test_log_kv_and_json_to_file() {
	path := os.join_path(os.temp_dir(), 'logutils_kv_${os.getpid()}.log')
	defer {
		os.rm(path) or {}
	}
	l := new_logger(LoggerConfig{
		level:          .debug
		output:         .file
		file_path:      path
		show_timestamp: false
	})
	l.log_kv(.info, 'login', {
		'user':     'bob'
		'Password': 'hunter2'
	})
	l.log_json(.error, 'boom', {
		'code': '42'
	})
	lines := os.read_lines(path)!
	assert lines[0] == '[INFO] login Password=[REDACTED] user=bob'
	assert lines[1].contains('"level":"error"') && lines[1].contains('"code":"42"')
	assert !os.read_file(path)!.contains('hunter2')
}

fn test_rotate_file() {
	base := os.join_path(os.temp_dir(), 'logutils_rot_${os.getpid()}.log')
	defer {
		for s in ['', '.1', '.2', '.3'] {
			os.rm(base + s) or {}
		}
	}
	for i in 0 .. 4 {
		os.write_file(base, 'generation ${i} ' + 'x'.repeat(100))!
		rotate_file(base, 50, 2)!
	}
	assert !os.exists(base)
	assert os.read_file(base + '.1')!.starts_with('generation 3')
	assert os.read_file(base + '.2')!.starts_with('generation 2')
	assert !os.exists(base + '.3')
	os.write_file(base, 'small')!
	assert !rotate_file(base, 50, 2)!
}

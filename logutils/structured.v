module logutils

import os
import strings
import time

// parse_level parses "debug", "INFO", "warning", "err", "fatal"/"critical" (case-insensitive).
pub fn parse_level(s string) !LogLevel {
	return match s.trim_space().to_lower() {
		'debug', 'trace' { LogLevel.debug }
		'info', 'information' { LogLevel.info }
		'warn', 'warning' { LogLevel.warn }
		'error', 'err' { LogLevel.error }
		'fatal', 'critical', 'crit', 'panic' { LogLevel.fatal }
		else { error('unknown log level "${s}"') }
	}
}

fn sorted_keys(fields map[string]string) []string {
	mut keys := fields.keys()
	keys.sort()
	return keys
}

fn logfmt_value(v string) string {
	if v == '' {
		return '""'
	}
	mut needs := false
	for c in v {
		if c <= ` ` || c == `"` || c == `=` || c == `\\` || c >= 0x7f {
			needs = true
			break
		}
	}
	if !needs {
		return v
	}
	return '"' +
		v.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n').replace('\r', '\\r').replace('\t', '\\t') +
		'"'
}

// format_logfmt renders fields as `key=value` pairs (Heroku/Go logfmt), keys sorted
// for deterministic output and values quoted/escaped when needed.
pub fn format_logfmt(fields map[string]string) string {
	return sorted_keys(fields).map('${it}=${logfmt_value(fields[it])}').join(' ')
}

fn json_escape(s string) string {
	mut sb := strings.new_builder(s.len + 8)
	for c in s {
		match c {
			`"` {
				sb.write_string('\\"')
			}
			`\\` {
				sb.write_string('\\\\')
			}
			`\n` {
				sb.write_string('\\n')
			}
			`\r` {
				sb.write_string('\\r')
			}
			`\t` {
				sb.write_string('\\t')
			}
			else {
				if c < 0x20 {
					sb.write_string('\\u00${c:02x}')
				} else {
					sb.write_u8(c)
				}
			}
		}
	}
	return sb.str()
}

// format_json_record renders one JSON log line: {"ts":..,"level":..,"msg":..,<fields>}.
// Compatible with ELK, Loki, Datadog and CloudWatch ingestion.
pub fn format_json_record(level LogLevel, msg string, fields map[string]string, now time.Time) string {
	mut sb := strings.new_builder(96 + msg.len)
	sb.write_string('{"ts":"${now.format_rfc3339()}","level":"${level.str().to_lower()}","msg":"${json_escape(msg)}"')
	for k in sorted_keys(fields) {
		if k in ['ts', 'level', 'msg'] {
			continue
		}
		sb.write_string(',"${json_escape(k)}":"${json_escape(fields[k])}"')
	}
	sb.write_u8(`}`)
	return sb.str()
}

// default_secret_keys are field names whose values are masked by redact_fields.
pub const default_secret_keys = ['password', 'passwd', 'secret', 'token', 'api_key', 'apikey',
	'authorization', 'auth', 'cookie', 'session', 'private_key', 'access_token', 'refresh_token']

// redact_fields returns a copy with values of sensitive keys (case-insensitive,
// substring match against `secret_keys`) replaced by "[REDACTED]".
pub fn redact_fields(fields map[string]string, secret_keys []string) map[string]string {
	mut out := map[string]string{}
	for k, v in fields {
		lk := k.to_lower()
		mut hidden := false
		for s in secret_keys {
			if lk.contains(s) {
				hidden = true
				break
			}
		}
		out[k] = if hidden { '[REDACTED]' } else { v }
	}
	return out
}

// log_kv logs `msg` followed by logfmt-encoded `fields` (secrets auto-redacted),
// honoring the logger's level, outputs and colors.
pub fn (l Logger) log_kv(level LogLevel, msg string, fields map[string]string) {
	if int(level) < int(l.level) {
		return
	}
	kv := format_logfmt(redact_fields(fields, default_secret_keys))
	l.log(level, if kv.len > 0 { '${msg} ${kv}' } else { msg })
}

// log_json appends a JSON record to the logger's file (or stdout when no file is set).
pub fn (l Logger) log_json(level LogLevel, msg string, fields map[string]string) {
	if int(level) < int(l.level) {
		return
	}
	line := format_json_record(level, msg, redact_fields(fields, default_secret_keys), time.now())
	if l.file_path != '' && l.output != .console {
		mut f := os.open_append(l.file_path) or { return }
		defer {
			f.close()
		}
		f.writeln(line) or {}
	}
	if l.output != .file || l.file_path == '' {
		println(line)
	}
}

// rotate_file rotates `path` when it exceeds `max_bytes`: path -> path.1 -> ... -> path.<keep>,
// discarding the oldest. Returns true if a rotation happened.
pub fn rotate_file(path string, max_bytes i64, keep int) !bool {
	if !os.exists(path) || i64(os.file_size(path)) < max_bytes {
		return false
	}
	n := if keep < 1 { 1 } else { keep }
	oldest := '${path}.${n}'
	if os.exists(oldest) {
		os.rm(oldest)!
	}
	for i := n - 1; i >= 1; i-- {
		src := '${path}.${i}'
		if os.exists(src) {
			os.rename(src, '${path}.${i + 1}')!
		}
	}
	os.rename(path, '${path}.1')!
	return true
}

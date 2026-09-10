module envutils

import os
import strconv
import strings

// get_str returns the string value of the environment variable key, or default_val if unset/empty.
pub fn get_str(key string, default_val string) string {
	val := os.getenv(key)
	if val.len == 0 {
		return default_val
	}
	return val
}

// get_int returns the integer value of the environment variable key, or default_val if unset or invalid.
pub fn get_int(key string, default_val int) int {
	val := os.getenv(key)
	if val.len == 0 {
		return default_val
	}
	return strconv.atoi(val) or { default_val }
}

// get_bool returns the boolean value of the environment variable key.
// '1', 'true', 'yes', 'on' (case-insensitive) are considered true.
pub fn get_bool(key string, default_val bool) bool {
	val := os.getenv(key).trim_space().to_lower()
	if val.len == 0 {
		return default_val
	}
	if val in ['1', 'true', 'yes', 'on'] {
		return true
	}
	if val in ['0', 'false', 'no', 'off'] {
		return false
	}
	return default_val
}

// get_f64 returns the f64 value of the environment variable key, or default_val if unset or invalid.
pub fn get_f64(key string, default_val f64) f64 {
	val := os.getenv(key)
	if val.len == 0 {
		return default_val
	}
	f := val.f64()
	return if f == 0.0 && val != '0' && val != '0.0' { default_val } else { f }
}

// get_required returns the string value of key, or an error if unset or empty.
pub fn get_required(key string) !string {
	val := os.getenv(key)
	if val.len == 0 {
		return error('required environment variable `${key}` is not set')
	}
	return val
}

// parse_dotenv_content parses a dotenv string into a key-value map.
// Supports comments (#), quoted strings ('...', "..."), and inline whitespace.
pub fn parse_dotenv_content(content string) map[string]string {
	mut res := map[string]string{}
	lines := content.split_into_lines()
	for line in lines {
		trimmed := line.trim_space()
		if trimmed.len == 0 || trimmed.starts_with('#') {
			continue
		}
		eq_pos := trimmed.index('=') or { continue }
		key := trimmed[..eq_pos].trim_space()
		if key.len == 0 {
			continue
		}
		mut val := trimmed[eq_pos + 1..].trim_space()
		if val.starts_with('"') {
			end_quote := val[1..].index('"') or { -1 }
			if end_quote != -1 {
				val = val[1..end_quote + 1]
			}
		} else if val.starts_with("'") {
			end_quote := val[1..].index("'") or { -1 }
			if end_quote != -1 {
				val = val[1..end_quote + 1]
			}
		} else {
			hash_pos := val.index('#') or { -1 }
			if hash_pos >= 0 {
				val = val[..hash_pos].trim_space()
			}
		}
		res[key] = val
	}
	return res
}

// load_dotenv loads environment variables from a .env file and sets them in the OS environment.
pub fn load_dotenv(path string) !map[string]string {
	content := os.read_file(path) or { return error('failed to read dotenv file: ${err}') }
	parsed := parse_dotenv_content(content)
	for k, v in parsed {
		os.setenv(k, v, true)
	}
	return parsed
}

// load_dotenv_auto searches for a .env file starting in the current directory and traversing parent directories.
pub fn load_dotenv_auto() !map[string]string {
	mut dir := os.getwd()
	for {
		target := os.join_path(dir, '.env')
		if os.exists(target) && !os.is_dir(target) {
			return load_dotenv(target)
		}
		parent := os.dir(dir)
		if parent == dir || parent.len == 0 {
			break
		}
		dir = parent
	}
	return error('no .env file found in current or parent directories')
}

fn is_env_char(r rune) bool {
	return (r >= `a` && r <= `z`) || (r >= `A` && r <= `Z`) || (r >= `0` && r <= `9`) || r == `_`
}

// expand_env replaces ${VAR} or $VAR in the input string with their corresponding environment variable values.
pub fn expand_env(input string) string {
	if !input.contains('$') {
		return input
	}
	mut sb := strings.new_builder(input.len + 16)
	runes := input.runes()
	mut i := 0
	for i < runes.len {
		if runes[i] == `$` && i + 1 < runes.len {
			if runes[i + 1] == `{` {
				// ${VAR} syntax
				mut closing := -1
				for j in (i + 2) .. runes.len {
					if runes[j] == `}` {
						closing = j
						break
					}
				}
				if closing != -1 {
					var_name := runes[i + 2..closing].string()
					sb.write_string(os.getenv(var_name))
					i = closing + 1
					continue
				}
			} else {
				// $VAR syntax
				mut j := i + 1
				for j < runes.len && is_env_char(runes[j]) {
					j++
				}
				if j > i + 1 {
					var_name := runes[i + 1..j].string()
					sb.write_string(os.getenv(var_name))
					i = j
					continue
				}
			}
		}
		sb.write_rune(runes[i])
		i++
	}
	return sb.str()
}

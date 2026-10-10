module envutils

import os
import strings
import time

fn env_lookup(k string) ?string {
	v := os.getenv_opt(k) or { return none }
	return v
}

// lookup_braced resolves the inside of `${...}` with POSIX-style defaults:
//   ${VAR}         value or ''
//   ${VAR:-dflt}   dflt when VAR is unset OR empty
//   ${VAR-dflt}    dflt only when VAR is unset
fn lookup_braced(expr string, lookup fn (string) ?string) string {
	if i := expr.index(':-') {
		v := lookup(expr[..i]) or { '' }
		return if v == '' { expr[i + 2..] } else { v }
	}
	if i := expr.index('-') {
		return lookup(expr[..i]) or { expr[i + 1..] }
	}
	return lookup(expr) or { '' }
}

// expand_with replaces ${VAR}, ${VAR:-default}, ${VAR-default} and $VAR using `vars`
// instead of the process environment. `$$` produces a literal `$`.
pub fn expand_with(input string, vars map[string]string) string {
	if !input.contains('$') {
		return input
	}
	mut sb := strings.new_builder(input.len + 16)
	mut i := 0
	for i < input.len {
		c := input[i]
		if c == `$` && i + 1 < input.len {
			n := input[i + 1]
			if n == `$` {
				sb.write_u8(`$`)
				i += 2
				continue
			}
			if n == `{` {
				if close := input.index_after('}', i + 2) {
					sb.write_string(lookup_braced(input[i + 2..close], fn [vars] (k string) ?string {
						if k in vars {
							return vars[k]
						}
						return none
					}))
					i = close + 1
					continue
				}
			} else {
				mut j := i + 1
				for j < input.len && is_env_char(rune(input[j])) {
					j++
				}
				if j > i + 1 {
					sb.write_string(vars[input[i + 1..j]] or { '' })
					i = j
					continue
				}
			}
		}
		sb.write_u8(c)
		i++
	}
	return sb.str()
}

// parse_dotenv_expand parses dotenv content and expands `${VAR}` references against
// previously defined keys (then the process environment), like `dotenv-expand`.
pub fn parse_dotenv_expand(content string) map[string]string {
	raw := parse_dotenv_content(content)
	mut scope := os.environ()
	mut out := map[string]string{}
	for k, v in raw {
		ev := expand_with(v, scope)
		out[k] = ev
		scope[k] = ev
	}
	return out
}

// load_dotenv_no_override loads a .env file but never overwrites variables that are
// already set in the environment (the usual "real env wins" precedence).
pub fn load_dotenv_no_override(path string) !map[string]string {
	content := os.read_file(path) or { return error('failed to read dotenv file: ${err}') }
	parsed := parse_dotenv_content(content)
	for k, v in parsed {
		if os.getenv_opt(k) == none {
			os.setenv(k, v, true)
		}
	}
	return parsed
}

// parse_duration_simple parses "250ms", "10s", "5m", "2h", "1d" or a bare number of seconds.
fn parse_duration_simple(s string) ?time.Duration {
	t := s.trim_space().to_lower()
	if t == '' {
		return none
	}
	units := [['ms', '1000000'], ['us', '1000'], ['ns', '1'],
		['s', '1000000000'], ['m', '60000000000'], ['h', '3600000000000'],
		['d', '86400000000000']]
	for u in units {
		if t.ends_with(u[0]) {
			num := t[..t.len - u[0].len]
			if num == '' || !num.bytes().all(it.is_digit() || it == `.`) {
				return none
			}
			return time.Duration(i64(num.f64() * u[1].f64()))
		}
	}
	if t.bytes().all(it.is_digit()) {
		return time.Duration(t.i64() * time.second)
	}
	return none
}

// get_duration reads a duration such as "30s", "5m", "250ms" (bare numbers = seconds).
pub fn get_duration(key string, default_val time.Duration) time.Duration {
	return parse_duration_simple(os.getenv(key)) or { default_val }
}

// get_enum returns the variable if it is one of `allowed` (case-insensitive), else default.
pub fn get_enum(key string, allowed []string, default_val string) string {
	v := os.getenv(key).trim_space()
	for a in allowed {
		if a.to_lower() == v.to_lower() {
			return a
		}
	}
	return default_val
}

// require_all returns an error listing every missing/empty variable at once.
pub fn require_all(keys []string) ! {
	missing := keys.filter(os.getenv(it).len == 0)
	if missing.len > 0 {
		return error('missing required environment variables: ${missing.join(', ')}')
	}
}

// with_env temporarily sets variables while running `f`, restoring prior values after.
pub fn with_env(vars map[string]string, f fn ()) {
	mut prev := map[string]?string{}
	for k, v in vars {
		prev[k] = os.getenv_opt(k)
		os.setenv(k, v, true)
	}
	defer {
		for k, old in prev {
			if o := old {
				os.setenv(k, o, true)
			} else {
				os.unsetenv(k)
			}
		}
	}
	f()
}

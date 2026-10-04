module regexutils

import regex
import strings

// Characters that must be backslash-escaped in V regex. `$` is special-cased:
// the engine rejects `\$`, so it is emitted as the class `[$]`.
const regex_meta = '.+*?()[]{}|^\\-'

// escape quotes every metacharacter so `s` matches literally, e.g. for
// building patterns from user input without regex injection.
pub fn escape(s string) string {
	mut sb := strings.new_builder(s.len + 8)
	for c in s {
		if c == `$` {
			sb.write_string('[$]')
		} else if regex_meta.contains_u8(c) {
			sb.write_u8(`\\`)
			sb.write_u8(c)
		} else {
			sb.write_u8(c)
		}
	}
	return sb.str()
}

// is_valid_pattern reports whether the pattern compiles.
pub fn is_valid_pattern(pattern string) bool {
	regex.regex_opt(pattern) or { return false }
	return true
}

// Regex is a compiled pattern for repeated use (avoids recompiling per call).
pub struct Regex {
pub:
	pattern string
mut:
	re regex.RE
}

// compile compiles a pattern once for reuse.
pub fn compile(pattern string) !Regex {
	re := regex.regex_opt(pattern)!
	return Regex{
		pattern: pattern
		re:      re
	}
}

// must_compile compiles a pattern or panics (for constant, known-good patterns).
pub fn must_compile(pattern string) Regex {
	return compile(pattern) or { panic('regexutils: invalid pattern "${pattern}": ${err}') }
}

// is_match reports whether the entire text matches.
pub fn (mut r Regex) is_match(text string) bool {
	return r.re.matches_string(text)
}

// contains reports whether the pattern occurs anywhere in text.
pub fn (mut r Regex) contains(text string) bool {
	s, _ := r.re.find(text)
	return s >= 0
}

// find returns the first match with its span.
pub fn (mut r Regex) find(text string) ?Match {
	s, e := r.re.find(text)
	if s < 0 {
		return none
	}
	return Match{
		text:  text[s..e]
		start: s
		end:   e
	}
}

// find_all returns every non-overlapping, non-empty match.
pub fn (mut r Regex) find_all(text string) []Match {
	mut out := []Match{}
	mut pos := 0
	for pos <= text.len {
		s, e := r.re.find_from(text, pos)
		if s < 0 {
			break
		}
		if e > s {
			out << Match{
				text:  text[s..e]
				start: s
				end:   e
			}
			pos = e
		} else {
			pos = s + 1
		}
	}
	return out
}

// count returns the number of non-empty matches.
pub fn (mut r Regex) count(text string) int {
	return r.find_all(text).len
}

fn (mut r Regex) groups_of(text string, s int, e int) []string {
	mut out := [text[s..e]]
	for i in 0 .. r.re.group_count {
		out << r.re.get_group_by_id(text, i)
	}
	return out
}

// captures returns the first match followed by its capture groups:
// [whole, group1, group2, ...]. Unmatched groups are ''.
pub fn (mut r Regex) captures(text string) ?[]string {
	s, e := r.re.find(text)
	if s < 0 {
		return none
	}
	return r.groups_of(text, s, e)
}

// captures_all returns captures (as in `captures`) for every match.
pub fn (mut r Regex) captures_all(text string) [][]string {
	mut out := [][]string{}
	mut pos := 0
	for pos <= text.len {
		s, e := r.re.find_from(text, pos)
		if s < 0 {
			break
		}
		if e > s {
			out << r.groups_of(text, s, e)
			pos = e
		} else {
			pos = s + 1
		}
	}
	return out
}

// named_captures returns `(?P<name>...)` groups of the first match.
pub fn (mut r Regex) named_captures(text string) ?map[string]string {
	s, _ := r.re.find(text)
	if s < 0 {
		return none
	}
	mut out := map[string]string{}
	for name, _ in r.re.group_map {
		out[name] = r.re.get_group_by_name(text, name)
	}
	return out
}

// replace substitutes all matches with repl (V regex `\0`..`\9` group refs supported).
pub fn (mut r Regex) replace(text string, repl string) string {
	return r.re.replace(text, repl)
}

// replace_fn substitutes every non-empty match with the callback's result.
pub fn (mut r Regex) replace_fn(text string, f fn (m Match) string) string {
	mut sb := strings.new_builder(text.len)
	mut last := 0
	for m in r.find_all(text) {
		sb.write_string(text[last..m.start])
		sb.write_string(f(m))
		last = m.end
	}
	sb.write_string(text[last..])
	return sb.str()
}

// split divides text around matches.
pub fn (mut r Regex) split(text string) []string {
	return r.re.split(text)
}

// ---------------------------------------------------------------------------
// One-shot convenience wrappers (compile per call)
// ---------------------------------------------------------------------------

// count_matches returns the number of non-empty matches of pattern in text.
pub fn count_matches(pattern string, text string) int {
	mut r := compile(pattern) or { return 0 }
	return r.count(text)
}

// captures returns [whole, group1, ...] for the first match.
pub fn captures(pattern string, text string) ?[]string {
	mut r := compile(pattern) or { return none }
	return r.captures(text)
}

// captures_all returns the captures of every match.
pub fn captures_all(pattern string, text string) [][]string {
	mut r := compile(pattern) or { return [][]string{} }
	return r.captures_all(text)
}

// named_captures returns the named groups of the first match.
pub fn named_captures(pattern string, text string) ?map[string]string {
	mut r := compile(pattern) or { return none }
	return r.named_captures(text)
}

// replace_fn substitutes each match with the callback's result.
pub fn replace_fn(pattern string, text string, f fn (m Match) string) string {
	mut r := compile(pattern) or { return text }
	return r.replace_fn(text, f)
}

module webutils

import x.json2
import math
import net.urllib
import strings
import time

// filters that produce HTML-safe output; `<%= x | safe %>` is not escaped again.
const safe_filters = ['safe', 'raw', 'escape', 'e', 'nl2br']

const max_range_len = 100_000

// escape_html escapes text for safe embedding in HTML element content and
// quoted attribute values (`&`, `<`, `>`, `"`, `'` and backtick).
pub fn escape_html(s string) string {
	mut needs := false
	for c in s {
		if c in [`&`, `<`, `>`, `"`, `'`, `\``] {
			needs = true
			break
		}
	}
	if !needs {
		return s
	}
	mut sb := strings.new_builder(s.len + 16)
	for c in s {
		match c {
			`&` { sb.write_string('&amp;') }
			`<` { sb.write_string('&lt;') }
			`>` { sb.write_string('&gt;') }
			`"` { sb.write_string('&quot;') }
			`'` { sb.write_string('&#39;') }
			`\`` { sb.write_string('&#96;') }
			else { sb.write_u8(c) }
		}
	}
	return sb.str()
}

// json_for_script encodes a value as JSON that is safe to embed inside an
// HTML `<script>` block: `<`, `>`, `&`, U+2028 and U+2029 are \u-escaped so
// the payload can never close the script tag or break the JS parser.
// Use it unescaped: `<script>const data = <%- data | json %>;</script>`.
pub fn json_for_script(v json2.Any) string {
	s := encode_json(v)
	return s.replace_each(['<', '\\u003c', '>', '\\u003e', '&', '\\u0026', '\u2028', '\\u2028',
		'\u2029', '\\u2029'])
}

// url_encode percent-encodes a string like JavaScript's encodeURIComponent.
pub fn url_encode(s string) string {
	return urllib.query_escape(s).replace('+', '%20')
}

fn arg(args []json2.Any, i int) json2.Any {
	return if i < args.len { args[i] } else { null }
}

fn arg_int(args []json2.Any, i int, def i64) i64 {
	if i >= args.len || is_null(args[i]) {
		return def
	}
	return as_i64(args[i]) or { def }
}

fn arg_str(args []json2.Any, i int, def string) string {
	if i >= args.len || is_null(args[i]) {
		return def
	}
	return to_text(args[i])
}

fn strip_tags(s string) string {
	mut sb := strings.new_builder(s.len)
	mut in_tag := false
	for c in s {
		if c == `<` {
			in_tag = true
			continue
		}
		if c == `>` && in_tag {
			in_tag = false
			continue
		}
		if !in_tag {
			sb.write_u8(c)
		}
	}
	return sb.str()
}

fn title_case(s string) string {
	mut sb := strings.new_builder(s.len)
	mut start := true
	for r in s.runes() {
		rs := r.str()
		if rs == ' ' || rs == '\t' || rs == '\n' || rs == '-' || rs == '_' {
			start = true
			sb.write_string(rs)
			continue
		}
		sb.write_string(if start { rs.to_upper() } else { rs.to_lower() })
		start = false
	}
	return sb.str()
}

fn sort_values(arr []json2.Any) []json2.Any {
	mut out := arr.clone()
	out.sort_with_compare(fn (a &json2.Any, b &json2.Any) int {
		return compare_values(*a, *b) or { to_text(*a).compare(to_text(*b)) }
	})
	return out
}

fn as_time(v json2.Any) ?time.Time {
	return match v {
		time.Time {
			v
		}
		string {
			time.parse_rfc3339(v) or { time.parse(v) or { time.parse_iso8601(v) or { return none } } }
		}
		else {
			secs := as_i64(v) or { return none }
			time.unix(secs)
		}
	}
}

// call_builtin evaluates a built-in filter/function. `x | f(a)`, `f(x, a)` and
// `x.f(a)` are equivalent.
fn call_builtin(name string, args []json2.Any) !json2.Any {
	a := arg(args, 0)
	match name {
		'upper', 'toUpperCase' {
			return json2.Any(to_text(a).to_upper())
		}
		'lower', 'toLowerCase' {
			return json2.Any(to_text(a).to_lower())
		}
		'capitalize' {
			s := to_text(a)
			if s.len == 0 {
				return json2.Any(s)
			}
			r := s.runes()
			return json2.Any(r[0].str().to_upper() + r[1..].string().to_lower())
		}
		'title' {
			return json2.Any(title_case(to_text(a)))
		}
		'trim' {
			return json2.Any(to_text(a).trim_space())
		}
		'length', 'len', 'count', 'size' {
			return match a {
				[]json2.Any { json2.Any(i64(a.len)) }
				map[string]json2.Any { json2.Any(i64(a.len)) }
				json2.Null { json2.Any(i64(0)) }
				else { json2.Any(i64(to_text(a).runes().len)) }
			}
		}
		'default' {
			if is_null(a) || (a is string && a.len == 0) {
				return arg(args, 1)
			}
			return a
		}
		'join' {
			sep := arg_str(args, 1, ',')
			if a is []json2.Any {
				return json2.Any(a.map(to_text(it)).join(sep))
			}
			return json2.Any(to_text(a))
		}
		'first' {
			return match a {
				[]json2.Any {
					if a.len > 0 { json2.Any(a[0]) } else { null }
				}
				string { get_index(a, json2.Any(i64(0))) }
				else { null }
			}
		}
		'last' {
			return match a {
				[]json2.Any {
					if a.len > 0 { json2.Any(a[a.len - 1]) } else { null }
				}
				string { get_index(a, json2.Any(i64(-1))) }
				else { null }
			}
		}
		'reverse' {
			if a is []json2.Any {
				return json2.Any(a.reverse())
			}
			return json2.Any(to_text(a).runes().reverse().string())
		}
		'sort' {
			if a is []json2.Any {
				return json2.Any(sort_values(a))
			}
			return a
		}
		'unique', 'uniq' {
			if a is []json2.Any {
				mut out := []json2.Any{}
				for item in a {
					if !out.any(values_equal(it, item)) {
						out << item
					}
				}
				return json2.Any(out)
			}
			return a
		}
		'truncate' {
			s := to_text(a)
			n := int(arg_int(args, 1, 80))
			suffix := arg_str(args, 2, '...')
			r := s.runes()
			if r.len <= n {
				return json2.Any(s)
			}
			keep := if n - suffix.runes().len > 0 { n - suffix.runes().len } else { 0 }
			return json2.Any(r[..keep].string() + suffix)
		}
		'replace' {
			return json2.Any(to_text(a).replace(arg_str(args, 1, ''), arg_str(args, 2, '')))
		}
		'split' {
			s := to_text(a)
			sep := arg_str(args, 1, ',')
			parts := if sep == '' { s.runes().map(it.str()) } else { s.split(sep) }
			return json2.Any(parts.map(json2.Any(it)))
		}
		'json', 'tojson', 'stringify' {
			return json2.Any(json_for_script(a))
		}
		'pretty', 'dump' {
			return json2.Any(encode_json_pretty(a))
		}
		'url', 'urlencode', 'encodeURIComponent' {
			return json2.Any(url_encode(to_text(a)))
		}
		'escape', 'e' {
			return json2.Any(escape_html(to_text(a)))
		}
		'safe', 'raw' {
			return a
		}
		'striptags' {
			return json2.Any(strip_tags(to_text(a)))
		}
		'nl2br' {
			return json2.Any(escape_html(to_text(a)).replace('\r\n', '\n').replace('\n', '<br>\n'))
		}
		'round' {
			x := as_num(a) or { return json2.Any(f64(0)) }
			n := arg_int(args, 1, 0)
			p := math.pow(10, f64(n))
			r := math.round(x * p) / p
			if n == 0 {
				return json2.Any(i64(r))
			}
			return json2.Any(r)
		}
		'fixed', 'toFixed' {
			x := as_num(a) or { 0.0 }
			n := int(arg_int(args, 1, 2))
			return json2.Any(strings_fixed(x, n))
		}
		'floor' {
			return json2.Any(i64(math.floor(as_num(a) or { 0.0 })))
		}
		'ceil' {
			return json2.Any(i64(math.ceil(as_num(a) or { 0.0 })))
		}
		'abs' {
			if is_intlike(a) {
				v := as_i64(a) or { 0 }
				return json2.Any(if v < 0 { -v } else { v })
			}
			return json2.Any(math.abs(as_num(a) or { 0.0 }))
		}
		'int' {
			return json2.Any(as_i64(a) or { i64(0) })
		}
		'float', 'number' {
			if a is string {
				return json2.Any(a.trim_space().f64())
			}
			return json2.Any(as_num(a) or { 0.0 })
		}
		'string', 'str' {
			return json2.Any(to_text(a))
		}
		'bool' {
			return json2.Any(truthy(a))
		}
		'keys' {
			if a is map[string]json2.Any {
				return json2.Any(a.keys().map(json2.Any(it)))
			}
			return json2.Any([]json2.Any{})
		}
		'values' {
			if a is map[string]json2.Any {
				return json2.Any(a.values())
			}
			return json2.Any([]json2.Any{})
		}
		'contains', 'includes' {
			return json2.Any(contains_value(a, arg(args, 1)))
		}
		'starts_with', 'startsWith' {
			return json2.Any(to_text(a).starts_with(arg_str(args, 1, '')))
		}
		'ends_with', 'endsWith' {
			return json2.Any(to_text(a).ends_with(arg_str(args, 1, '')))
		}
		'empty', 'is_empty' {
			return json2.Any(!truthy(a))
		}
		'slice' {
			start := arg_int(args, 1, 0)
			match a {
				[]json2.Any {
					s, e := clamp_slice(start, arg_int(args, 2, a.len), a.len)
					return json2.Any(a[s..e])
				}
				else {
					r := to_text(a).runes()
					s, e := clamp_slice(start, arg_int(args, 2, r.len), r.len)
					return json2.Any(r[s..e].string())
				}
			}
		}
		'range' {
			mut lo := i64(0)
			mut hi := arg_int(args, 0, 0)
			mut step := i64(1)
			if args.len >= 2 {
				lo = arg_int(args, 0, 0)
				hi = arg_int(args, 1, 0)
			}
			if args.len >= 3 {
				step = arg_int(args, 2, 1)
			}
			if step == 0 {
				return error('range step cannot be 0')
			}
			mut out := []json2.Any{}
			mut i := lo
			for (step > 0 && i < hi) || (step < 0 && i > hi) {
				out << json2.Any(i)
				if out.len > max_range_len {
					return error('range too large (max ${max_range_len})')
				}
				i += step
			}
			return json2.Any(out)
		}
		'min', 'max', 'sum' {
			items := if args.len == 1 && a is []json2.Any { a } else { args }
			if items.len == 0 {
				return null
			}
			if name == 'sum' {
				mut acc := json2.Any(i64(0))
				for it in items {
					acc = arith('+', acc, it)!
				}
				return acc
			}
			mut best := items[0]
			for it in items[1..] {
				c := compare_values(it, best)!
				if (name == 'min' && c < 0) || (name == 'max' && c > 0) {
					best = it
				}
			}
			return best
		}
		'date' {
			t := as_time(a) or { return json2.Any('') }
			return json2.Any(t.custom_format(arg_str(args, 1, 'YYYY-MM-DD')))
		}
		'plural', 'pluralize' {
			n := as_num(a) or { 0.0 }
			return if n == 1 {
				json2.Any(arg_str(args, 1, ''))
			} else {
				json2.Any(arg_str(args, 2, 's'))
			}
		}
		else {
			return error('unknown filter/function `${name}`')
		}
	}
}

fn clamp_slice(start i64, end i64, n int) (int, int) {
	mut s := if start < 0 { start + n } else { start }
	mut e := if end < 0 { end + n } else { end }
	s = if s < 0 {
		0
	} else if s > n {
		n
	} else {
		s
	}
	e = if e < s {
		s
	} else if e > n {
		n
	} else {
		e
	}
	return int(s), int(e)
}

fn strings_fixed(x f64, n int) string {
	digits := if n < 0 {
		0
	} else if n > 12 {
		12
	} else {
		n
	}
	if math.is_nan(x) || math.is_inf(x, 0) || math.abs(x) >= 1e15 {
		return fmt_num(x)
	}
	p := i64(math.pow(10, f64(digits)))
	scaled := i64(math.round(math.abs(x) * f64(p)))
	whole := scaled / p
	sign := if x < 0 && scaled != 0 { '-' } else { '' }
	if digits == 0 {
		return '${sign}${whole}'
	}
	frac := (scaled % p).str()
	return '${sign}${whole}.${'0'.repeat(digits - frac.len)}${frac}'
}

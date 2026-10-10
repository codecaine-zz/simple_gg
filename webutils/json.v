module webutils

import math
import strings
import time
import json2

// Self-contained JSON encode/parse for `json2.Any`. Instantiating json2's
// generic encoder/decoder on the recursive `json2.Any` sum type makes the V
// compiler explode in memory, so dynamic values go through this small,
// strict, depth-limited implementation instead.

const json_max_depth = 512

// encode_json serialises a dynamic value to compact JSON (NaN/Inf -> null).
pub fn encode_json(v json2.Any) string {
	mut sb := strings.new_builder(64)
	write_json(mut sb, v, '', '')
	return sb.str()
}

// encode_json_pretty serialises a dynamic value to indented JSON.
pub fn encode_json_pretty(v json2.Any) string {
	mut sb := strings.new_builder(64)
	write_json(mut sb, v, '  ', '')
	return sb.str()
}

fn write_json_string(mut sb strings.Builder, s string) {
	sb.write_u8(`"`)
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
			`\b` {
				sb.write_string('\\b')
			}
			`\f` {
				sb.write_string('\\f')
			}
			else {
				if c < 0x20 {
					sb.write_string('\\u00')
					sb.write_u8('0123456789abcdef'[c >> 4])
					sb.write_u8('0123456789abcdef'[c & 0xf])
				} else {
					sb.write_u8(c)
				}
			}
		}
	}
	sb.write_u8(`"`)
}

fn write_json(mut sb strings.Builder, v json2.Any, indent string, cur string) {
	match v {
		string {
			write_json_string(mut sb, v)
		}
		bool {
			sb.write_string(if v { 'true' } else { 'false' })
		}
		json2.Null {
			sb.write_string('null')
		}
		f64 {
			if math.is_nan(v) || math.is_inf(v, 0) {
				sb.write_string('null')
			} else {
				sb.write_string(fmt_num(v))
			}
		}
		f32 {
			write_json(mut sb, json2.Any(f64(v)), indent, cur)
		}
		time.Time {
			write_json_string(mut sb, v.format_rfc3339())
		}
		[]json2.Any {
			if v.len == 0 {
				sb.write_string('[]')
				return
			}
			inner := cur + indent
			sb.write_u8(`[`)
			for i, item in v {
				if i > 0 {
					sb.write_u8(`,`)
				}
				if indent != '' {
					sb.write_u8(`\n`)
					sb.write_string(inner)
				}
				write_json(mut sb, item, indent, inner)
			}
			if indent != '' {
				sb.write_u8(`\n`)
				sb.write_string(cur)
			}
			sb.write_u8(`]`)
		}
		map[string]json2.Any {
			if v.len == 0 {
				sb.write_string('{}')
				return
			}
			inner := cur + indent
			sb.write_u8(`{`)
			mut first := true
			for k, item in v {
				if !first {
					sb.write_u8(`,`)
				}
				first = false
				if indent != '' {
					sb.write_u8(`\n`)
					sb.write_string(inner)
				}
				write_json_string(mut sb, k)
				sb.write_u8(`:`)
				if indent != '' {
					sb.write_u8(` `)
				}
				write_json(mut sb, item, indent, inner)
			}
			if indent != '' {
				sb.write_u8(`\n`)
				sb.write_string(cur)
			}
			sb.write_u8(`}`)
		}
		else {
			sb.write_string((as_i64(v) or { 0 }).str())
		}
	}
}

struct JsonParser {
	src string
mut:
	pos   int
	depth int
}

// parse_json parses strict RFC 8259 JSON into a dynamic value. Integers
// become i64, other numbers f64. Nesting is limited to 512 levels.
pub fn parse_json(src string) !json2.Any {
	mut p := JsonParser{
		src: src
	}
	p.ws()
	v := p.value()!
	p.ws()
	if p.pos != src.len {
		return error('JSON: unexpected trailing data at offset ${p.pos}')
	}
	return v
}

fn (mut p JsonParser) ws() {
	for p.pos < p.src.len && p.src[p.pos] in [` `, `\t`, `\n`, `\r`] {
		p.pos++
	}
}

fn (mut p JsonParser) fail(msg string) IError {
	return error('JSON: ${msg} at offset ${p.pos}')
}

fn (mut p JsonParser) value() !json2.Any {
	if p.pos >= p.src.len {
		return p.fail('unexpected end of input')
	}
	c := p.src[p.pos]
	match c {
		`{` {
			return p.object()
		}
		`[` {
			return p.array()
		}
		`"` {
			return json2.Any(p.read_string()!)
		}
		`t` {
			return p.lit('true', json2.Any(true))
		}
		`f` {
			return p.lit('false', json2.Any(false))
		}
		`n` {
			return p.lit('null', null)
		}
		else {
			if c == `-` || c.is_digit() {
				return p.number()
			}
			return p.fail('unexpected character `${c.ascii_str()}`')
		}
	}
}

fn (mut p JsonParser) lit(word string, v json2.Any) !json2.Any {
	if p.src[p.pos..].starts_with(word) {
		p.pos += word.len
		return v
	}
	return p.fail('invalid literal')
}

fn (mut p JsonParser) enter() ! {
	p.depth++
	if p.depth > json_max_depth {
		return p.fail('nesting too deep')
	}
}

fn (mut p JsonParser) object() !json2.Any {
	p.enter()!
	p.pos++
	mut m := map[string]json2.Any{}
	p.ws()
	if p.pos < p.src.len && p.src[p.pos] == `}` {
		p.pos++
		p.depth--
		return json2.Any(m)
	}
	for {
		p.ws()
		if p.pos >= p.src.len || p.src[p.pos] != `"` {
			return p.fail('expected object key')
		}
		k := p.read_string()!
		p.ws()
		if p.pos >= p.src.len || p.src[p.pos] != `:` {
			return p.fail('expected `:`')
		}
		p.pos++
		p.ws()
		m[k] = p.value()!
		p.ws()
		if p.pos < p.src.len && p.src[p.pos] == `,` {
			p.pos++
			continue
		}
		if p.pos < p.src.len && p.src[p.pos] == `}` {
			p.pos++
			break
		}
		return p.fail('expected `,` or `}`')
	}
	p.depth--
	return json2.Any(m)
}

fn (mut p JsonParser) array() !json2.Any {
	p.enter()!
	p.pos++
	mut a := []json2.Any{}
	p.ws()
	if p.pos < p.src.len && p.src[p.pos] == `]` {
		p.pos++
		p.depth--
		return json2.Any(a)
	}
	for {
		p.ws()
		a << p.value()!
		p.ws()
		if p.pos < p.src.len && p.src[p.pos] == `,` {
			p.pos++
			continue
		}
		if p.pos < p.src.len && p.src[p.pos] == `]` {
			p.pos++
			break
		}
		return p.fail('expected `,` or `]`')
	}
	p.depth--
	return json2.Any(a)
}

fn hex4(s string) ?u32 {
	if s.len != 4 {
		return none
	}
	mut v := u32(0)
	for c in s {
		d := if c >= `0` && c <= `9` {
			u32(c - `0`)
		} else if c >= `a` && c <= `f` {
			u32(c - `a` + 10)
		} else if c >= `A` && c <= `F` {
			u32(c - `A` + 10)
		} else {
			return none
		}
		v = v * 16 + d
	}
	return v
}

fn (mut p JsonParser) read_string() !string {
	p.pos++
	mut sb := strings.new_builder(16)
	for {
		if p.pos >= p.src.len {
			return p.fail('unterminated string')
		}
		c := p.src[p.pos]
		if c == `"` {
			p.pos++
			break
		}
		if c < 0x20 {
			return p.fail('control character in string')
		}
		if c != `\\` {
			sb.write_u8(c)
			p.pos++
			continue
		}
		p.pos++
		if p.pos >= p.src.len {
			return p.fail('bad escape')
		}
		e := p.src[p.pos]
		p.pos++
		match e {
			`"` {
				sb.write_u8(`"`)
			}
			`\\` {
				sb.write_u8(`\\`)
			}
			`/` {
				sb.write_u8(`/`)
			}
			`b` {
				sb.write_u8(`\b`)
			}
			`f` {
				sb.write_u8(`\f`)
			}
			`n` {
				sb.write_u8(`\n`)
			}
			`r` {
				sb.write_u8(`\r`)
			}
			`t` {
				sb.write_u8(`\t`)
			}
			`u` {
				if p.pos + 4 > p.src.len {
					return p.fail('bad \\u escape')
				}
				mut cp := hex4(p.src[p.pos..p.pos + 4]) or { return p.fail('bad \\u escape') }
				p.pos += 4
				if cp >= 0xd800 && cp < 0xdc00 && p.pos + 6 <= p.src.len && p.src[p.pos] == `\\`
					&& p.src[p.pos + 1] == `u` {
					lo := hex4(p.src[p.pos + 2..p.pos + 6]) or { 0 }
					if lo >= 0xdc00 && lo < 0xe000 {
						cp = 0x10000 + ((cp - 0xd800) << 10) + (lo - 0xdc00)
						p.pos += 6
					}
				}
				if cp >= 0xd800 && cp < 0xe000 {
					cp = 0xfffd
				}
				sb.write_string(utf32_to_str(cp))
			}
			else {
				return p.fail('bad escape')
			}
		}
	}
	return sb.str()
}

fn (mut p JsonParser) number() !json2.Any {
	start := p.pos
	if p.src[p.pos] == `-` {
		p.pos++
	}
	if p.pos >= p.src.len || !p.src[p.pos].is_digit() {
		return p.fail('invalid number')
	}
	if p.src[p.pos] == `0` {
		p.pos++
	} else {
		for p.pos < p.src.len && p.src[p.pos].is_digit() {
			p.pos++
		}
	}
	mut is_float := false
	if p.pos < p.src.len && p.src[p.pos] == `.` {
		is_float = true
		p.pos++
		if p.pos >= p.src.len || !p.src[p.pos].is_digit() {
			return p.fail('invalid number')
		}
		for p.pos < p.src.len && p.src[p.pos].is_digit() {
			p.pos++
		}
	}
	if p.pos < p.src.len && (p.src[p.pos] == `e` || p.src[p.pos] == `E`) {
		is_float = true
		p.pos++
		if p.pos < p.src.len && (p.src[p.pos] == `+` || p.src[p.pos] == `-`) {
			p.pos++
		}
		if p.pos >= p.src.len || !p.src[p.pos].is_digit() {
			return p.fail('invalid number')
		}
		for p.pos < p.src.len && p.src[p.pos].is_digit() {
			p.pos++
		}
	}
	text := p.src[start..p.pos]
	digits := text.trim_left('-').len
	if !is_float && digits <= 18 {
		return json2.Any(text.i64())
	}
	return json2.Any(text.f64())
}

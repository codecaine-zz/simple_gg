module webutils

import json2
import math
import strings
import time

// ============================================================================
// Template expression language (used inside `<%= %>`, `<%- %>` and `<% %>`).
//
// Deliberately NOT a general-purpose language: there is no assignment to
// outer data, no I/O, no host-function calls and no reflection. Templates can
// only read the data they are given and transform it with a fixed set of pure
// built-in filters. That makes server-side template injection (SSTI) and
// "eval"-style RCE impossible by construction.
// ============================================================================

// Template data is `map[string]json2.Any`. Map literals auto-wrap scalars:
// `{'title': 'Home', 'count': 3, 'ok': true}`. Use `to_any(value)` for
// structs, arrays and nested maps of any type.

// null is the template/JSON null value.
pub const null = json2.Any(json2.null)

// to_any converts any JSON-encodable V value (structs, arrays, maps, scalars)
// into a `json2.Any` tree for templates. Field attributes such as `@[json: '-']`
// and `@[json: 'name']` are honoured, so secrets marked `@[json: '-']` never
// reach the template.
pub fn to_any[T](v T) json2.Any {
	$if T is json2.Any {
		return v
	} $else $if T is map[string]json2.Any {
		return json2.Any(v)
	} $else {
		return parse_json(json2.encode(v)) or { null }
	}
}

enum ETokKind {
	ident
	num
	str
	op
	eof
}

struct ETok {
	kind ETokKind
	val  string
}

enum ExprKind {
	lit
	var
	member
	index
	call
	filter
	unary
	binary
	ternary
	list
}

struct Expr {
	kind ExprKind
	name string // var / member field / function / operator
	lit  json2.Any = null
	args []Expr
}

fn is_ident_start(c u8) bool {
	return c.is_letter() || c == `_` || c == `$`
}

fn is_ident_char(c u8) bool {
	return c.is_letter() || c.is_digit() || c == `_` || c == `$`
}

fn lex_expr(src string) ![]ETok {
	mut toks := []ETok{}
	mut i := 0
	for i < src.len {
		c := src[i]
		if c == ` ` || c == `\t` || c == `\n` || c == `\r` {
			i++
			continue
		}
		if is_ident_start(c) {
			start := i
			for i < src.len && is_ident_char(src[i]) {
				i++
			}
			toks << ETok{.ident, src[start..i]}
			continue
		}
		if c.is_digit() {
			start := i
			for i < src.len && src[i].is_digit() {
				i++
			}
			if i + 1 < src.len && src[i] == `.` && src[i + 1].is_digit() {
				i++
				for i < src.len && src[i].is_digit() {
					i++
				}
			}
			toks << ETok{.num, src[start..i]}
			continue
		}
		if c == `'` || c == `"` || c == `\`` {
			mut sb := strings.new_builder(16)
			i++
			mut closed := false
			for i < src.len {
				ch := src[i]
				if ch == c {
					closed = true
					i++
					break
				}
				if ch == `\\` && i + 1 < src.len {
					i++
					match src[i] {
						`n` { sb.write_u8(`\n`) }
						`t` { sb.write_u8(`\t`) }
						`r` { sb.write_u8(`\r`) }
						`0` { sb.write_u8(0) }
						else { sb.write_u8(src[i]) }
					}
					i++
					continue
				}
				sb.write_u8(ch)
				i++
			}
			if !closed {
				return error('unterminated string literal')
			}
			toks << ETok{.str, sb.str()}
			continue
		}
		if i + 3 <= src.len {
			three := src[i..i + 3]
			if three in ['===', '!=='] {
				toks << ETok{.op, three[..2]}
				i += 3
				continue
			}
		}
		if i + 2 <= src.len {
			two := src[i..i + 2]
			if two in ['==', '!=', '<=', '>=', '&&', '||', '??'] {
				toks << ETok{.op, two}
				i += 2
				continue
			}
		}
		if c in [`+`, `-`, `*`, `/`, `%`, `(`, `)`, `[`, `]`, `.`, `,`, `|`, `?`, `:`, `!`, `<`,
			`>`, `=`] {
			toks << ETok{.op, c.ascii_str()}
			i++
			continue
		}
		return error('unexpected character `${c.ascii_str()}` in expression')
	}
	toks << ETok{.eof, ''}
	return toks
}

struct EParser {
	toks []ETok
mut:
	pos int
}

fn (p &EParser) peek() ETok {
	return p.toks[p.pos]
}

fn (mut p EParser) next() ETok {
	t := p.toks[p.pos]
	if p.pos < p.toks.len - 1 {
		p.pos++
	}
	return t
}

fn (p &EParser) is_op(v string) bool {
	t := p.toks[p.pos]
	return t.kind == .op && t.val == v
}

fn (p &EParser) is_kw(v string) bool {
	t := p.toks[p.pos]
	return t.kind == .ident && t.val == v
}

fn (mut p EParser) expect_op(v string) ! {
	if !p.is_op(v) {
		got := p.peek()
		return error('expected `${v}` but found `${if got.kind == .eof {
			'end of expression'
		} else {
			got.val
		}}`')
	}
	p.next()
}

// parse_expression parses a full expression and requires all input consumed.
fn parse_expression(src string) !Expr {
	toks := lex_expr(src)!
	mut p := EParser{
		toks: toks
	}
	e := p.parse_ternary()!
	if p.peek().kind != .eof {
		return error('unexpected `${p.peek().val}` in expression `${src}`')
	}
	return e
}

fn (mut p EParser) parse_ternary() !Expr {
	cond := p.parse_or()!
	if p.is_op('?') {
		p.next()
		a := p.parse_ternary()!
		p.expect_op(':')!
		b := p.parse_ternary()!
		return Expr{
			kind: .ternary
			args: [cond, a, b]
		}
	}
	return cond
}

fn (mut p EParser) parse_or() !Expr {
	mut left := p.parse_and()!
	for p.is_op('||') || p.is_kw('or') || p.is_op('??') {
		op := if p.is_op('??') { '??' } else { '||' }
		p.next()
		right := p.parse_and()!
		left = Expr{
			kind: .binary
			name: op
			args: [left, right]
		}
	}
	return left
}

fn (mut p EParser) parse_and() !Expr {
	mut left := p.parse_not()!
	for p.is_op('&&') || p.is_kw('and') {
		p.next()
		right := p.parse_not()!
		left = Expr{
			kind: .binary
			name: '&&'
			args: [left, right]
		}
	}
	return left
}

fn (mut p EParser) parse_not() !Expr {
	if p.is_op('!') || p.is_kw('not') {
		p.next()
		inner := p.parse_not()!
		return Expr{
			kind: .unary
			name: '!'
			args: [inner]
		}
	}
	return p.parse_cmp()
}

fn (mut p EParser) parse_cmp() !Expr {
	left := p.parse_add()!
	t := p.peek()
	mut op := ''
	if t.kind == .op && t.val in ['==', '!=', '<', '<=', '>', '>='] {
		op = t.val
		p.next()
	} else if p.is_kw('in') {
		op = 'in'
		p.next()
	} else if p.is_kw('not') && p.pos + 1 < p.toks.len && p.toks[p.pos + 1].kind == .ident
		&& p.toks[p.pos + 1].val == 'in' {
		op = 'not in'
		p.next()
		p.next()
	} else {
		return left
	}
	right := p.parse_add()!
	return Expr{
		kind: .binary
		name: op
		args: [left, right]
	}
}

fn (mut p EParser) parse_add() !Expr {
	mut left := p.parse_mul()!
	for p.is_op('+') || p.is_op('-') {
		op := p.next().val
		right := p.parse_mul()!
		left = Expr{
			kind: .binary
			name: op
			args: [left, right]
		}
	}
	return left
}

fn (mut p EParser) parse_mul() !Expr {
	mut left := p.parse_unary()!
	for p.is_op('*') || p.is_op('/') || p.is_op('%') {
		op := p.next().val
		right := p.parse_unary()!
		left = Expr{
			kind: .binary
			name: op
			args: [left, right]
		}
	}
	return left
}

fn (mut p EParser) parse_unary() !Expr {
	if p.is_op('-') {
		p.next()
		inner := p.parse_unary()!
		return Expr{
			kind: .unary
			name: '-'
			args: [inner]
		}
	}
	if p.is_op('+') {
		p.next()
		return p.parse_unary()
	}
	return p.parse_postfix()
}

fn (mut p EParser) parse_args() ![]Expr {
	mut args := []Expr{}
	p.expect_op('(')!
	if p.is_op(')') {
		p.next()
		return args
	}
	for {
		args << p.parse_ternary()!
		if p.is_op(',') {
			p.next()
			continue
		}
		p.expect_op(')')!
		break
	}
	return args
}

fn (mut p EParser) parse_postfix() !Expr {
	mut e := p.parse_primary()!
	for {
		if p.is_op('.') {
			p.next()
			t := p.next()
			if t.kind != .ident {
				return error('expected field name after `.`')
			}
			if p.is_op('(') {
				// method-call sugar: `name.upper()` == `upper(name)`
				mut args := [e]
				args << p.parse_args()!
				e = Expr{
					kind: .call
					name: t.val
					args: args
				}
			} else {
				e = Expr{
					kind: .member
					name: t.val
					args: [e]
				}
			}
		} else if p.is_op('[') {
			p.next()
			idx := p.parse_ternary()!
			p.expect_op(']')!
			e = Expr{
				kind: .index
				args: [e, idx]
			}
		} else if p.is_op('|') {
			// filter: `value | name` or `value | name(arg, ...)`
			p.next()
			t := p.next()
			if t.kind != .ident {
				return error('expected filter name after `|`')
			}
			mut args := [e]
			if p.is_op('(') {
				args << p.parse_args()!
			}
			e = Expr{
				kind: .filter
				name: t.val
				args: args
			}
		} else {
			break
		}
	}
	return e
}

fn (mut p EParser) parse_primary() !Expr {
	t := p.next()
	match t.kind {
		.num {
			if t.val.contains('.') {
				return Expr{
					kind: .lit
					lit:  json2.Any(t.val.f64())
				}
			}
			return Expr{
				kind: .lit
				lit:  json2.Any(t.val.i64())
			}
		}
		.str {
			return Expr{
				kind: .lit
				lit:  json2.Any(t.val)
			}
		}
		.ident {
			match t.val {
				'true' {
					return Expr{
						kind: .lit
						lit:  json2.Any(true)
					}
				}
				'false' {
					return Expr{
						kind: .lit
						lit:  json2.Any(false)
					}
				}
				'null', 'nil', 'none', 'undefined' {
					return Expr{
						kind: .lit
					}
				}
				else {}
			}
			if p.is_op('(') {
				args := p.parse_args()!
				return Expr{
					kind: .call
					name: t.val
					args: args
				}
			}
			return Expr{
				kind: .var
				name: t.val
			}
		}
		.op {
			if t.val == '(' {
				e := p.parse_ternary()!
				p.expect_op(')')!
				return e
			}
			if t.val == '[' {
				mut items := []Expr{}
				if p.is_op(']') {
					p.next()
				} else {
					for {
						items << p.parse_ternary()!
						if p.is_op(',') {
							p.next()
							if p.is_op(']') {
								p.next()
								break
							}
							continue
						}
						p.expect_op(']')!
						break
					}
				}
				return Expr{
					kind: .list
					args: items
				}
			}
			return error('unexpected `${t.val}` in expression')
		}
		.eof {
			return error('unexpected end of expression')
		}
	}
}

// ---------------------------------------------------------------------------
// Value helpers
// ---------------------------------------------------------------------------

fn is_null(v json2.Any) bool {
	return v is json2.Null
}

fn is_intlike(v json2.Any) bool {
	return match v {
		i64, int, i32, i16, i8, u64, u32, u16, u8 { true }
		else { false }
	}
}

fn as_num(v json2.Any) ?f64 {
	return match v {
		f64 { v }
		f32 { f64(v) }
		i64 { f64(v) }
		int { f64(v) }
		i32 { f64(v) }
		i16 { f64(v) }
		i8 { f64(v) }
		u64 { f64(v) }
		u32 { f64(v) }
		u16 { f64(v) }
		u8 { f64(v) }
		bool {
			if v { 1.0 } else { 0.0 }
		}
		else { none }
	}
}

fn as_i64(v json2.Any) ?i64 {
	return match v {
		i64 { v }
		int { i64(v) }
		i32 { i64(v) }
		i16 { i64(v) }
		i8 { i64(v) }
		u64 { i64(v) }
		u32 { i64(v) }
		u16 { i64(v) }
		u8 { i64(v) }
		f64 { i64(v) }
		f32 { i64(v) }
		string { v.trim_space().i64() }
		bool {
			if v { i64(1) } else { i64(0) }
		}
		else { none }
	}
}

fn fmt_num(f f64) string {
	if math.is_nan(f) {
		return 'NaN'
	}
	if math.is_inf(f, 0) {
		return if f > 0 { 'Infinity' } else { '-Infinity' }
	}
	if f == math.floor(f) && math.abs(f) < 1e15 {
		return i64(f).str()
	}
	return f.str()
}

// to_text renders a value as display text (null -> '', arrays comma-joined
// like JavaScript, maps as JSON, integral floats without `.0`).
fn to_text(v json2.Any) string {
	return match v {
		string { v }
		bool { v.str() }
		json2.Null { '' }
		f64 { fmt_num(v) }
		f32 { fmt_num(f64(v)) }
		time.Time { v.format_rfc3339() }
		[]json2.Any { v.map(to_text(it)).join(',') }
		map[string]json2.Any { encode_json(v) }
		else { (as_i64(v) or { 0 }).str() }
	}
}

fn truthy(v json2.Any) bool {
	return match v {
		bool { v }
		string { v.len > 0 }
		json2.Null { false }
		[]json2.Any { v.len > 0 }
		map[string]json2.Any { v.len > 0 }
		time.Time { true }
		else { (as_num(v) or { 0.0 }) != 0.0 }
	}
}

fn values_equal(a json2.Any, b json2.Any) bool {
	if na := as_num(a) {
		if a !is bool {
			if nb := as_num(b) {
				if b !is bool {
					return na == nb
				}
			}
		}
	}
	match a {
		string {
			if b is string {
				return a == b
			}
			return false
		}
		bool {
			if b is bool {
				return a == b
			}
			return false
		}
		json2.Null {
			return b is json2.Null
		}
		else {
			if is_null(b) || b is string || b is bool {
				return false
			}
			return encode_json(a) == encode_json(b)
		}
	}
}

fn compare_values(a json2.Any, b json2.Any) !int {
	if a is string && b is string {
		return if a < b {
			-1
		} else if a > b {
			1
		} else {
			0
		}
	}
	na := as_num(a) or { return error('cannot compare ${type_label(a)} with ${type_label(b)}') }
	nb := as_num(b) or { return error('cannot compare ${type_label(a)} with ${type_label(b)}') }
	return if na < nb {
		-1
	} else if na > nb {
		1
	} else {
		0
	}
}

fn type_label(v json2.Any) string {
	return match v {
		string { 'string' }
		bool { 'bool' }
		json2.Null { 'null' }
		[]json2.Any { 'array' }
		map[string]json2.Any { 'object' }
		time.Time { 'time' }
		else { 'number' }
	}
}

fn num_result(a json2.Any, b json2.Any, f f64) json2.Any {
	if is_intlike(a) && is_intlike(b) && f == math.floor(f) && math.abs(f) < 9e15 {
		return json2.Any(i64(f))
	}
	return json2.Any(f)
}

fn arith(op string, a json2.Any, b json2.Any) !json2.Any {
	if op == '+' {
		if a is string || b is string {
			return json2.Any(to_text(a) + to_text(b))
		}
		if a is []json2.Any && b is []json2.Any {
			mut out := a.clone()
			out << b
			return json2.Any(out)
		}
	}
	x := as_num(a) or { return error('operator `${op}` needs numbers, got ${type_label(a)}') }
	y := as_num(b) or { return error('operator `${op}` needs numbers, got ${type_label(b)}') }
	return match op {
		'+' {
			num_result(a, b, x + y)
		}
		'-' {
			num_result(a, b, x - y)
		}
		'*' {
			num_result(a, b, x * y)
		}
		'/' {
			if y == 0 {
				return error('division by zero')
			}
			num_result(a, b, x / y)
		}
		'%' {
			if y == 0 {
				return error('modulo by zero')
			}
			num_result(a, b, math.fmod(x, y))
		}
		else {
			return error('unknown operator `${op}`')
		}
	}
}

fn contains_value(container json2.Any, item json2.Any) bool {
	return match container {
		string { container.contains(to_text(item)) }
		[]json2.Any { container.any(values_equal(it, item)) }
		map[string]json2.Any { to_text(item) in container }
		else { false }
	}
}

fn get_member(obj json2.Any, name string) json2.Any {
	match obj {
		map[string]json2.Any {
			return obj[name] or { null }
		}
		[]json2.Any {
			if name in ['length', 'len', 'size'] {
				return json2.Any(i64(obj.len))
			}
		}
		string {
			if name in ['length', 'len', 'size'] {
				return json2.Any(i64(obj.runes().len))
			}
		}
		else {}
	}
	return null
}

fn get_index(obj json2.Any, idx json2.Any) json2.Any {
	match obj {
		map[string]json2.Any {
			return obj[to_text(idx)] or { null }
		}
		[]json2.Any {
			mut i := as_i64(idx) or { return null }
			if i < 0 {
				i += obj.len
			}
			if i < 0 || i >= obj.len {
				return null
			}
			return obj[int(i)]
		}
		string {
			r := obj.runes()
			mut i := as_i64(idx) or { return get_member(obj, to_text(idx)) }
			if i < 0 {
				i += r.len
			}
			if i < 0 || i >= r.len {
				return null
			}
			return json2.Any(r[int(i)].str())
		}
		else {
			return null
		}
	}
}

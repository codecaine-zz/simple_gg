module jsonutils

import json2
import strings

pub type Any = json2.Any

// parse decodes any JSON document into a dynamic json2.Any tree.
pub fn parse(src string) !json2.Any {
	return json2.decode[json2.Any](src)!
}

// pretty re-indents a JSON document.
pub fn pretty(src string) !string {
	return json2.encode(parse(src)!, prettify: true)
}

// minify removes all insignificant whitespace from a JSON document.
pub fn minify(src string) !string {
	return encode_canonical(parse(src)!, false)
}

// canonical returns a deterministic encoding with object keys sorted recursively
// (stable for hashing, caching and signature payloads; in the spirit of RFC 8785).
pub fn canonical(src string) !string {
	return encode_canonical(parse(src)!, true)
}

fn as_number(a json2.Any) ?f64 {
	return match a {
		f64 { a }
		f32 { f64(a) }
		i64 { f64(a) }
		int { f64(a) }
		i32 { f64(a) }
		i16 { f64(a) }
		i8 { f64(a) }
		u64 { f64(a) }
		u32 { f64(a) }
		u16 { f64(a) }
		u8 { f64(a) }
		else { none }
	}
}

fn quote(s string) string {
	mut sb := strings.new_builder(s.len + 2)
	sb.write_u8(`"`)
	for c in s {
		match c {
			`"` { sb.write_string('\\"') }
			`\\` { sb.write_string('\\\\') }
			`\n` { sb.write_string('\\n') }
			`\r` { sb.write_string('\\r') }
			`\t` { sb.write_string('\\t') }
			`\b` { sb.write_string('\\b') }
			`\f` { sb.write_string('\\f') }
			else {
				if c < 0x20 {
					sb.write_string('\\u00${c:02x}')
				} else {
					sb.write_u8(c)
				}
			}
		}
	}
	sb.write_u8(`"`)
	return sb.str()
}

// encode_canonical encodes an Any tree compactly; when `sort_keys` is true object
// keys are emitted in byte order.
pub fn encode_canonical(a json2.Any, sort_keys bool) string {
	mut sb := strings.new_builder(64)
	write_any(mut sb, a, sort_keys)
	return sb.str()
}

fn write_any(mut sb strings.Builder, a json2.Any, sort_keys bool) {
	match a {
		json2.Null {
			sb.write_string('null')
		}
		bool {
			sb.write_string(if a { 'true' } else { 'false' })
		}
		string {
			sb.write_string(quote(a))
		}
		[]json2.Any {
			sb.write_u8(`[`)
			for i, v in a {
				if i > 0 {
					sb.write_u8(`,`)
				}
				write_any(mut sb, v, sort_keys)
			}
			sb.write_u8(`]`)
		}
		map[string]json2.Any {
			mut keys := map_keys(a)
			if sort_keys {
				keys.sort()
			}
			sb.write_u8(`{`)
			for i, k in keys {
				if i > 0 {
					sb.write_u8(`,`)
				}
				sb.write_string(quote(k))
				sb.write_u8(`:`)
				write_any(mut sb, a[k] or { json2.Any(json2.null) }, sort_keys)
			}
			sb.write_u8(`}`)
		}
		else {
			if n := as_number(a) {
				if n == f64(i64(n)) && n < 9.007199254740992e15 && n > -9.007199254740992e15 {
					sb.write_string(i64(n).str())
				} else {
					sb.write_string(a.json_str())
				}
			} else {
				sb.write_string(a.json_str())
			}
		}
	}
}

// deep_equal compares two JSON values structurally (numbers compared numerically,
// object key order ignored).
pub fn deep_equal(a json2.Any, b json2.Any) bool {
	if na := as_number(a) {
		nb := as_number(b) or { return false }
		return na == nb
	}
	match a {
		json2.Null {
			return b is json2.Null
		}
		bool {
			return b is bool && b == a
		}
		string {
			return b is string && b == a
		}
		[]json2.Any {
			if b is []json2.Any {
				if a.len != b.len {
					return false
				}
				for i in 0 .. a.len {
					if !deep_equal(a[i], b[i]) {
						return false
					}
				}
				return true
			}
			return false
		}
		map[string]json2.Any {
			if b is map[string]json2.Any {
				if a.len != b.len {
					return false
				}
				for k, v in a {
					bv := b[k] or { return false }
					if !deep_equal(v, bv) {
						return false
					}
				}
				return true
			}
			return false
		}
		else {
			return a.json_str() == b.json_str()
		}
	}
}

// ============================================================================
// RFC 6901 JSON Pointer
// ============================================================================

fn pointer_tokens(ptr string) ![]string {
	if ptr == '' {
		return []
	}
	if !ptr.starts_with('/') {
		return error('JSON pointer must be empty or start with "/": "${ptr}"')
	}
	return ptr[1..].split('/').map(it.replace('~1', '/').replace('~0', '~'))
}

// escape_pointer_token escapes "~" and "/" for use inside a JSON pointer.
pub fn escape_pointer_token(tok string) string {
	return tok.replace('~', '~0').replace('/', '~1')
}

fn array_index(tok string, len int, allow_end bool) !int {
	if tok == '-' && allow_end {
		return len
	}
	if tok == '' || (tok.len > 1 && tok[0] == `0`) || !tok.bytes().all(it.is_digit()) {
		return error('invalid array index "${tok}"')
	}
	i := tok.int()
	if i > len || (i == len && !allow_end) {
		return error('array index ${i} out of range (len ${len})')
	}
	return i
}

// pointer_get resolves an RFC 6901 pointer such as "/users/0/name".
pub fn pointer_get(doc json2.Any, ptr string) !json2.Any {
	mut cur := doc
	for tok in pointer_tokens(ptr)! {
		match cur {
			map[string]json2.Any {
				cur = cur[tok] or { return error('key "${tok}" not found') }
			}
			[]json2.Any {
				cur = cur[array_index(tok, cur.len, false)!]
			}
			else {
				return error('cannot descend into scalar at "${tok}"')
			}
		}
	}
	return cur
}

fn set_in(node json2.Any, toks []string, val json2.Any) !json2.Any {
	if toks.len == 0 {
		return val
	}
	tok := toks[0]
	match node {
		map[string]json2.Any {
			mut m := map[string]json2.Any{}
			for k, v in node {
				m[k] = v
			}
			child := node[tok] or { json2.Any(map[string]json2.Any{}) }
			m[tok] = set_in(child, toks[1..], val)!
			return m
		}
		[]json2.Any {
			idx := array_index(tok, node.len, true)!
			mut arr := []json2.Any{cap: node.len + 1}
			arr << node
			if idx == arr.len {
				if toks.len > 1 {
					return error('cannot descend past array end')
				}
				arr << val
			} else {
				arr[idx] = set_in(arr[idx], toks[1..], val)!
			}
			return arr
		}
		else {
			return error('cannot set "${tok}" inside a scalar')
		}
	}
}

// pointer_set returns a copy of `doc` with the value at `ptr` replaced (missing
// object members are created; "-" appends to arrays).
pub fn pointer_set(doc json2.Any, ptr string, val json2.Any) !json2.Any {
	return set_in(doc, pointer_tokens(ptr)!, val)
}

// ============================================================================
// RFC 7386 JSON Merge Patch
// ============================================================================

// merge_patch applies an RFC 7386 merge patch: objects merge recursively, `null`
// deletes a member, and any non-object patch replaces the target.
pub fn merge_patch(target json2.Any, patch json2.Any) json2.Any {
	if patch is map[string]json2.Any {
		mut out := map[string]json2.Any{}
		if target is map[string]json2.Any {
			for k, v in target {
				out[k] = v
			}
		}
		for k, v in patch {
			if v is json2.Null {
				out.delete(k)
			} else {
				out[k] = merge_patch(out[k] or { json2.Any(json2.null) }, v)
			}
		}
		return out
	}
	return patch
}

// merge_patch_str applies a merge patch to JSON text and returns canonical JSON text.
pub fn merge_patch_str(target string, patch string) !string {
	return encode_canonical(merge_patch(parse(target)!, parse(patch)!), true)
}

// ============================================================================
// Diff & flatten
// ============================================================================

// Change describes one difference between two JSON documents.
pub struct Change {
pub:
	op   string // 'add' | 'remove' | 'replace'
	path string // RFC 6901 pointer
	old  string // canonical JSON of the old value ('' for add)
	new  string // canonical JSON of the new value ('' for remove)
}

// diff lists the differences between two documents as pointer-addressed changes.
pub fn diff(a json2.Any, b json2.Any) []Change {
	mut out := []Change{}
	diff_into(a, b, '', mut out)
	return out
}

fn diff_into(a json2.Any, b json2.Any, path string, mut out []Change) {
	if a is map[string]json2.Any && b is map[string]json2.Any {
		mut keys := map_keys(a)
		for k in map_keys(b) {
			if k !in a {
				keys << k
			}
		}
		keys.sort()
		for k in keys {
			p := '${path}/${escape_pointer_token(k)}'
			if av := a[k] {
				if bv := b[k] {
					diff_into(av, bv, p, mut out)
				} else {
					out << Change{'remove', p, encode_canonical(av, true), ''}
				}
			} else {
				out << Change{'add', p, '', encode_canonical(b[k] or { json2.Any(json2.null) },
					true)}
			}
		}
		return
	}
	if a is []json2.Any && b is []json2.Any {
		n := if a.len > b.len { a.len } else { b.len }
		for i in 0 .. n {
			p := '${path}/${i}'
			if i >= a.len {
				out << Change{'add', p, '', encode_canonical(b[i], true)}
			} else if i >= b.len {
				out << Change{'remove', p, encode_canonical(a[i], true), ''}
			} else {
				diff_into(a[i], b[i], p, mut out)
			}
		}
		return
	}
	if !deep_equal(a, b) {
		out << Change{'replace', path, encode_canonical(a, true), encode_canonical(b, true)}
	}
}

// flatten converts nested JSON into dotted keys, e.g. {"a":{"b":[1]}} -> {"a.b.0": "1"}.
// Scalars are rendered as canonical JSON except strings, which are raw.
pub fn flatten(a json2.Any) map[string]string {
	mut out := map[string]string{}
	flatten_into(a, '', mut out)
	return out
}

fn flatten_into(a json2.Any, prefix string, mut out map[string]string) {
	match a {
		map[string]json2.Any {
			if a.len == 0 && prefix != '' {
				out[prefix] = '{}'
			}
			for k, v in a {
				flatten_into(v, if prefix == '' { k } else { '${prefix}.${k}' }, mut out)
			}
		}
		[]json2.Any {
			if a.len == 0 && prefix != '' {
				out[prefix] = '[]'
			}
			for i, v in a {
				flatten_into(v, if prefix == '' { '${i}' } else { '${prefix}.${i}' }, mut
					out)
			}
		}
		string {
			out[prefix] = a
		}
		else {
			out[prefix] = encode_canonical(a, true)
		}
	}
}

fn map_keys(m map[string]json2.Any) []string {
	mut out := []string{cap: m.len}
	for k, _ in m {
		out << k
	}
	return out
}

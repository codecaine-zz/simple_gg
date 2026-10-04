module templateutils

import strings

// ============================================================================
// 3. Mustache-compatible logic-less templates with HTML auto-escaping
// ============================================================================

// Value is a template data value: strings, numbers, bools, lists and nested objects.
pub type Value = []Value | bool | f64 | int | map[string]Value | string

// str renders a scalar value as text (lists/maps render as '').
pub fn (v Value) str() string {
	return match v {
		string { v }
		int { v.str() }
		f64 { v.str() }
		bool {
			if v { 'true' } else { '' }
		}
		[]Value, map[string]Value { '' }
	}
}

fn truthy(v Value) bool {
	return match v {
		string { v.len > 0 }
		int { v != 0 }
		f64 { v != 0 }
		bool { v }
		[]Value { v.len > 0 }
		map[string]Value { true }
	}
}

enum TokKind {
	text
	var
	raw
	section
	inverted
	close
}

struct Tok {
	kind TokKind
	val  string
}

struct Node {
	kind     TokKind
	val      string
	children []Node
}

// escape_html_text escapes &, <, >, ", ' for safe HTML embedding.
pub fn escape_html_text(s string) string {
	mut sb := strings.new_builder(s.len + 8)
	for c in s {
		match c {
			`&` { sb.write_string('&amp;') }
			`<` { sb.write_string('&lt;') }
			`>` { sb.write_string('&gt;') }
			`"` { sb.write_string('&quot;') }
			`'` { sb.write_string('&#39;') }
			else { sb.write_u8(c) }
		}
	}
	return sb.str()
}

fn tokenize(t string) ![]Tok {
	mut toks := []Tok{}
	mut i := 0
	for i < t.len {
		open := t.index_after('{{', i) or {
			toks << Tok{.text, t[i..]}
			break
		}
		if open > i {
			toks << Tok{.text, t[i..open]}
		}
		if t[open..].starts_with('{{{') {
			close := t.index_after('}}}', open + 3) or { return error('unclosed {{{ at ${open}') }
			toks << Tok{.raw, t[open + 3..close].trim_space()}
			i = close + 3
			continue
		}
		close := t.index_after('}}', open + 2) or { return error('unclosed {{ at ${open}') }
		inner := t[open + 2..close].trim_space()
		i = close + 2
		if inner.len == 0 {
			continue
		}
		match inner[0] {
			`!` {}
			`#` { toks << Tok{.section, inner[1..].trim_space()} }
			`^` { toks << Tok{.inverted, inner[1..].trim_space()} }
			`/` { toks << Tok{.close, inner[1..].trim_space()} }
			`&` { toks << Tok{.raw, inner[1..].trim_space()} }
			else { toks << Tok{.var, inner} }
		}
	}
	return toks
}

struct Parser {
	toks []Tok
mut:
	pos int
}

fn (mut p Parser) build(closing string) ![]Node {
	mut out := []Node{}
	for p.pos < p.toks.len {
		tk := p.toks[p.pos]
		p.pos++
		match tk.kind {
			.close {
				if tk.val != closing {
					return error('unexpected {{/${tk.val}}}, expected {{/${closing}}}')
				}
				return out
			}
			.section, .inverted {
				kids := p.build(tk.val)!
				out << Node{tk.kind, tk.val, kids}
			}
			else {
				out << Node{tk.kind, tk.val, []}
			}
		}
	}
	if closing != '' {
		return error('unclosed section {{#${closing}}}')
	}
	return out
}

fn lookup(stack []Value, name string) ?Value {
	if name == '.' {
		return stack.last()
	}
	parts := name.split('.')
	for i := stack.len - 1; i >= 0; i-- {
		ctx := stack[i]
		if ctx is map[string]Value {
			if parts[0] in ctx {
				mut cur := ctx[parts[0]] or { continue }
				for p in parts[1..] {
					if cur is map[string]Value {
						cur = cur[p] or { return none }
					} else {
						return none
					}
				}
				return cur
			}
		}
	}
	return none
}

fn render_nodes(nodes []Node, mut stack []Value, mut sb strings.Builder, escape bool) {
	for n in nodes {
		match n.kind {
			.text {
				sb.write_string(n.val)
			}
			.var, .raw {
				if v := lookup(stack, n.val) {
					s := v.str()
					sb.write_string(if escape && n.kind == .var { escape_html_text(s) } else { s })
				}
			}
			.section {
				v := lookup(stack, n.val) or { continue }
				if !truthy(v) {
					continue
				}
				if v is []Value {
					for item in v {
						stack << item
						render_nodes(n.children, mut stack, mut sb, escape)
						stack.delete_last()
					}
				} else {
					stack << v
					render_nodes(n.children, mut stack, mut sb, escape)
					stack.delete_last()
				}
			}
			.inverted {
				v := lookup(stack, n.val) or { Value(false) }
				if !truthy(v) {
					render_nodes(n.children, mut stack, mut sb, escape)
				}
			}
			.close {}
		}
	}
}

fn render_impl(template string, data map[string]Value, escape bool) !string {
	mut p := Parser{
		toks: tokenize(template)!
	}
	nodes := p.build('')!
	mut stack := [Value(data)]
	mut sb := strings.new_builder(template.len + 64)
	render_nodes(nodes, mut stack, mut sb, escape)
	return sb.str()
}

// render_mustache renders a Mustache template with HTML auto-escaping of `{{var}}`.
// Supports `{{{raw}}}` / `{{& raw}}`, sections `{{#x}}..{{/x}}` (truthiness, lists
// iterate, objects push context), inverted `{{^x}}..{{/x}}`, comments `{{! ..}}`,
// dotted paths `{{user.name}}` and `{{.}}` for the current item.
pub fn render_mustache(template string, data map[string]Value) !string {
	return render_impl(template, data, true)
}

// render_mustache_text renders like render_mustache but without HTML escaping
// (for plain-text output such as emails, config files or CLI messages).
pub fn render_mustache_text(template string, data map[string]Value) !string {
	return render_impl(template, data, false)
}

// render_template_html is render_template with HTML-escaped substitutions,
// preventing XSS when variables contain user input.
pub fn render_template_html(template string, vars map[string]string) string {
	return render_template_fn(template, fn [vars] (key string) ?string {
		v := vars[key] or { return none }
		return escape_html_text(v)
	})
}

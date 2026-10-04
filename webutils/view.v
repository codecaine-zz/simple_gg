module webutils

import os
import strings
import sync
import json2

// ============================================================================
// EJS-style templates — familiar syntax, secure by default.
//
//   <%= expr %>        output, HTML-escaped (XSS-safe default)
//   <%- expr %>        output raw/unescaped (trusted HTML only, e.g. include)
//   <%# comment %>     comment, produces nothing
//   <%% / %%>          literal `<%` / `%>`
//   <% if cond %> .. <% elif cond %> .. <% else %> .. <% end %>
//   <% for item in items %> .. <% else %> (empty) .. <% end %>
//   <% for i, item in items %>   /   <% for key, value in object %>
//   <% set total = price * qty %>
//   <% include 'partials/nav' %>      or   <%- include('partials/nav') %>
//   <% layout 'layouts/main' %>       (layout prints the page with <%- body %>)
//
// EJS/JavaScript habits also work: `<% if (user) { %> .. <% } else { %> .. <% } %>`,
// `<% for (const item of items) { %> .. <% } %>`, `x === y`, `a || 'default'`,
// `name.toUpperCase()`, `items.length`.
//
// Trim markers: `<%_` strips spaces before the tag, `-%>` removes the newline
// after it, `_%>` removes whitespace and the newline after it. Lines holding
// only a control tag are removed automatically (ViewConfig.trim_blocks).
//
// Filters: `<%= name | upper %>`, `<%= bio | truncate(80) %>`,
// `<%= price | fixed(2) %>`, `<%= when | date('YYYY-MM-DD') %>`.
// ============================================================================

enum SegKind {
	text
	out
	raw
	code
}

struct Seg {
	kind SegKind
	val  string
	line int
}

// find_tag_close finds the `%>` closing a tag, ignoring `%>` inside quotes.
fn find_tag_close(src string, from int) ?int {
	mut i := from
	mut quote := u8(0)
	for i < src.len {
		c := src[i]
		if quote != 0 {
			if c == `\\` {
				i += 2
				continue
			}
			if c == quote {
				quote = 0
			}
		} else if c == `'` || c == `"` || c == `\`` {
			quote = c
		} else if c == `%` && i + 1 < src.len && src[i + 1] == `>` {
			return i
		}
		i++
	}
	// fall back to a plain search (e.g. an unbalanced quote inside a comment)
	return src.index_after('%>', from)
}

fn rest_of_line_blank(src string, from int) ?int {
	mut i := from
	for i < src.len && (src[i] == ` ` || src[i] == `\t`) {
		i++
	}
	if i >= src.len {
		return i
	}
	if src[i] == `\n` {
		return i + 1
	}
	if src[i] == `\r` && i + 1 < src.len && src[i + 1] == `\n` {
		return i + 2
	}
	return none
}

fn trim_tail_blanks(mut buf []u8) {
	for buf.len > 0 && (buf.last() == ` ` || buf.last() == `\t`) {
		buf.delete_last()
	}
}

fn scan_template(src string, trim_blocks bool) ![]Seg {
	mut segs := []Seg{}
	mut buf := []u8{cap: 256}
	mut buf_line := 1
	mut line := 1
	mut line_clean := true
	mut i := 0
	for i < src.len {
		open := src.index_after('<%', i) or { -1 }
		end := if open < 0 { src.len } else { open }
		for k in i .. end {
			c := src[k]
			if buf.len == 0 {
				buf_line = line
			}
			buf << c
			if c == `\n` {
				line++
				line_clean = true
			} else if c != ` ` && c != `\t` && c != `\r` {
				line_clean = false
			}
		}
		if open < 0 {
			break
		}
		if open + 2 < src.len && src[open + 2] == `%` {
			// `<%%` -> literal `<%`
			buf << `<`
			buf << `%`
			line_clean = false
			i = open + 3
			continue
		}
		mut j := open + 2
		mut kind := SegKind.code
		mut comment := false
		mut lstrip := false
		if j < src.len {
			match src[j] {
				`=` {
					kind = .out
					j++
				}
				`-` {
					kind = .raw
					j++
				}
				`#` {
					comment = true
					j++
				}
				`_` {
					lstrip = true
					j++
				}
				else {}
			}
		}
		close := find_tag_close(src, j) or {
			return error('line ${line}: unclosed tag `<%` (missing `%>`)')
		}
		mut inner := src[j..close]
		tag_line := line
		for c in src[open..close + 2] {
			if c == `\n` {
				line++
			}
		}
		mut after := close + 2
		mut nl_trim := false
		mut slurp := false
		if inner.ends_with('-') {
			nl_trim = true
			inner = inner[..inner.len - 1]
		} else if inner.ends_with('_') {
			slurp = true
			inner = inner[..inner.len - 1]
		}
		if lstrip {
			trim_tail_blanks(mut buf)
		}
		is_block := kind == .code || comment
		if trim_blocks && is_block && line_clean {
			if next := rest_of_line_blank(src, after) {
				trim_tail_blanks(mut buf)
				if next > after && src[next - 1] == `\n` {
					line++
				}
				after = next
			}
		}
		if after == close + 2 {
			if slurp {
				for after < src.len && (src[after] == ` ` || src[after] == `\t`) {
					after++
				}
			}
			if nl_trim || slurp {
				if after < src.len && src[after] == `\n` {
					after++
					line++
				} else if after + 1 < src.len && src[after] == `\r` && src[after + 1] == `\n` {
					after += 2
					line++
				}
			}
		}
		if buf.len > 0 {
			segs << Seg{.text, buf.bytestr(), buf_line}
			buf.clear()
		}
		if !comment {
			segs << Seg{kind, inner.trim_space(), tag_line}
		}
		if !is_block {
			line_clean = false
		}
		i = after
	}
	if buf.len > 0 {
		segs << Seg{.text, buf.bytestr(), buf_line}
	}
	return segs
}

enum NodeKind {
	text
	out
	raw_out
	if_block
	for_block
	include
	set
	layout
}

struct TBranch {
	cond Expr
	body []TNode
}

struct TNode {
	kind      NodeKind
	text      string
	expr      Expr
	names     []string
	branches  []TBranch
	body      []TNode
	else_body []TNode
	line      int
}

struct Stmt {
	kind  string
	expr  Expr
	names []string
	line  int
}

fn strip_paren_arg(s string) string {
	t := s.trim_space()
	if t.starts_with('(') && t.ends_with(')') {
		return t[1..t.len - 1].trim_space()
	}
	return t
}

fn starts_kw(s string, kw string) bool {
	return s == kw || (s.starts_with(kw) && s.len > kw.len && !is_ident_char(s[kw.len]))
}

fn parse_stmt(raw string, line int) !Stmt {
	mut s := raw.trim_space()
	if s.ends_with('{') {
		s = s[..s.len - 1].trim_space()
	}
	if s.ends_with(';') {
		s = s[..s.len - 1].trim_space()
	}
	mut closes := false
	if s.starts_with('}') {
		closes = true
		s = s[1..].trim_space()
	}
	if s == '' {
		if closes {
			return Stmt{
				kind: 'end'
				line: line
			}
		}
		return Stmt{
			kind: 'noop'
			line: line
		}
	}
	if s in ['end', 'endif', 'endfor', 'endeach', '/if', '/for'] {
		return Stmt{
			kind: 'end'
			line: line
		}
	}
	if s == 'else' {
		return Stmt{
			kind: 'else'
			line: line
		}
	}
	for kw in ['elif', 'elseif', 'else if'] {
		if starts_kw(s, kw) {
			return Stmt{
				kind: 'elif'
				expr: parse_expression(s[kw.len..])!
				line: line
			}
		}
	}
	if closes {
		return error('unexpected `${s}` after `}`')
	}
	if starts_kw(s, 'if') {
		return Stmt{
			kind: 'if'
			expr: parse_expression(s[2..])!
			line: line
		}
	}
	if starts_kw(s, 'for') || starts_kw(s, 'each') {
		mut body := strip_paren_arg(s[if s.starts_with('for') { 3 } else { 4 }..])
		for decl in ['const ', 'let ', 'var '] {
			if body.starts_with(decl) {
				body = body[decl.len..].trim_space()
			}
		}
		mut sep := body.index(' in ') or { -1 }
		mut sep_len := 4
		of := body.index(' of ') or { -1 }
		if sep < 0 || (of >= 0 && of < sep) {
			sep = of
		}
		if sep < 0 {
			return error('expected `for item in list`')
		}
		mut names := body[..sep].split(',').map(it.trim_space())
		if names.len > 0 && names[0].starts_with('[') && names.last().ends_with(']') {
			names[0] = names[0][1..]
			names[names.len - 1] = names.last()[..names.last().len - 1]
			names = names.map(it.trim_space())
		}
		if names.len < 1 || names.len > 2 || names.any(it == '' || !is_ident_start(it[0])) {
			return error('invalid loop variable(s) `${body[..sep]}`')
		}
		return Stmt{
			kind:  'for'
			names: names
			expr:  parse_expression(body[sep + sep_len..])!
			line:  line
		}
	}
	for kw in ['set', 'let', 'const', 'var'] {
		if starts_kw(s, kw) {
			rest := s[kw.len..].trim_space()
			eq := rest.index('=') or { return error('expected `${kw} name = value`') }
			name := rest[..eq].trim_space()
			if name == '' || !is_ident_start(name[0]) || name.bytes().any(!is_ident_char(it)) {
				return error('invalid variable name `${name}`')
			}
			return Stmt{
				kind:  'set'
				names: [name]
				expr:  parse_expression(rest[eq + 1..])!
				line:  line
			}
		}
	}
	for kw in ['include', 'layout'] {
		if starts_kw(s, kw) {
			return Stmt{
				kind: kw
				expr: parse_expression(strip_paren_arg(s[kw.len..]))!
				line: line
			}
		}
	}
	return error('unsupported statement `${s}` (templates allow if/elif/else/for/set/include/layout/end only)')
}

struct TParser {
	segs []Seg
mut:
	pos int
}

fn (mut tp TParser) parse_block(stops []string, opener string, open_line int) !([]TNode, Stmt) {
	mut nodes := []TNode{}
	for tp.pos < tp.segs.len {
		seg := tp.segs[tp.pos]
		tp.pos++
		match seg.kind {
			.text {
				nodes << TNode{
					kind: .text
					text: seg.val
					line: seg.line
				}
			}
			.out, .raw {
				e := parse_expression(seg.val) or { return error('line ${seg.line}: ${err.msg()}') }
				nodes << TNode{
					kind: if seg.kind == .out { NodeKind.out } else { NodeKind.raw_out }
					expr: e
					line: seg.line
				}
			}
			.code {
				st := parse_stmt(seg.val, seg.line) or {
					return error('line ${seg.line}: ${err.msg()}')
				}
				match st.kind {
					'noop' {}
					'end', 'else', 'elif' {
						if st.kind in stops {
							return nodes, st
						}
						return error('line ${seg.line}: unexpected `${st.kind}`')
					}
					'if' {
						mut branches := []TBranch{}
						mut cond := st.expr
						mut else_body := []TNode{}
						for {
							body, stop := tp.parse_block(['elif', 'else', 'end'], 'if', st.line)!
							branches << TBranch{cond, body}
							if stop.kind == 'elif' {
								cond = stop.expr
								continue
							}
							if stop.kind == 'else' {
								mut eb, _ := tp.parse_block(['end'], 'if', st.line)!
								else_body = eb.clone()
							}
							break
						}
						nodes << TNode{
							kind:      .if_block
							branches:  branches
							else_body: else_body
							line:      st.line
						}
					}
					'for' {
						body, stop := tp.parse_block(['else', 'end'], 'for', st.line)!
						mut else_body := []TNode{}
						if stop.kind == 'else' {
							mut eb, _ := tp.parse_block(['end'], 'for', st.line)!
							else_body = eb.clone()
						}
						nodes << TNode{
							kind:      .for_block
							names:     st.names
							expr:      st.expr
							body:      body
							else_body: else_body
							line:      st.line
						}
					}
					'set' {
						nodes << TNode{
							kind:  .set
							names: st.names
							expr:  st.expr
							line:  st.line
						}
					}
					'include' {
						nodes << TNode{
							kind: .include
							expr: st.expr
							line: st.line
						}
					}
					'layout' {
						nodes << TNode{
							kind: .layout
							expr: st.expr
							line: st.line
						}
					}
					else {}
				}
			}
		}
	}
	if stops.len > 0 {
		return error('line ${open_line}: `${opener}` block is never closed (missing `<% end %>`)')
	}
	return nodes, Stmt{}
}

// Template is a compiled, immutable, thread-safe template.
@[heap]
pub struct Template {
pub:
	name string
mut:
	nodes []TNode
}

@[params]
pub struct CompileOptions {
pub:
	name        string = 'inline'
	trim_blocks bool   = true
}

// compile parses a template once; the result can be rendered many times,
// concurrently, with different data.
pub fn compile(src string, opts CompileOptions) !&Template {
	segs := scan_template(src, opts.trim_blocks) or {
		return error('template "${opts.name}" ${err.msg()}')
	}
	mut tp := TParser{
		segs: segs
	}
	nodes, _ := tp.parse_block([], '', 0) or { return error('template "${opts.name}" ${err.msg()}') }
	return &Template{
		name:  opts.name
		nodes: nodes
	}
}

// render renders a compiled template that does not use include/layout.
// Use Views.render for templates that include partials.
pub fn (t &Template) render(data map[string]json2.Any) !string {
	mut r := new_renderer(unsafe { nil }, false, 32 * 1024 * 1024, 32)
	return r.run(t, data)
}

// render_string compiles and renders a template in one call (HTML-escaped
// `<%= %>` output). For repeated rendering prefer `compile` or `Views`.
pub fn render_string(src string, data map[string]json2.Any) !string {
	t := compile(src)!
	return t.render(data)
}

struct Renderer {
mut:
	views      &Views = unsafe { nil }
	sb         strings.Builder
	scope      []map[string]json2.Any
	depth      int
	max_depth  int
	layout     string
	strict     bool
	max_output int
	tname      string
}

fn new_renderer(views &Views, strict bool, max_output int, max_depth int) Renderer {
	return Renderer{
		views:      views
		sb:         strings.new_builder(4096)
		strict:     strict
		max_output: max_output
		max_depth:  max_depth
	}
}

fn (mut r Renderer) run(t &Template, data map[string]json2.Any) !string {
	r.scope = [data, map[string]json2.Any{}]
	r.tname = t.name
	r.render_nodes(t.nodes)!
	mut hops := 0
	for r.layout != '' {
		hops++
		if hops > 8 {
			return error('template "${t.name}": too many nested layouts')
		}
		if isnil(r.views) {
			return error('template "${t.name}": layout requires a Views loader')
		}
		lname := r.layout
		r.layout = ''
		lt := r.views.load(lname)!
		body := r.sb.str()
		r.sb = strings.new_builder(body.len + 4096)
		r.scope << {
			'body': json2.Any(body)
		}
		r.tname = lt.name
		r.render_nodes(lt.nodes)!
	}
	return r.sb.str()
}

fn (r &Renderer) lookup(name string) !json2.Any {
	for i := r.scope.len - 1; i >= 0; i-- {
		if v := r.scope[i][name] {
			return v
		}
	}
	if r.strict {
		return error('undefined variable `${name}`')
	}
	return null
}

fn (mut r Renderer) fail(line int, msg string) IError {
	return error('template "${r.tname}" line ${line}: ${msg}')
}

fn (mut r Renderer) write(s string) ! {
	r.sb.write_string(s)
	if r.sb.len > r.max_output {
		return error('template output exceeds ${r.max_output} bytes')
	}
}

fn (mut r Renderer) include(name string) ! {
	if isnil(r.views) {
		return error('include("${name}") requires a Views loader')
	}
	if r.depth >= r.max_depth {
		return error('include depth limit (${r.max_depth}) exceeded — recursive include?')
	}
	t := r.views.load(name)!
	saved := r.tname
	r.tname = t.name
	r.depth++
	r.render_nodes(t.nodes)!
	r.depth--
	r.tname = saved
}

fn (mut r Renderer) eval(e Expr) !json2.Any {
	match e.kind {
		.lit {
			return e.lit
		}
		.var {
			return r.lookup(e.name)!
		}
		.member {
			obj := r.eval(e.args[0])!
			return get_member(obj, e.name)
		}
		.index {
			obj := r.eval(e.args[0])!
			idx := r.eval(e.args[1])!
			return get_index(obj, idx)
		}
		.call, .filter {
			if e.name == 'include' && e.kind == .call {
				name := to_text(r.eval(e.args[0] or { return error('include needs a name') })!)
				saved := r.sb
				r.sb = strings.new_builder(1024)
				r.include(name)!
				out := r.sb.str()
				r.sb = saved
				return json2.Any(out)
			}
			mut args := []json2.Any{cap: e.args.len}
			for a in e.args {
				args << r.eval(a)!
			}
			return call_builtin(e.name, args)!
		}
		.unary {
			v := r.eval(e.args[0])!
			if e.name == '!' {
				res := !truthy(v)
				return json2.Any(res)
			}
			if is_intlike(v) {
				iv := as_i64(v) or { 0 }
				neg_iv := -iv
				return json2.Any(neg_iv)
			}
			n := as_num(v) or { return error('cannot negate ${type_label(v)}') }
			neg_n := -n
			return json2.Any(neg_n)
		}
		.binary {
			match e.name {
				'&&' {
					l := r.eval(e.args[0])!
					return if truthy(l) { r.eval(e.args[1])! } else { l }
				}
				'||' {
					l := r.eval(e.args[0])!
					return if truthy(l) { l } else { r.eval(e.args[1])! }
				}
				'??' {
					l := r.eval(e.args[0])!
					return if is_null(l) { r.eval(e.args[1])! } else { l }
				}
				else {}
			}
			a := r.eval(e.args[0])!
			b := r.eval(e.args[1])!
			match e.name {
				'==' {
					eq := values_equal(a, b)
					return json2.Any(eq)
				}
				'!=' {
					neq := !values_equal(a, b)
					return json2.Any(neq)
				}
				'<' {
					lt := compare_values(a, b)! < 0
					return json2.Any(lt)
				}
				'<=' {
					lte := compare_values(a, b)! <= 0
					return json2.Any(lte)
				}
				'>' {
					gt := compare_values(a, b)! > 0
					return json2.Any(gt)
				}
				'>=' {
					gte := compare_values(a, b)! >= 0
					return json2.Any(gte)
				}
				'in' {
					has := contains_value(b, a)
					return json2.Any(has)
				}
				'not in' {
					not_has := !contains_value(b, a)
					return json2.Any(not_has)
				}
				else {
					return arith(e.name, a, b)!
				}
			}
		}
		.ternary {
			c := r.eval(e.args[0])!
			return if truthy(c) { r.eval(e.args[1])! } else { r.eval(e.args[2])! }
		}
		.list {
			mut out := []json2.Any{cap: e.args.len}
			for a in e.args {
				out << r.eval(a)!
			}
			return json2.Any(out)
		}
	}
}

fn is_safe_output(e Expr) bool {
	return (e.kind == .filter && e.name in safe_filters) || (e.kind == .call && e.name == 'include')
}

fn (mut r Renderer) render_loop_item(n TNode, key json2.Any, item json2.Any, i int, total int) ! {
	mut frame := map[string]json2.Any{}
	if n.names.len == 2 {
		frame[n.names[0]] = key
		frame[n.names[1]] = item
	} else {
		frame[n.names[0]] = item
	}
	frame['loop'] = json2.Any({
		'index':  json2.Any(i64(i + 1))
		'index0': json2.Any(i64(i))
		'first':  json2.Any(i == 0)
		'last':   json2.Any(i == total - 1)
		'length': json2.Any(i64(total))
	})
	r.scope << frame
	r.render_nodes(n.body)!
	r.scope.delete_last()
}

fn (mut r Renderer) render_nodes(nodes []TNode) ! {
	for n in nodes {
		match n.kind {
			.text {
				r.write(n.text)!
			}
			.out, .raw_out {
				v := r.eval(n.expr) or { return r.fail(n.line, err.msg()) }
				s := to_text(v)
				if n.kind == .out && !is_safe_output(n.expr) {
					r.write(escape_html(s))!
				} else {
					r.write(s)!
				}
			}
			.if_block {
				mut done := false
				for b in n.branches {
					c := r.eval(b.cond) or { return r.fail(n.line, err.msg()) }
					if truthy(c) {
						r.render_nodes(b.body)!
						done = true
						break
					}
				}
				if !done {
					r.render_nodes(n.else_body)!
				}
			}
			.for_block {
				iter := r.eval(n.expr) or { return r.fail(n.line, err.msg()) }
				mut count := 0
				match iter {
					[]json2.Any {
						for i, item in iter {
							r.render_loop_item(n, json2.Any(i64(i)), item, i, iter.len)!
						}
						count = iter.len
					}
					map[string]json2.Any {
						mut i := 0
						for k, v in iter {
							if n.names.len == 2 {
								r.render_loop_item(n, json2.Any(k), v, i, iter.len)!
							} else {
								r.render_loop_item(n, json2.Any(k), json2.Any(k), i, iter.len)!
							}
							i++
						}
						count = iter.len
					}
					string {
						chars := iter.runes()
						for i, ch in chars {
							r.render_loop_item(n, json2.Any(i64(i)), json2.Any(ch.str()), i, chars.len)!
						}
						count = chars.len
					}
					json2.Null {}
					else {
						return r.fail(n.line, 'cannot loop over ${type_label(iter)} (use range(n) for numbers)')
					}
				}
				if count == 0 {
					r.render_nodes(n.else_body)!
				}
			}
			.set {
				v := r.eval(n.expr) or { return r.fail(n.line, err.msg()) }
				r.scope[r.scope.len - 1][n.names[0]] = v
			}
			.include {
				name := to_text(r.eval(n.expr) or { return r.fail(n.line, err.msg()) })
				r.include(name) or { return r.fail(n.line, err.msg()) }
			}
			.layout {
				if r.depth == 0 {
					r.layout = to_text(r.eval(n.expr) or { return r.fail(n.line, err.msg()) })
				}
			}
		}
	}
}

// ---------------------------------------------------------------------------
// Views: a cached, thread-safe template loader rooted at a directory
// ---------------------------------------------------------------------------

@[params]
pub struct ViewConfig {
pub:
	root        string = 'views' // directory holding templates; includes can never escape it
	ext         string = '.html' // default extension (`render('index')` loads `index.html`)
	cache       bool   = true  // cache compiled templates (disable during development for live reload)
	strict      bool // error on undefined variables instead of rendering ''
	trim_blocks bool = true             // drop lines that contain only a control tag
	max_depth   int  = 32               // include nesting limit (stops recursive includes)
	max_output  int  = 32 * 1024 * 1024 // output size limit per render
}

// Views loads, compiles and caches templates. Safe for concurrent use.
@[heap]
pub struct Views {
pub:
	cfg ViewConfig
mut:
	mu      &sync.RwMutex = sync.new_rwmutex()
	cache   map[string]&Template
	sources map[string]string
}

// new_views creates a template loader, e.g. `new_views(root: 'views')`.
pub fn new_views(cfg ViewConfig) &Views {
	return &Views{
		cfg: cfg
	}
}

fn validate_view_name(name string) ! {
	if name.len == 0 || name.len > 1024 {
		return error('invalid template name')
	}
	if name.contains('\0') || name.contains('\\') || name.starts_with('/')
		|| (name.len > 1 && name[1] == `:`) {
		return error('invalid template name "${name}"')
	}
	for seg in name.split('/') {
		if seg == '..' {
			return error('template name "${name}" may not contain `..`')
		}
	}
}

fn (v &Views) normalize(name string) !string {
	validate_view_name(name)!
	mut n := name
	for n.starts_with('./') {
		n = n[2..]
	}
	if v.cfg.ext != '' && n.ends_with(v.cfg.ext) {
		n = n[..n.len - v.cfg.ext.len]
	}
	return n
}

// add registers an in-memory template (great for tests and for single-binary
// deploys with `$embed_file`). In-memory templates take precedence over disk.
pub fn (mut v Views) add(name string, src string) ! {
	key := v.normalize(name)!
	t := compile(src, name: key, trim_blocks: v.cfg.trim_blocks)!
	v.mu.lock()
	v.sources[key] = src
	v.cache[key] = t
	v.mu.unlock()
}

// clear_cache drops compiled disk templates so they are re-read on next use.
pub fn (mut v Views) clear_cache() {
	v.mu.lock()
	v.cache = map[string]&Template{}
	v.mu.unlock()
}

fn (v &Views) disk_path(key string) !string {
	root := v.cfg.root
	mut candidates := []string{}
	last := key.all_after_last('/')
	if last.contains('.') {
		candidates << key
	}
	candidates << key + v.cfg.ext
	real_root := os.real_path(root)
	for c in candidates {
		p := os.join_path(root, c)
		if !os.is_file(p) {
			continue
		}
		real := os.real_path(p)
		if real != real_root && !real.starts_with(real_root + os.path_separator) {
			return error('template "${key}" resolves outside the views directory')
		}
		return real
	}
	return error('template "${key}" not found in "${root}"')
}

// load returns the compiled template `name` (cached when ViewConfig.cache).
pub fn (mut v Views) load(name string) !&Template {
	key := v.normalize(name)!
	v.mu.rlock()
	if t := v.cache[key] {
		v.mu.runlock()
		return t
	}
	src_mem := v.sources[key] or { '' }
	has_mem := key in v.sources
	v.mu.runlock()
	src := if has_mem { src_mem } else { os.read_file(v.disk_path(key)!)! }
	t := compile(src, name: key, trim_blocks: v.cfg.trim_blocks)!
	if v.cfg.cache || has_mem {
		v.mu.lock()
		v.cache[key] = t
		v.mu.unlock()
	}
	return t
}

// render renders template `name` with `data`. Supports include and layout.
pub fn (mut v Views) render(name string, data map[string]json2.Any) !string {
	t := v.load(name)!
	mut r := new_renderer(v, v.cfg.strict, v.cfg.max_output, v.cfg.max_depth)
	return r.run(t, data)
}

// render_string renders template source that may include/layout templates
// from this loader.
pub fn (mut v Views) render_string(src string, data map[string]json2.Any) !string {
	t := compile(src, trim_blocks: v.cfg.trim_blocks)!
	mut r := new_renderer(v, v.cfg.strict, v.cfg.max_output, v.cfg.max_depth)
	return r.run(t, data)
}

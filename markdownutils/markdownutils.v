module markdownutils

import strings

// Options controls Markdown rendering.
@[params]
pub struct Options {
pub:
	heading_ids bool = true // add id="slug" to headings (for anchors / TOC)
	safe_links  bool = true // drop javascript:/data:/vbscript: URLs
	raw_html    bool // pass inline HTML through untouched (UNSAFE for user content)
}

// Heading is an entry in a document outline.
pub struct Heading {
pub:
	level int
	text  string
	id    string
}

fn esc(s string) string {
	mut sb := strings.new_builder(s.len + 8)
	for c in s {
		match c {
			`&` { sb.write_string('&amp;') }
			`<` { sb.write_string('&lt;') }
			`>` { sb.write_string('&gt;') }
			`"` { sb.write_string('&quot;') }
			else { sb.write_u8(c) }
		}
	}
	return sb.str()
}

// slug converts heading text to a GitHub-style anchor id.
pub fn slug(text string) string {
	mut sb := strings.new_builder(text.len)
	for r in text.to_lower().runes() {
		if (r >= `a` && r <= `z`) || (r >= `0` && r <= `9`) || r == `-` || r == `_` || r > 127 {
			sb.write_rune(r)
		} else if r == ` ` {
			sb.write_u8(`-`)
		}
	}
	return sb.str()
}

fn safe_url(u string, opts Options) string {
	if !opts.safe_links {
		return u
	}
	l := u.trim_space().to_lower()
	for bad in ['javascript:', 'vbscript:', 'data:', 'file:'] {
		if l.starts_with(bad) {
			return '#'
		}
	}
	return u.trim_space()
}

// ============================================================================
// Inline parsing
// ============================================================================

fn find_closing(s string, from int, delim string) int {
	mut i := from
	for i <= s.len - delim.len {
		if s[i] == `\\` {
			i += 2
			continue
		}
		if s[i..].starts_with(delim) {
			return i
		}
		i++
	}
	return -1
}

// find_link_end finds the ')' closing a link destination, honoring nested parentheses
// (CommonMark allows balanced parens, e.g. https://en.wikipedia.org/wiki/V_(language)).
fn find_link_end(s string, from int) int {
	mut depth := 0
	mut i := from
	for i < s.len {
		match s[i] {
			`\\` {
				i++
			}
			`(` {
				depth++
			}
			`)` {
				if depth == 0 {
					return i
				}
				depth--
			}
			`\n` {
				return -1
			}
			else {}
		}

		i++
	}
	return -1
}

// inline renders inline Markdown (emphasis, code, links, images, autolinks, breaks).
pub fn inline(s string, opts Options) string {
	mut sb := strings.new_builder(s.len + 16)
	mut i := 0
	for i < s.len {
		c := s[i]
		// Backslash escapes
		if c == `\\` && i + 1 < s.len && '\\`*_{}[]()#+-.!~|<>'.contains_u8(s[i + 1]) {
			sb.write_string(esc(s[i + 1].ascii_str()))
			i += 2
			continue
		}
		// Hard line break: two+ spaces or backslash before newline
		if c == `\n` {
			if sb.len >= 2 && s[i - 1] == ` ` && i >= 2 && s[i - 2] == ` ` {
				sb.write_string('<br>\n')
			} else {
				sb.write_u8(`\n`)
			}
			i++
			continue
		}
		// Code span
		if c == `\`` {
			mut n := 0
			for i + n < s.len && s[i + n] == `\`` {
				n++
			}
			ticks := '`'.repeat(n)
			end := s.index_after(ticks, i + n) or { -1 }
			if end > 0 {
				sb.write_string('<code>${esc(s[i + n..end].trim_space())}</code>')
				i = end + n
				continue
			}
			sb.write_string(ticks)
			i += n
			continue
		}
		// Image / link
		if (c == `!` && i + 1 < s.len && s[i + 1] == `[`) || c == `[` {
			is_img := c == `!`
			start := if is_img { i + 2 } else { i + 1 }
			close := find_closing(s, start, ']')
			if close > 0 && close + 1 < s.len && s[close + 1] == `(` {
				pend := find_link_end(s, close + 2)
				if pend > 0 {
					mut target := s[close + 2..pend].trim_space()
					mut title := ''
					if sp := target.index(' "') {
						if target.ends_with('"') {
							title = target[sp + 2..target.len - 1]
							target = target[..sp]
						}
					}
					target = target.trim('<>')
					label := s[start..close]
					url := esc(safe_url(target, opts))
					t := if title != '' { ' title="${esc(title)}"' } else { '' }
					if is_img {
						sb.write_string('<img src="${url}" alt="${esc(label)}"${t}>')
					} else {
						sb.write_string('<a href="${url}"${t}>${inline(label, opts)}</a>')
					}
					i = pend + 1
					continue
				}
			}
		}
		// Autolink <https://...> or raw HTML
		if c == `<` {
			gt := s.index_after('>', i) or { -1 }
			if gt > 0 {
				inner := s[i + 1..gt]
				if (inner.starts_with('http://') || inner.starts_with('https://'))
					&& !inner.contains(' ') {
					sb.write_string('<a href="${esc(inner)}">${esc(inner)}</a>')
					i = gt + 1
					continue
				}
				if inner.contains('@') && !inner.contains(' ') && !inner.contains(':') {
					sb.write_string('<a href="mailto:${esc(inner)}">${esc(inner)}</a>')
					i = gt + 1
					continue
				}
				if opts.raw_html {
					sb.write_string(s[i..gt + 1])
					i = gt + 1
					continue
				}
			}
		}
		// Strong / emphasis / strikethrough
		for d in ['**', '__', '~~', '*', '_'] {
			if s[i..].starts_with(d) && i + d.len < s.len && s[i + d.len] != ` ` {
				// Intraword underscores are literal (snake_case_words).
				if d[0] == `_` && i > 0 && s[i - 1].is_alnum() {
					break
				}
				end := find_closing(s, i + d.len, d)
				if end > i + d.len && s[end - 1] != ` ` {
					tag := match d {
						'**', '__' { 'strong' }
						'~~' { 'del' }
						else { 'em' }
					}

					sb.write_string('<${tag}>${inline(s[i + d.len..end], opts)}</${tag}>')
					i = end + d.len
					unsafe {
						goto next
					}
				}
			}
		}
		match c {
			`&` { sb.write_string('&amp;') }
			`<` { sb.write_string('&lt;') }
			`>` { sb.write_string('&gt;') }
			`"` { sb.write_string('&quot;') }
			else { sb.write_u8(c) }
		}

		i++
		next:
	}
	return sb.str()
}

// ============================================================================
// Block parsing
// ============================================================================

fn is_hr(t string) bool {
	s := t.replace(' ', '')
	if s.len < 3 {
		return false
	}
	ch := s[0]
	return (ch == `-` || ch == `*` || ch == `_`) && s.bytes().all(it == ch)
}

fn heading_of(line string) ?(int, string) {
	mut n := 0
	for n < line.len && n < 7 && line[n] == `#` {
		n++
	}
	if n == 0 || n > 6 || (n < line.len && line[n] != ` `) {
		return none
	}
	mut text := line[n..].trim_space()
	// Strip optional closing #s
	text = text.trim_right('#').trim_space()
	return n, text
}

fn list_marker(line string) ?(bool, string) {
	t := line.trim_left(' ')
	if t.len >= 2 && (t[0] == `-` || t[0] == `*` || t[0] == `+`) && t[1] == ` ` {
		return false, t[2..]
	}
	mut j := 0
	for j < t.len && t[j].is_digit() {
		j++
	}
	if j > 0 && j < 10 && j + 1 < t.len && (t[j] == `.` || t[j] == `)`) && t[j + 1] == ` ` {
		return true, t[j + 2..]
	}
	return none
}

fn is_table_sep(line string) bool {
	t := line.trim_space()
	if !t.contains('-') || (!t.contains('|') && !t.starts_with(':') && !t.starts_with('-')) {
		return false
	}
	return t.bytes().all(it in [`|`, `-`, `:`, ` `])
}

fn has_list_marker(line string) bool {
	if _, _ := list_marker(line) {
		return true
	}
	return false
}

fn split_row(line string) []string {
	mut t := line.trim_space()
	if t.starts_with('|') {
		t = t[1..]
	}
	if t.ends_with('|') && !t.ends_with('\\|') {
		t = t[..t.len - 1]
	}
	return t.split('|').map(it.trim_space())
}

// to_html converts Markdown (CommonMark/GFM subset) to HTML. Text is always escaped,
// and unsafe link schemes are neutralized unless disabled in `opts`.
pub fn to_html(md string, opts Options) string {
	lines := md.replace('\r\n', '\n').replace('\t', '    ').split('\n')
	mut sb := strings.new_builder(md.len * 2)
	mut ids := map[string]int{}
	render_blocks(lines, opts, mut sb, mut ids)
	return sb.str().trim_right('\n')
}

fn unique_id(base string, mut ids map[string]int) string {
	n := ids[base] or { 0 }
	ids[base] = n + 1
	return if n == 0 { base } else { '${base}-${n}' }
}

fn render_blocks(lines []string, opts Options, mut sb strings.Builder, mut ids map[string]int) {
	mut i := 0
	for i < lines.len {
		line := lines[i]
		t := line.trim_space()
		if t == '' {
			i++
			continue
		}
		// Fenced code
		if t.starts_with('```') || t.starts_with('~~~') {
			fence := t[..3]
			lang := t[3..].trim_space().all_before(' ')
			mut body := []string{}
			i++
			for i < lines.len && !lines[i].trim_space().starts_with(fence) {
				body << lines[i]
				i++
			}
			i++
			cls := if lang != '' { ' class="language-${esc(lang)}"' } else { '' }
			sb.write_string('<pre><code${cls}>${esc(body.join('\n'))}</code></pre>\n')
			continue
		}
		// Heading
		if level, text := heading_of(t) {
			if opts.heading_ids {
				id := unique_id(slug(text), mut ids)
				sb.write_string('<h${level} id="${id}">${inline(text, opts)}</h${level}>\n')
			} else {
				sb.write_string('<h${level}>${inline(text, opts)}</h${level}>\n')
			}
			i++
			continue
		}
		// Horizontal rule
		if is_hr(t) {
			sb.write_string('<hr>\n')
			i++
			continue
		}
		// Blockquote
		if t.starts_with('>') {
			mut inner := []string{}
			for i < lines.len && lines[i].trim_space().starts_with('>') {
				q := lines[i].trim_space()[1..]
				inner << if q.starts_with(' ') { q[1..] } else { q }
				i++
			}
			sb.write_string('<blockquote>\n')
			render_blocks(inner, opts, mut sb, mut ids)
			sb.write_string('</blockquote>\n')
			continue
		}
		// Table (GFM)
		if t.contains('|') && i + 1 < lines.len && is_table_sep(lines[i + 1]) {
			head := split_row(t)
			aligns := split_row(lines[i + 1]).map(fn (c string) string {
				return if c.starts_with(':') && c.ends_with(':') {
					' style="text-align:center"'
				} else if c.ends_with(':') {
					' style="text-align:right"'
				} else if c.starts_with(':') {
					' style="text-align:left"'
				} else {
					''
				}
			})
			sb.write_string('<table>\n<thead>\n<tr>')
			for k, h in head {
				a := if k < aligns.len { aligns[k] } else { '' }
				sb.write_string('<th${a}>${inline(h, opts)}</th>')
			}
			sb.write_string('</tr>\n</thead>\n<tbody>\n')
			i += 2
			for i < lines.len && lines[i].trim_space() != '' && lines[i].contains('|') {
				cells := split_row(lines[i])
				sb.write_string('<tr>')
				for k in 0 .. head.len {
					a := if k < aligns.len { aligns[k] } else { '' }
					cell := if k < cells.len { cells[k] } else { '' }
					sb.write_string('<td${a}>${inline(cell, opts)}</td>')
				}
				sb.write_string('</tr>\n')
				i++
			}
			sb.write_string('</tbody>\n</table>\n')
			continue
		}
		// Lists
		if ordered, _ := list_marker(line) {
			base_indent := line.len - line.trim_left(' ').len
			tag := if ordered { 'ol' } else { 'ul' }
			sb.write_string('<${tag}>\n')
			for i < lines.len {
				cur := lines[i]
				ind := cur.len - cur.trim_left(' ').len
				o2, content := list_marker(cur) or { break }
				if ind != base_indent || o2 != ordered {
					break
				}
				mut item := [content]
				i++
				// Continuation lines and nested lists (indented deeper).
				for i < lines.len {
					nx := lines[i]
					nind := nx.len - nx.trim_left(' ').len
					if nx.trim_space() == '' {
						if i + 1 < lines.len
							&& (lines[i + 1].len - lines[i + 1].trim_left(' ').len) > base_indent {
							item << ''
							i++
							continue
						}
						break
					}
					if nind > base_indent {
						item << nx[base_indent + 2..].trim_right(' ')
						i++
						continue
					}
					if _, _ := list_marker(nx) {
						break
					}
					if nind == base_indent {
						break
					}
					item << nx.trim_space()
					i++
				}
				mut task := ''
				if item[0].starts_with('[ ] ') {
					task = '<input type="checkbox" disabled> '
					item[0] = item[0][4..]
				} else if item[0].starts_with('[x] ') || item[0].starts_with('[X] ') {
					task = '<input type="checkbox" checked disabled> '
					item[0] = item[0][4..]
				}
				has_block := item.len > 1 && item[1..].any(has_list_marker(it))
				if has_block {
					mut first := []string{}
					mut k := 0
					for k < item.len && !has_list_marker(item[k]) {
						first << item[k]
						k++
					}
					sb.write_string('<li>${task}${inline(first.join('\n').trim_space(), opts)}\n')
					render_blocks(item[k..], opts, mut sb, mut ids)
					sb.write_string('</li>\n')
				} else {
					sb.write_string('<li>${task}${inline(item.join('\n').trim_space(), opts)}</li>\n')
				}
			}
			sb.write_string('</${tag}>\n')
			continue
		}
		// Paragraph
		mut para := []string{}
		for i < lines.len {
			l := lines[i]
			lt := l.trim_space()
			if lt == '' || lt.starts_with('```') || lt.starts_with('~~~')
				|| lt.starts_with('>') || is_hr(lt) || heading_of(lt) != none
				|| (para.len > 0 && list_marker(l) != none) {
				break
			}
			para << l.trim_left(' ')
			i++
		}
		if para.len == 0 {
			// Defensive: unknown construct, emit as text.
			para << t
			i++
		}
		sb.write_string('<p>${inline(para.join('\n'), opts)}</p>\n')
	}
}

// headings extracts the document outline (for building a table of contents).
pub fn headings(md string) []Heading {
	mut out := []Heading{}
	mut ids := map[string]int{}
	mut in_code := false
	for line in md.split_into_lines() {
		t := line.trim_space()
		if t.starts_with('```') || t.starts_with('~~~') {
			in_code = !in_code
			continue
		}
		if in_code {
			continue
		}
		if level, text := heading_of(t) {
			out << Heading{level, text, unique_id(slug(text), mut ids)}
		}
	}
	return out
}

// toc renders a nested Markdown bullet list linking to each heading up to max_level.
pub fn toc(md string, max_level int) string {
	hs := headings(md).filter(it.level <= max_level)
	if hs.len == 0 {
		return ''
	}
	mut min := 6
	for h in hs {
		if h.level < min {
			min = h.level
		}
	}
	return hs.map('${'  '.repeat(it.level - min)}- [${it.text}](#${it.id})').join('\n')
}

// to_plain_text strips Markdown syntax, returning readable text (e.g. for previews).
pub fn to_plain_text(md string) string {
	html := to_html(md, heading_ids: false).replace('</th><th', '</th> | <th').replace('</td><td',
		'</td> | <td')
	mut sb := strings.new_builder(html.len)
	mut in_tag := false
	for c in html {
		if c == `<` {
			in_tag = true
		} else if c == `>` {
			in_tag = false
		} else if !in_tag {
			sb.write_u8(c)
		}
	}
	return sb.str().replace('&lt;', '<').replace('&gt;', '>').replace('&quot;', '"').replace('&amp;',
		'&').split_into_lines().map(it.trim_space()).filter(it != '').join('\n')
}

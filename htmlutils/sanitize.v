module htmlutils

import strings

// html_to_text converts HTML to readable plain text: drops <script>/<style>/comments,
// turns block elements and <br> into newlines, decodes entities and collapses blanks.
pub fn html_to_text(html string) string {
	mut sb := strings.new_builder(html.len)
	lower := html.to_lower()
	mut i := 0
	for i < html.len {
		if html[i] == `<` {
			if lower[i..].starts_with('<!--') {
				end := lower.index_after('-->', i + 4) or { html.len - 3 }
				i = end + 3
				continue
			}
			mut skipped := false
			for t in ['script', 'style', 'head', 'template'] {
				if lower[i..].starts_with('<${t}') {
					close := lower.index_after('</${t}', i) or { html.len }
					gt := lower.index_after('>', close) or { html.len - 1 }
					i = gt + 1
					skipped = true
					break
				}
			}
			if skipped {
				continue
			}
			gt := html.index_after('>', i) or { html.len - 1 }
			tag := lower[i + 1..gt].trim_left('/').all_before(' ').trim_right('/')
			if tag in ['br', 'p', 'div', 'li', 'tr', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'section',
				'article', 'header', 'footer', 'ul', 'ol', 'table', 'blockquote', 'pre'] {
				sb.write_u8(`\n`)
			}
			if tag == 'li' && !lower[i + 1..].starts_with('/') {
				sb.write_string('• ')
			}
			i = gt + 1
			continue
		}
		sb.write_u8(html[i])
		i++
	}
	text := unescape_html(sb.str()).replace('\u00a0', ' ')
	mut lines := []string{}
	for line in text.split_into_lines() {
		l := line.fields().join(' ')
		if l.len > 0 {
			lines << l
		}
	}
	return lines.join('\n')
}

// default_allowed_tags is a conservative allowlist for user-generated rich text.
pub const default_allowed_tags = ['b', 'strong', 'i', 'em', 'u', 's', 'code', 'pre', 'p', 'br',
	'ul', 'ol', 'li', 'blockquote', 'a', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6']

fn safe_href(raw string) ?string {
	v := unescape_html(raw).trim_space()
	l := v.to_lower().replace(' ', '').replace('\t', '').replace('\n', '')
	if l.starts_with('http://') || l.starts_with('https://') || l.starts_with('mailto:')
		|| l.starts_with('/') || l.starts_with('#') {
		return v
	}
	return none
}

fn extract_href(attrs string) ?string {
	l := attrs.to_lower()
	idx := l.index('href') or { return none }
	mut j := idx + 4
	for j < attrs.len && attrs[j] == ` ` {
		j++
	}
	if j >= attrs.len || attrs[j] != `=` {
		return none
	}
	j++
	for j < attrs.len && attrs[j] == ` ` {
		j++
	}
	if j >= attrs.len {
		return none
	}
	q := attrs[j]
	if q == `"` || q == `'` {
		end := attrs.index_after(q.ascii_str(), j + 1) or { return none }
		return attrs[j + 1..end]
	}
	mut e := j
	for e < attrs.len && attrs[e] != ` ` {
		e++
	}
	return attrs[j..e]
}

// sanitize_html makes untrusted HTML safe to embed: tags in `allowed` are kept with
// ALL attributes stripped (except a safe http/https/mailto/relative `href` on <a>,
// which also gets rel="nofollow noopener noreferrer"); every other tag is removed,
// <script>/<style> contents are dropped, and all text is re-escaped.
pub fn sanitize_html(input string, allowed []string) string {
	mut sb := strings.new_builder(input.len)
	lower := input.to_lower()
	mut i := 0
	for i < input.len {
		c := input[i]
		if c == `<` {
			if lower[i..].starts_with('<!--') {
				end := lower.index_after('-->', i + 4) or { input.len - 3 }
				i = end + 3
				continue
			}
			gt := input.index_after('>', i) or {
				sb.write_string('&lt;')
				i++
				continue
			}
			inner := input[i + 1..gt]
			closing := inner.starts_with('/')
			body := if closing { inner[1..] } else { inner }
			name := body.all_before(' ').all_before('\t').all_before('\n').trim_right('/').to_lower()
			if !closing && name in ['script', 'style', 'iframe', 'object', 'embed', 'template'] {
				close := lower.index_after('</${name}', gt) or { input.len }
				end := lower.index_after('>', close) or { input.len - 1 }
				i = end + 1
				continue
			}
			if name.len > 0 && name in allowed {
				if closing {
					sb.write_string('</${name}>')
				} else if name == 'a' {
					if href := extract_href(body[name.len..]) {
						if safe := safe_href(href) {
							sb.write_string('<a href="${escape_html(safe)}" rel="nofollow noopener noreferrer">')
						} else {
							sb.write_string('<a>')
						}
					} else {
						sb.write_string('<a>')
					}
				} else if name == 'br' {
					sb.write_string('<br>')
				} else {
					sb.write_string('<${name}>')
				}
			}
			i = gt + 1
			continue
		}
		if c == `&` {
			// Keep valid entities as-is, escape bare ampersands.
			if semi := input.index_after(';', i + 1) {
				if semi - i <= 12 {
					if _ := decode_entity(input[i + 1..semi]) {
						sb.write_string(input[i..semi + 1])
						i = semi + 1
						continue
					}
				}
			}
			sb.write_string('&amp;')
			i++
			continue
		}
		match c {
			`>` { sb.write_string('&gt;') }
			`"` { sb.write_string('&quot;') }
			`'` { sb.write_string('&#39;') }
			else { sb.write_u8(c) }
		}
		i++
	}
	return sb.str()
}

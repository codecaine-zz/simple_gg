module htmlutils

import net.html
import os
import strings

// HtmlNode represents a parsed HTML element with convenient accessors.
pub struct HtmlNode {
pub:
	tag        string
	id         string
	classes    []string
	attributes map[string]string
	text       string
}

// HtmlDoc provides high-level querying over an HTML document.
pub struct HtmlDoc {
pub mut:
	dom html.DocumentObjectModel
}

// parse parses an HTML string into a queryable HtmlDoc.
pub fn parse(content string) HtmlDoc {
	mut src := content
	if !src.contains('<html') && !src.contains('<body') {
		src = '<html><body>${content}</body></html>'
	}
	dom := html.parse(src)
	return HtmlDoc{
		dom: dom
	}
}

// parse_file reads and parses an HTML file from disk.
pub fn parse_file(path string) !HtmlDoc {
	content := os.read_file(path)!
	return parse(content)
}

fn convert_tag(t &html.Tag) HtmlNode {
	class_attr := t.attributes['class']
	classes := if class_attr != '' { class_attr.split(' ') } else { []string{} }
	return HtmlNode{
		tag:        t.name
		id:         t.attributes['id']
		classes:    classes
		attributes: t.attributes.clone()
		text:       t.text().trim_space()
	}
}

// get_element_by_id finds the first element with the matching id attribute.
pub fn (mut d HtmlDoc) get_element_by_id(id string) ?HtmlNode {
	tags := d.dom.get_tags_by_attribute_value('id', id)
	if tags.len > 0 {
		return convert_tag(tags[0])
	}
	return none
}

// get_elements_by_tag finds all elements matching the given tag name.
pub fn (mut d HtmlDoc) get_elements_by_tag(tag string) []HtmlNode {
	tags := d.dom.get_tags(name: tag)
	mut res := []HtmlNode{cap: tags.len}
	for t in tags {
		res << convert_tag(t)
	}
	return res
}

// get_elements_by_class finds all elements containing the given CSS class.
pub fn (mut d HtmlDoc) get_elements_by_class(class_name string) []HtmlNode {
	tags := d.dom.get_tags_by_class_name(class_name)
	mut res := []HtmlNode{cap: tags.len}
	for t in tags {
		res << convert_tag(t)
	}
	return res
}

// title retrieves the content of the <title> tag if present.
pub fn (mut d HtmlDoc) title() string {
	tags := d.dom.get_tags(name: 'title')
	if tags.len > 0 {
		return tags[0].text().trim_space()
	}
	return ''
}

// escape_html converts special characters to their corresponding HTML entities.
pub fn escape_html(s string) string {
	mut sb := strings.new_builder(s.len + 16)
	for ch in s {
		match ch {
			`&` { sb.write_string('&amp;') }
			`<` { sb.write_string('&lt;') }
			`>` { sb.write_string('&gt;') }
			`"` { sb.write_string('&quot;') }
			`\'` { sb.write_string('&#39;') }
			else { sb.write_u8(ch) }
		}
	}
	return sb.str()
}

// unescape_html replaces HTML entities with their character equivalents in a single
// pass (so "&amp;lt;" correctly becomes "&lt;", not "<"). Supports common named
// entities plus decimal (&#39;) and hex (&#x1F600;) numeric references.
pub fn unescape_html(s string) string {
	if !s.contains('&') {
		return s
	}
	mut sb := strings.new_builder(s.len)
	mut i := 0
	for i < s.len {
		if s[i] == `&` {
			if semi := s.index_after(';', i + 1) {
				if semi - i <= 12 {
					ent := s[i + 1..semi]
					if decoded := decode_entity(ent) {
						sb.write_string(decoded)
						i = semi + 1
						continue
					}
				}
			}
		}
		sb.write_u8(s[i])
		i++
	}
	return sb.str()
}

const named_entities = {
	'amp':    '&'
	'lt':     '<'
	'gt':     '>'
	'quot':   '"'
	'apos':   "'"
	'nbsp':   '\u00a0'
	'copy':   '©'
	'reg':    '®'
	'trade':  '™'
	'hellip': '…'
	'mdash':  '—'
	'ndash':  '–'
	'lsquo':  '‘'
	'rsquo':  '’'
	'ldquo':  '“'
	'rdquo':  '”'
	'euro':   '€'
	'pound':  '£'
	'yen':    '¥'
	'cent':   '¢'
	'deg':    '°'
	'times':  '×'
	'divide': '÷'
	'laquo':  '«'
	'raquo':  '»'
	'middot': '·'
	'bull':   '•'
	'sect':   '§'
	'para':   '¶'
}

fn decode_entity(ent string) ?string {
	if ent.len > 1 && ent[0] == `#` {
		mut code := u32(0)
		if ent[1] == `x` || ent[1] == `X` {
			hex := ent[2..]
			if hex.len == 0 || hex.len > 6 || !hex.bytes().all(it.is_hex_digit()) {
				return none
			}
			code = u32(('0x' + hex).u64())
		} else {
			dec := ent[1..]
			if dec.len > 7 || !dec.bytes().all(it.is_digit()) {
				return none
			}
			code = u32(dec.u64())
		}
		if code == 0 || code > 0x10FFFF || (code >= 0xD800 && code <= 0xDFFF) {
			return '\ufffd'
		}
		return rune(code).str()
	}
	return named_entities[ent] or { return none }
}

// strip_tags removes all HTML/XML tags from the input string.
pub fn strip_tags(s string) string {
	mut sb := strings.new_builder(s.len)
	mut inside_tag := false
	for ch in s {
		if ch == `<` {
			inside_tag = true
			continue
		}
		if ch == `>` {
			inside_tag = false
			continue
		}
		if !inside_tag {
			sb.write_u8(ch)
		}
	}
	return sb.str()
}

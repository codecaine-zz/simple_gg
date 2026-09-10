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
		tag: t.name
		id: t.attributes['id']
		classes: classes
		attributes: t.attributes.clone()
		text: t.text().trim_space()
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

// unescape_html replaces common HTML entities with their character equivalents.
pub fn unescape_html(s string) string {
	return s.replace('&amp;', '&').replace('&lt;', '<').replace('&gt;', '>').replace('&quot;', '"').replace('&#39;', "'").replace('&apos;', "'")
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

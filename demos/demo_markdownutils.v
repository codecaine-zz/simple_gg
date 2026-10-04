module main

import markdownutils

fn main() {
	println('=== markdownutils Demo ===')

	md := '# Release Notes

Welcome to **v2.0** of `vlang_utils` — see [the docs](https://vlang.io).

## Highlights

- [x] Security fixes
- [ ] World domination
  - nested item

| Module | Status |
|--------|:------:|
| jsonutils | new |
| markdownutils | new |

[evil](javascript:alert(1))
'

	// 1. Render to HTML (safe links on by default)
	html := markdownutils.to_html(md)
	println(html)
	assert html.contains('<h1 id="release-notes">')
	assert html.contains('<table>')
	assert !html.contains('javascript:')

	// 2. Outline & table of contents
	for h in markdownutils.headings(md) {
		println('H${h.level}: ${h.text} (#${h.id})')
	}
	println('TOC:\n${markdownutils.toc(md, 3)}')

	// 3. Slugs and plain text
	println('Slug: ${markdownutils.slug('Hello, World! 2.0')}')
	println('Plain text:\n${markdownutils.to_plain_text(md)}')

	println('markdownutils demo completed successfully!')
}

module htmlutils

const sample_html = '
<!DOCTYPE html>
<html>
<head>
	<title>Test Page Title</title>
</head>
<body>
	<h1 id="header" class="title primary">Welcome to V</h1>
	<div class="content">
		<p class="paragraph" id="p1">First paragraph of text.</p>
		<p class="paragraph" id="p2">Second paragraph of text.</p>
		<a href="https://vlang.io" id="link">Official Site</a>
	</div>
</body>
</html>'

fn test_html_parsing_and_query() {
	mut doc := parse(sample_html)

	assert doc.title() == 'Test Page Title'

	header := doc.get_element_by_id('header') or { panic('header not found') }
	assert header.tag == 'h1'
	assert header.text == 'Welcome to V'
	assert header.classes.contains('title')
	assert header.classes.contains('primary')

	home_link := doc.get_element_by_id('link') or { panic('link not found') }
	assert home_link.attributes['href'] == 'https://vlang.io'
	assert home_link.text == 'Official Site'

	paras := doc.get_elements_by_class('paragraph')
	assert paras.len == 2
	assert paras[0].text == 'First paragraph of text.'
	assert paras[1].text == 'Second paragraph of text.'

	divs := doc.get_elements_by_tag('div')
	assert divs.len >= 1
}

fn test_escape_unescape_and_strip() {
	raw := '<div class="greeting">Hello & "Welcome"!</div>'
	escaped := escape_html(raw)
	assert escaped.contains('&lt;div')
	assert escaped.contains('&amp;')
	assert escaped.contains('&quot;')

	unescaped := unescape_html(escaped)
	assert unescaped == raw

	stripped := strip_tags(raw)
	assert stripped == 'Hello & "Welcome"!'
}

module main

import htmlutils

fn main() {
	println('==================================================')
	println('                demo_htmlutils                    ')
	println('==================================================')

	html_content := '
	<div id="main-container" class="card primary">
		<h1 class="title">Hello V Community</h1>
		<p id="description">High-performance utilities suite.</p>
		<a href="https://vlang.io" class="link primary">Official Website</a>
	</div>
	'

	// 1. Parsing & DOM Querying
	doc := htmlutils.parse(html_content)
	h1_nodes := doc.get_elements_by_tag('h1')
	println('Found ${h1_nodes.len} <h1> tag(s):')
	for node in h1_nodes {
		println('  Text: "${node.text}", Classes: ${node.classes}')
	}
	assert h1_nodes.len == 1
	assert h1_nodes[0].text == 'Hello V Community'

	// 2. Query by ID
	if desc := doc.get_element_by_id('description') {
		println('\nElement by ID #description: "${desc.text}"')
		assert desc.text == 'High-performance utilities suite.'
	}

	// 3. Strip Tags & Escaping
	stripped := htmlutils.strip_tags('<b>Bold</b> and <i>Italic</i> text')
	escaped := htmlutils.escape_html('<script>alert("xss")</script>')
	unescaped := htmlutils.unescape_html('&lt;div&gt;Safe&lt;/div&gt;')
	println('\nStripped:   "${stripped}"')
	println('Escaped:    "${escaped}"')
	println('Unescaped:  "${unescaped}"')
	assert stripped.contains('Bold and Italic text')
	assert escaped.contains('&lt;script&gt;')
	assert unescaped == '<div>Safe</div>'

	println('\n✔ htmlutils demo completed successfully!')
}

module markdownutils

fn h(md string) string {
	return to_html(md)
}

fn test_inline() {
	assert inline('**bold** and *it* and ~~del~~ and `x<y`', Options{}) == '<strong>bold</strong> and <em>it</em> and <del>del</del> and <code>x&lt;y</code>'
	assert inline('snake_case_name', Options{}) == 'snake_case_name'
	assert inline('\\*literal\\*', Options{}) == '*literal*'
	assert inline('[site](https://e.com "T")', Options{}) == '<a href="https://e.com" title="T">site</a>'
	assert inline('![alt](/i.png)', Options{}) == '<img src="/i.png" alt="alt">'
	assert inline('<https://x.io>', Options{}) == '<a href="https://x.io">https://x.io</a>'
	assert inline('a & b <script>', Options{}) == 'a &amp; b &lt;script&gt;'
	assert inline('**[x](/y)**', Options{}) == '<strong><a href="/y">x</a></strong>'
}

fn test_xss_neutralized() {
	assert h('[x](javascript:alert(1))') == '<p><a href="#">x</a></p>'
	assert inline('[V](https://en.wikipedia.org/wiki/V_(language))', Options{}) == '<a href="https://en.wikipedia.org/wiki/V_(language)">V</a>'
	assert h('[x]( JAVASCRIPT:alert(1))').contains('href="#"')
	assert !h('<img src=x onerror=alert(1)>').contains('<img')
	assert h('<b>hi</b>').contains('&lt;b&gt;')
	assert to_html('<b>hi</b>', raw_html: true).contains('<b>hi</b>')
}

fn test_blocks() {
	md := '# Title\n\nPara one\ncontinues.\n\n## Sub *x*\n\n> quote **b**\n\n---\n\n```v\nfn main() {}\n<tag>\n```\n'
	out := h(md)
	assert out.contains('<h1 id="title">Title</h1>')
	assert out.contains('<p>Para one\ncontinues.</p>')
	assert out.contains('<h2 id="sub-x">Sub <em>x</em></h2>')
	assert out.contains('<blockquote>\n<p>quote <strong>b</strong></p>\n</blockquote>')
	assert out.contains('<hr>')
	assert out.contains('<pre><code class="language-v">fn main() {}\n&lt;tag&gt;</code></pre>')
}

fn test_lists() {
	assert h('- a\n- b\n- c') == '<ul>\n<li>a</li>\n<li>b</li>\n<li>c</li>\n</ul>'
	assert h('1. one\n2. two') == '<ol>\n<li>one</li>\n<li>two</li>\n</ol>'
	nested := h('- top\n  - inner\n  - inner2\n- next')
	assert nested == '<ul>\n<li>top\n<ul>\n<li>inner</li>\n<li>inner2</li>\n</ul>\n</li>\n<li>next</li>\n</ul>'
	tasks := h('- [ ] todo\n- [x] done')
	assert tasks.contains('<input type="checkbox" disabled> todo')
	assert tasks.contains('<input type="checkbox" checked disabled> done')
}

fn test_table() {
	out := h('| Name | Qty |\n|:-----|----:|\n| a | 1 |\n| **b** | 22 |')
	assert out.starts_with('<table>\n<thead>\n<tr><th style="text-align:left">Name</th><th style="text-align:right">Qty</th></tr>')
	assert out.contains('<td style="text-align:left"><strong>b</strong></td><td style="text-align:right">22</td>')
}

fn test_headings_toc_plain() {
	md := '# Intro\n## Setup\n```\n# not a heading\n```\n## Setup\n### Deep'
	hs := headings(md)
	assert hs.map(it.id) == ['intro', 'setup', 'setup-1', 'deep']
	assert toc(md, 2) == '- [Intro](#intro)\n  - [Setup](#setup)\n  - [Setup](#setup-1)'
	assert to_plain_text('# Hi\n\nSome **bold** & [link](/x).') == 'Hi\nSome bold & link.'
	assert slug('Hello, World! 2') == 'hello-world-2'
}

fn test_plain_text_separates_table_cells() {
	txt := to_plain_text('| A | B |\n|---|---|\n| 1 | 2 |')
	assert txt == 'A | B\n1 | 2'
}

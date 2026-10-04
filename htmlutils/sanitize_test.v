module htmlutils

fn test_unescape_single_pass() {
	assert unescape_html('&amp;lt;script&amp;gt;') == '&lt;script&gt;'
	assert unescape_html('&lt;b&gt; &quot;x&quot; &#39;y&#39; &apos;') == '<b> "x" \'y\' \''
	assert unescape_html('&#x1F600; &#169; &copy; &mdash;') == '😀 © © —'
	assert unescape_html('AT&T &unknown; & alone') == 'AT&T &unknown; & alone'
	assert unescape_html('&#0;') == '\ufffd'
	for s in ['<a href="x">&</a>', "it's", 'plain'] {
		assert unescape_html(escape_html(s)) == s
	}
}

fn test_html_to_text() {
	html := '<html><head><title>T</title><style>p{}</style></head><body><h1>Hi&nbsp;there</h1><!-- c --><p>One <b>two</b></p><script>alert(1)</script><ul><li>a</li><li>b</li></ul></body></html>'
	assert html_to_text(html) == 'Hi there\nOne two\n• a\n• b'
}

fn test_sanitize_html_blocks_xss() {
	cases := {
		'<script>alert(1)</script>ok':                'ok'
		'<img src=x onerror=alert(1)>hi':             'hi'
		'<b onclick="x()">bold</b>':                  '<b>bold</b>'
		'<a href="javascript:alert(1)">x</a>':        '<a>x</a>'
		'<a href=" JaVaScRiPt:alert(1)">x</a>':       '<a>x</a>'
		'<a href="https://e.com/?a=1&amp;b=2">x</a>': '<a href="https://e.com/?a=1&amp;b=2" rel="nofollow noopener noreferrer">x</a>'
		'5 > 3 & "q"':                                '5 &gt; 3 &amp; &quot;q&quot;'
		'<p>para<br/>line</p>':                       '<p>para<br>line</p>'
		'<iframe src="evil"></iframe>after':          'after'
		'<style>body{}</style><i>x</i>':              '<i>x</i>'
		'unclosed < tag':                             'unclosed &lt; tag'
		'<svg><script>x</script></svg>t':             't'
	}
	for input, want in cases {
		got := sanitize_html(input, default_allowed_tags)
		assert got == want, 'input: ${input}\n got: ${got}\nwant: ${want}'
	}
}

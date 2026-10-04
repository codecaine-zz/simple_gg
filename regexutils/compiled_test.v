module regexutils

fn test_escape_matches_literally() {
	for s in ['a.b', '(x)', '1+1=2', '[q]', 'cost: $5.00', 'a|b', '^start', 'x{2}', '*?', r'back\slash',
		'a-b', 'path/to/file', 'email@host.com'] {
		p := escape(s)
		assert is_valid_pattern(p), 'escape produced invalid pattern for ${s}: ${p}'
		assert is_match(p, s), '${p} should match ${s}'
	}
	assert !is_match(escape('a.b'), 'axb')
	assert !is_valid_pattern('(unclosed')
}

fn test_compiled_regex() {
	mut re := compile(r'(\w+)@(\w+)\.com') or { panic(err) }
	assert re.contains('mail bob@example.com now')
	assert !re.is_match('mail bob@example.com now')
	m := re.find('mail bob@example.com now') or { panic('no match') }
	assert m.text == 'bob@example.com' && m.start == 5 && m.end == 20
	caps := re.captures('mail bob@example.com now') or { panic('no caps') }
	assert caps == ['bob@example.com', 'bob', 'example']
	all := re.captures_all('a@x.com, b@y.com')
	assert all.len == 2 && all[1] == ['b@y.com', 'b', 'y']
	assert re.count('a@x.com b@y.com c@z.org') == 2
	compile('(') or { return }
	assert false
}

fn test_named_and_replace_fn() {
	named := named_captures(r'(?P<user>\w+)@(?P<host>\w+)', 'x alice@corp y') or { panic('none') }
	assert named['user'] == 'alice' && named['host'] == 'corp'
	out := replace_fn(r'\d+', 'a1 b22 c333', fn (m Match) string {
		return '<${m.text.len}>'
	})
	assert out == 'a<1> b<2> c<3>'
	assert count_matches(r'\d+', 'a1 b22 c333') == 3
	// zero-width patterns must not loop forever or emit empty matches
	assert count_matches(r'x*', 'abc') == 0
	assert captures(r'\d', 'none') == none
	mut re := must_compile(r'\s*,\s*')
	assert re.split('a , b,c') == ['a', 'b', 'c']
}

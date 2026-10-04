module urlutils

fn test_ipv6_and_port_validation() {
	u := parse_url('http://[::1]:8080/x')!
	assert u.host == '[::1]'
	assert u.port == 8080
	v := parse_url('http://[2001:db8::1]/')!
	assert v.host == '[2001:db8::1]' && v.port == 0
	if _ := parse_url('http://host:99999/') {
		assert false
	}
	if _ := parse_url('http://host:ab/') {
		assert false
	}
}

fn test_password_with_at_sign() {
	u := parse_url('postgres://user:p%40ss@db:5432/app')!
	assert u.username == 'user'
	assert u.password == 'p@ss'
	assert u.host == 'db'
	assert u.str().starts_with('postgres://user:p%40ss@db:5432')
	raw := parse_url('ftp://me:a@b@host/')!
	assert raw.password == 'a@b'
	assert raw.host == 'host'
}

fn test_rfc3986_reference_resolution() {
	base := 'http://a/b/c/d;p?q'
	cases := {
		'g':       'http://a/b/c/g'
		'./g':     'http://a/b/c/g'
		'g/':      'http://a/b/c/g/'
		'/g':      'http://a/g'
		'?y':      'http://a/b/c/d;p?y'
		'g?y':     'http://a/b/c/g?y'
		'#s':      'http://a/b/c/d;p?q#s'
		'..':      'http://a/b/'
		'../g':    'http://a/b/g'
		'../../g': 'http://a/g'
	}
	for ref, want in cases {
		got := resolve_reference(base, ref)!
		assert got == want, '${ref}: got ${got}, want ${want}'
	}
}

fn test_remove_dot_segments() {
	assert remove_dot_segments('/a/b/c/./../../g') == '/a/g'
	assert remove_dot_segments('mid/content=5/../6') == 'mid/6'
	assert remove_dot_segments('/a/b/..') == '/a/'
	assert remove_dot_segments('/../x') == '/x'
}

fn test_normalize_and_origin() {
	n := normalize_url('HTTPS://Example.COM:443/a/./b/../c?z=1&a=2')!
	assert n == 'https://example.com/a/c?a=2&z=1'
	u := parse_url('http://Example.com:8080/p')!
	assert u.origin() == 'http://example.com:8080'
	assert u.effective_port() == 8080
	assert is_same_origin('https://x.io/a', 'https://x.io:443/b')
	assert !is_same_origin('https://x.io', 'http://x.io')
	assert is_absolute_url('mailto:a@b.c')
	assert !is_absolute_url('/relative/path')
}

fn test_queries() {
	q := query_values('?tag=a&tag=b&x=1&flag')
	assert q['tag'] == ['a', 'b']
	assert q['x'] == ['1']
	assert q['flag'] == ['']
	assert encode_query({
		'b': '2'
		'a': 'x y'
	}) == 'a=x+y&b=2'
	assert encode_query_multi({
		't': ['1', '2']
	}) == 't=1&t=2'
	u := parse_url('http://h/p?a=1')!.with_query({
		'b': '2'
	})
	assert u.query['a'] == '1' && u.query['b'] == '2'
}

module webutils

import os
import net.http
import compress.gzip
import json2

fn hdr(r http.Response, name string) string {
	return r.header.get_custom(name) or { '' }
}

fn cookie_pair(r http.Response, name string) string {
	for v in r.header.custom_values('Set-Cookie') {
		if v.starts_with('${name}=') {
			return v.all_before(';')
		}
	}
	return ''
}

fn new_test_app() &App {
	mut app := new_app(secret: 'test-secret-please-change')
	app.get('/', fn (mut c Context) ! {
		c.text('home')
	})
	app.get('/users/:id', fn (mut c Context) ! {
		c.json({
			'id': c.param('id')
		})
	})
	app.get('/files/*path', fn (mut c Context) ! {
		c.text(c.param('path'))
	})
	app.get('/posts/:slug?', fn (mut c Context) ! {
		c.text('slug=' + c.param('slug'))
	})
	app.post('/echo', fn (mut c Context) ! {
		c.text(c.body())
	})
	app.get('/boom', fn (mut c Context) ! {
		return error('database password is hunter2')
	})
	app.get('/teapot', fn (mut c Context) ! {
		return http_error(418, 'short and stout')
	})
	return app
}

fn test_basic_routing_and_params() {
	mut app := new_test_app()
	r := app.request(path: '/')
	assert r.status_code == 200
	assert r.body == 'home'
	assert hdr(r, 'Content-Type').starts_with('text/plain')
	u := app.request(path: '/users/42?x=1')
	assert u.body == '{"id":"42"}'
	assert hdr(u, 'Content-Type').starts_with('application/json')
	assert app.request(path: '/users/a%20b').body == '{"id":"a b"}'
	assert app.request(path: '/files/a/b/c.txt').body == 'a/b/c.txt'
	assert app.request(path: '/posts').body == 'slug='
	assert app.request(path: '/posts/hello').body == 'slug=hello'
	// non-strict trailing slash and duplicate slashes
	assert app.request(path: '/users/7/').body == '{"id":"7"}'
}

fn test_404_405_head_options() {
	mut app := new_test_app()
	nf := app.request(path: '/nope')
	assert nf.status_code == 404
	assert nf.body.contains('404')
	m := app.request(method: 'DELETE', path: '/users/1')
	assert m.status_code == 405
	assert hdr(m, 'Allow').contains('GET')
	h := app.request(method: 'HEAD', path: '/')
	assert h.status_code == 200
	assert h.body == ''
	assert hdr(h, 'Content-Length') == '4'
	o := app.request(method: 'OPTIONS', path: '/users/1')
	assert o.status_code == 204
	assert hdr(o, 'Allow').contains('GET')
}

fn test_errors_do_not_leak_internals() {
	mut app := new_test_app()
	r := app.request(path: '/boom')
	assert r.status_code == 500
	assert !r.body.contains('hunter2')
	t := app.request(
		path:    '/teapot'
		headers: {
			'Accept': 'application/json'
		}
	)
	assert t.status_code == 418
	assert t.body == '{"error":"short and stout","status":418}'
	mut dbg := new_app(debug: true)
	dbg.get('/x', fn (mut c Context) ! {
		return error('detail')
	})
	assert dbg.request(path: '/x').body.contains('detail')
}

fn test_bad_paths_rejected() {
	mut app := new_test_app()
	assert app.request(path: '/users/%00').status_code == 400
	assert app.request(path: '/users/%zz').status_code == 400
	assert app.request(path: 'http://evil/').status_code == 400
}

fn test_body_limit() {
	mut app := new_app(max_body_bytes: 10)
	app.post('/x', fn (mut c Context) ! {
		c.text('ok')
	})
	assert app.request(method: 'POST', path: '/x', body: 'small').status_code == 200
	assert app.request(method: 'POST', path: '/x', body: 'x'.repeat(11)).status_code == 413
}

fn test_middleware_order_and_next() {
	mut app := new_app()
	mut log := &[]string{}
	app.use(fn [mut log] (mut c Context) ! {
		log << 'a-before'
		c.next()!
		log << 'a-after'
	})
	app.use_at('/admin', fn (mut c Context) ! {
		if c.header('X-Admin') != 'yes' {
			return http_error(403, 'forbidden')
		}
		c.next()!
	})
	app.get('/', fn [mut log] (mut c Context) ! {
		log << 'handler'
		c.text('ok')
	})
	app.get('/admin/panel', fn (mut c Context) ! {
		c.text('panel')
	})
	app.get('/administrator', fn (mut c Context) ! {
		c.text('not admin prefix')
	})
	assert app.request(path: '/').body == 'ok'
	assert log.join(',') == 'a-before,handler,a-after'
	assert app.request(path: '/admin/panel').status_code == 403
	assert app.request(
		path:    '/admin/panel'
		headers: {
			'X-Admin': 'yes'
		}
	).body == 'panel'
	assert app.request(path: '/administrator').status_code == 200
}

fn test_groups() {
	mut app := new_app()
	auth := fn (mut c Context) ! {
		if c.header('Authorization') == '' {
			return http_error(401, 'no')
		}
		c.next()!
	}
	mut api := app.group('/api', auth)
	api.get('/items', fn (mut c Context) ! {
		c.json(['a', 'b'])
	})
	mut v2 := api.group('/v2')
	v2.get('/items/:id', fn (mut c Context) ! {
		c.text('v2 ' + c.param('id'))
	})
	assert app.request(path: '/api/items').status_code == 401
	assert app.request(
		path:    '/api/items'
		headers: {
			'Authorization': 'x'
		}
	).body == '["a","b"]'
	assert app.request(
		path:    '/api/v2/items/9'
		headers: {
			'Authorization': 'x'
		}
	).body == 'v2 9'
}

struct NewUser {
	name  string
	email string
	age   int
}

fn test_json_binding() {
	mut app := new_app()
	app.post('/users', fn (mut c Context) ! {
		u := c.bind_json[NewUser]()!
		c.status(201)
		c.json(u)
	})
	ok := app.request(
		method:  'POST'
		path:    '/users'
		body:    '{"name":"Ann","email":"a@x.io","age":30}'
		headers: {
			'Content-Type': 'application/json'
		}
	)
	assert ok.status_code == 201
	assert ok.body.contains('"name":"Ann"')
	// wrong content type (CSRF-able text/plain) is refused
	assert app.request(
		method:  'POST'
		path:    '/users'
		body:    '{}'
		headers: {
			'Content-Type': 'text/plain'
		}
	).status_code == 415
	assert app.request(
		method:  'POST'
		path:    '/users'
		body:    '{bad'
		headers: {
			'Content-Type': 'application/json'
		}
	).status_code == 400
}

fn test_query_and_form() {
	mut app := new_app()
	app.get('/q', fn (mut c Context) ! {
		c.text('${c.query('a')}|${c.query_or('b', 'def')}|${c.query_int('n', -1)}|${c.query_values('t').join(',')}')
	})
	app.post('/f', fn (mut c Context) ! {
		c.text('${c.form_value('name')}|${c.form_values('tag').join(',')}')
	})
	assert app.request(path: '/q?a=x%20y&n=12&t=1&t=2').body == 'x y|def|12|1,2'
	assert app.request(path: '/q?n=12abc').body == '|def|-1|'
	assert app.request(
		method:  'POST'
		path:    '/f'
		body:    'name=J%C3%BCrgen&tag=a&tag=b'
		headers: {
			'Content-Type': 'application/x-www-form-urlencoded'
		}
	).body == 'Jürgen|a,b'
}

fn test_multipart_upload() {
	mut app := new_app()
	app.post('/up', fn (mut c Context) ! {
		f := c.file('doc') or { return http_error(400, 'no file') }
		c.text('${c.form_value('title')}|${f.filename}|${f.data}')
	})
	body := '--XyZ\r\nContent-Disposition: form-data; name="title"\r\n\r\nReport\r\n--XyZ\r\nContent-Disposition: form-data; name="doc"; filename="a.txt"\r\nContent-Type: text/plain\r\n\r\nhello\r\n--XyZ--\r\n'
	r := app.request(
		method:  'POST'
		path:    '/up'
		body:    body
		headers: {
			'Content-Type': 'multipart/form-data; boundary=XyZ'
		}
	)
	assert r.body == 'Report|a.txt|hello', r.body
}

fn test_security_headers_default_on() {
	mut app := new_test_app()
	r := app.request(path: '/')
	assert hdr(r, 'X-Content-Type-Options') == 'nosniff'
	assert hdr(r, 'X-Frame-Options') == 'SAMEORIGIN'
	assert hdr(r, 'Referrer-Policy') == 'no-referrer'
	csp := hdr(r, 'Content-Security-Policy')
	assert csp.contains("default-src 'self'")
	assert csp.contains("'nonce-")
	assert hdr(r, 'X-Powered-By') == ''
	mut off := new_app(security_headers: false)
	off.get('/', fn (mut c Context) ! {
		c.text('x')
	})
	assert hdr(off.request(path: '/'), 'Content-Security-Policy') == ''
}

fn test_header_injection_blocked() {
	mut app := new_app()
	app.get('/r', fn (mut c Context) ! {
		c.set_header('X-Test', 'a\r\nSet-Cookie: evil=1')
		c.redirect('/ok\r\nX-Evil: 1')
	})
	r := app.request(path: '/r')
	assert r.status_code == 302
	assert hdr(r, 'X-Test') == 'aSet-Cookie: evil=1'
	assert hdr(r, 'Location') == '/okX-Evil: 1'
	assert hdr(r, 'X-Evil') == ''
	assert cookie_pair(r, 'evil') == ''
}

fn test_safe_redirect() {
	assert is_local_url('/dashboard')
	assert is_local_url('/a?b=c')
	assert !is_local_url('//evil.com')
	assert !is_local_url('/\\evil.com')
	assert !is_local_url('https://evil.com')
	assert !is_local_url('javascript:alert(1)')
	assert !is_local_url('')
	mut app := new_app()
	app.get('/login', fn (mut c Context) ! {
		c.safe_redirect(c.query('next'), '/')
	})
	assert hdr(app.request(path: '/login?next=%2F%2Fevil.com'), 'Location') == '/'
	assert hdr(app.request(path: '/login?next=%2Fhome'), 'Location') == '/home'
}

fn test_cookies_and_signed_cookies() {
	mut app := new_app(secret: 'k')
	app.get('/set', fn (mut c Context) ! {
		c.set_cookie('theme', 'dark mode')
		c.set_signed_cookie('uid', '42')
		c.text('ok')
	})
	app.get('/read', fn (mut c Context) ! {
		theme := c.cookie('theme') or { '-' }
		uid := c.signed_cookie('uid') or { 'TAMPERED' }
		c.text('${theme}|${uid}')
	})
	r := app.request(path: '/set')
	sc := r.header.custom_values('Set-Cookie')
	assert sc.len == 2
	assert sc[0].contains('HttpOnly')
	assert sc[0].contains('SameSite=Lax')
	assert sc[0].contains('Path=/')
	theme := cookie_pair(r, 'theme')
	uid := cookie_pair(r, 'uid')
	assert theme == 'theme=dark%20mode'
	ok := app.request(
		path:    '/read'
		headers: {
			'Cookie': '${theme}; ${uid}'
		}
	)
	assert ok.body == 'dark mode|42'
	forged := uid.replace('42', '1')
	bad := app.request(
		path:    '/read'
		headers: {
			'Cookie': forged
		}
	)
	assert bad.body == '-|TAMPERED'
}

fn test_sessions_flow() {
	mut app := new_app(secret: 's')
	app.use(sessions())
	app.post('/login', fn (mut c Context) ! {
		c.session_regenerate()
		c.session_set('user', 'ann')
		c.flash('info', 'Welcome!')
		c.text('ok')
	})
	app.get('/me', fn (mut c Context) ! {
		c.text('${c.session_get('user') or { 'anon' }}|${c.take_flash('info')}')
	})
	app.post('/logout', fn (mut c Context) ! {
		c.session_destroy()
		c.text('bye')
	})
	assert app.request(path: '/me').body == 'anon|'
	login := app.request(method: 'POST', path: '/login')
	sid := cookie_pair(login, 'sid')
	assert sid.starts_with('sid=s%3A')
	first := app.request(
		path:    '/me'
		headers: {
			'Cookie': sid
		}
	)
	assert first.body == 'ann|Welcome!'
	// flash consumed
	assert app.request(
		path:    '/me'
		headers: {
			'Cookie': sid
		}
	).body == 'ann|'
	// forged id rejected
	assert app.request(
		path:    '/me'
		headers: {
			'Cookie': 'sid=s%3Aguess.abc'
		}
	).body == 'anon|'
	out := app.request(
		method:  'POST'
		path:    '/logout'
		headers: {
			'Cookie': sid
		}
	)
	assert cookie_pair(out, 'sid') == 'sid='
	assert app.request(
		path:    '/me'
		headers: {
			'Cookie': sid
		}
	).body == 'anon|'
}

fn test_csrf_protection() {
	mut app := new_app(secret: 'c')
	app.use(csrf())
	app.get('/form', fn (mut c Context) ! {
		c.text(c.csrf_token())
	})
	app.post('/submit', fn (mut c Context) ! {
		c.text('accepted')
	})
	// no cookie, no token
	assert app.request(method: 'POST', path: '/submit').status_code == 403
	page := app.request(path: '/form')
	token := page.body
	cookie := cookie_pair(page, '_csrf')
	assert token.len > 20
	assert app.request(
		method:  'POST'
		path:    '/submit'
		headers: {
			'Cookie': cookie
		}
	).status_code == 403
	assert app.request(
		method:  'POST'
		path:    '/submit'
		headers: {
			'Cookie':       cookie
			'X-CSRF-Token': token
		}
	).body == 'accepted'
	assert app.request(
		method:  'POST'
		path:    '/submit'
		body:    '_csrf=${url_encode(token)}'
		headers: {
			'Cookie':       cookie
			'Content-Type': 'application/x-www-form-urlencoded'
		}
	).body == 'accepted'
	// token from another browser secret fails
	other := app.request(path: '/form').body
	assert app.request(
		method:  'POST'
		path:    '/submit'
		headers: {
			'Cookie':       cookie
			'X-CSRF-Token': other
		}
	).status_code == 403
}

fn test_cors() {
	mut app := new_app()
	app.use(cors(origins: ['https://app.example'], credentials: true))
	app.get('/data', fn (mut c Context) ! {
		c.json({
			'ok': true
		})
	})
	good := app.request(
		path:    '/data'
		headers: {
			'Origin': 'https://app.example'
		}
	)
	assert hdr(good, 'Access-Control-Allow-Origin') == 'https://app.example'
	assert hdr(good, 'Access-Control-Allow-Credentials') == 'true'
	evil := app.request(
		path:    '/data'
		headers: {
			'Origin': 'https://evil.example'
		}
	)
	assert hdr(evil, 'Access-Control-Allow-Origin') == ''
	pre := app.request(
		method:  'OPTIONS'
		path:    '/data'
		headers: {
			'Origin':                         'https://app.example'
			'Access-Control-Request-Method':  'POST'
			'Access-Control-Request-Headers': 'Content-Type'
		}
	)
	assert pre.status_code == 204
	assert hdr(pre, 'Access-Control-Allow-Methods').contains('POST')
	assert hdr(pre, 'Access-Control-Allow-Headers') == 'Content-Type'
	mut open := new_app()
	open.use(cors())
	open.get('/', fn (mut c Context) ! {
		c.text('x')
	})
	assert hdr(open.request(
		path:    '/'
		headers: {
			'Origin': 'https://any.example'
		}
	), 'Access-Control-Allow-Origin') == '*'
}

fn test_rate_limit() {
	mut app := new_app()
	app.use(rate_limit(max: 2, window_ms: 60_000))
	app.get('/', fn (mut c Context) ! {
		c.text('ok')
	})
	assert app.request(path: '/').status_code == 200
	second := app.request(path: '/')
	assert hdr(second, 'RateLimit-Remaining') == '0'
	third := app.request(path: '/')
	assert third.status_code == 429
	assert hdr(third, 'Retry-After').int() > 0
	// different client has its own bucket
	assert app.request(path: '/', remote_addr: '10.0.0.9:1234').status_code == 200
}

fn test_basic_auth_and_bearer() {
	mut app := new_app()
	app.use_at('/admin', basic_auth({
		'admin': 's3cret'
	}, 'Admin'))
	app.get('/admin', fn (mut c Context) ! {
		c.text('hi')
	})
	app.get('/api', bearer_auth(fn (t string) bool {
		return t == 'tok'
	}), fn (mut c Context) ! {
		c.text('api')
	})
	no := app.request(path: '/admin')
	assert no.status_code == 401
	assert hdr(no, 'WWW-Authenticate').starts_with('Basic realm="Admin"')
	assert app.request(
		path:    '/admin'
		headers: {
			'Authorization': 'Basic YWRtaW46czNjcmV0'
		}
	).body == 'hi'
	assert app.request(
		path:    '/admin'
		headers: {
			'Authorization': 'Basic YWRtaW46d3Jvbmc='
		}
	).status_code == 401
	assert app.request(
		path:    '/api'
		headers: {
			'Authorization': 'Bearer tok'
		}
	).body == 'api'
	assert app.request(
		path:    '/api'
		headers: {
			'Authorization': 'Bearer nope'
		}
	).status_code == 401
}

fn test_compress() {
	mut app := new_app()
	app.use(compress())
	big := 'hello world '.repeat(500)
	app.get('/big', fn [big] (mut c Context) ! {
		c.text(big)
	})
	r := app.request(
		path:    '/big'
		headers: {
			'Accept-Encoding': 'gzip, deflate'
		}
	)
	assert hdr(r, 'Content-Encoding') == 'gzip'
	assert gzip.decompress(r.body.bytes())!.bytestr() == big
	assert hdr(r, 'Vary').contains('Accept-Encoding')
	plain := app.request(path: '/big')
	assert hdr(plain, 'Content-Encoding') == ''
	assert plain.body == big
}

fn test_request_id() {
	mut app := new_app()
	app.use(request_id())
	app.get('/', fn (mut c Context) ! {
		c.text(c.request_id)
	})
	r := app.request(path: '/')
	assert r.body.len > 10
	assert hdr(r, 'X-Request-Id') == r.body
	assert app.request(
		path:    '/'
		headers: {
			'X-Request-Id': 'abc-123'
		}
	).body == 'abc-123'
	assert app.request(
		path:    '/'
		headers: {
			'X-Request-Id': '<script>'
		}
	).body != '<script>'
}

fn test_accepts_and_ip() {
	mut app := new_app()
	app.get('/', fn (mut c Context) ! {
		c.text('${c.accepts('json', 'html')}|${c.ip()}')
	})
	assert app.request(
		path:    '/'
		headers: {
			'Accept': 'text/html,application/json;q=0.9'
		}
	).body == 'html|127.0.0.1'
	assert app.request(
		path:    '/'
		headers: {
			'Accept':          'application/json'
			'X-Forwarded-For': '1.2.3.4'
		}
	).body == 'json|127.0.0.1'
	mut proxied := new_app(trust_proxy: true)
	proxied.get('/', fn (mut c Context) ! {
		c.text(c.ip())
	})
	assert proxied.request(
		path:    '/'
		headers: {
			'X-Forwarded-For': '1.2.3.4, 10.0.0.1'
		}
	).body == '1.2.3.4'
	assert app.request(path: '/', remote_addr: '[::1]:9000').body.ends_with('|::1')
}

fn test_render_with_views_locals_and_nonce() {
	mut app := new_app()
	app.locals['site'] = 'MySite'
	app.views.add('layout', '<title><%= site %> - <%= title %></title><%- body %>')!
	app.views.add('home', '<% layout \'layout\' %><h1>Hi <%= name %></h1><script nonce="<%= csp_nonce %>"></script>')!
	app.get('/', fn (mut c Context) ! {
		c.locals['name'] = '<Ann>'
		c.render('home', {
			'title': 'Home'
		})!
	})
	r := app.request(path: '/')
	assert r.status_code == 200
	assert hdr(r, 'Content-Type').starts_with('text/html')
	assert r.body.starts_with('<title>MySite - Home</title><h1>Hi &lt;Ann&gt;</h1>')
	nonce := r.body.all_after('nonce="').all_before('"')
	assert nonce.len > 10
	assert hdr(r, 'Content-Security-Policy').contains("'nonce-${nonce}'")
}

fn test_static_files() {
	root := os.join_path(os.temp_dir(), 'webutils_static_${os.getpid()}')
	os.mkdir_all(os.join_path(root, 'css'))!
	defer {
		os.rmdir_all(root) or {}
	}
	os.write_file(os.join_path(root, 'index.html'), '<h1>idx</h1>')!
	os.write_file(os.join_path(root, 'css', 'app.css'), 'body{}')!
	os.write_file(os.join_path(root, '.env'), 'SECRET=1')!
	mut app := new_app()
	app.static('/assets', root)
	app.get('/assets/dynamic', fn (mut c Context) ! {
		c.text('dyn')
	})
	css := app.request(path: '/assets/css/app.css')
	assert css.status_code == 200
	assert css.body == 'body{}'
	assert hdr(css, 'Content-Type') == 'text/css; charset=utf-8'
	etag := hdr(css, 'ETag')
	assert etag.starts_with('W/"')
	cached := app.request(
		path:    '/assets/css/app.css'
		headers: {
			'If-None-Match': etag
		}
	)
	assert cached.status_code == 304
	assert cached.body == ''
	assert app.request(path: '/assets/').body == '<h1>idx</h1>'
	assert app.request(path: '/assets/dynamic').body == 'dyn'
	for bad in ['/assets/.env', '/assets/../etc/passwd', '/assets/%2e%2e/%2e%2e/etc/passwd',
		'/assets/css%2F..%2F..%2Fsecret', '/assets/css/..%5c..%5csecret'] {
		r := app.request(path: bad)
		assert r.status_code in [400, 404], '${bad} -> ${r.status_code}'
		assert !r.body.contains('SECRET')
	}
}

fn test_send_file_and_download() {
	path := os.join_path(os.temp_dir(), 'webutils_dl_${os.getpid()}.txt')
	os.write_file(path, 'data')!
	defer {
		os.rm(path) or {}
	}
	mut app := new_app()
	app.get('/dl', fn [path] (mut c Context) ! {
		c.download(path, 'rép"ort.txt')!
	})
	r := app.request(path: '/dl')
	assert r.body == 'data'
	cd := hdr(r, 'Content-Disposition')
	assert cd.starts_with('attachment; filename="r__p_ort.txt"')
	assert cd.contains("filename*=UTF-8''r%C3%A9p%22ort.txt")
}

fn test_custom_error_and_not_found_handlers() {
	mut app := new_app()
	app.on_not_found(fn (mut c Context) ! {
		c.status(404)
		c.json({
			'missing': c.path
		})
	})
	app.on_error(fn (mut c Context, err IError) {
		c.status(599)
		c.text('custom: ${err.msg()}')
	})
	app.get('/e', fn (mut c Context) ! {
		return error('x')
	})
	assert app.request(path: '/zzz').body == '{"missing":"/zzz"}'
	e := app.request(path: '/e')
	assert e.status_code == 599
	assert e.body == 'custom: x'
}

fn test_render_struct_and_json_any() {
	mut app := new_app()
	app.views.add('p', '<%= name %> (<%= age %>)')!
	app.get('/', fn (mut c Context) ! {
		c.render_struct('p', NewUser{ name: 'Zed', age: 9 })!
	})
	app.post('/any', fn (mut c Context) ! {
		v := c.json_body()!
		m := v.as_map()
		c.json(m['k'] or { json2.Any('none') })
	})
	assert app.request(path: '/').body == 'Zed (9)'
	assert app.request(
		method:  'POST'
		path:    '/any'
		body:    '{"k":[1,2]}'
		headers: {
			'Content-Type': 'application/json'
		}
	).body == '[1,2]'
}

fn test_real_server_roundtrip() {
	mut app := new_app()
	app.get('/ping', fn (mut c Context) ! {
		c.text('pong')
	})
	mut s := app.server('127.0.0.1:0', show_startup_message: false, workers: 2)
	spawn fn (mut s http.Server) {
		s.listen_and_serve()
	}(mut s)
	s.wait_till_running()!
	r := http.get('http://${s.addr}/ping')!
	assert r.body == 'pong'
	assert (r.header.get_custom('X-Content-Type-Options') or { '' }) == 'nosniff'
	s.close()
}

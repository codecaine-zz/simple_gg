module main

import webutils
import json2
import net.http

struct Todo {
	title string
	done  bool
}

fn cookie_of(r http.Response, name string) string {
	for v in r.header.custom_values('Set-Cookie') {
		if v.starts_with('${name}=') {
			return v.all_before(';')
		}
	}
	return ''
}

fn run() ! {
	println('=== webutils Demo ===')

	// 1. Template engine on its own (EJS syntax, auto-escaped, sandboxed)
	out := webutils.render_string('<h1><%= title | upper %></h1><% for i, t in todos %><%= loop.index %>.<%= t %> <% end %>', {
		'title': json2.Any('my <list>')
		'todos': webutils.to_any(['a', 'b'])
	})!
	println('Template : ${out}')
	assert out == '<h1>MY &lt;LIST&gt;</h1>1.a 2.b '

	// 2. App with batteries included
	mut app := webutils.new_app(secret: 'demo-secret-change-me')
	app.locals['site'] = 'Todo App'
	app.views.add('layout', '<title><%= site %> - <%= title %></title><main><%- body %></main>')!
	app.views.add('partials/todo', '<li><%= todo.title %><% if todo.done %> ✓<% end %></li>')!
	app.views.add('index',
		'<% layout \'layout\' %><ul><% for todo in todos %><%- include(\'partials/todo\') %><% else %><li>empty</li><% end %></ul><form><input name="_csrf" value="<%= csrf_token %>"></form>')!

	app.use(webutils.request_id())
	app.use(webutils.cors(origins: ['https://app.example']))
	app.use(webutils.rate_limit(max: 100, window_ms: 60_000))
	app.use(webutils.sessions())
	app.use(webutils.csrf())

	app.get('/', fn (mut c webutils.Context) ! {
		c.render('index', {
			'title': json2.Any('Home')
			'todos': webutils.to_any([Todo{'Write <code>', true},
				Todo{'Ship it', false}])
		})!
	})
	mut api := app.group('/api')
	api.get('/users/:id', fn (mut c webutils.Context) ! {
		id := c.param('id').int()
		if id <= 0 {
			return webutils.http_error(400, 'bad id')
		}
		c.json({
			'id':   json2.Any(id)
			'name': json2.Any('user${id}')
		})
	})
	app.post('/login', fn (mut c webutils.Context) ! {
		c.session_regenerate()
		c.session_set('user', c.form_value('user'))
		c.redirect('/me')
	})
	app.get('/me', fn (mut c webutils.Context) ! {
		c.text('hello ${c.session_get('user') or { 'anon' }}')
	})

	// 3. Exercise it in-process (built-in supertest)
	home := app.request(path: '/')
	println('GET /    : ${home.status_code} ${home.body}')
	assert home.status_code == 200
	assert home.body.contains('<title>Todo App - Home</title>')
	assert home.body.contains('<li>Write &lt;code&gt; ✓</li>')
	assert home.header.get_custom('X-Content-Type-Options') or { '' } == 'nosniff'
	assert home.header.get_custom('X-Request-Id') or { '' } != ''

	user := app.request(path: '/api/users/7')
	println('GET api  : ${user.body}')
	assert user.body == '{"id":7,"name":"user7"}'
	assert app.request(path: '/api/users/0').status_code == 400
	assert app.request(path: '/nope').status_code == 404
	// unsafe methods are blocked by CSRF before routing
	assert app.request(method: 'DELETE', path: '/me').status_code == 403

	// CSRF: POST without a token is rejected, with token it passes
	assert app.request(method: 'POST', path: '/login', body: 'user=ann').status_code == 403
	token := home.body.all_after('name="_csrf" value="').all_before('"')
	cookies := '${cookie_of(home, '_csrf')}; ${cookie_of(home, 'sid')}'
	login := app.request(
		method:  'POST'
		path:    '/login'
		body:    'user=ann&_csrf=${webutils.url_encode(token)}'
		headers: {
			'Cookie':       cookies
			'Content-Type': 'application/x-www-form-urlencoded'
		}
	)
	println('POST login: ${login.status_code} -> ${login.header.get_custom('Location') or { '' }}')
	assert login.status_code == 302
	me := app.request(
		path:    '/me'
		headers: {
			'Cookie': cookie_of(login, 'sid')
		}
	)
	println('GET /me  : ${me.body}')
	assert me.body == 'hello ann'

	println('webutils demo completed successfully!')
}

fn main() {
	run() or { panic(err) }
}

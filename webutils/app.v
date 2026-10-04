module webutils

import net.http
import net.urllib
import crypto.rand
import json2

// ============================================================================
// Express-style web framework with batteries included.
//
//   mut app := webutils.new_app()
//   app.use(webutils.logger())
//   app.static('/assets', 'public')
//   app.get('/', fn (mut c webutils.Context) ! {
//       c.render('index', {'title': 'Home'})!
//   })
//   app.get('/users/:id', fn (mut c webutils.Context) ! {
//       c.json({'id': c.param('id')})
//   })
//   app.listen(3000)
//
// Secure defaults: helmet-style security headers with a per-request CSP
// nonce, auto-escaping templates, body-size limit, NUL/path validation,
// HttpOnly+SameSite cookies, HMAC-signed cookies/sessions, constant-time
// token checks, no X-Powered-By, no stack traces in responses.
// ============================================================================

// Handler is a route handler or middleware. Middleware calls `c.next()!` to
// pass control on; a handler that responds simply returns.
pub type Handler = fn (mut c Context) !

// ErrorHandler renders errors returned by handlers.
pub type ErrorHandler = fn (mut c Context, err IError)

// http_error_base offsets HTTP statuses inside built-in error codes, so they
// can't be confused with errno-style codes from other libraries.
// (V 0.5.2 runs out of memory compiling closures that `return` an IError
// value, so `http_error` returns a failing `!` result instead.)
pub const http_error_base = 7_000_000

// http_error fails the current handler with an HTTP status. Use it as
// `return webutils.http_error(404, 'user not found')` in any handler or
// middleware. The message is shown to the client, so never put secrets in it.
pub fn http_error(status int, message string) ! {
	return new_http_error(status, message)
}

// new_http_error returns the error value behind `http_error`, for functions
// that return `!T` (e.g. `return webutils.new_http_error(400, 'bad id')`).
pub fn new_http_error(status int, message string) IError {
	s := if status >= 100 && status <= 999 { status } else { 500 }
	return error_with_code(message, http_error_base + s)
}

// error_status returns the HTTP status carried by an error made with
// `http_error`, or 0 for any other error.
pub fn error_status(err IError) int {
	c := err.code()
	if c > http_error_base + 99 && c <= http_error_base + 999 {
		return c - http_error_base
	}
	return 0
}

@[params]
pub struct AppConfig {
pub:
	views_dir        string = 'views' // template directory
	view_ext         string = '.html' // template extension
	view_cache       bool   = true  // cache compiled templates (false = live reload while developing)
	secret           string // HMAC key for signed cookies, sessions and CSRF; random per process when empty
	max_body_bytes   int  = 1024 * 1024 // larger request bodies get 413
	security_headers bool = true        // helmet-style headers on every response
	security         SecurityConfig // fine-tune the security headers
	trust_proxy      bool           // honour X-Forwarded-For / X-Forwarded-Proto (only behind a trusted proxy!)
	debug            bool           // include internal error messages in 500 responses (never in production)
	strict_routing   bool           // when true, `/a/` and `/a` are different routes
	https            bool           // set when the app itself terminates TLS (marks cookies Secure)
}

struct Mw {
	prefix  string
	handler Handler @[required]
}

enum SegType {
	literal
	param
	optional
	wildcard
}

struct RouteSeg {
	kind  SegType
	value string
}

struct Route {
	method   string
	pattern  string
	segs     []RouteSeg
	slash    bool
	handlers []Handler
}

// App is the web application: router, middleware stack, views and config.
@[heap]
pub struct App {
pub:
	cfg AppConfig
pub mut:
	views  &Views
	locals map[string]json2.Any // available in every template (like Express app.locals)
mut:
	routes        []Route
	mws           []Mw
	error_handler ErrorHandler = default_error_handler
	not_found     Handler      = default_not_found
	secret_key    []u8
}

// new_app creates an application. All options have secure defaults:
// `new_app()`, or `new_app(views_dir: 'templates', secret: os.getenv('APP_SECRET'))`.
pub fn new_app(cfg AppConfig) &App {
	key := if cfg.secret != '' {
		cfg.secret.bytes()
	} else {
		rand.bytes(32) or { panic('webutils: CSPRNG unavailable: ${err}') }
	}
	return &App{
		cfg:        cfg
		views:      new_views(
			root:  cfg.views_dir
			ext:   cfg.view_ext
			cache: cfg.view_cache
		)
		secret_key: key
	}
}

// use adds middleware that runs for every request, in registration order.
pub fn (mut app App) use(handlers ...Handler) {
	for h in handlers {
		app.mws << Mw{'/', h}
	}
}

// use_at adds middleware that only runs for paths under `prefix`
// (segment-aware: `/admin` matches `/admin` and `/admin/x`, not `/administrator`).
pub fn (mut app App) use_at(prefix string, handlers ...Handler) {
	p := normalize_prefix(prefix)
	for h in handlers {
		app.mws << Mw{p, h}
	}
}

// static serves files from directory `root` under URL `prefix`
// (shorthand for `app.use(static_files(root, prefix: prefix))`).
pub fn (mut app App) static(prefix string, root string) {
	app.use(static_files(root, prefix: prefix))
}

// on_error replaces the default error handler.
pub fn (mut app App) on_error(h ErrorHandler) {
	app.error_handler = h
}

// on_not_found replaces the default 404 handler.
pub fn (mut app App) on_not_found(h Handler) {
	app.not_found = h
}

// route registers handlers for an HTTP method ('*' matches every method).
// Patterns: `/users/:id`, optional `/posts/:slug?`, wildcard `/files/*` (or `*path`).
pub fn (mut app App) route(method string, pattern string, handlers ...Handler) {
	segs := compile_pattern(pattern) or { panic('webutils: invalid route `${pattern}`: ${err}') }
	if handlers.len == 0 {
		panic('webutils: route `${method} ${pattern}` has no handlers')
	}
	app.routes << Route{
		method:   method.to_upper()
		pattern:  pattern
		segs:     segs
		slash:    pattern.len > 1 && pattern.ends_with('/')
		handlers: handlers
	}
}

pub fn (mut app App) get(pattern string, handlers ...Handler) {
	app.route('GET', pattern, ...handlers)
}

pub fn (mut app App) post(pattern string, handlers ...Handler) {
	app.route('POST', pattern, ...handlers)
}

pub fn (mut app App) put(pattern string, handlers ...Handler) {
	app.route('PUT', pattern, ...handlers)
}

pub fn (mut app App) patch(pattern string, handlers ...Handler) {
	app.route('PATCH', pattern, ...handlers)
}

pub fn (mut app App) delete(pattern string, handlers ...Handler) {
	app.route('DELETE', pattern, ...handlers)
}

pub fn (mut app App) options(pattern string, handlers ...Handler) {
	app.route('OPTIONS', pattern, ...handlers)
}

pub fn (mut app App) head(pattern string, handlers ...Handler) {
	app.route('HEAD', pattern, ...handlers)
}

// all registers handlers for every HTTP method.
pub fn (mut app App) all(pattern string, handlers ...Handler) {
	app.route('*', pattern, ...handlers)
}

// Group registers routes under a common prefix with shared middleware.
@[heap]
pub struct Group {
mut:
	app    &App
	prefix string
	mws    []Handler
}

// group creates a route group: `mut api := app.group('/api', auth)`.
pub fn (mut app App) group(prefix string, mws ...Handler) &Group {
	return &Group{
		app:    app
		prefix: normalize_prefix(prefix)
		mws:    mws
	}
}

// group creates a nested group inheriting this group's prefix and middleware.
pub fn (mut g Group) group(prefix string, mws ...Handler) &Group {
	mut all := g.mws.clone()
	all << mws
	return &Group{
		app:    g.app
		prefix: join_prefix(g.prefix, prefix)
		mws:    all
	}
}

// use adds middleware to routes registered on this group afterwards.
pub fn (mut g Group) use(handlers ...Handler) {
	g.mws << handlers
}

pub fn (mut g Group) route(method string, pattern string, handlers ...Handler) {
	mut all := g.mws.clone()
	all << handlers
	g.app.route(method, join_prefix(g.prefix, pattern), ...all)
}

pub fn (mut g Group) get(pattern string, handlers ...Handler) {
	g.route('GET', pattern, ...handlers)
}

pub fn (mut g Group) post(pattern string, handlers ...Handler) {
	g.route('POST', pattern, ...handlers)
}

pub fn (mut g Group) put(pattern string, handlers ...Handler) {
	g.route('PUT', pattern, ...handlers)
}

pub fn (mut g Group) patch(pattern string, handlers ...Handler) {
	g.route('PATCH', pattern, ...handlers)
}

pub fn (mut g Group) delete(pattern string, handlers ...Handler) {
	g.route('DELETE', pattern, ...handlers)
}

pub fn (mut g Group) all(pattern string, handlers ...Handler) {
	g.route('*', pattern, ...handlers)
}

fn normalize_prefix(p string) string {
	mut s := p.trim_space()
	if !s.starts_with('/') {
		s = '/' + s
	}
	for s.len > 1 && s.ends_with('/') {
		s = s[..s.len - 1]
	}
	return s
}

fn join_prefix(prefix string, pattern string) string {
	if prefix == '/' {
		return if pattern.starts_with('/') { pattern } else { '/' + pattern }
	}
	if pattern == '' || pattern == '/' {
		return prefix
	}
	return prefix + if pattern.starts_with('/') { pattern } else { '/' + pattern }
}

fn prefix_matches(prefix string, path string) bool {
	return prefix == '/' || path == prefix || path.starts_with(prefix + '/')
}

fn compile_pattern(pattern string) ![]RouteSeg {
	if !pattern.starts_with('/') && pattern != '*' {
		return error('route must start with `/`')
	}
	mut segs := []RouteSeg{}
	parts := pattern.split('/').filter(it != '')
	for i, p in parts {
		if p.starts_with(':') {
			mut name := p[1..]
			mut kind := SegType.param
			if name.ends_with('?') {
				name = name[..name.len - 1]
				kind = .optional
			}
			if name == '' || name.bytes().any(!is_ident_char(it)) {
				return error('invalid parameter name `${p}`')
			}
			segs << RouteSeg{kind, name}
		} else if p.starts_with('*') {
			if i != parts.len - 1 {
				return error('wildcard must be the last segment')
			}
			segs << RouteSeg{.wildcard, if p.len > 1 { p[1..] } else { '*' }}
		} else {
			segs << RouteSeg{.literal, p}
		}
	}
	return segs
}

fn match_segs(segs []RouteSeg, parts []string) ?map[string]string {
	mut params := map[string]string{}
	mut i := 0
	for s in segs {
		match s.kind {
			.literal {
				if i >= parts.len || parts[i] != s.value {
					return none
				}
				i++
			}
			.param {
				if i >= parts.len {
					return none
				}
				params[s.value] = parts[i]
				i++
			}
			.optional {
				if i < parts.len {
					params[s.value] = parts[i]
					i++
				}
			}
			.wildcard {
				params[s.value] = parts[i..].join('/')
				return params
			}
		}
	}
	if i != parts.len {
		return none
	}
	return params
}

// split_path splits a raw URL path into percent-decoded segments.
// Encoded slashes stay inside their segment (`a%2Fb` is one segment).
fn split_path(raw string) ![]string {
	mut out := []string{}
	for p in raw.split('/') {
		if p == '' {
			continue
		}
		d := urllib.path_unescape(p) or { return error('malformed percent-encoding') }
		if d.contains('\0') {
			return error('NUL byte in path')
		}
		out << d
	}
	return out
}

// handle runs one request through the app and returns the response. It is
// transport-independent, which makes apps trivially unit-testable (see `request`).
pub fn (mut app App) handle(req http.Request) http.Response {
	mut c := new_context(app, req)
	if app.cfg.security_headers {
		apply_security_headers(mut c, app.cfg.security)
	}
	raw_path := c.path
	if !raw_path.starts_with('/') && !(raw_path == '*' && c.method == 'OPTIONS') {
		c.fail(400, 'Bad Request')
		return c.to_response()
	}
	parts := split_path(raw_path) or {
		c.fail(400, 'Bad Request')
		return c.to_response()
	}
	if req.data.len > app.cfg.max_body_bytes {
		c.fail(413, 'Payload Too Large')
		return c.to_response()
	}
	trailing := raw_path.len > 1 && raw_path.ends_with('/')
	mut chain := []Handler{cap: app.mws.len + 4}
	for m in app.mws {
		if prefix_matches(m.prefix, raw_path) {
			chain << m.handler
		}
	}
	mut found := false
	for attempt in 0 .. 2 {
		method := if attempt == 1 { 'GET' } else { c.method }
		if attempt == 1 && c.method != 'HEAD' {
			break
		}
		for r in app.routes {
			if r.method != method && r.method != '*' {
				continue
			}
			if app.cfg.strict_routing && r.slash != trailing {
				continue
			}
			if params := match_segs(r.segs, parts) {
				c.params = params.clone()
				chain << r.handlers
				found = true
				break
			}
		}
		if found {
			break
		}
	}
	if !found {
		mut allowed := []string{}
		for r in app.routes {
			if r.method != '*' && r.method !in allowed && match_segs(r.segs, parts) != none {
				allowed << r.method
			}
		}
		if allowed.len > 0 {
			if 'GET' in allowed && 'HEAD' !in allowed {
				allowed << 'HEAD'
			}
			allowed << 'OPTIONS'
			c.set_header('Allow', allowed.join(', '))
			chain << if c.method == 'OPTIONS' { auto_options } else { method_not_allowed }
		} else {
			chain << app.not_found
		}
	}
	c.chain = chain
	c.next() or {
		app.error_handler(mut c, err)
	}
	return c.to_response()
}

fn auto_options(mut c Context) ! {
	c.send_status(204)
}

fn method_not_allowed(mut _ Context) ! {
	return http_error(405, 'Method Not Allowed')
}

fn default_not_found(mut _ Context) ! {
	return http_error(404, 'Not Found')
}

fn default_error_handler(mut c Context, err IError) {
	mut status := 500
	mut message := 'Internal Server Error'
	hs := error_status(err)
	if hs > 0 {
		status = hs
		message = err.msg()
	} else {
		eprintln('[webutils] ${c.method} ${c.path} -> 500: ${err.msg()}')
		if c.app.cfg.debug {
			message = err.msg()
		}
	}
	c.fail(status, message)
}

// TestRequest describes a request for App.request (in-process testing).
@[params]
pub struct TestRequest {
pub:
	method      string = 'GET'
	path        string = '/'
	body        string
	headers     map[string]string
	remote_addr string = '127.0.0.1:40000'
}

// request performs an in-process request without opening a socket — the
// built-in equivalent of supertest: `res := app.request(path: '/users/1')`.
pub fn (mut app App) request(t TestRequest) http.Response {
	mut req := http.Request{
		method:      method_from_string(t.method)
		url:         t.path
		data:        t.body
		remote_addr: t.remote_addr
		header:      http.new_header()
	}
	for k, v in t.headers {
		req.header.add_custom(k, v) or {}
	}
	return app.handle(req)
}

fn method_from_string(m string) http.Method {
	return match m.to_upper() {
		'POST' { .post }
		'PUT' { .put }
		'PATCH' { .patch }
		'DELETE' { .delete }
		'HEAD' { .head }
		'OPTIONS' { .options }
		'TRACE' { .trace }
		'CONNECT' { .connect }
		else { .get }
	}
}

struct AppHandler {
mut:
	app &App
}

fn (mut h AppHandler) handle(req http.Request) http.Response {
	return h.app.handle(req)
}

@[params]
pub struct ListenOptions {
pub:
	workers              int // 0 = one per CPU
	show_startup_message bool = true
}

// server builds (but does not start) an `http.Server` for this app, for
// callers that need `stop()`/`close()` or TLS fields: `mut s := app.server(':8080')`.
pub fn (mut app App) server(addr string, opts ListenOptions) &http.Server {
	mut s := &http.Server{
		addr:                 addr
		handler:              AppHandler{app}
		show_startup_message: opts.show_startup_message
	}
	if opts.workers > 0 {
		s.worker_num = opts.workers
	}
	return s
}

// listen serves the app on `port` (blocking).
pub fn (mut app App) listen(port int, opts ListenOptions) {
	app.listen_addr(':${port}', opts)
}

// listen_addr serves the app on an address such as `127.0.0.1:8080` (blocking).
pub fn (mut app App) listen_addr(addr string, opts ListenOptions) {
	mut s := app.server(addr, opts)
	s.listen_and_serve()
}

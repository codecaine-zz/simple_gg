module webutils

import net.http
import net.urllib
import os
import time
import crypto.hmac
import crypto.sha256
import crypto.rand
import encoding.base64
import json2

// Context carries one request and its response (like Express `req` + `res`).
pub struct Context {
pub mut:
	req         http.Request         // the raw request
	method      string               // upper-case method, e.g. 'GET'
	path        string               // raw (still percent-encoded) path without query string
	params      map[string]string    // decoded route parameters (`:id`, `*`)
	locals      map[string]json2.Any // per-request template data (like Express res.locals)
	status_code int = 200
	res_headers http.Header // response headers
	res_body    string      // response body
	sent        bool        // a response method has been called
	csp_nonce   string      // per-request CSP nonce: `<script nonce="<%= csp_nonce %>">`
	request_id  string
	started     time.Time
mut:
	app           &App = unsafe { nil }
	chain         []Handler
	idx           int
	query_map     map[string][]string
	cookies       map[string]string
	sess          map[string]string
	session_on    bool
	session_dirty bool
	session_kill  bool
	session_regen bool
	csrf_secret   string
	form_parsed   bool
	form_map      map[string][]string
	files_map     map[string][]http.FileData
}

fn new_context(app &App, req http.Request) Context {
	raw := req.url
	q := raw.index('?') or { -1 }
	path := if q >= 0 { raw[..q] } else { raw }
	mut c := Context{
		req:         req
		method:      req.method.str().to_upper()
		path:        if path == '' { '/' } else { path }
		app:         app
		res_headers: http.new_header()
		started:     time.now()
	}
	if q >= 0 {
		c.query_map = parse_urlencoded(raw[q + 1..])
	}
	c.cookies = parse_cookie_header(c.header('Cookie'))
	return c
}

// next runs the next middleware/handler in the chain.
pub fn (mut c Context) next() ! {
	if c.idx < c.chain.len {
		h := c.chain[c.idx]
		c.idx++
		h(mut c)!
	}
}

fn parse_urlencoded(s string) map[string][]string {
	mut m := map[string][]string{}
	for pair in s.split('&') {
		if pair == '' {
			continue
		}
		kv := pair.split_nth('=', 2)
		k := urllib.query_unescape(kv[0]) or { continue }
		v := if kv.len > 1 { urllib.query_unescape(kv[1]) or { continue } } else { '' }
		m[k] << v
	}
	return m
}

fn parse_cookie_header(h string) map[string]string {
	mut m := map[string]string{}
	if h == '' {
		return m
	}
	for part in h.split(';') {
		kv := part.trim_space().split_nth('=', 2)
		if kv.len != 2 || kv[0] == '' {
			continue
		}
		mut v := kv[1].trim_space()
		if v.len >= 2 && v.starts_with('"') && v.ends_with('"') {
			v = v[1..v.len - 1]
		}
		name := kv[0].trim_space()
		if name !in m {
			m[name] = urllib.path_unescape(v) or { v }
		}
	}
	return m
}

// ---------------------------------------------------------------------------
// Request helpers
// ---------------------------------------------------------------------------

// param returns a decoded route parameter ('' when absent).
pub fn (c &Context) param(name string) string {
	return c.params[name] or { '' }
}

// query returns the first value of a query-string parameter ('' when absent).
pub fn (c &Context) query(name string) string {
	vals := c.query_map[name] or { return '' }
	return if vals.len > 0 { vals[0] } else { '' }
}

// query_or returns a query parameter or `def` when it is missing or empty.
pub fn (c &Context) query_or(name string, def string) string {
	v := c.query(name)
	return if v == '' { def } else { v }
}

// query_int parses a query parameter as an integer, returning `def` when
// missing or malformed.
pub fn (c &Context) query_int(name string, def int) int {
	v := c.query(name).trim_space()
	if v == '' {
		return def
	}
	for i, ch in v {
		if !(ch.is_digit() || (i == 0 && (ch == `-` || ch == `+`))) {
			return def
		}
	}
	return v.int()
}

// query_values returns every value for a repeated query parameter (`?t=a&t=b`).
pub fn (c &Context) query_values(name string) []string {
	return c.query_map[name] or { []string{} }
}

// queries returns all query parameters (first value of each).
pub fn (c &Context) queries() map[string]string {
	mut m := map[string]string{}
	for k, v in c.query_map {
		if v.len > 0 {
			m[k] = v[0]
		}
	}
	return m
}

// header returns a request header (case-insensitive, '' when absent).
pub fn (c &Context) header(name string) string {
	return c.req.header.get_custom(name) or { '' }
}

// content_type returns the request media type, lower-cased, without parameters.
pub fn (c &Context) content_type() string {
	return c.header('Content-Type').all_before(';').trim_space().to_lower()
}

// is_json reports whether the request body is declared as JSON.
pub fn (c &Context) is_json() bool {
	ct := c.content_type()
	return ct == 'application/json' || (ct.starts_with('application/') && ct.ends_with('+json'))
}

// body returns the raw request body.
pub fn (c &Context) body() string {
	return c.req.data
}

// bind_json decodes a JSON request body into `T`. Requires a JSON
// Content-Type (415 otherwise — blocks cross-site `text/plain` JSON CSRF);
// malformed JSON yields 400.
pub fn (c &Context) bind_json[T]() !T {
	if !c.is_json() {
		return new_http_error(415, 'expected Content-Type: application/json')
	}
	return json2.decode[T](c.req.data) or { return new_http_error(400, 'invalid JSON body') }
}

// json_body decodes a JSON request body into a dynamic value.
pub fn (c &Context) json_body() !json2.Any {
	if !c.is_json() {
		return new_http_error(415, 'expected Content-Type: application/json')
	}
	return parse_json(c.req.data) or { return new_http_error(400, 'invalid JSON body') }
}

fn (mut c Context) parse_form() {
	if c.form_parsed {
		return
	}
	c.form_parsed = true
	ct := c.content_type()
	if ct == 'application/x-www-form-urlencoded' {
		c.form_map = parse_urlencoded(c.req.data)
	} else if ct == 'multipart/form-data' {
		full := c.header('Content-Type')
		mut boundary := ''
		for p in full.split(';') {
			kv := p.trim_space().split_nth('=', 2)
			if kv.len == 2 && kv[0].to_lower() == 'boundary' {
				boundary = kv[1].trim('"')
			}
		}
		if boundary == '' || boundary.len > 200 {
			return
		}
		parse_multipart(c.req.data, boundary, mut c.form_map, mut c.files_map)
	}
}

// form returns urlencoded or multipart form fields (first value of each).
pub fn (mut c Context) form() map[string]string {
	c.parse_form()
	mut m := map[string]string{}
	for k, v in c.form_map {
		if v.len > 0 {
			m[k] = v[0]
		}
	}
	return m
}

// form_value returns one form field ('' when absent).
pub fn (mut c Context) form_value(name string) string {
	c.parse_form()
	vals := c.form_map[name] or { return '' }
	return if vals.len > 0 { vals[0] } else { '' }
}

// form_values returns all values of a repeated form field.
pub fn (mut c Context) form_values(name string) []string {
	c.parse_form()
	return c.form_map[name] or { []string{} }
}

// files returns uploaded files for a multipart field.
pub fn (mut c Context) files(name string) []http.FileData {
	c.parse_form()
	return c.files_map[name] or { []http.FileData{} }
}

// file returns the first uploaded file for a multipart field.
pub fn (mut c Context) file(name string) ?http.FileData {
	fs := c.files(name)
	return if fs.len > 0 { fs[0] } else { none }
}

// cookie returns a request cookie value.
pub fn (c &Context) cookie(name string) ?string {
	return c.cookies[name] or { return none }
}

// signed_cookie returns a cookie set with `set_signed_cookie`, or none when
// missing or tampered with (verified in constant time).
pub fn (c &Context) signed_cookie(name string) ?string {
	raw := c.cookies[name] or { return none }
	return unsign_value(c.app.secret_key, name, raw)
}

// ip returns the client IP. With AppConfig.trust_proxy the left-most
// X-Forwarded-For address is used; otherwise the socket peer address.
pub fn (c &Context) ip() string {
	if c.app.cfg.trust_proxy {
		xff := c.header('X-Forwarded-For')
		if xff != '' {
			return xff.all_before(',').trim_space()
		}
		real := c.header('X-Real-Ip')
		if real != '' {
			return real.trim_space()
		}
	}
	addr := c.req.remote_addr
	if addr.starts_with('[') {
		return addr.all_before(']')[1..]
	}
	if addr.count(':') == 1 {
		return addr.all_before(':')
	}
	return addr
}

// protocol returns 'https' or 'http' (X-Forwarded-Proto honoured with trust_proxy).
pub fn (c &Context) protocol() string {
	if c.app.cfg.trust_proxy {
		p := c.header('X-Forwarded-Proto').all_before(',').trim_space().to_lower()
		if p in ['http', 'https'] {
			return p
		}
	}
	return if c.app.cfg.https { 'https' } else { 'http' }
}

// secure reports whether the request arrived over HTTPS.
pub fn (c &Context) secure() bool {
	return c.protocol() == 'https'
}

// hostname returns the Host header without port.
pub fn (c &Context) hostname() string {
	host := c.header('Host')
	if host.starts_with('[') {
		return host.all_before(']') + ']'
	}
	return host.all_before(':')
}

// xhr reports whether the request was made with X-Requested-With: XMLHttpRequest.
pub fn (c &Context) xhr() bool {
	return c.header('X-Requested-With').to_lower() == 'xmlhttprequest'
}

fn expand_type(t string) string {
	return match t {
		'json' { 'application/json' }
		'html' { 'text/html' }
		'text' { 'text/plain' }
		'xml' { 'application/xml' }
		'css' { 'text/css' }
		'js', 'javascript' { 'text/javascript' }
		else { t }
	}
}

// accepts picks the best of `types` for the request's Accept header
// (q-values honoured; shorthands 'json', 'html', 'text', 'xml'). Returns the
// matching entry from `types`, or '' when none is acceptable.
pub fn (c &Context) accepts(types ...string) string {
	if types.len == 0 {
		return ''
	}
	accept := c.header('Accept')
	if accept.trim_space() == '' {
		return types[0]
	}
	mut best := ''
	mut best_q := 0.0
	for t in types {
		full := expand_type(t)
		for item in accept.split(',') {
			parts := item.split(';')
			mt := parts[0].trim_space().to_lower()
			mut q := 1.0
			for p in parts[1..] {
				kv := p.trim_space().split_nth('=', 2)
				if kv.len == 2 && kv[0] == 'q' {
					q = kv[1].f64()
				}
			}
			ok := mt == full || mt == '*/*' || (mt.ends_with('/*') && full.starts_with(mt[..mt.len - 1]))
			if ok && q > best_q {
				best_q = q
				best = t
			}
		}
	}
	return best
}

// ---------------------------------------------------------------------------
// Response helpers
// ---------------------------------------------------------------------------

fn clean_header_value(v string) string {
	mut dirty := false
	for ch in v {
		if ch == `\r` || ch == `\n` || ch == 0 {
			dirty = true
			break
		}
	}
	if !dirty {
		return v
	}
	mut out := []u8{cap: v.len}
	for ch in v {
		if ch != `\r` && ch != `\n` && ch != 0 {
			out << ch
		}
	}
	return out.bytestr()
}

// status sets the response status code.
pub fn (mut c Context) status(code int) {
	c.status_code = code
}

// set_header sets a response header (CR/LF stripped — no response splitting).
pub fn (mut c Context) set_header(name string, value string) {
	c.res_headers.set_custom(name, clean_header_value(value)) or {}
}

// add_header appends a response header value (e.g. multiple Link headers).
pub fn (mut c Context) add_header(name string, value string) {
	c.res_headers.add_custom(name, clean_header_value(value)) or {}
}

// response_header reads a response header that has been set.
pub fn (c &Context) response_header(name string) string {
	return c.res_headers.get_custom(name) or { '' }
}

// remove_header deletes a response header.
pub fn (mut c Context) remove_header(name string) {
	c.res_headers.delete_custom(name)
}

// set_content_type sets Content-Type; shorthands: 'json', 'html', 'text', 'xml', 'css', 'js'.
pub fn (mut c Context) set_content_type(t string) {
	full := expand_type(t)
	value := if full.starts_with('text/') || full == 'application/json' {
		if full.contains('charset') { full } else { '${full}; charset=utf-8' }
	} else {
		full
	}
	c.set_header('Content-Type', value)
}

// vary adds a field to the Vary header (deduplicated).
pub fn (mut c Context) vary(field string) {
	cur := c.response_header('Vary')
	if cur == '' {
		c.set_header('Vary', field)
		return
	}
	for f in cur.split(',') {
		if f.trim_space().to_lower() == field.to_lower() || f.trim_space() == '*' {
			return
		}
	}
	c.set_header('Vary', '${cur}, ${field}')
}

fn (mut c Context) write_body(ct string, body string) {
	if c.response_header('Content-Type') == '' {
		c.set_content_type(ct)
	}
	c.res_body = body
	c.sent = true
}

// text sends a plain-text response.
pub fn (mut c Context) text(s string) {
	c.set_content_type('text')
	c.res_body = s
	c.sent = true
}

// html sends an HTML response.
pub fn (mut c Context) html(s string) {
	c.set_content_type('html')
	c.res_body = s
	c.sent = true
}

// send sends a body (Content-Type defaults to text/html like Express res.send).
pub fn (mut c Context) send(s string) {
	c.write_body('html', s)
}

// send_bytes sends binary data with the given content type.
pub fn (mut c Context) send_bytes(data []u8, content_type string) {
	c.set_header('Content-Type', content_type)
	c.res_body = data.bytestr()
	c.sent = true
}

// json sends any JSON-encodable value (structs, maps, arrays, json2.Any).
pub fn (mut c Context) json[T](v T) {
	c.set_content_type('json')
	$if T is json2.Any {
		c.res_body = encode_json(v)
	} $else $if T is map[string]json2.Any {
		c.res_body = encode_json(json2.Any(v))
	} $else $if T is []json2.Any {
		c.res_body = encode_json(json2.Any(v))
	} $else {
		c.res_body = json2.encode(v)
	}
	c.sent = true
}

// json_any sends a dynamic json2.Any value as JSON (non-generic, compiles fast).
pub fn (mut c Context) json_any(v json2.Any) {
	c.set_content_type('json')
	c.res_body = encode_json(v)
	c.sent = true
}

// send_status sends just a status code with its reason phrase as body.
pub fn (mut c Context) send_status(code int) {
	c.status_code = code
	if code == 204 || code == 304 {
		c.res_body = ''
		c.sent = true
		return
	}
	c.text(http.status_from_int(code).str())
}

// no_content sends 204 No Content.
pub fn (mut c Context) no_content() {
	c.send_status(204)
}

// render renders a view with `data`, merged over app.locals and c.locals
// (which include `csrf_token` and `csp_nonce` when those features are on).
pub fn (mut c Context) render(view string, data map[string]json2.Any) ! {
	mut merged := c.app.locals.clone()
	for k, v in c.locals {
		merged[k] = v
	}
	if c.csp_nonce != '' && 'csp_nonce' !in merged {
		merged['csp_nonce'] = json2.Any(c.csp_nonce)
	}
	for k, v in data {
		merged[k] = v
	}
	out := c.app.views.render(view, merged)!
	c.html(out)
}

// render_struct renders a view with the fields of any struct/map as data.
pub fn (mut c Context) render_struct[T](view string, data T) ! {
	a := to_any(data)
	if a is map[string]json2.Any {
		c.render(view, a)!
		return
	}
	return error('render_struct: data must encode to a JSON object')
}

// redirect sends a 302 redirect. CR/LF are stripped from the location.
// For user-supplied targets use `safe_redirect` to prevent open redirects.
pub fn (mut c Context) redirect(location string) {
	c.redirect_with(302, location)
}

// redirect_with sends a redirect with a specific status (301, 302, 303, 307, 308).
pub fn (mut c Context) redirect_with(code int, location string) {
	loc := clean_header_value(location)
	c.status_code = if code >= 300 && code < 400 { code } else { 302 }
	c.set_header('Location', loc)
	c.html('<p>Redirecting to <a href="${escape_html(loc)}">${escape_html(loc)}</a></p>')
}

// is_local_url reports whether `u` is a same-origin relative path (starts
// with a single `/`, no scheme, no `//` or `/\` protocol-relative tricks).
pub fn is_local_url(u string) bool {
	if u.len == 0 || u[0] != `/` {
		return false
	}
	if u.len > 1 && (u[1] == `/` || u[1] == `\\`) {
		return false
	}
	for ch in u {
		if ch < 0x20 || ch == 0x7f {
			return false
		}
	}
	return true
}

// safe_redirect redirects to `target` only if it is a local path, otherwise
// to `fallback` — use for `?next=` / `?return_to=` parameters.
pub fn (mut c Context) safe_redirect(target string, fallback string) {
	c.redirect(if is_local_url(target) { target } else { fallback })
}

// fail sends an error response as JSON or HTML depending on Accept.
pub fn (mut c Context) fail(status int, message string) {
	c.status_code = status
	c.remove_header('Content-Type')
	c.remove_header('Content-Disposition')
	if c.accepts('html', 'json') == 'json' {
		c.json_any(json2.Any({
			'error':  json2.Any(message)
			'status': json2.Any(status)
		}))
		return
	}
	reason := escape_html(http.status_from_int(status).str())
	c.html('<!doctype html><html><head><meta charset="utf-8"><title>${status} ${reason}</title></head><body><h1>${status} ${reason}</h1><p>${escape_html(message)}</p></body></html>')
}

// ---------------------------------------------------------------------------
// Cookies
// ---------------------------------------------------------------------------

// SameSite controls cross-site cookie sending.
pub enum SameSite {
	lax            // default: sent on top-level navigations, blocks most CSRF
	strict         // never sent cross-site
	no_restriction // `SameSite=None` (forces Secure)
}

@[params]
pub struct CookieOptions {
pub:
	path      string = '/'
	domain    string
	max_age   int  // seconds; 0 = browser-session cookie; < 0 deletes
	secure    bool // auto-enabled on HTTPS requests and for SameSite=None
	http_only bool     = true // hide from JavaScript (XSS cannot steal it)
	same_site SameSite = .lax
}

fn valid_cookie_name(n string) bool {
	if n.len == 0 || n.len > 256 {
		return false
	}
	for ch in n {
		if ch <= 0x20 || ch >= 0x7f || ch in [`(`, `)`, `<`, `>`, `@`, `,`, `;`, `:`, `\\`, `"`,
			`/`, `[`, `]`, `?`, `=`, `{`, `}`] {
			return false
		}
	}
	return true
}

// set_cookie sets a cookie with secure defaults (HttpOnly, SameSite=Lax,
// Path=/, Secure on HTTPS). The value is percent-encoded.
pub fn (mut c Context) set_cookie(name string, value string, opts CookieOptions) {
	if !valid_cookie_name(name) {
		return
	}
	mut s := '${name}=${url_encode(value)}'
	if opts.path != '' {
		s += '; Path=${clean_header_value(opts.path).replace(';', '')}'
	}
	if opts.domain != '' {
		s += '; Domain=${clean_header_value(opts.domain).replace(';', '')}'
	}
	if opts.max_age > 0 {
		exp := time.utc().add_seconds(opts.max_age)
		s += '; Max-Age=${opts.max_age}; Expires=${exp.http_header_string()}'
	} else if opts.max_age < 0 {
		s += '; Max-Age=0; Expires=Thu, 01 Jan 1970 00:00:00 GMT'
	}
	if opts.http_only {
		s += '; HttpOnly'
	}
	s += match opts.same_site {
		.lax { '; SameSite=Lax' }
		.strict { '; SameSite=Strict' }
		.no_restriction { '; SameSite=None' }
	}
	if opts.secure || opts.same_site == .no_restriction || c.secure() {
		s += '; Secure'
	}
	c.res_headers.add_custom('Set-Cookie', s) or {}
}

// clear_cookie deletes a cookie (path/domain must match how it was set).
pub fn (mut c Context) clear_cookie(name string, opts CookieOptions) {
	c.set_cookie(name, '', CookieOptions{
		...opts
		max_age: -1
	})
}

fn sign_value(key []u8, name string, value string) string {
	mac := hmac.new(key, '${name}=${value}'.bytes(), sha256.sum, sha256.block_size)
	return 's:${value}.${base64.url_encode(mac)}'
}

fn unsign_value(key []u8, name string, raw string) ?string {
	if !raw.starts_with('s:') {
		return none
	}
	body := raw[2..]
	dot := body.last_index('.') or { return none }
	value := body[..dot]
	expected := sign_value(key, name, value)
	if hmac.equal(expected.bytes(), raw.bytes()) {
		return value
	}
	return none
}

// set_signed_cookie sets a cookie whose value is HMAC-SHA256 signed with the
// app secret; read it back with `signed_cookie` (tampering is rejected).
pub fn (mut c Context) set_signed_cookie(name string, value string, opts CookieOptions) {
	c.set_cookie(name, sign_value(c.app.secret_key, name, value), opts)
}

// random_token returns a URL-safe random token from `n_bytes` CSPRNG bytes.
pub fn random_token(n_bytes int) string {
	b := rand.bytes(n_bytes) or { panic('webutils: CSPRNG unavailable: ${err}') }
	return base64.url_encode(b)
}

// ---------------------------------------------------------------------------
// Files
// ---------------------------------------------------------------------------

// content_disposition builds a safe RFC 6266 Content-Disposition value with
// an ASCII fallback and a UTF-8 `filename*`.
pub fn content_disposition(kind string, filename string) string {
	base := os.base(filename.replace('\\', '/'))
	mut ascii := []u8{}
	for ch in base {
		ascii << if ch < 0x20 || ch >= 0x7f || ch == `"` || ch == `\\` || ch == `%` || ch == `;` {
			`_`
		} else {
			ch
		}
	}
	return '${kind}; filename="${ascii.bytestr()}"; filename*=UTF-8\'\'${url_encode(base)}'
}

// attachment marks the response as a download with the given filename.
pub fn (mut c Context) attachment(filename string) {
	c.set_header('Content-Disposition', content_disposition('attachment', filename))
}

// send_file sends a file from disk (Content-Type from its extension,
// ETag/Last-Modified with 304 support). The path is used as given — never
// pass user input here; use `static_files` or `safe_join` for that.
pub fn (mut c Context) send_file(path string) ! {
	if !os.is_file(path) {
		return http_error(404, 'Not Found')
	}
	serve_file(mut c, path, 0)!
}

// download sends a file as an attachment named `filename`.
pub fn (mut c Context) download(path string, filename string) ! {
	c.attachment(if filename == '' { os.base(path) } else { filename })
	c.send_file(path)!
}

fn (mut c Context) to_response() http.Response {
	mut resp := http.Response{
		body:   c.res_body
		header: c.res_headers
	}
	resp.set_version(.v1_1)
	resp.set_status(http.status_from_int(c.status_code))
	resp.status_code = c.status_code
	if c.status_code == 204 || c.status_code == 304 || (c.status_code >= 100 && c.status_code < 200) {
		resp.body = ''
		resp.header.delete(.content_length)
	} else {
		resp.header.set(.content_length, c.res_body.len.str())
	}
	if c.method == 'HEAD' {
		resp.body = ''
	}
	return resp
}

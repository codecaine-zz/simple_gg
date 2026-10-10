module webutils

import compress.gzip
import crypto.hmac
import crypto.sha256
import encoding.base64
import sync
import time

// ============================================================================
// Built-in middleware — replaces helmet, cors, express-rate-limit, csurf,
// morgan, compression, basic-auth and request-id packages.
// ============================================================================

// default_csp mirrors helmet's default Content-Security-Policy.
pub const default_csp = "default-src 'self';base-uri 'self';font-src 'self' https: data:;form-action 'self';frame-ancestors 'self';img-src 'self' data:;object-src 'none';script-src 'self';script-src-attr 'none';style-src 'self' https: 'unsafe-inline';upgrade-insecure-requests"

// SecurityConfig tunes the helmet-style headers. Set a field to '' to omit
// that header.
@[params]
pub struct SecurityConfig {
pub:
	csp                  string = default_csp
	csp_nonce            bool   = true // add a per-request 'nonce-…' to script-src (exposed as `csp_nonce`)
	hsts                 string = 'max-age=31536000; includeSubDomains'
	frame_options        string = 'SAMEORIGIN'
	referrer_policy      string = 'no-referrer'
	content_type_options string = 'nosniff'
	coop                 string = 'same-origin' // Cross-Origin-Opener-Policy
	corp                 string = 'same-origin' // Cross-Origin-Resource-Policy
	origin_agent_cluster string = '?1'
	dns_prefetch_control string = 'off'
	download_options     string = 'noopen'
	cross_domain_policy  string = 'none'
	xss_protection       string = '0' // modern recommendation: disable the legacy XSS auditor
	permissions_policy   string // e.g. 'camera=(), microphone=(), geolocation=()'
}

fn apply_security_headers(mut c Context, s SecurityConfig) {
	if s.csp != '' {
		mut csp := s.csp
		if s.csp_nonce {
			c.csp_nonce = random_token(16)
			if csp.contains('script-src ') {
				csp = csp.replace('script-src ', "script-src 'nonce-${c.csp_nonce}' ")
			} else {
				csp += ";script-src 'self' 'nonce-${c.csp_nonce}'"
			}
		}
		c.set_header('Content-Security-Policy', csp)
	}
	pairs := [
		['Strict-Transport-Security', s.hsts],
		['X-Frame-Options', s.frame_options],
		['Referrer-Policy', s.referrer_policy],
		['X-Content-Type-Options', s.content_type_options],
		['Cross-Origin-Opener-Policy', s.coop],
		['Cross-Origin-Resource-Policy', s.corp],
		['Origin-Agent-Cluster', s.origin_agent_cluster],
		['X-DNS-Prefetch-Control', s.dns_prefetch_control],
		['X-Download-Options', s.download_options],
		['X-Permitted-Cross-Domain-Policies', s.cross_domain_policy],
		['X-XSS-Protection', s.xss_protection],
		['Permissions-Policy', s.permissions_policy],
	]
	for p in pairs {
		if p[1] != '' {
			c.set_header(p[0], p[1])
		}
	}
}

// security_headers returns the helmet-style headers as middleware (useful
// when AppConfig.security_headers is false and you want them on some paths).
pub fn security_headers(cfg SecurityConfig) Handler {
	return fn [cfg] (mut c Context) ! {
		apply_security_headers(mut c, cfg)
		c.next()!
	}
}

// ---------------------------------------------------------------------------
// Logger (morgan-like)
// ---------------------------------------------------------------------------

pub type LogFn = fn (line string)

fn default_log(line string) {
	println(line)
}

@[params]
pub struct LoggerConfig {
pub:
	output LogFn = default_log
}

// logger logs `METHOD /path STATUS 1.23ms 512B` for each request.
pub fn logger(cfg LoggerConfig) Handler {
	return fn [cfg] (mut c Context) ! {
		sw := time.new_stopwatch()
		c.next() or {
			cfg.output('${c.method} ${c.path} ERR ${fmt_ms(sw.elapsed())} ${err.msg()}')
			return err
		}
		cfg.output('${c.method} ${c.path} ${c.status_code} ${fmt_ms(sw.elapsed())} ${c.res_body.len}B')
	}
}

fn fmt_ms(d time.Duration) string {
	return '${f64(d.microseconds()) / 1000.0:.2f}ms'
}

// ---------------------------------------------------------------------------
// CORS
// ---------------------------------------------------------------------------

@[params]
pub struct CorsConfig {
pub:
	origins         []string = ['*'] // allowed origins; '*' = any (never combined with credentials)
	methods         []string = ['GET', 'HEAD', 'PUT', 'PATCH', 'POST', 'DELETE']
	allowed_headers []string // empty = reflect Access-Control-Request-Headers
	exposed_headers []string
	credentials     bool
	max_age         int = 600 // preflight cache seconds
}

// cors handles CORS and preflight requests. With `credentials: true` only
// explicitly listed origins are reflected — `*` is never sent with credentials.
pub fn cors(cfg CorsConfig) Handler {
	return fn [cfg] (mut c Context) ! {
		origin := c.header('Origin')
		c.vary('Origin')
		if origin != '' {
			any_origin := '*' in cfg.origins
			listed := origin in cfg.origins
			if listed || (any_origin && !cfg.credentials) {
				c.set_header('Access-Control-Allow-Origin', if listed && cfg.credentials {
					origin
				} else if any_origin {
					'*'
				} else {
					origin
				})
				if cfg.credentials {
					c.set_header('Access-Control-Allow-Credentials', 'true')
				}
				if cfg.exposed_headers.len > 0 {
					c.set_header('Access-Control-Expose-Headers', cfg.exposed_headers.join(', '))
				}
				if c.method == 'OPTIONS' && c.header('Access-Control-Request-Method') != '' {
					c.set_header('Access-Control-Allow-Methods', cfg.methods.join(', '))
					hdrs := if cfg.allowed_headers.len > 0 {
						cfg.allowed_headers.join(', ')
					} else {
						c.header('Access-Control-Request-Headers')
					}
					if hdrs != '' {
						c.set_header('Access-Control-Allow-Headers', hdrs)
					}
					c.set_header('Access-Control-Max-Age', cfg.max_age.str())
					c.send_status(204)
					return
				}
			}
		}
		c.next()!
	}
}

// ---------------------------------------------------------------------------
// Rate limiting (fixed window, in-memory, thread-safe)
// ---------------------------------------------------------------------------

pub type KeyFn = fn (c &Context) string

fn default_rate_key(c &Context) string {
	return c.ip()
}

@[params]
pub struct RateLimitConfig {
pub:
	window_ms int    = 60_000
	max       int    = 100
	message   string = 'Too many requests, please try again later.'
	key       KeyFn  = default_rate_key // bucket key (default: client IP)
	headers   bool   = true             // send RateLimit-* headers (IETF draft)
}

struct RateEntry {
mut:
	count    int
	reset_at i64
}

@[heap]
struct RateStore {
mut:
	mu      &sync.Mutex = sync.new_mutex()
	hits    map[string]RateEntry
	last_gc i64
}

// rate_limit limits each client to `max` requests per `window_ms`;
// excess requests get 429 with Retry-After.
pub fn rate_limit(cfg RateLimitConfig) Handler {
	mut store := &RateStore{}
	return fn [cfg, mut store] (mut c Context) ! {
		key := cfg.key(c)
		now := time.now().unix_milli()
		store.mu.lock()
		if now - store.last_gc > i64(cfg.window_ms) && store.hits.len > 1000 {
			mut dead := []string{}
			for k, e in store.hits {
				if e.reset_at <= now {
					dead << k
				}
			}
			for k in dead {
				store.hits.delete(k)
			}
			store.last_gc = now
		}
		mut e := store.hits[key] or { RateEntry{} }
		if e.reset_at <= now {
			e = RateEntry{0, now + i64(cfg.window_ms)}
		}
		e.count++
		store.hits[key] = e
		store.mu.unlock()
		remaining := if cfg.max - e.count > 0 { cfg.max - e.count } else { 0 }
		reset_s := (e.reset_at - now + 999) / 1000
		if cfg.headers {
			c.set_header('RateLimit-Limit', cfg.max.str())
			c.set_header('RateLimit-Remaining', remaining.str())
			c.set_header('RateLimit-Reset', reset_s.str())
		}
		if e.count > cfg.max {
			c.set_header('Retry-After', reset_s.str())
			return http_error(429, cfg.message)
		}
		c.next()!
	}
}

// ---------------------------------------------------------------------------
// Request ID
// ---------------------------------------------------------------------------

fn valid_request_id(s string) bool {
	if s.len == 0 || s.len > 128 {
		return false
	}
	for ch in s {
		if !(ch.is_letter() || ch.is_digit() || ch == `-` || ch == `_` || ch == `.`) {
			return false
		}
	}
	return true
}

// request_id assigns `c.request_id` (reusing a well-formed incoming
// X-Request-Id) and echoes it in the response.
pub fn request_id() Handler {
	return fn (mut c Context) ! {
		incoming := c.header('X-Request-Id')
		c.request_id = if valid_request_id(incoming) { incoming } else { random_token(12) }
		c.set_header('X-Request-Id', c.request_id)
		c.next()!
	}
}

// ---------------------------------------------------------------------------
// Basic auth
// ---------------------------------------------------------------------------

fn ct_equal(a string, b string) bool {
	// hash first so comparison time does not leak the length either
	return hmac.equal(sha256.sum(a.bytes()), sha256.sum(b.bytes()))
}

// basic_auth protects routes with HTTP Basic auth (constant-time checks).
// Only use over HTTPS.
pub fn basic_auth(users map[string]string, realm string) Handler {
	return fn [users, realm] (mut c Context) ! {
		h := c.header('Authorization')
		if h.len > 6 && h[..6].to_lower() == 'basic ' {
			decoded := base64.decode_str(h[6..].trim_space())
			if decoded.contains(':') {
				user := decoded.all_before(':')
				pass := decoded.all_after(':')
				mut ok := false
				for u, p in users {
					// evaluate every entry so timing does not reveal which user exists
					if ct_equal(u, user) && ct_equal(p, pass) {
						ok = true
					}
				}
				if ok {
					c.locals['user'] = user
					c.next()!
					return
				}
			}
		}
		c.set_header('WWW-Authenticate', 'Basic realm="${realm.replace('"', '')}", charset="UTF-8"')
		return http_error(401, 'Unauthorized')
	}
}

// bearer_auth calls `verify(token)` for `Authorization: Bearer <token>`;
// 401 when missing or rejected.
pub fn bearer_auth(verify fn (token string) bool) Handler {
	return fn [verify] (mut c Context) ! {
		h := c.header('Authorization')
		if h.len > 7 && h[..7].to_lower() == 'bearer ' {
			if verify(h[7..].trim_space()) {
				c.next()!
				return
			}
		}
		c.set_header('WWW-Authenticate', 'Bearer')
		return http_error(401, 'Unauthorized')
	}
}

// ---------------------------------------------------------------------------
// Compression
// ---------------------------------------------------------------------------

@[params]
pub struct CompressConfig {
pub:
	min_bytes int = 1024
}

fn compressible(ct string) bool {
	t := ct.all_before(';').trim_space().to_lower()
	return t.starts_with('text/')
		|| t in ['application/json', 'application/javascript', 'application/xml', 'image/svg+xml', 'application/manifest+json']
		|| t.ends_with('+json') || t.ends_with('+xml')
}

// compress gzips compressible responses when the client accepts gzip.
pub fn compress(cfg CompressConfig) Handler {
	return fn [cfg] (mut c Context) ! {
		c.next()!
		c.vary('Accept-Encoding')
		if c.res_body.len < cfg.min_bytes || c.response_header('Content-Encoding') != ''
			|| !compressible(c.response_header('Content-Type')) {
			return
		}
		mut accepts_gzip := false
		for part in c.header('Accept-Encoding').split(',') {
			p := part.trim_space().to_lower()
			if p == 'gzip' || (p.starts_with('gzip;') && !p.replace(' ', '').ends_with('q=0')) {
				accepts_gzip = true
			}
		}
		if !accepts_gzip {
			return
		}
		z := gzip.compress(c.res_body.bytes()) or { return }
		if z.len < c.res_body.len {
			c.res_body = z.bytestr()
			c.set_header('Content-Encoding', 'gzip')
			etag := c.response_header('ETag')
			if etag != '' && !etag.starts_with('W/') {
				c.set_header('ETag', 'W/' + etag)
			}
		}
	}
}

// ---------------------------------------------------------------------------
// CSRF protection (signed double-submit tokens)
// ---------------------------------------------------------------------------

@[params]
pub struct CsrfConfig {
pub:
	cookie_name  string = '_csrf'
	header_name  string = 'X-CSRF-Token'
	field_name   string = '_csrf'
	ignore_paths []string // path prefixes exempt from checks (e.g. webhooks)
}

fn csrf_token_for(key []u8, secret string) string {
	salt := random_token(9)
	mac := hmac.new(key, '${salt}.${secret}'.bytes(), sha256.sum, sha256.block_size)
	return '${salt}.${base64.url_encode(mac)}'
}

fn csrf_verify(key []u8, secret string, token string) bool {
	dot := token.index('.') or { return false }
	salt := token[..dot]
	mac := hmac.new(key, '${salt}.${secret}'.bytes(), sha256.sum, sha256.block_size)
	return hmac.equal('${salt}.${base64.url_encode(mac)}'.bytes(), token.bytes())
}

// csrf_token returns a fresh CSRF token (requires the `csrf()` middleware).
// Put it in forms as `<input type="hidden" name="_csrf" value="<%= csrf_token %>">`
// or send it as the X-CSRF-Token header from JavaScript.
pub fn (c &Context) csrf_token() string {
	if c.csrf_secret == '' {
		return ''
	}
	return csrf_token_for(c.app.secret_key, c.csrf_secret)
}

// csrf rejects state-changing requests (POST/PUT/PATCH/DELETE) that lack a
// valid token with 403. Tokens are salted, HMAC-bound to a per-browser
// secret cookie and compared in constant time.
pub fn csrf(cfg CsrfConfig) Handler {
	return fn [cfg] (mut c Context) ! {
		mut secret := c.signed_cookie(cfg.cookie_name) or { '' }
		fresh := secret.len < 16
		if fresh {
			secret = random_token(18)
			c.set_signed_cookie(cfg.cookie_name, secret, same_site: .strict)
		}
		c.csrf_secret = secret
		c.locals['csrf_token'] = c.csrf_token()
		if c.method !in ['GET', 'HEAD', 'OPTIONS', 'TRACE']
			&& !cfg.ignore_paths.any(prefix_matches(normalize_prefix(it), c.path)) {
			mut tok := c.header(cfg.header_name)
			if tok == '' {
				tok = c.header('X-XSRF-Token')
			}
			if tok == '' {
				tok = c.form_value(cfg.field_name)
			}
			if fresh || tok == '' || !csrf_verify(c.app.secret_key, secret, tok) {
				return http_error(403, 'invalid or missing CSRF token')
			}
		}
		c.next()!
	}
}

// ---------------------------------------------------------------------------
// Misc
// ---------------------------------------------------------------------------

// body_limit rejects request bodies larger than `max_bytes` with 413
// (per-route override of AppConfig.max_body_bytes, which still applies first).
pub fn body_limit(max_bytes int) Handler {
	return fn [max_bytes] (mut c Context) ! {
		if c.req.data.len > max_bytes {
			return http_error(413, 'Payload Too Large')
		}
		c.next()!
	}
}

// no_cache sets headers that disable caching (for authenticated pages/APIs).
pub fn no_cache() Handler {
	return fn (mut c Context) ! {
		c.set_header('Cache-Control', 'no-store, no-cache, must-revalidate, private')
		c.set_header('Pragma', 'no-cache')
		c.set_header('Expires', '0')
		c.next()!
	}
}

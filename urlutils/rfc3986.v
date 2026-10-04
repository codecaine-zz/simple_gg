module urlutils

import net.urllib

// default_port returns the well-known port for a scheme (0 if unknown).
pub fn default_port(scheme string) int {
	return match scheme.to_lower() {
		'http', 'ws' { 80 }
		'https', 'wss' { 443 }
		'ftp' { 21 }
		'ssh', 'sftp' { 22 }
		'postgres', 'postgresql' { 5432 }
		'mysql' { 3306 }
		'redis' { 6379 }
		'mongodb' { 27017 }
		'amqp' { 5672 }
		else { 0 }
	}
}

// effective_port returns the explicit port or the scheme default.
pub fn (u URL) effective_port() int {
	return if u.port > 0 { u.port } else { default_port(u.scheme) }
}

// origin returns the web origin `scheme://host[:port]` (default ports omitted).
pub fn (u URL) origin() string {
	host := u.host.to_lower()
	if u.port > 0 && u.port != default_port(u.scheme) {
		return '${u.scheme}://${host}:${u.port}'
	}
	return '${u.scheme}://${host}'
}

// is_absolute_url reports whether `raw` has a scheme (RFC 3986 absolute URI).
pub fn is_absolute_url(raw string) bool {
	i := raw.index(':') or { return false }
	if i == 0 || !raw[0].is_letter() {
		return false
	}
	for c in raw[..i] {
		if !(c.is_alnum() || c in [`+`, `-`, `.`]) {
			return false
		}
	}
	return true
}

// remove_dot_segments implements RFC 3986 §5.2.4 (resolves `.` and `..`).
pub fn remove_dot_segments(path string) string {
	if path == '' {
		return ''
	}
	mut out := []string{}
	segs := path.split('/')
	for i, seg in segs {
		if seg == '.' {
			if i == segs.len - 1 {
				out << ''
			}
			continue
		}
		if seg == '..' {
			if out.len > 1 || (out.len == 1 && out[0] != '') {
				out.delete_last()
			}
			if i == segs.len - 1 {
				out << ''
			}
			continue
		}
		out << seg
	}
	mut res := out.join('/')
	if path.starts_with('/') && !res.starts_with('/') {
		res = '/' + res
	}
	return res
}

// resolve_reference resolves a (possibly relative) reference against a base URL
// per RFC 3986 §5.2, e.g. ("http://a/b/c/d;p?q", "../g") -> "http://a/b/g".
pub fn resolve_reference(base string, ref string) !string {
	b := urllib.parse(base)!
	r := urllib.parse(ref)!
	return b.resolve_reference(&r)!.str()
}

// query_values parses a raw query string preserving repeated keys and order of values,
// e.g. "tag=a&tag=b&x=1" -> {"tag": ["a", "b"], "x": ["1"]}.
pub fn query_values(raw_query string) map[string][]string {
	mut out := map[string][]string{}
	q := if raw_query.starts_with('?') { raw_query[1..] } else { raw_query }
	for pair in q.split('&') {
		if pair.len == 0 {
			continue
		}
		k, v := if pair.contains('=') { pair.split_once('=') or { pair, '' } } else { pair, '' }
		key := urllib.query_unescape(k) or { k }
		val := urllib.query_unescape(v) or { v }
		out[key] << val
	}
	return out
}

// encode_query builds a deterministic (key-sorted) query string from a map.
pub fn encode_query(params map[string]string) string {
	mut keys := params.keys()
	keys.sort()
	return keys.map('${urllib.query_escape(it)}=${urllib.query_escape(params[it])}').join('&')
}

// encode_query_multi builds a key-sorted query string supporting repeated keys.
pub fn encode_query_multi(params map[string][]string) string {
	mut keys := params.keys()
	keys.sort()
	mut parts := []string{}
	for k in keys {
		for v in params[k] {
			parts << '${urllib.query_escape(k)}=${urllib.query_escape(v)}'
		}
	}
	return parts.join('&')
}

// normalize_url canonicalizes a URL for comparison / cache keys: lowercases scheme and
// host, drops default ports and empty fragments, resolves dot segments, ensures a path,
// and sorts query parameters.
pub fn normalize_url(raw string) !string {
	mut u := parse_url(raw)!
	u.scheme = u.scheme.to_lower()
	u.host = u.host.to_lower().trim_right('.')
	if u.port == default_port(u.scheme) {
		u.port = 0
	}
	u.path = remove_dot_segments(if u.path == '' { '/' } else { u.path })
	mut base := u.str()
	// Re-emit query in sorted order.
	if i := base.index('?') {
		frag := if u.fragment.len > 0 { '#${u.fragment}' } else { '' }
		base = base[..i] + '?' + encode_query(u.query) + frag
	}
	return base
}

// with_query returns a copy of the URL with the given parameters merged in.
pub fn (u URL) with_query(params map[string]string) URL {
	mut q := u.query.clone()
	for k, v in params {
		q[k] = v
	}
	return URL{
		scheme:   u.scheme
		username: u.username
		password: u.password
		host:     u.host
		port:     u.port
		path:     u.path
		query:    q
		fragment: u.fragment
	}
}

// is_same_origin reports whether two URLs share scheme, host and effective port.
pub fn is_same_origin(a string, b string) bool {
	ua := parse_url(a) or { return false }
	ub := parse_url(b) or { return false }
	return ua.origin() == ub.origin()
}

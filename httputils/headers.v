module httputils

import net.http
import net.urllib
import time

// parse_retry_after parses a Retry-After header value: delta-seconds ("120") or an HTTP-date.
pub fn parse_retry_after(value string) ?time.Duration {
	v := value.trim_space()
	if v.len == 0 {
		return none
	}
	if v.is_int() {
		secs := v.i64()
		if secs < 0 {
			return none
		}
		return time.Duration(secs * time.second)
	}
	t := time.parse_rfc2822(v) or { return none }
	diff := t - time.utc()
	return if diff > 0 { diff } else { time.Duration(0) }
}

// status_text returns the standard reason phrase for an HTTP status code (e.g. 404 -> "Not Found").
pub fn status_text(status_code int) string {
	s := http.status_from_int(status_code)
	if s == .unknown {
		return 'Unknown'
	}
	return s.str()
}

// encode_form encodes a map as application/x-www-form-urlencoded with keys sorted (deterministic output).
pub fn encode_form(fields map[string]string) string {
	mut keys := fields.keys()
	keys.sort()
	mut parts := []string{cap: keys.len}
	for k in keys {
		parts << '${urllib.query_escape(k)}=${urllib.query_escape(fields[k])}'
	}
	return parts.join('&')
}

// parse_link_header parses an RFC 8288 Link header into a rel -> URL map
// (e.g. GitHub pagination: `<https://api/x?page=2>; rel="next"` -> {"next": "https://api/x?page=2"}).
pub fn parse_link_header(value string) map[string]string {
	mut res := map[string]string{}
	for part in value.split(',') {
		segs := part.split(';')
		if segs.len < 2 {
			continue
		}
		url := segs[0].trim_space().trim('<>')
		for seg in segs[1..] {
			kv := seg.trim_space()
			if kv.starts_with('rel=') {
				for rel in kv[4..].trim('"').split(' ') {
					if rel.len > 0 {
						res[rel] = url
					}
				}
			}
		}
	}
	return res
}

// parse_content_type splits a Content-Type header into its lower-cased media type and parameters
// (e.g. "text/html; charset=UTF-8" -> ("text/html", {"charset": "UTF-8"})).
pub fn parse_content_type(value string) (string, map[string]string) {
	segs := value.split(';')
	media := segs[0].trim_space().to_lower()
	mut params := map[string]string{}
	for seg in segs[1..] {
		idx := seg.index('=') or { continue }
		k := seg[..idx].trim_space().to_lower()
		v := seg[idx + 1..].trim_space().trim('"')
		if k.len > 0 {
			params[k] = v
		}
	}
	return media, params
}

// join_url joins a base URL and a path with exactly one slash; absolute URLs in path win.
pub fn join_url(base string, path string) string {
	if path.starts_with('http://') || path.starts_with('https://') {
		return path
	}
	if path.len == 0 {
		return base
	}
	if base.len == 0 {
		return path
	}
	return base.trim_right('/') + '/' + path.trim_left('/')
}

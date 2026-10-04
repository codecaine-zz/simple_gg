module urlutils

import net.urllib
import strings

// URL represents a fully parsed RFC 3986 Uniform Resource Locator.
pub struct URL {
pub mut:
	scheme   string
	username string
	password string
	host     string
	port     int
	path     string
	query    map[string]string
	fragment string
}

// parse_url parses an RFC 3986 raw URL string into a structured URL object.
pub fn parse_url(raw_url string) !URL {
	trimmed := raw_url.trim_space()
	if trimmed.len == 0 {
		return error('empty URL string')
	}

	mut rem := trimmed
	mut scheme := ''
	scheme_idx := rem.index('://') or { -1 }
	if scheme_idx != -1 {
		scheme = rem[..scheme_idx].to_lower()
		rem = rem[scheme_idx + 3..]
	}

	mut fragment := ''
	frag_idx := rem.index('#') or { -1 }
	if frag_idx != -1 {
		fragment = rem[frag_idx + 1..]
		rem = rem[..frag_idx]
	}

	mut query := map[string]string{}
	q_idx := rem.index('?') or { -1 }
	if q_idx != -1 {
		q_str := rem[q_idx + 1..]
		rem = rem[..q_idx]
		pairs := q_str.split('&')
		for pair in pairs {
			if pair.len == 0 {
				continue
			}
			eq := pair.index('=') or {
				k := urllib.query_unescape(pair) or { pair }
				query[k] = ''
				continue
			}
			k := urllib.query_unescape(pair[..eq]) or { pair[..eq] }
			v := urllib.query_unescape(pair[eq + 1..]) or { pair[eq + 1..] }
			query[k] = v
		}
	}

	mut path := '/'
	slash_idx := rem.index('/') or { -1 }
	mut authority := rem
	if slash_idx != -1 {
		authority = rem[..slash_idx]
		path = rem[slash_idx..]
	}

	mut username := ''
	mut password := ''
	// The LAST '@' separates userinfo from host (passwords may contain '@').
	at_idx := authority.last_index('@') or { -1 }
	if at_idx != -1 {
		userinfo := authority[..at_idx]
		authority = authority[at_idx + 1..]
		colon_idx := userinfo.index(':') or { -1 }
		if colon_idx != -1 {
			username = userinfo[..colon_idx]
			password = userinfo[colon_idx + 1..]
		} else {
			username = userinfo
		}
		username = urllib.path_unescape(username) or { username }
		password = urllib.path_unescape(password) or { password }
	}

	mut host := authority
	mut port := 0
	mut port_str := ''
	if host.starts_with('[') {
		// IPv6 literal: [addr] or [addr]:port
		close := host.index(']') or { return error('unterminated IPv6 literal in "${raw_url}"') }
		rest := host[close + 1..]
		if rest.len > 0 {
			if !rest.starts_with(':') {
				return error('invalid characters after IPv6 literal in "${raw_url}"')
			}
			port_str = rest[1..]
		}
		host = host[..close + 1]
	} else {
		colon_port := host.last_index(':') or { -1 }
		if colon_port != -1 {
			port_str = host[colon_port + 1..]
			host = host[..colon_port]
		}
	}
	if port_str.len > 0 {
		if !port_str.bytes().all(it.is_digit()) || port_str.len > 5 || port_str.int() > 65535 {
			return error('invalid port "${port_str}" in "${raw_url}"')
		}
		port = port_str.int()
	}

	return URL{
		scheme:   scheme
		username: username
		password: password
		host:     host
		port:     port
		path:     path
		query:    query
		fragment: fragment
	}
}

// host_with_port returns the host and, if non-zero, port combination (e.g. "localhost:8080").
pub fn (u URL) host_with_port() string {
	if u.port > 0 {
		return '${u.host}:${u.port}'
	}
	return u.host
}

// path_segments returns the non-empty path components of the URL.
pub fn (u URL) path_segments() []string {
	parts := u.path.split('/')
	mut segments := []string{}
	for p in parts {
		if p.len > 0 {
			segments << p
		}
	}
	return segments
}

// set_query_param adds or updates a query parameter key and value.
pub fn (mut u URL) set_query_param(k string, v string) {
	u.query[k] = v
}

// delete_query_param removes a query parameter key.
pub fn (mut u URL) delete_query_param(k string) {
	u.query.delete(k)
}

// str serializes the URL back into a valid URL string.
pub fn (u URL) str() string {
	mut sb := strings.new_builder(64)
	if u.scheme.len > 0 {
		sb.write_string('${u.scheme}://')
	}
	if u.username.len > 0 {
		sb.write_string(escape_userinfo(u.username))
		if u.password.len > 0 {
			sb.write_string(':${escape_userinfo(u.password)}')
		}
		sb.write_string('@')
	}
	sb.write_string(u.host)
	if u.port > 0 {
		sb.write_string(':${u.port}')
	}
	if u.path.len > 0 {
		if !u.path.starts_with('/') {
			sb.write_string('/')
		}
		sb.write_string(u.path)
	}
	if u.query.len > 0 {
		sb.write_string('?')
		mut parts := []string{cap: u.query.len}
		for k, v in u.query {
			parts << '${urllib.query_escape(k)}=${urllib.query_escape(v)}'
		}
		sb.write_string(parts.join('&'))
	}
	if u.fragment.len > 0 {
		sb.write_string('#${u.fragment}')
	}
	return sb.str()
}

// join_path joins multiple URL path segments cleanly without double slashes.
pub fn join_path(base string, parts ...string) string {
	mut clean_base := base.trim_right('/')
	for part in parts {
		clean_part := part.trim_left('/').trim_right('/')
		if clean_part.len > 0 {
			clean_base += '/' + clean_part
		}
	}
	return clean_base
}

// redact_credentials replaces passwords in URLs with "***" for safe logging and telemetry.
pub fn redact_credentials(raw_url string) string {
	mut parsed := parse_url(raw_url) or { return raw_url }
	if parsed.password.len > 0 {
		parsed.password = '***'
	}
	return parsed.str()
}

// escape_userinfo percent-encodes only the characters that would break URL structure.
fn escape_userinfo(s string) string {
	mut sb := strings.new_builder(s.len)
	for c in s {
		if c <= 0x20 || c >= 0x7f || c in [`%`, `@`, `:`, `/`, `?`, `#`, `[`, `]`] {
			sb.write_string('%' + '${c:02X}')
		} else {
			sb.write_u8(c)
		}
	}
	return sb.str()
}

module validutils

import json2

// validate_email verifies whether an email address adheres to standard mailbox format.
pub fn validate_email(email string) bool {
	trimmed := email.trim_space()
	if trimmed.len < 5 || trimmed.len > 254 {
		return false
	}
	at_idx := trimmed.index('@') or { return false }
	if at_idx == 0 || at_idx == trimmed.len - 1 {
		return false
	}
	// Only one @ allowed
	if trimmed[at_idx + 1..].contains('@') {
		return false
	}
	user := trimmed[..at_idx]
	domain := trimmed[at_idx + 1..]

	if user.len == 0 || domain.len < 3 {
		return false
	}
	if !domain.contains('.') {
		return false
	}
	last_dot := domain.last_index('.') or { return false }
	tld := domain[last_dot + 1..]
	if tld.len < 2 {
		return false
	}
	for r in domain.runes() {
		if !is_domain_char(r) {
			return false
		}
	}
	return true
}

fn is_domain_char(r rune) bool {
	return (r >= `a` && r <= `z`) || (r >= `A` && r <= `Z`) || (r >= `0` && r <= `9`) || r == `.`
		|| r == `-`
}

fn is_alnum_char(r rune) bool {
	return (r >= `a` && r <= `z`) || (r >= `A` && r <= `Z`) || (r >= `0` && r <= `9`)
}

// validate_url verifies whether a string is a valid HTTP or HTTPS URL.
pub fn validate_url(url string) bool {
	trimmed := url.trim_space()
	if !trimmed.starts_with('http://') && !trimmed.starts_with('https://') {
		return false
	}
	after_proto := if trimmed.starts_with('https://') { trimmed[8..] } else { trimmed[7..] }
	if after_proto.len == 0 {
		return false
	}
	host_part := after_proto.split('/')[0].split('?')[0].split('#')[0]
	return host_part.len > 0
}

// validate_ip verifies whether a string is a valid IPv4 address (e.g. 192.168.1.1).
pub fn validate_ip(ip string) bool {
	trimmed := ip.trim_space()
	parts := trimmed.split('.')
	if parts.len != 4 {
		return false
	}
	for part in parts {
		if part.len == 0 || (part.len > 1 && part.starts_with('0')) {
			return false
		}
		for r in part.runes() {
			if !(r >= `0` && r <= `9`) {
				return false
			}
		}
		num := part.int()
		if num < 0 || num > 255 {
			return false
		}
	}
	return true
}

// validate_phone checks if a string is a plausible telephone number (digits, spaces, hyphens, plus).
pub fn validate_phone(phone string) bool {
	trimmed := phone.trim_space()
	if trimmed.len < 7 {
		return false
	}
	mut digit_count := 0
	for i, r in trimmed.runes() {
		if r >= `0` && r <= `9` {
			digit_count++
		} else if r == `+` {
			if i != 0 {
				return false
			}
		} else if !(r == `-` || r == ` ` || r == `(` || r == `)` || r == `.`) {
			return false
		}
	}
	return digit_count >= 7 && digit_count <= 15
}

// validate_alphanumeric checks if a string contains only letters and digits without symbols.
pub fn validate_alphanumeric(s string) bool {
	if s.len == 0 {
		return false
	}
	for r in s.runes() {
		if !is_alnum_char(r) {
			return false
		}
	}
	return true
}

// validate_numeric_range verifies that val is between min and max (inclusive).
pub fn validate_numeric_range(val f64, min f64, max f64) bool {
	return val >= min && val <= max
}

// validate_length checks whether the rune count of s is between min_len and max_len (inclusive).
pub fn validate_length(s string, min_len int, max_len int) bool {
	count := s.runes().len
	return count >= min_len && count <= max_len
}

// validate_uuid checks if a string matches canonical RFC 4122 UUID format.
pub fn validate_uuid(s string) bool {
	if s.len != 36 {
		return false
	}
	for i, c in s {
		if i == 8 || i == 13 || i == 18 || i == 23 {
			if c != `-` {
				return false
			}
		} else {
			is_hex := (c >= `0` && c <= `9`) || (c >= `a` && c <= `f`) || (c >= `A` && c <= `F`)
			if !is_hex {
				return false
			}
		}
	}
	return true
}

// validate_json checks whether a string contains well-formed JSON syntax.
pub fn validate_json(s string) bool {
	trimmed := s.trim_space()
	if trimmed.len == 0 {
		return false
	}
	if !(trimmed.starts_with('{') && trimmed.ends_with('}'))
		&& !(trimmed.starts_with('[') && trimmed.ends_with(']')) {
		return false
	}
	_ = json2.decode[json2.Any](trimmed) or {
		return false
	}
	return true
}

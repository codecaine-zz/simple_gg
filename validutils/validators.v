module validutils

import math
import time

// validate_hostname checks RFC 1123 host names: total <= 253 chars, dot-separated labels of
// 1-63 letters/digits/hyphens that do not start or end with a hyphen. A trailing dot is allowed.
pub fn validate_hostname(host string) bool {
	h := host.trim_right('.')
	if h.len == 0 || h.len > 253 {
		return false
	}
	for label in h.split('.') {
		if label.len == 0 || label.len > 63 || label.starts_with('-') || label.ends_with('-') {
			return false
		}
		for c in label {
			if !(c.is_letter() || c.is_digit() || c == `-`) {
				return false
			}
		}
	}
	return true
}

// validate_port checks that s is a decimal TCP/UDP port in 1..65535.
pub fn validate_port(s string) bool {
	if s.len == 0 || s.len > 5 {
		return false
	}
	for c in s {
		if !c.is_digit() {
			return false
		}
	}
	n := s.int()
	return n >= 1 && n <= 65535
}

// validate_ipv6 checks an RFC 4291 IPv6 address, including "::" compression, an optional
// embedded IPv4 tail ("::ffff:192.0.2.1") and an optional zone id ("fe80::1%eth0").
pub fn validate_ipv6(ip string) bool {
	mut s := ip.trim_space()
	if pct := s.index('%') {
		if pct == s.len - 1 {
			return false
		}
		s = s[..pct]
	}
	if s.len < 2 || s.count('::') > 1 || s.contains(':::') {
		return false
	}
	if (s.starts_with(':') && !s.starts_with('::')) || (s.ends_with(':') && !s.ends_with('::')) {
		return false
	}
	mut groups := 0
	parts := s.split(':')
	for i, p in parts {
		if p.len == 0 {
			continue
		}
		if p.contains('.') {
			if i != parts.len - 1 || !validate_ip(p) {
				return false
			}
			groups += 2
			continue
		}
		if p.len > 4 {
			return false
		}
		for c in p {
			if !c.is_hex_digit() {
				return false
			}
		}
		groups++
	}
	return if s.contains('::') { groups < 8 } else { groups == 8 }
}

// validate_cidr checks IPv4 ("10.0.0.0/8") or IPv6 ("2001:db8::/32") CIDR notation.
pub fn validate_cidr(s string) bool {
	idx := s.index('/') or { return false }
	addr := s[..idx]
	bits := s[idx + 1..]
	if bits.len == 0 || bits.len > 3 || !bits.is_int() || bits.starts_with('+')
		|| bits.starts_with('-') {
		return false
	}
	n := bits.int()
	if validate_ip(addr) {
		return n >= 0 && n <= 32
	}
	if validate_ipv6(addr) {
		return n >= 0 && n <= 128
	}
	return false
}

// validate_mac checks a MAC address in colon, hyphen or Cisco-dot form (e.g. "00:1A:2b:3C:4d:5E").
pub fn validate_mac(s string) bool {
	hex_only := fn (t string) bool {
		for c in t {
			if !c.is_hex_digit() {
				return false
			}
		}
		return true
	}
	if s.len == 17 {
		sep := s[2]
		if sep != `:` && sep != `-` {
			return false
		}
		parts := s.split(sep.ascii_str())
		return parts.len == 6 && parts.all(it.len == 2 && hex_only(it))
	}
	if s.len == 14 {
		parts := s.split('.')
		return parts.len == 3 && parts.all(it.len == 4 && hex_only(it))
	}
	return false
}

// luhn_check verifies a number string with the Luhn mod-10 checksum (spaces and hyphens ignored).
pub fn luhn_check(s string) bool {
	mut sum := 0
	mut double := false
	mut digits := 0
	for i := s.len - 1; i >= 0; i-- {
		c := s[i]
		if c == ` ` || c == `-` {
			continue
		}
		if !c.is_digit() {
			return false
		}
		mut d := int(c - `0`)
		if double {
			d *= 2
			if d > 9 {
				d -= 9
			}
		}
		sum += d
		double = !double
		digits++
	}
	return digits > 1 && sum % 10 == 0
}

// validate_credit_card checks length (12-19 digits) and the Luhn checksum.
pub fn validate_credit_card(s string) bool {
	digits := s.replace(' ', '').replace('-', '')
	return digits.len >= 12 && digits.len <= 19 && luhn_check(digits)
}

// card_brand identifies the card network from the number prefix ("visa", "mastercard", "amex",
// "discover", "jcb", "diners", "unionpay") or returns "unknown".
pub fn card_brand(s string) string {
	d := s.replace(' ', '').replace('-', '')
	if d.len < 2 {
		return 'unknown'
	}
	p2 := d[..2].int()
	p4 := if d.len >= 4 { d[..4].int() } else { 0 }
	p3 := if d.len >= 3 { d[..3].int() } else { 0 }
	p6 := if d.len >= 6 { d[..6].int() } else { 0 }
	return if d[0] == `4` {
		'visa'
	} else if (p2 >= 51 && p2 <= 55) || (p6 >= 222100 && p6 <= 272099) {
		'mastercard'
	} else if p2 == 34 || p2 == 37 {
		'amex'
	} else if p4 == 6011 || p2 == 65 || (p3 >= 644 && p3 <= 649) {
		'discover'
	} else if p4 >= 3528 && p4 <= 3589 {
		'jcb'
	} else if p2 == 36 || p2 == 38 || (p3 >= 300 && p3 <= 305) {
		'diners'
	} else if p2 == 62 {
		'unionpay'
	} else {
		'unknown'
	}
}

// validate_iban checks an International Bank Account Number with the ISO 13616 mod-97 checksum.
pub fn validate_iban(s string) bool {
	iban := s.replace(' ', '').to_upper()
	if iban.len < 15 || iban.len > 34 || !iban[0].is_letter() || !iban[1].is_letter()
		|| !iban[2].is_digit() || !iban[3].is_digit() {
		return false
	}
	rearranged := iban[4..] + iban[..4]
	mut rem := 0
	for c in rearranged {
		if c.is_digit() {
			rem = (rem * 10 + int(c - `0`)) % 97
		} else if c >= `A` && c <= `Z` {
			v := int(c - `A`) + 10
			rem = (rem * 100 + v) % 97
		} else {
			return false
		}
	}
	return rem == 1
}

// validate_isbn checks ISBN-10 or ISBN-13 (hyphens/spaces ignored) including the check digit.
pub fn validate_isbn(s string) bool {
	d := s.replace('-', '').replace(' ', '').to_upper()
	if d.len == 10 {
		mut sum := 0
		for i, c in d {
			v := if c == `X` && i == 9 {
				10
			} else if c.is_digit() {
				int(c - `0`)
			} else {
				return false
			}
			sum += v * (10 - i)
		}
		return sum % 11 == 0
	}
	if d.len == 13 {
		mut sum := 0
		for i, c in d {
			if !c.is_digit() {
				return false
			}
			sum += int(c - `0`) * if i % 2 == 0 { 1 } else { 3 }
		}
		return sum % 10 == 0
	}
	return false
}

// validate_hex_color checks CSS hex colors: #RGB, #RGBA, #RRGGBB or #RRGGBBAA.
pub fn validate_hex_color(s string) bool {
	if !s.starts_with('#') || s.len !in [4, 5, 7, 9] {
		return false
	}
	for c in s[1..] {
		if !c.is_hex_digit() {
			return false
		}
	}
	return true
}

// validate_slug checks lowercase URL slugs ("my-post-2026"): a-z, 0-9 and single inner hyphens.
pub fn validate_slug(s string) bool {
	if s.len == 0 || s.starts_with('-') || s.ends_with('-') || s.contains('--') {
		return false
	}
	for c in s {
		if !((c >= `a` && c <= `z`) || c.is_digit() || c == `-`) {
			return false
		}
	}
	return true
}

// validate_base64 checks standard (RFC 4648 §4) Base64 with correct padding.
pub fn validate_base64(s string) bool {
	if s.len == 0 || s.len % 4 != 0 {
		return false
	}
	pad := if s.ends_with('==') {
		2
	} else if s.ends_with('=') {
		1
	} else {
		0
	}
	for c in s[..s.len - pad] {
		if !(c.is_letter() || c.is_digit() || c == `+` || c == `/`) {
			return false
		}
	}
	return true
}

// validate_e164 checks an international phone number in strict E.164 form ("+14155552671").
pub fn validate_e164(s string) bool {
	if s.len < 3 || s.len > 16 || s[0] != `+` || s[1] == `0` {
		return false
	}
	for c in s[1..] {
		if !c.is_digit() {
			return false
		}
	}
	return true
}

// validate_date checks that s is a real calendar date in YYYY-MM-DD form (rejects 2023-02-30).
pub fn validate_date(s string) bool {
	if s.len != 10 || s[4] != `-` || s[7] != `-` {
		return false
	}
	for i, c in s {
		if i != 4 && i != 7 && !c.is_digit() {
			return false
		}
	}
	y := s[..4].int()
	m := s[5..7].int()
	d := s[8..].int()
	if m < 1 || m > 12 || d < 1 {
		return false
	}
	leap := (y % 4 == 0 && y % 100 != 0) || y % 400 == 0
	max_d := match m {
		2 {
			if leap { 29 } else { 28 }
		}
		4, 6, 9, 11 {
			30
		}
		else {
			31
		}
	}

	return d <= max_d
}

// validate_ulid checks a 26-character Crockford Base32 ULID.
pub fn validate_ulid(s string) bool {
	if s.len != 26 || s[0] > `7` {
		return false
	}
	for c in s.to_upper() {
		if !(c.is_digit() || (c >= `A` && c <= `Z` && c !in [`I`, `L`, `O`, `U`])) {
			return false
		}
	}
	return true
}

// ---------------------------------------------------------------------------
// Password strength
// ---------------------------------------------------------------------------

// PasswordReport describes password strength: score 0 (very weak) .. 4 (strong), with feedback.
pub struct PasswordReport {
pub:
	score       int
	entropy     f64
	suggestions []string
}

const common_passwords = ['password', '123456', '12345678', 'qwerty', 'abc123', '111111', 'letmein',
	'iloveyou', 'admin', 'welcome', 'monkey', 'dragon', 'football', 'baseball', 'master', 'sunshine',
	'princess', 'passw0rd', 'qwertyuiop', '123123', 'trustno1', 'shadow']

// password_strength estimates strength from length, character variety, repetition and a
// common-password blocklist, returning a 0-4 score with actionable suggestions.
pub fn password_strength(pw string) PasswordReport {
	mut suggestions := []string{}
	mut lower, mut upper, mut digit, mut symbol := false, false, false, false
	for c in pw {
		if c >= `a` && c <= `z` {
			lower = true
		} else if c >= `A` && c <= `Z` {
			upper = true
		} else if c.is_digit() {
			digit = true
		} else {
			symbol = true
		}
	}
	mut pool := 0
	if lower {
		pool += 26
	}
	if upper {
		pool += 26
	}
	if digit {
		pool += 10
	}
	if symbol {
		pool += 33
	}
	// Penalise repeated characters by counting distinct runes towards length.
	mut distinct := map[rune]bool{}
	for r in pw.runes() {
		distinct[r] = true
	}
	eff_len := if distinct.len * 2 < pw.runes().len { distinct.len * 2 } else { pw.runes().len }
	entropy := if pool > 0 { f64(eff_len) * math.log2(f64(pool)) } else { 0.0 }
	mut score := if entropy < 28 {
		0
	} else if entropy < 36 {
		1
	} else if entropy < 60 {
		2
	} else if entropy < 80 {
		3
	} else {
		4
	}
	if pw.to_lower() in common_passwords {
		score = 0
		suggestions << 'this is one of the most common passwords'
	}
	if pw.len < 12 {
		suggestions << 'use at least 12 characters'
	}
	if !(lower && upper) {
		suggestions << 'mix upper and lower case letters'
	}
	if !digit {
		suggestions << 'add digits'
	}
	if !symbol {
		suggestions << 'add symbols'
	}
	if eff_len < pw.runes().len {
		suggestions << 'avoid repeated characters'
	}
	return PasswordReport{
		score:       score
		entropy:     entropy
		suggestions: suggestions
	}
}

// ---------------------------------------------------------------------------
// Fluent multi-field validator
// ---------------------------------------------------------------------------

// Validator accumulates field errors, ideal for validating forms and API payloads:
//   mut v := validutils.Validator{}
//   v.required('name', input.name).email('email', input.email).min_len('password', input.pw, 12)
//   if !v.is_valid() { return v.errors }
@[heap]
pub struct Validator {
pub mut:
	errors map[string][]string
}

// add records an error for field.
pub fn (mut v Validator) add(field string, message string) &Validator {
	v.errors[field] << message
	return v
}

// check records message for field when ok is false (escape hatch for custom rules).
pub fn (mut v Validator) check(ok bool, field string, message string) &Validator {
	if !ok {
		v.add(field, message)
	}
	return v
}

// required fails when value is empty or whitespace.
pub fn (mut v Validator) required(field string, value string) &Validator {
	return v.check(value.trim_space().len > 0, field, 'is required')
}

// email fails when value is not a valid email address (empty values are skipped; combine with required).
pub fn (mut v Validator) email(field string, value string) &Validator {
	return v.check(value.len == 0 || validate_email(value), field, 'must be a valid email address')
}

// url fails when value is not a valid http(s) URL (empty values are skipped).
pub fn (mut v Validator) url(field string, value string) &Validator {
	return v.check(value.len == 0 || validate_url(value), field, 'must be a valid URL')
}

// min_len fails when value has fewer than n runes.
pub fn (mut v Validator) min_len(field string, value string, n int) &Validator {
	return v.check(value.runes().len >= n, field, 'must be at least ${n} characters')
}

// max_len fails when value has more than n runes.
pub fn (mut v Validator) max_len(field string, value string, n int) &Validator {
	return v.check(value.runes().len <= n, field, 'must be at most ${n} characters')
}

// range fails when value is outside [min, max].
pub fn (mut v Validator) range(field string, value f64, min f64, max f64) &Validator {
	return v.check(value >= min && value <= max, field,
		'must be between ${fmt_num(min)} and ${fmt_num(max)}')
}

// fmt_num renders whole numbers without a trailing ".0".
fn fmt_num(x f64) string {
	return if x == math.trunc(x) && math.abs(x) < 1e15 { i64(x).str() } else { x.str() }
}

// one_of fails when value is not in allowed.
pub fn (mut v Validator) one_of(field string, value string, allowed []string) &Validator {
	return v.check(value in allowed, field, 'must be one of: ${allowed.join(', ')}')
}

// date fails when value is not a valid YYYY-MM-DD date (empty values are skipped).
pub fn (mut v Validator) date(field string, value string) &Validator {
	return v.check(value.len == 0 || validate_date(value), field, 'must be a date (YYYY-MM-DD)')
}

// not_in_future fails when t is after now.
pub fn (mut v Validator) not_in_future(field string, t time.Time) &Validator {
	return v.check(t <= time.now(), field, 'must not be in the future')
}

// is_valid reports whether no errors were recorded.
pub fn (v &Validator) is_valid() bool {
	return v.errors.len == 0
}

// error_messages flattens errors into "field message" strings, sorted by field for stable output.
pub fn (v &Validator) error_messages() []string {
	mut keys := v.errors.keys()
	keys.sort()
	mut out := []string{}
	for k in keys {
		for m in v.errors[k] {
			out << '${k} ${m}'
		}
	}
	return out
}

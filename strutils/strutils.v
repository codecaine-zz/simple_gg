module strutils

import rand
import strings

fn is_whitespace(r rune) bool {
	return u8(r).is_space() || r == `\t` || r == `\n` || r == `\r`
}

// to_snake_case converts a string (camelCase, PascalCase, kebab-case, or spaced) into snake_case.
pub fn to_snake_case(s string) string {
	if s.len == 0 {
		return ''
	}
	mut sb := strings.new_builder(s.len + 4)
	runes := s.runes()
	for i, r in runes {
		if r == `-` || r == ` ` || r == `_` {
			if sb.len > 0 && sb.last() != `_` {
				sb.write_u8(`_`)
			}
			continue
		}
		if r >= `A` && r <= `Z` {
			if i > 0 && sb.len > 0 && sb.last() != `_` {
				prev := runes[i - 1]
				next_is_lower := i + 1 < runes.len && runes[i + 1] >= `a` && runes[i + 1] <= `z`
				if !(prev >= `A` && prev <= `Z`) || next_is_lower {
					sb.write_u8(`_`)
				}
			}
			sb.write_u8(u8(r + 32))
		} else {
			sb.write_rune(r)
		}
	}
	return sb.str().trim_string_right('_')
}

// to_kebab_case converts a string into kebab-case.
pub fn to_kebab_case(s string) string {
	snake := to_snake_case(s)
	return snake.replace('_', '-')
}

// to_camel_case converts a string into camelCase.
pub fn to_camel_case(s string) string {
	pascal_str := to_pascal_case(s)
	if pascal_str.len == 0 {
		return ''
	}
	runes := pascal_str.runes()
	first := if runes[0] >= `A` && runes[0] <= `Z` { runes[0] + 32 } else { runes[0] }
	mut sb := strings.new_builder(pascal_str.len)
	sb.write_rune(first)
	if runes.len > 1 {
		sb.write_string(runes[1..].string())
	}
	return sb.str()
}

// to_pascal_case converts a string into PascalCase.
pub fn to_pascal_case(s string) string {
	if s.len == 0 {
		return ''
	}
	mut sb := strings.new_builder(s.len)
	mut capitalize_next := true
	for r in s.runes() {
		if r == `_` || r == `-` || r == ` ` || r == `.` {
			capitalize_next = true
			continue
		}
		if capitalize_next {
			if r >= `a` && r <= `z` {
				sb.write_rune(r - 32)
			} else {
				sb.write_rune(r)
			}
			capitalize_next = false
		} else {
			sb.write_rune(r)
		}
	}
	return sb.str()
}

// to_title_case capitalizes the first letter of each word using V's built-in title method.
pub fn to_title_case(s string) string {
	if s.len == 0 {
		return ''
	}
	normalized := s.replace('_', ' ').replace('-', ' ')
	return collapse_whitespace(normalized.title())
}

// slugify converts a string into a URL-friendly slug.
pub fn slugify(s string) string {
	trimmed := s.trim_space().to_lower()
	if trimmed.len == 0 {
		return ''
	}
	mut sb := strings.new_builder(trimmed.len)
	mut last_was_dash := false
	for r in trimmed.runes() {
		if (r >= `a` && r <= `z`) || (r >= `0` && r <= `9`) {
			sb.write_rune(r)
			last_was_dash = false
		} else if r == ` ` || r == `-` || r == `_` || r == `/` || r == `.` {
			if !last_was_dash && sb.len > 0 {
				sb.write_u8(`-`)
				last_was_dash = true
			}
		}
	}
	res := sb.str()
	return res.trim_string_right('-')
}

// truncate shortens a string to max_len runes, appending suffix if truncated.
pub fn truncate(s string, max_len int, suffix string) string {
	runes := s.runes()
	if runes.len <= max_len {
		return s
	}
	suffix_runes := suffix.runes()
	target_len := if max_len >= suffix_runes.len { max_len - suffix_runes.len } else { 0 }
	mut sb := strings.new_builder(max_len)
	for i in 0 .. target_len {
		sb.write_rune(runes[i])
	}
	sb.write_string(suffix)
	return sb.str()
}

// truncate_words shortens a string to a given number of words.
pub fn truncate_words(s string, max_words int, suffix string) string {
	words := s.fields()
	if words.len <= max_words {
		return s
	}
	mut chosen := []string{cap: max_words}
	for i in 0 .. max_words {
		chosen << words[i]
	}
	return chosen.join(' ') + suffix
}

// pad_left pads the left of s with fill until total width is reached.
// Employs V's built-in string interpolation formatting when padding with spaces on ASCII strings.
pub fn pad_left(s string, width int, pad_char string) string {
	runes_len := s.runes().len
	if runes_len >= width {
		return s
	}
	if (pad_char == ' ' || pad_char == '') && s.is_pure_ascii() {
		return '${s:(width)}'
	}
	needed := width - runes_len
	fill := if pad_char.len > 0 { pad_char } else { ' ' }
	return fill.repeat(needed) + s
}

// pad_right pads the right of s with fill until total width is reached.
// Employs V's built-in string interpolation formatting when padding with spaces on ASCII strings.
pub fn pad_right(s string, width int, pad_char string) string {
	runes_len := s.runes().len
	if runes_len >= width {
		return s
	}
	if (pad_char == ' ' || pad_char == '') && s.is_pure_ascii() {
		return '${s:-(width)}'
	}
	needed := width - runes_len
	fill := if pad_char.len > 0 { pad_char } else { ' ' }
	return s + fill.repeat(needed)
}

// pad_center centers s by padding equally on both sides.
pub fn pad_center(s string, width int, pad_char string) string {
	runes_len := s.runes().len
	if runes_len >= width {
		return s
	}
	total_padding := width - runes_len
	left_padding := total_padding / 2
	right_padding := total_padding - left_padding
	fill := if pad_char.len > 0 { pad_char } else { ' ' }
	return fill.repeat(left_padding) + s + fill.repeat(right_padding)
}

// mask masks characters in a string between unmasked_start and unmasked_end runes.
pub fn mask(s string, unmasked_start int, unmasked_end int, mask_char string) string {
	runes := s.runes()
	total := runes.len
	if total == 0 {
		return ''
	}
	if unmasked_start + unmasked_end >= total {
		return s
	}
	m := if mask_char.len > 0 { mask_char } else { '*' }
	mut sb := strings.new_builder(total)
	for i in 0 .. unmasked_start {
		sb.write_rune(runes[i])
	}
	mask_count := total - unmasked_start - unmasked_end
	sb.write_string(m.repeat(mask_count))
	for i in (total - unmasked_end) .. total {
		sb.write_rune(runes[i])
	}
	return sb.str()
}

// mask_email masks an email address for privacy (e.g. john.doe@example.com -> j***e@example.com).
pub fn mask_email(email string) string {
	at_idx := email.index('@') or { return mask(email, 1, 1, '*') }
	name := email[..at_idx]
	domain := email[at_idx..]
	if name.len <= 2 {
		return name[..1] + '*' + domain
	}
	masked_name := mask(name, 1, 1, '*')
	return masked_name + domain
}

// random_string generates a random string of specified length using the given charset.
pub fn random_string(len int, charset string) string {
	if len <= 0 || charset.len == 0 {
		return ''
	}
	charset_runes := charset.runes()
	mut sb := strings.new_builder(len)
	for _ in 0 .. len {
		idx := rand.int_in_range(0, charset_runes.len) or { 0 }
		sb.write_rune(charset_runes[idx])
	}
	return sb.str()
}

// random_alphanumeric generates a random alphanumeric string (A-Z, a-z, 0-9).
pub fn random_alphanumeric(len int) string {
	return random_string(len, 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789')
}

// random_hex generates a random lowercase hex string.
pub fn random_hex(len int) string {
	return random_string(len, '0123456789abcdef')
}

// strip_html_tags removes HTML/XML tags from a string.
pub fn strip_html_tags(s string) string {
	mut sb := strings.new_builder(s.len)
	mut in_tag := false
	for r in s.runes() {
		if r == `<` {
			in_tag = true
		} else if r == `>` {
			in_tag = false
		} else if !in_tag {
			sb.write_rune(r)
		}
	}
	return sb.str()
}

// collapse_whitespace replaces consecutive whitespace characters with a single space.
pub fn collapse_whitespace(s string) string {
	mut sb := strings.new_builder(s.len)
	mut in_whitespace := false
	for r in s.trim_space().runes() {
		if is_whitespace(r) {
			if !in_whitespace {
				sb.write_u8(` `)
				in_whitespace = true
			}
		} else {
			sb.write_rune(r)
			in_whitespace = false
		}
	}
	return sb.str()
}

// word_wrap wraps text to a maximum line width.
pub fn word_wrap(s string, width int) string {
	if width <= 0 || s.len <= width {
		return s
	}
	words := s.fields()
	if words.len == 0 {
		return ''
	}
	mut lines := []string{}
	mut current_line := ''
	for word in words {
		if current_line.len == 0 {
			current_line = word
		} else if current_line.runes().len + 1 + word.runes().len <= width {
			current_line += ' ' + word
		} else {
			lines << current_line
			current_line = word
		}
	}
	if current_line.len > 0 {
		lines << current_line
	}
	return lines.join('\n')
}

// extract_between returns the substring located between start_delim and end_delim.
pub fn extract_between(s string, start_delim string, end_delim string) ?string {
	start_idx := s.index(start_delim)?
	after_start := start_idx + start_delim.len
	sub := s[after_start..]
	end_idx := sub.index(end_delim)?
	return sub[..end_idx]
}

// levenshtein_distance computes the edit distance between two strings using V's built-in algorithm.
pub fn levenshtein_distance(a string, b string) int {
	return strings.levenshtein_distance(a, b)
}

// similarity returns a similarity ratio between 0.0 (completely different) and 1.0 (identical).
pub fn similarity(a string, b string) f64 {
	if a == b {
		return 1.0
	}
	a_len := a.runes().len
	b_len := b.runes().len
	max_len := if a_len > b_len { a_len } else { b_len }
	if max_len == 0 {
		return 1.0
	}
	distance := levenshtein_distance(a, b)
	return 1.0 - (f64(distance) / f64(max_len))
}

module strutils

import math
import strings

// ---------------------------------------------------------------------------
// Transliteration
// ---------------------------------------------------------------------------

const accent_from = 'ÀÁÂÃÄÅàáâãäåÈÉÊËèéêëÌÍÎÏìíîïÒÓÔÕÖØòóôõöøÙÚÛÜùúûüÝýÿÑñÇçŠšŽžĆćČčĐđŁłŃńŚśŹźŻżĘęĄąŌōŪūĒēĪīĞğŞşİıŘřŤťŮůĎďŇňĚěŐőŰű'
const accent_to = 'AAAAAAaaaaaaEEEEeeeeIIIIiiiiOOOOOOooooooUUUUuuuuYyyNnCcSsZzCcCcDdLlNnSsZzZzEeAaOoUuEeIiGgSsIiRrTtUuDdNnEeOoUu'
const accent_table = build_accent_table()

fn build_accent_table() map[rune]string {
	from := accent_from.runes()
	to := accent_to.runes()
	mut m := map[rune]string{}
	for i, r in from {
		m[r] = to[i].str()
	}
	m[`ß`] = 'ss'
	m[`Æ`] = 'AE'
	m[`æ`] = 'ae'
	m[`Œ`] = 'OE'
	m[`œ`] = 'oe'
	m[`Þ`] = 'Th'
	m[`þ`] = 'th'
	m[`Ð`] = 'D'
	m[`ð`] = 'd'
	return m
}

// remove_accents transliterates common Latin diacritics to ASCII (e.g. "Crème Brûlée" -> "Creme Brulee").
pub fn remove_accents(s string) string {
	if s.is_pure_ascii() {
		return s
	}
	mut sb := strings.new_builder(s.len)
	for r in s.runes() {
		if r >= 0x0300 && r <= 0x036f {
			// Drop combining diacritical marks (decomposed / NFD input).
			continue
		}
		if repl := accent_table[r] {
			sb.write_string(repl)
		} else {
			sb.write_rune(r)
		}
	}
	return sb.str()
}

// ---------------------------------------------------------------------------
// Word segmentation & extra case styles
// ---------------------------------------------------------------------------

fn is_ascii_lower(r rune) bool {
	return r >= `a` && r <= `z`
}

fn is_ascii_digit(r rune) bool {
	return r >= `0` && r <= `9`
}

// words splits identifiers and phrases into words, understanding camelCase, PascalCase, acronyms,
// digits and separators (e.g. "parseHTTPResponse_fast" -> ["parse", "HTTP", "Response", "fast"]).
pub fn words(s string) []string {
	mut res := []string{}
	runes := s.runes()
	mut cur := []rune{}
	for i, r in runes {
		is_letter := r.to_lower() != r || r.to_upper() != r
		is_sep := !(is_letter || is_ascii_digit(r) || (r > 127 && !is_whitespace(r)))
		if is_sep {
			if cur.len > 0 {
				res << cur.string()
				cur.clear()
			}
			continue
		}
		if cur.len > 0 {
			prev := cur[cur.len - 1]
			upper := r.to_lower() != r
			prev_upper := prev.to_lower() != prev
			prev_lower := prev.to_upper() != prev
			next_lower := i + 1 < runes.len && runes[i + 1].to_upper() != runes[i + 1]
			// fooBar | HTTPServer (split before 'S') | foo2 stays, 2Bar splits only on case.
			if (upper && prev_lower) || (upper && prev_upper && next_lower)
				|| (upper && is_ascii_digit(prev) && next_lower) {
				res << cur.string()
				cur.clear()
			}
		}
		cur << r
	}
	if cur.len > 0 {
		res << cur.string()
	}
	return res
}

// to_constant_case converts a string to SCREAMING_SNAKE_CASE (e.g. "maxRetryCount" -> "MAX_RETRY_COUNT").
pub fn to_constant_case(s string) string {
	return words(s).map(it.to_upper()).join('_')
}

// to_dot_case converts a string to dot.case (e.g. "AppConfigPath" -> "app.config.path").
pub fn to_dot_case(s string) string {
	return words(s).map(it.to_lower()).join('.')
}

// to_train_case converts a string to Train-Case, as used by HTTP headers (e.g. "content_type" -> "Content-Type").
pub fn to_train_case(s string) string {
	return words(s).map(capitalize(it.to_lower())).join('-')
}

// capitalize upper-cases the first rune of s, leaving the rest untouched.
pub fn capitalize(s string) string {
	if s.len == 0 {
		return s
	}
	mut runes := s.runes()
	runes[0] = runes[0].to_upper()
	return runes.string()
}

// uncapitalize lower-cases the first rune of s, leaving the rest untouched.
pub fn uncapitalize(s string) string {
	if s.len == 0 {
		return s
	}
	mut runes := s.runes()
	runes[0] = runes[0].to_lower()
	return runes.string()
}

// swap_case inverts the case of every cased rune (e.g. "Hello World" -> "hELLO wORLD").
pub fn swap_case(s string) string {
	mut runes := s.runes()
	for i, r in runes {
		lower := r.to_lower()
		runes[i] = if lower != r { lower } else { r.to_upper() }
	}
	return runes.string()
}

// humanize turns an identifier into a human readable phrase (e.g. "author_id" -> "Author", "createdAt" -> "Created at").
pub fn humanize(s string) string {
	mut ws := words(s).map(it.to_lower())
	if ws.len > 1 && ws.last() == 'id' {
		ws.delete_last()
	}
	return capitalize(ws.join(' '))
}

// ---------------------------------------------------------------------------
// Predicates & small transforms
// ---------------------------------------------------------------------------

// is_blank returns true if s is empty or consists only of Unicode whitespace.
pub fn is_blank(s string) bool {
	for r in s.runes() {
		if !is_whitespace(r) {
			return false
		}
	}
	return true
}

// default_if_blank returns fallback when s is blank, otherwise s.
pub fn default_if_blank(s string, fallback string) string {
	return if is_blank(s) { fallback } else { s }
}

// reverse reverses s rune-by-rune (UTF-8 safe).
pub fn reverse(s string) string {
	mut runes := s.runes()
	runes.reverse_in_place()
	return runes.string()
}

// is_palindrome reports whether s reads the same backwards, ignoring case, accents, and non-alphanumerics.
pub fn is_palindrome(s string) bool {
	clean := remove_accents(s).to_lower().runes().filter(is_ascii_lower(it) || is_ascii_digit(it)
		|| it > 127)
	mut i := 0
	mut j := clean.len - 1
	for i < j {
		if clean[i] != clean[j] {
			return false
		}
		i++
		j--
	}
	return true
}

// ensure_prefix returns s with prefix prepended unless it already starts with it.
pub fn ensure_prefix(s string, prefix string) string {
	return if s.starts_with(prefix) { s } else { prefix + s }
}

// ensure_suffix returns s with suffix appended unless it already ends with it.
pub fn ensure_suffix(s string, suffix string) string {
	return if s.ends_with(suffix) { s } else { s + suffix }
}

// rot13 applies the ROT13 substitution cipher to ASCII letters.
pub fn rot13(s string) string {
	mut b := s.bytes()
	for i, c in b {
		if c >= `a` && c <= `z` {
			b[i] = `a` + (c - `a` + 13) % 26
		} else if c >= `A` && c <= `Z` {
			b[i] = `A` + (c - `A` + 13) % 26
		}
	}
	return b.bytestr()
}

// extract_all_between returns every non-overlapping substring enclosed by start_delim and end_delim.
pub fn extract_all_between(s string, start_delim string, end_delim string) []string {
	mut res := []string{}
	if start_delim.len == 0 || end_delim.len == 0 {
		return res
	}
	mut pos := 0
	for pos < s.len {
		start := s.index_after(start_delim, pos) or { break }
		content_start := start + start_delim.len
		end := s.index_after(end_delim, content_start) or { break }
		res << s[content_start..end]
		pos = end + end_delim.len
	}
	return res
}

// ---------------------------------------------------------------------------
// Lines, indentation & layout
// ---------------------------------------------------------------------------

// split_lines splits s on \n, \r\n and \r line terminators (no trailing empty line for a final terminator).
pub fn split_lines(s string) []string {
	if s.len == 0 {
		return []string{}
	}
	mut lines := s.replace('\r\n', '\n').replace('\r', '\n').split('\n')
	if lines.len > 0 && lines.last() == '' {
		lines.delete_last()
	}
	return lines
}

// indent prefixes every non-blank line of s with prefix.
pub fn indent(s string, prefix string) string {
	lines := s.split('\n')
	mut out := []string{cap: lines.len}
	for line in lines {
		out << if is_blank(line) { line } else { prefix + line }
	}
	return out.join('\n')
}

// dedent removes the longest common leading whitespace from every non-blank line (like Python's textwrap.dedent).
pub fn dedent(s string) string {
	lines := s.split('\n')
	mut margin := -1
	mut margin_str := ''
	for line in lines {
		if is_blank(line) {
			continue
		}
		mut n := 0
		for n < line.len && (line[n] == ` ` || line[n] == `\t`) {
			n++
		}
		if margin == -1 {
			margin = n
			margin_str = line[..n]
			continue
		}
		// Shrink margin to the common prefix of whitespace.
		mut k := 0
		for k < margin && k < n && line[k] == margin_str[k] {
			k++
		}
		margin = k
		margin_str = margin_str[..k]
	}
	if margin <= 0 {
		return lines.map(if is_blank(it) { '' } else { it }).join('\n')
	}
	mut out := []string{cap: lines.len}
	for line in lines {
		out << if is_blank(line) { '' } else { line[margin..] }
	}
	return out.join('\n')
}

// count_words returns the number of whitespace separated words in s.
pub fn count_words(s string) int {
	return s.fields().len
}

fn rune_width(r rune) int {
	if r == 0 || (r < 0x20) || (r >= 0x7f && r < 0xa0) {
		return 0
	}
	if (r >= 0x0300 && r <= 0x036f) || (r >= 0x200b && r <= 0x200f) || (r >= 0x20d0 && r <= 0x20ff)
		|| (r >= 0xfe00 && r <= 0xfe0f) || r == 0x200d {
		return 0
	}
	if (r >= 0x1100 && r <= 0x115f) || (r >= 0x2e80 && r <= 0xa4cf && r != 0x303f)
		|| (r >= 0xac00 && r <= 0xd7a3) || (r >= 0xf900 && r <= 0xfaff)
		|| (r >= 0xfe30 && r <= 0xfe4f) || (r >= 0xff00 && r <= 0xff60)
		|| (r >= 0xffe0 && r <= 0xffe6) || (r >= 0x1f300 && r <= 0x1f64f)
		|| (r >= 0x1f900 && r <= 0x1f9ff) || (r >= 0x20000 && r <= 0x3fffd) {
		return 2
	}
	return 1
}

// display_width returns the number of terminal columns s occupies: ANSI codes and combining marks
// count 0, CJK and emoji count 2. Use it to align tables containing non-ASCII text.
pub fn display_width(s string) int {
	mut w := 0
	for r in strip_ansi(s).runes() {
		w += rune_width(r)
	}
	return w
}

// ---------------------------------------------------------------------------
// Comparison, distance & phonetics
// ---------------------------------------------------------------------------

// common_prefix returns the longest prefix (rune-aligned) shared by all strings.
pub fn common_prefix(strs []string) string {
	if strs.len == 0 {
		return ''
	}
	mut prefix := strs[0].runes()
	for s in strs[1..] {
		r := s.runes()
		mut k := 0
		for k < prefix.len && k < r.len && prefix[k] == r[k] {
			k++
		}
		prefix = prefix[..k].clone()
		if prefix.len == 0 {
			break
		}
	}
	return prefix.string()
}

// common_suffix returns the longest suffix (rune-aligned) shared by all strings.
pub fn common_suffix(strs []string) string {
	return reverse(common_prefix(strs.map(reverse(it))))
}

// hamming_distance counts positions at which two equal-length strings differ (rune-wise), or none if lengths differ.
pub fn hamming_distance(a string, b string) ?int {
	ar := a.runes()
	br := b.runes()
	if ar.len != br.len {
		return none
	}
	mut d := 0
	for i in 0 .. ar.len {
		if ar[i] != br[i] {
			d++
		}
	}
	return d
}

// jaro_winkler returns the Jaro-Winkler similarity in [0, 1], tuned for short strings such as names.
pub fn jaro_winkler(a string, b string) f64 {
	ar := a.runes()
	br := b.runes()
	if ar.len == 0 && br.len == 0 {
		return 1.0
	}
	if ar.len == 0 || br.len == 0 {
		return 0.0
	}
	mut match_dist := (if ar.len > br.len { ar.len } else { br.len }) / 2 - 1
	if match_dist < 0 {
		match_dist = 0
	}
	mut a_m := []bool{len: ar.len}
	mut b_m := []bool{len: br.len}
	mut matches := 0
	for i in 0 .. ar.len {
		lo := if i - match_dist > 0 { i - match_dist } else { 0 }
		hi := if i + match_dist + 1 < br.len { i + match_dist + 1 } else { br.len }
		for j in lo .. hi {
			if b_m[j] || ar[i] != br[j] {
				continue
			}
			a_m[i] = true
			b_m[j] = true
			matches++
			break
		}
	}
	if matches == 0 {
		return 0.0
	}
	mut transpositions := 0
	mut k := 0
	for i in 0 .. ar.len {
		if !a_m[i] {
			continue
		}
		for !b_m[k] {
			k++
		}
		if ar[i] != br[k] {
			transpositions++
		}
		k++
	}
	m := f64(matches)
	jaro := (m / f64(ar.len) + m / f64(br.len) + (m - f64(transpositions) / 2.0) / m) / 3.0
	mut prefix := 0
	for i in 0 .. math.min(4, math.min(ar.len, br.len)) {
		if ar[i] != br[i] {
			break
		}
		prefix++
	}
	return jaro + f64(prefix) * 0.1 * (1.0 - jaro)
}

// fuzzy_match reports whether every rune of query appears in target in order (case-insensitive),
// the matching model popularised by fzf / Sublime Text "Goto Anything".
pub fn fuzzy_match(query string, target string) bool {
	q := query.to_lower().runes()
	if q.len == 0 {
		return true
	}
	mut qi := 0
	for r in target.to_lower().runes() {
		if r == q[qi] {
			qi++
			if qi == q.len {
				return true
			}
		}
	}
	return false
}

// did_you_mean returns the candidate closest to input (by Levenshtein distance) if it is within
// max_distance edits, ideal for "unknown command, did you mean ...?" CLI hints.
pub fn did_you_mean(input string, candidates []string, max_distance int) ?string {
	mut best := ''
	mut best_d := max_distance + 1
	lower := input.to_lower()
	for c in candidates {
		d := levenshtein_distance(lower, c.to_lower())
		if d < best_d {
			best_d = d
			best = c
		}
	}
	if best_d <= max_distance {
		return best
	}
	return none
}

fn soundex_code(c u8) u8 {
	return match c {
		`B`, `F`, `P`, `V` { `1` }
		`C`, `G`, `J`, `K`, `Q`, `S`, `X`, `Z` { `2` }
		`D`, `T` { `3` }
		`L` { `4` }
		`M`, `N` { `5` }
		`R` { `6` }
		`H`, `W` { `-` }
		else { `0` }
	}
}

// soundex returns the American Soundex phonetic code (e.g. "Robert" and "Rupert" -> "R163").
pub fn soundex(s string) string {
	mut letters := []u8{}
	for c in remove_accents(s).to_upper().bytes() {
		if c >= `A` && c <= `Z` {
			letters << c
		}
	}
	if letters.len == 0 {
		return ''
	}
	mut out := [letters[0]]
	mut last := soundex_code(letters[0])
	for c in letters[1..] {
		code := soundex_code(c)
		if code == `-` {
			continue
		}
		if code == `0` {
			last = `0`
			continue
		}
		if code != last {
			out << code
			if out.len == 4 {
				break
			}
		}
		last = code
	}
	for out.len < 4 {
		out << `0`
	}
	return out.bytestr()
}

// natural_compare compares strings the way humans expect, treating digit runs as numbers
// ("file2" < "file10"), case-insensitively. Returns -1, 0 or 1.
// Use with sort: `arr.sort_with_compare(fn (a &string, b &string) int { return natural_compare(*a, *b) })`.
pub fn natural_compare(a string, b string) int {
	mut i := 0
	mut j := 0
	for i < a.len && j < b.len {
		ca := a[i]
		cb := b[j]
		if ca.is_digit() && cb.is_digit() {
			mut si := i
			for si < a.len && a[si] == `0` {
				si++
			}
			mut sj := j
			for sj < b.len && b[sj] == `0` {
				sj++
			}
			mut ei := si
			for ei < a.len && a[ei].is_digit() {
				ei++
			}
			mut ej := sj
			for ej < b.len && b[ej].is_digit() {
				ej++
			}
			la := ei - si
			lb := ej - sj
			if la != lb {
				return if la < lb { -1 } else { 1 }
			}
			for k in 0 .. la {
				if a[si + k] != b[sj + k] {
					return if a[si + k] < b[sj + k] { -1 } else { 1 }
				}
			}
			i = ei
			j = ej
			continue
		}
		la := if ca >= `A` && ca <= `Z` { ca + 32 } else { ca }
		lb := if cb >= `A` && cb <= `Z` { cb + 32 } else { cb }
		if la != lb {
			return if la < lb { -1 } else { 1 }
		}
		i++
		j++
	}
	if i < a.len {
		return 1
	}
	if j < b.len {
		return -1
	}
	return if a < b {
		-1
	} else if a > b {
		1
	} else {
		0
	}
}

// natural_sort sorts strings in place using natural_compare.
pub fn natural_sort(mut arr []string) {
	arr.sort_with_compare(fn (a &string, b &string) int {
		return natural_compare(*a, *b)
	})
}

// ---------------------------------------------------------------------------
// English inflection
// ---------------------------------------------------------------------------

const uncountable_words = ['equipment', 'information', 'rice', 'money', 'species', 'series', 'fish',
	'sheep', 'deer', 'news', 'moose', 'bison', 'aircraft', 'software', 'hardware', 'metadata',
	'police', 'feedback', 'traffic']

const irregular_plurals = {
	'person':     'people'
	'man':        'men'
	'woman':      'women'
	'child':      'children'
	'tooth':      'teeth'
	'foot':       'feet'
	'mouse':      'mice'
	'goose':      'geese'
	'ox':         'oxen'
	'analysis':   'analyses'
	'axis':       'axes'
	'basis':      'bases'
	'crisis':     'crises'
	'diagnosis':  'diagnoses'
	'hypothesis': 'hypotheses'
	'thesis':     'theses'
	'cactus':     'cacti'
	'fungus':     'fungi'
	'nucleus':    'nuclei'
	'radius':     'radii'
	'criterion':  'criteria'
	'phenomenon': 'phenomena'
	'matrix':     'matrices'
	'vertex':     'vertices'
	'quiz':       'quizzes'
	'datum':      'data'
	'medium':     'media'
	'appendix':   'appendices'
	'leaf':       'leaves'
	'loaf':       'loaves'
	'half':       'halves'
	'wolf':       'wolves'
	'shelf':      'shelves'
	'calf':       'calves'
	'elf':        'elves'
	'thief':      'thieves'
	'hero':       'heroes'
	'potato':     'potatoes'
	'tomato':     'tomatoes'
	'echo':       'echoes'
	'veto':       'vetoes'
	'torpedo':    'torpedoes'
}

const irregular_singulars = build_irregular_singulars()

fn build_irregular_singulars() map[string]string {
	mut m := map[string]string{}
	for k, v in irregular_plurals {
		m[v] = k
	}
	return m
}

fn match_case(template string, word string) string {
	if template.len == 0 {
		return word
	}
	if template.len > 1 && template == template.to_upper() && template != template.to_lower() {
		return word.to_upper()
	}
	first := template.runes()[0]
	if first.to_lower() != first {
		return capitalize(word)
	}
	return word
}

fn is_vowel(c u8) bool {
	return c in [`a`, `e`, `i`, `o`, `u`]
}

// pluralize returns the English plural of a singular noun, handling irregulars, uncountables
// and common suffix rules while preserving case (e.g. "Child" -> "Children", "box" -> "boxes").
pub fn pluralize(word string) string {
	w := word.to_lower()
	if w.len == 0 || w in uncountable_words {
		return word
	}
	if p := irregular_plurals[w] {
		return match_case(word, p)
	}
	if w in irregular_singulars {
		return word
	}
	res := if w.ends_with('s') || w.ends_with('x') || w.ends_with('z') || w.ends_with('ch')
		|| w.ends_with('sh') {
		w + 'es'
	} else if w.ends_with('y') && w.len > 1 && !is_vowel(w[w.len - 2]) {
		w[..w.len - 1] + 'ies'
	} else if w.ends_with('fe') {
		w[..w.len - 2] + 'ves'
	} else {
		w + 's'
	}
	return match_case(word, res)
}

// singularize returns the English singular of a plural noun (e.g. "categories" -> "category", "People" -> "Person").
pub fn singularize(word string) string {
	w := word.to_lower()
	if w.len == 0 || w in uncountable_words {
		return word
	}
	if s := irregular_singulars[w] {
		return match_case(word, s)
	}
	if w in irregular_plurals {
		return word
	}
	res := if w.ends_with('ies') && w.len > 3 {
		w[..w.len - 3] + 'y'
	} else if w.ends_with('ives') {
		w[..w.len - 3] + 'fe'
	} else if w.ends_with('sses') || w.ends_with('xes') || w.ends_with('zes') || w.ends_with('ches')
		|| w.ends_with('shes') || w.ends_with('uses') {
		w[..w.len - 2]
	} else if w.ends_with('ss') || w.ends_with('us') || w.ends_with('is') {
		w
	} else if w.ends_with('s') {
		w[..w.len - 1]
	} else {
		w
	}
	return match_case(word, res)
}

// pluralize_count formats a count with a correctly inflected noun (e.g. (1, "file") -> "1 file", (3, "file") -> "3 files").
pub fn pluralize_count(n i64, word string) string {
	noun := if n == 1 || n == -1 { word } else { pluralize(word) }
	return '${n} ${noun}'
}

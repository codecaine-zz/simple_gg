module regexutils

import regex

// Match contains the text and character span for a regex find result.
pub struct Match {
pub:
	text  string
	start int
	end   int
}

// is_match tests if the entire text matches the given regex pattern.
pub fn is_match(pattern string, text string) bool {
	mut re := regex.regex_opt(pattern) or { return false }
	return re.matches_string(text)
}

// contains_match tests if the regex pattern appears anywhere within text.
pub fn contains_match(pattern string, text string) bool {
	mut re := regex.regex_opt(pattern) or { return false }
	start, _ := re.find(text)
	return start >= 0
}

// find_first returns the first matching substring, or none if no match is found.
pub fn find_first(pattern string, text string) ?string {
	mut re := regex.regex_opt(pattern) or { return none }
	start, end := re.find(text)
	if start < 0 {
		return none
	}
	return text[start..end]
}

// find_all returns all non-overlapping matching substrings in text.
pub fn find_all(pattern string, text string) []string {
	mut re := regex.regex_opt(pattern) or { return [] }
	return re.find_all_str(text)
}

// find_matches returns all matches with their index start/end spans.
pub fn find_matches(pattern string, text string) []Match {
	mut re := regex.regex_opt(pattern) or { return [] }
	spans := re.find_all(text)
	mut matches := []Match{cap: spans.len / 2}
	for i := 0; i < spans.len; i += 2 {
		start := spans[i]
		end := spans[i + 1]
		if start >= 0 && end <= text.len && start <= end {
			matches << Match{
				text: text[start..end]
				start: start
				end: end
			}
		}
	}
	return matches
}

// replace substitutes all occurrences matching pattern with repl.
pub fn replace(pattern string, text string, repl string) string {
	mut re := regex.regex_opt(pattern) or { return text }
	return re.replace(text, repl)
}

// replace_n substitutes up to count occurrences matching pattern with repl.
pub fn replace_n(pattern string, text string, repl string, count int) string {
	mut re := regex.regex_opt(pattern) or { return text }
	return re.replace_n(text, repl, count)
}

// split divides text into a list of substrings separated by pattern.
pub fn split(pattern string, text string) []string {
	mut re := regex.regex_opt(pattern) or { return [text] }
	return re.split(text)
}

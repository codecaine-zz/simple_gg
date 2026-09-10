module regexutils

fn test_is_match() {
	assert is_match(r'^\d+$', '12345')
	assert !is_match(r'^\d+$', '123a45')
	assert is_match(r'^[a-z]+$', 'hello')
}

fn test_contains_match() {
	assert contains_match(r'\d+', 'order 123 in progress')
	assert !contains_match(r'\d+', 'no numbers here')
}

fn test_find_first() {
	match_str := find_first(r'\d+', 'invoice 420 paid') or { 'none' }
	assert match_str == '420'

	none_match := find_first(r'\d+', 'pure text') or { 'none' }
	assert none_match == 'none'
}

fn test_find_all() {
	numbers := find_all(r'\d+', 'call 555-123-4567')
	assert numbers == ['555', '123', '4567']

	empty := find_all(r'\d+', 'letters only')
	assert empty.len == 0
}

fn test_find_matches() {
	matches := find_matches(r'\d+', 'items: 10, 20')
	assert matches.len == 2
	assert matches[0].text == '10'
	assert matches[0].start == 7
	assert matches[0].end == 9
	assert matches[1].text == '20'
}

fn test_replace() {
	replaced := replace(r'\d+', 'secret 123 and 456', 'XXX')
	assert replaced == 'secret XXX and XXX'
}

fn test_replace_n() {
	replaced := replace_n(r'\d+', '1 2 3 4', 'X', 2)
	assert replaced == 'X X 3 4'
}

fn test_split() {
	parts := split(r'\s*,\s*', 'apple, banana , cherry')
	assert parts == ['apple', 'banana', 'cherry']
}

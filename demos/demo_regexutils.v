module main

import regexutils

fn main() {
	println('==================================================')
	println('                demo_regexutils                   ')
	println('==================================================')

	text := 'User #101 ordered 5 items on 2026-09-10'
	digits_pattern := r'\d+'

	// 1. is_match (full string) and contains_match (substring)
	is_numeric := regexutils.is_match(r'^\d+$', '2026')
	has_digits := regexutils.contains_match(digits_pattern, text)
	println('Text: "${text}"')
	println('"2026" is numeric: ${is_numeric}')
	println('Text contains digits: ${has_digits}')
	assert is_numeric == true
	assert has_digits == true

	// 2. find_first
	first := regexutils.find_first(digits_pattern, text) or { 'none' }
	println('First digit match: "${first}"')
	assert first == '101'

	// 3. find_all
	all_matches := regexutils.find_all(digits_pattern, text)
	println('All numeric matches: ${all_matches}')
	assert all_matches == ['101', '5', '2026', '09', '10']

	// 4. replace
	replaced := regexutils.replace(digits_pattern, text, '#')
	println('Masked numbers: "${replaced}"')
	assert replaced == 'User ## ordered # items on #-#-#'

	// 5. split
	tokens := regexutils.split(r'[,;\s]+', 'apple, banana; orange  grape')
	println('Split tokens: ${tokens}')
	assert tokens == ['apple', 'banana', 'orange', 'grape']

	println('\n✔ regexutils demo completed successfully!')
}

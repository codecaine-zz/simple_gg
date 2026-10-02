module strutils

fn test_case_conversions() {
	assert to_snake_case('helloWorld') == 'hello_world'
	assert to_snake_case('HelloWorld') == 'hello_world'
	assert to_snake_case('hello-world') == 'hello_world'
	assert to_snake_case('hello world') == 'hello_world'
	assert to_snake_case('HTTPResponseCode') == 'http_response_code'

	assert to_kebab_case('helloWorld') == 'hello-world'
	assert to_kebab_case('Hello_World') == 'hello-world'

	assert to_camel_case('hello_world') == 'helloWorld'
	assert to_camel_case('Hello-World') == 'helloWorld'

	assert to_pascal_case('hello_world') == 'HelloWorld'
	assert to_pascal_case('hello-world') == 'HelloWorld'

	assert to_title_case('hello world_again') == 'Hello World Again'
}

fn test_slugify() {
	assert slugify('Hello World!') == 'hello-world'
	assert slugify('  V Lang 2026: The Future  ') == 'v-lang-2026-the-future'
	assert slugify('multiple---hyphens   spaces') == 'multiple-hyphens-spaces'
}

fn test_truncate_and_padding() {
	assert truncate('Hello, world!', 8, '...') == 'Hello...'
	assert truncate('Short', 10, '...') == 'Short'

	assert truncate_words('The quick brown fox jumps over', 3, '...') == 'The quick brown...'

	assert pad_left('42', 5, '0') == '00042'
	assert pad_right('hi', 5, ' ') == 'hi   '
	assert pad_center('v', 5, '=') == '==v=='
}

fn test_masking() {
	assert mask('1234567890', 2, 2, '*') == '12******90'
	assert mask_email('john.doe@example.com') == 'j******e@example.com'
	assert mask_email('ab@test.com') == 'a*@test.com'
}

fn test_random() {
	s1 := random_alphanumeric(16)
	assert s1.len == 16

	hex1 := random_hex(10)
	assert hex1.len == 10
}

fn test_text_processing() {
	html := '<p>Hello <b>World</b>!</p>'
	assert strip_html_tags(html) == 'Hello World!'

	spaced := '  hello    world \t\n  vlang '
	assert collapse_whitespace(spaced) == 'hello world vlang'

	wrapped := word_wrap('one two three four five six', 10)
	assert wrapped.contains('\n')

	extracted := extract_between('start [content] end', '[', ']') or { '' }
	assert extracted == 'content'
}

fn test_fuzzy_matching() {
	assert levenshtein_distance('kitten', 'sitting') == 3
	assert levenshtein_distance('vlang', 'vlang') == 0
	assert levenshtein_distance('', 'abc') == 3

	sim := similarity('hello', 'hello')
	assert sim == 1.0

	sim2 := similarity('hello', 'hallo')
	assert sim2 > 0.7
}

fn test_formatting_and_ansi() {
	assert format_int_commas(0) == '0'
	assert format_int_commas(123) == '123'
	assert format_int_commas(1000) == '1,000'
	assert format_int_commas(1234567) == '1,234,567'
	assert format_int_commas(-9876543) == '-9,876,543'

	assert format_number_commas(1234567.89, 2) == '1,234,567.89'
	assert format_number_commas(1000.0, 0) == '1,000'

	assert ordinal(1) == '1st'
	assert ordinal(2) == '2nd'
	assert ordinal(3) == '3rd'
	assert ordinal(4) == '4th'
	assert ordinal(11) == '11th'
	assert ordinal(12) == '12th'
	assert ordinal(13) == '13th'
	assert ordinal(21) == '21st'
	assert ordinal(102) == '102nd'

	assert truncate_middle('0123456789abcdef', 10, '...') == '0123...def'
	assert truncate_middle('short', 10, '...') == 'short'

	colored := '\x1b[31;1mRed Alert\x1b[0m'
	assert strip_ansi(colored) == 'Red Alert'
}

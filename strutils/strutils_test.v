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

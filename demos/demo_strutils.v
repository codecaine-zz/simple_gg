module main

import strutils

fn main() {
	println('==================================================')
	println('                demo_strutils                     ')
	println('==================================================')

	// 1. Case Conversions
	raw := 'vLanguageUtils 2026'
	println('Raw string: "${raw}"')
	println('Snake:  ' + strutils.to_snake_case(raw))
	println('Kebab:  ' + strutils.to_kebab_case(raw))
	println('Camel:  ' + strutils.to_camel_case(raw))
	println('Pascal: ' + strutils.to_pascal_case(raw))
	assert strutils.to_snake_case('helloWorld') == 'hello_world'
	assert strutils.to_kebab_case('helloWorld') == 'hello-world'
	assert strutils.to_camel_case('hello_world') == 'helloWorld'
	assert strutils.to_pascal_case('hello_world') == 'HelloWorld'

	// 2. Slugs & Masking
	slug := strutils.slugify('Hello, World! 2026: Fast & Clean')
	println('\nSlug: ' + slug)
	assert slug == 'hello-world-2026-fast-and-clean' || slug == 'hello-world-2026-fast-clean'

	masked_key := strutils.mask('sk-live-1234567890abcdef', 4, 4, '*')
	masked_email := strutils.mask_email('developer@company.org')
	println('Masked key:   ' + masked_key)
	println('Masked email: ' + masked_email)
	assert masked_key.starts_with('sk-l')
	assert masked_email.ends_with('@company.org')

	// 3. Truncation, Wrapping & Padding
	sentence := 'The quick brown fox jumps over the lazy dog'
	truncated := strutils.truncate_words(sentence, 4, '...')
	padded := strutils.pad_left('42', 6, '0')
	println('\nTruncated (4 words): ' + truncated)
	println('Padded left: ' + padded)
	assert truncated == 'The quick brown fox...'
	assert padded == '000042'

	// 4. Levenshtein Distance & Token Generation
	dist := strutils.levenshtein_distance('sitting', 'kitten')
	token := strutils.random_alphanumeric(16)
	println('\nLevenshtein (sitting -> kitten): ${dist}')
	println('Random token (16 chars): ${token}')
	assert dist == 3
	assert token.len == 16

	println('\n✔ strutils demo completed successfully!')
}

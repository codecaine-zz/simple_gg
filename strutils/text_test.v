module strutils

fn test_whitespace_is_unicode_correct() {
	// U+0120 used to be truncated to 0x20 (space) and collapsed.
	assert collapse_whitespace('aĠb') == 'aĠb'
	assert collapse_whitespace('a\u00a0\u3000b') == 'a b'
	assert is_blank(' \t\n\u2003')
	assert !is_blank(' x ')
	assert default_if_blank('   ', 'fallback') == 'fallback'
}

fn test_mask_edge_cases() {
	assert mask('secret', -3, -1, '*') == '******'
	assert mask_email('@example.com') == '@example.com'
	assert mask_email('é@x.io') == 'é*@x.io'
	assert mask_email('a"b@c"@host.com').ends_with('@host.com')
}

fn test_number_formatting_edge_cases() {
	assert format_int_commas(-9223372036854775807 - 1) == '-9,223,372,036,854,775,808'
	assert format_number_commas(0.999, 2) == '1.00'
	assert format_number_commas(-0.5, 2) == '-0.50'
	assert format_number_commas(-1234.567, 1) == '-1,234.6'
	assert format_number_commas(-0.001, 2) == '0.00'
	assert format_number_commas(1234567.89, 2) == '1,234,567.89'
}

fn test_strip_ansi_full_sequences() {
	assert strip_ansi('\x1b[1;31mred\x1b[0m') == 'red'
	assert strip_ansi('\x1b[2~x') == 'x'
	assert strip_ansi('\x1b]8;;https://v.dev\x07link\x1b]8;;\x07') == 'link'
	assert strip_ansi('\x1b]0;title\x1b\\body') == 'body'
	assert strip_ansi('plain') == 'plain'
}

fn test_remove_accents_and_slugify() {
	assert remove_accents('Crème Brûlée à Łódź') == 'Creme Brulee a Lodz'
	assert remove_accents('Straße') == 'Strasse'
	assert remove_accents('e\u0301') == 'e'
	assert slugify('Café Déjà Vu') == 'cafe-deja-vu'
}

fn test_words_and_cases() {
	assert words('parseHTTPResponse_fast') == ['parse', 'HTTP', 'Response', 'fast']
	assert words('hello-world  foo') == ['hello', 'world', 'foo']
	assert words('Version2Beta') == ['Version2', 'Beta']
	assert to_constant_case('maxRetryCount') == 'MAX_RETRY_COUNT'
	assert to_dot_case('AppConfigPath') == 'app.config.path'
	assert to_train_case('content_type') == 'Content-Type'
	assert capitalize('éclair') == 'Éclair'
	assert uncapitalize('Hello') == 'hello'
	assert swap_case('Hello World') == 'hELLO wORLD'
	assert humanize('author_id') == 'Author'
	assert humanize('createdAt') == 'Created at'
}

fn test_small_transforms() {
	assert reverse('héllo') == 'olléh'
	assert is_palindrome('A man, a plan, a canal: Panamá')
	assert !is_palindrome('vlang')
	assert ensure_prefix('example.com', 'https://') == 'https://example.com'
	assert ensure_prefix('https://x', 'https://') == 'https://x'
	assert ensure_suffix('dir', '/') == 'dir/'
	assert rot13('Hello') == 'Uryyb'
	assert rot13(rot13('Round Trip!')) == 'Round Trip!'
	assert extract_all_between('a[1]b[22]c[', '[', ']') == ['1', '22']
}

fn test_lines_and_indentation() {
	assert split_lines('a\r\nb\rc\n') == ['a', 'b', 'c']
	assert split_lines('') == []string{}
	assert indent('a\n\nb', '  ') == '  a\n\n  b'
	assert dedent('    def f():\n        return 1\n') == 'def f():\n    return 1\n'
	assert dedent('\tx\n\t\ty') == 'x\n\ty'
	assert count_words('  the quick  brown fox ') == 4
	assert display_width('abc') == 3
	assert display_width('日本') == 4
	assert display_width('\x1b[31mok\x1b[0m') == 2
	assert display_width('e\u0301') == 1
}

fn test_distance_and_matching() {
	assert common_prefix(['interstellar', 'internet', 'interval']) == 'inter'
	assert common_prefix([]string{}) == ''
	assert common_suffix(['testing', 'running', 'jumping']) == 'ing'
	assert hamming_distance('karolin', 'kathrin')? == 3
	assert hamming_distance('a', 'ab') == none
	jw := jaro_winkler('MARTHA', 'MARHTA')
	assert jw > 0.96 && jw < 0.962
	assert jaro_winkler('', '') == 1.0
	assert jaro_winkler('abc', '') == 0.0
	assert fuzzy_match('fzf', 'FuzzyFinder')
	assert !fuzzy_match('zq', 'fuzzy_find')
	assert did_you_mean('stauts', ['status', 'start', 'stop'], 2)? == 'status'
	assert did_you_mean('xyzzy', ['status'], 2) == none
}

fn test_soundex() {
	assert soundex('Robert') == 'R163'
	assert soundex('Rupert') == 'R163'
	assert soundex('Ashcraft') == 'A261'
	assert soundex('Tymczak') == 'T522'
	assert soundex('Pfister') == 'P236'
	assert soundex('Lee') == 'L000'
	assert soundex('') == ''
}

fn test_natural_sort() {
	assert natural_compare('file2', 'file10') == -1
	assert natural_compare('File10', 'file2') == 1
	assert natural_compare('v1.10.0', 'v1.9.3') == 1
	assert natural_compare('a', 'a') == 0
	mut files := ['img12.png', 'img10.png', 'IMG2.png', 'img1.png']
	natural_sort(mut files)
	assert files == ['img1.png', 'IMG2.png', 'img10.png', 'img12.png']
}

fn test_inflection() {
	assert pluralize('box') == 'boxes'
	assert pluralize('category') == 'categories'
	assert pluralize('day') == 'days'
	assert pluralize('knife') == 'knives'
	assert pluralize('Child') == 'Children'
	assert pluralize('PERSON') == 'PEOPLE'
	assert pluralize('sheep') == 'sheep'
	assert pluralize('people') == 'people'
	assert pluralize('status') == 'statuses'
	assert singularize('categories') == 'category'
	assert singularize('boxes') == 'box'
	assert singularize('knives') == 'knife'
	assert singularize('wolves') == 'wolf'
	assert singularize('People') == 'Person'
	assert singularize('statuses') == 'status'
	assert singularize('class') == 'class'
	assert singularize('users') == 'user'
	assert pluralize_count(1, 'file') == '1 file'
	assert pluralize_count(3, 'query') == '3 queries'
}

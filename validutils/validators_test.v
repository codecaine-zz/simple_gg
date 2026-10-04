module validutils

fn test_email_tightened() {
	assert validate_email('developer@company.org')
	assert validate_email("o'brien+tag@mail.example.co.uk")
	assert !validate_email('a b@x.com')
	assert !validate_email('x@a..com')
	assert !validate_email('.x@a.com')
	assert !validate_email('x.@a.com')
	assert !validate_email('x@-a.com')
	assert !validate_email('x@a.c0m')
	assert !validate_email('${'a'.repeat(65)}@a.com')
}

fn test_url_tightened() {
	assert validate_url('https://vlang.io')
	assert validate_url('http://localhost:8080/path?q=1')
	assert validate_url('https://user:pw@api.example.com/v1')
	assert validate_url('http://192.168.0.1:3000')
	assert validate_url('http://[::1]:8080/')
	assert !validate_url('http://a b.com')
	assert !validate_url('http://exa_mple.com')
	assert !validate_url('http://example.com:99999')
	assert !validate_url('http://example.com:')
	assert !validate_url('http://[zz::1]/')
}

fn test_network_validators() {
	assert validate_hostname('localhost')
	assert validate_hostname('a-b.example.com.')
	assert !validate_hostname('-bad.com')
	assert !validate_hostname('${'a'.repeat(64)}.com')
	assert validate_port('443') && !validate_port('0') && !validate_port('65536') && !validate_port('8a')
	for ok in ['::', '::1', '2001:db8::8a2e:370:7334', 'fe80::1%eth0', '::ffff:192.0.2.1',
		'2001:0db8:0000:0000:0000:ff00:0042:8329'] {
		assert validate_ipv6(ok), ok
	}
	for bad in ['', ':', '1::2::3', '12345::', '2001:db8:::1', '1:2:3:4:5:6:7:8:9', ':1::',
		'::ffff:999.0.0.1', 'fe80::1%'] {
		assert !validate_ipv6(bad), bad
	}
	assert validate_cidr('10.0.0.0/8') && validate_cidr('2001:db8::/32')
	assert !validate_cidr('10.0.0.0/33') && !validate_cidr('10.0.0.0') && !validate_cidr('x/8')
	assert validate_mac('00:1A:2b:3C:4d:5E') && validate_mac('00-1A-2B-3C-4D-5E')
	assert validate_mac('001a.2b3c.4d5e')
	assert !validate_mac('00:1A:2B:3C:4D') && !validate_mac('00:1A-2B:3C:4D:5E')
}

fn test_financial_and_identifiers() {
	assert luhn_check('79927398713')
	assert !luhn_check('79927398710')
	assert validate_credit_card('4111 1111 1111 1111')
	assert !validate_credit_card('4111 1111 1111 1112')
	assert card_brand('4111111111111111') == 'visa'
	assert card_brand('5500 0000 0000 0004') == 'mastercard'
	assert card_brand('2221000000000009') == 'mastercard'
	assert card_brand('378282246310005') == 'amex'
	assert card_brand('6011111111111117') == 'discover'
	assert card_brand('9999') == 'unknown'
	assert validate_iban('GB82 WEST 1234 5698 7654 32')
	assert validate_iban('DE89370400440532013000')
	assert !validate_iban('GB82 WEST 1234 5698 7654 33')
	assert validate_isbn('0-306-40615-2')
	assert validate_isbn('978-0-306-40615-7')
	assert validate_isbn('0-8044-2957-X')
	assert !validate_isbn('978-0-306-40615-8')
	assert validate_ulid('01ARZ3NDEKTSV4RRFFQ69G5FAV')
	assert !validate_ulid('01ARZ3NDEKTSV4RRFFQ69G5FAU'[..25])
	assert !validate_ulid('81ARZ3NDEKTSV4RRFFQ69G5FAV')
}

fn test_format_validators() {
	assert validate_hex_color('#fff') && validate_hex_color('#A1B2C3') && validate_hex_color('#a1b2c3d4')
	assert !validate_hex_color('fff') && !validate_hex_color('#ggg') && !validate_hex_color('#12345')
	assert validate_slug('my-post-2026') && !validate_slug('My-Post') && !validate_slug('a--b')
	assert validate_base64('aGVsbG8=') && validate_base64('aGVsbG8h')
	assert !validate_base64('aGVsbG8') && !validate_base64('aGV$bG8=')
	assert validate_e164('+14155552671') && !validate_e164('14155552671') && !validate_e164('+0123')
	assert validate_date('2024-02-29') && !validate_date('2023-02-29') && !validate_date('2023-13-01')
	assert !validate_date('2023-1-01')
}

fn test_password_strength() {
	weak := password_strength('password')
	assert weak.score == 0
	assert weak.suggestions.any(it.contains('common'))
	assert password_strength('aaaaaaaaaaaaaaaa').score <= 1
	strong := password_strength('T7#vq!Lm9@zR2^wX')
	assert strong.score == 4
	assert strong.suggestions.len == 0
	assert password_strength('').score == 0
}

fn test_fluent_validator() {
	mut v := Validator{}
	v.required('name', ' ').email('email', 'nope').min_len('password', 'short', 12).range('age',
		150, 0, 130).one_of('role', 'root', ['user', 'admin']).date('dob', '2023-02-30')
	assert !v.is_valid()
	assert v.errors['name'] == ['is required']
	msgs := v.error_messages()
	assert msgs.len == 6
	assert msgs[0] == 'age must be between 0 and 130'
	mut ok := Validator{}
	ok.required('name', 'Ada').email('email', 'ada@example.com').email('optional', '')
	assert ok.is_valid()
}

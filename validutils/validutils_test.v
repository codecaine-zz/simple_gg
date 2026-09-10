module validutils

fn test_validations() {
	assert validate_email('developer@company.org') == true
	assert validate_email('user.name+tag@sub.domain.co') == true
	assert validate_email('invalid-email') == false
	assert validate_email('no@domain') == false
	assert validate_email('@domain.com') == false

	assert validate_url('https://vlang.io') == true
	assert validate_url('http://localhost:8080/path?q=1') == true
	assert validate_url('ftp://files.org') == false
	assert validate_url('not a url') == false

	assert validate_ip('192.168.1.1') == true
	assert validate_ip('127.0.0.1') == true
	assert validate_ip('256.0.0.1') == false
	assert validate_ip('192.168.01.1') == false
	assert validate_ip('192.168.1') == false

	assert validate_phone('+1 (555) 234-5678') == true
	assert validate_phone('555-1234') == true
	assert validate_phone('abc123') == false

	assert validate_alphanumeric('AdminUser123') == true
	assert validate_alphanumeric('User_123!') == false

	assert validate_numeric_range(85.5, 0.0, 100.0) == true
	assert validate_numeric_range(105.0, 0.0, 100.0) == false

	assert validate_length('secretpass', 8, 32) == true
	assert validate_length('short', 8, 32) == false

	assert validate_uuid('123e4567-e89b-12d3-a456-426614174000') == true
	assert validate_uuid('invalid-uuid') == false

	assert validate_json('{"name": "Alice"}') == true
	assert validate_json('["a", "b"]') == true
	assert validate_json('{invalid json}') == false
}

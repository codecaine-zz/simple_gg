module mockutils

fn test_lorem_generators() {
	words := lorem_words(5)
	assert words.len > 0

	sentence := lorem_sentence()
	assert sentence.len > 0

	text := lorem_text(2, 2, 4)
	assert text.len > 0
}

fn test_mock_names() {
	first := mock_first_name()
	assert first.len > 0

	last := mock_last_name()
	assert last.len > 0

	full := mock_full_name()
	assert full.contains(' ')
}

fn test_mock_network_and_contact() {
	email := mock_email()
	assert email.contains('@')
	assert email.contains('.')

	phone := mock_phone()
	assert phone.starts_with('+1-')

	ip := mock_ipv4()
	parts := ip.split('.')
	assert parts.len == 4

	url := mock_url()
	assert url.starts_with('http://') || url.starts_with('https://')
}

fn test_mock_user_and_users() {
	u := mock_user()
	assert u.id >= 1000
	assert u.name.len > 0
	assert u.email.contains('@')
	assert u.phone.len > 0
	assert u.ip.len > 0
	assert u.role.len > 0

	users := mock_users(3)
	assert users.len == 3
	assert users[0].id == 1
	assert users[1].id == 2
	assert users[2].id == 3
}

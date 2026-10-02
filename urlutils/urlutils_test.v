module urlutils

fn test_parse_url() {
	raw := 'https://admin:supersecret@api.example.com:8443/v1/users/profile?theme=dark&page=1#overview'
	u := parse_url(raw) or { panic(err) }

	assert u.scheme == 'https'
	assert u.username == 'admin'
	assert u.password == 'supersecret'
	assert u.host == 'api.example.com'
	assert u.port == 8443
	assert u.path == '/v1/users/profile'
	assert u.query['theme'] == 'dark'
	assert u.query['page'] == '1'
	assert u.fragment == 'overview'
	assert u.host_with_port() == 'api.example.com:8443'

	segs := u.path_segments()
	assert segs == ['v1', 'users', 'profile']
}

fn test_redact_credentials() {
	conn_str := 'postgres://postgres:mypassword123@db.internal.net:5432/production_db'
	redacted := redact_credentials(conn_str)
	assert redacted.contains('postgres:***@db.internal.net')
	assert !redacted.contains('mypassword123')
}

fn test_join_path() {
	assert join_path('/api/', '/v1/', 'users/') == '/api/v1/users'
	assert join_path('https://example.com', 'foo', 'bar') == 'https://example.com/foo/bar'
}

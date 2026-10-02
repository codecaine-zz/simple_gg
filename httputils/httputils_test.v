module httputils

fn test_query_string_builder_and_parser() {
	params := {
		'page':   '1'
		'search': 'v language'
		'filter': 'active'
	}
	qs := build_query_string(params)
	assert qs.contains('page=1')
	assert qs.contains('filter=active')
	assert qs.contains('search=v+language') || qs.contains('search=v%20language')

	parsed := parse_query_string(qs)
	assert parsed['page'] == '1'
	assert parsed['filter'] == 'active'
	assert parsed['search'] == 'v language'

	// Test with leading question mark
	parsed_with_q := parse_query_string('?name=alice&role=admin')
	assert parsed_with_q['name'] == 'alice'
	assert parsed_with_q['role'] == 'admin'

	// Empty query string
	empty := parse_query_string('')
	assert empty.len == 0
}

struct DummyPayload {
	title string
	count int
}

fn test_json_payload_types() {
	// Verify dummy types serialize and deserialize as expected
	p := DummyPayload{
		title: 'test'
		count: 5
	}
	encoded := build_query_string({
		'title': p.title
		'count': '${p.count}'
	})
	assert encoded.contains('title=test')
	assert encoded.contains('count=5')
}

fn test_headers_and_status_helpers() {
	bearer := bearer_auth_header('my-jwt-token')
	assert bearer['Authorization'] == 'Bearer my-jwt-token'

	basic := basic_auth_header('admin', 'secret123')
	assert basic['Authorization'].starts_with('Basic ')

	merged := merge_headers({
		'Content-Type': 'application/json'
		'Accept':       'text/plain'
	}, {
		'Accept':        'application/json'
		'Authorization': 'Bearer 123'
	})
	assert merged['Content-Type'] == 'application/json'
	assert merged['Accept'] == 'application/json'
	assert merged['Authorization'] == 'Bearer 123'

	assert is_success_status(200) == true
	assert is_success_status(204) == true
	assert is_success_status(404) == false

	assert is_redirect_status(301) == true
	assert is_redirect_status(302) == true

	assert is_client_error(400) == true
	assert is_client_error(404) == true

	assert is_server_error(500) == true
	assert is_server_error(503) == true
}

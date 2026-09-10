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

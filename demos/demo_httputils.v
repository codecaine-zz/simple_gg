module main

import httputils

struct ApiResponse {
	status string
	count  int
}

fn main() {
	println('==================================================')
	println('                demo_httputils                    ')
	println('==================================================')

	// 1. Query String Builder
	params := {
		'search': 'v language rapid development'
		'page':   '1'
		'limit':  '50'
		'format': 'json'
	}
	qs := httputils.build_query_string(params)
	println('Built Query String:\n  ${qs}')
	assert qs.contains('page=1')
	assert qs.contains('limit=50')
	assert qs.contains('format=json')

	// 2. Query String Parser
	parsed := httputils.parse_query_string(qs)
	println('\nParsed Query String:')
	for k, v in parsed {
		println('  ${k} -> "${v}"')
	}
	assert parsed['page'] == '1'
	assert parsed['search'] == 'v language rapid development'

	// 3. Leading Question Mark Handling
	with_q := httputils.parse_query_string('?sort=desc&filter=active')
	println('\nParsed with leading "?":')
	println('  sort=${with_q['sort']}, filter=${with_q['filter']}')
	assert with_q['sort'] == 'desc'
	assert with_q['filter'] == 'active'

	println('\n✔ httputils demo completed successfully!')
}

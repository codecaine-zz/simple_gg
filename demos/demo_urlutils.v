module main

import urlutils

fn main() {
	println('=== urlutils Demo ===')

	raw_url := 'https://service_user:super_secret_token@api.service.io:8080/v2/items/query?format=json&limit=50#section_results'
	u := urlutils.parse_url(raw_url) or { panic(err) }

	println('Scheme:   ${u.scheme}')
	println('Host:     ${u.host_with_port()}')
	println('User:     ${u.username}')
	println('Segments: ${u.path_segments()}')
	println('Query:    ${u.query}')

	// Path joining
	joined := urlutils.join_path('https://example.com/api', 'v1', 'resources/123')
	println('Joined Path: ${joined}')
	assert joined == 'https://example.com/api/v1/resources/123'

	// Redact credentials
	redacted := urlutils.redact_credentials(raw_url)
	println('Redacted URL: ${redacted}')
	assert !redacted.contains('super_secret_token')
	assert redacted.contains('***')

	println('urlutils demo completed successfully!')
}

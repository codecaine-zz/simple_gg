module httputils

import time

fn test_parse_retry_after() {
	assert parse_retry_after('120')? == 120 * time.second
	assert parse_retry_after(' 0 ')? == time.Duration(0)
	assert parse_retry_after('-5') == none
	assert parse_retry_after('') == none
	assert parse_retry_after('garbage') == none
	// A date in the past means "retry now".
	assert parse_retry_after('Wed, 21 Oct 2015 07:28:00 GMT')? == time.Duration(0)
}

fn test_backoff_delay() {
	cfg := RetryConfig{
		initial_delay_ms: 100
		backoff_factor:   2.0
		max_delay_ms:     1000
	}
	assert backoff_delay(1, cfg) == 100 * time.millisecond
	assert backoff_delay(3, cfg) == 400 * time.millisecond
	assert backoff_delay(50, cfg) == 1000 * time.millisecond
	jit := RetryConfig{
		...cfg
		jitter: true
	}
	for _ in 0 .. 20 {
		d := backoff_delay(3, jit)
		assert d >= 0 && d <= 400 * time.millisecond
	}
	assert is_retryable_status(503, cfg)
	assert is_retryable_status(429, cfg)
	assert !is_retryable_status(429, RetryConfig{ retry_on_429: false })
	assert !is_retryable_status(404, cfg)
}

fn test_header_helpers() {
	assert status_text(404) == 'Not Found'
	assert status_text(200) == 'OK'
	assert status_text(799) == 'Unknown'
	assert encode_form({
		'b': '2 3'
		'a': 'x&y'
	}) == 'a=x%26y&b=2+3'
	links :=
		parse_link_header('<https://api.x/r?page=2>; rel="next", <https://api.x/r?page=9>; rel="last"')
	assert links['next'] == 'https://api.x/r?page=2'
	assert links['last'] == 'https://api.x/r?page=9'
	media, params := parse_content_type('Text/HTML; charset="UTF-8"')
	assert media == 'text/html'
	assert params['charset'] == 'UTF-8'
	assert join_url('https://api.x/', '/v1/users') == 'https://api.x/v1/users'
	assert join_url('https://api.x', 'https://other/y') == 'https://other/y'
	assert join_url('', 'rel') == 'rel'
}

fn test_client_construction() {
	c := new_client(base_url: 'https://api.example.com', timeout: 5 * time.second)
	assert c.config.base_url == 'https://api.example.com'
	assert c.config.retry.max_retries == 1
	r := HttpResponse{
		status_code: 404
		headers:     {
			'content-type': 'application/json'
		}
		body:        '{}'
	}
	assert !r.ok()
	assert r.header('Content-Type') == 'application/json'
	if _ := r.raise_for_status() {
		assert false
	} else {
		assert err.msg().contains('404 Not Found')
	}
}

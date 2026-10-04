module httputils

import net.http
import time
import json2

// ClientConfig configures a reusable HTTP client.
@[params]
pub struct ClientConfig {
pub:
	base_url   string
	headers    map[string]string
	timeout    time.Duration = 30 * time.second
	retry      RetryConfig   = RetryConfig{
		max_retries: 1
	}
	user_agent string = 'vlang_utils-httputils/2.0'
}

// Client is a reusable HTTP client with a base URL, default headers, timeouts and retry policy.
pub struct Client {
pub:
	config ClientConfig
}

// HttpResponse is a simplified response with lower-cased header names and timing information.
pub struct HttpResponse {
pub:
	status_code int
	headers     map[string]string
	body        string
	elapsed     time.Duration
}

// new_client creates a Client, e.g. `httputils.new_client(base_url: 'https://api.example.com')`.
pub fn new_client(config ClientConfig) Client {
	return Client{
		config: config
	}
}

// ok reports whether the response status is 2xx.
pub fn (r HttpResponse) ok() bool {
	return is_success_status(r.status_code)
}

// header returns a response header value (case-insensitive), or '' if absent.
pub fn (r HttpResponse) header(name string) string {
	return r.headers[name.to_lower()] or { '' }
}

// json decodes the response body into T.
pub fn (r HttpResponse) json[T]() !T {
	return json2.decode[T](r.body)
}

// raise_for_status returns an error for 4xx/5xx responses (like Python requests' raise_for_status).
pub fn (r HttpResponse) raise_for_status() ! {
	if r.status_code >= 400 {
		return error('HTTP ${r.status_code} ${status_text(r.status_code)}: ${truncate_body(r.body)}')
	}
}

// request sends a request with any method. Network errors and retryable statuses follow the retry policy.
pub fn (c Client) request(method http.Method, path string, body string, headers map[string]string) !HttpResponse {
	mut req := http.new_request(method, join_url(c.config.base_url, path), body)
	req.user_agent = c.config.user_agent
	req.read_timeout = i64(c.config.timeout)
	req.write_timeout = i64(c.config.timeout)
	for k, v in merge_headers(c.config.headers, headers) {
		req.add_custom_header(k, v)!
	}
	sw := time.new_stopwatch()
	res := fetch_with_retry(mut req, c.config.retry)!
	mut hdrs := map[string]string{}
	for k in res.header.keys() {
		hdrs[k.to_lower()] = res.header.get_custom(k) or { '' }
	}
	return HttpResponse{
		status_code: res.status_code
		headers:     hdrs
		body:        res.body
		elapsed:     sw.elapsed()
	}
}

// get sends a GET request.
pub fn (c Client) get(path string) !HttpResponse {
	return c.request(.get, path, '', map[string]string{})
}

// delete sends a DELETE request.
pub fn (c Client) delete(path string) !HttpResponse {
	return c.request(.delete, path, '', map[string]string{})
}

// post sends a POST request with a raw body and content type.
pub fn (c Client) post(path string, body string, content_type string) !HttpResponse {
	return c.request(.post, path, body, {
		'Content-Type': content_type
	})
}

// put sends a PUT request with a raw body and content type.
pub fn (c Client) put(path string, body string, content_type string) !HttpResponse {
	return c.request(.put, path, body, {
		'Content-Type': content_type
	})
}

// patch sends a PATCH request with a raw body and content type.
pub fn (c Client) patch(path string, body string, content_type string) !HttpResponse {
	return c.request(.patch, path, body, {
		'Content-Type': content_type
	})
}

// post_form sends a URL-encoded form.
pub fn (c Client) post_form(path string, fields map[string]string) !HttpResponse {
	return c.post(path, encode_form(fields), 'application/x-www-form-urlencoded')
}

// get_json sends GET and decodes a successful JSON response into T.
pub fn (c Client) get_json[T](path string) !T {
	res := c.request(.get, path, '', {
		'Accept': 'application/json'
	})!
	res.raise_for_status()!
	return res.json[T]()
}

// send_json sends `body` encoded as JSON with the given method and decodes a successful response into R.
pub fn (c Client) send_json[T, R](method http.Method, path string, body T) !R {
	res := c.request(method, path, json2.encode(body), {
		'Content-Type': 'application/json'
		'Accept':       'application/json'
	})!
	res.raise_for_status()!
	return res.json[R]()
}

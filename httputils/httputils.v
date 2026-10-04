module httputils

import net.http
import net.urllib
import os
import time
import json2
import encoding.base64
import rand

// build_query_string converts a map of parameters into an encoded query string (e.g. "key=val&a=b").
pub fn build_query_string(params map[string]string) string {
	if params.len == 0 {
		return ''
	}
	mut parts := []string{cap: params.len}
	for k, v in params {
		parts << '${urllib.query_escape(k)}=${urllib.query_escape(v)}'
	}
	return parts.join('&')
}

// parse_query_string parses a URL query string (with or without leading '?') into key-value pairs.
pub fn parse_query_string(query string) map[string]string {
	mut res := map[string]string{}
	clean := if query.starts_with('?') { query[1..] } else { query }
	if clean.len == 0 {
		return res
	}
	pairs := clean.split('&')
	for pair in pairs {
		if pair.len == 0 {
			continue
		}
		eq_idx := pair.index('=') or {
			k := urllib.query_unescape(pair) or { pair }
			res[k] = ''
			continue
		}
		k := urllib.query_unescape(pair[..eq_idx]) or { pair[..eq_idx] }
		v := urllib.query_unescape(pair[eq_idx + 1..]) or { pair[eq_idx + 1..] }
		res[k] = v
	}
	return res
}

// get_text sends an HTTP GET request and returns the response body as a string.
pub fn get_text(url string, headers map[string]string) !string {
	mut req := http.new_request(.get, url, '')
	for k, v in headers {
		req.add_custom_header(k, v) or { return err }
	}
	res := req.do() or { return err }
	if res.status_code >= 400 {
		return error('HTTP GET ${url} returned status ${res.status_code}: ${truncate_body(res.body)}')
	}
	return res.body
}

// truncate_body keeps error messages readable when servers return large error pages.
fn truncate_body(body string) string {
	return if body.len > 512 { body[..512] + '... (${body.len} bytes)' } else { body }
}

// post_text sends an HTTP POST request with a text body and returns the response body.
pub fn post_text(url string, body string, headers map[string]string) !string {
	mut req := http.new_request(.post, url, body)
	for k, v in headers {
		req.add_custom_header(k, v) or { return err }
	}
	res := req.do() or { return err }
	if res.status_code >= 400 {
		return error('HTTP POST ${url} returned status ${res.status_code}: ${truncate_body(res.body)}')
	}
	return res.body
}

// get_json sends an HTTP GET request, verifies success, and decodes the JSON response into T.
pub fn get_json[T](url string, headers map[string]string) !T {
	mut req_headers := headers.clone()
	if 'Accept' !in req_headers {
		req_headers['Accept'] = 'application/json'
	}
	body := get_text(url, req_headers) or { return err }
	return json2.decode[T](body)
}

// post_json sends an HTTP POST request with JSON encoded body, and decodes the JSON response into R.
pub fn post_json[T, R](url string, body T, headers map[string]string) !R {
	mut req_headers := headers.clone()
	if 'Content-Type' !in req_headers {
		req_headers['Content-Type'] = 'application/json'
	}
	if 'Accept' !in req_headers {
		req_headers['Accept'] = 'application/json'
	}
	encoded_body := json2.encode(body)
	res_body := post_text(url, encoded_body, req_headers) or { return err }
	return json2.decode[R](res_body)
}

// download_file downloads a remote file from url directly to dest_path on disk.
pub fn download_file(url string, dest_path string) ! {
	parent := os.dir(dest_path)
	if parent.len > 0 && !os.exists(parent) {
		os.mkdir_all(parent) or { return err }
	}
	http.download_file(url, dest_path) or { return err }
}

// RetryConfig defines parameters for executing HTTP requests with exponential backoff retry.
pub struct RetryConfig {
pub:
	max_retries      int = 3
	initial_delay_ms int = 200
	backoff_factor   f64 = 2.0
	max_delay_ms     int = 30_000 // upper bound for any single wait
	jitter           bool // "full jitter" (AWS architecture blog): sleep a random 0..delay to avoid thundering herds
	retry_on_429     bool = true // retry "Too Many Requests", honoring Retry-After
}

// backoff_delay returns the wait before retry number `attempt` (1-based), capped at max_delay_ms.
pub fn backoff_delay(attempt int, config RetryConfig) time.Duration {
	mut delay := f64(config.initial_delay_ms)
	for _ in 1 .. attempt {
		delay *= config.backoff_factor
		if delay >= f64(config.max_delay_ms) {
			break
		}
	}
	if config.max_delay_ms > 0 && delay > f64(config.max_delay_ms) {
		delay = f64(config.max_delay_ms)
	}
	mut ms := i64(delay)
	if config.jitter && ms > 0 {
		ms = rand.i64n(ms + 1) or { ms }
	}
	return time.Duration(ms * time.millisecond)
}

// is_retryable_status reports whether a response status is worth retrying (5xx, and 429 when enabled).
pub fn is_retryable_status(status_code int, config RetryConfig) bool {
	return status_code >= 500 || (config.retry_on_429 && status_code == 429)
}

// fetch_with_retry attempts an HTTP request with exponential backoff on network failures, 5xx and 429 errors.
// A server-provided Retry-After header takes precedence over the computed backoff (still capped by max_delay_ms).
pub fn fetch_with_retry(mut req http.Request, config RetryConfig) !http.Response {
	mut attempts := 0
	for {
		attempts++
		res := req.do() or {
			if attempts >= config.max_retries {
				return err
			}
			time.sleep(backoff_delay(attempts, config))
			continue
		}
		if is_retryable_status(res.status_code, config) && attempts < config.max_retries {
			mut wait := backoff_delay(attempts, config)
			if ra := res.header.get_custom('Retry-After') {
				if d := parse_retry_after(ra) {
					cap := time.Duration(i64(config.max_delay_ms) * time.millisecond)
					wait = if config.max_delay_ms > 0 && d > cap { cap } else { d }
				}
			}
			time.sleep(wait)
			continue
		}
		return res
	}
	return error('request failed after retries')
}

// bearer_auth_header creates an Authorization header map containing a Bearer token.
pub fn bearer_auth_header(token string) map[string]string {
	return {
		'Authorization': 'Bearer ${token}'
	}
}

// basic_auth_header creates an Authorization header map with Basic username/password authentication.
pub fn basic_auth_header(username string, password string) map[string]string {
	encoded := base64.encode_str('${username}:${password}')
	return {
		'Authorization': 'Basic ${encoded}'
	}
}

// merge_headers merges multiple header maps into a single map, with later headers overriding earlier ones.
pub fn merge_headers(header_maps ...map[string]string) map[string]string {
	mut res := map[string]string{}
	for h in header_maps {
		for k, v in h {
			res[k] = v
		}
	}
	return res
}

// is_success_status returns true if status_code is in the 2xx range.
pub fn is_success_status(status_code int) bool {
	return status_code >= 200 && status_code < 300
}

// is_redirect_status returns true if status_code is in the 3xx range.
pub fn is_redirect_status(status_code int) bool {
	return status_code >= 300 && status_code < 400
}

// is_client_error returns true if status_code is in the 4xx range.
pub fn is_client_error(status_code int) bool {
	return status_code >= 400 && status_code < 500
}

// is_server_error returns true if status_code is in the 5xx range.
pub fn is_server_error(status_code int) bool {
	return status_code >= 500 && status_code < 600
}

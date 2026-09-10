module httputils

import net.http
import net.urllib
import os
import time
import json2

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
		return error('HTTP GET ${url} returned status ${res.status_code}: ${res.body}')
	}
	return res.body
}

// post_text sends an HTTP POST request with a text body and returns the response body.
pub fn post_text(url string, body string, headers map[string]string) !string {
	mut req := http.new_request(.post, url, body)
	for k, v in headers {
		req.add_custom_header(k, v) or { return err }
	}
	res := req.do() or { return err }
	if res.status_code >= 400 {
		return error('HTTP POST ${url} returned status ${res.status_code}: ${res.body}')
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
}

// fetch_with_retry attempts an HTTP request with exponential backoff on network failures or 5xx errors.
pub fn fetch_with_retry(mut req http.Request, config RetryConfig) !http.Response {
	mut attempts := 0
	mut delay := config.initial_delay_ms
	for {
		attempts++
		res := req.do() or {
			if attempts >= config.max_retries {
				return err
			}
			time.sleep(time.Duration(delay * int(time.millisecond)))
			delay = int(f64(delay) * config.backoff_factor)
			continue
		}
		if res.status_code >= 500 && attempts < config.max_retries {
			time.sleep(time.Duration(delay * int(time.millisecond)))
			delay = int(f64(delay) * config.backoff_factor)
			continue
		}
		return res
	}
	return error('request failed after retries')
}

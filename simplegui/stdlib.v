// Module simplegui - Core UI Framework for V
// File: stdlib.v
//
// Description:
//   This file provides beginner-friendly, high-level wrapper utilities around V's Core Standard Library.
//   It simplifies complex lower-level operations (such as HTTP requests, JSON parsing, Gzip compression,
//   AES encryption, Base64/Hex encoding, Regex matching, WebSockets, and Math statistics) so developers
//   can call simple functions on `SimpleWindow` or via the `simplegui` package namespace.

module simplegui

import os
import net.http
import regex
import compress.gzip
import crypto.sha256
import crypto.md5
import crypto.aes
import crypto.cipher
import rand
import time
import net.urllib
import net.websocket
import toml
import semver
import json2
import encoding.hex
import encoding.base64
import crypto.sha512
import crypto.sha1
import crypto.bcrypt
import crypto.hmac
import compress.zlib
import term
import datatypes
import clipboard
import benchmark
import net
import net.unix
import compress.deflate
import compress.zstd
import net.html
import strings.lorem
import math
import math.big
import math.stats
import arrays
import strings
import encoding.utf8
import encoding.csv
import crypto.ed25519
import crypto.pbkdf2
import sync
import math.complex
import crypto.rand as crand
import hash as vhash

// =============================================================================
// 1. HTTP Client Utilities (net.http)
// =============================================================================

// http_get sends a synchronous GET request and returns the response body, or empty on failure.
pub fn http_get(url string) string {
	res := http.get(url) or { return '' }
	return res.body
}

// http_get delegates to the standalone http_get.
pub fn (win &SimpleWindow) http_get(url string) string {
	if win.debug_mode {
		println('[simplegui STDLIB] Fetching url: ${url}')
	}
	return http_get(url)
}

// http_post sends a synchronous POST request with the specified body, returning the response, or empty on failure.
pub fn http_post(url string, data string) string {
	res := http.post(url, data) or { return '' }
	return res.body
}

// http_post delegates to the standalone http_post.
pub fn (win &SimpleWindow) http_post(url string, data string) string {
	if win.debug_mode {
		println('[simplegui STDLIB] Posting to url: ${url}')
	}
	return http_post(url, data)
}

// SimpleHttpResponse provides structured HTTP response metadata for production use.
pub struct SimpleHttpResponse {
pub:
	status_code int
	body        string
	raw_headers string
	url         string
}

// SimpleHttpRequestOptions controls strict request behavior for production API calls.
pub struct SimpleHttpRequestOptions {
pub:
	headers        map[string]string
	user_agent     string
	retries        int
	retry_delay_ms int
	expect_success bool
}

fn build_simple_http_response(url string, res http.Response) SimpleHttpResponse {
	return SimpleHttpResponse{
		status_code: int(res.status_code)
		body:        res.body
		raw_headers: res.header.str()
		url:         url
	}
}

fn http_request_once(method http.Method, url string, data string, headers map[string]string, user_agent string, expect_success bool) !SimpleHttpResponse {
	if url.trim_space().len == 0 {
		return error('url cannot be empty')
	}
	mut req := http.Request{
		url:    url
		method: method
		data:   data
	}
	if user_agent.len > 0 {
		req.header.set(http.CommonHeader.user_agent, user_agent)
	}
	for k, v in headers {
		req.header.add_custom(k, v) or {}
	}
	res := req.do()!
	response := build_simple_http_response(url, res)
	if expect_success && (response.status_code < 200 || response.status_code >= 300) {
		return error('http status ${response.status_code}')
	}
	return response
}

// http_request executes a configurable HTTP request with optional retries and strict status checks.
pub fn http_request(method http.Method, url string, data string, options SimpleHttpRequestOptions) !SimpleHttpResponse {
	attempts := if options.retries > 0 { options.retries + 1 } else { 1 }
	mut last_err := 'request failed'
	for attempt in 0 .. attempts {
		res := http_request_once(method, url, data, options.headers, options.user_agent,
			options.expect_success) or {
			last_err = err.msg()
			if attempt < attempts - 1 && options.retry_delay_ms > 0 {
				time.sleep(options.retry_delay_ms * time.millisecond)
			}
			continue
		}
		return res
	}
	return error(last_err)
}

// http_get_strict sends a GET request and returns the response body or an explicit error.
pub fn http_get_strict(url string) !string {
	res := http_request(.get, url, '', SimpleHttpRequestOptions{})!
	return res.body
}

// http_get_strict delegates to standalone http_get_strict.
pub fn (win &SimpleWindow) http_get_strict(url string) !string {
	return http_get_strict(url)!
}

// http_post_strict sends a POST request and returns the response body or an explicit error.
pub fn http_post_strict(url string, data string) !string {
	res := http_request(.post, url, data, SimpleHttpRequestOptions{})!
	return res.body
}

// http_post_strict delegates to standalone http_post_strict.
pub fn (win &SimpleWindow) http_post_strict(url string, data string) !string {
	return http_post_strict(url, data)!
}

// ==========================================
// 2. Regular Expressions & Patterns (Chapter 13: regex)
// ==========================================

// regex_match checks if a target string contains matches for a regular expression pattern.
pub fn regex_match(text string, pattern string) bool {
	mut re := regex.regex_opt(pattern) or { return false }
	return re.matches_string(text)
}

// regex_match delegates to standalone regex_match.
pub fn (win &SimpleWindow) regex_match(text string, pattern string) bool {
	return regex_match(text, pattern)
}

// regex_find extracts all substrings matching a regular expression pattern.
pub fn regex_find(text string, pattern string) []string {
	mut re := regex.regex_opt(pattern) or { return []string{} }
	matches := re.find_all_str(text)
	return matches
}

// regex_find delegates to standalone regex_find.
pub fn (win &SimpleWindow) regex_find(text string, pattern string) []string {
	return regex_find(text, pattern)
}

// regex_replace replaces any pattern matches inside a string with a replacement text.
pub fn regex_replace(text string, pattern string, replacement string) string {
	mut re := regex.regex_opt(pattern) or { return text }
	return re.replace(text, replacement)
}

// regex_replace delegates to standalone regex_replace.
pub fn (win &SimpleWindow) regex_replace(text string, pattern string, replacement string) string {
	return regex_replace(text, pattern, replacement)
}

// regex_match_strict validates the regex pattern and returns an explicit error for invalid syntax.
pub fn regex_match_strict(text string, pattern string) !bool {
	mut re := regex.regex_opt(pattern)!
	return re.matches_string(text)
}

// regex_match_strict delegates to standalone regex_match_strict.
pub fn (win &SimpleWindow) regex_match_strict(text string, pattern string) !bool {
	return regex_match_strict(text, pattern)!
}

// regex_find_strict validates the regex pattern and returns explicit errors when invalid.
pub fn regex_find_strict(text string, pattern string) ![]string {
	mut re := regex.regex_opt(pattern)!
	return re.find_all_str(text)
}

// regex_find_strict delegates to standalone regex_find_strict.
pub fn (win &SimpleWindow) regex_find_strict(text string, pattern string) ![]string {
	return regex_find_strict(text, pattern)!
}

// regex_replace_strict validates the regex pattern and returns explicit errors when invalid.
pub fn regex_replace_strict(text string, pattern string, replacement string) !string {
	mut re := regex.regex_opt(pattern)!
	return re.replace(text, replacement)
}

// regex_replace_strict delegates to standalone regex_replace_strict.
pub fn (win &SimpleWindow) regex_replace_strict(text string, pattern string, replacement string) !string {
	return regex_replace_strict(text, pattern, replacement)!
}

// ==========================================
// 3. Cryptography & Hash Functions (Chapter 13: crypto)
// ==========================================

// crypto_sha256 computes the hex-encoded SHA-256 hash of a string.
pub fn crypto_sha256(text string) string {
	return sha256.hexhash(text)
}

// crypto_sha256 delegates to standalone crypto_sha256.
pub fn (win &SimpleWindow) crypto_sha256(text string) string {
	return crypto_sha256(text)
}

// crypto_md5 computes the hex-encoded MD5 hash of a parameter string.
pub fn crypto_md5(text string) string {
	return md5.hexhash(text)
}

// crypto_md5 delegates to standalone crypto_md5.
pub fn (win &SimpleWindow) crypto_md5(text string) string {
	return crypto_md5(text)
}

// crypto_encrypt_aes encrypts text using 128-bit AES block cipher under CBC mode, returning hex-encoded ciphertext.
// Automatically handles standard block padding and initializes static secure IV arrays.
pub fn crypto_encrypt_aes(plain_text string, key_hex string) string {
	decoded_key := hex.decode(key_hex) or { []u8{} }
	mut key := decoded_key.clone()
	// AES key must be exactly 16 bytes for AES-128
	if key.len != 16 && key.len != 24 && key.len != 32 {
		if key.len < 16 {
			for key.len < 16 {
				key << u8(0)
			}
		} else {
			key = key[..16].clone()
		}
	}

	// Deterministic IV to keep decryption simple
	iv := [u8(9), 8, 7, 6, 5, 4, 3, 2, 1, 0, 9, 8, 7, 6, 5, 4]

	block := aes.new_cipher(key)
	mut enc := cipher.new_cbc(block, iv)

	plaintext := plain_text.bytes()
	mut padded := plaintext.clone()
	pad_len := 16 - (padded.len % 16)
	for _ in 0 .. pad_len {
		padded << u8(pad_len)
	}

	mut ciphertext := []u8{len: padded.len}
	enc.encrypt_blocks(mut ciphertext, padded)
	return hex.encode(ciphertext)
}

// crypto_encrypt_aes delegates to standalone crypto_encrypt_aes.
pub fn (win &SimpleWindow) crypto_encrypt_aes(plain_text string, key_hex string) string {
	return crypto_encrypt_aes(plain_text, key_hex)
}

// crypto_decrypt_aes decrypts a hex-encoded AES CBC block string, returning the unpadded plaintext string.
pub fn crypto_decrypt_aes(cipher_hex string, key_hex string) string {
	decoded_key := hex.decode(key_hex) or { []u8{} }
	mut key := decoded_key.clone()
	if key.len != 16 && key.len != 24 && key.len != 32 {
		if key.len < 16 {
			for key.len < 16 {
				key << u8(0)
			}
		} else {
			key = key[..16].clone()
		}
	}

	iv := [u8(9), 8, 7, 6, 5, 4, 3, 2, 1, 0, 9, 8, 7, 6, 5, 4]
	ciphertext := hex.decode(cipher_hex) or { return '' }
	if ciphertext.len % 16 != 0 || ciphertext.len == 0 {
		return ''
	}

	block := aes.new_cipher(key)
	mut dec := cipher.new_cbc(block, iv)
	mut decrypted := []u8{len: ciphertext.len}
	dec.decrypt_blocks(mut decrypted, ciphertext)

	if decrypted.len == 0 {
		return ''
	}
	unpadded_len := decrypted.len - int(decrypted.last())
	if unpadded_len < 0 || unpadded_len > decrypted.len {
		return decrypted.bytestr()
	}
	return decrypted[..unpadded_len].bytestr()
}

// crypto_decrypt_aes delegates to standalone crypto_decrypt_aes.
pub fn (win &SimpleWindow) crypto_decrypt_aes(cipher_hex string, key_hex string) string {
	return crypto_decrypt_aes(cipher_hex, key_hex)
}

fn aes_key_from_hex_strict(key_hex string) ![]u8 {
	key := hex.decode(key_hex)!
	if key.len != 16 && key.len != 24 && key.len != 32 {
		return error('key must be 16, 24, or 32 bytes after hex decoding')
	}
	return key
}

fn pkcs7_pad(data []u8, block_size int) []u8 {
	mut out := data.clone()
	pad_len := block_size - (out.len % block_size)
	for _ in 0 .. pad_len {
		out << u8(pad_len)
	}
	return out
}

fn pkcs7_unpad(data []u8, block_size int) ![]u8 {
	if data.len == 0 || data.len % block_size != 0 {
		return error('invalid padded payload length')
	}
	pad_len := int(data[data.len - 1])
	if pad_len <= 0 || pad_len > block_size || pad_len > data.len {
		return error('invalid PKCS7 padding')
	}
	for i in data.len - pad_len .. data.len {
		if int(data[i]) != pad_len {
			return error('invalid PKCS7 padding bytes')
		}
	}
	return data[..data.len - pad_len].clone()
}

// crypto_encrypt_aes_secure encrypts using AES-CBC with random IV and returns hex(iv+ciphertext).
pub fn crypto_encrypt_aes_secure(plain_text string, key_hex string) !string {
	key := aes_key_from_hex_strict(key_hex)!
	iv := crand.bytes(16)!
	block := aes.new_cipher(key)
	mut enc := cipher.new_cbc(block, iv)
	padded := pkcs7_pad(plain_text.bytes(), 16)
	mut ciphertext := []u8{len: padded.len}
	enc.encrypt_blocks(mut ciphertext, padded)
	mut payload := []u8{}
	payload << iv
	payload << ciphertext
	return hex.encode(payload)
}

// crypto_encrypt_aes_secure delegates to standalone crypto_encrypt_aes_secure.
pub fn (win &SimpleWindow) crypto_encrypt_aes_secure(plain_text string, key_hex string) !string {
	return crypto_encrypt_aes_secure(plain_text, key_hex)!
}

// crypto_decrypt_aes_secure decrypts hex(iv+ciphertext) payloads produced by crypto_encrypt_aes_secure.
pub fn crypto_decrypt_aes_secure(payload_hex string, key_hex string) !string {
	key := aes_key_from_hex_strict(key_hex)!
	payload := hex.decode(payload_hex)!
	if payload.len < 32 || payload.len % 16 != 0 {
		return error('payload must include 16-byte IV plus aligned ciphertext')
	}
	iv := payload[..16].clone()
	ciphertext := payload[16..]
	block := aes.new_cipher(key)
	mut dec := cipher.new_cbc(block, iv)
	mut decrypted := []u8{len: ciphertext.len}
	dec.decrypt_blocks(mut decrypted, ciphertext)
	plain := pkcs7_unpad(decrypted, 16)!
	return plain.bytestr()
}

// crypto_decrypt_aes_secure delegates to standalone crypto_decrypt_aes_secure.
pub fn (win &SimpleWindow) crypto_decrypt_aes_secure(payload_hex string, key_hex string) !string {
	return crypto_decrypt_aes_secure(payload_hex, key_hex)!
}

// ==========================================
// 4. Gzip Compression (Chapter 13: compress.gzip)
// ==========================================

// compress_gzip compresses flat plaintext string using gzip compression format.
pub fn compress_gzip(text string) []u8 {
	compressed := gzip.compress(text.bytes()) or { return []u8{} }
	return compressed
}

// compress_gzip delegates to standalone compress_gzip.
pub fn (win &SimpleWindow) compress_gzip(text string) []u8 {
	return compress_gzip(text)
}

// decompress_gzip extracts standard gzip compressed binary bytes back into a human-readable string.
pub fn decompress_gzip(data []u8) string {
	decompressed := gzip.decompress(data) or { return '' }
	return decompressed.bytestr()
}

// decompress_gzip delegates to standalone decompress_gzip.
pub fn (win &SimpleWindow) decompress_gzip(data []u8) string {
	return decompress_gzip(data)
}

// ==========================================
// 5. Random Number & Safe Strings Generator (Chapter 13: rand)
// ==========================================

// rand_int generates a secure random integer between min (inclusive) and max (exclusive).
pub fn rand_int(min int, max int) int {
	return rand.int_in_range(min, max) or { min }
}

// rand_int delegates to standalone rand_int.
pub fn (win &SimpleWindow) rand_int(min int, max int) int {
	return rand_int(min, max)
}

// rand_string produces a random alphanumeric string token of target length.
pub fn rand_string(length int) string {
	return rand.string(length)
}

// rand_string delegates to standalone rand_string.
pub fn (win &SimpleWindow) rand_string(length int) string {
	return rand_string(length)
}

// rand_shuffle_strings shuffles/randomizes the exact order of element items within a string array.
pub fn rand_shuffle_strings(mut arr []string) {
	mut indices := []int{}
	for i in 0 .. arr.len {
		indices << i
	}
	// Permute elements in place
	for i := arr.len - 1; i > 0; i-- {
		j := rand.intn(i + 1) or { 0 }
		temp := arr[i]
		arr[i] = arr[j]
		arr[j] = temp
	}
}

// rand_shuffle_strings delegates to standalone rand_shuffle_strings.
pub fn (win &SimpleWindow) rand_shuffle_strings(mut arr []string) &SimpleWindow {
	rand_shuffle_strings(mut arr)
	return win
}

// rand_choice_strings picks a single string item from an array at uniform random probability.
pub fn rand_choice_strings(items []string) string {
	if items.len == 0 {
		return ''
	}
	return rand.element(items) or { items[0] }
}

// rand_choice_strings delegates to standalone rand_choice_strings.
pub fn (win &SimpleWindow) rand_choice_strings(items []string) string {
	return rand_choice_strings(items)
}

// rand_choice_ints picks a single integer item from an array at uniform random probability.
pub fn rand_choice_ints(items []int) int {
	if items.len == 0 {
		return 0
	}
	return rand.element(items) or { items[0] }
}

// rand_choice_ints delegates to standalone rand_choice_ints.
pub fn (win &SimpleWindow) rand_choice_ints(items []int) int {
	return rand_choice_ints(items)
}

// rand_weighted_choice_strings picks a string item from an array according to relative weights.
pub fn rand_weighted_choice_strings(items []string, weights []f64) string {
	if items.len == 0 || items.len != weights.len {
		return ''
	}
	mut total_weight := 0.0
	for w in weights {
		if w > 0.0 {
			total_weight += w
		}
	}
	if total_weight <= 0.0 {
		return items[0]
	}
	r := rand.f64_in_range(0.0, total_weight) or { 0.0 }
	mut cumulative := 0.0
	for i in 0 .. items.len {
		w := if weights[i] > 0.0 { weights[i] } else { 0.0 }
		cumulative += w
		if r <= cumulative {
			return items[i]
		}
	}
	return items[items.len - 1]
}

// rand_weighted_choice_strings delegates to standalone rand_weighted_choice_strings.
pub fn (win &SimpleWindow) rand_weighted_choice_strings(items []string, weights []f64) string {
	return rand_weighted_choice_strings(items, weights)
}

// rand_weighted_choice_ints picks an integer item from an array according to relative weights.
pub fn rand_weighted_choice_ints(items []int, weights []f64) int {
	if items.len == 0 || items.len != weights.len {
		return 0
	}
	mut total_weight := 0.0
	for w in weights {
		if w > 0.0 {
			total_weight += w
		}
	}
	if total_weight <= 0.0 {
		return items[0]
	}
	r := rand.f64_in_range(0.0, total_weight) or { 0.0 }
	mut cumulative := 0.0
	for i in 0 .. items.len {
		w := if weights[i] > 0.0 { weights[i] } else { 0.0 }
		cumulative += w
		if r <= cumulative {
			return items[i]
		}
	}
	return items[items.len - 1]
}

// rand_weighted_choice_ints delegates to standalone rand_weighted_choice_ints.
pub fn (win &SimpleWindow) rand_weighted_choice_ints(items []int, weights []f64) int {
	return rand_weighted_choice_ints(items, weights)
}

// ==========================================
// 6. Time and Measurement (Chapter 13: time)
// ==========================================

// time_now returns formatted current timestamp in YYYY-MM-DD HH:MM:SS format.
pub fn time_now() string {
	t := time.now()
	return t.custom_format('YYYY-MM-DD HH:mm:ss')
}

// time_now delegates to standalone time_now.
pub fn (win &SimpleWindow) time_now() string {
	return time_now()
}

// time_elapsed formats a millisecond counter into a friendly custom duration (e.g. "1200ms" or "1.2s").
pub fn time_elapsed(ms int) string {
	if ms < 1000 {
		return '${ms}ms'
	}
	sec := f64(ms) / 1000.0
	return '${sec:.2f}s'
}

// time_elapsed delegates to standalone time_elapsed.
pub fn (win &SimpleWindow) time_elapsed(ms int) string {
	return time_elapsed(ms)
}

// ==========================================
// 7. URL Escaping & Query Packing (Chapter 13: net.urllib)
// ==========================================

// url_encode outputs a secure, percent-encoded string for URL query parameters.
pub fn url_encode(text string) string {
	return urllib.query_escape(text)
}

// url_encode delegates to standalone url_encode.
pub fn (win &SimpleWindow) url_encode(text string) string {
	return url_encode(text)
}

// url_decode translates a percent-encoded URL query string back to plain text.
pub fn url_decode(text string) string {
	res := urllib.query_unescape(text) or { return text }
	return res
}

// url_decode delegates to standalone url_decode.
pub fn (win &SimpleWindow) url_decode(text string) string {
	return url_decode(text)
}

// ==========================================
// 8. TOML Configuration Parser Wrapper (Chapter 13: toml)
// ==========================================
pub struct TOMLWrapperDoc {
mut:
	doc toml.Doc
}

// get_string extracts string value corresponding to a flat or dotted key path (e.g. "owner.name").
pub fn (t &TOMLWrapperDoc) get_string(key string) string {
	return t.doc.value(key).string()
}

// get_string_default extracts configuration option with an error-safe default choice.
pub fn (t &TOMLWrapperDoc) get_string_default(key string, def string) string {
	return t.doc.value(key).default_to(def).string()
}

// get_int parses setting option as integer.
pub fn (t &TOMLWrapperDoc) get_int(key string) int {
	return t.doc.value(key).int()
}

// get_bool parses config key path as boolean.
pub fn (t &TOMLWrapperDoc) get_bool(key string) bool {
	return t.doc.value(key).bool()
}

// toml_parse parses flat TOML text content, wrapping query details inside an easy helper.
pub fn toml_parse(content string) &TOMLWrapperDoc {
	res := toml.parse_text(content) or { return &TOMLWrapperDoc{
		doc: toml.Doc{}
	} }
	return &TOMLWrapperDoc{
		doc: res
	}
}

// toml_parse delegates to standalone toml_parse.
pub fn (win &SimpleWindow) toml_parse(content string) &TOMLWrapperDoc {
	return toml_parse(content)
}

// ==========================================
// 9. Semantic Versioning constraints (Chapter 13: semver)
// ==========================================

// semver_compare compares two version strings. Returns -1 if v1 < v2, 1 if v1 > v2, 0 if equal/unparseable.
pub fn semver_compare(v1 string, v2 string) int {
	sv1 := semver.from(v1) or { return 0 }
	sv2 := semver.from(v2) or { return 0 }
	if sv1 < sv2 {
		return -1
	}
	if sv1 > sv2 {
		return 1
	}
	return 0
}

// semver_compare delegates to standalone semver_compare.
pub fn (win &SimpleWindow) semver_compare(v1 string, v2 string) int {
	return semver_compare(v1, v2)
}

// semver_satisfies checks if a semantic version string complies with a semver range filter query (e.g. ">=1.0.0 <2.0.0").
pub fn semver_satisfies(v string, range_query string) bool {
	sv := semver.from(v) or { return false }
	return sv.satisfies(range_query)
}

// semver_satisfies delegates to standalone semver_satisfies.
pub fn (win &SimpleWindow) semver_satisfies(v string, range_query string) bool {
	return semver_satisfies(v, range_query)
}

// ==========================================
// 10. Direct Flat JSON Mapping Helper (Chapter 13: json)
// ==========================================

// json_decode_map cleanly deserializes a JSON string into a flat key-value map without mandatory struct setups.
pub fn json_decode_map(json_str string) map[string]string {
	res := json2.decode[map[string]string](json_str) or { return map[string]string{} }
	return res
}

// json_decode_map delegates to standalone json_decode_map.
pub fn (win &SimpleWindow) json_decode_map(json_str string) map[string]string {
	return json_decode_map(json_str)
}

// json_decode_map_strict decodes a JSON object and returns an explicit error for malformed payloads.
pub fn json_decode_map_strict(json_str string) !map[string]string {
	return json2.decode[map[string]string](json_str)!
}

// json_decode_map_strict delegates to standalone json_decode_map_strict.
pub fn (win &SimpleWindow) json_decode_map_strict(json_str string) !map[string]string {
	return json_decode_map_strict(json_str)!
}

// ==========================================
// 11. Custom Simple WebSocket Client (Chapter 13: net.websocket)
// ==========================================

pub type SimpleWSMessageCallback = fn (msg string)

pub struct SimpleWSClient {
pub mut:
	client        &websocket.Client       = unsafe { nil }
	on_message_cb SimpleWSMessageCallback = unsafe { nil }
}

// write_string sends a text payload to the active WebSocket server.
pub fn (mut ws SimpleWSClient) write_string(msg string) ! {
	if ws.client != unsafe { nil } {
		ws.client.write_string(msg)!
	}
}

// close cleanly disconnects from the remote WebSocket server.
pub fn (mut ws SimpleWSClient) close() {
	if ws.client != unsafe { nil } {
		ws.client.close(1000, 'normal close') or {}
	}
}

// websocket_client constructs and spawns a WebSocket client on a background routine.
pub fn websocket_client(url string, on_msg SimpleWSMessageCallback) ?&SimpleWSClient {
	mut client := websocket.new_client(url) or { return none }

	mut ws := &SimpleWSClient{
		client:        client
		on_message_cb: on_msg
	}

	client.on_message(fn [ws] (mut c websocket.Client, msg &websocket.Message) ! {
		if msg.opcode == .text_frame {
			payload := msg.payload.bytestr()
			if ws.on_message_cb != unsafe { nil } {
				ws.on_message_cb(payload)
			}
		}
	})

	client.connect() or { return none }
	spawn client.listen()
	return ws
}

// websocket_client delegates to standalone websocket_client.
pub fn (win &SimpleWindow) websocket_client(url string, on_msg SimpleWSMessageCallback) ?&SimpleWSClient {
	if win.debug_mode {
		println('[simplegui STDLIB] Spawning WebSocket connection to: ${url}')
	}
	return websocket_client(url, on_msg)
}

// ==========================================
// 12. More Cryptography and Password Security (Chapter 13: crypto)
// ==========================================

// crypto_sha512 computes the hex-encoded SHA-512 hash of a string.
pub fn crypto_sha512(text string) string {
	return sha512.hexhash(text)
}

// crypto_sha512 delegates to standalone crypto_sha512.
pub fn (win &SimpleWindow) crypto_sha512(text string) string {
	return crypto_sha512(text)
}

// crypto_sha1 computes the hex-encoded SHA-1 hash of a string.
pub fn crypto_sha1(text string) string {
	return sha1.hexhash(text)
}

// crypto_sha1 delegates to standalone crypto_sha1.
pub fn (win &SimpleWindow) crypto_sha1(text string) string {
	return crypto_sha1(text)
}

// crypto_bcrypt_hash generates a secure bcrypt password hash of a string.
pub fn crypto_bcrypt_hash(password string) !string {
	hash := bcrypt.generate_from_password(password.bytes(), bcrypt.default_cost)!
	return hash
}

// crypto_bcrypt_hash delegates to standalone crypto_bcrypt_hash.
pub fn (win &SimpleWindow) crypto_bcrypt_hash(password string) !string {
	return crypto_bcrypt_hash(password)
}

// crypto_bcrypt_verify verifies a password against a bcrypt hash.
pub fn crypto_bcrypt_verify(password string, hash string) bool {
	bcrypt.compare_hash_and_password(password.bytes(), hash.bytes()) or { return false }
	return true
}

// crypto_bcrypt_verify delegates to standalone crypto_bcrypt_verify.
pub fn (win &SimpleWindow) crypto_bcrypt_verify(password string, hash string) bool {
	return crypto_bcrypt_verify(password, hash)
}

// crypto_hmac_sha256 computes the hex-encoded HMAC-SHA256 signature of a string with a key.
pub fn crypto_hmac_sha256(text string, key string) string {
	sum := hmac.new(key.bytes(), text.bytes(), sha256.sum, sha256.block_size)
	return sum.hex()
}

// crypto_hmac_sha256 delegates to standalone crypto_hmac_sha256.
pub fn (win &SimpleWindow) crypto_hmac_sha256(text string, key string) string {
	return crypto_hmac_sha256(text, key)
}

// ==========================================
// 13. Zlib Compression (Chapter 13: compress.zlib)
// ==========================================

// compress_zlib compresses flat plaintext string using zlib compression format.
pub fn compress_zlib(text string) []u8 {
	compressed := zlib.compress(text.bytes()) or { return []u8{} }
	return compressed
}

// compress_zlib delegates to standalone compress_zlib.
pub fn (win &SimpleWindow) compress_zlib(text string) []u8 {
	return compress_zlib(text)
}

// decompress_zlib extracts standard zlib compressed binary bytes back into a human-readable string.
pub fn decompress_zlib(data []u8) string {
	decompressed := zlib.decompress(data) or { return '' }
	return decompressed.bytestr()
}

// decompress_zlib delegates to standalone decompress_zlib.
pub fn (win &SimpleWindow) decompress_zlib(data []u8) string {
	return decompress_zlib(data)
}

// ==========================================
// 14. JSON Map List Helpers (Chapter 13: json)
// ==========================================

// json_encode_map_list serializes an array of maps into a JSON string.
pub fn json_encode_map_list(m []map[string]string) string {
	return json2.encode(m)
}

// json_encode_map_list delegates to standalone json_encode_map_list.
pub fn (win &SimpleWindow) json_encode_map_list(m []map[string]string) string {
	return json_encode_map_list(m)
}

// json_decode_map_list deserializes a JSON string into an array of flat key-value maps.
pub fn json_decode_map_list(json_str string) []map[string]string {
	res := json2.decode[[]map[string]string](json_str) or { return []map[string]string{} }
	return res
}

// json_decode_map_list delegates to standalone json_decode_map_list.
pub fn (win &SimpleWindow) json_decode_map_list(json_str string) []map[string]string {
	return json_decode_map_list(json_str)
}

// ==========================================
// 15. Stopwatch Utility (Chapter 13: time)
// ==========================================

// SimpleStopwatch provides a high-level wrapper to measure high-precision elapsed execution time.
pub struct SimpleStopwatch {
pub mut:
	sw time.StopWatch = time.new_stopwatch()
}

// elapsed_ms returns the elapsed time in milliseconds.
pub fn (mut sw SimpleStopwatch) elapsed_ms() int {
	return int(sw.sw.elapsed().milliseconds())
}

// elapsed_sec returns the elapsed time in seconds.
pub fn (mut sw SimpleStopwatch) elapsed_sec() f64 {
	return sw.sw.elapsed().seconds()
}

// restart resets and restarts the stopwatch.
pub fn (mut sw SimpleStopwatch) restart() {
	sw.sw.restart()
}

// stop stops measuring elapsed time.
pub fn (mut sw SimpleStopwatch) stop() {
	sw.sw.stop()
}

// start_stopwatch constructs and starts a new high-precision stopwatch.
pub fn (win &SimpleWindow) start_stopwatch() &SimpleStopwatch {
	return &SimpleStopwatch{
		sw: time.new_stopwatch()
	}
}

// ==========================================
// 16. Terminal Text Styling (Chapter 13: term)
// ==========================================

// term_color styles terminal console text output (supports red, green, blue, yellow, bold, underline).
pub fn term_color(text string, style string) string {
	return match style.to_lower() {
		'red' { term.red(text) }
		'green' { term.green(text) }
		'blue' { term.blue(text) }
		'yellow' { term.yellow(text) }
		'bold' { term.bold(text) }
		'underline' { term.underline(text) }
		else { text }
	}
}

// term_color delegates to standalone term_color.
pub fn (win &SimpleWindow) term_color(text string, style string) string {
	return term_color(text, style)
}

// ==========================================
// 17. Standard Collections & Datatypes
// ==========================================

// SimpleStack provides a high-level, generic LIFO (Last In First Out) stack.
pub struct SimpleStack[T] {
mut:
	s datatypes.Stack[T]
}

// push pushes an item onto the top of the stack.
pub fn (mut ss SimpleStack[T]) push(item T) {
	ss.s.push(item)
}

// pop removes and returns the item on top of the stack, or errors if empty.
pub fn (mut ss SimpleStack[T]) pop() !T {
	return ss.s.pop()
}

// peek returns the top item of the stack without removing it, or errors if empty.
pub fn (ss &SimpleStack[T]) peek() !T {
	return ss.s.peek()
}

// len returns the number of elements currently stored in the stack.
pub fn (ss &SimpleStack[T]) len() int {
	return ss.s.len()
}

// is_empty returns true if the stack contains no elements.
pub fn (ss &SimpleStack[T]) is_empty() bool {
	return ss.s.is_empty()
}

// new_stack instantiates a new generic SimpleStack.
pub fn new_stack[T]() SimpleStack[T] {
	return SimpleStack[T]{}
}

// SimpleQueue provides a high-level, generic FIFO (First In First Out) queue.
pub struct SimpleQueue[T] {
mut:
	q datatypes.Queue[T]
}

// push enqueues an item at the back of the queue.
pub fn (mut sq SimpleQueue[T]) push(item T) {
	sq.q.push(item)
}

// pop dequeues and returns the item at the front of the queue, or errors if empty.
pub fn (mut sq SimpleQueue[T]) pop() !T {
	return sq.q.pop()
}

// peek returns the front item of the queue without removing it, or errors if empty.
pub fn (sq &SimpleQueue[T]) peek() !T {
	return sq.q.peek()
}

// len returns the number of elements currently stored in the queue.
pub fn (sq &SimpleQueue[T]) len() int {
	return sq.q.len()
}

// is_empty returns true if the queue contains no elements.
pub fn (sq &SimpleQueue[T]) is_empty() bool {
	return sq.q.is_empty()
}

// new_queue instantiates a new generic SimpleQueue.
pub fn new_queue[T]() SimpleQueue[T] {
	return SimpleQueue[T]{}
}

// SimpleSet provides a high-level, generic unique set collection.
pub struct SimpleSet[T] {
mut:
	set datatypes.Set[T]
}

// add inserts an item into the set.
pub fn (mut ss SimpleSet[T]) add(item T) {
	ss.set.add(item)
}

// remove removes an item from the set.
pub fn (mut ss SimpleSet[T]) remove(item T) {
	ss.set.remove(item)
}

// exists returns true if the item is present in the set.
pub fn (ss &SimpleSet[T]) exists(item T) bool {
	return ss.set.exists(item)
}

// len returns the total count of elements in the set.
pub fn (ss &SimpleSet[T]) len() int {
	return ss.set.size()
}

// is_empty returns true if the set contains no elements.
pub fn (ss &SimpleSet[T]) is_empty() bool {
	return ss.set.is_empty()
}

// to_array returns all items in the set as an array.
pub fn (ss &SimpleSet[T]) to_array() []T {
	return ss.set.array()
}

// new_set instantiates a new generic SimpleSet.
pub fn new_set[T]() SimpleSet[T] {
	return SimpleSet[T]{}
}

// SimpleRingBuffer provides a high-level, generic ring buffer.
pub struct SimpleRingBuffer[T] {
mut:
	rb datatypes.RingBuffer[T]
}

// push adds an item into the ring buffer, returning an error if full.
pub fn (mut srb SimpleRingBuffer[T]) push(item T) ! {
	srb.rb.push(item)!
}

// pop removes and returns the oldest item from the ring buffer, returning an error if empty.
pub fn (mut srb SimpleRingBuffer[T]) pop() !T {
	return srb.rb.pop()
}

// len returns the number of occupied elements in the ring buffer.
pub fn (srb &SimpleRingBuffer[T]) len() int {
	return srb.rb.occupied()
}

// capacity returns the maximum total capacity of the ring buffer.
pub fn (srb &SimpleRingBuffer[T]) capacity() int {
	return srb.rb.capacity()
}

// is_empty returns true if the ring buffer contains no elements.
pub fn (srb &SimpleRingBuffer[T]) is_empty() bool {
	return srb.rb.is_empty()
}

// is_full returns true if the ring buffer has reached its capacity.
pub fn (srb &SimpleRingBuffer[T]) is_full() bool {
	return srb.rb.is_full()
}

// new_ringbuffer instantiates a new generic SimpleRingBuffer with a specific capacity.
pub fn new_ringbuffer[T](capacity int) SimpleRingBuffer[T] {
	return SimpleRingBuffer[T]{
		rb: datatypes.new_ringbuffer[T](capacity)
	}
}

// ==========================================
// 18. System Clipboard Helper (Chapter 13: clipboard)
// ==========================================

// clipboard_copy copies text to the system clipboard across macOS, Linux (Wayland/X11), and Windows.
pub fn clipboard_copy(text string) bool {
	$if macos {
		pbcopy_path := os.find_abs_path_of_executable('pbcopy') or { '' }
		if pbcopy_path.len > 0 {
			mut p := os.new_process(pbcopy_path)
			p.set_redirect_stdio()
			p.run()
			p.stdin_write(text)
			p.close()
			p.wait()
			if p.code == 0 {
				return true
			}
		}
	} $else $if linux {
		// 1. Wayland clipboard
		wl_copy := os.find_abs_path_of_executable('wl-copy') or { '' }
		if wl_copy.len > 0 {
			mut p := os.new_process(wl_copy)
			p.set_redirect_stdio()
			p.run()
			p.stdin_write(text)
			p.close()
			p.wait()
			if p.code == 0 {
				return true
			}
		}
		// 2. X11 via xclip
		xclip := os.find_abs_path_of_executable('xclip') or { '' }
		if xclip.len > 0 {
			mut p := os.new_process(xclip)
			p.set_args(['-selection', 'clipboard'])
			p.set_redirect_stdio()
			p.run()
			p.stdin_write(text)
			p.close()
			p.wait()
			if p.code == 0 {
				return true
			}
		}
		// 3. X11 via xsel
		xsel := os.find_abs_path_of_executable('xsel') or { '' }
		if xsel.len > 0 {
			mut p := os.new_process(xsel)
			p.set_args(['-b', '-i'])
			p.set_redirect_stdio()
			p.run()
			p.stdin_write(text)
			p.close()
			p.wait()
			if p.code == 0 {
				return true
			}
		}
	} $else $if windows {
		clip_path := os.find_abs_path_of_executable('clip.exe') or { '' }
		if clip_path.len > 0 {
			mut p := os.new_process(clip_path)
			p.set_redirect_stdio()
			p.run()
			p.stdin_write(text)
			p.close()
			p.wait()
			if p.code == 0 {
				return true
			}
		}
	}

	// Fallback to V built-in clipboard module
	mut cb := clipboard.new()
	if !cb.is_available() {
		cb.destroy()
		return false
	}
	res := cb.copy(text)
	cb.destroy()
	return res
}

// clipboard_copy delegates to standalone clipboard_copy.
pub fn (win &SimpleWindow) clipboard_copy(text string) bool {
	return clipboard_copy(text)
}

// clipboard_read retrieves text from the system clipboard across macOS, Linux (Wayland/X11), and Windows.
pub fn clipboard_read() string {
	$if macos {
		pbpaste_path := os.find_abs_path_of_executable('pbpaste') or { '' }
		if pbpaste_path.len > 0 {
			res := os.execute(pbpaste_path)
			if res.exit_code == 0 {
				return res.output
			}
		}
	} $else $if linux {
		// 1. Wayland clipboard
		wl_paste := os.find_abs_path_of_executable('wl-paste') or { '' }
		if wl_paste.len > 0 {
			res := os.execute('${wl_paste} --no-newline 2>/dev/null || ${wl_paste} 2>/dev/null')
			if res.exit_code == 0 && res.output.len > 0 {
				return res.output
			}
		}
		// 2. X11 via xclip
		xclip := os.find_abs_path_of_executable('xclip') or { '' }
		if xclip.len > 0 {
			res := os.execute('${xclip} -selection clipboard -o 2>/dev/null')
			if res.exit_code == 0 {
				return res.output
			}
		}
		// 3. X11 via xsel
		xsel := os.find_abs_path_of_executable('xsel') or { '' }
		if xsel.len > 0 {
			res := os.execute('${xsel} -b -o 2>/dev/null')
			if res.exit_code == 0 {
				return res.output
			}
		}
	} $else $if windows {
		res := os.execute('powershell -Command "Get-Clipboard"')
		if res.exit_code == 0 {
			return res.output.trim_space()
		}
	}

	// Fallback to V built-in clipboard module
	mut cb := clipboard.new()
	if !cb.is_available() {
		cb.destroy()
		return ''
	}
	text := cb.paste()
	cb.destroy()
	return text
}

// clipboard_read delegates to standalone clipboard_read.
pub fn (win &SimpleWindow) clipboard_read() string {
	return clipboard_read()
}

// ==========================================
// 19. Benchmark & Execution Timing Helper (Chapter 13: benchmark)
// ==========================================

// SimpleBenchmark wraps benchmark.Benchmark to time execution stages.
pub struct SimpleBenchmark {
pub mut:
	b benchmark.Benchmark
}

// measure adds a benchmark measurement point.
pub fn (mut sb SimpleBenchmark) measure(label string) {
	sb.b.measure(label)
}

// step advances the benchmark to the next step.
pub fn (mut sb SimpleBenchmark) step() {
	sb.b.step()
}

// ok marks the current step as successful.
pub fn (mut sb SimpleBenchmark) ok() {
	sb.b.ok()
}

// fail marks the current step as failed.
pub fn (mut sb SimpleBenchmark) fail() {
	sb.b.fail()
}

// step_message returns the formatted string message for the current step.
pub fn (mut sb SimpleBenchmark) step_message(label string) string {
	return sb.b.step_message(label)
}

// total_message returns the final execution summary message.
pub fn (mut sb SimpleBenchmark) total_message(label string) string {
	return sb.b.total_message(label)
}

// stop stops the benchmark timing.
pub fn (mut sb SimpleBenchmark) stop() {
	sb.b.stop()
}

// start_benchmark starts a simple benchmark.
pub fn start_benchmark() SimpleBenchmark {
	return SimpleBenchmark{
		b: benchmark.start()
	}
}

// start_benchmark delegates to standalone start_benchmark.
pub fn (win &SimpleWindow) start_benchmark() SimpleBenchmark {
	return start_benchmark()
}

// new_benchmark initializes a new benchmark structure.
pub fn new_benchmark() SimpleBenchmark {
	return SimpleBenchmark{
		b: benchmark.new_benchmark()
	}
}

// new_benchmark delegates to standalone new_benchmark.
pub fn (win &SimpleWindow) new_benchmark() SimpleBenchmark {
	return new_benchmark()
}

// ==========================================
// 20. TCP Socket Client (Chapter 13: net)
// ==========================================

// SimpleTCPClient provides a simplified wrapper for TCP connections.
pub struct SimpleTCPClient {
pub mut:
	conn net.TcpConn
}

// write sends text to the TCP socket.
pub fn (mut s SimpleTCPClient) write(data string) ! {
	s.conn.write(data.bytes())!
}

// read reads string data from the TCP socket.
pub fn (mut s SimpleTCPClient) read() !string {
	mut buf := []u8{len: 1024}
	n := s.conn.read(mut buf)!
	return buf[..n].bytestr()
}

// close disconnects the TCP connection.
pub fn (mut s SimpleTCPClient) close() {
	s.conn.close() or {}
}

// tcp_connect establishes a TCP client connection to a specified address.
pub fn tcp_connect(address string) !SimpleTCPClient {
	conn := net.dial_tcp(address)!
	return SimpleTCPClient{
		conn: conn
	}
}

// tcp_connect delegates to standalone tcp_connect.
pub fn (win &SimpleWindow) tcp_connect(address string) !SimpleTCPClient {
	if win.debug_mode {
		println('[simplegui STDLIB] Dialing TCP socket connection to: ${address}')
	}
	return tcp_connect(address)!
}

// ==========================================
// 21. UDP Socket Client (Chapter 13: net)
// ==========================================

// SimpleUDPClient provides a simplified wrapper for UDP connections.
pub struct SimpleUDPClient {
pub mut:
	socket net.UdpConn
}

// write sends data packets over the UDP socket.
pub fn (mut s SimpleUDPClient) write(data string) ! {
	s.socket.write(data.bytes())!
}

// read reads a string data payload from the UDP socket.
pub fn (mut s SimpleUDPClient) read() !string {
	mut buf := []u8{len: 1024}
	n, _ := s.socket.read(mut buf)!
	return buf[..n].bytestr()
}

// close closes the UDP connection socket.
pub fn (mut s SimpleUDPClient) close() {
	s.socket.close() or {}
}

// udp_connect binds and connects a UDP socket to a target address.
pub fn udp_connect(address string) !SimpleUDPClient {
	socket := net.dial_udp(address)!
	return SimpleUDPClient{
		socket: socket
	}
}

// udp_connect delegates to standalone udp_connect.
pub fn (win &SimpleWindow) udp_connect(address string) !SimpleUDPClient {
	if win.debug_mode {
		println('[simplegui STDLIB] Dialing UDP socket to: ${address}')
	}
	return udp_connect(address)!
}

// ==========================================
// 22. Unix Domain Socket Client (Chapter 13: net.unix)
// ==========================================

// SimpleUnixClient provides a simplified wrapper for Unix domain socket connections.
pub struct SimpleUnixClient {
pub mut:
	conn unix.StreamConn
}

// write sends text data over the Unix socket.
pub fn (mut s SimpleUnixClient) write(data string) ! {
	s.conn.write(data.bytes())!
}

// read reads a string payload from the Unix socket.
pub fn (mut s SimpleUnixClient) read() !string {
	mut buf := []u8{len: 1024}
	n := s.conn.read(mut buf)!
	return buf[..n].bytestr()
}

// close closes the Unix socket stream connection.
pub fn (mut s SimpleUnixClient) close() {
	s.conn.close() or {}
}

// unix_connect connects a client to a Unix domain socket path.
pub fn unix_connect(path string) !SimpleUnixClient {
	conn := unix.connect_stream(path)!
	return SimpleUnixClient{
		conn: conn
	}
}

// unix_connect delegates to standalone unix_connect.
pub fn (win &SimpleWindow) unix_connect(path string) !SimpleUnixClient {
	if win.debug_mode {
		println('[simplegui STDLIB] Connecting Unix socket stream to path: ${path}')
	}
	return unix_connect(path)!
}

// ==========================================
// 23. Deflate Compression (Chapter 13: compress.deflate)
// ==========================================

// compress_deflate compresses text using Deflate compression format.
pub fn compress_deflate(text string) []u8 {
	compressed := deflate.compress(text.bytes()) or { return []u8{} }
	return compressed
}

// compress_deflate delegates to standalone compress_deflate.
pub fn (win &SimpleWindow) compress_deflate(text string) []u8 {
	return compress_deflate(text)
}

// decompress_deflate extracts Deflate-compressed binary bytes back to string format.
pub fn decompress_deflate(data []u8) string {
	decompressed := deflate.decompress(data) or { return '' }
	return decompressed.bytestr()
}

// decompress_deflate delegates to standalone decompress_deflate.
pub fn (win &SimpleWindow) decompress_deflate(data []u8) string {
	return decompress_deflate(data)
}

// ==========================================
// 24. Zstd Compression (Chapter 13: compress.zstd)
// ==========================================

// compress_zstd compresses text using Facebook Zstd compression format.
pub fn compress_zstd(text string) []u8 {
	// Standard compression level 3 as default
	compressed := zstd.compress(text.bytes(), compression_level: 3) or { return []u8{} }
	return compressed
}

// compress_zstd delegates to standalone compress_zstd.
pub fn (win &SimpleWindow) compress_zstd(text string) []u8 {
	return compress_zstd(text)
}

// decompress_zstd extracts Zstd-compressed binary bytes back to string format.
pub fn decompress_zstd(data []u8) string {
	decompressed := zstd.decompress(data) or { return '' }
	return decompressed.bytestr()
}

// decompress_zstd delegates to standalone decompress_zstd.
pub fn (win &SimpleWindow) decompress_zstd(data []u8) string {
	return decompress_zstd(data)
}

// ==========================================
// 25. HTML Parser Helper (Chapter 13: net.html)
// ==========================================

// SimpleHTMLDocument wraps html.DocumentObjectModel for easy tag and class querying.
pub struct SimpleHTMLDocument {
pub mut:
	doc html.DocumentObjectModel
}

// get_tag_text retrieves the text content of the first matching HTML tag name.
pub fn (d &SimpleHTMLDocument) get_tag_text(name string) string {
	tags := d.doc.get_tags(name: name)
	if tags.len > 0 {
		return tags[0].text().trim_space()
	}
	return ''
}

// get_tags_by_class retrieves the text content of all tags matching a class name.
pub fn (d &SimpleHTMLDocument) get_tags_by_class(class_name string) []string {
	tags := d.doc.get_tags_by_class_name(class_name)
	mut res := []string{}
	for t in tags {
		res << t.text().trim_space()
	}
	return res
}

// html_parse parses an HTML string into a SimpleHTMLDocument.
pub fn html_parse(content string) SimpleHTMLDocument {
	return SimpleHTMLDocument{
		doc: html.parse(content)
	}
}

// html_parse delegates to standalone html_parse.
pub fn (win &SimpleWindow) html_parse(content string) SimpleHTMLDocument {
	return html_parse(content)
}

// ==========================================
// 26. Strings Lorem Helper (Chapter 13: strings.lorem)
// ==========================================

// lorem_generate produces pseudo-random placeholder text (Markov chain).
// Supported corpora: 'lorem' (default), 'poe', 'darwin', 'bard'.
pub fn lorem_generate(corpus_name string, paragraphs int, sentences int, words int) string {
	return lorem.generate(lorem.LoremCfg{
		corpus_name:             corpus_name
		paragraphs:              paragraphs
		sentences_per_paragraph: sentences
		words_per_sentence:      words
	})
}

// lorem_generate delegates to standalone lorem_generate.
pub fn (win &SimpleWindow) lorem_generate(corpus_name string, paragraphs int, sentences int, words int) string {
	return lorem_generate(corpus_name, paragraphs, sentences, words)
}

// ==========================================
// 27. Encoding Utilities (Chapter 13: encoding.hex, encoding.base64)
// ==========================================

// hex_encode converts a raw string to a hex-encoded string.
pub fn hex_encode(text string) string {
	return hex.encode(text.bytes())
}

// hex_encode delegates to standalone hex_encode.
pub fn (win &SimpleWindow) hex_encode(text string) string {
	return hex_encode(text)
}

// hex_decode converts a hex-encoded string back to raw text.
pub fn hex_decode(hex_str string) string {
	decoded := hex.decode(hex_str) or { return '' }
	return decoded.bytestr()
}

// hex_decode delegates to standalone hex_decode.
pub fn (win &SimpleWindow) hex_decode(hex_str string) string {
	return hex_decode(hex_str)
}

// base64_encode converts a raw string to a base64-encoded string.
pub fn base64_encode(text string) string {
	return base64.encode(text.bytes())
}

// base64_encode delegates to standalone base64_encode.
pub fn (win &SimpleWindow) base64_encode(text string) string {
	return base64_encode(text)
}

// base64_decode converts a base64-encoded string back to raw text.
pub fn base64_decode(b64_str string) string {
	decoded := base64.decode(b64_str)
	return decoded.bytestr()
}

// base64_decode delegates to standalone base64_decode.
pub fn (win &SimpleWindow) base64_decode(b64_str string) string {
	return base64_decode(b64_str)
}

// ==========================================
// 28. Math & Trigonometry Helpers (Chapter 13: math)
// ==========================================

// math_sin returns the sine of a radian value.
pub fn math_sin(x f64) f64 {
	return math.sin(x)
}

// math_sin delegates to standalone math_sin.
pub fn (win &SimpleWindow) math_sin(x f64) f64 {
	return math_sin(x)
}

// math_cos returns the cosine of a radian value.
pub fn math_cos(x f64) f64 {
	return math.cos(x)
}

// math_cos delegates to standalone math_cos.
pub fn (win &SimpleWindow) math_cos(x f64) f64 {
	return math_cos(x)
}

// math_tan returns the tangent of a radian value.
pub fn math_tan(x f64) f64 {
	return math.tan(x)
}

// math_tan delegates to standalone math_tan.
pub fn (win &SimpleWindow) math_tan(x f64) f64 {
	return math_tan(x)
}

// math_sqrt returns the square root of a non-negative number.
pub fn math_sqrt(x f64) f64 {
	return math.sqrt(x)
}

// math_sqrt delegates to standalone math_sqrt.
pub fn (win &SimpleWindow) math_sqrt(x f64) f64 {
	return math_sqrt(x)
}

// math_pow returns base raised to the power exp.
pub fn math_pow(base f64, exp f64) f64 {
	return math.pow(base, exp)
}

// math_pow delegates to standalone math_pow.
pub fn (win &SimpleWindow) math_pow(base f64, exp f64) f64 {
	return math_pow(base, exp)
}

// math_abs returns the absolute value of a floating point number.
pub fn math_abs(x f64) f64 {
	return math.abs(x)
}

// math_abs delegates to standalone math_abs.
pub fn (win &SimpleWindow) math_abs(x f64) f64 {
	return math_abs(x)
}

// math_clamp constrains a value within a min and max range.
pub fn math_clamp(val f64, min f64, max f64) f64 {
	return math.clamp(val, min, max)
}

// math_clamp delegates to standalone math_clamp.
pub fn (win &SimpleWindow) math_clamp(val f64, min f64, max f64) f64 {
	return math_clamp(val, min, max)
}

// math_round rounds a number to the nearest integer.
pub fn math_round(x f64) f64 {
	return math.round(x)
}

// math_round delegates to standalone math_round.
pub fn (win &SimpleWindow) math_round(x f64) f64 {
	return math_round(x)
}

// math_floor returns the greatest integer less than or equal to x.
pub fn math_floor(x f64) f64 {
	return math.floor(x)
}

// math_floor delegates to standalone math_floor.
pub fn (win &SimpleWindow) math_floor(x f64) f64 {
	return math_floor(x)
}

// math_ceil returns the least integer greater than or equal to x.
pub fn math_ceil(x f64) f64 {
	return math.ceil(x)
}

// math_ceil delegates to standalone math_ceil.
pub fn (win &SimpleWindow) math_ceil(x f64) f64 {
	return math_ceil(x)
}

// ==========================================
// 29. Statistical Analysis Utilities (Chapter 13: math.stats)
// ==========================================

// stats_mean computes the arithmetic mean of a floating-point dataset.
pub fn stats_mean(data []f64) f64 {
	if data.len == 0 {
		return 0.0
	}
	return stats.mean(data)
}

// stats_mean delegates to standalone stats_mean.
pub fn (win &SimpleWindow) stats_mean(data []f64) f64 {
	return stats_mean(data)
}

// stats_median computes the median value of a dataset.
pub fn stats_median(data []f64) f64 {
	if data.len == 0 {
		return 0.0
	}
	mut sorted := data.clone()
	sorted.sort()
	return stats.median(sorted)
}

// stats_median delegates to standalone stats_median.
pub fn (win &SimpleWindow) stats_median(data []f64) f64 {
	return stats_median(data)
}

// stats_sample_variance computes the sample variance of a dataset.
pub fn stats_sample_variance(data []f64) f64 {
	if data.len == 0 {
		return 0.0
	}
	return stats.sample_variance(data)
}

// stats_sample_variance delegates to standalone stats_sample_variance.
pub fn (win &SimpleWindow) stats_sample_variance(data []f64) f64 {
	return stats_sample_variance(data)
}

// stats_sample_std_dev computes the sample standard deviation of a dataset.
pub fn stats_sample_std_dev(data []f64) f64 {
	if data.len == 0 {
		return 0.0
	}
	return stats.sample_stddev(data)
}

// stats_sample_std_dev delegates to standalone stats_sample_std_dev.
pub fn (win &SimpleWindow) stats_sample_std_dev(data []f64) f64 {
	return stats_sample_std_dev(data)
}

// stats_population_variance computes the population variance of a dataset.
pub fn stats_population_variance(data []f64) f64 {
	if data.len == 0 {
		return 0.0
	}
	return stats.population_variance(data)
}

// stats_population_variance delegates to standalone stats_population_variance.
pub fn (win &SimpleWindow) stats_population_variance(data []f64) f64 {
	return stats_population_variance(data)
}

// stats_population_std_dev computes the population standard deviation of a dataset.
pub fn stats_population_std_dev(data []f64) f64 {
	if data.len == 0 {
		return 0.0
	}
	return stats.population_stddev(data)
}

// stats_population_std_dev delegates to standalone stats_population_std_dev.
pub fn (win &SimpleWindow) stats_population_std_dev(data []f64) f64 {
	return stats_population_std_dev(data)
}

// ==========================================
// 30. Arbitrary-Precision BigInteger Math (Chapter 13: math.big)
// ==========================================

// SimpleBigInt provides a high-level wrapper around V's arbitrary-precision integer.
pub struct SimpleBigInt {
pub mut:
	val big.Integer
}

// add adds another SimpleBigInt and returns the result.
pub fn (b SimpleBigInt) add(other SimpleBigInt) SimpleBigInt {
	return SimpleBigInt{
		val: b.val + other.val
	}
}

// sub subtracts another SimpleBigInt and returns the result.
pub fn (b SimpleBigInt) sub(other SimpleBigInt) SimpleBigInt {
	return SimpleBigInt{
		val: b.val - other.val
	}
}

// mul multiplies by another SimpleBigInt and returns the result.
pub fn (b SimpleBigInt) mul(other SimpleBigInt) SimpleBigInt {
	return SimpleBigInt{
		val: b.val * other.val
	}
}

// div divides by another SimpleBigInt and returns the result.
pub fn (b SimpleBigInt) div(other SimpleBigInt) SimpleBigInt {
	return SimpleBigInt{
		val: b.val / other.val
	}
}

// mod computes the modulus by another SimpleBigInt and returns the result.
pub fn (b SimpleBigInt) mod(other SimpleBigInt) SimpleBigInt {
	return SimpleBigInt{
		val: b.val % other.val
	}
}

// str converts the BigInt to a decimal string representation.
pub fn (b SimpleBigInt) str() string {
	return b.val.str()
}

// big_int_from_int creates a SimpleBigInt from an integer value.
pub fn big_int_from_int(v int) SimpleBigInt {
	return SimpleBigInt{
		val: big.integer_from_int(v)
	}
}

// big_int_from_int delegates to standalone big_int_from_int.
pub fn (win &SimpleWindow) big_int_from_int(v int) SimpleBigInt {
	return big_int_from_int(v)
}

// big_int_from_str creates a SimpleBigInt from a decimal string.
pub fn big_int_from_str(s string) SimpleBigInt {
	res := big.integer_from_string(s) or { big.integer_from_int(0) }
	return SimpleBigInt{
		val: res
	}
}

// big_int_from_str delegates to standalone big_int_from_str.
pub fn (win &SimpleWindow) big_int_from_str(s string) SimpleBigInt {
	return big_int_from_str(s)
}

// ==========================================
// 31. Array Processing Utilities (Chapter 13: arrays)
// ==========================================

// array_min returns the minimum value in an integer array, or 0 if empty.
pub fn array_min(arr []int) int {
	return arrays.min(arr) or { 0 }
}

// array_min delegates to standalone array_min.
pub fn (win &SimpleWindow) array_min(arr []int) int {
	return array_min(arr)
}

// array_max returns the maximum value in an integer array, or 0 if empty.
pub fn array_max(arr []int) int {
	return arrays.max(arr) or { 0 }
}

// array_max delegates to standalone array_max.
pub fn (win &SimpleWindow) array_max(arr []int) int {
	return array_max(arr)
}

// array_min_f64 returns the minimum value in a float array, or 0.0 if empty.
pub fn array_min_f64(arr []f64) f64 {
	return arrays.min(arr) or { 0.0 }
}

// array_min_f64 delegates to standalone array_min_f64.
pub fn (win &SimpleWindow) array_min_f64(arr []f64) f64 {
	return array_min_f64(arr)
}

// array_max_f64 returns the maximum value in a float array, or 0.0 if empty.
pub fn array_max_f64(arr []f64) f64 {
	return arrays.max(arr) or { 0.0 }
}

// array_max_f64 delegates to standalone array_max_f64.
pub fn (win &SimpleWindow) array_max_f64(arr []f64) f64 {
	return array_max_f64(arr)
}

// array_sum returns the sum of all elements in an integer array.
pub fn array_sum(arr []int) int {
	return arrays.sum(arr) or { 0 }
}

// array_sum delegates to standalone array_sum.
pub fn (win &SimpleWindow) array_sum(arr []int) int {
	return array_sum(arr)
}

// array_sum_f64 returns the sum of all elements in a float array.
pub fn array_sum_f64(arr []f64) f64 {
	return arrays.sum(arr) or { 0.0 }
}

// array_sum_f64 delegates to standalone array_sum_f64.
pub fn (win &SimpleWindow) array_sum_f64(arr []f64) f64 {
	return array_sum_f64(arr)
}

// array_unique_strings removes duplicate string values from an array while preserving insertion order.
pub fn array_unique_strings(arr []string) []string {
	mut seen := map[string]bool{}
	mut res := []string{}
	for item in arr {
		if item !in seen {
			seen[item] = true
			res << item
		}
	}
	return res
}

// array_unique_strings delegates to standalone array_unique_strings.
pub fn (win &SimpleWindow) array_unique_strings(arr []string) []string {
	return array_unique_strings(arr)
}

// ==========================================
// 32. UTF-8 String Utilities (Chapter 13: encoding.utf8)
// ==========================================

// utf8_len returns the number of UTF-8 characters (code points) in a string.
pub fn utf8_len(text string) int {
	return utf8.len(text)
}

// utf8_len delegates to standalone utf8_len.
pub fn (win &SimpleWindow) utf8_len(text string) int {
	return utf8_len(text)
}

// utf8_is_valid checks if a string contains valid UTF-8 encoding.
pub fn utf8_is_valid(text string) bool {
	return utf8.validate_str(text)
}

// utf8_is_valid delegates to standalone utf8_is_valid.
pub fn (win &SimpleWindow) utf8_is_valid(text string) bool {
	return utf8_is_valid(text)
}

// ==========================================
// 33. String Distance & String Builder (Chapter 13: strings)
// ==========================================

// string_levenshtein computes the Levenshtein edit distance between two strings.
pub fn string_levenshtein(s1 string, s2 string) int {
	return strings.levenshtein_distance(s1, s2)
}

// string_levenshtein delegates to standalone string_levenshtein.
pub fn (win &SimpleWindow) string_levenshtein(s1 string, s2 string) int {
	return string_levenshtein(s1, s2)
}

// SimpleStringBuilder provides an efficient, growable string builder buffer.
pub struct SimpleStringBuilder {
mut:
	sb strings.Builder = strings.new_builder(256)
}

// write appends text to the string builder.
pub fn (mut ssb SimpleStringBuilder) write(text string) {
	ssb.sb.write_string(text)
}

// write_line appends text followed by a newline to the string builder.
pub fn (mut ssb SimpleStringBuilder) write_line(text string) {
	ssb.sb.writeln(text)
}

// str returns the complete accumulated string content.
pub fn (mut ssb SimpleStringBuilder) str() string {
	return ssb.sb.str()
}

// len returns the byte length of the accumulated string content.
pub fn (ssb &SimpleStringBuilder) len() int {
	return ssb.sb.len
}

// new_string_builder creates a new SimpleStringBuilder.
pub fn new_string_builder() SimpleStringBuilder {
	return SimpleStringBuilder{}
}

// new_string_builder delegates to standalone new_string_builder.
pub fn (win &SimpleWindow) new_string_builder() SimpleStringBuilder {
	return new_string_builder()
}

// ==========================================
// 34. CSV Reader & Writer Utilities (Chapter 13: encoding.csv)
// ==========================================

// csv_parse parses a CSV formatted string into a 2D matrix of row strings.
pub fn csv_parse(content string) [][]string {
	mut r := csv.new_reader(content)
	mut rows := [][]string{}
	for {
		row := r.read() or { break }
		rows << row
	}
	return rows
}

// csv_parse delegates to standalone csv_parse.
pub fn (win &SimpleWindow) csv_parse(content string) [][]string {
	return csv_parse(content)
}

// csv_encode serializes a 2D matrix of row strings into a CSV formatted string.
pub fn csv_encode(rows [][]string) string {
	mut sb := strings.new_builder(256)
	for row in rows {
		mut line := []string{}
		for col in row {
			if col.contains(',') || col.contains('"') || col.contains('\n') {
				escaped := col.replace('"', '""')
				line << '"${escaped}"'
			} else {
				line << col
			}
		}
		sb.writeln(line.join(','))
	}
	return sb.str()
}

// csv_encode delegates to standalone csv_encode.
pub fn (win &SimpleWindow) csv_encode(rows [][]string) string {
	return csv_encode(rows)
}

// ==========================================
// 35. Ed25519 Digital Signatures (Chapter 13: crypto.ed25519)
// ==========================================

// SimpleEd25519KeyPair contains a public and private Ed25519 key pair.
pub struct SimpleEd25519KeyPair {
pub:
	pub_key  []u8
	priv_key []u8
}

// crypto_ed25519_generate_key generates a new Ed25519 public/private key pair.
pub fn crypto_ed25519_generate_key() !SimpleEd25519KeyPair {
	pub_k, priv_k := ed25519.generate_key()!
	return SimpleEd25519KeyPair{
		pub_key:  pub_k
		priv_key: priv_k
	}
}

// crypto_ed25519_generate_key delegates to standalone crypto_ed25519_generate_key.
pub fn (win &SimpleWindow) crypto_ed25519_generate_key() !SimpleEd25519KeyPair {
	return crypto_ed25519_generate_key()!
}

// crypto_ed25519_sign signs a text message using an Ed25519 private key.
pub fn crypto_ed25519_sign(priv_key []u8, msg string) ![]u8 {
	return ed25519.sign(priv_key, msg.bytes())!
}

// crypto_ed25519_sign delegates to standalone crypto_ed25519_sign.
pub fn (win &SimpleWindow) crypto_ed25519_sign(priv_key []u8, msg string) ![]u8 {
	return crypto_ed25519_sign(priv_key, msg)!
}

// crypto_ed25519_verify verifies an Ed25519 signature against a public key and message.
pub fn crypto_ed25519_verify(pub_key []u8, msg string, sig []u8) bool {
	return ed25519.verify(pub_key, msg.bytes(), sig) or { false }
}

// crypto_ed25519_verify delegates to standalone crypto_ed25519_verify.
pub fn (win &SimpleWindow) crypto_ed25519_verify(pub_key []u8, msg string, sig []u8) bool {
	return crypto_ed25519_verify(pub_key, msg, sig)
}

// ==========================================
// 36. Password-Based Key Derivation (Chapter 13: crypto.pbkdf2)
// ==========================================

// crypto_pbkdf2 derives a key using PBKDF2 with HMAC-SHA256.
pub fn crypto_pbkdf2(password string, salt string, iterations int, key_len int) []u8 {
	h := sha256.new()
	derived := pbkdf2.key(password.bytes(), salt.bytes(), iterations, key_len, h) or { []u8{} }
	return derived
}

// crypto_pbkdf2 delegates to standalone crypto_pbkdf2.
pub fn (win &SimpleWindow) crypto_pbkdf2(password string, salt string, iterations int, key_len int) []u8 {
	return crypto_pbkdf2(password, salt, iterations, key_len)
}

// ==========================================
// 37. Thread Synchronization Primitives (Chapter 13: sync)
// ==========================================

// SimpleMutex wraps a thread-safe mutex lock.
pub struct SimpleMutex {
mut:
	m sync.Mutex
}

// lock acquires the mutex lock, blocking until available.
pub fn (mut sm SimpleMutex) lock() {
	sm.m.lock()
}

// unlock releases the mutex lock.
pub fn (mut sm SimpleMutex) unlock() {
	sm.m.unlock()
}

// new_mutex creates a new SimpleMutex lock.
pub fn new_mutex() SimpleMutex {
	return SimpleMutex{}
}

// new_mutex delegates to standalone new_mutex.
pub fn (win &SimpleWindow) new_mutex() SimpleMutex {
	return new_mutex()
}

// SimpleWaitGroup coordinates completion of multiple concurrent tasks.
pub struct SimpleWaitGroup {
mut:
	wg sync.WaitGroup
}

// add increments the WaitGroup counter.
pub fn (mut swg SimpleWaitGroup) add(delta int) {
	swg.wg.add(delta)
}

// done decrements the WaitGroup counter by 1.
pub fn (mut swg SimpleWaitGroup) done() {
	swg.wg.done()
}

// wait blocks until the WaitGroup counter reaches zero.
pub fn (mut swg SimpleWaitGroup) wait() {
	swg.wg.wait()
}

// new_wait_group creates a new SimpleWaitGroup.
pub fn new_wait_group() SimpleWaitGroup {
	return SimpleWaitGroup{}
}

// new_wait_group delegates to standalone new_wait_group.
pub fn (win &SimpleWindow) new_wait_group() SimpleWaitGroup {
	return new_wait_group()
}

// ==========================================
// 38. Complex Number Arithmetic (Chapter 13: math.complex)
// ==========================================

// SimpleComplex wraps a 2D complex number (real + imaginary).
pub struct SimpleComplex {
pub mut:
	c complex.Complex
}

// add adds two complex numbers together.
pub fn (sc SimpleComplex) add(other SimpleComplex) SimpleComplex {
	return SimpleComplex{
		c: sc.c.add(other.c)
	}
}

// sub subtracts another complex number from this complex number.
pub fn (sc SimpleComplex) sub(other SimpleComplex) SimpleComplex {
	return SimpleComplex{
		c: sc.c.subtract(other.c)
	}
}

// mul multiplies two complex numbers.
pub fn (sc SimpleComplex) mul(other SimpleComplex) SimpleComplex {
	return SimpleComplex{
		c: sc.c.multiply(other.c)
	}
}

// div divides this complex number by another complex number.
pub fn (sc SimpleComplex) div(other SimpleComplex) SimpleComplex {
	return SimpleComplex{
		c: sc.c.divide(other.c)
	}
}

// abs returns the magnitude/modulus of the complex number.
pub fn (sc SimpleComplex) abs() f64 {
	return sc.c.abs()
}

// arg returns the phase angle (in radians) of the complex number.
pub fn (sc SimpleComplex) arg() f64 {
	return sc.c.arg()
}

// conj returns the complex conjugate.
pub fn (sc SimpleComplex) conj() SimpleComplex {
	return SimpleComplex{
		c: sc.c.conjugate()
	}
}

// exp computes e raised to the power of this complex number.
pub fn (sc SimpleComplex) exp() SimpleComplex {
	return SimpleComplex{
		c: sc.c.exp()
	}
}

// str converts the complex number to a readable string formatted as (re + im i).
pub fn (sc SimpleComplex) str() string {
	return sc.c.str()
}

// complex_new constructs a new SimpleComplex instance.
pub fn complex_new(re f64, im f64) SimpleComplex {
	return SimpleComplex{
		c: complex.complex(re, im)
	}
}

// complex_new delegates to standalone complex_new.
pub fn (win &SimpleWindow) complex_new(re f64, im f64) SimpleComplex {
	return complex_new(re, im)
}

// ==========================================
// 39. Advanced Math & Geometry Helpers (Chapter 13: math)
// ==========================================

// math_degrees converts radians to degrees.
pub fn math_degrees(radians f64) f64 {
	return math.degrees(radians)
}

// math_degrees delegates to standalone math_degrees.
pub fn (win &SimpleWindow) math_degrees(radians f64) f64 {
	return math_degrees(radians)
}

// math_radians converts degrees to radians.
pub fn math_radians(degrees f64) f64 {
	return math.radians(degrees)
}

// math_radians delegates to standalone math_radians.
pub fn (win &SimpleWindow) math_radians(degrees f64) f64 {
	return math_radians(degrees)
}

// math_hypot computes the Euclidean distance sqrt(x^2 + y^2).
pub fn math_hypot(x f64, y f64) f64 {
	return math.hypot(x, y)
}

// math_hypot delegates to standalone math_hypot.
pub fn (win &SimpleWindow) math_hypot(x f64, y f64) f64 {
	return math_hypot(x, y)
}

// math_gcd returns the greatest common divisor of two integers.
pub fn math_gcd(a i64, b i64) i64 {
	return math.gcd(a, b)
}

// math_gcd delegates to standalone math_gcd.
pub fn (win &SimpleWindow) math_gcd(a i64, b i64) i64 {
	return math_gcd(a, b)
}

// math_lcm returns the least common multiple of two integers.
pub fn math_lcm(a i64, b i64) i64 {
	return math.lcm(a, b)
}

// math_lcm delegates to standalone math_lcm.
pub fn (win &SimpleWindow) math_lcm(a i64, b i64) i64 {
	return math_lcm(a, b)
}

// math_remap maps a value x from range [in_min, in_max] to target range [out_min, out_max].
pub fn math_remap(x f64, in_min f64, in_max f64, out_min f64, out_max f64) f64 {
	return math.remap(x, in_min, in_max, out_min, out_max)
}

// math_remap delegates to standalone math_remap.
pub fn (win &SimpleWindow) math_remap(x f64, in_min f64, in_max f64, out_min f64, out_max f64) f64 {
	return math_remap(x, in_min, in_max, out_min, out_max)
}

// math_smoothstep computes smooth Hermite interpolation between 0 and 1.
pub fn math_smoothstep(edge0 f64, edge1 f64, x f64) f64 {
	return math.smoothstep(edge0, edge1, x)
}

// math_smoothstep delegates to standalone math_smoothstep.
pub fn (win &SimpleWindow) math_smoothstep(edge0 f64, edge1 f64, x f64) f64 {
	return math_smoothstep(edge0, edge1, x)
}

// math_atan2 computes the multi-valued arctangent atan2(y, x).
pub fn math_atan2(y f64, x f64) f64 {
	return math.atan2(y, x)
}

// math_atan2 delegates to standalone math_atan2.
pub fn (win &SimpleWindow) math_atan2(y f64, x f64) f64 {
	return math_atan2(y, x)
}

// math_log10 returns the base-10 logarithm of a positive floating point number.
pub fn math_log10(x f64) f64 {
	return math.log10(x)
}

// math_log10 delegates to standalone math_log10.
pub fn (win &SimpleWindow) math_log10(x f64) f64 {
	return math_log10(x)
}

// math_log2 returns the base-2 logarithm of a positive floating point number.
pub fn math_log2(x f64) f64 {
	return math.log2(x)
}

// math_log2 delegates to standalone math_log2.
pub fn (win &SimpleWindow) math_log2(x f64) f64 {
	return math_log2(x)
}

// math_round_sig rounds a floating point number to a given number of significant digits.
pub fn math_round_sig(x f64, sig_digits int) f64 {
	return math.round_sig(x, sig_digits)
}

// math_round_sig delegates to standalone math_round_sig.
pub fn (win &SimpleWindow) math_round_sig(x f64, sig_digits int) f64 {
	return math_round_sig(x, sig_digits)
}

// ==========================================
// 40. Advanced Statistical Analytics (Chapter 13: math.stats)
// ==========================================

// stats_geometric_mean computes the geometric mean of a dataset.
pub fn stats_geometric_mean(data []f64) f64 {
	if data.len == 0 {
		return 0.0
	}
	return stats.geometric_mean(data)
}

// stats_geometric_mean delegates to standalone stats_geometric_mean.
pub fn (win &SimpleWindow) stats_geometric_mean(data []f64) f64 {
	return stats_geometric_mean(data)
}

// stats_harmonic_mean computes the harmonic mean of a dataset.
pub fn stats_harmonic_mean(data []f64) f64 {
	if data.len == 0 {
		return 0.0
	}
	return stats.harmonic_mean(data)
}

// stats_harmonic_mean delegates to standalone stats_harmonic_mean.
pub fn (win &SimpleWindow) stats_harmonic_mean(data []f64) f64 {
	return stats_harmonic_mean(data)
}

// stats_rms computes the Root Mean Square (quadratic mean) of a dataset.
pub fn stats_rms(data []f64) f64 {
	if data.len == 0 {
		return 0.0
	}
	return stats.rms(data)
}

// stats_rms delegates to standalone stats_rms.
pub fn (win &SimpleWindow) stats_rms(data []f64) f64 {
	return stats_rms(data)
}

// stats_mode returns the most frequent value in a dataset.
pub fn stats_mode(data []f64) f64 {
	if data.len == 0 {
		return 0.0
	}
	return stats.mode(data)
}

// stats_mode delegates to standalone stats_mode.
pub fn (win &SimpleWindow) stats_mode(data []f64) f64 {
	return stats_mode(data)
}

// stats_range returns the difference between maximum and minimum values in a dataset.
pub fn stats_range(data []f64) f64 {
	if data.len == 0 {
		return 0.0
	}
	return stats.range(data)
}

// stats_range delegates to standalone stats_range.
pub fn (win &SimpleWindow) stats_range(data []f64) f64 {
	return stats_range(data)
}

// stats_kurtosis computes the sample kurtosis of a dataset.
pub fn stats_kurtosis(data []f64) f64 {
	if data.len == 0 {
		return 0.0
	}
	return stats.kurtosis(data)
}

// stats_kurtosis delegates to standalone stats_kurtosis.
pub fn (win &SimpleWindow) stats_kurtosis(data []f64) f64 {
	return stats_kurtosis(data)
}

// stats_skew computes the sample skewness of a dataset.
pub fn stats_skew(data []f64) f64 {
	if data.len == 0 {
		return 0.0
	}
	return stats.skew(data)
}

// stats_skew delegates to standalone stats_skew.
pub fn (win &SimpleWindow) stats_skew(data []f64) f64 {
	return stats_skew(data)
}

// stats_covariance computes the sample covariance between two equal-sized datasets.
pub fn stats_covariance(data1 []f64, data2 []f64) f64 {
	if data1.len == 0 || data1.len != data2.len {
		return 0.0
	}
	return stats.covariance(data1, data2)
}

// stats_covariance delegates to standalone stats_covariance.
pub fn (win &SimpleWindow) stats_covariance(data1 []f64, data2 []f64) f64 {
	return stats_covariance(data1, data2)
}

// ==========================================
// 41. Cryptographically Secure Random & UUID (Chapter 13: crypto.rand)
// ==========================================

// crypto_rand_bytes returns a slice of cryptographically secure random bytes of specified length.
pub fn crypto_rand_bytes(length int) []u8 {
	if length <= 0 {
		return []u8{}
	}
	return crand.bytes(length) or { return []u8{len: length} }
}

// crypto_rand_bytes delegates to standalone crypto_rand_bytes.
pub fn (win &SimpleWindow) crypto_rand_bytes(length int) []u8 {
	return crypto_rand_bytes(length)
}

// crypto_rand_hex produces a cryptographically secure hex string token.
pub fn crypto_rand_hex(length int) string {
	b := crypto_rand_bytes(length)
	return hex.encode(b)
}

// crypto_rand_hex delegates to standalone crypto_rand_hex.
pub fn (win &SimpleWindow) crypto_rand_hex(length int) string {
	return crypto_rand_hex(length)
}

// crypto_rand_uuid generates a cryptographically secure UUID v4 string (8-4-4-4-12 hex format).
pub fn crypto_rand_uuid() string {
	mut b := crypto_rand_bytes(16)
	if b.len < 16 {
		return '00000000-0000-4000-8000-000000000000'
	}
	b[6] = (b[6] & u8(0x0f)) | u8(0x40)
	b[8] = (b[8] & u8(0x3f)) | u8(0x80)

	h := hex.encode(b)
	return '${h[0..8]}-${h[8..12]}-${h[12..16]}-${h[16..20]}-${h[20..32]}'
}

// crypto_rand_uuid delegates to standalone crypto_rand_uuid.
pub fn (win &SimpleWindow) crypto_rand_uuid() string {
	return crypto_rand_uuid()
}

// ==========================================
// 42. HMAC Extensions & Fast Hashing (Chapter 13: crypto.hmac, hash)
// ==========================================

// crypto_hmac_sha512 computes the hex-encoded HMAC-SHA512 signature of text with a key.
pub fn crypto_hmac_sha512(text string, key string) string {
	sum := hmac.new(key.bytes(), text.bytes(), sha512.sum512, sha512.block_size)
	return sum.hex()
}

// crypto_hmac_sha512 delegates to standalone crypto_hmac_sha512.
pub fn (win &SimpleWindow) crypto_hmac_sha512(text string, key string) string {
	return crypto_hmac_sha512(text, key)
}

// crypto_hmac_sha1 computes the hex-encoded HMAC-SHA1 signature of text with a key.
pub fn crypto_hmac_sha1(text string, key string) string {
	sum := hmac.new(key.bytes(), text.bytes(), sha1.sum, sha1.block_size)
	return sum.hex()
}

// crypto_hmac_sha1 delegates to standalone crypto_hmac_sha1.
pub fn (win &SimpleWindow) crypto_hmac_sha1(text string, key string) string {
	return crypto_hmac_sha1(text, key)
}

// crypto_wyhash computes a 64-bit Wyhash value of a string with a seed.
pub fn crypto_wyhash(text string, seed u64) u64 {
	return vhash.sum64_string(text, seed)
}

// crypto_wyhash delegates to standalone crypto_wyhash.
pub fn (win &SimpleWindow) crypto_wyhash(text string, seed u64) u64 {
	return crypto_wyhash(text, seed)
}

// ==========================================
// 43. Advanced String Metrics & Utility Functions (Chapter 13: strings)
// ==========================================

// string_jaro_similarity computes Jaro distance similarity between two strings (0.0 to 1.0).
pub fn string_jaro_similarity(s1 string, s2 string) f64 {
	return strings.jaro_similarity(s1, s2)
}

// string_jaro_similarity delegates to standalone string_jaro_similarity.
pub fn (win &SimpleWindow) string_jaro_similarity(s1 string, s2 string) f64 {
	return string_jaro_similarity(s1, s2)
}

// string_jaro_winkler_similarity computes Jaro-Winkler distance similarity (0.0 to 1.0).
pub fn string_jaro_winkler_similarity(s1 string, s2 string) f64 {
	return strings.jaro_winkler_similarity(s1, s2)
}

// string_jaro_winkler_similarity delegates to standalone string_jaro_winkler_similarity.
pub fn (win &SimpleWindow) string_jaro_winkler_similarity(s1 string, s2 string) f64 {
	return string_jaro_winkler_similarity(s1, s2)
}

// string_hamming_distance computes Hamming distance between two equal-length strings.
pub fn string_hamming_distance(s1 string, s2 string) int {
	return strings.hamming_distance(s1, s2)
}

// string_hamming_distance delegates to standalone string_hamming_distance.
pub fn (win &SimpleWindow) string_hamming_distance(s1 string, s2 string) int {
	return string_hamming_distance(s1, s2)
}

// string_between extracts text located between start and end delimiter strings.
pub fn string_between(input string, start string, end string) string {
	return strings.find_between_pair_string(input, start, end)
}

// string_between delegates to standalone string_between.
pub fn (win &SimpleWindow) string_between(input string, start string, end string) string {
	return string_between(input, start, end)
}

// string_pad_left left-pads a string with repeating pad_char characters up to total length.
pub fn string_pad_left(input string, length int, pad_char string) string {
	if input.len >= length || pad_char.len == 0 {
		return input
	}
	pad_len := length - input.len
	mut pad := strings.repeat_string(pad_char, pad_len)
	return pad + input
}

// string_pad_left delegates to standalone string_pad_left.
pub fn (win &SimpleWindow) string_pad_left(input string, length int, pad_char string) string {
	return string_pad_left(input, length, pad_char)
}

// string_pad_right right-pads a string with repeating pad_char characters up to total length.
pub fn string_pad_right(input string, length int, pad_char string) string {
	if input.len >= length || pad_char.len == 0 {
		return input
	}
	pad_len := length - input.len
	mut pad := strings.repeat_string(pad_char, pad_len)
	return input + pad
}

// string_pad_right delegates to standalone string_pad_right.
pub fn (win &SimpleWindow) string_pad_right(input string, length int, pad_char string) string {
	return string_pad_right(input, length, pad_char)
}

// string_repeat repeats a string n times.
pub fn string_repeat(input string, count int) string {
	if count <= 0 {
		return ''
	}
	return strings.repeat_string(input, count)
}

// string_repeat delegates to standalone string_repeat.
pub fn (win &SimpleWindow) string_repeat(input string, count int) string {
	return string_repeat(input, count)
}

// string_count_words counts non-empty space-separated words in a text string.
pub fn string_count_words(input string) int {
	words := input.fields()
	return words.len
}

// string_count_words delegates to standalone string_count_words.
pub fn (win &SimpleWindow) string_count_words(input string) int {
	return string_count_words(input)
}

// ==========================================
// 44. URL Parsing & Assembly Object Model (Chapter 13: net.urllib)
// ==========================================

// SimpleURL holds components of a parsed URL.
pub struct SimpleURL {
pub mut:
	scheme   string
	host     string
	port     string
	path     string
	query    map[string]string
	fragment string
}

// build_url constructs a canonical URL string from the SimpleURL fields.
pub fn (u SimpleURL) build_url() string {
	mut sb := strings.new_builder(128)
	if u.scheme.len > 0 {
		sb.write_string(u.scheme)
		sb.write_string('://')
	}
	sb.write_string(u.host)
	if u.port.len > 0 {
		sb.write_string(':')
		sb.write_string(u.port)
	}
	if u.path.len > 0 {
		if !u.path.starts_with('/') {
			sb.write_string('/')
		}
		sb.write_string(u.path)
	}
	if u.query.len > 0 {
		sb.write_string('?')
		mut parts := []string{}
		for k, v in u.query {
			parts << '${urllib.query_escape(k)}=${urllib.query_escape(v)}'
		}
		sb.write_string(parts.join('&'))
	}
	if u.fragment.len > 0 {
		sb.write_string('#')
		sb.write_string(u.fragment)
	}
	return sb.str()
}

// url_parse parses a raw URL string into a SimpleURL structure.
pub fn url_parse(raw_url string) SimpleURL {
	u := urllib.parse(raw_url) or { return SimpleURL{} }
	mut query_map := map[string]string{}
	q_vals := u.query()
	for k in q_vals.data {
		if v := q_vals.get(k.key) {
			query_map[k.key] = v
		}
	}
	return SimpleURL{
		scheme:   u.scheme
		host:     u.hostname()
		port:     u.port()
		path:     u.path
		query:    query_map
		fragment: u.fragment
	}
}

// url_parse delegates to standalone url_parse.
pub fn (win &SimpleWindow) url_parse(raw_url string) SimpleURL {
	return url_parse(raw_url)
}

// url_build constructs a URL from scheme, host, path, and query parameter map.
pub fn url_build(scheme string, host string, path string, query_params map[string]string) string {
	su := SimpleURL{
		scheme: scheme
		host:   host
		path:   path
		query:  query_params
	}
	return su.build_url()
}

// url_build delegates to standalone url_build.
pub fn (win &SimpleWindow) url_build(scheme string, host string, path string, query_params map[string]string) string {
	return url_build(scheme, host, path, query_params)
}

// ==========================================
// 45. Enhanced HTML Document Parsing & Inspection (Chapter 13: net.html)
// ==========================================

// get_attr retrieves an attribute value of the first matching HTML tag name.
pub fn (d &SimpleHTMLDocument) get_attr(tag_name string, attr_name string) string {
	tags := d.doc.get_tags(name: tag_name)
	if tags.len > 0 {
		return tags[0].attributes[attr_name]
	}
	return ''
}

// get_all_links extracts all href links from <a> tags in the HTML document.
pub fn (d &SimpleHTMLDocument) get_all_links() []string {
	tags := d.doc.get_tags(name: 'a')
	mut links := []string{}
	for t in tags {
		if href := t.attributes['href'] {
			links << href
		}
	}
	return links
}

// get_all_images extracts all image src URLs from <img> tags in the HTML document.
pub fn (d &SimpleHTMLDocument) get_all_images() []string {
	tags := d.doc.get_tags(name: 'img')
	mut imgs := []string{}
	for t in tags {
		if src := t.attributes['src'] {
			imgs << src
		}
	}
	return imgs
}

// strip_tags removes HTML tags from the document, returning plain text content.
pub fn (d &SimpleHTMLDocument) strip_tags() string {
	root := d.doc.get_root()
	if root != unsafe { nil } {
		return root.text().trim_space()
	}
	return ''
}

// ==========================================
// 46. CSV Matrix Column Manipulation (Chapter 13: encoding.csv)
// ==========================================

// csv_extract_column extracts all row values belonging to a specific zero-based column index.
pub fn csv_extract_column(rows [][]string, col_idx int) []string {
	mut res := []string{}
	for row in rows {
		if col_idx >= 0 && col_idx < row.len {
			res << row[col_idx]
		}
	}
	return res
}

// csv_extract_column delegates to standalone csv_extract_column.
pub fn (win &SimpleWindow) csv_extract_column(rows [][]string, col_idx int) []string {
	return csv_extract_column(rows, col_idx)
}

// csv_filter_by_column returns only CSV rows where a column matches a given search string.
pub fn csv_filter_by_column(rows [][]string, col_idx int, search_term string) [][]string {
	mut filtered := [][]string{}
	for row in rows {
		if col_idx >= 0 && col_idx < row.len {
			if row[col_idx] == search_term {
				filtered << row
			}
		}
	}
	return filtered
}

// csv_filter_by_column delegates to standalone csv_filter_by_column.
pub fn (win &SimpleWindow) csv_filter_by_column(rows [][]string, col_idx int, search_term string) [][]string {
	return csv_filter_by_column(rows, col_idx, search_term)
}

// ==========================================
// 47. MinHeap Priority Queue Data Structure (Chapter 13: datatypes)
// ==========================================

// SimpleMinHeap provides a high-level min-heap priority queue collection.
pub struct SimpleMinHeap[T] {
mut:
	heap datatypes.MinHeap[T]
}

// push inserts an item into the min-heap.
pub fn (mut smh SimpleMinHeap[T]) push(item T) {
	smh.heap.insert(item)
}

// pop removes and returns the smallest item from the min-heap, or errors if empty.
pub fn (mut smh SimpleMinHeap[T]) pop() !T {
	return smh.heap.pop()
}

// peek returns the smallest item from the min-heap without removing it, or errors if empty.
pub fn (smh &SimpleMinHeap[T]) peek() !T {
	return smh.heap.peek()
}

// len returns the total number of items stored in the min-heap.
pub fn (smh &SimpleMinHeap[T]) len() int {
	return smh.heap.len()
}

// new_min_heap instantiates a new generic SimpleMinHeap.
pub fn new_min_heap[T]() SimpleMinHeap[T] {
	return SimpleMinHeap[T]{}
}

// ==========================================
// 48. Extended Time & Calendar Utilities (Chapter 13: time)
// ==========================================

// time_unix_timestamp returns the current Unix epoch timestamp in seconds.
pub fn time_unix_timestamp() i64 {
	return time.now().unix()
}

// time_unix_timestamp delegates to standalone time_unix_timestamp.
pub fn (win &SimpleWindow) time_unix_timestamp() i64 {
	return time_unix_timestamp()
}

// time_from_unix formats a Unix epoch timestamp (seconds) into standard YYYY-MM-DD HH:MM:SS string.
pub fn time_from_unix(timestamp i64) string {
	t := time.unix(timestamp)
	return t.custom_format('YYYY-MM-DD HH:mm:ss')
}

// time_from_unix delegates to standalone time_from_unix.
pub fn (win &SimpleWindow) time_from_unix(timestamp i64) string {
	return time_from_unix(timestamp)
}

// time_is_leap_year returns true if the specified year is a leap year.
pub fn time_is_leap_year(year int) bool {
	return time.is_leap_year(year)
}

// time_is_leap_year delegates to standalone time_is_leap_year.
pub fn (win &SimpleWindow) time_is_leap_year(year int) bool {
	return time_is_leap_year(year)
}

// time_days_in_month returns the total number of days in a specific year and month (1-12).
pub fn time_days_in_month(year int, month int) int {
	return time.days_in_month(month, year) or { 30 }
}

// is_valid_date_str validates that a date string adheres strictly to YYYY-MM-DD format with a valid calendar date.
pub fn is_valid_date_str(date_str string) bool {
	parts := date_str.split('-')
	if parts.len != 3 {
		return false
	}
	if parts[0].len != 4 || parts[1].len != 2 || parts[2].len != 2 {
		return false
	}
	year := parts[0].int()
	month := parts[1].int()
	day := parts[2].int()

	if year < 1000 || year > 9999 {
		return false
	}
	if month < 1 || month > 12 {
		return false
	}
	max_days := time_days_in_month(year, month)
	if day < 1 || day > max_days {
		return false
	}
	return true
}

// is_valid_date_str delegates to standalone is_valid_date_str.
pub fn (win &SimpleWindow) is_valid_date_str(date_str string) bool {
	return is_valid_date_str(date_str)
}

// is_valid_time_str validates that a time string adheres strictly to HH:MM (24-hour) format.
pub fn is_valid_time_str(time_str string) bool {
	parts := time_str.split(':')
	if parts.len != 2 {
		return false
	}
	if parts[0].len != 2 || parts[1].len != 2 {
		return false
	}
	h := parts[0].int()
	m := parts[1].int()
	return h >= 0 && h <= 23 && m >= 0 && m <= 59
}

// is_valid_time_str delegates to standalone is_valid_time_str.
pub fn (win &SimpleWindow) is_valid_time_str(time_str string) bool {
	return is_valid_time_str(time_str)
}


// ==========================================
// 49. JSON Formatting & Validation Utilities (Chapter 13: json)
// ==========================================

// json_validate checks if a string contains valid JSON syntax by testing map decoding.
pub fn json_validate(json_str string) bool {
	_ := json2.decode[map[string]string](json_str) or { return false }
	return true
}

// json_validate delegates to standalone json_validate.
pub fn (win &SimpleWindow) json_validate(json_str string) bool {
	return json_validate(json_str)
}

// json_pretty_print formats a flat key-value map JSON string with clean line indents.
pub fn json_pretty_print(json_str string) string {
	m := json2.decode[map[string]string](json_str) or { return json_str }
	mut sb := strings.new_builder(128)
	sb.writeln('{')
	mut count := 0
	for k, v in m {
		count++
		comma := if count < m.len { ',' } else { '' }
		sb.writeln('  "${k}": "${v}"${comma}')
	}
	sb.writeln('}')
	return sb.str()
}

// json_pretty_print delegates to standalone json_pretty_print.
pub fn (win &SimpleWindow) json_pretty_print(json_str string) string {
	return json_pretty_print(json_str)
}

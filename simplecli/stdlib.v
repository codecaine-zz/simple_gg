// Module simplecli - Headless Console & RAD Toolkit for V
// File: stdlib.v
//
// Description:
//   This file provides high-level standard library wrapper utilities for HTTP client requests,
//   JSON serialization/querying, AES encryption/decryption, SHA256/SHA512/MD5/BCrypt hashing,
//   Base64/Hex encoding, RegEx matching, Gzip compression, CSV/TOML parsing, Math statistics,
//   generic data collections (Stack, Queue, Set, RingBuffer, MinHeap), validation helpers,
//   URL parsing, and string metric algorithms.

module simplecli

import net.http
import net.urllib
import regex
import compress.gzip
import crypto.sha256
import crypto.sha512
import crypto.sha1
import crypto.md5
import crypto.aes
import crypto.cipher
import crypto.bcrypt
import crypto.hmac
import rand
import json2
import encoding.hex
import encoding.base64
import encoding.csv
import toml
import semver
import math
import math.stats
import strings

// =============================================================================
// 1. HTTP Client Utilities & URL Parser
// =============================================================================

// SimpleHttpResponse contains status code, response body, and raw headers.
pub struct SimpleHttpResponse {
pub:
	status_code int
	body        string
	url         string
}

// SimpleURL represents a structured, parsed URL.
pub struct SimpleURL {
pub:
	raw      string
	scheme   string
	host     string
	port     int
	path     string
	query    string
	fragment string
}

// parse_url parses an absolute or relative URL string.
pub fn (cli &SimpleCli) parse_url(url_str string) !SimpleURL {
	u := urllib.parse(url_str)!
	return SimpleURL{
		raw: url_str
		scheme: u.scheme
		host: u.hostname()
		port: u.port().int()
		path: u.path
		query: u.raw_query
		fragment: u.fragment
	}
}

// http_get sends a synchronous GET request and returns the response body or empty string.
pub fn (cli &SimpleCli) http_get(url string) string {
	res := http.get(url) or { return '' }
	return res.body
}

// http_post sends a synchronous POST request with the specified payload.
pub fn (cli &SimpleCli) http_post(url string, data string) string {
	res := http.post(url, data) or { return '' }
	return res.body
}

// http_request sends a custom HTTP request (GET, POST, PUT, DELETE) and returns structured response.
pub fn (cli &SimpleCli) http_request(method string, url string, body string) !SimpleHttpResponse {
	req_method := match method.to_upper() {
		'POST' { http.Method.post }
		'PUT' { http.Method.put }
		'DELETE' { http.Method.delete }
		'PATCH' { http.Method.patch }
		'HEAD' { http.Method.head }
		else { http.Method.get }
	}
	mut req := http.new_request(req_method, url, body)
	res := req.do()!
	return SimpleHttpResponse{
		status_code: res.status_code
		body: res.body
		url: url
	}
}

// http_download downloads a remote URL directly to a local destination file.
pub fn (cli &SimpleCli) http_download(url string, dest_file string) !&SimpleCli {
	content := cli.http_get(url)
	if content.len == 0 {
		return error('Failed to download content from ${url}')
	}
	cli.write_file(dest_file, content)
	return cli
}

// =============================================================================
// 2. Cryptography, Hashing & Security
// =============================================================================

// crypto_sha256 computes the SHA-256 hexadecimal hash digest of a string.
pub fn (cli &SimpleCli) crypto_sha256(text string) string {
	return sha256.hexhash(text)
}

// crypto_sha512 computes the SHA-512 hexadecimal hash digest of a string.
pub fn (cli &SimpleCli) crypto_sha512(text string) string {
	return sha512.hexhash(text)
}

// crypto_sha1 computes the SHA-1 hexadecimal hash digest of a string.
pub fn (cli &SimpleCli) crypto_sha1(text string) string {
	return sha1.hexhash(text)
}

// crypto_md5 computes the MD5 hexadecimal hash digest of a string.
pub fn (cli &SimpleCli) crypto_md5(text string) string {
	return md5.hexhash(text)
}

// crypto_hmac_sha256 calculates an HMAC-SHA256 signature using a secret key.
pub fn (cli &SimpleCli) crypto_hmac_sha256(key string, data string) string {
	sum := hmac.new(key.bytes(), data.bytes(), sha256.sum, sha256.block_size)
	return hex.encode(sum)
}

// crypto_bcrypt_hash hashes a password string with bcrypt.
pub fn (cli &SimpleCli) crypto_bcrypt_hash(password string) !string {
	return bcrypt.generate_from_password(password.bytes(), 10)!
}

// crypto_bcrypt_verify verifies a plaintext password against a bcrypt hash.
pub fn (cli &SimpleCli) crypto_bcrypt_verify(password string, hash string) bool {
	bcrypt.compare_hash_and_password(password.bytes(), hash.bytes()) or { return false }
	return true
}

// crypto_aes_encrypt encrypts plaintext using AES-256-CTR with a 32-byte key.
pub fn (cli &SimpleCli) crypto_aes_encrypt(key_str string, plaintext string) !string {
	key_hash := sha256.sum(key_str.bytes())
	block := aes.new_cipher(key_hash)
	iv := rand.bytes(aes.block_size) or { return error('Failed to generate random IV') }
	mut stream := cipher.new_ctr(block, iv)
	mut ciphertext := []u8{len: plaintext.len}
	stream.xor_key_stream(mut ciphertext, plaintext.bytes())
	
	mut combined := []u8{cap: iv.len + ciphertext.len}
	combined << iv
	combined << ciphertext
	return base64.encode(combined)
}

// crypto_aes_decrypt decrypts base64-encoded AES-256-CTR ciphertext.
pub fn (cli &SimpleCli) crypto_aes_decrypt(key_str string, b64_ciphertext string) !string {
	combined := base64.decode(b64_ciphertext)
	if combined.len < aes.block_size {
		return error('Ciphertext payload is too short')
	}
	iv := combined[..aes.block_size]
	cipher_bytes := combined[aes.block_size..]
	key_hash := sha256.sum(key_str.bytes())
	block := aes.new_cipher(key_hash)
	mut stream := cipher.new_ctr(block, iv)
	mut plaintext := []u8{len: cipher_bytes.len}
	stream.xor_key_stream(mut plaintext, cipher_bytes)
	return plaintext.bytestr()
}

// rand_uuid generates a standard UUID v4 string.
pub fn (cli &SimpleCli) rand_uuid() string {
	b := rand.bytes(16) or { return '00000000-0000-4000-8000-000000000000' }
	mut bytes := b.clone()
	bytes[6] = (bytes[6] & 0x0f) | 0x40
	bytes[8] = (bytes[8] & 0x3f) | 0x80
	h := hex.encode(bytes)
	return '${h[0..8]}-${h[8..12]}-${h[12..16]}-${h[16..20]}-${h[20..32]}'
}

// rand_string generates a random alphanumeric string of length n.
pub fn (cli &SimpleCli) rand_string(length int) string {
	chars := 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
	mut out := ''
	for _ in 0 .. length {
		idx := rand.int_in_range(0, chars.len) or { 0 }
		out += chars[idx..idx + 1]
	}
	return out
}

// rand_int returns a random integer in the range [min, max).
pub fn (cli &SimpleCli) rand_int(min int, max int) int {
	return rand.int_in_range(min, max) or { min }
}

// rand_f64 returns a random float in the range [0.0, 1.0).
pub fn (cli &SimpleCli) rand_f64() f64 {
	return rand.f64()
}

// =============================================================================
// 3. Encodings, JSON & Data Validation
// =============================================================================

// base64_encode encodes text to Base64.
pub fn (cli &SimpleCli) base64_encode(text string) string {
	return base64.encode(text.bytes())
}

// base64_decode decodes a Base64 string.
pub fn (cli &SimpleCli) base64_decode(b64 string) string {
	return base64.decode_str(b64)
}

// hex_encode encodes text to hexadecimal.
pub fn (cli &SimpleCli) hex_encode(text string) string {
	return hex.encode(text.bytes())
}

// hex_decode decodes a hexadecimal string.
pub fn (cli &SimpleCli) hex_decode(hex_str string) string {
	bytes := hex.decode(hex_str) or { return '' }
	return bytes.bytestr()
}

// json_pretty formats a key-value JSON string with clean line indentation.
pub fn (cli &SimpleCli) json_pretty(json_str string) string {
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

// json_get_string extracts a top-level string property from a raw JSON string.
pub fn (cli &SimpleCli) json_get_string(raw_json string, key string, fallback string) string {
	obj := json2.decode[json2.Any](raw_json) or { return fallback }
	if obj is map[string]json2.Any {
		m := obj as map[string]json2.Any
		if key in m {
			val := m[key] or { return fallback }
			if val is string {
				return val as string
			}
			return val.str()
		}
	}
	return fallback
}

// json_get_int extracts a top-level integer property from a raw JSON string.
pub fn (cli &SimpleCli) json_get_int(raw_json string, key string, fallback int) int {
	obj := json2.decode[json2.Any](raw_json) or { return fallback }
	if obj is map[string]json2.Any {
		m := obj as map[string]json2.Any
		if key in m {
			val := m[key] or { return fallback }
			if val is int {
				return val as int
			} else if val is i64 {
				return int(val as i64)
			} else if val is f64 {
				return int(val as f64)
			}
			return val.str().int()
		}
	}
	return fallback
}

// json_get_bool extracts a top-level boolean property from a raw JSON string.
pub fn (cli &SimpleCli) json_get_bool(raw_json string, key string, fallback bool) bool {
	obj := json2.decode[json2.Any](raw_json) or { return fallback }
	if obj is map[string]json2.Any {
		m := obj as map[string]json2.Any
		if key in m {
			val := m[key] or { return fallback }
			if val is bool {
				return val as bool
			}
			s := val.str().to_lower()
			return s == 'true' || s == '1' || s == 'yes'
		}
	}
	return fallback
}

// validate_email verifies whether a string matches standard email syntax.
pub fn (cli &SimpleCli) validate_email(email string) bool {
	return cli.regex_match(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$', email.trim_space())
}

// validate_url checks whether a string is a valid HTTP/HTTPS URL.
pub fn (cli &SimpleCli) validate_url(url_str string) bool {
	return url_str.starts_with('http://') || url_str.starts_with('https://')
}

// validate_ip checks if a string is a valid IPv4 address.
pub fn (cli &SimpleCli) validate_ip(ip_str string) bool {
	parts := ip_str.split('.')
	if parts.len != 4 {
		return false
	}
	for p in parts {
		n := p.int()
		if p.len == 0 || n < 0 || n > 255 || (p.len > 1 && p.starts_with('0')) {
			return false
		}
	}
	return true
}

// validate_phone checks if a string is a valid international/national phone number.
pub fn (cli &SimpleCli) validate_phone(phone string) bool {
	clean := phone.replace(' ', '').replace('-', '').replace('(', '').replace(')', '').replace('+', '')
	return clean.len >= 7 && clean.len <= 15 && clean.int() > 0
}

// validate_alphanumeric checks if text contains only letters and numbers.
pub fn (cli &SimpleCli) validate_alphanumeric(text string) bool {
	return cli.regex_match(r'^[a-zA-Z0-9]+$', text)
}

// validate_numeric_range checks if a number is within [min, max].
pub fn (cli &SimpleCli) validate_numeric_range(val f64, min f64, max f64) bool {
	return val >= min && val <= max
}

// validate_length checks if string length is within [min_len, max_len].
pub fn (cli &SimpleCli) validate_length(text string, min_len int, max_len int) bool {
	return text.len >= min_len && text.len <= max_len
}

// =============================================================================
// 4. Data Formats & Parsing (CSV, TOML, Gzip, RegEx, Lorem)
// =============================================================================

// csv_parse parses a CSV string into a 2D array of rows and column cells.
pub fn (cli &SimpleCli) csv_parse(csv_content string) [][]string {
	mut reader := csv.new_reader(csv_content)
	mut rows := [][]string{}
	for {
		row := reader.read() or { break }
		rows << row
	}
	return rows
}

// toml_parse parses TOML text into a toml.Doc.
pub fn (cli &SimpleCli) toml_parse(toml_content string) !toml.Doc {
	return toml.parse_text(toml_content)!
}

// gzip_compress compresses data using Gzip.
pub fn (cli &SimpleCli) gzip_compress(data string) ![]u8 {
	return gzip.compress(data.bytes())!
}

// gzip_decompress decompresses Gzip compressed bytes back to text.
pub fn (cli &SimpleCli) gzip_decompress(bytes []u8) !string {
	decompressed := gzip.decompress(bytes)!
	return decompressed.bytestr()
}

// regex_match checks if a regular expression matches the input string.
pub fn (cli &SimpleCli) regex_match(pattern string, text string) bool {
	mut query := regex.regex_opt(pattern) or { return false }
	return query.matches_string(text)
}

// semver_compare compares two semantic version strings (-1 if v1 < v2, 0 if equal, 1 if v1 > v2).
pub fn (cli &SimpleCli) semver_compare(v1 string, v2 string) !int {
	ver1 := semver.from(v1)!
	ver2 := semver.from(v2)!
	if ver1 < ver2 {
		return -1
	} else if ver1 > ver2 {
		return 1
	}
	return 0
}

// lorem_words generates placeholder words.
pub fn (cli &SimpleCli) lorem_words(count int) string {
	sample := ['lorem', 'ipsum', 'dolor', 'sit', 'amet', 'consectetur', 'adipiscing', 'elit', 'sed', 'do', 'eiusmod', 'tempor', 'incididunt', 'ut', 'labore', 'et', 'dolore', 'magna', 'aliqua']
	mut out := []string{}
	for i in 0 .. count {
		out << sample[i % sample.len]
	}
	return out.join(' ')
}

// =============================================================================
// 5. Generic Collections & Data Structures
// =============================================================================

// SimpleStack provides a generic LIFO stack data structure.
pub struct SimpleStack[T] {
pub mut:
	items []T
}

// new_stack creates an empty generic stack.
pub fn new_stack[T]() SimpleStack[T] {
	return SimpleStack[T]{}
}

// push pushes an element onto the stack.
pub fn (mut s SimpleStack[T]) push(item T) {
	s.items << item
}

// pop removes and returns the top element from the stack.
pub fn (mut s SimpleStack[T]) pop() ?T {
	if s.items.len == 0 {
		return none
	}
	return s.items.pop()
}

// peek returns the top element without removing it.
pub fn (s SimpleStack[T]) peek() ?T {
	if s.items.len == 0 {
		return none
	}
	return s.items.last()
}

// is_empty returns true if the stack contains no elements.
pub fn (s SimpleStack[T]) is_empty() bool {
	return s.items.len == 0
}

// len returns the number of elements in the stack.
pub fn (s SimpleStack[T]) len() int {
	return s.items.len
}

// SimpleQueue provides a generic FIFO queue data structure.
pub struct SimpleQueue[T] {
pub mut:
	items []T
}

// new_queue creates an empty generic queue.
pub fn new_queue[T]() SimpleQueue[T] {
	return SimpleQueue[T]{}
}

// push enqueues an element to the back of the queue.
pub fn (mut q SimpleQueue[T]) push(item T) {
	q.items << item
}

// pop dequeues and returns the front element of the queue.
pub fn (mut q SimpleQueue[T]) pop() ?T {
	if q.items.len == 0 {
		return none
	}
	first := q.items[0]
	q.items.delete(0)
	return first
}

// peek returns the front element without removing it.
pub fn (q SimpleQueue[T]) peek() ?T {
	if q.items.len == 0 {
		return none
	}
	return q.items[0]
}

// is_empty returns true if the queue contains no elements.
pub fn (q SimpleQueue[T]) is_empty() bool {
	return q.items.len == 0
}

// len returns the number of elements in the queue.
pub fn (q SimpleQueue[T]) len() int {
	return q.items.len
}

// SimpleRingBuffer provides a fixed-capacity circular ring buffer.
pub struct SimpleRingBuffer[T] {
pub:
	capacity int
pub mut:
	items []T
	head  int
}

// new_ring_buffer creates a new circular buffer with fixed max capacity.
pub fn new_ring_buffer[T](capacity int) SimpleRingBuffer[T] {
	return SimpleRingBuffer[T]{
		capacity: if capacity > 0 { capacity } else { 16 }
	}
}

// push appends an item, discarding the oldest element if at capacity.
pub fn (mut r SimpleRingBuffer[T]) push(item T) {
	if r.items.len < r.capacity {
		r.items << item
	} else {
		r.items[r.head] = item
		r.head = (r.head + 1) % r.capacity
	}
}

// len returns current number of items.
pub fn (r SimpleRingBuffer[T]) len() int {
	return r.items.len
}

// SimpleMinHeap provides a lightweight min-heap priority queue of floats.
pub struct SimpleMinHeap {
pub mut:
	items []f64
}

// new_min_heap initializes an empty min-heap.
pub fn new_min_heap() SimpleMinHeap {
	return SimpleMinHeap{}
}

// push inserts a float value maintaining heap order.
pub fn (mut h SimpleMinHeap) push(val f64) {
	h.items << val
	mut i := h.items.len - 1
	for i > 0 {
		parent := (i - 1) / 2
		if h.items[i] >= h.items[parent] {
			break
		}
		tmp := h.items[i]
		h.items[i] = h.items[parent]
		h.items[parent] = tmp
		i = parent
	}
}

// pop extracts and returns the minimum element.
pub fn (mut h SimpleMinHeap) pop() ?f64 {
	if h.items.len == 0 {
		return none
	}
	min := h.items[0]
	last := h.items.pop()
	if h.items.len > 0 {
		h.items[0] = last
		mut i := 0
		for {
			left := 2 * i + 1
			right := 2 * i + 2
			mut smallest := i
			if left < h.items.len && h.items[left] < h.items[smallest] {
				smallest = left
			}
			if right < h.items.len && h.items[right] < h.items[smallest] {
				smallest = right
			}
			if smallest == i {
				break
			}
			tmp := h.items[i]
			h.items[i] = h.items[smallest]
			h.items[smallest] = tmp
			i = smallest
		}
	}
	return min
}

// =============================================================================
// 6. String Distance & Similarity Algorithms
// =============================================================================

// levenshtein_distance computes the edit distance between two strings.
pub fn (cli &SimpleCli) levenshtein_distance(a string, b string) int {
	if a == b { return 0 }
	if a.len == 0 { return b.len }
	if b.len == 0 { return a.len }

	mut d := [][]int{len: a.len + 1, init: []int{len: b.len + 1, init: 0}}
	for i in 0 .. a.len + 1 { d[i][0] = i }
	for j in 0 .. b.len + 1 { d[0][j] = j }

	for i in 1 .. a.len + 1 {
		for j in 1 .. b.len + 1 {
			cost := if a[i - 1] == b[j - 1] { 0 } else { 1 }
			d[i][j] = math.min(math.min(d[i - 1][j] + 1, d[i][j - 1] + 1), d[i - 1][j - 1] + cost)
		}
	}
	return d[a.len][b.len]
}

// similarity_ratio calculates a float similarity between 0.0 (unrelated) and 1.0 (identical).
pub fn (cli &SimpleCli) similarity_ratio(a string, b string) f64 {
	if a == b { return 1.0 }
	max_len := math.max(a.len, b.len)
	if max_len == 0 { return 1.0 }
	dist := cli.levenshtein_distance(a, b)
	return 1.0 - (f64(dist) / f64(max_len))
}

// =============================================================================
// 7. Math & Statistical Utilities
// =============================================================================

// stats_mean computes the arithmetic mean of an array of floats.
pub fn (cli &SimpleCli) stats_mean(data []f64) f64 {
	return stats.mean(data)
}

// stats_median computes the median value of an array of floats.
pub fn (cli &SimpleCli) stats_median(data []f64) f64 {
	return stats.median(data)
}

// stats_std_dev computes the sample standard deviation.
pub fn (cli &SimpleCli) stats_std_dev(data []f64) f64 {
	return stats.sample_stddev(data)
}

// stats_geometric_mean computes the geometric mean of positive numbers.
pub fn (cli &SimpleCli) stats_geometric_mean(data []f64) f64 {
	return stats.geometric_mean(data)
}

// stats_harmonic_mean computes the harmonic mean of positive numbers.
pub fn (cli &SimpleCli) stats_harmonic_mean(data []f64) f64 {
	return stats.harmonic_mean(data)
}

// stats_rms computes the Root Mean Square of an array of numbers.
pub fn (cli &SimpleCli) stats_rms(data []f64) f64 {
	return stats.rms(data)
}

// stats_min returns the minimum float in an array.
pub fn (cli &SimpleCli) stats_min(data []f64) f64 {
	return stats.min(data)
}

// stats_max returns the maximum float in an array.
pub fn (cli &SimpleCli) stats_max(data []f64) f64 {
	return stats.max(data)
}

// =============================================================================
// 8. Standalone Package-Level Stdlib Functions (1-liners)
// =============================================================================

// http_get sends a GET request and returns response body.
pub fn http_get(url string) string {
	res := http.get(url) or { return '' }
	return res.body
}

// http_post sends a POST request with body and returns response.
pub fn http_post(url string, data string) string {
	res := http.post(url, data) or { return '' }
	return res.body
}

// crypto_sha256 computes SHA-256 hash.
pub fn crypto_sha256(text string) string {
	return sha256.hexhash(text)
}

// rand_uuid generates a UUID v4 string.
pub fn rand_uuid() string {
	cli := new('SimpleCli')
	return cli.rand_uuid()
}

// base64_encode encodes string to base64.
pub fn base64_encode(text string) string {
	return base64.encode(text.bytes())
}

// base64_decode decodes base64 string.
pub fn base64_decode(b64 string) string {
	return base64.decode_str(b64)
}

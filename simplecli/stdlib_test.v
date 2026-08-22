module simplecli

fn test_stdlib_crypto_and_encoding() {
	app := new('StdlibTest')

	// SHA256 & MD5
	hash256 := app.crypto_sha256('antigravity')
	assert hash256.len == 64
	assert hash256 == 'ac0a3dfd6dddb20962cecff6ee5fe65e19d3923be20e52c5ab52ff877f7e4c32'

	hash_md5 := app.crypto_md5('antigravity')
	assert hash_md5.len == 32

	// Base64
	b64 := app.base64_encode('Hello SimpleCLI')
	decoded := app.base64_decode(b64)
	assert decoded == 'Hello SimpleCLI'

	// Hex
	hex_str := app.hex_encode('SimpleCLI')
	raw_str := app.hex_decode(hex_str)
	assert raw_str == 'SimpleCLI'

	// UUID & Random
	uuid_str := app.rand_uuid()
	assert uuid_str.len == 36
	assert uuid_str.contains('-')

	rnd_s := app.rand_string(12)
	assert rnd_s.len == 12

	rnd_i := app.rand_int(10, 20)
	assert rnd_i >= 10 && rnd_i < 20
}

fn test_stdlib_collections_and_string_metrics() {
	app := new('CollectionsTest')

	// SimpleStack
	mut stack := new_stack[int]()
	assert stack.is_empty()
	stack.push(10)
	stack.push(20)
	assert stack.len() == 2
	assert stack.peek() or { 0 } == 20
	assert stack.pop() or { 0 } == 20
	assert stack.pop() or { 0 } == 10
	assert stack.is_empty()

	// SimpleQueue
	mut queue := new_queue[string]()
	assert queue.is_empty()
	queue.push('first')
	queue.push('second')
	assert queue.len() == 2
	assert queue.peek() or { '' } == 'first'
	assert queue.pop() or { '' } == 'first'
	assert queue.pop() or { '' } == 'second'
	assert queue.is_empty()

	// Levenshtein & Similarity Ratio
	dist := app.levenshtein_distance('kitten', 'sitting')
	assert dist == 3

	ratio := app.similarity_ratio('simplecli', 'simplecli')
	assert ratio == 1.0

	// JSON Field Extraction
	raw_json := '{"service": "auth_api", "port": 5000, "enabled": true}'
	assert app.json_get_string(raw_json, 'service', '') == 'auth_api'
	assert app.json_get_int(raw_json, 'port', 0) == 5000
	assert app.json_get_bool(raw_json, 'enabled', false) == true
}

fn test_stdlib_aes_encryption() {
	app := new('AesTest')
	key := 'my_super_secret_key_1234567890!'
	plaintext := 'Confidential RAD data payload'

	ciphertext := app.crypto_aes_encrypt(key, plaintext) or { panic(err) }
	assert ciphertext.len > 0

	decrypted := app.crypto_aes_decrypt(key, ciphertext) or { panic(err) }
	assert decrypted == plaintext
}

fn test_stdlib_math_stats() {
	app := new('MathTest')
	data := [10.0, 20.0, 30.0, 40.0, 50.0]

	mean := app.stats_mean(data)
	assert mean == 30.0

	min_v := app.stats_min(data)
	max_v := app.stats_max(data)
	assert min_v == 10.0
	assert max_v == 50.0
}

fn test_stdlib_semver_and_regex() {
	app := new('SemverTest')

	cmp1 := app.semver_compare('1.0.0', '1.1.0') or { panic(err) }
	assert cmp1 == -1

	cmp2 := app.semver_compare('2.0.0', '1.9.9') or { panic(err) }
	assert cmp2 == 1

	matched := app.regex_match(r'^\d{3}-\d{2}-\d{4}$', '123-45-6789')
	assert matched == true
}

module cryptoutils

fn test_hashing() {
	// Standard test vectors
	// MD5("hello") = 5d41402abc4b2a76b9719d911017c592
	assert md5('hello') == '5d41402abc4b2a76b9719d911017c592'

	// SHA256("hello") = 2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824
	assert sha256('hello') == '2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824'

	// SHA512("hello") length is 128 hex chars
	h512 := sha512('hello')
	assert h512.len == 128

	// HMAC-SHA256
	hm := hmac_sha256('secret', 'message')
	assert hm.len == 64
}

fn test_base64() {
	orig := 'Hello, V developer!'
	encoded := base64_encode(orig)
	assert encoded == 'SGVsbG8sIFYgZGV2ZWxvcGVyIQ=='

	decoded := base64_decode(encoded) or { '' }
	assert decoded == orig

	url_enc := base64_url_encode(orig)
	url_dec := base64_url_decode(url_enc) or { '' }
	assert url_dec == orig
}

fn test_hex_conversion() {
	bytes := [u8(0xde), u8(0xad), u8(0xbe), u8(0xef)]
	h := to_hex(bytes)
	assert h.to_lower() == 'deadbeef'

	decoded := from_hex('deadbeef') or { []u8{} }
	assert decoded == bytes
}

fn test_uuid_v4() {
	uuid := uuid_v4()
	assert uuid.len == 36
	assert is_valid_uuid(uuid)
	assert is_valid_uuid('123e4567-e89b-12d3-a456-426614174000')
	assert !is_valid_uuid('invalid-uuid-string')
	assert !is_valid_uuid('123e4567-e89b-12d3-a456-42661417400Z')

	// Test secure token
	token := secure_token(16)
	assert token.len == 32
}

fn test_aes_encryption() {
	key := [u8(1), 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23,
		24, 25, 26, 27, 28, 29, 30, 31, 32]
	iv := [u8(10), 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150, 160]

	plaintext := 'High level abstractions in V language'
	cipher := aes_encrypt_string(key, iv, plaintext) or { panic(err) }
	assert cipher.len > 0
	assert cipher.len % 16 == 0

	decrypted := aes_decrypt_string(key, iv, cipher) or { panic(err) }
	assert decrypted == plaintext
}

fn test_bcrypt_and_entropy() {
	pass := 'my_secure_p@ssw0rd'
	hashed := bcrypt_hash(pass) or { panic(err) }
	assert hashed.starts_with('$2')
	assert bcrypt_verify(pass, hashed) == true
	assert bcrypt_verify('wrong_pass', hashed) == false

	bytes := secure_random_bytes(16) or { panic(err) }
	assert bytes.len == 16
	hex_token := secure_random_hex(16) or { panic(err) }
	assert hex_token.len == 32
}

fn test_fast_hashes_and_ed25519() {
	f := fnv1a_32('test payload')
	assert f > 0

	c := crc32_hash('test payload')
	assert c > 0

	pub_k, priv_k := generate_ed25519_keypair() or { panic(err) }
	msg := 'signed message'.bytes()
	sig := ed25519_sign(priv_k, msg) or { panic(err) }
	assert ed25519_verify(pub_k, msg, sig) == true
	assert ed25519_verify(pub_k, 'tampered'.bytes(), sig) == false
}

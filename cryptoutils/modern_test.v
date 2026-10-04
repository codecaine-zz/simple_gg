module cryptoutils

import os

fn test_tokens_use_csprng_and_are_well_formed() {
	t := secure_token(16)
	assert t.len == 32
	assert secure_token(16) != t
	u := uuid_v4()
	assert is_valid_uuid(u)
	assert uuid_version(u)? == 4
}

fn test_seal_open_roundtrip_and_tamper_detection() {
	key := generate_key()
	sealed := seal(key, 'top secret'.bytes())!
	assert open(key, sealed)!.bytestr() == 'top secret'
	// Same plaintext encrypts differently each time (random IV).
	assert seal(key, 'top secret'.bytes())! != sealed
	mut tampered := sealed.clone()
	tampered[20] ^= 0x01
	if _ := open(key, tampered) {
		assert false, 'tampering must be detected'
	}
	if _ := open(generate_key(), sealed) {
		assert false, 'wrong key must fail'
	}
	tok := seal_string(key, 'héllo')!
	assert open_string(key, tok)! == 'héllo'
	if _ := seal([]u8{len: 4}, 'x'.bytes()) {
		assert false, 'short keys rejected'
	}
}

fn test_hotp_rfc4226_vectors() {
	secret := '12345678901234567890'.bytes()
	expected := ['755224', '287082', '359152', '969429', '338314', '254676', '287922', '162583',
		'399871', '520489']
	for i, code in expected {
		assert hotp(secret, u64(i), 6)! == code
	}
}

fn test_totp_rfc6238_vectors() {
	// RFC 6238 SHA1 secret "12345678901234567890" in Base32.
	b32 := 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ'
	assert totp_at(b32, 59, 8)! == '94287082'
	assert totp_at(b32, 1111111109, 8)! == '07081804'
	assert totp_at(b32, 2000000000, 8)! == '69279037'
	assert totp_at('gezd gnbv gy3t qojq gezd gnbv gy3t qojq', 59, 8)! == '94287082'
	now_code := totp_now(b32)!
	assert verify_totp(b32, now_code, 1)
	assert !verify_totp(b32, '000000x', 1)
	s := generate_totp_secret()
	assert s.len == 32
	assert decode_totp_secret(s)!.len == 20
	uri := totp_uri('ACME Co', 'jane@x.io', s)
	assert uri.starts_with('otpauth://totp/ACME%20Co%3Ajane%40x.io?secret=')
}

fn test_legacy_totp_digits_no_overflow() {
	code := generate_totp('secret', 1, 10)!
	assert code.len == 10
}

fn test_password_hashing_and_kdf() {
	h := argon2id_hash('hunter2')!
	assert h.starts_with('$argon2id$')
	assert argon2id_verify('hunter2', h)
	assert !argon2id_verify('hunter3', h)
	// RFC 7914 / well-known PBKDF2-HMAC-SHA256 vector.
	dk := pbkdf2_sha256('password', 'salt'.bytes(), 1, 32)!
	assert to_hex(dk) == '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b'
}

fn test_digests() {
	assert sha1_hex('abc') == 'a9993e364706816aba3e25717850c26c9cd0d89d'
	assert sha3_256('abc') == '3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532'
	assert blake3_hex('') == 'af1349b9f5f9a1a6a0404dea36dcc9499bcb25c9adc112b7cc9a93cae41f3262'
	assert hmac_sha512('key', 'msg').len == 128
	sig := hmac_sha256('whsec', '{"ok":true}')
	assert hmac_sha256_verify('whsec', '{"ok":true}', sig.to_upper())
	assert !hmac_sha256_verify('whsec', '{"ok":false}', sig)
	path := os.join_path(os.temp_dir(), 'cryptoutils_sha_${os.getpid()}.txt')
	os.write_file(path, 'abc')!
	defer {
		os.rm(path) or {}
	}
	assert sha256_file(path)! == sha256('abc')
}

fn test_identifiers_and_encodings() {
	a := uuid_v7()
	assert is_valid_uuid(a)
	assert uuid_version(a)? == 7
	assert a[19] in [`8`, `9`, `a`, `b`]
	assert uuid_version('nope') == none
	n := nanoid(21)
	assert n.len == 21
	assert nanoid(0) == ''
	assert base32_encode('foobar') == 'MZXW6YTBOI======'
	assert base32_decode('MZXW6YTBOI======')! == 'foobar'
	key := []u8{len: 16, init: u8(index)}
	iv := []u8{len: 16}
	ct := aes_ctr_xor(key, iv, 'stream'.bytes())!
	assert aes_ctr_xor(key, iv, ct)!.bytestr() == 'stream'
}

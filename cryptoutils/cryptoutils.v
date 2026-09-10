module cryptoutils

import crypto.aes
import crypto.bcrypt
import crypto.cipher
import crypto.ed25519
import crypto.hmac
import crypto.md5 as vmd5
import crypto.rand as crand
import crypto.sha256 as vsha256
import crypto.sha512 as vsha512
import encoding.base64
import encoding.hex
import hash.crc32
import hash.fnv1a
import rand

// sha256 returns the hexadecimal SHA-256 hash of a string.
pub fn sha256(s string) string {
	return vsha256.hexhash(s)
}

// sha256_hex is an alias for sha256.
pub fn sha256_hex(s string) string {
	return vsha256.hexhash(s)
}

// sha512 returns the hexadecimal SHA-512 hash of a string.
pub fn sha512(s string) string {
	return vsha512.hexhash(s)
}

// sha512_hex is an alias for sha512.
pub fn sha512_hex(s string) string {
	return vsha512.hexhash(s)
}

// md5 returns the hexadecimal MD5 hash of a string.
pub fn md5(s string) string {
	return vmd5.hexhash(s)
}

// md5_hex is an alias for md5.
pub fn md5_hex(s string) string {
	return vmd5.hexhash(s)
}

// hmac_sha256 computes the HMAC-SHA256 digest of data with the given key, returned as hex.
pub fn hmac_sha256(key string, data string) string {
	digest := hmac.new(key.bytes(), data.bytes(), vsha256.sum, vsha256.block_size)
	return hex.encode(digest)
}

// base64_encode encodes a string to standard Base64.
pub fn base64_encode(s string) string {
	return base64.encode_str(s)
}

// base64_decode decodes a standard Base64 string into its original representation.
pub fn base64_decode(s string) !string {
	return base64.decode_str(s)
}

// base64_url_encode encodes a string to URL-safe Base64 without padding.
pub fn base64_url_encode(s string) string {
	return base64.url_encode_str(s)
}

// base64_url_decode decodes a URL-safe Base64 string.
pub fn base64_url_decode(s string) !string {
	return base64.url_decode_str(s)
}

// to_hex encodes a byte slice into a hexadecimal string.
pub fn to_hex(b []u8) string {
	return hex.encode(b)
}

// from_hex decodes a hexadecimal string into a byte slice.
pub fn from_hex(s string) ![]u8 {
	return hex.decode(s)
}

// secure_token generates a cryptographically random hexadecimal token of the specified byte length.
pub fn secure_token(byte_count int) string {
	if byte_count <= 0 {
		return ''
	}
	mut b := []u8{len: byte_count}
	rand.read(mut b)
	return hex.encode(b)
}

// uuid_v4 generates a cryptographically random RFC 4122 version 4 UUID.
pub fn uuid_v4() string {
	mut b := []u8{len: 16}
	rand.read(mut b)
	// Set version to 4 (0100) in the most significant 4 bits of the 7th byte
	b[6] = (b[6] & 0x0f) | 0x40
	// Set variant to RFC 4122 (10) in the most significant 2 bits of the 9th byte
	b[8] = (b[8] & 0x3f) | 0x80

	h := hex.encode(b)
	return '${h[0..8]}-${h[8..12]}-${h[12..16]}-${h[16..20]}-${h[20..32]}'
}

// is_valid_uuid verifies if a string matches canonical UUID format (8-4-4-4-12 hex digits).
pub fn is_valid_uuid(s string) bool {
	if s.len != 36 {
		return false
	}
	for i, c in s {
		if i == 8 || i == 13 || i == 18 || i == 23 {
			if c != `-` {
				return false
			}
		} else {
			is_hex := (c >= `0` && c <= `9`) || (c >= `a` && c <= `f`) || (c >= `A` && c <= `F`)
			if !is_hex {
				return false
			}
		}
	}
	return true
}

fn pkcs7_pad(data []u8, block_size int) []u8 {
	pad_len := block_size - (data.len % block_size)
	mut res := data.clone()
	for _ in 0 .. pad_len {
		res << u8(pad_len)
	}
	return res
}

fn pkcs7_unpad(data []u8) ![]u8 {
	if data.len == 0 {
		return error('empty data')
	}
	pad_len := int(data.last())
	if pad_len <= 0 || pad_len > 16 || pad_len > data.len {
		return error('invalid padding')
	}
	for i in data.len - pad_len .. data.len {
		if data[i] != u8(pad_len) {
			return error('invalid padding sequence')
		}
	}
	return data[..data.len - pad_len].clone()
}

// aes_encrypt_cbc encrypts arbitrary plaintext bytes with AES-CBC using PKCS7 padding.
pub fn aes_encrypt_cbc(key []u8, iv []u8, plaintext []u8) ![]u8 {
	if key.len != 16 && key.len != 24 && key.len != 32 {
		return error('key must be 16, 24, or 32 bytes (AES-128, AES-192, AES-256)')
	}
	if iv.len != aes.block_size {
		return error('IV must be ${aes.block_size} bytes')
	}
	padded := pkcs7_pad(plaintext, aes.block_size)
	block := aes.new_cipher(key)!
	mut enc := cipher.new_cbc(block, iv)
	mut ciphertext := []u8{len: padded.len}
	enc.encrypt_blocks(mut ciphertext, padded)
	return ciphertext
}

// aes_decrypt_cbc decrypts AES-CBC ciphertext and removes PKCS7 padding.
pub fn aes_decrypt_cbc(key []u8, iv []u8, ciphertext []u8) ![]u8 {
	if key.len != 16 && key.len != 24 && key.len != 32 {
		return error('key must be 16, 24, or 32 bytes')
	}
	if iv.len != aes.block_size {
		return error('IV must be ${aes.block_size} bytes')
	}
	if ciphertext.len % aes.block_size != 0 || ciphertext.len == 0 {
		return error('ciphertext length must be a non-zero multiple of ${aes.block_size}')
	}
	block := aes.new_cipher(key)!
	mut dec := cipher.new_cbc(block, iv)
	mut decrypted_padded := []u8{len: ciphertext.len}
	dec.decrypt_blocks(mut decrypted_padded, ciphertext)
	return pkcs7_unpad(decrypted_padded)!
}

// aes_encrypt_string encrypts a UTF-8 string with AES-CBC.
pub fn aes_encrypt_string(key []u8, iv []u8, text string) ![]u8 {
	return aes_encrypt_cbc(key, iv, text.bytes())!
}

// aes_decrypt_string decrypts ciphertext into a UTF-8 string.
pub fn aes_decrypt_string(key []u8, iv []u8, ciphertext []u8) !string {
	bytes := aes_decrypt_cbc(key, iv, ciphertext)!
	return bytes.bytestr()
}

// bcrypt_hash computes a secure bcrypt password hash with the default work factor.
pub fn bcrypt_hash(password string) !string {
	return bcrypt.generate_from_password(password.bytes(), bcrypt.default_cost)!
}

// bcrypt_verify verifies whether a plaintext password matches a bcrypt hash.
pub fn bcrypt_verify(password string, hash string) bool {
	bcrypt.compare_hash_and_password(password.bytes(), hash.bytes()) or { return false }
	return true
}

// secure_random_bytes generates cryptographically secure random bytes via crypto.rand.
pub fn secure_random_bytes(count int) ![]u8 {
	return crand.bytes(count)!
}

// secure_random_hex returns a cryptographically secure random hexadecimal string.
pub fn secure_random_hex(count int) !string {
	bytes := crand.bytes(count)!
	return hex.encode(bytes)
}

// fnv1a_32 computes the 32-bit Fowler–Noll–Vo non-cryptographic hash of a string.
pub fn fnv1a_32(s string) u32 {
	return fnv1a.sum32_string(s)
}

// crc32_hash computes the CRC-32 checksum of a string.
pub fn crc32_hash(s string) u32 {
	return crc32.sum(s.bytes())
}

// generate_ed25519_keypair generates a public and private Ed25519 keypair as hex strings.
pub fn generate_ed25519_keypair() !(string, string) {
	pub_k, priv_k := ed25519.generate_key()!
	return hex.encode(pub_k), hex.encode(priv_k)
}

// ed25519_sign signs a message byte slice using an Ed25519 private key hex string.
pub fn ed25519_sign(priv_key_hex string, msg []u8) !string {
	priv_bytes := hex.decode(priv_key_hex)!
	sig := ed25519.sign(priv_bytes, msg)!
	return hex.encode(sig)
}

// ed25519_verify verifies an Ed25519 signature hex string with a public key hex string.
pub fn ed25519_verify(pub_key_hex string, msg []u8, sig_hex string) bool {
	pub_bytes := hex.decode(pub_key_hex) or { return false }
	sig_bytes := hex.decode(sig_hex) or { return false }
	return ed25519.verify(pub_bytes, msg, sig_bytes) or { false }
}

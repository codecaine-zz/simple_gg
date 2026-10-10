module cryptoutils

import crypto.aes
import crypto.argon2
import crypto.blake3
import crypto.cipher
import crypto.hkdf
import crypto.hmac
import crypto.pbkdf2
import crypto.sha1
import crypto.sha256 as vsha256
import crypto.sha3
import crypto.sha512 as vsha512
import encoding.base32
import encoding.base64
import encoding.hex
import os
import time

// ---------------------------------------------------------------------------
// Authenticated encryption (encrypt-then-MAC: AES-256-CBC + HMAC-SHA256)
// ---------------------------------------------------------------------------

const seal_version = u8(1)
const seal_overhead = 1 + 16 + 32

fn seal_subkeys(key []u8) !([]u8, []u8) {
	if key.len < 16 {
		return error('key must be at least 16 bytes (use 32 random bytes from generate_key())')
	}
	enc_key := hkdf.key(vsha256.new, key, []u8{}, 'vlang_utils seal v1 enc', 32)!
	mac_key := hkdf.key(vsha256.new, key, []u8{}, 'vlang_utils seal v1 mac', 32)!
	return enc_key, mac_key
}

// generate_key returns 32 random bytes suitable for seal/open.
pub fn generate_key() []u8 {
	return csprng_bytes(32)
}

// seal encrypts and authenticates plaintext. A fresh random IV is used on every call and any
// tampering is detected by open(). Prefer this over raw aes_encrypt_cbc, which is unauthenticated.
pub fn seal(key []u8, plaintext []u8) ![]u8 {
	enc_key, mac_key := seal_subkeys(key)!
	iv := csprng_bytes(aes.block_size)
	ct := aes_encrypt_cbc(enc_key, iv, plaintext)!
	mut out := []u8{cap: seal_overhead + ct.len}
	out << seal_version
	out << iv
	out << ct
	tag := hmac.new(mac_key, out, vsha256.sum, vsha256.block_size)
	out << tag
	return out
}

// open verifies and decrypts data produced by seal. Returns an error if the data was modified,
// truncated, or encrypted with a different key.
pub fn open(key []u8, sealed []u8) ![]u8 {
	if sealed.len < seal_overhead + aes.block_size || sealed[0] != seal_version {
		return error('invalid sealed data')
	}
	enc_key, mac_key := seal_subkeys(key)!
	body := sealed[..sealed.len - 32]
	tag := sealed[sealed.len - 32..]
	expected := hmac.new(mac_key, body, vsha256.sum, vsha256.block_size)
	if !hmac.equal(tag, expected) {
		return error('authentication failed: data was tampered with or the key is wrong')
	}
	return aes_decrypt_cbc(enc_key, body[1..17], body[17..])
}

// seal_string encrypts text and returns a URL-safe Base64 token.
pub fn seal_string(key []u8, text string) !string {
	return base64.url_encode(seal(key, text.bytes())!)
}

// open_string decrypts a token produced by seal_string.
pub fn open_string(key []u8, token string) !string {
	return open(key, base64.url_decode(token))!.bytestr()
}

// ---------------------------------------------------------------------------
// One-time passwords (RFC 4226 HOTP / RFC 6238 TOTP, Google Authenticator compatible)
// ---------------------------------------------------------------------------

// hotp computes an RFC 4226 HMAC-SHA1 one-time password for a raw secret and counter.
pub fn hotp(secret []u8, counter u64, digits int) !string {
	if digits < 6 || digits > 10 {
		return error('digits must be between 6 and 10')
	}
	mut msg := []u8{len: 8}
	for i in 0 .. 8 {
		msg[7 - i] = u8((counter >> (8 * i)) & 0xff)
	}
	digest := hmac.new(secret, msg, sha1.sum, sha1.block_size)
	offset := int(digest[digest.len - 1] & 0x0f)
	code := ((u32(digest[offset]) & 0x7f) << 24) | (u32(digest[offset + 1]) << 16) | (u32(digest[
		offset + 2]) << 8) | u32(digest[offset + 3])
	mut mod := u64(1)
	for _ in 0 .. digits {
		mod *= 10
	}
	return zero_pad((u64(code) % mod).str(), digits)
}

// decode_totp_secret decodes a Base32 secret as shown by authenticator apps (spaces/padding/case tolerant).
pub fn decode_totp_secret(secret string) ![]u8 {
	mut clean := secret.to_upper().replace(' ', '').replace('-', '').trim_right('=')
	for clean.len % 8 != 0 {
		clean += '='
	}
	return base32.decode(clean.bytes())
}

// totp_at computes the RFC 6238 TOTP (SHA1, 30 s step) for a Base32 secret at the given unix time.
pub fn totp_at(secret_b32 string, unix_seconds i64, digits int) !string {
	key := decode_totp_secret(secret_b32)!
	return hotp(key, u64(unix_seconds / 30), digits)
}

// totp_now computes the current 6-digit TOTP code for a Base32 secret.
pub fn totp_now(secret_b32 string) !string {
	return totp_at(secret_b32, time.utc().unix(), 6)
}

// verify_totp checks a code against the current time, tolerating `window` steps of clock drift
// either side (1 is the common choice). Comparison is constant-time.
pub fn verify_totp(secret_b32 string, code string, window int) bool {
	now := time.utc().unix()
	for w in -window .. window + 1 {
		expected := totp_at(secret_b32, now + i64(w) * 30, code.len) or { return false }
		if secure_compare(expected, code) {
			return true
		}
	}
	return false
}

// generate_totp_secret returns a random 160-bit Base32 secret (RFC 4226 recommended length).
pub fn generate_totp_secret() string {
	return base32.encode_to_string(csprng_bytes(20)).trim_right('=')
}

// totp_uri builds an otpauth:// URI that authenticator apps import via QR code.
pub fn totp_uri(issuer string, account string, secret_b32 string) string {
	label := url_escape('${issuer}:${account}')
	return 'otpauth://totp/${label}?secret=${secret_b32}&issuer=${url_escape(issuer)}&algorithm=SHA1&digits=6&period=30'
}

fn url_escape(s string) string {
	mut out := []u8{}
	for c in s.bytes() {
		if (c >= `A` && c <= `Z`) || (c >= `a` && c <= `z`) || (c >= `0` && c <= `9`)
			|| c in [`-`, `_`, `.`, `~`] {
			out << c
		} else {
			out << `%`
			out << '0123456789ABCDEF'[c >> 4]
			out << '0123456789ABCDEF'[c & 15]
		}
	}
	return out.bytestr()
}

// ---------------------------------------------------------------------------
// Password hashing & key derivation
// ---------------------------------------------------------------------------

// argon2id_hash hashes a password with Argon2id (PHC string format), the OWASP-recommended default.
pub fn argon2id_hash(password string) !string {
	return argon2.generate_from_password(password.bytes())
}

// argon2id_verify checks a password against an Argon2 PHC hash string.
pub fn argon2id_verify(password string, hash string) bool {
	argon2.compare_hash_and_password(password.bytes(), hash.bytes()) or { return false }
	return true
}

// pbkdf2_sha256 derives key_len bytes from a password and salt (use >= 600_000 iterations per OWASP 2023).
pub fn pbkdf2_sha256(password string, salt []u8, iterations int, key_len int) ![]u8 {
	return pbkdf2.key(password.bytes(), salt, iterations, key_len, vsha256.new())
}

// ---------------------------------------------------------------------------
// Additional digests & MACs
// ---------------------------------------------------------------------------

// sha1 returns the hex SHA-1 digest (legacy interop only: git object ids, HOTP; not collision resistant).
pub fn sha1_hex(s string) string {
	return sha1.hexhash(s)
}

// sha3_256 returns the hex SHA3-256 digest.
pub fn sha3_256(s string) string {
	return hex.encode(sha3.sum256(s.bytes()))
}

// blake3_hex returns the hex BLAKE3 digest (very fast, modern).
pub fn blake3_hex(s string) string {
	return hex.encode(blake3.sum256(s.bytes()))
}

// hmac_sha512 computes the HMAC-SHA512 digest of data with the given key, returned as hex.
pub fn hmac_sha512(key string, data string) string {
	return hex.encode(hmac.new(key.bytes(), data.bytes(), vsha512.sum512, vsha512.block_size))
}

// hmac_sha256_verify checks a hex HMAC-SHA256 signature in constant time (e.g. webhook signatures).
pub fn hmac_sha256_verify(key string, data string, signature_hex string) bool {
	return secure_compare(hmac_sha256(key, data), signature_hex.to_lower())
}

// sha256_file streams a file through SHA-256 without loading it into memory; returns hex.
pub fn sha256_file(path string) !string {
	mut f := os.open(path)!
	defer {
		f.close()
	}
	mut d := vsha256.new()
	mut buf := []u8{len: 64 * 1024}
	for {
		n := f.read(mut buf) or { break }
		if n <= 0 {
			break
		}
		d.write(buf[..n])!
	}
	return hex.encode(d.sum([]u8{}))
}

// ---------------------------------------------------------------------------
// Identifiers & encodings
// ---------------------------------------------------------------------------

// uuid_v7 generates an RFC 9562 version 7 UUID: millisecond-timestamp prefixed, so ids sort by
// creation time and index well in databases, with 74 random bits.
pub fn uuid_v7() string {
	ms := u64(time.utc().unix_milli())
	mut b := csprng_bytes(16)
	for i in 0 .. 6 {
		b[i] = u8((ms >> (8 * (5 - i))) & 0xff)
	}
	b[6] = (b[6] & 0x0f) | 0x70
	b[8] = (b[8] & 0x3f) | 0x80
	h := hex.encode(b)
	return '${h[0..8]}-${h[8..12]}-${h[12..16]}-${h[16..20]}-${h[20..32]}'
}

// uuid_version returns the version nibble of a canonical UUID string, or none if invalid.
pub fn uuid_version(s string) ?int {
	if !is_valid_uuid(s) {
		return none
	}
	c := s[14]
	return if c >= `0` && c <= `9` { int(c - `0`) } else { int((c | 0x20) - `a` + 10) }
}

const nanoid_alphabet = '_-0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'

// nanoid returns a URL-safe random id of `size` characters (21 gives ~126 bits, like UUIDv4).
pub fn nanoid(size int) string {
	if size <= 0 {
		return ''
	}
	b := csprng_bytes(size)
	mut out := []u8{len: size}
	for i in 0 .. size {
		out[i] = nanoid_alphabet[b[i] & 63]
	}
	return out.bytestr()
}

// base32_encode encodes a string with RFC 4648 Base32 (with padding).
pub fn base32_encode(s string) string {
	return base32.encode_string_to_string(s)
}

// base32_decode decodes RFC 4648 Base32.
pub fn base32_decode(s string) !string {
	return base32.decode_string_to_string(s)
}

// aes_ctr_xor encrypts/decrypts with AES-CTR (same operation both ways). Unauthenticated: prefer seal().
pub fn aes_ctr_xor(key []u8, iv []u8, data []u8) ![]u8 {
	if iv.len != aes.block_size {
		return error('IV must be ${aes.block_size} bytes')
	}
	block := aes.new_cipher(key)!
	mut stream := cipher.new_ctr(block, iv)
	mut out := []u8{len: data.len}
	stream.xor_key_stream(mut out, data)
	return out
}

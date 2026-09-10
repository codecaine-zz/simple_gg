module main

import cryptoutils

fn main() {
	println('==================================================')
	println('               demo_cryptoutils                   ')
	println('==================================================')

	data := 'Hello, Vlang Utilities!'

	// 1. Hashes
	println('1. Cryptographic Hashes:')
	println('  SHA-256: ${cryptoutils.sha256(data)}')
	println('  SHA-512: ${cryptoutils.sha512(data)[..32]}... (truncated)')
	println('  MD5:     ${cryptoutils.md5(data)}')
	println('  CRC32:   ${cryptoutils.crc32_hash(data)}')
	println('  FNV-1a:  ${cryptoutils.fnv1a_32(data)}')

	// 2. HMAC
	println('\n2. HMAC-SHA256:')
	secret := 'super_secret_key'
	hmac_sig := cryptoutils.hmac_sha256(secret, data)
	println('  HMAC signature: ${hmac_sig}')

	// 3. Base64
	println('\n3. Base64 Encoding & Decoding:')
	b64 := cryptoutils.base64_encode(data)
	println('  Encoded: ${b64}')
	decoded := cryptoutils.base64_decode(b64) or { 'decode error' }
	println('  Decoded: ${decoded}')

	// 4. UUID v4
	println('\n4. UUID v4 Generation & Validation:')
	uid := cryptoutils.uuid_v4()
	println('  Generated: ${uid}')
	println('  Is Valid?  ${cryptoutils.is_valid_uuid(uid)}')

	// 5. Symmetric AES-CBC Encryption
	println('\n5. AES-256-CBC Encryption & Decryption:')
	key := [u8(1), 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23,
		24, 25, 26, 27, 28, 29, 30, 31, 32]
	iv := [u8(1), 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]
	ciphertext := cryptoutils.aes_encrypt_string(key, iv, data) or {
		eprintln('Encryption failed: ${err}')
		return
	}
	println('  Encrypted bytes len: ${ciphertext.len}')
	decrypted_text := cryptoutils.aes_decrypt_string(key, iv, ciphertext) or {
		eprintln('Decryption failed: ${err}')
		return
	}
	println('  Decrypted text:      "${decrypted_text}"')

	// 6. Ed25519 Signatures
	println('\n6. Ed25519 Keypair & Signatures:')
	pub_k, priv_k := cryptoutils.generate_ed25519_keypair() or {
		eprintln('Keypair error: ${err}')
		return
	}
	msg := 'Authorize transaction #420'.bytes()
	sig := cryptoutils.ed25519_sign(priv_k, msg) or {
		eprintln('Sign error: ${err}')
		return
	}
	verified := cryptoutils.ed25519_verify(pub_k, msg, sig)
	println('  Public Key:  ${pub_k[..16]}...')
	println('  Signature:   ${sig[..24]}...')
	println('  Valid Sig?   ${verified}')

	println('\n✔ cryptoutils demo completed successfully!')
}

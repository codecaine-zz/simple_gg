module main

import simplecli

fn main() {
	mut app := simplecli.new_app('crypto-cli', '1.0.0')
	app.set_description('Cryptographic Hash, Symmetric AES, and BCrypt Studio')

	app.add_flag_string('algo', 'a', 'sha256', 'Hash algorithm: md5, sha1, sha256, sha512, bcrypt')
	app.add_flag_string('text', 't', '', 'Input plaintext string')
	app.add_flag_string('file', 'f', '', 'Input file path for hashing')
	app.add_flag_string('encrypt', 'e', '', 'Encrypt input text using AES-256 with key')
	app.add_flag_string('decrypt', 'd', '', 'Decrypt ciphertext using AES-256 with key')
	app.add_flag_string('key', 'k', '', 'Passphrase/key for AES or HMAC operations')
	app.add_flag_bool('interactive', 'x', false, 'Launch interactive crypto workstation')

	app.parse_cli() or { return }

	app.banner('Crypto & Hashing Studio CLI', 'v1.0.0 - Headless Security Toolkit')

	if app.get_flag_bool('interactive') {
		run_interactive(mut app)
		return
	}

	key := app.get_flag_string('key')
	encrypt_txt := app.get_flag_string('encrypt')
	decrypt_txt := app.get_flag_string('decrypt')

	if encrypt_txt.len > 0 {
		if key.len == 0 {
			app.error('Encryption requires --key / -k flag.')
			return
		}
		cipher := app.crypto_aes_encrypt(key, encrypt_txt) or {
			app.error('AES encryption failed: ${err}')
			return
		}
		app.success('AES-256 Encrypted Ciphertext (Base64):')
		println(cipher)
		return
	}

	if decrypt_txt.len > 0 {
		if key.len == 0 {
			app.error('Decryption requires --key / -k flag.')
			return
		}
		plain := app.crypto_aes_decrypt(key, decrypt_txt) or {
			app.error('AES decryption failed: ${err}')
			return
		}
		app.success('AES-256 Decrypted Plaintext:')
		println(plain)
		return
	}

	algo := app.get_flag_string('algo').to_lower()
	file_path := app.get_flag_string('file')
	mut input_data := app.get_flag_string('text')

	if file_path.len > 0 {
		if !app.file_exists(file_path) {
			app.error('File not found: ${file_path}')
			return
		}
		input_data = app.read_file(file_path)
		app.info('Read ${input_data.len} bytes from ${file_path}')
	}

	if input_data.len == 0 {
		input_data = 'Hello, World!'
		app.info('No text or file specified. Using default input "${input_data}"')
	}

	app.reset_timer()
	hash_out := match algo {
		'md5' { app.crypto_md5(input_data) }
		'sha1' { app.crypto_sha1(input_data) }
		'sha512' { app.crypto_sha512(input_data) }
		'bcrypt' { app.crypto_bcrypt_hash(input_data) or { 'Error: ${err}' } }
		else { app.crypto_sha256(input_data) }
	}

	app.success('${algo.to_upper()} Hash computed in ${app.elapsed_ms()} ms:')
	println(hash_out)
}

fn run_interactive(mut app simplecli.SimpleCli) {
	app.panel('Crypto Studio REPL', 'Supported algorithms: MD5, SHA-1, SHA-256, SHA-512, BCrypt, AES-256.')
	text := app.prompt('Enter plaintext to process', 'MasterPassword123!')
	h_md5 := app.crypto_md5(text)
	h_sha256 := app.crypto_sha256(text)
	h_sha512 := app.crypto_sha512(text)
	h_bcrypt := app.crypto_bcrypt_hash(text) or { 'Failed' }

	app.table(
		['Algorithm', 'Hash / Digest'],
		[
			['MD5', h_md5],
			['SHA-256', h_sha256],
			['SHA-512', h_sha512[0..32] + '...'],
			['BCrypt', h_bcrypt],
		]
	)
}

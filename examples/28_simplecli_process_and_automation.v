module main

import simplecli

fn main() {
	mut app := simplecli.new_app('Automation & Task Runner', '1.0.0')

	app.banner('SimpleCLI Process & Task Automation', 'Rapid Process Control, Stdlib & Crypto')

	// 1. Process Execution & Command Discovery
	app.step(1, 'Command & Executable Discovery')
	git_path := app.find_executable('git')
	curl_path := app.find_executable('curl')
	v_path := app.find_executable('v')

	app.print_kv({
		'Git Executable':  if git_path.len > 0 { git_path } else { 'Not Found' }
		'Curl Executable': if curl_path.len > 0 { curl_path } else { 'Not Found' }
		'V Executable':    if v_path.len > 0 { v_path } else { 'Not Found' }
	})

	// 2. Synchronous & Timeout Command Execution
	app.step(2, 'Synchronous Execution & Timeout Verification')
	git_branch, _ := app.exec('git rev-parse --abbrev-ref HEAD')
	app.info('Current Git Branch: ${git_branch}')

	app.info('Executing sleep test with 500ms timeout guard...')
	out, code, timed_out := app.exec_timeout('sleep 2', 500)
	if timed_out {
		app.warn('Process safely aborted: ${out} (code: ${code})')
	} else {
		app.success('Process completed within timeout limit.')
	}

	// 3. Stdlib Cryptography & AES Encryption
	app.step(3, 'Security, Cryptography & Encryption')
	secret_key := 'simplecli_top_secret_passphrase'
	raw_payload := 'Database Credentials: host=db.internal port=5432 user=admin'

	sha256_hash := app.crypto_sha256(raw_payload)
	app.info('SHA256 Digest: ${sha256_hash}')

	encrypted_blob := app.crypto_aes_encrypt(secret_key, raw_payload) or {
		app.error('Encryption failed: ${err}')
		return
	}
	app.info('Encrypted AES-256 Payload (Base64):\n  ${encrypted_blob}')

	decrypted_payload := app.crypto_aes_decrypt(secret_key, encrypted_blob) or {
		app.error('Decryption failed: ${err}')
		return
	}
	app.success('Decrypted Match: "${decrypted_payload}"')

	// 4. Clipboard & System Audio
	app.step(4, 'System Clipboard & Audio Integration')
	app.copy_to_clipboard('https://github.com/vlang/v')
	clip := app.get_clipboard_text()
	app.info('Clipboard Content: "${clip}"')

	app.beep()
	app.notify('Task Complete', 'Automation workflow finished with zero errors.')
	app.success('All automation tasks completed successfully!')
	app.print_elapsed()
}

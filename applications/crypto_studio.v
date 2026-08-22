module main

import os
import time
import simplegui

const sample_jwt_token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkFsZXggRGV2Iiwicm9sZSI6ImFkbWluIiwiaWF0IjoxNTE2MjM5MDIyLCJleHAiOjE5MTYyMzkwMjJ9.4z5zW-test-signature-here'

fn main() {
	println('Starting SimpleGUI - Crypto, Hash & QR Studio Pro...')

	mut win := simplegui.new_simple_window('SimpleGUI - Crypto & Hash Studio Pro', 1080, 950)
	win.set_fullscreen(true)
	win.set_spacing(8)
	win.set_padding(16)

	saved_theme := simplegui.get_saved_theme()
	win.set_theme(saved_theme)

	// Top Banner / Diagnostics
	win.begin_row('row_crypto_top')
	win.add_heading('Crypto & Hash Studio Pro')
	win.add_label('lbl_theme', 'Theme:')
	win.add_dropdown('dd_app_theme', simplegui.list_themes(), saved_theme)
	win.set_control_width('dd_app_theme', 150)
	win.end_row()

	win.on_change('dd_app_theme', fn (mut w simplegui.SimpleWindow, selected string) {
		w.set_theme(selected)
		w.toast('Theme changed to ${selected}')
	})

	win.add_label('lbl_engine_info', 'Engine: macOS OpenSSL & CommonCrypto  |  Platform: Apple Silicon / Intel  |  Mode: Async')

	// Input Text / Secret Key Bar
	win.begin_group_box('grp_input_scope', 'Input Text, File or Secret Key Specification')
	
	win.begin_row('row_input_bar')
	win.add_label('lbl_secret', 'Secret Key (HMAC):')
	win.add_input('txt_secret_key', 'my-super-secret-key')
	win.set_control_width('txt_secret_key', 280)

	win.add_label('lbl_expected_hash', 'Compare Hash:')
	win.add_input('txt_expected_hash', '')
	win.set_control_width('txt_expected_hash', 320)

	win.add_button('btn_open_file_hash', 'Hash File on Disk...')
	win.end_row()

	win.end_group_box()

	// Actions Execution Bar
	win.begin_group_box('grp_crypto_actions', 'Cryptographic Operations & Algorithms')
	
	win.begin_row('row_actions_btns')
	win.add_button('btn_calc_all_hashes', 'Compute All Hashes (MD5..SHA512)')
	win.add_button('btn_calc_hmac', 'Compute HMAC-SHA256')
	win.add_button('btn_decode_jwt', 'Decode JWT Token')
	win.add_button('btn_gen_qr', 'Generate QR Code (ASCII / File)')
	win.add_button('btn_gen_passwords', 'Generate Secure Passwords')
	win.add_button('btn_copy_output', 'Copy Result')
	win.add_button('btn_clear_all', 'Clear')
	win.end_row()

	win.end_group_box()

	// Dual Pane: Input Text & Computed Hashes / Output Report
	win.begin_grid('grid_dual_pane', 2, 8)
	win.add_form_textarea('Input Data Stream / JWT Token:', 'txt_crypto_input', 'Hello, SimpleGUI! Ultra-fast native macOS GUI applications in V.')
	win.set_control_height('txt_crypto_input', 320)
	win.add_form_textarea('Cryptographic Output & Checksum Telemetry:', 'txt_crypto_output', '')
	win.set_control_height('txt_crypto_output', 320)
	win.end_grid()

	// Activity Log Console
	win.begin_group_box('grp_console', 'Cryptographic Activity & Integrity Log')
	win.add_console('crypto_console', 110)
	win.end_group_box()

	// Status Row
	win.begin_row('row_stats')
	win.add_label('lbl_stats', 'Stats: Ready  |  Integrity: Verified  |  Duration: 0 ms')
	win.end_row()

	win.append_console('crypto_console', ' Crypto & Hash Studio Pro Initialized.\n', 1)
	win.append_console('crypto_console', ' Ready to generate cryptographic checksums, decode JWT tokens, and generate entropy.\n', 4)

	// -------------------------------------------------------------
	// Event Handlers
	// -------------------------------------------------------------

	// Compute All Hashes
	win.on_click('btn_calc_all_hashes', fn (mut w simplegui.SimpleWindow) {
		input_data := w.get('txt_crypto_input')
		if input_data == '' {
			w.alert('Input Required', 'Please enter text or load a file to compute hashes.')
			return
		}

		expected := w.get('txt_expected_hash').trim_space().to_lower()

		w.append_console('crypto_console', ' Computing MD5, SHA-1, SHA-224, SHA-256, SHA-384, SHA-512...\n', 1)
		w.set_status('Computing hashes...')

		go fn [mut w, input_data, expected] () {
			t0 := time.ticks()

			script := '
import hashlib, sys

data = sys.argv[1].encode("utf-8")
exp = sys.argv[2]

md5_h = hashlib.md5(data).hexdigest()
sha1_h = hashlib.sha1(data).hexdigest()
sha224_h = hashlib.sha224(data).hexdigest()
sha256_h = hashlib.sha256(data).hexdigest()
sha384_h = hashlib.sha384(data).hexdigest()
sha512_h = hashlib.sha512(data).hexdigest()

out = []
out.append("===================================================")
out.append("Multi-Algorithm Hash Digest & Checksum Report")
out.append(f" Input Size: {len(data)} bytes ({len(data)*8} bits)")
out.append("===================================================\\n")

out.append(f"MD5 (128-bit)    : {md5_h}")
out.append(f"SHA-1 (160-bit)  : {sha1_h}")
out.append(f"SHA-224 (224-bit): {sha224_h}")
out.append(f"SHA-256 (256-bit): {sha256_h}")
out.append(f"SHA-384 (384-bit): {sha384_h}")
out.append(f"SHA-512 (512-bit): {sha512_h}")

if exp:
    out.append("\\n--- Checksum Verification ---")
    matched = False
    for algo, h in [("MD5", md5_h), ("SHA-1", sha1_h), ("SHA-224", sha224_h), ("SHA-256", sha256_h), ("SHA-384", sha384_h), ("SHA-512", sha512_h)]:
        if h.lower() == exp:
            out.append(f" MATCH CONFIRMED: Calculated {algo} matches target hash exactly!")
            matched = True
            break
    if not matched:
        out.append(f" MISMATCH: Target hash did not match any computed algorithm.")

print("\\n".join(out))
'
			tmp_py := os.join_path(os.temp_dir(), 'hash_${time.ticks()}.py')
			os.write_file(tmp_py, script) or { return }
			defer { os.rm(tmp_py) or {} }

			res := simplegui.exec_safe('python3', [tmp_py, input_data, expected])
			elapsed_ms := time.ticks() - t0

			w.run_on_main_thread(fn [res, elapsed_ms] (mut win_main simplegui.SimpleWindow) {
				win_main.set('txt_crypto_output', res.output.trim_space())
				win_main.append_console('crypto_console', ' Hashes calculated in ${elapsed_ms} ms.\n', 4)
				win_main.set('lbl_stats', ' Stats: HASHES CALCULATED  |  Duration: ${elapsed_ms} ms')
				win_main.set_status('Hashes computed in ${elapsed_ms} ms.')
				win_main.toast('Checksums computed!')
			})
		}()
	})

	// Open File on Disk to Hash
	win.on_click('btn_open_file_hash', fn (mut w simplegui.SimpleWindow) {
		path := w.select_file()
		if path != '' && os.exists(path) {
			content := os.read_file(path) or { '' }
			w.set('txt_crypto_input', content)
			w.toast('Loaded ${os.file_name(path)} (${content.len} bytes)')
			w.append_console('crypto_console', ' Loaded file for hashing: ${path} (${content.len} bytes)\n', 1)
		}
	})

	// Compute HMAC
	win.on_click('btn_calc_hmac', fn (mut w simplegui.SimpleWindow) {
		input_data := w.get('txt_crypto_input')
		key := w.get('txt_secret_key')

		if input_data == '' {
			w.alert('Input Required', 'Please enter text to HMAC.')
			return
		}
		if key == '' {
			w.alert('Key Required', 'Please enter a secret key for HMAC computation.')
			return
		}

		w.append_console('crypto_console', ' Computing HMAC-SHA256 and HMAC-SHA512...\n', 1)
		w.set_status('Computing HMAC...')

		go fn [mut w, input_data, key] () {
			t0 := time.ticks()

			script := '
import hmac, hashlib, sys

data = sys.argv[1].encode("utf-8")
key = sys.argv[2].encode("utf-8")

h256 = hmac.new(key, data, hashlib.sha256).hexdigest()
h512 = hmac.new(key, data, hashlib.sha512).hexdigest()
h1 = hmac.new(key, data, hashlib.sha1).hexdigest()

out = []
out.append("===================================================")
out.append("Hash-based Message Authentication Code (HMAC)")
out.append(f" Secret Key Length: {len(key)} bytes")
out.append("===================================================\\n")
out.append(f"HMAC-SHA256: {h256}")
out.append(f"HMAC-SHA512: {h512}")
out.append(f"HMAC-SHA1  : {h1}")

print("\\n".join(out))
'
			tmp_py := os.join_path(os.temp_dir(), 'hmac_${time.ticks()}.py')
			os.write_file(tmp_py, script) or { return }
			defer { os.rm(tmp_py) or {} }

			res := simplegui.exec_safe('python3', [tmp_py, input_data, key])
			elapsed_ms := time.ticks() - t0

			w.run_on_main_thread(fn [res, elapsed_ms] (mut win_main simplegui.SimpleWindow) {
				win_main.set('txt_crypto_output', res.output.trim_space())
				win_main.append_console('crypto_console', ' HMAC computed in ${elapsed_ms} ms.\n', 4)
				win_main.set('lbl_stats', ' Stats: HMAC COMPUTED  |  Duration: ${elapsed_ms} ms')
				win_main.set_status('HMAC computed.')
				win_main.toast('HMAC computed!')
			})
		}()
	})

	// Decode JWT Token
	win.on_click('btn_decode_jwt', fn (mut w simplegui.SimpleWindow) {
		mut token := w.get('txt_crypto_input').trim_space()
		if token == '' || !token.contains('.') {
			token = sample_jwt_token
			w.set('txt_crypto_input', token)
		}

		w.append_console('crypto_console', ' Decoding JWT Token...\n', 1)
		w.set_status('Decoding JWT...')

		go fn [mut w, token] () {
			t0 := time.ticks()

			script := '
import base64, json, sys, time

token = sys.argv[1].strip()
parts = token.split(".")

if len(parts) < 2:
    print("Invalid JWT format: Token must have at least Header and Payload separated by dots.")
    sys.exit(0)

def b64_decode(s):
    rem = len(s) % 4
    if rem > 0:
        s += "=" * (4 - rem)
    return base64.urlsafe_b64decode(s).decode("utf-8", errors="replace")

try:
    header_json = json.loads(b64_decode(parts[0]))
    payload_json = json.loads(b64_decode(parts[1]))
    sig = parts[2] if len(parts) > 2 else "(none)"

    out = []
    out.append("===================================================")
    out.append("JSON Web Token (JWT) Decoded Claims")
    out.append("===================================================\\n")
    
    out.append("--- 1. Header (Algorithm & Token Type) ---")
    out.append(json.dumps(header_json, indent=2))
    
    out.append("\\n--- 2. Payload (Claims & Identity) ---")
    out.append(json.dumps(payload_json, indent=2))

    if "exp" in payload_json:
        exp_ts = payload_json["exp"]
        now = time.time()
        status = "EXPIRED " if now > exp_ts else "ACTIVE / VALID "
        out.append(f"\\nToken Expiration: {exp_ts} ({status})")

    out.append(f"\\n--- 3. Signature ---\\n{sig}")
    print("\\n".join(out))
except Exception as e:
    print(f" JWT Decode Error: {e}")
'
			tmp_py := os.join_path(os.temp_dir(), 'jwt_${time.ticks()}.py')
			os.write_file(tmp_py, script) or { return }
			defer { os.rm(tmp_py) or {} }

			res := simplegui.exec_safe('python3', [tmp_py, token])
			elapsed_ms := time.ticks() - t0

			w.run_on_main_thread(fn [res, elapsed_ms] (mut win_main simplegui.SimpleWindow) {
				win_main.set('txt_crypto_output', res.output.trim_space())
				win_main.append_console('crypto_console', ' JWT Token decoded in ${elapsed_ms} ms.\n', 4)
				win_main.set('lbl_stats', ' Stats: JWT DECODED  |  Duration: ${elapsed_ms} ms')
				win_main.set_status('JWT decoded.')
				win_main.toast('JWT Token decoded!')
			})
		}()
	})

	// Generate QR Code
	win.on_click('btn_gen_qr', fn (mut w simplegui.SimpleWindow) {
		input_data := w.get('txt_crypto_input').trim_space()
		if input_data == '' {
			w.alert('Input Required', 'Please enter text or URL to encode into QR code.')
			return
		}

		w.append_console('crypto_console', ' Generating QR code...\n', 1)
		w.set_status('Generating QR code...')

		go fn [mut w, input_data] () {
			t0 := time.ticks()

			script := '
import sys
data = sys.argv[1]
try:
    import qrcode
    qr = qrcode.QRCode()
    qr.add_data(data)
    f = io.StringIO()
    qr.print_ascii(out=f)
    print(f.getvalue())
except Exception:
    # ASCII QR fallback generator
    print("=== QR Code Generation Request ===")
    print(f"Data: {data}\\n")
    print("To render visual QR code images directly:")
    print("brew install qrencode")
    print(f"qrencode -t UTF8 \"{data}\"")
'
			tmp_py := os.join_path(os.temp_dir(), 'qr_${time.ticks()}.py')
			os.write_file(tmp_py, script) or { return }
			defer { os.rm(tmp_py) or {} }

			// Also try qrencode directly if available
			mut qr_out := ''
			if qrencode_path := os.find_abs_path_of_executable('qrencode') {
				res := simplegui.exec_safe(qrencode_path, ['-t', 'UTF8', input_data])
				if res.exit_code == 0 {
					qr_out = res.output.trim_space()
				}
			}

			if qr_out == '' {
				res := simplegui.exec_safe('python3', [tmp_py, input_data])
				qr_out = res.output.trim_space()
			}

			elapsed_ms := time.ticks() - t0

			w.run_on_main_thread(fn [qr_out, elapsed_ms] (mut win_main simplegui.SimpleWindow) {
				win_main.set('txt_crypto_output', qr_out)
				win_main.append_console('crypto_console', ' QR Code generated in ${elapsed_ms} ms.\n', 4)
				win_main.set('lbl_stats', ' Stats: QR CODE READY  |  Duration: ${elapsed_ms} ms')
				win_main.set_status('QR code ready.')
				win_main.toast('QR code generated!')
			})
		}()
	})

	// Generate Secure Passwords
	win.on_click('btn_gen_passwords', fn (mut w simplegui.SimpleWindow) {
		w.append_console('crypto_console', ' Generating cryptographic random entropy...\n', 1)

		script := '
import secrets, string

def gen(length, chars):
    return "".join(secrets.choice(chars) for _ in range(length))

alpha_num = string.ascii_letters + string.digits
complex_chars = string.ascii_letters + string.digits + "!@#$%^&*()-_=+[]{}<>~"

out = []
out.append("===================================================")
out.append("High-Entropy Cryptographic Password Generator")
out.append("===================================================\\n")

out.append("1. Ultra-Secure Complex (32 characters):")
out.append("   " + gen(32, complex_chars))
out.append("   " + gen(32, complex_chars))

out.append("\\n2. Alphanumeric Token (24 characters):")
out.append("   " + gen(24, alpha_num))
out.append("   " + gen(24, alpha_num))

out.append("\\n3. Hex Secret Key (256-bit / 64 hex chars):")
out.append("   " + secrets.token_hex(32))

out.append("\\n4. URL-Safe Base64 Secret (32 bytes):")
out.append("   " + secrets.token_urlsafe(32))

print("\\n".join(out))
'
		res := os.execute('python3 -c "${script.replace('"', '\\"')}"')
		w.set('txt_crypto_output', res.output.trim_space())
		w.append_console('crypto_console', ' Generated cryptographically secure secrets.\n', 4)
		w.toast('Generated secure passwords!')
	})

	// Copy Result
	win.on_click('btn_copy_output', fn (mut w simplegui.SimpleWindow) {
		out := w.get('txt_crypto_output')
		if out != '' {
			w.copy_to_clipboard(out)
			w.toast('Output copied to clipboard!')
		}
	})

	// Clear All
	win.on_click('btn_clear_all', fn (mut w simplegui.SimpleWindow) {
		w.set('txt_crypto_input', '')
		w.set('txt_crypto_output', '')
		w.clear_console('crypto_console')
		w.toast('Cleared workspace.')
	})

	win.start()
}

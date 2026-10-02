module main

import jwtutils
import time

fn main() {
	println('=== jwtutils Demo ===')

	secret := 'my_top_secret_hmac_signing_key_456'
	claims := jwtutils.JWTClaims{
		sub:    'admin_user_42'
		iss:    'antigravity_auth_service'
		exp:    time.now().unix() + 3600
		custom: {
			'role':  'superadmin'
			'email': 'admin@example.com'
		}
	}

	token := jwtutils.sign_jwt(claims, secret) or { panic(err) }
	println('Generated JWT:\n${token}')

	verified := jwtutils.verify_jwt(token, secret) or { panic(err) }
	println('Verified subject: ${verified.sub}')
	println('Custom role:     ${verified.custom['role']}')
	assert verified.sub == 'admin_user_42'
	assert verified.custom['role'] == 'superadmin'

	// Simple token demo
	simple := jwtutils.sign_simple_token('worker_node_1', secret, 60) or { panic(err) }
	v_simple := jwtutils.verify_jwt(simple, secret) or { panic(err) }
	assert v_simple.sub == 'worker_node_1'
	println('Simple token verified for: ${v_simple.sub}')

	println('jwtutils demo completed successfully!')
}

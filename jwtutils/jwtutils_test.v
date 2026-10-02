module jwtutils

import time

fn test_sign_and_verify_jwt() {
	secret := 'my_super_secret_jwt_key_987654321'
	claims := JWTClaims{
		sub:    'user_123'
		iss:    'vlang_utils'
		exp:    time.now().unix() + 3600
		custom: {
			'role':  'admin'
			'scope': 'read:all write:all'
		}
	}

	token := sign_jwt(claims, secret) or { panic(err) }
	assert token.contains('.')

	verified := verify_jwt(token, secret) or { panic(err) }
	assert verified.sub == 'user_123'
	assert verified.iss == 'vlang_utils'
	assert verified.custom['role'] == 'admin'

	// Wrong secret must fail
	verify_jwt(token, 'wrong_secret') or {
		assert true
		return
	}
	assert false
}

fn test_expired_jwt() {
	secret := 'key_123'
	claims := JWTClaims{
		sub: 'expired_user'
		exp: time.now().unix() - 100 // Expired in past
	}

	token := sign_jwt(claims, secret) or { panic(err) }
	verify_jwt(token, secret) or {
		assert err.msg().contains('expired')
		return
	}
	assert false
}

fn test_simple_token() {
	token := sign_simple_token('guest_user', 'app_secret', 60) or { panic(err) }
	verified := verify_jwt(token, 'app_secret') or { panic(err) }
	assert verified.sub == 'guest_user'
}

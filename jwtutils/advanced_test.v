module jwtutils

import encoding.base64

const secret = 'top-secret-key'

fn test_rfc7515_hs256_signature_vector() {
	// RFC 7515 Appendix A.1 key and signing input.
	key := base64.url_decode('AyM1SysPpbyDfgZld3umj1qzKObwVMkoqQ-EstJQLr_T-1qS0gZH75aKtMN3Yj0iPS4hcgUuTwjAzZr1Z9CAow')
	input := 'eyJ0eXAiOiJKV1QiLA0KICJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJqb2UiLA0KICJleHAiOjEzMDA4MTkzODAsDQogImh0dHA6Ly9leGFtcGxlLmNvbS9pc19yb290Ijp0cnVlfQ'
	assert b64url(hmac_for(.hs256, key, input.bytes())) == 'dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk'
}

fn test_all_algorithms_roundtrip() {
	for alg in [JWTAlgorithm.hs256, .hs384, .hs512] {
		tok := sign_jwt_with(JWTClaims{ sub: 'u1', iss: 'me', aud: 'api' }, secret, alg)!
		c := verify_jwt_with(tok, secret, algorithm: alg, issuer: 'me', audience: 'api')!
		assert c.sub == 'u1'
	}
}

fn test_algorithm_mismatch_rejected() {
	tok := sign_jwt_with(JWTClaims{ sub: 'x' }, secret, .hs512)!
	if _ := verify_jwt(tok, secret) {
		assert false, 'HS512 token must not pass HS256 verification'
	}
	if _ := verify_jwt_with(tok, secret, algorithm: .hs256) {
		assert false
	}
}

fn test_alg_none_rejected() {
	header := b64url('{"alg":"none","typ":"JWT"}'.bytes())
	body := b64url('{"sub":"admin"}'.bytes())
	if _ := verify_jwt('${header}.${body}.', secret) {
		assert false, 'alg=none must be rejected'
	}
}

fn test_claim_policies() {
	tok := sign_jwt_with(JWTClaims{ sub: 'a', iss: 'good', aud: 'web', iat: 1000, exp: 2000 },
		secret, .hs256)!
	verify_jwt_with(tok, secret, now_unix: 1500)!
	if _ := verify_jwt_with(tok, secret, now_unix: 2001) {
		assert false, 'expired'
	}
	verify_jwt_with(tok, secret, now_unix: 2001, leeway_seconds: 5)!
	if _ := verify_jwt_with(tok, secret, now_unix: 1500, issuer: 'evil') {
		assert false
	}
	if _ := verify_jwt_with(tok, secret, now_unix: 1500, audience: 'mobile') {
		assert false
	}
	if _ := verify_jwt_with(tok, secret, now_unix: 1500, max_age_seconds: 100) {
		assert false
	}
	if _ := verify_jwt_with(tok, 'wrong', now_unix: 1500) {
		assert false
	}
}

fn test_require_exp_and_refresh() {
	tok := sign_jwt_with(JWTClaims{ sub: 'r' }, secret, .hs256)!
	if _ := verify_jwt_with(tok, secret, require_exp: true) {
		assert false
	}
	fresh := refresh_jwt(tok, secret, 60, now_unix: 5000)!
	c := decode_jwt_unverified(fresh)!
	assert c.iat == 5000
	assert c.exp == 5060
	assert c.sub == 'r'
}

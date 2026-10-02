module jwtutils

import crypto.hmac
import crypto.sha256
import encoding.base64
import json2
import time

// JWTClaims represents standard registered and custom JWT claims.
pub struct JWTClaims {
pub mut:
	sub    string
	iss    string
	aud    string
	exp    i64
	nbf    i64
	iat    i64
	custom map[string]string
}

struct JWTHeader {
	alg string = 'HS256'
	typ string = 'JWT'
}

// sign_jwt generates an encoded and cryptographically signed HS256 JWT string.
pub fn sign_jwt(claims JWTClaims, secret string) !string {
	if secret.len == 0 {
		return error('secret key cannot be empty')
	}

	header := JWTHeader{
		alg: 'HS256'
		typ: 'JWT'
	}
	header_json := json2.encode(header)
	claims_json := json2.encode(claims)

	header_b64 := base64.url_encode_str(header_json).trim_right('=')
	claims_b64 := base64.url_encode_str(claims_json).trim_right('=')

	unsigned_token := '${header_b64}.${claims_b64}'
	sig := hmac.new(secret.bytes(), unsigned_token.bytes(), sha256.sum, sha256.block_size)
	sig_b64 := base64.url_encode_str(sig.bytestr()).trim_right('=')

	return '${unsigned_token}.${sig_b64}'
}

// sign_simple_token signs a simple token with subject, secret, and validity TTL in seconds.
pub fn sign_simple_token(sub string, secret string, ttl_seconds i64) !string {
	now := time.now().unix()
	claims := JWTClaims{
		sub: sub
		iat: now
		exp: now + ttl_seconds
	}
	return sign_jwt(claims, secret)
}

// verify_jwt validates the signature and standard timestamps (exp, nbf) of a token, returning the parsed claims.
pub fn verify_jwt(token string, secret string) !JWTClaims {
	if secret.len == 0 {
		return error('secret key cannot be empty')
	}

	parts := token.split('.')
	if parts.len != 3 {
		return error('invalid JWT format: must consist of 3 parts')
	}

	header_b64, claims_b64, sig_b64 := parts[0], parts[1], parts[2]
	unsigned_token := '${header_b64}.${claims_b64}'

	expected_sig := hmac.new(secret.bytes(), unsigned_token.bytes(), sha256.sum, sha256.block_size)
	expected_b64 := base64.url_encode_str(expected_sig.bytestr()).trim_right('=')

	// Constant-time signature comparison
	if sig_b64.len != expected_b64.len {
		return error('invalid JWT signature')
	}
	mut diff := 0
	for i in 0 .. sig_b64.len {
		diff |= int(sig_b64[i] ^ expected_b64[i])
	}
	if diff != 0 {
		return error('invalid JWT signature')
	}

	// Decode claims
	claims_json := base64.url_decode_str(claims_b64)
	claims := json2.decode[JWTClaims](claims_json) or {
		return error('failed to parse claims JSON: ${err}')
	}

	now := time.now().unix()
	if claims.exp > 0 && now > claims.exp {
		return error('token has expired (exp: ${claims.exp}, now: ${now})')
	}
	if claims.nbf > 0 && now < claims.nbf {
		return error('token not yet active (nbf: ${claims.nbf}, now: ${now})')
	}

	return claims
}

module jwtutils

import crypto.hmac
import crypto.sha256
import crypto.sha512
import crypto.internal.subtle
import encoding.base64
import json2
import time

struct RawJWTHeader {
	alg string
	typ string
}

// JWTAlgorithm enumerates the supported HMAC signing algorithms.
pub enum JWTAlgorithm {
	hs256
	hs384
	hs512
}

// name returns the RFC 7518 identifier (e.g. `HS256`).
pub fn (a JWTAlgorithm) name() string {
	return match a {
		.hs256 { 'HS256' }
		.hs384 { 'HS384' }
		.hs512 { 'HS512' }
	}
}

// VerifyOptions configures `verify_jwt_with`.
@[params]
pub struct VerifyOptions {
pub:
	algorithm       JWTAlgorithm = .hs256
	leeway_seconds  i64    // tolerated clock skew for exp / nbf / iat
	issuer          string // when set, `iss` must match exactly
	audience        string // when set, `aud` must match exactly
	require_exp     bool   // reject tokens without an `exp` claim
	max_age_seconds i64    // when > 0, reject tokens whose `iat` is older than this
	now_unix        i64    // override "now" (testing); 0 = current time
}

fn b64url(data []u8) string {
	return base64.url_encode(data).trim_right('=')
}

fn hmac_for(alg JWTAlgorithm, key []u8, data []u8) []u8 {
	return match alg {
		.hs256 { hmac.new(key, data, sha256.sum, sha256.block_size) }
		.hs384 { hmac.new(key, data, sha512.sum384, sha512.block_size) }
		.hs512 { hmac.new(key, data, sha512.sum512, sha512.block_size) }
	}
}

fn check_header_alg(header_b64 string, expected string) ! {
	header_json := base64.url_decode_str(header_b64)
	header := json2.decode[RawJWTHeader](header_json) or {
		return error('invalid JWT header: ${err}')
	}
	if header.alg != expected {
		return error('unexpected JWT algorithm "${header.alg}" (expected ${expected})')
	}
}

// sign_jwt_with signs `claims` using the chosen HMAC algorithm (HS256/HS384/HS512).
pub fn sign_jwt_with(claims JWTClaims, secret string, alg JWTAlgorithm) !string {
	if secret.len == 0 {
		return error('secret key cannot be empty')
	}
	header_b64 := b64url('{"alg":"${alg.name()}","typ":"JWT"}'.bytes())
	claims_b64 := b64url(json2.encode(claims).bytes())
	unsigned_token := '${header_b64}.${claims_b64}'
	return '${unsigned_token}.${b64url(hmac_for(alg, secret.bytes(), unsigned_token.bytes()))}'
}

// decode_jwt_unverified parses the claims WITHOUT checking the signature.
// Only use it for routing/inspection; never trust its output for authorization.
pub fn decode_jwt_unverified(token string) !JWTClaims {
	parts := token.split('.')
	if parts.len != 3 {
		return error('invalid JWT format: must consist of 3 parts')
	}
	return json2.decode[JWTClaims](base64.url_decode_str(parts[1])) or {
		return error('failed to parse claims JSON: ${err}')
	}
}

// verify_jwt_with verifies signature, algorithm and registered claims according to `opts`.
pub fn verify_jwt_with(token string, secret string, opts VerifyOptions) !JWTClaims {
	if secret.len == 0 {
		return error('secret key cannot be empty')
	}
	parts := token.split('.')
	if parts.len != 3 {
		return error('invalid JWT format: must consist of 3 parts')
	}
	check_header_alg(parts[0], opts.algorithm.name())!
	unsigned_token := '${parts[0]}.${parts[1]}'
	expected := hmac_for(opts.algorithm, secret.bytes(), unsigned_token.bytes())
	given := base64.url_decode(parts[2])
	if subtle.constant_time_compare(given, expected) != 1 {
		return error('invalid JWT signature')
	}
	claims := json2.decode[JWTClaims](base64.url_decode_str(parts[1])) or {
		return error('failed to parse claims JSON: ${err}')
	}
	now := if opts.now_unix > 0 { opts.now_unix } else { time.now().unix() }
	leeway := if opts.leeway_seconds > 0 { opts.leeway_seconds } else { i64(0) }
	if opts.require_exp && claims.exp == 0 {
		return error('token is missing required exp claim')
	}
	if claims.exp > 0 && now > claims.exp + leeway {
		return error('token has expired (exp: ${claims.exp}, now: ${now})')
	}
	if claims.nbf > 0 && now + leeway < claims.nbf {
		return error('token not yet active (nbf: ${claims.nbf}, now: ${now})')
	}
	if claims.iat > 0 && claims.iat > now + leeway {
		return error('token issued in the future (iat: ${claims.iat}, now: ${now})')
	}
	if opts.max_age_seconds > 0
		&& (claims.iat == 0 || now - claims.iat > opts.max_age_seconds + leeway) {
		return error('token exceeds max age of ${opts.max_age_seconds}s')
	}
	if opts.issuer != '' && claims.iss != opts.issuer {
		return error('invalid issuer "${claims.iss}"')
	}
	if opts.audience != '' && claims.aud != opts.audience {
		return error('invalid audience "${claims.aud}"')
	}
	return claims
}

// refresh_jwt verifies `token` and re-issues it with a fresh iat/exp of `ttl_seconds`.
pub fn refresh_jwt(token string, secret string, ttl_seconds i64, opts VerifyOptions) !string {
	mut claims := verify_jwt_with(token, secret, opts)!
	now := if opts.now_unix > 0 { opts.now_unix } else { time.now().unix() }
	claims.iat = now
	claims.exp = now + ttl_seconds
	return sign_jwt_with(claims, secret, opts.algorithm)
}

module idutils

import time
import rand
import crypto.rand as crand

// -----------------------------------------------------------------------
// 1. ULID (Universally Unique Lexicographically Sortable Identifier)
// 128-bit identifier: 48-bit timestamp (ms) + 80-bit randomness
// Encoded using Crockford's Base32 (26 characters)
// -----------------------------------------------------------------------

const crockford_alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ'

// new_ulid generates a standard 26-character Crockford Base32 ULID at the current time.
pub fn new_ulid() string {
	return ulid_at_time(time.now())
}

// ulid_at_time generates a 26-character ULID for a specific timestamp.
pub fn ulid_at_time(t time.Time) string {
	ts_ms := u64(t.unix_milli())
	mut chars := []u8{len: 26}

	// 48-bit timestamp -> 10 characters (high to low)
	mut ts := ts_ms
	for i := 9; i >= 0; i-- {
		chars[i] = crockford_alphabet[int(ts & 0x1F)]
		ts >>= 5
	}

	// 80-bit random payload -> 16 characters
	rand_bytes := crand.bytes(10) or {
		// Fallback to PRNG if CSPRNG is unavailable
		mut b := []u8{len: 10}
		for mut val in b {
			val = u8(rand.u32n(256) or { 0 })
		}
		b
	}

	// Pack 10 bytes (80 bits) into 16 5-bit base32 chunks
	mut bit_buf := u64(0)
	mut bit_count := 0
	mut char_idx := 10

	for byte_val in rand_bytes {
		bit_buf = (bit_buf << 8) | u64(byte_val)
		bit_count += 8
		for bit_count >= 5 {
			bit_count -= 5
			idx := int((bit_buf >> bit_count) & 0x1F)
			chars[char_idx] = crockford_alphabet[idx]
			char_idx++
		}
	}
	if bit_count > 0 && char_idx < 26 {
		idx := int((bit_buf << (5 - bit_count)) & 0x1F)
		chars[char_idx] = crockford_alphabet[idx]
	}

	return chars.bytestr()
}

// is_valid_ulid checks if a string is a valid 26-character Crockford Base32 ULID.
pub fn is_valid_ulid(s string) bool {
	if s.len != 26 {
		return false
	}
	for b in s {
		c := if b >= `a` && b <= `z` { b - 32 } else { b }
		if c !in crockford_alphabet.bytes() {
			return false
		}
	}
	return true
}

// parse_ulid_time extracts the Unix millisecond timestamp from a ULID.
pub fn parse_ulid_time(s string) !time.Time {
	if s.len != 26 {
		return error('invalid ULID length: expected 26 chars')
	}
	mut ts := u64(0)
	for i in 0 .. 10 {
		mut b := s[i]
		if b >= `a` && b <= `z` {
			b -= 32
		}
		idx := crockford_alphabet.index_u8(b)
		if idx == -1 {
			return error('invalid character in ULID timestamp: ${b}')
		}
		ts = (ts << 5) | u64(idx)
	}
	return time.unix_milli(i64(ts))
}

// -----------------------------------------------------------------------
// 2. Twitter Snowflake 64-bit Distributed Unique ID Generator
// 1 bit unused | 41 bits timestamp | 10 bits machine/node ID | 12 bits sequence
// -----------------------------------------------------------------------

const default_epoch_ms = u64(1704067200000) // 2024-01-01 00:00:00 UTC

pub struct SnowflakeGenerator {
pub:
	node_id  u16
	epoch_ms u64
pub mut:
	last_timestamp u64
	sequence       u16
}

// new_snowflake_generator creates a generator for node_id (0..1023).
pub fn new_snowflake_generator(node_id u16) !&SnowflakeGenerator {
	if node_id > 1023 {
		return error('node_id must be between 0 and 1023')
	}
	return &SnowflakeGenerator{
		node_id:        node_id
		epoch_ms:       default_epoch_ms
		last_timestamp: 0
		sequence:       0
	}
}

// next_id generates the next unique 64-bit snowflake ID.
pub fn (mut g SnowflakeGenerator) next_id() !u64 {
	mut now_ms := u64(time.now().unix_milli())
	if now_ms < g.last_timestamp {
		return error('system clock moved backwards, refusing to generate id')
	}

	if now_ms == g.last_timestamp {
		g.sequence = (g.sequence + 1) & 0x0FFF // 12 bits = 4095 max
		if g.sequence == 0 {
			// Sequence overflow in same millisecond, wait for next ms
			for now_ms <= g.last_timestamp {
				time.sleep(100 * time.microsecond)
				now_ms = u64(time.now().unix_milli())
			}
		}
	} else {
		g.sequence = 0
	}

	g.last_timestamp = now_ms
	elapsed := now_ms - g.epoch_ms

	id := (elapsed << 22) | (u64(g.node_id & 0x03FF) << 12) | u64(g.sequence & 0x0FFF)
	return id
}

// parse_snowflake extracts the timestamp (unix ms), node_id, and sequence from an ID.
pub fn parse_snowflake(id u64, epoch_ms u64) (u64, u16, u16) {
	epoch := if epoch_ms == 0 { default_epoch_ms } else { epoch_ms }
	elapsed := id >> 22
	node_id := u16((id >> 12) & 0x03FF)
	sequence := u16(id & 0x0FFF)
	timestamp := elapsed + epoch
	return timestamp, node_id, sequence
}

// -----------------------------------------------------------------------
// 3. Sqids (formerly Hashids)
// URL-friendly, reversible integer obfuscation (e.g. 1042 -> "b9x")
// -----------------------------------------------------------------------

const default_sqids_alphabet = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'

pub struct SqidsOptions {
pub:
	alphabet   string = default_sqids_alphabet
	min_length int
}

pub struct Sqids {
pub:
	alphabet   string
	min_length int
}

// new_sqids creates a Sqids encoder/decoder with custom or default options.
pub fn new_sqids(opts SqidsOptions) !Sqids {
	mut alphabet := if opts.alphabet.len == 0 { default_sqids_alphabet } else { opts.alphabet }
	if alphabet.len < 3 {
		return error('alphabet length must be at least 3 characters')
	}
	// Check uniqueness
	mut seen := map[u8]bool{}
	for b in alphabet {
		if seen[b] {
			return error('alphabet contains duplicate characters')
		}
		seen[b] = true
	}
	return Sqids{
		alphabet:   alphabet
		min_length: opts.min_length
	}
}

// encode converts a list of non-negative integers into a unique ID string.
pub fn (s Sqids) encode(numbers []u64) !string {
	if numbers.len == 0 {
		return ''
	}
	mut alphabet := s.alphabet
	mut offset := u64(numbers.len)
	for i, num in numbers {
		offset += u64(alphabet[int(num % u64(alphabet.len))]) + u64(i)
	}
	offset %= u64(alphabet.len)

	// Rotate alphabet by offset
	prefix := alphabet[int(offset)]
	alphabet = alphabet[int(offset)..].str() + alphabet[..int(offset)].str()

	mut ret := [prefix]
	for i, num in numbers {
		// Encode number using current alphabet
		ret << s.encode_num(num, alphabet[1..].str())
		if i < numbers.len - 1 {
			ret << alphabet[0]
			alphabet = shuffle_alphabet(alphabet)
		}
	}

	mut res := ret.bytestr()
	if s.min_length > 0 && res.len < s.min_length {
		mut glue := alphabet[0]
		res += glue.ascii_str()
		for res.len < s.min_length {
			alphabet = shuffle_alphabet(alphabet)
			add_len := if s.min_length - res.len < alphabet.len {
				s.min_length - res.len
			} else {
				alphabet.len
			}
			res += alphabet[..add_len]
		}
	}

	return res
}

// decode decodes a Sqids string back into an array of integers.
pub fn (s Sqids) decode(id string) []u64 {
	if id.len == 0 {
		return []u64{}
	}
	for b in id {
		if s.alphabet.index_u8(b) == -1 {
			return []u64{}
		}
	}

	prefix := id[0]
	offset := s.alphabet.index_u8(prefix)
	if offset == -1 {
		return []u64{}
	}

	mut alphabet := s.alphabet[offset..].str() + s.alphabet[..offset].str()
	mut rem := id[1..]

	mut numbers := []u64{}

	for rem.len > 0 {
		separator := alphabet[0]
		mut chunk_len := 0
		for chunk_len < rem.len && rem[chunk_len] != separator {
			chunk_len++
		}
		chunk := rem[..chunk_len]
		if chunk.len == 0 {
			break
		}
		num := s.decode_num(chunk, alphabet[1..].str())
		numbers << num
		if chunk_len < rem.len {
			rem = rem[chunk_len + 1..]
			alphabet = shuffle_alphabet(alphabet)
		} else {
			break
		}
	}

	return numbers
}

fn (s Sqids) encode_num(num u64, alphabet string) []u8 {
	mut res := []u8{}
	mut n := num
	base := u64(alphabet.len)
	for {
		res << alphabet[int(n % base)]
		n /= base
		if n == 0 {
			break
		}
	}
	res.reverse_in_place()
	return res
}

fn (s Sqids) decode_num(str string, alphabet string) u64 {
	mut res := u64(0)
	base := u64(alphabet.len)
	for b in str {
		idx := alphabet.index_u8(b)
		if idx == -1 {
			return 0
		}
		res = res * base + u64(idx)
	}
	return res
}

fn shuffle_alphabet(alphabet string) string {
	mut chars := alphabet.bytes()
	mut i := 0
	mut j := chars.len - 1
	for j > 0 {
		r := (i * j + int(chars[i]) + int(chars[j])) % chars.len
		temp := chars[i]
		chars[i] = chars[r]
		chars[r] = temp
		i++
		j--
	}
	return chars.bytestr()
}

// Default convenience wrappers
pub fn sqids_encode(numbers []u64) !string {
	sq := new_sqids(SqidsOptions{})!
	return sq.encode(numbers)
}

pub fn sqids_decode(id string) []u64 {
	sq := new_sqids(SqidsOptions{}) or { return []u64{} }
	return sq.decode(id)
}

pub fn sqids_encode_one(num u64) !string {
	return sqids_encode([num])
}

pub fn sqids_decode_one(id string) !u64 {
	nums := sqids_decode(id)
	if nums.len == 0 {
		return error('failed to decode id: ${id}')
	}
	return nums[0]
}

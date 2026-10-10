module idutils

import time

fn test_ulid() {
	ulid := new_ulid()
	assert ulid.len == 26
	assert is_valid_ulid(ulid)
	assert !is_valid_ulid('invalid')

	now := time.now()
	ulid2 := ulid_at_time(now)
	parsed_time := parse_ulid_time(ulid2) or { panic(err) }
	diff := parsed_time.unix_milli() - now.unix_milli()
	assert diff >= -50 && diff <= 50
}

fn test_snowflake() {
	mut gen := new_snowflake_generator(42) or { panic(err) }
	id1 := gen.next_id() or { panic(err) }
	id2 := gen.next_id() or { panic(err) }
	assert id2 > id1

	_, node_id, _ := parse_snowflake(id1, 0)
	assert node_id == 42
}

fn test_sqids() {
	encoded := sqids_encode([u64(1), u64(2), u64(3)]) or { panic(err) }
	assert encoded.len > 0
	decoded := sqids_decode(encoded)
	assert decoded == [u64(1), u64(2), u64(3)]

	single_enc := sqids_encode_one(1042) or { panic(err) }
	single_dec := sqids_decode_one(single_enc) or { panic(err) }
	assert single_dec == 1042
}

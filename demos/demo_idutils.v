module main

import idutils
import time

fn main() {
	println('=== demo_idutils: Modern ID Generation & Obfuscation ===\n')

	// 1. ULID (Universally Unique Lexicographically Sortable Identifier)
	ulid := idutils.new_ulid()
	println('1. Generated ULID: ${ulid}')
	println('   Is valid: ${idutils.is_valid_ulid(ulid)}')
	parsed_time := idutils.parse_ulid_time(ulid) or { panic(err) }
	println('   Embedded timestamp: ${parsed_time.format_ss()}')

	// 2. Twitter Snowflake Distributed 64-bit ID
	mut gen := idutils.new_snowflake_generator(7) or { panic(err) }
	id1 := gen.next_id() or { panic(err) }
	id2 := gen.next_id() or { panic(err) }
	println('\n2. Generated Snowflake IDs:')
	println('   ID 1: ${id1}')
	println('   ID 2: ${id2}')
	ts, node, seq := idutils.parse_snowflake(id1, 0)
	println('   Parsed ID 1 -> Node: ${node}, Seq: ${seq}, Time: ${time.unix_milli(i64(ts)).format_ss()}')

	// 3. Sqids Reversible Obfuscation for Database IDs
	orig_id := u64(1042)
	encoded := idutils.sqids_encode_one(orig_id) or { panic(err) }
	decoded := idutils.sqids_decode_one(encoded) or { panic(err) }
	println('\n3. Sqids ID Obfuscation:')
	println('   Database ID: ${orig_id} -> Public URL Slug: "${encoded}" -> Decoded: ${decoded}')

	multi_ids := [u64(1), u64(99), u64(450)]
	multi_enc := idutils.sqids_encode(multi_ids) or { panic(err) }
	multi_dec := idutils.sqids_decode(multi_enc)
	println('   Multi-value: ${multi_ids} -> Slug: "${multi_enc}" -> Decoded: ${multi_dec}')

	println('\n=== demo_idutils completed successfully ===')
}

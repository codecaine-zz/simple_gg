module main

import bitutils

fn main() {
	println('=== bitutils Demo ===')
	mut bs := bitutils.new_bitset(16)
	bs.set(0)
	bs.set(7)
	bs.set(15)
	println('BitSet: ${bs.str()}')
	println('Bit count set: ${bs.count_set()}')
	assert bs.get(0) == true
	assert bs.get(1) == false
	assert bs.get(7) == true
	assert bs.get(15) == true

	// Bitwise operations
	mut bs2 := bitutils.new_bitset(16)
	bs2.set(7)
	bs2.set(8)
	and_bs := bs.and_op(bs2)
	assert and_bs.get(7) == true
	assert and_bs.get(0) == false

	println('Popcount of 42: ${bitutils.popcount(42)}')
	println('Binary of 42: ${bitutils.to_binary(42, 8)}')
	parsed := bitutils.from_binary('00101010') or { u64(0) }
	assert parsed == 42

	// Flag operations
	flags := u64(0)
	read_flag := u64(1 << 0)
	write_flag := u64(1 << 1)
	mut f := bitutils.set_flag(flags, read_flag)
	f = bitutils.set_flag(f, write_flag)
	assert bitutils.has_flag(f, read_flag)
	assert bitutils.has_flag(f, write_flag)

	println('bitutils demo completed successfully!')
}

module bitutils

import bitfield
import strconv
import strings

// BitSet provides a high-level wrapper over bitfield for efficient boolean flag management.
pub struct BitSet {
pub mut:
	bf bitfield.BitField
}

// new_bitset creates a BitSet of the specified bit capacity.
pub fn new_bitset(size int) BitSet {
	return BitSet{
		bf: bitfield.new(size)
	}
}

// from_binary_string creates a BitSet initialized from a string of '0's and '1's.
pub fn from_binary_string(s string) !BitSet {
	for ch in s {
		if ch != `0` && ch != `1` {
			return error('invalid binary digit: ${ch.ascii_str()}')
		}
	}
	return BitSet{
		bf: bitfield.from_str(s)
	}
}

// set turns ON the bit at index.
pub fn (mut b BitSet) set(index int) {
	b.bf.set_bit(index)
}

// clear turns OFF the bit at index.
pub fn (mut b BitSet) clear(index int) {
	b.bf.clear_bit(index)
}

// toggle inverts the bit at index.
pub fn (mut b BitSet) toggle(index int) {
	b.bf.toggle_bit(index)
}

// get returns true if the bit at index is set (1), false otherwise.
pub fn (b BitSet) get(index int) bool {
	return b.bf.get_bit(index) == 1
}

// size returns the total bit capacity.
pub fn (b BitSet) size() int {
	return b.bf.get_size()
}

// count_set returns the total number of bits set to 1 (popcount).
pub fn (b BitSet) count_set() int {
	return b.bf.pop_count()
}

// str returns the binary string representation of the BitSet.
pub fn (b BitSet) str() string {
	return b.bf.str()
}

// and_op performs bitwise AND with another BitSet.
pub fn (b BitSet) and_op(other BitSet) BitSet {
	return BitSet{
		bf: bitfield.bf_and(b.bf, other.bf)
	}
}

// or_op performs bitwise OR with another BitSet.
pub fn (b BitSet) or_op(other BitSet) BitSet {
	return BitSet{
		bf: bitfield.bf_or(b.bf, other.bf)
	}
}

// xor_op performs bitwise XOR with another BitSet.
pub fn (b BitSet) xor_op(other BitSet) BitSet {
	return BitSet{
		bf: bitfield.bf_xor(b.bf, other.bf)
	}
}

// not_op performs bitwise NOT, inverting all bits in the BitSet.
pub fn (b BitSet) not_op() BitSet {
	return BitSet{
		bf: bitfield.bf_not(b.bf)
	}
}

// popcount returns the number of 1 bits in an integer (Hamming weight).
pub fn popcount(n u64) int {
	mut val := n
	mut count := 0
	for val > 0 {
		count += int(val & 1)
		val >>= 1
	}
	return count
}

// to_binary returns the binary string representation of an unsigned integer with minimum bit padding.
pub fn to_binary(n u64, min_bits int) string {
	if n == 0 {
		return '0'.repeat(if min_bits > 0 { min_bits } else { 1 })
	}
	mut val := n
	mut chars := []string{}
	for val > 0 {
		chars << (val & 1).str()
		val >>= 1
	}
	chars.reverse_in_place()
	raw := chars.join('')
	if raw.len < min_bits {
		return strings.repeat(`0`, min_bits - raw.len) + raw
	}
	return raw
}

// from_binary parses a binary string into a u64 integer.
pub fn from_binary(s string) !u64 {
	return strconv.parse_uint(s, 2, 64)!
}

// has_flag checks if specific flag bits are set in flags.
pub fn has_flag(flags u64, flag u64) bool {
	return (flags & flag) == flag
}

// set_flag sets the given flag bits on flags and returns the new value.
pub fn set_flag(flags u64, flag u64) u64 {
	return flags | flag
}

// clear_flag clears the given flag bits from flags and returns the new value.
pub fn clear_flag(flags u64, flag u64) u64 {
	return flags & ~flag
}

// toggle_flag toggles the given flag bits in flags and returns the new value.
pub fn toggle_flag(flags u64, flag u64) u64 {
	return flags ^ flag
}

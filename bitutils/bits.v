module bitutils

import math.bits

// ============================================================================
// Word-level bit twiddling (the classic "Hacker's Delight" toolbox)
// ============================================================================

// leading_zeros counts zero bits above the highest set bit (64 for n == 0).
pub fn leading_zeros(n u64) int {
	return bits.leading_zeros_64(n)
}

// trailing_zeros counts zero bits below the lowest set bit (64 for n == 0).
pub fn trailing_zeros(n u64) int {
	return bits.trailing_zeros_64(n)
}

// bit_length returns the number of bits needed to represent n (0 for n == 0).
pub fn bit_length(n u64) int {
	return bits.len_64(n)
}

// is_power_of_two reports whether n is an exact power of two (0 is not).
pub fn is_power_of_two(n u64) bool {
	return n != 0 && n & (n - 1) == 0
}

// next_power_of_two returns the smallest power of two >= n (1 for n == 0),
// or 0 when the result does not fit in 64 bits.
pub fn next_power_of_two(n u64) u64 {
	if n <= 1 {
		return 1
	}
	if n > (u64(1) << 63) {
		return 0
	}
	return u64(1) << bits.len_64(n - 1)
}

// prev_power_of_two returns the largest power of two <= n (0 for n == 0).
pub fn prev_power_of_two(n u64) u64 {
	if n == 0 {
		return 0
	}
	return u64(1) << (bits.len_64(n) - 1)
}

// rotate_left rotates n left by k bits (negative k rotates right).
pub fn rotate_left(n u64, k int) u64 {
	return bits.rotate_left_64(n, k)
}

// rotate_right rotates n right by k bits.
pub fn rotate_right(n u64, k int) u64 {
	return bits.rotate_left_64(n, -k)
}

// reverse_bits mirrors the 64-bit word (bit 0 <-> bit 63).
pub fn reverse_bits(n u64) u64 {
	return bits.reverse_64(n)
}

// reverse_bytes swaps byte order (endianness conversion).
pub fn reverse_bytes(n u64) u64 {
	return bits.reverse_bytes_64(n)
}

// parity returns 1 if n has an odd number of set bits, else 0.
pub fn parity(n u64) int {
	return bits.ones_count_64(n) & 1
}

// hamming_distance counts differing bit positions between a and b.
pub fn hamming_distance(a u64, b u64) int {
	return bits.ones_count_64(a ^ b)
}

// lowest_set_bit isolates the lowest set bit (0 for n == 0).
pub fn lowest_set_bit(n u64) u64 {
	return n & (~n + 1)
}

// clear_lowest_set_bit clears the lowest set bit.
pub fn clear_lowest_set_bit(n u64) u64 {
	return if n == 0 { 0 } else { n & (n - 1) }
}

// extract_bits returns `len` bits of n starting at bit `start` (LSB = 0).
pub fn extract_bits(n u64, start int, len int) u64 {
	if start < 0 || start >= 64 || len <= 0 {
		return 0
	}
	shifted := n >> u64(start)
	return if len >= 64 { shifted } else { shifted & ((u64(1) << u64(len)) - 1) }
}

// insert_bits writes the low `len` bits of value into n at bit `start`.
pub fn insert_bits(n u64, start int, len int, value u64) u64 {
	if start < 0 || start >= 64 || len <= 0 {
		return n
	}
	w := if len > 64 - start { 64 - start } else { len }
	mask := (if w >= 64 { ~u64(0) } else { (u64(1) << u64(w)) - 1 }) << u64(start)
	return (n & ~mask) | ((value << u64(start)) & mask)
}

// gray_encode converts binary to reflected Gray code.
pub fn gray_encode(n u64) u64 {
	return n ^ (n >> 1)
}

// gray_decode converts reflected Gray code back to binary.
pub fn gray_decode(g u64) u64 {
	mut n := g
	mut shift := u64(1)
	for shift < 64 {
		n ^= n >> shift
		shift <<= 1
	}
	return n
}

fn spread_bits(x u32) u64 {
	mut v := u64(x)
	v = (v | (v << 16)) & 0x0000FFFF0000FFFF
	v = (v | (v << 8)) & 0x00FF00FF00FF00FF
	v = (v | (v << 4)) & 0x0F0F0F0F0F0F0F0F
	v = (v | (v << 2)) & 0x3333333333333333
	v = (v | (v << 1)) & 0x5555555555555555
	return v
}

fn compact_bits(x u64) u32 {
	mut v := x & 0x5555555555555555
	v = (v | (v >> 1)) & 0x3333333333333333
	v = (v | (v >> 2)) & 0x0F0F0F0F0F0F0F0F
	v = (v | (v >> 4)) & 0x00FF00FF00FF00FF
	v = (v | (v >> 8)) & 0x0000FFFF0000FFFF
	v = (v | (v >> 16)) & 0x00000000FFFFFFFF
	return u32(v)
}

// morton_encode_2d interleaves x and y into a Z-order curve index (spatial
// hashing / quadtrees / cache-friendly 2D layouts).
pub fn morton_encode_2d(x u32, y u32) u64 {
	return spread_bits(x) | (spread_bits(y) << 1)
}

// morton_decode_2d is the inverse of morton_encode_2d.
pub fn morton_decode_2d(code u64) (u32, u32) {
	return compact_bits(code), compact_bits(code >> 1)
}

// ============================================================================
// BitSet extensions
// ============================================================================

// set_indices returns the positions of all set bits in ascending order.
pub fn (b BitSet) set_indices() []int {
	mut out := []int{}
	for i in 0 .. b.size() {
		if b.get(i) {
			out << i
		}
	}
	return out
}

// any reports whether at least one bit is set.
pub fn (b BitSet) any() bool {
	return b.count_set() > 0
}

// none_set reports whether no bit is set.
pub fn (b BitSet) none_set() bool {
	return b.count_set() == 0
}

// all_set reports whether every bit is set.
pub fn (b BitSet) all_set() bool {
	return b.count_set() == b.size()
}

// count_clear returns the number of zero bits.
pub fn (b BitSet) count_clear() int {
	return b.size() - b.count_set()
}

// set_all turns every bit on.
pub fn (mut b BitSet) set_all() {
	b.bf.set_all()
}

// clear_all turns every bit off.
pub fn (mut b BitSet) clear_all() {
	b.bf.clear_all()
}

// set_range turns on bits [start, end) (clamped to the set's size).
pub fn (mut b BitSet) set_range(start int, end int) {
	for i in (if start < 0 {
		0
	} else {
		start
	}) .. (if end > b.size() {
		b.size()
	} else {
		end
	}) {
		b.bf.set_bit(i)
	}
}

// clone returns an independent copy.
pub fn (b BitSet) clone() BitSet {
	return BitSet{
		bf: b.bf.clone()
	}
}

// equals reports whether both sets have the same size and bits.
pub fn (b BitSet) equals(other BitSet) bool {
	return b.bf == other.bf
}

// is_subset_of reports whether every set bit of b is also set in other.
pub fn (b BitSet) is_subset_of(other BitSet) bool {
	for i in b.set_indices() {
		if !other.get(i) {
			return false
		}
	}
	return true
}

// difference returns bits set in b but not in other (b AND NOT other).
pub fn (b BitSet) difference(other BitSet) BitSet {
	mut out := b.clone()
	for i in b.set_indices() {
		if other.get(i) {
			out.clear(i)
		}
	}
	return out
}

// jaccard returns |A∩B| / |A∪B| (1.0 when both are empty).
pub fn (b BitSet) jaccard(other BitSet) f64 {
	u := b.or_op(other).count_set()
	if u == 0 {
		return 1.0
	}
	return f64(b.and_op(other).count_set()) / f64(u)
}

// to_bytes serializes the set (vlib bitfield byte layout).
pub fn (b BitSet) to_bytes() []u8 {
	return b.bf.bytes()
}

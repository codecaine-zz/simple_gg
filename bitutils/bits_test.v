module bitutils

import rand

fn test_word_ops() {
	assert leading_zeros(1) == 63 && leading_zeros(0) == 64
	assert trailing_zeros(8) == 3 && trailing_zeros(0) == 64
	assert bit_length(0) == 0 && bit_length(255) == 8 && bit_length(256) == 9
	assert is_power_of_two(1024) && !is_power_of_two(0) && !is_power_of_two(6)
	assert next_power_of_two(0) == 1 && next_power_of_two(5) == 8 && next_power_of_two(8) == 8
	assert next_power_of_two((u64(1) << 63) + 1) == 0
	assert prev_power_of_two(1000) == 512 && prev_power_of_two(0) == 0
	assert rotate_left(0x8000000000000001, 1) == 0x3
	assert rotate_right(0x3, 1) == 0x8000000000000001
	assert reverse_bits(1) == u64(1) << 63
	assert reverse_bytes(0x0102030405060708) == 0x0807060504030201
	assert parity(0b1011) == 1 && parity(0b11) == 0
	assert hamming_distance(0b1010, 0b0110) == 2
	assert lowest_set_bit(0b101000) == 0b1000 && lowest_set_bit(0) == 0
	assert clear_lowest_set_bit(0b101000) == 0b100000
	assert extract_bits(0xABCD, 4, 8) == 0xBC
	assert insert_bits(0xFFFF, 4, 8, 0x00) == 0xF00F
	assert insert_bits(0, 60, 8, 0xFF) == u64(0xF) << 60 // clipped at bit 63
}

fn test_gray_and_morton_roundtrip() {
	// Gray: consecutive codes differ in exactly one bit.
	for i in u64(0) .. 1000 {
		assert gray_decode(gray_encode(i)) == i
		assert hamming_distance(gray_encode(i), gray_encode(i + 1)) == 1
	}
	assert morton_encode_2d(0b11, 0b00) == 0b0101
	assert morton_encode_2d(0b00, 0b11) == 0b1010
	for _ in 0 .. 1000 {
		x, y := rand.u32(), rand.u32()
		dx, dy := morton_decode_2d(morton_encode_2d(x, y))
		assert dx == x && dy == y
	}
}

fn test_popcount_matches_naive() {
	for _ in 0 .. 1000 {
		n := rand.u64()
		mut c := 0
		for i in 0 .. 64 {
			c += int((n >> u64(i)) & 1)
		}
		assert popcount(n) == c
	}
}

fn test_bitset_extensions() {
	mut a := new_bitset(16)
	assert a.none_set() && !a.any()
	a.set_range(2, 6)
	assert a.set_indices() == [2, 3, 4, 5]
	assert a.count_clear() == 12
	mut b := new_bitset(16)
	b.set_range(4, 8)
	assert a.difference(b).set_indices() == [2, 3]
	assert a.jaccard(b) == 2.0 / 6.0
	mut sub := new_bitset(16)
	sub.set(3)
	assert sub.is_subset_of(a) && !a.is_subset_of(sub)
	c := a.clone()
	a.clear_all()
	assert c.count_set() == 4 && a.count_set() == 0 // clone is independent
	a.set_all()
	assert a.all_set()
	assert c.equals(c.clone()) && !c.equals(b)
	assert new_bitset(0).jaccard(new_bitset(0)) == 1.0
	assert c.to_bytes().len > 0
}

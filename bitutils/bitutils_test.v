module bitutils

fn test_bitset_basics() {
	mut bs := new_bitset(16)
	assert bs.size() == 16
	assert bs.count_set() == 0

	bs.set(2)
	bs.set(5)
	assert bs.get(2) == true
	assert bs.get(5) == true
	assert bs.get(3) == false
	assert bs.count_set() == 2

	bs.toggle(2)
	assert bs.get(2) == false
	assert bs.count_set() == 1

	bs.clear(5)
	assert bs.get(5) == false
	assert bs.count_set() == 0
}

fn test_bitset_logical_ops() {
	mut a := from_binary_string('1100') or { panic(err) }
	mut b := from_binary_string('1010') or { panic(err) }

	and_res := a.and_op(b)
	assert and_res.get(0) == true
	assert and_res.get(1) == false
	assert and_res.get(2) == false
	assert and_res.get(3) == false

	or_res := a.or_op(b)
	assert or_res.get(0) == true
	assert or_res.get(1) == true
	assert or_res.get(2) == true
	assert or_res.get(3) == false
}

fn test_numeric_flags_and_binary() {
	assert popcount(0b1011001) == 4
	assert popcount(0) == 0

	bin_str := to_binary(42, 8)
	assert bin_str == '00101010'
	parsed := from_binary('00101010') or { panic(err) }
	assert parsed == 42

	flag_read := u64(1)
	flag_write := u64(2)
	flag_exec := u64(4)

	mut perms := set_flag(0, flag_read)
	perms = set_flag(perms, flag_write)
	assert has_flag(perms, flag_read)
	assert has_flag(perms, flag_write)
	assert !has_flag(perms, flag_exec)

	perms = clear_flag(perms, flag_read)
	assert !has_flag(perms, flag_read)

	perms = toggle_flag(perms, flag_exec)
	assert has_flag(perms, flag_exec)
}

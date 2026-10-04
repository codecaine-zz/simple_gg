module mockutils

import time

fn luhn_ok(s string) bool {
	mut sum := 0
	for i := s.len - 1; i >= 0; i-- {
		mut d := int(s[i] - `0`)
		if (s.len - 1 - i) % 2 == 1 {
			d *= 2
			if d > 9 {
				d -= 9
			}
		}
		sum += d
	}
	return sum % 10 == 0
}

fn test_seeded_faker_is_deterministic() {
	mut a := new_faker(42)
	mut b := new_faker(42)
	mut c := new_faker(43)
	sa := [a.full_name(), a.email(), a.uuid_v4(), a.ipv4(), a.password(12)]
	sb := [b.full_name(), b.email(), b.uuid_v4(), b.ipv4(), b.password(12)]
	sc := [c.full_name(), c.email(), c.uuid_v4(), c.ipv4(), c.password(12)]
	assert sa == sb
	assert sa != sc
}

fn test_faker_formats() {
	mut f := new_faker(7)
	for _ in 0 .. 200 {
		n := f.int_between(-3, 3)
		assert n >= -3 && n <= 3
		u := f.uuid_v4()
		assert u.len == 36 && u[14] == `4` && u[19] in [`8`, `9`, `a`, `b`]
		cc := f.credit_card_number()
		assert cc.len == 16 && cc[0] == `4` && luhn_ok(cc)
		ip := f.ipv4()
		assert ip.starts_with('192.0.2.') || ip.starts_with('198.51.100.')
			|| ip.starts_with('203.0.113.')
		assert f.ipv6().starts_with('2001:db8:')
		mac := f.mac()
		first := ('0x' + mac[..2]).u8()
		assert mac.len == 17 && first & 0x02 == 0x02 && first & 0x01 == 0
		pw := f.password(12)
		assert pw.len == 12
		assert pw.bytes().any(it.is_digit()) && pw.bytes().any(it.is_capital())
		assert f.hex_color().len == 7
		assert f.zip_code().len == 5
		assert f.phone().contains('-555-01')
	}
	assert f.sentence(4).ends_with('.')
	assert f.int_between(5, 5) == 5
	assert f.pick_string([]) == ''
}

fn test_faker_dates_and_users() {
	mut f := new_faker(99)
	start := time.unix(1_600_000_000)
	end := time.unix(1_700_000_000)
	for _ in 0 .. 100 {
		d := f.date_between(start, end)
		assert d.unix() >= start.unix() && d.unix() < end.unix()
	}
	users := f.users(5)
	assert users.map(it.id) == [1, 2, 3, 4, 5]
	assert users.all(it.email.contains('@'))
	shuffled := f.shuffle_strings(['a', 'b', 'c', 'd'])
	mut sorted := shuffled.clone()
	sorted.sort()
	assert sorted == ['a', 'b', 'c', 'd']
}

fn test_one_shot_helpers() {
	assert mock_uuid().len == 36
	assert mock_ipv6().starts_with('2001:db8:')
	assert luhn_ok(mock_credit_card())
	assert mock_address().contains(',')
	assert mock_company().contains(' ')
	assert mock_mac().len == 17
	assert mock_hex_color().starts_with('#')
}

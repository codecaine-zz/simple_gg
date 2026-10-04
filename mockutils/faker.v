module mockutils

import rand
import rand.config
import time

const companies_a = ['Acme', 'Globex', 'Initech', 'Umbrella', 'Stark', 'Wayne', 'Hooli', 'Vandelay',
	'Soylent', 'Tyrell']
const companies_b = ['Labs', 'Systems', 'Industries', 'Dynamics', 'Analytics', 'Networks', 'Holdings',
	'Software']
const streets = ['Main St', 'Oak Ave', 'Maple Dr', 'Cedar Ln', 'Pine Rd', 'Elm St', 'Lake View',
	'Sunset Blvd']
const cities = ['Springfield', 'Riverton', 'Fairview', 'Lakeside', 'Georgetown', 'Franklin', 'Clinton',
	'Madison']
const country_codes = ['US', 'GB', 'DE', 'FR', 'JP', 'CA', 'AU', 'BR', 'IN', 'NL']
const faker_words = ['lorem', 'ipsum', 'dolor', 'sit', 'amet', 'consectetur', 'adipiscing', 'elit',
	'sed', 'do', 'eiusmod', 'tempor', 'incididunt', 'ut', 'labore', 'et', 'dolore', 'magna', 'aliqua']

// Faker generates realistic synthetic data. Created with a seed, it is fully
// deterministic: the same seed yields the same sequence on every run, which
// makes fixtures and property-based tests reproducible.
@[heap]
pub struct Faker {
mut:
	rng &rand.PRNG
}

// new_faker returns a deterministic generator for the given seed.
pub fn new_faker(seed u64) &Faker {
	return &Faker{
		rng: rand.new_default(config.PRNGConfigStruct{
			seed_: [u32(seed), u32(seed >> 32)]
		})
	}
}

// new_random_faker returns a generator seeded from the clock (non-reproducible).
pub fn new_random_faker() &Faker {
	return &Faker{
		rng: rand.new_default()
	}
}

// int_between returns an int in [min, max] (inclusive).
pub fn (mut f Faker) int_between(min int, max int) int {
	if max <= min {
		return min
	}
	return min + int(f.rng.u64n(u64(i64(max) - i64(min) + 1)) or { 0 })
}

// f64_between returns a float in [min, max).
pub fn (mut f Faker) f64_between(min f64, max f64) f64 {
	return min + f.rng.f64() * (max - min)
}

// boolean returns true with the given probability (0.0..1.0).
pub fn (mut f Faker) boolean(probability f64) bool {
	return f.rng.f64() < probability
}

// pick_string returns a random element of items ('' when empty).
pub fn (mut f Faker) pick_string(items []string) string {
	if items.len == 0 {
		return ''
	}
	return items[f.int_between(0, items.len - 1)]
}

// shuffle_strings returns a shuffled copy (Fisher–Yates).
pub fn (mut f Faker) shuffle_strings(items []string) []string {
	mut out := items.clone()
	for i := out.len - 1; i > 0; i-- {
		j := f.int_between(0, i)
		out[i], out[j] = out[j], out[i]
	}
	return out
}

pub fn (mut f Faker) first_name() string {
	return f.pick_string(first_names)
}

pub fn (mut f Faker) last_name() string {
	return f.pick_string(last_names)
}

pub fn (mut f Faker) full_name() string {
	return '${f.first_name()} ${f.last_name()}'
}

// username returns e.g. `alice_smith42`.
pub fn (mut f Faker) username() string {
	return '${f.first_name().to_lower()}_${f.last_name().to_lower()}${f.int_between(1, 99)}'
}

pub fn (mut f Faker) email() string {
	return '${f.first_name().to_lower()}.${f.last_name().to_lower()}${f.int_between(10, 999)}@${f.pick_string(domains)}'
}

// phone returns a North American number in the reserved 555-01xx fictional range.
pub fn (mut f Faker) phone() string {
	return '+1-${f.int_between(200, 999)}-555-01${f.int_between(0, 99):02}'
}

pub fn (mut f Faker) company() string {
	return '${f.pick_string(companies_a)} ${f.pick_string(companies_b)}'
}

pub fn (mut f Faker) street_address() string {
	return '${f.int_between(1, 9999)} ${f.pick_string(streets)}'
}

pub fn (mut f Faker) city() string {
	return f.pick_string(cities)
}

pub fn (mut f Faker) country_code() string {
	return f.pick_string(country_codes)
}

pub fn (mut f Faker) zip_code() string {
	return '${f.int_between(0, 99999):05}'
}

// ipv4 returns an address from the documentation ranges (RFC 5737), so test
// data never points at real hosts.
pub fn (mut f Faker) ipv4() string {
	prefix := f.pick_string(['192.0.2', '198.51.100', '203.0.113'])
	return '${prefix}.${f.int_between(1, 254)}'
}

// ipv6 returns an address in the documentation prefix 2001:db8::/32 (RFC 3849).
pub fn (mut f Faker) ipv6() string {
	mut groups := ['2001', 'db8']
	for _ in 0 .. 6 {
		groups << '${f.int_between(0, 0xffff):x}'
	}
	return groups.join(':')
}

// mac returns a locally-administered unicast MAC address.
pub fn (mut f Faker) mac() string {
	mut b := []string{}
	for i in 0 .. 6 {
		mut v := f.int_between(0, 255)
		if i == 0 {
			v = (v | 0x02) & 0xfe
		}
		b << '${v:02x}'
	}
	return b.join(':')
}

// url returns an https URL on a reserved example domain.
pub fn (mut f Faker) url() string {
	return 'https://${f.pick_string(domains)}/${f.word()}/${f.int_between(1, 9999)}'
}

// uuid_v4 returns an RFC 9562 version-4 UUID drawn from this generator.
pub fn (mut f Faker) uuid_v4() string {
	mut b := []u8{len: 16}
	for i in 0 .. 16 {
		b[i] = u8(f.int_between(0, 255))
	}
	b[6] = (b[6] & 0x0f) | 0x40
	b[8] = (b[8] & 0x3f) | 0x80
	h := b.hex()
	return '${h[..8]}-${h[8..12]}-${h[12..16]}-${h[16..20]}-${h[20..]}'
}

// hex_color returns e.g. `#1a2b3c`.
pub fn (mut f Faker) hex_color() string {
	return '#${f.int_between(0, 0xffffff):06x}'
}

pub fn (mut f Faker) word() string {
	return f.pick_string(faker_words)
}

// sentence returns a capitalised sentence of n words.
pub fn (mut f Faker) sentence(n int) string {
	count := if n <= 0 { 6 } else { n }
	mut ws := []string{cap: count}
	for _ in 0 .. count {
		ws << f.word()
	}
	s := ws.join(' ')
	return s[..1].to_upper() + s[1..] + '.'
}

pub fn (mut f Faker) paragraph(sentences int) string {
	count := if sentences <= 0 { 3 } else { sentences }
	mut out := []string{cap: count}
	for _ in 0 .. count {
		out << f.sentence(f.int_between(5, 12))
	}
	return out.join(' ')
}

// password returns a password of length n containing lower, upper, digit and
// symbol characters. Deterministic: for test fixtures only, never real secrets.
pub fn (mut f Faker) password(n int) string {
	length := if n < 4 { 4 } else { n }
	sets := ['abcdefghijkmnopqrstuvwxyz', 'ABCDEFGHJKLMNPQRSTUVWXYZ', '23456789', '!@#%^&*-_=+']
	mut chars := []string{}
	for s in sets {
		chars << s[f.int_between(0, s.len - 1)].ascii_str()
	}
	all := sets.join('')
	for chars.len < length {
		chars << all[f.int_between(0, all.len - 1)].ascii_str()
	}
	return f.shuffle_strings(chars).join('')
}

// credit_card_number returns a Luhn-valid 16-digit number with the Visa test
// prefix 4 (passes format validation, belongs to no real account).
pub fn (mut f Faker) credit_card_number() string {
	mut digits := [4]
	for _ in 0 .. 14 {
		digits << f.int_between(0, 9)
	}
	mut sum := 0
	for i := digits.len - 1; i >= 0; i-- {
		mut d := digits[i]
		if (digits.len - 1 - i) % 2 == 0 {
			d *= 2
			if d > 9 {
				d -= 9
			}
		}
		sum += d
	}
	digits << (10 - sum % 10) % 10
	return digits.map(it.str()).join('')
}

// date_between returns a time uniformly between start and end.
pub fn (mut f Faker) date_between(start time.Time, end time.Time) time.Time {
	a, b := start.unix(), end.unix()
	if b <= a {
		return start
	}
	off := f.rng.u64n(u64(b - a)) or { 0 }
	return time.unix(a + i64(off))
}

// past_date returns a time within the last `days` days.
pub fn (mut f Faker) past_date(days int) time.Time {
	now := time.now()
	return f.date_between(now.add_days(-days), now)
}

// user returns a synthetic profile.
pub fn (mut f Faker) user() MockUser {
	return MockUser{
		id:    f.int_between(1000, 9999)
		name:  f.full_name()
		email: f.email()
		phone: f.phone()
		ip:    f.ipv4()
		role:  f.pick_string(roles)
	}
}

// users returns n profiles with sequential ids starting at 1.
pub fn (mut f Faker) users(n int) []MockUser {
	mut out := []MockUser{cap: n}
	for i in 0 .. n {
		u := f.user()
		out << MockUser{
			...u
			id: i + 1
		}
	}
	return out
}

// ---------------------------------------------------------------------------
// Unseeded one-shot helpers
// ---------------------------------------------------------------------------

pub fn mock_uuid() string {
	mut f := new_random_faker()
	return f.uuid_v4()
}

pub fn mock_ipv6() string {
	mut f := new_random_faker()
	return f.ipv6()
}

pub fn mock_mac() string {
	mut f := new_random_faker()
	return f.mac()
}

pub fn mock_company() string {
	mut f := new_random_faker()
	return f.company()
}

pub fn mock_address() string {
	mut f := new_random_faker()
	return '${f.street_address()}, ${f.city()} ${f.zip_code()}'
}

pub fn mock_credit_card() string {
	mut f := new_random_faker()
	return f.credit_card_number()
}

pub fn mock_hex_color() string {
	mut f := new_random_faker()
	return f.hex_color()
}

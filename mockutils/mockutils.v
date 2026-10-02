module mockutils

import strings.lorem
import rand

// MockUser represents synthetic profile data for testing, prototyping, and seeds.
pub struct MockUser {
pub:
	id    int
	name  string
	email string
	phone string
	ip    string
	role  string
}

const first_names = [
	'Alice',
	'Bob',
	'Charlie',
	'Diana',
	'Edward',
	'Fiona',
	'George',
	'Hannah',
	'Isaac',
	'Julia',
	'Kevin',
	'Laura',
	'Marcus',
	'Nora',
	'Oscar',
	'Penny',
]

const last_names = [
	'Smith',
	'Johnson',
	'Williams',
	'Brown',
	'Jones',
	'Miller',
	'Davis',
	'Wilson',
	'Taylor',
	'Anderson',
	'Thomas',
	'Jackson',
	'White',
	'Harris',
	'Martin',
	'Thompson',
]

const roles = ['admin', 'developer', 'editor', 'viewer', 'guest', 'tester']

const domains = ['example.com', 'test.org', 'dev.io', 'mail.net', 'sample.co']

// lorem_text generates pseudo-random text using specified layout parameters.
pub fn lorem_text(paragraphs int, sentences int, words int) string {
	p := if paragraphs <= 0 { 1 } else { paragraphs }
	s := if sentences <= 0 { 3 } else { sentences }
	w := if words <= 0 { 8 } else { words }
	return lorem.generate(lorem.LoremCfg{
		paragraphs:              p
		sentences_per_paragraph: s
		words_per_sentence:      w
	})
}

// lorem_words generates a string containing approximately count words.
pub fn lorem_words(count int) string {
	c := if count <= 0 { 5 } else { count }
	return lorem.generate(lorem.LoremCfg{
		paragraphs:              1
		sentences_per_paragraph: 1
		words_per_sentence:      c
	})
}

// lorem_sentence generates a single lorem sentence.
pub fn lorem_sentence() string {
	return lorem.generate(lorem.LoremCfg{
		paragraphs:              1
		sentences_per_paragraph: 1
		words_per_sentence:      7
	})
}

// mock_first_name returns a random common first name.
pub fn mock_first_name() string {
	idx := rand.int_in_range(0, mockutils.first_names.len) or { 0 }
	return mockutils.first_names[idx]
}

// mock_last_name returns a random common last name.
pub fn mock_last_name() string {
	idx := rand.int_in_range(0, mockutils.last_names.len) or { 0 }
	return mockutils.last_names[idx]
}

// mock_full_name returns a random full name.
pub fn mock_full_name() string {
	return '${mock_first_name()} ${mock_last_name()}'
}

// mock_email returns a synthetic valid email address.
pub fn mock_email() string {
	first := mock_first_name().to_lower()
	last := mock_last_name().to_lower()
	num := rand.int_in_range(10, 999) or { 42 }
	d_idx := rand.int_in_range(0, mockutils.domains.len) or { 0 }
	return '${first}.${last}${num}@${mockutils.domains[d_idx]}'
}

// mock_phone returns a synthetic telephone number in format "+1-XXX-555-XXXX".
pub fn mock_phone() string {
	area := rand.int_in_range(200, 999) or { 555 }
	line := rand.int_in_range(1000, 9999) or { 1234 }
	return '+1-${area}-555-${line}'
}

// mock_ipv4 returns a random valid IPv4 address.
pub fn mock_ipv4() string {
	o1 := rand.int_in_range(1, 255) or { 192 }
	o2 := rand.int_in_range(0, 255) or { 168 }
	o3 := rand.int_in_range(0, 255) or { 1 }
	o4 := rand.int_in_range(1, 254) or { 100 }
	return '${o1}.${o2}.${o3}.${o4}'
}

// mock_url returns a synthetic URL.
pub fn mock_url() string {
	proto := if (rand.int_in_range(0, 2) or { 0 }) == 1 { 'https' } else { 'http' }
	d_idx := rand.int_in_range(0, mockutils.domains.len) or { 0 }
	slug := mock_first_name().to_lower()
	return '${proto}://${mockutils.domains[d_idx]}/${slug}'
}

// mock_user returns a populated synthetic user profile.
pub fn mock_user() MockUser {
	id := rand.int_in_range(1000, 9999) or { 1001 }
	name := mock_full_name()
	email := mock_email()
	phone := mock_phone()
	ip := mock_ipv4()
	r_idx := rand.int_in_range(0, mockutils.roles.len) or { 0 }
	return MockUser{
		id:    id
		name:  name
		email: email
		phone: phone
		ip:    ip
		role:  mockutils.roles[r_idx]
	}
}

// mock_users generates an array of count synthetic user profiles.
pub fn mock_users(count int) []MockUser {
	c := if count <= 0 { 1 } else { count }
	mut users := []MockUser{cap: c}
	for i in 0 .. c {
		u := mock_user()
		users << MockUser{
			id:    i + 1
			name:  u.name
			email: u.email
			phone: u.phone
			ip:    u.ip
			role:  u.role
		}
	}
	return users
}

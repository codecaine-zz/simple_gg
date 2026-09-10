module main

import mockutils

fn main() {
	println('==================================================')
	println('                demo_mockutils                    ')
	println('==================================================')

	// 1. Synthetic Name & Identity
	println('1. Synthetic Identity:')
	println('  First name: ${mockutils.mock_first_name()}')
	println('  Last name:  ${mockutils.mock_last_name()}')
	println('  Full name:  ${mockutils.mock_full_name()}')

	// 2. Synthetic Contact & Network Data
	println('\n2. Synthetic Contact & Network Info:')
	println('  Email:      ${mockutils.mock_email()}')
	println('  Phone:      ${mockutils.mock_phone()}')
	println('  IPv4:       ${mockutils.mock_ipv4()}')
	println('  URL:        ${mockutils.mock_url()}')

	// 3. User Profiles
	println('\n3. Mock User Profiles:')
	user := mockutils.mock_user()
	println('  Single User: ID=${user.id}, Name="${user.name}", Role=${user.role}, Email=${user.email}')

	users := mockutils.mock_users(3)
	println('  Batch Users (count=${users.len}):')
	for u in users {
		println('    [#${u.id}] ${u.name:18} | ${u.role:10} | ${u.email}')
	}

	// 4. Lorem Ipsum Generation
	println('\n4. Lorem Ipsum Text:')
	println('  Words (5):     ${mockutils.lorem_words(5)}')
	println('  Sentence:      ${mockutils.lorem_sentence()}')
	println('  Text (1p,2s):  ${mockutils.lorem_text(1, 2, 6)}')

	println('\n✔ mockutils demo completed successfully!')
}

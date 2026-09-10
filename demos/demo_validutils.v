module main

import validutils

fn main() {
	println('==================================================')
	println('               demo_validutils                    ')
	println('==================================================')

	// 1. Email validation
	println('1. Email Validation:')
	println('  user@domain.com  -> ${validutils.validate_email('user@domain.com')}')
	println('  invalid-email    -> ${validutils.validate_email('invalid-email')}')

	// 2. URL validation
	println('\n2. URL Validation:')
	println('  https://vlang.io -> ${validutils.validate_url('https://vlang.io')}')
	println('  ftp://vlang.io   -> ${validutils.validate_url('ftp://vlang.io')}')

	// 3. IP validation
	println('\n3. IP Validation:')
	println('  192.168.1.1      -> ${validutils.validate_ip('192.168.1.1')}')
	println('  999.0.0.1        -> ${validutils.validate_ip('999.0.0.1')}')

	// 4. Phone validation
	println('\n4. Phone Validation:')
	println('  +1 (555) 123-4567 -> ${validutils.validate_phone('+1 (555) 123-4567')}')
	println('  123               -> ${validutils.validate_phone('123')}')

	// 5. UUID validation
	println('\n5. UUID Validation:')
	println('  123e4567-e89b-12d3-a456-426614174000 -> ${validutils.validate_uuid('123e4567-e89b-12d3-a456-426614174000')}')
	println('  not-a-uuid                           -> ${validutils.validate_uuid('not-a-uuid')}')

	// 6. JSON validation
	println('\n6. JSON Validation:')
	println('  {"valid": true}  -> ${validutils.validate_json('{"valid": true}')}')
	println('  {invalid json}   -> ${validutils.validate_json('{invalid json}')}')

	// 7. Range and length
	println('\n7. Range & Length Checks:')
	println('  validate_numeric_range(42.0, 1.0, 100.0) -> ${validutils.validate_numeric_range(42.0, 1.0, 100.0)}')
	println('  validate_length("antigravity", 3, 20)    -> ${validutils.validate_length('antigravity', 3, 20)}')

	println('\n✔ validutils demo completed successfully!')
}

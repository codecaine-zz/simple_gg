module semverutils

fn sat(v string, r string) bool {
	return satisfies(parse(v) or { panic(err) }, r) or { panic(err) }
}

fn test_strict_parse_validation() {
	assert is_valid('1.0.0-alpha.1+build.5')
	assert !is_valid('1.0.0-')
	assert !is_valid('1.0.0+')
	assert !is_valid('1.0.0-alpha..1')
	assert !is_valid('1.0.0-01')
	assert !is_valid('1.0.0-al$pha')
	assert !is_valid('1.2')
	assert is_valid('1.0.0-0a') // alphanumeric identifiers may start with 0
}

fn test_spec_precedence_chain() {
	chain := ['1.0.0-alpha', '1.0.0-alpha.1', '1.0.0-alpha.beta', '1.0.0-beta', '1.0.0-beta.2',
		'1.0.0-beta.11', '1.0.0-rc.1', '1.0.0']
	for i in 0 .. chain.len - 1 {
		assert compare_str(chain[i], chain[i + 1])! < 0, '${chain[i]} < ${chain[i + 1]}'
	}
	sorted := sort_versions(['1.0.0', '1.0.0-rc.1', '0.9.9', '1.0.0-beta.11', '1.0.0-beta.2'])!
	assert sorted.map(it.str()) == ['0.9.9', '1.0.0-beta.2', '1.0.0-beta.11', '1.0.0-rc.1', '1.0.0']
}

fn test_npm_ranges() {
	assert sat('1.5.0', '1.x')
	assert !sat('2.0.0', '1.x')
	assert sat('1.2.9', '1.2.x')
	assert !sat('1.3.0', '1.2.*')
	assert sat('3.1.4', '*')
	assert sat('0.2.5', '^0.2')
	assert !sat('0.3.0', '^0.2')
	assert sat('1.9.0', '^1.2')
	assert !sat('2.0.0-beta', '^1.2.0')
	assert sat('0.0.3', '^0.0.3')
	assert !sat('0.0.4', '^0.0.3')
	assert sat('1.2.7', '~1.2')
	assert sat('1.2.7', '~> 1.2.3')
	assert sat('1.4.0', '1.2.3 - 1.4')
	assert sat('1.4.9', '1.2.3 - 1.4')
	assert !sat('1.5.0', '1.2.3 - 1.4')
	assert !sat('1.2.2', '1.2.3 - 2.3.4')
	assert sat('2.3.4', '1.2.3 - 2.3.4')
	assert sat('1.5.0', '>= 1.2.0 < 2.0.0')
	assert sat('3.0.0', '^1.0.0 || ^3.0.0')
	assert !sat('2.0.0', '^1.0.0 || ^3.0.0')
	assert sat('2.0.0', '>1.x')
	assert !sat('1.9.9', '>1.x')
	assert sat('0.9.0', '<1.x')
	assert sat('1.9.9', '<=1.x')
	assert !sat('1.0.0', '<1')
	assert is_valid_range('>=1.0.0 <2 || 3.x')
	assert !is_valid_range('>= ')
	assert !is_valid_range('1.a.0')
}

fn test_helpers() {
	assert coerce('v2')!.str() == '2.0.0'
	assert coerce('release-1.4')!.str() == '1.4.0'
	assert coerce('1.2.3.4')!.str() == '1.2.3'
	if _ := coerce('none') {
		assert false
	}
	vs := ['1.0.0', '1.2.0', '1.9.3', '2.0.0', 'garbage']
	assert max_satisfying(vs, '^1.0.0')?.str() == '1.9.3'
	assert min_satisfying(vs, '>=1.1.0')?.str() == '1.2.0'
	assert max_satisfying(vs, '^5.0.0') == none
	assert diff(parse('1.2.3')!, parse('1.3.0')!) == 'minor'
	assert diff(parse('1.2.3-a')!, parse('1.2.3-b')!) == 'prerelease'
	assert diff(parse('1.2.3')!, parse('1.2.3')!) == 'none'
}

module semverutils

fn test_semver_parse_and_str() {
	v1 := parse('1.2.3')!
	assert v1.major == 1
	assert v1.minor == 2
	assert v1.patch == 3
	assert v1.prerelease == ''
	assert v1.build == ''
	assert v1.str() == '1.2.3'

	v2 := parse('v2.0.1-rc.1+build.42')!
	assert v2.major == 2
	assert v2.minor == 0
	assert v2.patch == 1
	assert v2.prerelease == 'rc.1'
	assert v2.build == 'build.42'
	assert v2.str() == '2.0.1-rc.1+build.42'
}

fn test_semver_precedence_and_comparison() {
	// 1.0.0-alpha < 1.0.0-alpha.1 < 1.0.0-beta < 1.0.0
	va := parse('1.0.0-alpha')!
	va1 := parse('1.0.0-alpha.1')!
	vb := parse('1.0.0-beta')!
	v_norm := parse('1.0.0')!

	assert compare(va, va1) < 0
	assert compare(va1, vb) < 0
	assert compare(vb, v_norm) < 0
	assert compare(v_norm, vb) > 0
	assert compare(va, va) == 0

	// Build metadata is ignored in comparison
	b1 := parse('1.0.0+20130313144700')!
	b2 := parse('1.0.0+exp.sha.5114f85')!
	assert compare(b1, b2) == 0

	assert is_newer('2.0.0', '1.9.9')! == true
	assert is_newer('1.0.0', '1.0.1')! == false
}

fn test_semver_bumping() {
	v := parse('1.2.3-beta.1')!

	assert bump_patch(v).str() == '1.2.4'
	assert bump_minor(v).str() == '1.3.0'
	assert bump_major(v).str() == '2.0.0'
	assert bump_prerelease(v, 'rc.1').str() == '1.2.3-rc.1'
}

fn test_semver_satisfies_ranges() {
	v123 := parse('1.2.3')!
	v130 := parse('1.3.0')!
	v200 := parse('2.0.0')!

	// Caret ^
	assert satisfies(v123, '^1.0.0')! == true
	assert satisfies(v130, '^1.2.0')! == true
	assert satisfies(v200, '^1.2.0')! == false

	// Tilde ~
	assert satisfies(v123, '~1.2.0')! == true
	assert satisfies(v130, '~1.2.0')! == false

	// Comparison operators
	assert satisfies(v123, '>=1.2.0')! == true
	assert satisfies(v123, '<1.2.0')! == false
	assert satisfies(v123, '>=1.0.0 <2.0.0')! == true
	assert satisfies(v200, '>=1.0.0 <2.0.0')! == false
}

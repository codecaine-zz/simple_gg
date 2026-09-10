module main

import semverutils

fn main() {
	println('==================================================')
	println('               demo_semverutils                   ')
	println('==================================================')

	// 1. Parsing SemVer 2.0.0
	ver_str := '1.2.3-beta.1+build.42'
	v := semverutils.parse(ver_str)!
	println('Parsed: "${ver_str}"')
	println('  Major:      ${v.major}')
	println('  Minor:      ${v.minor}')
	println('  Patch:      ${v.patch}')
	println('  Prerelease: ${v.prerelease}')
	println('  Build:      ${v.build}')
	assert v.major == 1
	assert v.minor == 2
	assert v.patch == 3
	assert v.prerelease == 'beta.1'

	// 2. Bumping Versions
	bump_patch := semverutils.bump_patch(v)
	bump_minor := semverutils.bump_minor(v)
	bump_major := semverutils.bump_major(v)
	println('\nVersion Bumps:')
	println('  Bump Patch: ${bump_patch.str()}')
	println('  Bump Minor: ${bump_minor.str()}')
	println('  Bump Major: ${bump_major.str()}')
	assert bump_patch.str() == '1.2.4'
	assert bump_minor.str() == '1.3.0'
	assert bump_major.str() == '2.0.0'

	// 3. Comparison
	v1 := semverutils.parse('1.2.0')!
	v2 := semverutils.parse('1.3.0')!
	comp := semverutils.compare(v1, v2)
	println('\nCompare 1.2.0 vs 1.3.0: ${comp} (negative means v1 < v2)')
	assert comp < 0

	// 4. Range Satisfaction
	check1 := semverutils.satisfies(v, '^1.2.0')!
	check2 := semverutils.satisfies(v, '>=2.0.0')!
	println('\nRange Matching:')
	println('  1.2.3 satisfies "^1.2.0":  ${check1}')
	println('  1.2.3 satisfies ">=2.0.0": ${check2}')
	assert check1 == true
	assert check2 == false

	println('\n✔ semverutils demo completed successfully!')
}

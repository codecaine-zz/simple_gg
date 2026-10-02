module semverutils

// SemVer represents a semantic version adhering to the SemVer 2.0.0 specification.
pub struct SemVer {
pub:
	major      int
	minor      int
	patch      int
	prerelease string
	build      string
}

// str formats the SemVer back into standard string representation.
pub fn (s SemVer) str() string {
	mut res := '${s.major}.${s.minor}.${s.patch}'
	if s.prerelease.len > 0 {
		res += '-${s.prerelease}'
	}
	if s.build.len > 0 {
		res += '+${s.build}'
	}
	return res
}

// parse parses a semantic version string (e.g. "1.2.3", "v2.0.0-beta.1+build.2026").
pub fn parse(raw string) !SemVer {
	mut s := raw.trim_space()
	if s.len == 0 {
		return error('Version string cannot be empty')
	}
	if s.starts_with('v') || s.starts_with('V') {
		s = s[1..]
	}

	// Extract build metadata (+...)
	mut build := ''
	if s.contains('+') {
		before, after := s.split_once('+') or { s, '' }
		s = before
		build = after
	}

	// Extract prerelease (-...)
	mut prerelease := ''
	if s.contains('-') {
		before, after := s.split_once('-') or { s, '' }
		s = before
		prerelease = after
	}

	// Parse major.minor.patch
	segments := s.split('.')
	if segments.len != 3 {
		return error('Invalid semantic version format "${raw}", expected X.Y.Z')
	}

	major := segments[0].int()
	minor := segments[1].int()
	patch := segments[2].int()

	if segments[0] != '${major}' || segments[1] != '${minor}' || segments[2] != '${patch}' {
		return error('Semantic version numbers must be valid non-negative integers')
	}
	if major < 0 || minor < 0 || patch < 0 {
		return error('Semantic version numbers cannot be negative')
	}

	return SemVer{
		major:      major
		minor:      minor
		patch:      patch
		prerelease: prerelease
		build:      build
	}
}

// compare compares two SemVer versions according to SemVer 2.0.0 precedence rules.
// Returns -1 if a < b, 0 if a == b, and 1 if a > b.
// Note: Build metadata is explicitly ignored in precedence comparison.
pub fn compare(a SemVer, b SemVer) int {
	if a.major != b.major {
		return if a.major < b.major { -1 } else { 1 }
	}
	if a.minor != b.minor {
		return if a.minor < b.minor { -1 } else { 1 }
	}
	if a.patch != b.patch {
		return if a.patch < b.patch { -1 } else { 1 }
	}

	// When major, minor, and patch are equal, a normal version has greater precedence than a pre-release
	if a.prerelease.len == 0 && b.prerelease.len > 0 {
		return 1
	}
	if a.prerelease.len > 0 && b.prerelease.len == 0 {
		return -1
	}
	if a.prerelease.len == 0 && b.prerelease.len == 0 {
		return 0
	}

	// Compare pre-release identifiers dot-by-dot
	a_parts := a.prerelease.split('.')
	b_parts := b.prerelease.split('.')
	min_len := if a_parts.len < b_parts.len { a_parts.len } else { b_parts.len }

	for i in 0 .. min_len {
		ap := a_parts[i]
		bp := b_parts[i]
		if ap == bp {
			continue
		}

		a_is_num := ap.is_pure_ascii() && ap == '${ap.int()}'
		b_is_num := bp.is_pure_ascii() && bp == '${bp.int()}'

		if a_is_num && b_is_num {
			ai := ap.int()
			bi := bp.int()
			if ai != bi {
				return if ai < bi { -1 } else { 1 }
			}
		} else if a_is_num {
			return -1 // numeric identifiers have lower precedence than alphanumeric
		} else if b_is_num {
			return 1
		} else {
			return if ap < bp { -1 } else { 1 }
		}
	}

	if a_parts.len != b_parts.len {
		return if a_parts.len < b_parts.len { -1 } else { 1 }
	}

	return 0
}

// is_newer returns true if version a is strictly newer than version b.
pub fn is_newer(a string, b string) !bool {
	va := parse(a)!
	vb := parse(b)!
	return compare(va, vb) > 0
}

// bump_major increments major version, setting minor and patch to 0 and clearing prerelease/build.
pub fn bump_major(s SemVer) SemVer {
	return SemVer{
		major: s.major + 1
		minor: 0
		patch: 0
	}
}

// bump_minor increments minor version, setting patch to 0 and clearing prerelease/build.
pub fn bump_minor(s SemVer) SemVer {
	return SemVer{
		major: s.major
		minor: s.minor + 1
		patch: 0
	}
}

// bump_patch increments patch version and clears prerelease/build.
pub fn bump_patch(s SemVer) SemVer {
	return SemVer{
		major: s.major
		minor: s.minor
		patch: s.patch + 1
	}
}

// bump_prerelease updates the prerelease identifier of the version.
pub fn bump_prerelease(s SemVer, tag string) SemVer {
	return SemVer{
		major:      s.major
		minor:      s.minor
		patch:      s.patch
		prerelease: tag
		build:      s.build
	}
}

// satisfies tests whether a version satisfies a semver range condition (e.g. ">=1.2.0", "^1.0.0", "~2.1.0").
pub fn satisfies(ver SemVer, requirement string) !bool {
	req := requirement.trim_space()
	if req == '*' || req == '' {
		return true
	}

	// Handle compound requirements like ">=1.0.0 <2.0.0"
	if req.contains(' ') {
		parts := req.split(' ')
		for part in parts {
			if part.len > 0 && !satisfies(ver, part)! {
				return false
			}
		}
		return true
	}

	// Caret range ^X.Y.Z (compatible without breaking major)
	if req.starts_with('^') {
		base := parse(req[1..])!
		if compare(ver, base) < 0 {
			return false
		}
		if base.major > 0 {
			return ver.major == base.major
		}
		if base.minor > 0 {
			return ver.major == 0 && ver.minor == base.minor
		}
		return ver.major == 0 && ver.minor == 0 && ver.patch == base.patch
	}

	// Tilde range ~X.Y.Z (patch updates allowed)
	if req.starts_with('~') {
		base := parse(req[1..])!
		if compare(ver, base) < 0 {
			return false
		}
		return ver.major == base.major && ver.minor == base.minor
	}

	if req.starts_with('>=') {
		target := parse(req[2..])!
		return compare(ver, target) >= 0
	}
	if req.starts_with('<=') {
		target := parse(req[2..])!
		return compare(ver, target) <= 0
	}
	if req.starts_with('>') {
		target := parse(req[1..])!
		return compare(ver, target) > 0
	}
	if req.starts_with('<') {
		target := parse(req[1..])!
		return compare(ver, target) < 0
	}
	if req.starts_with('=') {
		target := parse(req[1..])!
		return compare(ver, target) == 0
	}

	// Exact match fallback
	target := parse(req)!
	return compare(ver, target) == 0
}

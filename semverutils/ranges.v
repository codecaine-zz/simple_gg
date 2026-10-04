module semverutils

// ============================================================================
// npm/Cargo-compatible range engine
// ============================================================================
// Supported grammar (node-semver compatible):
//   range      ::= set ( '||' set )*
//   set        ::= hyphen | comparator ( ' ' comparator )*
//   hyphen     ::= partial ' - ' partial
//   comparator ::= ( '>=' | '<=' | '>' | '<' | '=' | '^' | '~' | '~>' )? partial
//   partial    ::= ( 'v' )? xr ( '.' xr ( '.' xr pre? build? )? )?
//   xr         ::= 'x' | 'X' | '*' | number

struct Partial {
	major      int
	minor      int
	patch      int
	n          int // number of concrete components (0..3)
	prerelease string
}

struct Constraint {
	op string
	v  SemVer
}

fn parse_partial(raw string) !Partial {
	mut s := raw.trim_space()
	if s.starts_with('v') || s.starts_with('V') {
		s = s[1..]
	}
	if s == '' || s == '*' || s == 'x' || s == 'X' {
		return Partial{}
	}
	if i := s.index('+') {
		s = s[..i]
	}
	mut pre := ''
	if i := s.index('-') {
		pre = s[i + 1..]
		s = s[..i]
	}
	segs := s.split('.')
	if segs.len > 3 {
		return error('invalid version "${raw}"')
	}
	mut nums := [0, 0, 0]
	mut n := 0
	for seg in segs {
		if seg in ['x', 'X', '*'] {
			break
		}
		if seg == '' || !seg.bytes().all(it.is_digit()) {
			return error('invalid version "${raw}"')
		}
		nums[n] = seg.int()
		n++
	}
	return Partial{
		major:      nums[0]
		minor:      nums[1]
		patch:      nums[2]
		n:          n
		prerelease: if n == 3 { pre } else { '' }
	}
}

fn sv(major int, minor int, patch int, pre string) SemVer {
	return SemVer{
		major:      major
		minor:      minor
		patch:      patch
		prerelease: pre
	}
}

// expand turns one comparator into primitive `op version` constraints.
fn expand(op string, p Partial) []Constraint {
	if p.n == 0 {
		if op in ['<', '>'] {
			return [Constraint{'<', sv(0, 0, 0, '0')}] // matches nothing
		}
		return []
	}
	if p.n == 3 {
		full := sv(p.major, p.minor, p.patch, p.prerelease)
		match op {
			'^' {
				hi := if p.major > 0 {
					sv(p.major + 1, 0, 0, '0')
				} else if p.minor > 0 {
					sv(0, p.minor + 1, 0, '0')
				} else {
					sv(0, 0, p.patch + 1, '0')
				}
				return [Constraint{'>=', full}, Constraint{'<', hi}]
			}
			'~', '~>' {
				return [Constraint{'>=', full}, Constraint{'<', sv(p.major, p.minor + 1, 0, '0')}]
			}
			'', '=' {
				return [Constraint{'=', full}]
			}
			else {
				return [Constraint{op, full}]
			}
		}
	}
	lo := sv(p.major, p.minor, 0, '')
	mut hi := if p.n == 1 { sv(p.major + 1, 0, 0, '0') } else { sv(p.major, p.minor + 1, 0, '0') }
	if op == '^' && p.n == 2 && p.major > 0 {
		hi = sv(p.major + 1, 0, 0, '0')
	}
	match op {
		'>' { return [Constraint{'>=', sv(hi.major, hi.minor, hi.patch, '')}] }
		'>=' { return [Constraint{'>=', lo}] }
		'<' { return [Constraint{'<', sv(lo.major, lo.minor, 0, '0')}] }
		'<=' { return [Constraint{'<', hi}] }
		else { return [Constraint{'>=', lo}, Constraint{'<', hi}] }
	}
}

fn split_op(tok string) (string, string) {
	for op in ['>=', '<=', '~>', '>', '<', '=', '^', '~'] {
		if tok.starts_with(op) {
			return op, tok[op.len..]
		}
	}
	return '', tok
}

fn parse_set(raw string) ![]Constraint {
	s := raw.trim_space()
	if s.contains(' - ') {
		a, b := s.split_once(' - ') or { s, '' }
		lo := parse_partial(a)!
		hi := parse_partial(b)!
		mut out := expand('>=', lo)
		out << expand('<=', hi)
		return out
	}
	// Tokenize, gluing a bare operator to the version that follows it (">= 1.2.3").
	mut toks := []string{}
	mut pending := ''
	for t in s.fields() {
		op, rest := split_op(t)
		if rest == '' && op != '' {
			pending += op
			continue
		}
		toks << pending + t
		pending = ''
	}
	if pending != '' {
		return error('dangling operator "${pending}" in range "${raw}"')
	}
	mut out := []Constraint{}
	for t in toks {
		op, rest := split_op(t)
		out << expand(op, parse_partial(rest)!)
	}
	return out
}

fn check(v SemVer, c Constraint) bool {
	r := compare(v, c.v)
	return match c.op {
		'>=' { r >= 0 }
		'<=' { r <= 0 }
		'>' { r > 0 }
		'<' { r < 0 }
		else { r == 0 }
	}
}

// satisfies_range evaluates a full npm-style range (supports `||`, hyphen ranges,
// x-ranges like `1.2.x`, partials like `^1.2`, and `>= 1.0.0` with spaces).
pub fn satisfies_range(ver SemVer, range string) !bool {
	for set in range.split('||') {
		cs := parse_set(set)!
		if cs.all(check(ver, it)) {
			return true
		}
	}
	return false
}

// is_valid reports whether `raw` is a strict SemVer 2.0.0 string.
pub fn is_valid(raw string) bool {
	parse(raw) or { return false }
	return true
}

// is_valid_range reports whether `range` parses as a range expression.
pub fn is_valid_range(range string) bool {
	for set in range.split('||') {
		parse_set(set) or { return false }
	}
	return true
}

// coerce extracts the first version-like token from loose input
// ("v2", "release-1.4", "1.2.3.4" -> 2.0.0, 1.4.0, 1.2.3).
pub fn coerce(raw string) !SemVer {
	mut i := 0
	for i < raw.len && !raw[i].is_digit() {
		i++
	}
	if i == raw.len {
		return error('no version found in "${raw}"')
	}
	mut nums := [0, 0, 0]
	mut idx := 0
	for idx < 3 && i < raw.len && raw[i].is_digit() {
		mut j := i
		for j < raw.len && raw[j].is_digit() {
			j++
		}
		nums[idx] = raw[i..j].int()
		idx++
		if j + 1 < raw.len && raw[j] == `.` && raw[j + 1].is_digit() {
			i = j + 1
		} else {
			break
		}
	}
	return sv(nums[0], nums[1], nums[2], '')
}

// compare_str parses and compares two version strings.
pub fn compare_str(a string, b string) !int {
	return compare(parse(a)!, parse(b)!)
}

// sort_versions parses and sorts version strings ascending by precedence.
pub fn sort_versions(versions []string) ![]SemVer {
	mut out := []SemVer{cap: versions.len}
	for v in versions {
		out << parse(v)!
	}
	out.sort_with_compare(fn (a &SemVer, b &SemVer) int {
		return compare(*a, *b)
	})
	return out
}

// max_satisfying returns the highest version in `versions` that satisfies `range`.
pub fn max_satisfying(versions []string, range string) ?SemVer {
	mut best := ?SemVer(none)
	for raw in versions {
		v := parse(raw) or { continue }
		if satisfies_range(v, range) or { false } {
			if b := best {
				if compare(v, b) > 0 {
					best = v
				}
			} else {
				best = v
			}
		}
	}
	return best
}

// min_satisfying returns the lowest version in `versions` that satisfies `range`.
pub fn min_satisfying(versions []string, range string) ?SemVer {
	mut best := ?SemVer(none)
	for raw in versions {
		v := parse(raw) or { continue }
		if satisfies_range(v, range) or { false } {
			if b := best {
				if compare(v, b) < 0 {
					best = v
				}
			} else {
				best = v
			}
		}
	}
	return best
}

// diff names the most significant differing component:
// 'major', 'minor', 'patch', 'prerelease', 'build' or 'none'.
pub fn diff(a SemVer, b SemVer) string {
	if a.major != b.major {
		return 'major'
	}
	if a.minor != b.minor {
		return 'minor'
	}
	if a.patch != b.patch {
		return 'patch'
	}
	if a.prerelease != b.prerelease {
		return 'prerelease'
	}
	if a.build != b.build {
		return 'build'
	}
	return 'none'
}

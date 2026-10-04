module diffutils

import strings

// ============================================================================
// Myers O((N+M)·D) diff engine
// ============================================================================

// diff_sequences computes a minimal edit script between two string sequences using
// Myers' algorithm (the one behind `git diff`), after trimming the common prefix and
// suffix. Within each changed block, deletions are emitted before insertions.
pub fn diff_sequences(a []string, b []string) []DiffOp {
	mut pre := 0
	for pre < a.len && pre < b.len && a[pre] == b[pre] {
		pre++
	}
	mut suf := 0
	for suf < a.len - pre && suf < b.len - pre && a[a.len - 1 - suf] == b[b.len - 1 - suf] {
		suf++
	}
	mut ops := []DiffOp{cap: a.len + b.len}
	for i in 0 .. pre {
		ops << DiffOp{.equal, a[i]}
	}
	ops << normalize(myers(a[pre..a.len - suf], b[pre..b.len - suf]))
	for i in a.len - suf .. a.len {
		ops << DiffOp{.equal, a[i]}
	}
	return ops
}

fn myers(a []string, b []string) []DiffOp {
	n := a.len
	m := b.len
	if n == 0 && m == 0 {
		return []
	}
	max := n + m
	off := max + 1
	mut v := []int{len: 2 * max + 3}
	mut trace := [][]int{}
	outer: for d in 0 .. max + 1 {
		trace << v.clone()
		for k := -d; k <= d; k += 2 {
			mut x := if k == -d || (k != d && v[off + k - 1] < v[off + k + 1]) {
				v[off + k + 1]
			} else {
				v[off + k - 1] + 1
			}
			mut y := x - k
			for x < n && y < m && a[x] == b[y] {
				x++
				y++
			}
			v[off + k] = x
			if x >= n && y >= m {
				break outer
			}
		}
	}
	mut ops := []DiffOp{}
	mut x := n
	mut y := m
	for d := trace.len - 1; d >= 0; d-- {
		vv := trace[d]
		k := x - y
		prev_k := if k == -d || (k != d && vv[off + k - 1] < vv[off + k + 1]) {
			k + 1
		} else {
			k - 1
		}
		prev_x := if d == 0 { 0 } else { vv[off + prev_k] }
		prev_y := if d == 0 { 0 } else { prev_x - prev_k }
		for x > prev_x && y > prev_y {
			ops << DiffOp{.equal, a[x - 1]}
			x--
			y--
		}
		if d > 0 {
			if x == prev_x {
				ops << DiffOp{.insert, b[y - 1]}
				y--
			} else {
				ops << DiffOp{.delete, a[x - 1]}
				x--
			}
		}
	}
	ops.reverse_in_place()
	return ops
}

// normalize reorders each run of changes so deletions precede insertions.
fn normalize(ops []DiffOp) []DiffOp {
	mut out := []DiffOp{cap: ops.len}
	mut dels := []DiffOp{}
	mut ins := []DiffOp{}
	for op in ops {
		match op.op {
			.delete {
				dels << op
			}
			.insert {
				ins << op
			}
			.equal {
				out << dels
				out << ins
				dels.clear()
				ins.clear()
				out << op
			}
		}
	}
	out << dels
	out << ins
	return out
}

// diff_words diffs two texts word-by-word (whitespace separated).
pub fn diff_words(old_text string, new_text string) []DiffOp {
	return diff_sequences(old_text.fields(), new_text.fields())
}

// diff_chars diffs two strings character-by-character (Unicode aware).
pub fn diff_chars(old_text string, new_text string) []DiffOp {
	return diff_sequences(old_text.runes().map(it.str()), new_text.runes().map(it.str()))
}

// ============================================================================
// Statistics & similarity
// ============================================================================

// DiffStats summarizes an edit script.
pub struct DiffStats {
pub:
	added     int
	removed   int
	unchanged int
}

// diff_stats counts insertions, deletions and unchanged items.
pub fn diff_stats(ops []DiffOp) DiffStats {
	mut a, mut r, mut u := 0, 0, 0
	for op in ops {
		match op.op {
			.insert { a++ }
			.delete { r++ }
			.equal { u++ }
		}
	}
	return DiffStats{a, r, u}
}

// similarity returns 2*matches/(len(a)+len(b)) over lines, in [0, 1] (1 = identical).
pub fn similarity(old_text string, new_text string) f64 {
	a := old_text.split_into_lines()
	b := new_text.split_into_lines()
	if a.len + b.len == 0 {
		return 1.0
	}
	return 2.0 * f64(diff_stats(diff_sequences(a, b)).unchanged) / f64(a.len + b.len)
}

// ============================================================================
// Real unified diff (git / patch compatible)
// ============================================================================

// Hunk is a contiguous group of changes with surrounding context.
pub struct Hunk {
pub:
	old_start int // 1-based
	old_count int
	new_start int // 1-based
	new_count int
	ops       []DiffOp
}

// header renders the `@@ -a,b +c,d @@` line.
pub fn (h Hunk) header() string {
	return '@@ -${range_str(h.old_start, h.old_count)} +${range_str(h.new_start, h.new_count)} @@'
}

fn range_str(start int, count int) string {
	return if count == 1 { '${start}' } else { '${start},${count}' }
}

// make_hunks groups an edit script into hunks with `context` lines around changes.
pub fn make_hunks(ops []DiffOp, context int) []Hunk {
	ctx := if context < 0 { 0 } else { context }
	mut changes := []int{}
	for i, op in ops {
		if op.op != .equal {
			changes << i
		}
	}
	if changes.len == 0 {
		return []
	}
	// Precompute line numbers before each op.
	mut old_ln := []int{len: ops.len + 1}
	mut new_ln := []int{len: ops.len + 1}
	for i, op in ops {
		old_ln[i + 1] = old_ln[i] + if op.op != .insert { 1 } else { 0 }
		new_ln[i + 1] = new_ln[i] + if op.op != .delete { 1 } else { 0 }
	}
	mut hunks := []Hunk{}
	mut gi := 0
	for gi < changes.len {
		mut gj := gi
		for gj + 1 < changes.len && changes[gj + 1] - changes[gj] - 1 <= 2 * ctx {
			gj++
		}
		lo := if changes[gi] - ctx < 0 { 0 } else { changes[gi] - ctx }
		hi := if changes[gj] + ctx + 1 > ops.len { ops.len } else { changes[gj] + ctx + 1 }
		oc := old_ln[hi] - old_ln[lo]
		nc := new_ln[hi] - new_ln[lo]
		hunks << Hunk{
			old_start: if oc == 0 { old_ln[lo] } else { old_ln[lo] + 1 }
			old_count: oc
			new_start: if nc == 0 { new_ln[lo] } else { new_ln[lo] + 1 }
			new_count: nc
			ops:       ops[lo..hi].clone()
		}
		gi = gj + 1
	}
	return hunks
}

// unified_diff_hunks renders a standard unified diff (with `@@` hunk headers) that
// `patch`, `git apply` and `apply_patch` understand. Returns '' when texts are equal.
pub fn unified_diff_hunks(old_text string, new_text string, old_name string, new_name string, context int) string {
	hunks := make_hunks(diff_sequences(old_text.split_into_lines(), new_text.split_into_lines()),
		context)
	if hunks.len == 0 {
		return ''
	}
	mut sb := strings.new_builder(256)
	sb.write_string('--- ${old_name}\n+++ ${new_name}\n')
	for h in hunks {
		sb.write_string(h.header())
		sb.write_u8(`\n`)
		for op in h.ops {
			sb.write_u8(match op.op {
				.equal { ` ` }
				.insert { `+` }
				.delete { `-` }
			})
			sb.write_string(op.text)
			sb.write_u8(`\n`)
		}
	}
	return sb.str()
}

fn parse_range(s string) !(int, int) {
	if s.contains(',') {
		a, b := s.split_once(',') or { s, '1' }
		return a.int(), b.int()
	}
	if s == '' || !s.bytes().all(it.is_digit()) {
		return error('bad hunk range "${s}"')
	}
	return s.int(), 1
}

// apply_patch applies a unified diff to `old_text`, verifying every context and
// deletion line. Returns an error (and no partial result) if the patch does not apply.
pub fn apply_patch(old_text string, patch string) !string {
	old := old_text.split_into_lines()
	mut out := []string{cap: old.len}
	mut pos := 0 // 0-based index into old
	lines := patch.split_into_lines()
	mut i := 0
	for i < lines.len {
		line := lines[i]
		if !line.starts_with('@@') {
			i++
			continue
		}
		parts := line.fields()
		if parts.len < 3 || !parts[1].starts_with('-') || !parts[2].starts_with('+') {
			return error('malformed hunk header: ${line}')
		}
		old_start, old_count := parse_range(parts[1][1..])!
		target := if old_count == 0 { old_start } else { old_start - 1 }
		if target < pos || target > old.len {
			return error('hunk out of order or out of range: ${line}')
		}
		for pos < target {
			out << old[pos]
			pos++
		}
		i++
		for i < lines.len && !lines[i].starts_with('@@') {
			l := lines[i]
			if l.starts_with('---') || l.starts_with('+++') {
				break
			}
			if l.len == 0 || l[0] == ` ` || l[0] == `-` {
				body := if l.len == 0 { '' } else { l[1..] }
				if pos >= old.len || old[pos] != body {
					return error('patch does not apply at line ${pos + 1}: expected "${body}"')
				}
				if l.len == 0 || l[0] == ` ` {
					out << body
				}
				pos++
			} else if l[0] == `+` {
				out << l[1..]
			} else if l[0] != `\\` {
				return error('unexpected patch line: ${l}')
			}
			i++
		}
	}
	for pos < old.len {
		out << old[pos]
		pos++
	}
	mut res := out.join('\n')
	if old_text.ends_with('\n') && res.len > 0 {
		res += '\n'
	}
	return res
}

// render_ansi renders an edit script with terminal colors (red deletions, green insertions).
pub fn render_ansi(ops []DiffOp) string {
	mut sb := strings.new_builder(256)
	for op in ops {
		match op.op {
			.equal { sb.write_string('  ${op.text}\n') }
			.insert { sb.write_string('\x1b[32m+ ${op.text}\x1b[0m\n') }
			.delete { sb.write_string('\x1b[31m- ${op.text}\x1b[0m\n') }
		}
	}
	return sb.str()
}

module diffutils

import strings

// DiffType indicates whether a chunk is unchanged, inserted, or deleted.
pub enum DiffType {
	equal
	insert
	delete
}

// DiffOp represents a discrete diff operation on text.
pub struct DiffOp {
pub:
	op   DiffType
	text string
}

// diff_lines computes a line-level diff between two multi-line strings using the Longest Common Subsequence algorithm.
pub fn diff_lines(old_text string, new_text string) []DiffOp {
	old_lines := old_text.split_into_lines()
	new_lines := new_text.split_into_lines()
	n := old_lines.len
	m := new_lines.len

	// DP table for LCS
	mut dp := [][]int{len: n + 1, init: []int{len: m + 1, init: 0}}
	for i in 0 .. n {
		for j in 0 .. m {
			if old_lines[i] == new_lines[j] {
				dp[i + 1][j + 1] = dp[i][j] + 1
			} else if dp[i + 1][j] >= dp[i][j + 1] {
				dp[i + 1][j + 1] = dp[i + 1][j]
			} else {
				dp[i + 1][j + 1] = dp[i][j + 1]
			}
		}
	}

	// Backtrack to build diff
	mut ops := []DiffOp{}
	mut i := n
	mut j := m
	for i > 0 || j > 0 {
		if i > 0 && j > 0 && old_lines[i - 1] == new_lines[j - 1] {
			ops << DiffOp{
				op:   .equal
				text: old_lines[i - 1]
			}
			i--
			j--
		} else if j > 0 && (i == 0 || dp[i][j - 1] >= dp[i - 1][j]) {
			ops << DiffOp{
				op:   .insert
				text: new_lines[j - 1]
			}
			j--
		} else if i > 0 && (j == 0 || dp[i][j - 1] < dp[i - 1][j]) {
			ops << DiffOp{
				op:   .delete
				text: old_lines[i - 1]
			}
			i--
		}
	}

	ops.reverse_in_place()
	return ops
}

// unified_diff generates a standard unified diff string (e.g. for patching or Git view).
pub fn unified_diff(old_text string, new_text string, filename string) string {
	ops := diff_lines(old_text, new_text)
	mut sb := strings.new_builder(128)
	sb.write_string('--- a/${filename}\n')
	sb.write_string('+++ b/${filename}\n')

	mut has_changes := false
	for op in ops {
		match op.op {
			.equal {
				sb.write_string('  ${op.text}\n')
			}
			.insert {
				has_changes = true
				sb.write_string('+ ${op.text}\n')
			}
			.delete {
				has_changes = true
				sb.write_string('- ${op.text}\n')
			}
		}
	}

	if !has_changes {
		return ''
	}
	return sb.str()
}

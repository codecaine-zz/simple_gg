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

// diff_lines computes a line-level diff between two multi-line strings.
// It produces a minimal (longest-common-subsequence) edit script using Myers' algorithm
// with common prefix/suffix trimming: O((N+M)·D) time instead of the O(N·M) memory DP table.
pub fn diff_lines(old_text string, new_text string) []DiffOp {
	return diff_sequences(old_text.split_into_lines(), new_text.split_into_lines())
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

module diffutils

import rand

fn lcs_len(a []string, b []string) int {
	mut dp := [][]int{len: a.len + 1, init: []int{len: b.len + 1}}
	for i in 0 .. a.len {
		for j in 0 .. b.len {
			dp[i + 1][j + 1] = if a[i] == b[j] {
				dp[i][j] + 1
			} else if dp[i + 1][j] > dp[i][j + 1] {
				dp[i + 1][j]
			} else {
				dp[i][j + 1]
			}
		}
	}
	return dp[a.len][b.len]
}

fn rebuild(ops []DiffOp) ([]string, []string) {
	mut a := []string{}
	mut b := []string{}
	for op in ops {
		if op.op != .insert {
			a << op.text
		}
		if op.op != .delete {
			b << op.text
		}
	}
	return a, b
}

fn rand_lines(n int) []string {
	alphabet := ['a', 'b', 'c', 'd']
	return []string{len: n, init: alphabet[rand.intn(alphabet.len) or { 0 }]}
}

fn test_myers_is_minimal_and_consistent() {
	rand.seed([u32(7), 11])
	for _ in 0 .. 300 {
		a := rand_lines(rand.intn(15) or { 0 })
		b := rand_lines(rand.intn(15) or { 0 })
		ops := diff_sequences(a, b)
		ra, rb := rebuild(ops)
		assert ra == a
		assert rb == b
		assert diff_stats(ops).unchanged == lcs_len(a, b)
	}
}

fn test_patch_roundtrip_random() {
	rand.seed([u32(3), 5])
	for _ in 0 .. 200 {
		a := rand_lines(rand.intn(20) or { 0 }).join('\n')
		b := rand_lines(rand.intn(20) or { 0 }).join('\n')
		for ctx in [0, 1, 3] {
			p := unified_diff_hunks(a, b, 'a', 'b', ctx)
			if a == b {
				assert p == ''
				continue
			}
			got := apply_patch(a, p) or { panic('${err}\n${p}') }
			assert got == b, 'ctx=${ctx}\nA=${a}\nB=${b}\nP=${p}\nGOT=${got}'
		}
	}
}

fn test_unified_hunk_format() {
	old := 'l1\nl2\nl3\nl4\nl5\nl6\nl7\nl8\nl9\nl10'
	new := 'l1\nl2\nl3\nX4\nl5\nl6\nl7\nl8\nl9\nl10\nl11'
	p := unified_diff_hunks(old, new, 'a/f.txt', 'b/f.txt', 1)
	assert p.starts_with('--- a/f.txt\n+++ b/f.txt\n')
	assert p.contains('@@ -3,3 +3,3 @@\n l3\n-l4\n+X4\n l5\n')
	assert p.contains('@@ -10 +10,2 @@\n l10\n+l11\n')
}

fn test_apply_patch_rejects_mismatch() {
	p := unified_diff_hunks('a\nb\nc', 'a\nB\nc', 'x', 'y', 1)
	if _ := apply_patch('a\nZ\nc', p) {
		assert false
	}
}

fn test_word_char_diff_and_similarity() {
	w := diff_words('the quick brown fox', 'the slow brown fox')
	st := diff_stats(w)
	assert st.added == 1 && st.removed == 1 && st.unchanged == 3
	c := diff_chars('kitten', 'sitting')
	assert diff_stats(c).unchanged == 4 // LCS("kitten","sitting") = "ittn"
	assert similarity('a\nb\nc', 'a\nb\nc') == 1.0
	assert similarity('a\nb', 'c\nd') == 0.0
	assert render_ansi(w).contains('\x1b[32m+ slow')
}

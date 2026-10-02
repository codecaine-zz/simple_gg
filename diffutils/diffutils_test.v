module diffutils

fn test_diff_lines() {
	old_str := 'apple\nbanana\ncherry'
	new_str := 'apple\nblueberry\ncherry'

	ops := diff_lines(old_str, new_str)
	assert ops.len == 4

	assert ops[0].op == .equal
	assert ops[0].text == 'apple'

	assert ops[1].op == .delete
	assert ops[1].text == 'banana'

	assert ops[2].op == .insert
	assert ops[2].text == 'blueberry'

	assert ops[3].op == .equal
	assert ops[3].text == 'cherry'
}

fn test_unified_diff() {
	old_str := 'alpha\nbeta'
	new_str := 'alpha\ngamma'

	diff := unified_diff(old_str, new_str, 'test.txt')
	assert diff.starts_with('--- a/test.txt')
	assert diff.contains('+++ b/test.txt')
	assert diff.contains('- beta')
	assert diff.contains('+ gamma')

	// Identical texts should return empty diff
	no_diff := unified_diff('same', 'same', 'test.txt')
	assert no_diff == ''
}

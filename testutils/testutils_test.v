module testutils

import os

struct PathBox {
mut:
	path string
}

fn test_temp_dir() {
	mut box := &PathBox{}
	with_temp_dir(fn [mut box] (tmp_dir string) ! {
		box.path = tmp_dir
		assert os.exists(tmp_dir)
		test_file := os.join_path(tmp_dir, 'sample.txt')
		os.write_file(test_file, 'sandboxed')!
		assert os.exists(test_file)
	}) or { panic(err) }

	assert box.path.len > 0
	assert !os.exists(box.path)
}

fn test_temp_file() {
	mut box := &PathBox{}
	with_temp_file('initial payload', fn [mut box] (tmp_file string) ! {
		box.path = tmp_file
		assert os.exists(tmp_file)
		content := os.read_file(tmp_file)!
		assert content == 'initial payload'
	}) or { panic(err) }

	assert box.path.len > 0
	assert !os.exists(box.path)
}

fn test_with_env() {
	os.setenv('PRE_EXISTING_KEY', 'old_val', true)
	defer { os.unsetenv('PRE_EXISTING_KEY') }

	with_env({
		'PRE_EXISTING_KEY': 'new_val'
		'BRAND_NEW_KEY':    'created'
	}, fn () ! {
		assert os.getenv('PRE_EXISTING_KEY') == 'new_val'
		assert os.getenv('BRAND_NEW_KEY') == 'created'
	}) or { panic(err) }

	assert os.getenv('PRE_EXISTING_KEY') == 'old_val'
	assert os.getenv('BRAND_NEW_KEY') == ''
}

fn test_assertions() {
	assert_eq(42, 42)
	assert_eq('hello', 'hello')
	assert_contains('the quick brown fox', 'quick')
	assert_in_delta(3.14159, 3.14, 0.01)
}

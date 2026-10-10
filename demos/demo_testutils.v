module main

import os
import testutils

fn main() {
	println('=== demo_testutils: Testing Fixtures & Sandboxed Environments ===\n')

	// 1. Isolated Temporary Directory Sandbox
	println('1. Running test inside an isolated temporary directory:')
	testutils.with_temp_dir(fn (tmp_dir string) ! {
		println('   Sandboxed dir created at: ${tmp_dir}')
		test_file := os.join_path(tmp_dir, 'database.sqlite')
		os.write_file(test_file, 'test content')!
		println('   Created test file: ${os.exists(test_file)}')
	}) or { panic(err) }
	println('   Directory was automatically cleaned up upon exit.\n')

	// 2. Isolated Environment Variable Overrides
	println('2. Temporarily overriding environment variables:')
	testutils.with_env({
		'APP_ENVIRONMENT': 'testing'
		'MOCK_API_KEY':    'sk-secret-1234'
	}, fn () ! {
		println('   Inside sandbox -> APP_ENVIRONMENT: ${os.getenv('APP_ENVIRONMENT')}')
		println('   Inside sandbox -> MOCK_API_KEY:    ${os.getenv('MOCK_API_KEY')}')
	}) or { panic(err) }
	println('   Outside sandbox -> APP_ENVIRONMENT: "${os.getenv('APP_ENVIRONMENT')}" (restored)\n')

	// 3. Ergonomic Fluent Assertions
	println('3. Running assertions:')
	testutils.assert_eq('vlang', 'vlang', 'language check')
	testutils.assert_contains('fast, small, safe', 'small')
	testutils.assert_in_delta(3.14159, 3.14, 0.01)
	println('   All assertions passed successfully!')

	println('\n=== demo_testutils completed successfully ===')
}

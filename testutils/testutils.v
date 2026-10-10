module testutils

import os
import rand

// -----------------------------------------------------------------------
// 1. Sandbox Environments & Temp Files
// -----------------------------------------------------------------------

// with_temp_dir creates an isolated temporary directory, executes the callback,
// and guarantees complete recursive deletion upon completion.
pub fn with_temp_dir(action fn (tmp_dir string) !) ! {
	random_suffix := rand.u32().hex()
	dir_name := 'vlang_utils_test_${os.getpid()}_${random_suffix}'
	tmp_path := os.join_path(os.temp_dir(), dir_name)
	os.mkdir_all(tmp_path)!
	defer {
		os.rmdir_all(tmp_path) or {}
	}
	action(tmp_path)!
}

// with_temp_file writes initial content to a temporary file, passes its path to
// the callback, and deletes it upon completion.
pub fn with_temp_file(content string, action fn (tmp_file string) !) ! {
	random_suffix := rand.u32().hex()
	file_name := 'vlang_utils_file_${os.getpid()}_${random_suffix}.tmp'
	tmp_path := os.join_path(os.temp_dir(), file_name)
	os.write_file(tmp_path, content)!
	defer {
		os.rm(tmp_path) or {}
	}
	action(tmp_path)!
}

// with_env temporarily sets or overrides environment variables for the duration
// of the callback, restoring the previous environment state immediately after.
pub fn with_env(overrides map[string]string, action fn () !) ! {
	mut original := map[string]?string{}

	for k, _ in overrides {
		val := os.getenv_opt(k)
		original[k] = val
	}

	for k, v in overrides {
		os.setenv(k, v, true)
	}

	defer {
		for k, opt_val in original {
			if val := opt_val {
				os.setenv(k, val, true)
			} else {
				os.unsetenv(k)
			}
		}
	}

	action()!
}

// with_cwd switches the current working directory for the duration of the callback,
// restoring the original working directory on return.
pub fn with_cwd(new_dir string, action fn () !) ! {
	old_dir := os.getwd()
	os.chdir(new_dir)!
	defer {
		os.chdir(old_dir) or {}
	}
	action()!
}

// -----------------------------------------------------------------------
// 2. Assertions & Validation Helpers
// -----------------------------------------------------------------------

// assert_eq checks value equality and panics with a detailed message if unequal.
pub fn assert_eq[T](actual T, expected T, msg ...string) {
	if actual != expected {
		custom := if msg.len > 0 { ': ' + msg.join(' ') } else { '' }
		panic('assertion failed${custom}\n  expected: `${expected}`\n    actual: `${actual}`')
	}
}

// assert_contains verifies that a string or slice contains an expected element.
pub fn assert_contains(haystack string, needle string, msg ...string) {
	if !haystack.contains(needle) {
		custom := if msg.len > 0 { ': ' + msg.join(' ') } else { '' }
		panic('assertion failed${custom}\n  string does not contain `${needle}`\n  haystack: `${haystack}`')
	}
}

// assert_in_delta verifies that a floating point number is within delta of expected.
pub fn assert_in_delta(actual f64, expected f64, delta f64, msg ...string) {
	diff := if actual > expected { actual - expected } else { expected - actual }
	if diff > delta {
		custom := if msg.len > 0 { ': ' + msg.join(' ') } else { '' }
		panic('assertion failed${custom}\n  diff ${diff} exceeds delta ${delta} (actual: ${actual}, expected: ${expected})')
	}
}

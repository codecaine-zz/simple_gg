module envutils

import os

fn test_typed_getters() {
	os.setenv('TEST_PORT', '9000', true)
	os.setenv('TEST_ENABLED', 'true', true)
	os.setenv('TEST_PI', '3.14159', true)

	assert get_str('TEST_PORT', '80') == '9000'
	assert get_str('NON_EXISTENT_VAR', 'fallback') == 'fallback'

	assert get_int('TEST_PORT', 80) == 9000
	assert get_int('NON_EXISTENT_INT', 42) == 42

	assert get_bool('TEST_ENABLED', false) == true
	assert get_bool('NON_EXISTENT_BOOL', false) == false

	assert get_f64('TEST_PI', 0.0) > 3.14
	assert get_f64('NON_EXISTENT_F64', 2.71) == 2.71

	req := get_required('TEST_PORT') or { '' }
	assert req == '9000'

	if _ := get_required('DEFINITELY_NOT_SET_12345') {
		assert false
	} else {
		assert true
	}
}

fn test_parse_dotenv() {
	content := '
# Server Config
HOST=127.0.0.1
PORT="8080" # inline comment
NAME=\'My App\'
EMPTY=
	'
	parsed := parse_dotenv_content(content)
	assert parsed['HOST'] == '127.0.0.1'
	assert parsed['PORT'] == '8080'
	assert parsed['NAME'] == 'My App'
	assert parsed['EMPTY'] == ''
}

fn test_expand_env() {
	os.setenv('APP_ENV', 'staging', true)
	os.setenv('APP_REGION', 'us-east', true)

	assert expand_env('Environment is \$APP_ENV') == 'Environment is staging'
	assert expand_env('Path: /var/\${APP_REGION}/\${APP_ENV}/data') == 'Path: /var/us-east/staging/data'
	assert expand_env('Plain text without vars') == 'Plain text without vars'
}

fn test_set_unset() {
	assert is_set('TEST_CUSTOM_KEY') == false
	assert has('TEST_CUSTOM_KEY') == false

	set('TEST_CUSTOM_KEY', 'custom_val')
	assert is_set('TEST_CUSTOM_KEY') == true
	assert has('TEST_CUSTOM_KEY') == true
	assert get_str('TEST_CUSTOM_KEY', '') == 'custom_val'

	set_int('TEST_INT_VAR', 12345)
	assert get_int('TEST_INT_VAR', 0) == 12345

	set_bool('TEST_BOOL_VAR', true)
	assert get_bool('TEST_BOOL_VAR', false) == true

	set_f64('TEST_FLOAT_VAR', 99.5)
	assert get_f64('TEST_FLOAT_VAR', 0.0) == 99.5

	set_map({
		'MULTI_A': 'alpha'
		'MULTI_B': 'beta'
	})
	assert get_str('MULTI_A', '') == 'alpha'
	assert get_str('MULTI_B', '') == 'beta'

	unset('TEST_CUSTOM_KEY')
	assert is_set('TEST_CUSTOM_KEY') == false
	assert get_str('TEST_CUSTOM_KEY', 'fallback') == 'fallback'
}

fn test_advanced_features() {
	// get_opt
	unset('OPT_VAR')
	assert get_opt('OPT_VAR') == none
	set('OPT_VAR', 'found_it')
	if val := get_opt('OPT_VAR') {
		assert val == 'found_it'
	} else {
		assert false
	}

	// get_i64
	set('LARGE_NUM', '9223372036854775800')
	assert get_i64('LARGE_NUM', 0) == 9223372036854775800
	assert get_i64('NON_EXISTENT_I64', 500) == 500
	set('BAD_I64', 'invalid')
	assert get_i64('BAD_I64', 99) == 99

	// get_list
	set('CORS_ORIGINS', 'https://foo.com, https://bar.com , http://localhost:3000')
	origins := get_list('CORS_ORIGINS', ',', [])
	assert origins.len == 3
	assert origins[0] == 'https://foo.com'
	assert origins[1] == 'https://bar.com'
	assert origins[2] == 'http://localhost:3000'

	set('TAGS_PIPE', 'admin|user|guest')
	pipe_tags := get_list('TAGS_PIPE', '|', [])
	assert pipe_tags == ['admin', 'user', 'guest']

	fallback_list := get_list('UNSET_LIST', ',', ['default_val'])
	assert fallback_list == ['default_val']

	// set_default
	unset('DEFAULT_CHECK')
	set_default('DEFAULT_CHECK', 'initial')
	assert get_str('DEFAULT_CHECK', '') == 'initial'
	set_default('DEFAULT_CHECK', 'overwritten')
	assert get_str('DEFAULT_CHECK', '') == 'initial'

	// all
	set('ALL_CHECK_KEY', 'all_check_value')
	env_all := all()
	assert 'ALL_CHECK_KEY' in env_all
	assert env_all['ALL_CHECK_KEY'] == 'all_check_value'

	// save_dotenv and round-trip
	tmp_path := os.join_path(os.temp_dir(), 'test_vlang_utils.env')
	save_dotenv(tmp_path, {
		'SERVER_HOST': '0.0.0.0'
		'SERVER_PORT': '8080'
		'APP_SECRET':  'secret #value with spaces'
	}) or {
		assert false
	}
	loaded := parse_dotenv_content(os.read_file(tmp_path) or { '' })
	assert loaded['SERVER_HOST'] == '0.0.0.0'
	assert loaded['SERVER_PORT'] == '8080'
	assert loaded['APP_SECRET'] == 'secret #value with spaces'
	os.rm(tmp_path) or {}
}

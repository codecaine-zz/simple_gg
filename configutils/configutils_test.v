module configutils

import os

fn test_layered_config() {
	// Create temporary TOML config
	tmp_file := os.join_path(os.temp_dir(), 'test_app_config.toml')
	os.write_file(tmp_file, 'port = 8080\nhost = "localhost"\n') or { panic(err) }
	defer { os.rm(tmp_file) or {} }

	// Set temporary ENV
	os.setenv('TESTAPP_HOST', '0.0.0.0', true)
	defer { os.unsetenv('TESTAPP_HOST') }

	// CLI args override everything
	cli_args := ['--port', '9090', '--debug']

	store := load_config(ConfigOptions{
		config_path: tmp_file
		env_prefix:  'TESTAPP_'
		args:        cli_args
		defaults:    {
			'theme': 'dark'
			'port':  '3000'
		}
	}) or { panic(err) }

	// 1. Defaults
	assert store.get_string('theme', '') == 'dark'
	assert store.source_of('theme') == 'default'

	// 2. Env overrides file
	assert store.get_string('host', '') == '0.0.0.0'
	assert store.source_of('host') == 'env'

	// 3. CLI overrides env & file & default
	assert store.get_int('port', 0) == 9090
	assert store.source_of('port') == 'cli'

	// 4. CLI boolean flag
	assert store.get_bool('debug', false) == true
	assert store.source_of('debug') == 'cli'
}

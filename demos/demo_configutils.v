module main

import os
import configutils

fn main() {
	println('=== demo_configutils: Hierarchical Layered Configuration Loader ===\n')

	// 1. Create a sample TOML config file
	sample_conf := 'sample_app.toml'
	os.write_file(sample_conf, '
port = 8000
host = "127.0.0.1"
database_url = "sqlite://app.db"
workers = 4
') or {
		panic(err)
	}
	defer { os.rm(sample_conf) or {} }

	// 2. Set an environment variable (simulating Docker / systemd)
	os.setenv('MYAPP_DATABASE_URL', 'postgres://user:pass@db:5432/prod', true)
	defer { os.unsetenv('MYAPP_DATABASE_URL') }

	// 3. Simulated command line invocation
	simulated_args := ['--port', '9000', '--debug', '--tags=api,vlang']

	// 4. Load configuration with complete precedence cascading:
	//    Defaults -> Config File -> Environment Variables -> CLI Flags
	cfg := configutils.load_config(configutils.ConfigOptions{
		config_path: sample_conf
		env_prefix:  'MYAPP_'
		args:        simulated_args
		defaults:    {
			'app_name': 'SuperApp'
			'port':     '3000'
			'debug':    'false'
		}
	}) or { panic(err) }

	println('Resolved Configuration Values & Provenance Sources:')
	println('  app_name:     "${cfg.get_string('app_name', '')}" (Source: ${cfg.source_of('app_name')})')
	println('  host:         "${cfg.get_string('host', '')}" (Source: ${cfg.source_of('host')})')
	println('  database_url: "${cfg.get_string('database_url', '')}" (Source: ${cfg.source_of('database_url')})')
	println('  port:         ${cfg.get_int('port', 0)} (Source: ${cfg.source_of('port')})')
	println('  workers:      ${cfg.get_int('workers', 0)} (Source: ${cfg.source_of('workers')})')
	println('  debug:        ${cfg.get_bool('debug', false)} (Source: ${cfg.source_of('debug')})')
	println('  tags:         ${cfg.get_strings('tags', [])} (Source: ${cfg.source_of('tags')})')

	println('\n=== demo_configutils completed successfully ===')
}

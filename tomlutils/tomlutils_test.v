module tomlutils

const sample_toml = '
# TOML configuration example
title = "Vlang Utils"
version = "1.0.0"

[database]
server = "127.0.0.1"
port = 5432
enabled = true
ratio = 0.75
ports = [ 8080, 8081, 8082 ]
tags = [ "backend", "db", "prod" ]
'

fn test_toml_parsing() {
	doc := parse(sample_toml) or { panic(err) }

	assert doc.has('title')
	assert doc.has('database.server')
	assert !doc.has('database.non_existent')

	assert doc.get_string('title', '') == 'Vlang Utils'
	assert doc.get_string('missing', 'fallback') == 'fallback'

	assert doc.get_string('database.server', '') == '127.0.0.1'
	assert doc.get_int('database.port', 0) == 5432
	assert doc.get_bool('database.enabled', false) == true
	assert doc.get_f64('database.ratio', 0.0) == 0.75

	ports := doc.get_ints('database.ports')
	assert ports == [8080, 8081, 8082]

	tags := doc.get_strings('database.tags')
	assert tags == ['backend', 'db', 'prod']
}

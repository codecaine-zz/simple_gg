module main

import tomlutils

fn main() {
	println('==================================================')
	println('                demo_tomlutils                    ')
	println('==================================================')

	toml_content := '
	title = "Antigravity Server"
	port = 8080
	debug = true
	tags = ["web", "api", "vlang"]
	'

	doc := tomlutils.parse(toml_content)!
	title := doc.get_string('title', '')
	port := doc.get_int('port', 0)
	debug := doc.get_bool('debug', false)
	tags := doc.get_strings('tags')

	println('Parsed TOML:')
	println('  title = "${title}"')
	println('  port  = ${port}')
	println('  debug = ${debug}')
	println('  tags  = ${tags}')

	assert title == 'Antigravity Server'
	assert port == 8080
	assert debug == true
	assert tags == ['web', 'api', 'vlang']

	println('\n✔ tomlutils demo completed successfully!')
}

module main

import envutils

fn main() {
	println('==================================================')
	println('                 demo_envutils                    ')
	println('==================================================')

	// 1. Programmatic Setters
	envutils.set('DEMO_APP_NAME', 'vlang_suite')
	envutils.set_int('DEMO_PORT', 9000)
	envutils.set_bool('DEMO_DEBUG', true)
	envutils.set_f64('DEMO_RATE', 1.5)
	envutils.set_default('DEMO_HOST', 'localhost')
	envutils.set_map({
		'DEMO_SERVICE_A': 'running'
		'DEMO_SERVICE_B': 'standby'
	})

	// 2. Inspection
	assert envutils.is_set('DEMO_APP_NAME') == true
	assert envutils.has('DEMO_PORT') == true
	println('Variable DEMO_APP_NAME set: ${envutils.is_set('DEMO_APP_NAME')}')

	// 3. Typed Getters
	app_name := envutils.get_str('DEMO_APP_NAME', 'default')
	port := envutils.get_int('DEMO_PORT', 8080)
	debug := envutils.get_bool('DEMO_DEBUG', false)
	rate := envutils.get_f64('DEMO_RATE', 1.0)
	service_a := envutils.get_required('DEMO_SERVICE_A')!
	println('Typed values: name=${app_name}, port=${port}, debug=${debug}, rate=${rate}, service=${service_a}')
	assert app_name == 'vlang_suite'
	assert port == 9000
	assert debug == true
	assert rate == 1.5
	assert service_a == 'running'

	// 4. List parsing
	envutils.set('DEMO_ALLOWED_HOSTS', '127.0.0.1, localhost, api.internal')
	hosts := envutils.get_list('DEMO_ALLOWED_HOSTS', ',', [])
	println('Parsed list: ${hosts}')
	assert hosts.len == 3
	assert hosts[0] == '127.0.0.1'

	// 5. String Interpolation / Variable Expansion
	expanded := envutils.expand_env('Connecting to \$DEMO_APP_NAME on port \$DEMO_PORT')
	println('Expanded string: "${expanded}"')
	assert expanded.contains('vlang_suite')
	assert expanded.contains('9000')

	// 6. Dotenv parsing
	dotenv_content := 'API_KEY="super_secret"\nTIMEOUT=30\n'
	dotenv_map := envutils.parse_dotenv_content(dotenv_content)
	println('Parsed dotenv content: ${dotenv_map}')
	assert dotenv_map['API_KEY'] == 'super_secret'
	assert dotenv_map['TIMEOUT'] == '30'

	// Clean up environment variables
	envutils.unset('DEMO_APP_NAME')
	envutils.unset('DEMO_PORT')
	envutils.unset('DEMO_DEBUG')
	envutils.unset('DEMO_RATE')
	envutils.unset('DEMO_HOST')
	envutils.unset('DEMO_SERVICE_A')
	envutils.unset('DEMO_SERVICE_B')
	envutils.unset('DEMO_ALLOWED_HOSTS')

	println('\n✔ envutils demo completed successfully!')
}

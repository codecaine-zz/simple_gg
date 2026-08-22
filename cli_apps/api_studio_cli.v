module main

import simplecli

fn main() {
	mut app := simplecli.new_app('apistudio-cli', '1.0.0')
	app.set_description('Interactive REST API Client & Request Builder CLI')

	app.add_flag_string('url', 'u', 'https://httpbin.org/get', 'Target REST API endpoint URL')
	app.add_flag_string('method', 'm', 'GET', 'HTTP Request Method (GET, POST, PUT, DELETE, PATCH, HEAD)')
	app.add_flag_string('body', 'b', '', 'Request payload / JSON body string')
	app.add_flag_string('header', 'H', '', 'Custom HTTP header (e.g. "Authorization: Bearer token")')
	app.add_flag_bool('interactive', 'x', false, 'Launch interactive REST API studio REPL')

	app.parse_cli() or { return }

	app.banner('API Studio CLI', 'v1.0.0 - REST API Client & Request Builder')

	if app.get_flag_bool('interactive') {
		run_interactive(mut app)
		return
	}

	url := app.get_flag_string('url')
	method := app.get_flag_string('method').to_upper()
	body := app.get_flag_string('body')

	send_api_request(mut app, method, url, body)
}

fn send_api_request(mut app simplecli.SimpleCli, method string, url string, body string) {
	app.info('Sending ${method} ${url}...')
	app.reset_timer()

	res := app.http_request(method, url, body) or {
		app.error('HTTP Request failed: ${err}')
		return
	}

	elapsed := app.elapsed_ms()
	status_color := if res.status_code >= 200 && res.status_code < 300 {
		app.green('HTTP ${res.status_code}')
	} else {
		app.yellow('HTTP ${res.status_code}')
	}

	app.print_kv({
		'Status': status_color,
		'Latency': '${elapsed} ms',
		'Body Size': '${res.body.len} bytes',
	})

	app.panel('Response Body', res.body)
}

fn run_interactive(mut app simplecli.SimpleCli) {
	app.panel('REST API Studio REPL', 'Build and execute HTTP requests interactively.')
	for {
		method := app.select('HTTP Method:', ['GET', 'POST', 'PUT', 'DELETE', 'HEAD'])
		url := app.prompt('Request URL', 'https://httpbin.org/get')
		mut body := ''
		if method == 'POST' || method == 'PUT' || method == 'PATCH' {
			body = app.prompt('Request JSON Body', '{"test": true}')
		}
		send_api_request(mut app, method, url, body)
		if !app.confirm('Send another request?', true) {
			break
		}
	}
}

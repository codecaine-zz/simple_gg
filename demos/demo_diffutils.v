module main

import diffutils

fn main() {
	println('=== diffutils Demo ===')

	v1 := 'server_host = 127.0.0.1\nserver_port = 8080\nenable_tls = false'
	v2 := 'server_host = 0.0.0.0\nserver_port = 8080\nenable_tls = true'

	println('--- Line-by-Line Operations ---')
	ops := diffutils.diff_lines(v1, v2)
	for op in ops {
		symbol := match op.op {
			.equal { ' ' }
			.insert { '+' }
			.delete { '-' }
		}

		println('${symbol} ${op.text}')
	}

	println('\n--- Unified Diff Format ---')
	diff := diffutils.unified_diff(v1, v2, 'config.ini')
	print(diff)

	println('diffutils demo completed successfully!')
}

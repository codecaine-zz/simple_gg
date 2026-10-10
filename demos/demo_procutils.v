module main

import procutils

fn main() {
	println('=== demo_procutils: Subprocess Streaming & Safe Pipelines ===\n')

	// 1. Real-time Subprocess Streaming
	println('1. Streaming command output line-by-line:')
	res := procutils.exec_stream('echo', [
		'Step 1: Init\nStep 2: Compile\nStep 3: Done',
	], fn (line string, is_stderr bool) {
		prefix := if is_stderr { '[STDERR]' } else { '[STDOUT]' }
		println('   ${prefix} ${line}')
	}) or { panic(err) }
	println('   Process finished with exit code: ${res.exit_code}')

	// 2. Safe Shell-style Pipeline without Shell Vulnerabilities
	println('\n2. Pipeline Execution (printf | grep | tr):')
	pipe_out := procutils.pipeline([
		procutils.cmd('printf', 'apple\nbanana\ncherry\navocado\n'),
		procutils.cmd('grep', 'a'),
	]) or { panic(err) }
	println('   Matched output:\n${pipe_out.trim_space()}')

	// 3. Execution with Timeout
	println('\n3. Execution with Timeout Guard:')
	t_res := procutils.exec_with_timeout('echo', ['Completed within safety limit'], 1000) or {
		panic(err)
	}
	println('   Output: ${t_res.stdout.trim_space()}')

	println('\n=== demo_procutils completed successfully ===')
}

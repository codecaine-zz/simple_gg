module sysutils

import os
import time

fn test_exec_timeout_really_kills() {
	t0 := time.now()
	r := exec_timeout('echo started; sleep 5; echo never', 300)
	elapsed := time.since(t0)
	assert r.timed_out
	assert r.exit_code == 124
	assert elapsed < 3 * time.second, 'exec_timeout waited ${elapsed} for a 300ms limit'
	assert r.output.contains('started')
	assert !r.output.contains('never')
}

fn test_exec_timeout_normal_completion() {
	r := exec_timeout('echo hi; echo err 1>&2; exit 3', 5000)
	assert !r.timed_out
	assert r.exit_code == 3
	assert r.output.contains('hi') && r.output.contains('err')
	unlimited := exec_timeout('echo ok', 0)
	assert unlimited.exit_code == 0 && unlimited.output.contains('ok')
}

fn test_sanitize_filename_edge_cases() {
	assert sanitize_filename('..') == 'unnamed'
	assert sanitize_filename('.') == 'unnamed'
	assert sanitize_filename('...') == 'unnamed'
	assert sanitize_filename('') == 'unnamed'
	assert sanitize_filename('CON') == '_CON'
	assert sanitize_filename('nul.txt') == '_nul.txt'
	assert sanitize_filename('com1.log') == '_com1.log'
	assert sanitize_filename('console.txt') == 'console.txt'
	assert sanitize_filename('report.') == 'report'
	assert sanitize_filename('a'.repeat(300)).len == 255
	assert sanitize_filename('my file (1).pdf') == 'my_file__1_.pdf'
}

fn test_run_command_no_shell_injection() {
	r := run_command('echo', ['hello; rm -rf /tmp/nothing', '\$(whoami)']) or { panic(err) }
	assert r.success()
	assert r.stdout.trim_space() == 'hello; rm -rf /tmp/nothing \$(whoami)'
}

fn test_run_command_streams_env_cwd_timeout() {
	r := run_command('sh', ['-c', 'echo out; echo err >&2; exit 7']) or { panic(err) }
	assert r.stdout.trim_space() == 'out'
	assert r.stderr.trim_space() == 'err'
	assert r.exit_code == 7 && !r.success()

	e := run_command('sh', ['-c', 'echo \$VU_TEST_VAR'],
		env: {
			'VU_TEST_VAR': 'from-env'
		}
	) or { panic(err) }
	assert e.stdout.trim_space() == 'from-env'

	tmp := os.real_path(os.temp_dir())
	w := run_command('pwd', [], work_dir: tmp) or { panic(err) }
	assert os.real_path(w.stdout.trim_space()) == tmp

	t := run_command('sleep', ['5'], timeout_ms: 200) or { panic(err) }
	assert t.timed_out && t.exit_code == 124 && t.duration_ms < 3000

	run_command('definitely_not_a_command_xyz', []) or {
		assert err.msg().contains('not found')
		return
	}
	assert false
}

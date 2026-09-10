module main

import os
import time

fn main() {
	println('======================================================================')
	println('                RUNNING ALL VLANG_UTILS DEMOS                         ')
	println('======================================================================\n')

	demos_dir := os.dir(@FILE)
	mut files := os.ls(demos_dir) or { panic(err) }
	files.sort()

	mut passed := 0
	mut failed := 0
	mut demo_files := []string{}

	for f in files {
		if f.starts_with('demo_') && f.ends_with('.v') {
			demo_files << f
		}
	}

	start_all := time.now()

	for i, f in demo_files {
		full_path := os.join_path(demos_dir, f)
		print('[${i + 1:2}/${demo_files.len:2}] Running ${f:24} ... ')

		t0 := time.now()
		res := os.execute('v run ${full_path}')
		elapsed := time.since(t0)

		if res.exit_code == 0 {
			println('PASS (${elapsed.milliseconds()}ms)')
			passed++
		} else {
			println('FAIL (${elapsed.milliseconds()}ms)')
			eprintln('  Output: ${res.output}')
			failed++
		}
	}

	total_elapsed := time.since(start_all)
	println('\n======================================================================')
	println('SUMMARY: ${passed} passed, ${failed} failed across ${demo_files.len} demos in ${total_elapsed.seconds():.2f}s')
	println('======================================================================')

	if failed > 0 {
		exit(1)
	}
}

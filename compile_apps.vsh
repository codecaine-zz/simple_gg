#!/usr/bin/env -S v run

import os
import time

struct Task {
	index    int
	total    int
	app_name string
	src_path string
	out_path string
	is_prod  bool
}

struct TaskResult {
	index      int
	total      int
	app_name   string
	out_path   string
	success    bool
	elapsed_ms i64
	size_mb    f64
	err_msg    string
}

fn compile_app(t Task) TaskResult {
	mut cmd := 'v '
	if t.is_prod {
		cmd += '-prod -gc none '
	}
	cmd += '${t.src_path} -o ${t.out_path}'

	t0 := time.now()
	res := os.execute(cmd)
	elapsed := time.since(t0)

	if res.exit_code == 0 && os.exists(t.out_path) {
		sz := os.file_size(t.out_path)
		return TaskResult{
			index: t.index
			total: t.total
			app_name: t.app_name
			out_path: t.out_path
			success: true
			elapsed_ms: elapsed.milliseconds()
			size_mb: f64(sz) / 1024.0 / 1024.0
			err_msg: ''
		}
	}

	return TaskResult{
		index: t.index
		total: t.total
		app_name: t.app_name
		out_path: t.out_path
		success: false
		elapsed_ms: elapsed.milliseconds()
		size_mb: 0.0
		err_msg: res.output.trim_space()
	}
}

fn main() {
	println('====================================================')
	println('  SimpleGUI Batch Applications Compiler (Parallel)')
	println('====================================================')

	mut is_prod := false
	mut batch_size := 6
	mut target_filter := ''

	mut i := 1
	for i < os.args.len {
		arg := os.args[i]
		if arg == '-prod' || arg == '--prod' {
			is_prod = true
		} else if arg == '-j' || arg == '--jobs' || arg == '-b' || arg == '--batch' {
			if i + 1 < os.args.len {
				i++
				batch_size = os.args[i].int()
				if batch_size < 1 {
					batch_size = 1
				}
			}
		} else if arg.starts_with('-j') {
			batch_size = arg.replace('-j', '').int()
			if batch_size < 1 {
				batch_size = 1
			}
		} else if !arg.starts_with('-') {
			target_filter = arg
		}
		i++
	}

	cwd := os.getwd()
	app_dir := os.join_path(cwd, 'applications')
	out_dir := os.join_path(cwd, 'bin')
	os.mkdir_all(out_dir) or {
		eprintln('Failed to create output directory: ${out_dir}')
		exit(1)
	}

	raw_files := os.ls(app_dir) or {
		eprintln('Failed to list applications directory: ${app_dir}')
		exit(1)
	}

	mut app_files := []string{}
	for f in raw_files {
		if f.ends_with('.v') && !f.ends_with('_test.v') {
			if target_filter.len == 0 || f.contains(target_filter) {
				app_files << f
			}
		}
	}
	app_files.sort()

	if app_files.len == 0 {
		println('No matching application files found in ${app_dir}')
		exit(0)
	}

	mode_str := if is_prod { 'PRODUCTION (-prod)' } else { 'FAST BUILD' }
	println('Source Directory : ${app_dir}')
	println('Output Directory : ${out_dir}')
	println('Build Mode       : ${mode_str}')
	println('Concurrent Batch : ${batch_size} parallel jobs')
	println('Total Targets    : ${app_files.len}')
	println('----------------------------------------------------')

	mut tasks := []Task{}
	for idx, f in app_files {
		name := f.replace('.v', '')
		tasks << Task{
			index: idx + 1
			total: app_files.len
			app_name: name
			src_path: os.join_path('applications', f)
			out_path: os.join_path('bin', name)
			is_prod: is_prod
		}
	}

	mut success_count := 0
	mut fail_count := 0
	start_total := time.now()

	// Process in concurrent batches
	mut offset := 0
	for offset < tasks.len {
		end := if offset + batch_size > tasks.len { tasks.len } else { offset + batch_size }
		batch_tasks := tasks[offset..end].clone()
		batch_num := (offset / batch_size) + 1
		total_batches := ((tasks.len + batch_size - 1) / batch_size)

		println('--> Launching Batch ${batch_num}/${total_batches} (${batch_tasks.len} apps concurrent)...')

		mut threads := []thread TaskResult{}
		for t in batch_tasks {
			threads << spawn compile_app(t)
		}

		results := threads.wait()
		for r in results {
			if r.success {
				println('   [${r.index:02d}/${r.total:02d}] OK   ${r.app_name:-26s} (${r.elapsed_ms}ms, ${r.size_mb:.2f} MB)')
				success_count++
			} else {
				println('   [${r.index:02d}/${r.total:02d}] FAIL ${r.app_name:-26s} (${r.elapsed_ms}ms)')
				if r.err_msg.len > 0 {
					eprintln('        Error: ${r.err_msg}')
				}
				fail_count++
			}
		}

		offset = end
	}

	total_elapsed := time.since(start_total)
	println('====================================================')
	println('Build Summary:')
	println('  Success   : ${success_count} / ${app_files.len}')
	if fail_count > 0 {
		println('  Failed    : ${fail_count}')
	}
	println('  Total Time: ${total_elapsed.milliseconds()}ms (${total_elapsed.seconds():.2f}s)')
	println('  Binaries  : ${out_dir}/')
	println('====================================================')

	if fail_count > 0 {
		exit(1)
	}
}

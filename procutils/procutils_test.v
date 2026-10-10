module procutils

struct LineCollector {
mut:
	lines []string
}

fn test_exec_stream() {
	mut col := &LineCollector{}
	res := exec_stream('echo', ['hello\nworld'], fn [mut col] (line string, is_err bool) {
		if line.trim_space().len > 0 {
			col.lines << line.trim_space()
		}
	}) or { panic(err) }

	assert res.exit_code == 0
	assert res.stdout.contains('hello')
	assert res.stdout.contains('world')
	assert col.lines.contains('hello')
	assert col.lines.contains('world')
}

fn test_pipeline() {
	out := pipeline([
		cmd('printf', 'alpha\nbeta\ngamma\n'),
		cmd('grep', 'beta'),
	]) or { panic(err) }

	assert out.trim_space() == 'beta'
}

fn test_exec_with_timeout() {
	res := exec_with_timeout('echo', ['quick'], 2000) or { panic(err) }
	assert res.exit_code == 0
	assert res.stdout.trim_space() == 'quick'
}

module cliutils

fn new_test_parser() FlagParser {
	mut fp := new_flag_parser('app', 'test')
	fp.add_flag_int('count', 'n', 1, 'how many')
	fp.add_flag_string('output', 'o', '', 'file')
	fp.add_flag_bool('verbose', 'v', false, 'chatty')
	fp.add_flag_bool('all', 'a', false, 'everything')
	fp.add_flag_float('ratio', 'r', 0.5, 'ratio')
	return fp
}

fn test_strip_ansi_full_ecma48() {
	assert strip_ansi('\x1b[31mred\x1b[0m') == 'red'
	// v1 scanned to the next `m` and ate "hello " here.
	assert strip_ansi('\x1b[2Khello mom') == 'hello mom'
	assert strip_ansi('\x1b[1A\x1b[38;5;196mX') == 'X'
	assert strip_ansi('\x1b]8;;https://x.io\x07link\x1b]8;;\x07') == 'link'
	assert strip_ansi('\x1b]0;title\x1b\\rest') == 'rest'
	assert strip_ansi('naïve ✓ \x1b[1mbold\x1b[22m') == 'naïve ✓ bold'
	assert strip_ansi('trailing \x1b') == 'trailing \x1b'
}

fn test_flag_attached_and_combined() {
	mut fp := new_test_parser()
	fp.parse(['-n5', '-o=out.txt', '-va', 'file1']) or { panic(err) }
	assert fp.get_int('count') == 5
	assert fp.get_string('output') == 'out.txt'
	assert fp.get_bool('verbose') && fp.get_bool('all')
	assert fp.get_positional() == ['file1']
}

fn test_flag_double_dash_and_negatives() {
	mut fp := new_test_parser()
	fp.parse(['--count', '-3', '-7', '--', '--verbose', '-n']) or { panic(err) }
	assert fp.get_int('count') == -3
	assert fp.get_positional() == ['-7', '--verbose', '-n']
	assert !fp.get_bool('verbose')
	mut fp2 := new_test_parser()
	fp2.parse(['--ratio=-0.25', '--verbose=false']) or { panic(err) }
	assert fp2.get_float('ratio') == -0.25 && !fp2.get_bool('verbose')
}

fn test_flag_validation_errors() {
	cases := [
		['--count', 'abc'],
		['--count'],
		['-o'],
		['--ratio', 'x'],
		['--verbose=maybe'],
		['-vn'],
		['-vz'],
		['--nope'],
	]
	for args in cases {
		mut fp := new_test_parser()
		fp.parse(args) or { continue }
		assert false, 'expected error for ${args}'
	}
	mut ok := new_test_parser()
	ok.parse(['--ratio', '0', '--count', '+4']) or { panic(err) }
	assert ok.get_int('count') == 4 && ok.get_float('ratio') == 0.0
}

fn test_progress_clamps() {
	mut pb := new_progress_bar(10, 10)
	pb.update(-5)
	assert pb.current == 0
	pb.update(50)
	assert pb.current == 10
}

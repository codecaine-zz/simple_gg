module main

import simplegui

fn test_quote_arg_basic() {
	assert simplegui.quote_arg('') == "''"
	assert simplegui.quote_arg('hello') == "'hello'"
	assert simplegui.quote_arg('hello world') == "'hello world'"
}

fn test_quote_arg_injection_attempts() {
	// Semicolons and chained commands
	assert simplegui.quote_arg('foo; rm -rf /') == "'foo; rm -rf /'"
	// Subshells and dollar signs
	assert simplegui.quote_arg('foo $(whoami)') == "'foo \$(whoami)'"
	// Backticks
	assert simplegui.quote_arg('foo `id`') == "'foo `id`'"
	// Pipes and ampersands
	assert simplegui.quote_arg('foo | cat & id') == "'foo | cat & id'"
	// Single quotes inside string
	assert simplegui.quote_arg("user's file") == "'user'\\''s file'"
	assert simplegui.quote_arg("'; id; '") == "''\\''; id; '\\'''"
}

fn test_quote_path() {
	assert simplegui.quote_path('/Users/test/Documents/file.txt') == "'/Users/test/Documents/file.txt'"
	assert simplegui.quote_path('  /Users/test/dir/  ') == "'/Users/test/dir/'"
}

fn test_sanitize_filename() {
	assert simplegui.sanitize_filename('clean_file.txt') == 'clean_file.txt'
	assert simplegui.sanitize_filename('../../../etc/passwd') == '.._.._.._etc_passwd'
	assert simplegui.sanitize_filename('file;id.mp4') == 'file_id.mp4'
	assert simplegui.sanitize_filename('file$(whoami).png') == 'file__whoami_.png'
}

fn test_exec_safe() {
	res := simplegui.exec_safe('echo', ['hello', 'world'])
	assert res.exit_code == 0
	assert res.output.trim_space() == 'hello world'

	// Test that arguments containing shell metacharacters are treated literally and NOT executed
	res_inject := simplegui.exec_safe('echo', ['$(echo injected)', '; echo injected2'])
	assert res_inject.exit_code == 0
	assert res_inject.output.contains('$(echo injected)')
	assert res_inject.output.contains('; echo injected2')
}

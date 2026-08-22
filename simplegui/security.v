module simplegui

import os

// quote_arg escapes a string so that it can be safely used as a single shell argument.
// Uses strict POSIX single-quote wrapping: wraps in '...' and replaces internal ' with '\''.
pub fn quote_arg(s string) string {
	if s == '' {
		return "''"
	}
	return "'" + s.replace("'", "'\\''") + "'"
}

// quote_path validates that a path does not contain null bytes and safely quotes it.
pub fn quote_path(path string) string {
	clean := path.replace('\x00', '').trim_space()
	return quote_arg(clean)
}

// exec_safe executes a binary with an array of arguments, ensuring every argument
// is strictly quoted with quote_arg to prevent command injection and shell syntax errors.
pub fn exec_safe(bin string, args []string) os.Result {
	safe_bin := quote_arg(bin)
	mut safe_args := []string{}
	for a in args {
		safe_args << quote_arg(a)
	}
	cmd := '${safe_bin} ${safe_args.join(' ')}'
	return os.execute(cmd)
}

// exec_safe_stdin executes a binary with arguments while piping standard input from a target file securely.
pub fn exec_safe_stdin(bin string, args []string, input_file string) os.Result {
	safe_bin := quote_arg(bin)
	mut safe_args := []string{}
	for a in args {
		safe_args << quote_arg(a)
	}
	cmd := '${safe_bin} ${safe_args.join(' ')} < ${quote_path(input_file)}'
	return os.execute(cmd)
}

// sanitize_filename strips path traversal and shell metacharacters from user-provided file names.
pub fn sanitize_filename(name string) string {
	mut s := name.replace('\x00', '').replace('/', '_').replace('\\', '_').replace(':', '_')
	s = s.replace(';', '_').replace('&', '_').replace('|', '_').replace('`', '_').replace('$', '_')
	s = s.replace('(', '_').replace(')', '_').replace('"', '_').replace("'", '_')
	return s.trim_space()
}

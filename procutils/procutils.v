module procutils

import os
import time

pub struct ProcessCommand {
pub:
	program string
	args    []string
}

// to_shell formats the command with POSIX single-quote escaping for shell execution
pub fn (c ProcessCommand) to_shell() string {
	mut parts := [quote_arg(c.program)]
	for a in c.args {
		parts << quote_arg(a)
	}
	return parts.join(' ')
}

pub struct ProcessResult {
pub:
	exit_code int
	stdout    string
	stderr    string
}

pub fn (r ProcessResult) success() bool {
	return r.exit_code == 0
}

// quote_arg strictly quotes an argument using POSIX single quotes to eliminate shell injection
pub fn quote_arg(arg string) string {
	if arg.len == 0 {
		return "''"
	}
	return "'" + arg.replace("'", '\'"\'"\'') + "'"
}

// cmd creates a ProcessCommand with program and arguments
pub fn cmd(program string, args ...string) ProcessCommand {
	mut a := []string{}
	for arg in args {
		a << arg
	}
	return ProcessCommand{
		program: program
		args:    a
	}
}

// exec_stream executes a command while streaming output in real-time via callback
pub fn exec_stream(program string, args []string, on_line fn (line string, is_stderr bool)) !ProcessResult {
	mut p := os.new_process(program)
	p.set_args(args)
	p.set_redirect_stdio()
	p.run()

	mut full_stdout := []string{}
	mut full_stderr := []string{}

	for p.is_alive() {
		out_chunk := p.stdout_read()
		if out_chunk.len > 0 {
			full_stdout << out_chunk
			for line in out_chunk.split_into_lines() {
				on_line(line, false)
			}
		}
		err_chunk := p.stderr_read()
		if err_chunk.len > 0 {
			full_stderr << err_chunk
			for line in err_chunk.split_into_lines() {
				on_line(line, true)
			}
		}
		time.sleep(5 * time.millisecond)
	}

	// Slurp any trailing bytes remaining on the pipes
	last_out := p.stdout_slurp()
	if last_out.len > 0 {
		full_stdout << last_out
		for line in last_out.split_into_lines() {
			on_line(line, false)
		}
	}
	last_err := p.stderr_slurp()
	if last_err.len > 0 {
		full_stderr << last_err
		for line in last_err.split_into_lines() {
			on_line(line, true)
		}
	}

	p.wait()
	p.close()

	return ProcessResult{
		exit_code: p.code
		stdout:    full_stdout.join('')
		stderr:    full_stderr.join('')
	}
}

// exec_with_timeout executes a command and kills it if it exceeds timeout_ms
pub fn exec_with_timeout(program string, args []string, timeout_ms int) !ProcessResult {
	mut p := os.new_process(program)
	p.set_args(args)
	p.set_redirect_stdio()
	p.run()

	start := time.now()
	for p.is_alive() {
		elapsed := time.since(start).milliseconds()
		if elapsed > timeout_ms {
			p.signal_kill()
			p.wait()
			p.close()
			return error('process ${program} exceeded timeout of ${timeout_ms}ms')
		}
		time.sleep(10 * time.millisecond)
	}

	out := p.stdout_slurp()
	err := p.stderr_slurp()
	p.wait()
	p.close()

	return ProcessResult{
		exit_code: p.code
		stdout:    out
		stderr:    err
	}
}

// pipeline chains multiple commands using shell piping with POSIX quote-escaping
pub fn pipeline(commands []ProcessCommand) !string {
	if commands.len == 0 {
		return ''
	}

	mut parts := []string{}
	for c in commands {
		parts << c.to_shell()
	}
	pipeline_str := parts.join(' | ')

	res := os.execute(pipeline_str)
	if res.exit_code != 0 && res.output.len == 0 {
		return error('pipeline execution failed with code ${res.exit_code}')
	}
	return res.output
}

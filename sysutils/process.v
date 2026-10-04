module sysutils

import os
import strings
import time

// RunOptions configures run_command.
@[params]
pub struct RunOptions {
pub:
	timeout_ms int               // 0 = no limit
	work_dir   string            // '' = current directory
	env        map[string]string // extra variables merged over the current environment
}

// CommandResult is the outcome of run_command.
pub struct CommandResult {
pub:
	stdout      string
	stderr      string
	exit_code   int
	timed_out   bool
	duration_ms i64
}

// success reports a zero exit code without a timeout.
pub fn (r CommandResult) success() bool {
	return r.exit_code == 0 && !r.timed_out
}

// run_command executes a program directly, with no shell, so arguments are
// passed verbatim and command injection is impossible by construction. stdout
// and stderr are captured separately; on timeout the process group is killed
// and exit_code is 124.
pub fn run_command(bin string, args []string, opts RunOptions) !CommandResult {
	path := if bin.contains('/') || bin.contains('\\') {
		bin
	} else {
		os.find_abs_path_of_executable(bin) or { return error('command not found: ${bin}') }
	}
	t0 := time.now()
	mut p := os.new_process(path)
	p.set_args(args)
	if opts.work_dir != '' {
		p.set_work_folder(opts.work_dir)
	}
	if opts.env.len > 0 {
		mut env := os.environ()
		for k, v in opts.env {
			env[k] = v
		}
		p.set_environment(env)
	}
	p.set_redirect_stdio()
	p.use_pgroup = true
	p.run()
	if p.err != '' {
		return error('failed to start ${bin}: ${p.err}')
	}
	mut out := strings.new_builder(256)
	mut errb := strings.new_builder(64)
	mut timed_out := false
	for p.is_alive() {
		mut got := false
		if p.is_pending(.stdout) {
			out.write_string(p.stdout_read())
			got = true
		}
		if p.is_pending(.stderr) {
			errb.write_string(p.stderr_read())
			got = true
		}
		if !got {
			time.sleep(2 * time.millisecond)
		}
		if opts.timeout_ms > 0 && time.since(t0).milliseconds() > opts.timeout_ms {
			timed_out = true
			p.signal_pgkill()
			break
		}
	}
	if !timed_out {
		out.write_string(p.stdout_slurp())
		errb.write_string(p.stderr_slurp())
	}
	p.wait()
	code := if timed_out { 124 } else { p.code }
	p.close()
	return CommandResult{
		stdout:      out.str()
		stderr:      errb.str()
		exit_code:   code
		timed_out:   timed_out
		duration_ms: time.since(t0).milliseconds()
	}
}

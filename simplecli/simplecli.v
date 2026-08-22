// Module simplecli - Headless Console & RAD Toolkit for V
// File: simplecli.v
//
// Description:
//   This file provides the core `SimpleCli` console application runner, ANSI color styling,
//   rich terminal components (ASCII banners, boxed panels, formatted tables, progress bars,
//   spinners, interactive prompts, selects, confirms), reactive key-value state persistence,
//   command-line flag/argument parsing, structured multi-level logging, and file log streaming.

module simplecli

import os
import term
import time
import json2

// LogLevel defines the severity threshold for console and file logging.
pub enum LogLevel {
	trace = 0
	debug = 1
	info  = 2
	warn  = 3
	error = 4
	silent = 5
}

// FlagOption represents a command-line flag definition.
pub struct FlagOption {
pub:
	name        string
	short       string
	kind        string // 'string', 'int', 'bool', 'float'
	default_val string
	desc        string
}

// SimpleCli represents a headless console utility application instance.
@[heap]
pub struct SimpleCli {
pub mut:
	app_name     string = 'SimpleCli Application'
	version      string = '1.0.0'
	author       string
	description  string
	debug_mode   bool
	no_color     bool
	silent_mode  bool
	log_level    LogLevel = .info
	log_file     string
	state        map[string]string
	flags_def    map[string]FlagOption
	flags_val    map[string]string
	pos_args     []string
	bench_start  time.Time
}

// new creates a new SimpleCli application instance with the given name.
pub fn new(app_name string) &SimpleCli {
	return &SimpleCli{
		app_name: app_name
		bench_start: time.now()
	}
}

// new_app creates a new SimpleCli application instance with name and version.
pub fn new_app(app_name string, version string) &SimpleCli {
	return &SimpleCli{
		app_name: app_name
		version: version
		bench_start: time.now()
	}
}

// init_app initializes a default SimpleCli instance.
pub fn init_app() &SimpleCli {
	return new('SimpleCli')
}

// =============================================================================
// 1. Configuration & Builder Methods
// =============================================================================

// set_version sets the application version string.
pub fn (mut cli SimpleCli) set_version(v string) &SimpleCli {
	cli.version = v
	return cli
}

// set_author sets the application author metadata.
pub fn (mut cli SimpleCli) set_author(author string) &SimpleCli {
	cli.author = author
	return cli
}

// set_description sets the application description.
pub fn (mut cli SimpleCli) set_description(desc string) &SimpleCli {
	cli.description = desc
	return cli
}

// set_debug enables or disables debug logging output.
pub fn (mut cli SimpleCli) set_debug(debug bool) &SimpleCli {
	cli.debug_mode = debug
	if debug && int(cli.log_level) > int(LogLevel.debug) {
		cli.log_level = .debug
	}
	return cli
}

// set_no_color disables ANSI colored output.
pub fn (mut cli SimpleCli) set_no_color(no_color bool) &SimpleCli {
	cli.no_color = no_color
	return cli
}

// set_silent enables or disables all non-error console output.
pub fn (mut cli SimpleCli) set_silent(silent bool) &SimpleCli {
	cli.silent_mode = silent
	if silent {
		cli.log_level = .silent
	}
	return cli
}

// set_log_level sets the minimum log level for console output.
pub fn (mut cli SimpleCli) set_log_level(level LogLevel) &SimpleCli {
	cli.log_level = level
	return cli
}

// set_log_file redirects log messages to an output file as well as console.
pub fn (mut cli SimpleCli) set_log_file(file_path string) &SimpleCli {
	cli.log_file = resolve_user_path(file_path)
	dir := os.dir(cli.log_file)
	if dir.len > 0 && !os.exists(dir) {
		os.mkdir_all(dir) or {}
	}
	return cli
}

// =============================================================================
// 2. Command-Line Arguments & Flags Parser
// =============================================================================

// add_flag_string defines a string CLI flag (e.g. `--config` or `-c`).
pub fn (mut cli SimpleCli) add_flag_string(name string, short string, default_val string, desc string) &SimpleCli {
	cli.flags_def[name] = FlagOption{
		name: name
		short: short
		kind: 'string'
		default_val: default_val
		desc: desc
	}
	cli.flags_val[name] = default_val
	return cli
}

// add_flag_int defines an integer CLI flag (e.g. `--port` or `-p`).
pub fn (mut cli SimpleCli) add_flag_int(name string, short string, default_val int, desc string) &SimpleCli {
	cli.flags_def[name] = FlagOption{
		name: name
		short: short
		kind: 'int'
		default_val: default_val.str()
		desc: desc
	}
	cli.flags_val[name] = default_val.str()
	return cli
}

// add_flag_bool defines a boolean flag toggle (e.g. `--verbose` or `-v`).
pub fn (mut cli SimpleCli) add_flag_bool(name string, short string, default_val bool, desc string) &SimpleCli {
	cli.flags_def[name] = FlagOption{
		name: name
		short: short
		kind: 'bool'
		default_val: default_val.str()
		desc: desc
	}
	cli.flags_val[name] = default_val.str()
	return cli
}

// add_flag_float defines a floating-point flag (e.g. `--rate` or `-r`).
pub fn (mut cli SimpleCli) add_flag_float(name string, short string, default_val f64, desc string) &SimpleCli {
	cli.flags_def[name] = FlagOption{
		name: name
		short: short
		kind: 'float'
		default_val: default_val.str()
		desc: desc
	}
	cli.flags_val[name] = default_val.str()
	return cli
}

// parse_args parses a raw slice of string arguments (such as `os.args[1..]`).
pub fn (mut cli SimpleCli) parse_args(raw_args []string) !&SimpleCli {
	mut i := 0
	cli.pos_args.clear()

	for i < raw_args.len {
		arg := raw_args[i]

		// Automatic Built-in Flags
		if arg == '--help' || arg == '-h' {
			cli.print_help()
			exit(0)
		}
		if arg == '--version' || arg == '-v' {
			println('${cli.app_name} v${cli.version}')
			exit(0)
		}
		if arg == '--debug' {
			cli.set_debug(true)
			i++
			continue
		}
		if arg == '--no-color' {
			cli.set_no_color(true)
			i++
			continue
		}
		if arg == '--silent' {
			cli.set_silent(true)
			i++
			continue
		}

		if arg.starts_with('--') {
			flag_name := arg[2..]
			if flag_name.contains('=') {
				parts := flag_name.split('=')
				k := parts[0]
				v := parts[1]
				if k in cli.flags_def {
					cli.flags_val[k] = v
				}
			} else if flag_name in cli.flags_def {
				def := cli.flags_def[flag_name]
				if def.kind == 'bool' {
					cli.flags_val[flag_name] = 'true'
				} else if i + 1 < raw_args.len {
					cli.flags_val[flag_name] = raw_args[i + 1]
					i++
				}
			}
		} else if arg.starts_with('-') && arg.len > 1 {
			short_name := arg[1..]
			mut matched := false
			for k, def in cli.flags_def {
				if def.short == short_name {
					matched = true
					if def.kind == 'bool' {
						cli.flags_val[k] = 'true'
					} else if i + 1 < raw_args.len {
						cli.flags_val[k] = raw_args[i + 1]
						i++
					}
					break
				}
			}
			if !matched {
				cli.pos_args << arg
			}
		} else {
			cli.pos_args << arg
		}
		i++
	}
	return cli
}

// parse_cli parses `os.args[1..]` automatically.
pub fn (mut cli SimpleCli) parse_cli() !&SimpleCli {
	args := if os.args.len > 1 { os.args[1..] } else { []string{} }
	return cli.parse_args(args)
}

// get_flag_string retrieves the parsed string value of a flag.
pub fn (cli &SimpleCli) get_flag_string(name string) string {
	if name in cli.flags_val {
		return cli.flags_val[name]
	}
	return ''
}

// get_flag_int retrieves the parsed integer value of a flag.
pub fn (cli &SimpleCli) get_flag_int(name string) int {
	if name in cli.flags_val {
		return cli.flags_val[name].int()
	}
	return 0
}

// get_flag_bool retrieves the parsed boolean value of a flag.
pub fn (cli &SimpleCli) get_flag_bool(name string) bool {
	if name in cli.flags_val {
		v := cli.flags_val[name].to_lower()
		return v == 'true' || v == '1' || v == 'yes'
	}
	return false
}

// get_flag_float retrieves the parsed floating-point value of a flag.
pub fn (cli &SimpleCli) get_flag_float(name string) f64 {
	if name in cli.flags_val {
		return cli.flags_val[name].f64()
	}
	return 0.0
}

// get_positional_args returns all non-flag positional arguments.
pub fn (cli &SimpleCli) get_positional_args() []string {
	return cli.pos_args
}

// print_help prints an automatically generated, styled help message.
pub fn (cli &SimpleCli) print_help() {
	println('${cli.bold(cli.app_name)} ${cli.dim('v' + cli.version)}')
	if cli.description.len > 0 {
		println(cli.description)
	}
	println('\n${cli.bold('USAGE:')}')
	println('  ${cli.cyan(cli.app_name.to_lower().replace(' ', '-'))} [options] [arguments]')
	
	println('\n${cli.bold('OPTIONS:')}')
	println('  ${cli.cyan('--help, -h')}            Show this help information')
	println('  ${cli.cyan('--version, -v')}         Show application version')
	println('  ${cli.cyan('--debug')}               Enable verbose debug logging')
	println('  ${cli.cyan('--no-color')}            Disable ANSI terminal colors')
	println('  ${cli.cyan('--silent')}              Suppress non-error output')

	for name, def in cli.flags_def {
		short_str := if def.short.len > 0 { '-${def.short}, ' } else { '    ' }
		pad := ' '.repeat(int_max(0, 18 - name.len))
		def_str := if def.default_val.len > 0 { ' ' + cli.dim('(default: ' + def.default_val + ')') } else { '' }
		println('  ${cli.cyan(short_str + '--' + name)}${pad} ${def.desc}${def_str}')
	}
	println('')
}

// =============================================================================
// 3. Terminal Styling & Color Helpers
// =============================================================================

// colorize wraps text with ANSI color sequences unless `no_color` is enabled.
pub fn (cli &SimpleCli) colorize(text string, color_fn fn (string) string) string {
	if cli.no_color {
		return text
	}
	return color_fn(text)
}

// bold returns bold text.
pub fn (cli &SimpleCli) bold(text string) string {
	return cli.colorize(text, term.bold)
}

// dim returns dimmed text.
pub fn (cli &SimpleCli) dim(text string) string {
	return cli.colorize(text, term.dim)
}

// green returns green text.
pub fn (cli &SimpleCli) green(text string) string {
	return cli.colorize(text, term.green)
}

// cyan returns cyan text.
pub fn (cli &SimpleCli) cyan(text string) string {
	return cli.colorize(text, term.cyan)
}

// yellow returns yellow text.
pub fn (cli &SimpleCli) yellow(text string) string {
	return cli.colorize(text, term.yellow)
}

// red returns red text.
pub fn (cli &SimpleCli) red(text string) string {
	return cli.colorize(text, term.red)
}

// blue returns blue text.
pub fn (cli &SimpleCli) blue(text string) string {
	return cli.colorize(text, term.blue)
}

// magenta returns magenta text.
pub fn (cli &SimpleCli) magenta(text string) string {
	return cli.colorize(text, term.magenta)
}

// =============================================================================
// 4. Formatted Console Output & Structured Logging
// =============================================================================

fn (cli &SimpleCli) write_log(level_name string, msg string) {
	if cli.log_file.len > 0 {
		timestamp := time.now().format_ss()
		entry := '[${timestamp}] [${level_name}] ${msg}\n'
		mut f := os.open_append(cli.log_file) or { return }
		f.write_string(entry) or {}
		f.close()
	}
}

// print prints a message without trailing newline.
pub fn (cli &SimpleCli) print(msg string) &SimpleCli {
	if !cli.silent_mode {
		print(msg)
		os.flush()
	}
	return cli
}

// println prints a message with a trailing newline.
pub fn (cli &SimpleCli) println(msg string) &SimpleCli {
	if !cli.silent_mode {
		println(msg)
	}
	return cli
}

// trace logs fine-grained diagnostics (level: trace).
pub fn (cli &SimpleCli) trace(msg string) &SimpleCli {
	cli.write_log('TRACE', msg)
	if int(cli.log_level) <= int(LogLevel.trace) && !cli.silent_mode {
		badge := cli.dim('[TRACE]')
		println('${badge} ${msg}')
	}
	return cli
}

// debug logs debug-level information (level: debug).
pub fn (cli &SimpleCli) debug(msg string) &SimpleCli {
	cli.write_log('DEBUG', msg)
	if (cli.debug_mode || int(cli.log_level) <= int(LogLevel.debug)) && !cli.silent_mode {
		badge := cli.magenta('[DEBUG]')
		println('${badge} ${msg}')
	}
	return cli
}

// info logs an informational message with a blue/cyan badge (level: info).
pub fn (cli &SimpleCli) info(msg string) &SimpleCli {
	cli.write_log('INFO', msg)
	if int(cli.log_level) <= int(LogLevel.info) && !cli.silent_mode {
		badge := cli.cyan('[INFO]')
		println('${badge} ${msg}')
	}
	return cli
}

// success logs a success message with a green badge.
pub fn (cli &SimpleCli) success(msg string) &SimpleCli {
	cli.write_log('SUCCESS', msg)
	if !cli.silent_mode {
		badge := cli.green('[SUCCESS]')
		println('${badge} ${msg}')
	}
	return cli
}

// warn logs a warning message with a yellow badge (level: warn).
pub fn (cli &SimpleCli) warn(msg string) &SimpleCli {
	cli.write_log('WARN', msg)
	if int(cli.log_level) <= int(LogLevel.warn) && !cli.silent_mode {
		badge := cli.yellow('[WARNING]')
		println('${badge} ${msg}')
	}
	return cli
}

// error logs an error message with a red badge to stderr (level: error).
pub fn (cli &SimpleCli) error(msg string) &SimpleCli {
	cli.write_log('ERROR', msg)
	badge := cli.red('[ERROR]')
	eprintln('${badge} ${msg}')
	return cli
}

// fatal logs an error message and terminates the process immediately.
pub fn (cli &SimpleCli) fatal(msg string) {
	cli.error(msg)
	exit(1)
}

// step prints a numbered or bulleted workflow step.
pub fn (cli &SimpleCli) step(num int, title string) &SimpleCli {
	if !cli.silent_mode {
		badge := cli.cyan('[Step ${num}]')
		println('\n${badge} ${cli.bold(title)}')
	}
	return cli
}

// divider prints a horizontal rule across the terminal width.
pub fn (cli &SimpleCli) divider(ch string, length int) &SimpleCli {
	if !cli.silent_mode {
		len_to_use := if length > 0 { length } else { 70 }
		char_to_use := if ch.len > 0 { ch } else { '─' }
		mut line := ''
		for _ in 0 .. len_to_use {
			line += char_to_use
		}
		println(cli.dim(line))
	}
	return cli
}

// banner prints a modern ASCII art header box with app title and version.
pub fn (cli &SimpleCli) banner(title string, subtitle string) &SimpleCli {
	if cli.silent_mode {
		return cli
	}
	t := if title.len > 0 { title } else { cli.app_name }
	s := if subtitle.len > 0 { subtitle } else { 'v' + cli.version }
	
	line_len := 64
	println(cli.cyan('┌' + '─'.repeat(line_len) + '┐'))
	println(cli.cyan('│') + '  ' + cli.bold(t) + ' '.repeat(int_max(0, line_len - t.len - 2)) + cli.cyan('│'))
	if s.len > 0 {
		println(cli.cyan('│') + '  ' + cli.dim(s) + ' '.repeat(int_max(0, line_len - s.len - 2)) + cli.cyan('│'))
	}
	println(cli.cyan('└' + '─'.repeat(line_len) + '┘'))
	return cli
}

// panel displays text inside a stylish boxed panel.
pub fn (cli &SimpleCli) panel(title string, content string) &SimpleCli {
	if cli.silent_mode {
		return cli
	}
	lines := content.split('\n')
	mut max_len := title.len + 4
	for line in lines {
		if line.len > max_len {
			max_len = line.len
		}
	}
	max_len = int_max(max_len, 40)
	
	header := '─ ' + cli.bold(title) + ' '
	header_dashes := int_max(0, max_len - title.len - 3)
	println(cli.cyan('┌' + header + '─'.repeat(header_dashes) + '┐'))
	for line in lines {
		padding := int_max(0, max_len - line.len)
		println(cli.cyan('│ ') + line + ' '.repeat(padding) + cli.cyan(' │'))
	}
	println(cli.cyan('└' + '─'.repeat(max_len + 2) + '┘'))
	return cli
}

// card is an alias for panel.
pub fn (cli &SimpleCli) card(title string, content string) &SimpleCli {
	return cli.panel(title, content)
}

// print_kv prints aligned key-value pairs.
pub fn (cli &SimpleCli) print_kv(pairs map[string]string) &SimpleCli {
	if cli.silent_mode {
		return cli
	}
	mut max_k := 0
	for k, _ in pairs {
		if k.len > max_k {
			max_k = k.len
		}
	}
	for k, v in pairs {
		pad := ' '.repeat(max_k - k.len)
		println('  ${cli.dim(k + ':')}${pad}  ${cli.bold(v)}')
	}
	return cli
}

// table renders a structured ASCII data table with headers and rows.
pub fn (cli &SimpleCli) table(headers []string, rows [][]string) &SimpleCli {
	if cli.silent_mode {
		return cli
	}
	if headers.len == 0 && rows.len == 0 {
		return cli
	}
	
	col_count := if headers.len > 0 { headers.len } else { rows[0].len }
	mut col_widths := []int{len: col_count, init: 4}
	
	// Determine header widths
	for i, h in headers {
		if i < col_widths.len && h.len > col_widths[i] {
			col_widths[i] = h.len
		}
	}
	// Determine row cell widths
	for r in rows {
		for i, cell in r {
			if i < col_widths.len && cell.len > col_widths[i] {
				col_widths[i] = cell.len
			}
		}
	}
	
	// Top border
	mut top := '┌'
	mut sep := '├'
	mut bot := '└'
	for i, w in col_widths {
		top += '─'.repeat(w + 2)
		sep += '─'.repeat(w + 2)
		bot += '─'.repeat(w + 2)
		if i < col_widths.len - 1 {
			top += '┬'
			sep += '┼'
			bot += '┴'
		} else {
			top += '┐'
			sep += '┤'
			bot += '┘'
		}
	}
	println(cli.dim(top))
	
	// Headers
	if headers.len > 0 {
		mut h_row := '│'
		for i, h in headers {
			w := col_widths[i]
			pad := ' '.repeat(w - h.len)
			h_row += ' ' + cli.bold(h) + pad + ' │'
		}
		println(h_row)
		println(cli.dim(sep))
	}
	
	// Rows
	for r in rows {
		mut row_str := '│'
		for i in 0 .. col_count {
			val := if i < r.len { r[i] } else { '' }
			w := col_widths[i]
			pad := ' '.repeat(int_max(0, w - val.len))
			row_str += ' ' + val + pad + ' │'
		}
		println(row_str)
	}
	
	println(cli.dim(bot))
	return cli
}

// progress_bar prints or updates a visual progress bar (0.0 to 100.0%).
pub fn (cli &SimpleCli) progress_bar(current f64, total f64, label string) &SimpleCli {
	if cli.silent_mode {
		return cli
	}
	pct := if total > 0 { (current / total) * 100.0 } else { 0.0 }
	clamped_pct := math_clamp_f64(pct, 0.0, 100.0)
	bar_width := 30
	filled := int((clamped_pct / 100.0) * f64(bar_width))
	
	mut bar := ''
	for i in 0 .. bar_width {
		if i < filled {
			bar += '█'
		} else {
			bar += '░'
		}
	}
	
	lbl := if label.len > 0 { ' ${label}' } else { '' }
	print('\r  ${cli.cyan(bar)} ${clamped_pct:5.1f}%${lbl}')
	os.flush()
	if current >= total && total > 0 {
		println('')
	}
	return cli
}

// spinner simulates a short CLI spinner step for long-running operations.
pub fn (cli &SimpleCli) spinner(msg string, duration_ms int) &SimpleCli {
	if cli.silent_mode {
		time.sleep(duration_ms * time.millisecond)
		return cli
	}
	frames := ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏']
	start := time.now()
	mut idx := 0
	for {
		elapsed := time.since(start).milliseconds()
		if elapsed >= duration_ms {
			break
		}
		frame := frames[idx % frames.len]
		print('\r  ${cli.cyan(frame)} ${msg}')
		os.flush()
		time.sleep(80 * time.millisecond)
		idx++
	}
	print('\r  ${cli.green('✓')} ${msg}\n')
	os.flush()
	return cli
}

// =============================================================================
// 5. Interactive RAD User Prompts & Inputs
// =============================================================================

// prompt prompts the user for text input in the console, with an optional default value.
pub fn (cli &SimpleCli) prompt(question string, default_val string) string {
	def_hint := if default_val.len > 0 { ' ' + cli.dim('(${default_val})') } else { '' }
	print('${cli.cyan('?')} ${cli.bold(question)}${def_hint}: ')
	os.flush()
	input := os.get_raw_line().trim_space()
	if input.len == 0 && default_val.len > 0 {
		return default_val
	}
	return input
}

// prompt_password prompts the user for sensitive password input (masked or standard).
pub fn (cli &SimpleCli) prompt_password(question string) string {
	print('${cli.yellow('?')} ${cli.bold(question)}: ')
	os.flush()
	return os.get_raw_line().trim_space()
}

// prompt_validated prompts the user with custom validation function and retry loop.
pub fn (cli &SimpleCli) prompt_validated(question string, default_val string, validator fn (string) bool, error_msg string) string {
	for {
		ans := cli.prompt(question, default_val)
		if validator(ans) {
			return ans
		}
		err_text := if error_msg.len > 0 { error_msg } else { 'Invalid input format, please try again.' }
		println('  ${cli.red(err_text)}')
	}
	return default_val
}

// prompt_email prompts for a valid email address with loop retry.
pub fn (cli &SimpleCli) prompt_email(question string, default_val string) string {
	return cli.prompt_validated(question, default_val, fn (s string) bool {
		cli_inst := new('Validator')
		return cli_inst.validate_email(s)
	}, 'Please enter a valid email address (e.g. name@domain.com)')
}

// prompt_url prompts for a valid HTTP/HTTPS URL with loop retry.
pub fn (cli &SimpleCli) prompt_url(question string, default_val string) string {
	return cli.prompt_validated(question, default_val, fn (s string) bool {
		cli_inst := new('Validator')
		return cli_inst.validate_url(s)
	}, 'Please enter a valid URL (starting with http:// or https://)')
}

// prompt_number prompts for an integer within [min, max].
pub fn (cli &SimpleCli) prompt_number(question string, default_val int, min int, max int) int {
	for {
		ans_str := cli.prompt('${question} [${min}-${max}]', '${default_val}')
		val := ans_str.int()
		if val >= min && val <= max {
			return val
		}
		println('  ${cli.red('Value must be between ${min} and ${max}.')}')
	}
	return default_val
}

// confirm prompts the user for a yes/no confirmation, returning true on 'y' or 'yes'.
pub fn (cli &SimpleCli) confirm(question string, default_yes bool) bool {
	hint := if default_yes { '[Y/n]' } else { '[y/N]' }
	print('${cli.yellow('?')} ${cli.bold(question)} ${cli.dim(hint)}: ')
	os.flush()
	input := os.get_raw_line().trim_space().to_lower()
	if input.len == 0 {
		return default_yes
	}
	return input == 'y' || input == 'yes' || input == 'true' || input == '1'
}

// select displays a list of options and asks the user to pick one by index or keyword.
pub fn (cli &SimpleCli) select(question string, options []string) string {
	if options.len == 0 {
		return ''
	}
	println('${cli.cyan('?')} ${cli.bold(question)}')
	for i, opt in options {
		println('  ${cli.cyan('[' + (i + 1).str() + ']')} ${opt}')
	}
	for {
		print('  ${cli.dim('Enter choice [1-' + options.len.str() + ']: ')}')
		os.flush()
		input := os.get_raw_line().trim_space()
		val := input.int()
		if val >= 1 && val <= options.len {
			return options[val - 1]
		}
		// Match exact text if user typed option name
		for opt in options {
			if opt.to_lower() == input.to_lower() {
				return opt
			}
		}
		println('  ${cli.red('Invalid selection, please try again.')}')
	}
	return options[0]
}

// multi_select displays multiple choices and allows picking multiple comma-separated indices.
pub fn (cli &SimpleCli) multi_select(question string, options []string) []string {
	if options.len == 0 {
		return []
	}
	println('${cli.cyan('?')} ${cli.bold(question)} ${cli.dim('(comma-separated numbers, e.g. 1, 3)')}')
	for i, opt in options {
		println('  ${cli.cyan('[' + (i + 1).str() + ']')} ${opt}')
	}
	print('  ${cli.dim('Enter choices: ')}')
	os.flush()
	input := os.get_raw_line().trim_space()
	mut selected := []string{}
	parts := input.split(',')
	for p in parts {
		idx := p.trim_space().int()
		if idx >= 1 && idx <= options.len {
			selected << options[idx - 1]
		}
	}
	return selected
}

// =============================================================================
// 6. Reactive State Store & File Persistence
// =============================================================================

// set_state stores a key-value pair in memory.
pub fn (mut cli SimpleCli) set_state(key string, val string) &SimpleCli {
	cli.state[key] = val
	return cli
}

// get_state retrieves a stored state value or fallback.
pub fn (cli &SimpleCli) get_state(key string, fallback string) string {
	if key in cli.state {
		return cli.state[key]
	}
	return fallback
}

// get_state_int retrieves a stored state value parsed as an integer.
pub fn (cli &SimpleCli) get_state_int(key string, fallback int) int {
	if key in cli.state {
		return cli.state[key].int()
	}
	return fallback
}

// get_state_bool retrieves a stored state value parsed as a boolean.
pub fn (cli &SimpleCli) get_state_bool(key string, fallback bool) bool {
	if key in cli.state {
		v := cli.state[key].to_lower()
		return v == 'true' || v == '1' || v == 'yes'
	}
	return fallback
}

// clear_state resets all stored state values.
pub fn (mut cli SimpleCli) clear_state() &SimpleCli {
	cli.state.clear()
	return cli
}

// save_state persists all in-memory state key-values to a JSON file.
pub fn (cli &SimpleCli) save_state(file_path string) !&SimpleCli {
	json_str := json2.encode[map[string]string](cli.state)
	dir := os.dir(file_path)
	if dir.len > 0 && !os.exists(dir) {
		os.mkdir_all(dir)!
	}
	os.write_file(file_path, json_str)!
	return cli
}

// load_state loads state key-values from a JSON file into memory.
pub fn (mut cli SimpleCli) load_state(file_path string) !&SimpleCli {
	if !os.exists(file_path) {
		return error('State file "${file_path}" does not exist')
	}
	content := os.read_file(file_path)!
	raw_map := json2.decode[map[string]string](content)!
	for k, v in raw_map {
		cli.state[k] = v
	}
	return cli
}

// =============================================================================
// 7. Timing & Benchmark Utilities
// =============================================================================

// reset_timer restarts the internal execution timer.
pub fn (mut cli SimpleCli) reset_timer() &SimpleCli {
	cli.bench_start = time.now()
	return cli
}

// elapsed_ms returns the milliseconds elapsed since `new()` or `reset_timer()`.
pub fn (cli &SimpleCli) elapsed_ms() i64 {
	return time.since(cli.bench_start).milliseconds()
}

// print_elapsed prints the formatted elapsed runtime.
pub fn (cli &SimpleCli) print_elapsed() &SimpleCli {
	ms := cli.elapsed_ms()
	println(cli.dim('⚡ Execution time: ${ms} ms'))
	return cli
}

// =============================================================================
// 8. Internal Numeric Helpers
// =============================================================================

fn int_max(a int, b int) int {
	return if a > b { a } else { b }
}

fn math_clamp_f64(val f64, min f64, max f64) f64 {
	if val < min {
		return min
	}
	if val > max {
		return max
	}
	return val
}

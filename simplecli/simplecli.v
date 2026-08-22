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
import strings

// LogLevel defines the severity threshold for console and file logging.
pub enum LogLevel {
	trace = 0
	debug = 1
	info  = 2
	warn  = 3
	error = 4
	silent = 5
}

// AlertKind defines the visual style and icon of an alert callout box.
pub enum AlertKind {
	info
	success
	warning
	caution
	tip
	note
}

// TaskStatus represents the lifecycle state of a task checklist item.
pub enum TaskStatus {
	pending
	running
	done
	failed
	skipped
}

// FormFieldKind represents the data input type for form wizard fields.
pub enum FormFieldKind {
	text
	number
	boolean
	password
}

// FormField defines a single field inside an interactive multi-field form.
pub struct FormField {
pub:
	key         string
	label       string
	kind        FormFieldKind = .text
	default_val string
	required    bool
}

// PathMode defines path validation requirements for path prompts.
pub enum PathMode {
	any
	must_exist
	file
	directory
}

// TreeNode represents a node in a hierarchical console tree visualizer.
pub struct TreeNode {
pub mut:
	label    string
	children []TreeNode
}

// new_tree_node creates a new tree node.
pub fn new_tree_node(label string) TreeNode {
	return TreeNode{
		label: label
	}
}

// add_child adds a child label to a tree node and returns a reference to the created child.
pub fn (mut node TreeNode) add_child(child_label string) &TreeNode {
	node.children << TreeNode{
		label: child_label
	}
	return &node.children[node.children.len - 1]
}

// add_node adds an existing TreeNode as a child.
pub fn (mut node TreeNode) add_node(child TreeNode) &TreeNode {
	node.children << child
	return &node.children[node.children.len - 1]
}

// PipelineStep represents a single executable stage in a task pipeline.
pub struct PipelineStep {
pub:
	name    string
	step_fn fn () bool @[required]
}

// Pipeline executes multi-stage workflow tasks with live spinners and timers.
@[heap]
pub struct Pipeline {
pub mut:
	title string
	steps []PipelineStep
	cli   &SimpleCli
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

// sparkline converts a slice of floating point numbers into a compact Unicode sparkline string.
pub fn (cli &SimpleCli) sparkline(values []f64) string {
	if values.len == 0 {
		return ''
	}
	glyphs := [' ', '▂', '▃', '▄', '▅', '▆', '▇', '█']
	mut min_v := values[0]
	mut max_v := values[0]
	for v in values {
		if v < min_v {
			min_v = v
		}
		if v > max_v {
			max_v = v
		}
	}
	if max_v == min_v {
		return '▄'.repeat(values.len)
	}
	mut res := strings.new_builder(values.len * 4)
	for v in values {
		idx := int(((v - min_v) / (max_v - min_v)) * f64(glyphs.len - 1))
		clamped_idx := if idx < 0 { 0 } else if idx >= glyphs.len { glyphs.len - 1 } else { idx }
		res.write_string(glyphs[clamped_idx])
	}
	return res.str()
}

// bar_chart renders a stylish horizontal ASCII/Unicode bar chart.
pub fn (cli &SimpleCli) bar_chart(title string, data map[string]f64, max_width int) &SimpleCli {
	if cli.silent_mode || data.len == 0 {
		return cli
	}
	w := if max_width > 0 { max_width } else { 30 }
	mut max_val := 0.0
	mut max_lbl_len := 0
	for k, v in data {
		if v > max_val {
			max_val = v
		}
		if k.len > max_lbl_len {
			max_lbl_len = k.len
		}
	}
	max_lbl_len = int_max(max_lbl_len, 8)
	
	if title.len > 0 {
		println('\n${cli.bold(title)}')
		cli.divider('─', max_lbl_len + w + 20)
	}

	for k, v in data {
		pct := if max_val > 0.0 { (v / max_val) * 100.0 } else { 0.0 }
		bar_len := if max_val > 0.0 { int((v / max_val) * f64(w)) } else { 0 }
		clamped_bar_len := if bar_len < 0 { 0 } else if bar_len > w { w } else { bar_len }
		
		bar_str := '█'.repeat(clamped_bar_len) + '░'.repeat(w - clamped_bar_len)
		pad := ' '.repeat(int_max(0, max_lbl_len - k.len))
		
		println('  ${cli.bold(k)}${pad}  ${cli.cyan(bar_str)}  ${v:6.1f} ${cli.dim('(' + pct.str() + '%)')}')
	}
	println('')
	return cli
}

// gauge displays a single-metric meter gauge with threshold status indicator.
pub fn (cli &SimpleCli) gauge(title string, value f64, max f64, unit string) &SimpleCli {
	if cli.silent_mode {
		return cli
	}
	pct := if max > 0.0 { (value / max) * 100.0 } else { 0.0 }
	clamped_pct := math_clamp_f64(pct, 0.0, 100.0)
	bar_w := 20
	filled := int((clamped_pct / 100.0) * f64(bar_w))
	clamped_filled := if filled < 0 { 0 } else if filled > bar_w { bar_w } else { filled }
	
	bar_str := '█'.repeat(clamped_filled) + '░'.repeat(bar_w - clamped_filled)
	
	mut colored_bar := cli.green(bar_str)
	mut status_badge := cli.green('[OK]')
	if clamped_pct >= 90.0 {
		colored_bar = cli.red(bar_str)
		status_badge = cli.red('[CRITICAL]')
	} else if clamped_pct >= 75.0 {
		colored_bar = cli.yellow(bar_str)
		status_badge = cli.yellow('[WARN]')
	}
	
	u := if unit.len > 0 { ' ' + unit } else { '' }
	println('  ${cli.bold(title)}: [${colored_bar}] ${value:5.1f}/${max:5.1f}${u} (${clamped_pct:5.1f}%) ${status_badge}')
	return cli
}

// tree renders a hierarchical tree structure to console.
pub fn (cli &SimpleCli) tree(root TreeNode) &SimpleCli {
	if cli.silent_mode {
		return cli
	}
	println(cli.bold(root.label))
	cli.render_tree_children(root.children, '')
	return cli
}

fn (cli &SimpleCli) render_tree_children(children []TreeNode, prefix string) {
	for i, child in children {
		is_last := i == children.len - 1
		connector := if is_last { '└── ' } else { '├── ' }
		println('${cli.dim(prefix + connector)}${child.label}')
		new_prefix := prefix + if is_last { '    ' } else { '│   ' }
		if child.children.len > 0 {
			cli.render_tree_children(child.children, new_prefix)
		}
	}
}

// diff_text generates a colorized line-by-line diff between two strings.
pub fn (cli &SimpleCli) diff_text(old_text string, new_text string) string {
	old_lines := old_text.split('\n')
	new_lines := new_text.split('\n')
	
	mut b := strings.new_builder(1024)
	mut additions := 0
	mut deletions := 0
	
	max_lines := int_max(old_lines.len, new_lines.len)
	for i in 0 .. max_lines {
		line_num := (i + 1).str()
		pad := ' '.repeat(int_max(0, 4 - line_num.len))
		
		if i < old_lines.len && i < new_lines.len {
			if old_lines[i] == new_lines[i] {
				b.write_string('  ${cli.dim(line_num + pad + ' |')}   ${old_lines[i]}\n')
			} else {
				deletions++
				additions++
				b.write_string('  ${cli.red(line_num + pad + ' -')} ${cli.red(old_lines[i])}\n')
				b.write_string('  ${cli.green(line_num + pad + ' +')} ${cli.green(new_lines[i])}\n')
			}
		} else if i < old_lines.len {
			deletions++
			b.write_string('  ${cli.red(line_num + pad + ' -')} ${cli.red(old_lines[i])}\n')
		} else if i < new_lines.len {
			additions++
			b.write_string('  ${cli.green(line_num + pad + ' +')} ${cli.green(new_lines[i])}\n')
		}
	}
	summary := '  ${cli.dim('───')} ${cli.green('+' + additions.str() + ' additions')}, ${cli.red('-' + deletions.str() + ' deletions')} ${cli.dim('───')}\n'
	b.write_string(summary)
	return b.str()
}

// diff displays a colorized line-by-line unified diff between two text strings.
pub fn (cli &SimpleCli) diff(old_text string, new_text string) &SimpleCli {
	if !cli.silent_mode {
		print(cli.diff_text(old_text, new_text))
	}
	return cli
}

// badge formats an ANSI styled badge tag (e.g. `[PROD: ACTIVE]`).
pub fn (cli &SimpleCli) badge(prefix string, label string, level LogLevel) string {
	tag := if prefix.len > 0 { '${prefix}: ${label}' } else { label }
	if cli.no_color {
		return '[${tag}]'
	}
	return match level {
		.trace { cli.dim('[${tag}]') }
		.debug { cli.magenta('[${tag}]') }
		.info { cli.cyan('[${tag}]') }
		.warn { cli.yellow('[${tag}]') }
		.error { cli.red('[${tag}]') }
		.silent { '[${tag}]' }
	}
}

// alert displays a framed callout box with icon and style matching AlertKind.
pub fn (cli &SimpleCli) alert(kind AlertKind, title string, msg string) &SimpleCli {
	if cli.silent_mode {
		return cli
	}
	mut icon := 'ℹ'
	mut border_color_fn := cli.cyan
	mut badge_text := 'NOTE'
	
	match kind {
		.info {
			icon = 'ℹ'
			border_color_fn = cli.cyan
			badge_text = 'INFO'
		}
		.success {
			icon = '✓'
			border_color_fn = cli.green
			badge_text = 'SUCCESS'
		}
		.warning {
			icon = '⚠'
			border_color_fn = cli.yellow
			badge_text = 'WARNING'
		}
		.caution {
			icon = '✖'
			border_color_fn = cli.red
			badge_text = 'CAUTION'
		}
		.tip {
			icon = '💡'
			border_color_fn = cli.magenta
			badge_text = 'TIP'
		}
		.note {
			icon = '📝'
			border_color_fn = cli.blue
			badge_text = 'NOTE'
		}
	}
	
	header := '${icon}  ${badge_text}: ${title}'
	lines := msg.split('\n')
	mut max_len := header.len + 2
	for l in lines {
		if l.len > max_len {
			max_len = l.len
		}
	}
	max_len = int_max(max_len, 44)
	
	println(border_color_fn('┌' + '─'.repeat(max_len + 4) + '┐'))
	println(border_color_fn('│ ') + cli.bold(header) + ' '.repeat(int_max(0, max_len - header.len + 2)) + border_color_fn(' │'))
	println(border_color_fn('├' + '─'.repeat(max_len + 4) + '┤'))
	for l in lines {
		pad := ' '.repeat(int_max(0, max_len - l.len + 2))
		println(border_color_fn('│ ') + l + pad + border_color_fn(' │'))
	}
	println(border_color_fn('└' + '─'.repeat(max_len + 4) + '┘'))
	return cli
}

// task_item renders a structured checklist item with icon, title, and duration/status.
pub fn (cli &SimpleCli) task_item(title string, status TaskStatus, duration_ms i64) &SimpleCli {
	if cli.silent_mode {
		return cli
	}
	dur_str := if duration_ms > 0 { cli.dim(' (${duration_ms} ms)') } else { '' }
	match status {
		.done {
			println('  ${cli.green('✓')} ${title}${dur_str}')
		}
		.running {
			println('  ${cli.cyan('⏳')} ${title}...${dur_str}')
		}
		.pending {
			println('  ${cli.dim('○')} ${title}')
		}
		.failed {
			println('  ${cli.red('✖')} ${title} ${cli.red('[FAILED]')}${dur_str}')
		}
		.skipped {
			println('  ${cli.yellow('↷')} ${title} ${cli.dim('[SKIPPED]')}')
		}
	}
	return cli
}

// table_to_csv converts table headers and rows into a standard CSV string.
pub fn (cli &SimpleCli) table_to_csv(headers []string, rows [][]string) string {
	mut b := strings.new_builder(512)
	if headers.len > 0 {
		b.write_string(headers.map(escape_csv_cell).join(',') + '\n')
	}
	for r in rows {
		b.write_string(r.map(escape_csv_cell).join(',') + '\n')
	}
	return b.str()
}

fn escape_csv_cell(cell string) string {
	if cell.contains(',') || cell.contains('"') || cell.contains('\n') {
		return '"' + cell.replace('"', '""') + '"'
	}
	return cell
}

// table_to_markdown converts table headers and rows into a formatted Markdown table.
pub fn (cli &SimpleCli) table_to_markdown(headers []string, rows [][]string) string {
	if headers.len == 0 && rows.len == 0 {
		return ''
	}
	mut b := strings.new_builder(512)
	col_count := if headers.len > 0 { headers.len } else { rows[0].len }
	
	if headers.len > 0 {
		b.write_string('| ' + headers.join(' | ') + ' |\n')
		mut sep := []string{}
		for _ in 0 .. col_count {
			sep << ':---'
		}
		b.write_string('| ' + sep.join(' | ') + ' |\n')
	}
	for r in rows {
		mut line := []string{}
		for i in 0 .. col_count {
			line << if i < r.len { r[i] } else { '' }
		}
		b.write_string('| ' + line.join(' | ') + ' |\n')
	}
	return b.str()
}

// table_to_json converts table headers and rows into a JSON array of objects.
pub fn (cli &SimpleCli) table_to_json(headers []string, rows [][]string) string {
	if headers.len == 0 || rows.len == 0 {
		return '[]'
	}
	mut list := []map[string]string{}
	for r in rows {
		mut obj := map[string]string{}
		for i, h in headers {
			obj[h] = if i < r.len { r[i] } else { '' }
		}
		list << obj
	}
	return json2.encode[[]map[string]string](list)
}

// json_highlight adds syntax color highlighting to a JSON string for terminal display.
pub fn (cli &SimpleCli) json_highlight(json_str string) string {
	if cli.no_color {
		return json_str
	}
	mut res := strings.new_builder(json_str.len * 2)
	mut i := 0
	
	for i < json_str.len {
		ch := json_str[i]
		if ch == `"` {
			mut j := i + 1
			for j < json_str.len && json_str[j] != `"` {
				if json_str[j] == `\\` {
					j++
				}
				j++
			}
			str_val := if j < json_str.len { json_str[i .. j + 1] } else { json_str[i..] }
			mut k := j + 1
			for k < json_str.len && (json_str[k] == ` ` || json_str[k] == `\t` || json_str[k] == `\n` || json_str[k] == `\r`) {
				k++
			}
			if k < json_str.len && json_str[k] == `:` {
				res.write_string(cli.cyan(str_val))
			} else {
				res.write_string(cli.green(str_val))
			}
			i = j + 1
			continue
		} else if ch == `{` || ch == `}` || ch == `[` || ch == `]` {
			res.write_string(cli.dim(ch.ascii_str()))
		} else if ch == `:` || ch == `,` {
			res.write_string(cli.dim(ch.ascii_str()))
		} else if (ch >= `0` && ch <= `9`) || ch == `-` {
			mut j := i
			for j < json_str.len && ((json_str[j] >= `0` && json_str[j] <= `9`) || json_str[j] == `.` || json_str[j] == `-` || json_str[j] == `e` || json_str[j] == `E`) {
				j++
			}
			num_val := json_str[i..j]
			res.write_string(cli.yellow(num_val))
			i = j
			continue
		} else if json_str[i..].starts_with('true') {
			res.write_string(cli.magenta('true'))
			i += 4
			continue
		} else if json_str[i..].starts_with('false') {
			res.write_string(cli.magenta('false'))
			i += 5
			continue
		} else if json_str[i..].starts_with('null') {
			res.write_string(cli.dim('null'))
			i += 4
			continue
		} else {
			res.write_string(ch.ascii_str())
		}
		i++
	}
	return res.str()
}

// render_markdown parses basic Markdown (headings, lists, bold, blockquotes) and outputs styled console text.
pub fn (cli &SimpleCli) render_markdown(md_text string) &SimpleCli {
	if cli.silent_mode {
		return cli
	}
	lines := md_text.split('\n')
	for line in lines {
		trimmed := line.trim_space()
		if trimmed.starts_with('# ') {
			println('\n${cli.bold(cli.cyan(trimmed[2..]))}')
			cli.divider('═', int_max(40, trimmed.len + 10))
		} else if trimmed.starts_with('## ') {
			println('\n${cli.bold(trimmed[3..])}')
			cli.divider('─', int_max(30, trimmed.len + 6))
		} else if trimmed.starts_with('### ') {
			println('\n${cli.cyan(trimmed[4..])}')
		} else if trimmed.starts_with('* ') || trimmed.starts_with('- ') {
			println('  ${cli.cyan('•')} ${trimmed[2..]}')
		} else if trimmed.starts_with('> ') {
			println('  ${cli.dim('│')} ${cli.dim(trimmed[2..])}')
		} else {
			println(line)
		}
	}
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

// form presents an interactive multi-field form/wizard and returns collected responses.
pub fn (cli &SimpleCli) form(title string, fields []FormField) map[string]string {
	mut results := map[string]string{}
	if cli.silent_mode || fields.len == 0 {
		return results
	}
	println(cli.cyan('\n┌─ ' + cli.bold(title) + ' ' + '─'.repeat(int_max(0, 50 - title.len)) + '┐'))
	for field in fields {
		req_hint := if field.required { cli.red('*') } else { '' }
		def_hint := if field.default_val.len > 0 { ' ' + cli.dim('(' + field.default_val + ')') } else { '' }
		
		for {
			print('  ${cli.cyan('?')} ${cli.bold(field.label)}${req_hint}${def_hint}: ')
			os.flush()
			
			mut val := os.get_raw_line().trim_space()
			if val.len == 0 && field.default_val.len > 0 {
				val = field.default_val
			}
			
			if field.required && val.len == 0 {
				println('    ${cli.red('This field is required.')}')
				continue
			}
			
			results[field.key] = val
			break
		}
	}
	println(cli.cyan('└' + '─'.repeat(54) + '┘\n'))
	return results
}

// fuzzy_select filters a list of options using query substring and similarity matching.
pub fn (cli &SimpleCli) fuzzy_select(question string, options []string) string {
	if options.len == 0 {
		return ''
	}
	println('${cli.cyan('?')} ${cli.bold(question)} ${cli.dim('(type search query or hit Enter to list all)')}')
	print('  ${cli.dim('Search: ')}')
	os.flush()
	query := os.get_raw_line().trim_space().to_lower()
	
	if query.len == 0 {
		return cli.select(question, options)
	}
	
	// Filter matching options
	mut matches := []string{}
	for opt in options {
		if opt.to_lower().contains(query) {
			matches << opt
		}
	}
	if matches.len == 0 {
		// Fallback: search by fuzzy similarity
		for opt in options {
			if cli.similarity_ratio(query, opt.to_lower()) > 0.35 {
				matches << opt
			}
		}
	}
	if matches.len == 0 {
		println('  ${cli.yellow('No matching options found for "${query}", showing all options:')}')
		return cli.select(question, options)
	}
	if matches.len == 1 {
		println('  ${cli.green('✓ Selected match:')} ${cli.bold(matches[0])}')
		return matches[0]
	}
	return cli.select('Matching options:', matches)
}

// prompt_path prompts the user for a filesystem path and validates based on PathMode.
pub fn (cli &SimpleCli) prompt_path(question string, default_path string, mode PathMode) string {
	for {
		raw_path := cli.prompt(question, default_path)
		resolved := resolve_user_path(raw_path)
		
		match mode {
			.any {
				return resolved
			}
			.must_exist {
				if os.exists(resolved) {
					return resolved
				}
				println('  ${cli.red('Path does not exist: ' + resolved)}')
			}
			.file {
				if os.exists(resolved) && !os.is_dir(resolved) {
					return resolved
				}
				println('  ${cli.red('Path must be an existing file: ' + resolved)}')
			}
			.directory {
				if os.exists(resolved) && os.is_dir(resolved) {
					return resolved
				}
				println('  ${cli.red('Path must be an existing directory: ' + resolved)}')
			}
		}
	}
	return default_path
}

// new_pipeline initializes a new multi-step task pipeline.
pub fn (cli &SimpleCli) new_pipeline(title string) &Pipeline {
	return &Pipeline{
		title: title
		cli: cli
	}
}

// add_step registers a task stage in the pipeline.
pub fn (mut p Pipeline) add_step(name string, step_fn fn () bool) &Pipeline {
	p.steps << PipelineStep{
		name: name
		step_fn: step_fn
	}
	return p
}

// run executes all pipeline steps sequentially, displaying progress and returning true if all succeeded.
pub fn (mut p Pipeline) run() bool {
	if p.cli.silent_mode {
		for s in p.steps {
			if !s.step_fn() {
				return false
			}
		}
		return true
	}
	
	p.cli.banner(p.title, '${p.steps.len} Pipeline Steps')
	mut all_ok := true
	start_time := time.now()
	
	for i, step in p.steps {
		p.cli.print('  ${p.cli.cyan('⏳')} [${i + 1}/${p.steps.len}] ${step.name}...')
		os.flush()
		step_start := time.now()
		ok := step.step_fn()
		step_dur := time.since(step_start).milliseconds()
		
		if ok {
			print('\r  ${p.cli.green('✓')} [${i + 1}/${p.steps.len}] ${step.name} ${p.cli.dim('(' + step_dur.str() + ' ms)')}\n')
		} else {
			print('\r  ${p.cli.red('✖')} [${i + 1}/${p.steps.len}] ${step.name} ${p.cli.red('[FAILED]')} ${p.cli.dim('(' + step_dur.str() + ' ms)')}\n')
			all_ok = false
			break
		}
	}
	
	total_dur := time.since(start_time).milliseconds()
	p.cli.divider('─', 60)
	if all_ok {
		p.cli.println(p.cli.green('✨ Pipeline completed successfully in ${total_dur} ms'))
	} else {
		p.cli.println(p.cli.red('✖ Pipeline aborted due to step failure in ${total_dur} ms'))
	}
	return all_ok
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

// =============================================================================
// 9. Standalone Package-Level Functions for RAD Components
// =============================================================================

// sparkline converts a slice of floating point numbers into a compact Unicode sparkline string.
pub fn sparkline(values []f64) string {
	cli := new('SimpleCli')
	return cli.sparkline(values)
}

// bar_chart renders a stylish horizontal ASCII/Unicode bar chart.
pub fn bar_chart(title string, data map[string]f64, max_width int) {
	cli := new('SimpleCli')
	cli.bar_chart(title, data, max_width)
}

// gauge displays a single-metric meter gauge with threshold status indicator.
pub fn gauge(title string, value f64, max f64, unit string) {
	cli := new('SimpleCli')
	cli.gauge(title, value, max, unit)
}

// tree renders a hierarchical tree structure to console.
pub fn tree(root TreeNode) {
	cli := new('SimpleCli')
	cli.tree(root)
}

// diff displays a colorized line-by-line unified diff between two text strings.
pub fn diff(old_text string, new_text string) {
	cli := new('SimpleCli')
	cli.diff(old_text, new_text)
}

// badge formats an ANSI styled badge tag (e.g. `[PROD: ACTIVE]`).
pub fn badge(prefix string, label string, level LogLevel) string {
	cli := new('SimpleCli')
	return cli.badge(prefix, label, level)
}

// alert displays a framed callout box with icon and style matching AlertKind.
pub fn alert(kind AlertKind, title string, msg string) {
	cli := new('SimpleCli')
	cli.alert(kind, title, msg)
}

// task_item renders a structured checklist item with icon, title, and duration/status.
pub fn task_item(title string, status TaskStatus, duration_ms i64) {
	cli := new('SimpleCli')
	cli.task_item(title, status, duration_ms)
}

// table_to_csv converts table headers and rows into a standard CSV string.
pub fn table_to_csv(headers []string, rows [][]string) string {
	cli := new('SimpleCli')
	return cli.table_to_csv(headers, rows)
}

// table_to_markdown converts table headers and rows into a formatted Markdown table.
pub fn table_to_markdown(headers []string, rows [][]string) string {
	cli := new('SimpleCli')
	return cli.table_to_markdown(headers, rows)
}

// table_to_json converts table headers and rows into a JSON array of objects.
pub fn table_to_json(headers []string, rows [][]string) string {
	cli := new('SimpleCli')
	return cli.table_to_json(headers, rows)
}

// json_highlight adds syntax color highlighting to a JSON string for terminal display.
pub fn json_highlight(json_str string) string {
	cli := new('SimpleCli')
	return cli.json_highlight(json_str)
}

// render_markdown parses basic Markdown (headings, lists, bold, blockquotes) and outputs styled console text.
pub fn render_markdown(md_text string) {
	cli := new('SimpleCli')
	cli.render_markdown(md_text)
}


module cliutils

import clipboard
import os
import strings
import time

// ============================================================================
// ANSI Color & Text Style Formatting
// ============================================================================

pub fn bold(s string) string {
	return '\x1b[1m${s}\x1b[0m'
}

pub fn dim(s string) string {
	return '\x1b[2m${s}\x1b[0m'
}

pub fn italic(s string) string {
	return '\x1b[3m${s}\x1b[0m'
}

pub fn underline(s string) string {
	return '\x1b[4m${s}\x1b[0m'
}

pub fn red(s string) string {
	return '\x1b[31m${s}\x1b[0m'
}

pub fn green(s string) string {
	return '\x1b[32m${s}\x1b[0m'
}

pub fn yellow(s string) string {
	return '\x1b[33m${s}\x1b[0m'
}

pub fn blue(s string) string {
	return '\x1b[34m${s}\x1b[0m'
}

pub fn magenta(s string) string {
	return '\x1b[35m${s}\x1b[0m'
}

pub fn cyan(s string) string {
	return '\x1b[36m${s}\x1b[0m'
}

pub fn gray(s string) string {
	return '\x1b[90m${s}\x1b[0m'
}

// strip_ansi removes all ANSI escape codes from a string.
// Handles CSI sequences (colors, cursor movement, erase: ESC [ ... final byte 0x40-0x7E),
// OSC sequences such as hyperlinks (ESC ] ... BEL or ESC \) and two-byte escapes.
pub fn strip_ansi(s string) string {
	mut sb := strings.new_builder(s.len)
	mut i := 0
	for i < s.len {
		if s[i] != 0x1b || i + 1 >= s.len {
			sb.write_u8(s[i])
			i++
			continue
		}
		next := s[i + 1]
		if next == `[` {
			mut j := i + 2
			for j < s.len && !(s[j] >= 0x40 && s[j] <= 0x7e) {
				j++
			}
			i = j + 1
		} else if next == `]` {
			mut j := i + 2
			for j < s.len {
				if s[j] == 0x07 {
					j++
					break
				}
				if s[j] == 0x1b && j + 1 < s.len && s[j + 1] == `\\` {
					j += 2
					break
				}
				j++
			}
			i = j
		} else {
			i += 2 // two-byte escape such as ESC 7 / ESC 8
		}
	}
	return sb.str()
}

// ============================================================================
// Prompts & Interactive Input
// ============================================================================

// prompt displays a prompt message and reads a line of user input from stdin.
pub fn prompt(message string) string {
	print(message + ' ')
	os.flush()
	return os.get_line().trim_space()
}

// prompt_confirm asks a yes/no question, returning default_val if Enter is pressed without input.
pub fn prompt_confirm(message string, default_val bool) bool {
	hint := if default_val { '[Y/n]' } else { '[y/N]' }
	print('${message} ${hint}: ')
	os.flush()
	input := os.get_line().trim_space().to_lower()
	if input.len == 0 {
		return default_val
	}
	return input in ['y', 'yes', 'true', '1']
}

// prompt_select displays numbered options and returns the chosen 0-indexed option, or none.
pub fn prompt_select(message string, options []string) ?int {
	if options.len == 0 {
		return none
	}
	println(message)
	for i, opt in options {
		println('  [${i + 1}] ${opt}')
	}
	print('Select (1-${options.len}): ')
	os.flush()
	input := os.get_line().trim_space()
	num := input.int()
	if num >= 1 && num <= options.len {
		return num - 1
	}
	return none
}

// prompt_multiselect displays checkbox options, allowing comma- or space-separated selection (e.g. "1,3"), returning selected strings.
pub fn prompt_multiselect(message string, options []string, defaults []int) []string {
	if options.len == 0 {
		return []string{}
	}
	println(message)
	for i, opt in options {
		marker := if i in defaults { '[x]' } else { '[ ]' }
		println('  ${marker} ${i + 1}. ${opt}')
	}
	hint := if defaults.len > 0 {
		' [default: ${defaults.map((it + 1).str()).join(',')}]'
	} else {
		''
	}
	print('Select numbers separated by comma or space (e.g. 1,3)${hint}: ')
	os.flush()
	input := os.get_line().trim_space()
	if input.len == 0 {
		mut res := []string{}
		for d in defaults {
			if d >= 0 && d < options.len {
				res << options[d]
			}
		}
		return res
	}

	mut selected_indices := []int{}
	clean := input.replace(',', ' ')
	for part in clean.split(' ') {
		p := part.trim_space()
		if p.len == 0 {
			continue
		}
		idx := p.int() - 1
		if idx >= 0 && idx < options.len && idx !in selected_indices {
			selected_indices << idx
		}
	}

	mut selected_options := []string{}
	for idx in selected_indices {
		selected_options << options[idx]
	}
	return selected_options
}

// ============================================================================
// Progress Bar
// ============================================================================

// ProgressBar provides an ASCII progress bar for terminal applications.
pub struct ProgressBar {
pub:
	total int
	width int = 30
pub mut:
	current int
}

// new_progress_bar initializes a new ProgressBar with total steps and optional bar width.
pub fn new_progress_bar(total int, width int) ProgressBar {
	w := if width > 0 { width } else { 30 }
	return ProgressBar{
		total:   total
		width:   w
		current: 0
	}
}

// update advances or sets the current progress value.
pub fn (mut pb ProgressBar) update(current int) {
	pb.current = if current > pb.total {
		pb.total
	} else if current < 0 {
		0
	} else {
		current
	}
}

// render generates the string representation of the progress bar.
pub fn (pb ProgressBar) render() string {
	if pb.total <= 0 {
		return '[${strings.repeat(`-`, pb.width)}] 100%'
	}
	ratio := f64(pb.current) / f64(pb.total)
	percent := int(ratio * 100.0)
	filled_width := int(ratio * f64(pb.width))

	mut bar := strings.new_builder(pb.width + 30)
	bar.write_u8(`[`)
	for i in 0 .. pb.width {
		if i < filled_width {
			bar.write_u8(`=`)
		} else if i == filled_width && filled_width > 0 && filled_width < pb.width {
			bar.write_u8(`>`)
		} else {
			bar.write_u8(` `)
		}
	}
	bar.write_string('] ')
	bar.write_string('${percent:3}% (${pb.current}/${pb.total})')
	return bar.str()
}

// ============================================================================
// CLI Flags & Argument Parsing
// ============================================================================

pub struct FlagDef {
pub:
	name        string
	short       string
	default_val string
	description string
	kind        string // "string", "int", "bool", "float"
}

// FlagParser handles CLI flags with short/long aliases, types, and auto-generated help.
pub struct FlagParser {
pub mut:
	app_name    string
	description string
	flags       []FlagDef
	parsed      map[string]string
	positional  []string
}

// new_flag_parser creates a new CLI FlagParser instance.
pub fn new_flag_parser(app_name string, description string) FlagParser {
	return FlagParser{
		app_name:    app_name
		description: description
		flags:       []FlagDef{}
		parsed:      map[string]string{}
		positional:  []string{}
	}
}

pub fn (mut fp FlagParser) add_flag_string(name string, short string, default_val string, desc string) {
	fp.flags << FlagDef{
		name:        name
		short:       short
		default_val: default_val
		description: desc
		kind:        'string'
	}
	fp.parsed[name] = default_val
}

pub fn (mut fp FlagParser) add_flag_int(name string, short string, default_val int, desc string) {
	fp.flags << FlagDef{
		name:        name
		short:       short
		default_val: '${default_val}'
		description: desc
		kind:        'int'
	}
	fp.parsed[name] = '${default_val}'
}

pub fn (mut fp FlagParser) add_flag_bool(name string, short string, default_val bool, desc string) {
	fp.flags << FlagDef{
		name:        name
		short:       short
		default_val: if default_val { 'true' } else { 'false' }
		description: desc
		kind:        'bool'
	}
	fp.parsed[name] = if default_val { 'true' } else { 'false' }
}

pub fn (mut fp FlagParser) add_flag_float(name string, short string, default_val f64, desc string) {
	fp.flags << FlagDef{
		name:        name
		short:       short
		default_val: '${default_val}'
		description: desc
		kind:        'float'
	}
	fp.parsed[name] = '${default_val}'
}

fn (fp FlagParser) find_long(name string) ?FlagDef {
	for flag in fp.flags {
		if flag.name == name {
			return flag
		}
	}
	return none
}

fn (fp FlagParser) find_short(short string) ?FlagDef {
	for flag in fp.flags {
		if flag.short != '' && flag.short == short {
			return flag
		}
	}
	return none
}

fn check_flag_value(flag FlagDef, val string) ! {
	ok := match flag.kind {
		'int' {
			val.len > 0 && val.trim_left('+-').len > 0
				&& val.trim_left('+-').bytes().all(it.is_digit())
		}
		'float' {
			val.len > 0 && (val.f64() != 0.0 || val.trim_left('+-').trim('0.') == '')
		}
		'bool' {
			val.to_lower() in ['true', 'false', '1', '0', 'yes', 'no', 'on', 'off']
		}
		else {
			true
		}
	}

	if !ok {
		return error('invalid value for --${flag.name}: "${val}" (expected ${flag.kind})')
	}
}

fn is_negative_number(arg string) bool {
	return arg.len > 1 && arg[0] == `-` && (arg[1].is_digit() || arg[1] == `.`)
}

// parse parses an argument array, updating parsed flag values and collecting positional args.
// Supports `--name value`, `--name=value`, `-n value`, `-nvalue`, `-n=value`, combined
// boolean shorts (`-abc`), negative numbers as positionals, and `--` to end option parsing.
// Values are validated against the flag's type; a missing value is an error.
pub fn (mut fp FlagParser) parse(args []string) ! {
	mut i := 0
	for i < args.len {
		arg := args[i]
		if arg == '--help' || arg == '-h' {
			fp.print_help()
			return
		}
		if arg == '--' {
			fp.positional << args[i + 1..]
			return
		}
		if arg.starts_with('--') {
			raw := arg[2..]
			eq_idx := raw.index('=') or { -1 }
			name := if eq_idx >= 0 { raw[..eq_idx] } else { raw }
			flag := fp.find_long(name) or { return error('unknown flag: --${name}') }
			mut val := ''
			if eq_idx >= 0 {
				val = raw[eq_idx + 1..]
			} else if flag.kind == 'bool' {
				val = 'true'
			} else if i + 1 < args.len {
				i++
				val = args[i]
			} else {
				return error('flag --${name} requires a value')
			}
			check_flag_value(flag, val)!
			fp.parsed[name] = val
		} else if arg.starts_with('-') && arg.len >= 2 {
			short := arg[1..2]
			flag := fp.find_short(short) or {
				if is_negative_number(arg) {
					fp.positional << arg
					i++
					continue
				}
				return error('unknown flag: -${short}')
			}
			rest := arg[2..]
			if flag.kind == 'bool' {
				if rest.starts_with('=') {
					check_flag_value(flag, rest[1..])!
					fp.parsed[flag.name] = rest[1..]
				} else {
					fp.parsed[flag.name] = 'true'
					// combined boolean shorts: -abc == -a -b -c
					for k in 0 .. rest.len {
						f2 := fp.find_short(rest[k..k + 1]) or {
							return error('unknown flag: -${rest[k..k + 1]} (in ${arg})')
						}
						if f2.kind != 'bool' {
							return error('flag -${f2.short} needs a value and cannot be combined in ${arg}')
						}
						fp.parsed[f2.name] = 'true'
					}
				}
			} else {
				mut val := ''
				if rest.len > 0 {
					val = rest.trim_string_left('=')
				} else if i + 1 < args.len {
					i++
					val = args[i]
				} else {
					return error('flag -${short} requires a value')
				}
				check_flag_value(flag, val)!
				fp.parsed[flag.name] = val
			}
		} else {
			fp.positional << arg
		}
		i++
	}
}

pub fn (fp FlagParser) get_string(name string) string {
	return fp.parsed[name] or { '' }
}

pub fn (fp FlagParser) get_int(name string) int {
	return (fp.parsed[name] or { '0' }).int()
}

pub fn (fp FlagParser) get_bool(name string) bool {
	val := (fp.parsed[name] or { 'false' }).to_lower()
	return val in ['true', '1', 'yes', 'on']
}

pub fn (fp FlagParser) get_float(name string) f64 {
	return (fp.parsed[name] or { '0.0' }).f64()
}

pub fn (fp FlagParser) get_positional() []string {
	return fp.positional.clone()
}

// format_help generates formatted help text.
pub fn (fp FlagParser) format_help() string {
	mut sb := strings.new_builder(256)
	sb.write_string('${bold(fp.app_name)}\n')
	if fp.description.len > 0 {
		sb.write_string('${fp.description}\n\n')
	}
	sb.write_string('Usage:\n  ${fp.app_name} [flags] [arguments]\n\nFlags:\n')
	for flag in fp.flags {
		short_str := if flag.short.len > 0 { '-${flag.short}, ' } else { '    ' }
		padded_name := flag.name + strings.repeat(` `, if flag.name.len < 15 {
			15 - flag.name.len
		} else {
			1
		})
		sb.write_string('  ${short_str}--${padded_name} ${flag.description} (default: ${flag.default_val})\n')
	}
	sb.write_string('  -h, --help            Show this help message\n')
	return sb.str()
}

pub fn (fp FlagParser) print_help() {
	println(fp.format_help())
}

// ============================================================================
// Multi-Step Task Pipeline Runner
// ============================================================================

pub struct PipelineStep {
pub:
	name   string
	action fn () bool = unsafe { nil }
}

pub struct Pipeline {
pub:
	name string
pub mut:
	steps []PipelineStep
}

pub fn new_pipeline(name string) Pipeline {
	return Pipeline{
		name:  name
		steps: []PipelineStep{}
	}
}

pub fn (mut p Pipeline) add_step(name string, action fn () bool) {
	p.steps << PipelineStep{
		name:   name
		action: action
	}
}

pub fn (mut p Pipeline) run() bool {
	println(bold(cyan('==> Running pipeline: ${p.name} (${p.steps.len} steps)')))
	for i, step in p.steps {
		print('  [${i + 1}/${p.steps.len}] ${step.name}... ')
		os.flush()
		start := time.now()
		ok := step.action()
		dur := (time.now() - start).milliseconds()
		if ok {
			println(green('✔') + dim(' (${dur} ms)'))
		} else {
			println(red('✖ FAILED') + dim(' (${dur} ms)'))
			return false
		}
	}
	println(bold(green('✔ Pipeline ${p.name} completed successfully!')))
	return true
}

// ============================================================================
// Structured Multi-Level Logger
// ============================================================================

pub enum LogLevel {
	trace
	debug
	info
	warn
	error_level
	silent
}

pub struct Logger {
pub mut:
	level    LogLevel
	log_file string
	no_color bool
}

pub fn new_logger(level LogLevel, log_file string) Logger {
	return Logger{
		level:    level
		log_file: log_file
		no_color: false
	}
}

fn (mut l Logger) log(level LogLevel, tag string, colored_tag string, msg string) {
	if int(level) < int(l.level) || l.level == .silent {
		return
	}
	ts := time.now().format_ss()
	tag_to_use := if l.no_color { tag } else { colored_tag }
	formatted := '[${ts}] ${tag_to_use} ${msg}'
	println(formatted)

	if l.log_file.len > 0 {
		plain := strip_ansi(formatted) + '\n'
		mut f := os.open_append(l.log_file) or { return }
		f.write_string(plain) or {}
		f.close()
	}
}

pub fn (mut l Logger) trace(msg string) {
	l.log(.trace, '[TRACE]', gray('[TRACE]'), msg)
}

pub fn (mut l Logger) debug(msg string) {
	l.log(.debug, '[DEBUG]', cyan('[DEBUG]'), msg)
}

pub fn (mut l Logger) info(msg string) {
	l.log(.info, '[INFO]', blue('[INFO]'), msg)
}

pub fn (mut l Logger) success(msg string) {
	l.log(.info, '[SUCCESS]', green('[SUCCESS]'), msg)
}

pub fn (mut l Logger) warn(msg string) {
	l.log(.warn, '[WARN]', yellow('[WARN]'), msg)
}

pub fn (mut l Logger) error(msg string) {
	l.log(.error_level, '[ERROR]', red('[ERROR]'), msg)
}

// ============================================================================
// RAD Console Visualizations (Sparklines, Bar Charts, Gauges, Trees, Diffs)
// ============================================================================

// sparkline renders an inline Unicode sparkline ( ▂▃▄▅▆▇█) from numeric values.
pub fn sparkline(values []f64) string {
	if values.len == 0 {
		return ''
	}
	glyphs := [` `, `▂`, `▃`, `▄`, `▅`, `▆`, `▇`, `█`]
	mut min_val := values[0]
	mut max_val := values[0]
	for v in values[1..] {
		if v < min_val {
			min_val = v
		}
		if v > max_val {
			max_val = v
		}
	}
	delta := max_val - min_val
	mut sb := strings.new_builder(values.len)
	for v in values {
		idx := if delta == 0.0 { 0 } else { int((v - min_val) / delta * 7.0) }
		clamped := if idx < 0 {
			0
		} else if idx > 7 {
			7
		} else {
			idx
		}
		sb.write_rune(glyphs[clamped])
	}
	return sb.str()
}

// bar_chart prints a horizontal ASCII/Unicode bar chart.
pub fn bar_chart(title string, items map[string]f64, max_width int) string {
	w := if max_width > 0 { max_width } else { 30 }
	mut max_val := 0.0
	mut max_label_len := 0
	for k, v in items {
		if v > max_val {
			max_val = v
		}
		if k.len > max_label_len {
			max_label_len = k.len
		}
	}
	mut sb := strings.new_builder(items.len * 50)
	if title.len > 0 {
		sb.write_string('${bold(title)}\n')
	}
	for k, v in items {
		ratio := if max_val > 0.0 { v / max_val } else { 0.0 }
		bar_len := int(ratio * f64(w))
		bar := '█'.repeat(bar_len)
		padded_k := k + strings.repeat(` `, if max_label_len > k.len {
			max_label_len - k.len
		} else {
			0
		})
		sb.write_string('  ${padded_k} | ${cyan(bar)} ${v:.1f}\n')
	}
	return sb.str()
}

// gauge generates a single-metric meter gauge with percentage and status.
pub fn gauge(label string, current f64, max f64, unit string) string {
	ratio := if max > 0.0 { current / max } else { 0.0 }
	pct := ratio * 100.0
	width := 20
	filled := int(ratio * f64(width))
	bar := '█'.repeat(if filled > width { width } else { filled })
	empty := '░'.repeat(if width > filled { width - filled } else { 0 })
	status := if pct > 90.0 {
		red('[CRITICAL]')
	} else if pct > 75.0 {
		yellow('[WARN]')
	} else {
		green('[OK]')
	}
	return '${label}: [${cyan(bar)}${empty}] ${current:.1f}/${max:.1f} ${unit} (${pct:.1f}%) ${status}'
}

// TreeNode represents a node in a hierarchical tree.
pub struct TreeNode {
pub mut:
	label    string
	children []TreeNode
}

pub fn new_tree_node(label string) TreeNode {
	return TreeNode{
		label:    label
		children: []TreeNode{}
	}
}

pub fn (mut t TreeNode) add_child(label string) TreeNode {
	child := new_tree_node(label)
	t.children << child
	return child
}

// render_tree renders a tree structure with branch glyphs (├──, └──, │   ).
pub fn render_tree(root &TreeNode) string {
	mut sb := strings.new_builder(128)
	sb.write_string('${bold(root.label)}\n')
	render_tree_recursive(root, '', mut sb)
	return sb.str()
}

fn render_tree_recursive(node &TreeNode, prefix string, mut sb strings.Builder) {
	for i, child in node.children {
		is_last := i == node.children.len - 1
		branch := if is_last { '└── ' } else { '├── ' }
		sb.write_string('${prefix}${branch}${child.label}\n')
		child_prefix := prefix + if is_last { '    ' } else { '│   ' }
		render_tree_recursive(&child, child_prefix, mut sb)
	}
}

// diff_text generates a colorized line-by-line unified diff.
pub fn diff_text(old_text string, new_text string) string {
	old_lines := old_text.split_into_lines()
	new_lines := new_text.split_into_lines()
	mut sb := strings.new_builder(old_text.len + new_text.len)
	max_lines := if old_lines.len > new_lines.len { old_lines.len } else { new_lines.len }
	for i in 0 .. max_lines {
		if i < old_lines.len && i < new_lines.len {
			if old_lines[i] == new_lines[i] {
				sb.write_string('  ${old_lines[i]}\n')
			} else {
				sb.write_string(red('- ${old_lines[i]}') + '\n')
				sb.write_string(green('+ ${new_lines[i]}') + '\n')
			}
		} else if i < old_lines.len {
			sb.write_string(red('- ${old_lines[i]}') + '\n')
		} else if i < new_lines.len {
			sb.write_string(green('+ ${new_lines[i]}') + '\n')
		}
	}
	return sb.str()
}

// diff displays a colorized line-by-line diff in the console.
pub fn diff(old_text string, new_text string) {
	print(diff_text(old_text, new_text))
}

// ============================================================================
// Table Data Converters & JSON Syntax Highlighting
// ============================================================================

// table_to_markdown formats a table as GitHub Flavored Markdown.
pub fn table_to_markdown(headers []string, rows [][]string) string {
	if headers.len == 0 {
		return ''
	}
	mut sb := strings.new_builder(128)
	sb.write_string('| ' + headers.join(' | ') + ' |\n')
	mut sep := []string{cap: headers.len}
	for h in headers {
		sep << strings.repeat(`-`, if h.len > 3 { h.len } else { 3 })
	}
	sb.write_string('| ' + sep.join(' | ') + ' |\n')
	for row in rows {
		sb.write_string('| ' + row.join(' | ') + ' |\n')
	}
	return sb.str()
}

// table_to_csv formats table headers and rows as CSV.
pub fn table_to_csv(headers []string, rows [][]string) string {
	mut lines := []string{cap: rows.len + 1}
	lines << headers.join(',')
	for row in rows {
		lines << row.join(',')
	}
	return lines.join('\n') + '\n'
}

// table_to_json serializes a table into a JSON array of key-value objects.
pub fn table_to_json(headers []string, rows [][]string) string {
	mut objs := []string{cap: rows.len}
	for row in rows {
		mut pairs := []string{cap: headers.len}
		for i, h in headers {
			val := if i < row.len { row[i] } else { '' }
			pairs << '"${h}": "${val}"'
		}
		objs << '  {\n    ' + pairs.join(',\n    ') + '\n  }'
	}
	return '[\n' + objs.join(',\n') + '\n]'
}

// json_highlight adds syntax coloring to a JSON string.
pub fn json_highlight(json_str string) string {
	mut sb := strings.new_builder(json_str.len * 2)
	lines := json_str.split_into_lines()
	for line in lines {
		trimmed := line.trim_space()
		if trimmed.starts_with('"') && trimmed.contains(':') {
			col_idx := line.index(':') or { -1 }
			if col_idx > 0 {
				key := line[..col_idx]
				val := line[col_idx + 1..]
				sb.write_string('${cyan(key)}:${yellow(val)}\n')
				continue
			}
		}
		sb.write_string('${line}\n')
	}
	return sb.str()
}

// banner renders a framed header banner.
pub fn banner(title string, subtitle string) string {
	width := 60
	border := strings.repeat(`=`, width)
	mut sb := strings.new_builder(128)
	sb.write_string('${cyan(border)}\n')
	sb.write_string('  ${bold(title)}\n')
	if subtitle.len > 0 {
		sb.write_string('  ${dim(subtitle)}\n')
	}
	sb.write_string('${cyan(border)}\n')
	return sb.str()
}

// panel renders a framed panel box with title and content.
pub fn panel(title string, content string) string {
	width := 60
	top := '┌─ ${bold(title)} ' + strings.repeat(`─`, if width > title.len + 4 {
		width - title.len - 4
	} else {
		2
	}) + '┐'
	bot := '└' + strings.repeat(`─`, width) + '┘'
	return '${top}\n│ ${content}\n${bot}'
}

// card is an alias for panel.
pub fn card(title string, content string) string {
	return panel(title, content)
}

// divider renders a horizontal divider line of specified character and width.
pub fn divider(ch rune, width int) string {
	w := if width > 0 { width } else { 60 }
	return strings.repeat(ch, w)
}

// badge renders an inverted status badge (e.g. "[ PRODUCTION ]").
pub fn badge(label string, value string, color_fn fn (string) string) string {
	return color_fn('[ ${label}: ${value} ]')
}

// is_clipboard_available returns true if the system clipboard is accessible.
pub fn is_clipboard_available() bool {
	mut cb := clipboard.new()
	defer {
		cb.destroy()
	}
	return cb.is_available()
}

// copy_to_clipboard copies a string of text to the OS clipboard.
pub fn copy_to_clipboard(text string) bool {
	mut cb := clipboard.new()
	defer {
		cb.destroy()
	}
	if !cb.is_available() {
		return false
	}
	return cb.copy(text)
}

// read_from_clipboard retrieves the current text content from the OS clipboard.
pub fn read_from_clipboard() string {
	mut cb := clipboard.new()
	defer {
		cb.destroy()
	}
	if !cb.is_available() {
		return ''
	}
	return cb.paste()
}

// ============================================================================
// Terminal Spinner & Confirmation Prompt
// ============================================================================

// Spinner displays an animated terminal loading indicator.
@[heap]
pub struct Spinner {
mut:
	frames    []string = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏']
	frame_idx int
	message   string
	active    bool
}

// new_spinner creates a new Spinner with a status message.
pub fn new_spinner(message string) &Spinner {
	return &Spinner{
		message: message
		active:  false
	}
}

// step advances the spinner by one frame and returns the formatted frame string.
pub fn (mut s Spinner) step() string {
	frame := s.frames[s.frame_idx % s.frames.len]
	s.frame_idx++
	return cyan(frame) + ' ' + s.message
}

// update changes the spinner's message text.
pub fn (mut s Spinner) update(message string) {
	s.message = message
}

// confirm prompts the user for a Yes/No question and returns true for yes, false for no.
pub fn confirm(prompt string, default_yes bool) bool {
	options := if default_yes { '[Y/n]' } else { '[y/N]' }
	print('${prompt} ${options}: ')
	os.flush()
	input := os.get_line().trim_space().to_lower()
	if input.len == 0 {
		return default_yes
	}
	return input == 'y' || input == 'yes'
}

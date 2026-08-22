module main

import simplecli

fn main() {
	mut app := simplecli.new_app('texteditor-cli', '1.0.0')
	app.set_description('Terminal Text & Code File Inspector CLI')

	app.add_flag_string('file', 'f', '', 'Path to text/code file')
	app.add_flag_int('lines', 'n', 30, 'Number of lines to preview')
	app.add_flag_bool('stats', 's', false, 'Display file statistics (lines, words, chars, bytes)')
	app.add_flag_bool('interactive', 'x', false, 'Launch interactive text file viewer')

	app.parse_cli() or { return }

	app.banner('Text Editor Studio CLI', 'v1.0.0 - Code & Text Inspector')

	if app.get_flag_bool('interactive') {
		run_interactive(mut app)
		return
	}

	file_path := app.get_flag_string('file')
	if file_path.len == 0 {
		app.warn('No file specified. Run with -f <file.txt> or -x for interactive mode.')
		app.print_help()
		return
	}

	if !app.file_exists(file_path) {
		app.error('File not found: ${file_path}')
		return
	}

	content := app.read_file(file_path)
	lines := content.split_into_lines()
	words := content.split(' ').filter(it.trim_space().len > 0)

	meta := app.get_file_metadata(file_path) or {
		app.error('Failed to get metadata: ${err}')
		return
	}

	app.print_kv({
		'File Path': meta.path,
		'File Size': '${meta.size_bytes} bytes',
		'Total Lines': '${lines.len}',
		'Word Count': '${words.len}',
		'Permissions': if meta.is_readable { 'Readable' } else { 'Restricted' },
	})

	if !app.get_flag_bool('stats') {
		max_lines := app.get_flag_int('lines')
		println('')
		app.println(app.bold('--- Preview (First ${max_lines} Lines) ---'))
		for i, line in lines {
			if i >= max_lines {
				break
			}
			line_num := (i + 1).str()
			println('${line_num:4} │ ${line}')
		}
		println('')
	}
}

fn run_interactive(mut app simplecli.SimpleCli) {
	app.panel('Text File Inspector', 'Inspect source code, configs, and text documents.')
	file_path := app.prompt('Enter file path to view', 'README.md')
	if !app.file_exists(file_path) {
		app.warn('File does not exist.')
		return
	}
	content := app.read_file(file_path)
	lines := content.split_into_lines()
	app.info('File has ${lines.len} lines.')
	for i, l in lines {
		if i >= 20 {
			break
		}
		println('${i + 1:3} │ ${l}')
	}
}

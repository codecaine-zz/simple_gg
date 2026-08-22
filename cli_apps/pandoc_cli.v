module main

import simplecli

fn main() {
	mut app := simplecli.new_app('pandoc-cli', '1.0.0')
	app.set_description('Pandoc Universal Document Converter CLI')

	app.add_flag_string('input', 'i', '', 'Input document file path (e.g. doc.md, page.html)')
	app.add_flag_string('output', 'o', '', 'Output document file path (e.g. doc.pdf, doc.docx, page.html)')
	app.add_flag_string('from', 'f', 'markdown', 'Source markup format (markdown, html, docx, rst, latex)')
	app.add_flag_string('to', 't', 'html', 'Target markup format (html, pdf, docx, epub, latex)')
	app.add_flag_bool('interactive', 'x', false, 'Launch interactive document converter')

	app.parse_cli() or { return }

	app.banner('Pandoc Document Studio CLI', 'v1.0.0 - Universal Document Converter')

	has_pandoc := app.command_exists('pandoc')
	if !has_pandoc {
		app.warn('pandoc binary not found. Install via "brew install pandoc".')
	}

	if app.get_flag_bool('interactive') {
		run_interactive(mut app, has_pandoc)
		return
	}

	input_file := app.get_flag_string('input')
	if input_file.len == 0 {
		app.warn('No input file specified. Run with -i <file.md> -o <out.html> or -x for interactive mode.')
		app.print_help()
		return
	}

	if !app.file_exists(input_file) {
		app.error('File not found: ${input_file}')
		return
	}

	mut out_file := app.get_flag_string('output')
	if out_file.len == 0 {
		out_file = 'output_converted.html'
	}

	from_fmt := app.get_flag_string('from')
	to_fmt := app.get_flag_string('to')

	app.info('Converting document from ${from_fmt} to ${to_fmt}...')
	app.reset_timer()
	out, code := app.exec_safe('pandoc', ['-f', from_fmt, '-t', to_fmt, input_file, '-o', out_file])
	if code == 0 {
		app.success('Document converted in ${app.elapsed_ms()} ms -> ${out_file}')
	} else {
		app.error('Pandoc conversion failed (code ${code}):\n${out}')
	}
}

fn run_interactive(mut app simplecli.SimpleCli, has_pandoc bool) {
	app.panel('Pandoc Document Wizard', 'Convert between Markdown, HTML, PDF, Docx, and LaTeX.')
	doc := app.prompt('Enter input document path', 'README.md')
	target_fmt := app.select('Target Output Format:', ['HTML (.html)', 'Docx (.docx)', 'PDF (.pdf)', 'EPUB (.epub)'])
	out_file := match target_fmt {
		'Docx (.docx)' { 'document.docx' }
		'PDF (.pdf)' { 'document.pdf' }
		'EPUB (.epub)' { 'document.epub' }
		else { 'document.html' }
	}

	if has_pandoc {
		app.exec_safe('pandoc', [doc, '-o', out_file])
		app.success('Converted to ${out_file}')
	} else {
		app.warn('Pandoc is not installed on this system.')
	}
}

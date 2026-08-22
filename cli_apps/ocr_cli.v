module main

import simplecli

fn main() {
	mut app := simplecli.new_app('ocr-cli', '1.0.0')
	app.set_description('Tesseract Optical Character Recognition (OCR) CLI')

	app.add_flag_string('input', 'i', '', 'Input image file path for text recognition')
	app.add_flag_string('lang', 'l', 'eng', 'OCR recognition language (e.g. eng, spa, fra, deu, chi_sim)')
	app.add_flag_string('output', 'o', '', 'Output text file path (optional)')
	app.add_flag_bool('interactive', 'x', false, 'Launch interactive OCR wizard')

	app.parse_cli() or { return }

	app.banner('Tesseract OCR Studio CLI', 'v1.0.0 - Image Text Recognition Engine')

	if !app.command_exists('tesseract') {
		app.warn('tesseract binary not found. Install via "brew install tesseract".')
	}

	if app.get_flag_bool('interactive') {
		run_interactive(mut app)
		return
	}

	input_path := app.get_flag_string('input')
	if input_path.len == 0 {
		app.warn('No image file specified. Run with -i <image.png> or -x for interactive mode.')
		app.print_help()
		return
	}

	if !app.file_exists(input_path) {
		app.error('File not found: ${input_path}')
		return
	}

	lang := app.get_flag_string('lang')
	app.info('Extracting text from "${input_path}" (language: ${lang})...')
	app.reset_timer()

	out, code := app.exec_safe('tesseract', [input_path, 'stdout', '-l', lang])
	elapsed := app.elapsed_ms()

	if code == 0 {
		app.success('OCR completed in ${elapsed} ms:')
		println('----------------------------------------')
		println(out)
		println('----------------------------------------')

		out_file := app.get_flag_string('output')
		if out_file.len > 0 {
			app.write_file(out_file, out)
			app.success('Saved recognized text to: ${out_file}')
		}
	} else {
		app.error('Tesseract OCR failed (code ${code}):\n${out}')
	}
}

fn run_interactive(mut app simplecli.SimpleCli) {
	app.panel('OCR Interactive Wizard', 'Extract printed or handwritten text from document screenshots.')
	img := app.prompt('Enter image path', 'scan.png')
	lang := app.prompt('Enter language code', 'eng')
	out, code := app.exec_safe('tesseract', [img, 'stdout', '-l', lang])
	if code == 0 {
		app.success('Recognized Text:\n${out}')
	} else {
		app.error('Failed to run OCR:\n${out}')
	}
}

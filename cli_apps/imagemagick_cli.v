module main

import simplecli

fn get_magick_cmd(app &simplecli.SimpleCli) string {
	if app.command_exists('magick') {
		return 'magick'
	}
	if app.command_exists('convert') {
		return 'convert'
	}
	return 'magick'
}

fn main() {
	mut app := simplecli.new_app('imagemagick-cli', '1.0.0')
	app.set_description('ImageMagick Image Processing, Resizing & Format Conversion CLI')

	app.add_flag_string('input', 'i', '', 'Input image file path')
	app.add_flag_string('output', 'o', '', 'Output image file path')
	app.add_flag_string('resize', 'r', '', 'Resize dimensions (e.g. 800x600, 50%, 1024x)')
	app.add_flag_int('quality', 'q', 85, 'Image compression quality (1-100)')
	app.add_flag_bool('grayscale', 'g', false, 'Convert image to grayscale')
	app.add_flag_bool('interactive', 'x', false, 'Launch interactive ImageMagick wizard')

	app.parse_cli() or { return }

	app.banner('ImageMagick Studio CLI', 'v1.0.0 - Image Optimization & Format Engine')

	magick_cmd := get_magick_cmd(app)
	if !app.command_exists(magick_cmd) {
		app.warn('ImageMagick ("magick" or "convert") not found. Install via "brew install imagemagick".')
	}

	if app.get_flag_bool('interactive') {
		run_interactive(mut app, magick_cmd)
		return
	}

	input_path := app.get_flag_string('input')
	if input_path.len == 0 {
		app.warn('No input image specified. Run with -i <image.png> or -x for interactive mode.')
		app.print_help()
		return
	}

	if !app.file_exists(input_path) {
		app.error('Input image not found: ${input_path}')
		return
	}

	mut out_path := app.get_flag_string('output')
	if out_path.len == 0 {
		out_path = 'output_processed.jpg'
	}

	mut args := [input_path]

	resize_arg := app.get_flag_string('resize')
	if resize_arg.len > 0 {
		args << ['-resize', resize_arg]
	}

	if app.get_flag_bool('grayscale') {
		args << ['-colorspace', 'Gray']
	}

	quality := app.get_flag_int('quality')
	args << ['-quality', '${quality}', out_path]

	app.info('Processing image...')
	app.reset_timer()
	out, code := app.exec_safe(magick_cmd, args)
	if code == 0 {
		app.success('Image processed in ${app.elapsed_ms()} ms -> ${out_path}')
	} else {
		app.error('ImageMagick failed (code ${code}):\n${out}')
	}
}

fn run_interactive(mut app simplecli.SimpleCli, magick_cmd string) {
	app.panel('ImageMagick Operations Wizard', 'Resize, compress, convert formats, or apply image filters.')
	input := app.prompt('Enter input image path', 'photo.png')
	choice := app.select('Select Action:', [
		'Convert to WebP (Optimized Web Format)',
		'Generate 256x256 Thumbnail',
		'Convert to Grayscale JPEG (Quality 90)',
		'Rotate 90 Degrees Clockwise',
	])

	match choice {
		'Convert to WebP (Optimized Web Format)' {
			out := 'output.webp'
			app.exec_safe(magick_cmd, [input, '-quality', '85', out])
			app.success('Converted to ${out}')
		}
		'Generate 256x256 Thumbnail' {
			out := 'thumb_256.png'
			app.exec_safe(magick_cmd, [input, '-resize', '256x256^', '-gravity', 'center', '-extent', '256x256', out])
			app.success('Created thumbnail ${out}')
		}
		'Convert to Grayscale JPEG (Quality 90)' {
			out := 'grayscale.jpg'
			app.exec_safe(magick_cmd, [input, '-colorspace', 'Gray', '-quality', '90', out])
			app.success('Saved grayscale image to ${out}')
		}
		else {
			out := 'rotated_90.png'
			app.exec_safe(magick_cmd, [input, '-rotate', '90', out])
			app.success('Rotated image saved to ${out}')
		}
	}
}

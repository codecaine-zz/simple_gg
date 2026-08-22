module main

import simplecli

fn main() {
	mut app := simplecli.new_app('exif-cli', '1.0.0')
	app.set_description('EXIF Image Metadata Inspector & Stripper CLI')

	app.add_flag_string('input', 'i', '', 'Input image file path')
	app.add_flag_bool('strip', 's', false, 'Strip all privacy/EXIF metadata from image')
	app.add_flag_bool('gps', 'g', false, 'Extract GPS location coordinates only')
	app.add_flag_bool('interactive', 'x', false, 'Launch interactive EXIF explorer')

	app.parse_cli() or { return }

	app.banner('ExifTool Studio CLI', 'v1.0.0 - Image Metadata & Privacy Auditor')

	if app.get_flag_bool('interactive') {
		run_interactive(mut app)
		return
	}

	input_path := app.get_flag_string('input')
	if input_path.len == 0 {
		app.warn('No image specified. Run with -i <image.jpg> or -x for interactive mode.')
		app.print_help()
		return
	}

	if !app.file_exists(input_path) {
		app.error('File not found: ${input_path}')
		return
	}

	if app.get_flag_bool('strip') {
		app.info('Stripping EXIF metadata for privacy...')
		out, code := app.exec('exiftool -all= -overwrite_original "${input_path}" 2>/dev/null || sips -d all "${input_path}" 2>/dev/null')
		if code == 0 {
			app.success('Successfully stripped EXIF metadata from: ${input_path}')
		} else {
			app.error('Failed to strip metadata:\n${out}')
		}
		return
	}

	if app.get_flag_bool('gps') {
		app.info('Extracting GPS coordinates...')
		out, _ := app.exec('exiftool -GPSLatitude -GPSLongitude "${input_path}" 2>/dev/null')
		println(out)
		return
	}

	// Full metadata dump
	app.info('Inspecting EXIF metadata...')
	out, _ := app.exec('exiftool "${input_path}" 2>/dev/null || mdls "${input_path}" 2>/dev/null')
	println(out)
}

fn run_interactive(mut app simplecli.SimpleCli) {
	app.panel('EXIF Studio Wizard', 'Inspect camera settings, lenses, timestamps, and GPS tags.')
	img := app.prompt('Enter image path', 'photo.jpg')
	if !app.file_exists(img) {
		app.warn('Image file does not exist.')
		return
	}
	out, _ := app.exec('exiftool "${img}" 2>/dev/null || mdls "${img}"')
	println(out)
}

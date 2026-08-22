module main

import simplecli

fn main() {
	mut app := simplecli.new_app('audiotag-cli', '1.0.0')
	app.set_description('Audio Tag Inspector & ID3 Metadata Editor CLI')

	app.add_flag_string('input', 'i', '', 'Input audio file path (MP3, FLAC, M4A, OGG)')
	app.add_flag_string('title', 't', '', 'Set song title metadata')
	app.add_flag_string('artist', 'a', '', 'Set artist name metadata')
	app.add_flag_string('album', 'l', '', 'Set album title metadata')
	app.add_flag_string('year', 'y', '', 'Set release year metadata')
	app.add_flag_bool('interactive', 'x', false, 'Launch interactive audio tag editor')

	app.parse_cli() or { return }

	app.banner('Audio Tag Studio CLI', 'v1.0.0 - ID3 & Music Metadata Editor')

	if app.get_flag_bool('interactive') {
		run_interactive(mut app)
		return
	}

	input_path := app.get_flag_string('input')
	if input_path.len == 0 {
		app.warn('No audio file specified. Run with -i <song.mp3> or -x for interactive mode.')
		app.print_help()
		return
	}

	if !app.file_exists(input_path) {
		app.error('File not found: ${input_path}')
		return
	}

	// Read metadata using ffprobe or mid3v2 / id3v2
	app.info('Inspecting audio tags for ${input_path}...')
	out, _ := app.exec('ffprobe -v error -show_entries format_tags -of default=noprint_wrappers=1 "${input_path}"')
	if out.trim_space().len > 0 {
		println(out)
	} else {
		app.warn('No embedded ID3 tags detected in file.')
	}
}

fn run_interactive(mut app simplecli.SimpleCli) {
	app.panel('Audio Tag Wizard', 'View and modify ID3 / FLAC metadata tags.')
	file_path := app.prompt('Enter audio file path', 'song.mp3')
	if !app.file_exists(file_path) {
		app.warn('File does not exist.')
		return
	}
	out, _ := app.exec('ffprobe -v error -show_entries format_tags -of default=noprint_wrappers=1 "${file_path}"')
	println(out)
}

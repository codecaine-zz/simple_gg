module main

import simplecli

fn main() {
	mut app := simplecli.new_app('ffmpeg-cli', '1.0.0')
	app.set_description('FFmpeg Media Transcoder & Audio/Video Processor CLI')

	app.add_flag_string('input', 'i', '', 'Input media file path (video or audio)')
	app.add_flag_string('output', 'o', '', 'Output media file path')
	app.add_flag_string('scale', 's', '', 'Resolution scale (e.g. 1920:1080, 1280:720, 854:480)')
	app.add_flag_string('bitrate', 'b', '', 'Video bitrate (e.g. 2500k, 5000k)')
	app.add_flag_bool('audio-only', 'a', false, 'Extract audio track only as MP3/AAC')
	app.add_flag_bool('probe', 'p', false, 'Inspect media stream metadata and codecs (ffprobe)')
	app.add_flag_bool('interactive', 'x', false, 'Launch interactive FFmpeg wizard')

	app.parse_cli() or { return }

	app.banner('FFmpeg Media Studio CLI', 'v1.0.0 - Video & Audio Transcoding Engine')

	if !app.command_exists('ffmpeg') {
		app.warn('ffmpeg binary not found in PATH. Please install via "brew install ffmpeg".')
	}

	if app.get_flag_bool('interactive') {
		run_interactive(mut app)
		return
	}

	input_path := app.get_flag_string('input')
	if input_path.len == 0 {
		app.warn('No input file specified. Run with -i <input.mp4> or -x for interactive mode.')
		app.print_help()
		return
	}

	if !app.file_exists(input_path) {
		app.error('Input file not found: ${input_path}')
		return
	}

	if app.get_flag_bool('probe') {
		app.info('Inspecting media stream metadata...')
		out, _ := app.exec('ffprobe -v error -show_format -show_streams "${input_path}"')
		println(out)
		return
	}

	mut out_path := app.get_flag_string('output')
	if out_path.len == 0 {
		out_path = 'output_converted.mp4'
	}

	mut args := ['-y', '-i', input_path]

	scale := app.get_flag_string('scale')
	if scale.len > 0 {
		args << ['-vf', 'scale=${scale}']
	}

	bitrate := app.get_flag_string('bitrate')
	if bitrate.len > 0 {
		args << ['-b:v', bitrate]
	}

	if app.get_flag_bool('audio-only') {
		args << ['-vn', '-acodec', 'libmp3lame']
	}

	args << out_path

	app.info('Transcoding media...')
	app.reset_timer()
	out, code := app.exec_safe('ffmpeg', args)
	if code == 0 {
		app.success('Transcoding completed in ${app.elapsed_ms()} ms -> ${out_path}')
	} else {
		app.error('FFmpeg failed (code ${code}):\n${out}')
	}
}

fn run_interactive(mut app simplecli.SimpleCli) {
	app.panel('FFmpeg Transcoder Wizard', 'Quickly convert media formats, resize video, or extract audio tracks.')
	input := app.prompt('Enter input media path', 'sample.mov')
	choice := app.select('Select Action:', [
		'Convert to Web MP4 (H.264 / AAC)',
		'Extract Audio Track (MP3 320k)',
		'Compress & Scale to 720p',
		'Inspect Streams Metadata (ffprobe)',
	])

	match choice {
		'Extract Audio Track (MP3 320k)' {
			out := 'audio_extracted.mp3'
			app.exec_safe('ffmpeg', ['-y', '-i', input, '-vn', '-ab', '320k', out])
			app.success('Extracted audio to ${out}')
		}
		'Compress & Scale to 720p' {
			out := 'scaled_720p.mp4'
			app.exec_safe('ffmpeg', ['-y', '-i', input, '-vf', 'scale=1280:720', '-c:v', 'libx264', '-crf', '23', out])
			app.success('Rendered 720p to ${out}')
		}
		'Inspect Streams Metadata (ffprobe)' {
			out, _ := app.exec('ffprobe -v error -show_format "${input}"')
			println(out)
		}
		else {
			out := 'web_optimized.mp4'
			app.exec_safe('ffmpeg', ['-y', '-i', input, '-c:v', 'libx264', '-c:a', 'aac', out])
			app.success('Converted to ${out}')
		}
	}
}

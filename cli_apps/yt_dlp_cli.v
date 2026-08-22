module main

import simplecli

fn main() {
	mut app := simplecli.new_app('ytdlp-cli', '1.0.0')
	app.set_description('yt-dlp High-Performance Media Downloader CLI')

	app.add_flag_string('url', 'u', '', 'Media video/audio URL to download')
	app.add_flag_string('format', 'f', 'bestvideo+bestaudio/best', 'Target download format selector (e.g. mp4, mp3, 1080p, best)')
	app.add_flag_bool('audio-only', 'a', false, 'Extract audio only (MP3)')
	app.add_flag_bool('info', 'i', false, 'Print video metadata without downloading')
	app.add_flag_string('output', 'o', '%(title)s.%(ext)s', 'Output filename template')
	app.add_flag_bool('interactive', 'x', false, 'Launch interactive download wizard')

	app.parse_cli() or { return }

	app.banner('yt-dlp Studio CLI', 'v1.0.0 - Stream & Video Downloader Engine')

	if !app.command_exists('yt-dlp') {
		app.warn('yt-dlp binary not found in PATH. Install via "brew install yt-dlp".')
	}

	if app.get_flag_bool('interactive') {
		run_interactive(mut app)
		return
	}

	url := app.get_flag_string('url')
	if url.len == 0 {
		app.warn('No URL specified. Run with -u <url> or -x for interactive mode.')
		app.print_help()
		return
	}

	if app.get_flag_bool('info') {
		app.info('Fetching video metadata for "${url}"...')
		out, _ := app.exec_safe('yt-dlp', ['--dump-json', url])
		println(out)
		return
	}

	mut args := [url, '-o', app.get_flag_string('output')]
	if app.get_flag_bool('audio-only') {
		args << ['-x', '--audio-format', 'mp3']
	} else {
		args << ['-f', app.get_flag_string('format')]
	}

	app.info('Downloading stream...')
	app.reset_timer()
	out, code := app.exec_safe('yt-dlp', args)
	if code == 0 {
		app.success('Download finished in ${app.elapsed_ms()} ms.')
	} else {
		app.error('yt-dlp failed (code ${code}):\n${out}')
	}
}

fn run_interactive(mut app simplecli.SimpleCli) {
	app.panel('yt-dlp Interactive Wizard', 'Download web video, extract MP3 audio, or inspect media formats.')
	url := app.prompt('Enter media URL', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ')
	choice := app.select('Download Mode:', [
		'Best Quality Video (MP4 / WebM)',
		'Audio Only (MP3 320k)',
		'List Available Stream Formats',
	])

	match choice {
		'Audio Only (MP3 320k)' {
			app.exec_safe('yt-dlp', ['-x', '--audio-format', 'mp3', url])
		}
		'List Available Stream Formats' {
			out, _ := app.exec_safe('yt-dlp', ['-F', url])
			println(out)
		}
		else {
			app.exec_safe('yt-dlp', ['-f', 'bestvideo+bestaudio/best', url])
		}
	}
}

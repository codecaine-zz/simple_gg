module main

import simplecli

fn main() {
	mut app := simplecli.new_app('wget2-cli', '1.0.0')
	app.set_description('High-Performance Web File Downloader CLI')

	app.add_flag_string('url', 'u', '', 'Remote file URL to download')
	app.add_flag_string('output', 'o', '', 'Destination local file path')
	app.add_flag_bool('continue', 'c', false, 'Resume partially downloaded file')
	app.add_flag_bool('interactive', 'x', false, 'Launch interactive downloader')

	app.parse_cli() or { return }

	app.banner('Wget2 Studio CLI', 'v1.0.0 - Web Downloader Engine')

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

	mut out_file := app.get_flag_string('output')
	if out_file.len == 0 {
		// Extract name from URL
		parts := url.split('/')
		out_file = if parts.len > 0 && parts.last().len > 0 { parts.last() } else { 'downloaded_file' }
	}

	app.info('Downloading ${url} -> ${out_file}...')
	app.reset_timer()

	app.http_download(url, out_file) or {
		app.error('Download failed: ${err}')
		return
	}

	app.success('Download completed in ${app.elapsed_ms()} ms -> ${out_file}')
}

fn run_interactive(mut app simplecli.SimpleCli) {
	app.panel('Downloader Wizard', 'Download web assets, tarballs, and documents.')
	target_url := app.prompt('Enter file URL', 'https://raw.githubusercontent.com/vlang/v/master/README.md')
	dest := app.prompt('Destination filename', 'v_readme.md')
	app.http_download(target_url, dest) or {
		app.error('Download failed: ${err}')
		return
	}
	app.success('Saved to ${dest}')
}

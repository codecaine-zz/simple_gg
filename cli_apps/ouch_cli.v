module main

import simplecli

fn main() {
	mut app := simplecli.new_app('ouch-cli', '1.0.0')
	app.set_description('Universal Archive Compression & Decompression CLI')

	app.add_flag_string('compress', 'c', '', 'Archive destination filename (e.g. archive.tar.gz, backup.zip, files.7z)')
	app.add_flag_string('decompress', 'd', '', 'Archive file path to extract')
	app.add_flag_string('input', 'i', '', 'Input folder or files to compress')
	app.add_flag_bool('interactive', 'x', false, 'Launch interactive archive wizard')

	app.parse_cli() or { return }

	app.banner('Ouch Archive Studio CLI', 'v1.0.0 - Painless Universal Compression')

	has_ouch := app.command_exists('ouch')

	if app.get_flag_bool('interactive') {
		run_interactive(mut app, has_ouch)
		return
	}

	compress_target := app.get_flag_string('compress')
	decompress_target := app.get_flag_string('decompress')
	input_files := app.get_flag_string('input')

	if decompress_target.len > 0 {
		app.info('Extracting archive: ${decompress_target}...')
		if has_ouch {
			out, code := app.exec_safe('ouch', ['decompress', decompress_target])
			if code == 0 {
				app.success('Extracted archive successfully.')
			} else {
				app.error('Extraction failed:\n${out}')
			}
		} else {
			// Fallback to tar or unzip
			if decompress_target.ends_with('.zip') {
				app.exec_safe('unzip', [decompress_target])
			} else {
				app.exec_safe('tar', ['-xf', decompress_target])
			}
			app.success('Extracted using native fallback.')
		}
		return
	}

	if compress_target.len > 0 && input_files.len > 0 {
		app.info('Compressing "${input_files}" to "${compress_target}"...')
		if has_ouch {
			out, code := app.exec_safe('ouch', ['compress', input_files, compress_target])
			if code == 0 {
				app.success('Archive created successfully.')
			} else {
				app.error('Compression failed:\n${out}')
			}
		} else {
			// Fallback to zip or tar
			if compress_target.ends_with('.zip') {
				app.exec_safe('zip', ['-r', compress_target, input_files])
			} else {
				app.exec_safe('tar', ['-czf', compress_target, input_files])
			}
			app.success('Archive created using native fallback.')
		}
		return
	}

	app.println(app.dim('Run with -c <archive.zip> -i <folder> to compress or -d <archive.zip> to extract.'))
}

fn run_interactive(mut app simplecli.SimpleCli, has_ouch bool) {
	app.panel('Archive Manager Wizard', 'Compress and decompress ZIP, TAR, GZ, 7Z, and ZSTD archives.')
	choice := app.select('Action:', ['Compress Folder to ZIP', 'Compress Folder to Tar.gz', 'Decompress Archive'])
	match choice {
		'Compress Folder to ZIP' {
			src := app.prompt('Input folder', '.')
			dest := app.prompt('Destination zip', 'archive.zip')
			if has_ouch {
				app.exec_safe('ouch', ['compress', src, dest])
			} else {
				app.exec_safe('zip', ['-r', dest, src])
			}
			app.success('Created ${dest}')
		}
		'Compress Folder to Tar.gz' {
			src := app.prompt('Input folder', '.')
			dest := app.prompt('Destination tar.gz', 'archive.tar.gz')
			if has_ouch {
				app.exec_safe('ouch', ['compress', src, dest])
			} else {
				app.exec_safe('tar', ['-czf', dest, src])
			}
			app.success('Created ${dest}')
		}
		else {
			arc := app.prompt('Archive file path', 'archive.zip')
			if has_ouch {
				app.exec_safe('ouch', ['decompress', arc])
			} else {
				app.exec_safe('unzip', [arc])
			}
			app.success('Decompressed ${arc}')
		}
	}
}

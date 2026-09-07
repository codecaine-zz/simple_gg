module main

import os
import simplecli

fn main() {
	mut app := simplecli.new_app('rip-cli', '1.0.0')
	app.set_description('Ergonomic Graveyard & Safe Deletion CLI (rip2 alternative to rm)')

	app.add_flag_string('bury', 'b', '', 'File or directory to safely move to the graveyard')
	app.add_flag_bool('unbury', 'u', false, 'Restore specified file or most recent if omitted')
	app.add_flag_bool('seance', 's', false, 'List files deleted from directory (defaults to current dir)')
	app.add_flag_bool('decompose', 'd', false, 'Permanently delete all files in the graveyard')
	app.add_flag_bool('graveyard', 'g', false, 'Print graveyard directory path and active tomb records')
	app.add_flag_bool('inspect', 'i', false, 'Inspect file information before burying')
	app.add_flag_bool('force', 'f', false, 'Non-interactive mode')
	app.add_flag_bool('interactive', 'x', false, 'Launch interactive safe-deletion wizard')

	app.parse_cli() or { return }

	app.banner('Rip Safe Deletion CLI', 'v1.0.0 - Ergonomic Graveyard Recovery Engine')

	has_rip := app.command_exists('rip')
	pos_args := app.get_positional_args()

	if app.get_flag_bool('interactive') {
		run_interactive(mut app, has_rip)
		return
	}

	// 1. Graveyard info query
	if app.get_flag_bool('graveyard') {
		if has_rip {
			out, _ := app.exec_safe('rip', ['graveyard'])
			gy_path := out.trim_space()
			app.info('Graveyard Location: ${gy_path}')
			if os.exists(gy_path) {
				rec_file := os.join_path(gy_path, '.record')
				if os.exists(rec_file) {
					content := os.read_file(rec_file) or { '' }
					lines := content.split_into_lines()
					app.success('Tomb registry found: ${lines.len - 1} historical records recorded.')
				}
			}
		} else {
			app.warn('rip binary not found on PATH. Install with: brew install rip2')
		}
		return
	}

	// 2. Decompose (Permanent wipe)
	if app.get_flag_bool('decompose') {
		if !has_rip {
			app.error('rip binary required to decompose graveyard. Install rip2.')
			return
		}

		force := app.get_flag_bool('force')
		if !force {
			confirmed := app.confirm('Permanently delete all contents of the graveyard? Irreversible!', false)
			if !confirmed {
				app.warn('Decomposition aborted.')
				return
			}
		}

		app.info('Decomposing graveyard...')
		out, code := app.exec_safe('rip', ['-d'])
		if code == 0 {
			app.success('Graveyard successfully decomposed and purged.')
			if out.trim_space() != '' {
				println(out)
			}
		} else {
			app.error('Decomposition failed:\n${out}')
		}
		return
	}

	// 3. Unbury (Restore)
	if app.get_flag_bool('unbury') {
		if !has_rip {
			app.error('rip binary required for unburying. Install rip2.')
			return
		}

		mut args := ['-u']
		if pos_args.len > 0 {
			args << pos_args[0]
		}
		app.info('Resurrecting target from graveyard...')
		out, code := app.exec_safe('rip', args)
		if code == 0 {
			app.success('Successfully unburied item!\n${out}')
		} else {
			app.warn('Notice from unbury operation:\n${out}')
		}
		return
	}

	// 4. Séance (Ghost query)
	if app.get_flag_bool('seance') {
		if !has_rip {
			app.error('rip binary required for seance. Install rip2.')
			return
		}

		effective_dir := if pos_args.len > 0 { pos_args[0] } else { '.' }
		app.info('Summoning ghost records for directory: ${effective_dir}...')

		saved_dir := os.getwd()
		if os.is_dir(effective_dir) {
			os.chdir(effective_dir) or {}
		}
		out, _ := app.exec_safe('rip', ['-s'])
		os.chdir(saved_dir) or {}

		trimmed := out.trim_space()
		if trimmed == '' || trimmed == 'deletion_time\tpath' {
			app.info('No buried ghosts detected in this directory.')
		} else {
			println(out)
			app.success('Ghost records listed. Use -u to restore.')
		}
		return
	}

	// 5. Bury (Safe deletion)
	mut bury_target := app.get_flag_string('bury')
	if bury_target == '' && pos_args.len > 0 {
		bury_target = pos_args[0]
	}

	if bury_target.len > 0 {
		if !os.exists(bury_target) {
			app.error('Target path does not exist: ${bury_target}')
			return
		}

		if bury_target == '/' || bury_target == '/System' || bury_target == '/usr' {
			app.error('Refusing to bury critical operating system root: ${bury_target}')
			return
		}

		if has_rip {
			mut args := []string{}
			if app.get_flag_bool('inspect') {
				args << '-i'
			}
			if app.get_flag_bool('force') {
				args << '-f'
			}
			args << bury_target

			app.info('Burying ${bury_target} into graveyard...')
			out, code := app.exec_safe('rip', args)
			if code == 0 {
				app.success('Target moved to graveyard: ${bury_target}')
				if out.trim_space() != '' {
					println(out)
				}
			} else {
				app.error('Bury failed with exit code ${code}:\n${out}')
			}
		} else {
			app.warn('rip binary not found on PATH. Install rip2 with: brew install rip2')
		}
		return
	}

	app.println(app.dim('Usage examples:'))
	app.println(app.dim('  rip-cli -b myfile.txt           # Bury file safely to graveyard'))
	app.println(app.dim('  rip-cli -u                      # Unbury / resurrect last deleted file'))
	app.println(app.dim('  rip-cli -s                      # Run seance on current directory'))
	app.println(app.dim('  rip-cli -g                      # Show graveyard path and status'))
	app.println(app.dim('  rip-cli -x                      # Launch interactive wizard'))
}

fn run_interactive(mut app simplecli.SimpleCli, has_rip bool) {
	app.panel('Rip Safe Deletion Wizard', 'Safely delete, inspect, restore, and maintain file graveyards.')

	if !has_rip {
		app.warn('Homebrew formula "rip2" is not installed. Run: brew install rip2')
		return
	}

	choice := app.select('Select Graveyard Action:', [
		'Bury File / Directory to Graveyard (-b)',
		'Unbury Most Recent Item (-u)',
		'Directory Séance (Show Deleted in Folder) (-s)',
		'Show Graveyard Vault Path & Status (-g)',
		'Decompose Graveyard (Permanently Empty) (-d)',
	])

	match choice {
		'Bury File / Directory to Graveyard (-b)' {
			target := app.prompt('Path of file or folder to bury', '')
			if target == '' || !os.exists(target) {
				app.error('Specified path does not exist.')
				return
			}
			inspect_first := app.confirm('Inspect file details before burying?', true)
			mut args := []string{}
			if inspect_first {
				args << '-i'
			}
			args << target
			out, code := app.exec_safe('rip', args)
			if code == 0 {
				app.success('Safely buried ${target}')
				if out.trim_space() != '' {
					println(out)
				}
			} else {
				app.error('Operation failed:\n${out}')
			}
		}
		'Unbury Most Recent Item (-u)' {
			app.info('Restoring last buried item...')
			out, code := app.exec_safe('rip', ['-u'])
			if code == 0 {
				app.success('Item resurrected successfully!\n${out}')
			} else {
				app.warn('Result:\n${out}')
			}
		}
		'Directory Séance (Show Deleted in Folder) (-s)' {
			dir := app.prompt('Target directory to check for ghosts', '.')
			saved_dir := os.getwd()
			if os.is_dir(dir) {
				os.chdir(dir) or {}
			}
			out, _ := app.exec_safe('rip', ['-s'])
			os.chdir(saved_dir) or {}
			if out.trim_space() == '' || out.trim_space() == 'deletion_time\tpath' {
				app.info('No deleted files currently resting in graveyard for ${dir}.')
			} else {
				println(out)
				app.success('Séance complete.')
			}
		}
		'Show Graveyard Vault Path & Status (-g)' {
			out, _ := app.exec_safe('rip', ['graveyard'])
			gy := out.trim_space()
			app.info('Graveyard Path: ${gy}')
			if os.exists(gy) {
				app.success('Graveyard directory is active and reachable.')
			}
		}
		'Decompose Graveyard (Permanently Empty) (-d)' {
			if app.confirm('Are you absolutely sure you want to permanently erase the graveyard?', false) {
				out, code := app.exec_safe('rip', ['-d'])
				if code == 0 {
					app.success('Graveyard emptied.')
					if out.trim_space() != '' {
						println(out)
					}
				} else {
					app.error('Decomposition error:\n${out}')
				}
			} else {
				app.warn('Cancelled.')
			}
		}
		else {}
	}
}

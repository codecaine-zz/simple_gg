module main

import os
import simplecli

fn main() {
	mut app := simplecli.new_app('appbundler-cli', '1.0.0')
	app.set_description('macOS Native .app Bundle Packager & Generator CLI')

	app.add_flag_string('bin', 'b', '', 'Path to compiled executable binary')
	app.add_flag_string('name', 'n', 'MyApp', 'Application bundle display name')
	app.add_flag_string('id', 'i', 'com.simplegui.app', 'Bundle identifier (CFBundleIdentifier)')
	app.add_flag_string('version', 'v', '1.0.0', 'Bundle version (CFBundleShortVersionString)')
	app.add_flag_string('out', 'o', '.', 'Output destination directory for .app bundle')
	app.add_flag_bool('interactive', 'x', false, 'Launch interactive app bundler wizard')

	app.parse_cli() or { return }

	app.banner('App Bundler Studio CLI', 'v1.0.0 - macOS Native .app Packager')

	if app.get_flag_bool('interactive') {
		run_interactive(mut app)
		return
	}

	bin_path := app.get_flag_string('bin')
	if bin_path.len == 0 {
		app.warn('No binary specified. Run with -b <binary> -n <AppName> or -x for interactive mode.')
		app.print_help()
		return
	}

	if !app.file_exists(bin_path) {
		app.error('Binary file not found: ${bin_path}')
		return
	}

	app_name := app.get_flag_string('name')
	bundle_id := app.get_flag_string('id')
	version := app.get_flag_string('version')
	out_dir := app.get_flag_string('out')

	bundle_path := '${out_dir}/${app_name}.app'
	macos_dir := '${bundle_path}/Contents/MacOS'
	res_dir := '${bundle_path}/Contents/Resources'

	app.info('Creating bundle directories: ${bundle_path}...')
	app.create_directory(macos_dir)
	app.create_directory(res_dir)

	// Copy binary
	target_bin := '${macos_dir}/${app_name}'
	app.copy_file(bin_path, target_bin) or {
		app.error('Failed to copy binary: ${err}')
		return
	}
	os.chmod(target_bin, 0o755) or {}

	// Write Info.plist
	plist_content := '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleExecutable</key>
	<string>${app_name}</string>
	<key>CFBundleIdentifier</key>
	<string>${bundle_id}</string>
	<key>CFBundleName</key>
	<string>${app_name}</string>
	<key>CFBundleDisplayName</key>
	<string>${app_name}</string>
	<key>CFBundleVersion</key>
	<string>${version}</string>
	<key>CFBundleShortVersionString</key>
	<string>${version}</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>LSMinimumSystemVersion</key>
	<string>11.0</string>
	<key>NSHighResolutionCapable</key>
	<true/>
</dict>
</plist>'

	app.write_file('${bundle_path}/Contents/Info.plist', plist_content)
	app.success('Successfully generated macOS .app bundle at: ${bundle_path}')
}

fn run_interactive(mut app simplecli.SimpleCli) {
	app.panel('App Bundler Wizard', 'Package your compiled V native binary into a macOS .app application.')
	bin := app.prompt('Path to binary executable', 'bin/my_app')
	name := app.prompt('Application Name', 'MyAwesomeApp')
	bundle_id := app.prompt('Bundle ID', 'com.mycompany.myapp')

	if !app.file_exists(bin) {
		app.warn('Binary does not exist. Please compile first.')
		return
	}

	bundle_path := '${name}.app'
	app.create_directory('${bundle_path}/Contents/MacOS')
	app.create_directory('${bundle_path}/Contents/Resources')
	app.copy_file(bin, '${bundle_path}/Contents/MacOS/${name}') or { return }
	os.chmod('${bundle_path}/Contents/MacOS/${name}', 0o755) or {}
	plist := '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict><key>CFBundleExecutable</key><string>${name}</string><key>CFBundleIdentifier</key><string>${bundle_id}</string></dict></plist>'
	app.write_file('${bundle_path}/Contents/Info.plist', plist)
	app.success('Packaged into ${bundle_path}')
}

#!/usr/bin/env -S v run

import os

struct Dependency {
	category    string
	formula     string
	bin_names   []string
	name        string
	description string
	studio_app  string
	optional    bool
}

fn get_dependencies() []Dependency {
	mut deps := []Dependency{}

	// Media, Audio & Graphics
	deps << Dependency{
		category: 'Media & Graphics'
		formula: 'ffmpeg'
		bin_names: ['ffmpeg', 'ffprobe']
		name: 'FFmpeg & FFprobe'
		description: 'Video/Audio transcoding, streaming, and audio metadata tagging'
		studio_app: 'FFmpeg Studio, Audio Tag Studio, Media Hub'
	}
	deps << Dependency{
		category: 'Media & Graphics'
		formula: 'imagemagick'
		bin_names: ['magick', 'convert']
		name: 'ImageMagick'
		description: 'Bitmap/Vector image manipulation and asset generation'
		studio_app: 'ImageMagick Studio, Media Hub'
	}
	deps << Dependency{
		category: 'Media & Graphics'
		formula: 'yt-dlp'
		bin_names: ['yt-dlp']
		name: 'yt-dlp'
		description: 'High-speed media and streaming archive tool'
		studio_app: 'YT-DLP Studio, Media Hub'
	}
	deps << Dependency{
		category: 'Media & Graphics'
		formula: 'exiftool'
		bin_names: ['exiftool']
		name: 'ExifTool'
		description: 'Read and write image, audio & video metadata/EXIF/IPTC'
		studio_app: 'Exif Studio'
	}
	deps << Dependency{
		category: 'Media & Graphics'
		formula: 'tesseract'
		bin_names: ['tesseract']
		name: 'Tesseract OCR'
		description: 'Optical character recognition and document scanner'
		studio_app: 'OCR Studio'
	}
	deps << Dependency{
		category: 'Media & Graphics'
		formula: 'graphviz'
		bin_names: ['dot', 'neato']
		name: 'Graphviz (DOT)'
		description: 'Code-to-diagram visualization and graph compilation'
		studio_app: 'Graphviz Studio'
	}

	// Data, Search & Text Engineering
	deps << Dependency{
		category: 'Data & Text'
		formula: 'jq'
		bin_names: ['jq']
		name: 'JQ'
		description: 'Lightweight and flexible command-line JSON processor'
		studio_app: 'JQ Studio'
	}
	deps << Dependency{
		category: 'Data & Text'
		formula: 'ripgrep'
		bin_names: ['rg']
		name: 'ripgrep (rg)'
		description: 'Ultra-fast recursive regex pattern search engine'
		studio_app: 'RG Studio'
	}
	deps << Dependency{
		category: 'Data & Text'
		formula: 'fd'
		bin_names: ['fd']
		name: 'fd'
		description: 'Simple, fast, and user-friendly alternative to find'
		studio_app: 'FD Studio'
	}
	deps << Dependency{
		category: 'Data & Text'
		formula: 'sd'
		bin_names: ['sd']
		name: 'sd'
		description: 'Intuitive and fast find & replace CLI'
		studio_app: 'SD Studio'
	}
	deps << Dependency{
		category: 'Data & Text'
		formula: 'gawk'
		bin_names: ['gawk']
		name: 'GNU AWK'
		description: 'Pattern scanning and data stream processing language'
		studio_app: 'GAWK Studio'
	}
	deps << Dependency{
		category: 'Data & Text'
		formula: 'pandoc'
		bin_names: ['pandoc']
		name: 'Pandoc'
		description: 'Universal document format converter and publisher'
		studio_app: 'Pandoc Studio'
	}
	deps << Dependency{
		category: 'Data & Text'
		formula: 'ouch'
		bin_names: ['ouch']
		name: 'Ouch'
		description: 'Painless and ultra-fast compression/decompression tool'
		studio_app: 'Ouch Studio'
	}
	deps << Dependency{
		category: 'Data & Text'
		formula: 'sqlite'
		bin_names: ['sqlite3']
		name: 'SQLite3'
		description: 'Embedded SQL relational database engine'
		studio_app: 'SQLite Studio'
	}
	deps << Dependency{
		category: 'Data & Text'
		formula: 'wget2'
		bin_names: ['wget2', 'wget']
		name: 'GNU Wget2'
		description: 'Multi-threaded file download accelerator and web scraper'
		studio_app: 'Wget2 Studio'
	}

	// Network, Security & Reconnaissance
	deps << Dependency{
		category: 'Network & Security'
		formula: 'nmap'
		bin_names: ['nmap']
		name: 'Nmap'
		description: 'Network exploration tool and security / port scanner'
		studio_app: 'Nmap Studio'
	}
	deps << Dependency{
		category: 'Network & Security'
		formula: 'bind'
		bin_names: ['dig']
		name: 'BIND (dig)'
		description: 'DNS lookup utility and nameserver diagnostics'
		studio_app: 'DNS Studio'
	}
	deps << Dependency{
		category: 'Network & Security'
		formula: 'openssl@3'
		bin_names: ['openssl']
		name: 'OpenSSL 3'
		description: 'TLS/SSL cryptography toolkit and certificate inspector'
		studio_app: 'DNS Studio'
	}
	deps << Dependency{
		category: 'Network & Security'
		formula: 'whois'
		bin_names: ['whois']
		name: 'WHOIS'
		description: 'Domain and IP address registration lookup tool'
		studio_app: 'Recon Studio'
	}
	deps << Dependency{
		category: 'Network & Security'
		formula: 'subfinder'
		bin_names: ['subfinder']
		name: 'Subfinder'
		description: 'Fast passive subdomain discovery tool'
		studio_app: 'Subfinder Studio'
	}

	// Mathematics & Scientific Calculators
	deps << Dependency{
		category: 'Math & Calculators'
		formula: 'libqalculate'
		bin_names: ['qalc']
		name: 'Qalculate! (qalc)'
		description: 'Multi-purpose desktop calculator and unit conversion engine'
		studio_app: 'Qalc Studio'
	}
	deps << Dependency{
		category: 'Math & Calculators'
		formula: 'numbat'
		bin_names: ['numbat']
		name: 'Numbat'
		description: 'Statically-typed dimensional analysis and physical calculation engine'
		studio_app: 'Numbat Studio'
	}
	deps << Dependency{
		category: 'Math & Calculators'
		formula: 'kalker'
		bin_names: ['kalker']
		name: 'Kalker'
		description: 'Full math engine with natural calculus and matrix support'
		studio_app: 'Kalker Studio'
	}

	// Cross-compilation toolchains (Optional)
	deps << Dependency{
		category: 'Cross-Compilation Toolchains'
		formula: 'zig'
		bin_names: ['zig']
		name: 'Zig'
		description: 'C/C++ cross-compiler for targeting Windows/Linux'
		studio_app: 'Multi-OS Compilation (compile_apps.vsh)'
		optional: true
	}
	deps << Dependency{
		category: 'Cross-Compilation Toolchains'
		formula: 'mingw-w64'
		bin_names: ['x86_64-w64-mingw32-gcc']
		name: 'MinGW-w64'
		description: 'GCC toolchain for targeting Windows x86_64'
		studio_app: 'Windows Compilation (compile_apps.vsh)'
		optional: true
	}

	return deps
}

fn check_installed(dep Dependency) (bool, string) {
	for bin_name in dep.bin_names {
		// Check system PATH
		if p := os.find_abs_path_of_executable(bin_name) {
			return true, p
		}
		// Check standard macOS Homebrew locations
		homebrew_arm := '/opt/homebrew/bin/' + bin_name
		if os.exists(homebrew_arm) {
			return true, homebrew_arm
		}
		homebrew_intel := '/usr/local/bin/' + bin_name
		if os.exists(homebrew_intel) {
			return true, homebrew_intel
		}
	}
	return false, ''
}

fn print_help() {
	println('======================================================================')
	println('  SimpleGUI Homebrew Dependencies Installer & Health Inspector')
	println('======================================================================')
	println('Usage: ./install_dependencies.vsh [options]')
	println('')
	println('Options:')
	println('  -c, --check, --dry-run  Scan and report status without installing anything')
	println('  -y, --yes               Install all missing formulas non-interactively')
	println('  --all                   Include optional cross-compilers (zig, mingw-w64)')
	println('  --formula <name>        Install a single specific Homebrew formula')
	println('  -h, --help              Show this help information')
	println('')
	println('Examples:')
	println('  ./install_dependencies.vsh              # Inspect and prompt to install missing')
	println('  ./install_dependencies.vsh -y           # Auto-install all missing formulas')
	println('  ./install_dependencies.vsh --check      # Dry-run inspection only')
	println('  ./install_dependencies.vsh --all -y     # Auto-install apps + cross-compilers')
	println('======================================================================')
}

fn main() {
	mut is_check_only := false
	mut auto_confirm := false
	mut include_optional := false
	mut target_formula := ''

	mut i := 1
	for i < os.args.len {
		arg := os.args[i]
		if arg == '-h' || arg == '--help' || arg == 'help' {
			print_help()
			exit(0)
		} else if arg == '-c' || arg == '--check' || arg == '--dry-run' {
			is_check_only = true
		} else if arg == '-y' || arg == '--yes' {
			auto_confirm = true
		} else if arg == '--all' {
			include_optional = true
		} else if arg == '--formula' {
			if i + 1 < os.args.len {
				i++
				target_formula = os.args[i]
			}
		}
		i++
	}

	platform := os.user_os()
	println('======================================================================')
	println('  SimpleGUI Dependencies Inspector & Installer')
	println('======================================================================')
	println('Platform: ${platform}')

	mut brew_path := ''
	if platform == 'darwin' {
		if p := os.find_abs_path_of_executable('brew') {
			brew_path = p
		} else if os.exists('/opt/homebrew/bin/brew') {
			brew_path = '/opt/homebrew/bin/brew'
		} else if os.exists('/usr/local/bin/brew') {
			brew_path = '/usr/local/bin/brew'
		}
	}

	if platform == 'linux' {
		println('Linux detected: this project uses V/gg and needs X11/OpenGL dev headers.')
		println('Install them with:')
		println('  sudo apt update')
		println('  sudo apt install -y libx11-dev libxcursor-dev libxi-dev libgl1-mesa-dev libasound2-dev xclip')
		println('')
		println('Some CLI utilities can also be installed with Homebrew on Linux/macOS:')
		println('  brew install ffmpeg imagemagick yt-dlp exiftool tesseract graphviz jq ripgrep fd sd gawk pandoc sqlite wget nmap whois subfinder qalc numbat')
		println('')
		println('If you cloned the repo from GitHub, make the module importable with:')
		println('  mkdir -p ~/.vmodules')
		println('  ln -s "$PWD" ~/.vmodules/simplegui')
		println('----------------------------------------------------------------------')
	} else if brew_path.len == 0 {
		eprintln('\n❌ Homebrew is not installed on this system!')
		eprintln('To install Homebrew, run:')
		eprintln('   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"')
		eprintln('\nThen re-run this script.\n')
		exit(1)
	} else {
		println('Homebrew Path: ${brew_path}')
	}

	println('Scanning installed CLI tools across 43 workstation applications...')
	println('----------------------------------------------------------------------')

	all_deps := get_dependencies()
	mut missing_deps := []Dependency{}
	mut installed_count := 0
	mut current_category := ''

	for dep in all_deps {
		if !include_optional && dep.optional {
			continue
		}
		if target_formula.len > 0 && dep.formula != target_formula {
			continue
		}

		if dep.category != current_category {
			current_category = dep.category
			println('\n📁 ${current_category}:')
		}

		installed, bin_path := check_installed(dep)
		if installed {
			println('  ✅ ${dep.name:-24s} (${dep.formula}) -> ${bin_path}')
			installed_count++
		} else {
			opt_suffix := if dep.optional { ' [Optional]' } else { '' }
			println('  ❌ ${dep.name:-24s} (${dep.formula})${opt_suffix} -> NOT INSTALLED (Used by: ${dep.studio_app})')
			missing_deps << dep
		}
	}

	println('\n======================================================================')
	println('Health Summary:')
	println('  Installed : ${installed_count}')
	println('  Missing   : ${missing_deps.len}')
	println('======================================================================')

	if missing_deps.len == 0 {
		println('🎉 All required dependencies are installed and ready!')
		exit(0)
	}

	if is_check_only {
		println('\nℹ️  Run this script again on your platform with the package manager that matches your OS.')
		exit(0)
	}

	if platform == 'linux' {
		println('\nℹ️  Linux installs are commonly done with apt, but many of the same tools are available via Homebrew too.')
		println('Use apt on Ubuntu/Debian, for example:')
		println('  sudo apt update')
		println('  sudo apt install -y jq ripgrep fd-find sd gawk pandoc sqlite3 wget2 nmap dnsutils openssl whois subfinder ffmpeg imagemagick exiftool tesseract-ocr graphviz qalc numbat')
		println('')
		println('Or with Homebrew if it is already installed on your Linux/macOS system:')
		println('  brew install ffmpeg imagemagick yt-dlp exiftool tesseract graphviz jq ripgrep fd sd gawk pandoc sqlite wget nmap whois subfinder qalc numbat')
		exit(0)
	}

	mut formulas_to_install := []string{}
	for d in missing_deps {
		if d.formula !in formulas_to_install {
			formulas_to_install << d.formula
		}
	}

	println('\nThe following Homebrew formulas need to be installed:')
	println('   ' + formulas_to_install.join(' '))

	if !auto_confirm {
		print('\nWould you like to install all missing formulas via brew now? [Y/n]: ')
		flush_stdout()
		input := os.get_line().trim_space().to_lower()
		if input != '' && input != 'y' && input != 'yes' {
			println('Installation cancelled.')
			exit(0)
		}
	}

	println('\n🚀 Running: ${brew_path} install ' + formulas_to_install.join(' '))
	println('----------------------------------------------------------------------')

	cmd := '${os.quoted_path(brew_path)} install ' + formulas_to_install.join(' ')
	res := os.system(cmd)

	println('----------------------------------------------------------------------')
	if res == 0 {
		println('🎉 Successfully installed all missing dependencies!')
	} else {
		eprintln('⚠️  Homebrew exited with code ${res}. Some formulas may have failed.')
		exit(1)
	}
}

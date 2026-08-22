module main

import os
import time
import simplegui

// Helper to find sd binary
fn get_sd_bin() string {
	if path := os.find_abs_path_of_executable('sd') {
		return path
	}
	common_paths := [
		'/opt/homebrew/bin/sd',
		'/usr/local/bin/sd',
		'/bin/sd',
	]
	for p in common_paths {
		if os.exists(p) {
			return p
		}
	}
	return 'sd'
}

struct SdRecipe {
	title       string
	category    string
	find_pat    string
	replace_str string
	flags       string
	fixed_str   bool
	across      bool
	desc        string
}

fn get_all_sd_recipes() []SdRecipe {
	return [
		// 1. Code Refactoring & Syntax
		SdRecipe{
			title: 'Swap Two Function Arguments (foo(a, b) -> foo(b, a))'
			category: 'Code Refactoring'
			find_pat: '(\\w+)\\(([^,]+),\\s*([^)]+)\\)'
			replace_str: '$1($3, $2)'
			flags: ''
			fixed_str: false
			across: false
			desc: 'Swaps the 1st and 2nd arguments in function calls using capture groups $1, $2, $3.'
		},
		SdRecipe{
			title: 'Rename Variable / Identifier (Exact Word Match)'
			category: 'Code Refactoring'
			find_pat: 'old_var_name'
			replace_str: 'new_var_name'
			flags: 'w'
			fixed_str: false
			across: false
			desc: 'Matches exact whole words only (-f w) to prevent accidental partial matches.'
		},
		SdRecipe{
			title: 'Change Import / Require Path'
			category: 'Code Refactoring'
			find_pat: "import\\s+['\"]old_module['\"]"
			replace_str: "import 'new_module'"
			flags: ''
			fixed_str: false
			across: false
			desc: 'Updates library and module import declarations.'
		},
		SdRecipe{
			title: 'Convert var declarations to const / let'
			category: 'Code Refactoring'
			find_pat: '\\bvar\\s+(\\w+)\\s*='
			replace_str: 'const $1 ='
			flags: ''
			fixed_str: false
			across: false
			desc: 'Modernizes legacy var variable declarations.'
		},
		SdRecipe{
			title: 'Strip console.log / print Debug Statements'
			category: 'Code Refactoring'
			find_pat: '^\\s*console\\.log\\(.*?\\);?\\n?'
			replace_str: ''
			flags: 'm'
			fixed_str: false
			across: false
			desc: 'Removes all single-line console.log debugging statements.'
		},
		SdRecipe{
			title: 'Remove Single-Line Comments (// ...)'
			category: 'Code Refactoring'
			find_pat: '\\s*//.*$'
			replace_str: ''
			flags: 'm'
			fixed_str: false
			across: false
			desc: 'Strips single-line double-slash comments.'
		},
		SdRecipe{
			title: 'Remove Multi-Line Block Comments (/* ... */)'
			category: 'Code Refactoring'
			find_pat: '/\\*[\\s\\S]*?\\*/'
			replace_str: ''
			flags: 's'
			fixed_str: false
			across: true
			desc: 'Removes multi-line C-style block comments across line boundaries.'
		},

		// 2. Text Cleansing & Whitespace
		SdRecipe{
			title: 'Trim Trailing Whitespace from Lines'
			category: 'Text Cleansing'
			find_pat: '[ \\t]+$'
			replace_str: ''
			flags: 'm'
			fixed_str: false
			across: false
			desc: 'Removes lingering spaces and tabs at the ends of lines.'
		},
		SdRecipe{
			title: 'Collapse Multiple Blank Lines into Single Blank Line'
			category: 'Text Cleansing'
			find_pat: '\\n{3,}'
			replace_str: '\n\n'
			flags: 's'
			fixed_str: false
			across: true
			desc: 'Reduces excessive consecutive newlines to clean double newlines.'
		},
		SdRecipe{
			title: 'Convert Windows CRLF (\\r\\n) to Unix LF (\\n)'
			category: 'Text Cleansing'
			find_pat: '\r\n'
			replace_str: '\n'
			flags: ''
			fixed_str: true
			across: true
			desc: 'Normalizes Windows line endings to standard Unix line feeds.'
		},
		SdRecipe{
			title: 'Collapse Multiple Spaces to Single Space'
			category: 'Text Cleansing'
			find_pat: '[ ]{2,}'
			replace_str: ' '
			flags: ''
			fixed_str: false
			across: false
			desc: 'Replaces two or more consecutive spaces with a single space.'
		},
		SdRecipe{
			title: 'Strip All HTML / XML Tags (<...>'
			category: 'Text Cleansing'
			find_pat: '<[^>]+>'
			replace_str: ''
			flags: ''
			fixed_str: false
			across: false
			desc: 'Extracts plain text by stripping HTML and XML tags.'
		},

		// 3. Format & Pattern Transformation
		SdRecipe{
			title: 'Format Phone Numbers (1234567890 -> (123) 456-7890)'
			category: 'Pattern Formatting'
			find_pat: '\\b(\\d{3})[-.]?(\\d{3})[-.]?(\\d{4})\\b'
			replace_str: '($1) $2-$3'
			flags: ''
			fixed_str: false
			across: false
			desc: 'Normalizes 10-digit phone numbers into standard formatted format.'
		},
		SdRecipe{
			title: 'Reformat Date (YYYY-MM-DD -> MM/DD/YYYY)'
			category: 'Pattern Formatting'
			find_pat: '\\b(\\d{4})-(\\d{2})-(\\d{2})\\b'
			replace_str: '$2/$3/$1'
			flags: ''
			fixed_str: false
			across: false
			desc: 'Converts ISO 8601 dates to US slash format.'
		},
		SdRecipe{
			title: 'Convert Markdown Links to HTML <a> Tags'
			category: 'Pattern Formatting'
			find_pat: '\\[([^\\]]+)\\]\\(([^)]+)\\)'
			replace_str: '<a href="$2">$1</a>'
			flags: ''
			fixed_str: false
			across: false
			desc: 'Transforms [Title](url) markdown syntax into clickable HTML anchor tags.'
		},
		SdRecipe{
			title: 'Wrap Words / Identifiers in Backticks (`word`)'
			category: 'Pattern Formatting'
			find_pat: '\\b([A-Za-z0-9_]{4,})\\b'
			replace_str: '`$1`'
			flags: ''
			fixed_str: false
			across: false
			desc: 'Wraps code identifiers in markdown inline code backticks.'
		},
		SdRecipe{
			title: 'Redact Email Addresses (user@domain.com -> [REDACTED])'
			category: 'Pattern Formatting'
			find_pat: '\\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}\\b'
			replace_str: '[REDACTED_EMAIL]'
			flags: 'i'
			fixed_str: false
			across: false
			desc: 'Anonymizes email addresses for privacy compliance.'
		},
		SdRecipe{
			title: 'Redact IPv4 Addresses (192.168.1.1 -> [REDACTED_IP])'
			category: 'Pattern Formatting'
			find_pat: '\\b\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\b'
			replace_str: '[REDACTED_IP]'
			flags: ''
			fixed_str: false
			across: false
			desc: 'Hides public and private IP addresses.'
		},

		// 4. DevOps, Config & Cloud
		SdRecipe{
			title: 'Update .env Key-Value Pair (PORT=3000 -> PORT=8080)'
			category: 'DevOps & Config'
			find_pat: '^PORT=.*$'
			replace_str: 'PORT=8080'
			flags: 'm'
			fixed_str: false
			across: false
			desc: 'Updates specific environment variable in .env configuration.'
		},
		SdRecipe{
			title: 'Bump Semantic Version ("version": "x.y.z")'
			category: 'DevOps & Config'
			find_pat: '("version"\\s*:\\s*)"[^"]+"'
			replace_str: '$1"1.2.0"'
			flags: ''
			fixed_str: false
			across: false
			desc: 'Bumps version number in package.json, v.mod, or Cargo.toml.'
		},
		SdRecipe{
			title: 'Update Docker Base Image Tag (node:14 -> node:20-alpine)'
			category: 'DevOps & Config'
			find_pat: 'FROM\\s+node:[^\\s]+'
			replace_str: 'FROM node:20-alpine'
			flags: 'i'
			fixed_str: false
			across: false
			desc: 'Updates container base image in Dockerfile.'
		},
		SdRecipe{
			title: 'Switch HTTP URL protocol to HTTPS'
			category: 'DevOps & Config'
			find_pat: 'http://([A-Za-z0-9.-]+)'
			replace_str: 'https://$1'
			flags: 'i'
			fixed_str: false
			across: false
			desc: 'Upgrades unencrypted http endpoints to secure https.'
		},
	]
}

fn get_sample_code() string {
	return '// Project: User API Gateway v1.0.0
var user_id = 402;
var api_endpoint = "http://api.internal.service/v1";

function calculate_discount(price, rate) {
    console.log("Debug calculating price: " + price);
    return price * (1.0 - rate);
}

function process_user(id, email, phone) {
    // Contact details
    var user_phone = "4155550199";
    var user_email = "alex.dev@startup.io";
    var user_ip = "192.168.1.105";
    
    /* 
       Multi-line audit note:
       User approved on 2026-08-21.
    */
    console.log("Processing user: " + id);
    return calculate_discount(120.00, 0.15);
}'
}

fn main() {
	println('Starting SimpleGUI - SD Studio Pro (Search & Displace Workbench)...')

	mut win := simplegui.new_simple_window('SimpleGUI - SD Studio Pro', 1000, 930)
	win.set_fullscreen(true)
	win.set_spacing(8)
	win.set_padding(16)

	saved_theme := simplegui.get_saved_theme()
	win.set_theme(saved_theme)

	// Top Banner
	win.begin_row('row_sd_top')
	win.add_heading('SD Studio Pro')
	win.add_label('lbl_theme', 'Theme:')
	win.add_dropdown('dd_app_theme', simplegui.list_themes(), saved_theme)
	win.set_control_width('dd_app_theme', 150)
	win.end_row()

	win.on_change('dd_app_theme', fn (mut w simplegui.SimpleWindow, selected string) {
		w.set_theme(selected)
		w.toast('Theme changed to ${selected}')
	})
	sd_path := get_sd_bin()
	win.add_label('lbl_engine_info', 'Engine: ${sd_path}  |  Platform: macOS Cocoa  |  Mode: Async Worker (Zero UI Freezes)')

	all_recipes := get_all_sd_recipes()

	// -------------------------------------------------------------
	// Search & Replace Configuration Bar
	// -------------------------------------------------------------
	win.begin_group_box('grp_search_box', 'Search & Replace Parameters')
	
	// Row 1: Find Field
	win.begin_row('row_find')
	win.add_label('lbl_find', 'Find (Pattern / Regex):')
	win.add_input('txt_find', r'var\s+(\w+)\s*=')
	win.set_control_width('txt_find', 460)
	win.add_checkbox('chk_fixed_str', 'Fixed String Mode (-F)', false)
	win.add_checkbox('chk_across', 'Across Lines (-A)', false)
	win.end_row()

	// Row 2: Replace Field
	win.begin_row('row_replace')
	win.add_label('lbl_replace', 'Replace With ($1, $2):')
	win.add_input('txt_replace', 'const $1 =')
	win.set_control_width('txt_replace', 460)
	win.add_checkbox('chk_case_insens', 'Ignore Case (-f i)', false)
	win.add_checkbox('chk_word_only', 'Whole Words (-f w)', false)
	win.end_row()

	win.end_group_box()

	// -------------------------------------------------------------
	// Preset Recipe Library
	// -------------------------------------------------------------
	win.begin_group_box('grp_recipes', 'Ready-to-Use SD Solutions & Regex Recipes')
	
	mut recipe_titles := ['-- Select a Search & Displace Solution --']
	for r in all_recipes {
		recipe_titles << '[${r.category}] ' + r.title
	}

	win.begin_row('row_recipe_sel')
	win.add_label('lbl_recipe_title', 'Select Solution:')
	win.add_dropdown('dd_recipe', recipe_titles, recipe_titles[0])
	win.set_control_width('dd_recipe', 520)
	win.add_button('btn_apply_recipe', 'Load Recipe')
	win.add_button('btn_run_recipe_now', 'Load & Run')
	win.end_row()

	win.begin_row('row_recipe_desc')
	win.add_label('lbl_recipe_desc', 'Tip: Pick any recipe above to automatically configure regex pattern, replacement and flags.')
	win.end_row()
	win.end_group_box()

	// -------------------------------------------------------------
	// Dual Pane: Input Text & Output Preview
	// -------------------------------------------------------------
	win.begin_group_box('grp_input_pane', 'Input Data Stream (Paste code, logs, or text to transform)')
	win.begin_row('row_in_actions')
	win.add_button('btn_sample_code', 'Load Sample Code')
	win.add_button('btn_load_in_file', 'Load File from Disk...')
	win.add_button('btn_paste_in', 'Paste Clipboard')
	win.add_button('btn_clear_in', 'Clear Input')
	win.end_row()
	win.add_textarea('txt_input_data', get_sample_code())
	win.set_control_height('txt_input_data', 135)
	win.end_group_box()

	// -------------------------------------------------------------
	// Actions & Live Execution Bar
	// -------------------------------------------------------------
	win.begin_row('row_actions')
	win.add_button('btn_run_sd', 'Execute Search & Replace')
	win.add_button('btn_copy_output', 'Copy Result')
	win.add_button('btn_save_output', 'Save Output to File...')
	win.add_button('btn_batch_files', 'Batch Replace Across Disk Folder...')
	win.add_button('btn_clear_out', 'Clear Output')
	win.end_row()

	// -------------------------------------------------------------
	// Output Pane & Statistics Banner
	// -------------------------------------------------------------
	win.begin_group_box('grp_output_pane', 'Replaced Output Stream (Transformed Result)')
	win.add_textarea('txt_output_data', '')
	win.set_control_height('txt_output_data', 145)
	win.end_group_box()

	// Stats Row
	win.begin_row('row_stats')
	win.add_label('lbl_exec_stats', 'Stats: Ready  |  Duration: 0 ms  |  Output Size: 0 bytes')
	win.end_row()

	// -------------------------------------------------------------
	// Core SD Execution Engine (Async Non-Blocking)
	// -------------------------------------------------------------
	execute_sd := fn (mut win simplegui.SimpleWindow) {
		find_str := win.get('txt_find')
		repl_str := win.get('txt_replace')
		input_text := win.get('txt_input_data')

		if find_str == '' {
			win.alert('Search Empty', 'Please enter a pattern to search for.')
			return
		}

		sd := get_sd_bin()
		
		is_fixed := win.get('chk_fixed_str') == 'true'
		is_across := win.get('chk_across') == 'true'
		is_case_i := win.get('chk_case_insens') == 'true'
		is_word := win.get('chk_word_only') == 'true'

		win.set_status('Running sd search and replace in background...')
		win.toast('Running SD transformation...')

		go fn [mut win, sd, find_str, repl_str, input_text, is_fixed, is_across, is_case_i, is_word] () {
			t0 := time.ticks()

			tmp_in := os.join_path(os.temp_dir(), 'sd_studio_input_${time.ticks()}.txt')
			os.write_file(tmp_in, input_text) or {}

			mut raw_args := []string{}
			if is_fixed { raw_args << '-F' }
			if is_across { raw_args << '-A' }
			if is_case_i || is_word {
				mut f := ''
				if is_case_i { f += 'i' }
				if is_word { f += 'w' }
				raw_args << ['-f', f]
			}

			raw_args << find_str
			raw_args << repl_str

			res := simplegui.exec_safe_stdin(sd, raw_args, tmp_in)
			elapsed_ms := time.ticks() - t0

			if os.exists(tmp_in) {
				os.rm(tmp_in) or {}
			}

			win.run_on_main_thread(fn [res, elapsed_ms] (mut win_main simplegui.SimpleWindow) {
				if res.exit_code == 0 {
					out_str := res.output
					win_main.set('txt_output_data', out_str)
					bytes := out_str.len
					lines := out_str.count('\n')
					win_main.set('lbl_exec_stats', ' Stats: SUCCESS  |  Duration: ${elapsed_ms} ms  |  Output: ${bytes} bytes  |  Lines: ${lines}')
					win_main.set_status('SD replaced successfully in ${elapsed_ms} ms.')
					win_main.toast('Replaced in ${elapsed_ms} ms!')
				} else {
					win_main.set('txt_output_data', ' SD Execution Error:\n\n' + res.output)
					win_main.set('lbl_exec_stats', ' Stats: ERROR (Exit code ${res.exit_code})  |  Duration: ${elapsed_ms} ms')
					win_main.set_status('SD reported an error.')
				}
			})
		}()
	}

	// -------------------------------------------------------------
	// Event Handlers
	// -------------------------------------------------------------

	// Load Sample Code
	win.on_click('btn_sample_code', fn (mut w simplegui.SimpleWindow) {
		w.set('txt_input_data', get_sample_code())
		w.toast('Sample code loaded.')
	})

	// Load File from Disk
	win.on_click('btn_load_in_file', fn (mut w simplegui.SimpleWindow) {
		path := w.select_file()
		if path != '' && os.exists(path) {
			content := os.read_file(path) or { '' }
			w.set('txt_input_data', content)
			w.toast('Loaded ${path}')
		}
	})

	// Paste Clipboard
	win.on_click('btn_paste_in', fn (mut w simplegui.SimpleWindow) {
		clip := simplegui.clipboard_text()
		if clip != '' {
			w.set('txt_input_data', clip)
			w.toast('Pasted clipboard into input.')
		} else {
			w.toast('Clipboard is empty.')
		}
	})

	// Clear Input
	win.on_click('btn_clear_in', fn (mut w simplegui.SimpleWindow) {
		w.set('txt_input_data', '')
		w.toast('Input cleared.')
	})

	// Clear Output
	win.on_click('btn_clear_out', fn (mut w simplegui.SimpleWindow) {
		w.set('txt_output_data', '')
		w.toast('Output cleared.')
	})

	// Copy Output
	win.on_click('btn_copy_output', fn (mut w simplegui.SimpleWindow) {
		out := w.get('txt_output_data')
		if out != '' {
			w.copy_to_clipboard(out)
			w.toast('Output copied to clipboard!')
		} else {
			w.toast('Output is empty.')
		}
	})

	// Save Output to File
	win.on_click('btn_save_output', fn (mut w simplegui.SimpleWindow) {
		out := w.get('txt_output_data')
		if out == '' {
			w.toast('Output is empty.')
			return
		}
		path := w.save_file_picker()
		if path != '' {
			os.write_file(path, out) or {
				w.alert('Save Error', 'Failed to save file: ' + err.str())
				return
			}
			w.toast('Saved to ${path}')
		}
	})

	// Recipe Selection Change
	win.on_change('dd_recipe', fn [all_recipes] (mut w simplegui.SimpleWindow, selected string) {
		for r in all_recipes {
			if selected.contains(r.title) {
				w.set('lbl_recipe_desc', 'Tip: ' + r.desc)
				break
			}
		}
	})

	// Apply Recipe
	win.on_click('btn_apply_recipe', fn [all_recipes] (mut w simplegui.SimpleWindow) {
		selected := w.get('dd_recipe')
		for r in all_recipes {
			if selected.contains(r.title) {
				w.set('txt_find', r.find_pat)
				w.set('txt_replace', r.replace_str)
				w.set('chk_fixed_str', r.fixed_str.str())
				w.set('chk_across', r.across.str())
				w.set('chk_case_insens', r.flags.contains('i').str())
				w.set('chk_word_only', r.flags.contains('w').str())
				w.set('lbl_recipe_desc', 'Tip: ' + r.desc)
				w.toast('Loaded recipe: ' + r.title)
				return
			}
		}
		w.toast('Please select a solution from the dropdown.')
	})

	// Load & Run Recipe Immediately
	win.on_click('btn_run_recipe_now', fn [all_recipes, execute_sd] (mut w simplegui.SimpleWindow) {
		selected := w.get('dd_recipe')
		for r in all_recipes {
			if selected.contains(r.title) {
				w.set('txt_find', r.find_pat)
				w.set('txt_replace', r.replace_str)
				w.set('chk_fixed_str', r.fixed_str.str())
				w.set('chk_across', r.across.str())
				w.set('chk_case_insens', r.flags.contains('i').str())
				w.set('chk_word_only', r.flags.contains('w').str())
				w.set('lbl_recipe_desc', 'Tip: ' + r.desc)
				execute_sd(mut w)
				return
			}
		}
		w.toast('Please select a solution from the dropdown.')
	})

	// Batch In-Place Directory Replace (Async)
	win.on_click('btn_batch_files', fn (mut w simplegui.SimpleWindow) {
		find_str := w.get('txt_find')
		repl_str := w.get('txt_replace')

		if find_str == '' {
			w.alert('Pattern Required', 'Please specify a search pattern first.')
			return
		}

		folder := w.select_folder()
		if folder == '' || !os.is_dir(folder) {
			return
		}

		confirm := w.confirm('Confirm Batch Replacement', 'This will modify matching files inside:\n${folder}\n\nSearch: "${find_str}"\nReplace: "${repl_str}"\n\nProceed?')
		if !confirm {
			return
		}

		sd := get_sd_bin()
		is_fixed := w.get('chk_fixed_str') == 'true'
		is_across := w.get('chk_across') == 'true'
		is_case_i := w.get('chk_case_insens') == 'true'
		is_word := w.get('chk_word_only') == 'true'

		w.set_status('Running batch replacement across folder...')
		w.toast('Batch replacement running...')

		go fn [mut w, sd, folder, find_str, repl_str, is_fixed, is_across, is_case_i, is_word] () {
			files := os.walk_ext(folder, '')
			mut modified := 0

			mut base_args := []string{}
			if is_fixed { base_args << '-F' }
			if is_across { base_args << '-A' }
			if is_case_i || is_word {
				mut f := ''
				if is_case_i { f += 'i' }
				if is_word { f += 'w' }
				base_args << ['-f', f]
			}
			base_args << find_str
			base_args << repl_str

			for f in files {
				ext := os.file_ext(f).to_lower()
				// Only process text and code source files
				if ext in ['.v', '.go', '.rs', '.js', '.ts', '.py', '.c', '.h', '.m', '.json', '.md', '.txt', '.html', '.css', '.env', '.yaml', '.yml', '.toml', '.xml', '.sh'] {
					mut file_args := base_args.clone()
					file_args << f
					res := simplegui.exec_safe(sd, file_args)
					if res.exit_code == 0 {
						modified++
					}
				}
			}

			w.run_on_main_thread(fn [modified, folder] (mut win_main simplegui.SimpleWindow) {
				win_main.set_status('Batch replacement completed: ${modified} files processed.')
				win_main.toast('Batch replacement finished: ${modified} files updated!')
				win_main.alert('Batch Complete', 'Successfully processed ${modified} files in:\n${folder}')
			})
		}()
	})

	// Run SD
	win.on_click('btn_run_sd', fn [execute_sd] (mut w simplegui.SimpleWindow) {
		execute_sd(mut w)
	})

	println('SD Studio Pro configured. Starting event loop...')
	win.run()
}

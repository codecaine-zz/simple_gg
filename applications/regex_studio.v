module main

import os
import time
import simplegui

const sample_test_text = 'Welcome to SimpleGUI Regex Studio Pro v1.4.0 (2026-08-22)!
Contact support at support@simplegui.io or alex.dev@vlang.org for assistance.
Server cluster IP endpoints:
- Node Alpha: 192.168.1.100:8080 (Active)
- Node Beta:  10.0.0.45:443 (Active)
- Node Gamma: 172.16.254.1:9000 (Standby)
Visit documentation at https://github.com/vlang/v and https://vlang.io/docs
User UUID: 550e8400-e29b-41d4-a716-446655440000 | Token: eyJhbGciOiJIUzI1NiJ9.test.sig'

fn run_regex_evaluation(pattern string, text string, case_i bool, multiline bool, dotall bool) string {
	script := '
import re, sys, base64

try:
    pattern = base64.b64decode(sys.argv[1]).decode("utf-8")
    text = base64.b64decode(sys.argv[2]).decode("utf-8")
    case_i = sys.argv[3] == "1"
    multiline = sys.argv[4] == "1"
    dotall = sys.argv[5] == "1"

    flags = 0
    flag_names = []
    if case_i:
        flags |= re.IGNORECASE
        flag_names.append("IGNORECASE (?i)")
    if multiline:
        flags |= re.MULTILINE
        flag_names.append("MULTILINE (?m)")
    if dotall:
        flags |= re.DOTALL
        flag_names.append("DOTALL (?s)")

    rx = re.compile(pattern, flags)
    matches = list(rx.finditer(text))
    
    out = []
    out.append("===================================================")
    out.append("Regex Match Evaluation Report")
    out.append("Pattern: " + pattern)
    out.append("Active Flags: " + (", ".join(flag_names) if flag_names else "None"))
    out.append("Total Matches Found: " + str(len(matches)))
    out.append("===================================================\\n")

    if not matches:
        out.append("No matches found for the given pattern in target text.")
    else:
        for i, m in enumerate(matches, 1):
            full_val = m.group(0)
            out.append("Match #" + str(i) + " (Span: [" + str(m.start()) + ".." + str(m.end()) + "], Length: " + str(len(full_val)) + " chars)")
            out.append("Full Match: \\"" + full_val + "\\"")
            groups = m.groups()
            if groups:
                for g_idx, g_val in enumerate(groups, 1):
                    val_str = "\\"" + str(g_val) + "\\"" if g_val is not None else "(unmatched / None)"
                    out.append("    +- Group $" + str(g_idx) + ": " + val_str)
            groupdict = m.groupdict()
            if groupdict:
                for k, v in groupdict.items():
                    out.append("    +- Named (?P<" + k + ">): \\"" + str(v) + "\\"")
            out.append("")
    print("\\n".join(out))
except re.error as re_err:
    print("Regex Syntax Error: " + str(re_err))
except Exception as e:
    print("Regex Evaluation Error: " + str(e))
'
	tmp_py := os.join_path(os.temp_dir(), 'regex_eval_${time.ticks()}.py')
	os.write_file(tmp_py, script) or { return 'Error writing worker script.' }
	defer { os.rm(tmp_py) or {} }

	b64_pattern := os.execute('python3 -c "import sys, base64; sys.stdout.write(base64.b64encode(sys.argv[1].encode(\'utf-8\')).decode(\'ascii\'))" "${pattern.replace('"', '\\"')}"').output.trim_space()
	b64_text := os.execute('python3 -c "import sys, base64; sys.stdout.write(base64.b64encode(sys.argv[1].encode(\'utf-8\')).decode(\'ascii\'))" "${text.replace('"', '\\"')}"').output.trim_space()

	res := simplegui.exec_safe('python3', [
		tmp_py,
		b64_pattern,
		b64_text,
		if case_i { '1' } else { '0' },
		if multiline { '1' } else { '0' },
		if dotall { '1' } else { '0' },
	])
	return res.output.trim_space()
}

fn run_regex_replacement(pattern string, replacement string, text string, case_i bool, multiline bool, dotall bool) string {
	script := '
import re, sys, base64

try:
    pattern = base64.b64decode(sys.argv[1]).decode("utf-8")
    replacement = base64.b64decode(sys.argv[2]).decode("utf-8")
    text = base64.b64decode(sys.argv[3]).decode("utf-8")
    case_i = sys.argv[4] == "1"
    multiline = sys.argv[5] == "1"
    dotall = sys.argv[6] == "1"

    flags = 0
    if case_i:
        flags |= re.IGNORECASE
    if multiline:
        flags |= re.MULTILINE
    if dotall:
        flags |= re.DOTALL

    # Translate $1, $2 group syntax to \\1, \\2 for python re.sub
    sub_repl = re.sub(r"\\$([0-9]+)", r"\\\\\\1", replacement)

    rx = re.compile(pattern, flags)
    result, count = rx.subn(sub_repl, text)

    out = []
    out.append("===================================================")
    out.append("Regex Substitution Report (" + str(count) + " replacements made)")
    out.append("Pattern: " + pattern)
    out.append("Replacement Template: " + replacement)
    out.append("===================================================\\n")
    out.append(result)
    print("\\n".join(out))
except re.error as re_err:
    print("Regex Syntax Error: " + str(re_err))
except Exception as e:
    print("Substitution Error: " + str(e))
'
	tmp_py := os.join_path(os.temp_dir(), 'regex_sub_${time.ticks()}.py')
	os.write_file(tmp_py, script) or { return 'Error writing worker script.' }
	defer { os.rm(tmp_py) or {} }

	b64_pattern := os.execute('python3 -c "import sys, base64; sys.stdout.write(base64.b64encode(sys.argv[1].encode(\'utf-8\')).decode(\'ascii\'))" "${pattern.replace('"', '\\"')}"').output.trim_space()
	b64_replacement := os.execute('python3 -c "import sys, base64; sys.stdout.write(base64.b64encode(sys.argv[1].encode(\'utf-8\')).decode(\'ascii\'))" "${replacement.replace('"', '\\"')}"').output.trim_space()
	b64_text := os.execute('python3 -c "import sys, base64; sys.stdout.write(base64.b64encode(sys.argv[1].encode(\'utf-8\')).decode(\'ascii\'))" "${text.replace('"', '\\"')}"').output.trim_space()

	res := simplegui.exec_safe('python3', [
		tmp_py,
		b64_pattern,
		b64_replacement,
		b64_text,
		if case_i { '1' } else { '0' },
		if multiline { '1' } else { '0' },
		if dotall { '1' } else { '0' },
	])
	return res.output.trim_space()
}

fn main() {
	println('Starting SimpleGUI - Regex Studio Pro (Interactive Regex Testing Workbench)...')

	mut win := simplegui.new_simple_window('SimpleGUI - Regex Studio Pro', 1080, 950)
	win.set_fullscreen(true)
	win.set_spacing(8)
	win.set_padding(16)

	saved_theme := simplegui.get_saved_theme()
	win.set_theme(saved_theme)

	// Top Banner / Diagnostics
	win.begin_row('row_regex_top')
	win.add_heading('Regex Studio Pro')
	win.add_label('lbl_theme', 'Theme:')
	win.add_dropdown('dd_app_theme', simplegui.list_themes(), saved_theme)
	win.set_control_width('dd_app_theme', 150)
	win.end_row()

	win.on_change('dd_app_theme', fn (mut w simplegui.SimpleWindow, selected string) {
		w.set_theme(selected)
		w.toast('Theme changed to ${selected}')
	})

	win.add_label('lbl_engine_info', 'Engine: High-Performance PCRE2 / Python Regex Engine  |  Platform: macOS Cocoa  |  Mode: Async')

	// Regex Configuration & Pattern Bar
	win.begin_group_box('grp_pattern_config', 'Regular Expression & Substitution Specification')
	
	win.begin_row('row_pattern_input')
	win.add_label('lbl_pattern', 'Regex Pattern:')
	win.add_input('txt_pattern', r'([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})')
	win.set_control_width('txt_pattern', 400)

	win.add_label('lbl_presets', 'Recipes:')
	win.add_dropdown('dd_regex_presets', [
		'1. Email Addresses ([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,})',
		'2. IPv4 Address & Port ((\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}):(\\d+))',
		'3. HTTPS URLs (https?://[^\\s/$.?#].[^\\s]*)',
		'4. Semantic Versioning (v?(\\d+)\\.(\\d+)\\.(\\d+))',
		'5. ISO 8601 Dates ((\\d{4})-(\\d{2})-(\\d{2}))',
		'6. UUID v4 ([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})',
		'7. Hex Color Codes (#[0-9a-fA-F]{6}|#[0-9a-fA-F]{3})',
		'8. Markdown Links (\\[([^\\]]+)\\]\\(([^\\)]+)\\))',
		'9. Key-Value Pairs (([a-zA-Z0-9_]+)\\s*:\\s*([^,\\n]+))'
	], '1. Email Addresses ([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,})')
	win.set_control_width('dd_regex_presets', 320)
	win.end_row()

	win.begin_row('row_subst_input')
	win.add_label('lbl_subst', 'Replacement ($1):')
	win.add_input('txt_replacement', r'REDACTED<$1>')
	win.set_control_width('txt_replacement', 360)

	win.add_checkbox('chk_case_i', 'Case-Insensitive ((?i))', false)
	win.add_checkbox('chk_multiline', 'Multiline ((?m))', true)
	win.add_checkbox('chk_dotall', 'DotAll ((?s))', false)
	win.end_row()

	win.end_group_box()

	// Execution Actions Bar
	win.begin_row('row_actions_1')
	win.add_button('btn_find_matches', 'Find All Matches')
	win.add_button('btn_replace_all', 'Replace / Substitute')
	win.add_button('btn_load_sample', 'Load Sample Text')
	win.end_row()

	win.begin_row('row_actions_2')
	win.add_button('btn_copy_output', 'Copy Matches')
	win.add_button('btn_save_output', 'Save Output...')
	win.add_button('btn_clear_all', 'Clear')
	win.end_row()

	// Dual Pane: Test Input Text & Matches/Substitutions Output
	win.begin_grid('grid_dual_pane', 2, 8)
	win.add_form_textarea('Test Target Text:', 'txt_target_text', sample_test_text)
	win.set_control_height('txt_target_text', 320)
	win.add_form_textarea('Matches & Captured Groups:', 'txt_matches_out', '')
	win.set_control_height('txt_matches_out', 320)
	win.end_grid()

	// Activity & Diagnostics Console
	win.begin_group_box('grp_console', 'Regex Engine Telemetry & Match Statistics')
	win.add_console('regex_console', 110)
	win.end_group_box()

	// Status Row
	win.begin_row('row_stats')
	win.add_label('lbl_stats', 'Stats: Ready  |  Matches Found: 0  |  Duration: 0 ms')
	win.end_row()

	win.append_console('regex_console', ' Regex Studio Pro Initialized.\n', 1)
	win.append_console('regex_console', ' Ready to analyze regex capture groups and text substitutions.\n', 4)

	// -------------------------------------------------------------
	// Event Handlers
	// -------------------------------------------------------------

	// Preset Selection Handler
	win.on_change('dd_regex_presets', fn (mut w simplegui.SimpleWindow, selected string) {
		if selected.starts_with('1.') {
			w.set_text('txt_pattern', r'([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})')
			w.set_text('txt_replacement', r'REDACTED<$1>')
		} else if selected.starts_with('2.') {
			w.set_text('txt_pattern', r'((\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}):(\d+))')
			w.set_text('txt_replacement', r'host=$2 port=$3')
		} else if selected.starts_with('3.') {
			w.set_text('txt_pattern', r'(https?://[^\s/$.?#].[^\s]*)')
			w.set_text('txt_replacement', r'[Link]($1)')
		} else if selected.starts_with('4.') {
			w.set_text('txt_pattern', r'v?(\d+)\.(\d+)\.(\d+)')
			w.set_text('txt_replacement', r'Version(Major=$1, Minor=$2, Patch=$3)')
		} else if selected.starts_with('5.') {
			w.set_text('txt_pattern', r'(\d{4})-(\d{2})-(\d{2})')
			w.set_text('txt_replacement', r'$2/$3/$1')
		} else if selected.starts_with('6.') {
			w.set_text('txt_pattern', r'([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})')
			w.set_text('txt_replacement', r'UUID{$1}')
		} else if selected.starts_with('7.') {
			w.set_text('txt_pattern', r'(#[0-9a-fA-F]{6}|#[0-9a-fA-F]{3})')
			w.set_text('txt_replacement', r'Color($1)')
		} else if selected.starts_with('8.') {
			w.set_text('txt_pattern', r'\[([^\]]+)\]\(([^\)]+)\)')
			w.set_text('txt_replacement', r'<a href="$2">$1</a>')
		} else if selected.starts_with('9.') {
			w.set_text('txt_pattern', r'([a-zA-Z0-9_]+)\s*:\s*([^,\n]+)')
			w.set_text('txt_replacement', r'"$1": "$2"')
		}
		w.toast('Applied regex recipe: ${selected.split("(")[0]}')
	})

	// Load Sample Text
	win.on_click('btn_load_sample', fn (mut w simplegui.SimpleWindow) {
		w.set_text('txt_target_text', sample_test_text)
		w.toast('Sample text loaded.')
	})

	// Find Matches Handler
	win.on_click('btn_find_matches', fn (mut w simplegui.SimpleWindow) {
		pattern_raw := w.get_text('txt_pattern')
		target_text := w.get_text('txt_target_text')
		case_i := w.get_bool('chk_case_i')
		multiline := w.get_bool('chk_multiline')
		dotall := w.get_bool('chk_dotall')

		if pattern_raw.trim_space() == '' {
			w.alert('Pattern Required', 'Please enter a regex pattern to match.')
			return
		}
		if target_text.trim_space() == '' {
			w.alert('Text Required', 'Please enter target text to analyze.')
			return
		}

		w.append_console('regex_console', ' Evaluating pattern: ${pattern_raw}...\n', 1)
		w.set_status('Evaluating regex matches...')

		go fn [mut w, pattern_raw, target_text, case_i, multiline, dotall] () {
			t0 := time.ticks()
			report := run_regex_evaluation(pattern_raw, target_text, case_i, multiline, dotall)
			elapsed_ms := time.ticks() - t0

			w.run_on_main_thread(fn [report, elapsed_ms] (mut win_main simplegui.SimpleWindow) {
				win_main.set_text('txt_matches_out', report)
				match_cnt := report.count('Match #')
				if !report.starts_with('') {
					win_main.append_console('regex_console', ' Found ${match_cnt} regex matches in ${elapsed_ms} ms.\n', 4)
					win_main.set_text('lbl_stats', ' Stats: SUCCESS  |  Matches: ${match_cnt}  |  Duration: ${elapsed_ms} ms')
					win_main.set_status('Found ${match_cnt} matches in ${elapsed_ms} ms.')
					win_main.toast('Found ${match_cnt} matches!')
				} else {
					win_main.append_console('regex_console', report + '\n', 3)
					win_main.set_text('lbl_stats', ' Stats: REGEX ERROR  |  Duration: ${elapsed_ms} ms')
					win_main.set_status('Regex evaluation error.')
				}
			})
		}()
	})

	// Replace / Substitute Handler
	win.on_click('btn_replace_all', fn (mut w simplegui.SimpleWindow) {
		pattern_raw := w.get_text('txt_pattern')
		replacement := w.get_text('txt_replacement')
		target_text := w.get_text('txt_target_text')
		case_i := w.get_bool('chk_case_i')
		multiline := w.get_bool('chk_multiline')
		dotall := w.get_bool('chk_dotall')

		if pattern_raw.trim_space() == '' {
			w.alert('Pattern Required', 'Please enter a regex pattern to substitute.')
			return
		}

		w.append_console('regex_console', ' Performing substitution with: ${replacement}...\n', 1)
		w.set_status('Executing substitution...')

		go fn [mut w, pattern_raw, replacement, target_text, case_i, multiline, dotall] () {
			t0 := time.ticks()
			report := run_regex_replacement(pattern_raw, replacement, target_text, case_i, multiline, dotall)
			elapsed_ms := time.ticks() - t0

			w.run_on_main_thread(fn [report, elapsed_ms] (mut win_main simplegui.SimpleWindow) {
				win_main.set_text('txt_matches_out', report)
				if !report.starts_with('') {
					win_main.append_console('regex_console', ' Substitution complete in ${elapsed_ms} ms.\n', 4)
					win_main.set_text('lbl_stats', ' Stats: SUBSTITUTION COMPLETE  |  Duration: ${elapsed_ms} ms')
					win_main.set_status('Substitution completed.')
					win_main.toast('Substitution complete!')
				} else {
					win_main.append_console('regex_console', report + '\n', 3)
					win_main.set_text('lbl_stats', ' Stats: SUBSTITUTION ERROR  |  Duration: ${elapsed_ms} ms')
					win_main.set_status('Substitution error.')
				}
			})
		}()
	})

	// Copy Matches
	win.on_click('btn_copy_output', fn (mut w simplegui.SimpleWindow) {
		out := w.get_text('txt_matches_out')
		if out != '' {
			w.copy_to_clipboard(out)
			w.toast('Matches copied to clipboard!')
		} else {
			w.toast('No output to copy.')
		}
	})

	// Save Output
	win.on_click('btn_save_output', fn (mut w simplegui.SimpleWindow) {
		out := w.get_text('txt_matches_out')
		if out.trim_space() == '' {
			w.toast('No output to save.')
			return
		}
		path := w.save_file_picker()
		if path != '' {
			mut save_file := path
			if !save_file.ends_with('.txt') { save_file += '.txt' }
			os.write_file(save_file, out) or {
				w.toast('Failed to save file.')
				return
			}
			w.toast('Saved to ${os.file_name(save_file)}')
			w.append_console('regex_console', ' Saved output to: ${save_file}\n', 1)
		}
	})

	// Clear All
	win.on_click('btn_clear_all', fn (mut w simplegui.SimpleWindow) {
		w.set_text('txt_target_text', '')
		w.set_text('txt_matches_out', '')
		w.clear_console('regex_console')
		w.toast('Cleared workspace.')
	})

	win.start()
}

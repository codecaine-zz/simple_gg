module main

import os
import time
import simplegui

// Helper to find gawk and awk paths (Homebrew and PATH)
fn get_gawk_bin() string {
	if path := os.find_abs_path_of_executable('gawk') {
		return path
	}
	common_paths := [
		'/opt/homebrew/bin/gawk',
		'/usr/local/bin/gawk',
		'/usr/bin/awk',
		'/bin/awk',
	]
	for p in common_paths {
		if os.exists(p) {
			return p
		}
	}
	return 'gawk'
}

struct OneLiner {
	title    string
	category string
	fs       string
	script   string
	desc     string
}

fn get_all_one_liners() []OneLiner {
	return [
		// 1. Column & Field Operations
		OneLiner{
			title: 'Print Column 1 and Last Column ($1, $NF)'
			category: 'Columns & Fields'
			fs: ', (Comma - CSV)'
			script: '{ print $1, $NF }'
			desc: 'Prints the very first field and the last dynamic field on each record.'
		},
		OneLiner{
			title: 'Print 2nd to Last Column ($(NF-1))'
			category: 'Columns & Fields'
			fs: ', (Comma - CSV)'
			script: 'NF >= 2 { print $(NF-1) }'
			desc: 'Extracts the penultimate field before the end of the record.'
		},
		OneLiner{
			title: 'Swap Column 1 and Column 2 ($1 <-> $2)'
			category: 'Columns & Fields'
			fs: ', (Comma - CSV)'
			script: 'BEGIN { FS=","; OFS="," }\n{\n    t = $1; $1 = $2; $2 = t; print\n}'
			desc: 'Swaps the positions of the first and second columns.'
		},
		OneLiner{
			title: 'Delete First Column ($1 = "")'
			category: 'Columns & Fields'
			fs: ', (Comma - CSV)'
			script: '{\n    $1 = ""; sub("^[[:space:],]+", ""); print\n}'
			desc: 'Removes the first column from all rows.'
		},
		OneLiner{
			title: 'Delete Last Column (NF--)'
			category: 'Columns & Fields'
			fs: ', (Comma - CSV)'
			script: '{\n    NF--; print\n}'
			desc: 'Decrements total field count to discard the last column.'
		},
		OneLiner{
			title: 'Print Fields in Reverse Order'
			category: 'Columns & Fields'
			fs: '[[:space:]]+ (Whitespace / Columns)'
			script: '{\n    for (i=NF; i>0; i--) printf "%s%s", $i, (i>1 ? OFS : ORS)\n}'
			desc: 'Loops backwards from NF to 1, outputting columns in inverted sequence.'
		},
		OneLiner{
			title: 'Print Line with Field Count (NF: $0)'
			category: 'Columns & Fields'
			fs: ', (Comma - CSV)'
			script: '{ printf "[Fields: %2d] %s\\n", NF, $0 }'
			desc: 'Prefixes each record with the number of delimited fields detected.'
		},
		OneLiner{
			title: 'Filter Lines with exactly N fields (NF == 5)'
			category: 'Columns & Fields'
			fs: ', (Comma - CSV)'
			script: 'NF == 5'
			desc: 'Extracts only rows that have exactly 5 columns.'
		},

		// 2. Line Numbering & Slicing
		OneLiner{
			title: 'Print Total Line Count (NR)'
			category: 'Lines & Slicing'
			fs: ', (Comma - CSV)'
			script: 'END { print "Total Lines:", NR }'
			desc: 'Counts total number of input records processed.'
		},
		OneLiner{
			title: 'Number Every Line (NR: line)'
			category: 'Lines & Slicing'
			fs: ', (Comma - CSV)'
			script: '{ printf "%4d | %s\\n", NR, $0 }'
			desc: 'Formats line numbers right-aligned with pipe delimiter.'
		},
		OneLiner{
			title: 'Number Non-Empty Lines Only'
			category: 'Lines & Slicing'
			fs: ', (Comma - CSV)'
			script: 'NF { $0 = sprintf("%4d | %s", ++c, $0) } 1'
			desc: 'Numbers valid records while ignoring blank lines.'
		},
		OneLiner{
			title: 'Head: Print First 10 Lines (NR <= 10)'
			category: 'Lines & Slicing'
			fs: ', (Comma - CSV)'
			script: 'NR <= 10'
			desc: 'Emulates head -n 10 efficiently.'
		},
		OneLiner{
			title: 'Slice Range: Lines 10 to 25'
			category: 'Lines & Slicing'
			fs: ', (Comma - CSV)'
			script: 'NR >= 10 && NR <= 25'
			desc: 'Extracts a specific slice of lines by line number range.'
		},
		OneLiner{
			title: 'Tail: Print Last Line'
			category: 'Lines & Slicing'
			fs: ', (Comma - CSV)'
			script: 'END { print $0 }'
			desc: 'Outputs the final line of the input stream.'
		},
		OneLiner{
			title: 'Print Every 2nd Line (Even Lines)'
			category: 'Lines & Slicing'
			fs: ', (Comma - CSV)'
			script: 'NR % 2 == 0'
			desc: 'Filters only lines with even record numbers.'
		},
		OneLiner{
			title: 'Delete All Blank / Empty Lines'
			category: 'Lines & Slicing'
			fs: ', (Comma - CSV)'
			script: 'NF > 0'
			desc: 'Removes all empty lines from text stream.'
		},
		OneLiner{
			title: 'Double-Space Entire Text'
			category: 'Lines & Slicing'
			fs: ', (Comma - CSV)'
			script: '{ print $0 "\\n" }'
			desc: 'Inserts an extra blank newline after every line.'
		},

		// 3. Filtering & Searching
		OneLiner{
			title: 'Case-Insensitive Match (tolower ~ /pattern/)'
			category: 'Filter & Search'
			fs: ', (Comma - CSV)'
			script: 'tolower($0) ~ /engineering/'
			desc: 'Performs case-insensitive regex search across lines.'
		},
		OneLiner{
			title: 'Exclude Lines Matching Pattern (!/pattern/)'
			category: 'Filter & Search'
			fs: ', (Comma - CSV)'
			script: '!/Leave/'
			desc: 'Inverse filter: prints only lines NOT matching pattern.'
		},
		OneLiner{
			title: 'Numeric Filter: Field 4 > 100000'
			category: 'Filter & Search'
			fs: ', (Comma - CSV)'
			script: 'NR > 1 && $4 > 100000'
			desc: 'Extracts records where column 4 value exceeds 100,000.'
		},
		OneLiner{
			title: 'Exact Field Match: Field 5 == "Active"'
			category: 'Filter & Search'
			fs: ', (Comma - CSV)'
			script: 'NR == 1 || $5 == "Active"'
			desc: 'Includes header row plus rows where column 5 equals "Active".'
		},
		OneLiner{
			title: 'Print Range Between Two Patterns'
			category: 'Filter & Search'
			fs: ', (Comma - CSV)'
			script: '/Engineering/, /Finance/'
			desc: 'Outputs all lines from first occurrence of pattern A until pattern B.'
		},
		OneLiner{
			title: 'Filter Lines Longer Than 50 Chars'
			category: 'Filter & Search'
			fs: ', (Comma - CSV)'
			script: 'length($0) > 50'
			desc: 'Finds long lines exceeding 50 characters in length.'
		},

		// 4. Math & Statistics
		OneLiner{
			title: 'Sum Column Values ({ sum += $4 })'
			category: 'Math & Stats'
			fs: ', (Comma - CSV)'
			script: 'NR > 1 { sum += $4 }\nEND { print "TOTAL SUM:", sum }'
			desc: 'Calculates the sum of all values in column 4.'
		},
		OneLiner{
			title: 'Calculate Column Average (Mean)'
			category: 'Math & Stats'
			fs: ', (Comma - CSV)'
			script: 'NR > 1 && $4 != "" {\n    sum += $4; count++\n}\nEND {\n    print "COUNT:  ", count\n    print "SUM:    ", sum\n    print "AVERAGE:", (count ? sum/count : 0)\n}'
			desc: 'Computes count, total sum, and average mean for column.'
		},
		OneLiner{
			title: 'Find Maximum & Minimum in Column'
			category: 'Math & Stats'
			fs: ', (Comma - CSV)'
			script: 'NR == 2 { max = min = $4 }\nNR > 2 && $4 != "" {\n    if ($4 > max) max = $4\n    if ($4 < min) min = $4\n}\nEND {\n    print "MAX:", max\n    print "MIN:", min\n}'
			desc: 'Finds highest and lowest values across column 4.'
		},
		OneLiner{
			title: 'Group Sum by Department ({ total[$3] += $4 })'
			category: 'Math & Stats'
			fs: ', (Comma - CSV)'
			script: 'NR > 1 {\n    total[$3] += $4\n    count[$3]++\n}\nEND {\n    print "DEPARTMENT", "HEADCOUNT", "TOTAL_BUDGET", "AVG_SALARY"\n    print "----------------------------------------------------"\n    for (dept in total) {\n        avg = count[dept] ? total[dept]/count[dept] : 0\n        printf "%-15s %-10d $%-12.2f $%.2f\\n", dept, count[dept], total[dept], avg\n    }\n}'
			desc: 'Aggregates totals, headcounts, and averages grouped by column 3.'
		},
		OneLiner{
			title: 'Count Total Lines, Words & Characters'
			category: 'Math & Stats'
			fs: ', (Comma - CSV)'
			script: '{\n    words += NF\n    chars += length($0) + 1\n}\nEND {\n    print "Lines:     ", NR\n    print "Words:     ", words\n    print "Characters:", chars\n}'
			desc: 'Complete text telemetry counting lines, words, and characters.'
		},

		// 5. Deduplication & Sets
		OneLiner{
			title: 'Remove Duplicate Lines - Preserve Order (!seen[$0]++)'
			category: 'Deduplication'
			fs: ', (Comma - CSV)'
			script: '!seen[$0]++'
			desc: 'Removes duplicate lines while preserving original row order.'
		},
		OneLiner{
			title: 'Remove Duplicate Lines by Field ($2)'
			category: 'Deduplication'
			fs: ', (Comma - CSV)'
			script: '!seen[$2]++'
			desc: 'Ensures only the first occurrence of each value in field 2 is kept.'
		},
		OneLiner{
			title: 'Print Only Duplicate Lines (seen[$0]++ == 1)'
			category: 'Deduplication'
			fs: ', (Comma - CSV)'
			script: 'seen[$0]++ == 1'
			desc: 'Finds and prints only duplicate entries in the data stream.'
		},
		OneLiner{
			title: 'Histogram / Frequency Count of Values'
			category: 'Deduplication'
			fs: ', (Comma - CSV)'
			script: 'NR > 1 { freq[$3]++ }\nEND {\n    print "CATEGORY", "OCCURRENCES"\n    print "------------------------"\n    for (item in freq) {\n        printf "%-15s %d\\n", item, freq[item]\n    }\n}'
			desc: 'Generates frequency table of values in department column.'
		},

		// 6. String Transformations
		OneLiner{
			title: 'Convert Entire Text to UPPERCASE'
			category: 'Text Transforms'
			fs: ', (Comma - CSV)'
			script: '{ print toupper($0) }'
			desc: 'Converts all letters across all records to uppercase.'
		},
		OneLiner{
			title: 'Convert Entire Text to lowercase'
			category: 'Text Transforms'
			fs: ', (Comma - CSV)'
			script: '{ print tolower($0) }'
			desc: 'Converts all letters across all records to lowercase.'
		},
		OneLiner{
			title: 'Capitalize First Letter of Every Word'
			category: 'Text Transforms'
			fs: '[[:space:]]+ (Whitespace / Columns)'
			script: '{\n    for (i=1; i<=NF; i++) {\n        $i = toupper(substr($i, 1, 1)) tolower(substr($i, 2))\n    }\n    print\n}'
			desc: 'Converts text into Title Case capitalization.'
		},
		OneLiner{
			title: 'Trim Leading and Trailing Whitespace'
			category: 'Text Transforms'
			fs: ', (Comma - CSV)'
			script: '{\n    gsub(/^[[:space:]]+|[[:space:]]+$/, "");\n    print\n}'
			desc: 'Strips unwanted spaces and tabs from beginning and end of lines.'
		},
		OneLiner{
			title: 'Global Search and Replace (gsub)'
			category: 'Text Transforms'
			fs: ', (Comma - CSV)'
			script: '{\n    gsub(/Active/, "CONFIRMED");\n    print\n}'
			desc: 'Replaces all occurrences of pattern with replacement string.'
		},
		OneLiner{
			title: 'Reverse Characters in Every Line'
			category: 'Text Transforms'
			fs: ', (Comma - CSV)'
			script: '{\n    for (i=length($0); i>0; i--) printf "%s", substr($0, i, 1)\n    print ""\n}'
			desc: 'Reverses string character-by-character per line.'
		},

		// 7. Format Conversions
		OneLiner{
			title: 'Convert CSV to TSV'
			category: 'Format Conversions'
			fs: ', (Comma - CSV)'
			script: 'BEGIN { FS=","; OFS="\\t" }\n{\n    $1 = $1; print\n}'
			desc: 'Rewrites CSV data into Tab-Separated Values format.'
		},
		OneLiner{
			title: 'Convert TSV to CSV'
			category: 'Format Conversions'
			fs: '\\t (Tab - TSV)'
			script: 'BEGIN { FS="\\t"; OFS="," }\n{\n    $1 = $1; print\n}'
			desc: 'Rewrites TSV data into Comma-Separated Values format.'
		},
		OneLiner{
			title: 'Convert CSV to Markdown Table'
			category: 'Format Conversions'
			fs: ', (Comma - CSV)'
			script: 'BEGIN { FS="," }\nNR == 1 {\n    printf "| %-15s | %-15s | %-12s |\\n", $2, $3, $4\n    printf "|-%-15s-|-%-15s-|-%-12s-|\\n", "---------------", "---------------", "------------"\n    next\n}\n{\n    printf "| %-15s | %-15s | %-12s |\\n", $2, $3, "$" $4\n}'
			desc: 'Generates formatted Markdown table with column headers and dividers.'
		},
		OneLiner{
			title: 'Convert CSV to JSON Objects Array'
			category: 'Format Conversions'
			fs: ', (Comma - CSV)'
			script: 'BEGIN { FS=","; print "[" }\nNR == 1 {\n    h1=$1; h2=$2; h3=$3; h4=$4; h5=$5; next\n}\n{\n    printf "  { \\"%s\\": %s, \\"%s\\": \\"%s\\", \\"%s\\": \\"%s\\", \\"%s\\": %s, \\"%s\\": \\"%s\\" }%s\\n",\n           h1, $1, h2, $2, h3, $3, h4, $4, h5, $5, (NR > 2 ? "," : "")\n}\nEND { print "]" }'
			desc: 'Converts CSV rows into clean structured JSON array of objects.'
		},
		OneLiner{
			title: 'Format Lines as SQL IN (...) Clause'
			category: 'Format Conversions'
			fs: ', (Comma - CSV)'
			script: 'BEGIN { printf "(" }\nNR > 1 {\n    printf "%s\'%s\'", (NR > 2 ? ", " : ""), $2\n}\nEND { print ")" }'
			desc: 'Packages column values into SQL IN (\'Val1\', \'Val2\') list.'
		},

		// 8. Logs & Network Analytics
		OneLiner{
			title: 'Top IP Addresses in Web Log (count[$1]++)'
			category: 'Logs & Network'
			fs: '[[:space:]]+ (Whitespace / Columns)'
			script: '{\n    ip = $1\n    count[ip]++\n}\nEND {\n    print "HITS", "IP_ADDRESS"\n    print "------------------------"\n    for (i in count) {\n        printf "%-6d %s\\n", count[i], i\n    }\n}'
			desc: 'Aggregates requests per client IP address in Nginx/Apache log.'
		},
		OneLiner{
			title: 'Count HTTP Status Codes in Web Log (count[$9]++)'
			category: 'Logs & Network'
			fs: '[[:space:]]+ (Whitespace / Columns)'
			script: '{\n    code = $9\n    if (code != "") count[code]++\n}\nEND {\n    print "HTTP_CODE", "REQUEST_COUNT"\n    print "------------------------"\n    for (c in count) {\n        printf "HTTP %-5s %d hits\\n", c, count[c]\n    }\n}'
			desc: 'Counts occurrences of HTTP response codes (200, 404, 500).'
		},
		OneLiner{
			title: 'Extract Usernames & Shells from /etc/passwd'
			category: 'Logs & Network'
			fs: ': (Colon - Passwd / Config)'
			script: 'BEGIN { FS=":"; OFS="\\t"; print "USERNAME", "UID", "SHELL" }\n$3 >= 0 {\n    print $1, $3, $7\n}'
			desc: 'Parses system accounts from /etc/passwd table.'
		},
		OneLiner{
			title: 'Filter Human Users Only (UID >= 1000 in passwd)'
			category: 'Logs & Network'
			fs: ': (Colon - Passwd / Config)'
			script: 'BEGIN { FS=":"; OFS="\\t"; print "USER", "UID", "HOME_DIR" }\n$3 >= 1000 && $3 < 65534 {\n    print $1, $3, $6\n}'
			desc: 'Filters real interactive user accounts on UNIX/macOS system.'
		},
		OneLiner{
			title: 'Extract All URLs / Links from Text'
			category: 'Logs & Network'
			fs: '[[:space:]]+ (Whitespace / Columns)'
			script: '{\n    for (i=1; i<=NF; i++) {\n        if ($i ~ /^https?:\\/\\//) {\n            gsub(/[",]/, "", $i)\n            print $i\n        }\n    }\n}'
			desc: 'Extracts all http:// and https:// URLs from document.'
		},
	]
}

// Built-in sample datasets
fn get_sample_csv() string {
	return 'id,name,department,salary,status
101,Alice Johnson,Engineering,135000,Active
102,Bob Smith,Marketing,82000,Active
103,Charlie Brown,Engineering,142000,Active
104,Diana Prince,Sales,95000,Leave
105,Evan Wright,Engineering,128000,Active
106,Fiona Gallagher,Marketing,89000,Active
107,George Clark,Finance,115000,Active
108,Hannah Abbott,Sales,102000,Active
109,Ian Malcolm,Engineering,165000,Active
110,Julia Roberts,Finance,118000,Leave'
}

fn get_sample_nginx_log() string {
	return '192.168.1.45 - - [21/Aug/2026:14:32:10 +0000] "GET /api/v1/users HTTP/1.1" 200 4520 "https://app.io" "Mozilla/5.0"
10.0.0.12 - - [21/Aug/2026:14:32:11 +0000] "POST /api/v1/auth/login HTTP/1.1" 401 128 "https://app.io" "Mozilla/5.0"
192.168.1.45 - - [21/Aug/2026:14:32:15 +0000] "GET /api/v1/dashboard HTTP/1.1" 200 12800 "https://app.io" "Mozilla/5.0"
172.16.0.88 - - [21/Aug/2026:14:32:18 +0000] "GET /static/bundle.js HTTP/1.1" 304 0 "https://app.io" "Mozilla/5.0"
10.0.0.12 - - [21/Aug/2026:14:32:20 +0000] "POST /api/v1/auth/login HTTP/1.1" 200 890 "https://app.io" "Mozilla/5.0"
198.51.100.2 - - [21/Aug/2026:14:32:25 +0000] "GET /admin/db.php HTTP/1.1" 404 312 "-" "Python-urllib/3.9"
192.168.1.99 - - [21/Aug/2026:14:32:30 +0000] "GET /api/v1/reports HTTP/1.1" 500 240 "https://app.io" "Mozilla/5.0"
198.51.100.2 - - [21/Aug/2026:14:32:35 +0000] "GET /wp-login.php HTTP/1.1" 404 312 "-" "curl/7.68.0"'
}

fn get_sample_passwd() string {
	return 'root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
bin:x:2:2:bin:/bin:/usr/sbin/nologin
sys:x:3:3:sys:/dev:/usr/sbin/nologin
sync:x:4:65534:sync:/bin:/bin/sync
developer:x:1000:1000:Ada Lovelace,,,:/home/developer:/bin/zsh
guest:x:1001:1001:Guest User:/home/guest:/bin/bash
postgres:x:105:111:PostgreSQL server,,,:/var/lib/postgresql:/bin/bash
redis:x:106:112:Redis In-Memory Store:/var/lib/redis:/usr/sbin/nologin'
}

fn main() {
	println('Starting SimpleGUI - GAWK Studio Pro (Complete One-Liner Suite)...')

	mut win := simplegui.new_simple_window('SimpleGUI - GAWK Studio Pro', 1000, 920)
	win.set_fullscreen(true)
	win.set_spacing(8)
	win.set_padding(16)

	saved_theme := simplegui.get_saved_theme()
	win.set_theme(saved_theme)

	// Top Banner / Status
	win.begin_row('row_gawk_top')
	win.add_heading('GAWK Studio Pro')
	win.add_label('lbl_theme', 'Theme:')
	win.add_dropdown('dd_app_theme', simplegui.list_themes(), saved_theme)
	win.set_control_width('dd_app_theme', 150)
	win.end_row()

	win.on_change('dd_app_theme', fn (mut w simplegui.SimpleWindow, selected string) {
		w.set_theme(selected)
		w.toast('Theme changed to ${selected}')
	})
	gawk_path := get_gawk_bin()
	win.add_label('lbl_engine_info', 'Engine: ${gawk_path}  |  Platform: macOS Cocoa  |  Mode: Async Worker')

	all_recipes := get_all_one_liners()

	// -------------------------------------------------------------
	// Input Data Source & Configuration Bar
	// -------------------------------------------------------------
	win.begin_group_box('grp_config', 'Input Source & Delimiter Settings')
	
	win.begin_row('row_delimiters')
	win.add_label('lbl_fs', 'Field Separator (-F):')
	win.add_dropdown('dd_fs', [
		', (Comma - CSV)',
		'\\t (Tab - TSV)',
		'[[:space:]]+ (Whitespace / Columns)',
		': (Colon - Passwd / Config)',
		'| (Pipe Delimited)',
		'; (Semicolon)',
		'Custom Delimiter'
	], ', (Comma - CSV)')
	win.add_label('lbl_custom_fs', 'Custom FS:')
	win.add_input('txt_custom_fs', '')
	win.set_control_width('txt_custom_fs', 60)
	
	win.add_label('lbl_ofs', 'Output Separator (OFS):')
	win.add_dropdown('dd_ofs', [', (Comma)', '\\t (Tab)', ' | (Padded Pipe)', '  (Two Spaces)', 'Custom OFS'], '\\t (Tab)')
	win.end_row()

	win.begin_row('row_sample_loader')
	win.add_label('lbl_samples', 'Quick Presets & Sample Data:')
	win.add_button('btn_load_csv', 'Load Sample CSV')
	win.add_button('btn_load_log', 'Load Nginx Web Log')
	win.add_button('btn_load_passwd', 'Load /etc/passwd')
	win.add_button('btn_browse_in_file', 'Load File from Disk...')
	win.add_button('btn_paste_in', 'Paste Clipboard')
	win.add_button('btn_clear_in', 'Clear Input')
	win.end_row()

	win.end_group_box()

	// -------------------------------------------------------------
	// Dual Pane: Input Text & GAWK Script
	// -------------------------------------------------------------
	win.begin_group_box('grp_input_pane', 'Input Data Stream (Raw text, CSV, TSV, logs, or structured records)')
	win.add_textarea('txt_input_data', get_sample_csv())
	win.set_control_height('txt_input_data', 140)
	win.end_group_box()

	// -------------------------------------------------------------
	// Exhaustive AWK One-Liner Library & Recipe Selector
	// -------------------------------------------------------------
	win.begin_group_box('grp_presets', 'Ultimate AWK One-Liner Library (40+ Recipes by Category)')
	
	mut recipe_titles := ['-- Select a Classic AWK One-Liner --']
	for r in all_recipes {
		recipe_titles << '[${r.category}] ' + r.title
	}

	win.begin_row('row_recipes')
	win.add_label('lbl_recipe', 'Select One-Liner:')
	win.add_dropdown('dd_recipe', recipe_titles, recipe_titles[0])
	win.set_control_width('dd_recipe', 520)
	win.add_button('btn_apply_recipe', 'Insert Recipe')
	win.add_button('btn_run_recipe_now', 'Insert & Run')
	win.end_row()

	win.begin_row('row_recipe_desc')
	win.add_label('lbl_recipe_desc', 'Tip: Pick any one-liner above and click "Insert & Run" for instantaneous results.')
	win.end_row()
	win.end_group_box()

	// -------------------------------------------------------------
	// Script Editor Pane
	// -------------------------------------------------------------
	win.begin_group_box('grp_script', 'GAWK Script Program (BEGIN / Pattern { Action } / END)')
	default_script := '# Extract columns and calculate department total\nBEGIN { FS=","; OFS="\\t"; print "NAME", "DEPARTMENT", "SALARY" }\nNR > 1 && $4 > 100000 { \n    print $2, $3, "$" $4 \n    total += $4\n    count++\n}\nEND { \n    print "----------------------------------------"\n    print "TOTAL:", count " employees", "$" total \n    print "AVERAGE:", "$" (count ? total/count : 0)\n}'
	win.add_textarea('txt_awk_script', default_script)
	win.set_control_height('txt_awk_script', 125)
	win.end_group_box()

	// -------------------------------------------------------------
	// Actions & Live Execution Bar
	// -------------------------------------------------------------
	win.begin_row('row_actions')
	win.add_button('btn_run_awk', 'Run GAWK Program')
	win.add_button('btn_copy_output', 'Copy Result')
	win.add_button('btn_save_output', 'Save Output to File...')
	win.add_button('btn_file_stream', 'Process Massive File on Disk...')
	win.add_button('btn_clear_out', 'Clear Output')
	win.end_row()

	// -------------------------------------------------------------
	// Output Pane & Statistics Banner
	// -------------------------------------------------------------
	win.begin_group_box('grp_output', 'Processed Output Stream & Results')
	win.add_textarea('txt_output_data', '')
	win.set_control_height('txt_output_data', 150)
	win.end_group_box()

	// Stats Row
	win.begin_row('row_stats')
	win.add_label('lbl_exec_stats', 'Stats: Ready  |  Lines: 0  |  Duration: 0 ms  |  Output Size: 0 bytes')
	win.end_row()

	// -------------------------------------------------------------
	// Core Execution Helper Function
	// -------------------------------------------------------------
	execute_gawk_program := fn (mut win simplegui.SimpleWindow) {
		input_text := win.get('txt_input_data')
		script := win.get('txt_awk_script').trim_space()

		if script == '' {
			win.alert('Script Empty', 'Please provide an AWK script to run.')
			return
		}

		gawk := get_gawk_bin()
		
		fs_sel := win.get('dd_fs')
		mut raw_fs := ''
		if fs_sel.contains('Comma') { raw_fs = ',' }
		else if fs_sel.contains('Tab') { raw_fs = '\t' }
		else if fs_sel.contains('Colon') { raw_fs = ':' }
		else if fs_sel.contains('Pipe') { raw_fs = '|' }
		else if fs_sel.contains('Semicolon') { raw_fs = ';' }
		else if win.get('txt_custom_fs') != '' { raw_fs = win.get('txt_custom_fs') }

		win.set_status('Executing GAWK program in background...')
		win.toast('Running GAWK...')

		go fn [mut win, gawk, raw_fs, script, input_text] () {
			t0 := time.ticks()
			
			tmp_in := os.join_path(os.temp_dir(), 'gawk_studio_in_${time.ticks()}.txt')
			tmp_scr := os.join_path(os.temp_dir(), 'gawk_studio_scr_${time.ticks()}.awk')
			
			os.write_file(tmp_in, input_text) or {}
			os.write_file(tmp_scr, script) or {}

			mut raw_args := []string{}
			if raw_fs != '' {
				raw_args << ['-F', raw_fs]
			}
			raw_args << ['-f', tmp_scr]
			raw_args << tmp_in

			res := simplegui.exec_safe(gawk, raw_args)
			elapsed_ms := time.ticks() - t0

			if os.exists(tmp_in) { os.rm(tmp_in) or {} }
			if os.exists(tmp_scr) { os.rm(tmp_scr) or {} }

			win.run_on_main_thread(fn [res, elapsed_ms] (mut win_main simplegui.SimpleWindow) {
				if res.exit_code == 0 {
					out_str := res.output
					win_main.set('txt_output_data', out_str)
					lines := out_str.count('\n')
					bytes := out_str.len
					win_main.set('lbl_exec_stats', ' Stats: SUCCESS  |  Lines: ${lines}  |  Duration: ${elapsed_ms} ms  |  Output: ${bytes} bytes')
					win_main.set_status('GAWK program executed successfully in ${elapsed_ms} ms.')
					win_main.toast('Completed in ${elapsed_ms} ms (${lines} lines generated)!')
				} else {
					win_main.set('txt_output_data', ' GAWK Execution Error:\n\n' + res.output)
					win_main.set('lbl_exec_stats', ' Stats: ERROR (Exit code ${res.exit_code})  |  Duration: ${elapsed_ms} ms')
					win_main.set_status('GAWK reported a syntax or runtime error.')
				}
			})
		}()
	}

	// -------------------------------------------------------------
	// Event Handlers
	// -------------------------------------------------------------

	// Load Sample CSV
	win.on_click('btn_load_csv', fn (mut w simplegui.SimpleWindow) {
		w.set('txt_input_data', get_sample_csv())
		w.set_text('dd_fs', ', (Comma - CSV)')
		w.toast('Sample employee CSV loaded.')
	})

	// Load Sample Nginx Log
	win.on_click('btn_load_log', fn (mut w simplegui.SimpleWindow) {
		w.set('txt_input_data', get_sample_nginx_log())
		w.set_text('dd_fs', '[[:space:]]+ (Whitespace / Columns)')
		w.set('txt_awk_script', '# Count HTTP Status Codes in Nginx Access Log\n{\n    status = $9\n    if (status != "") count[status]++\n}\nEND {\n    print "HTTP_CODE", "REQUEST_COUNT"\n    print "------------------------"\n    for (s in count) {\n        printf "%-10s %d\\n", s, count[s]\n    }\n}')
		w.toast('Sample Nginx access log loaded with status-counting script.')
	})

	// Load Sample /etc/passwd
	win.on_click('btn_load_passwd', fn (mut w simplegui.SimpleWindow) {
		w.set('txt_input_data', get_sample_passwd())
		w.set_text('dd_fs', ': (Colon - Passwd / Config)')
		w.set('txt_awk_script', 'BEGIN { FS=":"; OFS="\\t"; print "USERNAME", "UID", "DEFAULT_SHELL" }\n$3 >= 0 {\n    print $1, $3, $7\n}\nEND {\n    print "Total accounts:", NR\n}')
		w.toast('Sample /etc/passwd loaded.')
	})

	// Load File from Disk
	win.on_click('btn_browse_in_file', fn (mut w simplegui.SimpleWindow) {
		path := w.select_file()
		if path != '' && os.exists(path) {
			size_bytes := os.file_size(path)
			if size_bytes > 5 * 1024 * 1024 {
				w.toast('Large file detected (>5MB). Reading first 5,000 lines into editor...')
				content := os.read_file(path) or { '' }
				lines := content.split_into_lines()
				sample_lines := if lines.len > 5000 { lines[..5000].join('\n') } else { content }
				w.set('txt_input_data', sample_lines)
			} else {
				content := os.read_file(path) or { '' }
				w.set('txt_input_data', content)
				w.toast('Loaded ${path} (${size_bytes} bytes).')
			}
		}
	})

	// Paste Clipboard to Input
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

	// Copy Output to Clipboard
	win.on_click('btn_copy_output', fn (mut w simplegui.SimpleWindow) {
		out := w.get('txt_output_data')
		if out != '' {
			w.copy_to_clipboard(out)
			w.toast('Output copied to clipboard!')
		} else {
			w.toast('No output to copy.')
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

	// Dropdown recipe selection change
	win.on_change('dd_recipe', fn [all_recipes] (mut w simplegui.SimpleWindow, selected string) {
		for r in all_recipes {
			if selected.contains(r.title) {
				w.set('lbl_recipe_desc', 'Tip: ' + r.desc)
				break
			}
		}
	})

	// Apply Recipe Template
	win.on_click('btn_apply_recipe', fn [all_recipes] (mut w simplegui.SimpleWindow) {
		selected := w.get('dd_recipe')
		for r in all_recipes {
			if selected.contains(r.title) {
				w.set('txt_awk_script', r.script)
				w.set_text('dd_fs', r.fs)
				w.set('lbl_recipe_desc', 'Tip: ' + r.desc)
				w.toast('Inserted recipe: ' + r.title)
				return
			}
		}
		w.toast('Please select a recipe from the dropdown.')
	})

	// Insert & Run Immediately
	win.on_click('btn_run_recipe_now', fn [all_recipes, execute_gawk_program] (mut w simplegui.SimpleWindow) {
		selected := w.get('dd_recipe')
		for r in all_recipes {
			if selected.contains(r.title) {
				w.set('txt_awk_script', r.script)
				w.set_text('dd_fs', r.fs)
				w.set('lbl_recipe_desc', 'Tip: ' + r.desc)
				execute_gawk_program(mut w)
				return
			}
		}
		w.toast('Please select a recipe from the dropdown.')
	})

	// Process Massive File from Disk Directly
	win.on_click('btn_file_stream', fn (mut w simplegui.SimpleWindow) {
		in_path := w.select_file()
		if in_path == '' || !os.exists(in_path) {
			return
		}
		out_path := w.save_file_picker()
		if out_path == '' {
			return
		}

		gawk := get_gawk_bin()
		script := w.get('txt_awk_script').trim_space()
		if script == '' {
			w.alert('Script Required', 'Please enter a valid GAWK script to execute.')
			return
		}

		tmp_script := os.join_path(os.temp_dir(), 'gawk_studio_prog_${time.ticks()}.awk')
		os.write_file(tmp_script, script) or {
			w.alert('Error', 'Failed to write temporary script file.')
			return
		}

		fs_sel := w.get('dd_fs')
		mut raw_fs := ''
		if fs_sel.contains('Comma') { raw_fs = ',' }
		else if fs_sel.contains('Tab') { raw_fs = '\t' }
		else if fs_sel.contains('Colon') { raw_fs = ':' }
		else if fs_sel.contains('Pipe') { raw_fs = '|' }
		else if fs_sel.contains('Semicolon') { raw_fs = ';' }
		else if w.get('txt_custom_fs') != '' { raw_fs = w.get('txt_custom_fs') }

		mut cmd_parts := [simplegui.quote_arg(gawk)]
		if raw_fs != '' {
			cmd_parts << '-F'
			cmd_parts << simplegui.quote_arg(raw_fs)
		}
		cmd_parts << '-f'
		cmd_parts << simplegui.quote_path(tmp_script)
		cmd_parts << simplegui.quote_path(in_path)
		cmd_parts << '>'
		cmd_parts << simplegui.quote_path(out_path)

		cmd := cmd_parts.join(' ')
		w.set_status('Processing massive file on disk in background...')
		w.toast('Direct file processing started...')

		go fn [mut w, cmd, in_path, out_path, tmp_script] () {
			t0 := time.ticks()
			res := os.execute(cmd)
			elapsed_ms := time.ticks() - t0

			if os.exists(tmp_script) { os.rm(tmp_script) or {} }

			w.run_on_main_thread(fn [res, in_path, out_path, elapsed_ms] (mut win_main simplegui.SimpleWindow) {
				if res.exit_code == 0 {
					out_sz := os.file_size(out_path)
					mb := f64(out_sz) / (1024.0 * 1024.0)
					win_main.set_status('File processed successfully in ${elapsed_ms} ms (${mb:.2f} MB).')
					win_main.toast('File processed & saved: ${out_path} (${mb:.2f} MB)!')
					win_main.set('lbl_exec_stats', ' Stats: Direct File Stream  |  In: ${os.file_name(in_path)}  |  Out: ${mb:.2f} MB  |  Time: ${elapsed_ms} ms')
				} else {
					win_main.alert('GAWK Error', 'Error processing file: ' + res.output)
					win_main.set_status('Error processing file.')
				}
			})
		}()
	})

	// Run GAWK Program
	win.on_click('btn_run_awk', fn [execute_gawk_program] (mut w simplegui.SimpleWindow) {
		execute_gawk_program(mut w)
	})

	println('GAWK Studio Pro configured. Starting event loop...')
	win.run()
}

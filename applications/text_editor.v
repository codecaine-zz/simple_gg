module main

import simplegui
import os
import encoding.base64
import encoding.hex
import crypto.md5
import crypto.sha256
import net.urllib
import regex
import time
import rand

// -------------------------------------------------------------
// Data Structures & State
// -------------------------------------------------------------

struct ScratchpadBuffer {
mut:
	name    string
	content string
	file    string
}

struct WordFrequency {
	word  string
	count int
}

struct EditorState {
mut:
	current_file_path string
	is_dirty          bool
	font_size         int
	font_family       string
	active_view       string
	active_buffer_idx int
	buffers           []ScratchpadBuffer
	original_content  string
}

// -------------------------------------------------------------
// Helper Calculation & Analysis Functions
// -------------------------------------------------------------

fn str_to_hex(s string) string {
	return hex.encode(s.bytes())
}

fn hex_to_str(h string) string {
	bytes := hex.decode(h) or { return '' }
	return bytes.bytestr()
}

fn count_words(text string) int {
	clean := text.replace('\n', ' ').replace('\r', ' ').replace('\t', ' ')
	tokens := clean.split(' ').filter(it.trim_space() != '')
	return tokens.len
}

fn count_sentences(text string) int {
	mut count := 0
	for ch in text {
		if ch == `.` || ch == `!` || ch == `?` {
			count++
		}
	}
	return if count > 0 { count } else if text.trim_space() != '' { 1 } else { 0 }
}

fn count_paragraphs(text string) int {
	lines := text.split_into_lines()
	mut count := 0
	mut in_para := false
	for line in lines {
		if line.trim_space() != '' {
			if !in_para {
				count++
				in_para = true
			}
		} else {
			in_para = false
		}
	}
	return count
}

fn calculate_word_frequencies(text string) []string {
	clean := text.to_lower().replace('\n', ' ').replace('\r', ' ').replace('\t', ' ')
	mut words_map := map[string]int{}
	mut word_chars := []u8{}

	for i in 0 .. clean.len {
		b := clean[i]
		if (b >= `a` && b <= `z`) || (b >= `0` && b <= `9`) || b == `_` {
			word_chars << b
		} else {
			if word_chars.len >= 3 {
				w := word_chars.bytestr()
				words_map[w]++
			}
			word_chars.clear()
		}
	}
	if word_chars.len >= 3 {
		w := word_chars.bytestr()
		words_map[w]++
	}

	mut pairs := []WordFrequency{}
	for k, v in words_map {
		pairs << WordFrequency{
			word: k
			count: v
		}
	}
	pairs.sort(a.count > b.count)

	mut result := []string{}
	max_take := if pairs.len > 10 { 10 } else { pairs.len }
	for i in 0 .. max_take {
		p := pairs[i]
		result << '${i + 1}. "${p.word}" -- ${p.count} occurrences'
	}
	return result
}

// -------------------------------------------------------------
// Markdown to HTML WebKit Renderer
// -------------------------------------------------------------

fn markdown_to_html(md string, theme string) string {
	lines := md.split_into_lines()
	mut html := ''
	mut in_list := false
	mut in_code_block := false

	mut body_bg := '#1e1e1e'
	mut body_fg := '#f8f8f2'
	mut code_bg := '#2d2d2d'
	mut code_fg := '#50fa7b'
	mut hr_color := '#444444'
	mut h1_color := '#8be9fd'
	mut h2_color := '#ffb86c'
	mut h3_color := '#ff79c6'

	if theme.contains('light') || theme.contains('solarized-light') {
		body_bg = '#ffffff'
		body_fg = '#24292e'
		code_bg = '#f6f8fa'
		code_fg = '#d73a49'
		hr_color = '#e1e4e8'
		h1_color = '#0366d6'
		h2_color = '#22863a'
		h3_color = '#6f42c1'
	} else if theme.contains('nord') {
		body_bg = '#2e3440'
		body_fg = '#d8dee9'
		code_bg = '#3b4252'
		code_fg = '#88c0d0'
		hr_color = '#4c566a'
		h1_color = '#88c0d0'
		h2_color = '#81a1c1'
		h3_color = '#b48ead'
	} else if theme.contains('cyberpunk') || theme.contains('synthwave') {
		body_bg = '#140c24'
		body_fg = '#ff71ce'
		code_bg = '#241734'
		code_fg = '#01cdfe'
		hr_color = '#7f22a7'
		h1_color = '#05ffa1'
		h2_color = '#fffb96'
		h3_color = '#ff71ce'
	}

	for line in lines {
		trimmed := line.trim_space()

		if trimmed.starts_with('```') {
			if in_code_block {
				html += '</code></pre>\n'
				in_code_block = false
			} else {
				html += '<pre style="background: ' + code_bg + '; color: ' + code_fg +
					'; padding: 12px; border-radius: 6px; overflow-x: auto; font-family: Menlo, monospace; font-size: 13px; line-height: 1.4;"><code>'
				in_code_block = true
			}
			continue
		}

		if in_code_block {
			escaped := line.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')
			html += escaped + '\n'
			continue
		}

		is_bullet := trimmed.starts_with('* ') || trimmed.starts_with('- ')
		if in_list && !is_bullet {
			html += '</ul>\n'
			in_list = false
		}

		if trimmed == '---' || trimmed == '***' {
			html += '<hr style="border: none; border-top: 1px solid ' + hr_color + '; margin: 20px 0;"/>\n'
			continue
		}

		if trimmed.starts_with('# ') {
			html += '<h1 style="color: ' + h1_color + '; margin-top: 20px; font-size: 24px; border-bottom: 1px solid ' + hr_color + '; padding-bottom: 6px;">' +
				parse_inline(trimmed[2..], code_bg, code_fg) + '</h1>\n'
			continue
		} else if trimmed.starts_with('## ') {
			html += '<h2 style="color: ' + h2_color + '; margin-top: 18px; font-size: 20px;">' +
				parse_inline(trimmed[3..], code_bg, code_fg) + '</h2>\n'
			continue
		} else if trimmed.starts_with('### ') {
			html += '<h3 style="color: ' + h3_color + '; margin-top: 14px; font-size: 16px;">' +
				parse_inline(trimmed[4..], code_bg, code_fg) + '</h3>\n'
			continue
		}

		if is_bullet {
			if !in_list {
				html += '<ul style="padding-left: 24px; line-height: 1.6;">\n'
				in_list = true
			}
			content := trimmed[2..]
			html += '<li style="margin-bottom: 6px;">' + parse_inline(content, code_bg, code_fg) + '</li>\n'
			continue
		}

		if trimmed == '' {
			continue
		}

		html += '<p style="line-height: 1.6; margin-bottom: 12px;">' + parse_inline(line, code_bg, code_fg) + '</p>\n'
	}

	if in_list {
		html += '</ul>\n'
	}
	if in_code_block {
		html += '</code></pre>\n'
	}

	return '<html><head><meta charset="utf-8"></head><body style="font-family: -apple-system, BlinkMacSystemFont, \'Segoe UI\', Helvetica, Arial, sans-serif; font-size: 14px; background-color: ' +
		body_bg + '; color: ' + body_fg + '; padding: 22px; margin: 0; line-height: 1.6;">' + html + '</body></html>'
}

fn parse_inline(text string, code_bg string, code_fg string) string {
	mut res := text.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')

	// Bold: **text**
	for {
		start := res.index('**') or { break }
		rest := res[start + 2..]
		end := rest.index('**') or { break }
		bold_text := rest[..end]
		res = res[..start] + '<strong>' + bold_text + '</strong>' + rest[end + 2..]
	}

	// Italics: *text*
	for {
		start := res.index('*') or { break }
		rest := res[start + 1..]
		end := rest.index('*') or { break }
		italic_text := rest[..end]
		res = res[..start] + '<em>' + italic_text + '</em>' + rest[end + 1..]
	}

	// Inline code: `code`
	for {
		start := res.index('`') or { break }
		rest := res[start + 1..]
		end := rest.index('`') or { break }
		code_text := rest[..end]
		res = res[..start] + '<code style="background: ' + code_bg + '; color: ' + code_fg +
			'; border-radius: 4px; padding: 2px 6px; font-family: Menlo, monospace; font-size: 0.9em;">' +
			code_text + '</code>' + rest[end + 1..]
	}

	return res
}

// -------------------------------------------------------------
// Unified Diff Generator
// -------------------------------------------------------------

fn generate_unified_diff(original string, modified string, title_a string, title_b string) string {
	lines_a := original.split_into_lines()
	lines_b := modified.split_into_lines()

	mut out := []string{}
	out << '--- ${title_a} (${lines_a.len} lines)'
	out << '+++ ${title_b} (${lines_b.len} lines)'
	out << '@@ -1,${lines_a.len} +1,${lines_b.len} @@'

	max_len := if lines_a.len > lines_b.len { lines_a.len } else { lines_b.len }
	mut diff_count := 0

	for i in 0 .. max_len {
		if i < lines_a.len && i < lines_b.len {
			if lines_a[i] == lines_b[i] {
				out << '  ${lines_a[i]}'
			} else {
				out << '- ${lines_a[i]}'
				out << '+ ${lines_b[i]}'
				diff_count++
			}
		} else if i < lines_a.len {
			out << '- ${lines_a[i]}'
			diff_count++
		} else if i < lines_b.len {
			out << '+ ${lines_b[i]}'
			diff_count++
		}
	}

	if diff_count == 0 {
		return ' Both documents are 100% IDENTICAL. No differences found.\n\n' + out.join('\n')
	}

	return ' Found differences across documents (${diff_count} line mutations):\n\n' + out.join('\n')
}

// -------------------------------------------------------------
// Snippets & Templates Catalog
// -------------------------------------------------------------

fn get_template_code(key string) string {
	match key {
		'V: CLI Application' {
			return 'module main

import os
import flag

fn main() {
	mut fp := flag.new_flag_parser(os.args)
	fp.application("v-cli-app")
	fp.version("v0.1.0")
	fp.description("High-performance V command-line tool")
	fp.skip_executable()

	verbose := fp.bool("verbose", `v`, false, "Enable verbose output logging")
	query := fp.string("query", `q`, "", "Search query to process")
	additional := fp.finalize() or {
		eprintln(err)
		return
	}

	if verbose {
		println("Processing with query: " + query)
		println("Additional arguments: " + additional.str())
	}
	println("V CLI Application executed successfully!")
}
'
		}
		'V: SimpleGUI Desktop App' {
			return 'module main

import simplegui

fn main() {
	mut win := simplegui.new_simple_window("My Native App", 640, 480)
	win.set_fullscreen(true)
	win.restore_saved_theme()
	win.set_padding(20)
	win.set_spacing(10)

	win.add_heading("SimpleGUI Desktop App")
	win.add_label("lbl_intro", "Welcome to native macOS GUI development in V!")
	win.add_input("txt_input", "Hello SimpleGUI")

	win.begin_row("row_btns")
	win.add_button("btn_action", "Click Me")
	win.add_button("btn_clear", "Clear")
	win.end_row()

	win.on_click("btn_action", fn (mut w simplegui.SimpleWindow) {
		val := w.get("txt_input")
		w.toast("Input: " + val)
		w.alert("Greeting", "You entered: " + val)
	})

	win.on_click("btn_clear", fn (mut w simplegui.SimpleWindow) {
		w.set("txt_input", "")
		w.toast("Cleared input")
	})

	win.run()
}
'
		}
		'Python: Data & HTTP Script' {
			return '#!/usr/bin/env python3
"""
Python Fast Script Boilerplate
"""
import sys
import json
import urllib.request

def fetch_json(url: str):
    req = urllib.request.Request(url, headers={"User-Agent": "TextEditorPro/1.0"})
    with urllib.request.urlopen(req, timeout=10) as resp:
        return json.loads(resp.read().decode("utf-8"))

def main():
    print("Executing Python Pipeline...")
    data = {"status": "success", "items": [1, 2, 3, 4, 5], "metadata": {"author": "SimpleGUI Developer"}}
    print("Payload Structure:")
    print(json.dumps(data, indent=2))

if __name__ == "__main__":
    main()
'
		}
		'JavaScript: Modern Async Script' {
			return '// JavaScript / Node.js Modern Async Boilerplate
const os = require("os");

async function runPipeline() {
    console.log("=== Node.js Automation Studio ===");
    console.log("Platform: " + os.platform() + " (" + os.arch() + ")");
    console.log("CPUs: " + os.cpus().length + " cores | Free Memory: " + (os.freemem() / 1024 / 1024).toFixed(0) + " MB");

    const items = ["Item Alpha", "Item Beta", "Item Gamma"];
    const transformed = items.map((x, idx) => ({ id: idx + 1, name: x.toUpperCase() }));
    
    console.log("Transformed payload:");
    console.table(transformed);
}

runPipeline().catch(console.error);
'
		}
		'HTML5 & Modern CSS' {
			return '<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Modern Responsive Web Studio</title>
  <style>
    :root {
      --bg: #0f172a;
      --card: #1e293b;
      --text: #f8fafc;
      --accent: #38bdf8;
    }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      background: var(--bg);
      color: var(--text);
      margin: 0;
      padding: 40px;
      display: flex;
      justify-content: center;
    }
    .card {
      background: var(--card);
      padding: 32px;
      border-radius: 16px;
      box-shadow: 0 10px 25px rgba(0,0,0,0.5);
      max-width: 600px;
      width: 100%;
    }
    h1 { color: var(--accent); margin-top: 0; }
    button {
      background: var(--accent);
      color: #0f172a;
      border: none;
      padding: 10px 20px;
      border-radius: 8px;
      font-weight: bold;
      cursor: pointer;
    }
  </style>
</head>
<body>
  <div class="card">
    <h1> Modern HTML5 Experience</h1>
    <p>Clean, semantic, dark-themed responsive template ready for production.</p>
    <button onclick="alert(\'Hello from SimpleGUI HTML5!\')">Explore Features</button>
  </div>
</body>
</html>
'
		}
		'JSON: Config & Schema' {
			return '{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "appName": "Text Editor Pro",
  "version": "2.5.0",
  "settings": {
    "theme": "Nord",
    "fontSize": 14,
    "fontFamily": "Menlo",
    "tabSize": 4,
    "wordWrap": true,
    "autoSave": false
  },
  "plugins": [
    {
      "id": "vlang-lsp",
      "enabled": true,
      "priority": 10
    },
    {
      "id": "markdown-preview",
      "enabled": true,
      "priority": 5
    }
  ]
}
'
		}
		'Markdown: Documentation' {
			return '#  Project Documentation & API Reference

Welcome to the **Developer Documentation Hub**!

##  Key Features
- **Ultra Fast**: Sub-millisecond text transformations.
- **Native Integration**: macOS Cocoa WebKit & native file dialogues.
- **Multi-Buffer Studio**: 4 independent scratchpads for seamless multitasking.

---

##  Quick Start

```v
import simplegui

fn main() {
    println("Hello Developer Studio!")
}
```

###  Checklist
- [x] Configure native theme
- [x] Test search & regex replace
- [x] Export HTML preview
'
		}
		'SQL: Table & Analytics Query' {
			return '-- ===================================================
-- Analytics Database Schema & Performance Query
-- ===================================================

CREATE TABLE IF NOT EXISTS system_telemetry (
    id BIGSERIAL PRIMARY KEY,
    session_id UUID NOT NULL,
    event_type VARCHAR(64) NOT NULL,
    payload JSONB DEFAULT \'{}\'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_telemetry_event ON system_telemetry(event_type, created_at DESC);

-- Aggregate Event Summary:
SELECT 
    event_type,
    COUNT(*) AS total_occurrences,
    MIN(created_at) AS first_seen,
    MAX(created_at) AS last_seen
FROM system_telemetry
WHERE created_at >= NOW() - INTERVAL \'7 days\'
GROUP BY event_type
ORDER BY total_occurrences DESC;
'
		}
		'Bash: Automation Script' {
			return '#!/usr/bin/env bash
set -euo pipefail

echo "=== System Automation & Deployment Pipeline ==="
echo "Timestamp: $(date -u)"
echo "Host: $(hostname) | User: $(whoami)"

TARGET_DIR="./output"
mkdir -p "$TARGET_DIR"

echo "Syncing artifacts to \$TARGET_DIR..."
echo "Deployment completed successfully."
'
		}
		'Dockerfile: Multi-Stage Build' {
			return '# Multi-stage Production Dockerfile
FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o /app/server .

FROM alpine:3.19
RUN apk --no-cache add ca-certificates tzdata
WORKDIR /root/
COPY --from=builder /app/server .
EXPOSE 8080
ENTRYPOINT ["/root/server"]
'
		}
		else {
			return ''
		}
	}
}

// -------------------------------------------------------------
// Main Application Entry Point
// -------------------------------------------------------------

fn main() {
	println('Starting SimpleGUI - Text Editor Pro (Ultimate Native macOS Developer & Document Studio)...')

	mut win := simplegui.new_simple_window('Text Editor Pro -- Ultimate Native Developer & Document Studio', 1240, 960)
	win.set_fullscreen(true)
	win.restore_saved_theme()
	win.set_spacing(6)
	win.set_padding(14)

	mut state := &EditorState{
		current_file_path: ''
		is_dirty: false
		font_size: 14
		font_family: 'Menlo'
		active_view: 'Editor & Tools'
		active_buffer_idx: 0
		buffers: [
			ScratchpadBuffer{ name: 'Scratchpad 1', content: '// Welcome to SimpleGUI Text Editor Pro!\n// Full-featured macOS Developer & Text Studio.\n\nfn main() {\n    println("Hello, World!")\n}\n', file: '' },
			ScratchpadBuffer{ name: 'Scratchpad 2', content: '# Scratchpad 2\nWrite notes, queries, or ideas here.\n', file: '' },
			ScratchpadBuffer{ name: 'Scratchpad 3', content: '{\n  "status": "ready",\n  "buffer": 3\n}\n', file: '' },
			ScratchpadBuffer{ name: 'Scratchpad 4', content: '-- Scratchpad 4: SQL & Data\nSELECT * FROM documents WHERE active = true;\n', file: '' },
		]
		original_content: ''
	}

	state.original_content = state.buffers[0].content

	// -------------------------------------------------------------
	// 1. Header & Theme Bar
	// -------------------------------------------------------------
	win.begin_row('row_header')
	win.add_heading('Text Editor Pro Studio')

	win.add_label('lbl_buf_sel', 'Active Buffer:')
	win.add_dropdown('dd_buffer', ['1: Scratchpad 1', '2: Scratchpad 2', '3: Scratchpad 3', '4: Scratchpad 4'], '1: Scratchpad 1')
	win.set_control_width('dd_buffer', 160)

	win.add_label('lbl_theme_hdr', 'Theme:')
	saved_theme := simplegui.get_saved_theme()
	win.add_dropdown('dd_theme_selector', simplegui.list_themes(), saved_theme)
	win.set_control_width('dd_theme_selector', 160)
	win.end_row()

	// -------------------------------------------------------------
	// 2. Multi-Mode View Tabs
	// -------------------------------------------------------------
	win.add_tabs('workspace_tabs', [
		'Editor & Tools',
		'Markdown Preview',
		'Runner & Console',
		'Telemetry & Stats',
		'Diff & Compare',
		'Templates Gallery',
	])

	// -------------------------------------------------------------
	// 3. File Operations Toolbar
	// -------------------------------------------------------------
	win.begin_group_box('grp_file_bar', 'File Operations & Buffer Management')
	win.begin_row('row_file_ops_1')
	win.add_button('btn_new', 'New')
	win.add_button('btn_open', 'Open...')
	win.add_button('btn_save', 'Save')
	win.add_button('btn_save_as', 'Save As...')
	win.add_button('btn_revert', 'Revert')
	win.add_button('btn_reveal', 'Reveal')
	win.add_button('btn_copy_path', 'Copy Path')
	win.end_row()

	win.begin_row('row_file_ops_2')
	win.add_button('btn_open_term', 'Terminal')
	win.add_button('btn_copy_all', 'Copy All')

	win.add_label('lbl_font_size', 'Font:')
	win.add_button('btn_font_dec', 'A-')
	win.add_button('btn_font_inc', 'A+')

	win.add_dropdown('dd_font_family', [
		'Menlo',
		'SF Mono',
		'Monaco',
		'Courier New',
		'Helvetica',
		'System'
	], 'Menlo')
	win.set_control_width('dd_font_family', 100)

	win.add_label('lbl_active_file', 'Active File: Untitled.txt (Unsaved)')
	win.end_row()
	win.end_group_box()

	// -------------------------------------------------------------
	// 4. View Container 1: Editor & Tools
	// -------------------------------------------------------------
	win.begin_group_box('pane_editor', 'Code & Document Workspace')

	// Search & Replace Row
	win.begin_row('row_search')
	win.add_label('lbl_find', 'Find:')
	win.add_input('txt_find', '')
	win.set_control_width('txt_find', 120)

	win.add_label('lbl_replace', 'Replace:')
	win.add_input('txt_replace', '')
	win.set_control_width('txt_replace', 120)

	win.add_button('btn_find_next', 'Find')
	win.add_button('btn_replace_all', 'Replace All')
	win.add_checkbox('chk_match_case', 'Case', false)
	win.add_checkbox('chk_whole_word', 'Word', false)
	win.add_checkbox('chk_regex', 'Regex', false)
	win.end_row()

	// Transformation Power Bar 1: Case Conversions
	win.begin_row('row_transforms_1')
	win.add_button('btn_upper', 'UPPER')
	win.add_button('btn_lower', 'lower')
	win.add_button('btn_title', 'Title')
	win.add_button('btn_camel', 'camelCase')
	win.add_button('btn_snake', 'snake_case')
	win.add_button('btn_kebab', 'kebab-case')
	win.add_button('btn_constant', 'CONSTANT')
	win.end_row()

	// Transformation Power Bar 2: Line Sorting & Ordering
	win.begin_row('row_transforms_2')
	win.add_button('btn_sort_az', 'Sort A-Z')
	win.add_button('btn_sort_za', 'Sort Z-A')
	win.add_button('btn_sort_len', 'By Length')
	win.add_button('btn_dedup', 'Unique Lines')
	win.add_button('btn_reverse_lines', 'Reverse')
	win.add_button('btn_shuffle_lines', 'Shuffle')
	win.add_button('btn_remove_empty', 'Strip Blank')
	win.end_row()

	// Transformation Power Bar 3: Formatting & Code Tools
	win.begin_row('row_transforms_3')
	win.add_button('btn_indent_2', 'Indent (+2)')
	win.add_button('btn_outdent_2', '<- Outdent (-2)')
	win.add_button('btn_trim', 'Trim Space')
	win.add_button('btn_num_lines', 'Number Lines')
	win.add_button('btn_strip_nums', 'Strip Numbers')
	win.add_button('btn_prettify_json', 'JSON Prettify')
	win.add_button('btn_minify_json', 'JSON Minify')
	win.end_row()

	// Transformation Power Bar 4: Encoders & Endings
	win.begin_row('row_transforms_4')
	win.add_button('btn_b64_enc', 'Base64 Enc')
	win.add_button('btn_b64_dec', 'Base64 Dec')
	win.add_button('btn_url_enc', 'URL Enc')
	win.add_button('btn_url_dec', 'URL Dec')
	win.add_button('btn_hex_enc', '0x Hex Enc')
	win.add_button('btn_hex_dec', 'Hex Dec')
	win.add_button('btn_crlf_to_lf', 'CRLF -> LF')
	win.add_button('btn_tabs_to_spaces', 'Tabs -> Spaces')
	win.end_row()

	// Power Filter & Line Extraction Bar
	win.begin_row('row_transforms_5')
	win.add_label('lbl_filter', 'Filter/Extract:')
	win.add_input('txt_filter_query', '')
	win.set_control_width('txt_filter_query', 140)
	win.add_button('btn_filter_keep', 'Keep Lines')
	win.add_button('btn_filter_remove', 'Remove Lines')
	win.add_button('btn_extract_urls', 'Extract URLs')
	win.add_button('btn_extract_emails', 'Extract Emails')
	win.add_button('btn_extract_ips', 'Extract IPs')
	win.add_button('btn_extract_quotes', 'Extract Quotes')
	win.end_row()

	// Main Editor Text Area
	win.add_textarea('txt_editor', state.buffers[0].content)
	win.set_control_height('txt_editor', 340)
	win.set_control_font_name('txt_editor', state.font_family)
	win.set_control_font_size('txt_editor', state.font_size)

	win.end_group_box()

	// -------------------------------------------------------------
	// 5. View Container 2: Markdown Live Preview
	// -------------------------------------------------------------
	win.begin_group_box('pane_markdown', 'Live Markdown / HTML WebKit Preview')
	win.begin_row('row_md_actions')
	win.add_button('btn_refresh_md', 'Refresh Preview')
	win.add_button('btn_copy_html', 'Copy Rendered HTML')
	win.add_button('btn_export_html', 'Export HTML File...')
	win.add_label('lbl_md_hint', '  (Changes in the editor reflect automatically in live preview)')
	win.end_row()

	initial_html := markdown_to_html(state.buffers[0].content, saved_theme)
	win.add_html_view('html_preview', initial_html)
	win.set_control_height('html_preview', 490)
	win.end_group_box()

	// -------------------------------------------------------------
	// 6. View Container 3: Runner & Code Execution Console
	// -------------------------------------------------------------
	win.begin_group_box('pane_runner', 'Integrated Developer Code Execution Studio')
	win.begin_row('row_runner_ctrls')
	win.add_label('lbl_run_env', 'Runtime Environment:')
	win.add_dropdown('dd_runtime', [
		'V (v run)',
		'Python 3 (python3)',
		'Node.js (node)',
		'Bash (bash -s)',
		'Ruby (ruby)',
		'Perl (perl)'
	], 'V (v run)')
	win.set_control_width('dd_runtime', 180)

	win.add_label('lbl_run_args', 'CLI Arguments:')
	win.add_input('txt_run_args', '')
	win.set_control_width('txt_run_args', 180)

	win.add_button('btn_execute_code', 'RUN CURRENT CODE')
	win.add_button('btn_clear_console', 'Clear Output')
	win.end_row()

	win.add_textarea('txt_console_output', '=== SimpleGUI Code Execution Console ===\nSelect an environment above and click "RUN CURRENT CODE" to execute the active editor buffer.\n')
	win.set_control_height('txt_console_output', 470)
	win.set_control_font_name('txt_console_output', 'Menlo')
	win.set_control_font_size('txt_console_output', 13)
	win.end_group_box()

	// -------------------------------------------------------------
	// 7. View Container 4: Document Telemetry & Statistics
	// -------------------------------------------------------------
	win.begin_group_box('pane_telemetry', 'Document Analytics, Readability & Cryptographic Hashes')
	win.begin_row('row_stats_actions')
	win.add_button('btn_refresh_stats', 'Refresh Statistics')
	win.add_button('btn_copy_stats', 'Copy Full Report')
	win.add_button('btn_copy_md5', 'Copy MD5 Hash')
	win.add_button('btn_copy_sha256', 'Copy SHA-256 Hash')
	win.end_row()

	win.add_textarea('txt_stats_report', '')
	win.set_control_height('txt_stats_report', 490)
	win.set_control_font_name('txt_stats_report', 'Menlo')
	win.set_control_font_size('txt_stats_report', 13)
	win.end_group_box()

	// -------------------------------------------------------------
	// 8. View Container 5: Diff & Comparison Studio
	// -------------------------------------------------------------
	win.begin_group_box('pane_diff', 'Document Comparison & Unified Diff')
	win.begin_row('row_diff_ctrls')
	win.add_label('lbl_diff_src', 'Compare Active Buffer with:')
	win.add_dropdown('dd_diff_target', [
		'Saved File on Disk',
		'System Clipboard',
		'Buffer 1: Scratchpad 1',
		'Buffer 2: Scratchpad 2',
		'Buffer 3: Scratchpad 3',
		'Buffer 4: Scratchpad 4'
	], 'Saved File on Disk')
	win.set_control_width('dd_diff_target', 200)

	win.add_button('btn_run_diff', 'Compute Unified Diff')
	win.add_button('btn_copy_diff', 'Copy Diff')
	win.end_row()

	win.add_textarea('txt_diff_output', 'Select a comparison target above and click "Compute Unified Diff" to view line-by-line mutations.')
	win.set_control_height('txt_diff_output', 490)
	win.set_control_font_name('txt_diff_output', 'Menlo')
	win.set_control_font_size('txt_diff_output', 13)
	win.end_group_box()

	// -------------------------------------------------------------
	// 9. View Container 6: Snippets & Templates Gallery
	// -------------------------------------------------------------
	win.begin_group_box('pane_templates', 'Boilerplate, Snippets & Code Templates Catalog')
	win.begin_row('row_tmpl_ctrls')
	win.add_label('lbl_tmpl_pick', 'Select Template:')
	win.add_dropdown('dd_templates', [
		'V: CLI Application',
		'V: SimpleGUI Desktop App',
		'Python: Data & HTTP Script',
		'JavaScript: Modern Async Script',
		'HTML5 & Modern CSS',
		'JSON: Config & Schema',
		'Markdown: Documentation',
		'SQL: Table & Analytics Query',
		'Bash: Automation Script',
		'Dockerfile: Multi-Stage Build'
	], 'V: CLI Application')
	win.set_control_width('dd_templates', 240)

	win.add_button('btn_load_template', 'Load Into Editor')
	win.add_button('btn_append_template', 'Append to Current Buffer')
	win.add_button('btn_copy_template', 'Copy Template')
	win.end_row()

	win.add_textarea('txt_template_preview', get_template_code('V: CLI Application'))
	win.set_control_height('txt_template_preview', 490)
	win.set_control_font_name('txt_template_preview', 'Menlo')
	win.set_control_font_size('txt_template_preview', 13)
	win.end_group_box()

	// Initially hide inactive tab panes
	win.set_control_visible('pane_markdown', false)
	win.set_control_visible('pane_runner', false)
	win.set_control_visible('pane_telemetry', false)
	win.set_control_visible('pane_diff', false)
	win.set_control_visible('pane_templates', false)

	// -------------------------------------------------------------
	// 10. Status Bar & Telemetry Footer
	// -------------------------------------------------------------
	win.begin_row('row_status_bar')
	win.add_label('lbl_stats', 'Lines: 6  |  Words: 15  |  Chars: 125  |  Size: 125 B  |  Encoding: UTF-8  |  Tab: 4 Spaces')
	win.end_row()

	// -------------------------------------------------------------
	// Telemetry & Statistics Update Engine
	// -------------------------------------------------------------
	update_telemetry := fn (mut win simplegui.SimpleWindow, state &EditorState) {
		text := win.get('txt_editor')
		lines := text.split_into_lines()
		line_count := lines.len
		word_count := count_words(text)
		char_count := text.len
		byte_count := text.len
		blank_lines := lines.filter(it.trim_space() == '').len
		sentence_count := count_sentences(text)
		para_count := count_paragraphs(text)

		file_display := if state.current_file_path != '' {
			name := os.file_name(state.current_file_path)
			if state.is_dirty { '* ' + name + ' (Modified)' } else { name }
		} else {
			buf_name := state.buffers[state.active_buffer_idx].name
			if state.is_dirty { '* ' + buf_name + ' (Unsaved)' } else { buf_name }
		}

		win.set('lbl_active_file', 'Active File: ' + file_display)
		win.set('lbl_stats', ' Lines: ${line_count}  |  Words: ${word_count}  |  Chars: ${char_count}  |  Bytes: ${byte_count} B  |  Encoding: UTF-8  |  View: ${state.active_view}')

		// If telemetry tab is visible or generated, populate full report
		mut max_line_len := 0
		mut longest_line := ''
		for l in lines {
			if l.len > max_line_len {
				max_line_len = l.len
				longest_line = l
			}
		}

		read_time_min := f64(word_count) / 200.0
		speak_time_min := f64(word_count) / 130.0
		read_str := if read_time_min < 1.0 { '${int(read_time_min * 60)} seconds' } else { '${read_time_min:.1f} minutes' }
		speak_str := if speak_time_min < 1.0 { '${int(speak_time_min * 60)} seconds' } else { '${speak_time_min:.1f} minutes' }

		md5_sum := md5.hexhash(text)
		sha256_sum := sha256.hexhash(text)

		top_words := calculate_word_frequencies(text)

		mut report := []string{}
		report << '========================================================================'
		report << ' TEXT EDITOR PRO -- DOCUMENT TELEMETRY & METRIC REPORT'
		report << '========================================================================'
		report << 'File Name / Buffer   : ' + file_display
		report << 'Disk File Path       : ' + if state.current_file_path != '' { state.current_file_path } else { '(In-Memory Scratchpad Buffer)' }
		report << 'Status               : ' + if state.is_dirty { 'Modified (Unsaved Changes)' } else { 'Saved / Clean' }
		report << 'Character Encoding   : UTF-8'
		report << ''
		report << ' STRUCTURAL COUNTS:'
		report << '------------------------------------------------------------------------'
		report << 'Total Lines          : ${line_count}'
		report << 'Blank Lines          : ${blank_lines}'
		report << 'Non-Blank Lines      : ${line_count - blank_lines}'
		report << 'Total Words          : ${word_count}'
		report << 'Total Characters     : ${char_count}'
		report << 'Non-Whitespace Chars : ${text.replace(' ', '').replace('\n', '').replace('\r', '').replace('\t', '').len}'
		report << 'Total Byte Size      : ${byte_count} Bytes (${f64(byte_count) / 1024.0:.2f} KB)'
		report << 'Paragraphs Count     : ${para_count}'
		report << 'Sentences Count      : ${sentence_count}'
		report << ''
		report << ' READABILITY & TIME ESTIMATES:'
		report << '------------------------------------------------------------------------'
		report << 'Estimated Reading Time (200 WPM) : ${read_str}'
		report << 'Estimated Speaking Time (130 WPM): ${speak_str}'
		report << 'Average Word Length             : ' + if word_count > 0 { '${f64(char_count) / f64(word_count):.1f} chars/word' } else { '0' }
		report << 'Maximum Line Length             : ${max_line_len} chars'
		if longest_line.len > 0 {
			disp_longest := if longest_line.len > 60 { longest_line[..60] + '...' } else { longest_line }
			report << 'Longest Line Preview            : "${disp_longest}"'
		}
		report << ''
		report << ' CRYPTOGRAPHIC CHECKSUMS:'
		report << '------------------------------------------------------------------------'
		report << 'MD5 Hash    : ${md5_sum}'
		report << 'SHA-256 Hash: ${sha256_sum}'
		report << ''
		report << ' TOP FREQUENT WORDS:'
		report << '------------------------------------------------------------------------'
		if top_words.len > 0 {
			for tw in top_words {
				report << tw
			}
		} else {
			report << '(Not enough words for frequency distribution)'
		}
		report << '========================================================================'

		win.set('txt_stats_report', report.join('\n'))
	}

	// -------------------------------------------------------------
	// Event Handlers & Core Workflow
	// -------------------------------------------------------------

	// Text Modified
	win.on_change('txt_editor', fn [mut state, update_telemetry] (mut w simplegui.SimpleWindow, _ string) {
		state.is_dirty = true
		state.buffers[state.active_buffer_idx].content = w.get('txt_editor')
		update_telemetry(mut w, state)
	})

	// Workspace Tabs Changed
	win.on_change('workspace_tabs', fn [mut state, update_telemetry] (mut w simplegui.SimpleWindow, tab string) {
		state.active_view = tab

		w.set_control_visible('pane_editor', tab == 'Editor & Tools')
		w.set_control_visible('pane_markdown', tab == 'Markdown Preview')
		w.set_control_visible('pane_runner', tab == 'Runner & Console')
		w.set_control_visible('pane_telemetry', tab == 'Telemetry & Stats')
		w.set_control_visible('pane_diff', tab == 'Diff & Compare')
		w.set_control_visible('pane_templates', tab == 'Templates Gallery')

		curr_text := w.get('txt_editor')

		if tab == 'Markdown Preview' {
			curr_theme := w.get('dd_theme_selector')
			rendered := markdown_to_html(curr_text, curr_theme)
			w.set_html('html_preview', rendered)
			w.toast('Rendered Markdown WebKit view.')
		} else if tab == 'Telemetry & Stats' {
			update_telemetry(mut w, state)
			w.toast('Updated document telemetry report.')
		}

		update_telemetry(mut w, state)
	})

	// Buffer Switcher
	win.on_change('dd_buffer', fn [mut state, update_telemetry] (mut w simplegui.SimpleWindow, selected string) {
		// Save current editor text into active buffer before switching
		state.buffers[state.active_buffer_idx].content = w.get('txt_editor')
		state.buffers[state.active_buffer_idx].file = state.current_file_path

		new_idx := match selected[..1] {
			'1' { 0 }
			'2' { 1 }
			'3' { 2 }
			'4' { 3 }
			else { 0 }
		}

		state.active_buffer_idx = new_idx
		state.current_file_path = state.buffers[new_idx].file
		state.is_dirty = false
		w.set('txt_editor', state.buffers[new_idx].content)
		state.original_content = state.buffers[new_idx].content
		update_telemetry(mut w, state)
		w.toast('Switched to ${state.buffers[new_idx].name}')
	})

	// Theme Selector
	win.on_change('dd_theme_selector', fn (mut w simplegui.SimpleWindow, selected string) {
		w.set_theme(selected)
		w.toast('Theme changed to ${selected}')
	})

	// Drag & Drop File onto Window
	win.on_file_drop(fn [mut state, update_telemetry] (mut w simplegui.SimpleWindow, files []string) {
		if files.len > 0 {
			target := files[0]
			if os.is_file(target) {
				content := os.read_file(target) or {
					w.alert('File Read Error', 'Unable to read dropped file:\n' + target)
					return
				}
				state.current_file_path = target
				state.original_content = content
				state.is_dirty = false
				state.buffers[state.active_buffer_idx].content = content
				state.buffers[state.active_buffer_idx].file = target
				w.set('txt_editor', content)
				update_telemetry(mut w, state)
				w.toast('Opened dropped file: ' + os.file_name(target))
			}
		}
	})

	// -------------------------------------------------------------
	// File Operations Toolbar Actions
	// -------------------------------------------------------------

	// New Document
	win.on_click('btn_new', fn [mut state, update_telemetry] (mut w simplegui.SimpleWindow) {
		if state.is_dirty {
			if !w.confirm('Discard Changes?', 'You have unsaved modifications in this buffer. Create new document anyway?') {
				return
			}
		}
		state.current_file_path = ''
		state.is_dirty = false
		state.original_content = ''
		state.buffers[state.active_buffer_idx].content = ''
		state.buffers[state.active_buffer_idx].file = ''
		w.set('txt_editor', '')
		update_telemetry(mut w, state)
		w.toast('Created new clean document buffer.')
	})

	// Open File
	win.on_click('btn_open', fn [mut state, update_telemetry] (mut w simplegui.SimpleWindow) {
		chosen := w.select_file()
		if chosen != '' && os.exists(chosen) {
			content := os.read_file(chosen) or {
				w.alert('Read Error', 'Failed to read file: ' + chosen)
				return
			}
			state.current_file_path = chosen
			state.original_content = content
			state.is_dirty = false
			state.buffers[state.active_buffer_idx].content = content
			state.buffers[state.active_buffer_idx].file = chosen
			w.set('txt_editor', content)
			update_telemetry(mut w, state)
			w.toast('Opened ' + os.file_name(chosen))
		}
	})

	// Save Helper
	save_doc := fn (mut w simplegui.SimpleWindow, mut state EditorState, update_fn fn (mut simplegui.SimpleWindow, &EditorState)) {
		mut target_path := state.current_file_path
		if target_path == '' {
			target_path = w.save_file_picker()
			if target_path == '' { return }
		}

		content := w.get('txt_editor')
		os.write_file(target_path, content) or {
			w.alert('Save Error', 'Failed to write to file: ' + target_path)
			return
		}

		state.current_file_path = target_path
		state.original_content = content
		state.is_dirty = false
		state.buffers[state.active_buffer_idx].content = content
		state.buffers[state.active_buffer_idx].file = target_path
		update_fn(mut w, &state)
		w.toast('Saved ' + os.file_name(target_path))
	}

	// Save Button
	win.on_click('btn_save', fn [mut state, save_doc, update_telemetry] (mut w simplegui.SimpleWindow) {
		save_doc(mut w, mut state, update_telemetry)
	})

	// Save As Button
	win.on_click('btn_save_as', fn [mut state, update_telemetry] (mut w simplegui.SimpleWindow) {
		target_path := w.save_file_picker()
		if target_path != '' {
			content := w.get('txt_editor')
			os.write_file(target_path, content) or {
				w.alert('Save Error', 'Failed to write to file: ' + target_path)
				return
			}
			state.current_file_path = target_path
			state.original_content = content
			state.is_dirty = false
			state.buffers[state.active_buffer_idx].content = content
			state.buffers[state.active_buffer_idx].file = target_path
			update_telemetry(mut w, state)
			w.toast('Saved as ' + os.file_name(target_path))
		}
	})

	// Revert to Disk
	win.on_click('btn_revert', fn [mut state, update_telemetry] (mut w simplegui.SimpleWindow) {
		if state.current_file_path == '' || !os.exists(state.current_file_path) {
			w.toast('No saved file on disk to revert from.')
			return
		}
		if !w.confirm('Revert Changes?', 'Discard all changes and reload from disk?') {
			return
		}
		content := os.read_file(state.current_file_path) or {
			w.alert('Revert Error', 'Failed to reload file from disk.')
			return
		}
		state.original_content = content
		state.is_dirty = false
		state.buffers[state.active_buffer_idx].content = content
		w.set('txt_editor', content)
		update_telemetry(mut w, state)
		w.toast('Reverted document to disk copy.')
	})

	// Reveal in Finder
	win.on_click('btn_reveal', fn [state] (mut w simplegui.SimpleWindow) {
		if state.current_file_path != '' && os.exists(state.current_file_path) {
			simplegui.reveal_in_finder(state.current_file_path)
			w.toast('Revealed in Finder.')
		} else {
			w.toast('Current document has not been saved to disk.')
		}
	})

	// Copy Full Path
	win.on_click('btn_copy_path', fn [state] (mut w simplegui.SimpleWindow) {
		if state.current_file_path != '' {
			w.copy_to_clipboard(state.current_file_path)
			w.toast('Copied file path to clipboard.')
		} else {
			w.toast('Document has not been saved to disk yet.')
		}
	})

	// Open Terminal in Directory
	win.on_click('btn_open_term', fn [state] (mut w simplegui.SimpleWindow) {
		target_dir := if state.current_file_path != '' && os.exists(state.current_file_path) {
			os.dir(state.current_file_path)
		} else {
			os.getwd()
		}
		simplegui.exec_safe('open', ['-a', 'Terminal', target_dir])
		w.toast('Opened Terminal in: ' + target_dir)
	})

	// Copy All Text
	win.on_click('btn_copy_all', fn (mut w simplegui.SimpleWindow) {
		text := w.get('txt_editor')
		w.copy_to_clipboard(text)
		w.toast('Copied entire document to clipboard!')
	})

	// -------------------------------------------------------------
	// Search, Replace & Typography Controls
	// -------------------------------------------------------------

	// Find Next
	win.on_click('btn_find_next', fn (mut w simplegui.SimpleWindow) {
		find_str := w.get('txt_find')
		if find_str == '' {
			w.alert('Empty Search', 'Please enter text in the Find field.')
			return
		}
		match_case := w.get_bool('chk_match_case')
		is_regex := w.get_bool('chk_regex')
		text := w.get('txt_editor')

		mut count := 0
		if is_regex {
			mut re := regex.regex_opt(find_str) or {
				w.alert('Invalid Regex', 'Regex syntax error:\n' + err.msg())
				return
			}
			matched := re.find_all_str(text)
			count = matched.len
		} else if match_case {
			mut start := 0
			for {
				if idx := text.index_after(find_str, start) {
					count++
					start = idx + find_str.len
				} else {
					break
				}
			}
		} else {
			lower_text := text.to_lower()
			lower_find := find_str.to_lower()
			mut start := 0
			for {
				if idx := lower_text.index_after(lower_find, start) {
					count++
					start = idx + find_str.len
				} else {
					break
				}
			}
		}

		w.toast('Found ${count} match(es) for "${find_str}".')
	})

	// Replace All
	win.on_click('btn_replace_all', fn [mut state, update_telemetry] (mut w simplegui.SimpleWindow) {
		find_str := w.get('txt_find')
		replace_str := w.get('txt_replace')
		match_case := w.get_bool('chk_match_case')
		whole_word := w.get_bool('chk_whole_word')
		is_regex := w.get_bool('chk_regex')

		if find_str == '' {
			w.alert('Empty Search', 'Please enter a search query in the Find field.')
			return
		}

		text := w.get('txt_editor')
		mut new_text := ''

		if is_regex {
			mut re := regex.regex_opt(find_str) or {
				w.alert('Invalid Regex', 'Regex syntax error:\n' + err.msg())
				return
			}
			new_text = re.replace(text, replace_str)
		} else if whole_word {
			lines := text.split_into_lines()
			mut res_lines := []string{}
			for line in lines {
				tokens := line.split(' ')
				mut new_tokens := []string{}
				for tok in tokens {
					matched := if match_case { tok == find_str } else { tok.to_lower() == find_str.to_lower() }
					if matched {
						new_tokens << replace_str
					} else {
						new_tokens << tok
					}
				}
				res_lines << new_tokens.join(' ')
			}
			new_text = res_lines.join('\n')
		} else if match_case {
			new_text = text.replace(find_str, replace_str)
		} else {
			lower_text := text.to_lower()
			lower_find := find_str.to_lower()
			mut start := 0
			mut res_builder := []string{}
			for {
				if idx := lower_text.index_after(lower_find, start) {
					res_builder << text[start..idx]
					res_builder << replace_str
					start = idx + find_str.len
				} else {
					res_builder << text[start..]
					break
				}
			}
			new_text = res_builder.join('')
		}

		w.set('txt_editor', new_text)
		state.is_dirty = true
		state.buffers[state.active_buffer_idx].content = new_text
		update_telemetry(mut w, state)
		w.toast('Replaced occurrences of "${find_str}".')
	})

	// Font Size Decrease
	win.on_click('btn_font_dec', fn [mut state] (mut w simplegui.SimpleWindow) {
		if state.font_size > 9 {
			state.font_size -= 1
			w.set_control_font_size('txt_editor', state.font_size)
			w.toast('Font Size: ${state.font_size}pt')
		}
	})

	// Font Size Increase
	win.on_click('btn_font_inc', fn [mut state] (mut w simplegui.SimpleWindow) {
		if state.font_size < 36 {
			state.font_size += 1
			w.set_control_font_size('txt_editor', state.font_size)
			w.toast('Font Size: ${state.font_size}pt')
		}
	})

	// Font Family Change
	win.on_change('dd_font_family', fn [mut state] (mut w simplegui.SimpleWindow, selected string) {
		state.font_family = selected
		w.set_control_font_name('txt_editor', selected)
		w.toast('Font Family: ${selected}')
	})

	// -------------------------------------------------------------
	// Text Transformations (Case & Line Operations)
	// -------------------------------------------------------------

	// UPPERCASE
	win.on_click('btn_upper', fn [mut state, update_telemetry] (mut w simplegui.SimpleWindow) {
		text := w.get('txt_editor')
		w.set('txt_editor', text.to_upper())
		state.is_dirty = true
		update_telemetry(mut w, state)
		w.toast('Converted to UPPERCASE.')
	})

	// lowercase
	win.on_click('btn_lower', fn [mut state, update_telemetry] (mut w simplegui.SimpleWindow) {
		text := w.get('txt_editor')
		w.set('txt_editor', text.to_lower())
		state.is_dirty = true
		update_telemetry(mut w, state)
		w.toast('Converted to lowercase.')
	})

	// Title Case
	win.on_click('btn_title', fn [mut state, update_telemetry] (mut w simplegui.SimpleWindow) {
		text := w.get('txt_editor')
		lines := text.split_into_lines()
		mut res := []string{cap: lines.len}
		for line in lines {
			words := line.split(' ')
			mut title_words := []string{cap: words.len}
			for word in words {
				if word.len > 0 {
					first := word[..1].to_upper()
					rest := if word.len > 1 { word[1..].to_lower() } else { '' }
					title_words << first + rest
				} else {
					title_words << ''
				}
			}
			res << title_words.join(' ')
		}
		w.set('txt_editor', res.join('\n'))
		state.is_dirty = true
		update_telemetry(mut w, state)
		w.toast('Converted to Title Case.')
	})

	// camelCase
	win.on_click('btn_camel', fn [mut state, update_telemetry] (mut w simplegui.SimpleWindow) {
		text := w.get('txt_editor')
		lines := text.split_into_lines()
		mut res_lines := []string{}
		for line in lines {
			clean := line.replace('-', ' ').replace('_', ' ')
			words := clean.split(' ').filter(it != '')
			if words.len == 0 {
				res_lines << ''
				continue
			}
			mut out := words[0].to_lower()
			for i in 1 .. words.len {
				w_str := words[i]
				out += w_str[..1].to_upper() + if w_str.len > 1 { w_str[1..].to_lower() } else { '' }
			}
			res_lines << out
		}
		w.set('txt_editor', res_lines.join('\n'))
		state.is_dirty = true
		update_telemetry(mut w, state)
		w.toast('Converted to camelCase.')
	})

	// snake_case
	win.on_click('btn_snake', fn [mut state, update_telemetry] (mut w simplegui.SimpleWindow) {
		text := w.get('txt_editor')
		lines := text.split_into_lines()
		mut res_lines := []string{}
		for line in lines {
			clean := line.replace('-', ' ')
			words := clean.split(' ').filter(it != '')
			mut lowered := []string{}
			for wd in words {
				lowered << wd.to_lower()
			}
			res_lines << lowered.join('_')
		}
		w.set('txt_editor', res_lines.join('\n'))
		state.is_dirty = true
		update_telemetry(mut w, state)
		w.toast('Converted to snake_case.')
	})

	// kebab-case
	win.on_click('btn_kebab', fn [mut state, update_telemetry] (mut w simplegui.SimpleWindow) {
		text := w.get('txt_editor')
		lines := text.split_into_lines()
		mut res_lines := []string{}
		for line in lines {
			clean := line.replace('_', ' ')
			words := clean.split(' ').filter(it != '')
			mut lowered := []string{}
			for wd in words {
				lowered << wd.to_lower()
			}
			res_lines << lowered.join('-')
		}
		w.set('txt_editor', res_lines.join('\n'))
		state.is_dirty = true
		update_telemetry(mut w, state)
		w.toast('Converted to kebab-case.')
	})

	// CONSTANT_CASE
	win.on_click('btn_constant', fn [mut state, update_telemetry] (mut w simplegui.SimpleWindow) {
		text := w.get('txt_editor')
		lines := text.split_into_lines()
		mut res_lines := []string{}
		for line in lines {
			clean := line.replace('-', ' ')
			words := clean.split(' ').filter(it != '')
			mut upped := []string{}
			for wd in words {
				upped << wd.to_upper()
			}
			res_lines << upped.join('_')
		}
		w.set('txt_editor', res_lines.join('\n'))
		state.is_dirty = true
		update_telemetry(mut w, state)
		w.toast('Converted to CONSTANT_CASE.')
	})

	// Sort A-Z
	win.on_click('btn_sort_az', fn [mut state, update_telemetry] (mut w simplegui.SimpleWindow) {
		text := w.get('txt_editor')
		mut lines := text.split_into_lines()
		lines.sort()
		w.set('txt_editor', lines.join('\n'))
		state.is_dirty = true
		update_telemetry(mut w, state)
		w.toast('Sorted lines A-Z.')
	})

	// Sort Z-A
	win.on_click('btn_sort_za', fn [mut state, update_telemetry] (mut w simplegui.SimpleWindow) {
		text := w.get('txt_editor')
		mut lines := text.split_into_lines()
		lines.sort()
		lines.reverse()
		w.set('txt_editor', lines.join('\n'))
		state.is_dirty = true
		update_telemetry(mut w, state)
		w.toast('Sorted lines Z-A.')
	})

	// Sort by Line Length
	win.on_click('btn_sort_len', fn [mut state, update_telemetry] (mut w simplegui.SimpleWindow) {
		text := w.get('txt_editor')
		mut lines := text.split_into_lines()
		lines.sort(a.len < b.len)
		w.set('txt_editor', lines.join('\n'))
		state.is_dirty = true
		update_telemetry(mut w, state)
		w.toast('Sorted lines by length.')
	})

	// Deduplicate Unique Lines
	win.on_click('btn_dedup', fn [mut state, update_telemetry] (mut w simplegui.SimpleWindow) {
		text := w.get('txt_editor')
		lines := text.split_into_lines()
		mut seen := map[string]bool{}
		mut res := []string{}
		for line in lines {
			if !seen[line] {
				seen[line] = true
				res << line
			}
		}
		w.set('txt_editor', res.join('\n'))
		state.is_dirty = true
		update_telemetry(mut w, state)
		w.toast('Deduplicated lines (kept ${res.len} unique lines).')
	})

	// Reverse Line Order
	win.on_click('btn_reverse_lines', fn [mut state, update_telemetry] (mut w simplegui.SimpleWindow) {
		text := w.get('txt_editor')
		mut lines := text.split_into_lines()
		lines.reverse()
		w.set('txt_editor', lines.join('\n'))
		state.is_dirty = true
		update_telemetry(mut w, state)
		w.toast('Reversed line order.')
	})

	// Shuffle Lines
	win.on_click('btn_shuffle_lines', fn [mut state, update_telemetry] (mut w simplegui.SimpleWindow) {
		text := w.get('txt_editor')
		mut lines := text.split_into_lines()
		rand.shuffle(mut lines) or {}
		w.set('txt_editor', lines.join('\n'))
		state.is_dirty = true
		update_telemetry(mut w, state)
		w.toast('Shuffled lines randomly.')
	})

	// Number Lines
	win.on_click('btn_num_lines', fn [mut state, update_telemetry] (mut w simplegui.SimpleWindow) {
		text := w.get('txt_editor')
		lines := text.split_into_lines()
		mut res := []string{cap: lines.len}
		for i, line in lines {
			res << '${i + 1}. ${line}'
		}
		w.set('txt_editor', res.join('\n'))
		state.is_dirty = true
		update_telemetry(mut w, state)
		w.toast('Numbered lines.')
	})

	// Strip Numbers
	win.on_click('btn_strip_nums', fn [mut state, update_telemetry] (mut w simplegui.SimpleWindow) {
		text := w.get('txt_editor')
		lines := text.split_into_lines()
		mut res := []string{cap: lines.len}
		for line in lines {
			trimmed := line.trim_space()
			mut cut_idx := 0
			for i in 0 .. trimmed.len {
				b := trimmed[i]
				if b >= `0` && b <= `9` {
					continue
				} else if b == `.` || b == `:` || b == `)` || b == `-` {
					cut_idx = i + 1
					break
				} else {
					break
				}
			}
			if cut_idx > 0 {
				res << trimmed[cut_idx..].trim_space()
			} else {
				res << line
			}
		}
		w.set('txt_editor', res.join('\n'))
		state.is_dirty = true
		update_telemetry(mut w, state)
		w.toast('Stripped line numbers.')
	})

	// Trim Whitespace
	win.on_click('btn_trim', fn [mut state, update_telemetry] (mut w simplegui.SimpleWindow) {
		text := w.get('txt_editor')
		lines := text.split_into_lines()
		mut res := []string{cap: lines.len}
		for line in lines {
			res << line.trim_space()
		}
		w.set('txt_editor', res.join('\n'))
		state.is_dirty = true
		update_telemetry(mut w, state)
		w.toast('Trimmed line whitespace.')
	})

	// Remove Blank Lines
	win.on_click('btn_remove_empty', fn [mut state, update_telemetry] (mut w simplegui.SimpleWindow) {
		text := w.get('txt_editor')
		lines := text.split_into_lines()
		filtered := lines.filter(it.trim_space() != '')
		w.set('txt_editor', filtered.join('\n'))
		state.is_dirty = true
		update_telemetry(mut w, state)
		w.toast('Removed empty lines (kept ${filtered.len} lines).')
	})

	// Indent (+2 spaces)
	win.on_click('btn_indent_2', fn [mut state, update_telemetry] (mut w simplegui.SimpleWindow) {
		text := w.get('txt_editor')
		lines := text.split_into_lines()
		mut res := []string{cap: lines.len}
		for line in lines {
			res << '  ' + line
		}
		w.set('txt_editor', res.join('\n'))
		state.is_dirty = true
		update_telemetry(mut w, state)
		w.toast('Indented lines (+2 spaces).')
	})

	// Outdent (-2 spaces)
	win.on_click('btn_outdent_2', fn [mut state, update_telemetry] (mut w simplegui.SimpleWindow) {
		text := w.get('txt_editor')
		lines := text.split_into_lines()
		mut res := []string{cap: lines.len}
		for line in lines {
			if line.starts_with('  ') {
				res << line[2..]
			} else if line.starts_with('\t') || line.starts_with(' ') {
				res << line[1..]
			} else {
				res << line
			}
		}
		w.set('txt_editor', res.join('\n'))
		state.is_dirty = true
		update_telemetry(mut w, state)
		w.toast('Outdented lines (-2 spaces).')
	})

	// JSON Prettify
	win.on_click('btn_prettify_json', fn [mut state, update_telemetry] (mut w simplegui.SimpleWindow) {
		text := w.get('txt_editor').trim_space()
		if text == '' { return }
		res := simplegui.exec_safe_stdin('python3', ['-m', 'json.tool'], text)
		if res.exit_code == 0 && res.output.trim_space() != '' {
			w.set('txt_editor', res.output)
			state.is_dirty = true
			update_telemetry(mut w, state)
			w.toast('Prettified JSON structure!')
		} else {
			w.alert('JSON Parse Error', 'Document is not valid JSON:\n' + res.output)
		}
	})

	// JSON Minify
	win.on_click('btn_minify_json', fn [mut state, update_telemetry] (mut w simplegui.SimpleWindow) {
		text := w.get('txt_editor').trim_space()
		if text == '' { return }
		res := simplegui.exec_safe_stdin('python3', ['-c', 'import sys, json; print(json.dumps(json.loads(sys.stdin.read()), separators=(",", ":")))'], text)
		if res.exit_code == 0 && res.output.trim_space() != '' {
			w.set('txt_editor', res.output.trim_space())
			state.is_dirty = true
			update_telemetry(mut w, state)
			w.toast('Minified JSON to compact single line!')
		} else {
			w.alert('JSON Parse Error', 'Document is not valid JSON:\n' + res.output)
		}
	})

	// Base64 Encode
	win.on_click('btn_b64_enc', fn [mut state, update_telemetry] (mut w simplegui.SimpleWindow) {
		text := w.get('txt_editor')
		enc := base64.encode_str(text)
		w.set('txt_editor', enc)
		state.is_dirty = true
		update_telemetry(mut w, state)
		w.toast('Base64 Encoded.')
	})

	// Base64 Decode
	win.on_click('btn_b64_dec', fn [mut state, update_telemetry] (mut w simplegui.SimpleWindow) {
		text := w.get('txt_editor').trim_space()
		dec := base64.decode_str(text)
		w.set('txt_editor', dec)
		state.is_dirty = true
		update_telemetry(mut w, state)
		w.toast('Base64 Decoded.')
	})

	// URL Encode
	win.on_click('btn_url_enc', fn [mut state, update_telemetry] (mut w simplegui.SimpleWindow) {
		text := w.get('txt_editor')
		enc := urllib.query_escape(text)
		w.set('txt_editor', enc)
		state.is_dirty = true
		update_telemetry(mut w, state)
		w.toast('URL Encoded.')
	})

	// URL Decode
	win.on_click('btn_url_dec', fn [mut state, update_telemetry] (mut w simplegui.SimpleWindow) {
		text := w.get('txt_editor')
		dec := urllib.query_unescape(text) or {
			w.alert('URL Decode Error', err.msg())
			return
		}
		w.set('txt_editor', dec)
		state.is_dirty = true
		update_telemetry(mut w, state)
		w.toast('URL Decoded.')
	})

	// Hex Encode
	win.on_click('btn_hex_enc', fn [mut state, update_telemetry] (mut w simplegui.SimpleWindow) {
		text := w.get('txt_editor')
		enc := str_to_hex(text)
		w.set('txt_editor', enc)
		state.is_dirty = true
		update_telemetry(mut w, state)
		w.toast('Hex Encoded.')
	})

	// Hex Decode
	win.on_click('btn_hex_dec', fn [mut state, update_telemetry] (mut w simplegui.SimpleWindow) {
		text := w.get('txt_editor').trim_space()
		dec := hex_to_str(text)
		if dec == '' && text != '' {
			w.alert('Hex Decode Error', 'Invalid Hex input string.')
			return
		}
		w.set('txt_editor', dec)
		state.is_dirty = true
		update_telemetry(mut w, state)
		w.toast('Hex Decoded.')
	})

	// Filter: Keep Matching Lines
	win.on_click('btn_filter_keep', fn [mut state, update_telemetry] (mut w simplegui.SimpleWindow) {
		query := w.get('txt_filter_query')
		if query == '' {
			w.alert('Filter', 'Please enter a search query in the filter field.')
			return
		}
		text := w.get('txt_editor')
		lines := text.split_into_lines()
		filtered := lines.filter(it.to_lower().contains(query.to_lower()))
		w.set('txt_editor', filtered.join('\n'))
		state.is_dirty = true
		update_telemetry(mut w, state)
		w.toast('Filtered: Kept ${filtered.len} lines matching "${query}".')
	})

	// Filter: Remove Matching Lines
	win.on_click('btn_filter_remove', fn [mut state, update_telemetry] (mut w simplegui.SimpleWindow) {
		query := w.get('txt_filter_query')
		if query == '' {
			w.alert('Filter', 'Please enter a search query in the filter field.')
			return
		}
		text := w.get('txt_editor')
		lines := text.split_into_lines()
		filtered := lines.filter(!it.to_lower().contains(query.to_lower()))
		w.set('txt_editor', filtered.join('\n'))
		state.is_dirty = true
		update_telemetry(mut w, state)
		w.toast('Filtered: Removed lines matching "${query}" (${filtered.len} remaining).')
	})

	// Extract URLs
	win.on_click('btn_extract_urls', fn (mut w simplegui.SimpleWindow) {
		text := w.get('txt_editor')
		tokens := text.replace('\n', ' ').replace('\r', ' ').replace('\t', ' ').split(' ')
		mut urls := []string{}
		for tok in tokens {
			clean := tok.trim_space()
			if clean.starts_with('http://') || clean.starts_with('https://') || clean.starts_with('ftp://') {
				if !urls.contains(clean) {
					urls << clean
				}
			}
		}
		if urls.len == 0 {
			w.toast('No URLs detected in document.')
			return
		}
		res := urls.join('\n')
		w.copy_to_clipboard(res)
		w.alert('Extracted URLs (${urls.len})', 'Copied ${urls.len} URL(s) to clipboard:\n\n' + res)
	})

	// Extract Emails
	win.on_click('btn_extract_emails', fn (mut w simplegui.SimpleWindow) {
		text := w.get('txt_editor')
		tokens := text.replace('\n', ' ').replace('\r', ' ').replace('\t', ' ').split(' ')
		mut emails := []string{}
		for tok in tokens {
			clean := tok.trim_space()
			if clean.contains('@') && clean.contains('.') && !clean.contains('/') {
				if !emails.contains(clean) {
					emails << clean
				}
			}
		}
		if emails.len == 0 {
			w.toast('No Email addresses detected in document.')
			return
		}
		res := emails.join('\n')
		w.copy_to_clipboard(res)
		w.alert('Extracted Emails (${emails.len})', 'Copied ${emails.len} Email(s) to clipboard:\n\n' + res)
	})

	// Extract IPv4 Addresses
	win.on_click('btn_extract_ips', fn (mut w simplegui.SimpleWindow) {
		text := w.get('txt_editor')
		tokens := text.replace('\n', ' ').replace('\r', ' ').replace('\t', ' ').split(' ')
		mut ips := []string{}
		for tok in tokens {
			clean := tok.trim_space().trim('()[],;"\'')
			parts := clean.split('.')
			if parts.len == 4 {
				mut valid := true
				for p in parts {
					val := p.int()
					if (val == 0 && p != '0') || val < 0 || val > 255 {
						valid = false
						break
					}
				}
				if valid && !ips.contains(clean) {
					ips << clean
				}
			}
		}
		if ips.len == 0 {
			w.toast('No IPv4 addresses detected in document.')
			return
		}
		res := ips.join('\n')
		w.copy_to_clipboard(res)
		w.alert('Extracted IPs (${ips.len})', 'Copied ${ips.len} IP address(es) to clipboard:\n\n' + res)
	})

	// Extract Quoted Strings
	win.on_click('btn_extract_quotes', fn (mut w simplegui.SimpleWindow) {
		text := w.get('txt_editor')
		mut quotes := []string{}
		mut in_quote := false
		mut quote_char := `"`
		mut cur := []u8{}

		for i in 0 .. text.len {
			b := text[i]
			if !in_quote && (b == `"` || b == `'` || b == '`'[0]) {
				in_quote = true
				quote_char = b
				cur.clear()
			} else if in_quote && b == quote_char {
				in_quote = false
				str_val := cur.bytestr()
				if str_val.trim_space() != '' && !quotes.contains(str_val) {
					quotes << str_val
				}
				cur.clear()
			} else if in_quote {
				cur << b
			}
		}

		if quotes.len == 0 {
			w.toast('No quoted strings detected.')
			return
		}
		res := quotes.join('\n')
		w.copy_to_clipboard(res)
		w.alert('Extracted Quotes (${quotes.len})', 'Copied ${quotes.len} quoted string(s) to clipboard:\n\n' + res)
	})

	// CRLF to LF
	win.on_click('btn_crlf_to_lf', fn [mut state, update_telemetry] (mut w simplegui.SimpleWindow) {
		text := w.get('txt_editor')
		normalized := text.replace('\r\n', '\n').replace('\r', '\n')
		w.set('txt_editor', normalized)
		state.is_dirty = true
		update_telemetry(mut w, state)
		w.toast('Normalized all line endings to Unix LF (\\n).')
	})

	// Tabs to Spaces
	win.on_click('btn_tabs_to_spaces', fn [mut state, update_telemetry] (mut w simplegui.SimpleWindow) {
		text := w.get('txt_editor')
		converted := text.replace('\t', '    ')
		w.set('txt_editor', converted)
		state.is_dirty = true
		update_telemetry(mut w, state)
		w.toast('Converted all Tab characters to 4 Spaces.')
	})

	// -------------------------------------------------------------
	// Markdown Live Preview Tab Controls
	// -------------------------------------------------------------
	win.on_click('btn_refresh_md', fn (mut w simplegui.SimpleWindow) {
		text := w.get('txt_editor')
		theme := w.get('dd_theme_selector')
		html := markdown_to_html(text, theme)
		w.set_html('html_preview', html)
		w.toast('Refreshed Markdown preview.')
	})

	win.on_click('btn_copy_html', fn (mut w simplegui.SimpleWindow) {
		text := w.get('txt_editor')
		theme := w.get('dd_theme_selector')
		html := markdown_to_html(text, theme)
		w.copy_to_clipboard(html)
		w.toast('Copied standalone HTML code to clipboard!')
	})

	win.on_click('btn_export_html', fn (mut w simplegui.SimpleWindow) {
		target_path := w.save_file_picker()
		if target_path != '' {
			mut save_file := target_path
			if !save_file.ends_with('.html') && !save_file.ends_with('.htm') {
				save_file += '.html'
			}
			text := w.get('txt_editor')
			theme := w.get('dd_theme_selector')
			html := markdown_to_html(text, theme)
			os.write_file(save_file, html) or {
				w.alert('Export Error', 'Failed to write HTML file.')
				return
			}
			w.toast('Exported HTML to ' + os.file_name(save_file))
		}
	})

	// -------------------------------------------------------------
	// Runner & Execution Studio Controls
	// -------------------------------------------------------------
	win.on_click('btn_clear_console', fn (mut w simplegui.SimpleWindow) {
		w.set('txt_console_output', '=== Console Output Flushed ===\n')
		w.toast('Cleared console.')
	})

	win.on_click('btn_execute_code', fn (mut w simplegui.SimpleWindow) {
		runtime := w.get('dd_runtime')
		args_str := w.get('txt_run_args').trim_space()
		code := w.get('txt_editor')

		if code.trim_space() == '' {
			w.alert('Empty Buffer', 'Editor buffer is empty. Please enter code to execute.')
			return
		}

		w.toast('Executing code via ${runtime}...')

		start_time := time.now()

		// Write code to a safe temporary execution file
		tmp_dir := os.temp_dir()
		mut ext := '.txt'
		mut bin_cmd := ''
		mut bin_args := []string{}

		if runtime.starts_with('V') {
			ext = '.v'
			bin_cmd = 'v'
			bin_args = ['run']
		} else if runtime.starts_with('Python') {
			ext = '.py'
			bin_cmd = 'python3'
		} else if runtime.starts_with('Node') {
			ext = '.js'
			bin_cmd = 'node'
		} else if runtime.starts_with('Bash') {
			ext = '.sh'
			bin_cmd = 'bash'
		} else if runtime.starts_with('Ruby') {
			ext = '.rb'
			bin_cmd = 'ruby'
		} else if runtime.starts_with('Perl') {
			ext = '.pl'
			bin_cmd = 'perl'
		}

		tmp_script := os.join_path(tmp_dir, 'simplegui_text_editor_run_' + rand.uuid_v4() + ext)
		os.write_file(tmp_script, code) or {
			w.alert('Execution Error', 'Failed to create temporary runner file.')
			return
		}

		bin_args << tmp_script
		if args_str != '' {
			for a in args_str.split(' ') {
				if a.trim_space() != '' {
					bin_args << a.trim_space()
				}
			}
		}

		res := simplegui.exec_safe(bin_cmd, bin_args)
		elapsed_ms := (time.now() - start_time).milliseconds()

		// Clean up temporary script file
		os.rm(tmp_script) or {}

		status_badge := if res.exit_code == 0 { ' SUCCESS (Exit 0)' } else { ' FAILED (Exit ${res.exit_code})' }

		mut out := []string{}
		out << '========================================================================'
		out << ' EXECUTION FINISHED: ${runtime}'
		out << 'Status   : ${status_badge}'
		out << 'Duration : ${elapsed_ms} ms'
		out << 'Command  : ${bin_cmd} ' + bin_args.join(' ')
		out << '========================================================================'
		if res.output.trim_space() != '' {
			out << res.output
		} else {
			out << '(Process exited with empty output stdout/stderr)'
		}
		out << '========================================================================\n'

		w.set('txt_console_output', out.join('\n'))
		w.toast('Execution finished in ${elapsed_ms}ms.')
	})

	// -------------------------------------------------------------
	// Telemetry & Statistics Actions
	// -------------------------------------------------------------
	win.on_click('btn_refresh_stats', fn [mut state, update_telemetry] (mut w simplegui.SimpleWindow) {
		update_telemetry(mut w, state)
		w.toast('Refreshed telemetry analytics.')
	})

	win.on_click('btn_copy_stats', fn (mut w simplegui.SimpleWindow) {
		rep := w.get('txt_stats_report')
		w.copy_to_clipboard(rep)
		w.toast('Copied full telemetry report to clipboard!')
	})

	win.on_click('btn_copy_md5', fn (mut w simplegui.SimpleWindow) {
		text := w.get('txt_editor')
		md5_val := md5.hexhash(text)
		w.copy_to_clipboard(md5_val)
		w.toast('Copied MD5 Hash: ' + md5_val)
	})

	win.on_click('btn_copy_sha256', fn (mut w simplegui.SimpleWindow) {
		text := w.get('txt_editor')
		sha_val := sha256.hexhash(text)
		w.copy_to_clipboard(sha_val)
		w.toast('Copied SHA-256 Hash: ' + sha_val)
	})

	// -------------------------------------------------------------
	// Diff & Comparison Studio Actions
	// -------------------------------------------------------------
	win.on_click('btn_run_diff', fn [state] (mut w simplegui.SimpleWindow) {
		target_choice := w.get('dd_diff_target')
		curr_text := w.get('txt_editor')
		mut compare_text := ''
		mut title_b := target_choice

		if target_choice == 'Saved File on Disk' {
			if state.current_file_path != '' && os.exists(state.current_file_path) {
				compare_text = os.read_file(state.current_file_path) or { '' }
			} else {
				compare_text = state.original_content
				title_b = 'Initial Buffer Content'
			}
		} else if target_choice == 'System Clipboard' {
			compare_text = simplegui.clipboard_text()
		} else if target_choice.contains('Buffer 1') {
			compare_text = state.buffers[0].content
		} else if target_choice.contains('Buffer 2') {
			compare_text = state.buffers[1].content
		} else if target_choice.contains('Buffer 3') {
			compare_text = state.buffers[2].content
		} else if target_choice.contains('Buffer 4') {
			compare_text = state.buffers[3].content
		}

		diff_result := generate_unified_diff(curr_text, compare_text, 'Active Editor Buffer', title_b)
		w.set('txt_diff_output', diff_result)
		w.toast('Computed unified diff comparison.')
	})

	win.on_click('btn_copy_diff', fn (mut w simplegui.SimpleWindow) {
		diff_str := w.get('txt_diff_output')
		w.copy_to_clipboard(diff_str)
		w.toast('Copied unified diff to clipboard!')
	})

	// -------------------------------------------------------------
	// Templates Gallery Actions
	// -------------------------------------------------------------
	win.on_change('dd_templates', fn (mut w simplegui.SimpleWindow, selected string) {
		code := get_template_code(selected)
		w.set('txt_template_preview', code)
	})

	win.on_click('btn_load_template', fn [mut state, update_telemetry] (mut w simplegui.SimpleWindow) {
		tmpl := w.get('dd_templates')
		code := get_template_code(tmpl)
		if state.is_dirty {
			if !w.confirm('Overwrite Buffer?', 'Replace current buffer with "${tmpl}" template?') {
				return
			}
		}
		w.set('txt_editor', code)
		state.is_dirty = true
		state.buffers[state.active_buffer_idx].content = code
		update_telemetry(mut w, state)
		w.toast('Loaded "${tmpl}" into active editor.')
	})

	win.on_click('btn_append_template', fn [mut state, update_telemetry] (mut w simplegui.SimpleWindow) {
		tmpl := w.get('dd_templates')
		code := get_template_code(tmpl)
		curr := w.get('txt_editor')
		combined := if curr.trim_space() != '' { curr + '\n\n' + code } else { code }
		w.set('txt_editor', combined)
		state.is_dirty = true
		state.buffers[state.active_buffer_idx].content = combined
		update_telemetry(mut w, state)
		w.toast('Appended "${tmpl}" template.')
	})

	win.on_click('btn_copy_template', fn (mut w simplegui.SimpleWindow) {
		code := w.get('txt_template_preview')
		w.copy_to_clipboard(code)
		w.toast('Copied template snippet to clipboard!')
	})

	// -------------------------------------------------------------
	// Native macOS Application Menus & Context Menus
	// -------------------------------------------------------------
	win.add_menu_item('File', 'New Document', 'n', fn [mut state, update_telemetry] (mut w simplegui.SimpleWindow) {
		state.current_file_path = ''
		state.is_dirty = false
		w.set('txt_editor', '')
		update_telemetry(mut w, state)
	})

	win.add_menu_item('File', 'Open File...', 'o', fn [mut state, update_telemetry] (mut w simplegui.SimpleWindow) {
		chosen := w.select_file()
		if chosen != '' && os.exists(chosen) {
			content := os.read_file(chosen) or { return }
			state.current_file_path = chosen
			state.original_content = content
			state.is_dirty = false
			w.set('txt_editor', content)
			update_telemetry(mut w, state)
		}
	})

	win.add_menu_item('File', 'Save Document', 's', fn [mut state, save_doc, update_telemetry] (mut w simplegui.SimpleWindow) {
		save_doc(mut w, mut state, update_telemetry)
	})

	win.add_menu_item('Edit', 'Copy All Text', 'c', fn (mut w simplegui.SimpleWindow) {
		w.copy_to_clipboard(w.get('txt_editor'))
		w.toast('Copied document.')
	})

	// Right-Click Context Menu Items on txt_editor
	win.add_context_menu_item('txt_editor', ' Copy All to Clipboard', fn (mut w simplegui.SimpleWindow) {
		w.copy_to_clipboard(w.get('txt_editor'))
		w.toast('Copied all text!')
	})

	win.add_context_menu_item('txt_editor', ' Prettify JSON', fn [mut state, update_telemetry] (mut w simplegui.SimpleWindow) {
		text := w.get('txt_editor').trim_space()
		res := simplegui.exec_safe_stdin('python3', ['-m', 'json.tool'], text)
		if res.exit_code == 0 && res.output != '' {
			w.set('txt_editor', res.output)
			state.is_dirty = true
			update_telemetry(mut w, state)
			w.toast('Prettified JSON!')
		}
	})

	win.add_context_menu_item('txt_editor', ' Convert to UPPERCASE', fn [mut state, update_telemetry] (mut w simplegui.SimpleWindow) {
		w.set('txt_editor', w.get('txt_editor').to_upper())
		state.is_dirty = true
		update_telemetry(mut w, state)
	})

	win.add_context_menu_item('txt_editor', ' Convert to lowercase', fn [mut state, update_telemetry] (mut w simplegui.SimpleWindow) {
		w.set('txt_editor', w.get('txt_editor').to_lower())
		state.is_dirty = true
		update_telemetry(mut w, state)
	})

	// Initial Telemetry & View Setup
	update_telemetry(mut win, state)

	println('Text Editor Pro Studio configured. Starting event loop...')
	win.run()
}

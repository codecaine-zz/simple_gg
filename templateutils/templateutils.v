module templateutils

import strings

// ============================================================================
// 1. Template Interpolation Engine
// ============================================================================

// render_template substitutes {{ variable }} and {{ variable | default }} tags in a template string.
pub fn render_template(template string, vars map[string]string) string {
	return render_template_fn(template, fn [vars] (key string) ?string {
		return vars[key] or { return none }
	})
}

// render_template_fn dynamically substitutes {{ variable }} and {{ variable | default }} tags using a resolver function.
pub fn render_template_fn(template string, resolver fn (key string) ?string) string {
	if !template.contains('{{') {
		return template
	}

	mut sb := strings.new_builder(template.len + 32)
	mut i := 0

	for i < template.len {
		if i + 1 < template.len && template[i] == `{` && template[i + 1] == `{` {
			if end_idx := template.index_after('}}', i + 2) {
				tag_content := template[i + 2..end_idx].trim_space()
				mut key := tag_content
				mut default_val := ''
				mut has_default := false

				if tag_content.contains('|') {
					before, after := tag_content.split_once('|') or { tag_content, '' }
					key = before.trim_space()
					default_val = after.trim_space()
					has_default = true
				}

				if val := resolver(key) {
					sb.write_string(val)
				} else if has_default {
					sb.write_string(default_val)
				}
				i = end_idx + 2
				continue
			}
		}
		sb.write_u8(template[i])
		i++
	}

	return sb.str()
}

// ============================================================================
// 2. Terminal Markdown-to-ANSI Formatter
// ============================================================================

// render_markdown_ansi formats markdown text into terminal-friendly ANSI escaped strings.
// Supports headings (#, ##, ###), bold (**text**), italic (*text*), inline code (`code`),
// blockquotes (> text), and bullet lists (- item).
pub fn render_markdown_ansi(markdown string) string {
	lines := markdown.split_into_lines()
	mut formatted_lines := []string{cap: lines.len}
	mut in_code_block := false

	for line in lines {
		trimmed := line.trim_space()

		// Code block fences
		if trimmed.starts_with('```') {
			in_code_block = !in_code_block
			formatted_lines << '\x1b[90m────────────────────────────────────────\x1b[0m'
			continue
		}

		if in_code_block {
			formatted_lines << '  \x1b[36m${line}\x1b[0m'
			continue
		}

		// Headings
		if trimmed.starts_with('### ') {
			heading := format_inline_ansi(trimmed[4..])
			formatted_lines << '\x1b[1m\x1b[34m◆ ${heading}\x1b[0m'
			continue
		}
		if trimmed.starts_with('## ') {
			heading := format_inline_ansi(trimmed[3..])
			formatted_lines << '\x1b[1m\x1b[33m■ ${heading}\x1b[0m'
			continue
		}
		if trimmed.starts_with('# ') {
			heading := format_inline_ansi(trimmed[2..])
			formatted_lines << '\x1b[1m\x1b[36m▲ ${heading}\x1b[0m'
			continue
		}

		// Blockquotes
		if trimmed.starts_with('> ') {
			quote_text := format_inline_ansi(trimmed[2..])
			formatted_lines << '\x1b[90m│\x1b[0m \x1b[3m${quote_text}\x1b[0m'
			continue
		}

		// Bullet lists
		if trimmed.starts_with('- ') || trimmed.starts_with('* ') {
			bullet_text := format_inline_ansi(trimmed[2..])
			formatted_lines << '  \x1b[32m•\x1b[0m ${bullet_text}'
			continue
		}

		// Standard paragraphs with inline styles
		formatted_lines << format_inline_ansi(line)
	}

	return formatted_lines.join('\n')
}

fn format_inline_ansi(text string) string {
	mut sb := strings.new_builder(text.len + 32)
	mut i := 0
	for i < text.len {
		if i + 1 < text.len && text[i] == `*` && text[i + 1] == `*` {
			if end_idx := text.index_after('**', i + 2) {
				bold_content := text[i + 2..end_idx]
				sb.write_string('\x1b[1m${bold_content}\x1b[22m')
				i = end_idx + 2
				continue
			}
		}
		if text[i] == `\`` {
			if end_idx := text.index_after('`', i + 1) {
				code_content := text[i + 1..end_idx]
				sb.write_string('\x1b[36m\x1b[2m`' + code_content + '`\x1b[22m\x1b[39m')
				i = end_idx + 1
				continue
			}
		}
		if text[i] == `*` {
			if end_idx := text.index_after('*', i + 1) {
				italic_content := text[i + 1..end_idx]
				sb.write_string('\x1b[3m${italic_content}\x1b[23m')
				i = end_idx + 1
				continue
			}
		}
		sb.write_u8(text[i])
		i++
	}
	return sb.str()
}

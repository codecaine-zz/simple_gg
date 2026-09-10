module templateutils

fn test_render_template_basic() {
	tpl := 'Hello, {{ name }}! You have {{ count }} notifications.'
	vars := {
		'name':  'Alice'
		'count': '5'
	}
	rendered := render_template(tpl, vars)
	assert rendered == 'Hello, Alice! You have 5 notifications.'
}

fn test_render_template_with_defaults() {
	tpl := 'Welcome {{ user | Guest }}, role is {{ role | Member }}.'
	vars := {
		'role': 'Admin'
	}
	rendered := render_template(tpl, vars)
	assert rendered == 'Welcome Guest, role is Admin.'
}

fn test_render_template_fn() {
	tpl := 'Build #{{ build_num }} on {{ env }}'
	rendered := render_template_fn(tpl, fn (k string) ?string {
		if k == 'build_num' {
			return '420'
		}
		if k == 'env' {
			return 'production'
		}
		return none
	})
	assert rendered == 'Build #420 on production'
}

fn test_render_markdown_ansi() {
	md := '# Main Title\n\nThis is **bold** and *italic* with `code`.\n\n> Important quote\n\n- First point\n\n```\nprintln("hello")\n```'
	ansi := render_markdown_ansi(md)

	// Verify that headings and formatting have ANSI escape sequences
	assert ansi.contains('\x1b[1m') // Bold
	assert ansi.contains('\x1b[3m') // Italic
	assert ansi.contains('•') // Bullet point
	assert ansi.contains('│') // Quote bar
}

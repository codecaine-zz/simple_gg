module main

import templateutils

fn main() {
	println('==================================================')
	println('              demo_templateutils                  ')
	println('==================================================')

	// 1. Template Rendering with Default Fallbacks
	tmpl := 'Hello {{user.name | Guest}}! Your current plan is {{plan | Community}} ({{credits | 100}} credits left).'
	vars := {
		'user.name': 'Alice'
		'plan':      'Enterprise'
	}
	rendered := templateutils.render_template(tmpl, vars)
	println('Template: "${tmpl}"')
	println('Rendered: "${rendered}"')
	assert rendered == 'Hello Alice! Your current plan is Enterprise (100 credits left).'

	// 2. Dynamic Resolver
	tmpl2 := 'Welcome to {{env:APP_NAME | MyApp}} running on {{env:ARCH}}'
	resolved := templateutils.render_template_fn(tmpl2, fn (key string) ?string {
		if key == 'env:APP_NAME' {
			return 'V-Studio'
		}
		if key == 'env:ARCH' {
			return 'arm64'
		}
		return none
	})
	println('\nResolved with callback:\n  "${resolved}"')
	assert resolved == 'Welcome to V-Studio running on arm64'

	// 3. ANSI Markdown Terminal Renderer
	md := '# Main Title\nThis is **bold** and *italic* text with `inline code`.'
	rendered_md := templateutils.render_markdown_ansi(md)
	println('\nRendered Markdown ANSI:')
	println(rendered_md)

	println('\n✔ templateutils demo completed successfully!')
}

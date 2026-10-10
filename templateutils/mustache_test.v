module templateutils

fn test_mustache_escaping_and_raw() {
	data := {
		'name': Value('<b>Ann</b> & "co"')
	}
	assert render_mustache('Hi {{name}}!', data)! == 'Hi &lt;b&gt;Ann&lt;/b&gt; &amp; &quot;co&quot;!'
	assert render_mustache('{{{name}}}|{{& name}}', data)! == '<b>Ann</b> & "co"|<b>Ann</b> & "co"'
	assert render_mustache_text('{{name}}', data)! == '<b>Ann</b> & "co"'
	assert render_mustache('a{{! comment }}b{{missing}}c', data)! == 'abc'
}

fn test_mustache_sections() {
	data := {
		'admin': Value(true)
		'guest': Value(false)
		'count': Value(0)
		'items': Value([Value('x'), Value('y'), Value('z')])
		'users': Value([
			Value({
				'name': Value('Ann')
				'age':  Value(31)
			}),
			Value({
				'name': Value('Bob')
				'age':  Value(27)
			}),
		])
		'user':  Value({
			'profile': Value({
				'city': Value('Oslo')
			})
		})
		'title': Value('T')
	}
	assert render_mustache('{{#admin}}A{{/admin}}{{#guest}}G{{/guest}}{{^guest}}!G{{/guest}}', data)! == 'A!G'
	assert render_mustache('{{#items}}[{{.}}]{{/items}}', data)! == '[x][y][z]'
	assert render_mustache('{{#users}}{{name}}:{{age}} ({{title}}) {{/users}}', data)! == 'Ann:31 (T) Bob:27 (T) '
	assert render_mustache('{{user.profile.city}}|{{user.nope.x}}', data)! == 'Oslo|'
	assert render_mustache('{{#user}}{{#profile}}{{city}}{{/profile}}{{/user}}', data)! == 'Oslo'
	assert render_mustache('{{^count}}none{{/count}}{{^missing}}m{{/missing}}', data)! == 'nonem'
	assert render_mustache('{{#empty}}x{{/empty}}', {
		'empty': Value([]Value{})
	})! == ''
}

fn test_mustache_errors() {
	if _ := render_mustache('{{#a}}x', map[string]Value{}) {
		assert false
	}
	if _ := render_mustache('{{#a}}x{{/b}}', map[string]Value{}) {
		assert false
	}
	if _ := render_mustache('{{oops', map[string]Value{}) {
		assert false
	}
}

fn test_render_template_html() {
	assert render_template_html('<p>{{ msg }}</p>', {
		'msg': '<script>x</script>'
	}) == '<p>&lt;script&gt;x&lt;/script&gt;</p>'
}

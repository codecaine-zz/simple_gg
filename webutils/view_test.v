module webutils

import os
import json2

fn test_escape_by_default() {
	out := render_string('<p><%= name %></p>', {
		'name': '<script>alert("x")</script>'
	})!
	assert out == '<p>&lt;script&gt;alert(&quot;x&quot;)&lt;/script&gt;</p>'
}

fn test_raw_output() {
	out := render_string('<%- html %>|<%= html | safe %>', {
		'html': '<b>hi</b>'
	})!
	assert out == '<b>hi</b>|<b>hi</b>'
}

fn test_comments_and_literal_tags() {
	out := render_string('a<%# hidden %>b <%% x %%> c', map[string]json2.Any{})!
	assert out == 'ab <% x %%> c'
}

fn test_if_elif_else() {
	tpl := '<% if n > 10 %>big<% elif n > 5 %>mid<% else %>small<% end %>'
	assert render_string(tpl, {
		'n': 20
	})! == 'big'
	assert render_string(tpl, {
		'n': 7
	})! == 'mid'
	assert render_string(tpl, {
		'n': 1
	})! == 'small'
}

fn test_ejs_brace_syntax() {
	tpl := '<% if (user) { %>Hi <%= user.name %><% } else { %>Guest<% } %>'
	assert render_string(tpl, {
		'user': json2.Any({
			'name': json2.Any('Ann')
		})
	})! == 'Hi Ann'
	assert render_string(tpl, map[string]json2.Any{})! == 'Guest'
	loop := '<% for (const x of xs) { %>[<%= x %>]<% } %>'
	assert render_string(loop, {
		'xs': json2.Any([json2.Any(1), json2.Any('b')])
	})! == '[1][b]'
}

fn test_for_loop_with_loop_vars_and_else() {
	tpl := '<% for i, x in items %><%= loop.index %>:<%= x %><% if !loop.last %>,<% end %><% else %>none<% end %>'
	assert render_string(tpl, {
		'items': json2.Any([json2.Any('a'), json2.Any('b'), json2.Any('c')])
	})! == '1:a,2:b,3:c'
	assert render_string(tpl, {
		'items': json2.Any([]json2.Any{})
	})! == 'none'
}

fn test_map_iteration() {
	tpl := '<% for k, v in m %><%= k %>=<%= v %>;<% end %>'
	assert render_string(tpl, {
		'm': json2.Any({
			'a': json2.Any(1)
			'b': json2.Any(2)
		})
	})! == 'a=1;b=2;'
}

fn test_trim_blocks_removes_control_lines() {
	tpl := '<ul>\n  <% for x in xs %>\n  <li><%= x %></li>\n  <% end %>\n</ul>'
	out := render_string(tpl, {
		'xs': json2.Any([json2.Any('a'), json2.Any('b')])
	})!
	assert out == '<ul>\n  <li>a</li>\n  <li>b</li>\n</ul>'
}

fn test_trim_markers() {
	assert render_string('a\n<%- "x" -%>\nb', map[string]json2.Any{})! == 'a\nxb'
	assert render_string('a   <%_ set y = 1 _%>   \nb', map[string]json2.Any{})! == 'ab'
}

fn test_expressions() {
	data := {
		'a':    json2.Any(7)
		'b':    json2.Any(2)
		'name': json2.Any('ann')
		'list': json2.Any([json2.Any(1), json2.Any(2), json2.Any(3)])
		'f':    json2.Any(1.5)
	}
	assert render_string('<%= a + b %>|<%= a / b %>|<%= a % b %>|<%= a * f %>', data)! == '9|3.5|1|10.5'
	assert render_string('<%= name + "!" %>|<%= -a %>|<%= (a + 1) * 2 %>', data)! == 'ann!|-7|16'
	assert render_string('<%= a > b && b > 0 %>|<%= a == 7 %>|<%= a === 7 %>|<%= 2 in list %>|<%= 9 not in list %>',
		data)! == 'true|true|true|true|true'
	assert render_string('<%= missing || "default" %>|<%= missing ?? "dflt" %>|<%= a > 5 ? "y" : "n" %>',
		data)! == 'default|dflt|y'
	assert render_string('<%= list.length %>|<%= list[0] %>|<%= list[-1] %>|<%= name.length %>',
		data)! == '3|1|3|3'
	assert render_string('<%= name.toUpperCase() %>|<%= [1, 2, 3] | join("-") %>', data)! == 'ANN|1-2-3'
}

fn test_filters() {
	data := {
		'name':  json2.Any('hello world')
		'price': json2.Any(3.14159)
		'items': json2.Any([json2.Any(3), json2.Any(1), json2.Any(2)])
		'empty': json2.Any('')
		'text':  json2.Any('a\n<b>')
	}
	assert render_string('<%= name | upper %>|<%= name | title %>|<%= name | capitalize %>', data)! == 'HELLO WORLD|Hello World|Hello world'
	assert render_string('<%= name | truncate(8) %>|<%= price | fixed(2) %>|<%= price | round(1) %>',
		data)! == 'hello...|3.14|3.1'
	assert render_string('<%= items | sort | join(",") %>|<%= items | first %>|<%= items | last %>|<%= items | sum %>|<%= items | max %>',
		data)! == '1,2,3|3|2|6|3'
	assert render_string('<%= empty | default("n/a") %>|<%= nothing | default("x") %>', data)! == 'n/a|x'
	assert render_string('<%= text | nl2br %>', data)! == 'a<br>\n&lt;b&gt;'
	assert render_string('<%= "a b&c" | url %>', data)! == 'a%20b%26c'
	assert render_string('<% for i in range(3) %><%= i %><% end %>', data)! == '012'
	assert render_string('<%= 1 | plural("item", "items") %> <%= 2 | plural("item", "items") %>',
		data)! == 'item items'
}

fn test_json_filter_is_script_safe() {
	out := render_string('<script>var d = <%- d | json %>;</script>', {
		'd': json2.Any({
			'x': json2.Any('</script><script>alert(1)</script>')
		})
	})!
	assert !out.contains('</script><script>')
	assert out.contains('\\u003c/script\\u003e')
	// escaped context also stays safe for attributes
	attr := render_string('<div data-x="<%= d | json %>">', {
		'd': json2.Any('"onmouseover="x')
	})!
	assert !attr.contains('"onmouseover')
}

fn test_set_and_scoping() {
	tpl := '<% set total = price * qty %>Total: <%= total %>'
	assert render_string(tpl, {
		'price': json2.Any(5)
		'qty':   json2.Any(3)
	})! == 'Total: 15'
}

fn test_set_does_not_mutate_caller_data() {
	data := {
		'x': json2.Any(1)
	}
	render_string('<% set x = 99 %><%= x %>', data)!
	assert (data['x'] or { json2.Any(0) }) == json2.Any(1)
}

fn test_to_any_struct_respects_skip() {
	struct_user := User{
		name:     'Bob'
		password: 'hunter2'
		roles:    ['admin', 'dev']
	}
	out := render_string('<%= u.name %>:<%= u.roles | join("/") %>:<%= u.password %>', {
		'u': to_any(struct_user)
	})!
	assert out == 'Bob:admin/dev:'
}

struct User {
	name     string
	password string @[json: '-']
	roles    []string
}

fn test_parse_errors_report_line() {
	render_string('line1\n<% if x %>\nno end', map[string]json2.Any{}) or {
		assert err.msg().contains('line 2')
		assert err.msg().contains('never closed')
		return
	}
	assert false
}

fn test_arbitrary_code_rejected() {
	render_string('<% os.system("rm -rf /") %>', map[string]json2.Any{}) or {
		assert err.msg().contains('unsupported statement')
		return
	}
	assert false
}

fn test_unknown_function_rejected() {
	render_string('<%= system("id") %>', map[string]json2.Any{}) or {
		assert err.msg().contains('unknown filter')
		return
	}
	assert false
}

fn test_strict_mode() {
	mut v := new_views(strict: true)
	v.add('t', '<%= nope %>')!
	v.render('t', map[string]json2.Any{}) or {
		assert err.msg().contains('undefined variable')
		return
	}
	assert false
}

fn test_views_include_and_layout_in_memory() {
	mut v := new_views()
	v.add('layouts/main', '<html><title><%= title %></title><body><%- body %></body></html>')!
	v.add('partials/item', '<li><%= item %></li>')!
	v.add('index',
		"<% layout 'layouts/main' %><ul><% for item in items %><%- include('partials/item') %><% end %></ul>")!
	out := v.render('index', {
		'title': json2.Any('A&B')
		'items': json2.Any([json2.Any('<x>'), json2.Any('y')])
	})!
	assert out == '<html><title>A&amp;B</title><body><ul><li>&lt;x&gt;</li><li>y</li></ul></body></html>'
}

fn test_recursive_include_is_bounded() {
	mut v := new_views()
	v.add('loop', "<% include 'loop' %>")!
	v.render('loop', map[string]json2.Any{}) or {
		assert err.msg().contains('depth')
		return
	}
	assert false
}

fn test_views_disk_and_traversal_protection() {
	root := os.join_path(os.temp_dir(), 'webutils_views_${os.getpid()}')
	os.mkdir_all(os.join_path(root, 'partials'))!
	defer {
		os.rmdir_all(root) or {}
	}
	os.write_file(os.join_path(root, 'home.html'), "<h1><%= t %></h1><% include 'partials/foot' %>")!
	os.write_file(os.join_path(root, 'partials', 'foot.html'), '<footer>f</footer>')!
	os.write_file(os.join_path(os.temp_dir(), 'webutils_secret_${os.getpid()}.html'), 'SECRET')!
	mut v := new_views(root: root)
	assert v.render('home', {
		't': json2.Any('Hi')
	})! == '<h1>Hi</h1><footer>f</footer>'
	for bad in ['../webutils_secret_${os.getpid()}', '/etc/passwd', 'a\\..\\b', 'x\0y'] {
		if _ := v.render(bad, map[string]json2.Any{}) {
			assert false, 'should reject ${bad}'
		}
	}
	os.rm(os.join_path(os.temp_dir(), 'webutils_secret_${os.getpid()}.html')) or {}
}

fn test_compile_once_render_many() {
	t := compile('Hi <%= n %>')!
	for i in 0 .. 3 {
		assert t.render({
			'n': json2.Any(i)
		})! == 'Hi ${i}'
	}
}

fn test_quotes_with_tag_close_inside_string() {
	assert render_string('<%= "%>" %>', map[string]json2.Any{})! == '%&gt;'
}

fn test_output_limit() {
	mut v := new_views(max_output: 100)
	v.add('big', '<% for i in range(1000) %>xxxxxxxxxx<% end %>')!
	v.render('big', map[string]json2.Any{}) or {
		assert err.msg().contains('exceeds')
		return
	}
	assert false
}

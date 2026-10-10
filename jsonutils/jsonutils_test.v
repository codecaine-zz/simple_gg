module jsonutils

import json2

fn jp(s string) json2.Any {
	return parse(s) or { panic(err) }
}

fn jc(a json2.Any) string {
	return encode_canonical(a, true)
}

// RFC 6901 §5 example document.
const rfc6901_doc = '{"foo":["bar","baz"],"":0,"a/b":1,"c%d":2,"e^f":3,"g|h":4,"i\\\\j":5,"k\\"l":6," ":7,"m~n":8}'

fn test_rfc6901_examples() {
	d := jp(rfc6901_doc)
	assert jc(pointer_get(d, '')!) == canonical(rfc6901_doc)!
	assert jc(pointer_get(d, '/foo')!) == '["bar","baz"]'
	assert jc(pointer_get(d, '/foo/0')!) == '"bar"'
	assert jc(pointer_get(d, '/')!) == '0'
	assert jc(pointer_get(d, '/a~1b')!) == '1'
	assert jc(pointer_get(d, '/c%d')!) == '2'
	assert jc(pointer_get(d, '/e^f')!) == '3'
	assert jc(pointer_get(d, '/g|h')!) == '4'
	assert jc(pointer_get(d, '/i\\\\j')!) == '5'
	assert jc(pointer_get(d, '/k\\"l')!) == '6'
	assert jc(pointer_get(d, '/ ')!) == '7'
	assert jc(pointer_get(d, '/m~0n')!) == '8'
	if _ := pointer_get(d, '/foo/2') {
		assert false
	}
	if _ := pointer_get(d, '/foo/01') {
		assert false
	}
	if _ := pointer_get(d, 'foo') {
		assert false
	}
}

fn test_pointer_set() {
	d := jp('{"a":{"b":[1,2]}}')
	d2 := pointer_set(d, '/a/b/-', json2.Any(3))!
	assert jc(d2) == '{"a":{"b":[1,2,3]}}'
	d3 := pointer_set(d2, '/a/new/x', json2.Any('y'))!
	assert jc(d3) == '{"a":{"b":[1,2,3],"new":{"x":"y"}}}'
	assert jc(d) == '{"a":{"b":[1,2]}}' // original untouched
}

fn test_rfc7386_examples() {
	cases := [
		['{"a":"b"}', '{"a":"c"}', '{"a":"c"}'],
		['{"a":"b"}', '{"b":"c"}', '{"a":"b","b":"c"}'],
		['{"a":"b"}', '{"a":null}', '{}'],
		['{"a":"b","b":"c"}', '{"a":null}', '{"b":"c"}'],
		['{"a":["b"]}', '{"a":"c"}', '{"a":"c"}'],
		['{"a":"c"}', '{"a":["b"]}', '{"a":["b"]}'],
		['{"a":{"b":"c"}}', '{"a":{"b":"d","c":null}}', '{"a":{"b":"d"}}'],
		['{"a":[{"b":"c"}]}', '{"a":[1]}', '{"a":[1]}'],
		['["a","b"]', '["c","d"]', '["c","d"]'],
		['{"a":"b"}', '["c"]', '["c"]'],
		['{"a":"foo"}', 'null', 'null'],
		['{"a":"foo"}', '"bar"', '"bar"'],
		['{"e":null}', '{"a":1}', '{"a":1,"e":null}'],
		['[1,2]', '{"a":"b","c":null}', '{"a":"b"}'],
		['{}', '{"a":{"bb":{"ccc":null}}}', '{"a":{"bb":{}}}'],
	]
	for t in cases {
		assert merge_patch_str(t[0], t[1])! == t[2], '${t}'
	}
}

fn test_canonical_minify_pretty_equal() {
	assert canonical('{ "b": 1, "a": [true, null, 2.5, "x\\ny"] }')! == '{"a":[true,null,2.5,"x\\ny"],"b":1}'
	assert minify('{ "b" : 1 , "a" : 2 }')!.len < 20
	assert pretty('{"a":1}')!.contains('\n')
	assert deep_equal(jp('{"a":1,"b":[1,2]}'), jp('{"b":[1,2.0],"a":1.0}'))
	assert !deep_equal(jp('{"a":1}'), jp('{"a":"1"}'))
	assert !deep_equal(jp('[1,2]'), jp('[2,1]'))
}

fn test_diff_and_flatten() {
	ch := diff(jp('{"a":1,"b":{"c":[1,2]},"d":true}'), jp('{"a":2,"b":{"c":[1]},"e":null}'))
	assert ch.map('${it.op} ${it.path}') == ['replace /a', 'remove /b/c/1', 'remove /d', 'add /e']
	assert ch[0].old == '1' && ch[0].new == '2'
	assert diff(jp('{"x":[1]}'), jp('{"x":[1.0]}')).len == 0
	f := flatten(jp('{"a":{"b":[10,{"c":"x"}]},"e":{},"n":null}'))
	assert f['a.b.0'] == '10'
	assert f['a.b.1.c'] == 'x'
	assert f['e'] == '{}'
	assert f['n'] == 'null'
}

struct LogEntry {
	level string
	msg   string
}

fn test_ndjson() {
	entries := [
		LogEntry{
			level: 'info'
			msg:   'start'
		},
		LogEntry{
			level: 'warn'
			msg:   'slow'
		},
	]
	encoded := encode_ndjson[LogEntry](entries) or { panic(err) }
	assert encoded.contains('{"level":"info","msg":"start"}\n')
	assert encoded.contains('{"level":"warn","msg":"slow"}\n')

	decoded := decode_ndjson[LogEntry](encoded) or { panic(err) }
	assert decoded.len == 2
	assert decoded[0].level == 'info'
	assert decoded[1].msg == 'slow'
}

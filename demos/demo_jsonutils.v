module main

import jsonutils

fn main() {
	println('=== jsonutils Demo ===')

	// 1. Formatting
	src := '{"b": 2, "a": [1, 2, {"z": true, "y": null}]}'
	println('Minified : ${jsonutils.minify(src) or { panic(err) }}')
	println('Canonical: ${jsonutils.canonical(src) or { panic(err) }}')
	println('Pretty:\n${jsonutils.pretty(src) or { panic(err) }}')

	// 2. JSON Pointer (RFC 6901)
	doc := jsonutils.parse(src) or { panic(err) }
	z := jsonutils.pointer_get(doc, '/a/2/z') or { panic(err) }
	println('/a/2/z = ${z}')
	updated := jsonutils.pointer_set(doc, '/b', jsonutils.parse('42') or { panic(err) }) or {
		panic(err)
	}

	// 3. Structural diff
	for c in jsonutils.diff(doc, updated) {
		println('diff: ${c.op} ${c.path} ${c.old} -> ${c.new}')
	}

	// 4. JSON Merge Patch (RFC 7386)
	merged := jsonutils.merge_patch_str('{"title":"Hello","author":{"name":"Ann","email":"a@x.io"}}',
		'{"title":"Hi","author":{"email":null}}') or { panic(err) }
	println('Merge patch: ${merged}')
	assert merged.contains('"title":"Hi"')
	assert !merged.contains('email')

	// 5. Flatten for logging / config diffing
	println('Flattened: ${jsonutils.flatten(doc)}')

	println('jsonutils demo completed successfully!')
}

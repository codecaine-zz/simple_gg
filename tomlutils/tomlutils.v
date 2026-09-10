module tomlutils

import toml

// TomlDoc provides a high-level wrapper around a parsed TOML document.
pub struct TomlDoc {
pub:
	doc toml.Doc
}

// parse parses TOML content from a string.
pub fn parse(text string) !TomlDoc {
	d := toml.parse_text(text)!
	return TomlDoc{
		doc: d
	}
}

// parse_file reads and parses a TOML file from disk.
pub fn parse_file(path string) !TomlDoc {
	d := toml.parse_file(path)!
	return TomlDoc{
		doc: d
	}
}

// has checks whether a key path exists in the TOML document.
pub fn (t TomlDoc) has(key string) bool {
	if _ := t.doc.value_opt(key) {
		return true
	}
	return false
}

// get_string retrieves a string value at key path, returning default_val if absent or empty.
pub fn (t TomlDoc) get_string(key string, default_val string) string {
	val := t.doc.value(key).default_to(default_val).string()
	if val == '' && default_val != '' && !t.has(key) {
		return default_val
	}
	return val
}

// get_int retrieves an integer value at key path, returning default_val if absent.
pub fn (t TomlDoc) get_int(key string, default_val int) int {
	return t.doc.value(key).default_to(default_val).int()
}

// get_i64 retrieves a 64-bit integer at key path, returning default_val if absent.
pub fn (t TomlDoc) get_i64(key string, default_val i64) i64 {
	return t.doc.value(key).default_to(default_val).i64()
}

// get_bool retrieves a boolean value at key path, returning default_val if absent.
pub fn (t TomlDoc) get_bool(key string, default_val bool) bool {
	return t.doc.value(key).default_to(default_val).bool()
}

// get_f64 retrieves a 64-bit float at key path, returning default_val if absent.
pub fn (t TomlDoc) get_f64(key string, default_val f64) f64 {
	return t.doc.value(key).default_to(default_val).f64()
}

// get_strings retrieves an array of strings at key path.
pub fn (t TomlDoc) get_strings(key string) []string {
	mut res := []string{}
	mut i := 0
	for {
		item_key := '${key}[${i}]'
		if !t.has(item_key) {
			break
		}
		res << t.doc.value(item_key).string()
		i++
	}
	return res
}

// get_ints retrieves an array of integers at key path.
pub fn (t TomlDoc) get_ints(key string) []int {
	mut res := []int{}
	mut i := 0
	for {
		item_key := '${key}[${i}]'
		if !t.has(item_key) {
			break
		}
		res << t.doc.value(item_key).int()
		i++
	}
	return res
}

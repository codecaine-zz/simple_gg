module tomlutils

import toml
import toml.to

// get returns the raw value at a dotted key path (`server.port`, `arr[0]`).
pub fn (t TomlDoc) get(key string) ?toml.Any {
	v := t.doc.value_opt(key) or { return none }
	return v
}

// require_string returns the string at key or an error naming the missing key
// (for mandatory configuration).
pub fn (t TomlDoc) require_string(key string) !string {
	v := t.doc.value_opt(key) or { return error('missing required TOML key "${key}"') }
	return v.string()
}

// require_int returns the integer at key or an error naming the missing key.
pub fn (t TomlDoc) require_int(key string) !int {
	v := t.doc.value_opt(key) or { return error('missing required TOML key "${key}"') }
	return v.int()
}

// get_array returns the elements of the array at key ([] if absent).
pub fn (t TomlDoc) get_array(key string) []toml.Any {
	v := t.doc.value_opt(key) or { return []toml.Any{} }
	return v.array()
}

// get_f64s retrieves an array of floats at key path.
pub fn (t TomlDoc) get_f64s(key string) []f64 {
	return t.get_array(key).map(it.f64())
}

// get_bools retrieves an array of booleans at key path.
pub fn (t TomlDoc) get_bools(key string) []bool {
	return t.get_array(key).map(it.bool())
}

// get_string_map returns a table's entries as strings (`{}` if absent).
pub fn (t TomlDoc) get_string_map(key string) map[string]string {
	v := t.doc.value_opt(key) or { return map[string]string{} }
	return v.as_map().as_strings()
}

// keys returns the sorted keys of the table at key ('' = top level).
pub fn (t TomlDoc) keys(key string) []string {
	m := if key == '' {
		t.doc.to_any().as_map()
	} else {
		v := t.doc.value_opt(key) or { return []string{} }
		v.as_map()
	}
	mut ks := m.keys()
	ks.sort()
	return ks
}

// to_json converts the whole document to a JSON string.
pub fn (t TomlDoc) to_json() string {
	return to.json(t.doc)
}

// decode parses TOML text directly into a struct.
pub fn decode[T](text string) !T {
	return toml.decode[T](text)!
}

// encode serializes a struct to TOML text.
pub fn encode[T](value T) string {
	return toml.encode[T](value)
}

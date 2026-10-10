module configutils

import os
import strconv
import toml
import tomlutils
import json

fn toml_any_to_str(a toml.Any) string {
	return match a {
		string { a }
		int { a.str() }
		i64 { a.str() }
		u64 { a.str() }
		f64 { a.str() }
		f32 { a.str() }
		bool { a.str() }
		else { a.string() }
	}
}

pub struct ConfigOptions {
pub:
	config_path string
	env_prefix  string
	args        []string
	defaults    map[string]string
}

pub struct ConfigStore {
pub mut:
	values  map[string]string
	sources map[string]string
}

pub fn new_config_store() &ConfigStore {
	return &ConfigStore{
		values:  map[string]string{}
		sources: map[string]string{}
	}
}

// load_config loads configuration by cascading Defaults -> File -> Env -> CLI Args
pub fn load_config(opts ConfigOptions) !&ConfigStore {
	mut store := new_config_store()

	// 1. Defaults
	if opts.defaults.len > 0 {
		store.load_defaults(opts.defaults)
	}

	// 2. Config File
	if opts.config_path.len > 0 && os.exists(opts.config_path) {
		store.load_file(opts.config_path)!
	}

	// 3. Environment Variables
	if opts.env_prefix.len > 0 {
		store.load_env(opts.env_prefix)
	}

	// 4. CLI Arguments
	if opts.args.len > 0 {
		store.load_args(opts.args)
	}

	return store
}

// load_defaults registers default key-value pairs
pub fn (mut s ConfigStore) load_defaults(defaults map[string]string) {
	for k, v in defaults {
		s.values[k] = v
		s.sources[k] = 'default'
	}
}

// load_file reads configuration from a TOML or JSON file
pub fn (mut s ConfigStore) load_file(path string) ! {
	if !os.exists(path) {
		return error('config file not found: ${path}')
	}
	content := os.read_file(path)!

	if path.ends_with('.toml') {
		doc := tomlutils.parse(content)!
		for k, v in doc.doc.to_any().as_map() {
			s.values[k] = toml_any_to_str(v)
			s.sources[k] = 'file'
		}
	} else if path.ends_with('.json') {
		raw_map := json.decode(map[string]string, content) or {
			return error('failed to parse json config: ${err}')
		}
		for k, v in raw_map {
			s.values[k] = v
			s.sources[k] = 'file'
		}
	} else {
		// Generic key=value text file fallback
		lines := content.split_into_lines()
		for line in lines {
			trimmed := line.trim_space()
			if trimmed.len == 0 || trimmed.starts_with('#') {
				continue
			}
			parts := trimmed.split_nth('=', 2)
			if parts.len == 2 {
				key := parts[0].trim_space()
				val := parts[1].trim_space().trim('\'"')
				s.values[key] = val
				s.sources[key] = 'file'
			}
		}
	}
}

// load_env scans all environment variables matching the given prefix (e.g. "APP_")
// Converts "APP_SERVER_PORT" to "server_port" and "port"
pub fn (mut s ConfigStore) load_env(prefix string) {
	env_map := os.environ()
	for k, v in env_map {
		if k.starts_with(prefix) {
			key_body := k[prefix.len..].to_lower()
			s.values[key_body] = v
			s.sources[key_body] = 'env'
		}
	}
}

// load_args parses command line arguments and flags (e.g., --port=8080, --host 0.0.0.0, --debug)
pub fn (mut s ConfigStore) load_args(args []string) {
	mut i := 0
	for i < args.len {
		arg := args[i]
		if arg.starts_with('--') {
			body := arg[2..]
			if body.contains('=') {
				parts := body.split_nth('=', 2)
				s.values[parts[0]] = parts[1]
				s.sources[parts[0]] = 'cli'
			} else if i + 1 < args.len && !args[i + 1].starts_with('-') {
				s.values[body] = args[i + 1]
				s.sources[body] = 'cli'
				i++
			} else {
				s.values[body] = 'true'
				s.sources[body] = 'cli'
			}
		} else if arg.starts_with('-') && arg.len > 1 && !arg.starts_with('--') {
			body := arg[1..]
			if body.contains('=') {
				parts := body.split_nth('=', 2)
				s.values[parts[0]] = parts[1]
				s.sources[parts[0]] = 'cli'
			} else if i + 1 < args.len && !args[i + 1].starts_with('-') {
				s.values[body] = args[i + 1]
				s.sources[body] = 'cli'
				i++
			} else {
				s.values[body] = 'true'
				s.sources[body] = 'cli'
			}
		}
		i++
	}
}

// has checks if a key exists
pub fn (s &ConfigStore) has(key string) bool {
	return key in s.values
}

// source_of returns the provenance ('default', 'file', 'env', 'cli') of a key
pub fn (s &ConfigStore) source_of(key string) string {
	return s.sources[key] or { 'none' }
}

// get_string returns the string value or default_val
pub fn (s &ConfigStore) get_string(key string, default_val string) string {
	return s.values[key] or { default_val }
}

// get_int returns the integer value or default_val
pub fn (s &ConfigStore) get_int(key string, default_val int) int {
	val := s.values[key] or { return default_val }
	return strconv.atoi(val) or { default_val }
}

// get_bool returns the boolean value (true, 1, yes) or default_val
pub fn (s &ConfigStore) get_bool(key string, default_val bool) bool {
	val := (s.values[key] or { return default_val }).to_lower()
	return match val {
		'true', '1', 'yes', 'on' { true }
		'false', '0', 'no', 'off' { false }
		else { default_val }
	}
}

// get_f64 returns the float value or default_val
pub fn (s &ConfigStore) get_f64(key string, default_val f64) f64 {
	val := s.values[key] or { return default_val }
	return strconv.atof_quick(val)
}

// get_strings returns a comma-separated or space-separated list of strings
pub fn (s &ConfigStore) get_strings(key string, default_val []string) []string {
	val := s.values[key] or { return default_val }
	mut parts := []string{}
	for p in val.split(',') {
		trimmed := p.trim_space()
		if trimmed.len > 0 {
			parts << trimmed
		}
	}
	if parts.len == 0 {
		return default_val
	}
	return parts
}

// to_map exports all resolved configuration key-values
pub fn (s &ConfigStore) to_map() map[string]string {
	return s.values.clone()
}

// keys returns all configuration keys
pub fn (s &ConfigStore) keys() []string {
	mut k_list := []string{}
	for k, _ in s.values {
		k_list << k
	}
	return k_list
}

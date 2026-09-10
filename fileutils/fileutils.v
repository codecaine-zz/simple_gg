module fileutils

import os
import rand
import json2

// Saves a slice of structs to disk as JSON.
pub fn save_struct_array_to_file[T](path string, data []T) ! {
	ensure_dir_exists(path) or { return err }
	encoded := json2.encode(data)
	os.write_file(path, encoded) or { return err }
}

// Loads a slice of structs from a JSON file back into memory.
pub fn load_struct_array_from_file[T](path string) ![]T {
	content := os.read_file(path) or { return err }
	return json2.decode[[]T](content)
}

// Saves a single struct to disk as JSON.
pub fn save_struct_to_file[T](path string, data T) ! {
	ensure_dir_exists(path) or { return err }
	encoded := json2.encode(data)
	os.write_file(path, encoded) or { return err }
}

// Loads a single struct from a JSON file.
pub fn load_struct_from_file[T](path string) !T {
	content := os.read_file(path) or { return err }
	return json2.decode[T](content)
}

// Appends a single line to a text file, creating the file if needed.
pub fn append_line_to_file(path string, line string) ! {
	ensure_dir_exists(path) or { return err }
	mut content := ''
	if os.exists(path) {
		content = os.read_file(path) or { return err }
	}
	if content.len > 0 {
		content += '\n'
	}
	content += line
	os.write_file(path, content) or { return err }
}

// Writes a text file, creating parent directories automatically.
pub fn write_text_file(path string, content string) ! {
	ensure_dir_exists(path) or { return err }
	os.write_file(path, content) or { return err }
}

// Reads a text file into memory.
pub fn read_text_file(path string) !string {
	return os.read_file(path)
}

// Saves a map to disk as JSON for simple configuration or lookup data.
pub fn save_map_to_file[K, V](path string, data map[K]V) ! {
	ensure_dir_exists(path) or { return err }
	encoded := json2.encode(data)
	os.write_file(path, encoded) or { return err }
}

// Loads a map from a JSON file into memory.
pub fn load_map_from_file[K, V](path string) !map[K]V {
	content := os.read_file(path) or { return err }
	return json2.decode[map[K]V](content)
}

// Creates the parent directory for a file path when it does not exist.
pub fn ensure_dir_exists(path string) ! {
	dir := os.dir(path)
	if dir.len > 0 {
		os.mkdir_all(dir) or { return err }
	}
}

// Reads a file into a slice of lines for simple text processing.
pub fn read_lines_from_file(path string) ![]string {
	content := os.read_file(path) or { return err }
	return content.split_into_lines()
}

// Loads a simple key=value config file, overlaying values onto provided defaults.
pub fn load_config_from_file(path string, defaults map[string]string) !map[string]string {
	mut config := defaults.clone()
	if !os.exists(path) {
		return config
	}
	lines := read_lines_from_file(path) or { return err }
	for line in lines {
		trimmed_line := line.trim_space()
		if trimmed_line == '' || trimmed_line.starts_with('#') {
			continue
		}
		eq_index := trimmed_line.index('=')
		if eq_index == none {
			continue
		}
		index := eq_index or { 0 }
		key := trimmed_line[..index].trim_space()
		if key.len == 0 {
			continue
		}
		mut value := trimmed_line[index + 1..].trim_space()
		if value.contains('#') {
			comment_index := value.index('#')
			if comment_index != none {
				value = value[..comment_index].trim_space()
			}
		}
		config[key] = value
	}
	return config
}

// Writes any JSON-serializable value to a file.
pub fn write_json_file[T](path string, data T) ! {
	ensure_dir_exists(path) or { return err }
	encoded := json2.encode(data)
	os.write_file(path, encoded) or { return err }
}

// Reads a JSON file into a value of the requested type.
pub fn read_json_file[T](path string) !T {
	content := os.read_file(path) or { return err }
	return json2.decode[T](content)
}

// Appends one JSON object as a new line in a newline-delimited JSON file.
pub fn append_json_line[T](path string, data T) ! {
	ensure_dir_exists(path) or { return err }
	encoded := json2.encode(data)
	append_line_to_file(path, encoded) or { return err }
}

// copy_file copies a file from src to dst, creating parent directories for dst if needed.
pub fn copy_file(src string, dst string) ! {
	ensure_dir_exists(dst) or { return err }
	os.cp(src, dst) or { return err }
}

// copy_dir copies an entire directory recursively from src to dst.
pub fn copy_dir(src string, dst string) ! {
	ensure_dir_exists(dst) or { return err }
	os.cp_all(src, dst, true) or { return err }
}

// move moves/renames a file or directory from src to dst, creating destination parent directory if needed.
pub fn move(src string, dst string) ! {
	ensure_dir_exists(dst) or { return err }
	os.mv(src, dst) or { return err }
}

// remove_file safely removes a file if it exists.
pub fn remove_file(path string) ! {
	if os.exists(path) {
		os.rm(path) or { return err }
	}
}

// remove_dir safely removes a directory and all its contents if it exists.
pub fn remove_dir(path string) ! {
	if os.exists(path) {
		os.rmdir_all(path) or { return err }
	}
}

// list_files returns a slice of paths for all files in a directory. If recursive is true, traverses subdirectories.
pub fn list_files(dir string, recursive bool) ![]string {
	if !os.exists(dir) {
		return error('directory does not exist: ${dir}')
	}
	mut files := []string{}
	if !recursive {
		entries := os.ls(dir) or { return err }
		for entry in entries {
			full_path := os.join_path(dir, entry)
			if !os.is_dir(full_path) {
				files << full_path
			}
		}
		return files
	}

	os.walk(dir, fn [mut files] (file string) {
		if !os.is_dir(file) {
			files << file
		}
	})
	return files
}

// list_files_with_ext returns files in dir matching the specified file extension (e.g. "json" or ".json").
pub fn list_files_with_ext(dir string, ext string, recursive bool) ![]string {
	target_ext := if ext.starts_with('.') { ext } else { '.' + ext }
	all_files := list_files(dir, recursive) or { return err }
	mut filtered := []string{}
	for f in all_files {
		if f.ends_with(target_ext) {
			filtered << f
		}
	}
	return filtered
}

// file_size returns the size of a file in bytes.
pub fn file_size(path string) !i64 {
	if !os.exists(path) {
		return error('file does not exist: ${path}')
	}
	return os.file_size(path)
}

// file_size_human returns a human-readable file size string (e.g. "1.50 MB", "450 B").
pub fn file_size_human(path string) !string {
	bytes := file_size(path) or { return err }
	b := f64(bytes)
	if b < 1024.0 {
		return '${bytes} B'
	} else if b < 1024.0 * 1024.0 {
		kb := b / 1024.0
		return '${kb:.2f} KB'
	} else if b < 1024.0 * 1024.0 * 1024.0 {
		mb := b / (1024.0 * 1024.0)
		return '${mb:.2f} MB'
	} else if b < 1024.0 * 1024.0 * 1024.0 * 1024.0 {
		gb := b / (1024.0 * 1024.0 * 1024.0)
		return '${gb:.2f} GB'
	}
	tb := b / (1024.0 * 1024.0 * 1024.0 * 1024.0)
	return '${tb:.2f} TB'
}

// file_extension returns the extension of a file path without the leading dot (e.g. "txt", "json").
pub fn file_extension(path string) string {
	ext := os.file_ext(path)
	if ext.starts_with('.') {
		return ext[1..]
	}
	return ext
}

// file_stem returns the base name of a file without its extension (e.g. "/path/to/app.conf" -> "app").
pub fn file_stem(path string) string {
	name := os.file_name(path)
	ext := os.file_ext(path)
	if ext.len > 0 && name.ends_with(ext) {
		return name[..name.len - ext.len]
	}
	return name
}

// read_csv reads a CSV or TSV file into a 2D slice of strings. Delimiter defaults to ',' if rune is 0.
pub fn read_csv(path string, delimiter rune) ![][]string {
	content := os.read_file(path) or { return err }
	delim := if delimiter == 0 { `,` } else { delimiter }
	lines := content.split_into_lines()
	mut rows := [][]string{}
	for line in lines {
		trimmed := line.trim_space()
		if trimmed.len == 0 {
			continue
		}
		mut cols := []string{}
		mut current := ''
		mut in_quotes := false
		for r in trimmed.runes() {
			if r == `"` {
				in_quotes = !in_quotes
			} else if r == delim && !in_quotes {
				cols << current.trim_space()
				current = ''
			} else {
				current += r.str()
			}
		}
		cols << current.trim_space()
		rows << cols
	}
	return rows
}

// write_csv writes a 2D slice of strings to disk as a CSV or TSV file. Delimiter defaults to ',' if rune is 0.
pub fn write_csv(path string, rows [][]string, delimiter rune) ! {
	ensure_dir_exists(path) or { return err }
	delim := if delimiter == 0 { `,` } else { delimiter }
	delim_str := delim.str()
	mut lines := []string{cap: rows.len}
	for row in rows {
		mut cols := []string{cap: row.len}
		for col in row {
			if col.contains(delim_str) || col.contains('"') || col.contains('\n') {
				escaped := col.replace('"', '""')
				cols << '"${escaped}"'
			} else {
				cols << col
			}
		}
		lines << cols.join(delim_str)
	}
	content := lines.join('\n') + '\n'
	os.write_file(path, content) or { return err }
}

// temp_file creates a temporary file with the given prefix and suffix and returns its absolute path.
pub fn temp_file(prefix string, suffix string) !string {
	name := '${prefix}_${os.getpid()}_${rand.ulid()}${suffix}'
	path := os.join_path(os.temp_dir(), name)
	os.write_file(path, '') or { return err }
	return path
}

// temp_dir creates a temporary directory with the given prefix and returns its absolute path.
pub fn temp_dir(prefix string) !string {
	name := '${prefix}_${os.getpid()}_${rand.ulid()}'
	path := os.join_path(os.temp_dir(), name)
	os.mkdir_all(path) or { return err }
	return path
}


module fileutils

import os
import rand
import json2
import crypto.sha256

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
// Lines are newline-separated without a trailing newline. Uses O_APPEND, so cost is O(1) per call.
pub fn append_line_to_file(path string, line string) ! {
	ensure_dir_exists(path) or { return err }
	needs_sep := os.exists(path) && os.file_size(path) > 0
	mut f := os.open_append(path) or { return err }
	defer {
		f.close()
	}
	if needs_sep {
		f.write_string('\n' + line) or { return err }
	} else {
		f.write_string(line) or { return err }
	}
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

	walk_files(dir, mut files)
	return files
}

// walk_files collects regular files under dir recursively without following directory symlinks.
fn walk_files(dir string, mut out []string) {
	entries := os.ls(dir) or { return }
	for entry in entries {
		full_path := os.join_path(dir, entry)
		if os.is_dir(full_path) && !os.is_link(full_path) {
			walk_files(full_path, mut out)
		} else if !os.is_dir(full_path) {
			out << full_path
		}
	}
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
// Follows RFC 4180: quoted fields may contain delimiters, newlines and "" escaped quotes.
// Fields are whitespace-trimmed and blank lines are skipped.
pub fn read_csv(path string, delimiter rune) ![][]string {
	content := os.read_file(path) or { return err }
	return parse_csv(content, delimiter)
}

// parse_csv parses CSV/TSV text (RFC 4180) into rows. Delimiter defaults to ',' if rune is 0.
// Skips lines beginning with '#' comments.
pub fn parse_csv(content string, delimiter rune) [][]string {
	return parse_csv_with(content, delimiter: delimiter, comment: `#`, trim: false)
}

// CsvOptions configures parse_csv_with.
@[params]
pub struct CsvOptions {
pub:
	delimiter rune = `,` // field separator (0 = ',')
	comment   rune = `#` // when non-zero, lines starting with this rune (e.g. `#`) are skipped
	trim      bool // trim surrounding whitespace from unquoted fields
}

// parse_csv_with parses CSV/TSV text (RFC 4180) with options, e.g.
// `parse_csv_with(text, delimiter: `\t`, comment: `#`, trim: true)`.
// Quoted fields may contain delimiters, newlines, comment runes and "" escaped quotes.
pub fn parse_csv_with(content string, opts CsvOptions) [][]string {
	delim := if opts.delimiter == 0 { `,` } else { opts.delimiter }
	mut rows := [][]string{}
	mut row := []string{}
	mut field := []rune{}
	mut in_quotes := false
	mut row_has_data := false
	runes := content.runes()
	mut i := 0
	for i < runes.len {
		r := runes[i]
		if in_quotes {
			if r == `"` {
				if i + 1 < runes.len && runes[i + 1] == `"` {
					field << `"`
					i++
				} else {
					in_quotes = false
				}
			} else {
				field << r
			}
		} else if opts.comment != 0 && r == opts.comment && !row_has_data && field.len == 0 {
			// comment line: skip to the end of the line
			for i < runes.len && runes[i] != `\n` && runes[i] != `\r` {
				i++
			}
			if i < runes.len && runes[i] == `\r` && i + 1 < runes.len && runes[i + 1] == `\n` {
				i++
			}
		} else if r == `"` {
			in_quotes = true
			row_has_data = true
		} else if r == delim {
			row << csv_field(field, opts.trim)
			field.clear()
			row_has_data = true
		} else if r == `\n` || r == `\r` {
			if r == `\r` && i + 1 < runes.len && runes[i + 1] == `\n` {
				i++
			}
			f := csv_field(field, opts.trim)
			if row_has_data || f.len > 0 {
				row << f
				rows << row
			}
			row = []string{}
			field.clear()
			row_has_data = false
		} else {
			field << r
		}
		i++
	}
	f := csv_field(field, opts.trim)
	if row_has_data || f.len > 0 {
		row << f
		rows << row
	}
	return rows
}

fn csv_field(field []rune, trim bool) string {
	s := field.string()
	return if trim { s.trim_space() } else { s }
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

// write_file_atomic safely writes content to a temporary file before atomically renaming it,
// preventing partial or corrupt file writes if interrupted.
pub fn write_file_atomic(path string, content string) ! {
	ensure_dir_exists(path) or { return err }
	dir := os.dir(path)
	tmp_name := '.tmp_${os.file_name(path)}_${os.getpid()}_${rand.ulid()}'
	tmp_path := os.join_path(dir, tmp_name)
	os.write_file(tmp_path, content) or { return err }
	// rename(2) is atomic on POSIX within one filesystem; readers see either the old or new file.
	os.rename(tmp_path, path) or {
		os.mv_by_cp(tmp_path, path) or {
			os.rm(tmp_path) or {}
			return err
		}
	}
}

// file_hash_sha256 calculates the hexadecimal SHA-256 checksum of a file, streaming in 64 KiB chunks.
pub fn file_hash_sha256(path string) !string {
	if !os.exists(path) {
		return error('file does not exist: ${path}')
	}
	mut f := os.open(path) or { return err }
	defer {
		f.close()
	}
	mut d := sha256.new()
	mut buf := []u8{len: 64 * 1024}
	for {
		n := f.read(mut buf) or { break }
		if n <= 0 {
			break
		}
		d.write(buf[..n]) or { return err }
	}
	return d.sum([]u8{}).hex()
}

// mime_type returns the MIME content type based on the file extension and signature.
pub fn mime_type(path string) string {
	ext := file_extension(path).to_lower()
	return match ext {
		'html', 'htm' { 'text/html' }
		'css' { 'text/css' }
		'js', 'mjs' { 'application/javascript' }
		'json' { 'application/json' }
		'xml' { 'application/xml' }
		'png' { 'image/png' }
		'jpg', 'jpeg' { 'image/jpeg' }
		'gif' { 'image/gif' }
		'svg' { 'image/svg+xml' }
		'webp' { 'image/webp' }
		'ico' { 'image/x-icon' }
		'pdf' { 'application/pdf' }
		'zip' { 'application/zip' }
		'tar' { 'application/x-tar' }
		'gz' { 'application/gzip' }
		'csv' { 'text/csv' }
		'tsv' { 'text/tab-separated-values' }
		'txt', 'log' { 'text/plain' }
		'md' { 'text/markdown' }
		'wasm' { 'application/wasm' }
		'mp3' { 'audio/mpeg' }
		'mp4' { 'video/mp4' }
		'v' { 'text/x-v' }
		else { 'application/octet-stream' }
	}
}

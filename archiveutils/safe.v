module archiveutils

import os
import compress.szip

// ZipLevel selects the compression level used when writing archives.
pub enum ZipLevel {
	store   // no compression (fastest, the v1 default of zip_file/zip_files/zip_dir)
	fast    // best speed
	default // balanced
	best    // best compression
}

fn szip_level(l ZipLevel) szip.CompressionLevel {
	return match l {
		.store { .no_compression }
		.fast { .best_speed }
		.default { .default_level }
		.best { .best_compression }
	}
}

// is_safe_entry_path reports whether an archive entry name stays inside the
// extraction directory: not empty, not absolute, no drive letter, no NUL byte and
// no `..` component. Used to block "zip-slip" path traversal.
pub fn is_safe_entry_path(name string) bool {
	if name.len == 0 || name.contains('\x00') {
		return false
	}
	if name[0] == `/` || name[0] == `\\` || (name.len >= 2 && name[1] == `:`) {
		return false
	}
	for part in name.replace('\\', '/').split('/') {
		if part == '..' {
			return false
		}
	}
	return true
}

// ensure_safe_entries returns an error naming the first entry that would escape
// the extraction directory.
pub fn ensure_safe_entries(zip_file string) ! {
	for e in list_entries(zip_file)! {
		if !is_safe_entry_path(e.name) {
			return error('unsafe path in zip archive (path traversal blocked): "${e.name}"')
		}
	}
}

// ExtractOptions bounds the resources an untrusted archive may consume.
@[params]
pub struct ExtractOptions {
pub:
	max_total_bytes u64 = u64(1) << 30 // sum of uncompressed sizes (default 1 GiB)
	max_entry_bytes u64 // per-entry cap; 0 = only the total applies
	max_entries     int  = 10000
	overwrite       bool = true // false = fail if a target file already exists
}

// extract_safe extracts an untrusted archive: every entry name is validated
// (zip-slip), entry count and uncompressed sizes are bounded (zip bombs), and each
// entry is decoded into a buffer no larger than its declared size, so a lying
// header cannot make it write more. Validation happens before anything is
// written. Returns the number of files written.
pub fn extract_safe(zip_file string, dest_dir string, opts ExtractOptions) !int {
	entries := list_entries(zip_file)!
	if entries.len > opts.max_entries {
		return error('archive has ${entries.len} entries, limit is ${opts.max_entries}')
	}
	mut total := u64(0)
	for e in entries {
		if !is_safe_entry_path(e.name) {
			return error('unsafe path in zip archive (path traversal blocked): "${e.name}"')
		}
		if opts.max_entry_bytes > 0 && e.size > opts.max_entry_bytes {
			return error('entry "${e.name}" is ${e.size} bytes, limit is ${opts.max_entry_bytes}')
		}
		total += e.size
		if total > opts.max_total_bytes {
			return error('archive expands beyond the ${opts.max_total_bytes}-byte limit')
		}
	}
	if !os.exists(dest_dir) {
		os.mkdir_all(dest_dir)!
	}
	mut z := szip.open(zip_file, .no_compression, .read_only)!
	defer {
		z.close()
	}
	n := z.total()!
	mut written := 0
	for i in 0 .. n {
		z.open_entry_by_index(i)!
		name := z.name().clone()
		is_dir := z.is_dir() or { false }
		target := os.join_path(dest_dir, name)
		if is_dir || name.ends_with('/') {
			os.mkdir_all(target)!
		} else {
			if !opts.overwrite && os.exists(target) {
				z.close_entry()
				return error('refusing to overwrite existing file: ${target}')
			}
			parent := os.dir(target)
			if !os.exists(parent) {
				os.mkdir_all(parent)!
			}
			sz := int(z.size())
			mut buf := []u8{len: sz}
			if sz > 0 {
				z.read_entry_buf(buf.data, sz)!
			}
			os.write_file_array(target, buf)!
			written++
		}
		z.close_entry()
	}
	return written
}

// create_zip writes in-memory files (entry name -> content) into dest_zip.
// Names ending in `/` create directory entries. Entry names are validated.
pub fn create_zip(dest_zip string, files map[string][]u8, level ZipLevel) ! {
	for name, _ in files {
		if !is_safe_entry_path(name) {
			return error('unsafe zip entry name: "${name}"')
		}
	}
	ensure_parent(dest_zip)!
	mut z := szip.open(dest_zip, szip_level(level), .write)!
	defer {
		z.close()
	}
	mut names := files.keys()
	names.sort()
	for name in names {
		z.open_entry(name)!
		if !name.ends_with('/') {
			z.write_entry(files[name])!
		}
		z.close_entry()
	}
}

// zip_dir_with recursively compresses a directory with the chosen level
// (zip_dir always stores uncompressed). Entries use `/` separators and paths
// relative to source_dir; symlinks are skipped. Returns the number of entries.
pub fn zip_dir_with(source_dir string, dest_zip string, level ZipLevel) !int {
	if !os.is_dir(source_dir) {
		return error('Source directory does not exist: "${source_dir}"')
	}
	mut files := map[string][]u8{}
	collect(source_dir, '', mut files)!
	create_zip(dest_zip, files, level)!
	return files.len
}

fn collect(root string, rel string, mut files map[string][]u8) ! {
	dir := if rel == '' { root } else { os.join_path(root, rel) }
	for n in os.ls(dir)! {
		full := os.join_path(dir, n)
		r := if rel == '' { n } else { '${rel}/${n}' }
		if os.is_link(full) {
			continue
		}
		if os.is_dir(full) {
			files[r + '/'] = []u8{}
			collect(root, r, mut files)!
		} else {
			files[r] = os.read_bytes(full)!
		}
	}
}

fn ensure_parent(path string) ! {
	d := os.dir(path)
	if d.len > 0 && !os.exists(d) {
		os.mkdir_all(d)!
	}
}

// has_entry reports whether the archive contains an entry with this exact name.
pub fn has_entry(zip_file string, entry_name string) bool {
	entries := list_entries(zip_file) or { return false }
	return entries.any(it.name == entry_name)
}

// total_uncompressed_size sums the declared uncompressed sizes of all entries.
pub fn total_uncompressed_size(zip_file string) !u64 {
	mut total := u64(0)
	for e in list_entries(zip_file)! {
		total += e.size
	}
	return total
}

// read_all_entries loads every file entry into memory (name -> bytes), refusing
// archives whose declared total exceeds max_total_bytes.
pub fn read_all_entries(zip_file string, max_total_bytes u64) !map[string][]u8 {
	if total_uncompressed_size(zip_file)! > max_total_bytes {
		return error('archive expands beyond the ${max_total_bytes}-byte limit')
	}
	mut out := map[string][]u8{}
	for e in list_entries(zip_file)! {
		if !e.is_dir && !e.name.ends_with('/') {
			out[e.name] = read_entry_bytes(zip_file, e.name)!
		}
	}
	return out
}

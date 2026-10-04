module tarutils

import os
import compress.gzip

// create_tar_from_dir archives an entire directory tree (relative paths, `/`
// separators, directories included, symlinks skipped). Returns the entry count.
pub fn create_tar_from_dir(tar_path string, src_dir string) !int {
	entries := collect_dir_entries(src_dir)!
	os.write_file_array(tar_path, pack_bytes(entries))!
	return entries.len
}

// create_tar_gz_from_dir is create_tar_from_dir with gzip compression (.tar.gz).
pub fn create_tar_gz_from_dir(tar_gz_path string, src_dir string) !int {
	entries := collect_dir_entries(src_dir)!
	os.write_file_array(tar_gz_path, pack_bytes_gz(entries)!)!
	return entries.len
}

// collect_dir_entries walks src_dir into TarEntry values in a deterministic (sorted) order.
pub fn collect_dir_entries(src_dir string) ![]TarEntry {
	if !os.is_dir(src_dir) {
		return error('source directory does not exist: ${src_dir}')
	}
	mut out := []TarEntry{}
	walk_into(src_dir, '', mut out)!
	return out
}

fn walk_into(root string, rel string, mut out []TarEntry) ! {
	dir := if rel == '' { root } else { os.join_path(root, rel) }
	mut names := os.ls(dir)!
	names.sort()
	for n in names {
		full := os.join_path(dir, n)
		rel_name := if rel == '' { n } else { '${rel}/${n}' }
		if os.is_link(full) {
			continue
		}
		mtime := os.file_last_mod_unix(full)
		if os.is_dir(full) {
			out << TarEntry{
				name:   rel_name + '/'
				is_dir: true
				mode:   0o755
				mtime:  mtime
			}
			walk_into(root, rel_name, mut out)!
		} else {
			data := os.read_bytes(full)!
			out << TarEntry{
				name:  rel_name
				size:  data.len
				data:  data
				mode:  if os.is_executable(full) { 0o755 } else { 0o644 }
				mtime: mtime
			}
		}
	}
}

// pack_bytes_gz serializes entries into a gzip-compressed tar (.tar.gz) buffer.
pub fn pack_bytes_gz(entries []TarEntry) ![]u8 {
	return gzip.compress(pack_bytes(entries))!
}

// unpack_bytes_gz parses a .tar.gz buffer (plain tar is accepted too).
pub fn unpack_bytes_gz(data []u8) ![]TarEntry {
	if data.len >= 2 && data[0] == 0x1f && data[1] == 0x8b {
		return unpack_bytes(gzip.decompress(data)!)
	}
	return unpack_bytes(data)
}

// create_tar_gz archives files (by base name) into a gzip-compressed tar.
pub fn create_tar_gz(tar_gz_path string, file_paths []string) !bool {
	mut entries := []TarEntry{}
	for path in file_paths {
		if !os.exists(path) {
			return error('file not found: ${path}')
		}
		data := os.read_bytes(path)!
		entries << TarEntry{
			name:  os.file_name(path)
			size:  data.len
			data:  data
			mtime: os.file_last_mod_unix(path)
		}
	}
	os.write_file_array(tar_gz_path, pack_bytes_gz(entries)!)!
	return true
}

// extract_tar_gz unpacks a .tar.gz archive safely (same guarantees as extract_tar).
pub fn extract_tar_gz(tar_gz_path string, dest_dir string) !bool {
	return extract_tar(tar_gz_path, dest_dir)
}

// find_entry returns the entry named `name`, if present.
pub fn find_entry(entries []TarEntry, name string) ?TarEntry {
	for e in entries {
		if e.name == name {
			return e
		}
	}
	return none
}

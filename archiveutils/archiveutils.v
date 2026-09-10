module archiveutils

import os
import compress.szip

// ZipEntry represents an individual file or directory entry within a zip archive.
pub struct ZipEntry {
pub:
	name   string
	size   u64
	is_dir bool
	crc32  u32
}

// is_valid_zip checks if a file exists and begins with the standard ZIP magic header.
pub fn is_valid_zip(path string) bool {
	if !os.exists(path) || os.is_dir(path) {
		return false
	}
	mut f := os.open(path) or { return false }
	defer {
		f.close()
	}
	mut buf := []u8{len: 4}
	read_count := f.read(mut buf) or { return false }
	if read_count < 4 {
		return false
	}
	is_pk := buf[0] == 0x50 && buf[1] == 0x4b
	is_magic := (buf[2] == 0x03 && buf[3] == 0x04) || (buf[2] == 0x05 && buf[3] == 0x06)
	return is_pk && is_magic
}

// zip_file compresses a single file to dest_zip.
pub fn zip_file(source_file string, dest_zip string) ! {
	if !os.exists(source_file) {
		return error('Source file does not exist: "${source_file}"')
	}
	if os.is_dir(source_file) {
		return error('Source path is a directory, use zip_dir instead: "${source_file}"')
	}
	dest_dir := os.dir(dest_zip)
	if dest_dir.len > 0 && !os.exists(dest_dir) {
		os.mkdir_all(dest_dir)!
	}
	szip.zip_files([source_file], dest_zip)!
}

// zip_files compresses multiple files into dest_zip.
pub fn zip_files(source_files []string, dest_zip string) ! {
	for file in source_files {
		if !os.exists(file) {
			return error('Source file does not exist: "${file}"')
		}
	}
	dest_dir := os.dir(dest_zip)
	if dest_dir.len > 0 && !os.exists(dest_dir) {
		os.mkdir_all(dest_dir)!
	}
	szip.zip_files(source_files, dest_zip)!
}

// zip_dir recursively compresses an entire directory to dest_zip.
pub fn zip_dir(source_dir string, dest_zip string) ! {
	if !os.exists(source_dir) || !os.is_dir(source_dir) {
		return error('Source directory does not exist: "${source_dir}"')
	}
	dest_parent := os.dir(dest_zip)
	if dest_parent.len > 0 && !os.exists(dest_parent) {
		os.mkdir_all(dest_parent)!
	}
	szip.zip_folder(source_dir, dest_zip, szip.ZipFolderOptions{})!
}

// unzip_to_dir extracts all files from zip_file into dest_dir.
pub fn unzip_to_dir(zip_file string, dest_dir string) ! {
	if !os.exists(zip_file) {
		return error('Zip archive does not exist: "${zip_file}"')
	}
	if !os.exists(dest_dir) {
		os.mkdir_all(dest_dir)!
	}
	ok := szip.extract_zip_to_dir(zip_file, dest_dir)!
	if !ok {
		return error('Failed to extract archive "${zip_file}" to "${dest_dir}"')
	}
}

// list_entries inspects a zip archive without extracting it, returning metadata for all contained files and directories.
pub fn list_entries(zip_file string) ![]ZipEntry {
	if !os.exists(zip_file) {
		return error('Zip archive does not exist: "${zip_file}"')
	}
	mut z := szip.open(zip_file, .no_compression, .read_only)!
	defer {
		z.close()
	}

	total := z.total()!
	mut entries := []ZipEntry{cap: total}

	for i in 0 .. total {
		z.open_entry_by_index(i) or { continue }
		name := z.name().clone()
		size := z.size()
		is_dir := z.is_dir() or { false }
		crc := z.crc32()
		entries << ZipEntry{
			name: name
			size: size
			is_dir: is_dir
			crc32: crc
		}
		z.close_entry()
	}
	return entries
}

// read_entry_bytes extracts the content of a specific entry from zip_file directly into memory.
pub fn read_entry_bytes(zip_file string, entry_name string) ![]u8 {
	if !os.exists(zip_file) {
		return error('Zip archive does not exist: "${zip_file}"')
	}
	mut z := szip.open(zip_file, .no_compression, .read_only)!
	defer {
		z.close()
	}

	z.open_entry(entry_name)!
	defer {
		z.close_entry()
	}

	sz := int(z.size())
	if sz == 0 {
		return []u8{}
	}

	mut buf := []u8{len: sz}
	z.read_entry_buf(buf.data, sz)!
	return buf
}

// read_entry_string extracts a text entry from zip_file directly as a string.
pub fn read_entry_string(zip_file string, entry_name string) !string {
	bytes := read_entry_bytes(zip_file, entry_name)!
	return bytes.bytestr()
}

module tarutils

import os
import strconv

// TarEntry represents a file or directory stored within a TAR archive.
pub struct TarEntry {
pub:
	name   string
	size   int
	is_dir bool
	data   []u8
}

// pack_bytes serializes a slice of TarEntry structs into a POSIX ustar TAR byte buffer.
pub fn pack_bytes(entries []TarEntry) []u8 {
	mut buf := []u8{}
	for entry in entries {
		mut header := []u8{len: 512, init: 0}
		for i in 0 .. entry.name.len {
			if i >= 100 {
				break
			}
			header[i] = entry.name[i]
		}
		mode := if entry.is_dir { '0000755\x00' } else { '0000644\x00' }
		for i in 0 .. mode.len {
			header[100 + i] = mode[i]
		}
		uid := '0000000\x00'
		for i in 0 .. uid.len {
			header[108 + i] = uid[i]
			header[116 + i] = uid[i]
		}

		size_oct := '${entry.size:011o}\x00'
		for i in 0 .. size_oct.len {
			header[124 + i] = size_oct[i]
		}
		mtime := '00000000000\x00'
		for i in 0 .. mtime.len {
			header[136 + i] = mtime[i]
		}
		for i in 0 .. 8 {
			header[148 + i] = ` `
		}
		header[156] = if entry.is_dir { `5` } else { `0` }
		magic := 'ustar\x00'
		for i in 0 .. magic.len {
			header[257 + i] = magic[i]
		}
		header[263] = `0`
		header[264] = `0`

		mut sum := 0
		for b in header {
			sum += int(b)
		}
		chk := '${sum:06o}\x00 '
		for i in 0 .. chk.len {
			header[148 + i] = chk[i]
		}

		buf << header
		if !entry.is_dir && entry.data.len > 0 {
			buf << entry.data
			padding := (512 - (entry.data.len % 512)) % 512
			for _ in 0 .. padding {
				buf << 0
			}
		}
	}
	// two empty 512-byte blocks denoting end of archive
	for _ in 0 .. 1024 {
		buf << 0
	}
	return buf
}

// unpack_bytes parses a raw POSIX ustar byte buffer into TarEntry structs.
pub fn unpack_bytes(data []u8) ![]TarEntry {
	mut entries := []TarEntry{}
	mut offset := 0
	for offset + 512 <= data.len {
		block := data[offset..offset + 512]
		mut is_all_zero := true
		for b in block {
			if b != 0 {
				is_all_zero = false
				break
			}
		}
		if is_all_zero {
			break
		}

		mut name_len := 0
		for i in 0 .. 100 {
			if block[i] == 0 {
				break
			}
			name_len++
		}
		name := block[..name_len].bytestr()

		mut size_str := ''
		for i in 124 .. 136 {
			if block[i] == 0 || block[i] == ` ` {
				break
			}
			size_str += block[i].ascii_str()
		}
		size := strconv.parse_uint(size_str.trim_space(), 8, 64) or { 0 }
		typeflag := block[156]
		is_dir := typeflag == `5`

		offset += 512
		mut entry_data := []u8{}
		if !is_dir && size > 0 {
			if offset + int(size) > data.len {
				return error('corrupted tar block size exceeds data length')
			}
			entry_data = data[offset..offset + int(size)].clone()
			padding := (512 - (int(size) % 512)) % 512
			offset += int(size) + padding
		}

		entries << TarEntry{
			name: name
			size: int(size)
			is_dir: is_dir
			data: entry_data
		}
	}
	return entries
}

// create_tar archives one or more files into a TAR archive file on disk.
pub fn create_tar(tar_path string, file_paths []string) !bool {
	mut entries := []TarEntry{}
	for path in file_paths {
		if !os.exists(path) {
			return error('file not found: ${path}')
		}
		data := os.read_bytes(path)!
		base_name := os.file_name(path)
		entries << TarEntry{
			name: base_name
			size: data.len
			is_dir: false
			data: data
		}
	}
	raw := pack_bytes(entries)
	os.write_file_array(tar_path, raw)!
	return true
}

// list_tar_entries returns headers for all entries in a TAR file.
pub fn list_tar_entries(tar_path string) ![]TarEntry {
	data := os.read_bytes(tar_path)!
	return unpack_bytes(data)
}

// extract_tar unpacks all entries from a TAR archive into the destination directory.
pub fn extract_tar(tar_path string, dest_dir string) !bool {
	if !os.exists(dest_dir) {
		os.mkdir_all(dest_dir)!
	}
	entries := list_tar_entries(tar_path)!
	for entry in entries {
		target_path := os.join_path(dest_dir, entry.name)
		if entry.is_dir {
			os.mkdir_all(target_path)!
		} else {
			dir := os.dir(target_path)
			if !os.exists(dir) {
				os.mkdir_all(dir)!
			}
			os.write_file_array(target_path, entry.data)!
		}
	}
	return true
}

// read_tar_file retrieves the string content of a specific file in a TAR archive.
pub fn read_tar_file(tar_path string, filename string) !string {
	entries := list_tar_entries(tar_path)!
	for entry in entries {
		if entry.name == filename {
			return entry.data.bytestr()
		}
	}
	return error('file not found in tar archive: ${filename}')
}

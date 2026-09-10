module tarutils

import os

fn test_tar_in_memory_roundtrip() {
	entries := [
		TarEntry{
			name: 'doc.txt'
			size: 13
			is_dir: false
			data: 'Hello, World!'.bytes()
		},
		TarEntry{
			name: 'assets'
			size: 0
			is_dir: true
			data: []u8{}
		},
	]

	raw := pack_bytes(entries)
	assert raw.len % 512 == 0

	unpacked := unpack_bytes(raw) or { panic(err) }
	assert unpacked.len == 2
	assert unpacked[0].name == 'doc.txt'
	assert unpacked[0].size == 13
	assert unpacked[0].is_dir == false
	assert unpacked[0].data.bytestr() == 'Hello, World!'

	assert unpacked[1].name == 'assets'
	assert unpacked[1].is_dir == true
}

fn test_tar_file_disk_roundtrip() {
	tmp_dir := os.join_path(os.temp_dir(), 'tarutils_test_dir')
	os.mkdir_all(tmp_dir) or { panic(err) }
	defer {
		os.rmdir_all(tmp_dir) or {}
	}

	file1 := os.join_path(tmp_dir, 'sample1.txt')
	file2 := os.join_path(tmp_dir, 'sample2.txt')
	os.write_file(file1, 'File 1 content') or { panic(err) }
	os.write_file(file2, 'File 2 content') or { panic(err) }

	tar_path := os.join_path(tmp_dir, 'archive.tar')
	create_tar(tar_path, [file1, file2]) or { panic(err) }
	assert os.exists(tar_path)

	entries := list_tar_entries(tar_path) or { panic(err) }
	assert entries.len == 2
	assert entries.any(it.name == 'sample1.txt')
	assert entries.any(it.name == 'sample2.txt')

	content1 := read_tar_file(tar_path, 'sample1.txt') or { panic(err) }
	assert content1 == 'File 1 content'

	extract_dir := os.join_path(tmp_dir, 'extracted')
	extract_tar(tar_path, extract_dir) or { panic(err) }
	assert os.exists(os.join_path(extract_dir, 'sample1.txt'))
	assert os.exists(os.join_path(extract_dir, 'sample2.txt'))
	assert os.read_file(os.join_path(extract_dir, 'sample1.txt')) or { '' } == 'File 1 content'
}

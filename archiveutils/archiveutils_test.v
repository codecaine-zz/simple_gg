module archiveutils

import os

fn test_zip_file_and_read() {
	test_dir := '.test_archive_single'
	os.mkdir_all(test_dir) or { panic(err) }
	defer {
		os.rmdir_all(test_dir) or {}
	}

	txt_file := '${test_dir}/sample.txt'
	os.write_file(txt_file, 'Antigravity IDE Vlang Utils Zip Test') or { panic(err) }

	zip_out := '${test_dir}/output.zip'
	zip_file(txt_file, zip_out) or { panic(err) }

	assert os.exists(zip_out)
	assert is_valid_zip(zip_out)
	assert !is_valid_zip(txt_file)

	// In-memory reading
	str_val := read_entry_string(zip_out, 'sample.txt') or { panic(err) }
	assert str_val == 'Antigravity IDE Vlang Utils Zip Test'

	bytes_val := read_entry_bytes(zip_out, 'sample.txt') or { panic(err) }
	assert bytes_val.len == 36

	// List entries
	entries := list_entries(zip_out) or { panic(err) }
	assert entries.len == 1
	assert entries[0].name == 'sample.txt'
	assert entries[0].size == 36
	assert !entries[0].is_dir
}

fn test_unzip_to_dir() {
	test_dir := '.test_archive_unzip'
	os.mkdir_all(test_dir) or { panic(err) }
	defer {
		os.rmdir_all(test_dir) or {}
	}

	f1 := '${test_dir}/file1.txt'
	f2 := '${test_dir}/file2.txt'
	os.write_file(f1, 'First File') or { panic(err) }
	os.write_file(f2, 'Second File') or { panic(err) }

	zip_path := '${test_dir}/archive.zip'
	zip_files([f1, f2], zip_path) or { panic(err) }

	extract_dir := '${test_dir}/extracted'
	unzip_to_dir(zip_path, extract_dir) or { panic(err) }

	assert os.exists('${extract_dir}/file1.txt')
	assert os.exists('${extract_dir}/file2.txt')
	assert os.read_file('${extract_dir}/file1.txt') or { '' } == 'First File'
	assert os.read_file('${extract_dir}/file2.txt') or { '' } == 'Second File'
}

fn test_zip_dir() {
	test_dir := '.test_archive_dir'
	os.mkdir_all('${test_dir}/nested/sub') or { panic(err) }
	defer {
		os.rmdir_all(test_dir) or {}
	}

	os.write_file('${test_dir}/root.txt', 'root content') or { panic(err) }
	os.write_file('${test_dir}/nested/sub/leaf.txt', 'leaf content') or { panic(err) }

	zip_out := '${test_dir}_bundle.zip'
	defer {
		os.rm(zip_out) or {}
	}
	zip_dir(test_dir, zip_out) or { panic(err) }

	assert os.exists(zip_out)
	assert is_valid_zip(zip_out)

	entries := list_entries(zip_out) or { panic(err) }
	names := entries.map(it.name)
	assert names.any(it.contains('root.txt'))
	assert names.any(it.contains('leaf.txt'))
}

fn test_invalid_paths() {
	assert !is_valid_zip('non_existent_file.zip')
	if _ := zip_file('non_existent_source.txt', 'test.zip') {
		assert false
	} else {
		assert true
	}
}

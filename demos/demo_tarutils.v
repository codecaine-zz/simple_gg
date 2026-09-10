module main

import os
import tarutils

fn main() {
	println('==================================================')
	println('                demo_tarutils                     ')
	println('==================================================')

	temp_dir := os.join_path(os.temp_dir(), 'demo_tar_${os.getpid()}')
	os.mkdir_all(temp_dir) or { panic(err) }
	defer {
		os.rmdir_all(temp_dir) or {}
	}

	doc1 := os.join_path(temp_dir, 'manifest.json')
	doc2 := os.join_path(temp_dir, 'readme.txt')
	os.write_file(doc1, '{"service": "vlang_utils", "status": "active"}') or { panic(err) }
	os.write_file(doc2, 'POSIX TAR archive demo documentation.') or { panic(err) }

	tar_archive := os.join_path(temp_dir, 'archive.tar')

	// 1. Create TAR archive
	println('1. Creating TAR Archive:')
	tarutils.create_tar(tar_archive, [doc1, doc2]) or { panic(err) }
	println('  Archive written to: ${tar_archive}')

	// 2. List entries
	println('\n2. Inspecting TAR Entries:')
	entries := tarutils.list_tar_entries(tar_archive) or { panic(err) }
	for entry in entries {
		println('  Entry: ${entry.name:15} | Size: ${entry.size:3} bytes | is_dir=${entry.is_dir}')
	}

	// 3. Read specific file from TAR directly
	println('\n3. Reading file directly from TAR:')
	content := tarutils.read_tar_file(tar_archive, os.file_name(doc1)) or { panic(err) }
	println('  Content of ${os.file_name(doc1)}: "${content}"')

	// 4. Extract TAR to destination
	println('\n4. Extracting TAR archive:')
	extract_path := os.join_path(temp_dir, 'extracted')
	tarutils.extract_tar(tar_archive, extract_path) or { panic(err) }
	println('  Extracted all files to: ${extract_path}')

	println('\n✔ tarutils demo completed successfully!')
}

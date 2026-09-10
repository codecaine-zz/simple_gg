module main

import archiveutils
import os

fn main() {
	println('==================================================')
	println('              demo_archiveutils                   ')
	println('==================================================')

	temp_root := os.join_path(os.temp_dir(), 'demo_archive_${os.getpid()}')
	os.mkdir_all(temp_root) or { panic(err) }
	defer {
		os.rmdir_all(temp_root) or {}
	}

	f1 := os.join_path(temp_root, 'file1.txt')
	f2 := os.join_path(temp_root, 'file2.txt')
	os.write_file(f1, 'Hello from inside the ZIP archive!') or { panic(err) }
	os.write_file(f2, 'Second file payload.') or { panic(err) }

	zip_path := os.join_path(temp_root, 'bundle.zip')

	// 1. Create zip archive
	println('1. Creating ZIP archive:')
	archiveutils.zip_files([f1, f2], zip_path) or { panic(err) }
	println('  Archive created: ${zip_path}')
	println('  Valid ZIP? ${archiveutils.is_valid_zip(zip_path)}')

	// 2. List entries without extracting
	println('\n2. Inspecting ZIP entries:')
	entries := archiveutils.list_entries(zip_path) or { panic(err) }
	for entry in entries {
		println('  Entry: ${entry.name} (${entry.size} bytes, is_dir=${entry.is_dir})')
	}

	// 3. Read entry directly to string
	println('\n3. Reading entry in-memory:')
	content := archiveutils.read_entry_string(zip_path, os.file_name(f1)) or { panic(err) }
	println('  Content of ${os.file_name(f1)}: "${content}"')

	// 4. Extract archive
	println('\n4. Extracting archive:')
	extract_dir := os.join_path(temp_root, 'extracted')
	archiveutils.unzip_to_dir(zip_path, extract_dir) or { panic(err) }
	println('  Extracted to: ${extract_dir}')

	println('\n✔ archiveutils demo completed successfully!')
}

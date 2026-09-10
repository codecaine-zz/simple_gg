module main

import os
import fileutils

struct ServerConfig {
	host string
	port int
	ssl  bool
}

fn main() {
	println('==================================================')
	println('               demo_fileutils                     ')
	println('==================================================')

	demo_dir := fileutils.temp_dir('vlang_demo_files_') or { '.demo_files_tmp' }
	defer {
		fileutils.remove_dir(demo_dir) or {}
	}
	println('Working directory: ${demo_dir}')

	// 1. Text file operations
	txt_path := os.join_path(demo_dir, 'notes.txt')
	fileutils.write_text_file(txt_path, 'First line')!
	fileutils.append_line_to_file(txt_path, 'Second line')!
	lines := fileutils.read_lines_from_file(txt_path)!
	println('Read ${lines.len} lines from notes.txt: ${lines}')
	assert lines.len == 2

	// 2. Struct JSON serialization
	cfg_path := os.join_path(demo_dir, 'config.json')
	cfg := ServerConfig{
		host: '127.0.0.1'
		port: 8080
		ssl: true
	}
	fileutils.save_struct_to_file(cfg_path, cfg)!
	loaded_cfg := fileutils.load_struct_from_file[ServerConfig](cfg_path)!
	println('Loaded config: host=${loaded_cfg.host}, port=${loaded_cfg.port}, ssl=${loaded_cfg.ssl}')
	assert loaded_cfg.port == 8080

	// 3. Struct array JSON serialization
	servers := [
		ServerConfig{ host: 'primary', port: 80, ssl: false },
		ServerConfig{ host: 'backup', port: 443, ssl: true },
	]
	arr_path := os.join_path(demo_dir, 'servers.json')
	fileutils.save_struct_array_to_file(arr_path, servers)!
	loaded_servers := fileutils.load_struct_array_from_file[ServerConfig](arr_path)!
	println('Loaded ${loaded_servers.len} servers from JSON array')
	assert loaded_servers.len == 2

	// 4. CSV operations
	csv_path := os.join_path(demo_dir, 'data.csv')
	csv_data := [
		['id', 'name', 'role'],
		['1', 'Alice', 'admin'],
		['2', 'Bob', 'user'],
	]
	fileutils.write_csv(csv_path, csv_data, `,`)!
	read_csv_rows := fileutils.read_csv(csv_path, `,`)!
	println('CSV rows count: ${read_csv_rows.len}')
	assert read_csv_rows.len == 3

	// 5. File inspection and path helpers
	size := fileutils.file_size(csv_path)!
	human_size := fileutils.file_size_human(csv_path)!
	ext := fileutils.file_extension(csv_path)
	stem := fileutils.file_stem(csv_path)
	println('File ${csv_path}: size=${size}B (${human_size}), ext=${ext}, stem=${stem}')
	assert ext == 'csv'
	assert stem == 'data'

	// 6. Directory and file copy/move/list
	copy_target := os.join_path(demo_dir, 'data_copy.csv')
	fileutils.copy_file(csv_path, copy_target)!
	files := fileutils.list_files(demo_dir, false)!
	println('Files in directory: ${files.len} files listed')
	assert files.len >= 3

	println('\n✔ fileutils demo completed successfully!')
}

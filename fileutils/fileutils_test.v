module fileutils

import os

struct Person {
	name string
	age  int
}

fn test_save_and_load_struct_array() {
	file_path := '/tmp/person_array.json'
	people := [Person{
		name: 'Alice'
		age:  30
	}, Person{
		name: 'Bob'
		age:  25
	}]

	save_struct_array_to_file(file_path, people) or { panic(err) }
	loaded := load_struct_array_from_file[Person](file_path) or { panic(err) }

	assert loaded.len == people.len
	assert loaded[0].name == people[0].name
	assert loaded[0].age == people[0].age
	assert loaded[1].name == people[1].name
	assert loaded[1].age == people[1].age

	os.rm(file_path) or {}
}

fn test_save_and_load_struct() {
	file_path := '/tmp/person.json'
	person := Person{
		name: 'Charlie'
		age:  40
	}

	save_struct_to_file(file_path, person) or { panic(err) }
	loaded := load_struct_from_file[Person](file_path) or { panic(err) }

	assert loaded.name == person.name
	assert loaded.age == person.age

	os.rm(file_path) or {}
}

fn test_append_line_to_file() {
	file_path := '/tmp/notes.txt'

	append_line_to_file(file_path, 'first line') or { panic(err) }
	append_line_to_file(file_path, 'second line') or { panic(err) }

	content := os.read_file(file_path) or { panic(err) }
	assert content.contains('first line')
	assert content.contains('second line')

	os.rm(file_path) or {}
}

fn test_save_and_load_map() {
	file_path := '/tmp/maps/config.json'
	mut data := map[string]int{}
	data['one'] = 1
	data['two'] = 2

	save_map_to_file(file_path, data) or { panic(err) }
	loaded := load_map_from_file[string, int](file_path) or { panic(err) }

	assert loaded['one'] == 1
	assert loaded['two'] == 2

	os.rm('/tmp/maps') or {}
}

fn test_ensure_dir_exists() {
	path := '/tmp/rad-demo/nested/file.txt'
	ensure_dir_exists(path) or { panic(err) }
	assert os.exists('/tmp/rad-demo/nested')

	os.rm('/tmp/rad-demo') or {}
}

fn test_read_lines_from_file() {
	file_path := '/tmp/lines.txt'
	os.write_file(file_path, 'alpha\nbeta\n') or { panic(err) }

	lines := read_lines_from_file(file_path) or { panic(err) }
	assert lines.len == 2
	assert lines[0] == 'alpha'
	assert lines[1] == 'beta'

	os.rm(file_path) or {}
}

fn test_load_config_from_file() {
	file_path := '/tmp/app.conf'
	os.write_file(file_path, 'name=demo\n# comment\nport=8080\n') or { panic(err) }

	defaults := {
		'host': 'localhost'
		'port': '3000'
	}
	config := load_config_from_file(file_path, defaults) or { panic(err) }

	assert config['host'] == 'localhost'
	assert config['name'] == 'demo'
	assert config['port'] == '8080'

	os.rm(file_path) or {}
}

fn test_append_line_to_file_creates_parent_directories() {
	os.rmdir_all('/tmp/nested') or {}
	file_path := '/tmp/nested/dir/notes.log'

	append_line_to_file(file_path, 'hello from nested dir') or { panic(err) }

	assert os.exists(file_path)
	assert os.read_file(file_path) or { panic(err) } == 'hello from nested dir'

	os.rmdir_all('/tmp/nested') or {}
}

fn test_write_and_read_text_file() {
	file_path := '/tmp/text/demo.txt'
	content := 'line 1\nline 2\n'

	write_text_file(file_path, content) or { panic(err) }
	loaded := read_text_file(file_path) or { panic(err) }

	assert loaded == content

	os.rm('/tmp/text') or {}
}

fn test_load_config_from_file_supports_comments_and_empty_values() {
	file_path := '/tmp/app-with-comments.conf'
	os.write_file(file_path, 'name=demo\nempty=\nport=8080 # comment\n') or { panic(err) }

	defaults := {
		'host': 'localhost'
	}
	config := load_config_from_file(file_path, defaults) or { panic(err) }

	assert config['name'] == 'demo'
	assert config['empty'] == ''
	assert config['port'] == '8080'
	assert config['host'] == 'localhost'

	os.rm(file_path) or {}
}

fn test_write_and_read_json_file() {
	file_path := '/tmp/json/person.json'
	person := Person{
		name: 'Dana'
		age:  35
	}

	write_json_file(file_path, person) or { panic(err) }
	loaded := read_json_file[Person](file_path) or { panic(err) }

	assert loaded.name == person.name
	assert loaded.age == person.age

	os.rm('/tmp/json') or {}
}

fn test_append_json_line() {
	file_path := '/tmp/jsonl/people.ndjson'
	os.rm(file_path) or {}
	person1 := Person{
		name: 'Eli'
		age:  28
	}
	person2 := Person{
		name: 'Fay'
		age:  32
	}

	append_json_line(file_path, person1) or { panic(err) }
	append_json_line(file_path, person2) or { panic(err) }

	lines := read_lines_from_file(file_path) or { panic(err) }
	assert lines.len == 2
	assert lines[0].contains('Eli')
	assert lines[1].contains('Fay')

	os.rm('/tmp/jsonl') or {}
}

fn test_file_and_dir_operations() {
	src := '/tmp/fileutils_test_src.txt'
	dst := '/tmp/nested_dir/fileutils_test_dst.txt'
	write_text_file(src, 'Hello V!') or { panic(err) }

	copy_file(src, dst) or { panic(err) }
	assert os.exists(dst)
	assert (read_text_file(dst) or { '' }) == 'Hello V!'

	mv_dst := '/tmp/nested_dir/fileutils_test_moved.txt'
	move(dst, mv_dst) or { panic(err) }
	assert !os.exists(dst)
	assert os.exists(mv_dst)

	remove_file(src) or { panic(err) }
	assert !os.exists(src)

	remove_dir('/tmp/nested_dir') or { panic(err) }
	assert !os.exists('/tmp/nested_dir')
}

fn test_file_metadata_and_listing() {
	test_dir := '/tmp/fileutils_listing_test'
	os.mkdir_all(test_dir) or { panic(err) }
	f1 := '${test_dir}/doc.txt'
	f2 := '${test_dir}/data.json'
	write_text_file(f1, 'test content') or { panic(err) }
	write_text_file(f2, '{"key": "val"}') or { panic(err) }

	all_files := list_files(test_dir, false) or { panic(err) }
	assert all_files.len == 2

	json_files := list_files_with_ext(test_dir, 'json', false) or { panic(err) }
	assert json_files.len == 1
	assert json_files[0].ends_with('data.json')

	sz := file_size(f1) or { 0 }
	assert sz > 0

	human := file_size_human(f1) or { '' }
	assert human.contains('B')

	assert file_extension('/path/to/archive.tar.gz') == 'gz'
	assert file_extension('/path/to/image.png') == 'png'
	assert file_stem('/path/to/image.png') == 'image'

	remove_dir(test_dir) or {}
}

fn test_csv_operations() {
	csv_path := '/tmp/test_table.csv'
	rows := [
		['id', 'name', 'notes'],
		['1', 'Alice', 'Hello, "world"'],
		['2', 'Bob', 'Simple note'],
	]
	write_csv(csv_path, rows, `,`) or { panic(err) }
	read_rows := read_csv(csv_path, `,`) or { panic(err) }

	assert read_rows.len == 3
	assert read_rows[0][0] == 'id'
	assert read_rows[1][1] == 'Alice'
	assert read_rows[2][1] == 'Bob'

	remove_file(csv_path) or {}
}

fn test_temp_helpers() {
	tf := temp_file('prefix', '.tmp') or { '' }
	assert tf.len > 0
	assert os.exists(tf)
	remove_file(tf) or {}

	td := temp_dir('my_temp') or { '' }
	assert td.len > 0
	assert os.is_dir(td)
	remove_dir(td) or {}
}


module fileutils

import os

struct Rec {
	id   int
	name string
}

fn tmp_root() string {
	p := os.join_path(os.temp_dir(), 'fileutils_adv_${os.getpid()}')
	os.mkdir_all(p) or {}
	return p
}

fn test_safe_join_blocks_traversal() {
	base := '/srv/uploads'
	assert safe_join(base, 'a/b.txt')! == os.join_path(base, 'a', 'b.txt')
	assert safe_join(base, 'a/../b.txt')! == os.join_path(base, 'b.txt')
	assert safe_join(base, './')! == base
	for bad in ['../etc/passwd', 'a/../../x', '/etc/passwd', 'C:\\win', '..\\..\\x'] {
		if _ := safe_join(base, bad) {
			assert false, 'should reject ${bad}'
		}
	}
}

fn test_sanitize_and_unique_path() {
	assert sanitize_filename('re:port?.txt') == 're_port_.txt'
	assert sanitize_filename('../../etc/passwd') == '.._.._etc_passwd'
	assert sanitize_filename('CON.txt') == '_CON.txt'
	assert sanitize_filename('name. . ') == 'name'
	assert sanitize_filename('') == '_'
	assert sanitize_filename('x'.repeat(300)).len == 255
	root := tmp_root()
	p := os.join_path(root, 'report.txt')
	os.write_file(p, 'x')!
	assert unique_path(p) == os.join_path(root, 'report (1).txt')
	assert unique_path(os.join_path(root, 'new.txt')) == os.join_path(root, 'new.txt')
}

fn test_csv_rfc4180() {
	rows := parse_csv('name,quote\r\n"Smith, J","He said ""hi"""\n"multi\nline",x\n\n', `,`)
	assert rows.len == 3
	assert rows[1] == ['Smith, J', 'He said "hi"']
	assert rows[2] == ['multi\nline', 'x']
	assert parse_csv('a\tb', `\t`) == [['a', 'b']]
	assert parse_csv('a,', `,`) == [['a', '']]
}

fn test_append_is_compatible() {
	p := os.join_path(tmp_root(), 'append.txt')
	os.rm(p) or {}
	append_line_to_file(p, 'one')!
	append_line_to_file(p, 'two')!
	assert os.read_file(p)! == 'one\ntwo'
}

fn test_streaming_helpers() {
	root := tmp_root()
	p := os.join_path(root, 'lines.txt')
	mut content := []string{}
	for i in 1 .. 2001 {
		content << 'line ${i}'
	}
	os.write_file(p, content.join('\r\n') + '\n')!
	assert line_count(p)! == 2000
	assert head(p, 2)! == ['line 1', 'line 2']
	assert tail(p, 3)! == ['line 1998', 'line 1999', 'line 2000']
	assert tail(p, 5000)!.len == 2000
	mut seen := &LineAcc{}
	each_line(p, fn [mut seen] (line string, n int) bool {
		seen.count = n
		return n < 10
	})!
	assert seen.count == 10
	q := os.join_path(root, 'copy.txt')
	os.cp(p, q)!
	assert files_equal(p, q)!
	os.write_file(q, 'different')!
	assert !files_equal(p, q)!
	assert !is_binary_file(p)!
	bin := os.join_path(root, 'b.bin')
	os.write_file_array(bin, [u8(1), 0, 2])!
	assert is_binary_file(bin)!
	assert file_hash_sha256(p)!.len == 64
}

fn test_ndjson_touch_dirsize_backup() {
	root := tmp_root()
	p := os.join_path(root, 'data.ndjson')
	os.rm(p) or {}
	append_json_line(p, Rec{1, 'a'})!
	append_json_line(p, Rec{2, 'b'})!
	recs := read_ndjson[Rec](p)!
	assert recs.len == 2 && recs[1].name == 'b'
	t := os.join_path(root, 'sub', 'touched')
	touch(t)!
	assert os.exists(t)
	touch(t)!
	assert dir_size(os.join_path(root, 'sub'))! == 0
	bak := backup_file(p)!
	assert bak.ends_with('.bak') && os.exists(bak)
}

fn test_wildcards_and_find() {
	assert wildcard_match('*.v', 'main.v')
	assert !wildcard_match('*.v', 'main.vv')
	assert wildcard_match('file?.txt', 'file1.txt')
	assert wildcard_match('[a-c]*', 'banana')
	assert !wildcard_match('[!a-c]*', 'banana')
	assert wildcard_match('*_test.*', 'x_test.v')
	assert wildcard_match('a*b*c', 'aXXbYYc')
	assert !wildcard_match('a*b*c', 'aXXbYY')
	root := tmp_root()
	os.mkdir_all(os.join_path(root, 'f', 'g'))!
	os.write_file(os.join_path(root, 'f', 'g', 'x.v'), '')!
	assert find_files(os.join_path(root, 'f'), '*.v')!.len == 1
}

fn test_byte_sizes_and_mime_sniffing() {
	assert format_bytes(512, true) == '512 B'
	assert format_bytes(1536, true) == '1.50 KiB'
	assert format_bytes(1_500_000, false) == '1.50 MB'
	assert format_bytes(-2048, true) == '-2.00 KiB'
	assert parse_bytes('10KB')! == 10240
	assert parse_bytes('1.5 GiB')! == 1610612736
	assert parse_bytes('42')! == 42
	if _ := parse_bytes('lots') {
		assert false
	}
	assert mime_type_from_bytes([u8(0x89), `P`, `N`, `G`, 0x0d]) == 'image/png'
	assert mime_type_from_bytes('%PDF-1.7'.bytes()) == 'application/pdf'
	assert mime_type_from_bytes('  {"a":1}'.bytes()) == 'application/json'
	assert mime_type_from_bytes('<!DOCTYPE html><p>'.bytes()) == 'text/html'
	assert mime_type_from_bytes('hello'.bytes()) == 'text/plain'
	os.rmdir_all(tmp_root()) or {}
}

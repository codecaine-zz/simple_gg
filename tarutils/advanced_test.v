module tarutils

import os

fn tmp(name string) string {
	d := os.join_path(os.temp_dir(), 'tarutils_adv_${name}_${os.getpid()}')
	os.rmdir_all(d) or {}
	os.mkdir_all(d) or { panic(err) }
	return d
}

fn test_safe_entry_path() {
	assert is_safe_entry_path('a/b/c.txt')
	assert is_safe_entry_path('dir/')
	assert is_safe_entry_path('..hidden')
	assert !is_safe_entry_path('')
	assert !is_safe_entry_path('../etc/passwd')
	assert !is_safe_entry_path('a/../../x')
	assert !is_safe_entry_path('/etc/passwd')
	assert !is_safe_entry_path('C:\\Windows\\x')
	assert !is_safe_entry_path('a\\..\\..\\x')
	assert !is_safe_entry_path('a\x00b')
}

fn test_tar_slip_blocked_and_nothing_written() {
	d := tmp('slip')
	defer {
		os.rmdir_all(d) or {}
	}
	raw := pack_bytes([
		TarEntry{
			name: 'innocent.txt'
			data: 'ok'.bytes()
		},
		TarEntry{
			name: '../escaped.txt'
			data: 'pwned'.bytes()
		},
	])
	tar_path := os.join_path(d, 'evil.tar')
	os.write_file_array(tar_path, raw) or { panic(err) }
	dest := os.join_path(d, 'out')
	extract_tar(tar_path, dest) or {
		assert err.msg().contains('path traversal')
		assert !os.exists(os.join_path(d, 'escaped.txt'))
		assert !os.exists(os.join_path(dest, 'innocent.txt'))
		return
	}
	assert false, 'extraction of a tar-slip archive must fail'
}

fn test_symlinks_are_not_materialised() {
	d := tmp('sym')
	defer {
		os.rmdir_all(d) or {}
	}
	raw := pack_bytes([
		TarEntry{
			name:     'link'
			typeflag: `2`
			linkname: '/etc/passwd'
		},
		TarEntry{
			name: 'f.txt'
			data: 'x'.bytes()
		},
	])
	entries := unpack_bytes(raw) or { panic(err) }
	assert entries[0].typeflag == `2`
	assert entries[0].linkname == '/etc/passwd'
	extract_entries(entries, d) or { panic(err) }
	assert !os.exists(os.join_path(d, 'link'))
	assert os.exists(os.join_path(d, 'f.txt'))
}

fn test_long_names_prefix_and_pax() {
	mid := 'dir_' + 'x'.repeat(60) + '/' + 'sub_' + 'y'.repeat(60) + '/file.txt' // > 100, splittable
	huge := 'z'.repeat(180) + '.txt' // no '/' -> needs PAX
	raw := pack_bytes([
		TarEntry{
			name: mid
			data: 'm'.bytes()
		},
		TarEntry{
			name: huge
			data: 'h'.bytes()
		},
	])
	entries := unpack_bytes(raw) or { panic(err) }
	assert entries.len == 2
	assert entries[0].name == mid
	assert entries[0].data.bytestr() == 'm'
	assert entries[1].name == huge
	assert entries[1].data.bytestr() == 'h'
}

fn test_size_field_follows_data() {
	// v1 trusted `size` blindly, producing corrupt archives when it disagreed with data.
	raw := pack_bytes([TarEntry{
		name: 'a'
		size: 999
		data: 'abc'.bytes()
	}])
	e := unpack_bytes(raw) or { panic(err) }
	assert e[0].size == 3
	assert e[0].data.bytestr() == 'abc'
}

fn test_checksum_verified() {
	mut raw := pack_bytes([TarEntry{
		name: 'a.txt'
		data: 'abc'.bytes()
	}])
	raw[10] = `Q` // corrupt the header name
	unpack_bytes(raw) or {
		assert err.msg().contains('checksum')
		return
	}
	assert false
}

fn test_mode_mtime_roundtrip() {
	raw := pack_bytes([TarEntry{
		name:  'run.sh'
		data:  '#!/bin/sh'.bytes()
		mode:  0o755
		mtime: 1700000000
	}])
	e := unpack_bytes(raw) or { panic(err) }
	assert e[0].mode == 0o755
	assert e[0].mtime == 1700000000
}

fn test_dir_roundtrip_and_targz() {
	d := tmp('dir')
	defer {
		os.rmdir_all(d) or {}
	}
	src := os.join_path(d, 'src')
	os.mkdir_all(os.join_path(src, 'nested', 'deep')) or { panic(err) }
	os.write_file(os.join_path(src, 'a.txt'), 'A') or { panic(err) }
	os.write_file(os.join_path(src, 'nested', 'deep', 'b.txt'), 'B') or { panic(err) }

	n := create_tar_gz_from_dir(os.join_path(d, 'x.tar.gz'), src) or { panic(err) }
	assert n == 4 // a.txt, nested/, nested/deep/, nested/deep/b.txt
	entries := list_tar_entries(os.join_path(d, 'x.tar.gz')) or { panic(err) }
	assert find_entry(entries, 'nested/deep/b.txt') or { panic('missing') }.data.bytestr() == 'B'

	out := os.join_path(d, 'out')
	extract_tar_gz(os.join_path(d, 'x.tar.gz'), out) or { panic(err) }
	assert os.read_file(os.join_path(out, 'nested', 'deep', 'b.txt')) or { '' } == 'B'
	assert read_tar_file(os.join_path(d, 'x.tar.gz'), 'a.txt') or { '' } == 'A'
}

fn test_interop_with_system_tar() {
	tar_bin := os.find_abs_path_of_executable('tar') or { return }
	d := tmp('interop')
	defer {
		os.rmdir_all(d) or {}
	}
	long := 'p' + 'q'.repeat(70) + '/' + 'r'.repeat(70) + '.txt'
	// ours -> system tar
	ours := os.join_path(d, 'ours.tar')
	os.write_file_array(ours, pack_bytes([
		TarEntry{
			name: long
			data: 'long'.bytes()
		},
	])) or { panic(err) }
	listing := os.execute('${tar_bin} -tf ${os.quoted_path(ours)}')
	assert listing.exit_code == 0
	assert listing.output.trim_space() == long

	// system tar -> ours (deep, long path)
	src := os.join_path(d, 'src')
	os.mkdir_all(os.join_path(src, 'q'.repeat(90))) or { panic(err) }
	os.write_file(os.join_path(src, 'q'.repeat(90), 'w'.repeat(90) + '.txt'), 'sys') or {
		panic(err)
	}
	theirs := os.join_path(d, 'theirs.tar')
	res := os.execute('cd ${os.quoted_path(src)} && ${tar_bin} -cf ${os.quoted_path(theirs)} .')
	assert res.exit_code == 0
	entries := list_tar_entries(theirs) or { panic(err) }
	want := './' + 'q'.repeat(90) + '/' + 'w'.repeat(90) + '.txt'
	e := find_entry(entries, want) or { panic('system tar entry not found; got ${entries.map(it.name)}') }
	assert e.data.bytestr() == 'sys'
}

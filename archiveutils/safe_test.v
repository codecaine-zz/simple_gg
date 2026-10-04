module archiveutils

import os
import hash.crc32

fn tdir(name string) string {
	d := os.join_path(os.temp_dir(), 'archiveutils_${name}_${os.getpid()}')
	os.rmdir_all(d) or {}
	os.mkdir_all(d) or { panic(err) }
	return d
}

fn le16(mut b []u8, v int) {
	b << u8(v & 0xff)
	b << u8((v >> 8) & 0xff)
}

fn le32(mut b []u8, v u32) {
	for i in 0 .. 4 {
		b << u8((v >> (8 * i)) & 0xff)
	}
}

// raw_stored_zip hand-assembles a STORED zip so hostile names reach the reader
// verbatim (independent of any normalisation in the writer library).
fn raw_stored_zip(files [][]string) []u8 {
	mut out := []u8{}
	mut cd := []u8{}
	for f in files {
		name := f[0]
		data := f[1].bytes()
		crc := crc32.sum(data)
		off := u32(out.len)
		le32(mut out, 0x04034b50)
		le16(mut out, 20)
		le16(mut out, 0)
		le16(mut out, 0)
		le16(mut out, 0)
		le16(mut out, 0x21)
		le32(mut out, crc)
		le32(mut out, u32(data.len))
		le32(mut out, u32(data.len))
		le16(mut out, name.len)
		le16(mut out, 0)
		out << name.bytes()
		out << data

		le32(mut cd, 0x02014b50)
		le16(mut cd, 20)
		le16(mut cd, 20)
		le16(mut cd, 0)
		le16(mut cd, 0)
		le16(mut cd, 0)
		le16(mut cd, 0x21)
		le32(mut cd, crc)
		le32(mut cd, u32(data.len))
		le32(mut cd, u32(data.len))
		le16(mut cd, name.len)
		le16(mut cd, 0)
		le16(mut cd, 0)
		le16(mut cd, 0)
		le16(mut cd, 0)
		le32(mut cd, 0)
		le32(mut cd, off)
		cd << name.bytes()
	}
	cd_off := u32(out.len)
	out << cd
	le32(mut out, 0x06054b50)
	le16(mut out, 0)
	le16(mut out, 0)
	le16(mut out, files.len)
	le16(mut out, files.len)
	le32(mut out, u32(cd.len))
	le32(mut out, cd_off)
	le16(mut out, 0)
	return out
}

fn test_safe_entry_path() {
	assert is_safe_entry_path('a/b.txt')
	assert is_safe_entry_path('dir/')
	assert !is_safe_entry_path('../x')
	assert !is_safe_entry_path('a/../../x')
	assert !is_safe_entry_path('/abs')
	assert !is_safe_entry_path('C:/x')
	assert !is_safe_entry_path('')
}

fn test_zip_slip_blocked() {
	d := tdir('slip')
	defer {
		os.rmdir_all(d) or {}
	}
	zp := os.join_path(d, 'evil.zip')
	os.write_file_array(zp, raw_stored_zip([['ok.txt', 'fine'], ['../../escaped.txt', 'pwned']])) or { panic(err) }
	// The reader sees the hostile name verbatim.
	names := list_entries(zp) or { panic(err) }.map(it.name)
	assert '../../escaped.txt' in names

	out := os.join_path(d, 'a', 'b')
	unzip_to_dir(zp, out) or {
		assert err.msg().contains('path traversal')
		extract_safe(zp, out) or {
			assert err.msg().contains('path traversal')
			assert !os.exists(os.join_path(d, 'escaped.txt'))
			assert !os.exists(os.join_path(out, 'ok.txt'))
			return
		}
		assert false, 'extract_safe accepted a zip-slip archive'
		return
	}
	assert false, 'unzip_to_dir accepted a zip-slip archive'
}

fn test_extract_safe_limits() {
	d := tdir('limits')
	defer {
		os.rmdir_all(d) or {}
	}
	zp := os.join_path(d, 'big.zip')
	create_zip(zp, {
		'a.txt': []u8{len: 5000, init: `a`}
		'b.txt': []u8{len: 5000, init: `b`}
	}, .best) or { panic(err) }
	extract_safe(zp, os.join_path(d, 'o1'), max_total_bytes: 8000) or {
		assert err.msg().contains('limit')
		extract_safe(zp, os.join_path(d, 'o2'), max_entries: 1) or {
			assert err.msg().contains('limit')
			extract_safe(zp, os.join_path(d, 'o3'), max_entry_bytes: 4000) or {
				assert err.msg().contains('limit')
				n := extract_safe(zp, os.join_path(d, 'ok')) or { panic(err) }
				assert n == 2
				assert os.read_file(os.join_path(d, 'ok', 'b.txt')) or { '' } == 'b'.repeat(5000)
				return
			}
		}
	}
	assert false, 'limits were not enforced'
}

fn test_extract_safe_no_overwrite() {
	d := tdir('ow')
	defer {
		os.rmdir_all(d) or {}
	}
	zp := os.join_path(d, 'x.zip')
	create_zip(zp, {
		'f.txt': 'new'.bytes()
	}, .default) or { panic(err) }
	out := os.join_path(d, 'out')
	os.mkdir_all(out) or { panic(err) }
	os.write_file(os.join_path(out, 'f.txt'), 'old') or { panic(err) }
	extract_safe(zp, out, overwrite: false) or {
		assert os.read_file(os.join_path(out, 'f.txt')) or { '' } == 'old'
		return
	}
	assert false
}

fn test_compressed_dir_roundtrip() {
	d := tdir('dir')
	defer {
		os.rmdir_all(d) or {}
	}
	src := os.join_path(d, 'src')
	os.mkdir_all(os.join_path(src, 'sub')) or { panic(err) }
	payload := 'compress me '.repeat(500)
	os.write_file(os.join_path(src, 'sub', 'big.txt'), payload) or { panic(err) }
	os.write_file(os.join_path(src, 'top.txt'), 'top') or { panic(err) }

	stored := os.join_path(d, 'stored.zip')
	packed := os.join_path(d, 'packed.zip')
	zip_dir_with(src, stored, .store) or { panic(err) }
	n := zip_dir_with(src, packed, .best) or { panic(err) }
	assert n == 3 // sub/, sub/big.txt, top.txt
	assert os.file_size(packed) < os.file_size(stored)

	assert has_entry(packed, 'sub/big.txt')
	assert !has_entry(packed, 'nope.txt')
	assert total_uncompressed_size(packed) or { 0 } == u64(payload.len + 3)
	all := read_all_entries(packed, 1 << 20) or { panic(err) }
	assert all['sub/big.txt'].bytestr() == payload
	read_all_entries(packed, 10) or { return }
	assert false, 'read_all_entries ignored its limit'
}

fn test_create_zip_rejects_unsafe_names() {
	d := tdir('names')
	defer {
		os.rmdir_all(d) or {}
	}
	create_zip(os.join_path(d, 'x.zip'), {
		'../bad': 'x'.bytes()
	}, .store) or { return }
	assert false
}

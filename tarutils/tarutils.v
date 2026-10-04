module tarutils

import os
import strconv
import compress.gzip

// TarEntry represents a file or directory stored within a TAR archive.
pub struct TarEntry {
pub:
	name   string
	size   int
	is_dir bool
	data   []u8
	// v2 additions (all optional, zero values keep the v1 behaviour):
	mode     int    // permission bits; 0 = default (0644 files, 0755 dirs)
	mtime    i64    // modification time in unix seconds
	typeflag u8     // raw ustar type flag (`0` file, `5` dir, `2` symlink...); 0 = derive from is_dir
	linkname string // link target for symlink / hardlink entries
}

// ============================================================================
// Header encoding helpers
// ============================================================================

fn put_str(mut h []u8, off int, max int, s string) {
	n := if s.len < max { s.len } else { max }
	for i in 0 .. n {
		h[off + i] = s[i]
	}
}

// put_oct writes `v` as zero-padded octal into a `width`-byte field (last byte NUL).
fn put_oct(mut h []u8, off int, width int, v i64) {
	val := if v < 0 { i64(0) } else { v }
	mut s := strconv.format_int(val, 8)
	if s.len < width - 1 {
		s = '0'.repeat(width - 1 - s.len) + s
	}
	put_str(mut h, off, width - 1, s)
	h[off + width - 1] = 0
}

// put_size writes the 12-byte size field, switching to GNU base-256 encoding for
// sizes that do not fit in 11 octal digits (>= 8 GiB).
fn put_size(mut h []u8, off int, size i64) {
	if size < 0o77777777777 {
		put_oct(mut h, off, 12, size)
		return
	}
	h[off] = 0x80
	mut v := u64(size)
	for i := 11; i >= 1; i-- {
		h[off + i] = u8(v & 0xff)
		v >>= 8
	}
}

fn write_header(mut buf []u8, name string, prefix string, mode int, size i64, mtime i64, typeflag u8, linkname string) {
	mut h := []u8{len: 512, init: 0}
	put_str(mut h, 0, 100, name)
	put_oct(mut h, 100, 8, mode)
	put_oct(mut h, 108, 8, 0) // uid
	put_oct(mut h, 116, 8, 0) // gid
	put_size(mut h, 124, size)
	put_oct(mut h, 136, 12, mtime)
	for i in 0 .. 8 {
		h[148 + i] = ` `
	}
	h[156] = typeflag
	put_str(mut h, 157, 100, linkname)
	put_str(mut h, 257, 6, 'ustar\x00')
	h[263] = `0`
	h[264] = `0`
	put_str(mut h, 345, 155, prefix)
	mut sum := 0
	for b in h {
		sum += int(b)
	}
	chk := '${sum:06o}\x00 '
	for i in 0 .. chk.len {
		h[148 + i] = chk[i]
	}
	buf << h
}

fn pad_block(mut buf []u8, n int) {
	padding := (512 - (n % 512)) % 512
	for _ in 0 .. padding {
		buf << 0
	}
}

// split_ustar_name splits a long path into (prefix, name) per POSIX ustar, or
// returns ok=false when no split fits the 155/100 byte limits.
fn split_ustar_name(path string) (string, string, bool) {
	if path.len <= 100 {
		return '', path, true
	}
	for i := path.len - 1; i > 0; i-- {
		if path[i] == `/` && i <= 155 && path.len - i - 1 <= 100 && path.len - i - 1 > 0 {
			return path[..i], path[i + 1..], true
		}
	}
	return '', '', false
}

fn pax_record(key string, value string) string {
	content := ' ${key}=${value}\n'
	mut digits := content.len.str().len
	for (content.len + digits).str().len != digits {
		digits++
	}
	return '${content.len + digits}${content}'
}

// pack_bytes serializes a slice of TarEntry structs into a POSIX ustar TAR byte buffer.
// Long names use the ustar prefix field and, when that is not enough, a PAX
// extended header, so no path is ever silently truncated.
pub fn pack_bytes(entries []TarEntry) []u8 {
	mut buf := []u8{}
	for entry in entries {
		typeflag := if entry.typeflag != 0 {
			entry.typeflag
		} else if entry.is_dir {
			`5`
		} else {
			`0`
		}
		is_regular := typeflag == `0` || typeflag == `7`
		mode := if entry.mode != 0 {
			entry.mode
		} else if entry.is_dir {
			0o755
		} else {
			0o644
		}
		size := if is_regular { i64(entry.data.len) } else { i64(0) }

		mut prefix, mut name, ok := split_ustar_name(entry.name)
		mut pax := ''
		if !ok {
			pax += pax_record('path', entry.name)
			prefix = ''
			name = entry.name[..100]
		}
		mut linkname := entry.linkname
		if linkname.len > 100 {
			pax += pax_record('linkpath', linkname)
			linkname = linkname[..100]
		}
		if pax.len > 0 {
			base := os.file_name(entry.name)
			pax_name := 'PaxHeaders/' + (if base.len > 80 { base[..80] } else { base })
			write_header(mut buf, pax_name, '', 0o644, pax.len, entry.mtime, `x`, '')
			buf << pax.bytes()
			pad_block(mut buf, pax.len)
		}
		write_header(mut buf, name, prefix, mode, size, entry.mtime, typeflag, linkname)
		if size > 0 {
			buf << entry.data
			pad_block(mut buf, entry.data.len)
		}
	}
	// two empty 512-byte blocks denoting end of archive
	for _ in 0 .. 1024 {
		buf << 0
	}
	return buf
}

// ============================================================================
// Header decoding helpers
// ============================================================================

fn cstr(b []u8) string {
	mut n := 0
	for n < b.len && b[n] != 0 {
		n++
	}
	return b[..n].bytestr()
}

// parse_numeric decodes an octal (or GNU base-256) numeric header field.
fn parse_numeric(field []u8) !i64 {
	if field.len > 0 && field[0] & 0x80 != 0 {
		mut v := u64(field[0] & 0x7f)
		for i in 1 .. field.len {
			v = (v << 8) | u64(field[i])
		}
		return i64(v)
	}
	s := cstr(field).trim(' \t')
	if s.len == 0 {
		return 0
	}
	return i64(strconv.parse_uint(s, 8, 64) or { return error('invalid numeric tar field "${s}"') })
}

fn checksum_ok(block []u8) bool {
	stored := parse_numeric(block[148..156]) or { return false }
	mut unsigned := i64(0)
	mut signed := i64(0)
	for i, b in block {
		c := if i >= 148 && i < 156 { u8(` `) } else { b }
		unsigned += i64(c)
		signed += i64(i8(c))
	}
	return stored == unsigned || stored == signed
}

fn is_zero_block(block []u8) bool {
	for b in block {
		if b != 0 {
			return false
		}
	}
	return true
}

fn parse_pax(payload []u8, mut out map[string]string) {
	text := payload.bytestr()
	mut pos := 0
	for pos < text.len {
		sp := text.index_after(' ', pos) or { return }
		rec_len := text[pos..sp].int()
		if rec_len <= 0 || pos + rec_len > text.len {
			return
		}
		rec := text[sp + 1..pos + rec_len].trim_right('\n')
		if eq := rec.index('=') {
			out[rec[..eq]] = rec[eq + 1..]
		}
		pos += rec_len
	}
}

// unpack_bytes parses a raw POSIX ustar byte buffer into TarEntry structs.
// Supports the ustar prefix field, PAX extended headers (path, linkpath, size),
// GNU long names (`L`/`K`) and GNU base-256 sizes; header checksums are verified.
pub fn unpack_bytes(data []u8) ![]TarEntry {
	mut entries := []TarEntry{}
	mut offset := 0
	mut pax := map[string]string{}
	mut gnu_name := ''
	mut gnu_link := ''
	for offset + 512 <= data.len {
		block := data[offset..offset + 512]
		if is_zero_block(block) {
			break
		}
		if !checksum_ok(block) {
			return error('corrupted tar header: checksum mismatch at offset ${offset}')
		}
		mut name := cstr(block[0..100])
		if block[257..262].bytestr() == 'ustar' {
			prefix := cstr(block[345..500])
			if prefix.len > 0 {
				name = prefix + '/' + name
			}
		}
		header_size := parse_numeric(block[124..136])!
		typeflag := block[156]
		mut linkname := cstr(block[157..257])
		mode := int(parse_numeric(block[100..108]) or { 0 })
		mtime := parse_numeric(block[136..148]) or { 0 }
		offset += 512

		is_meta := typeflag in [`x`, `g`, `L`, `K`]
		mut size := header_size
		if !is_meta {
			if s := pax['size'] {
				size = s.i64()
			}
		}
		if size < 0 || i64(offset) + size > i64(data.len) {
			return error('corrupted tar block size exceeds data length')
		}
		is_dir := typeflag == `5`
		payload := if is_dir { []u8{} } else { data[offset..offset + int(size)] }
		if !is_dir {
			offset += int(size) + (512 - (int(size) % 512)) % 512
		}

		match typeflag {
			`x` {
				parse_pax(payload, mut pax)
				continue
			}
			`g` {
				continue
			}
			`L` {
				gnu_name = cstr(payload)
				continue
			}
			`K` {
				gnu_link = cstr(payload)
				continue
			}
			else {}
		}
		if p := pax['path'] {
			name = p
		} else if gnu_name.len > 0 {
			name = gnu_name
		}
		if l := pax['linkpath'] {
			linkname = l
		} else if gnu_link.len > 0 {
			linkname = gnu_link
		}
		pax = map[string]string{}
		gnu_name = ''
		gnu_link = ''

		entries << TarEntry{
			name:     name
			size:     int(size)
			is_dir:   is_dir
			data:     if is_dir { []u8{} } else { payload.clone() }
			mode:     mode
			mtime:    mtime
			typeflag: typeflag
			linkname: linkname
		}
	}
	return entries
}

// ============================================================================
// Disk helpers
// ============================================================================

// is_safe_entry_path reports whether an archive entry name stays inside the
// extraction directory: not empty, not absolute, no drive letter, no NUL byte and
// no `..` component. Used to block "tar-slip" path traversal.
pub fn is_safe_entry_path(name string) bool {
	if name.len == 0 || name.contains('\x00') {
		return false
	}
	if name[0] == `/` || name[0] == `\\` || (name.len >= 2 && name[1] == `:`) {
		return false
	}
	for part in name.replace('\\', '/').split('/') {
		if part == '..' {
			return false
		}
	}
	return true
}

fn is_regular_entry(e TarEntry) bool {
	return !e.is_dir && e.typeflag in [u8(0), `0`, `7`]
}

// read_archive loads a .tar or .tar.gz file (gzip is detected by magic bytes).
fn read_archive(tar_path string) ![]u8 {
	raw := os.read_bytes(tar_path)!
	if raw.len >= 2 && raw[0] == 0x1f && raw[1] == 0x8b {
		return gzip.decompress(raw)!
	}
	return raw
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
			name:   base_name
			size:   data.len
			is_dir: false
			data:   data
		}
	}
	raw := pack_bytes(entries)
	os.write_file_array(tar_path, raw)!
	return true
}

// list_tar_entries returns headers for all entries in a TAR file (.tar or .tar.gz).
pub fn list_tar_entries(tar_path string) ![]TarEntry {
	data := read_archive(tar_path)!
	return unpack_bytes(data)
}

// extract_entries writes already-parsed entries below dest_dir. Every name is
// validated first, so a malicious archive writes nothing at all. Symlinks,
// hardlinks, devices and FIFOs are skipped deliberately (they are a classic
// vector for escaping the destination directory).
pub fn extract_entries(entries []TarEntry, dest_dir string) ! {
	for e in entries {
		if !is_safe_entry_path(e.name) {
			return error('unsafe path in tar archive (path traversal blocked): "${e.name}"')
		}
	}
	if !os.exists(dest_dir) {
		os.mkdir_all(dest_dir)!
	}
	for entry in entries {
		target_path := os.join_path(dest_dir, entry.name)
		if entry.is_dir {
			os.mkdir_all(target_path)!
		} else if is_regular_entry(entry) {
			dir := os.dir(target_path)
			if !os.exists(dir) {
				os.mkdir_all(dir)!
			}
			os.write_file_array(target_path, entry.data)!
			if entry.mode > 0 {
				os.chmod(target_path, entry.mode & 0o777) or {}
			}
		}
	}
}

// extract_tar unpacks all entries from a TAR archive into the destination directory.
// Entries that would escape dest_dir (absolute paths, `..`) cause an error before
// anything is written; .tar.gz input is detected automatically.
pub fn extract_tar(tar_path string, dest_dir string) !bool {
	entries := list_tar_entries(tar_path)!
	extract_entries(entries, dest_dir)!
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

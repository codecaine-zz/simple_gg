module fileutils

import os
import json2
import time

// ---------------------------------------------------------------------------
// Security: path traversal & filename sanitisation
// ---------------------------------------------------------------------------

// safe_join joins an untrusted relative path onto base and guarantees the result stays inside
// base (rejects "../" escapes and absolute paths). Use for every user-supplied file name.
pub fn safe_join(base string, untrusted string) !string {
	if untrusted.starts_with('/') || untrusted.starts_with('\\')
		|| (untrusted.len > 1 && untrusted[1] == `:`) {
		return error('absolute paths are not allowed: ${untrusted}')
	}
	mut parts := []string{}
	for seg in untrusted.replace('\\', '/').split('/') {
		match seg {
			'', '.' {
				continue
			}
			'..' {
				if parts.len == 0 {
					return error('path escapes base directory: ${untrusted}')
				}
				parts.delete_last()
			}
			else {
				if seg.contains_u8(0) {
					return error('NUL byte in path')
				}
				parts << seg
			}
		}
	}
	if parts.len == 0 {
		return base
	}
	return os.join_path(base, ...parts)
}

const windows_reserved_names = ['CON', 'PRN', 'AUX', 'NUL', 'COM1', 'COM2', 'COM3', 'COM4', 'COM5',
	'COM6', 'COM7', 'COM8', 'COM9', 'LPT1', 'LPT2', 'LPT3', 'LPT4', 'LPT5', 'LPT6', 'LPT7', 'LPT8',
	'LPT9']

// sanitize_filename makes a string safe to use as a file name on Windows, macOS and Linux:
// strips path separators, control and reserved characters, trailing dots/spaces, and reserved
// device names; caps length at 255 bytes. Returns '_' if nothing remains.
pub fn sanitize_filename(name string) string {
	mut out := []rune{}
	for r in name.runes() {
		if r < 32 || r == 127 || r in [`/`, `\\`, `:`, `*`, `?`, `"`, `<`, `>`, `|`] {
			out << `_`
		} else {
			out << r
		}
	}
	mut s := out.string().trim_space().trim_right('. ')
	stem := s.all_before('.').to_upper()
	if stem in windows_reserved_names {
		s = '_' + s
	}
	for s.len > 255 {
		mut r := s.runes()
		r.delete_last()
		s = r.string()
	}
	return if s.len == 0 || s == '.' { '_' } else { s }
}

// unique_path returns path if it does not exist, otherwise "name (1).ext", "name (2).ext", ...
pub fn unique_path(path string) string {
	if !os.exists(path) {
		return path
	}
	dir := os.dir(path)
	stem := file_stem(path)
	ext := os.file_ext(path)
	for i := 1; true; i++ {
		candidate := os.join_path(dir, '${stem} (${i})${ext}')
		if !os.exists(candidate) {
			return candidate
		}
	}
	return path
}

// ---------------------------------------------------------------------------
// Streaming & large-file helpers
// ---------------------------------------------------------------------------

// each_line streams a file line by line (constant memory). Return false from f to stop early.
// Line numbers are 1-based; trailing \r is removed.
pub fn each_line(path string, f fn (line string, line_no int) bool) ! {
	mut file := os.open(path)!
	defer {
		file.close()
	}
	mut buf := []u8{len: 64 * 1024}
	mut pending := []u8{}
	mut line_no := 0
	for {
		n := file.read(mut buf) or { break }
		if n <= 0 {
			break
		}
		for c in buf[..n] {
			if c == `\n` {
				line_no++
				if !f(pending.bytestr().trim_right('\r'), line_no) {
					return
				}
				pending.clear()
			} else {
				pending << c
			}
		}
	}
	if pending.len > 0 {
		line_no++
		f(pending.bytestr().trim_right('\r'), line_no)
	}
}

@[heap]
struct LineAcc {
mut:
	lines []string
	count int
}

// head returns the first n lines of a file without reading the rest.
pub fn head(path string, n int) ![]string {
	if n <= 0 {
		return []string{}
	}
	mut acc := &LineAcc{}
	each_line(path, fn [mut acc, n] (line string, _ int) bool {
		acc.lines << line
		return acc.lines.len < n
	})!
	return acc.lines
}

// tail returns the last n lines of a file by reading backwards from the end (like `tail -n`).
pub fn tail(path string, n int) ![]string {
	if n <= 0 {
		return []string{}
	}
	mut f := os.open(path)!
	defer {
		f.close()
	}
	size := os.file_size(path)
	chunk := u64(8192)
	mut pos := size
	mut data := []u8{}
	for pos > 0 {
		read_len := if pos >= chunk { chunk } else { pos }
		pos -= read_len
		mut buf := []u8{len: int(read_len)}
		f.read_bytes_into(pos, mut buf)!
		buf << data
		data = buf.clone()
		// n lines need n newlines plus possibly a trailing one.
		if data.bytestr().count('\n') > n {
			break
		}
	}
	mut lines := data.bytestr().split('\n').map(it.trim_right('\r'))
	if lines.len > 0 && lines.last() == '' {
		lines.delete_last()
	}
	return if lines.len > n { lines[lines.len - n..] } else { lines }
}

// line_count counts newline-terminated lines (plus a final unterminated line) in constant memory.
pub fn line_count(path string) !int {
	mut acc := &LineAcc{}
	each_line(path, fn [mut acc] (_ string, _ int) bool {
		acc.count++
		return true
	})!
	return acc.count
}

// files_equal compares two files byte-for-byte, streaming (fast-fails on size mismatch).
pub fn files_equal(a string, b string) !bool {
	if os.file_size(a) != os.file_size(b) {
		return false
	}
	mut fa := os.open(a)!
	defer {
		fa.close()
	}
	mut fb := os.open(b)!
	defer {
		fb.close()
	}
	mut ba := []u8{len: 64 * 1024}
	mut bb := []u8{len: 64 * 1024}
	for {
		na := fa.read(mut ba) or { 0 }
		nb := fb.read(mut bb) or { 0 }
		if na != nb || ba[..na] != bb[..nb] {
			return false
		}
		if na <= 0 {
			return true
		}
	}
	return true
}

// is_binary_file heuristically detects binary files by looking for NUL bytes in the first 8 KiB
// (the same heuristic git and grep use).
pub fn is_binary_file(path string) !bool {
	mut f := os.open(path)!
	defer {
		f.close()
	}
	mut buf := []u8{len: 8192}
	n := f.read(mut buf) or { 0 }
	return 0 in buf[..n]
}

// read_ndjson reads a newline-delimited JSON file (one value per line), skipping blank lines.
pub fn read_ndjson[T](path string) ![]T {
	mut out := []T{}
	for i, line in read_lines_from_file(path)! {
		if line.trim_space().len == 0 {
			continue
		}
		out << json2.decode[T](line) or { return error('line ${i + 1}: ${err}') }
	}
	return out
}

// ---------------------------------------------------------------------------
// Filesystem helpers
// ---------------------------------------------------------------------------

// touch creates an empty file (and parent directories) or updates its modification time.
pub fn touch(path string) ! {
	ensure_dir_exists(path)!
	if os.exists(path) {
		now := int(time.now().unix())
		os.utime(path, now, now)!
		return
	}
	os.write_file(path, '')!
}

// dir_size returns the total size in bytes of all files under dir (recursive).
pub fn dir_size(dir string) !i64 {
	mut total := i64(0)
	for f in list_files(dir, true)! {
		total += i64(os.file_size(f))
	}
	return total
}

// backup_file copies path to "path.YYYYMMDD-HHMMSS.bak" and returns the backup path.
pub fn backup_file(path string) !string {
	stamp := time.now().custom_format('YYYYMMDD-HHmmss')
	dst := unique_path('${path}.${stamp}.bak')
	os.cp(path, dst)!
	return dst
}

// wildcard_match matches name against a shell-style pattern: `*` (any run), `?` (one rune),
// `[abc]` / `[a-z]` / `[!x]` character classes. Matching is case-sensitive.
pub fn wildcard_match(pattern string, name string) bool {
	return wm(pattern.runes(), 0, name.runes(), 0)
}

fn wm(p []rune, pi int, s []rune, si int) bool {
	mut i := pi
	mut j := si
	mut star_p := -1
	mut star_s := -1
	for j < s.len {
		if i < p.len && p[i] == `*` {
			star_p = i
			star_s = j
			i++
			continue
		}
		if i < p.len && p[i] == `[` {
			end, ok := class_match(p, i, s[j])
			if end > 0 && ok {
				i = end
				j++
				continue
			}
		} else if i < p.len && (p[i] == `?` || p[i] == s[j]) {
			i++
			j++
			continue
		}
		if star_p >= 0 {
			i = star_p + 1
			star_s++
			j = star_s
			continue
		}
		return false
	}
	for i < p.len && p[i] == `*` {
		i++
	}
	return i == p.len
}

// class_match evaluates a [..] class at p[start]; returns (index after ']', matched) or (0, false) if malformed.
fn class_match(p []rune, start int, c rune) (int, bool) {
	mut i := start + 1
	negate := i < p.len && (p[i] == `!` || p[i] == `^`)
	if negate {
		i++
	}
	mut matched := false
	mut first := true
	for i < p.len && (p[i] != `]` || first) {
		first = false
		if i + 2 < p.len && p[i + 1] == `-` && p[i + 2] != `]` {
			if c >= p[i] && c <= p[i + 2] {
				matched = true
			}
			i += 3
		} else {
			if c == p[i] {
				matched = true
			}
			i++
		}
	}
	if i >= p.len {
		return 0, false
	}
	return i + 1, matched != negate
}

// find_files recursively finds files under dir whose base name matches a wildcard pattern (e.g. "*.v").
pub fn find_files(dir string, pattern string) ![]string {
	return list_files(dir, true)!.filter(wildcard_match(pattern, os.file_name(it)))
}

// ---------------------------------------------------------------------------
// Byte sizes
// ---------------------------------------------------------------------------

// format_bytes formats a byte count: binary=true uses IEC units (KiB, MiB; 1024), false uses SI (kB, MB; 1000).
pub fn format_bytes(n i64, binary bool) string {
	base := if binary { 1024.0 } else { 1000.0 }
	units := if binary {
		['B', 'KiB', 'MiB', 'GiB', 'TiB', 'PiB', 'EiB']
	} else {
		['B', 'kB', 'MB', 'GB', 'TB', 'PB', 'EB']
	}
	neg := n < 0
	mut v := if neg { -f64(n) } else { f64(n) }
	mut u := 0
	for v >= base && u < units.len - 1 {
		v /= base
		u++
	}
	sign := if neg { '-' } else { '' }
	if u == 0 {
		return '${sign}${i64(v)} B'
	}
	return '${sign}${v:.2f} ${units[u]}'
}

// parse_bytes parses human sizes like "512", "10KB", "1.5 GiB", "2m" into bytes.
// Single-letter and SI suffixes (K, KB, M, MB...) follow the common 1024 convention; kB/MB with
// explicit "iB" are always binary.
pub fn parse_bytes(s string) !i64 {
	t := s.trim_space()
	mut idx := 0
	for idx < t.len && (t[idx].is_digit() || t[idx] == `.`) {
		idx++
	}
	if idx == 0 {
		return error('invalid size: "${s}"')
	}
	num := t[..idx].f64()
	unit := t[idx..].trim_space().to_lower()
	mult := match unit {
		'', 'b' { 1.0 }
		'k', 'kb', 'kib' { 1024.0 }
		'm', 'mb', 'mib' { 1024.0 * 1024 }
		'g', 'gb', 'gib' { 1024.0 * 1024 * 1024 }
		't', 'tb', 'tib' { 1024.0 * 1024 * 1024 * 1024 }
		'p', 'pb', 'pib' { 1024.0 * 1024 * 1024 * 1024 * 1024 }
		else { return error('unknown size unit: "${unit}"') }
	}

	return i64(num * mult)
}

// mime_type_from_bytes sniffs the MIME type from magic numbers (file signatures) rather than extensions.
pub fn mime_type_from_bytes(data []u8) string {
	starts := fn [data] (sig []u8) bool {
		return data.len >= sig.len && data[..sig.len] == sig
	}
	if starts([u8(0x89), `P`, `N`, `G`]) {
		return 'image/png'
	}
	if starts([u8(0xff), 0xd8, 0xff]) {
		return 'image/jpeg'
	}
	if starts('GIF8'.bytes()) {
		return 'image/gif'
	}
	if starts('%PDF'.bytes()) {
		return 'application/pdf'
	}
	if starts([u8(`P`), `K`, 3, 4]) {
		return 'application/zip'
	}
	if starts([u8(0x1f), 0x8b]) {
		return 'application/gzip'
	}
	if starts([u8(0x28), 0xb5, 0x2f, 0xfd]) {
		return 'application/zstd'
	}
	if starts([u8(0), `a`, `s`, `m`]) {
		return 'application/wasm'
	}
	if starts('SQLite format 3'.bytes()) {
		return 'application/vnd.sqlite3'
	}
	if data.len >= 12 && data[..4] == 'RIFF'.bytes() && data[8..12] == 'WEBP'.bytes() {
		return 'image/webp'
	}
	if starts([u8(0x7f), `E`, `L`, `F`]) {
		return 'application/x-elf'
	}
	if starts('ID3'.bytes()) {
		return 'audio/mpeg'
	}
	if data.len >= 8 && data[4..8] == 'ftyp'.bytes() {
		return 'video/mp4'
	}
	trimmed := data[..if data.len > 512 { 512 } else { data.len }].bytestr().trim_space().to_lower()
	if trimmed.starts_with('<!doctype html') || trimmed.starts_with('<html') {
		return 'text/html'
	}
	if trimmed.starts_with('<?xml') {
		return 'application/xml'
	}
	if trimmed.starts_with('{') || trimmed.starts_with('[') {
		return 'application/json'
	}
	if 0 in data[..if data.len > 8192 {
		8192
	} else {
		data.len
	}] {
		return 'application/octet-stream'
	}
	return 'text/plain'
}

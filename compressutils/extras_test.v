module compressutils

import os

fn test_detect_and_auto() {
	payload := 'hello hello hello hello'.bytes()
	for algo in [CompressionAlgorithm.gzip, .zlib, .zstd] {
		c := compress(algo, payload) or { panic(err) }
		assert detect_algorithm(c) or { panic('undetected ${algo}') } == algo
		assert is_compressed(c)
		assert decompress_auto(c) or { panic(err) } == payload
	}
	assert detect_algorithm('plain text'.bytes()) == none
	assert !is_compressed([]u8{})
}

fn test_empty_roundtrip_all_codecs() {
	for algo in [CompressionAlgorithm.gzip, .zlib, .deflate, .zstd] {
		c := compress(algo, []u8{}) or { panic('${algo}: ${err}') }
		d := decompress(algo, c) or { panic('${algo}: ${err}') }
		assert d.len == 0
	}
}

fn test_decompress_limited_blocks_bombs() {
	bomb := []u8{len: 2_000_000, init: 0} // 2 MB of zeros compresses to a few KB
	for algo in [CompressionAlgorithm.gzip, .zlib, .deflate, .zstd] {
		c := compress(algo, bomb) or { panic(err) }
		assert c.len < 50_000
		decompress_limited(algo, c, 100_000) or {
			assert err.msg().contains('limit'), '${algo}: ${err}'
			ok := decompress_limited(algo, c, 2_000_000) or { panic('${algo}: ${err}') }
			assert ok.len == bomb.len
			continue
		}
		assert false, '${algo} bomb was not stopped'
	}
}

fn test_zstd_frame_content_size() {
	c := zstd_compress('abcdef'.repeat(100).bytes()) or { panic(err) }
	assert zstd_frame_content_size(c) or { 0 } == 600
	assert zstd_frame_content_size('nope!'.bytes()) == none
	// Forged header claiming 1 TiB is rejected without allocating.
	mut forged := c.clone()
	forged[4] = 0xe0 // FCS flag 3 (8 bytes), single segment
	for i in 0 .. 8 {
		forged[5 + i] = if i == 5 { u8(1) } else { u8(0) } // 2^40
	}
	assert zstd_frame_content_size(forged) or { 0 } == u64(1) << 40
	decompress_limited(.zstd, forged, 1 << 20) or {
		assert err.msg().contains('exceeds')
		return
	}
	assert false
}

fn test_checksums_reference_vectors() {
	// Standard check values: CRC-32/ISO-HDLC("123456789") = 0xCBF43926,
	// Adler-32("Wikipedia") = 0x11E60398.
	assert crc32_checksum('123456789'.bytes()) == u32(0xCBF43926)
	assert adler32_checksum('Wikipedia'.bytes()) == u32(0x11E60398)
}

fn test_compress_best_and_levels() {
	data := 'the quick brown fox jumps over the lazy dog. '.repeat(200).bytes()
	r := compress_best(data) or { panic(err) }
	assert r.ratio > 90.0
	assert decompress(r.algorithm, r.data) or { panic(err) } == data
	fast := zstd_compress_level(data, 1) or { panic(err) }
	small := zstd_compress_level(data, 19) or { panic(err) }
	assert small.len <= fast.len
}

fn test_file_helpers() {
	dir := os.join_path(os.temp_dir(), 'compressutils_files_${os.getpid()}')
	os.mkdir_all(dir) or { panic(err) }
	defer {
		os.rmdir_all(dir) or {}
	}
	src := os.join_path(dir, 'a.txt')
	os.write_file(src, 'file payload '.repeat(50)) or { panic(err) }
	compress_file(.gzip, src, src + '.gz') or { panic(err) }
	decompress_file(.gzip, src + '.gz', src + '.out', 1 << 20) or { panic(err) }
	assert os.read_file(src + '.out') or { '' } == 'file payload '.repeat(50)
	decompress_file(.gzip, src + '.gz', src + '.bad', 10) or { return }
	assert false
}

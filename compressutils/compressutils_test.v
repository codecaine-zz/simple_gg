module compressutils

const test_text = 'The V programming language is designed to be simple, readable, fast, and secure. ' +
	'This text is repeated multiple times to ensure sufficient compressibility across algorithms. ' +
	'The V programming language is designed to be simple, readable, fast, and secure. ' +
	'This text is repeated multiple times to ensure sufficient compressibility across algorithms.'

fn test_gzip() {
	compressed := gzip_compress_string(test_text) or { panic(err) }
	assert compressed.len < test_text.len

	decompressed := gzip_decompress_string(compressed) or { panic(err) }
	assert decompressed == test_text
}

fn test_zlib() {
	compressed := zlib_compress_string(test_text) or { panic(err) }
	assert compressed.len < test_text.len

	decompressed := zlib_decompress_string(compressed) or { panic(err) }
	assert decompressed == test_text
}

fn test_deflate() {
	compressed := deflate_compress_string(test_text) or { panic(err) }
	assert compressed.len < test_text.len

	decompressed := deflate_decompress_string(compressed) or { panic(err) }
	assert decompressed == test_text
}

fn test_zstd() {
	assert zstd_version() != ''

	compressed := zstd_compress_string(test_text) or { panic(err) }
	assert compressed.len < test_text.len

	decompressed := zstd_decompress_string(compressed) or { panic(err) }
	assert decompressed == test_text
}

fn test_unified_dispatcher_and_ratio() {
	raw := test_text.bytes()
	for algo in [CompressionAlgorithm.gzip, CompressionAlgorithm.zlib, CompressionAlgorithm.deflate,
		CompressionAlgorithm.zstd] {
		c := compress(algo, raw) or { panic(err) }
		assert c.len > 0
		d := decompress(algo, c) or { panic(err) }
		assert d == raw

		ratio := compression_ratio(raw.len, c.len)
		assert ratio > 0.0
	}
}

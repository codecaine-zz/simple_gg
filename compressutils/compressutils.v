module compressutils

import compress.deflate
import compress.gzip
import compress.zlib
import compress.zstd

// CompressionAlgorithm defines supported compression codecs.
pub enum CompressionAlgorithm {
	gzip
	zlib
	deflate
	zstd
}

// gzip_compress compresses bytes using the Gzip format.
pub fn gzip_compress(data []u8) ![]u8 {
	return gzip.compress(data)!
}

// gzip_decompress decompresses Gzip-compressed bytes.
pub fn gzip_decompress(data []u8) ![]u8 {
	return gzip.decompress(data)!
}

// gzip_compress_string compresses a string to Gzip bytes.
pub fn gzip_compress_string(text string) ![]u8 {
	return gzip.compress(text.bytes())!
}

// gzip_decompress_string decompresses Gzip bytes to a string.
pub fn gzip_decompress_string(data []u8) !string {
	decompressed := gzip.decompress(data)!
	return decompressed.bytestr()
}

// zlib_compress compresses bytes using the Zlib format.
pub fn zlib_compress(data []u8) ![]u8 {
	return zlib.compress(data)!
}

// zlib_decompress decompresses Zlib-compressed bytes.
pub fn zlib_decompress(data []u8) ![]u8 {
	return zlib.decompress(data)!
}

// zlib_compress_string compresses a string to Zlib bytes.
pub fn zlib_compress_string(text string) ![]u8 {
	return zlib.compress(text.bytes())!
}

// zlib_decompress_string decompresses Zlib bytes to a string.
pub fn zlib_decompress_string(data []u8) !string {
	decompressed := zlib.decompress(data)!
	return decompressed.bytestr()
}

// deflate_compress compresses bytes using raw Deflate.
pub fn deflate_compress(data []u8) ![]u8 {
	return deflate.compress(data)!
}

// deflate_decompress decompresses raw Deflate bytes.
pub fn deflate_decompress(data []u8) ![]u8 {
	return deflate.decompress(data)!
}

// deflate_compress_string compresses a string to raw Deflate bytes.
pub fn deflate_compress_string(text string) ![]u8 {
	return deflate.compress(text.bytes())!
}

// deflate_decompress_string decompresses raw Deflate bytes to a string.
pub fn deflate_decompress_string(data []u8) !string {
	decompressed := deflate.decompress(data)!
	return decompressed.bytestr()
}

// zstd_compress compresses bytes using the Zstandard algorithm.
pub fn zstd_compress(data []u8) ![]u8 {
	return zstd.compress(data)!
}

// zstd_decompress decompresses Zstandard-compressed bytes.
pub fn zstd_decompress(data []u8) ![]u8 {
	return zstd.decompress(data)!
}

// zstd_compress_string compresses a string to Zstandard bytes.
pub fn zstd_compress_string(text string) ![]u8 {
	return zstd.compress(text.bytes())!
}

// zstd_decompress_string decompresses Zstandard bytes to a string.
pub fn zstd_decompress_string(data []u8) !string {
	decompressed := zstd.decompress(data)!
	return decompressed.bytestr()
}

// zstd_version returns the underlying Zstandard C library version string.
pub fn zstd_version() string {
	return zstd.version_string()
}

// compress compresses byte data using the requested algorithm.
pub fn compress(algo CompressionAlgorithm, data []u8) ![]u8 {
	return match algo {
		.gzip { gzip_compress(data)! }
		.zlib { zlib_compress(data)! }
		.deflate { deflate_compress(data)! }
		.zstd { zstd_compress(data)! }
	}
}

// decompress decompresses byte data using the requested algorithm.
pub fn decompress(algo CompressionAlgorithm, data []u8) ![]u8 {
	return match algo {
		.gzip { gzip_decompress(data)! }
		.zlib { zlib_decompress(data)! }
		.deflate { deflate_decompress(data)! }
		.zstd { zstd_decompress(data)! }
	}
}

// compression_ratio calculates the space savings percentage: (1.0 - compressed / original) * 100.
pub fn compression_ratio(original_len int, compressed_len int) f64 {
	if original_len <= 0 {
		return 0.0
	}
	return (1.0 - (f64(compressed_len) / f64(original_len))) * 100.0
}

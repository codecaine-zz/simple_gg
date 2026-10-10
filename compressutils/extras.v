module compressutils

import os
import compress.gzip
import compress.zlib
import compress.deflate
import compress.zstd
import hash.crc32
import hash.adler32

// detect_algorithm identifies gzip, zlib and zstd streams by their magic bytes /
// header checksum. Raw deflate has no header and cannot be detected (none).
pub fn detect_algorithm(data []u8) ?CompressionAlgorithm {
	if data.len >= 4 && data[0] == 0x28 && data[1] == 0xb5 && data[2] == 0x2f && data[3] == 0xfd {
		return .zstd
	}
	if data.len >= 3 && data[0] == 0x1f && data[1] == 0x8b && data[2] == 8 {
		return .gzip
	}
	if looks_like_zlib(data) {
		return .zlib
	}
	return none
}

fn looks_like_zlib(data []u8) bool {
	return data.len >= 2 && data[0] & 0x0f == 8 && data[0] >> 4 <= 7
		&& (u32(data[0]) * 256 + u32(data[1])) % 31 == 0
}

// is_compressed reports whether data starts with a recognised compression header.
pub fn is_compressed(data []u8) bool {
	return detect_algorithm(data) != none
}

// decompress_auto detects the container format and decompresses accordingly.
pub fn decompress_auto(data []u8) ![]u8 {
	algo := detect_algorithm(data) or {
		return error('unrecognised compression format (raw deflate cannot be auto-detected)')
	}
	return decompress(algo, data)
}

// zstd_frame_content_size reads the decompressed size declared in a zstd frame
// header (RFC 8878 §3.1.1.1), or none when the frame does not declare it.
pub fn zstd_frame_content_size(data []u8) ?u64 {
	if data.len < 5 || data[0] != 0x28 || data[1] != 0xb5 || data[2] != 0x2f || data[3] != 0xfd {
		return none
	}
	fhd := data[4]
	fcs_flag := fhd >> 6
	single_segment := (fhd >> 5) & 1 == 1
	mut pos := 5
	if !single_segment {
		pos++ // Window_Descriptor
	}
	pos += [0, 1, 2, 4][int(fhd & 3)] // Dictionary_ID
	fcs_size := match fcs_flag {
		0 {
			if single_segment { 1 } else { 0 }
		}
		1 {
			2
		}
		2 {
			4
		}
		else {
			8
		}
	}

	if fcs_size == 0 || pos + fcs_size > data.len {
		return none
	}
	mut v := u64(0)
	for i in 0 .. fcs_size {
		v |= u64(data[pos + i]) << (8 * i)
	}
	if fcs_size == 2 {
		v += 256
	}
	return v
}

@[heap]
struct LimitSink {
mut:
	buf      []u8
	max      int
	exceeded bool
}

fn limit_cb(chunk []u8, userdata voidptr) int {
	mut s := unsafe { &LimitSink(userdata) }
	if s.buf.len + chunk.len > s.max {
		s.exceeded = true
		return 0
	}
	s.buf << chunk
	return if chunk.len > 0 { chunk.len } else { 1 }
}

// decompress_limited decompresses untrusted input but aborts as soon as the
// output would exceed max_bytes, which defeats decompression bombs: gzip, zlib
// and deflate are inflated in streamed chunks; for zstd the size declared in the
// frame header is checked before any allocation.
pub fn decompress_limited(algo CompressionAlgorithm, data []u8, max_bytes int) ![]u8 {
	if algo == .zstd {
		size := zstd_frame_content_size(data) or {
			return error('zstd frame does not declare its size; refusing unbounded decompression')
		}
		if size > u64(max_bytes) {
			return error('decompressed size ${size} exceeds the limit of ${max_bytes} bytes')
		}
		return zstd_decompress(data)
	}
	if algo == .deflate
		&& (looks_like_zlib(data) || (data.len >= 2 && data[0] == 0x1f && data[1] == 0x8b)) {
		// vlib's streaming entry point would misread this raw stream as zlib/gzip;
		// fall back to a full inflate followed by a size check.
		out := deflate.decompress(data)!
		if out.len > max_bytes {
			return error('decompressed data exceeds the limit of ${max_bytes} bytes')
		}
		return out
	}
	mut sink := &LimitSink{
		max: max_bytes
	}
	match algo {
		.gzip { gzip.decompress_with_callback(data, limit_cb, sink)! }
		.zlib { zlib.decompress_with_callback(data, limit_cb, sink)! }
		else { deflate.decompress_with_callback(data, limit_cb, sink)! }
	}

	if sink.exceeded {
		return error('decompressed data exceeds the limit of ${max_bytes} bytes')
	}
	return sink.buf
}

// zstd_compress_level compresses with an explicit zstd level (1 = fastest, 19+ = smallest).
pub fn zstd_compress_level(data []u8, level int) ![]u8 {
	return zstd.compress(data, compression_level: level)!
}

// crc32_checksum returns the IEEE CRC-32 used by gzip, zip and PNG.
pub fn crc32_checksum(data []u8) u32 {
	return crc32.sum(data)
}

// adler32_checksum returns the Adler-32 checksum used by zlib (RFC 1950).
pub fn adler32_checksum(data []u8) u32 {
	return adler32.sum(data)
}

// CompressionResult is the outcome of compress_best.
pub struct CompressionResult {
pub:
	algorithm CompressionAlgorithm
	data      []u8
	ratio     f64 // space savings in percent
}

// compress_best tries every codec and returns the smallest output.
pub fn compress_best(data []u8) !CompressionResult {
	mut best := CompressionResult{
		algorithm: .zstd
		data:      zstd_compress_level(data, 19)!
	}
	for algo in [CompressionAlgorithm.gzip, .zlib, .deflate] {
		out := compress(algo, data)!
		if out.len < best.data.len {
			best = CompressionResult{
				algorithm: algo
				data:      out
			}
		}
	}
	return CompressionResult{
		algorithm: best.algorithm
		data:      best.data
		ratio:     compression_ratio(data.len, best.data.len)
	}
}

// compress_file compresses src into dst with the given codec.
pub fn compress_file(algo CompressionAlgorithm, src string, dst string) ! {
	os.write_file_array(dst, compress(algo, os.read_bytes(src)!)!)!
}

// decompress_file decompresses src into dst, refusing output larger than max_bytes.
pub fn decompress_file(algo CompressionAlgorithm, src string, dst string, max_bytes int) ! {
	os.write_file_array(dst, decompress_limited(algo, os.read_bytes(src)!, max_bytes)!)!
}

module main

import compressutils

fn main() {
	println('==================================================')
	println('              demo_compressutils                  ')
	println('==================================================')

	sample_text := 'Vlang Utilities is a fast, modular, zero-dependency suite of production-ready tools for V programming. '.repeat(5)
	println('Original payload size: ${sample_text.len} bytes')

	// 1. Gzip
	println('\n1. Gzip Compression:')
	gz_data := compressutils.gzip_compress_string(sample_text) or { panic(err) }
	gz_ratio := compressutils.compression_ratio(sample_text.len, gz_data.len)
	gz_restored := compressutils.gzip_decompress_string(gz_data) or { panic(err) }
	println('  Compressed: ${gz_data.len} bytes (${gz_ratio:.1f}% space savings)')
	println('  Integrity verified? ${sample_text == gz_restored}')

	// 2. Zlib
	println('\n2. Zlib Compression:')
	zl_data := compressutils.zlib_compress_string(sample_text) or { panic(err) }
	zl_ratio := compressutils.compression_ratio(sample_text.len, zl_data.len)
	zl_restored := compressutils.zlib_decompress_string(zl_data) or { panic(err) }
	println('  Compressed: ${zl_data.len} bytes (${zl_ratio:.1f}% space savings)')
	println('  Integrity verified? ${sample_text == zl_restored}')

	// 3. Deflate
	println('\n3. Raw Deflate Compression:')
	df_data := compressutils.deflate_compress_string(sample_text) or { panic(err) }
	df_ratio := compressutils.compression_ratio(sample_text.len, df_data.len)
	df_restored := compressutils.deflate_decompress_string(df_data) or { panic(err) }
	println('  Compressed: ${df_data.len} bytes (${df_ratio:.1f}% space savings)')
	println('  Integrity verified? ${sample_text == df_restored}')

	// 4. Zstandard (Zstd)
	println('\n4. Zstandard Compression (v${compressutils.zstd_version()}):')
	zs_data := compressutils.zstd_compress_string(sample_text) or { panic(err) }
	zs_ratio := compressutils.compression_ratio(sample_text.len, zs_data.len)
	zs_restored := compressutils.zstd_decompress_string(zs_data) or { panic(err) }
	println('  Compressed: ${zs_data.len} bytes (${zs_ratio:.1f}% space savings)')
	println('  Integrity verified? ${sample_text == zs_restored}')

	println('\n✔ compressutils demo completed successfully!')
}

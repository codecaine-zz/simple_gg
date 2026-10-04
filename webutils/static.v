module webutils

import os
import time

// ============================================================================
// Static files (replaces serve-static)
// ============================================================================

const mime_types = {
	'html':        'text/html; charset=utf-8'
	'htm':         'text/html; charset=utf-8'
	'css':         'text/css; charset=utf-8'
	'js':          'text/javascript; charset=utf-8'
	'mjs':         'text/javascript; charset=utf-8'
	'json':        'application/json; charset=utf-8'
	'map':         'application/json; charset=utf-8'
	'webmanifest': 'application/manifest+json; charset=utf-8'
	'txt':         'text/plain; charset=utf-8'
	'md':          'text/markdown; charset=utf-8'
	'csv':         'text/csv; charset=utf-8'
	'xml':         'application/xml; charset=utf-8'
	'svg':         'image/svg+xml'
	'png':         'image/png'
	'jpg':         'image/jpeg'
	'jpeg':        'image/jpeg'
	'gif':         'image/gif'
	'webp':        'image/webp'
	'avif':        'image/avif'
	'ico':         'image/x-icon'
	'bmp':         'image/bmp'
	'woff':        'font/woff'
	'woff2':       'font/woff2'
	'ttf':         'font/ttf'
	'otf':         'font/otf'
	'mp4':         'video/mp4'
	'webm':        'video/webm'
	'mp3':         'audio/mpeg'
	'ogg':         'audio/ogg'
	'wav':         'audio/wav'
	'pdf':         'application/pdf'
	'zip':         'application/zip'
	'gz':          'application/gzip'
	'wasm':        'application/wasm'
	'ics':         'text/calendar; charset=utf-8'
}

// mime_type returns the Content-Type for a file name or extension
// (`application/octet-stream` when unknown).
pub fn mime_type(name string) string {
	ext := if name.contains('.') { name.all_after_last('.') } else { name }
	return mime_types[ext.to_lower()] or { 'application/octet-stream' }
}

@[params]
pub struct StaticConfig {
pub:
	prefix         string = '/'          // URL prefix, e.g. '/assets'
	index          string = 'index.html' // served for directory requests ('' disables)
	max_age        int  // Cache-Control max-age in seconds
	immutable      bool // add `immutable` (for fingerprinted assets)
	dotfiles       bool // serve dot-files such as .env (default: never)
	fall_through   bool = true // on miss continue to the next handler (false: 404)
	max_file_bytes i64  = 256 * 1024 * 1024
}

// static_files serves files under `root`. Traversal-proof: `..`, encoded
// slashes, NUL bytes, dot-files and symlinks escaping `root` are refused.
// Sends ETag/Last-Modified and answers conditional requests with 304.
pub fn static_files(root string, cfg StaticConfig) Handler {
	prefix := normalize_prefix(cfg.prefix)
	return fn [root, prefix, cfg] (mut c Context) ! {
		if (c.method != 'GET' && c.method != 'HEAD') || !prefix_matches(prefix, c.path) {
			c.next()!
			return
		}
		rel := if prefix == '/' { c.path } else { c.path[prefix.len..] }
		parts := split_path(rel) or { return http_error(400, 'Bad Request') }
		mut ok := true
		for p in parts {
			if p == '..' || p == '.' || p.contains('/') || p.contains('\\')
				|| (!cfg.dotfiles && p.starts_with('.')) {
				ok = false
				break
			}
		}
		if ok {
			real_root := os.real_path(root)
			mut full := if parts.len == 0 { real_root } else { os.join_path(real_root, ...parts) }
			if os.is_dir(full) && cfg.index != '' {
				full = os.join_path(full, cfg.index)
			}
			if os.is_file(full) {
				real := os.real_path(full)
				if real.starts_with(real_root + os.path_separator) {
					if os.file_size(real) > u64(cfg.max_file_bytes) {
						return http_error(413, 'File Too Large')
					}
					if c.response_header('Cache-Control') == '' {
						c.set_header('Cache-Control', 'public, max-age=${cfg.max_age}${if cfg.immutable {
							', immutable'
						} else {
							''
						}}')
					}
					serve_file(mut c, real, cfg.max_age)!
					return
				}
			}
		}
		if cfg.fall_through {
			c.next()!
			return
		}
		return http_error(404, 'Not Found')
	}
}

fn serve_file(mut c Context, path string, max_age int) ! {
	size := os.file_size(path)
	mtime := os.file_last_mod_unix(path)
	etag := 'W/"${size:x}-${mtime:x}"'
	c.set_header('ETag', etag)
	c.set_header('Last-Modified', time.unix(mtime).http_header_string())
	if c.response_header('Cache-Control') == '' {
		c.set_header('Cache-Control', 'public, max-age=${max_age}')
	}
	inm := c.header('If-None-Match')
	mut not_modified := false
	if inm != '' {
		not_modified = inm.trim_space() == '*'
			|| inm.split(',').any(it.trim_space().trim_string_left('W/') == etag.trim_string_left('W/'))
	} else {
		ims := c.header('If-Modified-Since')
		if ims != '' {
			if t := time.parse_http_header_string(ims) {
				not_modified = mtime <= t.unix()
			}
		}
	}
	if not_modified {
		c.status_code = 304
		c.res_body = ''
		c.sent = true
		return
	}
	if c.response_header('Content-Type') == '' {
		c.set_header('Content-Type', mime_type(path))
	}
	c.res_body = os.read_file(path)!
	c.sent = true
}

// safe_join joins untrusted relative `rel` onto `root`, returning an error
// if the result would escape `root` (`..`, absolute paths, symlinks).
pub fn safe_join(root string, rel string) !string {
	if rel.contains('\0') {
		return error('invalid path')
	}
	parts := rel.replace('\\', '/').split('/').filter(it != '' && it != '.')
	if parts.any(it == '..') {
		return error('path escapes root')
	}
	real_root := os.real_path(root)
	full := if parts.len == 0 { real_root } else { os.join_path(real_root, ...parts) }
	if os.exists(full) {
		real := os.real_path(full)
		if real != real_root && !real.starts_with(real_root + os.path_separator) {
			return error('path escapes root')
		}
		return real
	}
	return full
}

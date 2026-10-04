module webutils

import net.http

const max_multipart_parts = 1000

// parse_multipart parses an RFC 7578 multipart/form-data body. Header order
// and extra part headers are handled; part count is bounded.
fn parse_multipart(body string, boundary string, mut fields map[string][]string, mut files map[string][]http.FileData) {
	delim := '--' + boundary
	mut pos := body.index(delim) or { return }
	pos += delim.len
	mut parts := 0
	for parts < max_multipart_parts {
		// after a delimiter: `--` ends the body, otherwise CRLF starts a part
		if body[pos..].starts_with('--') {
			return
		}
		if body[pos..].starts_with('\r\n') {
			pos += 2
		} else if body[pos..].starts_with('\n') {
			pos += 1
		}
		next := body.index_after('\r\n' + delim, pos) or { return }
		part := body[pos..next]
		pos = next + 2 + delim.len
		parts++
		mut sep := part.index('\r\n\r\n') or { -1 }
		mut sep_len := 4
		if sep < 0 {
			sep = part.index('\n\n') or { continue }
			sep_len = 2
		}
		headers := part[..sep]
		data := part[sep + sep_len..]
		mut name := ''
		mut filename := ''
		mut has_filename := false
		mut ctype := 'text/plain'
		for line in headers.split('\n') {
			l := line.trim_space()
			colon := l.index(':') or { continue }
			key := l[..colon].trim_space().to_lower()
			val := l[colon + 1..].trim_space()
			if key == 'content-disposition' {
				params := parse_header_params(val)
				name = params['name'] or { '' }
				if fname := params['filename'] {
					filename = fname
					has_filename = true
				}
			} else if key == 'content-type' {
				ctype = val
			}
		}
		if name == '' {
			continue
		}
		if has_filename {
			files[name] << http.FileData{
				filename:     filename.replace('\\', '/').all_after_last('/')
				content_type: ctype
				data:         data
			}
		} else {
			fields[name] << data
		}
	}
}

// parse_header_params parses `form-data; name="a"; filename="b.txt"`.
fn parse_header_params(v string) map[string]string {
	mut m := map[string]string{}
	mut i := v.index(';') or { return m }
	i++
	for i < v.len {
		for i < v.len && (v[i] == ` ` || v[i] == `;` || v[i] == `\t`) {
			i++
		}
		start := i
		for i < v.len && v[i] != `=` && v[i] != `;` {
			i++
		}
		key := v[start..i].trim_space().to_lower()
		if i >= v.len || v[i] != `=` {
			continue
		}
		i++
		mut val := []u8{}
		if i < v.len && v[i] == `"` {
			i++
			for i < v.len && v[i] != `"` {
				if v[i] == `\\` && i + 1 < v.len {
					i++
				}
				val << v[i]
				i++
			}
			i++
		} else {
			for i < v.len && v[i] != `;` {
				val << v[i]
				i++
			}
		}
		if key != '' {
			m[key] = val.bytestr().trim_space()
		}
	}
	return m
}

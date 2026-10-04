module sqliteutils

import db.sqlite

// ─── SQL scripts ─────────────────────────────────────────────────────────────

// split_sql_statements splits a SQL script into individual statements. It
// understands '...' / "..." / `...` / [...] quoting, -- and /* */ comments, and
// CREATE TRIGGER ... BEGIN ... END bodies (including nested CASE ... END), so
// semicolons inside any of those never split a statement. Empty statements and
// comment-only fragments are dropped; returned statements have no trailing ';'.
pub fn split_sql_statements(script string) []string {
	mut out := []string{}
	mut start := 0
	mut i := 0
	mut in_trigger := false
	mut depth := 0
	mut first_words := []string{}
	mut code_end := 0 // index just past the last non-comment, non-space character
	n := script.len
	for i < n {
		c := script[i]
		if c == `'` || c == `"` || c == `\`` || c == `[` {
			close := if c == `[` { u8(`]`) } else { c }
			i++
			for i < n {
				if script[i] == close {
					if close != `]` && i + 1 < n && script[i + 1] == close {
						i += 2 // doubled quote escape
						continue
					}
					break
				}
				i++
			}
			i++
			if i > n {
				i = n
			}
			code_end = i
			continue
		}
		if c == `-` && i + 1 < n && script[i + 1] == `-` {
			for i < n && script[i] != `\n` {
				i++
			}
			continue
		}
		if c == `/` && i + 1 < n && script[i + 1] == `*` {
			i += 2
			for i + 1 < n && !(script[i] == `*` && script[i + 1] == `/`) {
				i++
			}
			i += 2
			continue
		}
		if c.is_letter() || c == `_` {
			j := i
			for i < n && (script[i].is_letter() || script[i].is_digit() || script[i] == `_`) {
				i++
			}
			word := script[j..i].to_upper()
			if first_words.len < 4 {
				first_words << word
				if word == 'TRIGGER' && first_words[0] == 'CREATE' {
					in_trigger = true
				}
			}
			if in_trigger {
				if word in ['BEGIN', 'CASE'] {
					depth++
				} else if word == 'END' {
					depth--
				}
			}
			code_end = i
			continue
		}
		if c == `;` && (!in_trigger || depth <= 0) {
			stmt := clean_stmt(script[start..i])
			if stmt.len > 0 {
				out << stmt
			}
			start = i + 1
			in_trigger = false
			depth = 0
			first_words = []string{}
		} else if !c.is_space() {
			code_end = i + 1
		}
		i++
	}
	if code_end > start {
		stmt := clean_stmt(script[start..code_end])
		if stmt.len > 0 {
			out << stmt
		}
	}
	return out
}

// clean_stmt trims whitespace and leading comments; comment-only fragments become ''.
fn clean_stmt(s string) string {
	mut probe := s
	for {
		p := probe.trim_space()
		if p.starts_with('--') {
			if !p.contains('\n') {
				return ''
			}
			probe = p.all_after('\n')
		} else if p.starts_with('/*') {
			if !p.contains('*/') {
				return ''
			}
			probe = p.all_after('*/')
		} else {
			return p
		}
	}
	return ''
}

// exec_script runs every statement of a SQL script atomically (all or nothing).
// Returns the number of statements executed.
pub fn exec_script(mut db sqlite.DB, script string) !int {
	stmts := split_sql_statements(script)
	db.exec('BEGIN;')!
	for idx, s in stmts {
		db.exec(s) or {
			db.exec('ROLLBACK;') or {}
			return error('statement ${idx + 1} failed: ${err.msg()}')
		}
	}
	db.exec('COMMIT;')!
	return stmts.len
}

// ─── Schema migrations ───────────────────────────────────────────────────────

// schema_version returns the database's PRAGMA user_version.
pub fn schema_version(mut db sqlite.DB) !int {
	return db.q_int('PRAGMA user_version;')!
}

// set_schema_version sets PRAGMA user_version.
pub fn set_schema_version(mut db sqlite.DB, version int) ! {
	if version < 0 {
		return error('schema version must be >= 0')
	}
	db.exec('PRAGMA user_version = ${version};')!
}

// migrate brings the schema up to date. `migrations[i]` is a SQL script that
// upgrades version i to version i+1; the current version is tracked in PRAGMA
// user_version. Each migration runs in its own transaction together with the
// version bump, so a failing migration leaves the database at the last good
// version. Append-only: never edit or reorder a migration once released.
// Returns how many migrations were applied.
pub fn migrate(mut db sqlite.DB, migrations []string) !int {
	current := schema_version(mut db)!
	if current > migrations.len {
		return error('database schema version ${current} is newer than the ${migrations.len} known migrations')
	}
	mut applied := 0
	for i in current .. migrations.len {
		db.exec('BEGIN IMMEDIATE;')!
		for s in split_sql_statements(migrations[i]) {
			db.exec(s) or {
				db.exec('ROLLBACK;') or {}
				return error('migration ${i + 1} failed: ${err.msg()}')
			}
		}
		db.exec('PRAGMA user_version = ${i + 1};') or {
			db.exec('ROLLBACK;') or {}
			return err
		}
		db.exec('COMMIT;')!
		applied++
	}
	return applied
}

// ─── Maintenance ─────────────────────────────────────────────────────────────

// integrity_check runs PRAGMA integrity_check and returns the reported problems
// (an empty list means the database is healthy).
pub fn integrity_check(mut db sqlite.DB) ![]string {
	rows := db.exec('PRAGMA integrity_check;')!
	mut problems := []string{}
	for r in rows {
		v := r.val(0)
		if v != 'ok' {
			problems << v
		}
	}
	return problems
}

// vacuum_into writes a compacted, consistent copy of the live database to
// dest_path (an online backup). dest_path must not already exist.
pub fn vacuum_into(mut db sqlite.DB, dest_path string) ! {
	ensure_db_dir(dest_path)!
	db.exec_param('VACUUM INTO ?;', dest_path)!
}

// enable_wal switches to write-ahead logging with synchronous=NORMAL and a busy
// timeout: the standard configuration for concurrent readers + one writer.
pub fn enable_wal(mut db sqlite.DB, busy_timeout_ms int) ! {
	db.exec('PRAGMA journal_mode = WAL;')!
	db.exec('PRAGMA synchronous = NORMAL;')!
	db.busy_timeout(busy_timeout_ms)
}

// ─── Upsert & pagination ─────────────────────────────────────────────────────

// upsert_row inserts a row or, when it conflicts on conflict_cols (which must
// form a UNIQUE / PRIMARY KEY constraint), updates the remaining columns.
// Identifiers are validated; values are bound as parameters.
pub fn upsert_row(mut db sqlite.DB, table_name string, data map[string]string, conflict_cols []string) ! {
	if data.len == 0 {
		return error('Cannot upsert empty data map')
	}
	if conflict_cols.len == 0 {
		return error('upsert requires at least one conflict column')
	}
	tbl := sanitize_identifier(table_name)!
	mut cols := []string{}
	mut vals := []string{}
	mut keys := data.keys()
	keys.sort()
	for k in keys {
		cols << '"' + sanitize_identifier(k)! + '"'
		vals << data[k]
	}
	mut conflict := []string{}
	for c in conflict_cols {
		conflict << '"' + sanitize_identifier(c)! + '"'
	}
	mut sets := []string{}
	for c in cols {
		if c !in conflict {
			sets << '${c} = excluded.${c}'
		}
	}
	action := if sets.len == 0 { 'DO NOTHING' } else { 'DO UPDATE SET ${sets.join(', ')}' }
	placeholders := []string{len: cols.len, init: '?'}
	query := 'INSERT INTO "${tbl}" (${cols.join(', ')}) VALUES (${placeholders.join(', ')}) ON CONFLICT (${conflict.join(', ')}) ${action};'
	db.exec_param_many(query, vals)!
}

// Page is one page of a paginated query.
pub struct Page {
pub:
	rows        []map[string]string
	page        int
	page_size   int
	total       int
	total_pages int
}

// paginate runs a SELECT query (with ? params) and returns the requested
// 1-based page plus total counts. ORDER BY inside the query gives stable pages.
pub fn paginate(mut db sqlite.DB, query string, params []string, page int, page_size int) !Page {
	if page < 1 || page_size < 1 {
		return error('page and page_size must be >= 1')
	}
	q := query.trim_space().trim_right(';')
	total := query_scalar(mut db, 'SELECT COUNT(*) FROM (${q});', params)!.int()
	mut p := params.clone()
	p << page_size.str()
	p << ((page - 1) * page_size).str()
	rows := query_maps_params(mut db, 'SELECT * FROM (${q}) LIMIT ? OFFSET ?;', p)!
	return Page{
		rows:        rows
		page:        page
		page_size:   page_size
		total:       total
		total_pages: (total + page_size - 1) / page_size
	}
}

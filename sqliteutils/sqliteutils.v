module sqliteutils

import db.sqlite
import os
import json2

// sanitize_identifier strictly validates that a SQL identifier (table/column name)
// contains only safe alphanumeric characters, underscores, or hyphens, starts with a letter
// or underscore, and does not exceed 128 characters.
// Table/column identifiers cannot be bound as ? parameters in SQLite, so strict validation
// eliminates SQL injection attempts into identifier slots.
pub fn sanitize_identifier(name string) !string {
	if name.len == 0 {
		return error('SQL identifier must not be empty')
	}
	if name.len > 128 {
		return error('SQL identifier "${name}" exceeds maximum allowed length of 128 characters')
	}
	first := name[0]
	if !first.is_letter() && first != `_` {
		return error('SQL identifier "${name}" must start with a letter or underscore')
	}
	for ch in name {
		if !ch.is_letter() && !ch.is_digit() && ch != `_` && ch != `-` {
			return error('SQL identifier "${name}" contains disallowed character: ${ch.ascii_str()}')
		}
	}
	return name
}

// is_valid_identifier checks if a string is a safe, valid SQL identifier.
pub fn is_valid_identifier(name string) bool {
	_ = sanitize_identifier(name) or { return false }
	return true
}

// escape_string doubles single quotes according to SQL-92 / SQLite standards to escape literal values.
// NOTE: Parameterized queries (? placeholders) should ALWAYS be preferred over string interpolation.
pub fn escape_string(s string) string {
	return s.replace("'", "''")
}

// Helper function to create parent directories if path is a file path.
fn ensure_db_dir(path string) ! {
	if path == ':memory:' || path == '' {
		return
	}
	if path.contains('\0') {
		return error('Database path contains illegal null bytes')
	}
	dir := os.dir(path)
	if dir.len > 0 {
		os.mkdir_all(dir) or { return err }
	}
}

// apply_secure_pragmas configures SQLite with recommended security and integrity settings:
// - foreign_keys = ON (enforces relational constraint validation)
// - trusted_schema = OFF (prevents untrusted database files from triggering code execution via malicious views/triggers)
// - cell_size_check = ON (detects B-tree corruption early)
pub fn apply_secure_pragmas(mut db sqlite.DB) ! {
	db.exec('PRAGMA foreign_keys = ON;') or { return err }
	db.exec('PRAGMA trusted_schema = OFF;') or { return err }
	db.exec('PRAGMA cell_size_check = ON;') or { return err }
}

// Connection & Database Management

// Opens a SQLite database connection, creating parent directories automatically if needed,
// and applies secure database PRAGMAs (foreign_keys=ON, trusted_schema=OFF, cell_size_check=ON).
pub fn open_db(path string) !sqlite.DB {
	ensure_db_dir(path) or { return err }
	mut db := sqlite.connect(path) or { return err }
	apply_secure_pragmas(mut db) or { return err }
	return db
}

// Closes a SQLite database connection, releasing all associated resources.
// Always call this when you are finished with a database — open file handles
// prevent other processes from writing to the same file (especially on Windows).
//
// Example:
//   mut db := sqliteutils.open_db('app.db')!
//   defer { sqliteutils.close_db(mut db) or {} }
pub fn close_db(mut db sqlite.DB) ! {
	db.close() or { return err }
}

// Returns the row ID of the most recent successful INSERT into the database.
// Use this immediately after an INSERT to retrieve the auto-assigned primary key.
// Returns 0 if no INSERT has been performed on this connection yet.
//
// Example:
//   sqliteutils.exec_sql(mut db, "INSERT INTO users (name) VALUES ('Alice');")!
//   id := sqliteutils.last_insert_id(db)
//   println('New row id: ${id}')
pub fn last_insert_id(db sqlite.DB) i64 {
	return db.last_insert_rowid()
}

// Executes a raw DDL/DML SQL query without expecting row returns.
// Caller is responsible for ensuring the query string contains no user-supplied data.
// Use exec_sql_params for queries involving user input.
pub fn exec_sql(mut db sqlite.DB, query string) ! {
	db.exec(query) or { return err }
}

// Executes a parameterized DDL/DML SQL query using ? placeholders.
// Prevents SQL injection by delegating argument binding directly to the SQLite engine.
pub fn exec_sql_params(mut db sqlite.DB, query string, params []string) ! {
	db.exec_param_many(query, params) or { return err }
}

// Executes a parameterized SQL query with a single bound parameter.
pub fn exec_sql_param(mut db sqlite.DB, query string, param string) ! {
	db.exec_param(query, param) or { return err }
}

// Checks if a table exists in the database.
pub fn table_exists(mut db sqlite.DB, table_name string) !bool {
	rows := db.exec_param("SELECT name FROM sqlite_master WHERE type='table' AND name=?",
		table_name) or { return err }
	return rows.len > 0
}

// Returns a list of all non-system table names in the database.
pub fn get_table_names(mut db sqlite.DB) ![]string {
	query := "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';"
	rows := db.exec(query) or { return err }
	mut names := []string{}
	for row in rows {
		if row.vals.len > 0 {
			names << row.vals[0]
		}
	}
	return names
}

// Returns the total row count for a table.
pub fn count_rows(mut db sqlite.DB, table_name string) !int {
	// Identifiers cannot be parameterized; sanitize_identifier guards against injection.
	tbl := sanitize_identifier(table_name)!
	rows := db.exec('SELECT COUNT(*) FROM "${tbl}";') or { return err }
	if rows.len == 0 || rows[0].vals.len == 0 {
		return 0
	}
	return rows[0].vals[0].int()
}

// Key-Value Store Helpers

// Creates a standard key-value table (key TEXT PRIMARY KEY, val TEXT).
pub fn create_kv_table(mut db sqlite.DB, table_name string) ! {
	tbl := sanitize_identifier(table_name)!
	db.exec('CREATE TABLE IF NOT EXISTS "${tbl}" (key TEXT PRIMARY KEY, val TEXT);') or {
		return err
	}
}

// Sets or updates a key-value pair in a key-value table.
pub fn set_kv(mut db sqlite.DB, table_name string, key string, val string) ! {
	tbl := sanitize_identifier(table_name)!
	// val is passed twice: once for INSERT and once for the ON CONFLICT UPDATE.
	db.exec_param_many('INSERT INTO "${tbl}" (key, val) VALUES (?, ?) ON CONFLICT(key) DO UPDATE SET val=?',
		[key, val, val]) or { return err }
}

// Gets the value for a key in a key-value table, returning an error if key is not found.
pub fn get_kv(mut db sqlite.DB, table_name string, key string) !string {
	tbl := sanitize_identifier(table_name)!
	rows := db.exec_param('SELECT val FROM "${tbl}" WHERE key = ?', key) or { return err }
	if rows.len == 0 || rows[0].vals.len == 0 {
		return error('Key "${key}" not found in table "${table_name}"')
	}
	return rows[0].vals[0]
}

// Deletes a key-value pair from a key-value table.
pub fn delete_kv(mut db sqlite.DB, table_name string, key string) ! {
	tbl := sanitize_identifier(table_name)!
	db.exec_param('DELETE FROM "${tbl}" WHERE key = ?', key) or { return err }
}

// Retrieves all key-value pairs from a key-value table as a map.
pub fn get_all_kv(mut db sqlite.DB, table_name string) !map[string]string {
	tbl := sanitize_identifier(table_name)!
	rows := db.exec('SELECT key, val FROM "${tbl}";') or { return err }
	mut result := map[string]string{}
	for row in rows {
		if row.vals.len >= 2 {
			result[row.vals[0]] = row.vals[1]
		}
	}
	return result
}

// Struct & JSON Document Store Helpers

// Creates a JSON document store table (id TEXT PRIMARY KEY, json_data TEXT).
pub fn create_json_store(mut db sqlite.DB, table_name string) ! {
	tbl := sanitize_identifier(table_name)!
	db.exec('CREATE TABLE IF NOT EXISTS "${tbl}" (id TEXT PRIMARY KEY, json_data TEXT);') or {
		return err
	}
}

// Saves a struct as a JSON document under a given ID.
pub fn save_struct[T](mut db sqlite.DB, table_name string, id string, data T) ! {
	tbl := sanitize_identifier(table_name)!
	encoded := json2.encode(data)
	// encoded is passed twice: for the INSERT value and for the ON CONFLICT UPDATE.
	db.exec_param_many('INSERT INTO "${tbl}" (id, json_data) VALUES (?, ?) ON CONFLICT(id) DO UPDATE SET json_data=?',
		[id, encoded, encoded]) or { return err }
}

// Loads a struct from a JSON document by ID.
pub fn load_struct[T](mut db sqlite.DB, table_name string, id string) !T {
	tbl := sanitize_identifier(table_name)!
	rows := db.exec_param('SELECT json_data FROM "${tbl}" WHERE id = ?', id) or { return err }
	if rows.len == 0 || rows[0].vals.len == 0 {
		return error('Record with ID "${id}" not found in table "${table_name}"')
	}
	return json2.decode[T](rows[0].vals[0])
}

// Loads all struct records from a JSON document store table.
pub fn load_all_structs[T](mut db sqlite.DB, table_name string) ![]T {
	tbl := sanitize_identifier(table_name)!
	rows := db.exec('SELECT json_data FROM "${tbl}";') or { return err }
	mut result := []T{}
	for row in rows {
		if row.vals.len > 0 {
			item := json2.decode[T](row.vals[0]) or { continue }
			result << item
		}
	}
	return result
}

// Deletes a struct document record by ID.
pub fn delete_struct(mut db sqlite.DB, table_name string, id string) ! {
	tbl := sanitize_identifier(table_name)!
	db.exec_param('DELETE FROM "${tbl}" WHERE id = ?', id) or { return err }
}

// Dynamic Query & Batch Transaction Helpers

// Executes a static SELECT query and returns rows as a list of column-name -> string-value maps.
// Caller is responsible for ensuring the query string contains no user-supplied data.
// Use query_maps_params when the query must include user values.
pub fn query_maps(mut db sqlite.DB, query string) ![]map[string]string {
	rows := db.exec(query) or { return err }
	mut result := []map[string]string{}
	for row in rows {
		mut row_map := map[string]string{}
		for i in 0 .. row.vals.len {
			col_name := if i < row.names.len { row.names[i] } else { i.str() }
			row_map[col_name] = row.vals[i]
		}
		result << row_map
	}
	return result
}

// Executes a parameterized SELECT query with ? placeholders and returns rows as maps.
// Use this variant whenever the query includes user-supplied values.
pub fn query_maps_params(mut db sqlite.DB, query string, params []string) ![]map[string]string {
	rows := db.exec_param_many(query, params) or { return err }
	mut result := []map[string]string{}
	for row in rows {
		mut row_map := map[string]string{}
		for i in 0 .. row.vals.len {
			col_name := if i < row.names.len { row.names[i] } else { i.str() }
			row_map[col_name] = row.vals[i]
		}
		result << row_map
	}
	return result
}

// Executes a static query and returns the first row as a map, or an error if no rows are returned.
// Caller is responsible for ensuring the query string contains no user-supplied data.
// Use query_one_map_params when the query must include user values.
pub fn query_one_map(mut db sqlite.DB, query string) !map[string]string {
	maps := query_maps(mut db, query) or { return err }
	if maps.len == 0 {
		return error('No rows returned for query')
	}
	return maps[0]
}

// Executes a parameterized query and returns the first row as a map.
// Use this variant whenever the query includes user-supplied values.
pub fn query_one_map_params(mut db sqlite.DB, query string, params []string) !map[string]string {
	maps := query_maps_params(mut db, query, params) or { return err }
	if maps.len == 0 {
		return error('No rows returned for query')
	}
	return maps[0]
}

// Executes multiple static SQL statements inside a single transaction with automatic rollback on error.
// Statements must contain no user-supplied data. Use execute_batch_params for parameterized statements.
pub fn execute_batch(mut db sqlite.DB, statements []string) ! {
	db.exec('BEGIN TRANSACTION;') or { return err }
	for stmt in statements {
		db.exec(stmt) or {
			db.exec('ROLLBACK;') or {}
			return err
		}
	}
	db.exec('COMMIT;') or { return err }
}

// ParamStatement pairs a parameterized SQL query with its bound values for use in execute_batch_params.
pub struct ParamStatement {
pub:
	query  string
	params []string
}

// Executes multiple parameterized SQL statements (each with its own params slice) inside a single
// transaction with automatic rollback on error.
pub fn execute_batch_params(mut db sqlite.DB, statements []ParamStatement) ! {
	db.exec('BEGIN TRANSACTION;') or { return err }
	for ps in statements {
		db.exec_param_many(ps.query, ps.params) or {
			db.exec('ROLLBACK;') or {}
			return err
		}
	}
	db.exec('COMMIT;') or { return err }
}

// ─── Schema / DDL Helpers ────────────────────────────────────────────────────

// Drops a table from the database. Pass force: true to use DROP TABLE IF EXISTS
// (no error when the table is absent).
pub fn drop_table(mut db sqlite.DB, table_name string, force bool) ! {
	tbl := sanitize_identifier(table_name)!
	if force {
		db.exec('DROP TABLE IF EXISTS "${tbl}";') or { return err }
	} else {
		db.exec('DROP TABLE "${tbl}";') or { return err }
	}
}

// Renames a table. Both names must pass identifier validation.
pub fn rename_table(mut db sqlite.DB, old_name string, new_name string) ! {
	old := sanitize_identifier(old_name)!
	new_ := sanitize_identifier(new_name)!
	db.exec('ALTER TABLE "${old}" RENAME TO "${new_}";') or { return err }
}

// Removes all rows from a table without dropping it (equivalent of TRUNCATE in SQLite).
pub fn clear_table(mut db sqlite.DB, table_name string) ! {
	tbl := sanitize_identifier(table_name)!
	db.exec('DELETE FROM "${tbl}";') or { return err }
}

// Returns the list of column names for a given table.
pub fn get_column_names(mut db sqlite.DB, table_name string) ![]string {
	tbl := sanitize_identifier(table_name)!
	// PRAGMA table_info columns: cid, name, type, notnull, dflt_value, pk
	rows := db.exec('PRAGMA table_info("${tbl}");') or { return err }
	mut names := []string{}
	for row in rows {
		if row.vals.len >= 2 {
			names << row.vals[1]
		}
	}
	return names
}

// Reports whether a column exists in a table.
pub fn column_exists(mut db sqlite.DB, table_name string, column_name string) !bool {
	cols := get_column_names(mut db, table_name)!
	return column_name in cols
}

// Returns a map of table_name -> row_count for every non-system table in the database.
pub fn table_row_counts(mut db sqlite.DB) !map[string]int {
	tables := get_table_names(mut db)!
	mut result := map[string]int{}
	for tbl in tables {
		result[tbl] = count_rows(mut db, tbl)!
	}
	return result
}

// ─── Extended Key-Value Helpers ───────────────────────────────────────────────

// Reports whether a key exists in a key-value table.
pub fn kv_exists(mut db sqlite.DB, table_name string, key string) !bool {
	tbl := sanitize_identifier(table_name)!
	rows := db.exec_param('SELECT 1 FROM "${tbl}" WHERE key = ? LIMIT 1', key) or { return err }
	return rows.len > 0
}

// Gets the value for a key from a key-value table, returning default_val when the key is absent.
// Never errors — the zero-friction read pattern for RAD.
pub fn get_kv_or(mut db sqlite.DB, table_name string, key string, default_val string) string {
	return get_kv(mut db, table_name, key) or { default_val }
}

// Increments an integer stored at key by amount. Creates the key starting at amount if absent.
// Returns the new value.
pub fn increment_kv(mut db sqlite.DB, table_name string, key string, amount int) !int {
	current := get_kv(mut db, table_name, key) or { '0' }
	new_val := current.int() + amount
	set_kv(mut db, table_name, key, new_val.str())!
	return new_val
}

// Deletes all key-value pairs from a table while keeping the table intact.
pub fn clear_kv(mut db sqlite.DB, table_name string) ! {
	clear_table(mut db, table_name)!
}

// ─── Extended JSON Document Store Helpers ────────────────────────────────────

// Reports whether a document with the given ID exists in a JSON store table.
pub fn struct_exists(mut db sqlite.DB, table_name string, id string) !bool {
	tbl := sanitize_identifier(table_name)!
	rows := db.exec_param('SELECT 1 FROM "${tbl}" WHERE id = ? LIMIT 1', id) or { return err }
	return rows.len > 0
}

// Returns the number of documents stored in a JSON store table.
pub fn count_structs(mut db sqlite.DB, table_name string) !int {
	return count_rows(mut db, table_name)
}

// Deletes all documents from a JSON store table while keeping the table intact.
pub fn delete_all_structs(mut db sqlite.DB, table_name string) ! {
	clear_table(mut db, table_name)!
}

// Returns every document ID stored in a JSON store table.
pub fn list_struct_ids(mut db sqlite.DB, table_name string) ![]string {
	tbl := sanitize_identifier(table_name)!
	rows := db.exec('SELECT id FROM "${tbl}";') or { return err }
	mut ids := []string{}
	for row in rows {
		if row.vals.len > 0 {
			ids << row.vals[0]
		}
	}
	return ids
}

// ─── Query Helpers ────────────────────────────────────────────────────────────

// Executes a parameterized query and returns the first column of the first row as a string.
// Ideal for scalar aggregates: COUNT, MAX, SUM, etc.
//
// Example:
//   total := sqliteutils.query_scalar(mut db, 'SELECT COUNT(*) FROM orders WHERE status = ?', ['open'])!
pub fn query_scalar(mut db sqlite.DB, query string, params []string) !string {
	rows := db.exec_param_many(query, params) or { return err }
	if rows.len == 0 || rows[0].vals.len == 0 {
		return error('query_scalar: no rows returned')
	}
	return rows[0].vals[0]
}

// Executes a parameterized query and returns every value from the first column as a string slice.
// Useful for fetching a list of IDs, names, tags, etc.
//
// Example:
//   names := sqliteutils.query_column(mut db, 'SELECT name FROM users WHERE active = ?', ['1'])!
pub fn query_column(mut db sqlite.DB, query string, params []string) ![]string {
	rows := db.exec_param_many(query, params) or { return err }
	mut values := []string{}
	for row in rows {
		if row.vals.len > 0 {
			values << row.vals[0]
		}
	}
	return values
}

// ─── Convenience Transaction Helper ──────────────────────────────────────────

// Runs a closure inside a BEGIN / COMMIT transaction.
// If the closure returns an error the transaction is rolled back automatically.
//
// Example:
//   sqliteutils.with_transaction(mut db, fn [mut db] () ! {
//       sqliteutils.set_kv(mut db, 'cfg', 'a', '1')!
//       sqliteutils.set_kv(mut db, 'cfg', 'b', '2')!
//   })!
pub fn with_transaction(mut db sqlite.DB, work fn () !) ! {
	db.exec('BEGIN TRANSACTION;') or { return err }
	work() or {
		db.exec('ROLLBACK;') or {}
		return err
	}
	db.exec('COMMIT;') or { return err }
}

// ─── Column Management Helpers ───────────────────────────────────────────────

// sanitize_sql_type validates that a SQL type expression (e.g. "TEXT", "INTEGER NOT NULL",
// "VARCHAR(255)", "INTEGER NOT NULL DEFAULT 0") contains only safe characters, balanced
// delimiters, no comments, and no statement separators. Prevents injection via type strings.
pub fn sanitize_sql_type(sql_type string) !string {
	if sql_type.len == 0 {
		return error('SQL type must not be empty')
	}
	if sql_type.len > 128 {
		return error('SQL type "${sql_type}" exceeds maximum allowed length of 128 characters')
	}
	// Disallow SQL comments
	if sql_type.contains('--') || sql_type.contains('/*') {
		return error('SQL type must not contain SQL comments: "${sql_type}"')
	}
	// Disallow statement separators
	if sql_type.contains(';') {
		return error('SQL type must not contain semicolons: "${sql_type}"')
	}
	// Whitelist safe characters
	for ch in sql_type {
		if !ch.is_letter() && !ch.is_digit() && ch != ` ` && ch != `(` && ch != `)` && ch != `_`
			&& ch != `-` && ch != `.` && ch != `'` && ch != `"` {
			return error('SQL type "${sql_type}" contains disallowed character: ${ch.ascii_str()}')
		}
	}
	// Check balanced parentheses
	mut parens := 0
	for ch in sql_type {
		if ch == `(` {
			parens++
		} else if ch == `)` {
			parens--
			if parens < 0 {
				return error('SQL type has unbalanced parentheses: "${sql_type}"')
			}
		}
	}
	if parens != 0 {
		return error('SQL type has unclosed parentheses: "${sql_type}"')
	}
	// Check balanced single quotes
	mut single_quotes := 0
	for ch in sql_type {
		if ch == `'` {
			single_quotes++
		}
	}
	if single_quotes % 2 != 0 {
		return error('SQL type has unclosed single quotes: "${sql_type}"')
	}
	return sql_type
}

// ColumnDef describes a column to be added to a table.
pub struct ColumnDef {
pub:
	// name is the column name. Must pass identifier validation.
	name string
	// sql_type is the SQLite type expression, e.g. "TEXT", "INTEGER", "REAL",
	// "INTEGER NOT NULL DEFAULT 0", "VARCHAR(255)".
	sql_type string
}

// Adds a single column to an existing table.
// Requires SQLite 3.1+ (universally available).
//
// Example:
//   add_column(mut db, 'users', ColumnDef{ name: 'email', sql_type: 'TEXT' })!
pub fn add_column(mut db sqlite.DB, table_name string, col ColumnDef) ! {
	tbl := sanitize_identifier(table_name)!
	col_name := sanitize_identifier(col.name)!
	col_type := sanitize_sql_type(col.sql_type)!
	db.exec('ALTER TABLE "${tbl}" ADD COLUMN "${col_name}" ${col_type};') or { return err }
}

// Adds multiple columns to an existing table in a single transaction.
// Any invalid name or type causes all additions to be rolled back.
pub fn add_columns(mut db sqlite.DB, table_name string, cols []ColumnDef) ! {
	tbl := sanitize_identifier(table_name)!
	db.exec('BEGIN TRANSACTION;') or { return err }
	for col in cols {
		col_name := sanitize_identifier(col.name) or {
			db.exec('ROLLBACK;') or {}
			return err
		}
		col_type := sanitize_sql_type(col.sql_type) or {
			db.exec('ROLLBACK;') or {}
			return err
		}
		db.exec('ALTER TABLE "${tbl}" ADD COLUMN "${col_name}" ${col_type};') or {
			db.exec('ROLLBACK;') or {}
			return err
		}
	}
	db.exec('COMMIT;') or { return err }
}

// Renames a column in a table.
// Requires SQLite 3.25.0+ (released 2018-09-15).
//
// Example:
//   rename_column(mut db, 'users', 'fname', 'first_name')!
pub fn rename_column(mut db sqlite.DB, table_name string, old_col string, new_col string) ! {
	tbl := sanitize_identifier(table_name)!
	old := sanitize_identifier(old_col)!
	new_ := sanitize_identifier(new_col)!
	db.exec('ALTER TABLE "${tbl}" RENAME COLUMN "${old}" TO "${new_}";') or { return err }
}

// Drops a single column from a table.
// Requires SQLite 3.35.0+ (released 2021-03-12).
//
// Example:
//   drop_column(mut db, 'users', 'legacy_field')!
pub fn drop_column(mut db sqlite.DB, table_name string, col_name string) ! {
	tbl := sanitize_identifier(table_name)!
	col := sanitize_identifier(col_name)!
	db.exec('ALTER TABLE "${tbl}" DROP COLUMN "${col}";') or { return err }
}

// Drops multiple columns from a table inside a single transaction.
// Requires SQLite 3.35.0+ (released 2021-03-12).
// Any failure rolls back all column drops.
pub fn drop_columns(mut db sqlite.DB, table_name string, col_names []string) ! {
	tbl := sanitize_identifier(table_name)!
	db.exec('BEGIN TRANSACTION;') or { return err }
	for col_name in col_names {
		col := sanitize_identifier(col_name) or {
			db.exec('ROLLBACK;') or {}
			return err
		}
		db.exec('ALTER TABLE "${tbl}" DROP COLUMN "${col}";') or {
			db.exec('ROLLBACK;') or {}
			return err
		}
	}
	db.exec('COMMIT;') or { return err }
}

// Returns full schema information for a table as a slice of maps with keys:
// "cid", "name", "type", "notnull", "dflt_value", "pk".
// Useful for introspection and schema migrations.
pub fn get_table_schema(mut db sqlite.DB, table_name string) ![]map[string]string {
	tbl := sanitize_identifier(table_name)!
	rows := db.exec('PRAGMA table_info("${tbl}");') or { return err }
	pragma_cols := ['cid', 'name', 'type', 'notnull', 'dflt_value', 'pk']
	mut result := []map[string]string{}
	for row in rows {
		mut m := map[string]string{}
		for i, val in row.vals {
			key := if i < pragma_cols.len { pragma_cols[i] } else { i.str() }
			m[key] = val
		}
		result << m
	}
	return result
}

// ─── Injection-Free Parameterized CRUD Helpers ──────────────────────────────

// insert_row safely inserts a record using parameterized binding. All column names
// are strictly validated as identifiers and all values are bound with ? placeholders.
// Returns the newly generated rowid.
pub fn insert_row(mut db sqlite.DB, table_name string, data map[string]string) !i64 {
	if data.len == 0 {
		return error('Cannot insert empty data map')
	}
	tbl := sanitize_identifier(table_name)!
	mut cols := []string{cap: data.len}
	mut placeholders := []string{cap: data.len}
	mut vals := []string{cap: data.len}

	for col, val in data {
		safe_col := sanitize_identifier(col)!
		cols << '"${safe_col}"'
		placeholders << '?'
		vals << val
	}

	query := 'INSERT INTO "${tbl}" (${cols.join(', ')}) VALUES (${placeholders.join(', ')});'
	db.exec_param_many(query, vals) or { return err }
	return db.last_insert_rowid()
}

// update_rows safely updates rows in table_name with column-value assignments in data
// filtered by where_clause and where_params. All column names are strictly validated.
pub fn update_rows(mut db sqlite.DB, table_name string, data map[string]string, where_clause string, where_params []string) ! {
	if data.len == 0 {
		return error('Cannot update with empty data map')
	}
	tbl := sanitize_identifier(table_name)!
	mut set_clauses := []string{cap: data.len}
	mut vals := []string{cap: data.len + where_params.len}

	for col, val in data {
		safe_col := sanitize_identifier(col)!
		set_clauses << '"${safe_col}" = ?'
		vals << val
	}

	for p in where_params {
		vals << p
	}

	clause := if where_clause.len > 0 { 'WHERE ${where_clause}' } else { '' }
	query := 'UPDATE "${tbl}" SET ${set_clauses.join(', ')} ${clause};'
	db.exec_param_many(query, vals) or { return err }
}

// delete_rows safely deletes rows from table_name matching where_clause and where_params.
pub fn delete_rows(mut db sqlite.DB, table_name string, where_clause string, where_params []string) ! {
	tbl := sanitize_identifier(table_name)!
	clause := if where_clause.len > 0 { 'WHERE ${where_clause}' } else { '' }
	query := 'DELETE FROM "${tbl}" ${clause};'
	db.exec_param_many(query, where_params) or { return err }
}

// select_rows safely retrieves rows from table_name selecting specific columns (or ['*'])
// filtered by where_clause and where_params. Returns result as a slice of maps.
pub fn select_rows(mut db sqlite.DB, table_name string, columns []string, where_clause string, where_params []string) ![]map[string]string {
	tbl := sanitize_identifier(table_name)!
	mut col_clause := '*'
	if columns.len > 0 && !(columns.len == 1 && columns[0] == '*') {
		mut safe_cols := []string{cap: columns.len}
		for c in columns {
			safe_cols << '"' + sanitize_identifier(c)! + '"'
		}
		col_clause = safe_cols.join(', ')
	}

	clause := if where_clause.len > 0 { 'WHERE ${where_clause}' } else { '' }
	query := 'SELECT ${col_clause} FROM "${tbl}" ${clause};'
	return query_maps_params(mut db, query, where_params)
}

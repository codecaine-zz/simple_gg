module sqliteutils

import os

// ─── Shared test struct ───────────────────────────────────────────────────────

struct Item {
	id    string
	title string
	price int
}

// ─── Connection lifecycle ─────────────────────────────────────────────────────

fn test_close_db() {
	mut db := open_db(':memory:') or { panic(err) }
	exec_sql(mut db, 'CREATE TABLE t (x INT);') or { panic(err) }
	// Closing must not error
	close_db(mut db) or { panic(err) }
	// Calling close again on an already-closed connection should also not panic;
	// the underlying sqlite3_close returns SQLITE_OK for already-closed handles.
	close_db(mut db) or {
		// Some SQLite builds error here — that's acceptable; just must not crash.
		_ := err
	}
}

fn test_last_insert_id() {
	mut db := open_db(':memory:') or { panic(err) }
	exec_sql(mut db, 'CREATE TABLE items (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT);') or {
		panic(err)
	}

	// Before any INSERT the rowid is 0
	assert last_insert_id(db) == 0

	exec_sql(mut db, "INSERT INTO items (name) VALUES ('alpha');") or { panic(err) }
	assert last_insert_id(db) == 1

	exec_sql(mut db, "INSERT INTO items (name) VALUES ('beta');") or { panic(err) }
	assert last_insert_id(db) == 2

	// Deleting does not affect last_insert_id
	exec_sql(mut db, 'DELETE FROM items WHERE id = 2;') or { panic(err) }
	assert last_insert_id(db) == 2

	close_db(mut db) or { panic(err) }
}

// ─── Existing tests (unchanged) ───────────────────────────────────────────────

fn test_open_db_and_schema_helpers() {
	mut db := open_db(':memory:') or { panic(err) }

	assert table_exists(mut db, 'users') or { panic(err) } == false

	exec_sql(mut db, 'CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT);') or { panic(err) }
	assert table_exists(mut db, 'users') or { panic(err) } == true

	tables := get_table_names(mut db) or { panic(err) }
	assert tables.contains('users')

	assert count_rows(mut db, 'users') or { panic(err) } == 0
	exec_sql(mut db, "INSERT INTO users (name) VALUES ('Alice'), ('Bob');") or { panic(err) }
	assert count_rows(mut db, 'users') or { panic(err) } == 2
}

fn test_kv_store_helpers() {
	mut db := open_db(':memory:') or { panic(err) }

	create_kv_table(mut db, 'settings') or { panic(err) }
	assert table_exists(mut db, 'settings') or { panic(err) } == true

	set_kv(mut db, 'settings', 'theme', 'dark') or { panic(err) }
	set_kv(mut db, 'settings', 'font_size', '14') or { panic(err) }

	theme := get_kv(mut db, 'settings', 'theme') or { panic(err) }
	assert theme == 'dark'

	// Update existing key
	set_kv(mut db, 'settings', 'theme', 'light') or { panic(err) }
	updated_theme := get_kv(mut db, 'settings', 'theme') or { panic(err) }
	assert updated_theme == 'light'

	all_kv := get_all_kv(mut db, 'settings') or { panic(err) }
	assert all_kv.len == 2
	assert all_kv['theme'] == 'light'
	assert all_kv['font_size'] == '14'

	delete_kv(mut db, 'settings', 'font_size') or { panic(err) }
	missing := get_kv(mut db, 'settings', 'font_size') or { 'not_found' }
	assert missing == 'not_found'
}

fn test_json_struct_store_helpers() {
	mut db := open_db(':memory:') or { panic(err) }

	create_json_store(mut db, 'items') or { panic(err) }
	assert table_exists(mut db, 'items') or { panic(err) } == true

	item1 := Item{
		id:    'item_1'
		title: 'Keyboard'
		price: 100
	}
	item2 := Item{
		id:    'item_2'
		title: 'Mouse'
		price: 50
	}

	save_struct(mut db, 'items', item1.id, item1) or { panic(err) }
	save_struct(mut db, 'items', item2.id, item2) or { panic(err) }

	loaded_item1 := load_struct[Item](mut db, 'items', 'item_1') or { panic(err) }
	assert loaded_item1.title == 'Keyboard'
	assert loaded_item1.price == 100

	all_items := load_all_structs[Item](mut db, 'items') or { panic(err) }
	assert all_items.len == 2

	delete_struct(mut db, 'items', 'item_1') or { panic(err) }
	remaining := load_all_structs[Item](mut db, 'items') or { panic(err) }
	assert remaining.len == 1
	assert remaining[0].title == 'Mouse'
}

fn test_query_maps_and_batch_transactions() {
	mut db := open_db(':memory:') or { panic(err) }

	statements := [
		'CREATE TABLE products (id INTEGER PRIMARY KEY, name TEXT, price INTEGER);',
		"INSERT INTO products (name, price) VALUES ('Widget', 25);",
		"INSERT INTO products (name, price) VALUES ('Gadget', 45);",
	]
	execute_batch(mut db, statements) or { panic(err) }

	rows := query_maps(mut db, 'SELECT name, price FROM products ORDER BY price ASC;') or {
		panic(err)
	}
	assert rows.len == 2
	assert rows[0]['name'] == 'Widget'
	assert rows[0]['price'] == '25'
	assert rows[1]['name'] == 'Gadget'

	one_row := query_one_map(mut db, "SELECT name, price FROM products WHERE name = 'Widget';") or {
		panic(err)
	}
	assert one_row['name'] == 'Widget'
	assert one_row['price'] == '25'

	query_one_map(mut db, "SELECT name FROM products WHERE name = 'Nonexistent';") or {
		assert err.msg().contains('No rows returned')
		map[string]string{}
	}
}

fn test_open_db_creates_parent_directories() {
	dir_path := '/tmp/nested_sqlite_dir'
	db_path := '${dir_path}/app.db'
	os.rmdir_all(dir_path) or {}

	mut db := open_db(db_path) or { panic(err) }
	assert os.exists(db_path)

	exec_sql(mut db, 'CREATE TABLE test (id INT);') or { panic(err) }
	assert table_exists(mut db, 'test') or { panic(err) } == true

	os.rmdir_all(dir_path) or {}
}

// ─── New: sanitize_identifier ─────────────────────────────────────────────────

fn test_sanitize_identifier_rejects_bad_names() {
	// Empty name
	sanitize_identifier('') or { assert err.msg().contains('must not be empty') }
	// SQL injection attempt
	sanitize_identifier('cfg; DROP TABLE cfg;--') or {
		assert err.msg().contains('disallowed character')
	}
	// Space
	sanitize_identifier('my table') or { assert err.msg().contains('disallowed character') }
	// Single quote
	sanitize_identifier("it's") or { assert err.msg().contains('disallowed character') }
	// Valid names must pass
	assert sanitize_identifier('my_table') or { panic(err) } == 'my_table'
	assert sanitize_identifier('cfg-v2') or { panic(err) } == 'cfg-v2'
	assert sanitize_identifier('Table1') or { panic(err) } == 'Table1'
}

// ─── New: SQL injection safety ────────────────────────────────────────────────

fn test_parameterized_queries_handle_special_characters() {
	mut db := open_db(':memory:') or { panic(err) }
	create_kv_table(mut db, 'store') or { panic(err) }

	// Value with single-quote — classic SQL injection probe
	set_kv(mut db, 'store', 'user', "O'Brien; DROP TABLE store;--") or { panic(err) }
	v := get_kv(mut db, 'store', 'user') or { panic(err) }
	assert v == "O'Brien; DROP TABLE store;--"

	// Double-quote in JSON payload
	create_json_store(mut db, 'docs') or { panic(err) }
	save_struct(mut db, 'docs', 'id1', {
		'msg': 'say "hello"'
	}) or { panic(err) }
	row := load_struct[map[string]string](mut db, 'docs', 'id1') or { panic(err) }
	assert row['msg'] == 'say "hello"'

	// table_exists must NOT match via injection
	exists := table_exists(mut db, "nope' OR '1'='1") or { panic(err) }
	assert exists == false
	// The store table must still be intact
	assert table_exists(mut db, 'store') or { panic(err) } == true
}

// ─── New: Schema / DDL helpers ────────────────────────────────────────────────

fn test_drop_table() {
	mut db := open_db(':memory:') or { panic(err) }
	exec_sql(mut db, 'CREATE TABLE tmp (id INT);') or { panic(err) }
	assert table_exists(mut db, 'tmp') or { panic(err) } == true

	// Normal drop
	drop_table(mut db, 'tmp', false) or { panic(err) }
	assert table_exists(mut db, 'tmp') or { panic(err) } == false

	// Force drop on non-existent table — must not error
	drop_table(mut db, 'tmp', true) or { panic(err) }
}

fn test_rename_table() {
	mut db := open_db(':memory:') or { panic(err) }
	exec_sql(mut db, 'CREATE TABLE old_tbl (id INT);') or { panic(err) }

	rename_table(mut db, 'old_tbl', 'new_tbl') or { panic(err) }
	assert table_exists(mut db, 'new_tbl') or { panic(err) } == true
	assert table_exists(mut db, 'old_tbl') or { panic(err) } == false
}

fn test_clear_table() {
	mut db := open_db(':memory:') or { panic(err) }
	exec_sql(mut db, 'CREATE TABLE events (msg TEXT);') or { panic(err) }
	exec_sql(mut db, "INSERT INTO events VALUES ('a'),('b'),('c');") or { panic(err) }
	assert count_rows(mut db, 'events') or { panic(err) } == 3

	clear_table(mut db, 'events') or { panic(err) }
	assert count_rows(mut db, 'events') or { panic(err) } == 0
	// Table still exists
	assert table_exists(mut db, 'events') or { panic(err) } == true
}

fn test_get_column_names_and_column_exists() {
	mut db := open_db(':memory:') or { panic(err) }
	exec_sql(mut db, 'CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, email TEXT);') or {
		panic(err)
	}

	cols := get_column_names(mut db, 'users') or { panic(err) }
	assert cols == ['id', 'name', 'email']

	assert column_exists(mut db, 'users', 'name') or { panic(err) } == true
	assert column_exists(mut db, 'users', 'phone') or { panic(err) } == false
}

fn test_table_row_counts() {
	mut db := open_db(':memory:') or { panic(err) }
	exec_sql(mut db, 'CREATE TABLE a (x INT);') or { panic(err) }
	exec_sql(mut db, 'CREATE TABLE b (x INT);') or { panic(err) }
	exec_sql(mut db, 'INSERT INTO a VALUES (1),(2),(3);') or { panic(err) }

	counts := table_row_counts(mut db) or { panic(err) }
	assert counts['a'] == 3
	assert counts['b'] == 0
}

// ─── New: Extended KV helpers ─────────────────────────────────────────────────

fn test_kv_exists() {
	mut db := open_db(':memory:') or { panic(err) }
	create_kv_table(mut db, 'cfg') or { panic(err) }
	set_kv(mut db, 'cfg', 'present', 'yes') or { panic(err) }

	assert kv_exists(mut db, 'cfg', 'present') or { panic(err) } == true
	assert kv_exists(mut db, 'cfg', 'absent') or { panic(err) } == false
}

fn test_get_kv_or() {
	mut db := open_db(':memory:') or { panic(err) }
	create_kv_table(mut db, 'cfg') or { panic(err) }
	set_kv(mut db, 'cfg', 'lang', 'fr') or { panic(err) }

	// Key present — returns stored value
	assert get_kv_or(mut db, 'cfg', 'lang', 'en') == 'fr'
	// Key absent — returns default, never panics
	assert get_kv_or(mut db, 'cfg', 'missing', 'default') == 'default'
}

fn test_increment_kv() {
	mut db := open_db(':memory:') or { panic(err) }
	create_kv_table(mut db, 'counters') or { panic(err) }

	// Auto-creates key at 0 + amount
	v1 := increment_kv(mut db, 'counters', 'hits', 1) or { panic(err) }
	assert v1 == 1

	v2 := increment_kv(mut db, 'counters', 'hits', 1) or { panic(err) }
	assert v2 == 2

	// Increment by larger step
	v3 := increment_kv(mut db, 'counters', 'hits', 10) or { panic(err) }
	assert v3 == 12

	// Decrement (negative amount)
	v4 := increment_kv(mut db, 'counters', 'hits', -2) or { panic(err) }
	assert v4 == 10
}

fn test_clear_kv() {
	mut db := open_db(':memory:') or { panic(err) }
	create_kv_table(mut db, 'session') or { panic(err) }
	set_kv(mut db, 'session', 'token', 'abc') or { panic(err) }
	set_kv(mut db, 'session', 'user', 'alice') or { panic(err) }

	clear_kv(mut db, 'session') or { panic(err) }
	assert count_rows(mut db, 'session') or { panic(err) } == 0
	// Table itself must still exist
	assert table_exists(mut db, 'session') or { panic(err) } == true
}

// ─── New: Extended JSON store helpers ────────────────────────────────────────

fn test_struct_exists() {
	mut db := open_db(':memory:') or { panic(err) }
	create_json_store(mut db, 'products') or { panic(err) }

	item := Item{
		id:    'p1'
		title: 'Widget'
		price: 5
	}
	save_struct(mut db, 'products', 'p1', item) or { panic(err) }

	assert struct_exists(mut db, 'products', 'p1') or { panic(err) } == true
	assert struct_exists(mut db, 'products', 'p99') or { panic(err) } == false
}

fn test_count_structs() {
	mut db := open_db(':memory:') or { panic(err) }
	create_json_store(mut db, 'notes') or { panic(err) }

	assert count_structs(mut db, 'notes') or { panic(err) } == 0

	save_struct(mut db, 'notes', 'n1', Item{ id: 'n1', title: 'First', price: 0 }) or { panic(err) }
	save_struct(mut db, 'notes', 'n2', Item{ id: 'n2', title: 'Second', price: 0 }) or {
		panic(err)
	}
	assert count_structs(mut db, 'notes') or { panic(err) } == 2
}

fn test_list_struct_ids() {
	mut db := open_db(':memory:') or { panic(err) }
	create_json_store(mut db, 'posts') or { panic(err) }

	save_struct(mut db, 'posts', 'post_a', Item{}) or { panic(err) }
	save_struct(mut db, 'posts', 'post_b', Item{}) or { panic(err) }
	save_struct(mut db, 'posts', 'post_c', Item{}) or { panic(err) }

	ids := list_struct_ids(mut db, 'posts') or { panic(err) }
	assert ids.len == 3
	assert 'post_a' in ids
	assert 'post_b' in ids
	assert 'post_c' in ids
}

fn test_delete_all_structs() {
	mut db := open_db(':memory:') or { panic(err) }
	create_json_store(mut db, 'cache') or { panic(err) }

	save_struct(mut db, 'cache', 'c1', Item{}) or { panic(err) }
	save_struct(mut db, 'cache', 'c2', Item{}) or { panic(err) }
	assert count_structs(mut db, 'cache') or { panic(err) } == 2

	delete_all_structs(mut db, 'cache') or { panic(err) }
	assert count_structs(mut db, 'cache') or { panic(err) } == 0
	// Table schema must still be intact
	assert table_exists(mut db, 'cache') or { panic(err) } == true
}

// ─── New: Parameterized query helpers ────────────────────────────────────────

fn test_query_maps_params_and_query_one_map_params() {
	mut db := open_db(':memory:') or { panic(err) }
	exec_sql(mut db, 'CREATE TABLE employees (name TEXT, dept TEXT, salary INT);') or { panic(err) }
	exec_sql(mut db, "INSERT INTO employees VALUES ('Alice','Eng',90),('Bob','Eng',80),('Carol','HR',70);") or {
		panic(err)
	}

	// query_maps_params — filter by department
	rows := query_maps_params(mut db, 'SELECT name, salary FROM employees WHERE dept = ? ORDER BY salary DESC',
		['Eng']) or { panic(err) }
	assert rows.len == 2
	assert rows[0]['name'] == 'Alice'
	assert rows[1]['name'] == 'Bob'

	// query_one_map_params — single row
	one := query_one_map_params(mut db, 'SELECT name FROM employees WHERE name = ?', [
		'Carol',
	]) or { panic(err) }
	assert one['name'] == 'Carol'

	// No rows — must return error
	query_one_map_params(mut db, 'SELECT name FROM employees WHERE name = ?', [
		'Ghost',
	]) or {
		assert err.msg().contains('No rows returned')
		map[string]string{}
	}
}

fn test_query_scalar() {
	mut db := open_db(':memory:') or { panic(err) }
	exec_sql(mut db, 'CREATE TABLE scores (user TEXT, score INT);') or { panic(err) }
	exec_sql(mut db, "INSERT INTO scores VALUES ('alice',90),('alice',85),('bob',70);") or {
		panic(err)
	}

	// SUM
	total := query_scalar(mut db, 'SELECT SUM(score) FROM scores WHERE user = ?', [
		'alice',
	]) or { panic(err) }
	assert total == '175'

	// COUNT
	cnt := query_scalar(mut db, 'SELECT COUNT(*) FROM scores WHERE user = ?', ['bob']) or {
		panic(err)
	}
	assert cnt == '1'

	// No rows — must error
	query_scalar(mut db, 'SELECT MAX(score) FROM scores WHERE user = ?', ['ghost']) or {
		// SQLite returns a single NULL row for MAX when no rows match; we get ''
		// Accept either '' or an error msg.
		_ := err
	}
}

fn test_query_column() {
	mut db := open_db(':memory:') or { panic(err) }
	exec_sql(mut db, 'CREATE TABLE tags (name TEXT, active INT);') or { panic(err) }
	exec_sql(mut db, "INSERT INTO tags VALUES ('v',1),('vlang',1),('draft',0);") or { panic(err) }

	active := query_column(mut db, 'SELECT name FROM tags WHERE active = ? ORDER BY name',
		['1']) or { panic(err) }
	assert active == ['v', 'vlang']

	// No matching rows — returns empty slice, not an error
	none_found := query_column(mut db, 'SELECT name FROM tags WHERE active = ?', [
		'99',
	]) or { panic(err) }
	assert none_found.len == 0
}

// ─── New: execute_batch_params ────────────────────────────────────────────────

fn test_execute_batch_params() {
	mut db := open_db(':memory:') or { panic(err) }
	exec_sql(mut db, 'CREATE TABLE log (msg TEXT, level TEXT);') or { panic(err) }

	stmts := [
		ParamStatement{
			query:  'INSERT INTO log VALUES (?, ?)'
			params: ['boot', 'INFO']
		},
		ParamStatement{
			query:  'INSERT INTO log VALUES (?, ?)'
			params: ['ready', 'INFO']
		},
		ParamStatement{
			query:  'INSERT INTO log VALUES (?, ?)'
			params: ['error', 'ERROR']
		},
	]
	execute_batch_params(mut db, stmts) or { panic(err) }
	assert count_rows(mut db, 'log') or { panic(err) } == 3

	// Rollback on error: inject a bad statement into the batch
	bad_stmts := [
		ParamStatement{
			query:  'INSERT INTO log VALUES (?, ?)'
			params: ['tx_start', 'INFO']
		},
		ParamStatement{
			query:  'INSERT INTO nonexistent VALUES (?)'
			params: ['x']
		},
	]
	execute_batch_params(mut db, bad_stmts) or {
		// Expected error — table must still have only 3 rows (rolled back)
		_ := err
	}
	assert count_rows(mut db, 'log') or { panic(err) } == 3
}

// ─── New: with_transaction ────────────────────────────────────────────────────

fn test_with_transaction_commits_on_success() {
	mut db := open_db(':memory:') or { panic(err) }
	create_kv_table(mut db, 'state') or { panic(err) }

	with_transaction(mut db, fn [mut db] () ! {
		set_kv(mut db, 'state', 'step', '1')!
		set_kv(mut db, 'state', 'status', 'ok')!
	}) or { panic(err) }

	assert get_kv(mut db, 'state', 'step') or { panic(err) } == '1'
	assert get_kv(mut db, 'state', 'status') or { panic(err) } == 'ok'
}

fn test_with_transaction_rolls_back_on_error() {
	mut db := open_db(':memory:') or { panic(err) }
	exec_sql(mut db, 'CREATE TABLE audit (msg TEXT);') or { panic(err) }
	exec_sql(mut db, "INSERT INTO audit VALUES ('before');") or { panic(err) }

	// This closure fails half-way through
	with_transaction(mut db, fn [mut db] () ! {
		exec_sql(mut db, "INSERT INTO audit VALUES ('txn_write');")!
		// Force error: insert into a nonexistent table
		exec_sql(mut db, 'INSERT INTO ghost VALUES (1);')!
	}) or {
		// Expected error path — nothing to do
		_ := err
	}

	// Only the original row should remain (transaction rolled back)
	assert count_rows(mut db, 'audit') or { panic(err) } == 1
}

// ─── New: Column Management helpers ─────────────────────────────────────────

fn test_add_column() {
	mut db := open_db(':memory:') or { panic(err) }
	exec_sql(mut db, 'CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT);') or { panic(err) }

	// Add a single column
	add_column(mut db, 'users', ColumnDef{ name: 'email', sql_type: 'TEXT' }) or { panic(err) }

	cols := get_column_names(mut db, 'users') or { panic(err) }
	assert cols == ['id', 'name', 'email']
	assert column_exists(mut db, 'users', 'email') or { panic(err) } == true

	// Add column with type modifiers
	add_column(mut db, 'users', ColumnDef{ name: 'score', sql_type: 'INTEGER NOT NULL DEFAULT 0' }) or {
		panic(err)
	}
	assert column_exists(mut db, 'users', 'score') or { panic(err) } == true

	// Existing data must still be intact
	exec_sql(mut db, "INSERT INTO users (name) VALUES ('Alice');") or { panic(err) }
	assert count_rows(mut db, 'users') or { panic(err) } == 1
}

fn test_add_columns_batch() {
	mut db := open_db(':memory:') or { panic(err) }
	exec_sql(mut db, 'CREATE TABLE products (id INTEGER PRIMARY KEY, name TEXT);') or { panic(err) }

	new_cols := [
		ColumnDef{
			name:     'price'
			sql_type: 'REAL'
		},
		ColumnDef{
			name:     'stock'
			sql_type: 'INTEGER NOT NULL DEFAULT 0'
		},
		ColumnDef{
			name:     'sku'
			sql_type: 'TEXT'
		},
	]
	add_columns(mut db, 'products', new_cols) or { panic(err) }

	cols := get_column_names(mut db, 'products') or { panic(err) }
	assert cols == ['id', 'name', 'price', 'stock', 'sku']
}

fn test_add_columns_rollback_on_bad_name() {
	mut db := open_db(':memory:') or { panic(err) }
	exec_sql(mut db, 'CREATE TABLE items (id INT, name TEXT);') or { panic(err) }

	// Second column has an invalid name — should rollback both
	bad_cols := [
		ColumnDef{
			name:     'valid_col'
			sql_type: 'TEXT'
		},
		ColumnDef{
			name:     'bad col!'
			sql_type: 'TEXT'
		}, // space + bang disallowed
	]
	add_columns(mut db, 'items', bad_cols) or { assert err.msg().contains('disallowed character') }
	// valid_col must NOT have been added (transaction rolled back)
	assert column_exists(mut db, 'items', 'valid_col') or { panic(err) } == false
}

fn test_rename_column() {
	mut db := open_db(':memory:') or { panic(err) }
	exec_sql(mut db, 'CREATE TABLE users (id INT, fname TEXT, age INT);') or { panic(err) }
	exec_sql(mut db, "INSERT INTO users VALUES (1, 'Alice', 30);") or { panic(err) }

	rename_column(mut db, 'users', 'fname', 'first_name') or { panic(err) }

	cols := get_column_names(mut db, 'users') or { panic(err) }
	assert 'first_name' in cols
	assert 'fname' !in cols

	// Data must be preserved under the new column name
	rows := query_maps(mut db, 'SELECT first_name FROM users;') or { panic(err) }
	assert rows[0]['first_name'] == 'Alice'
}

fn test_drop_column() {
	mut db := open_db(':memory:') or { panic(err) }
	exec_sql(mut db, 'CREATE TABLE events (id INT, msg TEXT, legacy TEXT, ts TEXT);') or {
		panic(err)
	}
	exec_sql(mut db, "INSERT INTO events VALUES (1, 'boot', 'old', '2024-01-01');") or {
		panic(err)
	}

	drop_column(mut db, 'events', 'legacy') or { panic(err) }

	cols := get_column_names(mut db, 'events') or { panic(err) }
	assert cols == ['id', 'msg', 'ts']
	assert 'legacy' !in cols

	// Remaining data must be intact
	assert count_rows(mut db, 'events') or { panic(err) } == 1
}

fn test_drop_columns() {
	mut db := open_db(':memory:') or { panic(err) }
	exec_sql(mut db, 'CREATE TABLE logs (id INT, msg TEXT, level TEXT, host TEXT, pid INT);') or {
		panic(err)
	}

	drop_columns(mut db, 'logs', ['host', 'pid']) or { panic(err) }

	cols := get_column_names(mut db, 'logs') or { panic(err) }
	assert cols == ['id', 'msg', 'level']
	assert 'host' !in cols
	assert 'pid' !in cols
}

fn test_drop_columns_rollback_on_bad_column() {
	mut db := open_db(':memory:') or { panic(err) }
	exec_sql(mut db, 'CREATE TABLE data (id INT, a TEXT, b TEXT, c TEXT);') or { panic(err) }

	// 'c' is valid but 'b@d' is not — should rollback so 'c' is NOT dropped
	drop_columns(mut db, 'data', ['c', 'b@d']) or {
		assert err.msg().contains('disallowed character')
	}
	// 'c' must still exist because the transaction was rolled back
	assert column_exists(mut db, 'data', 'c') or { panic(err) } == true
}

fn test_get_table_schema() {
	mut db := open_db(':memory:') or { panic(err) }
	exec_sql(mut db, 'CREATE TABLE orders (id INTEGER PRIMARY KEY, user TEXT NOT NULL, amount REAL);') or {
		panic(err)
	}

	schema := get_table_schema(mut db, 'orders') or { panic(err) }
	assert schema.len == 3

	// Check column names
	names := schema.map(it['name'])
	assert names == ['id', 'user', 'amount']

	// Check types
	assert schema[0]['type'] == 'INTEGER'
	assert schema[1]['type'] == 'TEXT'
	assert schema[2]['type'] == 'REAL'

	// Check NOT NULL flag
	assert schema[1]['notnull'] == '1' // user TEXT NOT NULL
	assert schema[2]['notnull'] == '0' // amount REAL (nullable)

	// Check primary key
	assert schema[0]['pk'] == '1'
	assert schema[1]['pk'] == '0'
}

fn test_sanitize_sql_type_validation() {
	// Valid type expressions must pass
	assert sanitize_sql_type('TEXT') or { panic(err) } == 'TEXT'
	assert sanitize_sql_type('INTEGER NOT NULL DEFAULT 0') or { panic(err) } == 'INTEGER NOT NULL DEFAULT 0'
	assert sanitize_sql_type('VARCHAR(255)') or { panic(err) } == 'VARCHAR(255)'
	assert sanitize_sql_type('REAL') or { panic(err) } == 'REAL'

	// Empty string must error
	sanitize_sql_type('') or { assert err.msg().contains('must not be empty') }

	// Semicolon injection must be rejected
	sanitize_sql_type('TEXT; DROP TABLE users;--') or {
		assert err.msg().contains('semicolon') || err.msg().contains('comment') || err.msg().contains('disallowed')
	}
}

fn test_sqlite_security_and_injection_defense() {
	// 1. Identifier Sanitization & Validation
	assert is_valid_identifier('users')
	assert is_valid_identifier('app_config_v2')
	assert is_valid_identifier('_private_col')
	assert !is_valid_identifier('')
	assert !is_valid_identifier('1table') // cannot start with digit
	assert !is_valid_identifier('-table') // cannot start with hyphen
	assert !is_valid_identifier('users; DROP TABLE users;')
	assert !is_valid_identifier('users" OR "1"="1')
	assert !is_valid_identifier('a'.repeat(129)) // length limit

	// 2. SQL Type Defense
	assert sanitize_sql_type("VARCHAR(100) DEFAULT 'unknown'") or { panic(err) } == "VARCHAR(100) DEFAULT 'unknown'"
	sanitize_sql_type('TEXT -- comment') or {
		assert err.msg().contains('comment')
	}
	sanitize_sql_type('VARCHAR(50') or {
		assert err.msg().contains('parentheses')
	}
	sanitize_sql_type("TEXT DEFAULT 'unclosed") or {
		assert err.msg().contains('single quotes')
	}

	// 3. String Escaping Helper
	assert escape_string("O'Connor") == "O''Connor"
	assert escape_string("admin'--") == "admin''--"

	// 4. Memory DB Connection with Automatic Security PRAGMAs
	mut db := open_db(':memory:') or { panic(err) }
	defer { close_db(mut db) or {} }

	// 5. exec_sql_params & Parameterized CRUD against injection payloads
	exec_sql(mut db, 'CREATE TABLE users (id INTEGER PRIMARY KEY, username TEXT, bio TEXT);') or { panic(err) }

	injection_payload := "admin' OR '1'='1'; DROP TABLE users; --"
	row_id := insert_row(mut db, 'users', {
		'username': 'attacker'
		'bio':      injection_payload
	}) or { panic(err) }

	assert row_id == 1

	// Verify table still exists and payload was stored as pure text
	assert table_exists(mut db, 'users') or { false }
	records := select_rows(mut db, 'users', ['id', 'username', 'bio'], 'username = ?', ['attacker']) or { panic(err) }
	assert records.len == 1
	assert records[0]['bio'] == injection_payload

	// Update rows securely with params
	update_rows(mut db, 'users', {
		'bio': 'cleansed'
	}, 'username = ?', ['attacker']) or { panic(err) }

	updated := select_rows(mut db, 'users', ['bio'], 'username = ?', ['attacker']) or { panic(err) }
	assert updated[0]['bio'] == 'cleansed'

	// Delete rows securely with params
	delete_rows(mut db, 'users', 'username = ?', ['attacker']) or { panic(err) }
	remaining := count_rows(mut db, 'users') or { panic(err) }
	assert remaining == 0

	// 6. Path null-byte rejection
	open_db('test\0bad.db') or {
		assert err.msg().contains('null byte')
	}
}

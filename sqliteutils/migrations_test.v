module sqliteutils

import os

fn test_split_sql_statements() {
	script := '
-- leading comment
CREATE TABLE a (x TEXT DEFAULT \'semi;colon\'); /* block ; comment */
INSERT INTO a VALUES (\'it\'\'s; fine\');
CREATE TRIGGER t AFTER INSERT ON a BEGIN
  UPDATE a SET x = CASE WHEN x = \'q\' THEN \'r;\' ELSE x END;
  SELECT 1;
END;
SELECT "weird;name" FROM [b;c]
-- trailing comment only
'
	stmts := split_sql_statements(script)
	assert stmts.len == 4, stmts.str()
	assert stmts[0].starts_with('CREATE TABLE a') && stmts[0].contains("'semi;colon'")
	assert stmts[1] == "INSERT INTO a VALUES ('it''s; fine')"
	assert stmts[2].starts_with('CREATE TRIGGER') && stmts[2].ends_with('END')
	assert stmts[3] == 'SELECT "weird;name" FROM [b;c]'
	assert split_sql_statements('  ;; -- nothing\n').len == 0
}

const migrations_v2 = [
	'CREATE TABLE users (id INTEGER PRIMARY KEY, email TEXT UNIQUE NOT NULL);',
	"ALTER TABLE users ADD COLUMN name TEXT DEFAULT '';
	 CREATE INDEX idx_users_name ON users(name);",
]

fn test_migrations_are_incremental_and_atomic() {
	mut db := open_db(':memory:') or { panic(err) }
	defer {
		close_db(mut db) or {}
	}
	assert schema_version(mut db) or { -1 } == 0
	assert migrate(mut db, migrations_v2) or { panic(err) } == 2
	assert schema_version(mut db) or { -1 } == 2
	assert migrate(mut db, migrations_v2) or { panic(err) } == 0 // idempotent
	assert column_exists(mut db, 'users', 'name') or { false }

	// A broken migration rolls back completely and leaves the version untouched.
	mut bad := migrations_v2.clone()
	bad << 'CREATE TABLE t3 (a INT); INSERT INTO nope VALUES (1);'
	migrate(mut db, bad) or {
		assert err.msg().contains('migration 3')
		assert schema_version(mut db) or { -1 } == 2
		assert !(table_exists(mut db, 't3') or { true })
		// Database newer than the code: refuse.
		set_schema_version(mut db, 9) or { panic(err) }
		migrate(mut db, migrations_v2) or {
			assert err.msg().contains('newer')
			return
		}
		assert false
		return
	}
	assert false
}

fn test_exec_script_atomic() {
	mut db := open_db(':memory:') or { panic(err) }
	defer {
		close_db(mut db) or {}
	}
	assert exec_script(mut db, "CREATE TABLE k (v TEXT); INSERT INTO k VALUES ('a');") or {
		panic(err)
	} == 2
	exec_script(mut db, "INSERT INTO k VALUES ('b'); INSERT INTO missing VALUES (1);") or {
		assert count_rows(mut db, 'k') or { -1 } == 1 // 'b' rolled back
		return
	}
	assert false
}

fn test_upsert_and_paginate() {
	mut db := open_db(':memory:') or { panic(err) }
	defer {
		close_db(mut db) or {}
	}
	exec_sql(mut db, 'CREATE TABLE prefs (user TEXT, key TEXT, val TEXT, PRIMARY KEY (user, key));') or {
		panic(err)
	}
	upsert_row(mut db, 'prefs', {
		'user': 'u1'
		'key':  'theme'
		'val':  'dark'
	}, ['user', 'key']) or { panic(err) }
	upsert_row(mut db, 'prefs', {
		'user': 'u1'
		'key':  'theme'
		'val':  'light'
	}, ['user', 'key']) or { panic(err) }
	assert count_rows(mut db, 'prefs') or { 0 } == 1
	assert query_scalar(mut db, 'SELECT val FROM prefs', []) or { '' } == 'light'
	upsert_row(mut db, 'prefs', {
		'user"; DROP TABLE prefs; --': 'x'
	}, ['user']) or { assert err.msg().contains('disallowed') }

	exec_sql(mut db, 'CREATE TABLE n (i INTEGER);') or { panic(err) }
	for i in 1 .. 26 {
		insert_row(mut db, 'n', {
			'i': i.str()
		}) or { panic(err) }
	}
	p := paginate(mut db, 'SELECT i FROM n WHERE i > ? ORDER BY i', ['0'], 3, 10) or { panic(err) }
	assert p.total == 25 && p.total_pages == 3
	assert p.rows.map(it['i']) == ['21', '22', '23', '24', '25']
	paginate(mut db, 'SELECT 1', [], 0, 10) or { return }
	assert false
}

fn test_maintenance() {
	dir := os.join_path(os.temp_dir(), 'sqliteutils_maint_${os.getpid()}')
	os.rmdir_all(dir) or {}
	defer {
		os.rmdir_all(dir) or {}
	}
	mut db := open_db(os.join_path(dir, 'live.db')) or { panic(err) }
	enable_wal(mut db, 2000) or { panic(err) }
	assert query_scalar(mut db, 'PRAGMA journal_mode;', []) or { '' } == 'wal'
	exec_script(mut db, 'CREATE TABLE t (v TEXT); INSERT INTO t VALUES (1);') or { panic(err) }
	assert (integrity_check(mut db) or { panic(err) }).len == 0
	backup := os.join_path(dir, 'backup', 'copy.db')
	vacuum_into(mut db, backup) or { panic(err) }
	close_db(mut db) or {}
	mut copy := open_db(backup) or { panic(err) }
	assert table_exists(mut copy, 't') or { false }
	close_db(mut copy) or {}
}

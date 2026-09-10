module main

import sqliteutils

struct UserProfile {
	id     string
	name   string
	email  string
	points int
}

fn main() {
	println('==================================================')
	println('              demo_sqliteutils                    ')
	println('==================================================')

	db_path := ':memory:'
	mut db := sqliteutils.open_db(db_path)!
	defer {
		sqliteutils.close_db(mut db) or {}
	}
	println('Opened in-memory SQLite database')

	// 1. Key-Value Store
	sqliteutils.create_kv_table(mut db, 'settings')!
	sqliteutils.set_kv(mut db, 'settings', 'theme', 'cyberpunk')!
	sqliteutils.set_kv(mut db, 'settings', 'font_size', '14')!
	theme := sqliteutils.get_kv_or(mut db, 'settings', 'theme', 'default')
	font_size := sqliteutils.get_kv_or(mut db, 'settings', 'font_size', '12')
	has_theme := sqliteutils.kv_exists(mut db, 'settings', 'theme')!
	println('KV Settings: theme=${theme}, font_size=${font_size}, exists=${has_theme}')
	assert theme == 'cyberpunk'
	assert has_theme == true

	// 2. Document Store (JSON persistence for structs)
	sqliteutils.create_json_store(mut db, 'users')!
	alice := UserProfile{
		id: 'usr_01'
		name: 'Alice Developer'
		email: 'alice@example.com'
		points: 250
	}
	sqliteutils.save_struct(mut db, 'users', alice.id, alice)!
	loaded_alice := sqliteutils.load_struct[UserProfile](mut db, 'users', alice.id)!
	println('Document loaded: id=${loaded_alice.id}, name="${loaded_alice.name}", points=${loaded_alice.points}')
	assert loaded_alice.name == 'Alice Developer'
	assert loaded_alice.points == 250

	keys := sqliteutils.list_struct_ids(mut db, 'users')!
	println('Document keys: ${keys}')
	assert 'usr_01' in keys

	// 3. SQL execution & Parameterized CRUD
	sqliteutils.exec_sql(mut db, 'CREATE TABLE audit_logs (id INTEGER PRIMARY KEY, action TEXT, created_at TEXT);')!
	new_id := sqliteutils.insert_row(mut db, 'audit_logs', {
		'action':     'USER_LOGIN'
		'created_at': '2026-09-10 12:00:00'
	})!
	println('Inserted audit log ID: ${new_id}')
	assert new_id > 0

	rows := sqliteutils.select_rows(mut db, 'audit_logs', ['action', 'created_at'], 'action = ?', [
		'USER_LOGIN',
	])!
	println('Found ${rows.len} matching audit log(s): action=${rows[0]['action']}')
	assert rows.len == 1

	// 4. Updates & Deletions
	sqliteutils.update_rows(mut db, 'audit_logs', {
		'action': 'USER_LOGOUT'
	}, 'id = ?', ['${new_id}'])!
	updated_rows := sqliteutils.select_rows(mut db, 'audit_logs', ['action'], 'id = ?', [
		'${new_id}',
	])!
	assert updated_rows[0]['action'] == 'USER_LOGOUT'

	sqliteutils.delete_rows(mut db, 'audit_logs', 'id = ?', ['${new_id}'])!
	rem_rows := sqliteutils.select_rows(mut db, 'audit_logs', ['id'], '1 = 1', [])!
	assert rem_rows.len == 0

	println('\n✔ sqliteutils demo completed successfully!')
}

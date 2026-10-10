module sqlbuilder

fn test_select_builder() {
	query, params := select('id', 'name', 'email')
		.from('users')
		.where('status = ?', 'active')
		.where_in('role', ['admin', 'editor'])
		.order_by('created_at', .desc)
		.paginate(2, 25)
		.build()

	assert query == 'SELECT id, name, email FROM users WHERE status = ? AND role IN (?, ?) ORDER BY created_at DESC LIMIT 25 OFFSET 25'
	assert params == ['active', 'admin', 'editor']

	inlined := select('id', 'name')
		.from('users')
		.where('id = ?', '42')
		.to_sql()
	assert inlined == "SELECT id, name FROM users WHERE id = '42'"
}

fn test_insert_builder() {
	query, params := insert_into('products')
		.columns('title', 'price')
		.values('Mechanical Keyboard', '99.99')
		.build()

	assert query == 'INSERT INTO products (title, price) VALUES (?, ?)'
	assert params == ['Mechanical Keyboard', '99.99']

	inlined := insert_into('products')
		.columns('title')
		.values("O'Reilly Book")
		.to_sql()
	assert inlined == "INSERT INTO products (title) VALUES ('O''Reilly Book')"
}

fn test_update_builder() {
	query, params := update('users')
		.set('name', 'Bob')
		.set('role', 'editor')
		.where('id = ?', '10')
		.build()

	assert query == 'UPDATE users SET name = ?, role = ? WHERE id = ?'
	assert params == ['Bob', 'editor', '10']
}

fn test_delete_builder() {
	query, params := delete_from('sessions')
		.where('expired_at < ?', '2026-01-01')
		.build()

	assert query == 'DELETE FROM sessions WHERE expired_at < ?'
	assert params == ['2026-01-01']
}

fn test_sql_injection_defense() {
	// Malicious payload trying to escape quotes
	malicious := "admin' OR '1'='1"
	escaped := escape_string(malicious)
	assert escaped == "'admin'' OR ''1''=''1'"

	// Null byte stripping
	with_null := 'user\x00name'
	assert escape_string(with_null) == "'username'"

	// Inline query with question mark in string literal
	inlined := select('id')
		.from('questions')
		.where("title = 'What?' AND author = ?", "O'Connor")
		.to_sql()
	assert inlined == "SELECT id FROM questions WHERE title = 'What?' AND author = 'O''Connor'"
}

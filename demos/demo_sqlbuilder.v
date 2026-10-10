module main

import sqlbuilder

fn main() {
	println('=== demo_sqlbuilder: Fluent SQL Query Construction & Pagination ===\n')

	// 1. Fluent SELECT Query with Filtering, Joins, and Sorting
	q1, p1 := sqlbuilder.select('u.id', 'u.name', 'u.email', 'p.title as role')
		.from('users u')
		.left_join('roles p', 'u.role_id = p.id')
		.where('u.status = ?', 'active')
		.where_in('u.country', ['US', 'CA', 'DE'])
		.order_by('u.created_at', .desc)
		.paginate(1, 20)
		.build()

	println('1. Parameterized SELECT Query:')
	println('   Query:  ${q1}')
	println('   Params: ${p1}')

	// 2. Safe Escaped Inlined SQL
	inlined := sqlbuilder.select('*')
		.from('articles')
		.where('author = ?', "O'Reilly")
		.to_sql()
	println('\n2. Safe Inlined SQL:')
	println('   ${inlined}')

	// 3. Batch INSERT Builder
	q3, p3 := sqlbuilder.insert_into('events')
		.columns('type', 'user_id', 'created_at')
		.values('login', '1001', '2026-10-10 12:00:00')
		.values('click', '1001', '2026-10-10 12:05:00')
		.build()
	println('\n3. Multi-row INSERT Query:')
	println('   Query:  ${q3}')
	println('   Params: ${p3}')

	// 4. UPDATE Builder
	q4, p4 := sqlbuilder.update('users')
		.set('is_verified', '1')
		.where('id = ?', '42')
		.build()
	println('\n4. UPDATE Query:')
	println('   Query:  ${q4}')
	println('   Params: ${p4}')

	// 5. DELETE Builder
	q5, p5 := sqlbuilder.delete_from('tokens')
		.where('expires_at < ?', '2026-10-10')
		.build()
	println('\n5. DELETE Query:')
	println('   Query:  ${q5}')
	println('   Params: ${p5}')

	println('\n=== demo_sqlbuilder completed successfully ===')
}

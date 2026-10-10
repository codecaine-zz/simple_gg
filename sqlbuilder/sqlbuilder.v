module sqlbuilder

import strings

pub enum OrderDirection {
	asc
	desc
}

// -----------------------------------------------------------------------
// Safe string escaping for SQL injection defense
// -----------------------------------------------------------------------

pub fn escape_string(val string) string {
	mut sb := strings.new_builder(val.len + 8)
	sb.write_u8(`'`)
	for b in val {
		if b == `'` {
			sb.write_string("''")
		} else if b == `\\` {
			sb.write_string('\\\\')
		} else if b == `\x00` {
			// ignore null bytes
		} else {
			sb.write_u8(b)
		}
	}
	sb.write_u8(`'`)
	return sb.str()
}

pub fn escape_identifier(name string) string {
	mut sb := strings.new_builder(name.len + 4)
	sb.write_u8(`"`)
	for b in name {
		if b == `"` {
			sb.write_string('""')
		} else {
			sb.write_u8(b)
		}
	}
	sb.write_u8(`"`)
	return sb.str()
}

// -----------------------------------------------------------------------
// SELECT Builder
// -----------------------------------------------------------------------

pub struct SelectBuilder {
pub:
	columns    []string
	table      string
	joins      []string
	wheres     []string
	params     []string
	group_bys  []string
	havings    []string
	order_bys  []string
	limit_val  int = -1
	offset_val int = -1
}

pub fn select(columns ...string) SelectBuilder {
	mut cols := []string{}
	if columns.len == 0 {
		cols << '*'
	} else {
		for c in columns {
			cols << c
		}
	}
	return SelectBuilder{
		columns: cols
	}
}

pub fn (b SelectBuilder) from(table string) SelectBuilder {
	return SelectBuilder{
		...b
		table: table
	}
}

pub fn (b SelectBuilder) join(table string, on_cond string) SelectBuilder {
	mut joins := b.joins.clone()
	joins << 'INNER JOIN ${table} ON ${on_cond}'
	return SelectBuilder{
		...b
		joins: joins
	}
}

pub fn (b SelectBuilder) left_join(table string, on_cond string) SelectBuilder {
	mut joins := b.joins.clone()
	joins << 'LEFT JOIN ${table} ON ${on_cond}'
	return SelectBuilder{
		...b
		joins: joins
	}
}

pub fn (b SelectBuilder) right_join(table string, on_cond string) SelectBuilder {
	mut joins := b.joins.clone()
	joins << 'RIGHT JOIN ${table} ON ${on_cond}'
	return SelectBuilder{
		...b
		joins: joins
	}
}

pub fn (b SelectBuilder) where(cond string, params ...string) SelectBuilder {
	mut wheres := b.wheres.clone()
	wheres << cond
	mut p := b.params.clone()
	for item in params {
		p << item
	}
	return SelectBuilder{
		...b
		wheres: wheres
		params: p
	}
}

pub fn (b SelectBuilder) where_eq(column string, val string) SelectBuilder {
	return b.where('${column} = ?', val)
}

pub fn (b SelectBuilder) where_in(column string, values []string) SelectBuilder {
	if values.len == 0 {
		return b.where('1 = 0')
	}
	placeholders := []string{len: values.len, init: '?'}.join(', ')
	return b.where('${column} IN (${placeholders})', ...values)
}

pub fn (b SelectBuilder) where_not_in(column string, values []string) SelectBuilder {
	if values.len == 0 {
		return b
	}
	placeholders := []string{len: values.len, init: '?'}.join(', ')
	return b.where('${column} NOT IN (${placeholders})', ...values)
}

pub fn (b SelectBuilder) where_null(column string) SelectBuilder {
	return b.where('${column} IS NULL')
}

pub fn (b SelectBuilder) where_not_null(column string) SelectBuilder {
	return b.where('${column} IS NOT NULL')
}

pub fn (b SelectBuilder) or_where(cond string, params ...string) SelectBuilder {
	mut wheres := b.wheres.clone()
	if wheres.len == 0 {
		wheres << cond
	} else {
		last_idx := wheres.len - 1
		wheres[last_idx] = '(${wheres[last_idx]}) OR (${cond})'
	}
	mut p := b.params.clone()
	for item in params {
		p << item
	}
	return SelectBuilder{
		...b
		wheres: wheres
		params: p
	}
}

pub fn (b SelectBuilder) group_by(columns ...string) SelectBuilder {
	mut group_bys := b.group_bys.clone()
	for c in columns {
		group_bys << c
	}
	return SelectBuilder{
		...b
		group_bys: group_bys
	}
}

pub fn (b SelectBuilder) having(cond string, params ...string) SelectBuilder {
	mut havings := b.havings.clone()
	havings << cond
	mut p := b.params.clone()
	for item in params {
		p << item
	}
	return SelectBuilder{
		...b
		havings: havings
		params:  p
	}
}

pub fn (b SelectBuilder) order_by(column string, direction OrderDirection) SelectBuilder {
	mut order_bys := b.order_bys.clone()
	dir_str := match direction {
		.asc { 'ASC' }
		.desc { 'DESC' }
	}

	order_bys << '${column} ${dir_str}'
	return SelectBuilder{
		...b
		order_bys: order_bys
	}
}

pub fn (b SelectBuilder) limit(n int) SelectBuilder {
	return SelectBuilder{
		...b
		limit_val: n
	}
}

pub fn (b SelectBuilder) offset(n int) SelectBuilder {
	return SelectBuilder{
		...b
		offset_val: n
	}
}

pub fn (b SelectBuilder) paginate(page int, per_page int) SelectBuilder {
	p := if page < 1 { 1 } else { page }
	pp := if per_page < 1 { 10 } else { per_page }
	off := (p - 1) * pp
	return b.limit(pp).offset(off)
}

pub fn (b SelectBuilder) build() (string, []string) {
	mut query := 'SELECT ${b.columns.join(', ')}'
	if b.table.len > 0 {
		query += ' FROM ${b.table}'
	}
	for j in b.joins {
		query += ' ${j}'
	}
	if b.wheres.len > 0 {
		query += ' WHERE ' + b.wheres.join(' AND ')
	}
	if b.group_bys.len > 0 {
		query += ' GROUP BY ' + b.group_bys.join(', ')
	}
	if b.havings.len > 0 {
		query += ' HAVING ' + b.havings.join(' AND ')
	}
	if b.order_bys.len > 0 {
		query += ' ORDER BY ' + b.order_bys.join(', ')
	}
	if b.limit_val >= 0 {
		query += ' LIMIT ${b.limit_val}'
	}
	if b.offset_val >= 0 {
		query += ' OFFSET ${b.offset_val}'
	}
	return query, b.params.clone()
}

pub fn (b SelectBuilder) to_sql() string {
	query, params := b.build()
	return inline_params(query, params)
}

// -----------------------------------------------------------------------
// INSERT Builder
// -----------------------------------------------------------------------

pub struct InsertBuilder {
pub:
	table   string
	columns []string
	rows    [][]string
}

pub fn insert_into(table string) InsertBuilder {
	return InsertBuilder{
		table: table
	}
}

pub fn (b InsertBuilder) columns(cols ...string) InsertBuilder {
	return InsertBuilder{
		...b
		columns: cols.clone()
	}
}

pub fn (b InsertBuilder) values(vals ...string) InsertBuilder {
	mut new_row := []string{cap: vals.len}
	for v in vals {
		new_row << v
	}
	mut rows := [][]string{cap: b.rows.len + 1}
	for r in b.rows {
		rows << r
	}
	rows << new_row
	return InsertBuilder{
		...b
		rows: rows
	}
}

pub fn (b InsertBuilder) row(row_map map[string]string) InsertBuilder {
	mut cols := b.columns.clone()
	if cols.len == 0 {
		for k, _ in row_map {
			cols << k
		}
	}
	mut new_row := []string{cap: cols.len}
	for col in cols {
		new_row << (row_map[col] or { '' })
	}
	mut rows := [][]string{cap: b.rows.len + 1}
	for r in b.rows {
		rows << r
	}
	rows << new_row
	return InsertBuilder{
		...b
		columns: cols
		rows:    rows
	}
}

pub fn (b InsertBuilder) build() (string, []string) {
	if b.columns.len == 0 || b.rows.len == 0 {
		return '', []string{}
	}
	mut query := 'INSERT INTO ${b.table} (${b.columns.join(', ')}) VALUES '
	mut placeholders := []string{}
	mut all_params := []string{}

	row_placeholder := '(' + []string{len: b.columns.len, init: '?'}.join(', ') + ')'
	for row in b.rows {
		placeholders << row_placeholder
		for v in row {
			all_params << v
		}
	}
	query += placeholders.join(', ')
	return query, all_params
}

pub fn (b InsertBuilder) to_sql() string {
	query, params := b.build()
	return inline_params(query, params)
}

// -----------------------------------------------------------------------
// UPDATE Builder
// -----------------------------------------------------------------------

pub struct UpdateBuilder {
pub:
	table  string
	sets   []string
	params []string
	wheres []string
}

pub fn update(table string) UpdateBuilder {
	return UpdateBuilder{
		table: table
	}
}

pub fn (b UpdateBuilder) set(column string, val string) UpdateBuilder {
	mut sets := b.sets.clone()
	sets << '${column} = ?'
	mut p := b.params.clone()
	p << val
	return UpdateBuilder{
		...b
		sets:   sets
		params: p
	}
}

pub fn (b UpdateBuilder) set_map(values map[string]string) UpdateBuilder {
	mut sets := b.sets.clone()
	mut p := b.params.clone()
	for k, v in values {
		sets << '${k} = ?'
		p << v
	}
	return UpdateBuilder{
		...b
		sets:   sets
		params: p
	}
}

pub fn (b UpdateBuilder) where(cond string, params ...string) UpdateBuilder {
	mut wheres := b.wheres.clone()
	wheres << cond
	mut p := b.params.clone()
	for item in params {
		p << item
	}
	return UpdateBuilder{
		...b
		wheres: wheres
		params: p
	}
}

pub fn (b UpdateBuilder) build() (string, []string) {
	if b.sets.len == 0 {
		return '', []string{}
	}
	mut query := 'UPDATE ${b.table} SET ' + b.sets.join(', ')
	if b.wheres.len > 0 {
		query += ' WHERE ' + b.wheres.join(' AND ')
	}
	return query, b.params.clone()
}

pub fn (b UpdateBuilder) to_sql() string {
	query, params := b.build()
	return inline_params(query, params)
}

// -----------------------------------------------------------------------
// DELETE Builder
// -----------------------------------------------------------------------

pub struct DeleteBuilder {
pub:
	table  string
	wheres []string
	params []string
}

pub fn delete_from(table string) DeleteBuilder {
	return DeleteBuilder{
		table: table
	}
}

pub fn (b DeleteBuilder) where(cond string, params ...string) DeleteBuilder {
	mut wheres := b.wheres.clone()
	wheres << cond
	mut p := b.params.clone()
	for item in params {
		p << item
	}
	return DeleteBuilder{
		...b
		wheres: wheres
		params: p
	}
}

pub fn (b DeleteBuilder) build() (string, []string) {
	mut query := 'DELETE FROM ${b.table}'
	if b.wheres.len > 0 {
		query += ' WHERE ' + b.wheres.join(' AND ')
	}
	return query, b.params.clone()
}

pub fn (b DeleteBuilder) to_sql() string {
	query, params := b.build()
	return inline_params(query, params)
}

// -----------------------------------------------------------------------
// Parameter Inlining
// -----------------------------------------------------------------------

fn inline_params(query string, params []string) string {
	mut sb := strings.new_builder(query.len + params.len * 16)
	mut param_idx := 0
	mut in_quote := false
	mut quote_char := u8(0)

	for i := 0; i < query.len; i++ {
		b := query[i]
		if !in_quote && (b == `'` || b == `"`) {
			in_quote = true
			quote_char = b
			sb.write_u8(b)
		} else if in_quote && b == quote_char {
			// Check for doubled quote escape '' or ""
			if i + 1 < query.len && query[i + 1] == quote_char {
				sb.write_u8(b)
				sb.write_u8(query[i + 1])
				i++
			} else {
				in_quote = false
				sb.write_u8(b)
			}
		} else if !in_quote && b == `?` && param_idx < params.len {
			sb.write_string(escape_string(params[param_idx]))
			param_idx++
		} else {
			sb.write_u8(b)
		}
	}
	return sb.str()
}

module main

import os
import simplecli

fn get_sqlite_bin() string {
	if path := os.find_abs_path_of_executable('sqlite3') {
		return path
	}
	common_paths := [
		'/usr/bin/sqlite3',
		'/usr/local/bin/sqlite3',
		'/opt/homebrew/bin/sqlite3',
	]
	for p in common_paths {
		if os.exists(p) {
			return p
		}
	}
	return 'sqlite3'
}

fn main() {
	mut app := simplecli.new_app('sqlite-cli', '1.0.0')
	app.set_description('SQLite Database Explorer & SQL Query Workbench')

	app.add_flag_string('db', 'd', '', 'Path to SQLite database file')
	app.add_flag_string('query', 'q', '', 'SQL query expression to execute')
	app.add_flag_bool('schema', 's', false, 'Show complete database schema / tables')
	app.add_flag_bool('interactive', 'x', false, 'Launch interactive SQL terminal REPL')

	app.parse_cli() or { return }

	app.banner('SQLite Database Studio CLI', 'v1.0.0 - Headless Database Workbench')

	sqlite_bin := get_sqlite_bin()
	if !app.command_exists(sqlite_bin) {
		app.error('sqlite3 command not found on this system.')
		return
	}

	mut db_path := app.get_flag_string('db')
	if db_path.len == 0 {
		// Use in-memory or temp demo db
		db_path = os.temp_dir() + '/simplecli_demo.db'
		init_demo_db(mut app, sqlite_bin, db_path)
		app.info('No database specified. Using demo database at ${db_path}')
	}

	if !app.file_exists(db_path) {
		app.error('Database file does not exist: ${db_path}')
		return
	}

	if app.get_flag_bool('schema') {
		show_schema(mut app, sqlite_bin, db_path)
		return
	}

	query := app.get_flag_string('query')
	if query.len > 0 {
		run_query(mut app, sqlite_bin, db_path, query)
		return
	}

	// Interactive REPL
	app.panel('SQLite Interactive Console', 'Connected to: ${db_path}\nCommands: .tables, .schema, or any SQL SELECT/INSERT/UPDATE query. Type "exit" or "q" to quit.')
	for {
		sql_cmd := app.prompt('sqlite', 'SELECT * FROM users LIMIT 5;')
		if sql_cmd == 'exit' || sql_cmd == 'q' {
			app.success('Exiting SQLite Studio.')
			break
		}
		if sql_cmd.len > 0 {
			run_query(mut app, sqlite_bin, db_path, sql_cmd)
		}
	}
}

fn init_demo_db(mut app simplecli.SimpleCli, sqlite_bin string, path string) {
	init_sql := 'CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, name TEXT, email TEXT, role TEXT);
INSERT OR IGNORE INTO users (id, name, email, role) VALUES (1, "Alice", "alice@example.com", "Admin");
INSERT OR IGNORE INTO users (id, name, email, role) VALUES (2, "Bob", "bob@example.com", "Engineer");
INSERT OR IGNORE INTO users (id, name, email, role) VALUES (3, "Charlie", "charlie@example.com", "DevOps");'
	app.exec_safe(sqlite_bin, [path, init_sql])
}

fn show_schema(mut app simplecli.SimpleCli, sqlite_bin string, db_path string) {
	out, code := app.exec_safe(sqlite_bin, [db_path, '.schema'])
	if code == 0 {
		app.success('Database Schema:')
		println(out)
	} else {
		app.error('Failed to read schema (code ${code}): ${out}')
	}
}

fn run_query(mut app simplecli.SimpleCli, sqlite_bin string, db_path string, query string) {
	app.reset_timer()
	// Execute with column headers and markdown table formatting
	out, code := app.exec_safe(sqlite_bin, ['-header', '-column', db_path, query])
	elapsed := app.elapsed_ms()
	if code == 0 {
		app.success('Query executed in ${elapsed} ms:')
		println(out)
	} else {
		app.error('Query execution error (code ${code}):\n${out}')
	}
}

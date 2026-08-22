module main

import os
import time
import simplegui

// Helper to find sqlite3 path
fn get_sqlite_bin() string {
	if path := os.find_abs_path_of_executable('sqlite3') {
		return path
	}
	common_paths := [
		'/usr/bin/sqlite3',
		'/opt/homebrew/bin/sqlite3',
		'/usr/local/bin/sqlite3',
	]
	for p in common_paths {
		if os.exists(p) {
			return p
		}
	}
	return 'sqlite3'
}

const sample_sql_query = 'SELECT 
    p.id, 
    p.name AS product_name, 
    c.name AS category, 
    p.price, 
    p.stock_quantity,
    ROUND(p.price * p.stock_quantity, 2) AS total_inventory_value
FROM products p
JOIN categories c ON p.category_id = c.id
WHERE p.stock_quantity > 0
ORDER BY total_inventory_value DESC;'

fn main() {
	println('Starting SimpleGUI - SQLite Studio Pro (Embedded Database Workbench)...')

	mut win := simplegui.new_simple_window('SimpleGUI - SQLite Studio Pro', 1080, 950)
	win.set_fullscreen(true)
	win.set_spacing(8)
	win.set_padding(16)

	saved_theme := simplegui.get_saved_theme()
	win.set_theme(saved_theme)

	// Top Banner / Diagnostics
	win.begin_row('row_sqlite_top')
	win.add_heading('SQLite Studio Pro')
	win.add_label('lbl_theme', 'Theme:')
	win.add_dropdown('dd_app_theme', simplegui.list_themes(), saved_theme)
	win.set_control_width('dd_app_theme', 150)
	win.end_row()

	win.on_change('dd_app_theme', fn (mut w simplegui.SimpleWindow, selected string) {
		w.set_theme(selected)
		w.toast('Theme changed to ${selected}')
	})

	sqlite_path := get_sqlite_bin()
	win.add_label('lbl_engine_info', 'Engine: ${sqlite_path}  |  Platform: macOS Cocoa  |  Mode: Async Worker')

	// Database File Selection & Schema Browser
	win.begin_group_box('grp_db_config', 'Database Connection & Schema Explorer')
	
	win.begin_row('row_db_file')
	win.add_label('lbl_db_path', 'Database File:')
	win.add_input('txt_db_path', ':memory:')
	win.set_control_width('txt_db_path', 380)

	win.add_button('btn_open_db', 'Open Database...')
	win.add_button('btn_init_demo_db', 'Load Demo Store Database')
	win.add_button('btn_inspect_schema', 'Show Schema (.schema)')
	win.add_button('btn_list_tables', 'List Tables')
	win.end_row()

	win.end_group_box()

	// SQL Query Editor & Presets
	win.begin_group_box('grp_sql_editor', 'SQL Query Scratchpad & Recipes')
	
	win.begin_row('row_sql_presets')
	win.add_label('lbl_presets', 'SQL Templates:')
	win.add_dropdown('dd_sql_presets', [
		'1. Product Inventory Report (JOIN & Computed Value)',
		'2. Category Sales & Item Count (GROUP BY)',
		'3. Top 5 Expensive Products (ORDER BY & LIMIT)',
		'4. Explain Query Execution Plan (EXPLAIN QUERY PLAN)',
		'5. Insert New Product Record (INSERT INTO)',
		'6. Create Indexed Transactions Table (CREATE TABLE & INDEX)',
		'7. Count Total Records Across Tables',
		'8. Vacuum & Optimize Database (VACUUM; PRAGMA optimize;)'
	], '1. Product Inventory Report (JOIN & Computed Value)')
	win.set_control_width('dd_sql_presets', 380)

	win.add_label('lbl_output_mode', 'Output Format:')
	win.add_dropdown('dd_out_mode', [
		'Table Grid (-box / -column)',
		'JSON Format (-json)',
		'CSV Format (-csv)',
		'Markdown Table (-markdown)',
		'Line Mode (-line)'
	], 'Table Grid (-box / -column)')
	win.set_control_width('dd_out_mode', 220)
	win.end_row()

	win.add_textarea('txt_sql_query', sample_sql_query)
	win.set_control_height('txt_sql_query', 130)

	win.end_group_box()

	// Execution Actions Bar
	win.begin_row('row_exec_bar')
	win.add_button('btn_execute_sql', 'Execute SQL Query')
	win.add_button('btn_copy_results', 'Copy Results')
	win.add_button('btn_export_csv', 'Export as CSV...')
	win.add_button('btn_export_json', 'Export as JSON...')
	win.add_button('btn_clear_query', 'Clear')
	win.end_row()

	// Query Results Output
	win.begin_group_box('grp_results', 'Query Results & Data Grid')
	win.add_textarea('txt_results_view', '')
	win.set_control_height('txt_results_view', 280)
	win.end_group_box()

	// Activity & Diagnostics Console
	win.begin_group_box('grp_console', 'SQLite Execution Telemetry & Error Log')
	win.add_console('sqlite_console', 100)
	win.end_group_box()

	// Status Row
	win.begin_row('row_stats')
	win.add_label('lbl_stats', 'Stats: Ready  |  Database: :memory:  |  Rows: 0  |  Duration: 0 ms')
	win.end_row()

	win.append_console('sqlite_console', ' SQLite Studio Pro Initialized.\n', 1)
	win.append_console('sqlite_console', ' Ready to run queries against SQLite / In-Memory databases.\n', 4)

	// Demo Database Initializer Script
	demo_db_path := os.join_path(os.temp_dir(), 'simplegui_demo_store.sqlite')
	init_demo_db := fn [demo_db_path] () {
		init_sql := '
		DROP TABLE IF EXISTS products;
		DROP TABLE IF EXISTS categories;
		
		CREATE TABLE categories (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			name TEXT NOT NULL UNIQUE,
			description TEXT
		);

		CREATE TABLE products (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			category_id INTEGER REFERENCES categories(id),
			name TEXT NOT NULL,
			price REAL NOT NULL,
			stock_quantity INTEGER NOT NULL DEFAULT 0,
			created_at DATETIME DEFAULT CURRENT_TIMESTAMP
		);

		INSERT INTO categories (name, description) VALUES
			("Laptops & Computers", "MacBook Pro, iMac, Mac Studio"),
			("Audio & Headphones", "AirPods Max, Studio Monitors"),
			("Displays & Accessories", "Studio Display, Magic Keyboard");

		INSERT INTO products (category_id, name, price, stock_quantity) VALUES
			(1, "MacBook Pro 16 M3 Max", 3499.00, 14),
			(1, "Mac Studio M2 Ultra", 3999.00, 8),
			(1, "MacBook Air 15 M3", 1299.00, 32),
			(2, "AirPods Max Space Gray", 549.00, 25),
			(2, "AirPods Pro 2 USB-C", 249.00, 60),
			(3, "Apple Studio Display 5K", 1599.00, 18),
			(3, "Magic Keyboard with Touch ID", 199.00, 45);
		'
		sqlite := get_sqlite_bin()
		simplegui.exec_safe(sqlite, [demo_db_path, init_sql])
	}

	// -------------------------------------------------------------
	// Event Handlers
	// -------------------------------------------------------------

	// Load Demo Database
	win.on_click('btn_init_demo_db', fn [init_demo_db, demo_db_path] (mut w simplegui.SimpleWindow) {
		init_demo_db()
		w.set('txt_db_path', demo_db_path)
		w.set('txt_sql_query', sample_sql_query)
		w.toast('Demo Store database initialized!')
		w.append_console('sqlite_console', ' Created demo SQLite database at: ${demo_db_path}\n', 4)
	})

	// Open DB File Picker
	win.on_click('btn_open_db', fn (mut w simplegui.SimpleWindow) {
		path := w.select_file()
		if path != '' && os.exists(path) {
			w.set('txt_db_path', path)
			w.toast('Selected database: ' + os.file_name(path))
			w.append_console('sqlite_console', ' Database opened: ${path}\n', 1)
		}
	})

	// Preset Selection Handler
	win.on_change('dd_sql_presets', fn (mut w simplegui.SimpleWindow, selected string) {
		if selected.starts_with('1.') {
			w.set('txt_sql_query', sample_sql_query)
		} else if selected.starts_with('2.') {
			w.set('txt_sql_query', 'SELECT c.name AS category, COUNT(p.id) AS product_count, AVG(p.price) AS avg_price FROM categories c LEFT JOIN products p ON c.id = p.category_id GROUP BY c.name;')
		} else if selected.starts_with('3.') {
			w.set('txt_sql_query', 'SELECT name, price, stock_quantity FROM products ORDER BY price DESC LIMIT 5;')
		} else if selected.starts_with('4.') {
			w.set('txt_sql_query', 'EXPLAIN QUERY PLAN\n' + sample_sql_query)
		} else if selected.starts_with('5.') {
			w.set('txt_sql_query', 'INSERT INTO products (category_id, name, price, stock_quantity) VALUES (1, "Mac mini M2", 599.00, 20);')
		} else if selected.starts_with('6.') {
			w.set('txt_sql_query', 'CREATE TABLE IF NOT EXISTS audit_logs (id INTEGER PRIMARY KEY, action TEXT, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP);\nCREATE INDEX IF NOT EXISTS idx_audit_time ON audit_logs(timestamp);')
		} else if selected.starts_with('7.') {
			w.set('txt_sql_query', 'SELECT "categories" AS table_name, count(*) AS total_rows FROM categories\nUNION ALL\nSELECT "products", count(*) FROM products;')
		} else if selected.starts_with('8.') {
			w.set('txt_sql_query', 'VACUUM;\nPRAGMA optimize;')
		}
		w.toast('Loaded SQL template: ${selected.split("(")[0]}')
	})

	// Execute Query Worker
	win.on_click('btn_execute_sql', fn (mut w simplegui.SimpleWindow) {
		db_path := w.get('txt_db_path').trim_space()
		query_str := w.get('txt_sql_query').trim_space()

		if query_str == '' {
			w.alert('Query Required', 'Please enter a SQL statement to execute.')
			return
		}

		sqlite_bin := get_sqlite_bin()
		out_mode_raw := w.get('dd_out_mode')

		mut mode_flag := '-box'
		if out_mode_raw.contains('-json') { mode_flag = '-json' }
		else if out_mode_raw.contains('-csv') { mode_flag = '-csv' }
		else if out_mode_raw.contains('-markdown') { mode_flag = '-markdown' }
		else if out_mode_raw.contains('-line') { mode_flag = '-line' }

		target_db := if db_path == '' || db_path == ':memory:' { ':memory:' } else { db_path }

		mut raw_args := []string{}
		if mode_flag == '-box' {
			raw_args << ['-box', '-header']
		} else if mode_flag == '-csv' {
			raw_args << ['-csv', '-header']
		} else if mode_flag == '-markdown' {
			raw_args << ['-markdown', '-header']
		} else if mode_flag == '-line' {
			raw_args << '-line'
		} else {
			raw_args << '-json'
		}

		raw_args << target_db
		raw_args << query_str

		w.append_console('sqlite_console', ' Executing SQL (${mode_flag}) against ${target_db}...\n', 1)
		w.set_status('Running SQL query...')

		go fn [mut w, sqlite_bin, raw_args, target_db] () {
			t0 := time.ticks()
			res := simplegui.exec_safe(sqlite_bin, raw_args)
			elapsed_ms := time.ticks() - t0

			w.run_on_main_thread(fn [res, elapsed_ms, target_db] (mut win_main simplegui.SimpleWindow) {
				out := res.output.trim_space()
				win_main.set('txt_results_view', out)

				if res.exit_code == 0 {
					lines_cnt := if out != '' { out.split_into_lines().len } else { 0 }
					win_main.append_console('sqlite_console', ' SQL query executed successfully in ${elapsed_ms} ms (${out.len} bytes)\n', 4)
					win_main.set('lbl_stats', ' Stats: SUCCESS  |  DB: ${os.file_name(target_db)}  |  Output: ${lines_cnt} lines  |  Duration: ${elapsed_ms} ms')
					win_main.set_status('Query finished in ${elapsed_ms} ms.')
					win_main.toast('Query executed in ${elapsed_ms} ms!')
				} else {
					win_main.append_console('sqlite_console', ' SQLite Error:\n' + out + '\n', 3)
					win_main.set('lbl_stats', ' Stats: ERROR (Exit ${res.exit_code})  |  Duration: ${elapsed_ms} ms')
					win_main.set_status('Query execution failed.')
					win_main.toast('SQL error encountered.')
				}
			})
		}()
	})

	// Inspect Schema
	win.on_click('btn_inspect_schema', fn (mut w simplegui.SimpleWindow) {
		w.set('txt_sql_query', '.schema')
		w.set('dd_out_mode', 'Table Grid (-box / -column)')
		w.toast('Schema inspection command loaded.')
	})

	// List Tables
	win.on_click('btn_list_tables', fn (mut w simplegui.SimpleWindow) {
		w.set('txt_sql_query', 'SELECT name, type, sql FROM sqlite_master WHERE type IN ("table", "view") AND name NOT LIKE "sqlite_%";')
		w.set('dd_out_mode', 'Table Grid (-box / -column)')
		w.toast('List tables query loaded.')
	})

	// Copy Results
	win.on_click('btn_copy_results', fn (mut w simplegui.SimpleWindow) {
		out := w.get('txt_results_view')
		if out != '' {
			w.copy_to_clipboard(out)
			w.toast('Query results copied to clipboard!')
		} else {
			w.toast('No results to copy.')
		}
	})

	// Export as CSV
	win.on_click('btn_export_csv', fn (mut w simplegui.SimpleWindow) {
		db_path := w.get('txt_db_path').trim_space()
		query_str := w.get('txt_sql_query').trim_space()
		if query_str == '' {
			w.toast('SQL query is empty.')
			return
		}
		path := w.save_file_picker()
		if path != '' {
			mut save_file := path
			if !save_file.ends_with('.csv') { save_file += '.csv' }
			sqlite_bin := get_sqlite_bin()
			target_db := if db_path == '' || db_path == ':memory:' { ':memory:' } else { db_path }
			
			res := simplegui.exec_safe(sqlite_bin, ['-csv', '-header', target_db, query_str])
			os.write_file(save_file, res.output) or {
				w.toast('Failed to save file.')
				return
			}
			w.toast('Exported CSV to ${os.file_name(save_file)}')
			w.append_console('sqlite_console', ' Exported CSV results to: ${save_file}\n', 1)
		}
	})

	// Export as JSON
	win.on_click('btn_export_json', fn (mut w simplegui.SimpleWindow) {
		db_path := w.get('txt_db_path').trim_space()
		query_str := w.get('txt_sql_query').trim_space()
		if query_str == '' {
			w.toast('SQL query is empty.')
			return
		}
		path := w.save_file_picker()
		if path != '' {
			mut save_file := path
			if !save_file.ends_with('.json') { save_file += '.json' }
			sqlite_bin := get_sqlite_bin()
			target_db := if db_path == '' || db_path == ':memory:' { ':memory:' } else { db_path }
			
			res := simplegui.exec_safe(sqlite_bin, ['-json', target_db, query_str])
			os.write_file(save_file, res.output) or {
				w.toast('Failed to save file.')
				return
			}
			w.toast('Exported JSON to ${os.file_name(save_file)}')
			w.append_console('sqlite_console', ' Exported JSON results to: ${save_file}\n', 1)
		}
	})

	// Clear
	win.on_click('btn_clear_query', fn (mut w simplegui.SimpleWindow) {
		w.set('txt_sql_query', '')
		w.set('txt_results_view', '')
		w.clear_console('sqlite_console')
		w.toast('Cleared SQL query & results.')
	})

	win.start()
}

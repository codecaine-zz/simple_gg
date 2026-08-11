// Example 11: Data Table Pro
// Demonstrates the improved data table: click a column header to sort, scroll
// with the mouse wheel through a fixed-height table, hover row highlighting,
// row add/remove, and reading back the (possibly re-sorted) row data.

module main

import simplegui

fn main() {
	mut win := simplegui.new_simple_window('11 - Data Table Pro', 860, 370)
	win.set_theme('Apple Dark')

	win.add_heading('Data Table Pro')
	win.add_label('lbl_hint', 'Click a header to sort. Scroll the wheel over the table to scroll rows.')

	mut rows := [][]string{}
	names := ['Ada Lovelace', 'Alan Turing', 'Grace Hopper', 'Linus Torvalds', 'Margaret Hamilton',
		'Dennis Ritchie', 'Barbara Liskov', 'Ken Thompson', 'Radia Perlman', 'Guido van Rossum',
		'James Gosling', 'Anita Borg', 'John Backus', 'Katherine Johnson', 'Tim Berners-Lee']
	for idx, n in names {
		rows << [(idx + 1).str(), n, '${(idx * 7 + 3) % 60 + 20}', if idx % 3 == 0 {
			'Active'
		} else {
			'Away'
		}]
	}

	win.add_table('staff_table', ['ID', 'Name', 'Age', 'Status'], rows)
	win.set_control_height('staff_table', 220)

	win.on_row_click('staff_table', fn (mut win simplegui.SimpleWindow) {
		selected := win.get_table_selected_row('staff_table')
		win.show_toast('Row Selected', 'Selected table index ${selected}')
	})

	win.begin_row('table_actions')
	win.add_button('btn_add_row', 'Add Row')
	win.add_button('btn_remove_row', 'Remove Selected')
	win.add_button('btn_sort_name', 'Sort by Name')
	win.add_button('btn_print_rows', 'Print Rows')
	win.end_row()

	win.on_click('btn_add_row', fn (mut win simplegui.SimpleWindow) {
		win.add_table_row('staff_table', ['0', 'New Hire', '25', 'Active'])
	})

	win.on_click('btn_remove_row', fn (mut win simplegui.SimpleWindow) {
		selected := win.get_table_selected_row('staff_table')
		if selected >= 0 {
			win.remove_table_row('staff_table', selected)
		}
	})

	win.on_click('btn_sort_name', fn (mut win simplegui.SimpleWindow) {
		win.sort_table('staff_table', 1, true)
	})

	win.on_click('btn_print_rows', fn (mut win simplegui.SimpleWindow) {
		println(win.get_table_rows('staff_table'))
	})

	win.run()
}

module simplegui

fn test_textarea_selection_and_editing() {
	mut ctrl := Control{
		name:       'notes'
		kind:       'textarea'
		text_value: 'Hello World\nLine 2 Text\nLine 3 End'
		caret_pos:  0
	}

	assert ctrl.text_value == 'Hello World\nLine 2 Text\nLine 3 End'
	assert !ctrl.has_selection()

	// Test select all
	ctrl.select_all()
	assert ctrl.has_selection()
	assert ctrl.selected_text() == 'Hello World\nLine 2 Text\nLine 3 End'

	// Test delete selected text
	ctrl.delete_selected_text()
	assert ctrl.text_value == ''
	assert !ctrl.has_selection()
	assert ctrl.caret_pos == 0

	// Test undo
	assert ctrl.undo()
	assert ctrl.text_value == 'Hello World\nLine 2 Text\nLine 3 End'

	// Test manual range selection
	ctrl.sel_start = 6
	ctrl.sel_end = 11
	assert ctrl.has_selection()
	assert ctrl.selected_text() == 'World'

	s, e := ctrl.selection_range()
	assert s == 6
	assert e == 11
}

fn test_multiline_text_index_calculation() {
	mut win := new_simple_window('Test Window', 400, 300)
	mut ctrl := Control{
		name:       'ta'
		kind:       'textarea'
		text_value: "ABC\nDEF"
		x:          10
		y:          10
		w:          200
		h:          100
	}

	// Line 0 ("ABC") start index is 0, Line 1 ("DEF") start index is 4.
	// Click near top left (Line 0)
	idx0 := get_multiline_text_index(win, ctrl, 10.0, 10.0)
	assert idx0 == 0

	// Click below line 0 (Line 1)
	txt_sz := if ctrl.font_size > 0 { ctrl.font_size } else { 13 }
	line_h := f32(txt_sz + 4)
	idx1 := get_multiline_text_index(win, ctrl, 10.0, 10.0 + 8.0 + line_h + 2.0)
	assert idx1 >= 4
}

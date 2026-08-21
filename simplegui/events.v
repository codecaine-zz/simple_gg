// Module simplegui - Core UI Framework for V
// File: events.v
//
// Description:
//   This file handles event processing, hit-testing, mouse clicks, mouse movement, drag operations,
//   keyboard focus, text caret positioning, scroll wheel events, and keyboard shortcuts for SimpleGUI.
//   It intercepts raw platform events from V's `gg` graphics library and dispatches them to active controls.

module simplegui

import gg
import math
import sokol.sapp
import time

// measure_text_width returns font text width, with fallback for headless unit tests.
fn measure_text_width(win &SimpleWindow, text string) f32 {
	if win.gg_ctx == unsafe { nil } {
		return f32(text.len * 7)
	}
	return f32(win.gg_ctx.text_width(text))
}

// get_multiline_text_index calculates the character index in a multi-line control based on mouse (x, y) coordinates.
fn get_multiline_text_index(win &SimpleWindow, ctrl &Control, mx f32, my f32) int {
	left_pad := f32(10.0)
	top_pad := f32(8.0)
	txt_sz := if ctrl.font_size > 0 { ctrl.font_size } else { 13 }
	line_h := f32(txt_sz + 4)
	rel_y := my - (ctrl.y + top_pad)
	lines := ctrl.text_value.split('\n')
	if lines.len == 0 {
		return 0
	}
	mut target_line_idx := int(rel_y / line_h)
	if target_line_idx < 0 {
		target_line_idx = 0
	}
	if target_line_idx >= lines.len {
		target_line_idx = lines.len - 1
	}
	mut line_start_idx := 0
	for i in 0 .. target_line_idx {
		line_start_idx += lines[i].len + 1
	}
	target_line := lines[target_line_idx]
	rel_x := mx - (ctrl.x + left_pad)
	mut best_col := 0
	mut min_dist := f32(999999.0)
	for col in 0 .. target_line.len + 1 {
		sub := target_line[0..col]
		w := measure_text_width(win, sub)
		dist := math.abs(rel_x - w)
		if dist < min_dist {
			min_dist = dist
			best_col = col
		}
	}
	res := line_start_idx + best_col
	if res < 0 {
		return 0
	}
	if res > ctrl.text_value.len {
		return ctrl.text_value.len
	}
	return res
}

// handle_event receives raw input events (mouse move, mouse click, mouse scroll, key press)
// from the windowing subsystem and dispatches them to appropriate control callback handlers.
pub fn (mut win SimpleWindow) handle_event(e &gg.Event) {
	match e.typ {
		.mouse_move {
			// Update current mouse coordinates in window state
			win.mouse_x = e.mouse_x
			win.mouse_y = e.mouse_y

			if win.modal_active {
				layout := win.get_modal_layout()
				if win.modal_input_mode && win.mouse_x >= layout.content_x && win.mouse_x <= layout.content_x + layout.input_w
					&& win.mouse_y >= layout.input_y && win.mouse_y <= layout.input_y + layout.input_h {
					win.cursor_name = 'ibeam'
					if win.mouse_down {
						left_pad := f32(10.0)
						rel_x := win.mouse_x - (layout.content_x + left_pad)
						mut min_dist := f32(999999.0)
						mut best_idx := 0
						for idx in 0 .. win.modal_input_val.len + 1 {
							sub := win.modal_input_val[0..idx]
							w := measure_text_width(win, sub)
							dist := math.abs(rel_x - w)
							if dist < min_dist {
								min_dist = dist
								best_idx = idx
							}
						}
						win.modal_input_caret = best_idx
					}
				} else {
					win.cursor_name = 'arrow'
				}
				return
			}

			mut new_hover := ''
			// Hit-test mouse position against all active, visible controls
			for mut ctrl in win.controls {
				if ctrl.visible && !ctrl.disabled {
					was_hovered := ctrl.is_hovered
					if win.mouse_x >= ctrl.x && win.mouse_x <= ctrl.x + ctrl.w
						&& win.mouse_y >= ctrl.y && win.mouse_y <= ctrl.y + ctrl.h {
						ctrl.is_hovered = true
						new_hover = ctrl.name
						if !was_hovered && ctrl.on_hover != unsafe { nil } {
							ctrl.on_hover(mut win)
						}
					} else {
						ctrl.is_hovered = false
					}

					// Handle mouse dragging for active sliders and splitters
					if ctrl.kind == 'range_slider' && win.mouse_down {
						range_w := ctrl.max_val - ctrl.min_val
						if range_w > 0 {
							rel_x := math.max(f32(0.0), math.min(ctrl.w, win.mouse_x - ctrl.x))
							val := ctrl.min_val + f64(rel_x / ctrl.w) * range_w
							if ctrl.is_dragging_min {
								ctrl.range_min = math.min(val, ctrl.range_max)
								if ctrl.on_change != unsafe { nil } { ctrl.on_change(mut win) }
							} else if ctrl.is_dragging_max {
								ctrl.range_max = math.max(val, ctrl.range_min)
								if ctrl.on_change != unsafe { nil } { ctrl.on_change(mut win) }
							}
						}
					} else if ctrl.kind == 'slider' && win.mouse_down && (ctrl.is_pressed || ctrl.is_focused) {
						rel_x := math.max(f32(0.0), math.min(ctrl.w, win.mouse_x - ctrl.x))
						pct := rel_x / ctrl.w
						ctrl.int_value = math.max(0, math.min(100, int(pct * 100.0)))
						ctrl.text_value = ctrl.int_value.str()
						if ctrl.on_change != unsafe { nil } { ctrl.on_change(mut win) }
					} else if ctrl.kind == 'step_slider' && win.mouse_down && (ctrl.is_pressed || ctrl.is_focused) {
						rel_x := win.mouse_x - (ctrl.x + 15.0)
						track_w := math.max(f32(1.0), ctrl.w - 50.0)
						pct := math.max(f32(0.0), math.min(f32(1.0), rel_x / track_w))
						step_cnt := if ctrl.int_value > 0 { ctrl.int_value } else { 4 }
						snapped_step := math.round(f64(pct) * f64(step_cnt))
						ctrl.f64_value = math.max(0.0, math.min(100.0, snapped_step * (100.0 / f64(step_cnt))))
						if ctrl.on_change != unsafe { nil } { ctrl.on_change(mut win) }
					} else if ctrl.kind == 'split_view' && ctrl.is_pressed {
						rel_x := math.max(f32(0.1), math.min(f32(0.9), (win.mouse_x - ctrl.x) / ctrl.w))
						ctrl.split_ratio = rel_x
						if ctrl.on_change != unsafe { nil } { ctrl.on_change(mut win) }
					}

					if win.is_selecting_text && win.mouse_down && ctrl.is_focused
						&& ctrl.kind in ['input', 'password', 'textarea', 'search_field', 'search_bar', 'file_picker', 'color_picker', 'pin_code', 'time_picker', 'tag_input', 'code_editor', 'code_studio'] {
						mut best_idx := 0
						if ctrl.kind in ['textarea', 'code_editor', 'code_studio'] {
							best_idx = get_multiline_text_index(win, ctrl, win.mouse_x, win.mouse_y)
						} else {
							left_pad := if ctrl.kind == 'search_bar' { f32(32.0) } else { f32(10.0) }
							rel_x := win.mouse_x - (ctrl.x + left_pad)
							mut min_dist := f32(999999.0)
							for idx in 0 .. ctrl.text_value.len + 1 {
								sub := ctrl.text_value[0..idx]
								w := f32(win.gg_ctx.text_width(sub))
								dist := math.abs(rel_x - w)
								if dist < min_dist {
									min_dist = dist
									best_idx = idx
								}
							}
						}
						ctrl.sel_start = win.text_select_anchor
						ctrl.sel_end = best_idx
						ctrl.caret_pos = best_idx
					}
				}
			}
			win.hovered_control = new_hover
		}
		.mouse_down {
			win.mouse_down = true
			win.mouse_x = e.mouse_x
			win.mouse_y = e.mouse_y
			is_shift := (e.modifiers & u32(gg.Modifier.shift)) != 0

			if win.modal_active {
				layout := win.get_modal_layout()

				// 1. Close 'X' button click
				if win.mouse_x >= layout.close_x - 4.0 && win.mouse_x <= layout.close_x + layout.close_sz + 4.0
					&& win.mouse_y >= layout.close_y - 4.0 && win.mouse_y <= layout.close_y + layout.close_sz + 4.0 {
					cb := win.modal_on_cancel
					win.hide_modal()
					if cb != unsafe { nil } {
						cb(mut win)
					}
					return
				}

				// 2. Text Input Box click & caret position
				if win.modal_input_mode && win.mouse_x >= layout.content_x && win.mouse_x <= layout.content_x + layout.input_w
					&& win.mouse_y >= layout.input_y && win.mouse_y <= layout.input_y + layout.input_h {
					left_pad := f32(10.0)
					rel_x := win.mouse_x - (layout.content_x + left_pad)
					mut min_dist := f32(999999.0)
					mut best_idx := 0
					for idx in 0 .. win.modal_input_val.len + 1 {
						sub := win.modal_input_val[0..idx]
						w := measure_text_width(win, sub)
						dist := math.abs(rel_x - w)
						if dist < min_dist {
							min_dist = dist
							best_idx = idx
						}
					}
					win.modal_input_caret = best_idx
					return
				}

				// 3. Checkbox toggle click
				if win.modal_checkbox_txt.len > 0 {
					if win.mouse_x >= layout.content_x && win.mouse_x <= layout.content_x + layout.content_w
						&& win.mouse_y >= layout.check_y - 2.0 && win.mouse_y <= layout.check_y + 20.0 {
						win.modal_checkbox_val = !win.modal_checkbox_val
						return
					}
				}

				// 4. Action Buttons Click (Confirm, Cancel, Neutral)
				if win.mouse_y >= layout.btn_y && win.mouse_y <= layout.btn_y + layout.btn_h {
					if win.mouse_x >= layout.confirm_x && win.mouse_x <= layout.confirm_x + layout.confirm_w {
						cb := win.modal_on_confirm
						win.hide_modal()
						if cb != unsafe { nil } {
							cb(mut win)
						}
						return
					} else if win.modal_cancel_txt.len > 0 && win.mouse_x >= layout.cancel_x && win.mouse_x <= layout.cancel_x + layout.cancel_w {
						cb := win.modal_on_cancel
						win.hide_modal()
						if cb != unsafe { nil } {
							cb(mut win)
						}
						return
					} else if win.modal_neutral_txt.len > 0 && win.mouse_x >= layout.neutral_x && win.mouse_x <= layout.neutral_x + layout.neutral_w {
						cb := win.modal_on_neutral
						win.hide_modal()
						if cb != unsafe { nil } {
							cb(mut win)
						}
						return
					}
				}
				return
			}

			if e.mouse_button == .right {
				for mut ctrl in win.controls {
					if ctrl.visible && !ctrl.disabled {
						if win.mouse_x >= ctrl.x && win.mouse_x <= ctrl.x + ctrl.w
							&& win.mouse_y >= ctrl.y && win.mouse_y <= ctrl.y + ctrl.h {
							if ctrl.on_right_click != unsafe { nil } {
								ctrl.on_right_click(mut win)
							}
						}
					}
				}
			}

			if win.toasts.len > 0 {
				mut ty := f32(20.0)
				t_w := f32(280.0)
				t_h := f32(54.0)
				tx := f32(win.width) - t_w - 20.0
				mut clicked_toast_idx := -1
				for idx in 0 .. win.toasts.len {
					if win.mouse_x >= tx && win.mouse_x <= tx + t_w && win.mouse_y >= ty && win.mouse_y <= ty + t_h {
						clicked_toast_idx = idx
						break
					}
					ty += t_h + 10.0
				}
				if clicked_toast_idx >= 0 && clicked_toast_idx < win.toasts.len {
					mut remaining_toasts := []Toast{}
					for i, t in win.toasts {
						if i != clicked_toast_idx {
							remaining_toasts << t
						}
					}
					win.toasts = remaining_toasts
					return
				}
			}

			if win.command_palette_active {
				box_w := f32(math.min(500, win.width - 40))
				box_h := f32(300.0)
				bx := (f32(win.width) - box_w) / 2.0
				by := f32(80.0)
				if win.mouse_x < bx || win.mouse_x > bx + box_w || win.mouse_y < by || win.mouse_y > by + box_h {
					win.hide_command_palette()
					return
				}
			}

			if win.context_menu_active {
				menu_w := f32(180.0)
				menu_h := f32(win.context_menu_items.len * 30 + 10)
				if win.mouse_x >= win.context_menu_x && win.mouse_x <= win.context_menu_x + menu_w && win.mouse_y >= win.context_menu_y && win.mouse_y <= win.context_menu_y + menu_h {
					idx := int((win.mouse_y - (win.context_menu_y + 5)) / 30)
					if idx >= 0 && idx < win.context_menu_items.len {
						item := win.context_menu_items[idx]
						win.hide_context_menu()
						if item.on_select != unsafe { nil } {
							item.on_select(mut win)
						}
						return
					}
				} else {
					win.hide_context_menu()
				}
			}

			mut clicked_ctrl := ''
			for mut ctrl in win.controls {
				if ctrl.visible && !ctrl.disabled {
					if win.mouse_x >= ctrl.x && win.mouse_x <= ctrl.x + ctrl.w
						&& win.mouse_y >= ctrl.y && win.mouse_y <= ctrl.y + ctrl.h {
						ctrl.is_pressed = true
						ctrl.is_focused = true
						clicked_ctrl = ctrl.name

						if ctrl.kind in ['input', 'password', 'textarea', 'search_field',
							'search_bar', 'file_picker', 'color_picker', 'pin_code', 'time_picker', 'tag_input', 'code_editor', 'code_studio'] {
							mut best_idx := 0
							if ctrl.kind in ['textarea', 'code_editor', 'code_studio'] {
								best_idx = get_multiline_text_index(win, ctrl, win.mouse_x, win.mouse_y)
							} else {
								left_pad := if ctrl.kind == 'search_bar' { f32(32.0) } else { f32(10.0) }
								rel_x := win.mouse_x - (ctrl.x + left_pad)
								mut min_dist := f32(999999.0)
								for idx in 0 .. ctrl.text_value.len + 1 {
									sub := ctrl.text_value[0..idx]
									w := f32(win.gg_ctx.text_width(sub))
									dist := math.abs(rel_x - w)
									if dist < min_dist {
										min_dist = dist
										best_idx = idx
									}
								}
							}
							if is_shift {
								if !ctrl.has_selection() {
									ctrl.sel_start = ctrl.caret_pos
								}
								ctrl.sel_end = best_idx
								ctrl.caret_pos = best_idx
							} else {
								ctrl.caret_pos = best_idx
								ctrl.sel_start = best_idx
								ctrl.sel_end = best_idx
								win.is_selecting_text = true
								win.text_select_anchor = best_idx
							}
						}

						if ctrl.kind in ['checkbox', 'toggle', 'switch'] {
							ctrl.bool_value = !ctrl.bool_value
							ctrl.text_value = ctrl.bool_value.str()
							if ctrl.on_change != unsafe { nil } {
								ctrl.on_change(mut win)
							}
						} else if ctrl.kind == 'slider' {
							rel_x := win.mouse_x - ctrl.x
							pct := rel_x / ctrl.w
							ctrl.int_value = int(pct * 100.0)
							ctrl.text_value = ctrl.int_value.str()
							if ctrl.on_change != unsafe { nil } {
								ctrl.on_change(mut win)
							}
						} else if ctrl.kind == 'tag_input' {
							mut cur_x := ctrl.x + 6.0
							cur_y := ctrl.y + 5.0
							for idx, tag in ctrl.tags {
								tag_w := f32(tag.len * 7 + 22)
								if win.mouse_x >= cur_x + tag_w - 18.0 && win.mouse_x <= cur_x + tag_w && win.mouse_y >= cur_y && win.mouse_y <= cur_y + 24.0 {
									mut new_tags := []string{}
									for i, t in ctrl.tags {
										if i != idx {
											new_tags << t
										}
									}
									ctrl.tags = new_tags
									if ctrl.on_change != unsafe { nil } { ctrl.on_change(mut win) }
									break
								}
								cur_x += tag_w + 6.0
							}
						} else if ctrl.kind == 'range_slider' {
							range_w := ctrl.max_val - ctrl.min_val
							if range_w > 0 {
								min_pct := f32((ctrl.range_min - ctrl.min_val) / range_w)
								max_pct := f32((ctrl.range_max - ctrl.min_val) / range_w)
								fill_x1 := ctrl.x + min_pct * ctrl.w
								fill_x2 := ctrl.x + max_pct * ctrl.w
								if math.abs(win.mouse_x - fill_x1) < math.abs(win.mouse_x - fill_x2) {
									ctrl.is_dragging_min = true
								} else {
									ctrl.is_dragging_max = true
								}
							}
						} else if ctrl.kind == 'property_grid' {
							if win.mouse_y > ctrl.y + 24.0 {
								idx := int((win.mouse_y - (ctrl.y + 28.0)) / 28.0)
								if idx >= 0 && idx < ctrl.property_items.len {
									mut item := ctrl.property_items[idx]
									if item.kind == 'bool' {
										item.val = if item.val == 'true' { 'false' } else { 'true' }
										ctrl.property_items[idx] = item
										if ctrl.on_change != unsafe { nil } { ctrl.on_change(mut win) }
									}
								}
							}
						} else if ctrl.kind == 'pagination' {
							if win.mouse_x >= ctrl.x + ctrl.w - 90 && win.mouse_x <= ctrl.x + ctrl.w - 50 {
								if ctrl.current_page > 1 {
									ctrl.current_page--
									if ctrl.on_change != unsafe { nil } { ctrl.on_change(mut win) }
								}
							} else if win.mouse_x >= ctrl.x + ctrl.w - 44 && win.mouse_x <= ctrl.x + ctrl.w {
								if ctrl.current_page < ctrl.total_pages {
									ctrl.current_page++
									if ctrl.on_change != unsafe { nil } { ctrl.on_change(mut win) }
								}
							}
						} else if ctrl.kind == 'rating' {
							rel_x := win.mouse_x - ctrl.x
							star := int(rel_x / 24.0) + 1
							if star >= 1 && star <= 5 {
								ctrl.int_value = star
								if ctrl.on_change != unsafe { nil } {
									ctrl.on_change(mut win)
								}
							}
						} else if ctrl.kind == 'dropdown' {
							if ctrl.items.len > 0 {
								mut cur_idx := 0
								for idx, item in ctrl.items {
									if item == ctrl.text_value {
										cur_idx = idx
										break
									}
								}
								next_idx := (cur_idx + 1) % ctrl.items.len
								ctrl.text_value = ctrl.items[next_idx]
								ctrl.int_value = next_idx
								if ctrl.on_change != unsafe { nil } {
									ctrl.on_change(mut win)
								}
							}
						} else if ctrl.kind in ['segmented', 'mode_control', 'tab_pills',
							'tab_container_start'] {
							if ctrl.items.len > 0 {
								seg_w := ctrl.w / f32(ctrl.items.len)
								idx := int((win.mouse_x - ctrl.x) / seg_w)
								if idx >= 0 && idx < ctrl.items.len {
									ctrl.int_value = idx
									ctrl.text_value = ctrl.items[idx]
									if ctrl.on_change != unsafe { nil } {
										ctrl.on_change(mut win)
									}
								}
							}
						} else if ctrl.kind in ['table', 'grid'] {
							header_h := table_header_height(ctrl)
							if header_h > 0 && win.mouse_y < ctrl.y + header_h {
								col_widths := calc_table_col_widths(ctrl)
								mut cur_col_x := ctrl.x
								mut clicked_col := -1
								for c_idx in 0 .. ctrl.headers.len {
									col_w := if c_idx < col_widths.len {
										col_widths[c_idx]
									} else {
										ctrl.w / f32(ctrl.headers.len)
									}
									if win.mouse_x >= cur_col_x && win.mouse_x < cur_col_x + col_w {
										clicked_col = c_idx
										break
									}
									cur_col_x += col_w
								}
								if clicked_col >= 0 {
									if ctrl.sort_col == clicked_col {
										ctrl.sort_asc = !ctrl.sort_asc
									} else {
										ctrl.sort_col = clicked_col
										ctrl.sort_asc = true
									}
									sort_table_rows(ctrl, clicked_col, ctrl.sort_asc)
									ctrl.selected_row = -1
									if ctrl.on_change != unsafe { nil } {
										ctrl.on_change(mut win)
									}
								}
							} else if ctrl.rows.len > 0 {
								rel_y := win.mouse_y - (ctrl.y + header_h) + ctrl.scroll_offset_y
								row_idx := int(rel_y / 26.0)
								if row_idx >= 0 && row_idx < ctrl.rows.len {
									ctrl.selected_row = row_idx
									if ctrl.on_row_click != unsafe { nil } {
										ctrl.on_row_click(mut win)
									}
									if ctrl.on_change != unsafe { nil } {
										ctrl.on_change(mut win)
									}
								}
							}
						} else if ctrl.kind == 'accordion' {
							ctrl.is_expanded = !ctrl.is_expanded
							ctrl.h = if ctrl.is_expanded { f32(110.0) } else { f32(36.0) }
							if ctrl.on_change != unsafe { nil } {
								ctrl.on_change(mut win)
							}
						} else if ctrl.kind == 'search_bar' {
							clear_x := ctrl.x + ctrl.w - 28
							if win.mouse_x >= clear_x && ctrl.text_value.len > 0 {
								ctrl.text_value = ''
								if ctrl.on_change != unsafe { nil } {
									ctrl.on_change(mut win)
								}
							}
						} else if ctrl.kind == 'file_picker' {
							btn_x := ctrl.x + ctrl.w - 80.0
							if win.mouse_x >= btn_x {
								picked := open_native_file_dialog()
								if picked.len > 0 {
									ctrl.text_value = picked
								} else if ctrl.text_value.len == 0 {
									ctrl.text_value = '/Users/documents/file.txt'
								}
								if ctrl.on_change != unsafe { nil } {
									ctrl.on_change(mut win)
								}
								if ctrl.on_click != unsafe { nil } {
									ctrl.on_click(mut win)
								}
							}
						} else if ctrl.kind == 'drop_zone' {
							picked := open_native_file_dialog()
							if picked.len > 0 {
								if picked !in ctrl.items {
									ctrl.items << picked
								}
								ctrl.text_value = picked
								if ctrl.on_change != unsafe { nil } {
									ctrl.on_change(mut win)
								}
								if ctrl.on_click != unsafe { nil } {
									ctrl.on_click(mut win)
								}
								win.push_toast('File Added', 'Added ${picked} to drop zone', 'success', 2500)
							}
						} else if ctrl.kind == 'tree_view' {
							rel_y := win.mouse_y - (ctrl.y + 6.0)
							node_idx := int(rel_y / 24.0)
							if node_idx >= 0 && node_idx < ctrl.tree_nodes.len {
								ctrl.tree_nodes[node_idx].expanded = !ctrl.tree_nodes[node_idx].expanded
								if ctrl.on_change != unsafe { nil } {
									ctrl.on_change(mut win)
								}
							}
						} else if ctrl.kind == 'number' {
							up_x := ctrl.x + ctrl.w - 24
							if win.mouse_x >= up_x {
								if win.mouse_y <= ctrl.y + ctrl.h / 2.0 {
									ctrl.int_value++
								} else {
									ctrl.int_value--
								}
								if ctrl.on_change != unsafe { nil } {
									ctrl.on_change(mut win)
								}
							}
						} else if ctrl.kind == 'list_box' {
							rel_y := win.mouse_y - (ctrl.y + 4.0)
							idx := int(rel_y / 24.0)
							if idx >= 0 && idx < ctrl.items.len {
								ctrl.int_value = idx
								ctrl.text_value = ctrl.items[idx]
								if ctrl.on_change != unsafe { nil } {
									ctrl.on_change(mut win)
								}
								if ctrl.on_click != unsafe { nil } {
									ctrl.on_click(mut win)
								}
							}
						} else if ctrl.kind == 'multi_list_box' {
							rel_y := win.mouse_y - (ctrl.y + 4.0)
							idx := int(rel_y / 24.0)
							if idx >= 0 && idx < ctrl.items.len {
								item := ctrl.items[idx]
								if item in ctrl.items_selected {
									ctrl.items_selected = ctrl.items_selected.filter(it != item)
								} else {
									ctrl.items_selected << item
								}
								if ctrl.on_change != unsafe { nil } {
									ctrl.on_change(mut win)
								}
							}
						} else if ctrl.kind == 'combobox' {
							hdr_h := f32(32.0)
							if win.mouse_y <= ctrl.y + hdr_h {
								ctrl.is_expanded = !ctrl.is_expanded
								ctrl.h = if ctrl.is_expanded {
									hdr_h + f32(math.min(150, ctrl.items.len * 26 + 8))
								} else {
									hdr_h
								}
							} else if ctrl.is_expanded {
								rel_y := win.mouse_y - (ctrl.y + hdr_h + 4.0)
								idx := int(rel_y / 26.0)
								if idx >= 0 && idx < ctrl.items.len {
									ctrl.text_value = ctrl.items[idx]
									ctrl.is_expanded = false
									ctrl.h = hdr_h
									if ctrl.on_change != unsafe { nil } {
										ctrl.on_change(mut win)
									}
								}
							}
						} else if ctrl.kind == 'color_palette' {
							mut px := ctrl.x + 6.0
							mut py := ctrl.y + 6.0
							swatch_s := f32(24.0)
							for item in ctrl.items {
								if win.mouse_x >= px && win.mouse_x <= px + swatch_s && win.mouse_y >= py && win.mouse_y <= py + swatch_s {
									ctrl.text_value = item
									if ctrl.on_change != unsafe { nil } {
										ctrl.on_change(mut win)
									}
									break
								}
								px += swatch_s + 6.0
								if px + swatch_s > ctrl.x + ctrl.w {
									px = ctrl.x + 6.0
									py += swatch_s + 6.0
								}
							}
						} else if ctrl.kind == 'step_slider' {
							rel_x := win.mouse_x - (ctrl.x + 15.0)
							track_w := math.max(f32(1.0), ctrl.w - 50.0)
							pct := math.max(f32(0.0), math.min(f32(1.0), rel_x / track_w))
							step_cnt := if ctrl.int_value > 0 { ctrl.int_value } else { 4 }
							snapped_step := math.round(f64(pct) * f64(step_cnt))
							ctrl.f64_value = math.max(0.0, math.min(100.0, snapped_step * (100.0 / f64(step_cnt))))
							if ctrl.on_change != unsafe { nil } {
								ctrl.on_change(mut win)
							}
						} else if ctrl.kind == 'transfer_list' {
							box_w := (ctrl.w - 60.0) / 2.0
							btn_x := ctrl.x + box_w + 10.0
							if win.mouse_x >= btn_x && win.mouse_x <= btn_x + 40.0 {
								rel_y := win.mouse_y - ctrl.y
								if rel_y >= 10.0 && rel_y <= 38.0 {
									if ctrl.items.len > 0 {
										item := ctrl.items[0]
										ctrl.items = ctrl.items.filter(it != item)
										ctrl.items_selected << item
										if ctrl.on_change != unsafe { nil } {
											ctrl.on_change(mut win)
										}
									}
								} else if rel_y >= 44.0 && rel_y <= 72.0 {
									if ctrl.items_selected.len > 0 {
										item := ctrl.items_selected[0]
										ctrl.items_selected = ctrl.items_selected.filter(it != item)
										ctrl.items << item
										if ctrl.on_change != unsafe { nil } {
											ctrl.on_change(mut win)
										}
									}
								} else if rel_y >= 78.0 && rel_y <= 106.0 {
									for item in ctrl.items {
										ctrl.items_selected << item
									}
									ctrl.items.clear()
									if ctrl.on_change != unsafe { nil } {
										ctrl.on_change(mut win)
									}
								}
							} else if win.mouse_x >= ctrl.x && win.mouse_x <= ctrl.x + box_w {
								rel_y := win.mouse_y - (ctrl.y + 24.0)
								idx := int(rel_y / 24.0)
								if idx >= 0 && idx < ctrl.items.len {
									item := ctrl.items[idx]
									ctrl.items = ctrl.items.filter(it != item)
									ctrl.items_selected << item
									if ctrl.on_change != unsafe { nil } {
										ctrl.on_change(mut win)
									}
								}
							} else if win.mouse_x >= ctrl.x + box_w + 60.0 && win.mouse_x <= ctrl.x + ctrl.w {
								rel_y := win.mouse_y - (ctrl.y + 24.0)
								idx := int(rel_y / 24.0)
								if idx >= 0 && idx < ctrl.items_selected.len {
									item := ctrl.items_selected[idx]
									ctrl.items_selected = ctrl.items_selected.filter(it != item)
									ctrl.items << item
									if ctrl.on_change != unsafe { nil } {
										ctrl.on_change(mut win)
									}
								}
							}
						} else if ctrl.kind == 'checklist' {
							rel_y := win.mouse_y - (ctrl.y + 6.0)
							idx := int(rel_y / 24.0)
							if idx >= 0 && idx < ctrl.items.len {
								item := ctrl.items[idx]
								if item in ctrl.items_selected {
									ctrl.items_selected = ctrl.items_selected.filter(it != item)
								} else {
									ctrl.items_selected << item
								}
								if ctrl.on_change != unsafe { nil } {
									ctrl.on_change(mut win)
								}
							}
						} else if ctrl.kind == 'chip_group' {
							mut cx := ctrl.x
							for item in ctrl.items {
								chip_w := f32(item.len * 7 + 20)
								if win.mouse_x >= cx && win.mouse_x <= cx + chip_w {
									if item in ctrl.items_selected {
										ctrl.items_selected = ctrl.items_selected.filter(it != item)
									} else {
										ctrl.items_selected << item
									}
									if ctrl.on_change != unsafe { nil } {
										ctrl.on_change(mut win)
									}
									break
								}
								cx += chip_w + 8.0
							}
						} else if ctrl.kind == 'menu_button' {
							hdr_h := f32(34.0)
							if win.mouse_y <= ctrl.y + hdr_h {
								ctrl.is_expanded = !ctrl.is_expanded
								ctrl.h = if ctrl.is_expanded {
									hdr_h + f32(ctrl.items.len) * 28.0
								} else {
									hdr_h
								}
							} else if ctrl.is_expanded {
								rel_y := win.mouse_y - (ctrl.y + hdr_h + 2.0)
								idx := int(rel_y / 28.0)
								if idx >= 0 && idx < ctrl.items.len {
									ctrl.text_value = ctrl.items[idx]
									ctrl.is_expanded = false
									ctrl.h = hdr_h
									if ctrl.on_change != unsafe { nil } {
										ctrl.on_change(mut win)
									}
								}
							}
						} else if ctrl.kind == 'super_terminal' {
							if win.mouse_y >= ctrl.y && win.mouse_y <= ctrl.y + 26.0 {
								// Clear button
								if win.mouse_x >= ctrl.x + ctrl.w - 64.0 && win.mouse_x <= ctrl.x + ctrl.w - 6.0 {
									ctrl.items_selected.clear()
									if ctrl.on_change != unsafe { nil } { ctrl.on_change(mut win) }
								} else {
									// Tab bar
									mut tab_x := ctrl.x + 8.0
									for idx, tab_name in ctrl.items {
										t_w := f32(tab_name.len * 7 + 18)
										if win.mouse_x >= tab_x && win.mouse_x <= tab_x + t_w {
											ctrl.int_value = idx
											if ctrl.on_change != unsafe { nil } { ctrl.on_change(mut win) }
											break
										}
										tab_x += t_w + 6.0
									}
								}
							}
						} else if ctrl.kind == 'code_studio' {
							// Copy button in header
							if win.mouse_y >= ctrl.y + 2.0 && win.mouse_y <= ctrl.y + 24.0 {
								if win.mouse_x >= ctrl.x + ctrl.w - 64.0 && win.mouse_x <= ctrl.x + ctrl.w - 8.0 {
									win.copy_to_clipboard(ctrl.text_value)
									win.show_toast('[COPIED]', '${ctrl.title} copied to clipboard')
								}
							}
						} else if ctrl.kind == 'smart_table' {
							hdr_top := ctrl.y + 32.0
							hdr_bot := hdr_top + 26.0
							footer_top := ctrl.y + ctrl.h - 26.0
							if win.mouse_y >= hdr_top && win.mouse_y <= hdr_bot && ctrl.headers.len > 0 {
								col_w := ctrl.w / f32(ctrl.headers.len)
								c_idx := int((win.mouse_x - ctrl.x) / col_w)
								if c_idx >= 0 && c_idx < ctrl.headers.len {
									if ctrl.sort_col == c_idx {
										ctrl.sort_asc = !ctrl.sort_asc
									} else {
										ctrl.sort_col = c_idx
										ctrl.sort_asc = true
									}
									sort_table_rows(ctrl, c_idx, ctrl.sort_asc)
									if ctrl.on_change != unsafe { nil } { ctrl.on_change(mut win) }
								}
							} else if win.mouse_y >= footer_top && win.mouse_y <= ctrl.y + ctrl.h {
								// Prev button
								if win.mouse_x >= ctrl.x + ctrl.w - 115.0 && win.mouse_x <= ctrl.x + ctrl.w - 65.0 {
									if ctrl.current_page > 1 {
										ctrl.current_page--
										if ctrl.on_change != unsafe { nil } { ctrl.on_change(mut win) }
									}
								} else if win.mouse_x >= ctrl.x + ctrl.w - 60.0 && win.mouse_x <= ctrl.x + ctrl.w - 10.0 {
									if ctrl.current_page < ctrl.total_pages {
										ctrl.current_page++
										if ctrl.on_change != unsafe { nil } { ctrl.on_change(mut win) }
									}
								}
							} else if win.mouse_y > hdr_bot && win.mouse_y < footer_top {
								page_size := 5
								start_idx := (ctrl.current_page - 1) * page_size
								rel_row := int((win.mouse_y - hdr_bot) / 26.0)
								target_row := start_idx + rel_row
								if target_row >= 0 && target_row < ctrl.rows.len {
									ctrl.selected_row = target_row
									if ctrl.on_row_click != unsafe { nil } { ctrl.on_row_click(mut win) }
									if ctrl.on_change != unsafe { nil } { ctrl.on_change(mut win) }
								}
							}
						} else if ctrl.kind == 'wizard_stepper' {
							if ctrl.items.len > 0 {
								step_w := ctrl.w / f32(ctrl.items.len)
								s_idx := int((win.mouse_x - ctrl.x) / step_w)
								if s_idx >= 0 && s_idx < ctrl.items.len {
									ctrl.int_value = s_idx
									if ctrl.on_change != unsafe { nil } { ctrl.on_change(mut win) }
								}
							}
						} else if ctrl.kind == 'floating_toolbar' {
							if ctrl.items.len > 0 {
								mut ax := ctrl.x + f32(ctrl.title.len * 7 + 24)
								for idx, act in ctrl.items {
									act_w := f32(act.len * 7 + 20)
									if win.mouse_x >= ax && win.mouse_x <= ax + act_w {
										ctrl.int_value = idx
										ctrl.text_value = act
										if ctrl.on_change != unsafe { nil } { ctrl.on_change(mut win) }
										break
									}
									ax += act_w + 8.0
								}
							}
						} else if ctrl.kind == 'chip_cloud' {
							mut cx := ctrl.x + 6.0
							for idx, tag in ctrl.tags {
								t_w := f32(tag.len * 7 + 24)
								if win.mouse_x >= cx + t_w - 16.0 && win.mouse_x <= cx + t_w && win.mouse_y >= ctrl.y + 4.0 && win.mouse_y <= ctrl.y + 28.0 {
									mut n_tags := []string{}
									for i, t in ctrl.tags {
										if i != idx { n_tags << t }
									}
									ctrl.tags = n_tags
									if ctrl.on_change != unsafe { nil } { ctrl.on_change(mut win) }
									break
								}
								cx += t_w + 8.0
							}
						} else if ctrl.kind == 'kanban_board' {
							if ctrl.items.len > 0 {
								col_w := (ctrl.w - f32(ctrl.items.len - 1) * 8.0) / f32(ctrl.items.len)
								c_idx := int((win.mouse_x - ctrl.x) / (col_w + 8.0))
								if c_idx >= 0 && c_idx < ctrl.items.len {
									ctrl.int_value = c_idx
									if ctrl.on_change != unsafe { nil } { ctrl.on_change(mut win) }
								}
							}
						} else if ctrl.kind == 'image' || ctrl.kind == 'image_box' || ctrl.kind == 'user_profile_card' || ctrl.kind == 'product_card' {
							// Handled on mouse_up
						} else if ctrl.kind == 'image_gallery' {
							pad := f32(8.0)
							main_h := f32(190.0)
							prev_btn_x := ctrl.x + pad + 8.0
							prev_btn_y := ctrl.y + pad + (main_h / 2.0) - 16.0
							next_btn_x := ctrl.x + ctrl.w - pad - 40.0
							next_btn_y := prev_btn_y

							if win.mouse_x >= prev_btn_x && win.mouse_x <= prev_btn_x + 32.0 && win.mouse_y >= prev_btn_y && win.mouse_y <= prev_btn_y + 32.0 {
								if ctrl.items.len > 0 {
									ctrl.int_value = (ctrl.int_value - 1 + ctrl.items.len) % ctrl.items.len
									if ctrl.on_change != unsafe { nil } { ctrl.on_change(mut win) }
								}
							} else if win.mouse_x >= next_btn_x && win.mouse_x <= next_btn_x + 32.0 && win.mouse_y >= next_btn_y && win.mouse_y <= next_btn_y + 32.0 {
								if ctrl.items.len > 0 {
									ctrl.int_value = (ctrl.int_value + 1) % ctrl.items.len
									if ctrl.on_change != unsafe { nil } { ctrl.on_change(mut win) }
								}
							} else {
								thumb_strip_y := ctrl.y + pad + main_h + 10.0
								thumb_w := f32(66.0)
								thumb_h := f32(50.0)
								if win.mouse_y >= thumb_strip_y && win.mouse_y <= thumb_strip_y + thumb_h {
									for t_i in 0 .. ctrl.items.len {
										tx := ctrl.x + pad + f32(t_i) * (thumb_w + 8.0)
										if win.mouse_x >= tx && win.mouse_x <= tx + thumb_w {
											ctrl.int_value = t_i
											if ctrl.on_change != unsafe { nil } { ctrl.on_change(mut win) }
											break
										}
									}
								}
							}
						} else if ctrl.kind == 'app_launcher_tile' {
							// Handled on mouse_up
						} else if ctrl.kind == 'media_player' {
							play_btn_x := ctrl.x + ctrl.w - 88.0
							play_btn_y := ctrl.y + 66.0
							if win.mouse_x >= play_btn_x && win.mouse_x <= play_btn_x + 74.0 && win.mouse_y >= play_btn_y && win.mouse_y <= play_btn_y + 24.0 {
								ctrl.bool_value = !ctrl.bool_value
								if ctrl.on_change != unsafe { nil } { ctrl.on_change(mut win) }
							} else {
								track_left := ctrl.x + 98.0
								bar_y := ctrl.y + 50.0
								bar_w := ctrl.w - 112.0
								if win.mouse_x >= track_left && win.mouse_x <= track_left + bar_w && win.mouse_y >= bar_y && win.mouse_y <= bar_y + 16.0 {
									rel_pct := math.max(0.0, math.min(1.0, f64((win.mouse_x - track_left) / bar_w)))
									tot_sec := if ctrl.int_value > 0 { ctrl.int_value } else { 180 }
									ctrl.min_val = f64(int(rel_pct * f64(tot_sec)))
									if ctrl.on_change != unsafe { nil } { ctrl.on_change(mut win) }
								}
							}
						} else if ctrl.kind == 'hero_banner' {
							// Handled on mouse_up
						}

					} else {
						ctrl.is_focused = false
					}
				}
			}

			win.focused_control = clicked_ctrl
			win.recalculate_layout()
		}
		.mouse_up {
			win.mouse_down = false
			if win.is_selecting_text {
				win.is_selecting_text = false
				if win.focused_control.len > 0 {
					if mut ctrl := win.get_control_ptr(win.focused_control) {
						if ctrl.sel_start == ctrl.sel_end {
							ctrl.clear_selection()
						}
					}
				}
			}
			for mut ctrl in win.controls {
				ctrl.is_dragging_min = false
				ctrl.is_dragging_max = false
				if ctrl.is_pressed {
					ctrl.is_pressed = false
					if win.mouse_x >= ctrl.x && win.mouse_x <= ctrl.x + ctrl.w
						&& win.mouse_y >= ctrl.y && win.mouse_y <= ctrl.y + ctrl.h {
						now := time.ticks()
						is_dbl := ctrl.last_click_time > 0 && (now - ctrl.last_click_time) <= 400
						ctrl.last_click_time = now

						if is_dbl && ctrl.kind in ['input', 'password', 'textarea', 'search_field', 'search_bar', 'file_picker', 'color_picker', 'pin_code', 'time_picker', 'tag_input', 'code_editor', 'code_studio'] {
							ctrl.select_all()
						}

						if ctrl.on_click != unsafe { nil } {
							ctrl.on_click(mut win)
						}
						if is_dbl && ctrl.on_dblclick != unsafe { nil } {
							ctrl.on_dblclick(mut win)
						}
					}
				}
			}
		}
		.char {
			is_super := (e.modifiers & u32(gg.Modifier.super)) != 0
			is_ctrl := (e.modifiers & u32(gg.Modifier.ctrl)) != 0
			if is_super || is_ctrl {
				return
			}
			if win.modal_active {
				if win.modal_input_mode && e.char_code > 32 && e.char_code <= 126 {
					ch := u8(e.char_code).ascii_str()
					if win.modal_input_caret < 0 || win.modal_input_caret > win.modal_input_val.len {
						win.modal_input_caret = win.modal_input_val.len
					}
					win.modal_input_val = win.modal_input_val[0..win.modal_input_caret] + ch +
						win.modal_input_val[win.modal_input_caret..]
					win.modal_input_caret++
				}
				return
			}
			if win.command_palette_active {
				if e.char_code >= 32 && e.char_code <= 126 {
					win.command_palette_query += u8(e.char_code).ascii_str()
				}
				return
			}
			if win.focused_control.len > 0 {
				if mut ctrl := win.get_control_ptr(win.focused_control) {
					if ctrl.kind in ['input', 'password', 'textarea', 'search_field', 'search_bar',
						'file_picker', 'color_picker', 'pin_code', 'time_picker', 'tag_input', 'code_editor', 'code_studio'] {
						if e.char_code >= 32 && e.char_code <= 126 {
							ch := u8(e.char_code).ascii_str()
							if ctrl.has_selection() {
								ctrl.delete_selected_text()
							} else {
								ctrl.save_undo_state()
							}
							if ctrl.caret_pos < 0 || ctrl.caret_pos > ctrl.text_value.len {
								ctrl.caret_pos = ctrl.text_value.len
							}
							ctrl.text_value = ctrl.text_value[0..ctrl.caret_pos] + ch +
								ctrl.text_value[ctrl.caret_pos..]
							ctrl.caret_pos++
							if ctrl.on_change != unsafe { nil } {
								ctrl.on_change(mut win)
							}
						}
					}
				}
			}
		}
		.key_down {
			is_super := (e.modifiers & u32(gg.Modifier.super)) != 0
			is_ctrl := (e.modifiers & u32(gg.Modifier.ctrl)) != 0
			is_alt := (e.modifiers & u32(gg.Modifier.alt)) != 0
			is_shift := (e.modifiers & u32(gg.Modifier.shift)) != 0

			if win.modal_active {
				if e.key_code == .escape {
					cb := win.modal_on_cancel
					win.hide_modal()
					if cb != unsafe { nil } {
						cb(mut win)
					}
					return
				} else if e.key_code == .enter {
					cb := win.modal_on_confirm
					win.hide_modal()
					if cb != unsafe { nil } {
						cb(mut win)
					}
					return
				}

				if win.modal_input_mode {
					if (is_ctrl || is_super) && e.key_code == .v {
						clip := win.get_clipboard_text()
						if clip.len > 0 {
							if win.modal_input_caret < 0 || win.modal_input_caret > win.modal_input_val.len {
								win.modal_input_caret = win.modal_input_val.len
							}
							win.modal_input_val = win.modal_input_val[0..win.modal_input_caret] + clip +
								win.modal_input_val[win.modal_input_caret..]
							win.modal_input_caret += clip.len
						}
						return
					} else if (is_ctrl || is_super) && e.key_code == .c {
						win.copy_to_clipboard(win.modal_input_val)
						return
					} else if (is_ctrl || is_super) && e.key_code == .x {
						win.copy_to_clipboard(win.modal_input_val)
						win.modal_input_val = ''
						win.modal_input_caret = 0
						return
					} else if (is_ctrl || is_super) && e.key_code == .a {
						win.modal_input_caret = win.modal_input_val.len
						return
					} else if e.key_code == .space {
						if win.modal_input_caret < 0 || win.modal_input_caret > win.modal_input_val.len {
							win.modal_input_caret = win.modal_input_val.len
						}
						win.modal_input_val = win.modal_input_val[0..win.modal_input_caret] + ' ' +
							win.modal_input_val[win.modal_input_caret..]
						win.modal_input_caret++
						return
					} else if e.key_code == .left {
						if win.modal_input_caret > 0 {
							win.modal_input_caret--
						}
						return
					} else if e.key_code == .right {
						if win.modal_input_caret < win.modal_input_val.len {
							win.modal_input_caret++
						}
						return
					} else if e.key_code == .home {
						win.modal_input_caret = 0
						return
					} else if e.key_code == .end {
						win.modal_input_caret = win.modal_input_val.len
						return
					} else if e.key_code == .backspace {
						if win.modal_input_val.len > 0 && win.modal_input_caret > 0 {
							if win.modal_input_caret > win.modal_input_val.len {
								win.modal_input_caret = win.modal_input_val.len
							}
							win.modal_input_val = win.modal_input_val[0..win.modal_input_caret - 1] +
								win.modal_input_val[win.modal_input_caret..]
							win.modal_input_caret--
						}
						return
					} else if e.key_code == .delete {
						if win.modal_input_caret < win.modal_input_val.len {
							win.modal_input_val = win.modal_input_val[0..win.modal_input_caret] +
								win.modal_input_val[win.modal_input_caret + 1..]
						}
						return
					}
				}
				return
			}

			if e.key_code == .escape {
				if win.command_palette_active {
					win.hide_command_palette()
					return
				}
				if win.context_menu_active {
					win.hide_context_menu()
					return
				}
				if win.fullscreen {
					win.set_fullscreen(false)
					return
				}
			}

			if (is_ctrl || is_super) && e.key_code == .k {
				win.command_palette_active = !win.command_palette_active
				return
			}

			if win.command_palette_active {
				if e.key_code == .escape {
					win.hide_command_palette()
				} else if e.key_code == .up {
					if win.command_palette_sel > 0 { win.command_palette_sel-- }
				} else if e.key_code == .down {
					if win.command_palette_sel < win.command_palette_items.len - 1 { win.command_palette_sel++ }
				} else if e.key_code == .enter {
					if win.command_palette_sel >= 0 && win.command_palette_sel < win.command_palette_items.len {
						item := win.command_palette_items[win.command_palette_sel]
						win.hide_command_palette()
						if item.on_execute != unsafe { nil } {
							item.on_execute(mut win)
						}
					}
				} else if e.key_code == .backspace {
					if win.command_palette_query.len > 0 {
						win.command_palette_query = win.command_palette_query[0..win.command_palette_query.len - 1]
					}
				}
				return
			}

			if win.close_shortcut_enabled {
				if ((is_super || is_ctrl) && e.key_code == .q) || (is_alt && e.key_code == .f4) {
					mut should_close := true
					if win.on_close_cb != unsafe { nil } {
						should_close = win.on_close_cb(mut win)
					}
					if should_close {
						win.close()
						return
					}
				}
			}

			if win.on_key_down_cb != unsafe { nil } {
				win.on_key_down_cb(mut win, e.key_code)
			}

			if win.focused_control.len > 0 {
				if mut ctrl := win.get_control_ptr(win.focused_control) {
					if (is_ctrl || is_super) && e.key_code == .a {
						if ctrl.kind in ['input', 'password', 'textarea', 'search_field',
							'search_bar', 'file_picker', 'color_picker', 'pin_code', 'time_picker', 'tag_input', 'code_editor', 'code_studio'] {
							ctrl.select_all()
							return
						}
					} else if (is_ctrl || is_super) && e.key_code == .c {
						if ctrl.kind in ['input', 'password', 'textarea', 'search_field',
							'search_bar', 'file_picker', 'color_picker', 'pin_code', 'time_picker', 'tag_input', 'code_editor', 'code_studio'] {
							if ctrl.has_selection() {
								win.copy_to_clipboard(ctrl.selected_text())
							}
							return
						}
					} else if (is_ctrl || is_super) && e.key_code == .x {
						if ctrl.kind in ['input', 'password', 'textarea', 'search_field',
							'search_bar', 'file_picker', 'color_picker', 'pin_code', 'time_picker', 'tag_input', 'code_editor', 'code_studio'] {
							if ctrl.has_selection() {
								win.copy_to_clipboard(ctrl.selected_text())
								ctrl.delete_selected_text()
								if ctrl.on_change != unsafe { nil } {
									ctrl.on_change(mut win)
								}
							}
							return
						}
					} else if (is_ctrl || is_super) && e.key_code == .v {
						if ctrl.kind in ['input', 'password', 'textarea', 'search_field',
							'search_bar', 'file_picker', 'color_picker', 'pin_code', 'time_picker', 'tag_input', 'code_editor', 'code_studio'] {
							clip_txt := win.get_clipboard_text()
							if clip_txt.len > 0 {
								if ctrl.has_selection() {
									ctrl.delete_selected_text()
								} else {
									ctrl.save_undo_state()
								}
								if ctrl.caret_pos < 0 || ctrl.caret_pos > ctrl.text_value.len {
									ctrl.caret_pos = ctrl.text_value.len
								}
								ctrl.text_value = ctrl.text_value[0..ctrl.caret_pos] + clip_txt +
									ctrl.text_value[ctrl.caret_pos..]
								ctrl.caret_pos += clip_txt.len
								if ctrl.on_change != unsafe { nil } {
									ctrl.on_change(mut win)
								}
							}
							return
						}
					} else if (is_ctrl || is_super) && e.key_code == .z {
						if ctrl.kind in ['input', 'password', 'textarea', 'search_field',
							'search_bar', 'file_picker', 'color_picker', 'pin_code', 'time_picker', 'tag_input', 'code_editor', 'code_studio'] {
							if is_shift {
								if ctrl.redo() {
									if ctrl.on_change != unsafe { nil } {
										ctrl.on_change(mut win)
									}
								}
							} else {
								if ctrl.undo() {
									if ctrl.on_change != unsafe { nil } {
										ctrl.on_change(mut win)
									}
								}
							}
							return
						}
					} else if (is_ctrl || is_super) && e.key_code == .y {
						if ctrl.kind in ['input', 'password', 'textarea', 'search_field',
							'search_bar', 'file_picker', 'color_picker', 'pin_code', 'time_picker', 'tag_input', 'code_editor', 'code_studio'] {
							if ctrl.redo() {
								if ctrl.on_change != unsafe { nil } {
									ctrl.on_change(mut win)
								}
							}
							return
						}
					}

					if e.key_code == .space {
						if ctrl.kind in ['input', 'password', 'textarea', 'search_field',
							'search_bar', 'file_picker', 'pin_code', 'time_picker', 'tag_input', 'code_editor', 'code_studio'] {
							if ctrl.has_selection() {
								ctrl.delete_selected_text()
							} else {
								ctrl.save_undo_state()
							}
							if ctrl.caret_pos < 0 || ctrl.caret_pos > ctrl.text_value.len {
								ctrl.caret_pos = ctrl.text_value.len
							}
							ctrl.text_value = ctrl.text_value[0..ctrl.caret_pos] + ' ' +
								ctrl.text_value[ctrl.caret_pos..]
							ctrl.caret_pos++
							if ctrl.on_change != unsafe { nil } {
								ctrl.on_change(mut win)
							}
						}
					} else if e.key_code == .enter {
						if ctrl.kind == 'tag_input' && ctrl.text_value.trim_space().len > 0 {
							ctrl.tags << ctrl.text_value.trim_space()
							ctrl.text_value = ''
							if ctrl.on_change != unsafe { nil } {
								ctrl.on_change(mut win)
							}
						} else if ctrl.kind in ['textarea', 'code_editor', 'code_studio'] {
							if ctrl.has_selection() {
								ctrl.delete_selected_text()
							} else {
								ctrl.save_undo_state()
							}
							if ctrl.caret_pos < 0 || ctrl.caret_pos > ctrl.text_value.len {
								ctrl.caret_pos = ctrl.text_value.len
							}
							ctrl.text_value = ctrl.text_value[0..ctrl.caret_pos] + '\n' +
								ctrl.text_value[ctrl.caret_pos..]
							ctrl.caret_pos++
							if ctrl.on_change != unsafe { nil } {
								ctrl.on_change(mut win)
							}
						}
						if ctrl.on_enter != unsafe { nil } {
							ctrl.on_enter(mut win)
						}
						if win.on_submit_cb != unsafe { nil } {
							win.on_submit_cb(mut win)
						}
					} else if e.key_code == .backspace {
						if ctrl.has_selection() {
							ctrl.delete_selected_text()
							if ctrl.on_change != unsafe { nil } {
								ctrl.on_change(mut win)
							}
						} else if ctrl.text_value.len > 0 && ctrl.caret_pos > 0 {
							ctrl.save_undo_state()
							ctrl.text_value = ctrl.text_value[0..ctrl.caret_pos - 1] +
								ctrl.text_value[ctrl.caret_pos..]
							ctrl.caret_pos--
							if ctrl.on_change != unsafe { nil } {
								ctrl.on_change(mut win)
							}
						}
					} else if e.key_code == .delete {
						if ctrl.has_selection() {
							ctrl.delete_selected_text()
							if ctrl.on_change != unsafe { nil } {
								ctrl.on_change(mut win)
							}
						} else if ctrl.caret_pos < ctrl.text_value.len {
							ctrl.save_undo_state()
							ctrl.text_value = ctrl.text_value[0..ctrl.caret_pos] +
								ctrl.text_value[ctrl.caret_pos + 1..]
							if ctrl.on_change != unsafe { nil } {
								ctrl.on_change(mut win)
							}
						}
					} else if e.key_code == .left {
						if is_shift {
							if !ctrl.has_selection() {
								ctrl.sel_start = ctrl.caret_pos
							}
							if ctrl.caret_pos > 0 {
								ctrl.caret_pos--
							}
							ctrl.sel_end = ctrl.caret_pos
						} else {
							if ctrl.has_selection() {
								s, _ := ctrl.selection_range()
								ctrl.caret_pos = s
								ctrl.clear_selection()
							} else if ctrl.caret_pos > 0 {
								ctrl.caret_pos--
							}
						}
					} else if e.key_code == .right {
						if is_shift {
							if !ctrl.has_selection() {
								ctrl.sel_start = ctrl.caret_pos
							}
							if ctrl.caret_pos < ctrl.text_value.len {
								ctrl.caret_pos++
							}
							ctrl.sel_end = ctrl.caret_pos
						} else {
							if ctrl.has_selection() {
								_, end_pos := ctrl.selection_range()
								ctrl.caret_pos = end_pos
								ctrl.clear_selection()
							} else if ctrl.caret_pos < ctrl.text_value.len {
								ctrl.caret_pos++
							}
						}
					} else if e.key_code == .home {
						mut target_pos := 0
						if ctrl.kind in ['textarea', 'code_editor', 'code_studio'] && !is_ctrl && !is_super {
							lines := ctrl.text_value.split('\n')
							mut line_start_idx := 0
							for i, line in lines {
								line_end_idx := line_start_idx + line.len
								if ctrl.caret_pos >= line_start_idx && (ctrl.caret_pos <= line_end_idx || i == lines.len - 1) {
									target_pos = line_start_idx
									break
								}
								line_start_idx += line.len + 1
							}
						}
						if is_shift {
							if !ctrl.has_selection() {
								ctrl.sel_start = ctrl.caret_pos
							}
							ctrl.caret_pos = target_pos
							ctrl.sel_end = target_pos
						} else {
							ctrl.caret_pos = target_pos
							ctrl.clear_selection()
						}
					} else if e.key_code == .end {
						mut target_pos := ctrl.text_value.len
						if ctrl.kind in ['textarea', 'code_editor', 'code_studio'] && !is_ctrl && !is_super {
							lines := ctrl.text_value.split('\n')
							mut line_start_idx := 0
							for i, line in lines {
								line_end_idx := line_start_idx + line.len
								if ctrl.caret_pos >= line_start_idx && (ctrl.caret_pos <= line_end_idx || i == lines.len - 1) {
									target_pos = line_end_idx
									break
								}
								line_start_idx += line.len + 1
							}
						}
						if is_shift {
							if !ctrl.has_selection() {
								ctrl.sel_start = ctrl.caret_pos
							}
							ctrl.caret_pos = target_pos
							ctrl.sel_end = target_pos
						} else {
							ctrl.caret_pos = target_pos
							ctrl.clear_selection()
						}
					} else if e.key_code == .up {
						if ctrl.kind == 'number' {
							ctrl.int_value++
							if ctrl.on_change != unsafe { nil } {
								ctrl.on_change(mut win)
							}
						} else if ctrl.kind in ['textarea', 'code_editor', 'code_studio'] {
							lines := ctrl.text_value.split('\n')
							mut curr_line := 0
							mut curr_col := 0
							mut line_start_idx := 0
							for i, line in lines {
								line_end_idx := line_start_idx + line.len
								if ctrl.caret_pos >= line_start_idx && (ctrl.caret_pos <= line_end_idx || i == lines.len - 1) {
									curr_line = i
									curr_col = ctrl.caret_pos - line_start_idx
									break
								}
								line_start_idx += line.len + 1
							}
							if curr_line > 0 {
								target_line := curr_line - 1
								mut target_line_start := 0
								for i in 0 .. target_line {
									target_line_start += lines[i].len + 1
								}
								target_col := math.min(lines[target_line].len, curr_col)
								new_caret := target_line_start + target_col
								if is_shift {
									if !ctrl.has_selection() {
										ctrl.sel_start = ctrl.caret_pos
									}
									ctrl.caret_pos = new_caret
									ctrl.sel_end = new_caret
								} else {
									ctrl.caret_pos = new_caret
									ctrl.clear_selection()
								}
							}
						}
					} else if e.key_code == .down {
						if ctrl.kind == 'number' {
							ctrl.int_value--
							if ctrl.on_change != unsafe { nil } {
								ctrl.on_change(mut win)
							}
						} else if ctrl.kind in ['textarea', 'code_editor', 'code_studio'] {
							lines := ctrl.text_value.split('\n')
							mut curr_line := 0
							mut curr_col := 0
							mut line_start_idx := 0
							for i, line in lines {
								line_end_idx := line_start_idx + line.len
								if ctrl.caret_pos >= line_start_idx && (ctrl.caret_pos <= line_end_idx || i == lines.len - 1) {
									curr_line = i
									curr_col = ctrl.caret_pos - line_start_idx
									break
								}
								line_start_idx += line.len + 1
							}
							if curr_line < lines.len - 1 {
								target_line := curr_line + 1
								mut target_line_start := 0
								for i in 0 .. target_line {
									target_line_start += lines[i].len + 1
								}
								target_col := math.min(lines[target_line].len, curr_col)
								new_caret := target_line_start + target_col
								if is_shift {
									if !ctrl.has_selection() {
										ctrl.sel_start = ctrl.caret_pos
									}
									ctrl.caret_pos = new_caret
									ctrl.sel_end = new_caret
								} else {
									ctrl.caret_pos = new_caret
									ctrl.clear_selection()
								}
							}
						}
					}
				}
			}
		}
		.resized {
			win.width = e.window_width
			win.height = e.window_height
			win.recalculate_layout()
			if win.on_resize_cb != unsafe { nil } {
				win.on_resize_cb(mut win, win.width, win.height)
			}
		}
		.mouse_scroll {
			if win.hovered_control.len > 0 {
				if mut ctrl := win.get_control_ptr(win.hovered_control) {
					if ctrl.kind in ['table', 'grid'] {
						header_h := table_header_height(ctrl)
						body_h := ctrl.h - header_h
						content_h := table_content_height(ctrl)
						max_scroll := math.max(f32(0.0), content_h - body_h)
						ctrl.scroll_offset_y -= e.scroll_y * 20.0
						ctrl.scroll_offset_y = math.max(f32(0.0), math.min(max_scroll,
							ctrl.scroll_offset_y))
					}
				}
			}
		}
		.files_dropped {
			num_files := sapp.get_num_dropped_files()
			mut dropped_paths := []string{}
			for i in 0 .. num_files {
				dropped_paths << sapp.get_dropped_file_path(i)
			}
			if dropped_paths.len > 0 {
				for mut ctrl in win.controls {
					if ctrl.visible && !ctrl.disabled && ctrl.kind == 'drop_zone' {
						for path in dropped_paths {
							if path !in ctrl.items {
								ctrl.items << path
							}
						}
						ctrl.text_value = dropped_paths.join(', ')
						if ctrl.on_change != unsafe { nil } {
							ctrl.on_change(mut win)
						}
						win.push_toast('Files Dropped', '${dropped_paths.len} file(s) added to drop zone.', 'success', 3000)
					}
				}
			}
		}
		else {}
	}
}

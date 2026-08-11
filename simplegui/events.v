module simplegui

import gg
import math
import sokol.sapp
import time

pub fn (mut win SimpleWindow) handle_event(e &gg.Event) {
	match e.typ {
		.mouse_move {
			win.mouse_x = e.mouse_x
			win.mouse_y = e.mouse_y

			mut new_hover := ''
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
				}
			}
			win.hovered_control = new_hover
		}
		.mouse_down {
			win.mouse_down = true
			win.mouse_x = e.mouse_x
			win.mouse_y = e.mouse_y

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
							'search_bar', 'file_picker', 'pin_code', 'time_picker', 'tag_input', 'code_editor'] {
							left_pad := if ctrl.kind == 'search_bar' { f32(32.0) } else { f32(10.0) }
							rel_x := win.mouse_x - (ctrl.x + left_pad)
							mut best_idx := 0
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
							ctrl.caret_pos = best_idx
						}

						if ctrl.kind in ['checkbox', 'toggle', 'switch'] {
							ctrl.bool_value = !ctrl.bool_value
							if ctrl.on_change != unsafe { nil } {
								ctrl.on_change(mut win)
							}
						} else if ctrl.kind == 'slider' {
							rel_x := win.mouse_x - ctrl.x
							pct := rel_x / ctrl.w
							ctrl.int_value = int(pct * 100.0)
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
			if win.command_palette_active {
				if e.char_code >= 32 && e.char_code <= 126 {
					win.command_palette_query += u8(e.char_code).ascii_str()
				}
				return
			}
			if win.focused_control.len > 0 {
				if mut ctrl := win.get_control_ptr(win.focused_control) {
					if ctrl.kind in ['input', 'password', 'textarea', 'search_field', 'search_bar',
						'file_picker', 'pin_code', 'time_picker', 'tag_input', 'code_editor'] {
						if e.char_code >= 32 && e.char_code <= 126 {
							ch := u8(e.char_code).ascii_str()
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
					if e.key_code == .space {
						if ctrl.kind in ['input', 'password', 'textarea', 'search_field',
							'search_bar', 'file_picker', 'pin_code', 'time_picker', 'tag_input', 'code_editor'] {
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
						} else if ctrl.kind == 'code_editor' {
							ctrl.text_value += '\n'
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
						if ctrl.text_value.len > 0 && ctrl.caret_pos > 0 {
							ctrl.text_value = ctrl.text_value[0..ctrl.caret_pos - 1] +
								ctrl.text_value[ctrl.caret_pos..]
							ctrl.caret_pos--
							if ctrl.on_change != unsafe { nil } {
								ctrl.on_change(mut win)
							}
						}
					} else if e.key_code == .delete {
						if ctrl.caret_pos < ctrl.text_value.len {
							ctrl.text_value = ctrl.text_value[0..ctrl.caret_pos] +
								ctrl.text_value[ctrl.caret_pos + 1..]
							if ctrl.on_change != unsafe { nil } {
								ctrl.on_change(mut win)
							}
						}
					} else if e.key_code == .left {
						if ctrl.caret_pos > 0 {
							ctrl.caret_pos--
						}
					} else if e.key_code == .right {
						if ctrl.caret_pos < ctrl.text_value.len {
							ctrl.caret_pos++
						}
					} else if e.key_code == .home {
						ctrl.caret_pos = 0
					} else if e.key_code == .end {
						ctrl.caret_pos = ctrl.text_value.len
					} else if e.key_code == .up {
						if ctrl.kind == 'number' {
							ctrl.int_value++
							if ctrl.on_change != unsafe { nil } {
								ctrl.on_change(mut win)
							}
						}
					} else if e.key_code == .down {
						if ctrl.kind == 'number' {
							ctrl.int_value--
							if ctrl.on_change != unsafe { nil } {
								ctrl.on_change(mut win)
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

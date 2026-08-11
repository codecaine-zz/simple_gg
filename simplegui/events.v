module simplegui

import gg
import math

pub fn (mut win SimpleWindow) handle_event(e &gg.Event) {
	match e.typ {
		.mouse_move {
			win.mouse_x = e.mouse_x
			win.mouse_y = e.mouse_y

			mut new_hover := ''
			for mut ctrl in win.controls {
				if ctrl.visible && !ctrl.disabled {
					if win.mouse_x >= ctrl.x && win.mouse_x <= ctrl.x + ctrl.w
						&& win.mouse_y >= ctrl.y && win.mouse_y <= ctrl.y + ctrl.h {
						ctrl.is_hovered = true
						new_hover = ctrl.name
					} else {
						ctrl.is_hovered = false
					}
				}
			}
			win.hovered_control = new_hover
		}
		.mouse_down {
			win.mouse_down = true
			win.mouse_x = e.mouse_x
			win.mouse_y = e.mouse_y

			mut clicked_ctrl := ''
			for mut ctrl in win.controls {
				if ctrl.visible && !ctrl.disabled {
					if win.mouse_x >= ctrl.x && win.mouse_x <= ctrl.x + ctrl.w
						&& win.mouse_y >= ctrl.y && win.mouse_y <= ctrl.y + ctrl.h {
						ctrl.is_pressed = true
						ctrl.is_focused = true
						clicked_ctrl = ctrl.name

						if ctrl.kind in ['input', 'password', 'textarea', 'search_field',
							'search_bar', 'file_picker', 'pin_code', 'time_picker'] {
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
							if ctrl.rows.len > 0 {
								header_h := f32(28.0)
								if win.mouse_y >= ctrl.y + header_h {
									rel_y := win.mouse_y - (ctrl.y + header_h)
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
				if ctrl.is_pressed {
					ctrl.is_pressed = false
					if win.mouse_x >= ctrl.x && win.mouse_x <= ctrl.x + ctrl.w
						&& win.mouse_y >= ctrl.y && win.mouse_y <= ctrl.y + ctrl.h {
						if ctrl.on_click != unsafe { nil } {
							ctrl.on_click(mut win)
						}
					}
				}
			}
		}
		.char {
			if win.focused_control.len > 0 {
				if mut ctrl := win.get_control_ptr(win.focused_control) {
					if ctrl.kind in ['input', 'password', 'textarea', 'search_field', 'search_bar',
						'file_picker', 'pin_code', 'time_picker'] {
						if e.char_code > 32 && e.char_code <= 126 {
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
							'search_bar', 'file_picker', 'pin_code', 'time_picker'] {
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
					} else if e.key_code == .enter {
						if ctrl.on_enter != unsafe { nil } {
							ctrl.on_enter(mut win)
						}
						if win.on_submit_cb != unsafe { nil } {
							win.on_submit_cb(mut win)
						}
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
		else {}
	}
}

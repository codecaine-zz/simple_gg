module simplegui

import math

pub fn (mut win SimpleWindow) recalculate_layout() {
	if win.controls.len == 0 {
		return
	}

	win_w := f32(win.width)
	win_h := f32(win.height)
	pad := f32(win.padding)
	sp := f32(win.spacing)
	content_w := win_w - pad * 2.0

	mut cur_y := pad
	mut i := 0

	for i < win.controls.len {
		mut ctrl := win.controls[i]
		if !ctrl.visible {
			i++
			continue
		}

		// Handle layout by container kind or linear sequence
		match ctrl.kind {
			'row_start' {
				// Find controls in this row until 'row_end'
				mut row_controls := []&Control{}
				i++
				for i < win.controls.len && win.controls[i].kind != 'row_end' {
					if win.controls[i].visible {
						row_controls << win.controls[i]
					}
					i++
				}

				if row_controls.len > 0 {
					row_count := f32(row_controls.len)
					avail_w := content_w - (row_count - 1.0) * sp
					item_w := avail_w / row_count
					mut max_h := f32(0.0)

					mut cur_x := pad
					for mut r_ctrl in row_controls {
						r_ctrl.x = cur_x
						r_ctrl.y = cur_y
						if r_ctrl.expand_fill || r_ctrl.w <= 0 {
							r_ctrl.w = item_w
						}
						if r_ctrl.h > max_h {
							max_h = r_ctrl.h
						}
						cur_x += r_ctrl.w + sp
					}
					cur_y += max_h + sp
				}
			}
			'grid_start' {
				cols := if ctrl.int_value > 0 { ctrl.int_value } else { 2 }
				grid_sp := if ctrl.f64_value > 0 { f32(ctrl.f64_value) } else { sp }

				mut grid_controls := []&Control{}
				i++
				for i < win.controls.len && win.controls[i].kind != 'grid_end' {
					if win.controls[i].visible {
						grid_controls << win.controls[i]
					}
					i++
				}

				if grid_controls.len > 0 {
					f_cols := f32(cols)
					col_w := (content_w - (f_cols - 1.0) * grid_sp) / f_cols
					mut row_max_h := f32(0.0)

					for idx, mut g_ctrl in grid_controls {
						col_idx := idx % cols
						if col_idx == 0 && idx > 0 {
							cur_y += row_max_h + grid_sp
							row_max_h = 0.0
						}

						g_ctrl.x = pad + f32(col_idx) * (col_w + grid_sp)
						g_ctrl.y = cur_y
						g_ctrl.w = col_w
						if g_ctrl.h > row_max_h {
							row_max_h = g_ctrl.h
						}
					}
					cur_y += row_max_h + sp
				}
			}
			'flex_start' {
				mut flex_controls := []&Control{}
				i++
				for i < win.controls.len && win.controls[i].kind != 'flex_end' {
					if win.controls[i].visible {
						flex_controls << win.controls[i]
					}
					i++
				}

				if flex_controls.len > 0 {
					count := f32(flex_controls.len)
					avail_w := content_w - (count - 1.0) * sp
					item_w := avail_w / count
					mut max_h := f32(0.0)

					mut cur_x := pad
					for mut f_ctrl in flex_controls {
						f_ctrl.x = cur_x
						f_ctrl.y = cur_y
						f_ctrl.w = item_w
						if f_ctrl.h > max_h {
							max_h = f_ctrl.h
						}
						cur_x += item_w + sp
					}
					cur_y += max_h + sp
				}
			}
			'group_start' {
				// Group box header and enclosing frame
				group_title := ctrl.title
				has_title := group_title.len > 0
				header_h := if has_title { f32(24.0) } else { f32(10.0) }

				ctrl.x = pad
				ctrl.y = cur_y
				ctrl.w = content_w

				group_start_y := cur_y + header_h + 8.0
				mut inner_y := group_start_y

				i++
				for i < win.controls.len && win.controls[i].kind != 'group_end' {
					if win.controls[i].visible {
						mut child := win.controls[i]
						child.x = pad + 12.0
						child.y = inner_y
						child.w = content_w - 24.0
						inner_y += child.h + sp
					}
					i++
				}

				group_height := (inner_y - cur_y) + 8.0
				ctrl.h = group_height
				cur_y += group_height + sp
			}
			'tab_container_start' {
				ctrl.x = pad
				ctrl.y = cur_y
				ctrl.w = content_w
				ctrl.h = 32.0

				active_tab := ctrl.int_value
				cur_y += 36.0

				mut inner_idx := i + 1
				mut in_active := false
				for inner_idx < win.controls.len && win.controls[inner_idx].kind != 'tab_container_end' {
					mut c_ctrl := win.controls[inner_idx]
					if c_ctrl.kind == 'tab_page_start' {
						in_active = (c_ctrl.int_value == active_tab)
						c_ctrl.visible = false
					} else if c_ctrl.kind == 'tab_page_end' {
						in_active = false
						c_ctrl.visible = false
					} else {
						c_ctrl.visible = in_active
					}
					inner_idx++
				}
			}
			'split_start' {
				split_pct := if ctrl.int_value > 0 { f32(ctrl.int_value) / 100.0 } else { f32(0.5) }
				left_w := (content_w - sp) * split_pct
				right_w := (content_w - sp) * (1.0 - split_pct)

				ctrl.x = pad
				ctrl.y = cur_y
				ctrl.w = content_w

				mut split_children := []&Control{}
				i++
				for i < win.controls.len && win.controls[i].kind != 'split_end' {
					if win.controls[i].visible {
						split_children << win.controls[i]
					}
					i++
				}

				if split_children.len >= 2 {
					split_children[0].x = pad
					split_children[0].y = cur_y
					split_children[0].w = left_w

					split_children[1].x = pad + left_w + sp
					split_children[1].y = cur_y
					split_children[1].w = right_w

					max_h := math.max(split_children[0].h, split_children[1].h)
					cur_y += max_h + sp
				}
			}
			'row_end', 'grid_end', 'flex_end', 'group_end', 'tab_container_end', 'tab_page_start', 'tab_page_end', 'split_end' {
				// Ignore loose end markers
			}
			'spacer' {
				spacer_h := if ctrl.h > 0 { ctrl.h } else { f32(20.0) }
				ctrl.x = pad
				ctrl.y = cur_y
				ctrl.w = content_w
				ctrl.h = spacer_h
				cur_y += spacer_h + sp
			}
			'separator' {
				ctrl.x = pad
				ctrl.y = cur_y
				ctrl.w = content_w
				ctrl.h = 2.0
				cur_y += 2.0 + sp
			}
			else {
				// Standard widget layout with margin adjustments
				ctrl.x = pad + ctrl.margin_left
				ctrl.y = cur_y + ctrl.margin_top

				avail_w := content_w - ctrl.margin_left - ctrl.margin_right
				if ctrl.expand_fill || ctrl.w <= 0 {
					ctrl.w = f32(math.max(10.0, avail_w))
				} else if ctrl.alignment == 'center' {
					ctrl.x = pad + ctrl.margin_left + (avail_w - ctrl.w) / 2.0
				} else if ctrl.alignment == 'right' {
					ctrl.x = pad + content_w - ctrl.margin_right - ctrl.w
				}

				cur_y += ctrl.margin_top + ctrl.h + ctrl.margin_bottom + sp
			}
		}
		i++
	}

	_ = win_h
}

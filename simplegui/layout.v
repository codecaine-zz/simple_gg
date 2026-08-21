// Module simplegui - Core UI Framework for V
// File: layout.v
//
// Description:
//   This file implements the automatic layout calculation engine for SimpleGUI.
//   It calculates exact screen coordinates (x, y) and bounding box sizes (w, h)
//   for every visible control on screen.
//
//   Layout Features:
//     - Linear vertical stacking (default)
//     - Multi-column Rows (`row_start` ... `row_end`)
//     - Equal-width Grid layouts (`grid_start` ... `grid_end`)
//     - Flex layouts (`flex_start` ... `flex_end`)
//     - Group Boxes (`group_start` ... `group_end`)
//     - Tab Containers (`tab_container_start` ... `tab_page_start` ... `tab_container_end`)
//     - Splitters (`split_start` ... `split_end`)
//     - Spacers & Horizontal Separators
//     - Alignment ('left', 'center', 'right') & Expand/Fill auto-resizing

module simplegui

import math

// recalculate_layout iterates through all controls registered in the window and computes
// their absolute X/Y screen positions and widths/heights based on window dimensions and containers.
pub fn (mut win SimpleWindow) recalculate_layout() {
	if win.controls.len == 0 {
		return
	}

	win_w := f32(win.width)
	win_h := f32(win.height)
	pad := f32(win.padding)  // Edge padding around window canvas
	sp := f32(win.spacing)   // Vertical gap spacing between controls
	content_w := win_w - pad * 2.0 // Available horizontal content width inside window edge padding

	mut cur_y := pad // Vertical tracking cursor (starts below top window padding)
	mut i := 0

	for i < win.controls.len {
		// Skip hidden/invisible controls during layout positioning
		if !win.controls[i].visible {
			i++
			continue
		}

		kind := win.controls[i].kind

		// Calculate positioning based on control kind or container wrapper
		match kind {
			'row_start' {
				mut row_indices := []int{}
				i++
				for i < win.controls.len && win.controls[i].kind != 'row_end' {
					if win.controls[i].visible {
						row_indices << i
					}
					i++
				}

				if row_indices.len > 0 {
					mut fixed_w := f32(0.0)
					mut auto_count := 0
					for idx in row_indices {
						r_w := win.controls[idx].w
						if !win.controls[idx].expand_fill && r_w > 0 && r_w < content_w * 0.75 {
							fixed_w += r_w
						} else {
							auto_count++
						}
					}
					gaps_w := (f32(row_indices.len) - 1.0) * sp
					remaining_w := f32(math.max(10.0, content_w - fixed_w - gaps_w))
					item_w := if auto_count > 0 { remaining_w / f32(auto_count) } else { remaining_w }
					mut max_h := f32(0.0)

					mut cur_x := pad
					for idx in row_indices {
						win.controls[idx].x = cur_x
						win.controls[idx].y = cur_y
						if win.controls[idx].expand_fill || win.controls[idx].w <= 0 || win.controls[idx].w >= content_w * 0.75 {
							win.controls[idx].w = item_w
						}
						if win.controls[idx].h > max_h {
							max_h = win.controls[idx].h
						}
						cur_x += win.controls[idx].w + sp
					}
					cur_y += max_h + sp
				}
			}
			'grid_start' {
				cols := if win.controls[i].int_value > 0 { win.controls[i].int_value } else { 2 }
				grid_sp := if win.controls[i].min_val > 0 { f32(win.controls[i].min_val) } else { sp }

				mut grid_indices := []int{}
				i++
				for i < win.controls.len && win.controls[i].kind != 'grid_end' {
					if win.controls[i].visible {
						grid_indices << i
					}
					i++
				}

				if grid_indices.len > 0 {
					f_cols := f32(cols)
					col_w := (content_w - (f_cols - 1.0) * grid_sp) / f_cols
					mut row_max_h := f32(0.0)

					for c_i, idx in grid_indices {
						col_idx := c_i % cols
						if col_idx == 0 && c_i > 0 {
							cur_y += row_max_h + grid_sp
							row_max_h = 0.0
						}

						win.controls[idx].x = pad + f32(col_idx) * (col_w + grid_sp)
						win.controls[idx].y = cur_y
						win.controls[idx].w = col_w
						if win.controls[idx].h > row_max_h {
							row_max_h = win.controls[idx].h
						}
					}
					cur_y += row_max_h + sp
				}
			}
			'flex_start' {
				mut flex_indices := []int{}
				i++
				for i < win.controls.len && win.controls[i].kind != 'flex_end' {
					if win.controls[i].visible {
						flex_indices << i
					}
					i++
				}

				if flex_indices.len > 0 {
					count := f32(flex_indices.len)
					avail_w := content_w - (count - 1.0) * sp
					item_w := avail_w / count
					mut max_h := f32(0.0)

					mut cur_x := pad
					for idx in flex_indices {
						win.controls[idx].x = cur_x
						win.controls[idx].y = cur_y
						if win.controls[idx].expand_fill || win.controls[idx].w <= 0 {
							win.controls[idx].w = item_w
						}
						if win.controls[idx].h > max_h {
							max_h = win.controls[idx].h
						}
						cur_x += win.controls[idx].w + sp
					}
					cur_y += max_h + sp
				}
			}
			'group_start' {
				win.controls[i].x = pad
				win.controls[i].y = cur_y
				win.controls[i].w = content_w

				group_inner_pad := f32(12.0)
				mut inner_y := cur_y + 28.0
				group_start_idx := i
				i++

				for i < win.controls.len && win.controls[i].kind != 'group_end' {
					if win.controls[i].visible {
						c_kind := win.controls[i].kind
						match c_kind {
							'row_start' {
								mut row_indices := []int{}
								i++
								for i < win.controls.len && win.controls[i].kind != 'row_end' {
									if win.controls[i].visible {
										row_indices << i
									}
									i++
								}
								if row_indices.len > 0 {
									row_count := f32(row_indices.len)
									inner_content_w := content_w - group_inner_pad * 2.0
									avail_w := inner_content_w - (row_count - 1.0) * sp
									item_w := avail_w / row_count
									mut max_h := f32(0.0)

									mut cur_x := pad + group_inner_pad
									for idx in row_indices {
										win.controls[idx].x = cur_x
										win.controls[idx].y = inner_y
										if win.controls[idx].expand_fill || win.controls[idx].w <= 0 {
											win.controls[idx].w = item_w
										}
										if win.controls[idx].h > max_h {
											max_h = win.controls[idx].h
										}
										cur_x += win.controls[idx].w + sp
									}
									inner_y += max_h + sp
								}
							}
							else {
								win.controls[i].x = pad + group_inner_pad + win.controls[i].margin_left
								win.controls[i].y = inner_y + win.controls[i].margin_top
								avail_w := content_w - group_inner_pad * 2.0 - win.controls[i].margin_left - win.controls[i].margin_right
								if win.controls[i].expand_fill || win.controls[i].w <= 0 {
									win.controls[i].w = f32(math.max(10.0, avail_w))
								}
								inner_y += win.controls[i].margin_top + win.controls[i].h + win.controls[i].margin_bottom + sp
							}
						}
					}
					i++
				}

				group_height := (inner_y - cur_y) + 8.0
				win.controls[group_start_idx].h = group_height
				cur_y += group_height + sp
			}
			'tab_container_start' {
				win.controls[i].x = pad
				win.controls[i].y = cur_y
				win.controls[i].w = content_w
				win.controls[i].h = 32.0

				active_tab := win.controls[i].int_value
				cur_y += 36.0

				mut inner_idx := i + 1
				mut in_active := false
				for inner_idx < win.controls.len && win.controls[inner_idx].kind != 'tab_container_end' {
					if win.controls[inner_idx].kind == 'tab_page_start' {
						in_active = (win.controls[inner_idx].int_value == active_tab)
						win.controls[inner_idx].visible = false
					} else if win.controls[inner_idx].kind == 'tab_page_end' {
						in_active = false
						win.controls[inner_idx].visible = false
					} else {
						win.controls[inner_idx].visible = in_active
					}
					inner_idx++
				}
			}
			'split_start' {
				split_pct := if win.controls[i].int_value > 0 { f32(win.controls[i].int_value) / 100.0 } else { f32(0.5) }
				left_w := (content_w - sp) * split_pct
				right_w := (content_w - sp) * (1.0 - split_pct)

				win.controls[i].x = pad
				win.controls[i].y = cur_y
				win.controls[i].w = content_w

				mut split_indices := []int{}
				i++
				for i < win.controls.len && win.controls[i].kind != 'split_end' {
					if win.controls[i].visible {
						split_indices << i
					}
					i++
				}

				if split_indices.len >= 2 {
					idx0 := split_indices[0]
					idx1 := split_indices[1]
					win.controls[idx0].x = pad
					win.controls[idx0].y = cur_y
					win.controls[idx0].w = left_w

					win.controls[idx1].x = pad + left_w + sp
					win.controls[idx1].y = cur_y
					win.controls[idx1].w = right_w

					max_h := math.max(win.controls[idx0].h, win.controls[idx1].h)
					cur_y += max_h + sp
				}
			}
			'flow_start' {
				gap := if win.controls[i].int_value > 0 { f32(win.controls[i].int_value) } else { f32(8.0) }
				mut flow_indices := []int{}
				i++
				for i < win.controls.len && win.controls[i].kind != 'flow_end' {
					if win.controls[i].visible {
						flow_indices << i
					}
					i++
				}

				if flow_indices.len > 0 {
					mut line_x := pad
					mut line_max_h := f32(32.0)
					for idx in flow_indices {
						calc_w := f32(measure_text_width(win, win.controls[idx].title) + 48.0)
						item_w := if calc_w > 80.0 { calc_w } else { f32(90.0) }
						item_h := if win.controls[idx].h > 0 { win.controls[idx].h } else { f32(32.0) }
						if line_x + item_w > pad + content_w && line_x > pad {
							cur_y += line_max_h + gap
							line_x = pad
							line_max_h = item_h
						}
						win.controls[idx].x = line_x
						win.controls[idx].y = cur_y
						win.controls[idx].w = item_w
						win.controls[idx].h = item_h
						if item_h > line_max_h {
							line_max_h = item_h
						}
						line_x += item_w + gap
					}
					cur_y += line_max_h + sp
				}
			}
			'vstack_start' {
				gap := if win.controls[i].int_value > 0 { f32(win.controls[i].int_value) } else { sp }
				align := if win.controls[i].alignment.len > 0 { win.controls[i].alignment } else { 'left' }
				mut v_indices := []int{}
				i++
				for i < win.controls.len && win.controls[i].kind != 'vstack_end' {
					if win.controls[i].visible {
						v_indices << i
					}
					i++
				}
				for idx in v_indices {
					win.controls[idx].y = cur_y
					if align == 'center' {
						win.controls[idx].x = pad + (content_w - win.controls[idx].w) / 2.0
					} else if align == 'right' {
						win.controls[idx].x = pad + content_w - win.controls[idx].w
					} else {
						win.controls[idx].x = pad
					}
					cur_y += win.controls[idx].h + gap
				}
			}
			'hstack_start' {
				gap := if win.controls[i].int_value > 0 { f32(win.controls[i].int_value) } else { sp }
				mut h_indices := []int{}
				i++
				for i < win.controls.len && win.controls[i].kind != 'hstack_end' {
					if win.controls[i].visible {
						h_indices << i
					}
					i++
				}
				if h_indices.len > 0 {
					h_count := f32(h_indices.len)
					avail_w := content_w - (h_count - 1.0) * gap
					item_w := avail_w / h_count
					mut max_h := f32(0.0)
					mut cur_x := pad
					for idx in h_indices {
						win.controls[idx].x = cur_x
						win.controls[idx].y = cur_y
						if win.controls[idx].expand_fill || win.controls[idx].w <= 0 {
							win.controls[idx].w = item_w
						}
						if win.controls[idx].h > max_h {
							max_h = win.controls[idx].h
						}
						cur_x += win.controls[idx].w + gap
					}
					cur_y += max_h + sp
				}
			}
			'row_end', 'grid_end', 'flex_end', 'group_end', 'tab_container_end', 'tab_page_start', 'tab_page_end', 'split_end', 'flow_end', 'vstack_end', 'hstack_end' {
				// End tags are processed in container blocks above, ignore loose end tags
			}
			'spacer' {
				spacer_h := if win.controls[i].h > 0 { win.controls[i].h } else { f32(20.0) }
				win.controls[i].x = pad
				win.controls[i].y = cur_y
				win.controls[i].w = content_w
				win.controls[i].h = spacer_h
				cur_y += spacer_h + sp
			}
			'separator' {
				win.controls[i].x = pad
				win.controls[i].y = cur_y
				win.controls[i].w = content_w
				win.controls[i].h = 2.0
				cur_y += 2.0 + sp
			}
			else {
				win.controls[i].x = pad + win.controls[i].margin_left
				win.controls[i].y = cur_y + win.controls[i].margin_top

				avail_w := content_w - win.controls[i].margin_left - win.controls[i].margin_right
				if win.controls[i].expand_fill || win.controls[i].w <= 0 {
					win.controls[i].w = f32(math.max(10.0, avail_w))
				} else if win.controls[i].alignment == 'center' {
					win.controls[i].x = pad + win.controls[i].margin_left + (avail_w - win.controls[i].w) / 2.0
				} else if win.controls[i].alignment == 'right' {
					win.controls[i].x = pad + content_w - win.controls[i].margin_right - win.controls[i].w
				}

				cur_y += win.controls[i].margin_top + win.controls[i].h + win.controls[i].margin_bottom + sp
			}
		}
		i++
	}

	_ = win_h
}


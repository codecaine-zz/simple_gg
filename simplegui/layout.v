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
		mut ctrl := win.controls[i]
		// Skip hidden/invisible controls during layout positioning
		if !ctrl.visible {
			i++
			continue
		}

		// Calculate positioning based on control kind or container wrapper
		match ctrl.kind {
			'row_start' {
				// Collect all sibling controls inside this horizontal row block
				mut row_controls := []&Control{}
				i++
				for i < win.controls.len && win.controls[i].kind != 'row_end' {
					if win.controls[i].visible {
						row_controls << win.controls[i]
					}
					i++
				}

				// Position row controls side-by-side horizontally
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
					// Advance vertical cursor by tallest element in the row
					cur_y += max_h + sp
				}
			}
			'grid_start' {
				// Read column count (default 2) and grid gap spacing
				cols := if ctrl.int_value > 0 { ctrl.int_value } else { 2 }
				grid_sp := if ctrl.f64_value > 0 { f32(ctrl.f64_value) } else { sp }

				// Collect controls inside grid container
				mut grid_controls := []&Control{}
				i++
				for i < win.controls.len && win.controls[i].kind != 'grid_end' {
					if win.controls[i].visible {
						grid_controls << win.controls[i]
					}
					i++
				}

				// Arrange controls into uniform grid columns and rows
				if grid_controls.len > 0 {
					f_cols := f32(cols)
					col_w := (content_w - (f_cols - 1.0) * grid_sp) / f_cols
					mut row_max_h := f32(0.0)

					for idx, mut g_ctrl in grid_controls {
						col_idx := idx % cols
						// Wrap to next grid row when column limit is reached
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
				// Flex layout distributes available width equally among all visible flex children
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
				// Group box container frame calculation
				group_title := ctrl.title
				has_title := group_title.len > 0
				header_h := if has_title { f32(24.0) } else { f32(10.0) }

				ctrl.x = pad
				ctrl.y = cur_y
				ctrl.w = content_w

				group_start_y := cur_y + header_h + 8.0
				mut inner_y := group_start_y
				grp_content_w := content_w - 24.0
				grp_pad := pad + 12.0

				i++
				// Position inner child controls inside group box border
				for i < win.controls.len && win.controls[i].kind != 'group_end' {
					mut child := win.controls[i]
					if !child.visible {
						i++
						continue
					}

					match child.kind {
						'row_start' {
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
								avail_w := grp_content_w - (row_count - 1.0) * sp
								item_w := avail_w / row_count
								mut max_h := f32(0.0)
								mut cur_x := grp_pad
								for mut r_ctrl in row_controls {
									r_ctrl.x = cur_x
									r_ctrl.y = inner_y
									if r_ctrl.expand_fill || r_ctrl.w <= 0 {
										r_ctrl.w = item_w
									}
									if r_ctrl.h > max_h {
										max_h = r_ctrl.h
									}
									cur_x += r_ctrl.w + sp
								}
								inner_y += max_h + sp
							}
						}
						'grid_start' {
							cols := if child.int_value > 0 { child.int_value } else { 2 }
							grid_sp := if child.f64_value > 0 { f32(child.f64_value) } else { sp }
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
								col_w := (grp_content_w - (f_cols - 1.0) * grid_sp) / f_cols
								mut row_max_h := f32(0.0)
								for idx, mut g_ctrl in grid_controls {
									col_idx := idx % cols
									if col_idx == 0 && idx > 0 {
										inner_y += row_max_h + grid_sp
										row_max_h = 0.0
									}
									g_ctrl.x = grp_pad + f32(col_idx) * (col_w + grid_sp)
									g_ctrl.y = inner_y
									g_ctrl.w = col_w
									if g_ctrl.h > row_max_h {
										row_max_h = g_ctrl.h
									}
								}
								inner_y += row_max_h + sp
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
								avail_w := grp_content_w - (count - 1.0) * sp
								item_w := avail_w / count
								mut max_h := f32(0.0)
								mut cur_x := grp_pad
								for mut f_ctrl in flex_controls {
									f_ctrl.x = cur_x
									f_ctrl.y = inner_y
									f_ctrl.w = item_w
									if f_ctrl.h > max_h {
										max_h = f_ctrl.h
									}
									cur_x += item_w + sp
								}
								inner_y += max_h + sp
							}
						}
						else {
							child.x = grp_pad + child.margin_left
							child.y = inner_y + child.margin_top
							avail_w := grp_content_w - child.margin_left - child.margin_right
							if child.expand_fill || child.w <= 0 {
								child.w = f32(math.max(10.0, avail_w))
							}
							inner_y += child.margin_top + child.h + child.margin_bottom + sp
						}
					}
					i++
				}

				// Adjust outer group box height to neatly enclose all children
				group_height := (inner_y - cur_y) + 8.0
				ctrl.h = group_height
				cur_y += group_height + sp
			}
			'tab_container_start' {
				// Tab container header bar
				ctrl.x = pad
				ctrl.y = cur_y
				ctrl.w = content_w
				ctrl.h = 32.0

				active_tab := ctrl.int_value
				cur_y += 36.0

				// Toggle visibility of controls depending on which tab page is currently active
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
				// Split pane divides container into two side-by-side panes by split_ratio percentage
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
				// End tags are processed in container blocks above, ignore loose end tags
			}
			'spacer' {
				// Blank vertical space buffer
				spacer_h := if ctrl.h > 0 { ctrl.h } else { f32(20.0) }
				ctrl.x = pad
				ctrl.y = cur_y
				ctrl.w = content_w
				ctrl.h = spacer_h
				cur_y += spacer_h + sp
			}
			'separator' {
				// Thin horizontal divider line
				ctrl.x = pad
				ctrl.y = cur_y
				ctrl.w = content_w
				ctrl.h = 2.0
				cur_y += 2.0 + sp
			}
			else {
				// Standard standalone widget layout with margin calculations
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


// Module simplegui - Core UI Framework for V
// File: render.v
//
// Description:
//   This file implements the immediate-mode rendering pipeline for SimpleGUI.
//   It takes the calculated positions (x, y, w, h) of every control and draws them on screen
//   using V's native `gg` graphics library.
//
//   Rendering Responsibilities:
//     - Clearing the window background canvas with the active Theme colors
//     - Drawing shapes (filled/rounded rectangles, lines, circles, borders, drop shadows)
//     - Rendering typography text labels, headings, links, and input carets
//     - Drawing interactive UI elements (Buttons, Sliders, CheckBoxes, DropDowns, ListBoxes)
//     - Drawing complex widgets (Data Tables, Sparkline graphs, Accordions, Property Grids, Tag Inputs)
//     - Rendering overlay popups (Toasts, Tooltips, Modal dialogs, Context menus, Spotlight search)

module simplegui

import gg
import math
import time

// render_ui is called on every graphics frame refresh to render the complete window user interface.
// It recalculates layout coordinates, clears the window canvas, and renders every visible control.
pub fn (mut win SimpleWindow) render_ui() {
	if win.gg_ctx == unsafe { nil } {
		return
	}

	// Step 1: Compute responsive control coordinate locations
	win.recalculate_layout()

	// Step 2: Resolve color palette values from current active Theme
	bg := parse_hex_color(win.theme.background_color)
	fg := parse_hex_color(win.theme.font_color)
	accent := parse_hex_color(win.theme.accent_color)
	surface := if win.theme.is_dark { gg.rgb(40, 42, 54) } else { gg.rgb(240, 242, 245) }
	border_c := if win.theme.is_dark { gg.rgb(70, 72, 85) } else { gg.rgb(210, 215, 220) }
	hover_c := if win.theme.hover_color.len > 0 {
		parse_hex_color(win.theme.hover_color)
	} else {
		accent
	}
	surface_hover := if win.theme.surface_hover.len > 0 {
		parse_hex_color(win.theme.surface_hover)
	} else if win.theme.is_dark {
		gg.rgb(55, 58, 72)
	} else {
		gg.rgb(225, 230, 238)
	}

	// Step 3: Clear window background canvas
	win.gg_ctx.draw_rect_filled(0, 0, f32(win.width), f32(win.height), bg)

	// Step 4: Render every visible control registered in the window
	for mut ctrl in win.controls {
		if !ctrl.visible {
			continue
		}

		match ctrl.kind {
			'label' {
				txt_c := if ctrl.font_color.len > 0 { parse_hex_color(ctrl.font_color) } else { fg }
				lbl_txt := if ctrl.text_value.len > 0 { ctrl.text_value } else { ctrl.title }
				win.gg_ctx.draw_text2(
					x:     int(ctrl.x)
					y:     int(ctrl.y + 4)
					text:  lbl_txt
					color: txt_c
					size:  15
				)
			}
			'heading' {
				txt_c := if ctrl.font_color.len > 0 { parse_hex_color(ctrl.font_color) } else { fg }
				hd_txt := if ctrl.text_value.len > 0 { ctrl.text_value } else { ctrl.title }
				win.gg_ctx.draw_text2(
					x:     int(ctrl.x)
					y:     int(ctrl.y)
					text:  hd_txt
					color: txt_c
					size:  22
				)
				win.gg_ctx.draw_line(ctrl.x, ctrl.y + 28, ctrl.x + ctrl.w, ctrl.y + 28,
					border_c)
			}
			'link' {
				link_txt := if ctrl.text_value.len > 0 { ctrl.text_value } else { ctrl.title }
				win.gg_ctx.draw_text2(
					x:     int(ctrl.x)
					y:     int(ctrl.y + 4)
					text:  link_txt
					color: accent
					size:  14
				)
				win.gg_ctx.draw_line(ctrl.x, ctrl.y + 20, ctrl.x + f32(link_txt.len * 8),
					ctrl.y + 20, accent)
			}
			'button', 'action' {
				mut btn_bg := if ctrl.accent_color.len > 0 {
					parse_hex_color(ctrl.accent_color)
				} else {
					accent
				}
				if ctrl.is_hovered {
					btn_bg = hover_c
				}
				if ctrl.is_pressed {
					btn_bg = gg.rgb(u8(math.max(0, btn_bg.r - 30)), u8(math.max(0, btn_bg.g - 30)),
						u8(math.max(0, btn_bg.b - 30)))
				}

				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0,
					btn_bg)

				max_chars := math.max(1, int((ctrl.w - 16.0) / 8.0))
				disp_title := if ctrl.title.len > max_chars && max_chars > 3 {
					ctrl.title[0..max_chars - 3] + '...'
				} else {
					ctrl.title
				}

				text_w := disp_title.len * 8
				text_x := int(ctrl.x + (ctrl.w - f32(text_w)) / 2.0)
				text_y := int(ctrl.y + (ctrl.h - 16.0) / 2.0)

				win.gg_ctx.draw_text2(
					x:     math.max(int(ctrl.x + 8), text_x)
					y:     text_y
					text:  disp_title
					color: gg.Color{
						r: 255
						g: 255
						b: 255
					}
					size:  14
				)
			}
			'icon_button' {
				mut ib_bg := if ctrl.accent_color.len > 0 {
					parse_hex_color(ctrl.accent_color)
				} else {
					surface
				}
				if ctrl.is_hovered {
					ib_bg = surface_hover
				}
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0,
					ib_bg)
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0,
					if ctrl.is_hovered { hover_c } else { border_c })

				icon_c := if ctrl.is_hovered {
					accent
				} else {
					fg
				}
				txt_w := ctrl.title.len * 8
				win.gg_ctx.draw_text2(
					x:     int(ctrl.x + (ctrl.w - f32(txt_w)) / 2.0)
					y:     int(ctrl.y + (ctrl.h - 16.0) / 2.0)
					text:  ctrl.title
					color: icon_c
					size:  15
				)
			}
			'input', 'password', 'search_field', 'pin_code', 'number', 'time_picker' {
				in_bg := if ctrl.is_hovered { surface_hover } else { surface }
				b_c := if ctrl.is_focused { accent } else if ctrl.is_hovered { hover_c } else { border_c }

				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0,
					in_bg)
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0,
					b_c)

				display_txt := if ctrl.kind == 'password' {
					'*'.repeat(ctrl.text_value.len)
				} else if ctrl.kind == 'number' {
					'${ctrl.int_value}'
				} else if ctrl.text_value.len == 0 && ctrl.placeholder.len > 0 {
					ctrl.placeholder
				} else {
					ctrl.text_value
				}

				txt_color := if ctrl.text_value.len == 0 && ctrl.placeholder.len > 0 {
					gg.Color{
						r: 128
						g: 128
						b: 128
					}
				} else {
					fg
				}

				max_in_chars := math.max(1, int((ctrl.w - 24.0) / 7.5))
				mut start_idx := 0
				if ctrl.caret_pos > max_in_chars {
					start_idx = ctrl.caret_pos - max_in_chars
				}
				if start_idx + max_in_chars > display_txt.len && display_txt.len > max_in_chars {
					start_idx = display_txt.len - max_in_chars
				}
				if start_idx < 0 {
					start_idx = 0
				}

				end_idx := math.min(display_txt.len, start_idx + max_in_chars)
				clipped_txt := if display_txt.len > 0 && start_idx < display_txt.len {
					display_txt[start_idx..end_idx]
				} else {
					display_txt
				}

				win.gg_ctx.draw_text2(
					x:     int(ctrl.x + 10)
					y:     int(ctrl.y + (ctrl.h - 16.0) / 2.0)
					text:  clipped_txt
					color: txt_color
					size:  14
				)

				if ctrl.is_focused {
					visible_caret_pos := math.max(0, math.min(clipped_txt.len, ctrl.caret_pos - start_idx))
					prefix_txt := if visible_caret_pos <= clipped_txt.len {
						clipped_txt[0..visible_caret_pos]
					} else {
						clipped_txt
					}
					caret_offset_x := f32(win.gg_ctx.text_width(prefix_txt))
					caret_x := ctrl.x + 10.0 + caret_offset_x
					win.gg_ctx.draw_line(caret_x, ctrl.y + 6, caret_x, ctrl.y + ctrl.h - 6,
						accent)
				}

				if ctrl.kind == 'number' {
					up_x := ctrl.x + ctrl.w - 24
					win.gg_ctx.draw_text2(
						x:     int(up_x)
						y:     int(ctrl.y + 2)
						text:  '^'
						color: fg
						size:  10
					)
					win.gg_ctx.draw_text2(
						x:     int(up_x)
						y:     int(ctrl.y + 14)
						text:  'v'
						color: fg
						size:  10
					)
				}
			}
			'textarea', 'console', 'code', 'markdown' {
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0,
					surface)
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0,
					border_c)

				lines := ctrl.text_value.split('\n')
				mut line_y := ctrl.y + 8.0
				for line in lines {
					if line_y + 18.0 > ctrl.y + ctrl.h - 8.0 {
						break
					}
					win.gg_ctx.draw_text2(
						x:     int(ctrl.x + 10)
						y:     int(line_y)
						text:  line
						color: fg
						size:  13
					)
					line_y += 18.0
				}
			}
			'checkbox', 'toggle' {
				box_size := f32(20.0)
				box_y := ctrl.y + (ctrl.h - box_size) / 2.0

				if ctrl.bool_value {
					win.gg_ctx.draw_rounded_rect_filled(ctrl.x, box_y, box_size, box_size,
						4.0, if ctrl.is_hovered { hover_c } else { accent })
					white_c := gg.Color{
						r: 255
						g: 255
						b: 255
					}
					win.gg_ctx.draw_line(ctrl.x + 4, box_y + 10, ctrl.x + 8, box_y + 14,
						white_c)
					win.gg_ctx.draw_line(ctrl.x + 8, box_y + 14, ctrl.x + 15, box_y + 5,
						white_c)
				} else {
					win.gg_ctx.draw_rounded_rect_filled(ctrl.x, box_y, box_size, box_size,
						4.0, if ctrl.is_hovered { surface_hover } else { surface })
					win.gg_ctx.draw_rounded_rect_empty(ctrl.x, box_y, box_size, box_size,
						4.0, if ctrl.is_hovered { hover_c } else { border_c })
				}

				win.gg_ctx.draw_text2(
					x:     int(ctrl.x + box_size + 10)
					y:     int(ctrl.y + (ctrl.h - 16.0) / 2.0)
					text:  ctrl.title
					color: fg
					size:  14
				)
			}
			'switch' {
				sw_w := f32(40.0)
				sw_h := f32(22.0)
				sw_y := ctrl.y + (ctrl.h - sw_h) / 2.0
				white_c := gg.Color{
					r: 255
					g: 255
					b: 255
				}

				knob_s := f32(18.0)
				knob_y := sw_y + (sw_h - knob_s) / 2.0

				if ctrl.bool_value {
					win.gg_ctx.draw_rounded_rect_filled(ctrl.x, sw_y, sw_w, sw_h, 11.0,
						if ctrl.is_hovered { hover_c } else { accent })
					win.gg_ctx.draw_rounded_rect_filled(ctrl.x + sw_w - knob_s - 2.0, knob_y,
						knob_s, knob_s, 9.0, white_c)
				} else {
					win.gg_ctx.draw_rounded_rect_filled(ctrl.x, sw_y, sw_w, sw_h, 11.0,
						if ctrl.is_hovered { hover_c } else { border_c })
					win.gg_ctx.draw_rounded_rect_filled(ctrl.x + 2.0, knob_y,
						knob_s, knob_s, 9.0, white_c)
				}

				win.gg_ctx.draw_text2(
					x:     int(ctrl.x + sw_w + 12)
					y:     int(ctrl.y + (ctrl.h - 16.0) / 2.0)
					text:  ctrl.title
					color: fg
					size:  14
				)
			}
			'slider' {
				track_h := f32(6.0)
				track_y := ctrl.y + (ctrl.h - track_h) / 2.0
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, track_y, ctrl.w, track_h,
					3.0, if ctrl.is_hovered { surface_hover } else { border_c })

				pct := f32(ctrl.int_value) / 100.0
				fill_w := ctrl.w * pct
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, track_y, fill_w, track_h,
					3.0, if ctrl.is_hovered { hover_c } else { accent })

				thumb_w := if ctrl.is_hovered { f32(16.0) } else { f32(14.0) }
				thumb_h := if ctrl.is_hovered { f32(16.0) } else { f32(14.0) }
				thumb_x := ctrl.x + fill_w - thumb_w / 2.0
				thumb_y := ctrl.y + (ctrl.h - thumb_h) / 2.0
				win.gg_ctx.draw_rounded_rect_filled(thumb_x, thumb_y, thumb_w, thumb_h, 4.0, if ctrl.is_hovered { hover_c } else { accent })
			}
			'progress', 'gauge', 'radial_gauge', 'circular_progress' {
				track_h := f32(10.0)
				track_y := ctrl.y + (ctrl.h - track_h) / 2.0
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, track_y, ctrl.w, track_h,
					5.0, border_c)

				pct := math.max(0.0, math.min(1.0, f64(ctrl.int_value) / 100.0))
				fill_w := ctrl.w * f32(pct)
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, track_y, fill_w, track_h,
					5.0, accent)
			}
			'password_strength' {
				target_name := ctrl.props['target']
				mut pwd_val := ''
				if tctrl := win.control_map[target_name] {
					pwd_val = tctrl.text_value
				}

				mut score := 0
				mut has_upper := false
				mut has_digit := false
				mut has_symbol := false
				for i in 0 .. pwd_val.len {
					c := pwd_val[i]
					if c >= u8(65) && c <= u8(90) {
						has_upper = true
					} else if c >= u8(48) && c <= u8(57) {
						has_digit = true
					} else if !(c >= u8(97) && c <= u8(122)) {
						has_symbol = true
					}
				}
				if pwd_val.len > 0 {
					score += 20
				}
				if pwd_val.len >= 8 {
					score += 25
				}
				if has_upper {
					score += 20
				}
				if has_digit {
					score += 20
				}
				if has_symbol {
					score += 15
				}
				score = math.min(100, score)

				mut label_txt := ''
				mut bar_c := border_c
				if pwd_val.len == 0 {
					label_txt = ''
					bar_c = border_c
				} else if score >= 75 {
					label_txt = 'Strong'
					bar_c = gg.rgb(52, 199, 89)
				} else if score >= 45 {
					label_txt = 'Medium'
					bar_c = gg.rgb(245, 158, 11)
				} else {
					label_txt = 'Weak'
					bar_c = gg.rgb(239, 68, 68)
				}

				track_h2 := f32(8.0)
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, track_h2,
					4.0, border_c)
				fill_w2 := ctrl.w * f32(score) / 100.0
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, fill_w2, track_h2,
					4.0, bar_c)
				win.gg_ctx.draw_text2(
					x:     int(ctrl.x)
					y:     int(ctrl.y + 12)
					text:  label_txt
					color: fg
					size:  12
				)
			}
			'dropdown' {
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0,
					surface)
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0,
					border_c)

				display_txt := if ctrl.text_value.len > 0 {
					ctrl.text_value
				} else {
					if ctrl.items.len > 0 { ctrl.items[0] } else { ctrl.title }
				}
				win.gg_ctx.draw_text2(
					x:     int(ctrl.x + 10)
					y:     int(ctrl.y + (ctrl.h - 16.0) / 2.0)
					text:  display_txt
					color: fg
					size:  14
				)
				win.gg_ctx.draw_text2(
					x:     int(ctrl.x + ctrl.w - 24)
					y:     int(ctrl.y + (ctrl.h - 16.0) / 2.0)
					text:  'v'
					color: fg
					size:  11
				)
			}
			'skeleton' {
				ticks := time.ticks()
				pulse := math.abs(math.sin(f64(ticks % 2000) / 2000.0 * math.pi))
				sk_base := if win.theme.is_dark { f32(40.0) } else { f32(210.0) }
				sk_val := u8(math.max(0.0, math.min(255.0, sk_base + f32(pulse * 45.0))))
				sk_c := gg.rgb(sk_val, sk_val, sk_val)
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0, sk_c)
			}
			'menu_button' {
				hdr_h := f32(34.0)
				mb_bg := if ctrl.is_hovered { accent } else { surface }
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, hdr_h, 6.0,
					mb_bg)
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, ctrl.w, hdr_h, 6.0,
					border_c)

				mb_label := if ctrl.text_value.len > 0 { ctrl.text_value } else { ctrl.title }
				mb_txt_c := if ctrl.is_hovered {
					gg.Color{
						r: 255
						g: 255
						b: 255
					}
				} else {
					fg
				}
				win.gg_ctx.draw_text2(
					x:     int(ctrl.x + 10)
					y:     int(ctrl.y + (hdr_h - 16.0) / 2.0)
					text:  mb_label
					color: mb_txt_c
					size:  14
				)

				arrow_c := if ctrl.is_expanded { '^' } else { 'v' }
				win.gg_ctx.draw_text2(
					x:     int(ctrl.x + ctrl.w - 20)
					y:     int(ctrl.y + (hdr_h - 16.0) / 2.0)
					text:  arrow_c
					color: mb_txt_c
					size:  12
				)

				if ctrl.is_expanded && ctrl.items.len > 0 {
					list_y := ctrl.y + hdr_h + 2.0
					list_h := f32(ctrl.items.len) * 28.0
					win.gg_ctx.draw_rounded_rect_filled(ctrl.x, list_y, ctrl.w, list_h,
						6.0, surface)
					win.gg_ctx.draw_rounded_rect_empty(ctrl.x, list_y, ctrl.w, list_h,
						6.0, border_c)

					mut item_y := list_y
					for item in ctrl.items {
						is_sel := item == ctrl.text_value
						if is_sel {
							win.gg_ctx.draw_rect_filled(ctrl.x + 2, item_y + 1, ctrl.w - 4,
								26.0, accent)
						}
						item_c := if is_sel {
							gg.Color{
								r: 255
								g: 255
								b: 255
							}
						} else {
							fg
						}
						win.gg_ctx.draw_text2(
							x:     int(ctrl.x + 10)
							y:     int(item_y + 6)
							text:  item
							color: item_c
							size:  13
						)
						item_y += 28.0
					}
				}
			}
			'segmented', 'tab_pills', 'radio', 'filter_chips', 'mode_control' {
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0,
					surface)
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0,
					border_c)

				if ctrl.items.len > 0 {
					seg_w := ctrl.w / f32(ctrl.items.len)
					for idx, item in ctrl.items {
						item_x := ctrl.x + f32(idx) * seg_w
						is_sel := item == ctrl.text_value || idx == ctrl.int_value
						if is_sel {
							win.gg_ctx.draw_rounded_rect_filled(item_x + 2, ctrl.y + 2,
								seg_w - 4, ctrl.h - 4, 4.0, accent)
						}
						item_c := if is_sel {
							gg.Color{
								r: 255
								g: 255
								b: 255
							}
						} else {
							fg
						}
						win.gg_ctx.draw_text2(
							x:     int(item_x + (seg_w - f32(item.len * 7)) / 2.0)
							y:     int(ctrl.y + (ctrl.h - 16.0) / 2.0)
							text:  item
							color: item_c
							size:  13
						)
					}
				} else {
					win.gg_ctx.draw_text2(
						x:     int(ctrl.x + 10)
						y:     int(ctrl.y + (ctrl.h - 16.0) / 2.0)
						text:  if ctrl.text_value.len > 0 { ctrl.text_value } else { ctrl.title }
						color: fg
						size:  14
					)
				}
			}
			'rating' {
				stars := if ctrl.int_value > 0 { ctrl.int_value } else { 4 }
				mut star_x := ctrl.x
				for s_idx in 1 .. 6 {
					star_txt := if s_idx <= stars { '★' } else { '☆' }
					star_c := if s_idx <= stars { accent } else { border_c }
					win.gg_ctx.draw_text2(
						x:     int(star_x)
						y:     int(ctrl.y + 2)
						text:  star_txt
						color: star_c
						size:  18
					)
					star_x += 24.0
				}
			}
			'date_picker' {
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0,
					surface)
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0,
					border_c)

				date_str := if ctrl.text_value.len > 0 { ctrl.text_value } else { 'yyyy-mm-dd' }
				win.gg_ctx.draw_text2(
					x:     int(ctrl.x + 10)
					y:     int(ctrl.y + (ctrl.h - 16.0) / 2.0)
					text:  date_str
					color: fg
					size:  14
				)
				win.gg_ctx.draw_text2(
					x:     int(ctrl.x + ctrl.w - 48)
					y:     int(ctrl.y + (ctrl.h - 16.0) / 2.0)
					text:  '[Date]'
					color: fg
					size:  12
				)
			}
			'color_well', 'color_palette', 'color_grid' {
				swatch_c := parse_hex_color(if ctrl.text_value.len > 0 {
					ctrl.text_value
				} else {
					'#007aff'
				})
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0,
					swatch_c)
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0,
					border_c)
			}
			'list_box' {
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0,
					surface)
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0,
					border_c)

				mut item_y := ctrl.y + 4.0
				for idx, item in ctrl.items {
					if item_y + 22.0 > ctrl.y + ctrl.h {
						break
					}
					is_sel := item == ctrl.text_value || idx == ctrl.int_value
					if is_sel {
						win.gg_ctx.draw_rounded_rect_filled(ctrl.x + 3, item_y, ctrl.w - 6, 22.0, 4.0,
							accent)
					}
					item_c := if is_sel {
						gg.Color{
							r: 255
							g: 255
							b: 255
						}
					} else {
						fg
					}
					prefix := if is_sel { '▸ ' } else { '  ' }
					win.gg_ctx.draw_text2(
						x:     int(ctrl.x + 8)
						y:     int(item_y + 3)
						text:  prefix + item
						color: item_c
						size:  12
					)
					item_y += 24.0
				}
			}
			'multi_list_box' {
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0,
					surface)
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0,
					border_c)

				mut item_y := ctrl.y + 4.0
				for _, item in ctrl.items {
					if item_y + 22.0 > ctrl.y + ctrl.h {
						break
					}
					is_sel := item in ctrl.items_selected
					if is_sel {
						win.gg_ctx.draw_rounded_rect_filled(ctrl.x + 3, item_y, ctrl.w - 6, 22.0, 4.0,
							accent)
					}
					item_c := if is_sel {
						gg.Color{
							r: 255
							g: 255
							b: 255
						}
					} else {
						fg
					}
					check_mark := if is_sel { '[✓] ' } else { '[  ] ' }
					win.gg_ctx.draw_text2(
						x:     int(ctrl.x + 8)
						y:     int(item_y + 3)
						text:  check_mark + item
						color: item_c
						size:  12
					)
					item_y += 24.0
				}
			}
			'checklist' {
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0,
					surface)
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0,
					border_c)

				mut cl_y := ctrl.y + 6.0
				for item in ctrl.items {
					if cl_y + 22.0 > ctrl.y + ctrl.h {
						break
					}
					is_checked := item in ctrl.items_selected
					if is_checked {
						win.gg_ctx.draw_rounded_rect_filled(ctrl.x + 8, cl_y, 16.0, 16.0,
							3.0, accent)
						white_c := gg.Color{
							r: 255
							g: 255
							b: 255
						}
						win.gg_ctx.draw_line(ctrl.x + 11, cl_y + 8, ctrl.x + 14, cl_y + 12,
							white_c)
						win.gg_ctx.draw_line(ctrl.x + 14, cl_y + 12, ctrl.x + 20, cl_y + 4,
							white_c)
					} else {
						win.gg_ctx.draw_rounded_rect_filled(ctrl.x + 8, cl_y, 16.0, 16.0,
							3.0, surface)
						win.gg_ctx.draw_rounded_rect_empty(ctrl.x + 8, cl_y, 16.0, 16.0,
							3.0, border_c)
					}
					win.gg_ctx.draw_text2(
						x:     int(ctrl.x + 32)
						y:     int(cl_y - 1)
						text:  item
						color: fg
						size:  13
					)
					cl_y += 24.0
				}
			}
			'chip_group' {
				mut cx := ctrl.x
				for item in ctrl.items {
					is_sel := item in ctrl.items_selected
					chip_w := f32(item.len * 7 + 20)
					if cx + chip_w > ctrl.x + ctrl.w {
						break
					}
					chip_bg := if is_sel { accent } else { surface }
					win.gg_ctx.draw_rounded_rect_filled(cx, ctrl.y, chip_w, ctrl.h, ctrl.h / 2.0,
						chip_bg)
					win.gg_ctx.draw_rounded_rect_empty(cx, ctrl.y, chip_w, ctrl.h, ctrl.h / 2.0,
						border_c)
					chip_c := if is_sel {
						gg.Color{
							r: 255
							g: 255
							b: 255
						}
					} else {
						fg
					}
					win.gg_ctx.draw_text2(
						x:     int(cx + 10)
						y:     int(ctrl.y + (ctrl.h - 14.0) / 2.0)
						text:  item
						color: chip_c
						size:  12
					)
					cx += chip_w + 8.0
				}
			}
			'grid', 'table' {
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0,
					surface)
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0,
					border_c)

				col_cnt := if ctrl.headers.len > 0 {
					ctrl.headers.len
				} else {
					if ctrl.rows.len > 0 { ctrl.rows[0].len } else { 1 }
				}
				col_widths := calc_table_col_widths(ctrl)
				header_h := table_header_height(ctrl)

				if ctrl.headers.len > 0 {
					win.gg_ctx.draw_rect_filled(ctrl.x, ctrl.y, ctrl.w, header_h, border_c)
					mut cur_col_x := ctrl.x
					for c_idx, h_text in ctrl.headers {
						col_w := if c_idx < col_widths.len {
							col_widths[c_idx]
						} else {
							ctrl.w / f32(ctrl.headers.len)
						}
						is_sorted_col := c_idx == ctrl.sort_col
						sort_arrow := if is_sorted_col {
							if ctrl.sort_asc { ' ^' } else { ' v' }
						} else {
							''
						}
						max_len := int((col_w - 10.0 - f32(sort_arrow.len * 7)) / 7.0)
						disp_h := if h_text.len > max_len && max_len > 3 {
							'${h_text[0..max_len - 3]}...'
						} else {
							h_text
						}
						hdr_c := if is_sorted_col { accent } else { fg }
						win.gg_ctx.draw_text2(
							x:     int(cur_col_x + 8)
							y:     int(ctrl.y + 6)
							text:  '${disp_h}${sort_arrow}'
							color: hdr_c
							size:  13
						)
						cur_col_x += col_w
					}
				}

				body_h := ctrl.h - header_h
				content_h := table_content_height(ctrl)
				hover_row_idx := if ctrl.is_hovered && !win.mouse_down {
					int((win.mouse_y - (ctrl.y + header_h) + ctrl.scroll_offset_y) / 26.0)
				} else {
					-1
				}

				if ctrl.rows.len == 0 {
					empty_txt := 'No data available'
					win.gg_ctx.draw_text2(
						x:     int(ctrl.x + (ctrl.w - f32(empty_txt.len * 7)) / 2.0)
						y:     int(ctrl.y + header_h + (body_h - 16.0) / 2.0)
						text:  empty_txt
						color: border_c
						size:  13
					)
				} else {
					mut row_y := ctrl.y + header_h - ctrl.scroll_offset_y

					for r_idx, row in ctrl.rows {
						if row_y + 26.0 < ctrl.y + header_h {
							row_y += 26.0
							continue
						}
						if row_y > ctrl.y + ctrl.h {
							break
						}
						is_sel := r_idx == ctrl.selected_row
						is_row_hover := r_idx == hover_row_idx && !is_sel
						if is_sel {
							win.gg_ctx.draw_rect_filled(ctrl.x + 2, row_y + 1, ctrl.w - 4,
								24.0, accent)
						} else if is_row_hover {
							hover_bg := if win.theme.is_dark {
								gg.rgb(60, 63, 78)
							} else {
								gg.rgb(232, 236, 241)
							}
							win.gg_ctx.draw_rect_filled(ctrl.x + 2, row_y + 1, ctrl.w - 4,
								24.0, hover_bg)
						} else if r_idx % 2 == 1 {
							row_bg := if win.theme.is_dark {
								gg.rgb(32, 34, 44)
							} else {
								gg.rgb(248, 249, 250)
							}
							win.gg_ctx.draw_rect_filled(ctrl.x + 2, row_y + 1, ctrl.w - 4,
								24.0, row_bg)
						}

						row_fg := if is_sel {
							gg.Color{
								r: 255
								g: 255
								b: 255
							}
						} else {
							fg
						}
						mut cur_col_x := ctrl.x
						for c_idx, cell_txt in row {
							if c_idx < col_cnt {
								col_w := if c_idx < col_widths.len {
									col_widths[c_idx]
								} else {
									ctrl.w / f32(col_cnt)
								}
								max_len := int((col_w - 10.0) / 7.0)
								disp_txt := if cell_txt.len > max_len && max_len > 3 {
									'${cell_txt[0..max_len - 3]}...'
								} else {
									cell_txt
								}
								win.gg_ctx.draw_text2(
									x:     int(cur_col_x + 8)
									y:     int(row_y + 4)
									text:  disp_txt
									color: row_fg
									size:  13
								)
								cur_col_x += col_w
							}
						}
						row_y += 26.0
					}
				}

				if content_h > body_h {
					max_scroll := content_h - body_h
					track_x := ctrl.x + ctrl.w - 6.0
					win.gg_ctx.draw_rect_filled(track_x, ctrl.y + header_h, 4.0, body_h,
						border_c)
					thumb_h := math.max(f32(20.0), body_h * (body_h / content_h))
					thumb_y := ctrl.y + header_h +
						(ctrl.scroll_offset_y / max_scroll) * (body_h - thumb_h)
					win.gg_ctx.draw_rect_filled(track_x, thumb_y, 4.0, thumb_h, accent)
				}
			}
			'tree_view' {
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0,
					surface)
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0,
					border_c)

				mut node_y := ctrl.y + 6.0
				for node in ctrl.tree_nodes {
					if node_y + 24.0 > ctrl.y + ctrl.h {
						break
					}
					exp_icon := if node.children.len > 0 {
						if node.expanded { '[-]' } else { '[+]' }
					} else {
						'   '
					}
					icon_tag := if node.icon.len > 0 {
						node.icon
					} else {
						if node.children.len > 0 { '[DIR]' } else { '[FILE]' }
					}
					node_txt := '${exp_icon} ${icon_tag} ${node.text}'

					win.gg_ctx.draw_text2(
						x:     int(ctrl.x + 10)
						y:     int(node_y)
						text:  node_txt
						color: fg
						size:  13
					)
					node_y += 24.0

					if node.expanded && node.children.len > 0 {
						for child in node.children {
							if node_y + 24.0 > ctrl.y + ctrl.h {
								break
							}
							ch_tag := if child.icon.len > 0 { child.icon } else { '[FILE]' }
							ch_txt := '     |-- ${ch_tag} ${child.text}'
							win.gg_ctx.draw_text2(
								x:     int(ctrl.x + 20)
								y:     int(node_y)
								text:  ch_txt
								color: fg
								size:  12
							)
							node_y += 22.0
						}
					}
				}
			}
			'tab_container_start' {
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0,
					surface)
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0,
					border_c)

				if ctrl.items.len > 0 {
					tab_w := ctrl.w / f32(ctrl.items.len)
					for idx, title in ctrl.items {
						tx := ctrl.x + f32(idx) * tab_w
						is_sel := idx == ctrl.int_value
						if is_sel {
							win.gg_ctx.draw_rounded_rect_filled(tx + 2, ctrl.y + 2, tab_w - 4,
								ctrl.h - 4, 4.0, accent)
						}
						txt_c := if is_sel {
							gg.Color{
								r: 255
								g: 255
								b: 255
							}
						} else {
							fg
						}
						win.gg_ctx.draw_text2(
							x:     int(tx + (tab_w - f32(title.len * 7)) / 2.0)
							y:     int(ctrl.y + (ctrl.h - 16.0) / 2.0)
							text:  title
							color: txt_c
							size:  13
						)
					}
				}
			}
			'file_picker' {
				input_w := ctrl.w - 84.0
				fp_b_c := if ctrl.is_focused { accent } else { border_c }
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, input_w, ctrl.h, 6.0,
					surface)
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, input_w, ctrl.h, 6.0,
					fp_b_c)

				raw_path := if ctrl.text_value.len > 0 { ctrl.text_value } else { 'Select file...' }
				path_c := if ctrl.text_value.len > 0 {
					fg
				} else {
					gg.Color{
						r: 128
						g: 128
						b: 128
					}
				}

				max_path_chars := math.max(1, int((input_w - 20.0) / 7.5))
				mut start_idx := 0
				if ctrl.caret_pos > max_path_chars {
					start_idx = ctrl.caret_pos - max_path_chars
				}
				if start_idx + max_path_chars > ctrl.text_value.len
					&& ctrl.text_value.len > max_path_chars {
					start_idx = ctrl.text_value.len - max_path_chars
				}
				if start_idx < 0 {
					start_idx = 0
				}

				end_idx := math.min(raw_path.len, start_idx + max_path_chars)
				disp_path := if raw_path.len > 0 && start_idx < raw_path.len {
					raw_path[start_idx..end_idx]
				} else {
					raw_path
				}

				win.gg_ctx.draw_text2(
					x:     int(ctrl.x + 10)
					y:     int(ctrl.y + (ctrl.h - 16.0) / 2.0)
					text:  disp_path
					color: path_c
					size:  13
				)

				if ctrl.is_focused {
					visible_caret_pos := math.max(0, math.min(disp_path.len, ctrl.caret_pos - start_idx))
					prefix_txt := if visible_caret_pos <= disp_path.len {
						disp_path[0..visible_caret_pos]
					} else {
						disp_path
					}
					caret_offset_x := f32(win.gg_ctx.text_width(prefix_txt))
					caret_x := ctrl.x + 10.0 + caret_offset_x
					win.gg_ctx.draw_line(caret_x, ctrl.y + 6, caret_x, ctrl.y + ctrl.h - 6,
						accent)
				}

				btn_x := ctrl.x + ctrl.w - 78.0
				win.gg_ctx.draw_rounded_rect_filled(btn_x, ctrl.y, 78.0, ctrl.h, 6.0,
					accent)
				win.gg_ctx.draw_text2(
					x:     int(btn_x + 12)
					y:     int(ctrl.y + (ctrl.h - 16.0) / 2.0)
					text:  'Browse'
					color: gg.Color{
						r: 255
						g: 255
						b: 255
					}
					size:  13
				)
			}
			'search_bar' {
				sb_b_c := if ctrl.is_focused { accent } else { border_c }
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0,
					surface)
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0,
					sb_b_c)

				win.gg_ctx.draw_text2(
					x:     int(ctrl.x + 8)
					y:     int(ctrl.y + (ctrl.h - 16.0) / 2.0)
					text:  '[Q]'
					color: fg
					size:  11
				)

				s_txt := if ctrl.text_value.len > 0 { ctrl.text_value } else { ctrl.placeholder }
				s_color := if ctrl.text_value.len == 0 && ctrl.placeholder.len > 0 {
					gg.Color{
						r: 128
						g: 128
						b: 128
					}
				} else {
					fg
				}

				max_s_chars := math.max(1, int((ctrl.w - 56.0) / 7.5))
				mut start_idx := 0
				if ctrl.caret_pos > max_s_chars {
					start_idx = ctrl.caret_pos - max_s_chars
				}
				if start_idx + max_s_chars > ctrl.text_value.len
					&& ctrl.text_value.len > max_s_chars {
					start_idx = ctrl.text_value.len - max_s_chars
				}
				if start_idx < 0 {
					start_idx = 0
				}

				end_idx := math.min(s_txt.len, start_idx + max_s_chars)
				disp_s := if s_txt.len > 0 && start_idx < s_txt.len {
					s_txt[start_idx..end_idx]
				} else {
					s_txt
				}

				win.gg_ctx.draw_text2(
					x:     int(ctrl.x + 32)
					y:     int(ctrl.y + (ctrl.h - 16.0) / 2.0)
					text:  disp_s
					color: s_color
					size:  13
				)

				if ctrl.is_focused {
					visible_caret_pos := math.max(0, math.min(disp_s.len, ctrl.caret_pos - start_idx))
					prefix_txt := if visible_caret_pos <= disp_s.len {
						disp_s[0..visible_caret_pos]
					} else {
						disp_s
					}
					caret_offset_x := f32(win.gg_ctx.text_width(prefix_txt))
					caret_x := ctrl.x + 32.0 + caret_offset_x
					win.gg_ctx.draw_line(caret_x, ctrl.y + 6, caret_x, ctrl.y + ctrl.h - 6,
						accent)
				}

				if ctrl.text_value.len > 0 {
					win.gg_ctx.draw_text2(
						x:     int(ctrl.x + ctrl.w - 22)
						y:     int(ctrl.y + (ctrl.h - 16.0) / 2.0)
						text:  '[x]'
						color: fg
						size:  11
					)
				}
			}
			'badge' {
				badge_bg := match ctrl.variant {
					'success' { parse_hex_color('#10b981') }
					'warning' { parse_hex_color('#f59e0b') }
					'danger' { parse_hex_color('#ef4444') }
					'info' { parse_hex_color('#3b82f6') }
					else { accent }
				}
				badge_w := f32(ctrl.title.len * 7 + 16)
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, badge_w, ctrl.h, 12.0,
					badge_bg)
				win.gg_ctx.draw_text2(
					x:     int(ctrl.x + 8)
					y:     int(ctrl.y + (ctrl.h - 14.0) / 2.0)
					text:  ctrl.title
					color: gg.Color{
						r: 255
						g: 255
						b: 255
					}
					size:  12
				)
			}
			'breadcrumb' {
				if ctrl.items.len > 0 {
					mut bx := ctrl.x
					for idx, item in ctrl.items {
						is_last := idx == ctrl.items.len - 1
						item_c := if is_last { fg } else { accent }
						win.gg_ctx.draw_text2(
							x:     int(bx)
							y:     int(ctrl.y + 4)
							text:  item
							color: item_c
							size:  13
						)
						bx += f32(item.len * 7 + 6)
						if !is_last {
							win.gg_ctx.draw_text2(
								x:     int(bx)
								y:     int(ctrl.y + 4)
								text:  '>'
								color: border_c
								size:  13
							)
							bx += 14.0
						}
					}
				}
			}
			'stepper' {
				if ctrl.items.len > 0 {
					step_cnt := ctrl.items.len
					step_w := ctrl.w / f32(step_cnt)
					active_idx := ctrl.int_value

					line_y := ctrl.y + ctrl.h / 2.0
					win.gg_ctx.draw_line(ctrl.x + 20, line_y, ctrl.x + ctrl.w - 20, line_y,
						border_c)

					for idx, step_name in ctrl.items {
						cx := ctrl.x + f32(idx) * step_w + step_w / 2.0
						is_done := idx <= active_idx
						circle_c := if is_done { accent } else { border_c }

						win.gg_ctx.draw_rounded_rect_filled(cx - 10.0, line_y - 10.0, 20.0, 20.0, 4.0, circle_c)
						num_str := '${idx + 1}'
						win.gg_ctx.draw_text2(
							x:     int(cx - 3)
							y:     int(line_y - 6)
							text:  num_str
							color: gg.Color{
								r: 255
								g: 255
								b: 255
							}
							size:  11
						)

						win.gg_ctx.draw_text2(
							x:     int(cx - f32(step_name.len * 3))
							y:     int(line_y + 12)
							text:  step_name
							color: fg
							size:  11
						)
					}
				}
			}
			'accordion' {
				hdr_h := f32(32.0)
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, hdr_h, 6.0,
					surface)
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, ctrl.w, hdr_h, 6.0,
					border_c)

				fold_icon := if ctrl.is_expanded { '[-]' } else { '[+]' }
				win.gg_ctx.draw_text2(
					x:     int(ctrl.x + 10)
					y:     int(ctrl.y + 8)
					text:  '${fold_icon} ${ctrl.title}'
					color: fg
					size:  14
				)

				if ctrl.is_expanded {
					body_y := ctrl.y + hdr_h + 4
					body_h := ctrl.h - hdr_h - 4
					win.gg_ctx.draw_rounded_rect_filled(ctrl.x, body_y, ctrl.w, body_h,
						6.0, bg)
					win.gg_ctx.draw_rounded_rect_empty(ctrl.x, body_y, ctrl.w, body_h,
						6.0, border_c)
					win.gg_ctx.draw_text2(
						x:     int(ctrl.x + 12)
						y:     int(body_y + 8)
						text:  ctrl.text_value
						color: fg
						size:  13
					)
				}
			}
			'avatar' {
				circle_r := f32(18.0)
				cy := ctrl.y + ctrl.h / 2.0
				cx := ctrl.x + circle_r
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, cy - circle_r, circle_r * 2.0, circle_r * 2.0, 6.0, accent)
				win.gg_ctx.draw_text2(
					x:     int(cx - 6)
					y:     int(cy - 7)
					text:  ctrl.title
					color: gg.Color{
						r: 255
						g: 255
						b: 255
					}
					size:  13
				)

				if ctrl.placeholder.len > 0 {
					win.gg_ctx.draw_text2(
						x:     int(ctrl.x + circle_r * 2.0 + 10)
						y:     int(cy - 6)
						text:  ctrl.placeholder
						color: fg
						size:  13
					)
				}
			}
			'divider' {
				mid_y := ctrl.y + ctrl.h / 2.0
				if ctrl.title.len > 0 {
					txt_w := f32(ctrl.title.len * 7 + 16)
					win.gg_ctx.draw_line(ctrl.x, mid_y, ctrl.x + 20, mid_y, border_c)
					win.gg_ctx.draw_text2(
						x:     int(ctrl.x + 24)
						y:     int(mid_y - 7)
						text:  ctrl.title
						color: border_c
						size:  12
					)
					win.gg_ctx.draw_line(ctrl.x + 24 + txt_w, mid_y, ctrl.x + ctrl.w,
						mid_y, border_c)
				} else {
					win.gg_ctx.draw_line(ctrl.x, mid_y, ctrl.x + ctrl.w, mid_y, border_c)
				}
			}
			'chart', 'sparkline', 'audio_waveform' {
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0,
					surface)
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0,
					border_c)

				if ctrl.f64_list.len > 1 {
					pts_cnt := ctrl.f64_list.len
					step_x := ctrl.w / f32(pts_cnt - 1)
					for p_idx in 0 .. pts_cnt {
						v := ctrl.f64_list[p_idx]
						px := ctrl.x + f32(p_idx) * step_x
						py := ctrl.y + ctrl.h - f32((v / 100.0) * f64(ctrl.h - 16)) - 8

						if p_idx < pts_cnt - 1 {
							v_next := ctrl.f64_list[p_idx + 1]
							px_next := ctrl.x + f32(p_idx + 1) * step_x
							py_next := ctrl.y + ctrl.h - f32((v_next / 100.0) * f64(ctrl.h - 16)) - 8
							win.gg_ctx.draw_line(px, py, px_next, py_next, accent)
						}

						win.gg_ctx.draw_rect_filled(px - 2.0, py - 2.0, 4.0, 4.0, accent)
					}
				}
			}
			'metric_card', 'card' {
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 10.0,
					surface)
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 10.0,
					border_c)

				win.gg_ctx.draw_text2(
					x:     int(ctrl.x + 12)
					y:     int(ctrl.y + 10)
					text:  ctrl.title
					color: fg
					size:  13
				)
				win.gg_ctx.draw_text2(
					x:     int(ctrl.x + 12)
					y:     int(ctrl.y + 32)
					text:  ctrl.text_value
					color: accent
					size:  18
				)

				if ctrl.placeholder.len > 0 {
					badge_w := f32(ctrl.placeholder.len * 7 + 12)
					badge_x := ctrl.x + ctrl.w - badge_w - 10
					win.gg_ctx.draw_rounded_rect_filled(badge_x, ctrl.y + 10, badge_w,
						20.0, 4.0, accent)
					win.gg_ctx.draw_text2(
						x:     int(badge_x + 6)
						y:     int(ctrl.y + 12)
						text:  ctrl.placeholder
						color: gg.Color{
							r: 255
							g: 255
							b: 255
						}
						size:  11
					)
				}
			}
			'alert_banner' {
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0,
					parse_hex_color('#fef3c7'))
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0,
					parse_hex_color('#f59e0b'))
				win.gg_ctx.draw_text2(
					x:     int(ctrl.x + 10)
					y:     int(ctrl.y + 8)
					text:  ctrl.title
					color: parse_hex_color('#92400e')
					size:  14
				)
			}
			'breadcrumbs', 'step_tracker', 'timeline' {
				win.gg_ctx.draw_text2(
					x:     int(ctrl.x)
					y:     int(ctrl.y + 4)
					text:  ctrl.title
					color: fg
					size:  13
				)
			}
			'group_start' {
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 8.0,
					border_c)
				if ctrl.title.len > 0 {
					win.gg_ctx.draw_rect_filled(ctrl.x + 12, ctrl.y - 2, f32(ctrl.title.len * 8 + 8),
						18.0, bg)
					win.gg_ctx.draw_text2(
						x:     int(ctrl.x + 16)
						y:     int(ctrl.y - 2)
						text:  ctrl.title
						color: accent
						size:  13
					)
				}
			}
			'separator' {
				win.gg_ctx.draw_line(ctrl.x, ctrl.y + 1, ctrl.x + ctrl.w, ctrl.y + 1,
					border_c)
			}
			'tag_input' {
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0, surface)
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0, if ctrl.is_focused { accent } else { border_c })
				mut cur_x := ctrl.x + 6.0
				cur_y := ctrl.y + 5.0
				for tag in ctrl.tags {
					tag_w := f32(tag.len * 7 + 22)
					if cur_x + tag_w > ctrl.x + ctrl.w - 10.0 {
						break
					}
					win.gg_ctx.draw_rounded_rect_filled(cur_x, cur_y, tag_w, 24.0, 4.0, accent)
					win.gg_ctx.draw_text2(x: int(cur_x + 6), y: int(cur_y + 4), text: tag, color: gg.Color{r: 255, g: 255, b: 255}, size: 12)
					win.gg_ctx.draw_text2(x: int(cur_x + tag_w - 14), y: int(cur_y + 4), text: 'x', color: gg.Color{r: 255, g: 200, b: 200}, size: 12)
					cur_x += tag_w + 6.0
				}
				if cur_x < ctrl.x + ctrl.w - 20.0 {
					inp_txt := if ctrl.text_value.len > 0 { ctrl.text_value } else { if ctrl.tags.len == 0 { 'Add tag...' } else { '' } }
					txt_color := if ctrl.text_value.len > 0 { fg } else { border_c }
					win.gg_ctx.draw_text2(x: int(cur_x), y: int(cur_y + 4), text: inp_txt, color: txt_color, size: 12)
				}
			}
			'range_slider' {
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y + 12.0, ctrl.w, 6.0, 3.0, surface)
				range_w := ctrl.max_val - ctrl.min_val
				if range_w > 0 {
					min_pct := f32((ctrl.range_min - ctrl.min_val) / range_w)
					max_pct := f32((ctrl.range_max - ctrl.min_val) / range_w)
					fill_x1 := ctrl.x + min_pct * ctrl.w
					fill_x2 := ctrl.x + max_pct * ctrl.w
					win.gg_ctx.draw_rounded_rect_filled(fill_x1, ctrl.y + 12.0, math.max(f32(4.0), fill_x2 - fill_x1), 6.0, 3.0, accent)
					
					win.gg_ctx.draw_rounded_rect_filled(fill_x1 - 7.0, ctrl.y + 5.0, 14.0, 20.0, 4.0, if ctrl.is_dragging_min { fg } else { accent })
					win.gg_ctx.draw_rounded_rect_filled(fill_x2 - 7.0, ctrl.y + 5.0, 14.0, 20.0, 4.0, if ctrl.is_dragging_max { fg } else { accent })
				}
				win.gg_ctx.draw_text2(x: int(ctrl.x), y: int(ctrl.y + 26.0), text: '${int(ctrl.range_min)} - ${int(ctrl.range_max)}', color: fg, size: 11)
			}
			'code_editor' {
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0, gg.rgb(30, 32, 44))
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0, border_c)
				win.gg_ctx.draw_rect_filled(ctrl.x, ctrl.y, 36.0, ctrl.h, gg.rgb(20, 22, 30))
				win.gg_ctx.draw_line(ctrl.x + 36.0, ctrl.y, ctrl.x + 36.0, ctrl.y + ctrl.h, border_c)

				lines := ctrl.text_value.split('\n')
				for i, line in lines {
					if i * 18 > int(ctrl.h - 10) { break }
					line_y := ctrl.y + f32(i * 18 + 6)
					win.gg_ctx.draw_text2(x: int(ctrl.x + 8), y: int(line_y), text: '${i + 1}', color: gg.rgb(100, 105, 125), size: 11)
					
					words := line.split(' ')
					mut word_x := ctrl.x + 44.0
					for w in words {
						w_color := if w in ['fn', 'mut', 'struct', 'return', 'if', 'else', 'pub', 'import', 'string', 'int', 'f64', 'bool', 'true', 'false', 'type'] {
							gg.rgb(189, 147, 249)
						} else {
							gg.rgb(248, 248, 242)
						}
						win.gg_ctx.draw_text2(x: int(word_x), y: int(line_y), text: w + ' ', color: w_color, size: 12)
						word_x += f32((w.len + 1) * 7)
					}
				}
			}
			'drop_zone' {
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 8.0, surface)
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 8.0, if ctrl.is_hovered { accent } else { border_c })
				
				prompt := if ctrl.placeholder.len > 0 { ctrl.placeholder } else { 'Drag & Drop files here or Click to Browse' }
				win.gg_ctx.draw_text2(x: int(ctrl.x + (ctrl.w - f32(prompt.len * 7)) / 2.0), y: int(ctrl.y + ctrl.h / 2.0 - 10.0), text: prompt, color: accent, size: 13)
				if ctrl.items.len > 0 {
					win.gg_ctx.draw_text2(x: int(ctrl.x + 10), y: int(ctrl.y + ctrl.h - 20.0), text: 'Files: ${ctrl.items.len} selected', color: fg, size: 11)
				}
			}
			'property_grid' {
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0, surface)
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0, border_c)
				
				win.gg_ctx.draw_rect_filled(ctrl.x, ctrl.y, ctrl.w, 24.0, gg.rgb(45, 48, 60))
				win.gg_ctx.draw_text2(x: int(ctrl.x + 10), y: int(ctrl.y + 4), text: 'Property', color: fg, size: 12)
				win.gg_ctx.draw_text2(x: int(ctrl.x + ctrl.w / 2.0 + 10), y: int(ctrl.y + 4), text: 'Value', color: fg, size: 12)
				win.gg_ctx.draw_line(ctrl.x + ctrl.w / 2.0, ctrl.y, ctrl.x + ctrl.w / 2.0, ctrl.y + ctrl.h, border_c)

				for idx, item in ctrl.property_items {
					row_y := ctrl.y + f32(idx * 28 + 28)
					if row_y + 24 > ctrl.y + ctrl.h { break }
					win.gg_ctx.draw_line(ctrl.x, row_y, ctrl.x + ctrl.w, row_y, border_c)
					win.gg_ctx.draw_text2(x: int(ctrl.x + 10), y: int(row_y + 6), text: item.name, color: fg, size: 12)

					val_x := ctrl.x + ctrl.w / 2.0 + 10.0
					match item.kind {
						'bool' {
							b_txt := if item.val == 'true' { '[ON]' } else { '[OFF]' }
							b_c := if item.val == 'true' { accent } else { border_c }
							win.gg_ctx.draw_text2(x: int(val_x), y: int(row_y + 6), text: b_txt, color: b_c, size: 12)
						}
						'color' {
							c_box := parse_hex_color(if item.val.len > 0 { item.val } else { '#3b82f6' })
							win.gg_ctx.draw_rounded_rect_filled(val_x, row_y + 5.0, 16.0, 16.0, 3.0, c_box)
							win.gg_ctx.draw_text2(x: int(val_x + 22), y: int(row_y + 6), text: item.val, color: fg, size: 12)
						}
						else {
							win.gg_ctx.draw_text2(x: int(val_x), y: int(row_y + 6), text: item.val, color: fg, size: 12)
						}
					}
				}
			}
			'pagination' {
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0, surface)
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0, border_c)
				
				page_info := 'Page ${ctrl.current_page} of ${ctrl.total_pages}'
				win.gg_ctx.draw_text2(x: int(ctrl.x + 12), y: int(ctrl.y + 9), text: page_info, color: fg, size: 13)

				btn_w := f32(40.0)
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x + ctrl.w - 90, ctrl.y + 4, btn_w, 28.0, 4.0, accent)
				win.gg_ctx.draw_text2(x: int(ctrl.x + ctrl.w - 82), y: int(ctrl.y + 9), text: '< Prev', color: gg.Color{r: 255, g: 255, b: 255}, size: 11)

				win.gg_ctx.draw_rounded_rect_filled(ctrl.x + ctrl.w - 44, ctrl.y + 4, btn_w, 28.0, 4.0, accent)
				win.gg_ctx.draw_text2(x: int(ctrl.x + ctrl.w - 38), y: int(ctrl.y + 9), text: 'Next >', color: gg.Color{r: 255, g: 255, b: 255}, size: 11)
			}
			'combobox' {
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, 32.0, 6.0, surface)
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, ctrl.w, 32.0, 6.0, border_c)
				val_str := if ctrl.text_value.len > 0 { ctrl.text_value } else { ctrl.placeholder }
				win.gg_ctx.draw_text2(x: int(ctrl.x + 10), y: int(ctrl.y + 8), text: val_str, color: fg, size: 12)
				win.gg_ctx.draw_text2(x: int(ctrl.x + ctrl.w - 20), y: int(ctrl.y + 8), text: '▼', color: accent, size: 10)

				if ctrl.is_expanded {
					pop_h := f32(math.min(150, ctrl.items.len * 26 + 8))
					pop_y := ctrl.y + 34.0
					win.gg_ctx.draw_rounded_rect_filled(ctrl.x, pop_y, ctrl.w, pop_h, 6.0, surface)
					win.gg_ctx.draw_rounded_rect_empty(ctrl.x, pop_y, ctrl.w, pop_h, 6.0, accent)
					mut opt_y := pop_y + 4.0
					for item in ctrl.items {
						if opt_y + 24.0 > pop_y + pop_h { break }
						is_sel := item == ctrl.text_value
						if is_sel {
							win.gg_ctx.draw_rounded_rect_filled(ctrl.x + 2, opt_y, ctrl.w - 4, 22.0, 4.0, accent)
						}
						win.gg_ctx.draw_text2(x: int(ctrl.x + 8), y: int(opt_y + 3), text: item, color: if is_sel { gg.Color{r: 255, g: 255, b: 255} } else { fg }, size: 12)
						opt_y += 26.0
					}
				}
			}
			'status_bar' {
				bar_h := if ctrl.h > 0 { ctrl.h } else { 26.0 }
				win.gg_ctx.draw_rect_filled(ctrl.x, ctrl.y, ctrl.w, bar_h, surface)
				win.gg_ctx.draw_line(ctrl.x, ctrl.y, ctrl.x + ctrl.w, ctrl.y, border_c)
				status_txt := if ctrl.text_value.len > 0 { ctrl.text_value } else { 'Ready' }
				win.gg_ctx.draw_text2(x: int(ctrl.x + 10), y: int(ctrl.y + 5), text: status_txt, color: fg, size: 11)
				if ctrl.placeholder.len > 0 {
					win.gg_ctx.draw_rounded_rect_filled(ctrl.x + ctrl.w - 90, ctrl.y + 3, 80.0, 20.0, 4.0, accent)
					win.gg_ctx.draw_text2(x: int(ctrl.x + ctrl.w - 82), y: int(ctrl.y + 5), text: ctrl.placeholder, color: gg.Color{r: 255, g: 255, b: 255}, size: 10)
				}
			}
			'step_slider' {
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0, surface)
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0, border_c)
				
				track_y := ctrl.y + ctrl.h / 2.0
				track_w := ctrl.w - 30.0
				track_x := ctrl.x + 15.0
				win.gg_ctx.draw_line(track_x, track_y, track_x + track_w, track_y, border_c)

				steps := if ctrl.int_value > 0 { ctrl.int_value } else { 4 }
				for i in 0 .. (steps + 1) {
					tx := track_x + f32(i) * (track_w / f32(steps))
					win.gg_ctx.draw_line(tx, track_y - 4, tx, track_y + 4, accent)
				}

				pct := f32(ctrl.f64_value / 100.0)
				knob_x := track_x + pct * track_w
				win.gg_ctx.draw_line(track_x, track_y, knob_x, track_y, accent)
				win.gg_ctx.draw_rounded_rect_filled(knob_x - 6.0, track_y - 6.0, 12.0, 12.0, 6.0, accent)
				val_txt := '${int(ctrl.f64_value)}%'
				win.gg_ctx.draw_text2(x: int(ctrl.x + ctrl.w - 30), y: int(ctrl.y + 6), text: val_txt, color: fg, size: 10)
			}
			'transfer_list' {
				box_w := (ctrl.w - 60.0) / 2.0
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, box_w, ctrl.h, 6.0, surface)
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, box_w, ctrl.h, 6.0, border_c)
				win.gg_ctx.draw_text2(x: int(ctrl.x + 8), y: int(ctrl.y + 6), text: 'Available (${ctrl.items.len})', color: accent, size: 11)
				win.gg_ctx.draw_line(ctrl.x, ctrl.y + 22, ctrl.x + box_w, ctrl.y + 22, border_c)
				mut ly := ctrl.y + 26.0
				for item in ctrl.items {
					if ly + 22.0 > ctrl.y + ctrl.h { break }
					win.gg_ctx.draw_text2(x: int(ctrl.x + 10), y: int(ly + 2), text: item, color: fg, size: 11)
					ly += 24.0
				}

				btn_x := ctrl.x + box_w + 10.0
				win.gg_ctx.draw_rounded_rect_filled(btn_x, ctrl.y + 10, 40.0, 28.0, 4.0, accent)
				win.gg_ctx.draw_text2(x: int(btn_x + 15), y: int(ctrl.y + 16), text: '>', color: gg.Color{r: 255, g: 255, b: 255}, size: 14)

				win.gg_ctx.draw_rounded_rect_filled(btn_x, ctrl.y + 44, 40.0, 28.0, 4.0, accent)
				win.gg_ctx.draw_text2(x: int(btn_x + 15), y: int(ctrl.y + 50), text: '<', color: gg.Color{r: 255, g: 255, b: 255}, size: 14)

				win.gg_ctx.draw_rounded_rect_filled(btn_x, ctrl.y + 78, 40.0, 28.0, 4.0, accent)
				win.gg_ctx.draw_text2(x: int(btn_x + 12), y: int(ctrl.y + 84), text: '>>', color: gg.Color{r: 255, g: 255, b: 255}, size: 12)

				rx := ctrl.x + box_w + 60.0
				win.gg_ctx.draw_rounded_rect_filled(rx, ctrl.y, box_w, ctrl.h, 6.0, surface)
				win.gg_ctx.draw_rounded_rect_empty(rx, ctrl.y, box_w, ctrl.h, 6.0, border_c)
				win.gg_ctx.draw_text2(x: int(rx + 8), y: int(ctrl.y + 6), text: 'Selected (${ctrl.items_selected.len})', color: accent, size: 11)
				win.gg_ctx.draw_line(rx, ctrl.y + 22, rx + box_w, ctrl.y + 22, border_c)
				mut ry := ctrl.y + 26.0
				for item in ctrl.items_selected {
					if ry + 22.0 > ctrl.y + ctrl.h { break }
					win.gg_ctx.draw_text2(x: int(rx + 10), y: int(ry + 2), text: item, color: fg, size: 11)
					ry += 24.0
				}
			}
			'console_view' {
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0, gg.rgb(20, 22, 30))
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0, border_c)
				win.gg_ctx.draw_rect_filled(ctrl.x, ctrl.y, ctrl.w, 22.0, gg.rgb(32, 35, 48))
				win.gg_ctx.draw_text2(x: int(ctrl.x + 8), y: int(ctrl.y + 4), text: 'Console Output Log', color: fg, size: 11)
				
				mut log_y := ctrl.y + 26.0
				for idx, line in ctrl.items {
					if log_y + 20.0 > ctrl.y + ctrl.h { break }
					line_c := if line.contains('[ERR]') {
						gg.rgb(248, 113, 113)
					} else if line.contains('[WARN]') {
						gg.rgb(251, 191, 36)
					} else if line.contains('[OK]') || line.contains('[SUCCESS]') {
						gg.rgb(52, 211, 153)
					} else {
						gg.rgb(209, 213, 219)
					}
					win.gg_ctx.draw_text2(x: int(ctrl.x + 10), y: int(log_y), text: '${idx + 1:2d} | ${line}', color: line_c, size: 11)
					log_y += 20.0
				}
			}
			else {}
		}
	}

	if win.toast_title.len > 0 || win.toast_message.len > 0 {
		t_w := f32(260.0)
		t_h := f32(50.0)
		tx := f32(win.width) - t_w - 16.0
		ty := f32(win.height) - t_h - 32.0
		win.gg_ctx.draw_rounded_rect_filled(tx, ty, t_w, t_h, 8.0, accent)
		win.gg_ctx.draw_text2(
			x:     int(tx + 12)
			y:     int(ty + 8)
			text:  win.toast_title
			color: gg.Color{
				r: 255
				g: 255
				b: 255
			}
			size:  13
		)
		win.gg_ctx.draw_text2(
			x:     int(tx + 12)
			y:     int(ty + 26)
			text:  win.toast_message
			color: gg.Color{
				r: 230
				g: 230
				b: 250
			}
			size:  12
		)
	}

	if win.debug_mode || win.status_text.len > 0 {
		footer_y := f32(win.height - 24)
		win.gg_ctx.draw_rect_filled(0, footer_y, f32(win.width), 24.0, surface)
		win.gg_ctx.draw_line(0, footer_y, f32(win.width), footer_y, border_c)
		st_text := if win.status_text.len > 0 {
			win.status_text
		} else {
			'Debug Mode Active | Controls: ${win.controls.len}'
		}
		win.gg_ctx.draw_text2(x: 10, y: int(footer_y + 4), text: st_text, color: fg, size: 12)
	}

	win.render_toasts()
	win.render_modal()
	win.render_tooltip()
	win.render_command_palette()
	win.render_context_menu()
}

fn (mut win SimpleWindow) render_toasts() {
	if win.toasts.len == 0 { return }
	mut active_toasts := []Toast{}
	mut ty := f32(20.0)

	for mut toast in win.toasts {
		toast.remaining -= 0.016
		if toast.remaining <= 0 {
			continue
		}

		t_w := f32(280.0)
		t_h := f32(54.0)
		tx := f32(win.width) - t_w - 20.0
		
		t_color := match toast.variant {
			'success' { parse_hex_color('#10b981') }
			'warning' { parse_hex_color('#f59e0b') }
			'error' { parse_hex_color('#ef4444') }
			else { parse_hex_color('#3b82f6') }
		}

		win.gg_ctx.draw_rounded_rect_filled(tx, ty, t_w, t_h, 8.0, gg.rgb(35, 38, 48))
		win.gg_ctx.draw_rounded_rect_empty(tx, ty, t_w, t_h, 8.0, t_color)
		win.gg_ctx.draw_rect_filled(tx, ty, 6.0, t_h, t_color)

		win.gg_ctx.draw_text2(x: int(tx + 16), y: int(ty + 8), text: toast.title, color: gg.Color{r: 255, g: 255, b: 255}, size: 13)
		win.gg_ctx.draw_text2(x: int(tx + 16), y: int(ty + 28), text: toast.message, color: gg.rgb(200, 205, 215), size: 12)
		win.gg_ctx.draw_text2(x: int(tx + t_w - 20), y: int(ty + 6), text: 'x', color: gg.rgb(180, 185, 200), size: 13)

		active_toasts << toast
		ty += t_h + 10.0
	}

	win.toasts = active_toasts
}

fn (mut win SimpleWindow) render_command_palette() {
	if !win.command_palette_active { return }
	win.gg_ctx.draw_rect_filled(0, 0, f32(win.width), f32(win.height), gg.rgba(0, 0, 0, 160))

	box_w := f32(math.min(500, win.width - 40))
	box_h := f32(300.0)
	bx := (f32(win.width) - box_w) / 2.0
	by := f32(80.0)

	win.gg_ctx.draw_rounded_rect_filled(bx, by, box_w, box_h, 10.0, gg.rgb(30, 32, 44))
	win.gg_ctx.draw_rounded_rect_empty(bx, by, box_w, box_h, 10.0, parse_hex_color(win.theme.accent_color))

	win.gg_ctx.draw_text2(x: int(bx + 16), y: int(by + 16), text: 'Find: ${win.command_palette_query}_', color: gg.Color{r: 255, g: 255, b: 255}, size: 15)
	win.gg_ctx.draw_line(bx, by + 48, bx + box_w, by + 48, gg.rgb(60, 64, 80))

	mut item_y := by + 56.0
	for idx, item in win.command_palette_items {
		if win.command_palette_query.len > 0 && !item.title.to_lower().contains(win.command_palette_query.to_lower()) {
			continue
		}
		if item_y + 32.0 > by + box_h { break }

		if idx == win.command_palette_sel {
			win.gg_ctx.draw_rounded_rect_filled(bx + 8, item_y, box_w - 16, 28.0, 4.0, parse_hex_color(win.theme.accent_color))
		}
		win.gg_ctx.draw_text2(x: int(bx + 20), y: int(item_y + 6), text: item.title, color: gg.Color{r: 255, g: 255, b: 255}, size: 13)
		if item.shortcut.len > 0 {
			win.gg_ctx.draw_text2(x: int(bx + box_w - 80), y: int(item_y + 6), text: item.shortcut, color: gg.rgb(180, 185, 200), size: 11)
		}
		item_y += 32.0
	}
}

fn (mut win SimpleWindow) render_context_menu() {
	if !win.context_menu_active { return }
	menu_w := f32(180.0)
	menu_h := f32(win.context_menu_items.len * 30 + 10)
	mx := win.context_menu_x
	my := win.context_menu_y

	win.gg_ctx.draw_rounded_rect_filled(mx, my, menu_w, menu_h, 6.0, gg.rgb(35, 38, 50))
	win.gg_ctx.draw_rounded_rect_empty(mx, my, menu_w, menu_h, 6.0, parse_hex_color(win.theme.accent_color))

	for idx, item in win.context_menu_items {
		iy := my + f32(idx * 30 + 5)
		win.gg_ctx.draw_text2(x: int(mx + 12), y: int(iy + 6), text: item.title, color: gg.Color{r: 255, g: 255, b: 255}, size: 13)
		if item.shortcut.len > 0 {
			win.gg_ctx.draw_text2(x: int(mx + menu_w - 60), y: int(iy + 6), text: item.shortcut, color: gg.rgb(160, 165, 180), size: 11)
		}
	}
}

// table_header_height returns the header band height, or 0 when the table has no headers.
fn table_header_height(ctrl &Control) f32 {
	return if ctrl.headers.len > 0 { f32(28.0) } else { f32(0.0) }
}

// table_content_height returns the total pixel height of all data rows.
fn table_content_height(ctrl &Control) f32 {
	return f32(ctrl.rows.len) * 26.0
}

// calc_table_col_widths distributes column widths proportional to their widest cell content.
fn calc_table_col_widths(ctrl &Control) []f32 {
	col_cnt := if ctrl.headers.len > 0 {
		ctrl.headers.len
	} else {
		if ctrl.rows.len > 0 { ctrl.rows[0].len } else { 1 }
	}
	mut col_widths := []f32{}
	if col_cnt > 0 {
		mut weights := []f32{len: col_cnt, init: 1.0}
		for c_idx in 0 .. col_cnt {
			mut max_l := 4
			if c_idx < ctrl.headers.len && ctrl.headers[c_idx].len > max_l {
				max_l = ctrl.headers[c_idx].len
			}
			for row in ctrl.rows {
				if c_idx < row.len && row[c_idx].len > max_l {
					max_l = row[c_idx].len
				}
			}
			weights[c_idx] = f32(max_l)
		}

		mut tot_w := f32(0.0)
		for w_val in weights {
			tot_w += w_val
		}
		if tot_w <= 0 {
			tot_w = 1.0
		}

		for w_val in weights {
			col_widths << (w_val / tot_w) * ctrl.w
		}
	}
	return col_widths
}

fn (mut win SimpleWindow) render_modal() {
	if !win.modal_active { return }
	win.gg_ctx.draw_rect_filled(0, 0, f32(win.width), f32(win.height), gg.rgba(0, 0, 0, 160))

	box_w := f32(math.min(460, win.width - 40))
	box_h := f32(180.0)
	bx := (f32(win.width) - box_w) / 2.0
	by := (f32(win.height) - box_h) / 2.0

	modal_bg := if win.theme.is_dark { gg.rgb(28, 30, 42) } else { gg.rgb(255, 255, 255) }
	accent := parse_hex_color(win.theme.accent_color)
	fg := parse_hex_color(win.theme.font_color)
	border_c := if win.theme.is_dark { gg.rgb(65, 68, 82) } else { gg.rgb(210, 215, 220) }

	win.gg_ctx.draw_rounded_rect_filled(bx, by, box_w, box_h, 12.0, modal_bg)
	win.gg_ctx.draw_rounded_rect_empty(bx, by, box_w, box_h, 12.0, accent)

	win.gg_ctx.draw_text2(x: int(bx + 20), y: int(by + 16), text: win.modal_title, color: fg, size: 16)
	win.gg_ctx.draw_line(bx, by + 46, bx + box_w, by + 46, border_c)

	win.gg_ctx.draw_text2(x: int(bx + 20), y: int(by + 62), text: win.modal_message, color: fg, size: 13)

	btn_w := f32(100.0)
	btn_h := f32(36.0)
	confirm_x := bx + box_w - btn_w - 20.0
	cancel_x := confirm_x - btn_w - 12.0
	btn_y := by + box_h - btn_h - 18.0

	if win.modal_cancel_txt.len > 0 {
		win.gg_ctx.draw_rounded_rect_filled(cancel_x, btn_y, btn_w, btn_h, 6.0, border_c)
		win.gg_ctx.draw_text2(
			x: int(cancel_x + (btn_w - f32(win.modal_cancel_txt.len * 7)) / 2.0)
			y: int(btn_y + 10)
			text: win.modal_cancel_txt
			color: fg
			size: 13
		)
	}

	win.gg_ctx.draw_rounded_rect_filled(confirm_x, btn_y, btn_w, btn_h, 6.0, accent)
	win.gg_ctx.draw_text2(
		x: int(confirm_x + (btn_w - f32(win.modal_confirm_txt.len * 7)) / 2.0)
		y: int(btn_y + 10)
		text: win.modal_confirm_txt
		color: gg.rgb(255, 255, 255)
		size: 13
	)
}

fn (mut win SimpleWindow) render_tooltip() {
	if win.hovered_control.len == 0 { return }
	for ctrl in win.controls {
		if ctrl.name == win.hovered_control {
			if ctrl.tooltip.len > 0 {
				tip_w := f32(ctrl.tooltip.len * 7 + 20)
				tip_h := f32(26.0)
				tx := math.min(f32(win.width) - tip_w - 10.0, f32(win.mouse_x + 12))
				ty := math.min(f32(win.height) - tip_h - 10.0, f32(win.mouse_y + 16))

				tip_bg := gg.rgb(20, 22, 30)
				border_c := parse_hex_color(win.theme.accent_color)

				win.gg_ctx.draw_rounded_rect_filled(tx, ty, tip_w, tip_h, 6.0, tip_bg)
				win.gg_ctx.draw_rounded_rect_empty(tx, ty, tip_w, tip_h, 6.0, border_c)
				win.gg_ctx.draw_text2(
					x: int(tx + 10)
					y: int(ty + 5)
					text: ctrl.tooltip
					color: gg.rgb(255, 255, 255)
					size: 12
				)
			}
			break
		}
	}
}

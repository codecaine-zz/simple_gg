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

	// Step 0: Process scheduled interval and timeout timers
	win.process_timers()

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
				lbl_txt := clean_text(if ctrl.text_value.len > 0 { ctrl.text_value } else { ctrl.title })
				lbl_sz := if ctrl.font_size > 0 { ctrl.font_size } else { 15 }
				is_mono := ctrl.font_name.len > 0 && (ctrl.font_name.to_lower().contains('mono') || ctrl.font_name.to_lower().contains('courier'))
				win.gg_ctx.draw_text2(
					x:     int(ctrl.x)
					y:     int(ctrl.y + 4)
					text:  lbl_txt
					color: txt_c
					size:  lbl_sz
					bold:  ctrl.font_bold
					mono:  is_mono
				)
			}
			'heading' {
				txt_c := if ctrl.font_color.len > 0 { parse_hex_color(ctrl.font_color) } else { fg }
				hd_txt := clean_text(if ctrl.text_value.len > 0 { ctrl.text_value } else { ctrl.title })
				hd_sz := if ctrl.font_size > 0 { ctrl.font_size } else { 22 }
				is_mono := ctrl.font_name.len > 0 && (ctrl.font_name.to_lower().contains('mono') || ctrl.font_name.to_lower().contains('courier'))
				win.gg_ctx.draw_text2(
					x:     int(ctrl.x)
					y:     int(ctrl.y)
					text:  hd_txt
					color: txt_c
					size:  hd_sz
					bold:  ctrl.font_bold
					mono:  is_mono
				)
				win.gg_ctx.draw_line(ctrl.x, ctrl.y + 28, ctrl.x + ctrl.w, ctrl.y + 28,
					border_c)
			}
			'link' {
				link_txt := if ctrl.text_value.len > 0 { ctrl.text_value } else { ctrl.title }
				lnk_sz := if ctrl.font_size > 0 { ctrl.font_size } else { 14 }
				is_mono := ctrl.font_name.len > 0 && (ctrl.font_name.to_lower().contains('mono') || ctrl.font_name.to_lower().contains('courier'))
				win.gg_ctx.draw_text2(
					x:     int(ctrl.x)
					y:     int(ctrl.y + 4)
					text:  link_txt
					color: accent
					size:  lnk_sz
					bold:  ctrl.font_bold
					mono:  is_mono
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

				has_btn_icon := ctrl.icon_path.len > 0
				btn_icon_sz := if has_btn_icon { f32(math.min(ctrl.h - 10.0, 20.0)) } else { f32(0.0) }
				if has_btn_icon {
					icon_x := ctrl.x + 10.0
					icon_y := ctrl.y + (ctrl.h - btn_icon_sz) / 2.0
					win.draw_image_fit(ctrl.icon_path, icon_x, icon_y, btn_icon_sz, btn_icon_sz, '')
				}

				btn_sz := if ctrl.font_size > 0 { ctrl.font_size } else { 14 }
				btn_tc := if ctrl.font_color.len > 0 {
					parse_hex_color(ctrl.font_color)
				} else {
					gg.Color{ r: 255, g: 255, b: 255 }
				}

				btn_icon_offset := if has_btn_icon { btn_icon_sz + 8.0 } else { f32(0.0) }
				max_chars := math.max(1, int((ctrl.w - 16.0 - btn_icon_offset) / (f32(btn_sz) * 0.55)))
				raw_title := clean_text(ctrl.title)
				disp_title := if raw_title.len > max_chars && max_chars > 3 {
					raw_title[0..max_chars - 3] + '...'
				} else {
					raw_title
				}

				text_w := f32(disp_title.len) * (f32(btn_sz) * 0.55)
				text_x := int(ctrl.x + btn_icon_offset + (ctrl.w - btn_icon_offset - text_w) / 2.0)
				text_y := int(ctrl.y + (ctrl.h - f32(btn_sz)) / 2.0)

				is_mono := ctrl.font_name.len > 0 && (ctrl.font_name.to_lower().contains('mono') || ctrl.font_name.to_lower().contains('courier'))
				win.gg_ctx.draw_text2(
					x:     math.max(int(ctrl.x + 8 + btn_icon_offset), text_x)
					y:     text_y
					text:  disp_title
					color: btn_tc
					size:  btn_sz
					bold:  ctrl.font_bold
					mono:  is_mono
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

				ib_sz := if ctrl.font_size > 0 { ctrl.font_size } else { 15 }
				icon_c := if ctrl.font_color.len > 0 {
					parse_hex_color(ctrl.font_color)
				} else if ctrl.is_hovered {
					accent
				} else {
					fg
				}
				txt_w := f32(ctrl.title.len) * (f32(ib_sz) * 0.55)
				is_mono := ctrl.font_name.len > 0 && (ctrl.font_name.to_lower().contains('mono') || ctrl.font_name.to_lower().contains('courier'))
				win.gg_ctx.draw_text2(
					x:     int(ctrl.x + (ctrl.w - txt_w) / 2.0)
					y:     int(ctrl.y + (ctrl.h - f32(ib_sz)) / 2.0)
					text:  ctrl.title
					color: icon_c
					size:  ib_sz
					bold:  ctrl.font_bold
					mono:  is_mono
				)
			}
			'input', 'password', 'search_field', 'pin_code', 'number', 'time_picker', 'date_picker' {
				in_bg := if ctrl.is_hovered { surface_hover } else { surface }
				b_c := if ctrl.is_focused { accent } else if ctrl.is_hovered { hover_c } else { border_c }

				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0,
					in_bg)
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0,
					b_c)

				has_in_icon := ctrl.icon_path.len > 0
				in_icon_sz := if has_in_icon { f32(math.min(ctrl.h - 12.0, 18.0)) } else { f32(0.0) }
				if has_in_icon {
					win.draw_image_fit(ctrl.icon_path, ctrl.x + 8.0, ctrl.y + (ctrl.h - in_icon_sz) / 2.0, in_icon_sz, in_icon_sz, '')
				}
				in_offset_x := if has_in_icon { in_icon_sz + 8.0 } else { f32(0.0) }

				if ctrl.kind == 'time_picker' {
					draw_vector_clock_icon(win.gg_ctx, ctrl.x + ctrl.w - 18.0, ctrl.y + ctrl.h / 2.0, 5.0, fg)
				}
				if ctrl.kind == 'date_picker' {
					draw_vector_calendar_icon(win.gg_ctx, ctrl.x + ctrl.w - 24.0, ctrl.y + (ctrl.h - 14.0) / 2.0, fg)
				}
				if ctrl.kind == 'number' {
					up_x := ctrl.x + ctrl.w - 18.0
					draw_vector_chevron(win.gg_ctx, up_x, ctrl.y + 8.0, 4.0, 'up', fg)
					draw_vector_chevron(win.gg_ctx, up_x, ctrl.y + 20.0, 4.0, 'down', fg)
				}

				display_txt := if ctrl.kind == 'password' {
					'*'.repeat(ctrl.text_value.len)
				} else if ctrl.kind == 'number' {
					'${ctrl.int_value}'
				} else if ctrl.text_value.len == 0 && ctrl.placeholder.len > 0 {
					ctrl.placeholder
				} else if ctrl.text_value.len == 0 && ctrl.kind == 'date_picker' {
					'YYYY-MM-DD'
				} else {
					ctrl.text_value
				}

				inp_sz := if ctrl.font_size > 0 { ctrl.font_size } else { 14 }
				txt_color := if ctrl.font_color.len > 0 {
					parse_hex_color(ctrl.font_color)
				} else if ctrl.text_value.len == 0 && ctrl.placeholder.len > 0 {
					gg.Color{
						r: 128
						g: 128
						b: 128
					}
				} else {
					fg
				}

				max_in_chars := math.max(1, int((ctrl.w - 24.0 - in_offset_x) / (f32(inp_sz) * 0.55)))
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

				if ctrl.has_selection() {
					s_raw, e_raw := ctrl.selection_range()
					vis_s := math.max(0, math.min(clipped_txt.len, s_raw - start_idx))
					vis_e := math.max(0, math.min(clipped_txt.len, e_raw - start_idx))
					if vis_s < vis_e {
						prefix_s := clipped_txt[0..vis_s]
						prefix_e := clipped_txt[0..vis_e]
						sel_x1 := ctrl.x + 10.0 + in_offset_x + f32(win.gg_ctx.text_width(prefix_s))
						sel_x2 := ctrl.x + 10.0 + in_offset_x + f32(win.gg_ctx.text_width(prefix_e))
						sel_w := sel_x2 - sel_x1
						if sel_w > 0 {
							win.gg_ctx.draw_rect_filled(sel_x1, ctrl.y + 4.0, sel_w, ctrl.h - 8.0,
								gg.Color{r: 59, g: 130, b: 246, a: 120})
						}
					}
				}

				is_mono := ctrl.font_name.len > 0 && (ctrl.font_name.to_lower().contains('mono') || ctrl.font_name.to_lower().contains('courier'))
				win.gg_ctx.draw_text2(
					x:     int(ctrl.x + 10 + in_offset_x)
					y:     int(ctrl.y + (ctrl.h - f32(inp_sz)) / 2.0)
					text:  clipped_txt
					color: txt_color
					size:  inp_sz
					bold:  ctrl.font_bold
					mono:  is_mono
				)

				if ctrl.is_focused {
					visible_caret_pos := math.max(0, math.min(clipped_txt.len, ctrl.caret_pos - start_idx))
					prefix_txt := if visible_caret_pos <= clipped_txt.len {
						clipped_txt[0..visible_caret_pos]
					} else {
						clipped_txt
					}
					caret_offset_x := f32(win.gg_ctx.text_width(prefix_txt))
					caret_x := ctrl.x + 10.0 + in_offset_x + caret_offset_x
					win.gg_ctx.draw_line(caret_x, ctrl.y + 6, caret_x, ctrl.y + ctrl.h - 6,
						accent)
				}

				if ctrl.kind == 'number' {
					up_x := ctrl.x + ctrl.w - 18.0
					draw_vector_chevron(win.gg_ctx, up_x, ctrl.y + 8.0, 4.0, 'up', fg)
					draw_vector_chevron(win.gg_ctx, up_x, ctrl.y + 20.0, 4.0, 'down', fg)
				}
			}
			'textarea', 'console', 'code', 'markdown' {
				ta_bg := if ctrl.is_hovered { surface_hover } else { surface }
				ta_bc := if ctrl.is_focused { accent } else if ctrl.is_hovered { hover_c } else { border_c }
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0,
					ta_bg)
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0,
					ta_bc)

				lines := ctrl.text_value.split('\n')
				mut line_y := ctrl.y + 8.0
				txt_sz := if ctrl.font_size > 0 { ctrl.font_size } else { 13 }
				txt_c := if ctrl.font_color.len > 0 { parse_hex_color(ctrl.font_color) } else { fg }
				line_h := f32(txt_sz + 4)

				if ctrl.has_selection() {
					s_raw, e_raw := ctrl.selection_range()
					mut line_start_idx := 0
					for i, line in lines {
						curr_line_y := ctrl.y + 8.0 + f32(i) * line_h
						if curr_line_y + line_h > ctrl.y + ctrl.h - 4.0 {
							break
						}
						line_end_idx := line_start_idx + line.len
						vis_s := math.max(line_start_idx, s_raw) - line_start_idx
						vis_e := math.min(line_end_idx, e_raw) - line_start_idx
						if vis_s < vis_e && vis_s <= line.len {
							prefix_s := line[0..vis_s]
							prefix_e := line[0..vis_e]
							sel_x1 := ctrl.x + 10.0 + f32(win.gg_ctx.text_width(prefix_s))
							sel_x2 := ctrl.x + 10.0 + f32(win.gg_ctx.text_width(prefix_e))
							mut sel_w := sel_x2 - sel_x1
							if e_raw > line_end_idx {
								sel_w += 6.0
							}
							if sel_w > 0 {
								win.gg_ctx.draw_rect_filled(sel_x1, curr_line_y, sel_w, line_h,
									gg.Color{r: 59, g: 130, b: 246, a: 120})
							}
						} else if vis_s == vis_e && vis_s == line.len && e_raw > line_end_idx && s_raw <= line_end_idx {
							sel_x1 := ctrl.x + 10.0 + f32(win.gg_ctx.text_width(line))
							win.gg_ctx.draw_rect_filled(sel_x1, curr_line_y, 6.0, line_h,
								gg.Color{r: 59, g: 130, b: 246, a: 120})
						}
						line_start_idx += line.len + 1
					}
				}

				for line in lines {
					if line_y + line_h > ctrl.y + ctrl.h - 4.0 {
						break
					}
					is_mono := ctrl.font_name.len > 0 && (ctrl.font_name.to_lower().contains('mono') || ctrl.font_name.to_lower().contains('courier'))
					win.gg_ctx.draw_text2(
						x:     int(ctrl.x + 10)
						y:     int(line_y)
						text:  line
						color: txt_c
						size:  txt_sz
						bold:  ctrl.font_bold
						mono:  is_mono
					)
					line_y += line_h
				}

				if ctrl.is_focused {
					mut line_start_idx := 0
					for i, line in lines {
						curr_line_y := ctrl.y + 8.0 + f32(i) * line_h
						if curr_line_y + line_h > ctrl.y + ctrl.h - 4.0 {
							break
						}
						line_end_idx := line_start_idx + line.len
						if ctrl.caret_pos >= line_start_idx && (ctrl.caret_pos <= line_end_idx || i == lines.len - 1) {
							col := math.max(0, math.min(line.len, ctrl.caret_pos - line_start_idx))
							prefix_txt := line[0..col]
							caret_offset_x := f32(win.gg_ctx.text_width(prefix_txt))
							caret_x := ctrl.x + 10.0 + caret_offset_x
							win.gg_ctx.draw_line(caret_x, curr_line_y + 1.0, caret_x, curr_line_y + line_h - 1.0,
								accent)
							break
						}
						line_start_idx += line.len + 1
					}
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

				chk_sz := if ctrl.font_size > 0 { ctrl.font_size } else { 14 }
				chk_tc := if ctrl.font_color.len > 0 { parse_hex_color(ctrl.font_color) } else { fg }
				win.gg_ctx.draw_text2(
					x:     int(ctrl.x + box_size + 10)
					y:     int(ctrl.y + (ctrl.h - f32(chk_sz)) / 2.0)
					text:  ctrl.title
					color: chk_tc
					size:  chk_sz
					bold:  ctrl.font_bold
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

				sw_sz := if ctrl.font_size > 0 { ctrl.font_size } else { 14 }
				sw_tc := if ctrl.font_color.len > 0 { parse_hex_color(ctrl.font_color) } else { fg }
				win.gg_ctx.draw_text2(
					x:     int(ctrl.x + sw_w + 12)
					y:     int(ctrl.y + (ctrl.h - f32(sw_sz)) / 2.0)
					text:  ctrl.title
					color: sw_tc
					size:  sw_sz
					bold:  ctrl.font_bold
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
				draw_vector_chevron(win.gg_ctx, ctrl.x + ctrl.w - 18.0, ctrl.y + ctrl.h / 2.0, 5.0, if ctrl.is_expanded { 'up' } else { 'down' }, fg)
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

				draw_vector_chevron(win.gg_ctx, ctrl.x + ctrl.w - 16.0, ctrl.y + hdr_h / 2.0, 5.0, if ctrl.is_expanded { 'up' } else { 'down' }, mb_txt_c)

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
			'segmented', 'tab_pills', 'tabs', 'radio', 'filter_chips', 'mode_control' {
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
						text_w := f32(item.len * 7)
						win.gg_ctx.draw_text2(
							x:     int(item_x + math.max(4.0, (seg_w - text_w) / 2.0))
							y:     int(ctrl.y + (ctrl.h - 14.0) / 2.0)
							text:  item
							color: item_c
							size:  12
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
				star_gold := gg.Color{ r: 255, g: 193, b: 7 }
				star_border := if win.theme.is_dark { gg.Color{ r: 120, g: 120, b: 125 } } else { border_c }
				mut star_x := ctrl.x + 12.0
				star_y := ctrl.y + 12.0
				for s_idx in 1 .. 6 {
					is_filled := s_idx <= stars
					fill_c := if is_filled { star_gold } else { bg }
					stroke_c := if is_filled { star_gold } else { star_border }
					draw_vector_star(win.gg_ctx, star_x, star_y, 8.5, 3.6, is_filled, fill_c, stroke_c)
					star_x += 24.0
				}
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
			'color_picker' {
				cp_b_c := if ctrl.is_focused { accent } else { border_c }
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0,
					surface)
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0,
					cp_b_c)

				swatch_w := f32(24.0)
				swatch_h := f32(ctrl.h - 10.0)
				swatch_x := f32(ctrl.x + 5.0)
				swatch_y := f32(ctrl.y + 5.0)
				hex_str := if ctrl.text_value.len > 0 { ctrl.text_value } else { '#0a84ff' }
				swatch_c := parse_hex_color(hex_str)
				win.gg_ctx.draw_rounded_rect_filled(swatch_x, swatch_y, swatch_w, swatch_h, 4.0,
					swatch_c)
				win.gg_ctx.draw_rounded_rect_empty(swatch_x, swatch_y, swatch_w, swatch_h, 4.0,
					border_c)

				win.gg_ctx.draw_text2(
					x:     int(swatch_x + swatch_w + 8.0)
					y:     int(ctrl.y + (ctrl.h - 16.0) / 2.0)
					text:  hex_str
					color: fg
					size:  14
				)
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

						icon_p := ctrl.tab_icons[idx]
						has_tab_icon := icon_p.len > 0
						tab_icon_sz := f32(16.0)
						text_w := f32(title.len * 7)
						total_content_w := if has_tab_icon { text_w + tab_icon_sz + 6.0 } else { text_w }
						mut start_x := tx + (tab_w - total_content_w) / 2.0

						if has_tab_icon {
							win.draw_image_fit(icon_p, start_x, ctrl.y + (ctrl.h - tab_icon_sz) / 2.0, tab_icon_sz, tab_icon_sz, '')
							start_x += tab_icon_sz + 6.0
						}

						win.gg_ctx.draw_text2(
							x:     int(start_x)
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

				if ctrl.has_selection() {
					s_raw, e_raw := ctrl.selection_range()
					vis_s := math.max(0, math.min(disp_path.len, s_raw - start_idx))
					vis_e := math.max(0, math.min(disp_path.len, e_raw - start_idx))
					if vis_s < vis_e {
						prefix_s := disp_path[0..vis_s]
						prefix_e := disp_path[0..vis_e]
						sel_x1 := ctrl.x + 10.0 + f32(win.gg_ctx.text_width(prefix_s))
						sel_x2 := ctrl.x + 10.0 + f32(win.gg_ctx.text_width(prefix_e))
						sel_w := sel_x2 - sel_x1
						if sel_w > 0 {
							win.gg_ctx.draw_rect_filled(sel_x1, ctrl.y + 4.0, sel_w, ctrl.h - 8.0,
								gg.Color{r: 59, g: 130, b: 246, a: 120})
						}
					}
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

				draw_vector_search_icon(win.gg_ctx, ctrl.x + 14.0, ctrl.y + ctrl.h / 2.0, 4.5, fg)


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

				if ctrl.has_selection() {
					s_raw, e_raw := ctrl.selection_range()
					vis_s := math.max(0, math.min(disp_s.len, s_raw - start_idx))
					vis_e := math.max(0, math.min(disp_s.len, e_raw - start_idx))
					if vis_s < vis_e {
						prefix_s := disp_s[0..vis_s]
						prefix_e := disp_s[0..vis_e]
						sel_x1 := ctrl.x + 32.0 + f32(win.gg_ctx.text_width(prefix_s))
						sel_x2 := ctrl.x + 32.0 + f32(win.gg_ctx.text_width(prefix_e))
						sel_w := sel_x2 - sel_x1
						if sel_w > 0 {
							win.gg_ctx.draw_rect_filled(sel_x1, ctrl.y + 4.0, sel_w, ctrl.h - 8.0,
								gg.Color{r: 59, g: 130, b: 246, a: 120})
						}
					}
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
							draw_vector_chevron(win.gg_ctx, bx + 6.0, ctrl.y + 11.0, 4.0, 'right', border_c)
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

				draw_vector_chevron(win.gg_ctx, ctrl.x + 16.0, ctrl.y + hdr_h / 2.0, 5.0, if ctrl.is_expanded { 'down' } else { 'right' }, fg)
				win.gg_ctx.draw_text2(
					x:     int(ctrl.x + 28)
					y:     int(ctrl.y + 8)
					text:  ctrl.title
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
				win.gg_ctx.draw_text2(x: int(ctrl.x + 10), y: int(ctrl.y + 8), text: clean_text(val_str), color: fg, size: 12)
				draw_vector_chevron(win.gg_ctx, ctrl.x + ctrl.w - 14.0, ctrl.y + 16.0, 4.5, if ctrl.is_expanded { 'up' } else { 'down' }, accent)

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

				has_sb_icon := ctrl.icon_path.len > 0
				sb_icon_sz := f32(16.0)
				mut st_x := ctrl.x + 10.0
				if has_sb_icon {
					win.draw_image_fit(ctrl.icon_path, st_x, ctrl.y + (bar_h - sb_icon_sz) / 2.0, sb_icon_sz, sb_icon_sz, '')
					st_x += sb_icon_sz + 6.0
				}

				win.gg_ctx.draw_text2(x: int(st_x), y: int(ctrl.y + 5), text: status_txt, color: fg, size: 11)
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
				draw_vector_chevron(win.gg_ctx, btn_x + 20.0, ctrl.y + 24.0, 5.0, 'right', gg.Color{r: 255, g: 255, b: 255})

				win.gg_ctx.draw_rounded_rect_filled(btn_x, ctrl.y + 44, 40.0, 28.0, 4.0, accent)
				draw_vector_chevron(win.gg_ctx, btn_x + 20.0, ctrl.y + 58.0, 5.0, 'left', gg.Color{r: 255, g: 255, b: 255})

				win.gg_ctx.draw_rounded_rect_filled(btn_x, ctrl.y + 78, 40.0, 28.0, 4.0, accent)
				draw_vector_chevron(win.gg_ctx, btn_x + 16.0, ctrl.y + 92.0, 5.0, 'right', gg.Color{r: 255, g: 255, b: 255})
				draw_vector_chevron(win.gg_ctx, btn_x + 24.0, ctrl.y + 92.0, 5.0, 'right', gg.Color{r: 255, g: 255, b: 255})

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
			'super_stat_card' {
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 8.0, surface)
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 8.0, if ctrl.is_hovered { accent } else { border_c })

				// Title
				max_title_chars := math.max(6, int((ctrl.w - 60.0) / 6.5))
				disp_title := if ctrl.title.len > max_title_chars { ctrl.title[0..max_title_chars - 3] + '...' } else { ctrl.title }
				win.gg_ctx.draw_text2(x: int(ctrl.x + 14), y: int(ctrl.y + 10), text: disp_title, color: gg.rgb(156, 163, 175), size: 12)

				// Value
				val_c := if ctrl.font_color.len > 0 { parse_hex_color(ctrl.font_color) } else { fg }
				win.gg_ctx.draw_text2(x: int(ctrl.x + 14), y: int(ctrl.y + 28), text: ctrl.text_value, color: val_c, size: 20, bold: true)

				// Delta Pill
				if ctrl.placeholder.len > 0 {
					delta_c := if ctrl.bool_value { gg.rgb(52, 211, 153) } else { gg.rgb(248, 113, 113) }
					pill_bg := if ctrl.bool_value { gg.rgba(16, 185, 129, 35) } else { gg.rgba(239, 68, 68, 35) }
					pill_txt := if ctrl.bool_value { '[+] ' + ctrl.placeholder } else { '[-] ' + ctrl.placeholder }
					pill_w := f32(pill_txt.len * 6 + 12)
					win.gg_ctx.draw_rounded_rect_filled(ctrl.x + 14, ctrl.y + 54, pill_w, 18.0, 4.0, pill_bg)
					win.gg_ctx.draw_text2(x: int(ctrl.x + 20), y: int(ctrl.y + 56), text: pill_txt, color: delta_c, size: 10, bold: true)
				}

				// Mini Sparkline
				if ctrl.f64_list.len >= 2 {
					sp_x := ctrl.x + ctrl.w - f32(100.0)
					sp_y := ctrl.y + f32(18.0)
					sp_w := f32(86.0)
					sp_h := f32(48.0)
					mut min_v := ctrl.f64_list[0]
					mut max_v := ctrl.f64_list[0]
					for v in ctrl.f64_list {
						if v < min_v { min_v = v }
						if v > max_v { max_v = v }
					}
					range_v := if max_v > min_v { max_v - min_v } else { 1.0 }
					step_x := sp_w / f32(ctrl.f64_list.len - 1)
					sp_color := if ctrl.bool_value { gg.rgb(52, 211, 153) } else { accent }
					for i in 0 .. (ctrl.f64_list.len - 1) {
						x1 := sp_x + f32(i) * step_x
						y1 := sp_y + sp_h - f32((ctrl.f64_list[i] - min_v) / range_v) * sp_h
						x2 := sp_x + f32(i + 1) * step_x
						y2 := sp_y + sp_h - f32((ctrl.f64_list[i + 1] - min_v) / range_v) * sp_h
						win.gg_ctx.draw_line(x1, y1, x2, y2, sp_color)
						win.gg_ctx.draw_circle_filled(x1, y1, f32(2.0), sp_color)
					}
					last_i := ctrl.f64_list.len - 1
					last_x := sp_x + f32(last_i) * step_x
					last_y := sp_y + sp_h - f32((ctrl.f64_list[last_i] - min_v) / range_v) * sp_h
					win.gg_ctx.draw_circle_filled(last_x, last_y, f32(3.0), sp_color)
				}
			}
			'code_studio' {
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 8.0, gg.rgb(18, 20, 28))
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 8.0, border_c)

				// Header bar
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, 28.0, 8.0, gg.rgb(26, 29, 42))
				win.gg_ctx.draw_rect_filled(ctrl.x, ctrl.y + 14.0, ctrl.w, 14.0, gg.rgb(26, 29, 42))
				win.gg_ctx.draw_line(ctrl.x, ctrl.y + 28.0, ctrl.x + ctrl.w, ctrl.y + 28.0, border_c)

				// Window dots
				win.gg_ctx.draw_circle_filled(ctrl.x + 12.0, ctrl.y + 14.0, 4.0, gg.rgb(239, 68, 68))
				win.gg_ctx.draw_circle_filled(ctrl.x + 24.0, ctrl.y + 14.0, 4.0, gg.rgb(245, 158, 11))
				win.gg_ctx.draw_circle_filled(ctrl.x + 36.0, ctrl.y + 14.0, 4.0, gg.rgb(16, 185, 129))

				// Filename
				win.gg_ctx.draw_text2(x: int(ctrl.x + 50), y: int(ctrl.y + 7), text: ctrl.title, color: gg.Color{r: 255, g: 255, b: 255}, size: 12, bold: true)

				// Language pill badge
				lang_txt := if ctrl.code_lang.len > 0 { '[' + ctrl.code_lang.to_upper() + ']' } else { '[V]' }
				lang_w := f32(lang_txt.len * 7 + 10)
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x + ctrl.w - 126.0, ctrl.y + 5.0, lang_w, 18.0, 4.0, gg.rgb(40, 44, 62))
				win.gg_ctx.draw_text2(x: int(ctrl.x + ctrl.w - 122.0), y: int(ctrl.y + 7), text: lang_txt, color: accent, size: 10, bold: true)

				// Copy Button
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x + ctrl.w - 60.0, ctrl.y + 5.0, 52.0, 18.0, 4.0, accent)
				win.gg_ctx.draw_text2(x: int(ctrl.x + ctrl.w - 52.0), y: int(ctrl.y + 7), text: 'Copy', color: gg.Color{r: 255, g: 255, b: 255}, size: 11, bold: true)

				// Gutter
				win.gg_ctx.draw_rect_filled(ctrl.x, ctrl.y + 28.0, 36.0, ctrl.h - 48.0, gg.rgb(14, 16, 23))
				win.gg_ctx.draw_line(ctrl.x + 36.0, ctrl.y + 28.0, ctrl.x + 36.0, ctrl.y + ctrl.h - 20.0, border_c)

				// Text Lines with Syntax Highlight
				lines := ctrl.text_value.split('\n')
				mut code_y := ctrl.y + 34.0
				for idx, raw_line in lines {
					if code_y + 18.0 > ctrl.y + ctrl.h - 20.0 { break }
					// Gutter number
					win.gg_ctx.draw_text2(x: int(ctrl.x + 8), y: int(code_y), text: '${idx + 1:2d}', color: gg.rgb(90, 95, 115), size: 11, mono: true)

					// Expand tabs into 4 spaces for crisp rendering
					line := raw_line.replace('\t', '    ')
					words := line.split(' ')
					mut word_x := ctrl.x + 44.0
					for w in words {
						if word_x > ctrl.x + ctrl.w - 14.0 { break }
						if w.len == 0 {
							word_x += 6.5
							continue
						}
						w_clean := w.trim_space()
						w_c := if w_clean in ['fn', 'mut', 'pub', 'struct', 'return', 'if', 'else', 'for', 'match', 'import', 'module', 'type', 'const', 'true', 'false', 'nil', 'int', 'string', 'bool', 'f64', 'def', 'class', 'let', 'var', 'SELECT', 'FROM', 'WHERE'] {
							gg.rgb(192, 132, 252) // purple
						} else if w_clean.starts_with('//') || w_clean.starts_with('#') {
							gg.rgb(100, 116, 139) // slate comment
						} else if w_clean.starts_with('\'') || w_clean.starts_with('"') {
							gg.rgb(74, 222, 128) // green string
						} else if w_clean.len > 0 && w_clean[0].is_digit() {
							gg.rgb(251, 146, 60) // orange number
						} else {
							gg.rgb(241, 245, 249) // light white
						}
						win.gg_ctx.draw_text2(x: int(word_x), y: int(code_y), text: w + ' ', color: w_c, size: 12, mono: true)
						word_x += f32((w.len + 1) * 7)
					}
					code_y += 18.0
				}

				// Status footer bar
				win.gg_ctx.draw_rect_filled(ctrl.x, ctrl.y + ctrl.h - 20.0, ctrl.w, 20.0, gg.rgb(22, 25, 36))
				win.gg_ctx.draw_line(ctrl.x, ctrl.y + ctrl.h - 20.0, ctrl.x + ctrl.w, ctrl.y + ctrl.h - 20.0, border_c)
				win.gg_ctx.draw_text2(x: int(ctrl.x + 10), y: int(ctrl.y + ctrl.h - 16.0), text: 'Ln ${lines.len}, Col 1', color: gg.rgb(148, 163, 184), size: 10)
				win.gg_ctx.draw_text2(x: int(ctrl.x + ctrl.w - 140), y: int(ctrl.y + ctrl.h - 16.0), text: 'UTF-8 | Spaces: 4 | ${ctrl.code_lang.to_upper()}', color: gg.rgb(148, 163, 184), size: 10)
			}
			'kanban_board' {
				num_cols := math.max(1, ctrl.items.len)
				gap := f32(8.0)
				col_w := (ctrl.w - f32(num_cols - 1) * gap) / f32(num_cols)

				for c_idx, col_name in ctrl.items {
					col_x := ctrl.x + f32(c_idx) * (col_w + gap)
					win.gg_ctx.draw_rounded_rect_filled(col_x, ctrl.y, col_w, ctrl.h, 6.0, gg.rgb(24, 27, 38))
					win.gg_ctx.draw_rounded_rect_empty(col_x, ctrl.y, col_w, ctrl.h, 6.0, border_c)

					// Top header accent line
					col_accent := match c_idx % 4 {
						0 { gg.rgb(59, 130, 246) }
						1 { gg.rgb(245, 158, 11) }
						2 { gg.rgb(168, 85, 247) }
						else { gg.rgb(16, 185, 129) }
					}
					win.gg_ctx.draw_rect_filled(col_x + 2, ctrl.y + 2, col_w - 4, 3.0, col_accent)

					// Count matching cards
					prefix := '${c_idx}:'
					mut card_list := []string{}
					for item in ctrl.items_selected {
						if item.starts_with(prefix) {
							card_list << item[prefix.len..]
						}
					}

					// Header text & count badge
					max_hdr_chars := math.max(3, int((col_w - 38.0) / 7.0))
					disp_hdr := if col_name.len > max_hdr_chars { col_name[0..max_hdr_chars - 2] + '..' } else { col_name }
					win.gg_ctx.draw_text2(x: int(col_x + 8), y: int(ctrl.y + 10), text: disp_hdr, color: fg, size: 11, bold: true)
					win.gg_ctx.draw_rounded_rect_filled(col_x + col_w - 26, ctrl.y + 8, 20.0, 16.0, 4.0, gg.rgb(40, 44, 60))
					win.gg_ctx.draw_text2(x: int(col_x + col_w - 21), y: int(ctrl.y + 10), text: '${card_list.len}', color: accent, size: 10, bold: true)

					// Cards
					mut card_y := ctrl.y + 32.0
					for card in card_list {
						if card_y + 44.0 > ctrl.y + ctrl.h { break }
						win.gg_ctx.draw_rounded_rect_filled(col_x + 6, card_y, col_w - 12, 42.0, 4.0, surface)
						win.gg_ctx.draw_rounded_rect_empty(col_x + 6, card_y, col_w - 12, 42.0, 4.0, border_c)

						// Render card details (support tag|priority|title or title)
						c_parts := card.split('|')
						card_title := if c_parts.len >= 3 { c_parts[2] } else { card }
						max_title_chars := math.max(4, int((col_w - 20.0) / 6.5))
						disp_title := if card_title.len > max_title_chars { card_title[0..max_title_chars - 3] + '...' } else { card_title }
						win.gg_ctx.draw_text2(x: int(col_x + 10), y: int(card_y + 6), text: disp_title, color: fg, size: 10, bold: true)

						if c_parts.len >= 2 {
							tag_name := c_parts[0]
							prio := c_parts[1]
							prio_c := match prio.to_upper() {
								'HIGH' { gg.rgb(239, 68, 68) }
								'MED' { gg.rgb(245, 158, 11) }
								else { gg.rgb(59, 130, 246) }
							}
							win.gg_ctx.draw_rounded_rect_filled(col_x + 10, card_y + 24, 34.0, 14.0, 3.0, prio_c)
							win.gg_ctx.draw_text2(x: int(col_x + 13), y: int(card_y + 25), text: prio, color: gg.Color{r: 255, g: 255, b: 255}, size: 9, bold: true)
							win.gg_ctx.draw_text2(x: int(col_x + 50), y: int(card_y + 25), text: tag_name, color: gg.rgb(156, 163, 175), size: 9)
						}
						card_y += 48.0
					}
				}
			}
			'activity_feed' {
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 8.0, surface)
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 8.0, border_c)

				// Header
				win.gg_ctx.draw_text2(x: int(ctrl.x + 14), y: int(ctrl.y + 10), text: 'Activity Timeline Feed', color: fg, size: 12, bold: true)
				win.gg_ctx.draw_line(ctrl.x + 14, ctrl.y + 28.0, ctrl.x + ctrl.w - 14, ctrl.y + 28.0, border_c)

				// Vertical track line
				track_x := ctrl.x + 24.0
				win.gg_ctx.draw_line(track_x, ctrl.y + 36.0, track_x, ctrl.y + ctrl.h - 14.0, border_c)

				mut ev_y := ctrl.y + 36.0
				for item in ctrl.items {
					if ev_y + 28.0 > ctrl.y + ctrl.h { break }
					parts := item.split('|')
					tag := if parts.len > 0 { parts[0] } else { 'INFO' }
					time_ago := if parts.len > 1 { parts[1] } else { 'now' }
					desc := if parts.len > 2 { parts[2] } else { item }

					dot_c := match tag.to_upper() {
						'OK', 'DEPLOY', 'SUCCESS' { gg.rgb(52, 211, 153) }
						'WARN', 'ALERT' { gg.rgb(251, 191, 36) }
						'ERR', 'ERROR', 'FAIL' { gg.rgb(248, 113, 113) }
						else { gg.rgb(56, 189, 248) }
					}

					win.gg_ctx.draw_circle_filled(track_x, ev_y + 8.0, 4.0, dot_c)

					// Truncate description so it never collides with time_ago badge
					max_chars := math.max(4, int((ctrl.w - 110.0) / 6.5))
					disp_desc := if desc.len > max_chars { desc[0..max_chars - 3] + '...' } else { desc }
					win.gg_ctx.draw_text2(x: int(ctrl.x + 38), y: int(ev_y + 2), text: disp_desc, color: fg, size: 11, bold: true)

					time_w := f32(time_ago.len * 6 + 10)
					win.gg_ctx.draw_text2(x: int(ctrl.x + ctrl.w - time_w - 8.0), y: int(ev_y + 2), text: time_ago, color: gg.rgb(148, 163, 184), size: 10)

					ev_y += 28.0
				}
			}
			'donut_chart' {
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 8.0, surface)
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 8.0, border_c)

				cx := ctrl.x + ctrl.w / 2.0
				cy := ctrl.y + 48.0
				r_out := f32(36.0)
				r_in := f32(26.0)

				// Background ring
				win.gg_ctx.draw_circle_empty(cx, cy, (r_out + r_in) / 2.0, border_c)

				// Progress arc
				pct := math.max(0.0, math.min(100.0, ctrl.f64_value))
				num_pts := int(pct * 0.36)
				for i in 0 .. num_pts {
					angle := -math.pi / 2.0 + f64(i) * (2.0 * math.pi / 36.0)
					ax := cx + f32(math.cos(angle)) * ((r_out + r_in) / 2.0)
					ay := cy + f32(math.sin(angle)) * ((r_out + r_in) / 2.0)
					win.gg_ctx.draw_circle_filled(ax, ay, 3.5, accent)
				}

				// Center percentage
				pct_txt := '${int(pct)}%'
				win.gg_ctx.draw_text2(x: int(cx - f32(pct_txt.len * 5)), y: int(cy - 7), text: pct_txt, color: fg, size: 15, bold: true)

				// Title & Caption
				title_w := f32(ctrl.title.len * 6)
				win.gg_ctx.draw_text2(x: int(cx - title_w / 2.0), y: int(ctrl.y + ctrl.h - 22), text: ctrl.title, color: fg, size: 11, bold: true)
			}
			'super_terminal' {
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 8.0, gg.rgb(13, 16, 23))
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 8.0, border_c)

				// Top tab bar
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, 26.0, 8.0, gg.rgb(22, 27, 38))
				win.gg_ctx.draw_rect_filled(ctrl.x, ctrl.y + 14.0, ctrl.w, 12.0, gg.rgb(22, 27, 38))
				win.gg_ctx.draw_line(ctrl.x, ctrl.y + 26.0, ctrl.x + ctrl.w, ctrl.y + 26.0, border_c)

				mut tab_x := ctrl.x + 8.0
				for idx, tab_name in ctrl.items {
					t_w := f32(tab_name.len * 7 + 18)
					is_active := idx == ctrl.int_value
					if is_active {
						win.gg_ctx.draw_rounded_rect_filled(tab_x, ctrl.y + 4.0, t_w, 20.0, 4.0, gg.rgb(35, 41, 58))
						win.gg_ctx.draw_line(tab_x + 4.0, ctrl.y + 24.0, tab_x + t_w - 4.0, ctrl.y + 24.0, accent)
					}
					win.gg_ctx.draw_text2(x: int(tab_x + 8), y: int(ctrl.y + 6), text: tab_name, color: if is_active { gg.Color{r: 255, g: 255, b: 255} } else { gg.rgb(156, 163, 175) }, size: 11, bold: is_active)
					tab_x += t_w + 6.0
				}

				// Running green pulse indicator dot
				win.gg_ctx.draw_circle_filled(ctrl.x + ctrl.w - 120.0, ctrl.y + 13.0, 3.5, gg.rgb(52, 211, 153))
				win.gg_ctx.draw_text2(x: int(ctrl.x + ctrl.w - 110.0), y: int(ctrl.y + 7), text: 'LIVE', color: gg.rgb(52, 211, 153), size: 10, bold: true)

				// Clear button
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x + ctrl.w - 60.0, ctrl.y + 4.0, 52.0, 18.0, 4.0, gg.rgb(40, 45, 62))
				win.gg_ctx.draw_text2(x: int(ctrl.x + ctrl.w - 50.0), y: int(ctrl.y + 6), text: 'Clear', color: gg.rgb(200, 205, 220), size: 10)

				// Log outputs
				mut log_y := ctrl.y + 32.0
				for idx, line in ctrl.items_selected {
					if log_y + 18.0 > ctrl.y + ctrl.h { break }
					line_c := if line.contains('[ERR]') || line.contains('[ERROR]') {
						gg.rgb(248, 113, 113)
					} else if line.contains('[WARN]') {
						gg.rgb(251, 191, 36)
					} else if line.contains('[OK]') || line.contains('[SUCCESS]') {
						gg.rgb(52, 211, 153)
					} else if line.contains('[INFO]') {
						gg.rgb(56, 189, 248)
					} else {
						gg.rgb(226, 232, 240)
					}
					win.gg_ctx.draw_text2(x: int(ctrl.x + 10), y: int(log_y), text: '${idx + 1:2d} | ${line}', color: line_c, size: 11, mono: true)
					log_y += 18.0
				}
			}
			'smart_table' {
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 8.0, surface)
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 8.0, border_c)

				// Search filter bar
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x + 8.0, ctrl.y + 6.0, ctrl.w - 16.0, 22.0, 4.0, gg.rgb(24, 27, 38))
				draw_vector_search_icon(win.gg_ctx, ctrl.x + 18.0, ctrl.y + 17.0, 3.5, gg.rgb(156, 163, 175))
				search_txt := if ctrl.search_query.len > 0 { ctrl.search_query } else { 'Filter ${ctrl.rows.len} records...' }
				win.gg_ctx.draw_text2(x: int(ctrl.x + 32), y: int(ctrl.y + 10), text: search_txt, color: if ctrl.search_query.len > 0 { fg } else { gg.rgb(148, 163, 184) }, size: 11)

				// Column Headers
				hdr_y := ctrl.y + 32.0
				win.gg_ctx.draw_rect_filled(ctrl.x + 1, hdr_y, ctrl.w - 2, 24.0, gg.rgb(30, 34, 48))
				win.gg_ctx.draw_line(ctrl.x, hdr_y + 24.0, ctrl.x + ctrl.w, hdr_y + 24.0, border_c)

				num_cols := math.max(1, ctrl.headers.len)
				col_w := (ctrl.w - 16.0) / f32(num_cols)
				for c_idx, hdr in ctrl.headers {
					hx := ctrl.x + 8.0 + f32(c_idx) * col_w
					sort_sym := if ctrl.sort_col == c_idx { if ctrl.sort_asc { ' ^' } else { ' v' } } else { '' }
					win.gg_ctx.draw_text2(x: int(hx), y: int(hdr_y + 5), text: hdr + sort_sym, color: if ctrl.sort_col == c_idx { accent } else { fg }, size: 11, bold: true)
				}

				// Data Rows (Paginated 5 items)
				page_size := 5
				start_idx := (ctrl.current_page - 1) * page_size
				mut row_y := hdr_y + 26.0
				for r_i in start_idx .. math.min(ctrl.rows.len, start_idx + page_size) {
					row := ctrl.rows[r_i]
					is_sel := ctrl.selected_row == r_i
					row_bg := if is_sel { gg.rgba(59, 130, 246, 50) } else if r_i % 2 == 1 { gg.rgba(255, 255, 255, 6) } else { surface }
					win.gg_ctx.draw_rect_filled(ctrl.x + 2, row_y, ctrl.w - 4, 24.0, row_bg)

					for c_idx, cell in row {
						cx := ctrl.x + 8.0 + f32(c_idx) * col_w
						// Check status badge
						if cell in ['Active', 'Done', 'Paid', 'Completed', 'Success'] {
							win.gg_ctx.draw_rounded_rect_filled(cx, row_y + 3.0, 56.0, 18.0, 3.0, gg.rgba(16, 185, 129, 40))
							win.gg_ctx.draw_text2(x: int(cx + 6), y: int(row_y + 5), text: cell, color: gg.rgb(52, 211, 153), size: 10, bold: true)
						} else if cell in ['Pending', 'Warning', 'Review'] {
							win.gg_ctx.draw_rounded_rect_filled(cx, row_y + 3.0, 56.0, 18.0, 3.0, gg.rgba(245, 158, 11, 40))
							win.gg_ctx.draw_text2(x: int(cx + 6), y: int(row_y + 5), text: cell, color: gg.rgb(251, 191, 36), size: 10, bold: true)
						} else {
							win.gg_ctx.draw_text2(x: int(cx), y: int(row_y + 5), text: cell, color: fg, size: 11)
						}
					}
					row_y += 26.0
				}

				// Footer Pagination Bar
				footer_y := ctrl.y + ctrl.h - 26.0
				win.gg_ctx.draw_line(ctrl.x, footer_y, ctrl.x + ctrl.w, footer_y, border_c)
				win.gg_ctx.draw_text2(x: int(ctrl.x + 10), y: int(footer_y + 6), text: 'Page ${ctrl.current_page} of ${ctrl.total_pages} (${ctrl.rows.len} items)', color: gg.rgb(156, 163, 175), size: 10)

				// Prev / Next buttons
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x + ctrl.w - 115.0, footer_y + 3.0, 50.0, 20.0, 3.0, gg.rgb(35, 40, 55))
				win.gg_ctx.draw_text2(x: int(ctrl.x + ctrl.w - 105.0), y: int(footer_y + 6), text: '< Prev', color: fg, size: 10)
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x + ctrl.w - 60.0, footer_y + 3.0, 50.0, 20.0, 3.0, gg.rgb(35, 40, 55))
				win.gg_ctx.draw_text2(x: int(ctrl.x + ctrl.w - 50.0), y: int(footer_y + 6), text: 'Next >', color: fg, size: 10)
			}
			'wizard_stepper' {
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 8.0, surface)
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 8.0, border_c)

				if ctrl.items.len > 0 {
					step_w := (ctrl.w - 40.0) / f32(ctrl.items.len)
					cy := ctrl.y + 24.0

					for idx, step_title in ctrl.items {
						cx := ctrl.x + 20.0 + f32(idx) * step_w + step_w / 2.0

						// Connecting line to next step
						if idx < ctrl.items.len - 1 {
							next_cx := ctrl.x + 20.0 + f32(idx + 1) * step_w + step_w / 2.0
							line_c := if idx < ctrl.int_value { accent } else { border_c }
							win.gg_ctx.draw_line(cx + 12.0, cy, next_cx - 12.0, cy, line_c)
						}

						// Step node circle
						if idx < ctrl.int_value {
							win.gg_ctx.draw_circle_filled(cx, cy, 11.0, gg.rgb(52, 211, 153))
							win.gg_ctx.draw_text2(x: int(cx - 4), y: int(cy - 6), text: 'v', color: gg.Color{r: 255, g: 255, b: 255}, size: 10, bold: true)
						} else if idx == ctrl.int_value {
							win.gg_ctx.draw_circle_filled(cx, cy, 12.0, accent)
							win.gg_ctx.draw_text2(x: int(cx - 3), y: int(cy - 6), text: '${idx + 1}', color: gg.Color{r: 255, g: 255, b: 255}, size: 11, bold: true)
						} else {
							win.gg_ctx.draw_circle_empty(cx, cy, 10.0, border_c)
							win.gg_ctx.draw_text2(x: int(cx - 3), y: int(cy - 6), text: '${idx + 1}', color: gg.rgb(156, 163, 175), size: 10)
						}

						// Step title label
						step_txt_w := f32(step_title.len) * 5.5
						win.gg_ctx.draw_text2(x: int(cx - step_txt_w / 2.0), y: int(cy + 18), text: step_title, color: if idx == ctrl.int_value { fg } else { gg.rgb(156, 163, 175) }, size: 10, bold: idx == ctrl.int_value)
					}
				}
			}
			'floating_toolbar' {
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 20.0, gg.rgb(25, 29, 42))
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 20.0, border_c)

				// Title with accent dot
				win.gg_ctx.draw_circle_filled(ctrl.x + 16.0, ctrl.y + ctrl.h / 2.0, 4.0, accent)
				win.gg_ctx.draw_text2(x: int(ctrl.x + 26), y: int(ctrl.y + (ctrl.h - 14.0) / 2.0), text: ctrl.title, color: fg, size: 12, bold: true)

				// Action pills
				mut ax := ctrl.x + f32(ctrl.title.len * 7 + 36)
				for idx, act in ctrl.items {
					act_w := f32(act.len * 7 + 20)
					is_sel := idx == ctrl.int_value
					if is_sel {
						win.gg_ctx.draw_rounded_rect_filled(ax, ctrl.y + 6.0, act_w, ctrl.h - 12.0, 14.0, accent)
					} else {
						win.gg_ctx.draw_rounded_rect_filled(ax, ctrl.y + 6.0, act_w, ctrl.h - 12.0, 14.0, gg.rgb(38, 43, 60))
					}
					win.gg_ctx.draw_text2(x: int(ax + 10), y: int(ctrl.y + 13), text: act, color: if is_sel { gg.Color{r: 255, g: 255, b: 255} } else { fg }, size: 11, bold: is_sel)
					ax += act_w + 8.0
				}
			}
			'chip_cloud' {
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 8.0, surface)
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 8.0, border_c)

				mut cx := ctrl.x + 8.0
				for idx, tag in ctrl.tags {
					t_w := f32(tag.len * 7 + 24)
					if cx + t_w > ctrl.x + ctrl.w - 50.0 { break }
					chip_c := match idx % 4 {
						0 { gg.rgb(59, 130, 246) }
						1 { gg.rgb(16, 185, 129) }
						2 { gg.rgb(168, 85, 247) }
						else { gg.rgb(245, 158, 11) }
					}
					win.gg_ctx.draw_rounded_rect_filled(cx, ctrl.y + 8.0, t_w, 26.0, 13.0, chip_c)
					win.gg_ctx.draw_text2(x: int(cx + 8), y: int(ctrl.y + 14), text: tag, color: gg.Color{r: 255, g: 255, b: 255}, size: 11, bold: true)
					win.gg_ctx.draw_text2(x: int(cx + t_w - 14), y: int(ctrl.y + 14), text: 'x', color: gg.rgb(230, 230, 240), size: 11)
					cx += t_w + 8.0
				}

				// + Add tag button
				win.gg_ctx.draw_rounded_rect_empty(cx, ctrl.y + 8.0, 52.0, 26.0, 13.0, accent)
				win.gg_ctx.draw_text2(x: int(cx + 8), y: int(ctrl.y + 14), text: '+ Tag', color: accent, size: 11, bold: true)
			}
			'score_card' {
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 8.0, surface)
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 8.0, border_c)

				// Left Column: Score & Stars
				score_txt := '${ctrl.f64_value:3.1f}'
				win.gg_ctx.draw_text2(x: int(ctrl.x + 16), y: int(ctrl.y + 14), text: score_txt, color: fg, size: 24, bold: true)
				win.gg_ctx.draw_text2(x: int(ctrl.x + 72), y: int(ctrl.y + 18), text: '/ 5.0', color: gg.rgb(156, 163, 175), size: 13)

				// Stars
				for s in 0 .. 5 {
					draw_vector_star(win.gg_ctx, ctrl.x + 22.0 + f32(s * 16), ctrl.y + 54.0, 6.0, 3.0, s < int(ctrl.f64_value), gg.rgb(245, 158, 11), gg.rgb(245, 158, 11))
				}
				win.gg_ctx.draw_text2(x: int(ctrl.x + 16), y: int(ctrl.y + 72), text: '${ctrl.int_value} reviews', color: gg.rgb(156, 163, 175), size: 10)

				// Divider
				win.gg_ctx.draw_line(ctrl.x + 115.0, ctrl.y + 12.0, ctrl.x + 115.0, ctrl.y + ctrl.h - 12.0, border_c)

				// Right Column: Breakdown Bars
				bar_x := ctrl.x + 145.0
				bar_w := ctrl.w - 165.0
				for b_i in 0 .. 5 {
					by := ctrl.y + 12.0 + f32(b_i * 18)
					star_num := 5 - b_i
					win.gg_ctx.draw_text2(x: int(ctrl.x + 124), y: int(by + 1), text: '${star_num}*', color: gg.rgb(156, 163, 175), size: 10)
					win.gg_ctx.draw_rounded_rect_filled(bar_x, by + 4.0, bar_w, 8.0, 4.0, gg.rgb(35, 40, 55))
					pct := if b_i < ctrl.f64_list.len { ctrl.f64_list[b_i] } else { 0.0 }
					if pct > 0 {
						fill_w := bar_w * f32(pct / 100.0)
						win.gg_ctx.draw_rounded_rect_filled(bar_x, by + 4.0, math.max(f32(4.0), fill_w), 8.0, 4.0, accent)
					}
				}
			}
			'image', 'image_box' {
				win.draw_image_fit(ctrl.text_value, ctrl.x, ctrl.y, ctrl.w, ctrl.h, ctrl.placeholder)
				if ctrl.placeholder.len > 0 {
					cap_h := f32(24.0)
					cap_y := ctrl.y + ctrl.h - cap_h
					win.gg_ctx.draw_rect_filled(ctrl.x, cap_y, ctrl.w, cap_h, gg.Color{ r: 15, g: 20, b: 30, a: 190 })
					win.gg_ctx.draw_text2(
						x: int(ctrl.x + 8)
						y: int(cap_y + 5)
						text: clean_text(ctrl.placeholder)
						color: gg.rgb(240, 245, 255)
						size: 11
						bold: true
					)
				}
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0, border_c)
			}
			'user_profile_card' {
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 10.0, surface)
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 10.0, border_c)

				// Avatar Box (68x68)
				av_x := ctrl.x + 14.0
				av_y := ctrl.y + 14.0
				av_sz := f32(68.0)
				win.draw_image_fit(ctrl.text_value, av_x, av_y, av_sz, av_sz, '')
				win.gg_ctx.draw_rounded_rect_empty(av_x, av_y, av_sz, av_sz, 6.0, border_c)

				// Online status indicator badge dot
				dot_x := av_x + av_sz - 4.0
				dot_y := av_y + av_sz - 4.0
				dot_c := if ctrl.bool_value { gg.rgb(16, 185, 129) } else { gg.rgb(156, 163, 175) }
				win.gg_ctx.draw_circle_filled(dot_x, dot_y, 7.0, surface)
				win.gg_ctx.draw_circle_filled(dot_x, dot_y, 5.0, dot_c)

				// Action button geometry on right
				btn_txt := if ctrl.variant.len > 0 { ctrl.variant } else if ctrl.items.len > 2 { ctrl.items[2] } else { '[Message]' }
				btn_w := f32(96.0)
				btn_h := f32(30.0)
				btn_x := ctrl.x + ctrl.w - btn_w - 14.0
				btn_y := ctrl.y + 24.0

				// Full Name & Handle
				text_left := ctrl.x + 94.0
				name_txt := if ctrl.title.len > 0 { ctrl.title } else { 'User Profile' }
				max_name_w := btn_x - text_left - 8.0
				disp_name := truncate_text_to_width(win, name_txt, max_name_w)
				win.gg_ctx.draw_text2(
					x: int(text_left)
					y: int(ctrl.y + 14)
					text: disp_name
					color: fg
					size: 15
					bold: true
				)

				handle_txt := clean_text(ctrl.placeholder)
				if handle_txt.len > 0 {
					win.gg_ctx.draw_text2(
						x: int(text_left)
						y: int(ctrl.y + 34)
						text: handle_txt
						color: gg.rgb(148, 163, 184)
						size: 12
					)
				}

				// Role badge
				role_txt := if ctrl.items.len > 0 && ctrl.items[0].len > 0 { ctrl.items[0] } else { 'Member' }
				handle_w := measure_text_width(win, handle_txt)
				mut badge_x := text_left + handle_w + 10.0
				if handle_txt.len == 0 {
					badge_x = text_left
				}
				max_role_w := btn_x - badge_x - 8.0
				if max_role_w > 20.0 {
					disp_role := truncate_text_to_width(win, role_txt, max_role_w - 14.0)
					role_w := measure_text_width(win, disp_role) + 14.0
					win.gg_ctx.draw_rounded_rect_filled(badge_x, ctrl.y + 32.0, role_w, 18.0, 4.0, if win.theme.is_dark { gg.rgb(30, 58, 138) } else { gg.rgb(219, 234, 254) })
					win.gg_ctx.draw_text2(
						x: int(badge_x + 7)
						y: int(ctrl.y + 35)
						text: disp_role
						color: if win.theme.is_dark { gg.rgb(147, 197, 253) } else { gg.rgb(29, 78, 216) }
						size: 10
						bold: true
					)
				}

				// Bio description
				bio_txt := if ctrl.items.len > 1 { ctrl.items[1] } else { '' }
				if bio_txt.len > 0 {
					max_bio_w := ctrl.w - 104.0
					disp_bio := truncate_text_to_width(win, bio_txt, max_bio_w)
					win.gg_ctx.draw_text2(
						x: int(text_left)
						y: int(ctrl.y + 58)
						text: disp_bio
						color: if win.theme.is_dark { gg.rgb(203, 213, 225) } else { gg.rgb(71, 85, 105) }
						size: 11
					)
				}

				// Draw Action button
				is_btn_hover := win.mouse_x >= btn_x && win.mouse_x <= btn_x + btn_w && win.mouse_y >= btn_y && win.mouse_y <= btn_y + btn_h
				btn_bg := if is_btn_hover { hover_c } else { accent }
				win.gg_ctx.draw_rounded_rect_filled(btn_x, btn_y, btn_w, btn_h, 6.0, btn_bg)
				win.gg_ctx.draw_text2(
					x: int(btn_x + 12)
					y: int(btn_y + 8)
					text: clean_text(btn_txt)
					color: gg.Color{ r: 255, g: 255, b: 255 }
					size: 11
					bold: true
				)
			}
			'product_card' {
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 10.0, surface)
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 10.0, border_c)

				// Hero Image Top Box
				img_pad := f32(8.0)
				img_w := ctrl.w - img_pad * 2.0
				img_h := f32(130.0)
				win.draw_image_fit(ctrl.text_value, ctrl.x + img_pad, ctrl.y + img_pad, img_w, img_h, ctrl.title)
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x + img_pad, ctrl.y + img_pad, img_w, img_h, 6.0, border_c)

				// Badge Tag Overlay (e.g. 'PRO' / 'BESTSELLER')
				badge_str := if ctrl.items.len > 1 && ctrl.items[1].len > 0 { ctrl.items[1] } else { 'PRO' }
				badge_w := f32(badge_str.len * 7 + 16)
				badge_x := ctrl.x + ctrl.w - img_pad - badge_w - 6.0
				badge_y := ctrl.y + img_pad + 6.0
				win.gg_ctx.draw_rounded_rect_filled(badge_x, badge_y, badge_w, 20.0, 4.0, gg.rgb(239, 68, 68))
				win.gg_ctx.draw_text2(
					x: int(badge_x + 8)
					y: int(badge_y + 4)
					text: clean_text(badge_str)
					color: gg.Color{ r: 255, g: 255, b: 255 }
					size: 10
					bold: true
				)

				// Product Title
				win.gg_ctx.draw_text2(
					x: int(ctrl.x + 12)
					y: int(ctrl.y + 146)
					text: clean_text(ctrl.title)
					color: fg
					size: 14
					bold: true
				)

				// Description / subtitle
				if ctrl.placeholder.len > 0 {
					win.gg_ctx.draw_text2(
						x: int(ctrl.x + 12)
						y: int(ctrl.y + 168)
						text: clean_text(ctrl.placeholder)
						color: gg.rgb(148, 163, 184)
						size: 11
					)
				}

				// Price & Rating
				price_txt := if ctrl.items.len > 0 { ctrl.items[0] } else { '$49.00' }
				rating_txt := if ctrl.items.len > 3 { ctrl.items[3] } else { '4.9 *' }
				win.gg_ctx.draw_text2(
					x: int(ctrl.x + 12)
					y: int(ctrl.y + 204)
					text: clean_text(price_txt)
					color: accent
					size: 16
					bold: true
				)
				win.gg_ctx.draw_text2(
					x: int(ctrl.x + 12 + price_txt.len * 9 + 10)
					y: int(ctrl.y + 208)
					text: clean_text(rating_txt)
					color: gg.rgb(234, 179, 8)
					size: 11
					bold: true
				)

				// Action CTA Button
				btn_txt := if ctrl.items.len > 2 { ctrl.items[2] } else { '[Buy Now]' }
				btn_w := f32(92.0)
				btn_h := f32(28.0)
				btn_x := ctrl.x + ctrl.w - btn_w - 12.0
				btn_y := ctrl.y + 200.0
				is_btn_hover := win.mouse_x >= btn_x && win.mouse_x <= btn_x + btn_w && win.mouse_y >= btn_y && win.mouse_y <= btn_y + btn_h
				btn_bg := if is_btn_hover { hover_c } else { accent }
				win.gg_ctx.draw_rounded_rect_filled(btn_x, btn_y, btn_w, btn_h, 6.0, btn_bg)
				win.gg_ctx.draw_text2(
					x: int(btn_x + 12)
					y: int(btn_y + 7)
					text: clean_text(btn_txt)
					color: gg.Color{ r: 255, g: 255, b: 255 }
					size: 11
					bold: true
				)
			}
			'image_gallery' {
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 10.0, surface)
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 10.0, border_c)

				pad := f32(8.0)
				main_w := ctrl.w - pad * 2.0
				main_h := f32(190.0)
				curr_idx := if ctrl.items.len > 0 { math.max(0, math.min(ctrl.items.len - 1, ctrl.int_value)) } else { 0 }
				curr_img := if curr_idx < ctrl.items.len { ctrl.items[curr_idx] } else { '' }

				// Main Hero Preview Image
				win.draw_image_fit(curr_img, ctrl.x + pad, ctrl.y + pad, main_w, main_h, '')
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x + pad, ctrl.y + pad, main_w, main_h, 6.0, border_c)

				// Navigation Prev / Next overlay buttons
				prev_btn_x := ctrl.x + pad + 8.0
				prev_btn_y := ctrl.y + pad + (main_h / 2.0) - 16.0
				next_btn_x := ctrl.x + ctrl.w - pad - 40.0
				next_btn_y := prev_btn_y

				win.gg_ctx.draw_rounded_rect_filled(prev_btn_x, prev_btn_y, 32.0, 32.0, 6.0, gg.Color{ r: 20, g: 25, b: 35, a: 210 })
				draw_vector_chevron(win.gg_ctx, prev_btn_x + 16.0, prev_btn_y + 16.0, 10.0, 'left', gg.Color{ r: 255, g: 255, b: 255 })

				win.gg_ctx.draw_rounded_rect_filled(next_btn_x, next_btn_y, 32.0, 32.0, 6.0, gg.Color{ r: 20, g: 25, b: 35, a: 210 })
				draw_vector_chevron(win.gg_ctx, next_btn_x + 16.0, next_btn_y + 16.0, 10.0, 'right', gg.Color{ r: 255, g: 255, b: 255 })

				// Caption overlay banner
				caption_h := f32(28.0)
				caption_y := ctrl.y + pad + main_h - caption_h
				win.gg_ctx.draw_rect_filled(ctrl.x + pad, caption_y, main_w, caption_h, gg.Color{ r: 15, g: 20, b: 30, a: 210 })
				cap_str := if curr_idx < ctrl.items_selected.len { ctrl.items_selected[curr_idx] } else { 'Image ${curr_idx + 1}' }
				win.gg_ctx.draw_text2(
					x: int(ctrl.x + pad + 10)
					y: int(caption_y + 7)
					text: clean_text(cap_str)
					color: gg.Color{ r: 255, g: 255, b: 255 }
					size: 11
					bold: true
				)
				idx_str := '${curr_idx + 1} / ${ctrl.items.len}'
				win.gg_ctx.draw_text2(
					x: int(ctrl.x + ctrl.w - pad - 60)
					y: int(caption_y + 7)
					text: idx_str
					color: gg.rgb(186, 230, 253)
					size: 11
				)

				// Bottom Thumbnail Strip (66x50 thumbs)
				thumb_strip_y := ctrl.y + pad + main_h + 10.0
				thumb_w := f32(66.0)
				thumb_h := f32(50.0)
				for t_i in 0 .. ctrl.items.len {
					tx := ctrl.x + pad + f32(t_i) * (thumb_w + 8.0)
					if tx + thumb_w > ctrl.x + ctrl.w {
						break
					}
					win.draw_image_fit(ctrl.items[t_i], tx, thumb_strip_y, thumb_w, thumb_h, '')
					if t_i == curr_idx {
						win.gg_ctx.draw_rounded_rect_empty(tx, thumb_strip_y, thumb_w, thumb_h, 4.0, accent)
						win.gg_ctx.draw_rounded_rect_empty(tx - 1.0, thumb_strip_y - 1.0, thumb_w + 2.0, thumb_h + 2.0, 4.0, accent)
					} else {
						win.gg_ctx.draw_rounded_rect_empty(tx, thumb_strip_y, thumb_w, thumb_h, 4.0, border_c)
					}
				}
			}
			'app_launcher_tile' {
				is_hov := ctrl.is_hovered
				tile_bg := if is_hov { surface_hover } else { surface }
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 8.0, tile_bg)
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 8.0, if is_hov { accent } else { border_c })

				// Icon Box (48x48)
				icon_sz := f32(48.0)
				icon_y := ctrl.y + (ctrl.h - icon_sz) / 2.0
				win.draw_image_fit(ctrl.text_value, ctrl.x + 12.0, icon_y, icon_sz, icon_sz, '')
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x + 12.0, icon_y, icon_sz, icon_sz, 6.0, border_c)

				// Status Pill at Top-Right
				stat_txt := if ctrl.items.len > 0 { ctrl.items[0] } else { 'ONLINE' }
				stat_w := f32(stat_txt.len * 7 + 16)
				stat_x := ctrl.x + ctrl.w - stat_w - 10.0
				stat_y := ctrl.y + 10.0
				stat_bg := match stat_txt.to_upper() {
					'ONLINE', 'READY' { if win.theme.is_dark { gg.rgb(6, 78, 59) } else { gg.rgb(209, 250, 229) } }
					'DEPLOYING', 'BUSY' { if win.theme.is_dark { gg.rgb(120, 53, 15) } else { gg.rgb(254, 243, 199) } }
					'ERROR', 'OFFLINE' { if win.theme.is_dark { gg.rgb(127, 29, 29) } else { gg.rgb(254, 226, 226) } }
					else { if win.theme.is_dark { gg.rgb(30, 58, 138) } else { gg.rgb(219, 234, 254) } }
				}
				stat_fg := match stat_txt.to_upper() {
					'ONLINE', 'READY' { if win.theme.is_dark { gg.rgb(110, 231, 183) } else { gg.rgb(5, 150, 105) } }
					'DEPLOYING', 'BUSY' { if win.theme.is_dark { gg.rgb(252, 211, 77) } else { gg.rgb(217, 119, 6) } }
					'ERROR', 'OFFLINE' { if win.theme.is_dark { gg.rgb(252, 165, 165) } else { gg.rgb(220, 38, 38) } }
					else { if win.theme.is_dark { gg.rgb(147, 197, 253) } else { gg.rgb(37, 99, 235) } }
				}
				win.gg_ctx.draw_rounded_rect_filled(stat_x, stat_y, stat_w, 20.0, 4.0, stat_bg)
				win.gg_ctx.draw_text2(
					x: int(stat_x + 8)
					y: int(stat_y + 4)
					text: clean_text(stat_txt)
					color: stat_fg
					size: 10
					bold: true
				)

				// Title (truncated so it never overlaps the status badge)
				max_title_w := stat_x - (ctrl.x + 68.0) - 6.0
				disp_title := truncate_text_to_width(win, ctrl.title, max_title_w)
				win.gg_ctx.draw_text2(
					x: int(ctrl.x + 68)
					y: int(ctrl.y + 14)
					text: disp_title
					color: fg
					size: 13
					bold: true
				)

				// Category / Subtitle (truncated to fit card width)
				if ctrl.placeholder.len > 0 {
					max_sub_w := ctrl.w - 78.0
					disp_sub := truncate_text_to_width(win, ctrl.placeholder, max_sub_w)
					win.gg_ctx.draw_text2(
						x: int(ctrl.x + 68)
						y: int(ctrl.y + 38)
						text: disp_sub
						color: gg.rgb(148, 163, 184)
						size: 11
					)
				}
			}
			'media_player' {
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 10.0, surface)
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 10.0, border_c)

				// Cover Art Image Box (72x72)
				cov_sz := f32(72.0)
				win.draw_image_fit(ctrl.text_value, ctrl.x + 14.0, ctrl.y + 16.0, cov_sz, cov_sz, '')
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x + 14.0, ctrl.y + 16.0, cov_sz, cov_sz, 6.0, border_c)

				// Track Title & Artist
				track_left := ctrl.x + 98.0
				win.gg_ctx.draw_text2(
					x: int(track_left)
					y: int(ctrl.y + 14)
					text: clean_text(ctrl.title)
					color: fg
					size: 14
					bold: true
				)
				win.gg_ctx.draw_text2(
					x: int(track_left)
					y: int(ctrl.y + 32)
					text: clean_text(ctrl.placeholder)
					color: gg.rgb(148, 163, 184)
					size: 11
				)

				// Progress Bar Track
				bar_x := track_left
				bar_y := ctrl.y + 54.0
				bar_w := ctrl.w - 112.0
				bar_h := f32(6.0)
				win.gg_ctx.draw_rounded_rect_filled(bar_x, bar_y, bar_w, bar_h, 3.0, if win.theme.is_dark { gg.rgb(55, 65, 81) } else { gg.rgb(209, 213, 219) })
				
				tot_sec := if ctrl.int_value > 0 { ctrl.int_value } else { 180 }
				elapsed_sec := int(ctrl.min_val)
				progress_pct := math.max(0.0, math.min(1.0, f64(elapsed_sec) / f64(tot_sec)))
				elapsed_w := bar_w * f32(progress_pct)
				if elapsed_w > 0 {
					win.gg_ctx.draw_rounded_rect_filled(bar_x, bar_y, elapsed_w, bar_h, 3.0, accent)
					win.gg_ctx.draw_circle_filled(bar_x + elapsed_w, bar_y + 3.0, 5.0, gg.rgb(255, 255, 255))
				}

				// Timestamps
				time_txt := '${elapsed_sec / 60:02d}:${elapsed_sec % 60:02d} / ${tot_sec / 60:02d}:${tot_sec % 60:02d}'
				win.gg_ctx.draw_text2(
					x: int(bar_x)
					y: int(ctrl.y + 68)
					text: time_txt
					color: gg.rgb(148, 163, 184)
					size: 10
				)

				// Play/Pause & Skip Buttons
				play_txt := if ctrl.bool_value { '|| PAUSE' } else { '> PLAY' }
				play_btn_x := ctrl.x + ctrl.w - 88.0
				play_btn_y := ctrl.y + 66.0
				win.gg_ctx.draw_rounded_rect_filled(play_btn_x, play_btn_y, 74.0, 24.0, 4.0, accent)
				win.gg_ctx.draw_text2(
					x: int(play_btn_x + 10)
					y: int(play_btn_y + 5)
					text: play_txt
					color: gg.Color{ r: 255, g: 255, b: 255 }
					size: 10
					bold: true
				)
			}
			'hero_banner' {
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 12.0, surface)
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 12.0, border_c)

				// Right Hero Illustration (210x148)
				ill_pad := f32(10.0)
				ill_w := f32(210.0)
				ill_h := ctrl.h - ill_pad * 2.0
				ill_x := ctrl.x + ctrl.w - ill_w - ill_pad
				ill_y := ctrl.y + ill_pad
				win.draw_image_fit(ctrl.text_value, ill_x, ill_y, ill_w, ill_h, '')
				win.gg_ctx.draw_rounded_rect_empty(ill_x, ill_y, ill_w, ill_h, 8.0, border_c)

				// Left Content
				badge_str := if ctrl.items.len > 2 { ctrl.items[2] } else { 'FEATURED' }
				badge_w := f32(badge_str.len * 7 + 14)
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x + 16.0, ctrl.y + 14.0, badge_w, 18.0, 4.0, accent)
				win.gg_ctx.draw_text2(
					x: int(ctrl.x + 23)
					y: int(ctrl.y + 17)
					text: clean_text(badge_str)
					color: gg.Color{ r: 255, g: 255, b: 255 }
					size: 10
					bold: true
				)

				// Title
				win.gg_ctx.draw_text2(
					x: int(ctrl.x + 16)
					y: int(ctrl.y + 40)
					text: clean_text(ctrl.title)
					color: fg
					size: 18
					bold: true
				)

				// Subtitle
				if ctrl.placeholder.len > 0 {
					win.gg_ctx.draw_text2(
						x: int(ctrl.x + 16)
						y: int(ctrl.y + 68)
						text: clean_text(ctrl.placeholder)
						color: gg.rgb(148, 163, 184)
						size: 12
					)
				}

				// Primary CTA & Secondary Button
				cta1 := if ctrl.items.len > 0 { ctrl.items[0] } else { '[Get Started]' }
				cta2 := if ctrl.items.len > 1 { ctrl.items[1] } else { '[Learn More]' }

				btn1_x := ctrl.x + 16.0
				btn1_y := ctrl.y + 112.0
				win.gg_ctx.draw_rounded_rect_filled(btn1_x, btn1_y, 118.0, 32.0, 6.0, accent)
				win.gg_ctx.draw_text2(
					x: int(btn1_x + 12)
					y: int(btn1_y + 8)
					text: clean_text(cta1)
					color: gg.Color{ r: 255, g: 255, b: 255 }
					size: 11
					bold: true
				)

				btn2_x := ctrl.x + 144.0
				btn2_y := btn1_y
				win.gg_ctx.draw_rounded_rect_empty(btn2_x, btn2_y, 118.0, 32.0, 6.0, border_c)
				win.gg_ctx.draw_text2(
					x: int(btn2_x + 12)
					y: int(btn2_y + 8)
					text: clean_text(cta2)
					color: fg
					size: 11
					bold: true
				)
			}
			'vector_icon' {
				v_color := if ctrl.accent_color.len > 0 { parse_hex_color(ctrl.accent_color) } else { fg }
				sz := math.min(ctrl.w, ctrl.h)
				draw_vector_icon_glyph(win.gg_ctx, ctrl.icon_vector, ctrl.x, ctrl.y, sz, v_color)
			}
			'sidebar', 'nav_rail' {
				is_rail := ctrl.is_collapsed || ctrl.kind == 'nav_rail'
				sb_w := if is_rail { f32(64.0) } else { f32(220.0) }
				ctrl.w = sb_w
				draw_elevation_shadow(win.gg_ctx, ctrl.x, ctrl.y, ctrl.w, ctrl.h, 8.0, 2, win.theme.is_dark)
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 8.0, surface)
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 8.0, border_c)

				hdr_h := f32(40.0)
				hdr_txt := if is_rail { '' } else { if ctrl.title.len > 0 { ctrl.title } else { 'Navigation' } }
				if hdr_txt.len > 0 {
					win.gg_ctx.draw_text2(x: int(ctrl.x + 14), y: int(ctrl.y + 12), text: hdr_txt, color: fg, size: 14, bold: true)
				}
				tgl_x := ctrl.x + ctrl.w - 30.0
				tgl_y := ctrl.y + 12.0
				draw_vector_icon_glyph(win.gg_ctx, if is_rail { 'chevron_right' } else { 'chevron_left' }, tgl_x, tgl_y, 16.0, border_c)
				win.gg_ctx.draw_line(ctrl.x, ctrl.y + hdr_h, ctrl.x + ctrl.w, ctrl.y + hdr_h, border_c)

				mut item_y := ctrl.y + hdr_h + 8.0
				item_h := f32(36.0)
				for item in ctrl.sidebar_items {
					is_hov := win.mouse_x >= ctrl.x + 6.0 && win.mouse_x <= ctrl.x + ctrl.w - 6.0 && win.mouse_y >= item_y && win.mouse_y <= item_y + item_h
					if item.is_active {
						win.gg_ctx.draw_rounded_rect_filled(ctrl.x + 6.0, item_y, ctrl.w - 12.0, item_h, 6.0, accent)
						win.gg_ctx.draw_rounded_rect_filled(ctrl.x + 8.0, item_y + 6.0, 3.0, item_h - 12.0, 2.0, gg.rgb(255, 255, 255))
					} else if is_hov {
						win.gg_ctx.draw_rounded_rect_filled(ctrl.x + 6.0, item_y, ctrl.w - 12.0, item_h, 6.0, surface_hover)
					}

					item_color := if item.is_active { gg.rgb(255, 255, 255) } else { fg }
					icon_name := if item.icon.len > 0 { item.icon } else { 'star' }
					icon_x := if is_rail { ctrl.x + (ctrl.w - 18.0) / 2.0 } else { ctrl.x + 16.0 }
					draw_vector_icon_glyph(win.gg_ctx, icon_name, icon_x, item_y + 9.0, 18.0, item_color)

					if !is_rail {
						win.gg_ctx.draw_text2(x: int(ctrl.x + 44), y: int(item_y + 10), text: clean_text(item.title), color: item_color, size: 13, bold: item.is_active)
						if item.badge.len > 0 {
							bdg_w := measure_text_width(win, item.badge) + 10.0
							bdg_x := ctrl.x + ctrl.w - bdg_w - 14.0
							win.gg_ctx.draw_rounded_rect_filled(bdg_x, item_y + 8.0, bdg_w, 20.0, 10.0, if item.is_active { gg.Color{r: 255, g: 255, b: 255, a: 80} } else { accent })
							win.gg_ctx.draw_text2(x: int(bdg_x + 5), y: int(item_y + 11), text: item.badge, color: gg.rgb(255, 255, 255), size: 11, bold: true)
						}
					}
					item_y += item_h + 4.0
				}
			}
			'area_chart', 'spline_chart' {
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 8.0, surface)
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 8.0, border_c)
				if ctrl.title.len > 0 {
					win.gg_ctx.draw_text2(x: int(ctrl.x + 12), y: int(ctrl.y + 10), text: clean_text(ctrl.title), color: fg, size: 13, bold: true)
				}
				chart_y := ctrl.y + 36.0
				chart_h := ctrl.h - 48.0
				chart_x := ctrl.x + 16.0
				chart_w := ctrl.w - 32.0
				if ctrl.f64_list.len >= 2 {
					mut max_val := f64(0.001)
					mut min_val := f64(0.0)
					for v in ctrl.f64_list {
						if v > max_val { max_val = v }
						if v < min_val { min_val = v }
					}
					val_range := if max_val - min_val > 0.0 { max_val - min_val } else { 1.0 }
					pts_count := ctrl.f64_list.len
					step_x := chart_w / f32(pts_count - 1)
					mut pts := []f32{}
					for idx, v in ctrl.f64_list {
						px := chart_x + f32(idx) * step_x
						norm := f32((v - min_val) / val_range)
						py := chart_y + chart_h - (norm * chart_h)
						pts << px
						pts << py
					}
					for seg := 0; seg < pts.len - 2; seg += 2 {
						x1 := pts[seg]
						y1 := pts[seg+1]
						x2 := pts[seg+2]
						y2 := pts[seg+3]
						bottom_y := chart_y + chart_h
						area_color := gg.Color{ r: accent.r, g: accent.g, b: accent.b, a: 45 }
						win.gg_ctx.draw_triangle_filled(x1, y1, x2, y2, x1, bottom_y, area_color)
						win.gg_ctx.draw_triangle_filled(x2, y2, x2, bottom_y, x1, bottom_y, area_color)
						win.gg_ctx.draw_line(x1, y1, x2, y2, accent)
						win.gg_ctx.draw_circle_filled(x1, y1, 3.0, accent)
					}
					if pts.len >= 2 {
						last_x := pts[pts.len-2]
						last_y := pts[pts.len-1]
						win.gg_ctx.draw_circle_filled(last_x, last_y, 3.5, accent)
					}
				}
			}
			'activity_heatmap', 'contribution_grid' {
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 8.0, surface)
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 8.0, border_c)
				if ctrl.title.len > 0 {
					win.gg_ctx.draw_text2(x: int(ctrl.x + 12), y: int(ctrl.y + 10), text: clean_text(ctrl.title), color: fg, size: 13, bold: true)
				}
				grid_x := ctrl.x + 36.0
				grid_y := ctrl.y + 34.0
				cell_sz := f32(11.0)
				cell_gap := f32(3.0)
				weeks_count := if ctrl.int_value > 0 { ctrl.int_value } else { 20 }
				day_labels := ['M', 'W', 'F']
				day_indices := [1, 3, 5]
				for d_i, d_lbl in day_labels {
					ly := grid_y + f32(day_indices[d_i]) * (cell_sz + cell_gap) + 1.0
					win.gg_ctx.draw_text2(x: int(ctrl.x + 14), y: int(ly), text: d_lbl, color: border_c, size: 10)
				}
				levels := if ctrl.heatmap_levels.len >= 5 { ctrl.heatmap_levels } else { ['#161b22', '#0e4429', '#006d32', '#26a641', '#39d353'] }
				for w_i in 0 .. weeks_count {
					for d_i in 0 .. 7 {
						cx := grid_x + f32(w_i) * (cell_sz + cell_gap)
						cy := grid_y + f32(d_i) * (cell_sz + cell_gap)
						mut val := 0
						if d_i < ctrl.heatmap_data.len && w_i < ctrl.heatmap_data[d_i].len {
							val = ctrl.heatmap_data[d_i][w_i]
						}
						lvl_idx := if val <= 0 { 0 } else if val == 1 { 1 } else if val == 2 { 2 } else if val <= 4 { 3 } else { 4 }
						lvl_c := parse_hex_color(levels[lvl_idx])
						win.gg_ctx.draw_rounded_rect_filled(cx, cy, cell_sz, cell_sz, 2.0, lvl_c)
					}
				}
			}
			'tree_table' {
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0, surface)
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0, border_c)
				hdr_h := f32(30.0)
				win.gg_ctx.draw_rect_filled(ctrl.x, ctrl.y, ctrl.w, hdr_h, if win.theme.is_dark { gg.rgb(30, 32, 42) } else { gg.rgb(230, 235, 240) })
				win.gg_ctx.draw_line(ctrl.x, ctrl.y + hdr_h, ctrl.x + ctrl.w, ctrl.y + hdr_h, border_c)
				col_count := f32(math.max(1, ctrl.headers.len))
				col_w := ctrl.w / col_count
				for h_i, h_txt in ctrl.headers {
					hx := ctrl.x + f32(h_i) * col_w + 10.0
					win.gg_ctx.draw_text2(x: int(hx), y: int(ctrl.y + 7), text: clean_text(h_txt), color: fg, size: 12, bold: true)
				}
				mut row_y := ctrl.y + hdr_h
				row_h := f32(28.0)
				for node in ctrl.tree_table_nodes {
					if row_y + row_h > ctrl.y + ctrl.h { break }
					is_hov := win.mouse_x >= ctrl.x && win.mouse_x <= ctrl.x + ctrl.w && win.mouse_y >= row_y && win.mouse_y <= row_y + row_h
					if is_hov {
						win.gg_ctx.draw_rect_filled(ctrl.x, row_y, ctrl.w, row_h, surface_hover)
					}
					arrow_x := ctrl.x + 8.0
					arrow_y := row_y + 8.0
					if node.children.len > 0 {
						draw_vector_icon_glyph(win.gg_ctx, if node.is_expanded { 'chevron_down' } else { 'chevron_right' }, arrow_x, arrow_y, 12.0, border_c)
					} else {
						win.gg_ctx.draw_circle_filled(arrow_x + 6.0, arrow_y + 6.0, 2.0, border_c)
					}
					for v_i, val in node.values {
						vx := if v_i == 0 { ctrl.x + 24.0 } else { ctrl.x + f32(v_i) * col_w + 8.0 }
						win.gg_ctx.draw_text2(x: int(vx), y: int(row_y + 6), text: clean_text(val), color: fg, size: 12)
					}
					win.gg_ctx.draw_line(ctrl.x, row_y + row_h, ctrl.x + ctrl.w, row_y + row_h, border_c)
					row_y += row_h
					if node.is_expanded {
						for child in node.children {
							if row_y + row_h > ctrl.y + ctrl.h { break }
							c_arrow_x := ctrl.x + 26.0
							c_arrow_y := row_y + 8.0
							win.gg_ctx.draw_circle_filled(c_arrow_x + 6.0, c_arrow_y + 6.0, 2.0, border_c)
							for cv_i, cval in child.values {
								cvx := if cv_i == 0 { ctrl.x + 42.0 } else { ctrl.x + f32(cv_i) * col_w + 8.0 }
								win.gg_ctx.draw_text2(x: int(cvx), y: int(row_y + 6), text: clean_text(cval), color: fg, size: 12)
							}
							win.gg_ctx.draw_line(ctrl.x, row_y + row_h, ctrl.x + ctrl.w, row_y + row_h, border_c)
							row_y += row_h
						}
					}
				}
			}
			'calendar' {
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 8.0, surface)
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 8.0, border_c)
				hdr_h := f32(36.0)
				month_names := ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December']
				m_idx := if ctrl.cal_month >= 1 && ctrl.cal_month <= 12 { ctrl.cal_month - 1 } else { 0 }
				m_name := '${month_names[m_idx]} ${ctrl.cal_year}'
				win.gg_ctx.draw_text2(x: int(ctrl.x + 14), y: int(ctrl.y + 10), text: m_name, color: fg, size: 14, bold: true)
				prev_x := ctrl.x + ctrl.w - 56.0
				next_x := ctrl.x + ctrl.w - 28.0
				arr_y := ctrl.y + 10.0
				draw_vector_icon_glyph(win.gg_ctx, 'chevron_left', prev_x, arr_y, 16.0, border_c)
				draw_vector_icon_glyph(win.gg_ctx, 'chevron_right', next_x, arr_y, 16.0, border_c)
				win.gg_ctx.draw_line(ctrl.x, ctrl.y + hdr_h, ctrl.x + ctrl.w, ctrl.y + hdr_h, border_c)

				weekdays := ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
				day_w := (ctrl.w - 16.0) / 7.0
				mut day_x := ctrl.x + 8.0
				for wd in weekdays {
					win.gg_ctx.draw_text2(x: int(day_x + (day_w - 14.0) / 2.0), y: int(ctrl.y + hdr_h + 6), text: wd, color: border_c, size: 11, bold: true)
					day_x += day_w
				}
				grid_top := ctrl.y + hdr_h + 24.0
				cell_h := (ctrl.h - hdr_h - 32.0) / 6.0
				days_in_m := if ctrl.cal_month in [1, 3, 5, 7, 8, 10, 12] { 31 } else if ctrl.cal_month == 2 { 28 } else { 30 }
				start_offset := (ctrl.cal_month * 2 + ctrl.cal_year) % 7
				for day := 1; day <= days_in_m; day++ {
					slot := day - 1 + start_offset
					row := slot / 7
					col := slot % 7
					dx := ctrl.x + 8.0 + f32(col) * day_w
					dy := grid_top + f32(row) * cell_h
					is_selected := (day == ctrl.cal_selected_day)
					if is_selected {
						win.gg_ctx.draw_rounded_rect_filled(dx + 2.0, dy + 2.0, day_w - 4.0, cell_h - 4.0, 6.0, accent)
					}
					txt_c := if is_selected { gg.rgb(255, 255, 255) } else { fg }
					d_str := '${day}'
					tw := measure_text_width(win, d_str)
					win.gg_ctx.draw_text2(x: int(dx + (day_w - tw) / 2.0), y: int(dy + (cell_h - 12.0) / 2.0), text: d_str, color: txt_c, size: 12, bold: is_selected)
				}
			}
			'markdown_view' {
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0, surface)
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0, border_c)
				lines := ctrl.markdown_content.split('\n')
				mut my := ctrl.y + 10.0
				for line in lines {
					if my + 18.0 > ctrl.y + ctrl.h { break }
					trimmed := line.trim_space()
					if trimmed.starts_with('# ') {
						h_txt := clean_text(trimmed[2..])
						win.gg_ctx.draw_text2(x: int(ctrl.x + 12), y: int(my), text: h_txt, color: fg, size: 16, bold: true)
						my += 22.0
					} else if trimmed.starts_with('## ') {
						h_txt := clean_text(trimmed[3..])
						win.gg_ctx.draw_text2(x: int(ctrl.x + 12), y: int(my), text: h_txt, color: accent, size: 14, bold: true)
						my += 20.0
					} else if trimmed.starts_with('> ') {
						q_txt := clean_text(trimmed[2..])
						win.gg_ctx.draw_line(ctrl.x + 12, my, ctrl.x + 12, my + 16, accent)
						win.gg_ctx.draw_text2(x: int(ctrl.x + 20), y: int(my), text: q_txt, color: border_c, size: 12)
						my += 18.0
					} else if trimmed.starts_with('- ') || trimmed.starts_with('* ') {
						b_txt := clean_text(trimmed[2..])
						win.gg_ctx.draw_circle_filled(ctrl.x + 16, my + 6, 2.5, accent)
						win.gg_ctx.draw_text2(x: int(ctrl.x + 24), y: int(my), text: b_txt, color: fg, size: 12)
						my += 18.0
					} else if trimmed.starts_with('```') {
						win.gg_ctx.draw_rect_filled(ctrl.x + 12, my, ctrl.w - 24, 20.0, if win.theme.is_dark { gg.rgb(20, 22, 30) } else { gg.rgb(220, 225, 230) })
						my += 22.0
					} else if trimmed.len > 0 {
						win.gg_ctx.draw_text2(x: int(ctrl.x + 12), y: int(my), text: clean_text(trimmed), color: fg, size: 12)
						my += 18.0
					} else {
						my += 8.0
					}
				}
			}
			'masked_input' {
				win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0, surface)
				win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0, if ctrl.is_focused { accent } else { border_c })
				if ctrl.is_focused {
					draw_focus_ring(win.gg_ctx, ctrl.x, ctrl.y, ctrl.w, ctrl.h, 6.0, accent)
				}
				disp_text := if ctrl.text_value.len > 0 { ctrl.text_value } else { ctrl.mask_pattern }
				txt_color := if ctrl.text_value.len > 0 { fg } else { border_c }
				win.gg_ctx.draw_text2(x: int(ctrl.x + 10), y: int(ctrl.y + 8), text: clean_text(disp_text), color: txt_color, size: 13)
			}
			'inline_label' {
				if ctrl.is_editing {
					win.gg_ctx.draw_rounded_rect_filled(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 4.0, surface)
					win.gg_ctx.draw_rounded_rect_empty(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 4.0, accent)
					draw_focus_ring(win.gg_ctx, ctrl.x, ctrl.y, ctrl.w, ctrl.h, 4.0, accent)
					win.gg_ctx.draw_text2(x: int(ctrl.x + 6), y: int(ctrl.y + 6), text: clean_text(ctrl.text_value), color: fg, size: 13)
					chk_x := ctrl.x + ctrl.w - 36.0
					draw_vector_icon_glyph(win.gg_ctx, 'check', chk_x, ctrl.y + 6.0, 14.0, parse_hex_color('#10b981'))
					draw_vector_icon_glyph(win.gg_ctx, 'close', chk_x + 18.0, ctrl.y + 6.0, 14.0, parse_hex_color('#ef4444'))
				} else {
					lbl_txt := if ctrl.text_value.len > 0 { ctrl.text_value } else { ctrl.title }
					win.gg_ctx.draw_text2(x: int(ctrl.x), y: int(ctrl.y + 6), text: clean_text(lbl_txt), color: fg, size: 13)
					tw := measure_text_width(win, lbl_txt)
					draw_vector_icon_glyph(win.gg_ctx, 'gear', ctrl.x + tw + 8.0, ctrl.y + 8.0, 12.0, border_c)
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

	win.render_drawer()
	win.render_toasts()
	win.render_modal()
	win.render_tooltip()
	win.render_command_palette()
	win.render_context_menu()
	win.render_menu_bar()
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

		has_icon := toast.icon_path.len > 0
		t_w := f32(math.min(320, win.width - 40))
		t_h := f32(56.0)
		tx := f32(win.width) - t_w - 20.0
		
		t_color := match toast.variant {
			'success' { parse_hex_color('#10b981') }
			'warning' { parse_hex_color('#f59e0b') }
			'error' { parse_hex_color('#ef4444') }
			'cloud' { parse_hex_color('#14b8a6') }
			'security' { parse_hex_color('#f59e0b') }
			'database' { parse_hex_color('#a855f7') }
			else { parse_hex_color('#3b82f6') }
		}

		// Dark glass backdrop card
		win.gg_ctx.draw_rounded_rect_filled(tx, ty, t_w, t_h, 8.0, gg.rgb(32, 35, 46))
		win.gg_ctx.draw_rounded_rect_empty(tx, ty, t_w, t_h, 8.0, t_color)
		win.gg_ctx.draw_rect_filled(tx, ty, 4.0, t_h, t_color)

		text_left := if has_icon {
			icon_sz := f32(34.0)
			win.gg_ctx.draw_rounded_rect_filled(tx + 10.0, ty + 11.0, icon_sz, icon_sz, 6.0, gg.rgba(t_color.r, t_color.g, t_color.b, 35))
			win.draw_image_fit(toast.icon_path, tx + 10.0, ty + 11.0, icon_sz, icon_sz, '')
			tx + 52.0
		} else {
			tx + 16.0
		}

		win.gg_ctx.draw_text2(x: int(text_left), y: int(ty + 9), text: clean_text(toast.title), color: gg.Color{r: 255, g: 255, b: 255}, size: 13, bold: true)
		win.gg_ctx.draw_text2(x: int(text_left), y: int(ty + 29), text: clean_text(toast.message), color: gg.rgb(200, 205, 215), size: 11)
		win.gg_ctx.draw_text2(x: int(tx + t_w - 18), y: int(ty + 8), text: 'x', color: gg.rgb(180, 185, 200), size: 12, bold: true)

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

		mut title_x := bx + 20.0
		if item.icon_path.len > 0 {
			win.draw_image_fit(item.icon_path, bx + 16.0, item_y + 4.0, 20.0, 20.0, '')
			title_x = bx + 42.0
		}

		win.gg_ctx.draw_text2(x: int(title_x), y: int(item_y + 6), text: item.title, color: gg.Color{r: 255, g: 255, b: 255}, size: 13)
		if item.shortcut.len > 0 {
			win.gg_ctx.draw_text2(x: int(bx + box_w - 80), y: int(item_y + 6), text: item.shortcut, color: gg.rgb(180, 185, 200), size: 11)
		}
		item_y += 32.0
	}
}

fn (mut win SimpleWindow) render_context_menu() {
	if !win.context_menu_active { return }
	menu_w := f32(190.0)
	menu_h := f32(win.context_menu_items.len * 30 + 10)
	mx := win.context_menu_x
	my := win.context_menu_y

	win.gg_ctx.draw_rounded_rect_filled(mx, my, menu_w, menu_h, 6.0, gg.rgb(35, 38, 50))
	win.gg_ctx.draw_rounded_rect_empty(mx, my, menu_w, menu_h, 6.0, parse_hex_color(win.theme.accent_color))

	for idx, item in win.context_menu_items {
		iy := my + f32(idx * 30 + 5)
		mut text_x := mx + 12.0
		if item.icon_path.len > 0 {
			win.draw_image_fit(item.icon_path, mx + 10.0, iy + 6.0, 16.0, 16.0, '')
			text_x = mx + 32.0
		}
		win.gg_ctx.draw_text2(x: int(text_x), y: int(iy + 6), text: item.title, color: gg.Color{r: 255, g: 255, b: 255}, size: 13)
		if item.shortcut.len > 0 {
			win.gg_ctx.draw_text2(x: int(mx + menu_w - 60), y: int(iy + 6), text: item.shortcut, color: gg.rgb(160, 165, 180), size: 11)
		}
	}
}

fn (mut win SimpleWindow) render_menu_bar() {
	if !win.menu_bar_visible || win.menu_categories.len == 0 {
		return
	}

	bar_h := f32(28.0)
	bar_w := f32(win.width)

	fg := parse_hex_color(win.theme.font_color)
	accent := parse_hex_color(win.theme.accent_color)
	bar_bg := if win.theme.is_dark { gg.rgb(28, 30, 38) } else { gg.rgb(238, 240, 244) }
	bar_border := if win.theme.is_dark { gg.rgb(55, 60, 75) } else { gg.rgb(215, 220, 228) }
	hover_bg := if win.theme.is_dark { gg.rgb(45, 50, 65) } else { gg.rgb(222, 226, 234) }

	// Draw top menubar background and bottom border
	win.gg_ctx.draw_rect_filled(0, 0, bar_w, bar_h, bar_bg)
	win.gg_ctx.draw_line(0, bar_h, bar_w, bar_h, bar_border)

	mut cur_x := f32(12.0)
	mut open_menu_x := f32(0.0)

	for idx, cat in win.menu_categories {
		txt_w := f32(cat.title.len * 8 + 16)
		is_cat_hover := win.mouse_x >= cur_x && win.mouse_x < cur_x + txt_w && win.mouse_y >= 0 && win.mouse_y <= bar_h
		is_cat_active := win.active_menu_idx == idx

		if is_cat_active {
			open_menu_x = cur_x
			win.gg_ctx.draw_rounded_rect_filled(cur_x, 3.0, txt_w, bar_h - 6.0, 4.0, accent)
		} else if is_cat_hover {
			win.gg_ctx.draw_rounded_rect_filled(cur_x, 3.0, txt_w, bar_h - 6.0, 4.0, hover_bg)
		}

		cat_txt_c := if is_cat_active { gg.rgb(255, 255, 255) } else { fg }
		win.gg_ctx.draw_text2(
			x: int(cur_x + 8.0)
			y: int((bar_h - 14.0) / 2.0)
			text: cat.title
			color: cat_txt_c
			size: 13
		)

		cur_x += txt_w + 4.0
	}

	// Render open dropdown menu
	if win.active_menu_idx >= 0 && win.active_menu_idx < win.menu_categories.len {
		cat := win.menu_categories[win.active_menu_idx]
		if cat.items.len > 0 {
			menu_x := open_menu_x
			menu_y := bar_h + 2.0
			menu_w := f32(200.0)
			mut total_menu_h := f32(8.0)
			for item in cat.items {
				if item.is_separator {
					total_menu_h += 7.0
				} else {
					total_menu_h += 26.0
				}
			}

			popup_bg := if win.theme.is_dark { gg.rgb(32, 35, 45) } else { gg.rgb(255, 255, 255) }
			popup_border := if win.theme.is_dark { gg.rgb(65, 72, 90) } else { gg.rgb(205, 212, 222) }
			popup_hover := accent
			popup_muted := if win.theme.is_dark { gg.rgb(150, 155, 175) } else { gg.rgb(125, 130, 145) }

			// Drop shadow
			win.gg_ctx.draw_rounded_rect_filled(menu_x + 2.0, menu_y + 2.0, menu_w, total_menu_h, 6.0, gg.rgba(0, 0, 0, 40))
			// Popup box
			win.gg_ctx.draw_rounded_rect_filled(menu_x, menu_y, menu_w, total_menu_h, 6.0, popup_bg)
			win.gg_ctx.draw_rounded_rect_empty(menu_x, menu_y, menu_w, total_menu_h, 6.0, popup_border)

			mut item_y := menu_y + 4.0
			for item in cat.items {
				if item.is_separator {
					win.gg_ctx.draw_line(menu_x + 8.0, item_y + 3.0, menu_x + menu_w - 8.0, item_y + 3.0, bar_border)
					item_y += 7.0
				} else {
					is_item_hover := win.mouse_x >= menu_x && win.mouse_x <= menu_x + menu_w && win.mouse_y >= item_y && win.mouse_y < item_y + 26.0 && !item.disabled

					if is_item_hover {
						win.gg_ctx.draw_rounded_rect_filled(menu_x + 4.0, item_y, menu_w - 8.0, 24.0, 4.0, popup_hover)
					}

					item_fg := if item.disabled {
						popup_muted
					} else if is_item_hover {
						gg.rgb(255, 255, 255)
					} else {
						fg
					}

					item_title := if item.icon.len > 0 { '${item.icon} ${item.title}' } else { item.title }
					win.gg_ctx.draw_text2(
						x: int(menu_x + 12.0)
						y: int(item_y + 5.0)
						text: item_title
						color: item_fg
						size: 13
					)

					if item.shortcut.len > 0 {
						sc_color := if is_item_hover { gg.rgb(230, 235, 255) } else { popup_muted }
						win.gg_ctx.draw_text2(
							x: int(menu_x + menu_w - 65.0)
							y: int(item_y + 5.0)
							text: item.shortcut
							color: sc_color
							size: 11
						)
					}

					item_y += 26.0
				}
			}
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
			if max_l > 45 {
				max_l = 45
			}
			weights[c_idx] = f32(math.max(6, max_l))
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
	// Semi-transparent backdrop overlay
	win.gg_ctx.draw_rect_filled(0, 0, f32(win.width), f32(win.height), gg.rgba(0, 0, 0, 175))

	layout := win.get_modal_layout()

	modal_bg := if win.theme.is_dark { gg.rgb(24, 27, 36) } else { gg.rgb(255, 255, 255) }
	accent := win.get_dialog_accent_color()
	fg := parse_hex_color(win.theme.font_color)
	border_c := if win.theme.is_dark { gg.rgb(55, 60, 75) } else { gg.rgb(215, 220, 230) }
	muted_fg := if win.theme.is_dark { gg.rgb(150, 155, 175) } else { gg.rgb(115, 120, 135) }

	// Main Card Background
	win.gg_ctx.draw_rounded_rect_filled(layout.bx, layout.by, layout.bw, layout.bh, 14.0, modal_bg)
	win.gg_ctx.draw_rounded_rect_empty(layout.bx, layout.by, layout.bw, layout.bh, 14.0, accent)

	// Top accent strip
	win.gg_ctx.draw_rounded_rect_filled(layout.bx + 20.0, layout.by, layout.bw - 40.0, 3.0, 1.5, accent)

	// Close 'X' Button in Top-Right
	is_close_hov := win.mouse_x >= layout.close_x && win.mouse_x <= layout.close_x + layout.close_sz
		&& win.mouse_y >= layout.close_y && win.mouse_y <= layout.close_y + layout.close_sz
	if is_close_hov {
		win.gg_ctx.draw_rounded_rect_filled(layout.close_x - 3.0, layout.close_y - 3.0, layout.close_sz + 6.0, layout.close_sz + 6.0, 4.0, if win.theme.is_dark { gg.rgb(45, 48, 62) } else { gg.rgb(235, 238, 245) })
	}
	win.gg_ctx.draw_text2(
		x: int(layout.close_x + 3)
		y: int(layout.close_y)
		text: 'x'
		color: if is_close_hov { fg } else { muted_fg }
		size: 14
		bold: true
	)

	// Left Image Icon (if present)
	if layout.has_image {
		win.gg_ctx.draw_rounded_rect_filled(layout.img_x - 3.0, layout.img_y - 3.0, layout.img_sz + 6.0, layout.img_sz + 6.0, 12.0, gg.rgba(accent.r, accent.g, accent.b, 40))
		win.draw_image_fit(win.modal_image_path, layout.img_x, layout.img_y, layout.img_sz, layout.img_sz, '')
	}

	// Title & Divider
	win.gg_ctx.draw_text2(
		x: int(layout.content_x)
		y: int(layout.by + 16)
		text: clean_text(win.modal_title)
		color: fg
		size: 16
		bold: true
	)
	win.gg_ctx.draw_line(layout.content_x, layout.by + 42, layout.bx + layout.bw - 20.0, layout.by + 42, border_c)

	// Message lines
	lines := wrap_text_to_width(win, win.modal_message, layout.content_w)
	mut my := layout.by + 52.0
	for line in lines {
		win.gg_ctx.draw_text2(x: int(layout.content_x), y: int(my), text: line, color: fg, size: 13)
		my += 18.0
	}

	// Optional Detail text callout
	if win.modal_detail.len > 0 {
		chip_bg := if win.theme.is_dark { gg.rgb(32, 35, 48) } else { gg.rgb(238, 242, 248) }
		win.gg_ctx.draw_rounded_rect_filled(layout.content_x, layout.detail_y, layout.content_w, 24.0, 4.0, chip_bg)
		win.gg_ctx.draw_rounded_rect_empty(layout.content_x, layout.detail_y, layout.content_w, 24.0, 4.0, border_c)
		win.gg_ctx.draw_text2(
			x: int(layout.content_x + 8)
			y: int(layout.detail_y + 5)
			text: clean_text(win.modal_detail)
			color: muted_fg
			size: 11
			mono: true
		)
	}

	// Optional Input Mode Text Box
	if win.modal_input_mode {
		input_bg := if win.theme.is_dark { gg.rgb(18, 20, 28) } else { gg.rgb(248, 250, 252) }
		win.gg_ctx.draw_rounded_rect_filled(layout.content_x, layout.input_y, layout.input_w, layout.input_h, 6.0, input_bg)
		win.gg_ctx.draw_rounded_rect_empty(layout.content_x, layout.input_y, layout.input_w, layout.input_h, 6.0, accent)

		if win.modal_input_val.len > 0 {
			win.gg_ctx.draw_text2(
				x: int(layout.content_x + 10)
				y: int(layout.input_y + (layout.input_h - 14) / 2.0)
				text: win.modal_input_val
				color: fg
				size: 14
			)
		} else if win.modal_input_holder.len > 0 {
			win.gg_ctx.draw_text2(
				x: int(layout.content_x + 10)
				y: int(layout.input_y + (layout.input_h - 14) / 2.0)
				text: win.modal_input_holder
				color: muted_fg
				size: 14
			)
		}

		// Blinking caret cursor
		if (time.now().unix_milli() / 500) % 2 == 0 {
			caret_pos := math.max(0, math.min(win.modal_input_val.len, win.modal_input_caret))
			sub := if caret_pos <= win.modal_input_val.len {
				win.modal_input_val[0..caret_pos]
			} else {
				win.modal_input_val
			}
			caret_offset := measure_text_width(win, sub)
			cursor_x := layout.content_x + 10.0 + caret_offset
			win.gg_ctx.draw_line(cursor_x, layout.input_y + 6.0, cursor_x, layout.input_y + layout.input_h - 6.0, accent)
		}
	}

	// Optional Checkbox
	if win.modal_checkbox_txt.len > 0 {
		chk_bg := if win.modal_checkbox_val { accent } else { if win.theme.is_dark { gg.rgb(35, 38, 50) } else { gg.rgb(230, 234, 240) } }
		win.gg_ctx.draw_rounded_rect_filled(layout.content_x, layout.check_y, 16.0, 16.0, 4.0, chk_bg)
		win.gg_ctx.draw_rounded_rect_empty(layout.content_x, layout.check_y, 16.0, 16.0, 4.0, if win.modal_checkbox_val { accent } else { border_c })
		if win.modal_checkbox_val {
			win.gg_ctx.draw_text2(
				x: int(layout.content_x + 3)
				y: int(layout.check_y + 1)
				text: 'v'
				color: gg.rgb(255, 255, 255)
				size: 11
				bold: true
			)
		}
		win.gg_ctx.draw_text2(
			x: int(layout.content_x + 24)
			y: int(layout.check_y + 1)
			text: clean_text(win.modal_checkbox_txt)
			color: fg
			size: 12
		)
	}

	// Neutral Button (if present)
	if win.modal_neutral_txt.len > 0 {
		is_neu_hov := win.mouse_x >= layout.neutral_x && win.mouse_x <= layout.neutral_x + layout.neutral_w
			&& win.mouse_y >= layout.btn_y && win.mouse_y <= layout.btn_y + layout.btn_h
		neu_bg := if is_neu_hov { if win.theme.is_dark { gg.rgb(45, 48, 62) } else { gg.rgb(225, 230, 238) } } else { if win.theme.is_dark { gg.rgb(32, 35, 46) } else { gg.rgb(240, 243, 248) } }
		win.gg_ctx.draw_rounded_rect_filled(layout.neutral_x, layout.btn_y, layout.neutral_w, layout.btn_h, 6.0, neu_bg)
		win.gg_ctx.draw_rounded_rect_empty(layout.neutral_x, layout.btn_y, layout.neutral_w, layout.btn_h, 6.0, border_c)
		win.gg_ctx.draw_text2(
			x: int(layout.neutral_x + (layout.neutral_w - f32(win.modal_neutral_txt.len * 7)) / 2.0)
			y: int(layout.btn_y + 9)
			text: clean_text(win.modal_neutral_txt)
			color: fg
			size: 13
		)
	}

	// Cancel Button (if present)
	if win.modal_cancel_txt.len > 0 {
		is_can_hov := win.mouse_x >= layout.cancel_x && win.mouse_x <= layout.cancel_x + layout.cancel_w
			&& win.mouse_y >= layout.btn_y && win.mouse_y <= layout.btn_y + layout.btn_h
		can_bg := if is_can_hov { if win.theme.is_dark { gg.rgb(48, 52, 68) } else { gg.rgb(220, 225, 235) } } else { if win.theme.is_dark { gg.rgb(35, 38, 50) } else { gg.rgb(235, 238, 245) } }
		win.gg_ctx.draw_rounded_rect_filled(layout.cancel_x, layout.btn_y, layout.cancel_w, layout.btn_h, 6.0, can_bg)
		win.gg_ctx.draw_rounded_rect_empty(layout.cancel_x, layout.btn_y, layout.cancel_w, layout.btn_h, 6.0, border_c)
		win.gg_ctx.draw_text2(
			x: int(layout.cancel_x + (layout.cancel_w - f32(win.modal_cancel_txt.len * 7)) / 2.0)
			y: int(layout.btn_y + 9)
			text: clean_text(win.modal_cancel_txt)
			color: fg
			size: 13
		)
	}

	// Confirm Button
	is_cnf_hov := win.mouse_x >= layout.confirm_x && win.mouse_x <= layout.confirm_x + layout.confirm_w
		&& win.mouse_y >= layout.btn_y && win.mouse_y <= layout.btn_y + layout.btn_h
	confirm_bg := if win.modal_is_destructive {
		if is_cnf_hov { gg.rgb(255, 75, 75) } else { gg.rgb(225, 45, 45) }
	} else {
		if is_cnf_hov {
			gg.rgb(
				u8(math.min(255, int(accent.r) + 25)),
				u8(math.min(255, int(accent.g) + 25)),
				u8(math.min(255, int(accent.b) + 25)),
			)
		} else {
			accent
		}
	}
	win.gg_ctx.draw_rounded_rect_filled(layout.confirm_x, layout.btn_y, layout.confirm_w, layout.btn_h, 6.0, confirm_bg)
	confirm_txt := if win.modal_confirm_txt.len > 0 { win.modal_confirm_txt } else { 'OK' }
	win.gg_ctx.draw_text2(
		x: int(layout.confirm_x + (layout.confirm_w - f32(confirm_txt.len * 7)) / 2.0)
		y: int(layout.btn_y + 9)
		text: clean_text(confirm_txt)
		color: gg.rgb(255, 255, 255)
		size: 13
		bold: true
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

fn draw_vector_star(gg_ctx &gg.Context, cx f32, cy f32, outer_r f32, inner_r f32, is_filled bool, fill_c gg.Color, stroke_c gg.Color) {
	mut pts_x := [10]f32{}
	mut pts_y := [10]f32{}
	for i in 0 .. 10 {
		angle := -math.pi / 2.0 + f64(i) * (math.pi / 5.0)
		r := if i % 2 == 0 { outer_r } else { inner_r }
		pts_x[i] = cx + f32(r * math.cos(angle))
		pts_y[i] = cy + f32(r * math.sin(angle))
	}

	if is_filled {
		for i in 0 .. 10 {
			next_i := (i + 1) % 10
			gg_ctx.draw_triangle_filled(cx, cy, pts_x[i], pts_y[i], pts_x[next_i], pts_y[next_i], fill_c)
		}
	}

	for i in 0 .. 10 {
		next_i := (i + 1) % 10
		gg_ctx.draw_line(pts_x[i], pts_y[i], pts_x[next_i], pts_y[next_i], stroke_c)
	}
}

fn draw_vector_chevron(gg_ctx &gg.Context, cx f32, cy f32, size f32, dir string, color gg.Color) {
	half := size / 2.0
	match dir {
		'down' {
			gg_ctx.draw_line(cx - half, cy - half / 2.0, cx, cy + half / 2.0, color)
			gg_ctx.draw_line(cx, cy + half / 2.0, cx + half, cy - half / 2.0, color)
		}
		'up' {
			gg_ctx.draw_line(cx - half, cy + half / 2.0, cx, cy - half / 2.0, color)
			gg_ctx.draw_line(cx, cy - half / 2.0, cx + half, cy + half / 2.0, color)
		}
		'right' {
			gg_ctx.draw_line(cx - half / 2.0, cy - half, cx + half / 2.0, cy, color)
			gg_ctx.draw_line(cx + half / 2.0, cy, cx - half / 2.0, cy + half, color)
		}
		'left' {
			gg_ctx.draw_line(cx + half / 2.0, cy - half, cx - half / 2.0, cy, color)
			gg_ctx.draw_line(cx - half / 2.0, cy, cx + half / 2.0, cy + half, color)
		}
		else {}
	}
}

fn draw_vector_search_icon(gg_ctx &gg.Context, cx f32, cy f32, radius f32, color gg.Color) {
	gg_ctx.draw_circle_empty(cx - 2.0, cy - 2.0, radius, color)
	gg_ctx.draw_line(cx + 2.0, cy + 2.0, cx + 7.0, cy + 7.0, color)
}

fn draw_vector_calendar_icon(gg_ctx &gg.Context, x f32, y f32, color gg.Color) {
	gg_ctx.draw_rounded_rect_empty(x, y, 14.0, 14.0, 3.0, color)
	gg_ctx.draw_line(x, y + 4.0, x + 14.0, y + 4.0, color)
	gg_ctx.draw_line(x + 3.0, y - 2.0, x + 3.0, y + 2.0, color)
	gg_ctx.draw_line(x + 10.0, y - 2.0, x + 10.0, y + 2.0, color)
	gg_ctx.draw_rect_filled(x + 3.5, y + 7.0, 2.0, 2.0, color)
	gg_ctx.draw_rect_filled(x + 8.5, y + 7.0, 2.0, 2.0, color)
	gg_ctx.draw_rect_filled(x + 3.5, y + 10.5, 2.0, 2.0, color)
	gg_ctx.draw_rect_filled(x + 8.5, y + 10.5, 2.0, 2.0, color)
}

fn draw_vector_folder_icon(gg_ctx &gg.Context, x f32, y f32, color gg.Color) {
	gg_ctx.draw_rect_filled(x, y, 6.0, 3.0, color)
	gg_ctx.draw_rounded_rect_empty(x, y + 2.0, 15.0, 10.0, 2.0, color)
}

fn draw_vector_clock_icon(gg_ctx &gg.Context, cx f32, cy f32, radius f32, color gg.Color) {
	gg_ctx.draw_circle_empty(cx, cy, radius, color)
	gg_ctx.draw_line(cx, cy, cx, cy - radius * 0.55, color)
	gg_ctx.draw_line(cx, cy, cx + radius * 0.45, cy, color)
}

fn draw_vector_spinner(gg_ctx &gg.Context, cx f32, cy f32, radius f32, active bool, color gg.Color) {
	num_dots := 8
	ticks := time.ticks()
	step := if active { int(ticks / 100) % num_dots } else { 0 }
	for i in 0 .. num_dots {
		angle := f64(i) * (2.0 * math.pi / f64(num_dots))
		dot_x := cx + f32(radius * math.cos(angle))
		dot_y := cy + f32(radius * math.sin(angle))
		diff := (i - step + num_dots) % num_dots
		alpha := u8(math.max(40.0, 255.0 - f64(diff) * 26.0))
		dot_color := gg.Color{
			r: color.r
			g: color.g
			b: color.b
			a: alpha
		}
		dot_radius := if diff == 0 { f32(2.5) } else { f32(1.8) }
		gg_ctx.draw_circle_filled(dot_x, dot_y, dot_radius, dot_color)
	}
}

fn clean_text(s string) string {
	if s.len == 0 {
		return ''
	}
	mut runes := s.runes()
	mut res := []rune{cap: runes.len}
	for r in runes {
		u := u32(r)
		if (u >= 0x1F000 && u <= 0x1FAFF) || (u >= 0x2600 && u <= 0x27BF) || (u >= 0xFE00 && u <= 0xFE0F) {
			continue
		}
		if r == `★` || r == `☆` || r == `⭐` {
			res << `*`
			continue
		}
		res << r
	}
	return res.string()
}

// truncate_text_to_width truncates a string with '...' if its rendered width exceeds max_width.
fn truncate_text_to_width(win &SimpleWindow, text string, max_width f32) string {
	if text.len == 0 || max_width <= 0 {
		return text
	}
	clean := clean_text(text)
	w := measure_text_width(win, clean)
	if w <= max_width {
		return clean
	}
	mut low := 0
	mut high := clean.len
	mut best := 0
	for low <= high {
		mid := (low + high) / 2
		candidate := clean[0..mid] + '...'
		cw := measure_text_width(win, candidate)
		if cw <= max_width {
			best = mid
			low = mid + 1
		} else {
			high = mid - 1
		}
	}
	if best <= 0 {
		return '...'
	}
	return clean[0..best] + '...'
}

// wrap_text_to_width splits text into wrapped lines based on max pixel width and word boundaries.
fn wrap_text_to_width(win &SimpleWindow, text string, max_w f32) []string {
	if text.len == 0 {
		return []
	}
	clean := clean_text(text)
	raw_lines := clean.split('\n')
	mut result := []string{}
	for raw_line in raw_lines {
		if raw_line.len == 0 {
			result << ''
			continue
		}
		if max_w <= 0 || measure_text_width(win, raw_line) <= max_w {
			result << raw_line
			continue
		}
		words := raw_line.split(' ')
		mut current_line := ''
		for word in words {
			// If a single unbroken word exceeds max_w, split it by characters
			if max_w > 0 && measure_text_width(win, word) > max_w {
				if current_line.len > 0 {
					result << current_line
					current_line = ''
				}
				mut chunk := ''
				for ch in word.runes() {
					test_chunk := chunk + ch.str()
					if measure_text_width(win, test_chunk) <= max_w || chunk.len == 0 {
						chunk = test_chunk
					} else {
						result << chunk
						chunk = ch.str()
					}
				}
				if chunk.len > 0 {
					current_line = chunk
				}
				continue
			}

			test_line := if current_line.len == 0 { word } else { current_line + ' ' + word }
			if measure_text_width(win, test_line) <= max_w || current_line.len == 0 {
				current_line = test_line
			} else {
				result << current_line
				current_line = word
			}
		}
		if current_line.len > 0 {
			result << current_line
		}
	}
	return result
}

// draw_image_fit draws an image scaled to fit inside the specified (x, y, w, h) bounds.
// If the image file does not exist or fails to load, it gracefully renders a modern vector placeholder.
fn (mut win SimpleWindow) draw_image_fit(file_path string, x f32, y f32, w f32, h f32, fallback_label string) {
	if win.gg_ctx == unsafe { nil } {
		return
	}
	if file_path.len > 0 {
		if mut img := win.get_or_load_image(file_path) {
			if !img.simg_ok {
				img.init_sokol_image()
			}
			if img.simg_ok {
				win.gg_ctx.draw_image(x, y, w, h, img)
				return
			}
		}
	}


	// Fallback vector placeholder card if file is missing or loading
	surface := if win.theme.is_dark { gg.rgb(35, 38, 50) } else { gg.rgb(230, 234, 242) }
	border_c := if win.theme.is_dark { gg.rgb(65, 70, 85) } else { gg.rgb(200, 205, 215) }
	muted_fg := if win.theme.is_dark { gg.rgb(130, 135, 155) } else { gg.rgb(120, 125, 140) }
	win.gg_ctx.draw_rounded_rect_filled(x, y, w, h, 6.0, surface)
	win.gg_ctx.draw_rounded_rect_empty(x, y, w, h, 6.0, border_c)

	cx := x + w / 2.0
	cy := y + h / 2.0
	if w >= 32.0 && h >= 32.0 {
		win.gg_ctx.draw_rounded_rect_empty(cx - 14.0, cy - 10.0, 28.0, 20.0, 3.0, muted_fg)
		win.gg_ctx.draw_circle_filled(cx - 6.0, cy - 4.0, 3.0, muted_fg)
		win.gg_ctx.draw_triangle_filled(cx - 10.0, cy + 8.0, cx - 2.0, cy, cx + 4.0, cy + 8.0, muted_fg)
		win.gg_ctx.draw_triangle_filled(cx + 1.0, cy + 8.0, cx + 6.0, cy + 3.0, cx + 11.0, cy + 8.0, muted_fg)
	}
	if fallback_label.len > 0 && h >= 50.0 {
		win.gg_ctx.draw_text2(
			x:     int(x + 6)
			y:     int(y + h - 18)
			text:  clean_text(fallback_label)
			color: muted_fg
			size:  11
		)
	}
}

// draw_elevation_shadow renders multi-pass soft ambient drop shadow simulation.
fn draw_elevation_shadow(gg_ctx &gg.Context, x f32, y f32, w f32, h f32, radius f32, elevation int, is_dark bool) {
	if elevation <= 0 || gg_ctx == unsafe { nil } {
		return
	}
	layers := if elevation > 4 { 4 } else { elevation }
	for layer in 1 .. layers + 1 {
		offset := f32(layer) * 2.0
		spread := f32(layer) * 1.5
		alpha := if is_dark { u8(15 + layer * 8) } else { u8(8 + layer * 6) }
		shadow_color := gg.Color{
			r: 0
			g: 0
			b: 0
			a: alpha
		}
		gg_ctx.draw_rounded_rect_filled(x - spread, y + offset, w + spread * 2.0, h + spread * 2.0,
			radius + spread, shadow_color)
	}
}

// draw_focus_ring renders an accessible glowing focus ring around active controls.
fn draw_focus_ring(gg_ctx &gg.Context, x f32, y f32, w f32, h f32, radius f32, accent gg.Color) {
	if gg_ctx == unsafe { nil } {
		return
	}
	ring_color := gg.Color{
		r: accent.r
		g: accent.g
		b: accent.b
		a: 160
	}
	gg_ctx.draw_rounded_rect_empty(x - 2.0, y - 2.0, w + 4.0, h + 4.0, radius + 2.0,
		ring_color)
}

// draw_vector_icon_glyph draws crisp procedural vector glyphs without image assets.
fn draw_vector_icon_glyph(gg_ctx &gg.Context, glyph string, x f32, y f32, sz f32, color gg.Color) {
	if gg_ctx == unsafe { nil } {
		return
	}
	cx := x + sz / 2.0
	cy := y + sz / 2.0
	r := sz / 2.0

	match glyph.to_lower() {
		'search' {
			cr := r * 0.55
			ccx := cx - r * 0.2
			ccy := cy - r * 0.2
			gg_ctx.draw_circle_empty(ccx, ccy, cr, color)
			gg_ctx.draw_line(ccx + cr * 0.7, ccy + cr * 0.7, cx + r * 0.85, cy + r * 0.85,
				color)
		}
		'close', 'x' {
			pad := sz * 0.25
			gg_ctx.draw_line(x + pad, y + pad, x + sz - pad, y + sz - pad, color)
			gg_ctx.draw_line(x + sz - pad, y + pad, x + pad, y + sz - pad, color)
		}
		'check' {
			gg_ctx.draw_line(x + sz * 0.2, cy, cx - sz * 0.1, y + sz * 0.75, color)
			gg_ctx.draw_line(cx - sz * 0.1, y + sz * 0.75, x + sz * 0.8, y + sz * 0.25,
				color)
		}
		'gear', 'settings' {
			gg_ctx.draw_circle_empty(cx, cy, r * 0.55, color)
			gg_ctx.draw_circle_filled(cx, cy, r * 0.25, color)
			for i in 0 .. 8 {
				ang := f64(i) * math.pi / 4.0
				gx1 := cx + f32(r * 0.55 * math.cos(ang))
				gy1 := cy + f32(r * 0.55 * math.sin(ang))
				gx2 := cx + f32(r * 0.88 * math.cos(ang))
				gy2 := cy + f32(r * 0.88 * math.sin(ang))
				gg_ctx.draw_line(gx1, gy1, gx2, gy2, color)
			}
		}
		'copy' {
			w_box := sz * 0.55
			h_box := sz * 0.6
			gg_ctx.draw_rounded_rect_empty(x + sz * 0.1, y + sz * 0.1, w_box, h_box, 2.0,
				color)
			gg_ctx.draw_rounded_rect_filled(x + sz * 0.35, y + sz * 0.3, w_box, h_box,
				2.0, gg.Color{
				r: color.r
				g: color.g
				b: color.b
				a: 60
			})
			gg_ctx.draw_rounded_rect_empty(x + sz * 0.35, y + sz * 0.3, w_box, h_box,
				2.0, color)
		}
		'chevron_down', 'down' {
			pad := sz * 0.3
			gg_ctx.draw_line(x + pad, cy - sz * 0.1, cx, cy + sz * 0.2, color)
			gg_ctx.draw_line(cx, cy + sz * 0.2, x + sz - pad, cy - sz * 0.1, color)
		}
		'chevron_up', 'up' {
			pad := sz * 0.3
			gg_ctx.draw_line(x + pad, cy + sz * 0.2, cx, cy - sz * 0.1, color)
			gg_ctx.draw_line(cx, cy - sz * 0.1, x + sz - pad, cy + sz * 0.2, color)
		}
		'chevron_right', 'right' {
			pad := sz * 0.3
			gg_ctx.draw_line(cx - sz * 0.1, y + pad, cx + sz * 0.2, cy, color)
			gg_ctx.draw_line(cx + sz * 0.2, cy, cx - sz * 0.1, y + sz - pad, color)
		}
		'chevron_left', 'left' {
			pad := sz * 0.3
			gg_ctx.draw_line(cx + sz * 0.2, y + pad, cx - sz * 0.1, cy, color)
			gg_ctx.draw_line(cx - sz * 0.1, cy, cx + sz * 0.2, y + sz - pad, color)
		}
		'trash', 'delete' {
			gg_ctx.draw_line(x + sz * 0.2, y + sz * 0.25, x + sz * 0.8, y + sz * 0.25,
				color)
			gg_ctx.draw_rect_empty(x + sz * 0.28, y + sz * 0.25, sz * 0.44, sz * 0.58,
				color)
			gg_ctx.draw_line(cx, y + sz * 0.35, cx, y + sz * 0.7, color)
		}
		'folder' {
			draw_vector_folder_icon(gg_ctx, x, y, color)
		}
		'refresh' {
			gg_ctx.draw_circle_empty(cx, cy, r * 0.65, color)
			gg_ctx.draw_triangle_filled(cx + r * 0.5, cy - r * 0.7, cx + r * 0.9, cy - r * 0.2,
				cx + r * 0.2, cy - r * 0.2, color)
		}
		'arrow_right' {
			gg_ctx.draw_line(x + sz * 0.15, cy, x + sz * 0.8, cy, color)
			gg_ctx.draw_line(x + sz * 0.55, cy - sz * 0.25, x + sz * 0.8, cy, color)
			gg_ctx.draw_line(x + sz * 0.55, cy + sz * 0.25, x + sz * 0.8, cy, color)
		}
		'star' {
			gg_ctx.draw_circle_filled(cx, cy, r * 0.3, color)
			for i in 0 .. 5 {
				ang := f64(i) * 2.0 * math.pi / 5.0 - math.pi / 2.0
				sx := cx + f32(r * 0.85 * math.cos(ang))
				sy := cy + f32(r * 0.85 * math.sin(ang))
				gg_ctx.draw_line(cx, cy, sx, sy, color)
			}
		}
		'heart' {
			gg_ctx.draw_circle_filled(cx - r * 0.3, cy - r * 0.2, r * 0.35, color)
			gg_ctx.draw_circle_filled(cx + r * 0.3, cy - r * 0.2, r * 0.35, color)
			gg_ctx.draw_triangle_filled(cx - r * 0.65, cy - r * 0.1, cx + r * 0.65,
				cy - r * 0.1, cx, cy + r * 0.8, color)
		}
		'eye' {
			gg_ctx.draw_circle_empty(cx, cy, r * 0.65, color)
			gg_ctx.draw_circle_filled(cx, cy, r * 0.3, color)
		}
		'eye_off' {
			gg_ctx.draw_circle_empty(cx, cy, r * 0.65, color)
			gg_ctx.draw_circle_filled(cx, cy, r * 0.3, color)
			gg_ctx.draw_line(x + sz * 0.15, y + sz * 0.15, x + sz * 0.85, y + sz * 0.85,
				color)
		}
		'lock' {
			gg_ctx.draw_rounded_rect_filled(x + sz * 0.2, cy - sz * 0.05, sz * 0.6,
				sz * 0.5, 3.0, color)
			gg_ctx.draw_circle_empty(cx, cy - sz * 0.15, sz * 0.22, color)
		}
		'cloud' {
			gg_ctx.draw_circle_filled(cx - r * 0.3, cy + r * 0.1, r * 0.45, color)
			gg_ctx.draw_circle_filled(cx + r * 0.3, cy + r * 0.15, r * 0.35, color)
			gg_ctx.draw_circle_filled(cx, cy - r * 0.2, r * 0.45, color)
		}
		'database' {
			gg_ctx.draw_rounded_rect_empty(x + sz * 0.2, y + sz * 0.15, sz * 0.6, sz * 0.22,
				3.0, color)
			gg_ctx.draw_rounded_rect_empty(x + sz * 0.2, y + sz * 0.42, sz * 0.6, sz * 0.22,
				3.0, color)
			gg_ctx.draw_rounded_rect_empty(x + sz * 0.2, y + sz * 0.69, sz * 0.6, sz * 0.22,
				3.0, color)
		}
		'bell' {
			gg_ctx.draw_circle_filled(cx, cy - r * 0.1, r * 0.55, color)
			gg_ctx.draw_rect_filled(x + sz * 0.2, cy + r * 0.2, sz * 0.6, sz * 0.15,
				color)
			gg_ctx.draw_circle_filled(cx, cy + r * 0.55, r * 0.18, color)
		}
		'home' {
			gg_ctx.draw_triangle_filled(cx, y + sz * 0.15, x + sz * 0.15, cy + sz * 0.1,
				x + sz * 0.85, cy + sz * 0.1, color)
			gg_ctx.draw_rect_filled(x + sz * 0.25, cy + sz * 0.05, sz * 0.5, sz * 0.45,
				color)
		}
		'user' {
			gg_ctx.draw_circle_filled(cx, cy - r * 0.3, r * 0.35, color)
			gg_ctx.draw_rounded_rect_filled(x + sz * 0.2, cy + r * 0.15, sz * 0.6, sz * 0.35,
				4.0, color)
		}
		'plus', 'add' {
			gg_ctx.draw_line(cx, y + sz * 0.2, cx, y + sz * 0.8, color)
			gg_ctx.draw_line(x + sz * 0.2, cy, x + sz * 0.8, cy, color)
		}
		'minus' {
			gg_ctx.draw_line(x + sz * 0.2, cy, x + sz * 0.8, cy, color)
		}
		'info' {
			gg_ctx.draw_circle_empty(cx, cy, r * 0.8, color)
			gg_ctx.draw_circle_filled(cx, cy - r * 0.35, 2.0, color)
			gg_ctx.draw_line(cx, cy - r * 0.05, cx, cy + r * 0.45, color)
		}
		'warning' {
			gg_ctx.draw_triangle_empty(cx, y + sz * 0.15, x + sz * 0.1, y + sz * 0.85,
				x + sz * 0.9, y + sz * 0.85, color)
			gg_ctx.draw_line(cx, cy - r * 0.1, cx, cy + r * 0.2, color)
			gg_ctx.draw_circle_filled(cx, cy + r * 0.45, 1.8, color)
		}
		else {
			gg_ctx.draw_circle_filled(cx, cy, r * 0.5, color)
		}
	}
}

// render_drawer renders the active slide-over drawer panel overlay.
fn (mut win SimpleWindow) render_drawer() {
	if !win.drawer_active {
		return
	}
	// Semi-transparent backdrop
	win.gg_ctx.draw_rect_filled(0, 0, f32(win.width), f32(win.height), gg.Color{
		r: 0
		g: 0
		b: 0
		a: 140
	})
	dr_w := win.drawer_width
	dr_h := f32(win.height)
	dr_x := if win.drawer_side == 'left' { f32(0.0) } else { f32(win.width) - dr_w }
	dr_y := f32(0.0)

	surface := if win.theme.is_dark { gg.rgb(24, 27, 36) } else { gg.rgb(255, 255, 255) }
	border_c := if win.theme.is_dark { gg.rgb(55, 60, 75) } else { gg.rgb(215, 220, 230) }
	fg := parse_hex_color(win.theme.font_color)
	muted_fg := if win.theme.is_dark { gg.rgb(140, 145, 165) } else { gg.rgb(120, 125, 140) }
	accent := parse_hex_color(win.theme.accent_color)
	hover_bg := if win.theme.is_dark { gg.rgb(36, 40, 54) } else { gg.rgb(240, 243, 250) }
	active_bg := gg.Color{
		r: accent.r
		g: accent.g
		b: accent.b
		a: if win.theme.is_dark { u8(50) } else { u8(35) }
	}

	draw_elevation_shadow(win.gg_ctx, dr_x, dr_y, dr_w, dr_h, 0.0, 4, win.theme.is_dark)
	win.gg_ctx.draw_rect_filled(dr_x, dr_y, dr_w, dr_h, surface)
	win.gg_ctx.draw_line(if win.drawer_side == 'left' { dr_x + dr_w } else { dr_x },
		0, if win.drawer_side == 'left' { dr_x + dr_w } else { dr_x }, dr_h, border_c)

	// Drawer Header
	hdr_h := f32(52.0)
	win.gg_ctx.draw_text2(
		x:     int(dr_x + 20)
		y:     int(dr_y + 16)
		text:  clean_text(win.drawer_title)
		color: fg
		size:  16
		bold:  true
	)

	// Close Button
	close_x := dr_x + dr_w - 36.0
	close_y := dr_y + 16.0
	is_close_hov := win.mouse_x >= close_x - 6.0 && win.mouse_x <= close_x + 22.0
		&& win.mouse_y >= close_y - 6.0 && win.mouse_y <= close_y + 22.0
	if is_close_hov {
		win.gg_ctx.draw_rounded_rect_filled(close_x - 4.0, close_y - 4.0, 24.0, 24.0, 4.0, hover_bg)
	}
	draw_vector_icon_glyph(win.gg_ctx, 'close', close_x, close_y, 16.0, if is_close_hov { accent } else { muted_fg })
	win.gg_ctx.draw_line(dr_x, hdr_h, dr_x + dr_w, hdr_h, border_c)

	// Drawer Items Content
	mut item_y := hdr_h + 12.0
	item_pad_x := dr_x + 14.0
	item_w := dr_w - 28.0

	for item in win.drawer_items {
		if item.is_header {
			item_y += 6.0
			win.gg_ctx.draw_text2(
				x:     int(item_pad_x + 4)
				y:     int(item_y)
				text:  item.title.to_upper()
				color: muted_fg
				size:  10
				bold:  true
			)
			item_y += 18.0
			win.gg_ctx.draw_line(item_pad_x + 4, item_y, item_pad_x + item_w - 4, item_y, border_c)
			item_y += 6.0
			continue
		}

		item_h := if item.subtitle.len > 0 { f32(48.0) } else { f32(36.0) }
		is_hov := win.mouse_x >= item_pad_x && win.mouse_x <= item_pad_x + item_w
			&& win.mouse_y >= item_y && win.mouse_y <= item_y + item_h

		if item.is_active {
			win.gg_ctx.draw_rounded_rect_filled(item_pad_x, item_y, item_w, item_h, 6.0, active_bg)
			win.gg_ctx.draw_rounded_rect_empty(item_pad_x, item_y, item_w, item_h, 6.0, accent)
		} else if is_hov {
			win.gg_ctx.draw_rounded_rect_filled(item_pad_x, item_y, item_w, item_h, 6.0, hover_bg)
		}

		// Icon
		icon_sz := f32(16.0)
		icon_color := if item.is_active { accent } else if is_hov { fg } else { muted_fg }
		if item.icon.len > 0 {
			draw_vector_icon_glyph(win.gg_ctx, item.icon, item_pad_x + 12.0, item_y + (item_h - icon_sz) / 2.0, icon_sz, icon_color)
		}

		// Title & Subtitle
		txt_x := if item.icon.len > 0 { item_pad_x + 36.0 } else { item_pad_x + 12.0 }
		txt_color := if item.is_active { fg } else { fg }
		if item.subtitle.len > 0 {
			win.gg_ctx.draw_text2(
				x:     int(txt_x)
				y:     int(item_y + 8)
				text:  item.title
				color: txt_color
				size:  13
				bold:  item.is_active
			)
			win.gg_ctx.draw_text2(
				x:     int(txt_x)
				y:     int(item_y + 26)
				text:  item.subtitle
				color: muted_fg
				size:  11
			)
		} else {
			win.gg_ctx.draw_text2(
				x:     int(txt_x)
				y:     int(item_y + (item_h - 14.0) / 2.0)
				text:  item.title
				color: txt_color
				size:  13
				bold:  item.is_active
			)
		}

		// Badge Pill
		if item.badge.len > 0 {
			badge_w := f32(item.badge.len * 7 + 14)
			badge_x := item_pad_x + item_w - badge_w - 8.0
			badge_y := item_y + (item_h - 20.0) / 2.0
			win.gg_ctx.draw_rounded_rect_filled(badge_x, badge_y, badge_w, 20.0, 10.0, if item.is_active { accent } else { hover_bg })
			win.gg_ctx.draw_text2(
				x:     int(badge_x + 7)
				y:     int(badge_y + 3)
				text:  item.badge
				color: if item.is_active { gg.rgb(255, 255, 255) } else { muted_fg }
				size:  10
				bold:  true
			)
		}

		item_y += item_h + 4.0
	}
}


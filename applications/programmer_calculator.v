module main

import simplegui
import os
import math
import time

// -------------------------------------------------------------
// Word Size & Signedness Enums
// -------------------------------------------------------------

enum WordSize {
	ws_byte  // 8-bit
	ws_word  // 16-bit
	ws_dword // 32-bit
	ws_qword // 64-bit
}

struct BitMetrics {
mut:
	popcount int
	clz      int
	ctz      int
	parity   int
	is_pow2  bool
}

struct AppState {
mut:
	current_val    u64
	word_size      WordSize
	is_signed      bool
	active_tab     string
	history_ledger []string
}

// -------------------------------------------------------------
// String Padding Helpers
// -------------------------------------------------------------

fn pad_l(s string, width int) string {
	if s.len >= width { return s }
	return ' '.repeat(width - s.len) + s
}

// -------------------------------------------------------------
// Core Bitwise & Integer Math Helpers
// -------------------------------------------------------------

fn mask_value(val u64, ws WordSize) u64 {
	match ws {
		.ws_byte  { return val & 0xFF }
		.ws_word  { return val & 0xFFFF }
		.ws_dword { return val & 0xFFFF_FFFF }
		.ws_qword { return val }
	}
}

fn to_signed_string(val u64, ws WordSize) string {
	match ws {
		.ws_byte {
			s := i8(val & 0xFF)
			return '${s}'
		}
		.ws_word {
			s := i16(val & 0xFFFF)
			return '${s}'
		}
		.ws_dword {
			s := int(val & 0xFFFF_FFFF)
			return '${s}'
		}
		.ws_qword {
			s := i64(val)
			return '${s}'
		}
	}
}

fn format_binary_grouped(val u64, ws WordSize) string {
	mut bit_len := 64
	match ws {
		.ws_byte  { bit_len = 8 }
		.ws_word  { bit_len = 16 }
		.ws_dword { bit_len = 32 }
		.ws_qword { bit_len = 64 }
	}

	mut bits := []string{}
	for i := bit_len - 1; i >= 0; i-- {
		bit := (val >> u64(i)) & 1
		bits << '${bit}'
		if i > 0 && i % 4 == 0 {
			bits << '_'
		}
	}
	return bits.join('')
}

fn format_hex_clean(val u64, ws WordSize) string {
	match ws {
		.ws_byte  { return '0x${(val & 0xFF):02X}' }
		.ws_word  { return '0x${(val & 0xFFFF):04X}' }
		.ws_dword { return '0x${(val & 0xFFFF_FFFF):08X}' }
		.ws_qword { return '0x${val:016X}' }
	}
}

fn bits_to_octal(val u64) string {
	if val == 0 { return '0' }
	mut n := val
	mut digits := []string{}
	for n > 0 {
		d := n & 7
		digits << '${d}'
		n >>= 3
	}
	digits.reverse()
	return digits.join('')
}

fn format_octal(val u64, ws WordSize) string {
	masked := mask_value(val, ws)
	return '0o' + bits_to_octal(masked)
}

fn compute_bit_metrics(val u64, ws WordSize) BitMetrics {
	masked := mask_value(val, ws)
	mut bit_len := 64
	match ws {
		.ws_byte  { bit_len = 8 }
		.ws_word  { bit_len = 16 }
		.ws_dword { bit_len = 32 }
		.ws_qword { bit_len = 64 }
	}

	mut pop := 0
	for i := 0; i < bit_len; i++ {
		if (masked >> u64(i)) & 1 == 1 {
			pop++
		}
	}

	mut clz := 0
	for i := bit_len - 1; i >= 0; i-- {
		if (masked >> u64(i)) & 1 == 0 {
			clz++
		} else {
			break
		}
	}

	mut ctz := 0
	if masked == 0 {
		ctz = bit_len
	} else {
		for i := 0; i < bit_len; i++ {
			if (masked >> u64(i)) & 1 == 0 {
				ctz++
			} else {
				break
			}
		}
	}

	return BitMetrics{
		popcount: pop
		clz: clz
		ctz: ctz
		parity: pop % 2
		is_pow2: masked > 0 && (masked & (masked - 1)) == 0
	}
}

// -------------------------------------------------------------
// Number Base Parser (Hex, Dec, Oct, Bin)
// -------------------------------------------------------------

fn hex_to_u64(hex_str string) ?u64 {
	mut res := u64(0)
	for ch in hex_str {
		digit := match ch {
			`0`...`9` { u64(ch - `0`) }
			`a`...`f` { u64(ch - `a` + 10) }
			`A`...`F` { u64(ch - `A` + 10) }
			else { return none }
		}
		res = (res << 4) | digit
	}
	return res
}

fn bin_to_u64(bin_str string) ?u64 {
	mut res := u64(0)
	for ch in bin_str {
		digit := match ch {
			`0` { u64(0) }
			`1` { u64(1) }
			else { return none }
		}
		res = (res << 1) | digit
	}
	return res
}

fn oct_to_u64(oct_str string) ?u64 {
	mut res := u64(0)
	for ch in oct_str {
		digit := match ch {
			`0`...`7` { u64(ch - `0`) }
			else { return none }
		}
		res = (res << 3) | digit
	}
	return res
}

fn parse_any_radix(input_str string) ?u64 {
	mut s := input_str.trim_space().replace('_', '').replace(' ', '')
	if s == '' { return 0 }

	if s.starts_with('0x') || s.starts_with('0X') {
		hex_part := s[2..]
		return hex_to_u64(hex_part)
	} else if s.starts_with('0b') || s.starts_with('0B') {
		bin_part := s[2..]
		return bin_to_u64(bin_part)
	} else if s.starts_with('0o') || s.starts_with('0O') {
		oct_part := s[2..]
		return oct_to_u64(oct_part)
	} else if s.starts_with('#') {
		hex_part := s[1..]
		return hex_to_u64(hex_part)
	} else {
		// Decimal or Negative decimal
		if s.starts_with('-') {
			neg_val := s.i64()
			return u64(neg_val)
		}
		return s.u64()
	}
}

// -------------------------------------------------------------
// IEEE 754 Floating-Point Inspector
// -------------------------------------------------------------

fn format_bits_raw(val u64, count int) string {
	mut bits := []string{}
	for i := count - 1; i >= 0; i-- {
		b := (val >> u64(i)) & 1
		bits << '${b}'
	}
	return bits.join('')
}

fn format_ieee754_breakdown(val u64) string {
	u32_val := u32(val & 0xFFFF_FFFF)
	f32_val := math.f32_from_bits(u32_val)
	f64_val := math.f64_from_bits(val)

	// 32-bit Single Precision breakdown
	sign_32 := (u32_val >> 31) & 1
	exp_32 := (u32_val >> 23) & 0xFF
	mant_32 := u32_val & 0x7F_FFFF
	bias_exp_32 := int(exp_32) - 127

	// 64-bit Double Precision breakdown
	sign_64 := (val >> 63) & 1
	exp_64 := (val >> 52) & 0x7FF
	mant_64 := val & 0xF_FFFF_FFFF_FFFF
	bias_exp_64 := int(exp_64) - 1023

	mut lines := []string{}
	lines << '========================================================================'
	lines << ' IEEE 754 FLOATING-POINT BIT FIELD BREAKDOWN'
	lines << '========================================================================'
	lines << ' 32-BIT SINGLE PRECISION (FLOAT):'
	lines << '   * Floating Value   : ${f32_val}'
	lines << '   * Sign Bit [31]    : ${sign_32} (' + (if sign_32 == 1 { 'Negative -' } else { 'Positive +' }) + ')'
	lines << '   * Exponent [30:23] : 0x${exp_32:02X} (${exp_32} unsigned, 2^${bias_exp_32} biased)'
	lines << '   * Mantissa [22:0]  : 0x${mant_32:06X} (Fractional: 1.${mant_32:06X})'
	lines << '   * Binary Breakdown : [${sign_32}] [' + format_bits_raw(u64(exp_32), 8) + '] [' + format_bits_raw(u64(mant_32), 23) + ']'
	lines << '------------------------------------------------------------------------'
	lines << ' 64-BIT DOUBLE PRECISION (DOUBLE):'
	lines << '   * Floating Value   : ${f64_val}'
	lines << '   * Sign Bit [63]    : ${sign_64} (' + (if sign_64 == 1 { 'Negative -' } else { 'Positive +' }) + ')'
	lines << '   * Exponent [62:52] : 0x${exp_64:03X} (${exp_64} unsigned, 2^${bias_exp_64} biased)'
	lines << '   * Mantissa [51:0]  : 0x${mant_64:013X}'
	lines << '   * Binary Breakdown : [${sign_64}] [' + format_bits_raw(u64(exp_64), 11) + '] [' + format_bits_raw(u64(mant_64), 52) + ']'
	lines << '========================================================================\n'
	return lines.join('\n')
}

// -------------------------------------------------------------
// Data Type Interpretations Inspector
// -------------------------------------------------------------

fn format_type_interpretations(val u64) string {
	u8_val := u8(val & 0xFF)
	i8_val := i8(val & 0xFF)
	u16_val := u16(val & 0xFFFF)
	i16_val := i16(val & 0xFFFF)
	u32_val := u32(val & 0xFFFF_FFFF)
	i32_val := int(val & 0xFFFF_FFFF)
	u64_val := val
	i64_val := i64(val)

	f32_val := math.f32_from_bits(u32_val)
	f64_val := math.f64_from_bits(val)

	// ASCII characters in low bytes
	mut ascii_repr := []string{}
	for i := 7; i >= 0; i-- {
		b := u8((val >> u64(i * 8)) & 0xFF)
		if b >= 32 && b <= 126 {
			ascii_repr << '${rune(b)}'
		} else if b == 0 {
			ascii_repr << '\\0'
		} else {
			ascii_repr << '.'
		}
	}

	// IPv4 address
	ip_a := (val >> 24) & 0xFF
	ip_b := (val >> 16) & 0xFF
	ip_c := (val >> 8) & 0xFF
	ip_d := val & 0xFF
	ip_str := '${ip_a}.${ip_b}.${ip_c}.${ip_d}'

	// RGB Color breakdown
	r_col := (val >> 16) & 0xFF
	g_col := (val >> 8) & 0xFF
	b_col := val & 0xFF
	a_col := (val >> 24) & 0xFF

	// UNIX Epoch timestamp
	epoch_time := if val <= 253402300799 { time.unix(i64(val)).format_ss() } else { 'Out of range (> year 9999)' }

	mut lines := []string{}
	lines << '========================================================================'
	lines << ' MULTI-TYPE DATA INTERPRETATIONS'
	lines << '========================================================================'
	lines << ' INTEGER PRIMITIVES (SIGNED / UNSIGNED):'
	lines << '   * 8-bit Byte    (i8 / u8)   : ' + pad_l('${i8_val}', 6) + '  /  ' + pad_l('${u8_val}', 5) + '  (0x${u8_val:02X})'
	lines << '   * 16-bit Word   (i16 / u16) : ' + pad_l('${i16_val}', 6) + '  /  ' + pad_l('${u16_val}', 5) + '  (0x${u16_val:04X})'
	lines << '   * 32-bit Dword  (i32 / u32) : ' + pad_l('${i32_val}', 11) + '  /  ' + pad_l('${u32_val}', 10) + '  (0x${u32_val:08X})'
	lines << '   * 64-bit Qword  (i64 / u64) : ' + pad_l('${i64_val}', 20) + '  /  ' + pad_l('${u64_val}', 20)
	lines << '------------------------------------------------------------------------'
	lines << ' FLOATING-POINT INTERPRETATION:'
	lines << '   * IEEE 754 Float32          : ${f32_val}'
	lines << '   * IEEE 754 Float64          : ${f64_val}'
	lines << '------------------------------------------------------------------------'
	lines << ' NETWORK, TIME & GRAPHICS CONVERSIONS:'
	lines << '   * ASCII / String Bytes      : "${ascii_repr.join('')}"'
	lines << '   * IPv4 Dotted Quad Address  : ${ip_str}'
	lines << '   * Hex Color RGBA Code       : #${r_col:02X}${g_col:02X}${b_col:02X} (A=${a_col}, R=${r_col}, G=${g_col}, B=${b_col})'
	lines << '   * UNIX Epoch UTC Timestamp  : ${epoch_time}'
	lines << '========================================================================\n'
	return lines.join('\n')
}

// -------------------------------------------------------------
// Interactive 64-Bit Matrix Display
// -------------------------------------------------------------

fn render_bit_grid(val u64, ws WordSize) string {
	mut bit_len := 64
	match ws {
		.ws_byte  { bit_len = 8 }
		.ws_word  { bit_len = 16 }
		.ws_dword { bit_len = 32 }
		.ws_qword { bit_len = 64 }
	}

	mut lines := []string{}
	lines << '========================================================================'
	lines << ' 64-BIT BINARY REGISTER & BIT-FLIPPER MATRIX'
	lines << '========================================================================'

	// Render in rows of 16 bits
	num_rows := (bit_len + 15) / 16
	for r := num_rows - 1; r >= 0; r-- {
		high_idx := (r + 1) * 16 - 1
		low_idx := r * 16

		mut hdr := ' Bits [${high_idx:02}:${low_idx:02}] : '
		mut val_row := ' State       : '
		
		for i := high_idx; i >= low_idx; i-- {
			bit := (val >> u64(i)) & 1
			hdr += '${i:02} '
			val_row += (if bit == 1 { ' 1 ' } else { ' 0 ' })
			if i % 8 == 0 && i != low_idx {
				hdr += '| '
				val_row += '| '
			}
		}
		lines << hdr
		lines << val_row
		lines << '------------------------------------------------------------------------'
	}

	bm := compute_bit_metrics(val, ws)
	lines << ' BIT TELEMETRY:'
	lines << '   * Popcount (Set Bits 1s)    : ${bm.popcount} / ${bit_len} bits'
	lines << '   * Count Leading Zeros (CLZ) : ${bm.clz}'
	lines << '   * Count Trailing Zeros (CTZ): ${bm.ctz}'
	lines << '   * Parity Bit (Even/Odd)     : ' + (if bm.parity == 0 { 'Even (0)' } else { 'Odd (1)' })
	lines << '   * Is Power of 2 (2^k)       : ' + (if bm.is_pow2 { 'YES' } else { 'NO' })
	lines << '========================================================================\n'
	return lines.join('\n')
}

// -------------------------------------------------------------
// Byte Swapping & Endianness Engine
// -------------------------------------------------------------

fn swap_bytes_16(v u16) u16 {
	return (v >> 8) | (v << 8)
}

fn swap_bytes_32(v u32) u32 {
	return ((v >> 24) & 0xFF) |
		((v >> 8) & 0xFF00) |
		((v << 8) & 0xFF_0000) |
		((v << 24) & 0xFF00_0000)
}

fn swap_bytes_64(v u64) u64 {
	return ((v >> 56) & 0x0000_0000_0000_00FF) |
		((v >> 40) & 0x0000_0000_0000_FF00) |
		((v >> 24) & 0x0000_0000_00FF_0000) |
		((v >> 8) & 0x0000_0000_FF00_0000) |
		((v << 8) & 0x0000_00FF_0000_0000) |
		((v << 24) & 0x0000_FF00_0000_0000) |
		((v << 40) & 0x00FF_0000_0000_0000) |
		((v << 56) & 0xFF00_0000_0000_0000)
}

fn reverse_bits_64(v u64) u64 {
	mut res := u64(0)
	for i := 0; i < 64; i++ {
		res = (res << 1) | ((v >> u64(i)) & 1)
	}
	return res
}

// -------------------------------------------------------------
// Main Application Entry Point
// -------------------------------------------------------------

fn main() {
	println('Starting SimpleGUI - Programmer Calculator Studio Pro...')

	mut win := simplegui.new_simple_window('Programmer\'s Calculator Pro -- Systems, Hex & Bitwise Engine', 1180, 920)
	win.set_fullscreen(true)
	win.restore_saved_theme()
	win.set_spacing(6)
	win.set_padding(14)

	mut state := &AppState{
		current_val: 0xDEAD_BEEF
		word_size: .ws_dword
		is_signed: false
		active_tab: ' Bitwise Calculator'
		history_ledger: []string{}
	}

	// -------------------------------------------------------------
	// Header & Theme
	// -------------------------------------------------------------
	win.begin_row('row_header')
	win.add_heading('Programmer\'s Calculator Pro')

	win.add_label('lbl_theme_hdr', 'Theme:')
	saved_theme := simplegui.get_saved_theme()
	win.add_dropdown('dd_theme_selector', simplegui.list_themes(), saved_theme)
	win.set_control_width('dd_theme_selector', 160)
	win.end_row()

	// -------------------------------------------------------------
	// Top Multi-Radix Key Display Metric Cards
	// -------------------------------------------------------------
	win.begin_group_box('grp_summary_cards', 'Synchronized Multi-Radix Register Displays')
	win.begin_row('row_metric_cards')
	win.add_metric_card('card_hex', 'HEXADECIMAL', '0xDEADBEEF', 'HEX', 'Base 16')
	win.add_metric_card('card_dec', 'DECIMAL (U)', '3735928559', 'DEC', 'Base 10')
	win.add_metric_card('card_oct', 'OCTAL', '0o33653337357', 'OCT', 'Base 8')
	win.add_metric_card('card_pop', 'POPCOUNT', '24 bits', '1s', 'Hamming Weight')
	win.end_row()
	win.end_group_box()

	// -------------------------------------------------------------
	// Primary Register Control Bar
	// -------------------------------------------------------------
	win.begin_group_box('grp_register_input', 'Primary Input Register')
	win.begin_row('row_reg_in')
	win.add_label('lbl_input_val', 'Value (Hex 0x.., Bin 0b.., Dec, Oct 0o..):')
	win.add_input('txt_main_val', '0xDEADBEEF')
	win.set_control_width('txt_main_val', 280)
	win.set_control_font_name('txt_main_val', 'Menlo')
	win.set_control_font_size('txt_main_val', 14)

	win.add_label('lbl_ws', 'Word Size:')
	win.add_dropdown('dd_word_size', [
		'64-bit QWORD (uint64)',
		'32-bit DWORD (uint32)',
		'16-bit WORD (uint16)',
		'8-bit BYTE (uint8)'
	], '32-bit DWORD (uint32)')
	win.set_control_width('dd_word_size', 190)

	win.add_button('btn_sync_reg', 'Update / Sync')
	win.add_button('btn_clear_reg', 'Clear (0)')
	win.end_row()
	win.end_group_box()

	// -------------------------------------------------------------
	// Navigation Workspace Tabs
	// -------------------------------------------------------------
	win.add_tabs('main_tabs', [
		' Bitwise Calculator',
		' 64-Bit Binary Register Matrix',
		' IEEE 754 Floating-Point',
		' Data Type Interpretations',
		' Endianness & Byte Swapping',
		' Bitmask Presets & Powers of 2',
		' Operation Ledger'
	])

	// -------------------------------------------------------------
	// Tab 1: Bitwise Calculator Actions
	// -------------------------------------------------------------
	win.begin_group_box('pane_calc', 'Bitwise Logical & Arithmetic Operations')

	win.begin_row('row_bitwise_1')
	win.add_button('btn_op_not', 'NOT ( ~X )')
	win.add_button('btn_op_and', 'AND ( X & Y )')
	win.add_button('btn_op_or', 'OR ( X | Y )')
	win.add_button('btn_op_xor', 'XOR ( X ^ Y )')
	win.end_row()

	win.begin_row('row_bitwise_2')
	win.add_button('btn_op_nand', 'NAND ( ~(X & Y) )')
	win.add_button('btn_op_nor', 'NOR ( ~(X | Y) )')
	win.add_button('btn_shl_1', 'SHL 1 ( << 1 )')
	win.add_button('btn_shr_1', 'SHR 1 ( >> 1 )')
	win.end_row()

	win.begin_row('row_bitwise_3')
	win.add_button('btn_shl_8', 'SHL 8 ( << 8 )')
	win.add_button('btn_shr_8', 'SHR 8 ( >> 8 )')
	win.add_button('btn_rol_1', 'ROL 1 ( Rotate L )')
	win.add_button('btn_ror_1', 'ROR 1 ( Rotate R )')
	win.end_row()

	win.begin_row('row_operand_y')
	win.add_label('lbl_operand_y', 'Secondary Operand Y:')
	win.add_input('txt_operand_y', '0x000000FF')
	win.set_control_width('txt_operand_y', 200)
	win.set_control_font_name('txt_operand_y', 'Menlo')
	win.add_button('btn_apply_y', 'Apply Y with Selected Op')
	win.end_row()

	win.add_textarea('txt_calc_report', 'Real-time multi-radix evaluation report will appear here.\n')
	win.set_control_height('txt_calc_report', 300)
	win.set_control_font_name('txt_calc_report', 'Menlo')
	win.set_control_font_size('txt_calc_report', 12)
	win.end_group_box()

	// -------------------------------------------------------------
	// Tab 2: 64-Bit Binary Matrix
	// -------------------------------------------------------------
	win.begin_group_box('pane_matrix', 'Interactive Binary Bit Matrix')

	win.begin_row('row_bit_manip')
	win.add_label('lbl_bit_idx', 'Target Bit Index (0-63):')
	win.add_input('txt_bit_idx', '7')
	win.set_control_width('txt_bit_idx', 60)
	win.add_button('btn_set_bit', 'Set Bit (1)')
	win.add_button('btn_clear_bit', 'Clear Bit (0)')
	win.add_button('btn_toggle_bit', 'Toggle Bit (~)')
	win.add_button('btn_invert_all', 'Invert All Bits')
	win.end_row()

	win.add_textarea('txt_matrix_report', '64-bit binary matrix will appear here.\n')
	win.set_control_height('txt_matrix_report', 340)
	win.set_control_font_name('txt_matrix_report', 'Menlo')
	win.set_control_font_size('txt_matrix_report', 11)
	win.end_group_box()

	// -------------------------------------------------------------
	// Tab 3: IEEE 754
	// -------------------------------------------------------------
	win.begin_group_box('pane_float', 'IEEE 754 Floating-Point Inspector')

	win.begin_row('row_float_input')
	win.add_label('lbl_float_val', 'Input Float Value:')
	win.add_input('txt_float_in', '3.1415926535')
	win.set_control_width('txt_float_in', 180)
	win.add_button('btn_from_float32', 'Convert from Float32')
	win.add_button('btn_from_float64', 'Convert from Float64')
	win.end_row()

	win.add_textarea('txt_float_report', 'IEEE-754 bit field breakdown will appear here.\n')
	win.set_control_height('txt_float_report', 340)
	win.set_control_font_name('txt_float_report', 'Menlo')
	win.set_control_font_size('txt_float_report', 12)
	win.end_group_box()

	// -------------------------------------------------------------
	// Tab 4: Type Interpretations
	// -------------------------------------------------------------
	win.begin_group_box('pane_types', 'Data Type Interpretations & Conversions')
	win.add_textarea('txt_types_report', 'Multi-type data interpretations will appear here.\n')
	win.set_control_height('txt_types_report', 380)
	win.set_control_font_name('txt_types_report', 'Menlo')
	win.set_control_font_size('txt_types_report', 12)
	win.end_group_box()

	// -------------------------------------------------------------
	// Tab 5: Endianness
	// -------------------------------------------------------------
	win.begin_group_box('pane_endian', 'Endianness & Byte Swapping Workbench')

	win.begin_row('row_endian_actions')
	win.add_button('btn_bswap16', 'Swap 16-bit (bswap16)')
	win.add_button('btn_bswap32', 'Swap 32-bit (bswap32)')
	win.add_button('btn_bswap64', 'Swap 64-bit (bswap64)')
	win.add_button('btn_revbits', 'Reverse All Bits')
	win.end_row()

	win.add_textarea('txt_endian_report', 'Endianness byte swaps and reverse bit representations will appear here.\n')
	win.set_control_height('txt_endian_report', 340)
	win.set_control_font_name('txt_endian_report', 'Menlo')
	win.set_control_font_size('txt_endian_report', 12)
	win.end_group_box()

	// -------------------------------------------------------------
	// Tab 6: Presets
	// -------------------------------------------------------------
	win.begin_group_box('pane_presets', 'Bitmask Presets & Powers of 2')

	win.begin_row('row_pre_1')
	win.add_button('btn_pre_0xff', '0x000000FF (Byte Mask)')
	win.add_button('btn_pre_0xffff', '0x0000FFFF (Word Mask)')
	win.add_button('btn_pre_0xffffffff', '0xFFFFFFFF (32-bit Mask)')
	win.add_button('btn_pre_allones', '0xFFFFFFFFFFFFFFFF (All 1s)')
	win.end_row()

	win.begin_row('row_pre_2')
	win.add_button('btn_pre_altaa', '0xAAAAAAAAAAAAAAAA (Alternating 1010..)')
	win.add_button('btn_pre_alt55', '0x5555555555555555 (Alternating 0101..)')
	win.add_button('btn_pre_highbit', '0x8000000000000000 (Sign Bit)')
	win.add_button('btn_pre_deadbeef', '0xDEADBEEF (Magic Value)')
	win.end_row()

	win.add_textarea('txt_presets_report', 'Quickly load common bitwise masks and constants above.\n')
	win.set_control_height('txt_presets_report', 300)
	win.set_control_font_name('txt_presets_report', 'Menlo')
	win.set_control_font_size('txt_presets_report', 12)
	win.end_group_box()

	// -------------------------------------------------------------
	// Tab 7: Ledger
	// -------------------------------------------------------------
	win.begin_group_box('pane_history', 'Session Operation & Conversion Ledger')

	win.begin_row('row_hist_actions')
	win.add_button('btn_copy_ledger', 'Copy Ledger')
	win.add_button('btn_clear_ledger', 'Clear Ledger')
	win.add_button('btn_export_ledger', 'Export Ledger...')
	win.end_row()

	win.add_textarea('txt_ledger', 'All programmer calculator operations and evaluations are recorded here.\n')
	win.set_control_height('txt_ledger', 380)
	win.set_control_font_name('txt_ledger', 'Menlo')
	win.set_control_font_size('txt_ledger', 12)
	win.end_group_box()

	// Initially hide inactive tab panes
	win.set_control_visible('pane_matrix', false)
	win.set_control_visible('pane_float', false)
	win.set_control_visible('pane_types', false)
	win.set_control_visible('pane_endian', false)
	win.set_control_visible('pane_presets', false)
	win.set_control_visible('pane_history', false)

	// -------------------------------------------------------------
	// Status Bar Footer
	// -------------------------------------------------------------
	win.begin_row('row_footer')
	win.add_label('lbl_status_bar', 'Ready. Programmer\'s Multi-Radix Calculator active.')
	win.end_row()

	// -------------------------------------------------------------
	// Ledger Helper
	// -------------------------------------------------------------
	append_ledger := fn [mut state] (mut w simplegui.SimpleWindow, title string, summary string) {
		ts := time.now().format_ss()
		entry := '[${ts}] ${title}\n${summary}\n------------------------------------------------------------------------'
		state.history_ledger << entry
		mut content := []string{}
		content << '========================================================================'
		content << ' PROGRAMMER\'S CALCULATOR PRO -- OPERATION LEDGER'
		content << '========================================================================'
		content << state.history_ledger.join('\n')
		content << '========================================================================\n'
		w.set('txt_ledger', content.join('\n'))
	}

	// -------------------------------------------------------------
	// Master Synchronizer
	// -------------------------------------------------------------
	sync_all_views := fn [mut state, append_ledger] (mut w simplegui.SimpleWindow, update_input bool) {
		val := mask_value(state.current_val, state.word_size)
		state.current_val = val

		hex_str := format_hex_clean(val, state.word_size)
		dec_u_str := '${val}'
		dec_s_str := to_signed_string(val, state.word_size)
		oct_str := format_octal(val, state.word_size)
		bin_str := format_binary_grouped(val, state.word_size)

		if update_input {
			w.set('txt_main_val', hex_str)
		}

		bm := compute_bit_metrics(val, state.word_size)

		// Update Top Metric Cards
		w.set_metric_card_value('card_hex', hex_str, 'HEX')
		w.set_metric_card_value('card_dec', dec_u_str, 'DEC (U)')
		w.set_metric_card_value('card_oct', oct_str, 'OCT')
		w.set_metric_card_value('card_pop', '${bm.popcount} bits', '1s')

		// Format Multi-Radix Report
		mut rep := []string{}
		rep << '========================================================================'
		rep << ' MULTI-RADIX SYNCHRONIZED VALUE SUMMARY'
		rep << '========================================================================'
		rep << ' * HEXADECIMAL (Base 16) : ${hex_str}'
		rep << ' * DECIMAL Unsigned (u)  : ${dec_u_str}'
		rep << ' * DECIMAL Signed (i)    : ${dec_s_str}'
		rep << ' * OCTAL (Base 8)        : ${oct_str}'
		rep << ' * BINARY (Base 2)       : 0b${bin_str}'
		rep << '------------------------------------------------------------------------'
		rep << ' BIT TELEMETRY:'
		rep << ' * Popcount (Set Bits)   : ${bm.popcount} bits'
		rep << ' * Leading Zeros (CLZ)   : ${bm.clz}'
		rep << ' * Trailing Zeros (CTZ)  : ${bm.ctz}'
		rep << ' * Parity                : ' + (if bm.parity == 0 { 'Even (0)' } else { 'Odd (1)' })
		rep << ' * Power of 2 (2^k)      : ' + (if bm.is_pow2 { 'YES' } else { 'NO' })
		rep << '========================================================================\n'

		w.set('txt_calc_report', rep.join('\n'))
		w.set('txt_matrix_report', render_bit_grid(val, state.word_size))
		w.set('txt_float_report', format_ieee754_breakdown(val))
		w.set('txt_types_report', format_type_interpretations(val))

		// Endian report
		u16_swapped := swap_bytes_16(u16(val & 0xFFFF))
		u32_swapped := swap_bytes_32(u32(val & 0xFFFF_FFFF))
		u64_swapped := swap_bytes_64(val)
		rev_bits := reverse_bits_64(val)

		mut end_rep := []string{}
		end_rep << '========================================================================'
		end_rep << ' BYTE SWAPPING & ENDIANNESS CONVERSIONS'
		end_rep << '========================================================================'
		end_rep << ' * Original Value          : ${hex_str} (DEC: ${val})'
		end_rep << ' * 16-bit Swapped (bswap16) : 0x${u16_swapped:04X}'
		end_rep << ' * 32-bit Swapped (bswap32) : 0x${u32_swapped:08X}'
		end_rep << ' * 64-bit Swapped (bswap64) : 0x${u64_swapped:016X}'
		end_rep << ' * Reversed Bits (Bit-Swap) : 0x${rev_bits:016X}'
		end_rep << 'Binary Reversed          : 0b' + format_binary_grouped(rev_bits, .ws_qword)
		end_rep << '========================================================================\n'
		w.set('txt_endian_report', end_rep.join('\n'))

		w.set('lbl_status_bar', ' Value = ${hex_str} (${val} dec, 0b${bin_str})')
		append_ledger(mut w, 'Register Update: ${hex_str}', 'DEC: ${val}, BIN: 0b${bin_str}, Popcount: ${bm.popcount}')
	}

	// -------------------------------------------------------------
	// Event Callbacks
	// -------------------------------------------------------------

	// Workspace Tabs Navigation
	win.on_change('main_tabs', fn [mut state] (mut w simplegui.SimpleWindow, tab string) {
		state.active_tab = tab

		w.set_control_visible('pane_calc', tab == ' Bitwise Calculator')
		w.set_control_visible('pane_matrix', tab == ' 64-Bit Binary Register Matrix')
		w.set_control_visible('pane_float', tab == ' IEEE 754 Floating-Point')
		w.set_control_visible('pane_types', tab == ' Data Type Interpretations')
		w.set_control_visible('pane_endian', tab == ' Endianness & Byte Swapping')
		w.set_control_visible('pane_presets', tab == ' Bitmask Presets & Powers of 2')
		w.set_control_visible('pane_history', tab == ' Operation Ledger')

		w.toast('Switched to ' + tab)
	})

	// Theme Selector
	win.on_change('dd_theme_selector', fn (mut w simplegui.SimpleWindow, selected string) {
		w.set_theme(selected)
		w.toast('Theme changed to ${selected}')
	})

	// Word Size Selector
	win.on_change('dd_word_size', fn [mut state, sync_all_views] (mut w simplegui.SimpleWindow, selected string) {
		if selected.contains('64-bit') { state.word_size = .ws_qword }
		else if selected.contains('32-bit') { state.word_size = .ws_dword }
		else if selected.contains('16-bit') { state.word_size = .ws_word }
		else { state.word_size = .ws_byte }

		sync_all_views(mut w, true)
		w.toast('Word size changed to ' + selected.split(' ')[0])
	})

	// Sync / Input Submit
	win.on_click('btn_sync_reg', fn [mut state, sync_all_views] (mut w simplegui.SimpleWindow) {
		raw_in := w.get('txt_main_val')
		parsed := parse_any_radix(raw_in) or {
			w.alert('Parse Error', 'Invalid integer or radix format: "${raw_in}".\nUse 0x.. for Hex, 0b.. for Binary, 0o.. for Octal, or Plain Decimal.')
			return
		}
		state.current_val = parsed
		sync_all_views(mut w, true)
		w.toast('Updated register value!')
	})

	win.on_click('btn_clear_reg', fn [mut state, sync_all_views] (mut w simplegui.SimpleWindow) {
		state.current_val = 0
		sync_all_views(mut w, true)
		w.toast('Cleared register (0).')
	})

	// -------------------------------------------------------------
	// Tab 1: Bitwise Operations
	// -------------------------------------------------------------
	win.on_click('btn_op_not', fn [mut state, sync_all_views] (mut w simplegui.SimpleWindow) {
		state.current_val = ~state.current_val
		sync_all_views(mut w, true)
		w.toast('Applied Bitwise NOT (~X)')
	})

	win.on_click('btn_shl_1', fn [mut state, sync_all_views] (mut w simplegui.SimpleWindow) {
		state.current_val = state.current_val << 1
		sync_all_views(mut w, true)
		w.toast('Shifted Left << 1')
	})

	win.on_click('btn_shr_1', fn [mut state, sync_all_views] (mut w simplegui.SimpleWindow) {
		state.current_val = state.current_val >> 1
		sync_all_views(mut w, true)
		w.toast('Shifted Right >> 1')
	})

	win.on_click('btn_shl_8', fn [mut state, sync_all_views] (mut w simplegui.SimpleWindow) {
		state.current_val = state.current_val << 8
		sync_all_views(mut w, true)
		w.toast('Shifted Left << 8')
	})

	win.on_click('btn_shr_8', fn [mut state, sync_all_views] (mut w simplegui.SimpleWindow) {
		state.current_val = state.current_val >> 8
		sync_all_views(mut w, true)
		w.toast('Shifted Right >> 8')
	})

	win.on_click('btn_rol_1', fn [mut state, sync_all_views] (mut w simplegui.SimpleWindow) {
		val := mask_value(state.current_val, state.word_size)
		mut bit_len := 64
		match state.word_size {
			.ws_byte  { bit_len = 8 }
			.ws_word  { bit_len = 16 }
			.ws_dword { bit_len = 32 }
			.ws_qword { bit_len = 64 }
		}
		high_bit := (val >> u64(bit_len - 1)) & 1
		state.current_val = ((val << 1) | high_bit)
		sync_all_views(mut w, true)
		w.toast('Rotated Left ROL 1')
	})

	win.on_click('btn_ror_1', fn [mut state, sync_all_views] (mut w simplegui.SimpleWindow) {
		val := mask_value(state.current_val, state.word_size)
		mut bit_len := 64
		match state.word_size {
			.ws_byte  { bit_len = 8 }
			.ws_word  { bit_len = 16 }
			.ws_dword { bit_len = 32 }
			.ws_qword { bit_len = 64 }
		}
		low_bit := val & 1
		state.current_val = ((val >> 1) | (low_bit << u64(bit_len - 1)))
		sync_all_views(mut w, true)
		w.toast('Rotated Right ROR 1')
	})

	// Secondary Operand Ops
	win.on_click('btn_op_and', fn [mut state, sync_all_views] (mut w simplegui.SimpleWindow) {
		y := parse_any_radix(w.get('txt_operand_y')) or { 0 }
		state.current_val = state.current_val & y
		sync_all_views(mut w, true)
		w.toast('Applied AND (&)')
	})

	win.on_click('btn_op_or', fn [mut state, sync_all_views] (mut w simplegui.SimpleWindow) {
		y := parse_any_radix(w.get('txt_operand_y')) or { 0 }
		state.current_val = state.current_val | y
		sync_all_views(mut w, true)
		w.toast('Applied OR (|)')
	})

	win.on_click('btn_op_xor', fn [mut state, sync_all_views] (mut w simplegui.SimpleWindow) {
		y := parse_any_radix(w.get('txt_operand_y')) or { 0 }
		state.current_val = state.current_val ^ y
		sync_all_views(mut w, true)
		w.toast('Applied XOR (^)')
	})

	win.on_click('btn_op_nand', fn [mut state, sync_all_views] (mut w simplegui.SimpleWindow) {
		y := parse_any_radix(w.get('txt_operand_y')) or { 0 }
		state.current_val = ~(state.current_val & y)
		sync_all_views(mut w, true)
		w.toast('Applied NAND')
	})

	win.on_click('btn_op_nor', fn [mut state, sync_all_views] (mut w simplegui.SimpleWindow) {
		y := parse_any_radix(w.get('txt_operand_y')) or { 0 }
		state.current_val = ~(state.current_val | y)
		sync_all_views(mut w, true)
		w.toast('Applied NOR')
	})

	win.on_click('btn_apply_y', fn [mut state, sync_all_views] (mut w simplegui.SimpleWindow) {
		y := parse_any_radix(w.get('txt_operand_y')) or { 0 }
		state.current_val = state.current_val & y
		sync_all_views(mut w, true)
		w.toast('Applied Y')
	})

	// -------------------------------------------------------------
	// Tab 2: Bit Manipulations
	// -------------------------------------------------------------
	win.on_click('btn_set_bit', fn [mut state, sync_all_views] (mut w simplegui.SimpleWindow) {
		idx := int(w.get('txt_bit_idx').f64())
		if idx >= 0 && idx < 64 {
			state.current_val = state.current_val | (u64(1) << u64(idx))
			sync_all_views(mut w, true)
			w.toast('Set bit ${idx} to 1')
		}
	})

	win.on_click('btn_clear_bit', fn [mut state, sync_all_views] (mut w simplegui.SimpleWindow) {
		idx := int(w.get('txt_bit_idx').f64())
		if idx >= 0 && idx < 64 {
			state.current_val = state.current_val & ~(u64(1) << u64(idx))
			sync_all_views(mut w, true)
			w.toast('Cleared bit ${idx} to 0')
		}
	})

	win.on_click('btn_toggle_bit', fn [mut state, sync_all_views] (mut w simplegui.SimpleWindow) {
		idx := int(w.get('txt_bit_idx').f64())
		if idx >= 0 && idx < 64 {
			state.current_val = state.current_val ^ (u64(1) << u64(idx))
			sync_all_views(mut w, true)
			w.toast('Toggled bit ${idx}')
		}
	})

	win.on_click('btn_invert_all', fn [mut state, sync_all_views] (mut w simplegui.SimpleWindow) {
		state.current_val = ~state.current_val
		sync_all_views(mut w, true)
		w.toast('Inverted all bits')
	})

	// -------------------------------------------------------------
	// Tab 3: IEEE 754 Actions
	// -------------------------------------------------------------
	win.on_click('btn_from_float32', fn [mut state, sync_all_views] (mut w simplegui.SimpleWindow) {
		f_val := f32(w.get('txt_float_in').f64())
		u_val := math.f32_bits(f_val)
		state.current_val = u64(u_val)
		state.word_size = .ws_dword
		sync_all_views(mut w, true)
		w.toast('Converted Float32 to bits!')
	})

	win.on_click('btn_from_float64', fn [mut state, sync_all_views] (mut w simplegui.SimpleWindow) {
		f_val := w.get('txt_float_in').f64()
		u_val := math.f64_bits(f_val)
		state.current_val = u_val
		state.word_size = .ws_qword
		sync_all_views(mut w, true)
		w.toast('Converted Float64 to bits!')
	})

	// -------------------------------------------------------------
	// Tab 5: Endian Actions
	// -------------------------------------------------------------
	win.on_click('btn_bswap16', fn [mut state, sync_all_views] (mut w simplegui.SimpleWindow) {
		swapped := swap_bytes_16(u16(state.current_val & 0xFFFF))
		state.current_val = u64(swapped)
		state.word_size = .ws_word
		sync_all_views(mut w, true)
		w.toast('Applied 16-bit Byte Swap')
	})

	win.on_click('btn_bswap32', fn [mut state, sync_all_views] (mut w simplegui.SimpleWindow) {
		swapped := swap_bytes_32(u32(state.current_val & 0xFFFF_FFFF))
		state.current_val = u64(swapped)
		state.word_size = .ws_dword
		sync_all_views(mut w, true)
		w.toast('Applied 32-bit Byte Swap')
	})

	win.on_click('btn_bswap64', fn [mut state, sync_all_views] (mut w simplegui.SimpleWindow) {
		swapped := swap_bytes_64(state.current_val)
		state.current_val = swapped
		state.word_size = .ws_qword
		sync_all_views(mut w, true)
		w.toast('Applied 64-bit Byte Swap')
	})

	win.on_click('btn_revbits', fn [mut state, sync_all_views] (mut w simplegui.SimpleWindow) {
		reversed := reverse_bits_64(state.current_val)
		state.current_val = reversed
		sync_all_views(mut w, true)
		w.toast('Reversed all 64 bits')
	})

	// -------------------------------------------------------------
	// Tab 6: Presets Actions
	// -------------------------------------------------------------
	win.on_click('btn_pre_0xff', fn [mut state, sync_all_views] (mut w simplegui.SimpleWindow) {
		state.current_val = 0x000000FF
		state.word_size = .ws_byte
		sync_all_views(mut w, true)
		w.toast('Loaded 0xFF Byte Mask')
	})

	win.on_click('btn_pre_0xffff', fn [mut state, sync_all_views] (mut w simplegui.SimpleWindow) {
		state.current_val = 0x0000FFFF
		state.word_size = .ws_word
		sync_all_views(mut w, true)
		w.toast('Loaded 0xFFFF Word Mask')
	})

	win.on_click('btn_pre_0xffffffff', fn [mut state, sync_all_views] (mut w simplegui.SimpleWindow) {
		state.current_val = 0xFFFFFFFF
		state.word_size = .ws_dword
		sync_all_views(mut w, true)
		w.toast('Loaded 0xFFFFFFFF DWORD Mask')
	})

	win.on_click('btn_pre_allones', fn [mut state, sync_all_views] (mut w simplegui.SimpleWindow) {
		state.current_val = 0xFFFF_FFFF_FFFF_FFFF
		state.word_size = .ws_qword
		sync_all_views(mut w, true)
		w.toast('Loaded All 1s Mask')
	})

	win.on_click('btn_pre_altaa', fn [mut state, sync_all_views] (mut w simplegui.SimpleWindow) {
		state.current_val = 0xAAAA_AAAA_AAAA_AAAA
		state.word_size = .ws_qword
		sync_all_views(mut w, true)
		w.toast('Loaded Alternating 0xAAAA Pattern')
	})

	win.on_click('btn_pre_alt55', fn [mut state, sync_all_views] (mut w simplegui.SimpleWindow) {
		state.current_val = 0x5555_5555_5555_5555
		state.word_size = .ws_qword
		sync_all_views(mut w, true)
		w.toast('Loaded Alternating 0x5555 Pattern')
	})

	win.on_click('btn_pre_highbit', fn [mut state, sync_all_views] (mut w simplegui.SimpleWindow) {
		state.current_val = 0x8000_0000_0000_0000
		state.word_size = .ws_qword
		sync_all_views(mut w, true)
		w.toast('Loaded High Sign Bit')
	})

	win.on_click('btn_pre_deadbeef', fn [mut state, sync_all_views] (mut w simplegui.SimpleWindow) {
		state.current_val = 0xDEAD_BEEF
		state.word_size = .ws_dword
		sync_all_views(mut w, true)
		w.toast('Loaded 0xDEADBEEF')
	})

	// -------------------------------------------------------------
	// Tab 7: Ledger Actions
	// -------------------------------------------------------------
	win.on_click('btn_copy_ledger', fn (mut w simplegui.SimpleWindow) {
		w.copy_to_clipboard(w.get('txt_ledger'))
		w.toast('Copied ledger to clipboard!')
	})

	win.on_click('btn_clear_ledger', fn [mut state] (mut w simplegui.SimpleWindow) {
		state.history_ledger.clear()
		w.set('txt_ledger', 'Ledger cleared.\n')
		w.toast('Cleared ledger.')
	})

	win.on_click('btn_export_ledger', fn (mut w simplegui.SimpleWindow) {
		save_path := w.save_file_picker()
		if save_path != '' {
			mut real_path := save_path
			if !real_path.ends_with('.txt') {
				real_path += '.txt'
			}
			ledger := w.get('txt_ledger')
			os.write_file(real_path, ledger) or {
				w.alert('Export Error', 'Failed to save ledger file.')
				return
			}
			w.toast('Saved ledger to ' + os.file_name(real_path))
		}
	})

	// Initial Sync
	sync_all_views(mut win, true)

	println('Programmer Calculator Studio Pro configured. Starting event loop...')
	win.run()
}

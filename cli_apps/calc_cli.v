module main

import bitutils
import simplecli

fn main() {
	mut app := simplecli.new_app('calc-cli', '1.1.0')
	app.set_description('Programmer Calculator CLI: Hex, Dec, Oct, Bin conversions, bitwise engine, and word telemetry')

	app.add_flag_string('val', 'n', '255',
		'Primary numeric value (prefix with 0x for Hex, 0b for Binary, 0o for Octal, or Decimal)')
	app.add_flag_string('op', 'o', '',
		'Bitwise operation: NOT, AND, OR, XOR, SHL, SHR, ROL, ROR')
	app.add_flag_string('val2', 'w', '',
		'Second operand for binary bitwise operation (Hex, Bin, Oct, or Dec)')
	app.add_flag_bool('interactive', 'x', false,
		'Launch interactive programmer calculator REPL')

	app.parse_cli() or { return }

	if app.get_flag_bool('interactive') {
		app.banner('Programmer Calculator CLI', 'v1.1.0 - Interactive Radix & Bitwise Engine')
		run_interactive(mut app)
		return
	}

	val_str := app.get_flag_string('val')
	val1 := parse_radix_number(val_str) or {
		app.banner('Programmer Calculator CLI', 'v1.1.0 - Error')
		app.error('Invalid primary number: ${err.msg()}')
		app.info('Supported formats:')
		app.info('  • Hexadecimal : 0xDEADBEEF, 0xFF')
		app.info('  • Decimal     : 255, 65536')
		app.info('  • Octal       : 0o755, 0o377')
		app.info('  • Binary      : 0b11111111, 0b1010')
		exit(1)
	}

	op_str := app.get_flag_string('op').trim_space().to_upper()

	if op_str.len > 0 {
		app.banner('Programmer Calculator CLI', 'v1.1.0 - Bitwise Evaluation')
		execute_operation(mut app, val1, val_str, op_str)
	} else {
		app.banner('Programmer Calculator CLI', 'v1.1.0 - Radix & Bitwise Engine')
		display_radix_table(mut app, val1)
	}
}

pub fn parse_radix_number(s string) !u64 {
	clean := s.trim_space()
	if clean.len == 0 {
		return error('empty input')
	}

	lower := clean.to_lower()
	if lower.starts_with('0x') {
		body := lower[2..]
		if body.len == 0 {
			return error('missing digits after 0x')
		}
		mut res := u64(0)
		for c in body {
			digit := match c {
				`0`...`9` { u64(c - `0`) }
				`a`...`f` { u64(c - `a` + 10) }
				else { return error("invalid hexadecimal character: '${c.ascii_str()}'") }
			}
			res = (res << 4) | digit
		}
		return res
	} else if lower.starts_with('0b') {
		body := lower[2..]
		if body.len == 0 {
			return error('missing digits after 0b')
		}
		mut res := u64(0)
		for c in body {
			if c != `0` && c != `1` {
				return error("invalid binary character: '${c.ascii_str()}'")
			}
			res = (res << 1) | u64(c - `0`)
		}
		return res
	} else if lower.starts_with('0o') {
		body := lower[2..]
		if body.len == 0 {
			return error('missing digits after 0o')
		}
		mut res := u64(0)
		for c in body {
			if c < `0` || c > `7` {
				return error("invalid octal character: '${c.ascii_str()}'")
			}
			res = (res << 3) | u64(c - `0`)
		}
		return res
	}

	// Decimal validation
	for c in clean {
		if c < `0` || c > `9` {
			return error("invalid decimal character: '${c.ascii_str()}'")
		}
	}
	return clean.u64()
}

pub fn bits_to_octal(val u64) string {
	if val == 0 {
		return '0'
	}
	mut res := []u8{}
	mut temp := val
	for temp > 0 {
		digit := u8(temp & 7) + `0`
		res << digit
		temp >>= 3
	}
	res.reverse_in_place()
	return res.bytestr()
}

pub fn to_binary_string(v u64) string {
	mut s := ''
	for i := 63; i >= 0; i-- {
		bit := (v >> u64(i)) & 1
		s += bit.str()
		if i % 8 == 0 && i > 0 {
			s += ' '
		}
	}
	return s
}

pub fn swap_bytes_64(v u64) u64 {
	return ((v & 0xFF00000000000000) >> 56) | ((v & 0x00FF000000000000) >> 40) | ((v & 0x0000FF0000000000) >> 24) | ((v & 0x000000FF00000000) >> 8) | ((v & 0x00000000FF000000) << 8) | ((v & 0x0000000000FF0000) << 24) | ((v & 0x000000000000FF00) << 40) | ((v & 0x00000000000000FF) << 56)
}

fn execute_operation(mut app simplecli.SimpleCli, val1 u64, val1_str string, op string) {
	val2_raw := app.get_flag_string('val2')
	mut val2 := u64(0)
	is_binary_op := op in ['AND', '&', 'OR', '|', 'XOR', '^', 'SHL', '<<', 'SHR', '>>', 'ROL',
		'ROR']

	if is_binary_op {
		if val2_raw.trim_space().len == 0 {
			app.error('Operation "${op}" requires a second operand (--val2 or -w).')
			exit(1)
		}
		val2 = parse_radix_number(val2_raw) or {
			app.error('Invalid second operand "${val2_raw}": ${err.msg()}')
			exit(1)
		}
	}

	mut result := u64(0)
	mut expr_name := ''

	match op {
		'NOT', '~' {
			result = ~val1
			expr_name = '~${val1_str}'
		}
		'AND', '&' {
			result = val1 & val2
			expr_name = '${val1_str} & ${val2_raw}'
		}
		'OR', '|' {
			result = val1 | val2
			expr_name = '${val1_str} | ${val2_raw}'
		}
		'XOR', '^' {
			result = val1 ^ val2
			expr_name = '${val1_str} ^ ${val2_raw}'
		}
		'SHL', '<<' {
			shift := int(val2 & 63)
			result = val1 << shift
			expr_name = '${val1_str} << ${shift}'
		}
		'SHR', '>>' {
			shift := int(val2 & 63)
			result = val1 >> shift
			expr_name = '${val1_str} >> ${shift}'
		}
		'ROL' {
			shift := int(val2 & 63)
			result = bitutils.rotate_left(val1, shift)
			expr_name = 'rotate_left(${val1_str}, ${shift})'
		}
		'ROR' {
			shift := int(val2 & 63)
			result = bitutils.rotate_right(val1, shift)
			expr_name = 'rotate_right(${val1_str}, ${shift})'
		}
		else {
			app.error('Unknown bitwise operator: "${op}"')
			app.info('Supported operators: NOT, AND, OR, XOR, SHL, SHR, ROL, ROR')
			exit(1)
		}
	}

	app.panel('Bitwise Computation Result', 'Expression: ${expr_name}')
	display_radix_table(mut app, result)
}

fn display_radix_table(mut app simplecli.SimpleCli, val u64) {
	hex_val := '0x' + val.hex().to_upper()
	dec_val := val.str()
	oct_val := '0o' + bits_to_octal(val)
	bin_val := to_binary_string(val)

	app.table(['Radix Base', 'Representation', 'Bit Size / Notes'], [
		['HEX (Base 16)', hex_val, '64-bit Hexadecimal'],
		['DEC (Base 10)', dec_val, 'Unsigned 64-bit Decimal'],
		['OCT (Base 8)', oct_val, 'Base-8 Octal Representation'],
		['BIN (Base 2)', bin_val, '64-bit formatted byte groups'],
	])

	not_val := ~val
	swapped := swap_bytes_64(val)
	bit_len := bitutils.bit_length(val)
	leading_z := bitutils.leading_zeros(val)
	trailing_z := bitutils.trailing_zeros(val)
	is_pow2 := if bitutils.is_power_of_two(val) { 'True' } else { 'False' }

	app.print_kv({
		'Bitwise Inversion (~val)': not_val.hex().to_upper() + ' (0x' + not_val.hex().to_upper() + ')'
		'Byte Swapped (Endian)':    '0x' + swapped.hex().to_upper()
		'Effective Bit Length':     bit_len.str()
		'Leading Zero Bits':        leading_z.str()
		'Trailing Zero Bits':       trailing_z.str()
		'Power of Two':             is_pow2
	})
}

fn run_interactive(mut app simplecli.SimpleCli) {
	app.panel('Programmer Calculator REPL',
		'Enter numbers (0x..., 0b..., 0o..., decimal) or operations (e.g. 0xFF AND 0x0F, ~0x12). Type q or exit to leave.')

	for {
		input := app.prompt('Enter expression or number', '255').trim_space()
		if input == 'exit' || input == 'q' || input == 'quit' {
			app.success('Exiting Programmer Calculator REPL.')
			break
		}
		if input.len == 0 {
			continue
		}

		// Check for binary expression: e.g. "0xFF AND 0x0F"
		parts := input.split(' ')
		if parts.len == 3 {
			v1 := parse_radix_number(parts[0]) or {
				app.error('Invalid first operand "${parts[0]}": ${err.msg()}')
				continue
			}
			v2 := parse_radix_number(parts[2]) or {
				app.error('Invalid second operand "${parts[2]}": ${err.msg()}')
				continue
			}
			op := parts[1].to_upper()
			mut res := u64(0)
			match op {
				'AND', '&' { res = v1 & v2 }
				'OR', '|' { res = v1 | v2 }
				'XOR', '^' { res = v1 ^ v2 }
				'SHL', '<<' { res = v1 << int(v2 & 63) }
				'SHR', '>>' { res = v1 >> int(v2 & 63) }
				'ROL' { res = bitutils.rotate_left(v1, int(v2 & 63)) }
				'ROR' { res = bitutils.rotate_right(v1, int(v2 & 63)) }
				else {
					app.error('Unknown operator "${op}". Use AND, OR, XOR, SHL, SHR, ROL, ROR')
					continue
				}
			}
			app.success('Computed: ${parts[0]} ${op} ${parts[2]}')
			display_radix_table(mut app, res)
		} else if parts.len == 2 && (parts[0].to_upper() == 'NOT' || parts[0] == '~') {
			v := parse_radix_number(parts[1]) or {
				app.error('Invalid operand "${parts[1]}": ${err.msg()}')
				continue
			}
			res := ~v
			app.success('Computed: NOT ${parts[1]}')
			display_radix_table(mut app, res)
		} else if parts.len == 1 {
			num := parse_radix_number(input) or {
				app.error('Invalid number "${input}": ${err.msg()}')
				continue
			}
			display_radix_table(mut app, num)
		} else {
			app.warn('Format unrecognized. Enter a single number, "val OP val", or "~val".')
		}

		println('')
	}
}

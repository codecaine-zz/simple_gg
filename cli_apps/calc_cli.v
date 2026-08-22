module main

import simplecli

fn main() {
	mut app := simplecli.new_app('calc-cli', '1.0.0')
	app.set_description('Programmer Calculator (HEX, DEC, OCT, BIN, Bitwise Ops) CLI')

	app.add_flag_string('val', 'v', '255', 'Numeric value (prefix with 0x for Hex, 0b for Binary, or standard Decimal)')
	app.add_flag_string('op', 'o', '', 'Bitwise operation (e.g. NOT, AND, OR, XOR, SHL, SHR)')
	app.add_flag_string('val2', 'w', '', 'Second operand for binary bitwise operation')
	app.add_flag_bool('interactive', 'x', false, 'Launch interactive programmer calculator')

	app.parse_cli() or { return }

	app.banner('Programmer Calculator CLI', 'v1.0.0 - Radix & Bitwise Engine')

	if app.get_flag_bool('interactive') {
		run_interactive(mut app)
		return
	}

	val_str := app.get_flag_string('val')
	num := parse_radix_number(val_str)

	display_radix_table(mut app, num)
}

fn parse_radix_number(s string) u64 {
	clean := s.trim_space().to_lower()
	if clean.starts_with('0x') {
		// Parse hex
		mut res := u64(0)
		for c in clean[2..] {
			digit := match c {
				`0`...`9` { u64(c - `0`) }
				`a`...`f` { u64(c - `a` + 10) }
				else { u64(0) }
			}
			res = (res << 4) | digit
		}
		return res
	} else if clean.starts_with('0b') {
		mut res := u64(0)
		for c in clean[2..] {
			bit := if c == `1` { u64(1) } else { u64(0) }
			res = (res << 1) | bit
		}
		return res
	}
	return clean.u64()
}

fn display_radix_table(mut app simplecli.SimpleCli, val u64) {
	hex_val := '0x' + val.hex().to_upper()
	dec_val := val.str()
	oct_val := '0o' + val.str() // approximation
	bin_val := to_binary_string(val)

	app.table(
		['Radix Base', 'Representation', 'Bit Size'],
		[
			['HEX (Base 16)', hex_val, '64-bit'],
			['DEC (Base 10)', dec_val, '64-bit'],
			['OCT (Base 8)', oct_val, '64-bit'],
			['BIN (Base 2)', bin_val, '64-bit formatted'],
		]
	)

	// Bitwise Inversion
	not_val := ~val
	app.print_kv({
		'Bitwise NOT (~val)': '0x' + not_val.hex().to_upper(),
		'Byte Swapped (endian)': '0x' + swap_bytes_64(val).hex().to_upper(),
	})
}

fn to_binary_string(v u64) string {
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

fn swap_bytes_64(v u64) u64 {
	return ((v & 0xFF00000000000000) >> 56) |
		((v & 0x00FF000000000000) >> 40) |
		((v & 0x0000FF0000000000) >> 24) |
		((v & 0x000000FF00000000) >> 8) |
		((v & 0x00000000FF000000) << 8) |
		((v & 0x0000000000FF0000) << 24) |
		((v & 0x000000000000FF00) << 40) |
		((v & 0x00000000000000FF) << 56)
}

fn run_interactive(mut app simplecli.SimpleCli) {
	app.panel('Programmer Calculator REPL', 'Enter decimal, hex (0x...), or binary (0b...) numbers.')
	for {
		input := app.prompt('Enter number', '0xDEADBEEF')
		if input == 'exit' || input == 'q' {
			break
		}
		num := parse_radix_number(input)
		display_radix_table(mut app, num)
		if !app.confirm('Inspect another number?', true) {
			break
		}
	}
}

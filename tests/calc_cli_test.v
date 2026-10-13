module main

import os

const calc_bin = os.join_path(os.temp_dir(), 'calc_cli_test_bin')

fn testsuite_begin() {
	res := os.execute('v -o ${calc_bin} cli_apps/calc_cli.v')
	if res.exit_code != 0 {
		panic('Failed to build calc_cli: ${res.output}')
	}
}

fn testsuite_end() {
	os.rm(calc_bin) or {}
}

fn run_calc(args string) os.Result {
	return os.execute('${calc_bin} ${args}')
}

fn test_calc_cli_default_number() {
	res := run_calc('')
	assert res.exit_code == 0
	assert res.output.contains('HEX (Base 16)')
	assert res.output.contains('0xFF')
	assert res.output.contains('DEC (Base 10)')
	assert res.output.contains('255')
	assert res.output.contains('OCT (Base 8)')
	assert res.output.contains('0o377')
}

fn test_calc_cli_hex_conversion() {
	res := run_calc('-n 0x100')
	assert res.exit_code == 0
	assert res.output.contains('0x100')
	assert res.output.contains('256')
	assert res.output.contains('0o400')
}

fn test_calc_cli_octal_conversion() {
	res := run_calc('-n 0o755')
	assert res.exit_code == 0
	assert res.output.contains('493')
	assert res.output.contains('0x1ED')
	assert res.output.contains('0o755')
}

fn test_calc_cli_binary_conversion() {
	res := run_calc('-n 0b101010')
	assert res.exit_code == 0
	assert res.output.contains('42')
	assert res.output.contains('0x2A')
	assert res.output.contains('0o52')
}

fn test_calc_cli_bitwise_and() {
	res := run_calc('-n 0xFF -o AND -w 0x0F')
	assert res.exit_code == 0
	assert res.output.contains('0xF')
	assert res.output.contains('15')
}

fn test_calc_cli_bitwise_shl() {
	res := run_calc('-n 1 -o SHL -w 8')
	assert res.exit_code == 0
	assert res.output.contains('256')
	assert res.output.contains('0x100')
}

fn test_calc_cli_bitwise_not() {
	res := run_calc('-n 0 -o NOT')
	assert res.exit_code == 0
	assert res.output.contains('18446744073709551615')
	assert res.output.contains('0xFFFFFFFFFFFFFFFF')
}

fn test_calc_cli_error_recovery() {
	res := run_calc('-n 0xZZZ')
	assert res.exit_code != 0
	assert res.output.contains('Invalid primary number')
	assert res.output.contains('Supported formats')
}

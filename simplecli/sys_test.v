module simplecli

import os

fn test_sys_execution_and_env() {
	app := new('SysTest')
	
	// Exec sync
	out, code := app.exec('echo "Hello SimpleCLI"')
	assert code == 0
	assert out.contains('Hello SimpleCLI')

	// Exec with fallback
	res_fb := app.exec_or('echo "Success"', 'fallback')
	assert res_fb.contains('Success')

	// Parallel Execution
	res_list := app.parallel_exec(['echo "Task A"', 'echo "Task B"'])
	assert res_list.len == 2
	assert res_list[0].exit_code == 0
	assert res_list[1].exit_code == 0

	// Safe Exec & Quoting
	quoted := quote_arg('hello; rm -rf /')
	assert quoted == "'hello; rm -rf /'"

	sanitized := sanitize_filename('../../../etc/passwd')
	assert !sanitized.contains('/')
	assert !sanitized.contains('..')

	safe_out, safe_code := app.exec_safe('echo', ['arg1 with spaces', 'arg2'])
	assert safe_code == 0
	assert safe_out.contains('arg1 with spaces')

	// Environment variables
	app.set_env('SIMPLECLI_TEST_VAR', 'antigravity_rad')
	assert app.get_env('SIMPLECLI_TEST_VAR') == 'antigravity_rad'
	app.unset_env('SIMPLECLI_TEST_VAR')
	assert app.get_env('SIMPLECLI_TEST_VAR') == ''

	// PID and Paths
	pid := app.get_pid()
	assert pid > 0

	home := app.get_system_path('home')
	assert home.len > 0
	assert os.exists(home)

	temp := app.get_system_path('temp')
	assert temp.len > 0
	assert os.exists(temp)
}

fn test_sys_hardware_and_network() {
	app := new('HardwareTest')

	cpu := app.get_cpu_info()
	assert cpu.len > 0

	cores := app.get_cpu_cores()
	assert cores > 0

	arch := app.get_cpu_architecture()
	assert arch.len > 0

	ram := app.get_memory_info()
	assert ram.contains('GB RAM')

	locale := app.get_system_locale()
	assert locale.len > 0

	local_ip := app.get_local_ip()
	assert local_ip.len > 0

	mac := app.get_mac_address()
	assert mac.len > 0

	gateway := app.get_default_gateway()
	assert gateway.len > 0

	dns := app.get_dns_servers()
	assert dns.len > 0

	accent := app.get_system_accent_color()
	assert accent.len > 0
}

fn test_sys_file_operations() {
	app := new('FileTest')
	test_file := os.join_path(os.temp_dir(), 'simplecli_file_test_${os.getpid()}.txt')
	copy_target := os.join_path(os.temp_dir(), 'simplecli_file_copy_${os.getpid()}.txt')

	app.write_file(test_file, 'RAD console utilities')
	assert app.file_exists(test_file)

	content := app.read_file(test_file)
	assert content == 'RAD console utilities'

	meta := app.get_file_metadata(test_file) or { panic(err) }
	assert meta.size_bytes > 0
	assert meta.is_readable

	app.copy_file(test_file, copy_target) or { panic(err) }
	assert app.file_exists(copy_target)

	app.delete_file(test_file)
	app.delete_file(copy_target)
	assert !app.file_exists(test_file)
	assert !app.file_exists(copy_target)
}

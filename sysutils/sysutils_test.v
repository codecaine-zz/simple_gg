module sysutils

import os

fn test_telemetry() {
	cpu_cores := get_cpu_count()
	assert cpu_cores >= 1

	l1, l5, l15 := get_load_averages()
	assert l1 >= 0.0 && l5 >= 0.0 && l15 >= 0.0

	total_ram, _, ram_pct := get_memory_stats()
	assert total_ram > 0
	assert ram_pct >= 0.0 && ram_pct <= 100.0

	total_disk, _, disk_pct := get_disk_stats('/')
	assert total_disk > 0
	assert disk_pct >= 0.0 && disk_pct <= 100.0

	uptime := get_uptime()
	assert uptime > 0

	locale := get_system_locale()
	assert locale.len > 0

	theme := get_os_theme()
	assert theme == 'dark' || theme == 'light'
}

fn test_process_security() {
	safe_arg := quote_arg('hello; world')
	assert safe_arg.starts_with("'") && safe_arg.ends_with("'")
	assert safe_arg.contains('hello; world')

	sanitized := sanitize_filename('../../../etc/passwd')
	assert !sanitized.contains('/')
	assert !sanitized.contains('..')

	out, code := exec_safe('echo', ['hello', 'vlang'])
	assert code == 0
	assert out.contains('hello vlang')

	fallback := exec_or('non_existent_command_12345', 'default_val')
	assert fallback == 'default_val'

	assert has_command('ls') == true
	assert has_command('this_command_does_not_exist_xyz') == false

	assert is_process_running(os.getpid()) == true
}

fn test_standard_paths() {
	home := get_user_home_dir()
	assert home.len > 0
	assert os.exists(home)

	cfg := get_app_config_dir('test_app')
	assert cfg.contains('test_app')

	data_dir := get_app_data_dir('test_app')
	assert data_dir.contains('test_app')

	desktop := get_system_path('desktop')
	assert desktop.contains('Desktop')

	resolved := resolve_user_path('~/test')
	assert resolved.starts_with(home)
}

fn test_clipboard() {
	test_msg := 'vlang_sysutils_test_payload'
	copy_to_clipboard(test_msg) or { return }
	paste := get_clipboard_text() or { '' }
	assert paste == test_msg
}

fn test_runtime_and_pipe() {
	info := runtime_system_info()
	assert info.os_name.len > 0
	assert info.num_cpus > 0
	assert info.arch.len > 0

	piped := pipe_commands('echo "antigravity rocks"', 'grep "rocks"') or { panic(err) }
	assert piped.contains('antigravity rocks')
}

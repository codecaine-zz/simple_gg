module main

import sysutils

fn main() {
	println('==================================================')
	println('                 demo_sysutils                    ')
	println('==================================================')

	// 1. Hardware & System Telemetry
	cores := sysutils.get_cpu_count()
	uptime := sysutils.get_uptime()
	total_ram, used_ram, ram_pct := sysutils.get_memory_stats()
	total_disk, used_disk, disk_pct := sysutils.get_disk_stats('/')
	l1, l5, l15 := sysutils.get_load_averages()

	println('Hardware Telemetry:')
	println('  CPU Logical Cores: ${cores}')
	println('  System Uptime:     ${uptime} seconds')
	println('  RAM Usage:         ${used_ram / (1024 * 1024)} MB / ${total_ram / (1024 * 1024)} MB (${ram_pct:.1f}%)')
	println('  Root Disk Usage:   ${used_disk / (1024 * 1024 * 1024)} GB / ${total_disk / (1024 * 1024 * 1024)} GB (${disk_pct:.1f}%)')
	println('  Load Averages:     1m=${l1:.2f}, 5m=${l5:.2f}, 15m=${l15:.2f}')
	assert cores > 0
	assert total_ram > 0

	// 2. Safe Process Execution
	out, code := sysutils.exec_safe('echo', ['safe command execution test'])
	println('\nSafe Exec Output: "${out.trim_space()}" (code: ${code})')
	assert code == 0
	assert out.contains('safe command execution test')

	// 3. Command Piping
	piped := sysutils.pipe_commands('echo "antigravity engine"', 'grep "antigravity"') or { '' }
	println('Piped command: "${piped.trim_space()}"')
	assert piped.contains('antigravity')

	// 4. Runtime Info
	info := sysutils.runtime_system_info()
	println('\nRuntime Info:')
	println('  OS:     ${info.os_name}')
	println('  Arch:   ${info.arch}')
	println('  CPUs:   ${info.num_cpus}')
	println('  64-bit: ${info.is_64bit}')
	assert info.num_cpus > 0

	println('\n✔ sysutils demo completed successfully!')
}

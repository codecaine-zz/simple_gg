module main

import netutils

fn main() {
	println('==================================================')
	println('                 demo_netutils                    ')
	println('==================================================')

	// 1. IP & Interface Discovery
	local_ip := netutils.get_local_ip()
	dns := netutils.get_dns_servers()
	gateway := netutils.get_default_gateway()
	online := netutils.is_online()

	println('Network Discovery:')
	println('  Local IP:        ${local_ip}')
	println('  Default Gateway: ${gateway}')
	println('  DNS Servers:     ${dns}')
	println('  Online Status:   ${online}')
	assert local_ip.len > 0
	assert local_ip.contains('.')

	// 2. TCP Port Ping
	ports := netutils.get_listening_ports()
	println('\nListening local ports found: ${ports.len}')
	if ports.len > 0 {
		is_open := netutils.ping_tcp_port('127.0.0.1', ports[0], 500)
		println('  TCP Ping 127.0.0.1:${ports[0]} -> open: ${is_open}')
	}

	// 3. Unopened Port Ping
	is_closed := netutils.ping_tcp_port('127.0.0.1', 65432, 100)
	println('  TCP Ping unopened port 65432 -> open: ${is_closed}')
	assert is_closed == false

	println('\n✔ netutils demo completed successfully!')
}

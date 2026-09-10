module netutils

import net

fn test_network_probes() {
	local_ip := get_local_ip()
	assert local_ip.len > 0
	assert local_ip.contains('.')

	dns := get_dns_servers()
	assert dns.len > 0

	gateway := get_default_gateway()
	assert gateway.len > 0

	ports := get_listening_ports()
	// Should identify listening ports on the host
	assert ports.len > 0

	// Test TCP port check against one of the active listening ports
	if ports.len > 0 {
		is_open := ping_tcp_port('127.0.0.1', ports[0], 500)
		assert is_open == true
	}

	// Test an unopened port
	is_closed := ping_tcp_port('127.0.0.1', 65432, 200)
	assert is_closed == false
}

fn test_tcp_framing() {
	mut listener := net.listen_tcp(.ip, '127.0.0.1:0') or { panic(err) }
	port := (listener.addr() or { panic(err) }).port() or { panic(err) }

	spawn fn (mut l net.TcpListener) {
		mut client := l.accept() or { return }
		msg := read_framed_msg(mut client, 8192) or { return }
		send_framed_msg(mut client, 'REPLY: ${msg.bytestr()}'.bytes()) or { return }
		client.close() or {}
	}(mut listener)

	mut client := net.dial_tcp('127.0.0.1:${port}') or { panic(err) }
	send_framed_msg(mut client, 'test frame'.bytes()) or { panic(err) }
	res := read_framed_msg(mut client, 8192) or { panic(err) }
	assert res.bytestr() == 'REPLY: test frame'
	client.close() or {}
}


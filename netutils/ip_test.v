module netutils

import net
import time

fn test_ipv4_parse_strict() {
	assert ipv4_to_u32('192.168.1.10') or { 0 } == u32(0xC0A8010A)
	assert u32_to_ipv4(0xC0A8010A) == '192.168.1.10'
	assert is_ipv4('0.0.0.0')
	assert is_ipv4('255.255.255.255')
	for bad in ['256.1.1.1', '1.2.3', '1.2.3.4.5', '01.2.3.4', '1..2.3', 'a.b.c.d', ' 1.2.3.4',
		''] {
		assert !is_ipv4(bad), bad
	}
}

fn test_ipv6_rfc5952_vectors() {
	// RFC 5952 §4 examples
	assert compress_ipv6('2001:db8:0:0:1:0:0:1') or { '' } == '2001:db8::1:0:0:1'
	assert compress_ipv6('2001:0db8:0000:0000:0000:0000:0002:0001') or { '' } == '2001:db8::2:1'
	assert compress_ipv6('2001:db8:0:1:1:1:1:1') or { '' } == '2001:db8:0:1:1:1:1:1'
	assert compress_ipv6('2001:db8:0:0:1:0:0:0') or { '' } == '2001:db8:0:0:1::'
	assert compress_ipv6('2001:DB8::AAAA') or { '' } == '2001:db8::aaaa'
	assert compress_ipv6('0:0:0:0:0:0:0:0') or { '' } == '::'
	assert compress_ipv6('0:0:0:0:0:0:0:1') or { '' } == '::1'
	assert compress_ipv6('::ffff:192.0.2.1') or { '' } == '::ffff:192.0.2.1'
	assert compress_ipv6('[fe80::1%en0]') or { '' } == 'fe80::1'
	assert expand_ipv6('2001:db8::1') or { '' } == '2001:0db8:0000:0000:0000:0000:0000:0001'
	for bad in ['1::2::3', '12345::', 'g::1', '1:2:3:4:5:6:7:8:9', '1:2:3:4:5:6:7', ':::'] {
		assert !is_ipv6(bad), bad
	}
}

fn test_cidr_math() {
	n := parse_cidr('192.168.1.77/24') or { panic(err) }
	assert n.str() == '192.168.1.0/24'
	assert n.network_address() == '192.168.1.0'
	assert n.broadcast_address() == '192.168.1.255'
	assert n.netmask() == '255.255.255.0'
	assert n.first_host() == '192.168.1.1'
	assert n.last_host() == '192.168.1.254'
	assert n.size() == 256
	assert n.contains('192.168.1.200')
	assert !n.contains('192.168.2.1')
	assert n.contains('::ffff:192.168.1.5') // IPv4-mapped
	p2p := parse_cidr('10.0.0.0/31') or { panic(err) }
	assert p2p.first_host() == '10.0.0.0' && p2p.last_host() == '10.0.0.1' // RFC 3021
	v6 := parse_cidr('2001:db8::/32') or { panic(err) }
	assert v6.contains('2001:db8:ffff::1')
	assert !v6.contains('2001:db9::1')
	assert v6.broadcast_address() == '2001:db8:ffff:ffff:ffff:ffff:ffff:ffff'
	assert v6.size() == max_u64
	a := parse_cidr('10.0.0.0/8') or { panic(err) }
	b := parse_cidr('10.20.0.0/16') or { panic(err) }
	c := parse_cidr('11.0.0.0/8') or { panic(err) }
	assert a.overlaps(b) && b.overlaps(a) && !a.overlaps(c)
	for bad in ['1.2.3.4/33', '1.2.3.4/-1', '::/129', 'x/8', '1.2.3.4/8a'] {
		parse_cidr(bad) or { continue }
		assert false, bad
	}
}

fn test_ip_classification_ssrf() {
	for ip in ['127.0.0.1', '10.1.2.3', '172.16.5.4', '192.168.0.1', '169.254.169.254', '100.64.0.1',
		'0.0.0.0', '::1', '::', 'fe80::1', 'fd00::1', '::ffff:127.0.0.1', '::ffff:169.254.169.254',
		'224.0.0.1', '2001:db8::1', '198.51.100.7'] {
		assert !is_public_ip(ip), ip
	}
	for ip in ['8.8.8.8', '1.1.1.1', '2606:4700:4700::1111', '::ffff:8.8.8.8'] {
		assert is_public_ip(ip), ip
	}
	assert !is_public_ip('not-an-ip')
	assert is_loopback_ip('127.9.9.9') && is_loopback_ip('::1')
	assert is_private_ip('172.31.255.255') && !is_private_ip('172.32.0.0')
	assert is_link_local_ip('fe80::abcd') && is_multicast_ip('ff02::1')
}

fn test_host_port() {
	assert join_host_port('::1', 80) == '[::1]:80'
	assert join_host_port('example.com', 443) == 'example.com:443'
	h, p := split_host_port('[2001:db8::1]:8080') or { panic(err) }
	assert h == '2001:db8::1' && p == 8080
	h2, p2 := split_host_port('localhost:65535') or { panic(err) }
	assert h2 == 'localhost' && p2 == 65535
	for bad in ['localhost', 'h:99999', 'h:', '::1:80', '[::1]80', 'h:8a'] {
		split_host_port(bad) or { continue }
		assert false, bad
	}
	assert normalize_ip('2001:0DB8::0001') or { '' } == '2001:db8::1'
}

fn test_ports_and_timeouts() {
	port := find_free_port() or { panic(err) }
	assert port > 0
	assert !ping_tcp_port('127.0.0.1', port, 500)
	mut l := net.listen_tcp(.ip, '127.0.0.1:${port}') or { panic(err) }
	defer {
		l.close() or {}
	}
	assert wait_for_port('127.0.0.1', port, 2000)
	// Non-routable address: must return within the timeout instead of hanging.
	t0 := time.now()
	assert !ping_tcp_port('10.255.255.1', 9, 300)
	assert time.since(t0) < 2 * time.second
	ips := resolve_host('localhost') or { panic(err) }
	assert ips.any(it == '127.0.0.1' || it == '::1')
}

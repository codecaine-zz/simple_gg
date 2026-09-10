module netutils

import net
import net.http
import os

// is_online checks whether the system has active Internet connectivity by dialing a public DNS server.
pub fn is_online() bool {
	// Try Cloudflare DNS port 53 (TCP)
	mut conn := net.dial_tcp('1.1.1.1:53') or {
		// Fallback to Google DNS
		mut conn2 := net.dial_tcp('8.8.8.8:53') or { return false }
		conn2.close() or {}
		return true
	}
	conn.close() or {}
	return true
}

// ping_tcp_port tests whether a specific TCP host and port is open and listening.
pub fn ping_tcp_port(host string, port int, timeout_ms int) bool {
	target := '${host}:${port}'
	mut conn := net.dial_tcp(target) or { return false }
	conn.close() or {}
	return true
}

// get_local_ip returns the primary local network IP address of the machine.
pub fn get_local_ip() string {
	$if macos {
		// Try en0 first, then en1
		for iface in ['en0', 'en1', 'en2', 'bridge0'] {
			res := os.execute('ipconfig getifaddr ${iface}')
			ip := res.output.trim_space()
			if res.exit_code == 0 && ip.len > 0 && ip.contains('.') {
				return ip
			}
		}
	}
	$if linux {
		res := os.execute('hostname -I')
		if res.exit_code == 0 {
			fields := res.output.fields()
			if fields.len > 0 && fields[0].contains('.') {
				return fields[0]
			}
		}
	}
	return '127.0.0.1'
}

// get_public_ip resolves the public WAN IP address by querying api.ipify.org.
pub fn get_public_ip() !string {
	res := http.get('https://api.ipify.org') or { return error('failed to reach IP lookup service: ${err}') }
	if res.status_code == 200 && res.body.len > 0 {
		return res.body.trim_space()
	}
	return error('HTTP ${res.status_code} from IP lookup service')
}

// get_mac_address returns the hardware MAC address of the default network interface.
pub fn get_mac_address() string {
	$if macos {
		for iface in ['en0', 'en1', 'bridge0'] {
			res := os.execute('ifconfig ${iface}')
			if res.exit_code == 0 && res.output.contains('ether ') {
				idx := res.output.index('ether ') or { -1 }
				if idx >= 0 {
					sub := res.output[idx + 6..].trim_space()
					fields := sub.fields()
					if fields.len > 0 && fields[0].contains(':') {
						return fields[0]
					}
				}
			}
		}
	}
	$if linux {
		content := os.read_file('/sys/class/net/eth0/address') or {
			os.read_file('/sys/class/net/enp0s3/address') or { '' }
		}
		trimmed := content.trim_space()
		if trimmed.len > 0 {
			return trimmed
		}
	}
	return ''
}

// get_wifi_ssid returns the current Wi-Fi network SSID, or empty string if disconnected / unavailable.
pub fn get_wifi_ssid() string {
	$if macos {
		for iface in ['en0', 'en1'] {
			res := os.execute('networksetup -getairportnetwork ${iface}')
			if res.exit_code == 0 && res.output.contains('Current Wi-Fi Network:') {
				idx := res.output.index('Current Wi-Fi Network:') or { -1 }
				if idx >= 0 {
					return res.output[idx + 23..].trim_space()
				}
			}
		}
	}
	return ''
}

// get_default_gateway returns the default network gateway IP address.
pub fn get_default_gateway() string {
	$if macos {
		res := os.execute('route -n get default')
		if res.exit_code == 0 && res.output.contains('gateway:') {
			idx := res.output.index('gateway:') or { -1 }
			if idx >= 0 {
				sub := res.output[idx + 8..].trim_space()
				fields := sub.fields()
				if fields.len > 0 {
					return fields[0]
				}
			}
		}
	}
	$if linux {
		res := os.execute('ip route show default')
		if res.exit_code == 0 {
			fields := res.output.fields()
			// Format: "default via 192.168.1.1 dev eth0"
			for i in 0 .. fields.len {
				if fields[i] == 'via' && i + 1 < fields.len {
					return fields[i + 1]
				}
			}
		}
	}
	return ''
}

// get_dns_servers returns a list of configured DNS nameserver IP addresses.
pub fn get_dns_servers() []string {
	mut servers := []string{}
	content := os.read_file('/etc/resolv.conf') or { return servers }
	for line in content.split_into_lines() {
		trimmed := line.trim_space()
		if trimmed.starts_with('nameserver ') {
			parts := trimmed.fields()
			if parts.len >= 2 {
				servers << parts[1].trim_space()
			}
		}
	}
	return servers
}

// get_listening_ports returns a sorted list of unique local TCP ports currently in LISTEN state.
pub fn get_listening_ports() []int {
	mut ports := []int{}
	res := os.execute('lsof -nP -iTCP -sTCP:LISTEN')
	if res.exit_code == 0 {
		for line in res.output.split_into_lines() {
			if !line.contains('(LISTEN)') {
				continue
			}
			colon_idx := line.last_index(':') or { -1 }
			space_idx := line.index(' (LISTEN)') or { -1 }
			if colon_idx >= 0 && space_idx > colon_idx {
				port_str := line[colon_idx + 1..space_idx].trim_space()
				port_num := port_str.int()
				if port_num > 0 && port_num !in ports {
					ports << port_num
				}
			}
		}
	}
	ports.sort()
	return ports
}

// send_framed_msg writes a length-prefixed framed binary message using magic header MSG0.
pub fn send_framed_msg(mut conn net.TcpConn, payload []u8) ! {
	mut buf := []u8{len: 8 + payload.len}
	buf[0] = `M`
	buf[1] = `S`
	buf[2] = `G`
	buf[3] = `0`
	buf[4] = u8((u32(payload.len) >> 24) & 0xff)
	buf[5] = u8((u32(payload.len) >> 16) & 0xff)
	buf[6] = u8((u32(payload.len) >> 8) & 0xff)
	buf[7] = u8(u32(payload.len) & 0xff)
	for i in 0 .. payload.len {
		buf[8 + i] = payload[i]
	}
	conn.write(buf)!
}

fn read_exact(mut conn net.TcpConn, size int) ![]u8 {
	mut data := []u8{len: size}
	mut read_bytes := 0
	for read_bytes < size {
		remaining := size - read_bytes
		chunk := if remaining > 512 { 512 } else { remaining }
		n := conn.read(mut data[read_bytes..read_bytes + chunk])!
		if n == 0 {
			return error('unexpected end of stream')
		}
		read_bytes += n
	}
	return data
}

// read_framed_msg reads a length-prefixed framed message ensuring no partial packet fragmentation.
pub fn read_framed_msg(mut conn net.TcpConn, max_size int) ![]u8 {
	hdr := read_exact(mut conn, 8)!
	if hdr[0] != `M` || hdr[1] != `S` || hdr[2] != `G` || hdr[3] != `0` {
		return error('invalid protocol magic header')
	}
	len := int((u32(hdr[4]) << 24) | (u32(hdr[5]) << 16) | (u32(hdr[6]) << 8) | u32(hdr[7]))
	if len > max_size {
		return error('message length ${len} exceeds max size ${max_size}')
	}
	if len == 0 {
		return []u8{}
	}
	return read_exact(mut conn, len)
}

// send_udp transmits a UDP packet to the given host and port.
pub fn send_udp(host string, port int, data []u8) ! {
	mut conn := net.dial_udp('${host}:${port}')!
	defer {
		conn.close() or {}
	}
	conn.write(data)!
}


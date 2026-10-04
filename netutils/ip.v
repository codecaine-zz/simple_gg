module netutils

import net
import time

// ============================================================================
// IPv4
// ============================================================================

// ipv4_to_u32 parses a dotted-quad IPv4 address. Leading zeros are rejected
// because some parsers read them as octal (a well-known SSRF filter bypass).
pub fn ipv4_to_u32(ip string) !u32 {
	parts := ip.split('.')
	if parts.len != 4 {
		return error('invalid IPv4 address "${ip}"')
	}
	mut v := u32(0)
	for p in parts {
		if p.len == 0 || p.len > 3 || !p.bytes().all(it.is_digit()) {
			return error('invalid IPv4 address "${ip}"')
		}
		if p.len > 1 && p[0] == `0` {
			return error('invalid IPv4 address "${ip}": leading zeros are ambiguous')
		}
		n := p.int()
		if n > 255 {
			return error('invalid IPv4 address "${ip}": octet out of range')
		}
		v = (v << 8) | u32(n)
	}
	return v
}

// u32_to_ipv4 formats a 32-bit integer as a dotted-quad address.
pub fn u32_to_ipv4(n u32) string {
	return '${n >> 24}.${(n >> 16) & 0xff}.${(n >> 8) & 0xff}.${n & 0xff}'
}

// is_ipv4 reports whether s is a strictly valid dotted-quad IPv4 address.
pub fn is_ipv4(s string) bool {
	ipv4_to_u32(s) or { return false }
	return true
}

// ============================================================================
// IPv6
// ============================================================================

fn parse_groups(groups []string, allow_v4_last bool) ![]u16 {
	mut out := []u16{}
	for i, g in groups {
		if allow_v4_last && i == groups.len - 1 && g.contains('.') {
			v := ipv4_to_u32(g)!
			out << u16(v >> 16)
			out << u16(v & 0xffff)
			continue
		}
		if g.len == 0 || g.len > 4 {
			return error('invalid IPv6 group "${g}"')
		}
		for c in g {
			if !c.is_hex_digit() {
				return error('invalid IPv6 group "${g}"')
			}
		}
		out << u16(g.parse_uint(16, 16) or { return error('invalid IPv6 group "${g}"') })
	}
	return out
}

// parse_ipv6 parses an IPv6 address (RFC 4291 text forms, including `::`,
// embedded IPv4, brackets and `%zone` suffixes) into 16 bytes.
pub fn parse_ipv6(addr string) ![]u8 {
	mut s := addr
	if s.starts_with('[') && s.ends_with(']') {
		s = s[1..s.len - 1]
	}
	if i := s.index('%') {
		s = s[..i]
	}
	if s.count('::') > 1 || s.len == 0 {
		return error('invalid IPv6 address "${addr}"')
	}
	mut words := []u16{}
	if idx := s.index('::') {
		h := s[..idx]
		t := s[idx + 2..]
		head := if h == '' { []u16{} } else { parse_groups(h.split(':'), t == '')! }
		tail := if t == '' { []u16{} } else { parse_groups(t.split(':'), true)! }
		if head.len + tail.len > 7 {
			return error('invalid IPv6 address "${addr}"')
		}
		words << head
		for _ in 0 .. 8 - head.len - tail.len {
			words << u16(0)
		}
		words << tail
	} else {
		words = parse_groups(s.split(':'), true)!
		if words.len != 8 {
			return error('invalid IPv6 address "${addr}"')
		}
	}
	mut out := []u8{cap: 16}
	for w in words {
		out << u8(w >> 8)
		out << u8(w & 0xff)
	}
	return out
}

// is_ipv6 reports whether s is a valid IPv6 address.
pub fn is_ipv6(s string) bool {
	if !s.contains(':') {
		return false
	}
	parse_ipv6(s) or { return false }
	return true
}

fn words_of(b []u8) []u16 {
	mut w := []u16{cap: 8}
	for i := 0; i < 16; i += 2 {
		w << (u16(b[i]) << 8) | u16(b[i + 1])
	}
	return w
}

fn is_v4_mapped(b []u8) bool {
	if b.len != 16 {
		return false
	}
	for i in 0 .. 10 {
		if b[i] != 0 {
			return false
		}
	}
	return b[10] == 0xff && b[11] == 0xff
}

fn format_ipv6(b []u8) string {
	if is_v4_mapped(b) {
		return '::ffff:${b[12]}.${b[13]}.${b[14]}.${b[15]}'
	}
	w := words_of(b)
	// RFC 5952 §4.2: compress the longest run (>= 2) of zero groups, first on ties.
	mut best_start, mut best_len := -1, 0
	mut i := 0
	for i < 8 {
		if w[i] == 0 {
			mut j := i
			for j < 8 && w[j] == 0 {
				j++
			}
			if j - i > best_len {
				best_start, best_len = i, j - i
			}
			i = j
		} else {
			i++
		}
	}
	if best_len < 2 {
		best_start = -1
	}
	mut parts := []string{}
	mut k := 0
	for k < 8 {
		if k == best_start {
			parts << (if k == 0 { ':' } else { '' })
			k += best_len
			if k == 8 {
				parts << ''
			}
			continue
		}
		parts << '${w[k]:x}'
		k++
	}
	return parts.join(':')
}

// compress_ipv6 returns the canonical RFC 5952 text form (lowercase, no leading
// zeros, longest zero run as `::`, IPv4-mapped addresses in dotted form).
pub fn compress_ipv6(addr string) !string {
	return format_ipv6(parse_ipv6(addr)!)
}

// expand_ipv6 returns the full form with eight 4-digit lowercase groups.
pub fn expand_ipv6(addr string) !string {
	w := words_of(parse_ipv6(addr)!)
	return w.map('${it:04x}').join(':')
}

// ip_to_bytes parses any IPv4 or IPv6 address into 4 or 16 bytes.
pub fn ip_to_bytes(ip string) ![]u8 {
	if v := ipv4_to_u32(ip) {
		return [u8(v >> 24), u8(v >> 16), u8(v >> 8), u8(v)]
	}
	return parse_ipv6(ip)
}

// bytes_to_ip formats 4 or 16 bytes as an address string (canonical form).
pub fn bytes_to_ip(b []u8) string {
	if b.len == 4 {
		return '${b[0]}.${b[1]}.${b[2]}.${b[3]}'
	}
	return format_ipv6(b)
}

// normalize_ip returns the canonical form of an address (IPv6 compressed per
// RFC 5952), or an error if it is not a valid address.
pub fn normalize_ip(ip string) !string {
	return bytes_to_ip(ip_to_bytes(ip)!)
}

// ============================================================================
// CIDR networks
// ============================================================================

// IPNet is a parsed CIDR block (IPv4 or IPv6) with host bits cleared.
pub struct IPNet {
pub:
	network []u8 // 4 or 16 bytes
	prefix  int
}

fn mask_bytes(n int, prefix int) []u8 {
	mut m := []u8{len: n}
	for i in 0 .. n {
		bits := prefix - i * 8
		m[i] = if bits >= 8 {
			u8(0xff)
		} else if bits <= 0 {
			u8(0)
		} else {
			u8(0xff << (8 - bits))
		}
	}
	return m
}

// parse_cidr parses `addr/prefix` (a bare address is treated as /32 or /128).
pub fn parse_cidr(s string) !IPNet {
	addr, plen := if i := s.index('/') { s[..i], s[i + 1..] } else { s, '' }
	b := ip_to_bytes(addr)!
	max := b.len * 8
	prefix := if plen == '' {
		max
	} else {
		if !plen.bytes().all(it.is_digit()) || plen.len > 3 {
			return error('invalid CIDR prefix in "${s}"')
		}
		plen.int()
	}
	if prefix < 0 || prefix > max {
		return error('CIDR prefix /${prefix} out of range for "${s}"')
	}
	m := mask_bytes(b.len, prefix)
	mut net_b := []u8{len: b.len}
	for i in 0 .. b.len {
		net_b[i] = b[i] & m[i]
	}
	return IPNet{
		network: net_b
		prefix:  prefix
	}
}

// is_ipv4 reports whether this is an IPv4 network.
pub fn (n IPNet) is_ipv4() bool {
	return n.network.len == 4
}

// str returns the canonical `network/prefix` form.
pub fn (n IPNet) str() string {
	return '${bytes_to_ip(n.network)}/${n.prefix}'
}

// contains reports whether ip lies inside the network. IPv4-mapped IPv6
// addresses match IPv4 networks.
pub fn (n IPNet) contains(ip string) bool {
	mut b := ip_to_bytes(ip) or { return false }
	if n.network.len == 4 && is_v4_mapped(b) {
		b = b[12..].clone()
	}
	if b.len != n.network.len {
		return false
	}
	m := mask_bytes(b.len, n.prefix)
	for i in 0 .. b.len {
		if b[i] & m[i] != n.network[i] {
			return false
		}
	}
	return true
}

// overlaps reports whether two networks share any address.
pub fn (n IPNet) overlaps(o IPNet) bool {
	if n.network.len != o.network.len {
		return false
	}
	p := if n.prefix < o.prefix { n.prefix } else { o.prefix }
	m := mask_bytes(n.network.len, p)
	for i in 0 .. n.network.len {
		if n.network[i] & m[i] != o.network[i] & m[i] {
			return false
		}
	}
	return true
}

// network_address returns the first address of the block.
pub fn (n IPNet) network_address() string {
	return bytes_to_ip(n.network)
}

fn (n IPNet) last_bytes() []u8 {
	m := mask_bytes(n.network.len, n.prefix)
	mut b := []u8{len: n.network.len}
	for i in 0 .. b.len {
		b[i] = n.network[i] | ~m[i]
	}
	return b
}

// broadcast_address returns the last address of the block.
pub fn (n IPNet) broadcast_address() string {
	return bytes_to_ip(n.last_bytes())
}

// netmask returns the mask in address form (e.g. 255.255.255.0).
pub fn (n IPNet) netmask() string {
	return bytes_to_ip(mask_bytes(n.network.len, n.prefix))
}

// size returns the number of addresses in the block (saturates at max u64).
pub fn (n IPNet) size() u64 {
	host_bits := n.network.len * 8 - n.prefix
	if host_bits >= 64 {
		return max_u64
	}
	return u64(1) << host_bits
}

// first_host returns the first usable host address (RFC 3021: /31 and /32
// networks have no reserved network/broadcast address).
pub fn (n IPNet) first_host() string {
	if !n.is_ipv4() || n.prefix >= 31 {
		return n.network_address()
	}
	mut b := n.network.clone()
	b[3]++
	return bytes_to_ip(b)
}

// last_host returns the last usable host address.
pub fn (n IPNet) last_host() string {
	mut b := n.last_bytes()
	if n.is_ipv4() && n.prefix < 31 {
		b[3]--
	}
	return bytes_to_ip(b)
}

// ============================================================================
// Classification (SSRF defence)
// ============================================================================

const non_public_nets = [
	'0.0.0.0/8',
	'10.0.0.0/8',
	'100.64.0.0/10',
	'127.0.0.0/8',
	'169.254.0.0/16',
	'172.16.0.0/12',
	'192.0.0.0/24',
	'192.0.2.0/24',
	'192.88.99.0/24',
	'192.168.0.0/16',
	'198.18.0.0/15',
	'198.51.100.0/24',
	'203.0.113.0/24',
	'224.0.0.0/4',
	'240.0.0.0/4',
	'::/128',
	'::1/128',
	'64:ff9b:1::/48',
	'100::/64',
	'2001::/23',
	'2001:db8::/32',
	'fc00::/7',
	'fe80::/10',
	'ff00::/8',
]

fn in_any(ip string, nets []string) bool {
	for c in nets {
		n := parse_cidr(c) or { continue }
		if n.contains(ip) {
			return true
		}
	}
	return false
}

// is_loopback_ip reports 127.0.0.0/8 and ::1 (including IPv4-mapped forms).
pub fn is_loopback_ip(ip string) bool {
	return in_any(ip, ['127.0.0.0/8', '::1/128'])
}

// is_private_ip reports RFC 1918 IPv4 ranges and IPv6 unique-local fc00::/7.
pub fn is_private_ip(ip string) bool {
	return in_any(ip, ['10.0.0.0/8', '172.16.0.0/12', '192.168.0.0/16', 'fc00::/7'])
}

// is_link_local_ip reports 169.254.0.0/16 and fe80::/10.
pub fn is_link_local_ip(ip string) bool {
	return in_any(ip, ['169.254.0.0/16', 'fe80::/10'])
}

// is_multicast_ip reports 224.0.0.0/4 and ff00::/8.
pub fn is_multicast_ip(ip string) bool {
	return in_any(ip, ['224.0.0.0/4', 'ff00::/8'])
}

// is_public_ip reports whether ip is a valid, globally routable unicast address,
// i.e. not in any IANA special-purpose block (private, loopback, link-local,
// CGNAT, documentation, benchmarking, multicast, reserved...). Use it to reject
// internal targets before fetching user-supplied URLs (SSRF defence). Resolve
// the hostname first and check every resulting address.
pub fn is_public_ip(ip string) bool {
	b := ip_to_bytes(ip) or { return false }
	if is_v4_mapped(b) {
		return is_public_ip(bytes_to_ip(b[12..]))
	}
	return !in_any(ip, non_public_nets)
}

// ============================================================================
// Host/port helpers
// ============================================================================

// join_host_port combines host and port, bracketing IPv6 literals ([::1]:80).
pub fn join_host_port(host string, port int) string {
	if host.contains(':') && !host.starts_with('[') {
		return '[${host}]:${port}'
	}
	return '${host}:${port}'
}

// split_host_port splits `host:port` / `[v6]:port` and validates the port.
pub fn split_host_port(hostport string) !(string, int) {
	mut host := ''
	mut port_s := ''
	if hostport.starts_with('[') {
		end := hostport.index(']') or { return error('missing "]" in "${hostport}"') }
		host = hostport[1..end]
		rest := hostport[end + 1..]
		if !rest.starts_with(':') {
			return error('missing port in "${hostport}"')
		}
		port_s = rest[1..]
	} else {
		i := hostport.last_index(':') or { return error('missing port in "${hostport}"') }
		host = hostport[..i]
		if host.contains(':') {
			return error('IPv6 address must be bracketed in "${hostport}"')
		}
		port_s = hostport[i + 1..]
	}
	if port_s.len == 0 || port_s.len > 5 || !port_s.bytes().all(it.is_digit()) {
		return error('invalid port in "${hostport}"')
	}
	port := port_s.int()
	if port > 65535 {
		return error('port out of range in "${hostport}"')
	}
	return host, port
}

// find_free_port asks the OS for an unused TCP port on 127.0.0.1.
pub fn find_free_port() !int {
	mut l := net.listen_tcp(.ip, '127.0.0.1:0')!
	defer {
		l.close() or {}
	}
	return int(l.addr()!.port()!)
}

// resolve_host returns the unique IP addresses a hostname resolves to.
pub fn resolve_host(host string) ![]string {
	addrs := net.resolve_addrs_fuzzy(join_host_port(host, 0), .tcp)!
	mut out := []string{}
	for a in addrs {
		h, _ := split_host_port(a.str()) or { continue }
		ip := normalize_ip(h) or { h }
		if ip !in out {
			out << ip
		}
	}
	return out
}

// wait_for_port polls until host:port accepts TCP connections or timeout_ms elapses.
pub fn wait_for_port(host string, port int, timeout_ms int) bool {
	deadline := time.now().add(timeout_ms * time.millisecond)
	for {
		if ping_tcp_port(host, port, 250) {
			return true
		}
		if time.now() > deadline {
			return false
		}
		time.sleep(50 * time.millisecond)
	}
	return false
}

module main

import simplegui
import os
import x.json2
import time

// -------------------------------------------------------------
// Data Structures
// -------------------------------------------------------------

struct IPInfoResponse {
pub mut:
	ip       string
	hostname string
	city     string
	region   string
	country  string
	loc      string
	org      string
	postal   string
	timezone string
	readme   string
}

struct IPApiResponse {
pub mut:
	status       string
	country      string
	country_code string @[json: 'countryCode']
	region       string
	region_name  string @[json: 'regionName']
	city         string
	zip          string
	lat          f64
	lon          f64
	timezone     string
	isp          string
	org          string
	as_info      string @[json: 'as']
	query        string
}

struct IfconfigMeAllResponse {
pub mut:
	ip_addr    string
	user_agent string
	port       string
	method     string
	mime       string
	via        string
	forwarded  string
}

struct AppState {
mut:
	selected_provider  string
	public_ipv4        string
	public_ipv6        string
	active_ip          string
	hostname           string
	city               string
	region             string
	country            string
	country_code       string
	loc_coords         string
	isp_org            string
	asn                string
	timezone           string
	postal_code        string
	raw_json           string
	active_tab         string
	local_interface    string
	local_ipv4         string
	local_netmask      string
	local_broadcast    string
	local_mac          string
	local_gateway      string
	local_dns          string
	target_query       string
	is_refreshing      bool
}

// -------------------------------------------------------------
// Core Network Fetching & Parsing Engine
// -------------------------------------------------------------

fn fetch_curl_url(url string, is_ipv4 bool, is_ipv6 bool) string {
	mut args := ['-s', '--max-time', '4']
	if is_ipv4 {
		args << '-4'
	} else if is_ipv6 {
		args << '-6'
	}
	args << url
	res := simplegui.exec_safe('curl', args)
	if res.exit_code == 0 {
		return res.output.trim_space()
	}
	return ''
}

fn fetch_local_network_telemetry() (string, string, string, string, string, string, string) {
	// 1. Default gateway & interface via route
	mut iface := 'en0'
	mut gateway := 'Unknown'
	route_res := simplegui.exec_safe('route', ['-n', 'get', 'default'])
	if route_res.exit_code == 0 {
		for line in route_res.output.split_into_lines() {
			trimmed := line.trim_space()
			if trimmed.starts_with('interface:') {
				iface = trimmed.replace('interface:', '').trim_space()
			} else if trimmed.starts_with('gateway:') {
				gateway = trimmed.replace('gateway:', '').trim_space()
			}
		}
	}

	// 2. Interface IP, Netmask, Broadcast, MAC via ifconfig
	mut local_ip := 'Unknown'
	mut netmask := 'Unknown'
	mut broadcast := 'Unknown'
	mut mac := 'Unknown'

	ifconfig_res := simplegui.exec_safe('ifconfig', [iface])
	if ifconfig_res.exit_code == 0 {
		for line in ifconfig_res.output.split_into_lines() {
			trimmed := line.trim_space()
			if trimmed.starts_with('inet ') {
				parts := trimmed.split(' ')
				if parts.len >= 2 {
					local_ip = parts[1]
				}
				idx_mask := parts.index('netmask')
				if idx_mask != -1 && idx_mask + 1 < parts.len {
					netmask = parts[idx_mask + 1]
				}
				idx_bcast := parts.index('broadcast')
				if idx_bcast != -1 && idx_bcast + 1 < parts.len {
					broadcast = parts[idx_bcast + 1]
				}
			} else if trimmed.starts_with('ether ') {
				parts := trimmed.split(' ')
				if parts.len >= 2 {
					mac = parts[1]
				}
			}
		}
	}

	// 3. DNS Resolvers via scutil --dns
	mut dns_servers := []string{}
	dns_res := simplegui.exec_safe('scutil', ['--dns'])
	if dns_res.exit_code == 0 {
		for line in dns_res.output.split_into_lines() {
			trimmed := line.trim_space()
			if trimmed.starts_with('nameserver[') {
				parts := trimmed.split(':')
				if parts.len >= 2 {
					srv := parts[1].trim_space()
					if srv != '' && !dns_servers.contains(srv) {
						dns_servers << srv
					}
				}
			}
		}
	}
	dns_str := if dns_servers.len > 0 { dns_servers.join(', ') } else { '1.1.1.1, 8.8.8.8' }

	return iface, local_ip, netmask, broadcast, mac, gateway, dns_str
}

fn country_code_to_flag(code string) string {
	upper := code.to_upper().trim_space()
	if upper.len != 2 {
		return ''
	}
	return match upper {
		'US' { ' US' }
		'CA' { ' CA' }
		'GB' { ' GB' }
		'DE' { ' DE' }
		'FR' { ' FR' }
		'NL' { ' NL' }
		'JP' { ' JP' }
		'AU' { ' AU' }
		'SG' { ' SG' }
		'BR' { ' BR' }
		'IN' { ' IN' }
		'KR' { ' KR' }
		'SE' { ' SE' }
		'CH' { ' CH' }
		'ES' { ' ES' }
		'IT' { ' IT' }
		'MX' { ' MX' }
		else { ' ' + upper }
	}
}

// -------------------------------------------------------------
// Main Application Entry Point
// -------------------------------------------------------------

fn main() {
	println('Starting SimpleGUI - IFConfig Studio Pro (IP & Network Intelligence Workstation)...')

	mut win := simplegui.new_simple_window('IFConfig Studio Pro -- Native macOS IP & Network Intelligence', 1160, 920)
	win.set_fullscreen(true)
	win.restore_saved_theme()
	win.set_spacing(6)
	win.set_padding(14)

	mut state := &AppState{
		selected_provider: 'ifconfig.me & ipinfo.io'
		public_ipv4: 'Resolving...'
		public_ipv6: 'Resolving...'
		active_ip: 'Resolving...'
		hostname: 'Resolving...'
		city: 'Resolving...'
		region: 'Resolving...'
		country: 'Resolving...'
		country_code: 'US'
		loc_coords: '0.00, 0.00'
		isp_org: 'Resolving...'
		asn: 'Resolving...'
		timezone: 'Resolving...'
		postal_code: 'Resolving...'
		raw_json: '{\n  "status": "fetching network telemetry..."\n}'
		active_tab: ' Public IP & Geolocation'
		local_interface: 'en0'
		local_ipv4: 'Detecting...'
		local_netmask: '255.255.255.0'
		local_broadcast: 'Unknown'
		local_mac: 'Unknown'
		local_gateway: 'Unknown'
		local_dns: 'Unknown'
		target_query: '8.8.8.8'
		is_refreshing: false
	}

	// -------------------------------------------------------------
	// Header & Controls
	// -------------------------------------------------------------
	win.begin_row('row_header')
	win.add_heading('IFConfig Studio Pro')

	win.add_label('lbl_provider_hdr', 'Provider:')
	win.add_dropdown('dd_provider', [
		'ifconfig.me & ipinfo.io',
		'ifconfig.me (All JSON)',
		'ipinfo.io (Direct)',
		'ip-api.com (Extended)',
		'icanhazip.com (Raw IP)',
		'ifconfig.co (Fast JSON)',
		'api64.ipify.org (Dual-Stack)'
	], 'ifconfig.me & ipinfo.io')
	win.set_control_width('dd_provider', 190)

	win.add_button('btn_refresh_all', 'Refresh All')

	win.add_label('lbl_theme_hdr', 'Theme:')
	saved_theme := simplegui.get_saved_theme()
	win.add_dropdown('dd_theme_selector', simplegui.list_themes(), saved_theme)
	win.set_control_width('dd_theme_selector', 160)
	win.end_row()

	// -------------------------------------------------------------
	// Navigation Workspace Tabs
	// -------------------------------------------------------------
	win.add_tabs('main_tabs', [
		' Public IP & Geolocation',
		' Target IP / Domain Inspector',
		' Local Network & Adapters',
		' Latency & DNS Benchmark',
		' Raw JSON & Curl Studio'
	])

	// -------------------------------------------------------------
	// Top Summary Highlights Bar (Always Visible)
	// -------------------------------------------------------------
	win.begin_group_box('grp_summary_bar', 'Active Connection Snapshot')
	win.begin_row('row_summary_highlights')
	win.add_label('lbl_sum_ipv4', 'IPv4: Resolving...')
	win.add_label('lbl_sum_ipv6', 'IPv6: Resolving...')
	win.add_label('lbl_sum_location', 'Location: Resolving...')
	win.add_label('lbl_sum_isp', 'ISP: Resolving...')
	win.add_label('lbl_sum_local', 'Local IP: Detecting...')
	win.end_row()
	win.end_group_box()

	// -------------------------------------------------------------
	// View Container 1: Public IP & Geolocation
	// -------------------------------------------------------------
	win.begin_group_box('pane_public_geo', 'Public IP Address & Detailed Geolocation Telemetry')

	// Quick Action Buttons
	win.begin_row('row_geo_quick_actions')
	win.add_button('btn_copy_ipv4', 'Copy IPv4')
	win.add_button('btn_copy_ipv6', 'Copy IPv6')
	win.add_button('btn_copy_all_info', 'Copy Full Summary')
	win.add_button('btn_open_apple_maps', 'Open in Apple Maps')
	win.add_button('btn_open_google_maps', 'Open in Google Maps')
	win.add_button('btn_copy_curl', 'Copy Curl Command')
	win.end_row()

	// Cards Grid Layout
	win.begin_row('row_cards_1')
	win.add_metric_card('card_ipv4', 'Public IPv4 Address', 'Resolving...', 'IPv4', 'Primary internet address')
	win.add_metric_card('card_ipv6', 'Public IPv6 Address', 'Resolving...', 'IPv6', 'Next-gen global address')
	win.add_metric_card('card_city', 'City & Region', 'Resolving...', 'Location', 'Physical geolocation')
	win.end_row()

	win.begin_row('row_cards_2')
	win.add_metric_card('card_country', 'Country & Code', 'Resolving...', 'Country', 'Country flag & ISO code')
	win.add_metric_card('card_isp', 'ISP & Organization', 'Resolving...', 'ISP', 'Internet service provider')
	win.add_metric_card('card_asn', 'Autonomous System', 'Resolving...', 'Routing', 'ASN network route')
	win.end_row()

	// Detailed Text Summary Box
	win.add_textarea('txt_geo_details', 'Connecting to network endpoints (ifconfig.me & ipinfo.io)...')
	win.set_control_height('txt_geo_details', 180)
	win.set_control_font_name('txt_geo_details', 'Menlo')
	win.set_control_font_size('txt_geo_details', 13)

	win.end_group_box()

	// -------------------------------------------------------------
	// View Container 2: Target IP / Domain Inspector
	// -------------------------------------------------------------
	win.begin_group_box('pane_inspector', 'Inspect Arbitrary Remote IP Address or Domain')
	win.begin_row('row_target_input')
	win.add_label('lbl_target_prompt', 'Target IP / Hostname:')
	win.add_input('txt_target_input', '8.8.8.8')
	win.set_control_width('txt_target_input', 240)

	win.add_button('btn_inspect_target', 'INSPECT TARGET')
	win.add_button('btn_set_cf', 'Cloudflare (1.1.1.1)')
	win.add_button('btn_set_goog', 'Google (8.8.8.8)')
	win.add_button('btn_set_gh', 'GitHub (github.com)')
	win.add_button('btn_set_quad9', 'Quad9 (9.9.9.9)')
	win.end_row()

	win.add_textarea('txt_target_output', 'Enter an IP address (e.g. 1.1.1.1, 8.8.8.8) or domain name (e.g. github.com, cloudflare.com) above and click "INSPECT TARGET".\n')
	win.set_control_height('txt_target_output', 440)
	win.set_control_font_name('txt_target_output', 'Menlo')
	win.set_control_font_size('txt_target_output', 13)
	win.end_group_box()

	// -------------------------------------------------------------
	// View Container 3: Local Network & Adapters
	// -------------------------------------------------------------
	win.begin_group_box('pane_local_net', 'macOS Local Network Adapters, Gateway & Hardware MAC')
	win.begin_row('row_local_cards')
	win.add_metric_card('card_local_ip', 'Local Private IPv4', 'Resolving...', 'LAN', 'Local subnet IP')
	win.add_metric_card('card_gateway', 'Default Gateway', 'Resolving...', 'Router', 'Upstream router')
	win.add_metric_card('card_mac', 'MAC Hardware Address', 'Resolving...', 'Hardware', 'Adapter MAC')
	win.end_row()

	win.begin_row('row_local_actions')
	win.add_button('btn_refresh_local', 'Refresh Network Interfaces')
	win.add_button('btn_copy_local_ip', 'Copy Local IP')
	win.add_button('btn_copy_mac', 'Copy MAC Address')
	win.add_button('btn_copy_gateway', 'Copy Gateway')
	win.end_row()

	win.add_textarea('txt_local_details', 'Scanning local adapters with ifconfig and networksetup...')
	win.set_control_height('txt_local_details', 320)
	win.set_control_font_name('txt_local_details', 'Menlo')
	win.set_control_font_size('txt_local_details', 13)
	win.end_group_box()

	// -------------------------------------------------------------
	// View Container 4: Latency & DNS Benchmark
	// -------------------------------------------------------------
	win.begin_group_box('pane_benchmark', 'Anycast DNS Ping Benchmark & DNS/HTTP Protocol Diagnostics')
	win.begin_row('row_bench_ctrls')
	win.add_button('btn_run_ping_bench', 'RUN PING LATENCY BENCHMARK')
	win.add_button('btn_lookup_dns', 'Lookup DNS Records')
	win.add_button('btn_check_http_headers', 'Inspect HTTP Response Headers')
	win.add_label('lbl_bench_target', 'Domain/Host:')
	win.add_input('txt_bench_host', 'google.com')
	win.set_control_width('txt_bench_host', 180)
	win.end_row()

	win.add_textarea('txt_benchmark_output', 'Click "RUN PING LATENCY BENCHMARK" to test response latency across Cloudflare, Google, Quad9, OpenDNS, and GitHub.\n')
	win.set_control_height('txt_benchmark_output', 440)
	win.set_control_font_name('txt_benchmark_output', 'Menlo')
	win.set_control_font_size('txt_benchmark_output', 13)
	win.end_group_box()

	// -------------------------------------------------------------
	// View Container 5: Raw JSON & Curl Studio
	// -------------------------------------------------------------
	win.begin_group_box('pane_json_studio', 'Raw JSON Response & CLI Curl Script Studio')
	win.begin_row('row_json_ctrls')
	win.add_button('btn_copy_raw_json', 'Copy JSON')
	win.add_button('btn_prettify_raw_json', 'Prettify JSON')
	win.add_button('btn_minify_raw_json', 'Minify JSON')
	win.add_button('btn_export_json_file', 'Save JSON File...')
	win.add_label('lbl_curl_hint', '  (Curl Command: curl -s ifconfig.me/all.json)')
	win.end_row()

	win.add_textarea('txt_raw_json', '{\n  "loading": true\n}')
	win.set_control_height('txt_raw_json', 440)
	win.set_control_font_name('txt_raw_json', 'Menlo')
	win.set_control_font_size('txt_raw_json', 13)
	win.end_group_box()

	// Initially hide inactive tab panes
	win.set_control_visible('pane_inspector', false)
	win.set_control_visible('pane_local_net', false)
	win.set_control_visible('pane_benchmark', false)
	win.set_control_visible('pane_json_studio', false)

	// -------------------------------------------------------------
	// Status Bar Footer
	// -------------------------------------------------------------
	win.begin_row('row_footer')
	win.add_label('lbl_status_bar', 'Initializing telemetry engine...')
	win.end_row()

	// -------------------------------------------------------------
	// UI Update Helper
	// -------------------------------------------------------------
	apply_state_to_ui := fn [state] (mut w simplegui.SimpleWindow) {
		flag_display := country_code_to_flag(state.country_code)

		// 1. Update Metric Cards via set_metric_card_value
		w.set_metric_card_value('card_ipv4', state.public_ipv4, 'IPv4')
		w.set_metric_card_value('card_ipv6', state.public_ipv6, 'IPv6')
		w.set_metric_card_value('card_city', '${state.city}, ${state.region}', 'Location')
		w.set_metric_card_value('card_country', '${flag_display} (${state.country})', 'Country')
		w.set_metric_card_value('card_isp', state.isp_org, 'ISP')
		w.set_metric_card_value('card_asn', state.asn, 'Routing')

		w.set_metric_card_value('card_local_ip', state.local_ipv4, 'LAN')
		w.set_metric_card_value('card_gateway', state.local_gateway, 'Router')
		w.set_metric_card_value('card_mac', state.local_mac, 'Hardware')

		// 2. Update Top Highlights Bar
		w.set('lbl_sum_ipv4', ' IPv4: ' + state.public_ipv4)
		w.set('lbl_sum_ipv6', ' IPv6: ' + (if state.public_ipv6.len > 24 { state.public_ipv6[..24] + '...' } else { state.public_ipv6 }))
		w.set('lbl_sum_location', ' Location: ${state.city}, ${state.country}')
		w.set('lbl_sum_isp', ' ISP: ' + (if state.isp_org.len > 22 { state.isp_org[..22] + '...' } else { state.isp_org }))
		w.set('lbl_sum_local', ' LAN: ' + state.local_ipv4)

		// 3. Update Detailed Geolocation Report
		mut rep := []string{}
		rep << '========================================================================'
		rep << ' IFCONFIG & GEOLOCATION INTELLIGENCE REPORT'
		rep << '========================================================================'
		rep << 'Public IPv4 Address : ' + state.public_ipv4
		rep << 'Public IPv6 Address : ' + state.public_ipv6
		rep << 'Reverse DNS / Host  : ' + state.hostname
		rep << 'City & Region       : ' + state.city + ', ' + state.region
		rep << 'Country             : ' + state.country + ' (' + state.country_code + ') ' + flag_display
		rep << 'Postal / ZIP Code   : ' + state.postal_code
		rep << 'GPS Coordinates     : ' + state.loc_coords + ' (Latitude, Longitude)'
		rep << 'ISP & Organization  : ' + state.isp_org
		rep << 'Autonomous System   : ' + state.asn
		rep << 'Timezone            : ' + state.timezone
		rep << 'Local Adapter (LAN) : ' + state.local_interface + ' | IP: ' + state.local_ipv4 + ' | MAC: ' + state.local_mac
		rep << 'Default Gateway     : ' + state.local_gateway + ' | DNS: ' + state.local_dns
		rep << '========================================================================'
		w.set('txt_geo_details', rep.join('\n'))

		// 4. Update Local Network Details Box
		mut loc_rep := []string{}
		loc_rep << '========================================================================'
		loc_rep << ' MACOS LOCAL NETWORK ADAPTERS & HARDWARE TELEMETRY'
		loc_rep << '========================================================================'
		loc_rep << 'Active Interface    : ' + state.local_interface
		loc_rep << 'Local Private IPv4  : ' + state.local_ipv4
		loc_rep << 'Subnet Mask         : ' + state.local_netmask
		loc_rep << 'Broadcast Address   : ' + state.local_broadcast
		loc_rep << 'MAC Hardware (Ether): ' + state.local_mac
		loc_rep << 'Default Gateway     : ' + state.local_gateway
		loc_rep << 'System DNS Servers  : ' + state.local_dns
		loc_rep << '========================================================================\n'
		loc_rep << 'RAW IFCONFIG OUTPUT:\n'
		ifconfig_raw := simplegui.exec_safe('ifconfig', [state.local_interface])
		loc_rep << ifconfig_raw.output
		w.set('txt_local_details', loc_rep.join('\n'))

		// 5. Update Raw JSON View
		w.set('txt_raw_json', state.raw_json)

		timestamp := time.now().format_ss()
		w.set('lbl_status_bar', ' Live | Updated at ${timestamp} | IPv4: ${state.public_ipv4} | Location: ${state.city}, ${state.country} | Provider: ${state.selected_provider}')
	}

	// -------------------------------------------------------------
	// Asynchronous Telemetry Refresh Engine
	// -------------------------------------------------------------
	async_refresh_telemetry := fn [mut state, apply_state_to_ui] (mut w simplegui.SimpleWindow) {
		if state.is_refreshing {
			w.toast('Refresh already in progress...')
			return
		}
		state.is_refreshing = true
		w.toast('Querying network & IP endpoints...')
		w.set('lbl_status_bar', ' Querying public IP and geolocation endpoints...')

		// Launch background worker thread
		go fn [mut state, mut w, apply_state_to_ui] () {
			// 1. Fetch IPv4 from ifconfig.me
			v4 := fetch_curl_url('ifconfig.me', true, false)
			res_v4 := if v4 != '' { v4 } else { fetch_curl_url('icanhazip.com', true, false) }
			state.public_ipv4 = if res_v4 != '' { res_v4 } else { 'Unavailable' }

			// 2. Fetch IPv6 from ifconfig.me
			v6 := fetch_curl_url('ifconfig.me', false, true)
			res_v6 := if v6 != '' { v6 } else { fetch_curl_url('icanhazip.com', false, true) }
			state.public_ipv6 = if res_v6 != '' { res_v6 } else { 'No IPv6 Route' }

			// 3. Fetch Rich Geolocation JSON from ipinfo.io
			raw_ipinfo := fetch_curl_url('ipinfo.io', false, false)
			state.raw_json = if raw_ipinfo != '' { raw_ipinfo } else { '{\n  "error": "No response"\n}' }

			if raw_ipinfo != '' {
				info := json2.decode[IPInfoResponse](raw_ipinfo) or { IPInfoResponse{} }
				if info.ip != '' {
					state.active_ip = info.ip
					state.hostname = if info.hostname != '' { info.hostname } else { 'None / Direct' }
					state.city = if info.city != '' { info.city } else { 'Unknown' }
					state.region = if info.region != '' { info.region } else { 'Unknown' }
					state.country = if info.country != '' { info.country } else { 'Unknown' }
					state.country_code = info.country
					state.loc_coords = if info.loc != '' { info.loc } else { '0.00,0.00' }
					state.isp_org = if info.org != '' { info.org } else { 'Unknown ISP' }
					state.postal_code = if info.postal != '' { info.postal } else { 'N/A' }
					state.timezone = if info.timezone != '' { info.timezone } else { 'UTC' }

					if state.isp_org.starts_with('AS') {
						parts := state.isp_org.split(' ')
						state.asn = parts[0]
					} else {
						state.asn = 'N/A'
					}
				}
			}

			// 4. Fetch Local Network Info
			iface, local_ip, netmask, broadcast, mac, gateway, dns := fetch_local_network_telemetry()
			state.local_interface = iface
			state.local_ipv4 = local_ip
			state.local_netmask = netmask
			state.local_broadcast = broadcast
			state.local_mac = mac
			state.local_gateway = gateway
			state.local_dns = dns
			state.is_refreshing = false

			// Dispatch UI update on main thread
			w.run_on_main_thread(fn [apply_state_to_ui] (mut win_main simplegui.SimpleWindow) {
				apply_state_to_ui(mut win_main)
				win_main.toast('Network telemetry updated!')
			})
		}()
	}

	// -------------------------------------------------------------
	// Event Callbacks
	// -------------------------------------------------------------

	// Refresh All Button
	win.on_click('btn_refresh_all', fn [async_refresh_telemetry] (mut w simplegui.SimpleWindow) {
		async_refresh_telemetry(mut w)
	})

	// Theme Selector
	win.on_change('dd_theme_selector', fn (mut w simplegui.SimpleWindow, selected string) {
		w.set_theme(selected)
		w.toast('Theme changed to ${selected}')
	})

	// Workspace Tabs Navigation
	win.on_change('main_tabs', fn [mut state] (mut w simplegui.SimpleWindow, tab string) {
		state.active_tab = tab

		w.set_control_visible('pane_public_geo', tab == ' Public IP & Geolocation')
		w.set_control_visible('pane_inspector', tab == ' Target IP / Domain Inspector')
		w.set_control_visible('pane_local_net', tab == ' Local Network & Adapters')
		w.set_control_visible('pane_benchmark', tab == ' Latency & DNS Benchmark')
		w.set_control_visible('pane_json_studio', tab == ' Raw JSON & Curl Studio')

		w.toast('Switched to ' + tab)
	})

	// Provider Switcher
	win.on_change('dd_provider', fn [mut state, async_refresh_telemetry] (mut w simplegui.SimpleWindow, selected string) {
		state.selected_provider = selected
		if selected == 'ifconfig.me (All JSON)' {
			json_res := fetch_curl_url('ifconfig.me/all.json', false, false)
			w.set('txt_raw_json', json_res)
			w.toast('Loaded ifconfig.me all.json payload.')
		} else if selected == 'ip-api.com (Extended)' {
			json_res := fetch_curl_url('http://ip-api.com/json', false, false)
			w.set('txt_raw_json', json_res)
			w.toast('Loaded ip-api.com payload.')
		} else {
			async_refresh_telemetry(mut w)
		}
	})

	// -------------------------------------------------------------
	// Public IP & Geolocation Actions
	// -------------------------------------------------------------
	win.on_click('btn_copy_ipv4', fn [state] (mut w simplegui.SimpleWindow) {
		w.copy_to_clipboard(state.public_ipv4)
		w.toast('Copied IPv4: ' + state.public_ipv4)
	})

	win.on_click('btn_copy_ipv6', fn [state] (mut w simplegui.SimpleWindow) {
		w.copy_to_clipboard(state.public_ipv6)
		w.toast('Copied IPv6: ' + state.public_ipv6)
	})

	win.on_click('btn_copy_all_info', fn (mut w simplegui.SimpleWindow) {
		rep := w.get('txt_geo_details')
		w.copy_to_clipboard(rep)
		w.toast('Copied entire IP summary to clipboard!')
	})

	win.on_click('btn_open_apple_maps', fn [state] (mut w simplegui.SimpleWindow) {
		if state.loc_coords != '' && state.loc_coords != '0.00, 0.00' {
			simplegui.exec_safe('open', ['https://maps.apple.com/?q=' + state.loc_coords])
			w.toast('Opening coordinates in Apple Maps...')
		} else {
			w.toast('Coordinates not available.')
		}
	})

	win.on_click('btn_open_google_maps', fn [state] (mut w simplegui.SimpleWindow) {
		if state.loc_coords != '' && state.loc_coords != '0.00, 0.00' {
			simplegui.exec_safe('open', ['https://www.google.com/maps/search/?api=1&query=' + state.loc_coords])
			w.toast('Opening coordinates in Google Maps...')
		} else {
			w.toast('Coordinates not available.')
		}
	})

	win.on_click('btn_copy_curl', fn (mut w simplegui.SimpleWindow) {
		cmd := 'curl -s ifconfig.me'
		w.copy_to_clipboard(cmd)
		w.toast('Copied: ' + cmd)
	})

	// -------------------------------------------------------------
	// Target Inspector Actions
	// -------------------------------------------------------------
	inspect_target_fn := fn (mut w simplegui.SimpleWindow, target string) {
		clean_target := target.trim_space()
		if clean_target == '' {
			w.alert('Empty Target', 'Please enter a valid IP or domain.')
			return
		}
		w.toast('Inspecting target: ' + clean_target + '...')

		start_time := time.now()

		// Query ip-api.com for target
		url := 'http://ip-api.com/json/' + clean_target
		res := simplegui.exec_safe('curl', ['-s', '--max-time', '5', url])
		elapsed_ms := (time.now() - start_time).milliseconds()

		mut out := []string{}
		out << '========================================================================'
		out << ' REMOTE TARGET INSPECTION: ' + clean_target
		out << 'Response Time: ${elapsed_ms} ms'
		out << '========================================================================'

		if res.exit_code == 0 && res.output != '' {
			geo := json2.decode[IPApiResponse](res.output) or { IPApiResponse{} }
			if geo.status == 'success' {
				flag := country_code_to_flag(geo.country_code)
				out << 'IP / Resolved Query : ' + geo.query
				out << 'Location            : ' + geo.city + ', ' + geo.region_name + ', ' + geo.country + ' ' + flag
				out << 'Postal / ZIP Code   : ' + geo.zip
				out << 'GPS Coordinates     : ${geo.lat:.4f}, ${geo.lon:.4f}'
				out << 'ISP Provider        : ' + geo.isp
				out << 'Organization        : ' + geo.org
				out << 'Autonomous System   : ' + geo.as_info
				out << 'Timezone            : ' + geo.timezone
			} else {
				out << 'Lookup Status: ' + geo.status
				out << 'Raw API Output: ' + res.output
			}
		} else {
			out << 'Failed to query remote IP endpoint: ' + res.output
		}

		// DNS lookup query using dig
		dig_res := simplegui.exec_safe('dig', ['+noall', '+answer', clean_target, 'A'])
		if dig_res.exit_code == 0 && dig_res.output.trim_space() != '' {
			out << '\n DNS A RECORDS (dig):\n' + dig_res.output.trim_space()
		}

		out << '========================================================================\n'
		w.set('txt_target_output', out.join('\n'))
		w.toast('Inspection complete for ' + clean_target)
	}

	win.on_click('btn_inspect_target', fn [inspect_target_fn] (mut w simplegui.SimpleWindow) {
		t := w.get('txt_target_input')
		inspect_target_fn(mut w, t)
	})

	win.on_click('btn_set_cf', fn [inspect_target_fn] (mut w simplegui.SimpleWindow) {
		w.set('txt_target_input', '1.1.1.1')
		inspect_target_fn(mut w, '1.1.1.1')
	})

	win.on_click('btn_set_goog', fn [inspect_target_fn] (mut w simplegui.SimpleWindow) {
		w.set('txt_target_input', '8.8.8.8')
		inspect_target_fn(mut w, '8.8.8.8')
	})

	win.on_click('btn_set_gh', fn [inspect_target_fn] (mut w simplegui.SimpleWindow) {
		w.set('txt_target_input', 'github.com')
		inspect_target_fn(mut w, 'github.com')
	})

	win.on_click('btn_set_quad9', fn [inspect_target_fn] (mut w simplegui.SimpleWindow) {
		w.set('txt_target_input', '9.9.9.9')
		inspect_target_fn(mut w, '9.9.9.9')
	})

	// -------------------------------------------------------------
	// Local Network Actions
	// -------------------------------------------------------------
	win.on_click('btn_refresh_local', fn [mut state] (mut w simplegui.SimpleWindow) {
		iface, local_ip, netmask, broadcast, mac, gateway, dns := fetch_local_network_telemetry()
		state.local_interface = iface
		state.local_ipv4 = local_ip
		state.local_netmask = netmask
		state.local_broadcast = broadcast
		state.local_mac = mac
		state.local_gateway = gateway
		state.local_dns = dns

		w.set_metric_card_value('card_local_ip', state.local_ipv4, 'LAN')
		w.set_metric_card_value('card_gateway', state.local_gateway, 'Router')
		w.set_metric_card_value('card_mac', state.local_mac, 'Hardware')

		mut loc_rep := []string{}
		loc_rep << '========================================================================'
		loc_rep << ' MACOS LOCAL NETWORK ADAPTERS & HARDWARE TELEMETRY'
		loc_rep << '========================================================================'
		loc_rep << 'Active Interface    : ' + state.local_interface
		loc_rep << 'Local Private IPv4  : ' + state.local_ipv4
		loc_rep << 'Subnet Mask         : ' + state.local_netmask
		loc_rep << 'Broadcast Address   : ' + state.local_broadcast
		loc_rep << 'MAC Hardware (Ether): ' + state.local_mac
		loc_rep << 'Default Gateway     : ' + state.local_gateway
		loc_rep << 'System DNS Servers  : ' + state.local_dns
		loc_rep << '========================================================================\n'
		ifconfig_raw := simplegui.exec_safe('ifconfig', [state.local_interface])
		loc_rep << ifconfig_raw.output
		w.set('txt_local_details', loc_rep.join('\n'))
		w.toast('Refreshed local network adapters.')
	})

	win.on_click('btn_copy_local_ip', fn [state] (mut w simplegui.SimpleWindow) {
		w.copy_to_clipboard(state.local_ipv4)
		w.toast('Copied Local IP: ' + state.local_ipv4)
	})

	win.on_click('btn_copy_mac', fn [state] (mut w simplegui.SimpleWindow) {
		w.copy_to_clipboard(state.local_mac)
		w.toast('Copied MAC Address: ' + state.local_mac)
	})

	win.on_click('btn_copy_gateway', fn [state] (mut w simplegui.SimpleWindow) {
		w.copy_to_clipboard(state.local_gateway)
		w.toast('Copied Gateway IP: ' + state.local_gateway)
	})

	// -------------------------------------------------------------
	// Latency & DNS Benchmark Actions
	// -------------------------------------------------------------
	win.on_click('btn_run_ping_bench', fn (mut w simplegui.SimpleWindow) {
		w.toast('Running Anycast DNS & Server latency benchmark...')

		targets := [
			'1.1.1.1 (Cloudflare DNS)',
			'8.8.8.8 (Google DNS)',
			'9.9.9.9 (Quad9 DNS)',
			'208.67.222.222 (OpenDNS)',
			'github.com (GitHub)',
			'apple.com (Apple)'
		]

		mut out := []string{}
		out << '========================================================================'
		out << ' ANYCAST DNS & GLOBAL LATENCY BENCHMARK (macOS ping -c 3)'
		out << '========================================================================'
		out << 'Target Host                   | Avg Latency  | Packet Loss | Status'
		out << '------------------------------------------------------------------------'

		for item in targets {
			parts := item.split(' ')
			ip := parts[0]
			ping_res := simplegui.exec_safe('ping', ['-c', '3', '-t', '2', ip])

			mut avg_ms := 'Timeout'
			mut loss := '100%'
			mut status := ' Down/Blocked'

			if ping_res.exit_code == 0 {
				for line in ping_res.output.split_into_lines() {
					if line.contains('packet loss') {
						if idx := line.index('%') {
							start := line[..idx].last_index(' ') or { 0 }
							loss = line[start..idx + 1].trim_space()
						}
					} else if line.contains('round-trip') || line.contains('avg') {
						split_slash := line.split('/')
						if split_slash.len >= 5 {
							avg_ms = split_slash[4] + ' ms'
							status = ' Excellent'
						}
					}
				}
			}

			disp_name := if item.len < 30 { item + ' '.repeat(30 - item.len) } else { item }
			out << '${disp_name} | ${avg_ms} | ${loss} | ${status}'
		}
		out << '========================================================================\n'

		w.set('txt_benchmark_output', out.join('\n'))
		w.toast('Latency benchmark finished!')
	})

	win.on_click('btn_lookup_dns', fn (mut w simplegui.SimpleWindow) {
		host := w.get('txt_bench_host').trim_space()
		if host == '' { return }
		w.toast('Resolving DNS records for ' + host + '...')

		mut out := []string{}
		out << '========================================================================'
		out << ' DNS RECORDS RESOLUTION FOR: ' + host
		out << '========================================================================'

		record_types := ['A', 'AAAA', 'MX', 'TXT', 'NS', 'CNAME', 'SOA']
		for rtype in record_types {
			res := simplegui.exec_safe('dig', ['+noall', '+answer', host, rtype])
			if res.exit_code == 0 && res.output.trim_space() != '' {
				out << '\n[ ${rtype} RECORDS ]:\n' + res.output.trim_space()
			}
		}
		out << '\n========================================================================\n'
		w.set('txt_benchmark_output', out.join('\n'))
		w.toast('DNS resolution completed for ' + host)
	})

	win.on_click('btn_check_http_headers', fn (mut w simplegui.SimpleWindow) {
		mut host := w.get('txt_bench_host').trim_space()
		if host == '' { return }
		if !host.starts_with('http://') && !host.starts_with('https://') {
			host = 'https://' + host
		}
		w.toast('Fetching HTTP headers from ' + host + '...')

		res := simplegui.exec_safe('curl', ['-I', '-s', '--max-time', '6', host])
		mut out := []string{}
		out << '========================================================================'
		out << ' HTTP/HTTPS RESPONSE HEADERS (curl -I ' + host + ')'
		out << '========================================================================\n'
		if res.exit_code == 0 && res.output.trim_space() != '' {
			out << res.output.trim_space()
		} else {
			out << 'Failed to fetch HTTP headers: ' + res.output
		}
		out << '\n========================================================================\n'
		w.set('txt_benchmark_output', out.join('\n'))
		w.toast('HTTP headers fetched!')
	})

	// -------------------------------------------------------------
	// Raw JSON Studio Actions
	// -------------------------------------------------------------
	win.on_click('btn_copy_raw_json', fn (mut w simplegui.SimpleWindow) {
		j := w.get('txt_raw_json')
		w.copy_to_clipboard(j)
		w.toast('Copied raw JSON to clipboard!')
	})

	win.on_click('btn_prettify_raw_json', fn (mut w simplegui.SimpleWindow) {
		j := w.get('txt_raw_json').trim_space()
		if j == '' { return }
		res := simplegui.exec_safe_stdin('python3', ['-m', 'json.tool'], j)
		if res.exit_code == 0 && res.output.trim_space() != '' {
			w.set('txt_raw_json', res.output)
			w.toast('Prettified JSON structure!')
		}
	})

	win.on_click('btn_minify_raw_json', fn (mut w simplegui.SimpleWindow) {
		j := w.get('txt_raw_json').trim_space()
		if j == '' { return }
		res := simplegui.exec_safe_stdin('python3', ['-c', 'import sys, json; print(json.dumps(json.loads(sys.stdin.read()), separators=(",", ":")))'], j)
		if res.exit_code == 0 && res.output.trim_space() != '' {
			w.set('txt_raw_json', res.output.trim_space())
			w.toast('Minified JSON to single line!')
		}
	})

	win.on_click('btn_export_json_file', fn (mut w simplegui.SimpleWindow) {
		save_path := w.save_file_picker()
		if save_path != '' {
			mut real_path := save_path
			if !real_path.ends_with('.json') {
				real_path += '.json'
			}
			j := w.get('txt_raw_json')
			os.write_file(real_path, j) or {
				w.alert('Export Error', 'Failed to write JSON file.')
				return
			}
			w.toast('Saved JSON to ' + os.file_name(real_path))
		}
	})

	// Trigger initial background telemetry refresh upon startup
	go fn (mut w simplegui.SimpleWindow, refresh_fn fn (mut simplegui.SimpleWindow)) {
		time.sleep(120 * time.millisecond)
		w.run_on_main_thread(fn [refresh_fn] (mut win_main simplegui.SimpleWindow) {
			refresh_fn(mut win_main)
		})
	}(mut win, async_refresh_telemetry)

	println('IFConfig Studio Pro configured. Starting event loop...')
	win.run()
}

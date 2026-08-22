# SimpleCLI: Headless Console & RAD Toolkit for V

`simplecli` is a comprehensive, lightweight, zero-window console utility framework and Rapid Application Development (RAD) toolkit for the V programming language. It brings all the cross-platform OS system calls, hardware resource monitoring, desktop notifications, speech synthesis, standard path resolvers, cryptography, HTTP, generic data structures, string similarity metrics, multi-level logging, CLI flag parsing, and stdlib wrappers directly to command-line utilities and automation scripts without requiring any graphical window backend (no `gg`/`sokol` GUI dependencies).

---

## Table of Contents

1. [Architecture & Application Lifecycle](#1-architecture--application-lifecycle)
2. [CLI Flags & Argument Parsing](#2-cli-flags--argument-parsing)
3. [Console UI & RAD Components](#3-console-ui--rad-components)
4. [Interactive Prompts, Menus & Input Validation](#4-interactive-prompts-menus--input-validation)
5. [Structured Multi-Level Logging & File Logging](#5-structured-multi-level-logging--file-logging)
6. [Benchmark & Execution Timing](#6-benchmark--execution-timing)
7. [Reactive State Store & File Persistence](#7-reactive-state-store--file-persistence)
8. [Safe Process Execution & Subprocess Control](#8-safe-process-execution--subprocess-control)
9. [Hardware Telemetry & Resource Probing](#9-hardware-telemetry--resource-probing)
10. [Standard OS Directory Resolution & File System](#10-standard-os-directory-resolution--file-system)
11. [Network, Wi-Fi & TCP Port Diagnostics](#11-network-wi-fi--tcp-port-diagnostics)
12. [Desktop Notifications, Speech & Audio Utilities](#12-desktop-notifications-speech--audio-utilities)
13. [System Clipboard & Headless OS Native Dialogs](#13-system-clipboard--headless-os-native-dialogs)
14. [HTTP Client & REST APIs](#14-http-client--rest-apis)
15. [Cryptography, Hashing & Random Utilities](#15-cryptography-hashing--random-utilities)
16. [Encodings, Data Formats & Serialization](#16-encodings-data-formats--serialization)
17. [Validation Engine](#17-validation-engine)
18. [Generic Collections, Queues & String Metrics](#18-generic-collections-queues--string-metrics)
19. [Statistical Math Calculations](#19-statistical-math-calculations)
20. [Standalone Package Functions (1-Liners)](#20-standalone-package-functions-1-liners)

---

## 1. Architecture & Application Lifecycle

### Constructors

```v
module main

import simplecli

fn main() {
	// Standard constructor
	mut app1 := simplecli.new('MyTool')

	// Constructor with explicit version
	mut app2 := simplecli.new_app('DeployPilot', '2.1.0')

	// Automatic constructor taking name from default
	mut app3 := simplecli.init_app()
}
```

### Configuration & Fluent Setup

```v
mut app := simplecli.new('Sentinel')
	.set_version('1.5.0')
	.set_author('DevOps Core Team')
	.set_description('High-performance endpoint guardian & telemetry reporter')
	.set_debug(true)
	.set_no_color(false)
	.set_silent(false)
	.set_log_level(.info)
	.set_log_file('/tmp/sentinel.log')
```

---

## 2. CLI Flags & Argument Parsing

Define typed CLI flags with long names, short aliases, default values, and help descriptions:

```v
mut app := simplecli.new_app('Migrator', '2.0.0')

// Register typed flags
app.add_flag_string('config', 'c', 'app.config.json', 'Path to JSON configuration')
app.add_flag_int('port', 'p', 5432, 'Target database port')
app.add_flag_bool('dry-run', 'd', false, 'Simulate execution without modifying state')
app.add_flag_float('timeout', 't', 30.0, 'Network timeout in seconds')

// Parse command line arguments from os.args
app.parse_cli() or {
	// Automatically outputs flag usage or version if --help/-h or --version/-v was passed
	return
}

// Access parsed flag values
cfg_file   := app.get_flag_string('config')
db_port    := app.get_flag_int('port')
is_dry_run := app.get_flag_bool('dry-run')
timeout    := app.get_flag_float('timeout')
extra_args := app.get_positional_args() // Free arguments passed after flags

// Explicitly display the generated help table on demand
app.print_help()
```

Custom argument slices can also be parsed with `app.parse_args(args []string)`:

```v
app.parse_args(['--config', 'custom.json', '--port', '8080', 'deploy', 'target1'])!
```

---

## 3. Console UI & RAD Components

### Terminal ANSI Styling

```v
app.println(app.bold('Bold headline text'))
app.println(app.dim('Muted debug commentary'))
app.println(app.green('✓ All 48 tests passed successfully'))
app.println(app.cyan('ℹ Connecting to database cluster...'))
app.println(app.yellow('⚠ High disk usage detected'))
app.println(app.red('✖ Fatal connection drop'))
app.println(app.blue('⚡ Initializing thread pool'))
app.println(app.magenta('◆ Deployment tag v2.4.0'))
```

### Steps, Dividers, Banners & Panels

```v
// Step indicator with number and title
app.step(1, 'Compiling Native Binaries')
app.step(2, 'Running Static Analysis Checks')

// Horizontal dividers
app.divider('─', 60)
app.divider('=', 80)

// Header banner with title and subtitle
app.banner('Sentinel Infrastructure Pilot', 'Production Node 04 - us-east-1')

// Framed panel with bordered title
app.panel('Cluster Health', 'All 12 nodes reporting healthy heartbeat (RTT < 4ms).')

// Card style panel (alias for panel)
app.card('Security Status', 'TLS 1.3 Strict Mode enforced. Certificates valid for 84 days.')
```

### Key-Value Pairs & Formatted Tables

```v
// Output aligned key-value status dictionary
app.print_kv({
	'Host Name': 'srv-prod-api-01',
	'IP Address': '10.0.4.18',
	'Architecture': 'aarch64 (Apple Silicon)',
	'Uptime': '14 days, 6 hours',
})

// Output formatted data grid with aligned column widths and borders
app.table(
	['Endpoint', 'Protocol', 'Latency', 'Status'],
	[
		['https://api.internal/v1', 'HTTP/2', '12.4 ms', '200 OK'],
		['https://auth.internal', 'HTTP/2', '8.1 ms', '200 OK'],
		['postgres://10.0.0.5:5432', 'TCP', '1.2 ms', 'CONNECTED'],
		['redis://10.0.0.9:6379', 'TCP', '0.4 ms', 'CONNECTED'],
	]
)
```

### Dynamic Progress Bars & Spinners

```v
// Render progress bars in long-running loops
total_items := 100.0
for i in 1 .. 101 {
	app.progress_bar(f64(i), total_items, 'Migrating database tables')
	time.sleep(20 * time.millisecond)
}

// Display animated terminal spinner during synchronous operations
app.spinner('Synchronizing repository submodules...', 1500)
```

---

## 4. Interactive Prompts, Menus & Input Validation

### Text, Secret & Typed Prompts

```v
// Plain string prompt with optional default
username := app.prompt('Enter admin username', 'admin')

// Hidden / masked password prompt
api_token := app.prompt_password('Enter secret API access token')

// Validated email prompt (re-prompts until valid email syntax)
email := app.prompt_email('Enter alert recipient email', 'devops@corp.internal')

// Validated URL prompt (re-prompts until valid http/https URL)
webhook := app.prompt_url('Enter Slack Webhook URL', 'https://hooks.slack.com/services/xxx')

// Constrained numeric prompt between min and max bounds
threads := app.prompt_number('Worker thread concurrency', 8, 1, 64)

// Custom validated prompt with predicate lambda
code := app.prompt_validated('Enter 4-digit MFA code', '1234', fn (s string) bool {
	return s.len == 4 && s.int() > 0
}, 'Code must be exactly 4 numeric digits')

// Yes/No confirmation prompt (returns bool)
proceed := app.confirm('Do you want to apply migrations to production?', false)
```

### Single & Multi-Select Menus

```v
// Single selection menu with string option return
choice := app.select('Choose build target environment:', [
	'Local Development',
	'Staging Integration',
	'Production Release',
])
app.info('Selected environment: ${choice}')

// Multi-select menu with comma-separated numbers (e.g. "1, 3")
selected := app.multi_select('Select deployment components to verify:', [
	'PostgreSQL Database',
	'Redis Cache',
	'Kafka Event Streams',
	'Elasticsearch Index',
])
app.info('Components to check: ${selected.join(", ")}')
```

---

## 5. Structured Multi-Level Logging & File Logging

`simplecli` provides structured logging with timestamps, level tags, ANSI colors, and automatic file log streaming:

```v
mut app := simplecli.new('Runner')

// Configure log file path for persistent audit logs
app.set_log_file('/var/log/mytool.log')

// Set minimum display log level (.trace, .debug, .info, .warn, .error, .silent)
app.set_log_level(.debug)

// Multi-level log calls
app.trace('Detailed execution trace dump')
app.debug('Loaded configuration from config.json with 14 keys')
app.info('Worker thread pool initialized with 8 threads')
app.success('Successfully provisioned staging environment')
app.warn('High memory usage detected (> 85%)')
app.error('Failed to connect to secondary database node')

// Fatal log call outputs error, writes to log file, and terminates process with exit code 1
// app.fatal('Unrecoverable database corruption')
```

---

## 6. Benchmark & Execution Timing

Track execution duration with microsecond/millisecond precision:

```v
// Reset the high-resolution execution timer
app.reset_timer()

// Perform heavy computation or batch I/O
time.sleep(340 * time.millisecond)

// Read elapsed time
elapsed_ms := app.elapsed_ms() // i64 (e.g. 340)

// Print formatted elapsed runtime directly
app.print_elapsed()
```

---

## 7. Reactive State Store & File Persistence

Store key-value runtime configuration and persist it to JSON state files:

```v
// Set and get memory-backed state
app.set_state('last_sync', '2026-08-22T12:00:00Z')
app.set_state('active_profile', 'staging-us-east')
app.set_state('port', '8080')
app.set_state('is_leader', 'true')

profile   := app.get_state('active_profile', 'default')
port_num  := app.get_state_int('port', 3000)
is_leader := app.get_state_bool('is_leader', false)

// Save full key-value state to persistent JSON file on disk
state_path := app.get_system_path('state') + '/mytool_state.json'
app.save_state(state_path)!

// Restore state from JSON file on subsequent runs
app.load_state(state_path)!

// Clear in-memory state
app.clear_state()
```

---

## 8. Safe Process Execution & Subprocess Control

Execute system commands safely with strict argument quoting, timeouts, retries, and parallel background threads:

### Execution Functions

```v
// Standard synchronous execution (returns output string and exit code)
out, code := app.exec('git rev-parse HEAD')

// Execution with fallback output string if command fails
branch := app.exec_or('git rev-parse --abbrev-ref HEAD', 'main')

// Execution within a specific working directory
tags, _ := app.exec_in_dir('/path/to/repo', 'git tag --list')

// Non-blocking background launch
app.exec_bg('redis-server /etc/redis.conf')

// Safe execution preventing shell injection (automatically POSIX-quotes every arg)
res, exit_code := app.exec_safe('git', ['commit', '-m', 'User input; rm -rf /'])

// Timeout guard (terminates process if exceeds timeout in milliseconds)
stdout, err_code, timed_out := app.exec_timeout('ping -c 10 8.8.8.8', 2000)

// Retry execution loop with exponential backoff
retry_res := app.exec_retry('curl -s https://api.site.com/health', 3, 500, 2.0)
println('Status: ${retry_res.exit_code}, Output: ${retry_res.output}')

// Concurrent parallel command execution across worker threads
results := app.parallel_exec([
	'curl -s https://api.ipify.org',
	'git --version',
	'uname -a',
])
for r in results {
	println('${r.command} -> exit code ${r.exit_code}')
}
```

### Argument Sanitization & Quoting

```v
clean_arg := simplecli.quote_arg("user's query & payload; echo 1")
clean_path := simplecli.quote_path('/Volumes/External Drive/App Data')
safe_name := simplecli.sanitize_filename('../../../etc/passwd') // 'passwd'
```

### Process Inspection & Control

```v
// Command discovery and requirement assertions
has_docker := app.command_exists('docker')
docker_path := app.require_command('docker')! // returns absolute path or fails
bin_loc := app.find_executable('psql')

// Active process checks & termination
is_running := app.is_process_running('postgres')
app.kill_process('stray_worker')
app.kill_process_by_pid(12345)

// Process metrics
pid := app.get_pid()
uptime_sec := app.get_uptime_seconds()
procs := app.get_running_process_count()
open_fds := app.get_open_file_count()

// Readiness polling with timeout
file_ready := app.wait_for_file('/var/run/app.pid', 5000)
port_ready := app.wait_for_port('127.0.0.1', 5432, 5000)

// Environment variables
app.set_env('STAGE', 'production')
stage_val := app.get_env('STAGE')
app.unset_env('STAGE')
```

---

## 9. Hardware Telemetry & Resource Probing

Query cross-platform hardware, system metrics, and OS configurations:

```v
// CPU information
cpu_model := app.get_cpu_info()
cores     := app.get_cpu_cores()
arch      := app.get_cpu_architecture()
cpu_usage := app.get_cpu_usage_percent()
l1, l5, l15 := app.get_load_average()

// Memory & Disk
ram_info   := app.get_memory_info()
swap_info  := app.get_swap_usage()
disk_stats := app.get_disk_usage('/')!
println('Disk: ${disk_stats.free_gb:.1f} GB free of ${disk_stats.total_gb:.1f} GB (${disk_stats.percent_used:.1f}% used)')

// Power & Battery
battery_pct := app.get_battery_percent()
is_charging := app.is_on_ac_power()

// System Locale & Desktop Appearance
locale := app.get_system_locale()
theme  := app.get_system_theme() // 'Dark' or 'Light'
accent := app.get_system_accent_color()
```

---

## 10. Standard OS Directory Resolution & File System

Cross-platform standard folder resolvers with support for `~` and environment variables:

### Standard Paths

```v
home_dir   := simplecli.get_user_home_dir()
config_dir := simplecli.get_app_config_dir('my_app')
data_dir   := simplecli.get_app_data_dir('my_app')
cache_dir  := simplecli.get_app_cache_dir('my_app')
state_dir  := simplecli.get_app_state_dir('my_app')
log_dir    := simplecli.get_app_log_dir('my_app')

// Dynamic resolution via name: 'home', 'desktop', 'documents', 'downloads', 'config', 'data', 'cache', 'state', 'logs', 'temp'
downloads  := app.get_system_path('downloads')
resolved   := simplecli.resolve_user_path('~/Projects/app.conf')
```

### File Operations

```v
// Existence & directory checks
exists := app.file_exists('~/data/config.json')
is_dir := app.is_dir('~/data')

// File read / write (automatically creates parent directory tree)
app.write_file('~/data/config.json', '{"port": 8080}')
app.append_file('~/data/audit.log', 'User login at 10:00 AM')
content := app.read_file('~/data/config.json')

// Copy, move, delete
app.copy_file('~/data/config.json', '~/data/config.bak')!
app.move_file('~/data/config.bak', '~/data/config.old')!
app.delete_file('~/data/config.old')

// Directory management & recursive scanning
app.create_directory('~/data/backups/daily')
entries := app.read_dir('~/data')
v_sources := app.list_files_recursive('~/Projects/my_app', '.v')

// Detailed file metadata
meta := app.get_file_metadata('~/data/config.json')!
println('Name: ${meta.name}, Size: ${meta.size_bytes} bytes, Readable: ${meta.is_readable}')

// Reveal in desktop file explorer or open web browser
app.reveal_in_file_manager('~/data/config.json')
app.open_in_browser('https://vlang.io')
```

### Overwrite & Persistence Behavior Matrix

| Method | Default Behavior | Parent Dirs Created? | Safe Non-Overwrite Alternative |
| :--- | :--- | :--- | :--- |
| `app.write_file(path, content)` | **Always Overwrites** (truncates target) | ✅ Yes | Guard with `if !app.file_exists(path)` |
| `app.append_file(path, content)` | **Appends** (preserves existing content) | ✅ Yes | N/A (non-destructive) |
| `app.copy_file(src, dst)!` | **Overwrites** destination if present | ✅ Yes | Guard with `if !app.file_exists(dst)` |
| `app.move_file(src, dst)!` | **Overwrites** / replaces destination | ❌ No | Guard with `if !app.file_exists(dst)` |
| `app.http_download(url, dst)!` | **Always Overwrites** destination | ✅ Yes | Guard with `if !app.file_exists(dst)` |
| `app.save_state(path)!` | **Always Overwrites** JSON state file | ✅ Yes | Check existence or create `.bak` |

### Practical Overwrite & File Safety Patterns

#### 1. Default Overwriting (Auto-creating Parent Directories)
```v
// Overwrites target file if it already exists; creates all necessary parent directories automatically
app.write_file('~/data/export/report.json', '{"status": "ok"}')
```

#### 2. Guarded Non-Overwriting
```v
target_path := '~/data/config.json'
if app.file_exists(target_path) {
	app.log_warn('File already exists: ${target_path}. Skipping write to prevent data loss.')
} else {
	app.write_file(target_path, default_config)
	app.log_info('Config initialized at ${target_path}')
}
```

#### 3. CLI Flag-Controlled Overwrite (`--overwrite` / `--force`)
```v
app.add_flag_bool('overwrite', 'f', false, 'Force overwrite existing target files')
app.parse_cli() or { return }

target_path := '~/data/output.csv'
if app.file_exists(target_path) && !app.get_flag_bool('overwrite') {
	app.log_error('Destination ${target_path} already exists. Pass --overwrite or -f to replace.')
	return
}
app.write_file(target_path, csv_payload)
```

#### 4. Interactive User Confirmation Before Overwrite
```v
target_path := '~/data/production.db'
if app.file_exists(target_path) {
	if !app.prompt_confirm('File "${target_path}" already exists. Overwrite?', false) {
		app.log_info('Operation cancelled by user.')
		return
	}
}
app.write_file(target_path, new_db_data)
```

#### 5. Safe Backup Before Overwrite
```v
file_path := '~/data/important.json'
if app.file_exists(file_path) {
	backup_path := '${file_path}.bak'
	app.copy_file(file_path, backup_path)!
	app.log_info('Created safety backup at ${backup_path}')
}
app.write_file(file_path, updated_payload)
```

#### 6. Non-Destructive Log Appending
```v
// Append logs or streaming outputs without truncating previous contents
app.append_file('~/logs/audit.log', '[${app.now()}] Job processed\n')
```

#### 7. Copy & Move Safety Guards
```v
src := '~/data/input.raw'
dst := '~/data/archive/input.raw'

if app.file_exists(dst) {
	app.log_warn('Destination already exists: ${dst}')
} else {
	app.copy_file(src, dst)!
}
```

---

## 11. Network, Wi-Fi & TCP Port Diagnostics

```v
// Connectivity checks
online := app.is_online()
db_open := app.ping_tcp_port('10.0.0.5', 5432, 1000)

// IP addresses & MAC hardware
local_ip  := app.get_local_ip()
public_ip := app.get_public_ip()
mac_addr  := app.get_mac_address()

// Network routing & Wi-Fi
wifi_ssid := app.get_wifi_ssid()
gateway   := app.get_default_gateway()
dns_hosts := app.get_dns_servers()
listeners := app.get_listening_ports()
println('Active listening TCP ports: ${listeners}')
```

---

## 12. Desktop Notifications, Speech & Audio Utilities

```v
// Native OS desktop banner notifications
app.notify('Build Successful', 'Artifacts uploaded to repository.')
app.show_system_notification('Backup Complete', 'All 18 tables backed up.')

// macOS Dock integration
app.bounce_dock()
app.set_dock_badge('5')

// Terminal bell and system audio sounds
app.beep()
app.beep_n(3)
app.play_system_sound('Ping')

// Text-to-Speech (TTS) synthesizer
app.say('System operational.')
app.speak_with_voice('Deployment finished.', 'Samantha')

// Volume controls
vol := app.get_volume()
app.set_volume(80)
is_mute := app.is_muted()
app.set_muted(false)
```

---

## 13. System Clipboard & Headless OS Native Dialogs

```v
// System Clipboard
app.copy_to_clipboard('Copied API Key')
current_clip := app.get_clipboard_text()
app.clear_clipboard()

// Headless native OS confirmation dialog (OK / Cancel)
confirmed := app.ask('Confirm Operation', 'Do you want to purge cached data?')

// macOS Native AppleScript popups
user_input := app.osascript_dialog('Enter server hostname:', 'localhost')
chosen_file := app.osascript_choose_file()
chosen_dir := app.osascript_choose_folder()
```

---

## 14. HTTP Client & REST APIs

```v
// URL parsing
url_info := app.parse_url('https://api.example.com:8443/v2/items?filter=active#results')!
println('Host: ${url_info.host}, Port: ${url_info.port}, Path: ${url_info.path}, Query: ${url_info.query}')

// Simplified HTTP GET and POST
body := app.http_get('https://api.ipify.org')
resp_text := app.http_post('https://httpbin.org/post', '{"key":"value"}')

// Full custom HTTP request
res := app.http_request('PUT', 'https://api.example.com/v1/resource', '{"status":"active"}')!
println('HTTP ${res.status_code}: ${res.body}')

// File download streaming to disk
app.http_download('https://example.com/release.tar.gz', '/tmp/release.tar.gz')!
```

---

## 15. Cryptography, Hashing & Random Utilities

```v
// Cryptographic hashes
h256 := app.crypto_sha256('secret text')
h512 := app.crypto_sha512('secret text')
h1   := app.crypto_sha1('secret text')
md5  := app.crypto_md5('secret text')
hmac := app.crypto_hmac_sha256('signing_key', 'payload data')

// BCrypt password hashing & verification
bcrypt_hash := app.crypto_bcrypt_hash('my_secure_password')!
is_valid := app.crypto_bcrypt_verify('my_secure_password', bcrypt_hash)

// AES-256-CTR Symmetric Encryption & Decryption
cipher_b64 := app.crypto_aes_encrypt('my_secret_key_32_bytes_long_!', 'Sensitive Data')!
plaintext := app.crypto_aes_decrypt('my_secret_key_32_bytes_long_!', cipher_b64)!

// Random values
uuid_v4 := app.rand_uuid()
rand_str := app.rand_string(16)
rand_num := app.rand_int(100, 999)
rand_float := app.rand_f64()
```

---

## 16. Encodings, Data Formats & Serialization

```v
// Base64 & Hex
b64 := app.base64_encode('Binary Data')
decoded := app.base64_decode(b64)
hex_str := app.hex_encode('Hello')
raw_str := app.hex_decode(hex_str)

// JSON manipulation & extraction
formatted_json := app.json_pretty('{"a":1,"b":"text"}')
json_payload := '{"service": "auth_node", "port": 9000, "active": true}'
svc_name  := app.json_get_string(json_payload, 'service', 'unknown')
svc_port  := app.json_get_int(json_payload, 'port', 80)
is_active := app.json_get_bool(json_payload, 'active', false)

// CSV & TOML parsing
csv_rows := app.csv_parse('id,name,role\n1,Alice,Admin\n2,Bob,User')
toml_doc := app.toml_parse('title = "App"\n[server]\nport = 8080')!

// Gzip Compression
compressed_bytes := app.gzip_compress('Large payload text...')!
uncompressed := app.gzip_decompress(compressed_bytes)!

// Regular Expression & SemVer comparison
matches := app.regex_match('^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$', 'user@domain.com')
cmp := app.semver_compare('1.2.0', '1.1.9')! // Returns 1 (v1 > v2), 0 (v1 == v2), -1 (v1 < v2)

// Placeholder text generator
lorem := app.lorem_words(12)
```

---

## 17. Validation Engine

```v
valid_email := app.validate_email('contact@company.com')
valid_url   := app.validate_url('https://sub.domain.org/path')
valid_ip    := app.validate_ip('192.168.1.50')
valid_phone := app.validate_phone('+1-555-019-2834')
valid_alnum := app.validate_alphanumeric('AlphaNumeric123')
in_range    := app.validate_numeric_range(42.0, 10.0, 100.0)
valid_len   := app.validate_length('Password123', 8, 32)
```

---

## 18. Generic Collections, Queues & String Metrics

### Generic Stack (LIFO)

```v
mut stack := simplecli.new_stack[string]()
stack.push('first')
stack.push('second')
top := stack.pop() // 'second'
peek := stack.peek() // 'first'
is_empty := stack.is_empty() // false
size := stack.len() // 1
```

### Generic Queue (FIFO)

```v
mut queue := simplecli.new_queue[int]()
queue.push(10)
queue.push(20)
first := queue.pop() // 10
head := queue.peek() // 20
```

### Generic Circular Ring Buffer

```v
mut ring := simplecli.new_ring_buffer[string](100)
ring.push('log item 1')
ring.push('log item 2')
total := ring.len()
```

### Min-Heap Priority Queue

```v
mut heap := simplecli.new_min_heap()
heap.push(35.5)
heap.push(12.2)
heap.push(88.0)
min_val := heap.pop() // 12.2
```

### String Similarity & Edit Distance

```v
dist := app.levenshtein_distance('kitten', 'sitting') // 3
ratio := app.similarity_ratio('simplecli', 'simplegui') // 0.7777... (77.8% match)
```

---

## 19. Statistical Math Calculations

Perform rapid statistics on floating-point datasets:

```v
data := [12.0, 15.0, 18.0, 22.0, 29.0, 35.0]

mean_val    := app.stats_mean(data)
median_val  := app.stats_median(data)
std_dev     := app.stats_std_dev(data)
geo_mean    := app.stats_geometric_mean(data)
harm_mean   := app.stats_harmonic_mean(data)
rms_val     := app.stats_rms(data)
min_item    := app.stats_min(data)
max_item    := app.stats_max(data)

println('Mean: ${mean_val:.2f}, StdDev: ${std_dev:.2f}, RMS: ${rms_val:.2f}')
```

---

## 20. Standalone Package Functions (1-Liners)

For lightweight scripts and quick automations, call `simplecli` package functions directly without instantiating `SimpleCli`:

```v
import simplecli

fn main() {
	// Execute shell command
	out, code := simplecli.exec('git status -s')
	fallback := simplecli.exec_or('git rev-parse HEAD', 'unknown')

	// System hardware & metrics
	cpu := simplecli.cpu_info()
	ram := simplecli.memory_info()
	cores := simplecli.cpu_cores()

	// Text-to-speech & audio alert
	simplecli.say('Pipeline completed')
	simplecli.sys_beep()

	// Desktop notification banner
	simplecli.notify('Job Complete', 'Artifacts published.')

	// Cryptography, UUID & Encodings
	h256 := simplecli.crypto_sha256('mypassword')
	uuid := simplecli.rand_uuid()
	b64  := simplecli.base64_encode('Payload')
	raw  := simplecli.base64_decode(b64)

	// HTTP Requests
	html := simplecli.http_get('https://example.com')
	post_res := simplecli.http_post('https://httpbin.org/post', '{"test":true}')
}
```

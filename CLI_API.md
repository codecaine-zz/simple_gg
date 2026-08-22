# SimpleCLI: Headless Console & RAD Toolkit for V

`simplecli` is a comprehensive, lightweight, zero-window console utility framework and Rapid Application Development (RAD) toolkit for the V programming language. It brings all the cross-platform OS system calls, hardware resource monitoring, desktop notifications, speech synthesis, standard path resolvers, cryptography, HTTP, generic data structures, string similarity metrics, multi-level logging, CLI flag parsing, and stdlib wrappers directly to command-line utilities and automation scripts without requiring any graphical window backend (no `gg`/`sokol` GUI dependencies).

---

## Table of Contents

1. [Quickstart](#1-quickstart)
2. [CLI Flags & Argument Parsing](#2-cli-flags--argument-parsing)
3. [Console UI & RAD Components](#3-console-ui--rad-components)
4. [Interactive Prompts & Validated Inputs](#4-interactive-prompts--validated-inputs)
5. [Structured Multi-Level Logging & File Logs](#5-structured-multi-level-logging--file-logs)
6. [Safe Command Execution & Process Management](#6-safe-command-execution--process-management)
7. [Hardware & Resource Monitoring](#7-hardware--resource-monitoring)
8. [Standard Paths & File System](#8-standard-paths--file-system)
9. [Network, Wi-Fi & TCP Port Diagnostics](#9-network-wi-fi--tcp-port-diagnostics)
10. [Desktop Notifications, Audio, Dock & Speech](#10-desktop-notifications-audio-dock--speech)
11. [Generic Collections & Priority Queues](#11-generic-collections--priority-queues)
12. [Validation Engine & URL Parsing](#12-validation-engine--url-parsing)
13. [Standard Library, Crypto, JSON & HTTP Toolkit](#13-standard-library-crypto-json--http-toolkit)
14. [Reactive State Store & File Persistence](#14-reactive-state-store--file-persistence)
15. [Standalone 1-Liner Package Functions](#15-standalone-1-liner-package-functions)

---

## 1. Quickstart

Create a new console application:

```v
module main

import simplecli

fn main() {
	mut app := simplecli.new_app('DeployBot', '1.0.0')

	// Define CLI Flags
	app.add_flag_string('env', 'e', 'staging', 'Target deployment environment')
	app.add_flag_int('port', 'p', 8080, 'Listening port')
	app.add_flag_bool('dry-run', 'd', false, 'Simulate deployment without execution')
	app.parse_cli() or { return }

	// Render styled banner
	app.banner('DeployBot Workspace CLI', 'v1.0.0')

	// Access parsed flags
	env := app.get_flag_string('env')
	app.info('Deploying to environment: ${env}')

	// System & hardware inspection
	cpu := app.get_cpu_info()
	ram := app.get_memory_info()
	app.print_kv({
		'CPU': cpu,
		'RAM': ram,
	})

	// Safe process execution
	branch, _ := app.exec_safe('git', ['rev-parse', '--abbrev-ref', 'HEAD'])
	app.info('Active branch: ${branch}')

	// Desktop alert & TTS
	app.notify('Deployment Ready', 'Ready on branch ${branch}')
}
```

---

## 2. CLI Flags & Argument Parsing

`simplecli` has built-in flag definition and argument parsing with automatic `--help` (`-h`), `--version` (`-v`), `--debug`, `--no-color`, and `--silent` support:

```v
mut app := simplecli.new_app('Migrator', '2.0.0')

// Define flags
app.add_flag_string('config', 'c', 'default.json', 'Path to config file')
app.add_flag_int('port', 'p', 5432, 'Database port')
app.add_flag_bool('dry-run', 'd', false, 'Simulate without applying')
app.add_flag_float('timeout', 't', 30.0, 'Operation timeout in seconds')

// Parse os.args automatically
app.parse_cli()!

// Access parsed flags
cfg := app.get_flag_string('config')
port := app.get_flag_int('port')
is_dry := app.get_flag_bool('dry-run')
timeout_sec := app.get_flag_float('timeout')
positional := app.get_positional_args() // Remaining non-flag arguments
```

---

## 3. Console UI & RAD Components

### ANSI Colors & Styling

```v
app.bold('Important Header')
app.dim('Subtitle text')
app.green('Success status')
app.cyan('Info highlight')
app.yellow('Warning message')
app.red('Critical error')
app.blue('Network payload')
app.magenta('Special tag')
```

### Banners, Panels & Cards

```v
// ASCII Banner
app.banner('Application Name', 'Subtitle or version')

// Boxed Panel / Card
app.panel('Diagnostic Status', 'All 12 microservices healthy.\nMemory usage within threshold.')

// Horizontal Divider
app.divider('─', 70)

// Workflow Steps
app.step(1, 'Database Migration')
```

### Formatted Data Tables

```v
headers := ['ID', 'Task Name', 'Status', 'Duration']
rows := [
	['101', 'Optimize Assets', 'Done', '240ms'],
	['102', 'Compile Binaries', 'Running', '1.2s'],
	['103', 'Deploy Artifacts', 'Pending', '--'],
]
app.table(headers, rows)
```

### Progress Bars & Spinners

```v
// Progress Bar (current, total, label)
for i in 1 .. 101 {
	app.progress_bar(f64(i), 100.0, 'Uploading build...')
}

// Simulated Spinner
app.spinner('Synchronizing repository...', 1500)
```

---

## 4. Interactive Prompts & Validated Inputs

```v
// Standard Text Prompt
name := app.prompt('Enter project name', 'my-v-service')

// Masked / Sensitive Password Prompt
apiKey := app.prompt_password('Enter API secret key')

// Validated Email Input
email := app.prompt_email('Enter admin email', 'admin@example.com')

// Validated URL Input
repo := app.prompt_url('Enter Git URL', 'https://github.com/vlang/v')

// Validated Numeric Range Prompt
port := app.prompt_number('Enter port', 8080, 1024, 65535)

// Custom Validator Prompt
code := app.prompt_validated('Enter 4-digit code', '1234', fn (s string) bool {
	return s.len == 4 && s.int() > 0
}, 'Code must be exactly 4 digits.')

// Confirmation Prompt ([Y/n] or [y/N])
if app.confirm('Do you want to proceed with deployment?', true) {
	app.info('Deploying...')
}

// Single Selection Menu
env := app.select('Choose deployment target:', [
	'Development (Local)',
	'Staging (Pre-release)',
	'Production (Global)',
])

// Multi-Selection Menu
tags := app.multi_select('Select enabled modules:', [
	'WebSockets',
	'PostgreSQL',
	'Redis Cache',
	'Prometheus Metrics',
])
```

---

## 5. Structured Multi-Level Logging & File Logs

`simplecli` supports multi-level structured logging (`trace`, `debug`, `info`, `warn`, `error`, `fatal`) with optional file log streaming:

```v
mut app := simplecli.new('WorkerService')

// Configure log file & minimum log level
app.set_log_file('~/logs/worker.log')
app.set_log_level(.debug)

app.trace('Entering worker main loop')
app.debug('Connection pool active: 16 connections')
app.info('Processed batch of 500 records')
app.warn('High memory consumption detected')
app.error('Database connection timed out')
// app.fatal('Unrecoverable disk error') // logs error and terminates with exit code 1
```

---

## 6. Safe Command Execution & Process Management

```v
// Safe Shell Execution (prevents command injection)
out, code := app.exec_safe('git', ['commit', '-m', 'User input message with ; and &'])

// POSIX Quoting & Filename Sanitization
quoted := simplecli.quote_arg('unsafe input; rm -rf /')
clean_name := simplecli.sanitize_filename('../../passwords.txt') // 'passwords.txt'

// Command Verification & Dependency Requirements
has_git := app.command_exists('git')
git_path := app.require_command('git')! // returns absolute path or fails

// Readiness Waits
has_file := app.wait_for_file('~/build/output.bin', 5000)
has_port := app.wait_for_port('127.0.0.1', 8080, 5000)

// Parallel Concurrent Command Execution (Worker Threads)
results := app.parallel_exec([
	'curl -s https://api.github.com',
	'curl -s https://api.ipify.org',
	'git status',
])

// Timeout Guard (milliseconds)
out, code, timed_out := app.exec_timeout('ping -c 10 8.8.8.8', 2000)

// Retry with Exponential Backoff
res := app.exec_retry('curl -s https://api.ipify.org', 3, 500, 2.0)

// Process Control & Telemetry
pid := app.get_pid()
uptime_sec := app.get_uptime_seconds()
procs := app.get_running_process_count()
open_files := app.get_open_file_count()
app.kill_process('node')
```

---

## 7. Hardware & Resource Monitoring

```v
cpu_name := app.get_cpu_info()
cores := app.get_cpu_cores()
arch := app.get_cpu_architecture()
ram := app.get_memory_info()
cpu_usage := app.get_cpu_usage_percent()
l1, l5, l15 := app.get_load_average()
battery := app.get_battery_percent()
is_charging := app.is_on_ac_power()
swap := app.get_swap_usage()
locale := app.get_system_locale()
theme := app.get_system_theme()
accent_color := app.get_system_accent_color()
```

---

## 8. Standard Paths & File System

```v
// User & Application Paths
home_dir := app.get_system_path('home')
docs_dir := app.get_system_path('documents')
conf_dir := app.get_system_path('config')
data_dir := app.get_system_path('data')
state_dir := app.get_system_path('state')
temp_dir := app.get_system_path('temp')

// File Operations (automatically creates parent folders)
app.write_file('~/my_app/config.json', '{ "debug": true }')
content := app.read_file('~/my_app/config.json')
exists := app.file_exists('~/my_app/config.json')
app.copy_file('~/my_app/config.json', '~/my_app/config.backup.json')!
app.move_file('~/my_app/temp.txt', '~/my_app/saved.txt')!
app.delete_file('~/my_app/saved.txt')

// Reveal in Finder / File Explorer & Web Browser
app.reveal_in_file_manager('~/my_app/config.json')
app.open_in_browser('https://vlang.io')

// Recursive Directory Scanning
v_files := app.list_files_recursive('~/my_project', '.v')
```

---

## 9. Network, Wi-Fi & TCP Port Diagnostics

```v
// Connectivity
is_online := app.is_online()
is_db_up := app.ping_tcp_port('127.0.0.1', 5432, 1000)

// Network Telemetry
local_ip := app.get_local_ip()
public_ip := app.get_public_ip()
mac_addr := app.get_mac_address()
wifi_ssid := app.get_wifi_ssid()
gateway := app.get_default_gateway()
dns_servers := app.get_dns_servers()
open_ports := app.get_listening_ports()
```

---

## 10. Desktop Notifications, Audio, Dock & Speech

```v
// Native Desktop Notification Banner
app.notify('Backup Finished', 'All database tables archived.')

// macOS Dock Integration
app.bounce_dock()
app.set_dock_badge('3')

// Terminal Bell & Sounds
app.beep()
app.beep_n(3)
app.play_system_sound('Ping')

// Text-to-Speech (TTS)
app.say('Deployment complete')
app.speak_with_voice('System online', 'Samantha')

// System Volume & Muting
vol := app.get_volume()
app.set_volume(75)

// System Clipboard
app.copy_to_clipboard('Copied API Key')
clip := app.get_clipboard_text()
app.clear_clipboard()

// Headless Native OS Confirmation Dialog
confirmed := app.ask('Confirm Migration', 'Are you sure you want to drop the staging database?')
```

---

## 11. Generic Collections & Priority Queues

```v
// SimpleStack[T] (LIFO)
mut stack := simplecli.new_stack[int]()
stack.push(10)
top := stack.pop() // 10

// SimpleQueue[T] (FIFO)
mut queue := simplecli.new_queue[string]()
queue.push('task1')
first := queue.pop() // 'task1'

// SimpleRingBuffer[T] (Circular Buffer)
mut ring := simplecli.new_ring_buffer[string](100)
ring.push('log entry')

// SimpleMinHeap (Priority Queue)
mut heap := simplecli.new_min_heap()
heap.push(45.0)
heap.push(12.0)
min := heap.pop() // 12.0
```

---

## 12. Validation Engine & URL Parsing

```v
// Data Validators
is_email := app.validate_email('test@domain.com')
is_url := app.validate_url('https://google.com')
is_ip := app.validate_ip('192.168.1.1')
is_phone := app.validate_phone('+1-555-123-4567')
is_alnum := app.validate_alphanumeric('User123')
is_in_range := app.validate_numeric_range(42.0, 1.0, 100.0)

// Structured URL Parsing
u := app.parse_url('https://api.site.com:8443/v1/users?role=admin#section')!
println('Host: ${u.host}, Port: ${u.port}, Path: ${u.path}, Query: ${u.query}')
```

---

## 13. Standard Library, Crypto, JSON & HTTP Toolkit

```v
// HTTP Client
html := app.http_get('https://example.com')
post_res := app.http_post('https://httpbin.org/post', '{"key":"val"}')
res := app.http_request('POST', 'https://api.site.com/v1/auth', '{"token":"123"}')!

// Dynamic JSON Field Extraction
raw_json := '{"service": "auth_api", "port": 5000, "enabled": true}'
svc_name := app.json_get_string(raw_json, 'service', 'unknown') // 'auth_api'
port_num := app.json_get_int(raw_json, 'port', 80)               // 5000
is_enabled := app.json_get_bool(raw_json, 'enabled', false)      // true

// Cryptography & Hashing
sha256_hash := app.crypto_sha256('mypassword')
sha512_hash := app.crypto_sha512('mypassword')
md5_hash := app.crypto_md5('mypassword')
hmac_sig := app.crypto_hmac_sha256('secret_key', 'payload')

// BCrypt Password Hashing
bcrypt_hash := app.crypto_bcrypt_hash('password123')!
is_valid := app.crypto_bcrypt_verify('password123', bcrypt_hash)

// AES-256-CTR Encryption & Decryption
ciphertext := app.crypto_aes_encrypt('my_secret_key_32bytes', 'Sensitive Data')!
plaintext := app.crypto_aes_decrypt('my_secret_key_32bytes', ciphertext)!

// Encodings
b64 := app.base64_encode('Payload')
raw := app.base64_decode(b64)
hex_str := app.hex_encode('Binary')
raw_hex := app.hex_decode(hex_str)

// Math & Statistics
mean_val := app.stats_mean([10.0, 20.0, 30.0])
g_mean := app.stats_geometric_mean([10.0, 20.0, 30.0])
h_mean := app.stats_harmonic_mean([10.0, 20.0, 30.0])
rms_val := app.stats_rms([10.0, 20.0, 30.0])

// Placeholder Text Generation
lorem_text := app.lorem_words(10)
```

---

## 14. Reactive State Store & File Persistence

```v
mut app := simplecli.new('StateApp')

// In-Memory Key-Value State
app.set_state('user', 'Alice')
app.set_state('retry_count', '3')
app.set_state('is_admin', 'true')

u := app.get_state('user', 'guest')
rc := app.get_state_int('retry_count', 0)
admin := app.get_state_bool('is_admin', false)

// JSON File Persistence
app.save_state('~/my_app/state.json')!
app.load_state('~/my_app/state.json')!
```

---

## 15. Standalone 1-Liner Package Functions

```v
import simplecli

fn main() {
	// Standalone process execution
	out, code := simplecli.exec('git status')

	// Standalone notification
	simplecli.notify('Backup Alert', 'Finished.')

	// Standalone hardware inspection
	cpu := simplecli.cpu_info()
	ram := simplecli.memory_info()

	// Standalone crypto & UUID
	hash := simplecli.crypto_sha256('hello')
	uuid := simplecli.rand_uuid()

	// Standalone speech & bell
	simplecli.say('Hello World')
	simplecli.sys_beep()
}
```

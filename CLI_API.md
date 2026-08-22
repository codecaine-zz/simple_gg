# SimpleCLI: Headless Console & RAD Toolkit for V

`simplecli` is a comprehensive, lightweight, zero-window console utility framework and Rapid Application Development (RAD) toolkit for the V programming language. It brings all the cross-platform OS system calls, hardware resource monitoring, desktop notifications, speech synthesis, standard path resolvers, cryptography, HTTP, generic data structures, string similarity metrics, multi-level logging, CLI flag parsing, and stdlib wrappers directly to command-line utilities and automation scripts without requiring any graphical window backend (no `gg`/`sokol` GUI dependencies).

---

## Table of Contents

1. [Architecture & Application Lifecycle](#1-architecture--application-lifecycle)
2. [CLI Flags & Argument Parsing](#2-cli-flags--argument-parsing)
3. [Console UI & RAD Components](#3-console-ui--rad-components)
4. [Interactive Prompts, Menus & Input Validation](#4-interactive-prompts-menus--input-validation)
5. [Multi-Step Task Pipeline Runner](#5-multi-step-task-pipeline-runner)
6. [Structured Multi-Level Logging & File Logging](#6-structured-multi-level-logging--file-logging)
7. [Benchmark & Execution Timing](#7-benchmark--execution-timing)
8. [Reactive State Store & File Persistence](#8-reactive-state-store--file-persistence)
9. [Safe Process Execution & Subprocess Control](#9-safe-process-execution--subprocess-control)
10. [Hardware Telemetry & Resource Probing](#10-hardware-telemetry--resource-probing)
11. [Standard OS Directory Resolution & File System](#11-standard-os-directory-resolution--file-system)
12. [Network, Wi-Fi & TCP Port Diagnostics](#12-network-wi-fi--tcp-port-diagnostics)
13. [Desktop Notifications, Speech & Audio Utilities](#13-desktop-notifications-speech--audio-utilities)
14. [System Clipboard & Headless OS Native Dialogs](#14-system-clipboard--headless-os-native-dialogs)
15. [HTTP Client & REST APIs](#15-http-client--rest-apis)
16. [Cryptography, Hashing & Random Utilities](#16-cryptography-hashing--random-utilities)
17. [Encodings, Data Formats & Serialization](#17-encodings-data-formats--serialization)
18. [Validation Engine](#18-validation-engine)
19. [Generic Collections, Queues & String Metrics](#19-generic-collections-queues--string-metrics)
20. [Statistical Math Calculations](#20-statistical-math-calculations)
21. [Standalone Package Functions (1-Liners)](#21-standalone-package-functions-1-liners)

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

	// Automatic constructor taking name from current executable
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

### Unicode Sparklines

Render inline high-density trend visualizations using Unicode block elements (` ▂▃▄▅▆▇█`):

```v
latencies := [12.0, 15.0, 45.0, 90.0, 120.0, 80.0, 30.0, 14.0]
spark := app.sparkline(latencies)
app.info('Latency Trend (last 8 ticks): ${spark}')
// Output: Latency Trend (last 8 ticks):  ▂▄▆█▆▂ 
```

### Horizontal Bar Charts

Visualize distributions, resource utilization, or benchmark comparative results:

```v
app.bar_chart('Resource Allocation (%)', {
	'CPU Core 0': 42.5
	'CPU Core 1': 89.0
	'Memory':     64.2
	'Disk /':     23.8
}, 30) // 30-character max bar width
```

### Meter Gauges

Display single-metric gauges with automatic green/yellow/red threshold badges:

```v
app.gauge('PostgreSQL Connection Pool', 48.0, 50.0, 'conns')
// Output: PostgreSQL Connection Pool: [████████████████████░░] 48.0/50.0 conns (96.0%) [CRITICAL]

app.gauge('Storage Capacity', 34.2, 100.0, 'GB')
// Output: Storage Capacity: [██████░░░░░░░░░░░░░░] 34.2/100.0 GB (34.2%) [OK]
```

### Hierarchical Tree Visualizer

Render nested dependency graphs, filesystem trees, or structured schemas with Unicode branch glyphs (`├──`, `└──`, `│   `):

```v
mut root := simplecli.new_tree_node('production-cluster')
mut db := root.add_child('postgres-db')
db.add_child('replica-01 (read-only)')
db.add_child('replica-02 (standby)')
root.add_child('redis-cache')
mut api := root.add_child('api-gateway')
api.add_child('auth-service')
api.add_child('payment-service')

app.tree(root)
```

### Colorized Line Diff Viewer

Generate and display unified line-by-line diffs with line numbering and colored change annotations:

```v
old_config := 'port: 8080\nworkers: 4\nenv: staging'
new_config := 'port: 8080\nworkers: 8\nenv: production\ntls: true'

// Output colorized line diff to console:
app.diff(old_config, new_config)

// Or retrieve formatted diff string:
diff_text := app.diff_text(old_config, new_config)
```

### Status Badges & Alert Callout Boxes

```v
// Inverted/bracketed status badges
prod_badge := app.badge('ENV', 'PRODUCTION', .warn)
app.println('${prod_badge} Initializing migration sequence...')

// Styled GitHub-like alert boxes (.info, .success, .warning, .caution, .tip, .note)
app.alert(.info, 'Configuration Loaded', 'Loaded 42 rules from settings.json.')
app.alert(.warning, 'High Memory Threshold', 'Memory utilization exceeded 85%.')
app.alert(.caution, 'Destructive Action', 'Dropping database table `audit_logs`.')
app.alert(.tip, 'Pro Tip', 'Pass `--silent` to disable interactive output.')
```

### Task Checklist Items

Format structured task execution checklists:

```v
app.task_item('Compile C sources', .done, 140)     // ✓ Compile C sources (140 ms)
app.task_item('Run static analysis', .running, 0)   // ⏳ Run static analysis...
app.task_item('Deploy image to registry', .pending, 0) // ○ Deploy image to registry
app.task_item('Run smoke tests', .failed, 55)       // ✖ Run smoke tests [FAILED] (55 ms)
app.task_item('Upload optional symbols', .skipped, 0) // ↷ Upload optional symbols [SKIPPED]
```

### Table Data Format Exporters & Markdown Rendering

Convert table data structures to standard formats or render Markdown inside the terminal:

```v
headers := ['ID', 'Name', 'Role']
rows := [
	['1', 'Alice, VP', 'Admin'],
	['2', 'Bob', 'Developer'],
]

// Convert to CSV string:
csv_data := app.table_to_csv(headers, rows)

// Convert to Markdown table:
md_table := app.table_to_markdown(headers, rows)

// Convert to JSON array of objects:
json_data := app.table_to_json(headers, rows)

// Syntax-highlight JSON with ANSI colors in terminal:
app.println(app.json_highlight('{"status": "healthy", "uptime_sec": 86400, "debug": false}'))

// Render Markdown document to terminal with styled headings and lists:
app.render_markdown('# Release Notes\n## Improvements\n* Faster CLI startup\n* Zero-window RAD components\n> Ready for production.')
```

---

## 4. Interactive Prompts, Menus & Input Validation

### Text, Secret & Typed Prompts

```v
// Plain string prompt
username := app.prompt('Enter admin username: ', 'admin')

// Hidden / masked password prompt
api_token := app.prompt_password('Enter secret API access token: ')

// Validated email prompt (re-prompts until a valid email syntax is entered)
email := app.prompt_email('Enter alert recipient email: ', 'dev@domain.com')

// Validated URL prompt (re-prompts until a valid http/https URL is entered)
webhook := app.prompt_url('Enter Slack Webhook URL: ', 'https://hooks.slack.com/...')

// Constrained numeric prompt between min and max bounds
threads := app.prompt_number('Worker thread concurrency', 8, 1, 64)

// Yes/No confirmation prompt (returns bool)
proceed := app.confirm('Do you want to apply migrations to production?', false)
```

### Single, Multi-Select & Fuzzy Search Menus

```v
// Single selection menu with index and value return
choice := app.select('Choose build target environment:', [
	'Local Development',
	'Staging Integration',
	'Production Release',
])

// Multi-select menu with comma-separated numbers (e.g. "1, 3")
selected := app.multi_select('Select deployment components to verify:', [
	'PostgreSQL Database',
	'Redis Cache',
	'Kafka Event Streams',
	'Elasticsearch Index',
])

// Interactive Fuzzy Selector with query typing and similarity ranking
branch := app.fuzzy_select('Search and checkout Git branch:', [
	'main',
	'feature/rad-components',
	'feature/graphql-api',
	'bugfix/state-persistence',
])
```

### Interactive Form / Wizard Builder

Collect multi-field configuration forms inside a stylish framed console wizard:

```v
form_data := app.form('Deploy Microservice Wizard', [
	simplecli.FormField{
		key: 'name'
		label: 'Service Name'
		kind: .text
		required: true
	},
	simplecli.FormField{
		key: 'port'
		label: 'Listen Port'
		kind: .number
		default_val: '8080'
	},
	simplecli.FormField{
		key: 'secret'
		label: 'Master API Key'
		kind: .password
		required: true
	},
])

service_name := form_data['name']
listen_port  := form_data['port']
```

### Path & Directory Validation Prompt

Prompt for user file paths with automatic `~` expansion and existence mode checks (`.any`, `.must_exist`, `.file`, `.directory`):

```v
cert_path := app.prompt_path('Enter path to TLS certificate:', '~/.config/certs/app.pem', .file)
target_dir := app.prompt_path('Enter deployment directory:', '/var/www/app', .directory)
```

---

## 5. Multi-Step Task Pipeline Runner

Execute multi-stage automation workflows with live step spinners, precise step timers, and summary reporting:

```v
mut pipeline := app.new_pipeline('Production Release Pipeline')

pipeline.add_step('Clean temporary build artifacts', fn () bool {
	return os.rmdir_all('/tmp/build') or { true }
})

pipeline.add_step('Compile native binaries', fn () bool {
	// Execute build step
	time.sleep(200 * time.millisecond)
	return true
})

pipeline.add_step('Run security vulnerability scan', fn () bool {
	// Execute vulnerability scan
	time.sleep(150 * time.millisecond)
	return true
})

pipeline.add_step('Deploy container image to registry', fn () bool {
	// Push artifacts
	time.sleep(300 * time.millisecond)
	return true
})

// Run pipeline: displays live checkmarks, spinners, and duration summary
success := pipeline.run()
```

---

## 6. Structured Multi-Level Logging & File Logging

`simplecli` provides structured logging with timestamps, level tags, ANSI colors, and automatic file log streaming:

```v
mut app := simplecli.new('Runner')

// Configure log file path for persistent audit logs
app.set_log_file('/var/log/mytool.log')

// Set minimum display log level (.trace, .debug, .info, .warn, .error_level, .silent)
app.set_log_level(.debug)

// Multi-level log calls
app.trace('Detailed execution trace dump')
app.debug('Loaded configuration from config.json with 14 keys')
app.info('Worker thread pool initialized with 8 threads')
app.success('Successfully provisioned staging environment')
app.warn('High memory usage detected (> 85%)')
app.error('Failed to connect to secondary database node')

// Fatal log call outputs error, writes to log file, and exits process with code 1
// app.fatal('Unrecoverable database corruption')
```

---

## 7. Benchmark & Execution Timing

Track execution duration with microsecond/millisecond precision:

```v
// Reset the high-resolution execution timer
app.reset_timer()

// Perform heavy computation or batch I/O
time.sleep(340 * time.millisecond)

// Read elapsed time
elapsed_ms := app.elapsed_ms()      // i64 (e.g. 340)
elapsed_s  := app.elapsed_seconds() // f64 (e.g. 0.340)

app.info('Task completed in ${elapsed_ms} ms (${elapsed_s:.3f} s)')
```

---

## 8. Reactive State Store & File Persistence

Store key-value runtime configuration and persist it to JSON state files:

```v
// Set and get memory-backed state
app.set_state('last_sync', '2026-08-22T12:00:00Z')
app.set_state('active_profile', 'staging-us-east')
profile := app.get_state('active_profile')

// Save full key-value state to persistent JSON file on disk
state_path := app.get_app_state_file('deploybot', 'state.json')
app.save_state(state_path)!

// Restore state from JSON file on subsequent runs
app.load_state(state_path)!
```

---

## 9. Safe Process Execution & Subprocess Control

Execute system commands safely with strict argument quoting, timeouts, retries, and parallel background threads:

### Execution Functions

```v
// Basic execution returning (output, exit_code)
output, code := app.exec('uptime')

// Safe argument execution (quotes every argument with POSIX single-quotes)
branch, _ := app.exec_safe('git', ['rev-parse', '--abbrev-ref', 'HEAD'])

// Fallback execution (returns fallback string if command fails or returns non-zero)
git_tag := app.exec_or('git describe --tags', 'v0.0.0-dev')

// Execute inside a specific working directory
status, _ := app.exec_in_dir('git status --short', '/Users/developer/project')

// Execute in background (non-blocking)
app.exec_bg('open https://github.com')

// Execute with a hard timeout in milliseconds
res_timeout := app.exec_timeout('ping -c 10 1.1.1.1', 2000)
if res_timeout.timed_out {
	app.warn('Ping command timed out after 2000 ms')
}

// Execute with automatic retry logic on failure
res_retry := app.exec_retry('curl -sf https://api.service.internal/health', 3, 500)
app.info('Attempts: ${res_retry.attempts}, Exit Code: ${res_retry.exit_code}')

// Parallel concurrent command execution across background threads
results := app.parallel_exec([
	'git fetch origin',
	'npm check',
	'brew update',
])
for r in results {
	app.info('Exit: ${r.exit_code} | Duration: ${r.duration_ms} ms')
}
```

### Process Management & Utilities

```v
// Current process PID
pid := app.get_pid()

// Check if a process is alive by PID
is_alive := app.is_process_running(1234)

// Terminate process by PID (SIGTERM / taskkill)
app.kill_process(1234)

// Check if an executable binary exists in system PATH
has_docker := app.has_command('docker')
docker_path := app.get_command_path('docker')

// Get open file descriptors count for current process
open_fds := app.get_open_file_descriptors()

// String and path quoting helpers
safe_arg := simplecli.quote_arg('unsafe input; rm -rf /')
safe_path := simplecli.quote_path('~/My Documents/Report.pdf')
clean_name := simplecli.sanitize_filename('../../../etc/passwd') // returns '______etc_passwd'
```

---

## 10. Hardware Telemetry & Resource Probing

Monitor CPU, Memory, Swap, Load Averages, Battery, and Disk utilization:

```v
// CPU information
cpu_count := app.get_cpu_count()
cpu_usage := app.get_cpu_usage() // Percentage 0.0 - 100.0
app.info('CPU Cores: ${cpu_count} | CPU Usage: ${cpu_usage:.1f}%')

// System Load Averages (1 min, 5 min, 15 min)
load1, load5, load15 := app.get_load_averages()
app.info('Load: ${load1:.2f}, ${load5:.2f}, ${load15:.2f}')

// Physical RAM Memory stats
total_ram, used_ram, ram_percent := app.get_memory_stats()
app.info('RAM: ${(used_ram / 1024 / 1024)} MB / ${(total_ram / 1024 / 1024)} MB (${ram_percent:.1f}%)')

// Swap memory stats
total_swap, used_swap, swap_percent := app.get_swap_stats()

// Battery & Power metrics
if battery := app.get_battery_level() {
	is_charging := app.is_battery_charging() or { false }
	app.info('Battery: ${battery}% (Charging: ${is_charging})')
}

// Disk space statistics for a given path
total_disk, used_disk, disk_percent := app.get_disk_stats('/')
app.info('Disk /: ${(used_disk / 1024 / 1024 / 1024)} GB / ${(total_disk / 1024 / 1024 / 1024)} GB (${disk_percent:.1f}%)')

// System Locale, OS Theme & Accent Color
locale := app.get_system_locale()       // e.g. "en_US.UTF-8"
theme := app.get_os_theme()             // "dark" or "light"
accent := app.get_system_accent_color() // e.g. "blue"
```

---

## 11. Standard OS Directory Resolution & File System

### Standard OS Directories

Resolves standard paths across macOS, Linux, and Windows following XDG and Apple guidelines:

```v
home_dir := app.get_user_home_dir()

// Standard application configuration directories & files
app_cfg_dir  := app.get_app_config_dir('DeployBot')
app_cfg_file := app.get_app_config_file('DeployBot', 'config.json')

// Persistent application data directories
app_data_dir := app.get_app_data_dir('DeployBot')

// State directories & files
app_state_dir  := app.get_app_state_dir('DeployBot')
app_state_file := app.get_app_state_file('DeployBot', 'state.json')

// Cache directories & files
app_cache_dir  := app.get_app_cache_dir('DeployBot')
app_cache_file := app.get_app_cache_file('DeployBot', 'index.cache')

// Log directories & files
app_log_dir  := app.get_app_log_dir('DeployBot')
app_log_file := app.get_app_log_file('DeployBot', 'runner.log')

// Temporary runtime directory (for PID / sockets)
app_run_dir := app.get_app_runtime_dir('DeployBot')

// User standard folders
downloads_dir := app.get_system_path('downloads')
desktop_dir   := app.get_system_path('desktop')
documents_dir := app.get_system_path('documents')
pictures_dir  := app.get_system_path('pictures')
music_dir     := app.get_system_path('music')
videos_dir    := app.get_system_path('videos')

// Resolve and expand '~' in user paths
abs_path := app.resolve_user_path('~/.config/myapp/settings.toml')
```

### File System Utilities & Overwrite Options

`simplecli` provides built-in path resolution (expanding `~/`), automatic parent directory creation, and flexible file operations.

#### Overwrite & Persistence Behavior Matrix

| Method | Default Behavior | Parent Dirs Created? | Safe Non-Overwrite Alternative |
| :--- | :--- | :--- | :--- |
| `app.write_file(path, content)` | **Always Overwrites** (truncates target) | ✅ Yes | Guard with `if !app.file_exists(path)` |
| `app.append_file(path, content)` | **Appends** (preserves existing content) | ✅ Yes | N/A (non-destructive) |
| `app.copy_file(src, dst)!` | **Overwrites** destination if present | ✅ Yes | Guard with `if !app.file_exists(dst)` |
| `app.move_file(src, dst)!` | **Overwrites** / replaces destination | ❌ No | Guard with `if !app.file_exists(dst)` |
| `app.http_download(url, dst)!` | **Always Overwrites** destination | ✅ Yes | Guard with `if !app.file_exists(dst)` |
| `app.save_state(path)!` | **Always Overwrites** JSON state file | ✅ Yes | Check file existence or create backup |

---

#### 1. Default Overwrite vs. Safe Non-Overwrite Pattern

```v
file_path := app.resolve_user_path('~/project/config.env')
content := 'API_KEY=secret_12345\nDEBUG=true\n'

// --- OPTION A: Direct Overwrite (Replaces entire content) ---
// Note: Automatically creates parent directories if they do not exist
app.write_file(file_path, content)
app.success('Wrote (overwrote) file: ${file_path}')

// --- OPTION B: Safe Non-Overwrite (Only write if file does NOT exist) ---
if !app.file_exists(file_path) {
	app.write_file(file_path, content)
	app.success('Created new file: ${file_path}')
} else {
	app.warn('File already exists: ${file_path}. Skipping write to prevent overwrite.')
}

// --- OPTION C: CLI Flag-Controlled Overwrite (--overwrite / -f) ---
overwrite_allowed := app.get_flag_bool('overwrite') // Or: app.get_flag_bool('force')

if !app.file_exists(file_path) || overwrite_allowed {
	app.write_file(file_path, content)
	app.info('File saved successfully (force/overwrite: ${overwrite_allowed})')
} else {
	app.error('File "${file_path}" exists. Pass --overwrite / -f to replace it.')
}

// --- OPTION D: Interactive Prompt Confirmation Before Overwrite ---
if app.file_exists(file_path) {
	if app.prompt_confirm('File "${file_path}" already exists. Overwrite?', false) {
		app.write_file(file_path, content)
		app.success('File overwritten by user confirmation.')
	} else {
		app.info('Operation aborted by user.')
	}
} else {
	app.write_file(file_path, content)
}

// --- OPTION E: Atomic Backup Before Overwrite ---
if app.file_exists(file_path) {
	bak_path := '${file_path}.bak'
	app.copy_file(file_path, bak_path)!
	app.info('Backed up existing file to ${bak_path}')
}
app.write_file(file_path, content)
```

---

#### 2. Appending to Files Without Overwriting

```v
log_file := '/tmp/audit.log'

// app.append_file appends text without modifying existing contents:
app.append_file(log_file, '[2026-08-22 09:00:00] Worker started')
app.append_file(log_file, '[2026-08-22 09:01:00] Job completed successfully')

// Read back the complete file content:
full_log := app.read_file(log_file)
app.info('Log file size: ${full_log.len} bytes')
```

---

#### 3. Copy, Move, Directory & Metadata Operations

```v
src := '/tmp/source_data.csv'
dst := '/tmp/backups/target_data.csv'

// Copy with overwrite protection
if app.file_exists(dst) && !app.get_flag_bool('force') {
	app.warn('Destination already exists. Use --force to overwrite.')
} else {
	app.copy_file(src, dst)! // Automatically creates /tmp/backups/ if needed
	app.success('Copied ${src} -> ${dst}')
}

// Moving / Renaming files
app.move_file('/tmp/old_name.txt', '/tmp/new_name.txt')!

// Deleting files
app.delete_file('/tmp/temporary_cache.tmp')

// Directory management
app.create_directory('/tmp/my_app/workspace/logs')
entries := app.read_dir('/tmp/my_app')

// Recursive file listing by file extension (e.g. all '.v' or '.json' files, or '' for all)
v_files := app.list_files_recursive('/path/to/project', '.v')
all_files := app.list_files_recursive('/path/to/project', '')

// Detailed File & Directory Metadata
if meta := app.get_file_metadata('/tmp/source_data.csv') {
	app.info('Path: ${meta.path}')
	app.info('Size: ${meta.size_bytes} bytes')
	app.info('Is Directory: ${meta.is_dir}')
	app.info('Is Readable: ${meta.is_readable}, Is Writable: ${meta.is_writable}')
}
```

---

## 12. Network, Wi-Fi & TCP Port Diagnostics

Inspect local network interfaces, public IPs, Wi-Fi connectivity, DNS servers, and open listening ports:

```v
// Check Internet connectivity (checks default gateway / DNS reachability)
online := app.is_online()

// Fast TCP socket ping (returns true if port is listening and reachable)
is_pg_up := app.ping_tcp_port('127.0.0.1', 5432, 500)
is_redis_up := app.ping_tcp_port('127.0.0.1', 6379, 500)

// IP addresses
local_ip  := app.get_local_ip()  // e.g. "192.168.1.42"
public_ip := app.get_public_ip() // e.g. "203.0.113.195" via https://api.ipify.org

// Hardware MAC Address & Wi-Fi SSID
mac_addr := app.get_mac_address()
wifi_name := app.get_wifi_ssid()

// Default Gateway & Configured DNS Servers
gateway := app.get_default_gateway()
dns_servers := app.get_dns_servers() // e.g. ["1.1.1.1", "8.8.8.8"]

// List active TCP listening ports on the local machine
listening_ports := app.get_listening_ports() // e.g. [22, 80, 443, 5432, 8080]
```

---

## 13. Desktop Notifications, Speech & Audio Utilities

```v
// Desktop notification
app.notify('Deployment Complete', 'Artifacts uploaded to S3 bucket.')

// Desktop notification with custom sound
app.notify_with_sound('Alert Triggered', 'CPU load exceeded 90%', 'Glass')

// Text-to-Speech (TTS) voice synthesis
app.say('Deployment succeeded.')
app.speak_with_voice('Build failed on step 4.', 'Samantha')

// Terminal bell audio beep
app.beep()

// System audio volume control (0-100)
app.set_volume(75)
vol := app.get_volume()

// Mute and unmute system audio
app.mute_audio()
app.unmute_audio()
```

---

## 14. System Clipboard & Headless OS Native Dialogs

Interact with system clipboard and trigger native OS dialogs without GUI libraries:

```v
// Copy and read system clipboard
app.copy_to_clipboard('https://example.com/builds/123')
clip_text := app.get_clipboard_text()
app.clear_clipboard()

// Native OS dialogs (AppleScript on macOS, Zenity/Kdialog on Linux)
user_input := app.ask('Please enter database migration passphrase:')
confirmed := app.osascript_dialog('Proceed with destructive database reset?', 'Warning')

// Native OS file and folder picker
selected_files := app.osascript_file_picker('Choose archive to restore', true)
selected_folder := app.osascript_folder_picker('Choose backup target folder')
```

---

## 15. HTTP Client & REST APIs

Synchronous and flexible HTTP operations with URL parsing and file streaming:

```v
// URL parsing
parsed_url := app.parse_url('https://api.github.com:443/repos/vlang/v?tab=tags#top')!
app.info('Host: ${parsed_url.host}, Port: ${parsed_url.port}, Path: ${parsed_url.path}')

// Quick HTTP GET and POST
body_get := app.http_get('https://httpbin.org/get')
body_post := app.http_post('https://httpbin.org/post', '{"action": "ping"}')

// Full HTTP request with custom method and response metadata
resp := app.http_request('GET', 'https://api.github.com/zen', '')!
app.info('Status: ${resp.status_code}, Body: ${resp.body}')

// Direct remote file download to disk
app.http_download('https://example.com/assets.zip', '/tmp/assets.zip')!
```

---

## 16. Cryptography, Hashing & Random Utilities

### Hashing & Authentication

```v
// Standard cryptographic hashes
sha256_hash := app.crypto_sha256('secret message')
sha512_hash := app.crypto_sha512('secret message')
sha1_hash   := app.crypto_sha1('secret message')
md5_hash    := app.crypto_md5('secret message')

// HMAC-SHA256
hmac_sig := app.crypto_hmac_sha256('api_secret_key', 'payload_data')

// Bcrypt password hashing and verification
pw_hash := app.crypto_bcrypt_hash('my_super_password')!
is_valid := app.crypto_bcrypt_verify('my_super_password', pw_hash)
```

### AES-256-CTR Symmetric Encryption

```v
key := '01234567890123456789012345678901' // 32-character key for AES-256
plaintext := 'Confidential database connection string'

// Encrypt string to Base64 (includes 16-byte random IV)
encrypted_b64 := app.crypto_aes_encrypt(key, plaintext)!

// Decrypt Base64 back to plaintext
decrypted := app.crypto_aes_decrypt(key, encrypted_b64)!
assert decrypted == plaintext
```

### Random Generation

```v
uuid_str := app.rand_uuid()               // e.g. "c4a8d09b-2a91-4c39-8b65-68041a87b1c2"
rand_tok := app.rand_string(32)           // 32-character alphanumeric token
rand_num := app.rand_int(1000, 9999)      // Random integer in range
rand_flt := app.rand_f64()                // Random float 0.0 - 1.0
```

---

## 17. Encodings, Data Formats & Serialization

### Encodings

```v
// Base64 encode / decode
b64_str := app.base64_encode('Hello World')
decoded := app.base64_decode(b64_str)

// Hex encode / decode
hex_str := app.hex_encode('Hello World')
hex_raw := app.hex_decode(hex_str)
```

### JSON, CSV & TOML Helpers

```v
// Format JSON with 2-space indentation
pretty_json := app.json_pretty('{"name":"Sentinel","port":8080,"enabled":true}')

// Safe extraction from JSON strings without full struct mapping
name := app.json_get_string(pretty_json, 'name', 'default_name')
port := app.json_get_int(pretty_json, 'port', 80)
enabled := app.json_get_bool(pretty_json, 'enabled', false)

// Parse CSV content into 2D string grid
csv_rows := app.csv_parse('ID,Name,Role\n1,Alice,Admin\n2,Bob,Developer')

// Parse TOML document
toml_doc := app.toml_parse('title = "Build Config"\nversion = 2')!

// GZIP string compression and decompression
compressed_bytes := app.gzip_compress('Large payload string to compress')!
uncompressed_str := app.gzip_decompress(compressed_bytes)!

// Regex matching
is_match := app.regex_match(r'^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$', 'user@domain.com')

// Semantic Version Comparison (-1, 0, 1)
cmp := app.semver_compare('1.2.4', '1.3.0')! // returns -1

// Placeholder text generator
sample_text := app.lorem_words(10)
```

---

## 18. Validation Engine

Validate inputs and values with built-in boolean validators:

```v
// Email validation
is_email := app.validate_email('developer@company.org') // true

// URL validation
is_url := app.validate_url('https://vlang.io')          // true

// IPv4 validation
is_ip := app.validate_ip('192.168.1.1')                 // true

// Phone number validation
is_phone := app.validate_phone('+1 (555) 234-5678')    // true

// Alphanumeric validation
is_alpha := app.validate_alphanumeric('AdminUser123')   // true

// Numeric range check [min, max]
in_range := app.validate_numeric_range(85.5, 0.0, 100.0) // true

// String length check [min_len, max_len]
len_valid := app.validate_length('secretpass', 8, 32)   // true
```

---

## 19. Generic Collections, Queues & String Metrics

### Generic Stack (`SimpleStack[T]`)

```v
import simplecli

mut stack := simplecli.new_stack[string]()
stack.push('first')
stack.push('second')
stack.push('third')

top := stack.peek()  // ?string ('third')
val := stack.pop()   // ?string ('third')
len := stack.len()   // 2
empty := stack.is_empty() // false
```

### Generic Queue (`SimpleQueue[T]`)

```v
mut queue := simplecli.new_queue[int]()
queue.push(10)
queue.push(20)
queue.push(30)

next := queue.peek() // ?int (10)
out  := queue.pop()  // ?int (10)
len  := queue.len()  // 2
```

### Generic Fixed-Capacity Ring Buffer (`SimpleRingBuffer[T]`)

```v
// Circular buffer holding up to 5 items (overwrites oldest on overflow)
mut ring := simplecli.new_ring_buffer[string](5)
ring.push('log 1')
ring.push('log 2')
ring.push('log 3')

elem := ring.get(0) // ?string ('log 1')
item := ring.pop()   // ?string ('log 1')
full := ring.is_full()
```

### Min-Heap Priority Queue (`SimpleMinHeap`)

```v
mut heap := simplecli.new_min_heap()
heap.push(42.0)
heap.push(12.5)
heap.push(99.0)
heap.push(5.0)

min_val := heap.pop() // ?f64 (5.0 - always extracts minimum)
```

### String Similarity & Levenshtein Distance

```v
// Compute minimum edit distance
dist := app.levenshtein_distance('kitten', 'sitting') // 3

// Compute similarity ratio between 0.0 (unrelated) and 1.0 (identical)
ratio := app.similarity_ratio('deploy', 'deploying') // ~0.667
```

---

## 20. Statistical Math Calculations

Calculate descriptive statistics across numeric arrays:

```v
latencies := [12.4, 15.1, 9.8, 14.2, 110.5, 13.0, 16.2]

mean      := app.stats_mean(latencies)            // Arithmetic average
median    := app.stats_median(latencies)          // Median value
std_dev   := app.stats_std_dev(latencies)         // Standard deviation
geo_mean  := app.stats_geometric_mean(latencies)  // Geometric mean
harm_mean := app.stats_harmonic_mean(latencies)   // Harmonic mean
rms       := app.stats_rms(latencies)             // Root Mean Square
min_val   := app.stats_min(latencies)             // Minimum
max_val   := app.stats_max(latencies)             // Maximum
```

---

## 21. Standalone Package Functions (1-Liners)

Every method available on `&SimpleCli` is also exported as a standalone package-level function in `simplecli` for direct one-liner scripting without instantiating an app instance:

```v
import simplecli

fn main() {
	// Standalone process execution
	out, _ := simplecli.exec_safe('git', ['status', '--short'])
	
	// Standalone path resolvers
	cfg_dir := simplecli.get_app_config_dir('DeployBot')
	home := simplecli.get_user_home_dir()
	
	// Standalone network & hardware probes
	is_up := simplecli.is_online()
	port_open := simplecli.ping_tcp_port('127.0.0.1', 5432, 500)
	cpu_count := simplecli.get_cpu_count()
	
	// Standalone crypto & validation
	hash := simplecli.crypto_sha256('input')
	valid_email := simplecli.validate_email('test@domain.com')
	
	// Standalone notifications & speech
	simplecli.notify('Alert', 'System running')
	simplecli.say('Backup complete')
}
```

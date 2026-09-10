# V Developer Utility Suite (`vlang_utils`) - Complete API Reference

Welcome to the comprehensive API reference manual for the **30 production-grade developer utility modules** in `vlang_utils`.

Every module is zero-dependency, self-contained, and designed for Rapid Application Development (RAD). You can import any module directly across GUI apps, CLI tools, services, and background workers (e.g. `import strutils`, `import sqliteutils`, `import cacheutils`).

---

## Start Here: How To Read Any Example

Each example is a small recipe. Copy the section's **Import statement** and the example into a file ending in `.v`, then run it from this project with `v run your_file.v`. Text inside single quotes, such as `'Alice'` or `'data/report.json'`, is sample input: replace it with your own name, text, file path, or value.

The examples use a few V conventions that are worth knowing before you start:

- `import fileutils` makes the named toolkit available. Keep it at the top of your file.
- `name := value` creates a value and gives it a name. Later lines can use that name. `mut name := value` means the value will be changed later.
- A value in quotes is text. Values such as `42`, `true`, and `1.5` are a whole number, yes/no choice, and decimal number.
- `[]` means a list, for example `['red', 'blue']`. `{}` means named values, for example `{ 'name': 'Alice' }`.
- A trailing `!`, as in `fileutils.read_text_file('notes.txt')!`, means the operation may fail. It stops with a clear error when a file is missing, input is invalid, or the operating system refuses the operation. Use `or { ... }` when you want to choose a fallback instead.
- `println(...)` displays a result in the terminal. `assert ...` checks that an example produced the expected answer; it prints nothing when the check passes.

Examples that contact a website, read a file, use the clipboard, or ask a question in the terminal need that service, file, or user input to be available. Their surrounding text names the required input and explains the expected result.

### 🚀 Ready-to-Run Demos

All 30 utility modules have standalone, fully functional demo scripts located in the [`demos/`](demos/) directory.

- **Run all 30 demos sequentially with execution timing:**
  ```bash
  v run demos/run_all_demos.v
  ```

| Module | Demo Script | Command |
| :--- | :--- | :--- |
| [`archiveutils`](#archiveutils-api) | [`demo_archiveutils.v`](demos/demo_archiveutils.v) | `v run demos/demo_archiveutils.v` |
| [`asyncutils`](#asyncutils-api) | [`demo_asyncutils.v`](demos/demo_asyncutils.v) | `v run demos/demo_asyncutils.v` |
| [`bitutils`](#bitutils-api) | [`demo_bitutils.v`](demos/demo_bitutils.v) | `v run demos/demo_bitutils.v` |
| [`cacheutils`](#cacheutils-api) | [`demo_cacheutils.v`](demos/demo_cacheutils.v) | `v run demos/demo_cacheutils.v` |
| [`cliutils`](#cliutils-api) | [`demo_cliutils.v`](demos/demo_cliutils.v) | `v run demos/demo_cliutils.v` |
| [`colorutils`](#colorutils-api) | [`demo_colorutils.v`](demos/demo_colorutils.v) | `v run demos/demo_colorutils.v` |
| [`compressutils`](#compressutils-api) | [`demo_compressutils.v`](demos/demo_compressutils.v) | `v run demos/demo_compressutils.v` |
| [`cryptoutils`](#cryptoutils-api) | [`demo_cryptoutils.v`](demos/demo_cryptoutils.v) | `v run demos/demo_cryptoutils.v` |
| [`envutils`](#envutils-api) | [`demo_envutils.v`](demos/demo_envutils.v) | `v run demos/demo_envutils.v` |
| [`fileutils`](#fileutils-api) | [`demo_fileutils.v`](demos/demo_fileutils.v) | `v run demos/demo_fileutils.v` |
| [`flowutils`](#flowutils-api) | [`demo_flowutils.v`](demos/demo_flowutils.v) | `v run demos/demo_flowutils.v` |
| [`htmlutils`](#htmlutils-api) | [`demo_htmlutils.v`](demos/demo_htmlutils.v) | `v run demos/demo_htmlutils.v` |
| [`httputils`](#httputils-api) | [`demo_httputils.v`](demos/demo_httputils.v) | `v run demos/demo_httputils.v` |
| [`logutils`](#logutils-api) | [`demo_logutils.v`](demos/demo_logutils.v) | `v run demos/demo_logutils.v` |
| [`mockutils`](#mockutils-api) | [`demo_mockutils.v`](demos/demo_mockutils.v) | `v run demos/demo_mockutils.v` |
| [`netutils`](#netutils-api) | [`demo_netutils.v`](demos/demo_netutils.v) | `v run demos/demo_netutils.v` |
| [`regexutils`](#regexutils-api) | [`demo_regexutils.v`](demos/demo_regexutils.v) | `v run demos/demo_regexutils.v` |
| [`semverutils`](#semverutils-api) | [`demo_semverutils.v`](demos/demo_semverutils.v) | `v run demos/demo_semverutils.v` |
| [`sliceutils`](#sliceutils-api) | [`demo_sliceutils.v`](demos/demo_sliceutils.v) | `v run demos/demo_sliceutils.v` |
| [`sqliteutils`](#sqliteutils-api) | [`demo_sqliteutils.v`](demos/demo_sqliteutils.v) | `v run demos/demo_sqliteutils.v` |
| [`stateutils`](#stateutils-api) | [`demo_stateutils.v`](demos/demo_stateutils.v) | `v run demos/demo_stateutils.v` |
| [`statutils`](#statutils-api) | [`demo_statutils.v`](demos/demo_statutils.v) | `v run demos/demo_statutils.v` |
| [`structutils`](#structutils-api) | [`demo_structutils.v`](demos/demo_structutils.v) | `v run demos/demo_structutils.v` |
| [`strutils`](#strutils-api) | [`demo_strutils.v`](demos/demo_strutils.v) | `v run demos/demo_strutils.v` |
| [`sysutils`](#sysutils-api) | [`demo_sysutils.v`](demos/demo_sysutils.v) | `v run demos/demo_sysutils.v` |
| [`tarutils`](#tarutils-api) | [`demo_tarutils.v`](demos/demo_tarutils.v) | `v run demos/demo_tarutils.v` |
| [`templateutils`](#templateutils-api) | [`demo_templateutils.v`](demos/demo_templateutils.v) | `v run demos/demo_templateutils.v` |
| [`timeutils`](#timeutils-api) | [`demo_timeutils.v`](demos/demo_timeutils.v) | `v run demos/demo_timeutils.v` |
| [`tomlutils`](#tomlutils-api) | [`demo_tomlutils.v`](demos/demo_tomlutils.v) | `v run demos/demo_tomlutils.v` |
| [`validutils`](#validutils-api) | [`demo_validutils.v`](demos/demo_validutils.v) | `v run demos/demo_validutils.v` |

---

<a id="table-of-contents"></a>

## 📑 Table of Contents

### ⚡ Quick Jump Index

[`archiveutils`](#archiveutils-api) • [`asyncutils`](#asyncutils-api) • [`bitutils`](#bitutils-api) • [`cacheutils`](#cacheutils-api) • [`cliutils`](#cliutils-api) • [`colorutils`](#colorutils-api) • [`compressutils`](#compressutils-api) • [`cryptoutils`](#cryptoutils-api) • [`envutils`](#envutils-api) • [`fileutils`](#fileutils-api) • [`flowutils`](#flowutils-api) • [`htmlutils`](#htmlutils-api) • [`httputils`](#httputils-api) • [`logutils`](#logutils-api) • [`mockutils`](#mockutils-api) • [`netutils`](#netutils-api) • [`regexutils`](#regexutils-api) • [`semverutils`](#semverutils-api) • [`sliceutils`](#sliceutils-api) • [`sqliteutils`](#sqliteutils-api) • [`stateutils`](#stateutils-api) • [`statutils`](#statutils-api) • [`structutils`](#structutils-api) • [`strutils`](#strutils-api) • [`sysutils`](#sysutils-api) • [`tarutils`](#tarutils-api) • [`templateutils`](#templateutils-api) • [`timeutils`](#timeutils-api) • [`tomlutils`](#tomlutils-api) • [`validutils`](#validutils-api) • [Advanced Additions & Enhancements](#advanced-additions--enhancements)

---

### 📂 Categorized Modules & Subsections

#### 1. File & Data Persistence

- **[`cacheutils`](#cacheutils-api)** — In-memory LRU and TTL caching engines
  - [LRU (Least-Recently-Used) Cache](#1-lru-least-recently-used-cache)
  - [TTL (Time-To-Live) Cache](#2-ttl-time-to-live-cache)
- **[`fileutils`](#fileutils-api)** — High-level file, JSON, CSV, and directory operations
  - [Struct Helpers](#struct-helpers)
  - [Text File Helpers](#text-file-helpers)
  - [Map & Config Helpers](#map--config-helpers)
  - [Directory Helpers](#directory-helpers)
  - [JSON Helpers](#json-helpers)
  - [File Operations & CSV Helpers](#file-operations--csv-helpers)
- **[`sqliteutils`](#sqliteutils-api)** — SQLite persistence, KV store, JSON document store, CRUD & migrations
  - [Connection & Database Management](#connection--database-management)
  - [Key-Value Store Helpers](#key-value-store-helpers)
  - [Struct & JSON Document Store Helpers](#struct--json-document-store-helpers)
  - [Dynamic Query & Transaction Helpers](#dynamic-query--transaction-helpers)
  - [Schema / DDL Helpers](#schema--ddl-helpers)
  - [Extended Key-Value Helpers](#extended-key-value-helpers)
  - [Extended JSON Document Store Helpers](#extended-json-document-store-helpers)
  - [Query Helpers](#query-helpers)
  - [Column Management Helpers](#column-management-helpers)
- **[`stateutils`](#stateutils-api)** — Atomic crash-proof AppStateStore & KeyValueState with auto-save & rollback

#### 2. Strings, Collections & Math

- **[`bitutils`](#bitutils-api)** — Dynamic BitSet, popcount, bitwise operations, binary string conversions
- **[`sliceutils`](#sliceutils-api)** — Generic slice operations (unique, chunk, flatten, partition, sample, shuffle)
- **[`statutils`](#statutils-api)** — Statistical analysis, linear regression, variance, quartiles, outlier detection
- **[`structutils`](#structutils-api)** — Generic Stack, Queue, RingBuffer, and MinHeap data structures
- **[`strutils`](#strutils-api)** — String transformations, casing (snake, kebab, camel, pascal), slugify, masking, wrap

#### 3. System Telemetry, OS & CLI

- **[`cliutils`](#cliutils-api)** — ANSI terminal colors, FlagParser, interactive prompts, progress bars, tables
- **[`envutils`](#envutils-api)** — Type-safe environment variable access, setters, inspection, .env persistence, variable expansion
  - [Programmatic Setters](#envutils-setters)
  - [State & Inspection](#envutils-inspection)
  - [Typed Getters](#envutils-getters)
  - [Dotenv (.env) Persistence](#envutils-dotenv)
  - [String Interpolation](#envutils-expansion)
- **[`logutils`](#logutils-api)** — Leveled structured logging (.debug, .info, .warn, .error, .fatal)
- **[`sysutils`](#sysutils-api)** — CPU/RAM/disk telemetry, system uptime, safe command execution, clipboard

#### 4. Network, HTTP & Web

- **[`htmlutils`](#htmlutils-api)** — HTML document parsing, DOM element search, tag stripping, entity escaping
- **[`httputils`](#httputils-api)** — Ergonomic typed HTTP client (get_json, post_json), query builders, retries
- **[`netutils`](#netutils-api)** — Local/public IP discovery, MAC address, Wi-Fi SSID, DNS servers, TCP ping

#### 5. Parsing, Formatting & Encodings

- **[`regexutils`](#regexutils-api)** — High-level regular expressions (is_match, find_all, replace, split)
  - [Regex Data Structures](#regexutils-data-structures)
  - [Regex Functions](#regexutils-functions)
- **[`semverutils`](#semverutils-api)** — Semantic Versioning 2.0.0 parsing, precedence compare, range matching, bumping
  - [SemVer Data Structures](#semverutils-data-structures)
  - [SemVer Functions & Methods](#semverutils-functions--methods)
- **[`templateutils`](#templateutils-api)** — Fast string templating with defaults ({{key | default}}), terminal markdown
  - [Template Functions](#templateutils-functions)
- **[`timeutils`](#timeutils-api)** — Relative time ("2 hours ago"), ISO 8601 parsing/formatting, Stopwatch, benchmarking
- **[`tomlutils`](#tomlutils-api)** — TOML configuration file and string parser with typed accessors
- **[`validutils`](#validutils-api)** — High-speed input validation (email, URL, IPv4/IPv6, phone, UUID, range, JSON)

#### 6. Security, Cryptography & Concurrency

- **[`asyncutils`](#asyncutils-api)** — Order-preserving parallel map/filter/each, WaitGroup, WorkerPool
  - [Parallel Collections](#1-parallel-collections)
  - [WaitGroup Synchronization](#2-waitgroup-synchronization)
  - [Worker Pool](#3-worker-pool)
- **[`cryptoutils`](#cryptoutils-api)** — SHA-256, SHA-512, MD5, HMAC, AES-CBC, Bcrypt, UUID v4, secure tokens
- **[`flowutils`](#flowutils-api)** — Traffic control & resilience: RateLimiter, CircuitBreaker, Debouncer, retry
  - [Rate Limiting (Token Bucket)](#1-rate-limiting-token-bucket)
  - [Circuit Breaker](#2-circuit-breaker)
  - [Exponential Backoff Retry](#3-exponential-backoff-retry)
  - [Debouncer](#4-debouncer)

#### 7. Graphics, Color Theory & Archives

- **[`archiveutils`](#archiveutils-api)** — Zip archive creation, extraction, recursive directory compression
  - [Archive Data Structures](#archiveutils-data-structures)
  - [Archive Functions](#archiveutils-functions)
- **[`colorutils`](#colorutils-api)** — HEX/RGB/HSL conversion, color harmonies, WCAG 2.1 contrast audits, Truecolor
  - [Color Data Structures](#colorutils-data-structures)
  - [Color Space Conversions](#1-color-space-conversions)
  - [Color Transformations & Harmonies](#2-color-transformations--harmonies)
  - [WCAG 2.1 Accessibility & Contrast](#3-wcag-21-accessibility--contrast)
  - [Terminal Truecolor (24-bit ANSI)](#4-terminal-truecolor-24-bit-ansi-formatting)
- **[`compressutils`](#compressutils-api)** — Fast Gzip, Zlib, Deflate, and Zstandard compression/decompression
- **[`tarutils`](#tarutils-api)** — In-memory and on-disk TAR archive creation, unpacking, directory archiving
- **[`mockutils`](#mockutils-api)** — Synthetic mock data generator (users, emails, phones, IPv4, URLs, lorem)
  - [Mock Data Structures](#mockutils-data-structures)
  - [Mock Functions](#mockutils-functions)

#### 8. Advanced Extensions

- **[Advanced Additions & Enhancements](#advanced-additions--enhancements)** — System clipboard, symmetric AES-CBC, Bcrypt hashing, secure entropy, fast non-cryptographic hashes

---

<a id="fileutils"></a><a id="fileutils-api"></a>

# fileutils API

**Plain-language purpose:** Use these tools to create, read, copy, rename, and organize files. The examples start with simple text and move to saved lists, settings, and JSON data.

Import statement:

```v
import fileutils
```

<a id="struct-helpers"></a>

## Struct helpers

### `save_struct_array_to_file[T](path string, data []T) !`

Saves a slice of structs to disk as a JSON array file. Automatically creates any missing parent directories.

```v
struct Person {
    name string
    age  int
}

// Create a list of Person structs
people := [
    Person{ name: 'Alice', age: 30 },
    Person{ name: 'Bob', age: 25 }
]

// Save the list to disk
fileutils.save_struct_array_to_file('data/people.json', people)!
println('Saved people array!')
```

---

### `load_struct_array_from_file[T](path string) ![]T`

Loads a slice of structs from a JSON array file back into memory.

```v
struct Person {
    name string
    age  int
}

// Load the slice of Person structs from file
people := fileutils.load_struct_array_from_file[Person]('data/people.json')!
println('Loaded ${people.len} people from file:')
for person in people {
    println('- ${person.name} (${person.age})')
}
```

---

### `save_struct_to_file[T](path string, data T) !`

Saves a single struct object to disk as a JSON file.

```v
struct Person {
    name string
    age  int
}

// Single struct object
person := Person{ name: 'Charlie', age: 40 }

// Save struct to disk
fileutils.save_struct_to_file('data/person.json', person)!
```

---

### `load_struct_from_file[T](path string) !T`

Loads a single struct object from a JSON file into memory.

```v
struct Person {
    name string
    age  int
}

// Load single struct from disk
person := fileutils.load_struct_from_file[Person]('data/person.json')!
println('Loaded single person: ${person.name}, age ${person.age}')
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="text-file-helpers"></a>

## Text File Helpers

### `append_line_to_file(path string, line string) !`

Appends a single text line to a file. Creates the file and any missing parent directories automatically if they do not exist.

```v
// Append log entries to a text file
fileutils.append_line_to_file('logs/app.log', 'First log entry')!
fileutils.append_line_to_file('logs/app.log', 'Second log entry')!
```

---

### `write_text_file(path string, content string) !`

Writes string content to a text file, creating parent directories automatically.

```v
// Write text content to a file
content := "Hello world!\nWelcome to RAD development with V."
fileutils.write_text_file('notes/readme.txt', content)!
```

---

### `read_text_file(path string) !string`

Reads an entire text file into a string variable.

```v
// Read file content back as a string
text := fileutils.read_text_file('notes/readme.txt')!
println(text)
```

---

### `read_lines_from_file(path string) ![]string`

Reads a text file line-by-line into a slice of strings (`[]string`).

```v
// Read file into lines
lines := fileutils.read_lines_from_file('logs/app.log')!
println('Total log lines: ${lines.len}')
for line in lines {
    println('Log: ${line}')
}
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="map--config-helpers"></a><a id="map-config-helpers"></a>

## Map & Config Helpers

### `save_map_to_file[K, V](path string, data map[K]V) !`

Saves a V map to disk as JSON for key-value configurations or lookup tables.

```v
mut settings := map[string]int{}
settings['max_connections'] = 100
settings['timeout_seconds'] = 30

fileutils.save_map_to_file('config/settings.json', settings)!
```

---

### `load_map_from_file[K, V](path string) !map[K]V`

Loads a V map from a JSON file into memory.

```v
settings := fileutils.load_map_from_file[string, int]('config/settings.json')!
println('Max connections: ${settings['max_connections']}')
```

---

### `load_config_from_file(path string, defaults map[string]string) !map[string]string`

Loads a simple `key=value` configuration file, ignoring `#` comments and falling back to default values when keys are missing.

```v
// Define default fallback values
defaults := {
    'host': 'localhost'
    'port': '3000'
    'mode': 'development'
}

// Load config file overlaying parsed values onto defaults
config := fileutils.load_config_from_file('app.conf', defaults)!
println('Server running on ${config['host']}:${config['port']} (${config['mode']} mode)')
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="directory-helpers"></a>

## Directory Helpers

### `ensure_dir_exists(path string) !`

Creates the parent directory for a given file path if it doesn't already exist.

```v
// Ensure output directory exists before writing custom output
fileutils.ensure_dir_exists('exports/2026/report.csv')!
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="json-helpers"></a>

## JSON Helpers

### `write_json_file[T](path string, data T) !`

Writes any serializable data value or struct `T` as JSON to a file.

```v
struct Config {
    title string
    debug bool
}

cfg := Config{ title: 'My App', debug: true }
fileutils.write_json_file('config.json', cfg)!
```

---

### `read_json_file[T](path string) !T`

Reads a JSON file into a value or struct of type `T`.

```v
struct Config {
    title string
    debug bool
}

cfg := fileutils.read_json_file[Config]('config.json')!
println('App title: ${cfg.title}, debug enabled: ${cfg.debug}')
```

---

### `append_json_line[T](path string, data T) !`

Appends a JSON object as a single line to a newline-delimited JSON (NDJSON / `.jsonl`) file.

```v
struct LogEvent {
    level   string
    message string
}

event1 := LogEvent{ level: 'INFO', message: 'System boot' }
event2 := LogEvent{ level: 'WARN', message: 'High memory usage' }

fileutils.append_json_line('events.ndjson', event1)!
fileutils.append_json_line('events.ndjson', event2)!
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="file-operations--csv-helpers"></a><a id="file-operations-csv-helpers"></a>

## File Operations & CSV Helpers

### `copy_file(src string, dst string) !`

Copies a single file from `src` to `dst`. Automatically creates any missing parent directories for the destination.

```v
fileutils.copy_file('data/source.txt', 'backup/nested/copy.txt')!
```

---

### `copy_dir(src string, dst string) !`

Recursively copies a directory and all of its contents from `src` to `dst`.

```v
fileutils.copy_dir('assets', 'dist/assets')!
```

---

### `move(src string, dst string) !`

Moves or renames a file or directory. Automatically ensures destination parent folders exist.

```v
fileutils.move('temp/draft.txt', 'archive/final.txt')!
```

---

### `remove_file(path string) !`

Safely removes a file if it exists without throwing an error if absent.

```v
fileutils.remove_file('temp/scratch.txt')!
```

---

### `remove_dir(path string) !`

Safely and recursively removes a directory and all its contents if it exists.

```v
fileutils.remove_dir('temp/cache')!
```

---

### `list_files(dir string, recursive bool) ![]string`

Returns a list of all file paths inside `dir`. If `recursive` is `true`, traverses all nested directories.

```v
files := fileutils.list_files('logs', true)!
for f in files {
    println(f)
}
```

---

### `list_files_with_ext(dir string, ext string, recursive bool) ![]string`

Finds all files in `dir` matching a specific extension (e.g. `'json'` or `'.json'`).

```v
configs := fileutils.list_files_with_ext('conf', 'json', false)!
```

---

### `file_size(path string) !i64`

Returns the size of a file in bytes.

```v
bytes := fileutils.file_size('video.mp4')!
println('Size in bytes: ${bytes}')
```

---

### `file_size_human(path string) !string`

Returns a human-readable file size (e.g. `'450 B'`, `'1.50 MB'`, `'2.40 GB'`).

```v
readable := fileutils.file_size_human('dataset.csv')!
println('Size: ${readable}') // "12.45 MB"
```

---

### `file_extension(path string) string`

Returns the file extension without the leading dot.

```v
ext := fileutils.file_extension('image.png') // "png"
```

---

### `file_stem(path string) string`

Returns the base filename without extension or directory prefix.

```v
stem := fileutils.file_stem('/var/logs/app.conf') // "app"
```

---

### `read_csv(path string, delimiter rune) ![][]string`

Reads a CSV or TSV file into a 2D slice of strings. Delimiter defaults to `,` if `0` is passed.

```v
rows := fileutils.read_csv('users.csv', `,`)!
for row in rows {
    println('User: ${row[0]}, Role: ${row[1]}')
}
```

---

### `write_csv(path string, rows [][]string, delimiter rune) !`

Writes a 2D slice of strings to disk as a delimited CSV file, properly escaping cells containing quotes, delimiters, or newlines.

```v
table := [
    ['id', 'name', 'status'],
    ['1', 'Alice', 'active'],
    ['2', 'Bob', 'inactive'],
]
fileutils.write_csv('report.csv', table, `,`)!
```

---

### `temp_file(prefix string, suffix string) !string`

Creates a new empty temporary file with the given prefix and suffix and returns its absolute path.

```v
tmp := fileutils.temp_file('cache', '.tmp')!
defer { fileutils.remove_file(tmp) or {} }
```

---

### `temp_dir(prefix string) !string`

Creates a new temporary directory and returns its absolute path.

```v
dir := fileutils.temp_dir('build')!
defer { fileutils.remove_dir(dir) or {} }
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="sqliteutils"></a><a id="sqliteutils-api"></a>

# sqliteutils API

**Plain-language purpose:** Use these tools to keep information in a small local database, such as a contact list or app settings. The examples show how to open a database, add records, find them, change them, and keep the data safe.

Import statement:

```v
import sqliteutils
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="connection--database-management"></a><a id="connection-database-management"></a>

## Connection & Database Management

### `open_db(path string) !sqlite.DB`

Opens a SQLite database connection to a file (or `:memory:`). Automatically creates parent folders if the file path directory does not exist.

```v
// Open or create a database in 'db/' folder
mut db := sqliteutils.open_db('db/app.db')!
println('Connected to database!')
```

---

### `close_db(mut db sqlite.DB) !`

Closes a SQLite database connection and releases all associated OS file handles. Always close a database when you are finished with it — leaving connections open can block other processes from writing to the same file.

The idiomatic pattern is to call `close_db` via `defer` immediately after opening:

```v
mut db := sqliteutils.open_db('app.db')!
defer { sqliteutils.close_db(mut db) or {} }

// … do work …
// close_db is called automatically when the function returns
```

---

### `last_insert_id(db sqlite.DB) i64`

Returns the row ID (typically the `INTEGER PRIMARY KEY`) assigned to the most recently inserted row on this connection. Returns `0` if no `INSERT` has been performed yet. Call this **immediately** after an `INSERT` before any other statement.

```v
mut db := sqliteutils.open_db(':memory:')!
defer { sqliteutils.close_db(mut db) or {} }

sqliteutils.exec_sql(mut db, 'CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT);')!

sqliteutils.exec_sql(mut db, "INSERT INTO users (name) VALUES ('Alice');")!
alice_id := sqliteutils.last_insert_id(db)
println('Alice inserted with id: ${alice_id}') // 1

sqliteutils.exec_sql(mut db, "INSERT INTO users (name) VALUES ('Bob');")!
bob_id := sqliteutils.last_insert_id(db)
println('Bob inserted with id: ${bob_id}') // 2
```

---

### `exec_sql(mut db sqlite.DB, query string) !`

Executes raw static DDL or DML SQL statements (`CREATE TABLE`, `INSERT`, `UPDATE`, `DELETE`) without returning rows.
Caller is responsible for ensuring the query string contains no unescaped user-supplied data. For user inputs, ALWAYS use `exec_sql_params` or the parameterized CRUD helpers below.

```v
mut db := sqliteutils.open_db(':memory:')!

// Create table using raw SQL
sqliteutils.exec_sql(mut db, 'CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT);')!
```

---

### `exec_sql_params(mut db sqlite.DB, query string, params []string) !` & `exec_sql_param`

Executes parameterized SQL statements using `?` placeholders, delegating argument binding directly to SQLite to guarantee complete immunity against SQL injection.

```v
mut db := sqliteutils.open_db(':memory:')!
sqliteutils.exec_sql(mut db, 'CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, email TEXT);')!

// Parameterized execution prevents SQL injection even with malicious inputs
user_input := "admin' OR 1=1; DROP TABLE users; --"
sqliteutils.exec_sql_params(mut db, 'INSERT INTO users (name, email) VALUES (?, ?)', ['attacker', user_input])!
```

---

### Security & SQL Injection Prevention Helpers

#### `sanitize_identifier(name string) !string` & `is_valid_identifier(name string) bool`

Strictly validates table and column identifiers against injection. Valid identifiers must start with an ASCII letter or underscore, contain only `[a-zA-Z0-9_-]`, and be under 128 characters.

```v
import sqliteutils

safe_table := sqliteutils.sanitize_identifier('user_accounts')!
assert sqliteutils.is_valid_identifier('users') == true
assert sqliteutils.is_valid_identifier('users; DROP TABLE users;') == false
```

#### `escape_string(s string) string`

Doubles single quotes according to SQL-92 standards (`'` -> `''`). Parameterized queries should always be favored over string interpolation.

```v
safe_literal := sqliteutils.escape_string("O'Connor") // "O''Connor"
```

#### `sanitize_sql_type(sql_type string) !string`

Validates that a SQL column type definition (e.g. `TEXT`, `INTEGER NOT NULL`, `VARCHAR(255)`) contains only safe characters, balanced delimiters, no comment injection (`--`, `/*`), and no statement separators (`;`).

```v
safe_type := sqliteutils.sanitize_sql_type('VARCHAR(255) NOT NULL')!
```

#### `apply_secure_pragmas(mut db sqlite.DB) !`

Applies recommended security and durability settings to SQLite:

- `foreign_keys = ON`: Validates foreign key constraints.
- `trusted_schema = OFF`: Blocks malicious triggers/views in untrusted schemas.
- `cell_size_check = ON`: Detects B-tree corruption early.
  _(Note: `open_db` calls `apply_secure_pragmas` automatically)._

---

### Injection-Free Parameterized CRUD Helpers

High-level helpers that eliminate manual SQL query construction for common CRUD operations:

#### `insert_row(mut db sqlite.DB, table_name string, data map[string]string) !i64`

Safely inserts a record with automatic parameter binding. Returns the newly generated `last_insert_rowid`.

```v
mut db := sqliteutils.open_db(':memory:')!
sqliteutils.exec_sql(mut db, 'CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, email TEXT);')!

new_id := sqliteutils.insert_row(mut db, 'users', {
    'name':  'Alice'
    'email': 'alice@example.com'
})!
println('Created user id: ${new_id}')
```

#### `select_rows(mut db sqlite.DB, table_name string, columns []string, where_clause string, where_params []string) ![]map[string]string`

Safely queries rows with bound filter parameters.

```v
mut db := sqliteutils.open_db(':memory:')!
sqliteutils.exec_sql(mut db, 'CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, email TEXT);')!
sqliteutils.exec_sql(mut db, "INSERT INTO users (name, email) VALUES ('Alice', 'alice@example.com');")!

users := sqliteutils.select_rows(mut db, 'users', ['id', 'name', 'email'], 'name = ?', ['Alice'])!
for u in users {
    println('Found: ${u["name"]} (${u["email"]})')
}
```

#### `update_rows(mut db sqlite.DB, table_name string, data map[string]string, where_clause string, where_params []string) !`

Safely updates records with bound parameters.

```v
mut db := sqliteutils.open_db(':memory:')!
sqliteutils.exec_sql(mut db, 'CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, email TEXT);')!
sqliteutils.exec_sql(mut db, "INSERT INTO users (id, name, email) VALUES (1, 'Alice', 'alice@example.com');")!

sqliteutils.update_rows(mut db, 'users', {
    'email': 'alice.new@example.com'
}, 'id = ?', ['1'])!
```

#### `delete_rows(mut db sqlite.DB, table_name string, where_clause string, where_params []string) !`

Safely deletes records matching parameterized criteria.

```v
mut db := sqliteutils.open_db(':memory:')!
sqliteutils.exec_sql(mut db, 'CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, email TEXT);')!
sqliteutils.exec_sql(mut db, "INSERT INTO users (id, name, email) VALUES (1, 'Alice', 'alice@example.com');")!

sqliteutils.delete_rows(mut db, 'users', 'id = ?', ['1'])!
```

---

### `table_exists(mut db sqlite.DB, table_name string) !bool`

Checks whether a specific table exists in the database.

```v
mut db := sqliteutils.open_db(':memory:')!

if sqliteutils.table_exists(mut db, 'users')! {
    println('Users table exists!')
} else {
    println('Users table does not exist yet.')
}
```

---

### `get_table_names(mut db sqlite.DB) ![]string`

Returns a slice containing all non-system table names in the database.

```v
mut db := sqliteutils.open_db(':memory:')!
sqliteutils.exec_sql(mut db, 'CREATE TABLE users (id INT);')!
sqliteutils.exec_sql(mut db, 'CREATE TABLE orders (id INT);')!

tables := sqliteutils.get_table_names(mut db)!
println('Tables in database: ${tables}') // Output: ['users', 'orders']
```

---

### `count_rows(mut db sqlite.DB, table_name string) !int`

Returns the total row count for a given table.

```v
mut db := sqliteutils.open_db(':memory:')!
sqliteutils.exec_sql(mut db, 'CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT);')!
sqliteutils.exec_sql(mut db, "INSERT INTO users (name) VALUES ('Alice'), ('Bob');")!

count := sqliteutils.count_rows(mut db, 'users')!
println('Total rows in users table: ${count}') // Output: 2
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="key-value-store-helpers"></a>

## Key-Value Store Helpers

### `create_kv_table(mut db sqlite.DB, table_name string) !`

Creates a Key-Value table with schema `(key TEXT PRIMARY KEY, val TEXT)`.

```v
mut db := sqliteutils.open_db(':memory:')!

// Create a key-value table called 'settings'
sqliteutils.create_kv_table(mut db, 'settings')!
```

---

### `set_kv(mut db sqlite.DB, table_name string, key string, val string) !`

Inserts or updates a key-value pair in a Key-Value table.

```v
mut db := sqliteutils.open_db(':memory:')!
sqliteutils.create_kv_table(mut db, 'settings')!

// Save key-value settings
sqliteutils.set_kv(mut db, 'settings', 'theme', 'dark')!
sqliteutils.set_kv(mut db, 'settings', 'fontSize', '16')!
```

---

### `get_kv(mut db sqlite.DB, table_name string, key string) !string`

Gets the string value for a key from a Key-Value table. Returns an error if the key is missing (allowing the `or { 'default' }` fallback pattern).

```v
mut db := sqliteutils.open_db(':memory:')!
sqliteutils.create_kv_table(mut db, 'settings')!
sqliteutils.set_kv(mut db, 'settings', 'theme', 'dark')!

// Fetch value with default fallback if key is missing
theme := sqliteutils.get_kv(mut db, 'settings', 'theme') or { 'light' }
println('Theme: ${theme}') // Output: dark

missing := sqliteutils.get_kv(mut db, 'settings', 'nonexistent_key') or { 'default_val' }
println('Missing key fallback: ${missing}') // Output: default_val
```

---

### `delete_kv(mut db sqlite.DB, table_name string, key string) !`

Deletes a key-value entry from a Key-Value table.

```v
mut db := sqliteutils.open_db(':memory:')!
sqliteutils.create_kv_table(mut db, 'settings')!
sqliteutils.set_kv(mut db, 'settings', 'theme', 'dark')!

// Delete key
sqliteutils.delete_kv(mut db, 'settings', 'theme')!
```

---

### `get_all_kv(mut db sqlite.DB, table_name string) !map[string]string`

Retrieves all key-value entries from a Key-Value table as a V `map[string]string`.

```v
mut db := sqliteutils.open_db(':memory:')!
sqliteutils.create_kv_table(mut db, 'settings')!
sqliteutils.set_kv(mut db, 'settings', 'theme', 'dark')!
sqliteutils.set_kv(mut db, 'settings', 'lang', 'en')!

all_settings := sqliteutils.get_all_kv(mut db, 'settings')!
println('Theme setting: ${all_settings['theme']}')
println('Language setting: ${all_settings['lang']}')
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="struct--json-document-store-helpers"></a><a id="struct-json-document-store-helpers"></a>

## Struct & JSON Document Store Helpers

### `create_json_store(mut db sqlite.DB, table_name string) !`

Creates a document store table with schema `(id TEXT PRIMARY KEY, json_data TEXT)` for persisting struct objects.

```v
mut db := sqliteutils.open_db(':memory:')!

// Create document store table
sqliteutils.create_json_store(mut db, 'user_store')!
```

---

### `save_struct[T](mut db sqlite.DB, table_name string, id string, data T) !`

Serializes a V struct into JSON and saves it in SQLite under a unique ID. Updates existing records if ID exists.

```v
struct Product {
    name  string
    price int
}

mut db := sqliteutils.open_db(':memory:')!
sqliteutils.create_json_store(mut db, 'products')!

item := Product{ name: 'Mechanical Keyboard', price: 120 }
sqliteutils.save_struct(mut db, 'products', 'prod_01', item)!
println('Saved product struct to SQLite!')
```

---

### `load_struct[T](mut db sqlite.DB, table_name string, id string) !T`

Loads and deserializes a struct from a SQLite document store by ID.

```v
struct Product {
    name  string
    price int
}

mut db := sqliteutils.open_db(':memory:')!
sqliteutils.create_json_store(mut db, 'products')!
sqliteutils.save_struct(mut db, 'products', 'prod_01', Product{ name: 'Keyboard', price: 100 })!

// Load struct by ID
product := sqliteutils.load_struct[Product](mut db, 'products', 'prod_01')!
println('Loaded product: ${product.name}, price: $${product.price}')
```

---

### `load_all_structs[T](mut db sqlite.DB, table_name string) ![]T`

Loads and deserializes all struct records in a document store table into a slice `[]T`.

```v
struct Product {
    name  string
    price int
}

mut db := sqliteutils.open_db(':memory:')!
sqliteutils.create_json_store(mut db, 'products')!

sqliteutils.save_struct(mut db, 'products', 'p1', Product{ name: 'Mouse', price: 40 })!
sqliteutils.save_struct(mut db, 'products', 'p2', Product{ name: 'Monitor', price: 300 })!

// Load all products
products := sqliteutils.load_all_structs[Product](mut db, 'products')!
println('Total products loaded: ${products.len}')
for p in products {
    println('- ${p.name}: $${p.price}')
}
```

---

### `delete_struct(mut db sqlite.DB, table_name string, id string) !`

Deletes a document record by ID from a document store table.

```v
mut db := sqliteutils.open_db(':memory:')!
sqliteutils.create_json_store(mut db, 'products')!

// Delete record with ID 'p1'
sqliteutils.delete_struct(mut db, 'products', 'p1')!
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="dynamic-query--transaction-helpers"></a><a id="dynamic-query-transaction-helpers"></a>

## Dynamic Query & Transaction Helpers

### `query_maps(mut db sqlite.DB, query string) ![]map[string]string`

Executes a `SELECT` SQL query and returns rows as a slice of maps (`[]map[string]string`), where keys are column names.

```v
mut db := sqliteutils.open_db(':memory:')!
sqliteutils.exec_sql(mut db, 'CREATE TABLE employees (name TEXT, role TEXT, salary INT);')!
sqliteutils.exec_sql(mut db, "INSERT INTO employees VALUES ('Alice', 'Developer', 90000), ('Bob', 'Designer', 80000);")!

// Run query returning rows as column maps
rows := sqliteutils.query_maps(mut db, 'SELECT name, role, salary FROM employees;')!
for row in rows {
    println('Employee ${row['name']}: ${row['role']} (Salary: $${row['salary']})')
}
```

---

### `query_one_map(mut db sqlite.DB, query string) !map[string]string`

Executes a `SELECT` query and returns the first row as a column map `map[string]string`. Returns an error if no rows match.

```v
mut db := sqliteutils.open_db(':memory:')!
sqliteutils.exec_sql(mut db, 'CREATE TABLE users (id INT, name TEXT);')!
sqliteutils.exec_sql(mut db, "INSERT INTO users VALUES (1, 'Alice');")!

// Fetch single row
user := sqliteutils.query_one_map(mut db, 'SELECT name FROM users WHERE id = 1;')!
println('Found user: ${user['name']}') // Output: Alice
```

---

### `query_maps_params(mut db sqlite.DB, query string, params []string) ![]map[string]string`

Executes a **parameterized** `SELECT` query with `?` placeholders and returns rows as a slice of maps. Use this variant whenever the query includes user-supplied filter values.

```v
mut db := sqliteutils.open_db(':memory:')!
sqliteutils.exec_sql(mut db, 'CREATE TABLE employees (name TEXT, dept TEXT, salary INT);')!
sqliteutils.exec_sql(mut db, "INSERT INTO employees VALUES ('Alice','Eng',90),('Bob','Eng',80),('Carol','HR',70);")!

// Safe parameterized filter — user input goes in params, not the query string
rows := sqliteutils.query_maps_params(mut db,
    'SELECT name, salary FROM employees WHERE dept = ? ORDER BY salary DESC',
    ['Eng'])!
for row in rows {
    println('${row['name']}: ${row['salary']}')
}
```

---

### `query_one_map_params(mut db sqlite.DB, query string, params []string) !map[string]string`

Executes a **parameterized** `SELECT` query and returns the first matching row as a map. Returns an error if no rows match.

```v
mut db := sqliteutils.open_db(':memory:')!
sqliteutils.exec_sql(mut db, 'CREATE TABLE users (id INT, name TEXT);')!
sqliteutils.exec_sql(mut db, "INSERT INTO users VALUES (1, 'Alice');")!

// Safe lookup by user-supplied id
row := sqliteutils.query_one_map_params(mut db,
    'SELECT name FROM users WHERE id = ?',
    ['1'])!
println('Found: ${row['name']}') // Output: Alice
```

### `execute_batch(mut db sqlite.DB, statements []string) !`

Executes multiple SQL statements inside a single transaction (`BEGIN TRANSACTION ... COMMIT`). If any statement fails, the transaction automatically rolls back.

```v
mut db := sqliteutils.open_db(':memory:')!

// Run multiple statements atomically
batch := [
    'CREATE TABLE accounts (id INT PRIMARY KEY, balance INT);',
    'INSERT INTO accounts VALUES (1, 500);',
    'INSERT INTO accounts VALUES (2, 1000);',
    'UPDATE accounts SET balance = balance - 100 WHERE id = 1;',
    'UPDATE accounts SET balance = balance + 100 WHERE id = 2;'
]

sqliteutils.execute_batch(mut db, batch)!
println('Batch transaction executed successfully!')
```

---

### `execute_batch_params(mut db sqlite.DB, statements []ParamStatement) !`

Executes multiple **parameterized** SQL statements atomically. Each `ParamStatement` pairs a query string with its bound values. Rolls back automatically on any error.

```v
mut db := sqliteutils.open_db(':memory:')!
sqliteutils.exec_sql(mut db, 'CREATE TABLE log (msg TEXT, level TEXT);')!

batch := [
    sqliteutils.ParamStatement{ query: 'INSERT INTO log VALUES (?, ?)', params: ['boot', 'INFO'] },
    sqliteutils.ParamStatement{ query: 'INSERT INTO log VALUES (?, ?)', params: ['ready', 'INFO'] },
]

sqliteutils.execute_batch_params(mut db, batch)!
println('Parameterized batch executed!')
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="schema--ddl-helpers"></a>

## Schema / DDL Helpers

### `drop_table(mut db sqlite.DB, table_name string, force bool) !`

Drops a table. Pass `force: true` to use `DROP TABLE IF EXISTS` — no error is returned when the table is already absent.

```v
mut db := sqliteutils.open_db(':memory:')!
sqliteutils.exec_sql(mut db, 'CREATE TABLE tmp (id INT);')!

// Normal drop — errors if table is missing
sqliteutils.drop_table(mut db, 'tmp', false)!

// Force drop — safe even when table doesn't exist
sqliteutils.drop_table(mut db, 'tmp', true)!
println('Dropped!')
```

---

### `rename_table(mut db sqlite.DB, old_name string, new_name string) !`

Renames a table using `ALTER TABLE … RENAME TO`. Both names must contain only letters, digits, underscores, or hyphens.

```v
mut db := sqliteutils.open_db(':memory:')!
sqliteutils.exec_sql(mut db, 'CREATE TABLE old_name (id INT);')!

sqliteutils.rename_table(mut db, 'old_name', 'new_name')!
println('Renamed!')
```

---

### `clear_table(mut db sqlite.DB, table_name string) !`

Removes all rows from a table without dropping it (SQLite's equivalent of `TRUNCATE`).

```v
mut db := sqliteutils.open_db(':memory:')!
sqliteutils.exec_sql(mut db, 'CREATE TABLE events (msg TEXT);')!
sqliteutils.exec_sql(mut db, "INSERT INTO events VALUES ('one'),('two');")!

sqliteutils.clear_table(mut db, 'events')!
count := sqliteutils.count_rows(mut db, 'events')!
println('Rows after clear: ${count}') // Output: 0
```

---

### `get_column_names(mut db sqlite.DB, table_name string) ![]string`

Returns the ordered list of column names for a table via `PRAGMA table_info`.

```v
mut db := sqliteutils.open_db(':memory:')!
sqliteutils.exec_sql(mut db, 'CREATE TABLE users (id INT, name TEXT, email TEXT);')!

cols := sqliteutils.get_column_names(mut db, 'users')!
println('Columns: ${cols}') // Output: ['id', 'name', 'email']
```

---

### `column_exists(mut db sqlite.DB, table_name string, column_name string) !bool`

Checks whether a specific column exists in a table.

```v
mut db := sqliteutils.open_db(':memory:')!
sqliteutils.exec_sql(mut db, 'CREATE TABLE users (id INT, name TEXT);')!

println(sqliteutils.column_exists(mut db, 'users', 'name')!)  // true
println(sqliteutils.column_exists(mut db, 'users', 'phone')!) // false
```

---

### `table_row_counts(mut db sqlite.DB) !map[string]int`

Returns a map of every non-system table name to its current row count. Useful for quick database health checks.

```v
mut db := sqliteutils.open_db(':memory:')!
sqliteutils.exec_sql(mut db, 'CREATE TABLE a (x INT);')!
sqliteutils.exec_sql(mut db, 'CREATE TABLE b (x INT);')!
sqliteutils.exec_sql(mut db, 'INSERT INTO a VALUES (1),(2);')!

counts := sqliteutils.table_row_counts(mut db)!
println(counts) // {'a': 2, 'b': 0}
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="extended-key-value-helpers"></a>

## Extended Key-Value Helpers

### `kv_exists(mut db sqlite.DB, table_name string, key string) !bool`

Checks whether a key is present in a key-value table without fetching the value.

```v
mut db := sqliteutils.open_db(':memory:')!
sqliteutils.create_kv_table(mut db, 'cfg')!
sqliteutils.set_kv(mut db, 'cfg', 'theme', 'dark')!

println(sqliteutils.kv_exists(mut db, 'cfg', 'theme')!)  // true
println(sqliteutils.kv_exists(mut db, 'cfg', 'ghost')!)  // false
```

---

### `get_kv_or(mut db sqlite.DB, table_name string, key string, default_val string) string`

Gets a value by key, returning `default_val` if the key is absent. **Never errors** — designed for the zero-friction RAD read pattern.

```v
mut db := sqliteutils.open_db(':memory:')!
sqliteutils.create_kv_table(mut db, 'cfg')!

lang := sqliteutils.get_kv_or(mut db, 'cfg', 'lang', 'en')
println('Language: ${lang}') // Output: en  (key absent, default returned)
```

---

### `increment_kv(mut db sqlite.DB, table_name string, key string, amount int) !int`

Atomically increments an integer stored at `key` by `amount`. Creates the key with value `amount` if it doesn't yet exist. Returns the updated value.

```v
mut db := sqliteutils.open_db(':memory:')!
sqliteutils.create_kv_table(mut db, 'counters')!

v1 := sqliteutils.increment_kv(mut db, 'counters', 'page_views', 1)!
println(v1) // 1  (created from zero)

v2 := sqliteutils.increment_kv(mut db, 'counters', 'page_views', 1)!
println(v2) // 2
```

---

### `clear_kv(mut db sqlite.DB, table_name string) !`

Removes all key-value pairs from a table while keeping the table itself intact.

```v
mut db := sqliteutils.open_db(':memory:')!
sqliteutils.create_kv_table(mut db, 'session')!
sqliteutils.set_kv(mut db, 'session', 'token', 'abc123')!

sqliteutils.clear_kv(mut db, 'session')!
println(sqliteutils.count_rows(mut db, 'session')!) // 0
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="extended-json-document-store-helpers"></a>

## Extended JSON Document Store Helpers

### `struct_exists(mut db sqlite.DB, table_name string, id string) !bool`

Checks whether a document with the given ID exists in a JSON store table.

```v
mut db := sqliteutils.open_db(':memory:')!
sqliteutils.create_json_store(mut db, 'users')!

struct User { name string }
sqliteutils.save_struct(mut db, 'users', 'u1', User{ name: 'Alice' })!

println(sqliteutils.struct_exists(mut db, 'users', 'u1')!)  // true
println(sqliteutils.struct_exists(mut db, 'users', 'u99')!) // false
```

---

### `count_structs(mut db sqlite.DB, table_name string) !int`

Returns the number of documents stored in a JSON store table. Alias for `count_rows` with clearer intent.

```v
mut db := sqliteutils.open_db(':memory:')!
sqliteutils.create_json_store(mut db, 'items')!
sqliteutils.save_struct(mut db, 'items', 'i1', map[string]string{})!
sqliteutils.save_struct(mut db, 'items', 'i2', map[string]string{})!

println(sqliteutils.count_structs(mut db, 'items')!) // 2
```

---

### `delete_all_structs(mut db sqlite.DB, table_name string) !`

Deletes every document from a JSON store table while keeping the table schema intact.

```v
mut db := sqliteutils.open_db(':memory:')!
sqliteutils.create_json_store(mut db, 'cache')!
sqliteutils.save_struct(mut db, 'cache', 'c1', map[string]string{})!

sqliteutils.delete_all_structs(mut db, 'cache')!
println(sqliteutils.count_structs(mut db, 'cache')!) // 0
```

---

### `list_struct_ids(mut db sqlite.DB, table_name string) ![]string`

Returns a slice of all document IDs stored in a JSON store table. Useful for iterating or bulk-loading records.

```v
mut db := sqliteutils.open_db(':memory:')!
sqliteutils.create_json_store(mut db, 'posts')!
sqliteutils.save_struct(mut db, 'posts', 'post_1', map[string]string{})!
sqliteutils.save_struct(mut db, 'posts', 'post_2', map[string]string{})!

ids := sqliteutils.list_struct_ids(mut db, 'posts')!
println('Post IDs: ${ids}') // ['post_1', 'post_2']
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="query-helpers"></a>

## Query Helpers

### `query_scalar(mut db sqlite.DB, query string, params []string) !string`

Executes a parameterized query and returns the **first column of the first row** as a string. Ideal for scalar aggregates (`COUNT`, `MAX`, `SUM`, etc.).

```v
mut db := sqliteutils.open_db(':memory:')!
sqliteutils.exec_sql(mut db, 'CREATE TABLE orders (user TEXT, amount INT);')!
sqliteutils.exec_sql(mut db, "INSERT INTO orders VALUES ('alice', 50), ('alice', 30), ('bob', 20);")!

total := sqliteutils.query_scalar(mut db, 'SELECT SUM(amount) FROM orders WHERE user = ?', ['alice'])!
println('Alice total: ${total}') // 80
```

---

### `query_column(mut db sqlite.DB, query string, params []string) ![]string`

Executes a parameterized query and returns **every value from the first column** as a `[]string`. Useful for fetching a list of IDs, names, tags, etc.

```v
mut db := sqliteutils.open_db(':memory:')!
sqliteutils.exec_sql(mut db, 'CREATE TABLE tags (name TEXT, active INT);')!
sqliteutils.exec_sql(mut db, "INSERT INTO tags VALUES ('v','1'),('vlang','1'),('draft','0');")!

active_tags := sqliteutils.query_column(mut db, 'SELECT name FROM tags WHERE active = ?', ['1'])!
println('Active tags: ${active_tags}') // ['v', 'vlang']
```

---

### `with_transaction(mut db sqlite.DB, work fn () !) !`

Runs a closure inside a `BEGIN / COMMIT` transaction. If the closure returns an error the transaction is automatically rolled back. A clean, closure-style alternative to `execute_batch`.

```v
mut db := sqliteutils.open_db(':memory:')!
sqliteutils.create_kv_table(mut db, 'state')!

sqliteutils.with_transaction(mut db, fn [mut db] () ! {
    sqliteutils.set_kv(mut db, 'state', 'step', '1')!
    sqliteutils.set_kv(mut db, 'state', 'status', 'ok')!
})!

println(sqliteutils.get_kv(mut db, 'state', 'status')!) // ok
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="column-management-helpers"></a>

## Column Management Helpers

> **SQLite version requirements**
>
> - `add_column` / `add_columns` — SQLite 3.1+ (always available)
> - `rename_column` — SQLite 3.25+ (September 2018)
> - `drop_column` / `drop_columns` — SQLite 3.35+ (March 2021)

### `ColumnDef`

A struct used with `add_column` and `add_columns` to describe a new column.

```v
pub struct ColumnDef {
pub:
    name     string // column identifier — validated by sanitize_identifier
    sql_type string // SQLite type expression, e.g. "TEXT", "INTEGER NOT NULL DEFAULT 0"
}
```

---

### `add_column(mut db sqlite.DB, table_name string, col ColumnDef) !`

Adds a single new column to an existing table using `ALTER TABLE … ADD COLUMN`.
The column name and type expression are both validated before the query runs.

```v
mut db := sqliteutils.open_db(':memory:')!
sqliteutils.exec_sql(mut db, 'CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT);')!

// Add a plain text column
sqliteutils.add_column(mut db, 'users', sqliteutils.ColumnDef{
    name:     'email'
    sql_type: 'TEXT'
})!

// Add a column with constraints and a default value
sqliteutils.add_column(mut db, 'users', sqliteutils.ColumnDef{
    name:     'score'
    sql_type: 'INTEGER NOT NULL DEFAULT 0'
})!

cols := sqliteutils.get_column_names(mut db, 'users')!
println(cols) // ['id', 'name', 'email', 'score']
```

---

### `add_columns(mut db sqlite.DB, table_name string, cols []ColumnDef) !`

Adds multiple columns inside a single transaction. If any column name or type is invalid, or if SQLite rejects any of the `ALTER TABLE` statements, the entire batch is rolled back — either all columns are added or none are.

```v
mut db := sqliteutils.open_db(':memory:')!
sqliteutils.exec_sql(mut db, 'CREATE TABLE products (id INTEGER PRIMARY KEY, name TEXT);')!

sqliteutils.add_columns(mut db, 'products', [
    sqliteutils.ColumnDef{ name: 'price', sql_type: 'REAL' },
    sqliteutils.ColumnDef{ name: 'stock', sql_type: 'INTEGER NOT NULL DEFAULT 0' },
    sqliteutils.ColumnDef{ name: 'sku',   sql_type: 'TEXT' },
])!

println(sqliteutils.get_column_names(mut db, 'products')!)
// ['id', 'name', 'price', 'stock', 'sku']
```

---

### `rename_column(mut db sqlite.DB, table_name string, old_col string, new_col string) !`

Renames a column using `ALTER TABLE … RENAME COLUMN`. Existing data is preserved under the new column name. Both old and new names must pass identifier validation.

```v
mut db := sqliteutils.open_db(':memory:')!
sqliteutils.exec_sql(mut db, 'CREATE TABLE users (id INT, fname TEXT, age INT);')!
sqliteutils.exec_sql(mut db, "INSERT INTO users VALUES (1, 'Alice', 30);")!

sqliteutils.rename_column(mut db, 'users', 'fname', 'first_name')!

cols := sqliteutils.get_column_names(mut db, 'users')!
println(cols) // ['id', 'first_name', 'age']

// Data is preserved
rows := sqliteutils.query_maps(mut db, 'SELECT first_name FROM users;')!
println(rows[0]['first_name']) // Alice
```

---

### `drop_column(mut db sqlite.DB, table_name string, col_name string) !`

Drops a single column from a table using `ALTER TABLE … DROP COLUMN`. The column name must pass identifier validation. Note: SQLite prevents dropping a column that is a primary key, part of an index, or referenced by a UNIQUE/CHECK constraint.

```v
mut db := sqliteutils.open_db(':memory:')!
sqliteutils.exec_sql(mut db, 'CREATE TABLE events (id INT, msg TEXT, legacy TEXT, ts TEXT);')!
sqliteutils.exec_sql(mut db, "INSERT INTO events VALUES (1, 'boot', 'old_data', '2024-01-01');")!

sqliteutils.drop_column(mut db, 'events', 'legacy')!

cols := sqliteutils.get_column_names(mut db, 'events')!
println(cols) // ['id', 'msg', 'ts']
```

---

### `drop_columns(mut db sqlite.DB, table_name string, col_names []string) !`

Drops multiple columns inside a single transaction. If any column name is invalid or SQLite rejects any drop, the entire batch is rolled back — either all columns are dropped or none are.

```v
mut db := sqliteutils.open_db(':memory:')!
sqliteutils.exec_sql(mut db, 'CREATE TABLE logs (id INT, msg TEXT, level TEXT, host TEXT, pid INT);')!

// Remove infrastructure columns that are no longer needed
sqliteutils.drop_columns(mut db, 'logs', ['host', 'pid'])!

cols := sqliteutils.get_column_names(mut db, 'logs')!
println(cols) // ['id', 'msg', 'level']
```

---

### `get_table_schema(mut db sqlite.DB, table_name string) ![]map[string]string`

Returns full `PRAGMA table_info` schema for a table as a slice of maps. Each map contains the keys `"cid"`, `"name"`, `"type"`, `"notnull"`, `"dflt_value"`, and `"pk"`. Useful for schema introspection and migration tools.

```v
mut db := sqliteutils.open_db(':memory:')!
sqliteutils.exec_sql(mut db,
    'CREATE TABLE orders (id INTEGER PRIMARY KEY, user TEXT NOT NULL, amount REAL);')!

schema := sqliteutils.get_table_schema(mut db, 'orders')!
for col in schema {
    println('${col['name']} (${col['type']}) pk=${col['pk']} notnull=${col['notnull']}')
}
// id (INTEGER) pk=1 notnull=0
// user (TEXT) pk=0 notnull=1
// amount (REAL) pk=0 notnull=0
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="strutils"></a><a id="strutils-api"></a>

# strutils API

**Plain-language purpose:** Use these tools to clean up and reshape text, such as turning a title into a web address, masking private information, or comparing two words. Each example starts with ordinary text and shows the transformed result.

Import statement:

```v
import strutils
```

### `to_snake_case(s string) string`

Converts camelCase, PascalCase, kebab-case, or spaced strings into snake_case.

```v
assert strutils.to_snake_case('helloWorld') == 'hello_world'
```

---

### `to_kebab_case(s string) string`

Converts a string into kebab-case.

```v
assert strutils.to_kebab_case('hello_world') == 'hello-world'
```

---

### `to_camel_case(s string) string`

Converts snake_case or kebab-case into camelCase.

```v
assert strutils.to_camel_case('hello_world') == 'helloWorld'
```

---

### `to_pascal_case(s string) string`

Converts snake_case or kebab-case into PascalCase.

```v
assert strutils.to_pascal_case('hello_world') == 'HelloWorld'
```

---

### `to_title_case(s string) string`

Capitalizes the first letter of each word in a string.

```v
assert strutils.to_title_case('hello world_again') == 'Hello World Again'
```

---

### `slugify(s string) string`

Converts arbitrary text into a URL-friendly slug.

```v
assert strutils.slugify('Hello World! 2026') == 'hello-world-2026'
```

---

### `truncate(s string, max_len int, suffix string) string`

Truncates a string to a given rune length, appending suffix if truncated.

```v
assert strutils.truncate('Hello, world!', 8, '...') == 'Hello...'
```

---

### `truncate_words(s string, max_words int, suffix string) string`

Shortens a string to the specified number of words.

```v
assert strutils.truncate_words('The quick brown fox jumps', 3, '...') == 'The quick brown...'
```

---

### `pad_left(s string, width int, pad_char string) string`

Pads the beginning of a string until it reaches the specified width. Automatically utilizes V's built-in string interpolation formatting (`${s:(width)}`) when padding with spaces on ASCII.

```v
assert strutils.pad_left('42', 5, '0') == '00042'
```

---

### `pad_right(s string, width int, pad_char string) string`

Pads the end of a string until it reaches the specified width. Automatically utilizes V's built-in string interpolation formatting (`${s:-(width)}`) when padding with spaces on ASCII.

```v
assert strutils.pad_right('hi', 5, ' ') == 'hi   '
```

---

### `pad_center(s string, width int, pad_char string) string`

Centers a string with symmetric padding.

```v
assert strutils.pad_center('v', 5, '=') == '==v=='
```

---

### `mask(s string, unmasked_start int, unmasked_end int, mask_char string) string`

Masks characters between unmasked start and end counts.

```v
assert strutils.mask('1234567890', 2, 2, '*') == '12******90'
```

---

### `mask_email(email string) string`

Redacts user portion of an email address for privacy.

```v
assert strutils.mask_email('john.doe@example.com') == 'j******e@example.com'
```

---

### `random_string(len int, charset string) string`

Generates a random string of the specified length using custom runes from `charset`.

```v
custom_code := strutils.random_string(8, 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789')
```

---

### `random_alphanumeric(len int) string`

Generates a random string containing letters (A-Z, a-z) and digits (0-9).

```v
token := strutils.random_alphanumeric(16)
```

---

### `random_hex(len int) string`

Generates a random lowercase hexadecimal string of length `len`.

```v
hex_token := strutils.random_hex(32)
```

---

### `extract_between(s string, start_delim string, end_delim string) ?string`

Extracts the substring bounded between two delimiter strings, or returns `none` if not found.

```v
tag := strutils.extract_between('<title>Home Page</title>', '<title>', '</title>') or { '' }
assert tag == 'Home Page'
```

---

### `strip_html_tags(s string) string`

Strips HTML/XML tags from a string.

```v
assert strutils.strip_html_tags('<p>Hello <b>World</b>!</p>') == 'Hello World!'
```

---

### `collapse_whitespace(s string) string`

Replaces multiple consecutive whitespace characters with a single space.

```v
assert strutils.collapse_whitespace('  hello   world  ') == 'hello world'
```

---

### `word_wrap(s string, width int) string`

Wraps a string so that lines do not exceed the specified width.

```v
wrapped := strutils.word_wrap('one two three four five', 10)
```

---

### `levenshtein_distance(a string, b string) int`

Calculates the minimum edit operations (insertions, deletions, substitutions) between two strings using V's built-in standard library `strings.levenshtein_distance`.

```v
assert strutils.levenshtein_distance('kitten', 'sitting') == 3
```

---

### `similarity(a string, b string) f64`

Returns similarity score between 0.0 (completely different) and 1.0 (identical).

```v
score := strutils.similarity('hello', 'hallo') // ~0.8
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="sliceutils"></a><a id="sliceutils-api"></a>

# sliceutils API

**Plain-language purpose:** Use these tools to work with lists of things, such as names, numbers, or files. The examples show common list tasks like removing duplicates, grouping items, filtering choices, and changing their order.

Import statement:

```v
import sliceutils
```

### `unique[T](arr []T) []T`

Returns a new slice with duplicate items removed, preserving order of first appearance.

```v
assert sliceutils.unique([1, 2, 2, 3, 1]) == [1, 2, 3]
```

---

### `intersection[T](a []T, b []T) []T`

Returns elements present in both slices.

```v
assert sliceutils.intersection([1, 2, 3], [2, 3, 4]) == [2, 3]
```

---

### `difference[T](a []T, b []T) []T`

Returns elements in `a` that are not present in `b`.

```v
assert sliceutils.difference([1, 2, 3], [2, 3, 4]) == [1]
```

---

### `union_slices[T](a []T, b []T) []T`

Combines two slices and returns only unique elements.

```v
assert sliceutils.union_slices([1, 2], [2, 3]) == [1, 2, 3]
```

---

### `chunk[T](arr []T, size int) [][]T`

Splits a slice into smaller chunks of given size.

```v
chunks := sliceutils.chunk([1, 2, 3, 4, 5], 2) // [[1, 2], [3, 4], [5]]
```

---

### `flatten[T](matrix [][]T) []T`

Flattens a 2D slice into a 1D slice.

```v
assert sliceutils.flatten([[1, 2], [3, 4]]) == [1, 2, 3, 4]
```

---

### `find_index[T](arr []T, pred fn (item T) bool) ?int`

Finds the index of the first item matching the predicate, or `none`.

```v
idx := sliceutils.find_index([10, 20, 30], fn (x int) bool { return x > 15 }) // 1
```

---

### `partition[T](arr []T, pred fn (item T) bool) ([]T, []T)`

Partitions elements into two slices: those matching the predicate and those that do not.

```v
evens, odds := sliceutils.partition([1, 2, 3, 4], fn (x int) bool { return x % 2 == 0 })
```

---

### `count[T](arr []T, target T) int`

Counts how many times `target` appears in the slice.

```v
assert sliceutils.count(['a', 'b', 'a'], 'a') == 2
```

---

### `sample[T](arr []T, n int) []T`

Randomly selects `n` items without replacement.

```v
picks := sliceutils.sample([1, 2, 3, 4, 5], 3)
```

---

### `shuffle[T](mut arr []T)`

Randomly shuffles slice elements in-place using Fisher-Yates.

```v
mut items := [1, 2, 3, 4, 5]
sliceutils.shuffle(mut items)
```

---

### `sum_int(arr []int) int` and `average_int(arr []int) f64`

Calculates the arithmetic sum and average of integer slices.

```v
assert sliceutils.sum_int([1, 2, 3, 4]) == 10
assert sliceutils.average_int([1, 2, 3, 4]) == 2.5
```

---

### `min_int(arr []int) ?int` and `max_int(arr []int) ?int`

Finds the minimum and maximum integers in a slice, returning `none` if empty.

```v
nums := [42, 10, 88, 3]
min_val := sliceutils.min_int(nums) or { 0 } // 3
max_val := sliceutils.max_int(nums) or { 0 } // 88
```

---

### `sum_f64(arr []f64) f64` and `average_f64(arr []f64) f64`

Calculates the arithmetic sum and average of floating point slices.

```v
floats := [1.5, 2.5, 3.5, 4.5]
assert sliceutils.sum_f64(floats) == 12.0
assert sliceutils.average_f64(floats) == 3.0
```

---

### `min_f64(arr []f64) ?f64` and `max_f64(arr []f64) ?f64`

Finds the minimum and maximum floating point values in a slice, returning `none` if empty.

```v
floats := [1.5, -2.5, 8.2]
min_f := sliceutils.min_f64(floats) or { 0.0 } // -2.5
max_f := sliceutils.max_f64(floats) or { 0.0 } // 8.2
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="envutils"></a><a id="envutils-api"></a>

# envutils API

**Plain-language purpose:** Use these tools to read and set app settings that live in the process environment, such as a port number, a feature switch, or a secret key. The examples show typed getters with safe defaults, programmatic setters, inspection, .env persistence, and string interpolation.

Import statement:

```v
import envutils
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="envutils-setters"></a>

## Programmatic Setters

### `set(key string, val string)`

Sets an environment variable to a string value in the current process.

```v
envutils.set('APP_ENV', 'production')
```

---

### `set_int(key string, val int)`

Sets an environment variable to an integer formatted as a string.

```v
envutils.set_int('PORT', 8080)
```

---

### `set_bool(key string, val bool)`

Sets an environment variable to `'true'` or `'false'`.

```v
envutils.set_bool('DEBUG', true)
```

---

### `set_f64(key string, val f64)`

Sets an environment variable to a floating-point number formatted as a string.

```v
envutils.set_f64('RATE_LIMIT_RATIO', 1.25)
```

---

### `set_default(key string, val string)`

Sets an environment variable **only if it is currently unset or empty**. If the variable already has a value, it remains untouched.

```v
// Preserves runtime environment overrides if already defined
envutils.set_default('HOST', '127.0.0.1')
```

---

### `set_map(vars map[string]string)`

Sets multiple environment variables at once from a key-value map.

```v
envutils.set_map({
    'SERVICE_NAME': 'payments',
    'REGION':       'us-east-1',
    'ENV':          'staging'
})
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="envutils-inspection"></a>

## State & Inspection

### `is_set(key string) bool` & `has(key string) bool`

Checks whether an environment variable exists and is non-empty.

```v
if envutils.is_set('DATABASE_URL') {
    println('Database URL is configured')
}
if envutils.has('REDIS_URL') {
    println('Redis URL is configured')
}
```

---

### `unset(key string)`

Removes an environment variable from the OS environment.

```v
envutils.unset('TEMP_TOKEN')
```

---

### `all() map[string]string`

Returns a map snapshot of all environment variables currently active in the process.

```v
current_env := envutils.all()
println('Total environment variables: ${current_env.len}')
for k, v in current_env {
    println('${k}=${v}')
}
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="envutils-getters"></a>

## Typed Getters

### `get_str(key string, default_val string) string`

Gets environment variable string, or fallback if unset/empty.

```v
host := envutils.get_str('APP_HOST', 'localhost')
```

---

### `get_int(key string, default_val int) int`

Gets environment variable parsed as integer, or fallback if unset or invalid.

```v
port := envutils.get_int('PORT', 8080)
```

---

### `get_i64(key string, default_val i64) i64`

Gets environment variable parsed as a 64-bit integer, or fallback if unset or invalid. Ideal for timestamps and large byte limits.

```v
max_bytes := envutils.get_i64('MAX_UPLOAD_BYTES', 10737418240)
```

---

### `get_bool(key string, default_val bool) bool`

Interprets `'true'`, `'1'`, `'yes'`, `'on'` as `true`, and `'false'`, `'0'`, `'no'`, `'off'` as `false`.

```v
debug := envutils.get_bool('DEBUG', false)
```

---

### `get_f64(key string, default_val f64) f64`

Gets environment variable parsed as float, or fallback if unset or invalid.

```v
scale := envutils.get_f64('SCALE_FACTOR', 1.0)
```

---

### `get_opt(key string) ?string`

Returns an Option `?string` with the variable value if set and non-empty, or `none`. Allows idiomatic V `if val := envutils.get_opt(...)` checks without throwing errors.

```v
if token := envutils.get_opt('GITHUB_TOKEN') {
    println('Found API token: ${token}')
} else {
    println('Running in anonymous mode')
}
```

---

### `get_required(key string) !string`

Returns the environment variable value or errors if missing/empty.

```v
secret := envutils.get_required('JWT_SECRET')!
```

---

### `get_list(key string, delimiter string, default_val []string) []string`

Splits an environment variable by delimiter into trimmed, non-empty tokens. Falls back to `default_val` if unset, empty, or whitespace.

```v
// Splits comma-delimited origins and trims whitespace
origins := envutils.get_list('ALLOWED_ORIGINS', ',', ['http://localhost:3000'])
for origin in origins {
    println('Allowed: ${origin}')
}
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="envutils-dotenv"></a>

## Dotenv (.env) Persistence

### `load_dotenv(path string) !map[string]string`

Loads a `.env` file into the OS environment and returns the parsed key-value map.

```v
env_vars := envutils.load_dotenv('.env')!
println('Loaded ${env_vars.len} variables')
```

---

### `load_dotenv_auto() !map[string]string`

Searches for `.env` in the current working directory or a parent directory, loading it into the environment if found. Returns the parsed values or an error when no `.env` file exists.

```v
env_vars := envutils.load_dotenv_auto() or {
    println('No .env file found')
    map[string]string{}
}
if env_vars.len > 0 {
    println('Successfully loaded ${env_vars.len} variables')
}
```

---

### `save_dotenv(path string, vars map[string]string) !`

Writes or overwrites a `.env` file with the provided key-value map. Keys are written in sorted order, and values containing spaces, newlines, hashes, or quotes are automatically quoted and escaped.

```v
envutils.save_dotenv('.env', {
    'APP_ENV':     'production',
    'PORT':        '8080',
    'DATABASE_URL': 'postgres://user:pass@localhost:5432/app'
})!
```

---

### `parse_dotenv_content(content string) map[string]string`

Parses raw `.env` formatted content string without touching the OS environment.

```v
env_map := envutils.parse_dotenv_content('PORT=8080\nDEBUG=true\nDB_PASS="secret #1"')
assert env_map['PORT'] == '8080'
assert env_map['DB_PASS'] == 'secret #1'
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="envutils-expansion"></a>

## String Interpolation

### `expand_env(input string) string`

Substitutes `$VAR` and `${VAR}` in strings with current environment values.

```v
path := envutils.expand_env('/home/\${USER}/config')
println(path)
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="cryptoutils"></a><a id="cryptoutils-api"></a>

# cryptoutils API

**Plain-language purpose:** Use these tools to protect information, check whether text was changed, create secure random values, and handle passwords. Treat the sample keys and passwords as demonstrations only; real secret values should stay outside source code.

Import statement:

```v
import cryptoutils
```

### `sha256(s string) string` & `sha256_hex(s string) string`

Returns the hexadecimal SHA-256 hash.

```v
hash := cryptoutils.sha256('hello')
assert cryptoutils.sha256_hex('hello') == hash
```

---

### `sha512(s string) string` & `sha512_hex(s string) string`

Returns the hexadecimal SHA-512 hash.

```v
hash := cryptoutils.sha512('hello')
assert cryptoutils.sha512_hex('hello') == hash
```

---

### `md5(s string) string` & `md5_hex(s string) string`

Returns the hexadecimal MD5 hash.

```v
hash := cryptoutils.md5('hello')
assert cryptoutils.md5_hex('hello') == hash
```

---

### `to_hex(b []u8) string` & `from_hex(s string) ![]u8`

Encodes bytes into hexadecimal and decodes hexadecimal strings back to raw bytes.

```v
raw := [u8(0xde), u8(0xad), u8(0xbe), u8(0xef)]
hex_str := cryptoutils.to_hex(raw) // "deadbeef"
bytes := cryptoutils.from_hex('deadbeef')!
```

---

### `hmac_sha256(key string, data string) string`

Computes HMAC-SHA256 digest in hex.

```v
mac := cryptoutils.hmac_sha256('my-secret-key', 'message payload')
```

---

### `base64_encode(s string) string` & `base64_decode(s string) !string`

Standard Base64 encoding and decoding.

```v
encoded := cryptoutils.base64_encode('Hello V')
decoded := cryptoutils.base64_decode(encoded)!
```

---

### `base64_url_encode(s string) string` & `base64_url_decode(s string) !string`

URL-safe Base64 encoding and decoding without padding.

```v
url_safe := cryptoutils.base64_url_encode('Hello V')
```

---

### `uuid_v4() string` & `is_valid_uuid(s string) bool`

Generates RFC 4122 v4 UUIDs and validates UUID format strings.

```v
id := cryptoutils.uuid_v4()
assert cryptoutils.is_valid_uuid(id)
```

---

### `secure_token(byte_count int) string`

Generates a cryptographically random hexadecimal string of given byte length.

```v
token := cryptoutils.secure_token(32) // 64 hex characters
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="timeutils"></a><a id="timeutils-api"></a>

# timeutils API

**Plain-language purpose:** Use these tools to display dates and durations in forms people can read, calculate time differences, and measure how long work takes. The examples use the current clock so you can see familiar dates and times.

Import statement:

```v
import timeutils
import time
```

### `time_ago(t time.Time) string`

Returns a human-friendly relative time string.

```v
println(timeutils.time_ago(time.now().add(-120 * time.second))) // "2 minutes ago"
```

---

### `time_until(t time.Time) string`

Returns a human-friendly relative time string for future timestamps.

```v
println(timeutils.time_until(time.now().add(7200 * time.second))) // "in 2 hours"
```

---

### `format_duration(d time.Duration) string`

Formats duration into readable units (e.g. `'250ms'`, `'2m 5s'`, `'1h 10m'`).

```v
println(timeutils.format_duration(125 * time.second)) // "2m 5s"
```

---

### `to_iso8601(t time.Time) string` & `from_iso8601(s string) !time.Time`

Serializes and parses ISO 8601 / RFC 3339 timestamps.

```v
iso := timeutils.to_iso8601(time.now())
parsed := timeutils.from_iso8601(iso)!
```

---

### `start_of_day(t time.Time) time.Time` & `end_of_day(t time.Time) time.Time`

Returns 00:00:00.000 or 23:59:59.999 for the given date.

```v
today_start := timeutils.start_of_day(time.now())
```

---

### `days_between(a time.Time, b time.Time) int`

Returns the absolute number of calendar days between two timestamps.

```v
t1 := time.now()
t2 := t1.add(86400 * 5 * time.second)
assert timeutils.days_between(t1, t2) == 5
```

---

### `is_weekend(t time.Time) bool`

Checks if `t` falls on Saturday or Sunday.

```v
if timeutils.is_weekend(time.now()) {
    println('Weekend!')
}
```

---

### `Stopwatch`

High-resolution timer for benchmarks, latency tracking, and profiling.

```v
mut sw := timeutils.new_stopwatch()
println('Running: ${sw.is_running()}') // true

// perform task...
sw.stop()

println('Elapsed ms: ${sw.elapsed_ms():.2f} ms')
println('Elapsed seconds: ${sw.elapsed_seconds():.4f} s')
println('Duration: ${sw.elapsed()}')

sw.reset()
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="httputils"></a><a id="httputils-api"></a>

# httputils API

**Plain-language purpose:** Use these tools to ask a website or web service for information, send information to it, and download files. Examples that include a web address need an internet connection and a real service that accepts the request.

Import statement:

```v
import httputils
```

### `build_query_string(params map[string]string) string`

Encodes parameter map into URL query string.

```v
qs := httputils.build_query_string({ 'page': '1', 'search': 'vlang' }) // "page=1&search=vlang"
```

---

### `parse_query_string(query string) map[string]string`

Parses query string into key-value map.

```v
params := httputils.parse_query_string('?page=1&search=vlang')
```

---

### `get_text(url string, headers map[string]string) !string`

Fetches a URL and returns text body.

```v
body := httputils.get_text('https://httpbin.org/get', {})!
```

---

### `post_text(url string, body string, headers map[string]string) !string`

Sends an HTTP POST request with raw text payload and returns the response body.

```v
res := httputils.post_text('https://httpbin.org/post', 'hello world', {
    'Content-Type': 'text/plain'
})!
```

---

### `get_json[T](url string, headers map[string]string) !T`

Fetches JSON endpoint and parses directly into struct `T` using `json2`.

```v
struct UserInfo {
    id   int
    name string
}
user := httputils.get_json[UserInfo]('https://api.example.com/user/1', {})!
```

---

### `post_json[T, R](url string, body T, headers map[string]string) !R`

Sends a JSON-serialized payload struct `T` via HTTP POST and parses the response into struct `R` using `json2`.

```v
struct CreateUserReq {
    name  string
    email string
}
struct UserResponse {
    id    int
    name  string
    email string
}

req := CreateUserReq{ name: 'Alice', email: 'alice@example.com' }
user_res := httputils.post_json[CreateUserReq, UserResponse]('https://api.example.com/users', req, {})!
```

---

### `download_file(url string, dest_path string) !`

Downloads a file directly to disk, creating parent folders automatically.

```v
httputils.download_file('https://example.com/archive.zip', 'downloads/archive.zip')!
```

---

### `fetch_with_retry(mut req http.Request, config RetryConfig) !http.Response`

Executes an HTTP request with exponential backoff on network failures or 5xx server errors.

```v
import net.http

mut req := http.new_request(.get, 'https://api.example.com/data', '')
res := httputils.fetch_with_retry(mut req, httputils.RetryConfig{
    max_retries: 3
    initial_delay_ms: 250
    backoff_factor: 2.0
})!
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="cliutils"></a><a id="cliutils-api"></a>

# cliutils API

**Plain-language purpose:** Use these tools to build friendlier terminal programs with prompts, menus, colored messages, progress indicators, and tables. Run interactive examples in a terminal where you can type an answer when asked.

Import statement:

```v
import cliutils
```

### ANSI Colors & Text Styles

Zero external dependencies. Returns ANSI escape-coded strings for styled terminal output.

```v
import cliutils

// Standard colors
println(cliutils.green('Operation completed successfully'))
println(cliutils.red('Fatal: Connection refused'))
println(cliutils.yellow('Warning: High memory pressure'))
println(cliutils.cyan('Info: Listening on port 8080'))
println(cliutils.blue('Notice: Update available'))
println(cliutils.magenta('Highlight: Special token'))
println(cliutils.gray('Debug: [trace_id=4829]'))

// Text decorations
println(cliutils.bold('Bold Header'))
println(cliutils.dim('Dimmed secondary text'))
println(cliutils.italic('Italicized note'))
println(cliutils.underline('Underlined link'))

// Combining styles
println(cliutils.bold(cliutils.green('SUCCESS: All checks passed!')))
```

---

### `strip_ansi(s string) string`

Removes all ANSI escape color and formatting codes from a string (ideal for writing clean log files).

```v
import cliutils

styled := cliutils.bold(cliutils.red('Error 404: Not Found'))
plain := cliutils.strip_ansi(styled)
println(plain) // "Error 404: Not Found"
```

---

### Interactive Terminal Prompts

#### `prompt(message string) string`

Displays a text prompt and reads the user's line input.

```v
import cliutils

name := cliutils.prompt('Enter your project name: ')
println('Creating project: ${name}')
```

#### `prompt_confirm(message string, default_val bool) bool`

Asks a yes/no question with a default fallback if the user presses Enter.

```v
import cliutils

proceed := cliutils.prompt_confirm('Do you want to deploy to production?', false)
if proceed {
    println('Deploying...')
} else {
    println('Deployment aborted.')
}
```

#### `prompt_select(message string, options []string) ?int`

Presents a numbered list of choices to the user and returns the selected zero-based index.

```v
import cliutils

options := ['Development', 'Staging', 'Production']
idx := cliutils.prompt_select('Choose target environment:', options) or {
    println('Invalid selection')
    return
}
println('Selected: ${options[idx]}')
```

---

### Terminal Visualizations

#### `ProgressBar`

Interactive terminal ASCII progress bar with percentage and step indicators.

```v
import cliutils
import time

mut pb := cliutils.new_progress_bar(100, 30)
for i in 1 .. 101 {
    pb.update(i)
    print('\r' + pb.render())
    time.sleep(10 * time.millisecond)
}
println('')
```

#### `sparkline(values []f64) string`

Renders an in-line sparkline chart using UTF-8 block glyphs (` ▂▃▄▅▆▇█`).

```v
import cliutils

history := [10.0, 25.0, 15.0, 60.0, 80.0, 45.0, 95.0, 100.0, 70.0]
println('Network Activity: ' + cliutils.sparkline(history))
```

#### `bar_chart(title string, items map[string]f64, max_width int) string`

Generates a clean horizontal Unicode bar chart.

```v
import cliutils

chart := cliutils.bar_chart('Server Resource Usage', {
    'CPU %':  42.5
    'RAM %':  78.2
    'Disk %': 65.0
}, 25)
println(chart)
```

#### `gauge(label string, current f64, max f64, unit string) string`

Generates a meter gauge with percentage calculation and status color badge (`[OK]`, `[WARN]`, `[CRITICAL]`).

```v
import cliutils

println(cliutils.gauge('RAM Usage', 7.2, 16.0, 'GB'))
println(cliutils.gauge('CPU Load', 92.0, 100.0, '%'))
```

#### `TreeNode`, `new_tree_node`, `add_child`, and `render_tree`

Visualizes hierarchical directory trees, taxonomies, and nested data using Unicode branch glyphs (`├──`, `└──`, `│   `).

```v
import cliutils

// Manual or programmatic tree construction
mut root := cliutils.new_tree_node('my_project')
root.add_child('README.md')
mut src := root.add_child('src')
src.add_child('main.v')
src.add_child('config.v')
root.add_child('v.mod')

println(cliutils.render_tree(&root))
```

#### `diff_text(old_text string, new_text string) string` & `diff(old_text string, new_text string)`

Generates and displays colorized line-by-line unified diffs with green additions and red deletions.

```v
import cliutils

old_code := "fn main() {\n\tprintln('old')\n}"
new_code := "fn main() {\n\tprintln('new feature')\n}"

// Output directly or capture string
diff_str := cliutils.diff_text(old_code, new_code)
println(diff_str)
```

---

### Presentation & Layout Components

#### `banner(title string, subtitle string) string`

Creates a stylish, framed header banner.

```v
import cliutils

println(cliutils.banner('ANTIGRAVITY CLI v2.0', 'High-Performance Developer Toolkit'))
```

#### `panel(title string, content string) string` (or `card`)

Renders a bordered box panel for notices, summaries, and cards.

```v
import cliutils

println(cliutils.panel('Service Status', 'API Gateway: Online\nLatency: 14ms\nUptime: 99.98%'))
```

#### `divider(ch rune, width int) string`

Renders a horizontal rule across the terminal.

```v
import cliutils

println(cliutils.divider(`=`, 60))
println(cliutils.divider(`-`, 40))
```

#### `badge(label string, value string, color_fn fn (string) string) string`

Generates an inverted status badge tag.

```v
import cliutils

println(cliutils.badge('ENV', 'PRODUCTION', cliutils.red))
println(cliutils.badge('BUILD', 'PASSING', cliutils.green))
```

---

### Data Formatting & Table Export

#### `table_to_markdown`, `table_to_csv`, `table_to_json`

Serializes 2D table data into GitHub Flavored Markdown, RFC CSV, or JSON array format.

```v
import cliutils

headers := ['ID', 'User', 'Role', 'Status']
rows := [
    ['1', 'alice', 'Admin', 'Active'],
    ['2', 'bob', 'Developer', 'Pending'],
    ['3', 'charlie', 'Viewer', 'Active']
]

md := cliutils.table_to_markdown(headers, rows)
println(md)

csv := cliutils.table_to_csv(headers, rows)
println(csv)

json_data := cliutils.table_to_json(headers, rows)
println(cliutils.json_highlight(json_data))
```

#### `json_highlight(json_str string) string`

Adds syntax coloring (cyan keys, yellow values) to formatted JSON strings.

```v
import cliutils

raw_json := '{\n  "name": "vlang_utils",\n  "version": "0.1.0",\n  "active": true\n}'
println(cliutils.json_highlight(raw_json))
```

---

### CLI Tools: `FlagParser`, `Pipeline`, `Logger`

#### `FlagParser` and `FlagDef`

Ergonomic command-line flag and argument parser supporting string, int, bool, and float flags with automated `-h, --help` generation and positional argument extraction.

```v
import cliutils
import os

mut fp := cliutils.new_flag_parser('deployer', 'Automated cloud deployment utility')
fp.add_flag_string('env', 'e', 'staging', 'Target deployment environment')
fp.add_flag_int('port', 'p', 8080, 'Listening HTTP port')
fp.add_flag_float('timeout', 't', 30.5, 'Request timeout in seconds')
fp.add_flag_bool('verbose', 'v', false, 'Enable verbose debug output')

fp.parse(os.args[1..])!

if fp.get_bool('verbose') {
    println('Verbose mode active')
}
println('Target: ' + fp.get_string('env'))
println('Port: ${fp.get_int('port')}')
println('Timeout: ${fp.get_float('timeout')}s')

// Positional arguments
pos_args := fp.get_positional()
println('Positional arguments: ${pos_args}')

// Programmatic help printing
help_text := fp.format_help()
fp.print_help()
```

#### `Pipeline` and `PipelineStep`

Task runner executing a multi-step sequential workflow composed of `PipelineStep` actions, halting on failure.

```v
import cliutils

mut p := cliutils.new_pipeline('Deploy Pipeline')
p.add_step('Check Environment', fn () bool {
    return true
})
p.add_step('Build Release Binaries', fn () bool {
    return true
})
p.add_step('Deploy to Cluster', fn () bool {
    return true
})

success := p.run()
println('Pipeline succeeded: ${success}')
```

#### `Logger`

Structured console logger supporting log level filtering (`debug`, `info`, `warn`, `error`).

```v
import cliutils

mut log := cliutils.new_logger(cliutils.LogLevel.info, '')
log.debug('Connecting to database...') // suppressed because level is info
log.info('Server started on :8080')
log.warn('Disk capacity above 80%')
log.error('Failed to send webhook notification')
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="sysutils"></a><a id="sysutils-api"></a>

# sysutils API

**Plain-language purpose:** Use these tools to learn about the computer running your program and to safely work with operating-system features. The examples may report different values on different computers, which is expected.

Import statement:

```v
import sysutils
```

### Hardware Telemetry & Probing

#### `get_cpu_count() int` & `get_cpu_usage() f64`

Retrieves logical CPU core count and current system CPU utilization percentage.

```v
import sysutils

cores := sysutils.get_cpu_count()
usage := sysutils.get_cpu_usage()
println('CPU: ${cores} cores @ ${usage:.1f}% load')
```

#### `get_load_averages() (f64, f64, f64)`

Returns the 1-minute, 5-minute, and 15-minute system load averages.

```v
import sysutils

l1, l5, l15 := sysutils.get_load_averages()
println('Load average: 1m=${l1:.2f}, 5m=${l5:.2f}, 15m=${l15:.2f}')
```

#### `get_memory_stats() (u64, u64, f64)` & `get_swap_stats() (u64, u64, f64)`

Returns `(total_bytes, used_bytes, used_percent)` for RAM and swap memory.

```v
import sysutils

total_ram, used_ram, ram_pct := sysutils.get_memory_stats()
println('RAM: ${used_ram / (1024 * 1024)} MB / ${total_ram / (1024 * 1024)} MB (${ram_pct:.1f}%)')

total_swap, used_swap, swap_pct := sysutils.get_swap_stats()
println('Swap: ${used_swap / (1024 * 1024)} MB / ${total_swap / (1024 * 1024)} MB')
```

#### `get_disk_stats(path string) (u64, u64, f64)`

Returns `(total_bytes, used_bytes, used_percent)` for the filesystem containing the given path.

```v
import sysutils

total, used, pct := sysutils.get_disk_stats('/')
println('Disk (/): ${used / (1024 * 1024 * 1024)} GB / ${total / (1024 * 1024 * 1024)} GB (${pct:.1f}%)')
```

#### `get_battery_level() ?int`, `is_battery_charging() ?bool` & `get_uptime() i64`

Queries laptop battery percentage, AC power/charging state, and system uptime in seconds.

```v
import sysutils

if battery := sysutils.get_battery_level() {
    charging := sysutils.is_battery_charging() or { false }
    println('Battery: ${battery}% (Charging: ${charging})')
}
uptime := sysutils.get_uptime()
println('Uptime: ${uptime} seconds')
```

#### `get_system_locale() string` & `get_os_theme() string`

Detects user language/locale (e.g. `en_US.UTF-8`) and OS appearance mode (`"dark"` or `"light"`).

```v
import sysutils

locale := sysutils.get_system_locale()
theme := sysutils.get_os_theme()
println('System Locale: ${locale}, Theme: ${theme}')
```

---

### Process Security & Command Execution

#### `exec_safe(cmd string, args []string) (string, int)`

Executes external processes safely with separate argument vectors, preventing shell injection.

```v
import sysutils

stdout, code := sysutils.exec_safe('git', ['status', '--porcelain'])
if code == 0 {
    println('Git status:\n${stdout}')
}
```

#### `exec_timeout(cmd string, timeout_ms i64) ExecTimeoutResult`

Executes a command with a maximum time limit, returning structured output, exit code, and `timed_out` boolean flag.

```v
import sysutils

res := sysutils.exec_timeout('ping -c 5 1.1.1.1', 2000)
if res.timed_out {
    println('Process exceeded 2000ms timeout!')
} else {
    println('Command completed with code ${res.exit_code}: ${res.output}')
}
```

#### `exec_retry(cmd string, retries int, delay_ms int) ExecRetryResult`

Runs an external command with automatic retries if non-zero exit code occurs, returning the final output, exit code, and number of attempts made.

```v
import sysutils

retry_res := sysutils.exec_retry('curl -s https://api.github.com', 3, 500)
println('Attempts: ${retry_res.attempts}, Exit code: ${retry_res.exit_code}')
```

#### `exec_or(cmd string, default_output string) string`

Executes a command and returns `default_output` if execution fails or exits non-zero.

```v
import sysutils

branch := sysutils.exec_or('git rev-parse --abbrev-ref HEAD', 'main').trim_space()
println('Current branch: ${branch}')
```

#### `quote_arg(arg string) string`, `quote_path(path string) string` & `sanitize_filename(name string) string`

Quotes command-line arguments and paths (expanding `~`) to prevent shell injection, and cleans filename inputs from path traversal attacks.

```v
import sysutils

safe_arg := sysutils.quote_arg('hello; rm -rf /')
safe_path := sysutils.quote_path('~/My Documents/Report.pdf')
clean_name := sysutils.sanitize_filename('../../etc/passwd') // "passwd"
```

#### `has_command(name string) bool`, `is_process_running(pid int) bool`, `kill_process(pid int) bool`, `get_command_path(name string) ?string`

Checks command availability on system `$PATH`, checks if a PID is alive, terminates processes by PID, and finds binary locations.

```v
import sysutils
import os

if sysutils.has_command('docker') {
    path := sysutils.get_command_path('docker') or { '' }
    println('Docker located at: ${path}')
}
running := sysutils.is_process_running(os.getpid())
// Terminate process: sysutils.kill_process(pid)
```

#### `beep()`

Produces an audible terminal bell alert (`\a`).

```v
import sysutils

sysutils.beep()
```

---

### Standard System Paths & Clipboard

#### Application Directories

Provides standard OS paths:

- `get_app_config_dir(app_name string) string`
- `get_app_data_dir(app_name string) string`
- `get_app_data_path(app_name string, filename string) string`
- `get_app_config_path(app_name string, filename string) string`
- `get_app_cache_dir(app_name string) string`
- `get_app_log_dir(app_name string) string`

```v
import sysutils

data_dir := sysutils.get_app_data_dir('my_app')
cfg_file := sysutils.get_app_config_path('my_app', 'settings.json')
println('Config file path: ${cfg_file}')
```

#### User & System Directories

- `get_user_home_dir() string`
- `get_system_path(folder_name string) string` (`"desktop"`, `"documents"`, `"downloads"`, `"music"`, `"pictures"`, `"videos"`)
- `resolve_user_path(path string) string` (expands `~/` to home directory)

```v
import sysutils

downloads := sysutils.get_system_path('downloads')
expanded := sysutils.resolve_user_path('~/Projects/my_app')
println('Resolved path: ${expanded}')
```

#### Clipboard & Notifications

- `copy_to_clipboard(text string) !`
- `get_clipboard_text() !string`
- `notify(title string, message string)`
- `say(text string) !`

```v
import sysutils

// System Clipboard
sysutils.copy_to_clipboard('Copied API Key: 12345')!
clip := sysutils.get_clipboard_text()!

// Desktop notification & speech
sysutils.notify('Build Complete', 'All 15 modules compiled successfully!')
sysutils.say('Build finished successfully') or {}
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="netutils"></a><a id="netutils-api"></a>

# netutils API

**Plain-language purpose:** Use these tools to inspect network details, such as addresses and DNS servers, or check whether a network service can be reached. Results depend on your network connection and its security rules.

Import statement:

```v
import netutils
```

### `is_online() bool`

Checks whether active Internet connectivity is present.

```v
import netutils

if netutils.is_online() {
    println('Internet connection active')
} else {
    println('Offline mode')
}
```

### `ping_tcp_port(host string, port int, timeout_ms int) bool`

Checks whether a remote or local TCP service is reachable within a timeout.

```v
import netutils

is_db_up := netutils.ping_tcp_port('127.0.0.1', 5432, 1000)
if is_db_up {
    println('Postgres is reachable')
}
```

### `get_local_ip() string` & `get_public_ip() !string`

Resolves local subnet IP address (e.g. `192.168.1.50`) and queries external public IP.

```v
import netutils

local := netutils.get_local_ip()
public := netutils.get_public_ip() or { 'Unavailable' }
println('Local: ${local} | Public: ${public}')
```

### `get_mac_address() string` & `get_wifi_ssid() string`

Queries host primary MAC address and connected Wi-Fi network SSID name.

```v
import netutils

mac := netutils.get_mac_address()
ssid := netutils.get_wifi_ssid()
println('MAC: ${mac} | Wi-Fi: ${ssid}')
```

### `get_dns_servers() []string` & `get_default_gateway() string`

Returns configured DNS nameserver IPs and primary gateway IP.

```v
import netutils

dns := netutils.get_dns_servers()
gateway := netutils.get_default_gateway()
println('DNS: ${dns} | Gateway: ${gateway}')
```

### `get_listening_ports() []int`

Scans and discovers currently listening TCP ports on the machine.

```v
import netutils

ports := netutils.get_listening_ports()
println('Active listening ports: ${ports}')
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="validutils"></a><a id="validutils-api"></a>

# validutils API

**Plain-language purpose:** Use these tools to check whether a value looks valid before your program relies on it, such as an email address, web address, phone number, or date. Examples show a valid value and, where useful, an invalid one.

Import statement:

```v
import validutils
```

### Fast Data Validators

All validators return boolean true/false for instant conditional checks.

```v
import validutils

// Email validation (RFC standard)
valid_email := validutils.validate_email('developer@domain.com') // true
bad_email   := validutils.validate_email('invalid..email@')       // false

// Web URL validation
valid_url := validutils.validate_url('https://vlang.io/docs') // true
bad_url   := validutils.validate_url('ftp://bad url')         // false

// IPv4 and IPv6 addresses
v4_ok := validutils.validate_ip('192.168.1.1') // true
v6_ok := validutils.validate_ip('::1')         // true

// International and standard phone numbers
phone_ok := validutils.validate_phone('+1-800-555-0199') // true

// Alphanumeric checks
user_ok := validutils.validate_alphanumeric('AdminUser42') // true

// Numeric ranges
range_ok := validutils.validate_numeric_range(25.0, 18.0, 65.0) // true

// String length constraints
len_ok := validutils.validate_length('my_password', 8, 32) // true

// RFC 4122 UUID format
uuid_ok := validutils.validate_uuid('e74a81d1-4db5-4b06-a077-80f0c0576395') // true

// JSON syntax validation
json_ok := validutils.validate_json('{"status": "ok", "code": 200}') // true
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="structutils"></a><a id="structutils-api"></a>

# structutils API

**Plain-language purpose:** Use these ready-made containers when a normal list is not the best fit, such as a queue for first-in-first-out work or a stack for last-in-first-out work. The examples add a few familiar values and then show how they are retrieved.

Import statement:

```v
import structutils
```

### Generic Stack: `SimpleStack[T]` (LIFO)

Fast, thread-safe generic Last-In-First-Out stack.

```v
import structutils

mut stack := structutils.new_stack[string]()
stack.push('first')
stack.push('second')
stack.push('third')

println('Top: ${stack.peek() or { "" }}') // "third"
item := stack.pop() or { '' }             // "third"
println('Popped: ${item}, Remaining: ${stack.len()}')

items := stack.to_array() // ['first', 'second']
stack.clear()
println('Is empty: ${stack.is_empty()}') // true
```

### Generic Queue: `SimpleQueue[T]` (FIFO)

Generic First-In-First-Out queue.

```v
import structutils

mut queue := structutils.new_queue[int]()
queue.push(10)
queue.push(20)
queue.push(30)

first := queue.pop() or { 0 } // 10
println('First out: ${first}')
println('Next up: ${queue.peek() or { 0 }}') // 20
```

### Circular Ring Buffer: `SimpleRingBuffer[T]`

Fixed-capacity circular buffer that automatically drops the oldest item when capacity is exceeded.

```v
import structutils

mut ring := structutils.new_ring_buffer[string](3)
ring.push('log_1')
ring.push('log_2')
ring.push('log_3')
println('Is ring buffer full: ${ring.is_full()}') // true

ring.push('log_4') // automatically overwrites 'log_1'

// Contents: ['log_2', 'log_3', 'log_4']
println('Recent logs: ${ring.to_array()}')
oldest := ring.pop() or { '' } // "log_2"
```

### Priority Queue: `SimpleMinHeap`

Binary min-heap where lowest numerical values are popped with highest priority.

```v
import structutils

mut heap := structutils.new_min_heap()
heap.push(50.0)
heap.push(12.5)
heap.push(3.0)
heap.push(25.0)

println('Smallest: ${heap.peek() or { 0.0 }}') // 3.0
val1 := heap.pop() or { 0.0 } // 3.0
val2 := heap.pop() or { 0.0 } // 12.5
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="statutils"></a><a id="statutils-api"></a>

# statutils API

**Plain-language purpose:** Use these tools to make sense of a set of numbers, such as scores, prices, or measurements. The examples explain the usual summary questions: typical value, spread, trend, unusual values, and relationships between two lists.

Import statement:

```v
import statutils
```

High-performance statistical analysis, distribution modeling, regression, and data profiling operating directly on `[]f64` numeric slices.

---

### 1. Measures of Central Tendency

```v
import statutils

dataset := [10.0, 20.0, 20.0, 30.0, 40.0, 50.0, 90.0]

// Arithmetic Sum & Mean
total := statutils.stats_sum(dataset)                 // 260.00
mean := statutils.stats_mean(dataset)                 // 37.14

// Median & Mode
median := statutils.stats_median(dataset)             // 30.00
mode := statutils.stats_mode(dataset) or { 0.0 }      // 20.00

// Specialized Means
geom_mean := statutils.stats_geometric_mean([2.0, 8.0])      // 4.00
harm_mean := statutils.stats_harmonic_mean([1.0, 2.0, 4.0])  // 1.714
rms := statutils.stats_rms([3.0, 4.0])                       // 3.535

// Weighted Mean
weights := [1.0, 2.0, 3.0, 1.0, 2.0, 1.0, 1.0]
w_mean := statutils.stats_weighted_mean(dataset, weights)!

// Trimmed Mean (discards 10% from lower and upper bounds)
t_mean := statutils.stats_trimmed_mean(dataset, 0.1)!
```

---

### 2. Measures of Dispersion & Spread

```v
import statutils

dataset := [10.0, 20.0, 20.0, 30.0, 40.0, 50.0, 90.0]

// Min, Max & Range
min_val := statutils.stats_min(dataset) or { 0.0 }    // 10.00
max_val := statutils.stats_max(dataset) or { 0.0 }    // 90.00
span := statutils.stats_range(dataset)                // 80.00

// Population Variance & Standard Deviation (N)
pop_var := statutils.stats_variance(dataset)
pop_std := statutils.stats_std_dev(dataset)

// Sample Variance & Sample Standard Deviation (N - 1, Bessel's Correction)
sample_var := statutils.stats_sample_variance(dataset)
sample_std := statutils.stats_sample_std_dev(dataset)

// Standard Error of the Mean (SEM = sample_std / sqrt(N))
sem := statutils.stats_standard_error(dataset)

// Quantiles & Interquartile Range
p50 := statutils.stats_percentile(dataset, 50.0)      // 30.00
p95 := statutils.stats_percentile(dataset, 95.0)      // 78.00
q1, q2, q3 := statutils.stats_quartiles(dataset)      // Q1 (25%), Q2 (50%), Q3 (75%)
iqr := statutils.stats_iqr(dataset)                   // Q3 - Q1

// Relative Dispersion
cov := statutils.stats_coefficient_of_variation(dataset) // std_dev / mean
mad := statutils.stats_median_abs_deviation(dataset)     // Median Absolute Deviation
```

---

### 3. Distribution Shape (Higher Moments)

```v
import statutils

dataset := [10.0, 20.0, 20.0, 30.0, 40.0, 50.0, 90.0]

// Skewness: measures distribution asymmetry (0 = symmetric, >0 right-skewed, <0 left-skewed)
skew := statutils.stats_skewness(dataset)

// Excess Kurtosis: measures tailedness relative to normal distribution (0 = normal, >0 leptokurtic)
kurt := statutils.stats_kurtosis(dataset)
```

---

### 4. Bivariate Analysis: Correlation & Linear Regression

```v
import statutils

x := [1.0, 2.0, 3.0, 4.0, 5.0]
y := [2.1, 4.0, 5.9, 8.1, 10.2]

// Population and Sample Covariance
cov := statutils.stats_covariance(x, y)!
sample_cov := statutils.stats_sample_covariance(x, y)!

// Pearson Linear Correlation Coefficient r (-1.0 to 1.0)
pearson_r := statutils.stats_pearson_correlation(x, y)!

// Spearman Rank Correlation Coefficient r_s
spearman_r := statutils.stats_spearman_correlation(x, y)!

// Ordinary Least Squares (OLS) Linear Regression: y = slope * x + intercept
reg := statutils.stats_linear_regression(x, y)! // returns statutils.LinearRegressionResult
println('Slope: ${reg.slope:.4f}')
println('Intercept: ${reg.intercept:.4f}')
println('R² (Coefficient of Determination): ${reg.r_squared:.4f}')
println('Correlation: ${reg.correlation:.4f}')
```

---

### 5. Probability Distributions & Normalization

```v
import statutils

// Normal (Gaussian) Probability Density Function (PDF) & Cumulative Distribution (CDF)
pdf := statutils.stats_normal_pdf(1.96, 0.0, 1.0) // Density at z = 1.96
cdf := statutils.stats_normal_cdf(1.96, 0.0, 1.0) // ~0.975 (97.5% cumulative probability)

// Z-Scores (Standardization)
single_z := statutils.stats_z_score(15.0, 10.0, 2.5) // 2.0
standardized_data := statutils.stats_z_scores([10.0, 20.0, 30.0])

// Min-Max Normalization (scales values to [0.0, 1.0])
normalized := statutils.stats_min_max_normalize([10.0, 20.0, 30.0]) // [0.0, 0.5, 1.0]
```

---

### 6. Outlier Detection

```v
import statutils

data := [10.0, 11.0, 11.5, 12.0, 10.5, 12.5, 105.0]

// Detect outliers using Tukey's IQR Fences (multiplier typically 1.5)
iqr_outliers := statutils.stats_outliers_iqr(data, 1.5)
println('IQR Outliers: ${iqr_outliers}') // [105.0]

// Detect outliers using Z-Score threshold (typically |z| > 3.0)
z_outliers := statutils.stats_outliers_z_score(data, 3.0)
println('Z Outliers: ${z_outliers}')
```

---

### 7. Time Series & Smoothing

```v
import statutils

series := [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0]

// Simple Moving Average (SMA) over window size
sma := statutils.stats_moving_average(series, 3)!
// Output: [2.0, 3.0, 4.0, 5.0, 6.0, 7.0]

// Exponential Moving Average (EMA) with smoothing factor alpha
ema := statutils.stats_exponential_moving_average(series, 0.3)!
```

---

### 8. Comprehensive Summary Profile (`SummaryStats`)

```v
import statutils

data := [12.0, 15.0, 18.0, 20.0, 22.0, 25.0, 30.0, 45.0, 45.0, 50.0]

// Single-call calculation of 17 descriptive statistical metrics
summary := statutils.stats_summary(data) // returns statutils.SummaryStats
println('Count:           ${summary.count}')
println('Min / Max:       ${summary.min} / ${summary.max}')
println('Range:           ${summary.range}')
println('Sum:             ${summary.sum}')
println('Mean / Median:   ${summary.mean:.2f} / ${summary.median:.2f}')
println('Sample StdDev:   ${summary.sample_std_dev:.2f}')
println('Std Error (SEM): ${summary.sem:.2f}')
println('Quartiles:       Q1=${summary.q1:.2f}, Q3=${summary.q3:.2f}, IQR=${summary.iqr:.2f}')
println('Skewness:        ${summary.skewness:.2f}')
println('Excess Kurtosis: ${summary.kurtosis:.2f}')
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="stateutils"></a><a id="stateutils-api"></a>

# stateutils API

**Plain-language purpose:** Use these tools to remember an app's choices between runs, such as a theme, volume, or window size. The examples show both a named data record and flexible key-value settings, saved safely to the standard app-data location.

Import statement:

```v
import stateutils
```

### OS-Recommended Path Resolution

#### `get_app_dir(app_name string, loc StateLocation) string`

Returns the OS-recommended directory for an application:

- **macOS**: `~/Library/Application Support/<app_name>`
- **Windows**: `%APPDATA%\<app_name>`
- **Linux / BSD**: `$XDG_DATA_HOME/<app_name>` (fallback `~/.local/share/<app_name>`)
  Automatically creates the directory structure if missing.

```v
import stateutils

data_dir := stateutils.get_app_dir('my_app', .data)
config_dir := stateutils.get_app_dir('my_app', .config)
println('App data dir: ${data_dir}')
```

#### `get_state_path(app_name string, filename string, loc StateLocation) string`

Resolves the complete absolute path for a state file in the recommended directory.

```v
import stateutils

path := stateutils.get_state_path('my_app', 'state.json', .data)
println('State file path: ${path}')
```

---

### Direct State Functions

#### `save_app_state[T](app_name string, filename string, state T) !`

Atomically serializes and persists a struct to disk without risk of file corruption if interrupted.

```v
import stateutils

struct UserPrefs {
    theme string
    sound bool
}

stateutils.save_app_state('my_app', 'prefs.json', UserPrefs{ theme: 'dark', sound: true })!
```

#### `load_app_state[T](app_name string, filename string) !T`

Loads and deserializes a struct from the recommended app data path.

```v
import stateutils

struct UserPrefs {
    theme string
    sound bool
}

prefs := stateutils.load_app_state[UserPrefs]('my_app', 'prefs.json')!
println('Loaded theme: ${prefs.theme}')
```

#### `load_app_state_or[T](app_name string, filename string, default_val T) T`

Loads state if available, or gracefully falls back to `default_val` on error or missing file.

```v
import stateutils

struct UserPrefs {
    theme string
    sound bool
}

prefs := stateutils.load_app_state_or('my_app', 'prefs.json', UserPrefs{ theme: 'system', sound: false })
println('Loaded theme: ${prefs.theme}')
```

#### `app_state_exists(app_name string, filename string) bool` & `delete_app_state(app_name string, filename string) !`

Checks for the presence of a state file or removes it.

```v
import stateutils

if stateutils.app_state_exists('my_app', 'prefs.json') {
    stateutils.delete_app_state('my_app', 'prefs.json')!
}
```

---

### `AppStateStore[T]` - Managed Generic Store

Manages in-memory state, atomic disk persistence, auto-saving, backups, and rollback. Created via `new_app_state` (default `state.json` in `.data`) or `new_app_state_with_file` for custom state filenames or `.config` locations.

```v
import stateutils

struct Settings {
pub mut:
    window_w     int
    window_h     int
    theme        string
    recent_files []string
}

// Default state store (state.json in OS data dir)
mut store := stateutils.new_app_state[Settings]('my_app', Settings{
    window_w: 1280
    window_h: 720
    theme:    'dark'
})

// Or custom filename & directory location:
mut custom_store := stateutils.new_app_state_with_file[Settings]('my_app', 'workspace.json', Settings{}, .config)

// Access current state
println('Window width: ${store.get().window_w}')

// Modify state via updater callback
store.update(fn (mut s Settings) {
    s.window_w = 1920
    s.theme = 'dracula'
    s.recent_files << 'main.v'
})!
store.save()! // persists atomically

// Backup & Rollback
bak_file := store.backup()! // saves ${path}.bak
store.set(Settings{ window_w: 800, window_h: 600, theme: 'light' })!
store.rollback()! // reverts from .bak

// Auto-save mode (automatically persists whenever state changes)
store.auto_save = true
store.update(fn (mut s Settings) {
    s.theme = 'solarized'
})! // automatically saved to disk
```

---

### `KeyValueState` - Dynamic App State

For apps that need schema-free configuration and preferences. Created via `new_kv_state` or `new_kv_state_with_file`.

```v
import stateutils

mut kv := stateutils.new_kv_state('my_app')
kv.auto_save = true

// Or custom file/location:
mut custom_kv := stateutils.new_kv_state_with_file('my_app', 'tokens.json', .config)

// Typed setters & getters with fallbacks
kv.set_str('current_profile', 'guest')!
kv.set_int('volume', 85)!
kv.set_bool('notifications', true)!
kv.set_f64('scale', 1.5)!

profile := kv.get_str('current_profile', 'default')
volume  := kv.get_int('volume', 100)
notify  := kv.get_bool('notifications', false)
scale   := kv.get_f64('scale', 1.0)

// Management
println('Has volume: ${kv.has("volume")}')
kv.delete('scale')!
keys := kv.keys()
all_data := kv.all()

kv.clear()!
kv.reset()! // clears memory and deletes state file from disk
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="cacheutils"></a><a id="cacheutils-api"></a>

# cacheutils API

**Plain-language purpose:** Use these tools to temporarily keep frequently used results in memory so repeat work is faster. The examples show two rules for discarding old data: least recently used and a fixed time limit.

Import statement:

```v
import cacheutils
import time
```

High-performance, in-memory caching data structures featuring O(1) Least-Recently-Used (LRU) evictions and entry-level Time-To-Live (TTL) expiration policies.

<a id="1-lru-least-recently-used-cache"></a>

## 1. LRU (Least-Recently-Used) Cache

### `LRUCache[T]`

Fixed-capacity generic in-memory cache that automatically discards the least-recently used items when capacity is reached.

### `new_lru[T](capacity int) !LRUCache[T]`

Initializes a new `LRUCache[T]` with a fixed capacity limit. Capacity must be greater than 0.

```v
import cacheutils

// Create an LRU cache holding up to 3 strings
mut cache := cacheutils.new_lru[string](3)!

// Insert items
cache.set('user:1', 'Alice')
cache.set('user:2', 'Bob')
cache.set('user:3', 'Charlie')

// Accessing 'user:1' refreshes its recency
println(cache.get('user:1') or { 'not found' }) // "Alice"

// Adding a 4th item evicts the oldest ('user:2')
cache.set('user:4', 'Diana')

println(cache.has('user:2')) // false (evicted)
println(cache.has('user:1')) // true
println('Total items in cache: ${cache.len()}') // 3

// Delete an item manually
cache.delete('user:3')

// Clear the entire cache
cache.clear()
```

---

### `get_or_set_lru[T](mut cache LRUCache[T], key string, fetcher fn () !T) !T`

Convenience helper that retrieves a value from the LRU cache if present, or calls `fetcher()` to compute, store, and return it.

```v
import cacheutils

mut user_cache := cacheutils.new_lru[string](100)!

// Expensive computation runs only on cache miss
val := cacheutils.get_or_set_lru[string](mut user_cache, 'config:profile', fn () !string {
    println('Computing expensive profile config...')
    return '{"theme":"dark","lang":"v"}'
})!

println('Retrieved: ${val}')
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="2-ttl-time-to-live-cache"></a>

## 2. TTL (Time-To-Live) Cache

### `TTLCache[T]`

Generic cache where each entry carries an expiration timestamp. Expired items are ignored upon lookup, lazily removed, or purged via periodic sweeps.

### `new_ttl[T](default_ttl time.Duration) TTLCache[T]`

Initializes a new `TTLCache[T]` with a default expiration duration.

```v
import cacheutils
import time

// Create a TTL cache where entries default to expiring after 5 seconds
mut cache := cacheutils.new_ttl[string](5 * time.second)

// Set with default TTL
cache.set('session:token', 'abc123xyz')

// Set with custom individual TTL (e.g. 1 hour)
cache.set_with_ttl('remember_me', 'persistent_cookie', 1 * time.hour)

// Retrieve active item
if token := cache.get('session:token') {
    println('Active session: ${token}')
}

// Check key existence
if cache.has('remember_me') {
    println('Remember me token is still valid')
}

// Sweep and clean up any expired entries
purged := cache.cleanup_expired()
println('Purged ${purged} expired entries')

// Remove entry
cache.delete('session:token')

// Clear all items
cache.clear()
```

---

### `get_or_set_ttl[T](mut cache TTLCache[T], key string, fetcher fn () !T) !T`

Retrieves a cached value or executes `fetcher()` to populate the TTL cache if missing or expired.

```v
import cacheutils
import time

mut api_cache := cacheutils.new_ttl[string](60 * time.second)

data := cacheutils.get_or_set_ttl[string](mut api_cache, 'api:rates', fn () !string {
    println('Fetching live exchange rates from remote API...')
    return '{"USD": 1.0, "EUR": 0.92}'
})!

println('Rates: ${data}')
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="semverutils"></a><a id="semverutils-api"></a>

# semverutils API

**Plain-language purpose:** Use these tools to understand software version labels such as `1.4.2`, compare releases, and decide whether a version matches a requirement. The examples break a version into its meaningful parts before making a decision.

Import statement:

```v
import semverutils
```

Complete semantic version parsing, comparison, and range requirement matching conforming strictly to the [SemVer 2.0.0](https://semver.org/) specification.

<a id="semverutils-data-structures"></a>

## Data Structures

### `SemVer`

Represents a parsed semantic version:

- `major`: int
- `minor`: int
- `patch`: int
- `prerelease`: string (e.g. `alpha.1`, `beta`, `rc.2`)
- `build`: string (e.g. `build.2026`, `sha.123abc`)

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="semverutils-functions--methods"></a><a id="semverutils-functions-methods"></a>

## Functions & Methods

### `parse(raw string) !SemVer`

Parses a semantic version string into a `SemVer` struct. Supports leading `'v'` or `'V'`.

```v
import semverutils

ver := semverutils.parse('v2.1.0-beta.3+build.2026')!
println('Major: ${ver.major}')       // 2
println('Minor: ${ver.minor}')       // 1
println('Patch: ${ver.patch}')       // 0
println('Prerelease: ${ver.prerelease}') // "beta.3"
println('Build: ${ver.build}')           // "build.2026"
println('Standard string: ${ver.str()}') // "2.1.0-beta.3+build.2026"
```

---

### `compare(a SemVer, b SemVer) int`

Compares two versions according to SemVer 2.0.0 precedence rules. Returns `-1` if `a < b`, `0` if `a == b`, and `1` if `a > b`. Build metadata is ignored per SemVer 2.0.0 spec.

```v
import semverutils

v1 := semverutils.parse('1.0.0')!
v2 := semverutils.parse('1.0.0-alpha')!

cmp := semverutils.compare(v1, v2)
println(cmp) // 1 (1.0.0 is newer than 1.0.0-alpha)
```

---

### `is_newer(a string, b string) !bool`

Returns true if version string `a` is strictly newer than version string `b`.

```v
import semverutils

println(semverutils.is_newer('2.0.0', '1.9.9')!) // true
println(semverutils.is_newer('1.0.0-rc.1', '1.0.0')!) // false
```

---

### Version Bumping Helpers

- `bump_major(s SemVer) SemVer`: Increments major, resets minor & patch to 0, clears prerelease & build.
- `bump_minor(s SemVer) SemVer`: Increments minor, resets patch to 0, clears prerelease & build.
- `bump_patch(s SemVer) SemVer`: Increments patch, clears prerelease & build.
- `bump_prerelease(s SemVer, tag string) SemVer`: Updates the prerelease identifier.

```v
import semverutils

base := semverutils.parse('1.2.3')!

v_patch := semverutils.bump_patch(base)
println(v_patch.str()) // "1.2.4"

v_minor := semverutils.bump_minor(base)
println(v_minor.str()) // "1.3.0"

v_major := semverutils.bump_major(base)
println(v_major.str()) // "2.0.0"

v_pre := semverutils.bump_prerelease(base, 'beta.1')
println(v_pre.str()) // "1.2.3-beta.1"
```

---

### `satisfies(ver SemVer, requirement string) !bool`

Tests whether a `SemVer` satisfies a version range requirement. Supports:

- Caret ranges (`^1.2.3`): Compatible non-breaking updates within the major version.
- Tilde ranges (`~1.2.3`): Patch-level updates within the minor version.
- Comparisons: `>=`, `<=`, `>`, `<`, `=`
- Compound expressions: `>=1.0.0 <2.0.0`
- Wildcards: `*`

```v
import semverutils

v := semverutils.parse('1.2.4')!

println(semverutils.satisfies(v, '^1.2.0')!) // true (compatible with 1.x)
println(semverutils.satisfies(v, '~1.2.0')!) // true (patch update on 1.2.x)
println(semverutils.satisfies(v, '>=1.0.0 <2.0.0')!) // true
println(semverutils.satisfies(v, '^2.0.0')!) // false
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="flowutils"></a><a id="flowutils-api"></a>

# flowutils API

**Plain-language purpose:** Use these tools to keep a program calm under pressure: limit repeated actions, retry temporary failures, avoid repeatedly calling a broken service, and wait until rapid changes settle down.

Import statement:

```v
import flowutils
import time
```

Resilience and traffic control primitives: Token Bucket rate limiting, Circuit Breaker state machine, exponential backoff retries, and call debouncing.

<a id="1-rate-limiting-token-bucket"></a>

## 1. Rate Limiting (Token Bucket)

### `RateLimiter`

Token Bucket rate limiter for managing bursty traffic and enforcing requests-per-second thresholds.

### `new_rate_limiter(capacity int, refill_rate_per_sec f64) !RateLimiter`

Initializes a rate limiter with a maximum token bucket capacity and a refill rate in tokens per second.

```v
import flowutils
import time

// Allow up to 10 tokens burst, refilling at 2 tokens per second
mut limiter := flowutils.new_rate_limiter(10, 2.0)!

// Consume 1 token
if limiter.allow() {
    println('Request permitted!')
}

// Consume multiple tokens (e.g. 5 tokens for a batch job)
if limiter.allow_n(5) {
    println('Batch job permitted!')
} else {
    println('Rate limit exceeded for batch job')
}

// Inspect available token pool
println('Available tokens: ${limiter.available_tokens():.2f}')

// Block execution until 1 token is ready
limiter.wait()!

// Reset token bucket back to full capacity
limiter.reset()
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="2-circuit-breaker"></a>

## 2. Circuit Breaker

### `CircuitBreaker`

3-state failure protection barrier (`closed` -> `open` -> `half_open`) preventing cascading downtime across microservices and external APIs.

### `new_circuit_breaker(failure_threshold int, recovery_timeout time.Duration) !CircuitBreaker`

Creates a circuit breaker that trips to `open` after `failure_threshold` consecutive errors, remaining open for `recovery_timeout` before allowing trial probe requests in `half_open` state.

```v
import flowutils
import time

mut cb := flowutils.new_circuit_breaker(3, 5 * time.second)!

// Check if execution is permitted
if cb.can_execute() {
    // Attempt remote network call
    success := true // simulate network call
    if success {
        cb.record_success()
    } else {
        cb.record_failure()
    }
} else {
    println('Circuit is OPEN! Fast failing request.')
}

// Inspect breaker status
println('Circuit is closed (healthy): ${cb.is_closed()}')
println('Circuit is open (tripped): ${cb.is_open()}')
println('State: ${cb.get_state()}') // .closed, .open, or .half_open

// Manually reset breaker
cb.reset()
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="3-exponential-backoff-retry"></a>

## 3. Exponential Backoff Retry

### `retry[T](attempts int, base_delay time.Duration, factor f64, max_delay time.Duration, action fn () !T) !T`

Executes `action` repeatedly with exponentially increasing delays until it succeeds or exhausts `attempts`.

```v
import flowutils
import time

// Retry up to 4 times, starting with 50ms delay, multiplying by 2.0, capped at 1s
res := flowutils.retry[string](4, 50 * time.millisecond, 2.0, 1 * time.second, fn () !string {
    // Perform transient network request
    return 'Fetched payload successfully'
})!

println(res)
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="4-debouncer"></a>

## 4. Debouncer

### `Debouncer`

Rate limits high-frequency events (e.g. keypresses, file change notifications) by ensuring a minimum delay between executions.

### `new_debouncer(delay time.Duration) Debouncer`

Creates a debouncer requiring `delay` duration of inactivity before `can_trigger()` returns true again.

```v
import flowutils
import time

mut debouncer := flowutils.new_debouncer(250 * time.millisecond)

// In an event loop or keypress listener:
if debouncer.can_trigger() {
    println('Executing debounced action (e.g. search query)')
} else {
    println('Ignored rapid subsequent trigger')
}

// Reset timer
debouncer.reset()
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="templateutils"></a><a id="templateutils-api"></a>

# templateutils API

**Plain-language purpose:** Use these tools to fill a reusable piece of text with your own names, dates, and values. The examples start with a message containing placeholders and show how a completed message is produced.

Import statement:

```v
import templateutils
```

Fast, lightweight string templating with fallback default values, custom resolver callbacks, and ANSI markdown rendering for terminal interfaces.

<a id="templateutils-functions"></a>

## Functions

### `render_template(tpl string, vars map[string]string) string`

Renders `{{key}}` and `{{key | default}}` placeholders using a dictionary of string values. If a key is missing and has no default specified, the placeholder remains untouched.

```v
import templateutils

tpl := 'Hello {{name}}! Welcome to {{app | Antigravity IDE}} on {{os}}.'
vars := {
    'name': 'Alice'
    'os':   'macOS'
}

rendered := templateutils.render_template(tpl, vars)
println(rendered) // "Hello Alice! Welcome to Antigravity IDE on macOS."
```

---

### `render_template_fn(tpl string, resolver fn (key string) ?string) string`

Renders placeholders dynamically using a callback function. Supports fallback defaults if the resolver returns `none`.

```v
import templateutils
import os

tpl := 'Running user: {{USER | unknown}}, Path: {{HOME}}'

rendered := templateutils.render_template_fn(tpl, fn (key string) ?string {
    val := os.getenv(key)
    if val.len > 0 {
        return val
    }
    return none
})

println(rendered)
```

---

### `render_markdown_ansi(markdown string) string`

Renders CommonMark markdown subsets into styled ANSI terminal output, transforming:

- Headings (`#`, `##`, `###`) into bold underlined headers
- `**bold**` into bold ANSI text
- `*italic*` into italic ANSI text
- `` `code` `` into inverted/colored code text
- Code fences (` ``` `) into indented blocks
- Blockquotes (`> `) into styled callout quotes
- Bullet lists (`- ` or `* `) into clean bullet markers

````v
import templateutils

md := '# Installation Guide\nTo install `vlang_utils`, run:\n```\nv install codecaine.vlang_utils\n```\n> **Note:** Requires V 0.4+.'

println(templateutils.render_markdown_ansi(md))
````

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="colorutils"></a><a id="colorutils-api"></a>

# colorutils API

**Plain-language purpose:** Use these tools to convert between color formats, choose related colors, and check whether text is easy to read against its background. The examples use familiar hexadecimal color codes such as `#ff0000` for red.

Import statement:

```v
import colorutils
```

Comprehensive color conversions (HEX, RGB, HSL), color theory transformations (lighten, darken, invert, blend, grayscale), WCAG 2.1 accessibility auditing (relative luminance, contrast ratio, AA/AAA compliance), and 24-bit truecolor ANSI terminal styling.

<a id="colorutils-data-structures"></a>

## Data Structures

### `RGB`

Represents an 8-bit per channel Red-Green-Blue color:

- `r`: u8
- `g`: u8
- `b`: u8
- `(c RGB) hex() string`: Formats color as lowercase `#rrggbb`.
- `(c RGB) str() string`: Formats color as `rgb(r, g, b)`.

### `HSL`

Represents Hue (0.0 to 360.0°), Saturation (0.0 to 1.0), and Lightness (0.0 to 1.0):

- `h`: f64
- `s`: f64
- `l`: f64
- `(c HSL) str() string`: Formats color as `hsl(h, s%, l%)`.

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="1-color-space-conversions"></a>

## 1. Color Space Conversions

### `hex_to_rgb(hex_str string) !RGB`

Parses 3-character or 6-character hex strings (with or without `#`).

```v
import colorutils

c1 := colorutils.hex_to_rgb('#007acc')!
println('R=${c1.r}, G=${c1.g}, B=${c1.b}') // R=0, G=122, B=204

c2 := colorutils.hex_to_rgb('f0a')! // Short form #ff00aa
println(c2.hex()) // "#ff00aa"
```

---

### `rgb_to_hex(c RGB) string`

Formats an RGB struct into a lowercase hex string.

```v
import colorutils

hex := colorutils.rgb_to_hex(colorutils.RGB{255, 128, 0})
println(hex) // "#ff8000"
```

---

### `rgb_to_hsl(c RGB) HSL` & `hsl_to_rgb(hsl HSL) RGB`

Bidirectional lossless conversion between RGB and HSL color spaces.

```v
import colorutils

rgb := colorutils.RGB{255, 0, 0} // Pure Red
hsl := colorutils.rgb_to_hsl(rgb)
println('Hue: ${hsl.h}°, Saturation: ${hsl.s * 100}%, Lightness: ${hsl.l * 100}%') // 0°, 100%, 50%

back_rgb := colorutils.hsl_to_rgb(hsl)
println(back_rgb.str()) // "rgb(255, 0, 0)"
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="2-color-transformations--harmonies"></a><a id="2-color-transformations-harmonies"></a>

## 2. Color Transformations & Harmonies

### `lighten(c RGB, percent f64) RGB` & `darken(c RGB, percent f64) RGB`

Adjusts color lightness by a percentage from `0.0` to `1.0`.

```v
import colorutils

blue := colorutils.RGB{0, 100, 200}
lighter := colorutils.lighten(blue, 0.2) // 20% lighter
darker  := colorutils.darken(blue, 0.2)  // 20% darker
```

---

### `invert(c RGB) RGB`

Computes the inverted / photographic negative of an RGB color.

```v
import colorutils

white := colorutils.RGB{255, 255, 255}
black := colorutils.invert(white) // RGB{0, 0, 0}
```

---

### `blend(c1 RGB, c2 RGB, factor f64) RGB`

Linearly interpolates between two colors with a factor from `0.0` (`c1`) to `1.0` (`c2`).

```v
import colorutils

red := colorutils.RGB{255, 0, 0}
blue := colorutils.RGB{0, 0, 255}
purple := colorutils.blend(red, blue, 0.5) // Halfway blend
```

---

### `grayscale(c RGB) RGB`

Converts an RGB color to perceptually weighted grayscale using ITU-R BT.601 luminance coefficients.

```v
import colorutils

c := colorutils.RGB{255, 200, 50}
gray := colorutils.grayscale(c)
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="3-wcag-21-accessibility--contrast"></a><a id="3-wcag-21-accessibility-contrast"></a>

## 3. WCAG 2.1 Accessibility & Contrast

### `luminance(c RGB) f64`

Calculates relative luminance according to the WCAG 2.1 standard (returns `0.0` for black to `1.0` for white).

```v
import colorutils

lum := colorutils.luminance(colorutils.RGB{255, 255, 255})
println('Luminance: ${lum}') // 1.0
```

---

### `contrast_ratio(c1 RGB, c2 RGB) f64`

Computes the WCAG contrast ratio between two colors (ranging from `1.0:1` to `21.0:1`).

```v
import colorutils

black := colorutils.RGB{0, 0, 0}
white := colorutils.RGB{255, 255, 255}
ratio := colorutils.contrast_ratio(black, white)
println('Contrast: ${ratio:.1f}:1') // "Contrast: 21.0:1"
```

---

### `is_accessible(foreground RGB, background RGB, level string) bool`

Audits whether foreground and background colors meet WCAG contrast thresholds:

- `"AA"`: Standard text (minimum ratio 4.5:1)
- `"AAA"`: Enhanced contrast (minimum ratio 7.0:1)
- `"AA_large"`: Large text and UI graphics (minimum ratio 3.0:1)

```v
import colorutils

bg := colorutils.RGB{255, 255, 255} // White
fg := colorutils.RGB{0, 122, 204}   // Blue

println('Meets AA standard text: ${colorutils.is_accessible(fg, bg, "AA")}')
println('Meets AAA enhanced text: ${colorutils.is_accessible(fg, bg, "AAA")}')
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="4-terminal-truecolor-24-bit-ansi-formatting"></a>

## 4. Terminal Truecolor (24-bit ANSI) Formatting

### `fg_rgb(text string, c RGB) string` & `bg_rgb(text string, c RGB) string`

Formats text with 24-bit Truecolor ANSI terminal escape sequences.

```v
import colorutils

brand_color := colorutils.RGB{255, 107, 107}
white := colorutils.RGB{255, 255, 255}

// 24-bit truecolor text
styled_text := colorutils.fg_rgb('Hello Vibrant World!', brand_color)
println(styled_text)

// Combined foreground and background
badge := colorutils.bg_rgb(colorutils.fg_rgb(' SUCCESS ', white), colorutils.RGB{46, 204, 113})
println(badge)
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="archiveutils"></a><a id="archiveutils-api"></a>

# archiveutils API

**Plain-language purpose:** Use these tools to put files into a ZIP archive or unpack a ZIP archive later. The examples distinguish between creating an archive, seeing what is inside it, and restoring files to a folder.

Import statement:

```v
import archiveutils
```

Ergonomic Zip archive creation, extraction, recursive directory bundling, and in-memory file inspection built directly on V's native `compress.szip` engine.

<a id="archiveutils-data-structures"></a>

## Data Structures

### `ZipEntry`

Represents an individual file or directory entry inside a zip archive:

- `name`: string
- `size`: u64
- `is_dir`: bool
- `crc32`: u32

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="archiveutils-functions"></a>

## Functions

### `is_valid_zip(path string) bool`

Tests whether a file exists and starts with standard ZIP magic bytes (`PK\x03\x04` or `PK\x05\x06`).

```v
import archiveutils

if archiveutils.is_valid_zip('data/backup.zip') {
    println('Valid zip archive confirmed!')
}
```

---

### `zip_file(source_file string, dest_zip string) !` & `zip_files(source_files []string, dest_zip string) !`

Compresses one or more files into a single zip archive. Automatically creates any missing destination directories.

```v
import archiveutils

// Compress a single file
archiveutils.zip_file('logs/app.log', 'backups/log.zip')!

// Compress multiple files
archiveutils.zip_files(['src/main.v', 'v.mod', 'README.md'], 'dist/source.zip')!
```

---

### `zip_dir(source_dir string, dest_zip string) !`

Recursively bundles an entire directory tree into a zip archive with relative path preserves.

```v
import archiveutils

archiveutils.zip_dir('assets/images', 'dist/images_bundle.zip')!
```

---

### `unzip_to_dir(zip_file string, dest_dir string) !`

Extracts all entries from a zip archive into a destination directory.

```v
import archiveutils

archiveutils.unzip_to_dir('dist/images_bundle.zip', 'extracted/images')!
```

---

### `list_entries(zip_file string) ![]ZipEntry`

Inspects the internal contents of a zip archive without extracting files to disk.

```v
import archiveutils

entries := archiveutils.list_entries('dist/source.zip')!
println('Found ${entries.len} entries:')
for entry in entries {
    type_str := if entry.is_dir { 'DIR ' } else { 'FILE' }
    println('- [${type_str}] ${entry.name} (${entry.size} bytes)')
}
```

---

### `read_entry_bytes(zip_file string, entry_name string) ![]u8` & `read_entry_string(zip_file string, entry_name string) !string`

Reads a specific file from inside a zip archive directly into memory as bytes or a string without extracting to disk.

```v
import archiveutils

// Read file directly from zip into memory
text := archiveutils.read_entry_string('dist/source.zip', 'README.md')!
println('Readme preview:\n${text[..100]}...')
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="asyncutils"></a><a id="asyncutils-api"></a>

# asyncutils API

**Plain-language purpose:** Use these tools to let several independent jobs happen at the same time, such as processing many files. The examples show the work to do, wait until it finishes, and keep results in a predictable order.

Import statement:

```v
import asyncutils
import time
```

High-throughput, deterministic concurrency abstractions: order-preserving parallel collections (`parallel_map`, `parallel_filter`, `parallel_each`), `WaitGroup` synchronization, and bounded `WorkerPool`.

<a id="1-parallel-collections"></a>

## 1. Parallel Collections

### `parallel_map[T, R](items []T, worker_count int, mapper fn (T) R) []R`

Concurrently transforms a slice of items using up to `worker_count` background threads, guaranteeing that output results retain the exact index order of the inputs.

```v
import asyncutils

numbers := [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

// Process with 4 parallel worker threads
squares := asyncutils.parallel_map[int, int](numbers, 4, fn (n int) int {
    return n * n
})

println(squares) // [1, 4, 9, 16, 25, 36, 49, 64, 81, 100]
```

---

### `parallel_filter[T](items []T, worker_count int, predicate fn (T) bool) []T`

Concurrently evaluates a predicate on each element, preserving the original array order of matching elements.

```v
import asyncutils

words := ['apple', 'cat', 'banana', 'dog', 'elephant', 'fox']

long_words := asyncutils.parallel_filter[string](words, 3, fn (w string) bool {
    return w.len > 3
})

println(long_words) // ['apple', 'banana', 'elephant']
```

---

### `parallel_each[T](items []T, worker_count int, action fn (T))`

Executes a side-effecting action concurrently across items across up to `worker_count` threads.

```v
import asyncutils

urls := ['https://api1.local', 'https://api2.local', 'https://api3.local']

asyncutils.parallel_each[string](urls, 3, fn (url string) {
    println('Polling endpoint: ${url}')
})
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="2-waitgroup-synchronization"></a>

## 2. WaitGroup Synchronization

### `WaitGroup`

Lightweight thread synchronization barrier.

### `new_waitgroup() &WaitGroup`

Creates and heap-allocates a new `WaitGroup`.

```v
import asyncutils
import time

mut wg := asyncutils.new_waitgroup()

for i in 0 .. 3 {
    wg.add(1)
    spawn fn (mut wg asyncutils.WaitGroup, id int) {
        defer { wg.done() }
        time.sleep(50 * time.millisecond)
        println('Worker ${id} finished')
    }(mut wg, i + 1)
}

// Block until all 3 workers call wg.done()
wg.wait()
println('All tasks completed!')
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="3-worker-pool"></a>

## 3. Worker Pool

### `WorkerPool`

Dispatches arbitrary tasks across a fixed number of worker threads via a bounded channel.

### `new_worker_pool(worker_count int, queue_size int) !&WorkerPool`

Initializes a pool with `worker_count` worker threads and a bounded task queue.

```v
import asyncutils
import time

mut pool := asyncutils.new_worker_pool(4, 32)!
defer { pool.stop() }

// Submit jobs to the pool
for i in 0 .. 10 {
    pool.submit(fn [i] () {
        println('Processing job #${i}')
        time.sleep(10 * time.millisecond)
    })!
}

// Wait for all queued tasks to finish
pool.wait_all()
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="regexutils"></a><a id="regexutils-api"></a>

# regexutils API

**Plain-language purpose:** Use these tools to find, check, split, or replace patterns inside text. A pattern is a compact search rule; the examples pair each rule with ordinary sample text so you can see what it matches.

Import statement:

```v
import regexutils
```

Ergonomic, high-level regular expression helpers eliminating boilerplate around regex queries, group indexes, and match boundaries.

<a id="regexutils-data-structures"></a>

## Data Structures

### `Match`

Represents a matched substring and its span:

- `text`: string
- `start`: int
- `end`: int

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="regexutils-functions"></a>

## Functions

### `is_match(pattern string, text string) bool`

Returns true if the entire string strictly matches the regular expression.

```v
import regexutils

println(regexutils.is_match(r'^\d+$', '12345')) // true
println(regexutils.is_match(r'^\d+$', '123a5')) // false
```

---

### `contains_match(pattern string, text string) bool`

Returns true if the regular expression pattern matches any substring within text.

```v
import regexutils

println(regexutils.contains_match(r'\d+', 'Order ID: 48291')) // true
```

---

### `find_first(pattern string, text string) ?string`

Returns the first matching substring, or `none` if no match exists.

```v
import regexutils

match_str := regexutils.find_first(r'\d+', 'Total: 450 items') or { 'none' }
println(match_str) // "450"
```

---

### `find_all(pattern string, text string) []string`

Returns an array of all matching substrings.

```v
import regexutils

numbers := regexutils.find_all(r'\d+', 'Call 800-555-0199 or 415-555-0122')
println(numbers) // ['800', '555', '0199', '415', '555', '0122']
```

---

### `find_matches(pattern string, text string) []Match`

Returns all matches including their starting and ending byte offsets.

```v
import regexutils

matches := regexutils.find_matches(r'[A-Z][a-z]+', 'Alice and Bob went to Paris')
for m in matches {
    println('Found "${m.text}" at indices [${m.start}..${m.end}]')
}
```

---

### `replace(pattern string, text string, repl string) string` & `replace_n(pattern string, text string, repl string, count int) string`

Substitutes matched substrings with replacement text.

```v
import regexutils

// Replace all digits
masked := regexutils.replace(r'\d', 'Pin: 1234', '*')
println(masked) // "Pin: ****"

// Replace up to 2 occurrences
partial := regexutils.replace_n(r'\d+', '10 20 30 40', 'X', 2)
println(partial) // "X X 30 40"
```

---

### `split(pattern string, text string) []string`

Splits a string by occurrences of a regular expression pattern.

```v
import regexutils

parts := regexutils.split(r'\s*,\s*', 'apple, banana , cherry,date')
println(parts) // ['apple', 'banana', 'cherry', 'date']
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="mockutils"></a><a id="mockutils-api"></a>

# mockutils API

**Plain-language purpose:** Use these tools to make believable sample names, emails, addresses, and other test data without using real people's information. The examples generate one kind of placeholder value at a time.

Import statement:

```v
import mockutils
```

Rapid prototyping, testing, and mock data generation wrapping V's native `strings.lorem` and pseudo-random generators.

<a id="mockutils-data-structures"></a>

## Data Structures

### `MockUser`

Represents a synthetic user profile:

- `id`: int
- `name`: string
- `email`: string
- `phone`: string
- `ip`: string
- `role`: string

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="mockutils-functions"></a>

## Functions

### `lorem_text(paragraphs int, sentences int, words int) string`

Generates structured multi-paragraph pseudo-random placeholder text.

```v
import mockutils

text := mockutils.lorem_text(2, 3, 6)
println(text)
```

---

### `lorem_words(count int) string` & `lorem_sentence() string`

Generates a specific number of lorem words or a single coherent sentence.

```v
import mockutils

words := mockutils.lorem_words(5)
println(words)

sentence := mockutils.lorem_sentence()
println(sentence)
```

---

### Synthetic Data Generators

- `mock_first_name() string`: Returns a realistic first name.
- `mock_last_name() string`: Returns a realistic last name.
- `mock_full_name() string`: Returns a combined full name.
- `mock_email() string`: Generates a valid formatted email address.
- `mock_phone() string`: Generates an E.164-style telephone number (`+1-XXX-555-XXXX`).
- `mock_ipv4() string`: Generates a valid IPv4 address.
- `mock_url() string`: Generates a synthetic HTTP/HTTPS URL.
- `mock_user() MockUser`: Returns a populated `MockUser` profile struct.
- `mock_users(count int) []MockUser`: Returns a slice of `count` synthetic user profiles.

```v
import mockutils

// Generate mock user profile
user := mockutils.mock_user()
println('User: ${user.name} (${user.role})')
println('Email: ${user.email}, Phone: ${user.phone}, IP: ${user.ip}')

// Seed a list of 5 test users
test_users := mockutils.mock_users(5)
for u in test_users {
    println('#${u.id}: ${u.name} <${u.email}>')
}
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="logutils"></a><a id="logutils-api"></a>

# logutils API

**Plain-language purpose:** Use these tools to leave a clear record of what your program is doing, especially when something goes wrong. The examples show message levels so important warnings stand out from routine notes.

Import statement:

```v
import logutils
```

### `LoggerConfig` & `Logger`

Configures structured, level-filtered logging to console and disk.

- `LogLevel`: `.debug`, `.info`, `.warn`, `.error`, `.fatal`
- `LogOutput`: `.console`, `.file`, `.both`
- `new_logger(cfg LoggerConfig) Logger`
- `set_level(level LogLevel)`
- `set_file(path string)`
- `format_message(level LogLevel, msg string, now time.Time, colored bool) string`
- `debug(msg string)`, `info(msg string)`, `warn(msg string)`, `error(msg string)`, `fatal(msg string)`

```v
import logutils

mut logger := logutils.new_logger(
    level: .info
    output: .both
    file_path: 'app.log'
    use_color: true
    show_timestamp: true
)

logger.set_level(.debug)
logger.set_file('custom_app.log')
logger.info('Application service initialized')
logger.warn('Elevated cache memory usage detected')
logger.error('Database connection timeout')
logger.fatal('Fatal startup panic averted')
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="tomlutils"></a><a id="tomlutils-api"></a>

# tomlutils API

**Plain-language purpose:** Use these tools to read TOML settings files, which are human-friendly text files for app configuration. The examples show a short configuration and then retrieve values by their descriptive names.

Import statement:

```v
import tomlutils
```

### `TomlDoc` & Parsing Functions

High-level querying and configuration loading for TOML documents.

- `parse(text string) !TomlDoc`
- `parse_file(path string) !TomlDoc`
- `has(key string) bool`
- `get_string(key string, default_val string) string`
- `get_int(key string, default_val int) int`
- `get_i64(key string, default_val i64) i64`
- `get_bool(key string, default_val bool) bool`
- `get_f64(key string, default_val f64) f64`
- `get_strings(key string) []string`
- `get_ints(key string) []int`

```v
import tomlutils

toml_text := '
title = "Config Demo"
[database]
server = "127.0.0.1"
port = 5432
max_conn = 10000000000
enabled = true
ports = [ 8080, 8081 ]
tags = [ "prod", "db" ]
'

doc := tomlutils.parse(toml_text) or { panic(err) }
file_doc := tomlutils.parse_file('config.toml') or { doc }

title := doc.get_string('title', 'untitled')
server := doc.get_string('database.server', 'localhost')
port := doc.get_int('database.port', 5432)
max_conn := doc.get_i64('database.max_conn', 0)
enabled := doc.get_bool('database.enabled', false)

ports := doc.get_ints('database.ports')
tags := doc.get_strings('database.tags')
println('${title}: ${server}:${port}, max=${max_conn}, tags=${tags}')
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="htmlutils"></a><a id="htmlutils-api"></a>

# htmlutils API

**Plain-language purpose:** Use these tools to inspect and clean up web-page markup. The examples show how to find a heading or paragraph, read its text, and safely handle special characters such as `&` and `<`.

Import statement:

```v
import htmlutils
```

### `HtmlDoc`, `HtmlNode`, & HTML Manipulation

DOM querying, text extraction, escaping, unescaping, and tag stripping.

- `HtmlNode`: `tag string`, `id string`, `classes []string`, `attributes map[string]string`, `text string`
- `HtmlDoc`: wrapper around parsed HTML DOM
- `parse(content string) HtmlDoc`
- `parse_file(path string) !HtmlDoc`
- `get_element_by_id(id string) ?HtmlNode`
- `get_elements_by_tag(tag string) []HtmlNode`
- `get_elements_by_class(class_name string) []HtmlNode`
- `title() string`
- `escape_html(s string) string`
- `unescape_html(s string) string`
- `strip_tags(s string) string`

```v
import htmlutils

raw_html := '<!DOCTYPE html><html><head><title>Test Page</title></head><body><h1 id="main-heading" class="title primary">Welcome</h1><p class="desc">V is fast</p></body></html>'

mut doc := htmlutils.parse(raw_html)
file_doc := htmlutils.parse_file('page.html') or { doc }

page_title := doc.title()
h1 := doc.get_element_by_id('main-heading') or { panic('missing') }
println('Header: ${h1.text}, Classes: ${h1.classes}')

paragraphs := doc.get_elements_by_class('desc')
divs := doc.get_elements_by_tag('p')

escaped := htmlutils.escape_html('<div class="box">Hello & "world"</div>')
unescaped := htmlutils.unescape_html(escaped)
plain := htmlutils.strip_tags('<b>Bold</b> and <i>Italic</i>')
println(plain) // "Bold and Italic"
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="bitutils"></a><a id="bitutils-api"></a>

# bitutils API

**Plain-language purpose:** Use these tools when you need compact on/off flags or binary values. The examples use a small set of switches, then show how to turn one on, off, or combine several permissions.

Import statement:

```v
import bitutils
```

### `BitSet` & Bitwise Arithmetic

Compact boolean bit manipulation, Hamming weight (popcount), and flag bitmasks.

- `new_bitset(size int) BitSet`
- `from_binary_string(s string) !BitSet`
- `set(index int)`, `clear(index int)`, `toggle(index int)`, `get(index int) bool`
- `size() int`, `count_set() int`, `str() string`
- `and_op(other BitSet) BitSet`, `or_op(other BitSet) BitSet`, `xor_op(other BitSet) BitSet`, `not_op() BitSet`
- `popcount(n u64) int`
- `to_binary(n u64, min_bits int) string`
- `from_binary(s string) !u64`
- `has_flag(flags u64, flag u64) bool`, `set_flag(flags u64, flag u64) u64`, `clear_flag(flags u64, flag u64) u64`, `toggle_flag(flags u64, flag u64) u64`

```v
import bitutils

mut bs := bitutils.new_bitset(16)
bs.set(0)
bs.set(5)
bs.toggle(5)
is_set := bs.get(0) // true
count := bs.count_set() // 1

mut b1 := bitutils.from_binary_string('1100') or { panic(err) }
mut b2 := bitutils.from_binary_string('1010') or { panic(err) }

and_res := b1.and_op(b2)
or_res := b1.or_op(b2)
xor_res := b1.xor_op(b2)
not_res := b1.not_op()

ones := bitutils.popcount(0b1011001) // 4
bin_str := bitutils.to_binary(42, 8)  // "00101010"
num := bitutils.from_binary('00101010') or { 0 } // 42

flag_read := u64(1)
flag_write := u64(2)
mut perms := bitutils.set_flag(0, flag_read)
perms = bitutils.set_flag(perms, flag_write)
can_read := bitutils.has_flag(perms, flag_read) // true
perms = bitutils.clear_flag(perms, flag_read)
perms = bitutils.toggle_flag(perms, flag_write)
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="compressutils"></a><a id="compressutils-api"></a>

# compressutils API

**Plain-language purpose:** Use these tools to make data smaller for storage or transfer and restore it later without losing information. The examples compress the same text with several common formats and then decompress it again.

Import statement:

```v
import compressutils
```

### Multi-Codec Compression (Gzip, Zlib, Deflate, Zstandard)

Byte slice and string compression and decompression across all major standard compression codecs.

- `gzip_compress(data []u8) ![]u8`, `gzip_decompress(data []u8) ![]u8`
- `gzip_compress_string(text string) ![]u8`, `gzip_decompress_string(data []u8) !string`
- `zlib_compress(data []u8) ![]u8`, `zlib_decompress(data []u8) ![]u8`
- `zlib_compress_string(text string) ![]u8`, `zlib_decompress_string(data []u8) !string`
- `deflate_compress(data []u8) ![]u8`, `deflate_decompress(data []u8) ![]u8`
- `deflate_compress_string(text string) ![]u8`, `deflate_decompress_string(data []u8) !string`
- `zstd_compress(data []u8) ![]u8`, `zstd_decompress(data []u8) ![]u8`
- `zstd_compress_string(text string) ![]u8`, `zstd_decompress_string(data []u8) !string`
- `zstd_version() string`
- `compress(algo CompressionAlgorithm, data []u8) ![]u8`
- `decompress(algo CompressionAlgorithm, data []u8) ![]u8`
- `compression_ratio(original_len int, compressed_len int) f64`

```v
import compressutils

payload := 'Vlang utilities unified compression and decompression across formats.'

// Gzip
gz_bytes := compressutils.gzip_compress_string(payload) or { panic(err) }
gz_raw := compressutils.gzip_compress(payload.bytes()) or { panic(err) }
gz_dec_bytes := compressutils.gzip_decompress(gz_raw) or { panic(err) }
gz_text := compressutils.gzip_decompress_string(gz_bytes) or { panic(err) }

// Zlib
zl_bytes := compressutils.zlib_compress_string(payload) or { panic(err) }
zl_raw := compressutils.zlib_compress(payload.bytes()) or { panic(err) }
zl_dec_bytes := compressutils.zlib_decompress(zl_raw) or { panic(err) }
zl_text := compressutils.zlib_decompress_string(zl_bytes) or { panic(err) }

// Deflate
df_bytes := compressutils.deflate_compress_string(payload) or { panic(err) }
df_raw := compressutils.deflate_compress(payload.bytes()) or { panic(err) }
df_dec_bytes := compressutils.deflate_decompress(df_raw) or { panic(err) }
df_text := compressutils.deflate_decompress_string(df_bytes) or { panic(err) }

// Zstandard
zstd_v := compressutils.zstd_version()
zs_bytes := compressutils.zstd_compress_string(payload) or { panic(err) }
zs_raw := compressutils.zstd_compress(payload.bytes()) or { panic(err) }
zs_dec_bytes := compressutils.zstd_decompress(zs_raw) or { panic(err) }
zs_text := compressutils.zstd_decompress_string(zs_bytes) or { panic(err) }

// Unified dispatcher & ratio
uni_c := compressutils.compress(.zstd, payload.bytes()) or { panic(err) }
uni_d := compressutils.decompress(.zstd, uni_c) or { panic(err) }
ratio := compressutils.compression_ratio(payload.len, uni_c.len)
println('Zstandard version: ${zstd_v}, ratio: ${ratio:.1f}%')
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="tarutils"></a><a id="tarutils-api"></a>

# tarutils API

**Plain-language purpose:** Use these tools to create and unpack TAR archives, a common way to bundle files on Unix-like systems. The examples cover both in-memory data and archive files stored on disk.

Import statement:

```v
import tarutils
```

### POSIX ustar TAR Archive Management

Creating, packing, inspecting, and extracting archives in pure V.

- `TarEntry`: `name string`, `size int`, `is_dir bool`, `data []u8`
- `pack_bytes(entries []TarEntry) []u8`
- `unpack_bytes(data []u8) ![]TarEntry`
- `create_tar(tar_path string, file_paths []string) !bool`
- `list_tar_entries(tar_path string) ![]TarEntry`
- `extract_tar(tar_path string, dest_dir string) !bool`
- `read_tar_file(tar_path string, filename string) !string`

```v
import tarutils

// In-memory TAR packing and unpacking
entries := [
    tarutils.TarEntry{ name: 'hello.txt', size: 12, is_dir: false, data: 'Hello World!'.bytes() },
    tarutils.TarEntry{ name: 'folder', size: 0, is_dir: true, data: []u8{} }
]
tar_bytes := tarutils.pack_bytes(entries)
unpacked := tarutils.unpack_bytes(tar_bytes) or { panic(err) }

// Disk TAR archive creation and extraction
tarutils.create_tar('backup.tar', ['file1.txt', 'file2.txt']) or { panic(err) }
files_in_tar := tarutils.list_tar_entries('backup.tar') or { panic(err) }
content := tarutils.read_tar_file('backup.tar', 'file1.txt') or { '' }
tarutils.extract_tar('backup.tar', './output_dir') or { panic(err) }
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="advanced-additions--enhancements"></a><a id="advanced-additions-enhancements"></a>

# Advanced Additions & Enhancements

### `cliutils` Clipboard Functions

```v
import cliutils

if cliutils.is_clipboard_available() {
    cliutils.copy_to_clipboard('Copied to system clipboard')
    text := cliutils.read_from_clipboard()
    println(text)
}
```

### `cryptoutils` Advanced Cryptography

```v
import cryptoutils

// Symmetric AES-CBC (with PKCS7 padding)
key := cryptoutils.secure_random_bytes(32) or { panic(err) }
iv := cryptoutils.secure_random_bytes(16) or { panic(err) }
ciphertext := cryptoutils.aes_encrypt_string(key, iv, 'Secret Payload') or { panic(err) }
raw_cipher := cryptoutils.aes_encrypt_cbc(key, iv, 'Secret Payload'.bytes()) or { panic(err) }
raw_dec := cryptoutils.aes_decrypt_cbc(key, iv, raw_cipher) or { panic(err) }
decrypted := cryptoutils.aes_decrypt_string(key, iv, ciphertext) or { panic(err) }

// Password hashing with Bcrypt
hash := cryptoutils.bcrypt_hash('user_password') or { panic(err) }
ok := cryptoutils.bcrypt_verify('user_password', hash)

// Secure Entropy
random_hex := cryptoutils.secure_random_hex(16) or { '' }

// Fast non-cryptographic hashes
fnv32 := cryptoutils.fnv1a_32('string to hash')
c32 := cryptoutils.crc32_hash('string to hash')

// Asymmetric Ed25519 digital signatures
pub_k, priv_k := cryptoutils.generate_ed25519_keypair() or { panic(err) }
sig := cryptoutils.ed25519_sign(priv_k, 'message'.bytes()) or { panic(err) }
valid := cryptoutils.ed25519_verify(pub_k, 'message'.bytes(), sig)
```

### `netutils` Framed TCP & UDP

```v
import netutils
import net

// Framed TCP messages (4-byte length prefix to prevent fragmentation)
mut conn := net.dial_tcp('127.0.0.1:9000') or { panic(err) }
netutils.send_framed_msg(mut conn, 'Framed Payload'.bytes()) or { panic(err) }
reply := netutils.read_framed_msg(mut conn, 8192) or { panic(err) }

// UDP datagram transmission
netutils.send_udp('127.0.0.1', 9001, 'UDP Packet'.bytes()) or { panic(err) }
```

### `structutils` Advanced Generic Collections (`GenericSet`, `BloomFilter`, `BinarySearchTree`, `SinglyLinkedList`, `DoublyLinkedList`)

```v
import structutils

// GenericSet[T]
mut s := structutils.new_set[string]()
mut s_arr := structutils.new_set_from_array(['a', 'b', 'c'])
s.add('first')
s.add_all(['second', 'third'])
has_val := s.contains('first')
arr := s.to_array()
var_set := structutils.GenericSet[string]{ set: s.set }

// BloomFilter
mut bf := structutils.new_bloom_filter(64, 3) or { panic(err) }
bf.add('item1')
exists := bf.contains('item1')
var_bf := structutils.BloomFilter{}

// BinarySearchTree[T]
mut bst := structutils.new_bstree[int]()
bst.insert(10)
bst.insert(5)
bst.insert(15)
sorted_order := bst.in_order()
smallest := bst.min()
largest := bst.max()
var_bst := structutils.BinarySearchTree[int]{}

// SinglyLinkedList[T]
mut ll := structutils.new_linked_list[int]()
ll.push(10)
item := ll.pop()
first_item := ll.shift()
var_ll := structutils.SinglyLinkedList[int]{}

// DoublyLinkedList[T]
mut dll := structutils.new_doubly_linked_list[string]()
dll.push_back('tail')
dll.push_front('head')
popped_tail := dll.pop_back()
popped_head := dll.pop_front()
var_dll := structutils.DoublyLinkedList[string]{}
```

### `sysutils` Runtime Info (`RuntimeInfo`) & Shell Piping

```v
import sysutils

info := sysutils.runtime_system_info()
println('OS: ${info.os_name}, Arch: ${info.arch}, CPUs: ${info.num_cpus}, 64bit: ${info.is_64bit}')
var_rt := sysutils.RuntimeInfo{ os_name: 'macos', arch: 'arm64' }

piped_output := sysutils.pipe_commands('echo "antigravity toolkit"', 'grep "antigravity"') or { '' }
println(piped_output)
```

### `timeutils` Benchmarking Suite (`BenchmarkResult`)

```v
import timeutils

res := timeutils.benchmark_fn('loop_benchmark', 1000, fn () {
    mut sum := 0
    for i in 0 .. 100 { sum += i }
})
println(res.str())
println('Ops/Sec: ${res.ops_per_sec}')
var_bm := timeutils.BenchmarkResult{ name: 'demo', iterations: 10 }
```

[▲ Back to Table of Contents](#table-of-contents)

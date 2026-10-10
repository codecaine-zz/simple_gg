# V Developer Utility Suite (`vlang_utils`) - Complete API Reference

Welcome to the comprehensive API reference manual for the **40 production-grade developer utility modules** in `vlang_utils`.

Every module is zero-dependency, self-contained, and designed for Rapid Application Development (RAD). You can import any module directly across GUI apps, CLI tools, services, and background workers (e.g. `import strutils`, `import sqliteutils`, `import cacheutils`).

> [!NOTE]
> **V Compiler Compatibility**: All 40 modules in `vlang_utils` are verified and tested against **V 0.5.2** (`9e9f7f05`). This includes full support for `json2` streaming serialization, generics, and native SQLite bindings. For compiler maintenance, `v up` troubleshooting, and `VFLAGS` setup, refer to [`README.md`](README.md#5-v-compiler-version--v-up-maintenance).

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

All 40 utility modules have standalone, fully functional demo scripts located in the [`demos/`](demos/) directory.

- **Run all 40 demos sequentially with execution timing:**
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
| [`cronutils`](#cronutils-api) | [`demo_cronutils.v`](demos/demo_cronutils.v) | `v run demos/demo_cronutils.v` |
| [`cryptoutils`](#cryptoutils-api) | [`demo_cryptoutils.v`](demos/demo_cryptoutils.v) | `v run demos/demo_cryptoutils.v` |
| [`diffutils`](#diffutils-api) | [`demo_diffutils.v`](demos/demo_diffutils.v) | `v run demos/demo_diffutils.v` |
| [`envutils`](#envutils-api) | [`demo_envutils.v`](demos/demo_envutils.v) | `v run demos/demo_envutils.v` |
| [`eventutils`](#eventutils-api) | [`demo_eventutils.v`](demos/demo_eventutils.v) | `v run demos/demo_eventutils.v` |
| [`fileutils`](#fileutils-api) | [`demo_fileutils.v`](demos/demo_fileutils.v) | `v run demos/demo_fileutils.v` |
| [`flowutils`](#flowutils-api) | [`demo_flowutils.v`](demos/demo_flowutils.v) | `v run demos/demo_flowutils.v` |
| [`graphutils`](#graphutils-api) | [`demo_graphutils.v`](demos/demo_graphutils.v) | `v run demos/demo_graphutils.v` |
| [`htmlutils`](#htmlutils-api) | [`demo_htmlutils.v`](demos/demo_htmlutils.v) | `v run demos/demo_htmlutils.v` |
| [`httputils`](#httputils-api) | [`demo_httputils.v`](demos/demo_httputils.v) | `v run demos/demo_httputils.v` |
| [`jsonutils`](#jsonutils-api) | [`demo_jsonutils.v`](demos/demo_jsonutils.v) | `v run demos/demo_jsonutils.v` |
| [`jwtutils`](#jwtutils-api) | [`demo_jwtutils.v`](demos/demo_jwtutils.v) | `v run demos/demo_jwtutils.v` |
| [`logutils`](#logutils-api) | [`demo_logutils.v`](demos/demo_logutils.v) | `v run demos/demo_logutils.v` |
| [`markdownutils`](#markdownutils-api) | [`demo_markdownutils.v`](demos/demo_markdownutils.v) | `v run demos/demo_markdownutils.v` |
| [`mathutils`](#mathutils-api) | [`demo_mathutils.v`](demos/demo_mathutils.v) | `v run demos/demo_mathutils.v` |
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
| [`urlutils`](#urlutils-api) | [`demo_urlutils.v`](demos/demo_urlutils.v) | `v run demos/demo_urlutils.v` |
| [`validutils`](#validutils-api) | [`demo_validutils.v`](demos/demo_validutils.v) | `v run demos/demo_validutils.v` |
| [`webutils`](#webutils-api) | [`demo_webutils.v`](demos/demo_webutils.v) | `v run demos/demo_webutils.v` |

---

<a id="table-of-contents"></a>

## 📑 Table of Contents

### ⚡ Quick Jump Index

[`archiveutils`](#archiveutils-api) • [`asyncutils`](#asyncutils-api) • [`bitutils`](#bitutils-api) • [`cacheutils`](#cacheutils-api) • [`cliutils`](#cliutils-api) • [`colorutils`](#colorutils-api) • [`compressutils`](#compressutils-api) • [`cronutils`](#cronutils-api) • [`cryptoutils`](#cryptoutils-api) • [`diffutils`](#diffutils-api) • [`envutils`](#envutils-api) • [`eventutils`](#eventutils-api) • [`fileutils`](#fileutils-api) • [`flowutils`](#flowutils-api) • [`graphutils`](#graphutils-api) • [`htmlutils`](#htmlutils-api) • [`httputils`](#httputils-api) • [`jsonutils`](#jsonutils-api) • [`jwtutils`](#jwtutils-api) • [`logutils`](#logutils-api) • [`markdownutils`](#markdownutils-api) • [`mathutils`](#mathutils-api) • [`mockutils`](#mockutils-api) • [`netutils`](#netutils-api) • [`regexutils`](#regexutils-api) • [`semverutils`](#semverutils-api) • [`sliceutils`](#sliceutils-api) • [`sqliteutils`](#sqliteutils-api) • [`stateutils`](#stateutils-api) • [`statutils`](#statutils-api) • [`structutils`](#structutils-api) • [`strutils`](#strutils-api) • [`sysutils`](#sysutils-api) • [`tarutils`](#tarutils-api) • [`templateutils`](#templateutils-api) • [`timeutils`](#timeutils-api) • [`tomlutils`](#tomlutils-api) • [`urlutils`](#urlutils-api) • [`validutils`](#validutils-api) • [`webutils`](#webutils-api) • [Advanced Additions & Enhancements](#advanced-additions--enhancements)

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
- **[`jsonutils`](#jsonutils-api)** — RFC 6901 JSON Pointer, RFC 7386 Merge Patch, canonical encoding, diff & flatten
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
- **[`mathutils`](#mathutils-api)** — 2D mathematics, spatial geometry, interpolation, clamping, and number theory
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
- **[`webutils`](#webutils-api)** — Express-style web framework with templates, middleware, sessions & security

#### 5. Parsing, Formatting & Encodings

- **[`cronutils`](#cronutils-api)** — POSIX cron parsing, future execution calculation, and human summaries
- **[`markdownutils`](#markdownutils-api)** — CommonMark-style Markdown to HTML, GFM tables, task lists, TOC & plain text
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
- **[`urlutils`](#urlutils-api)** — RFC 3986 URL parsing, path segmentation, query manipulation, and credential redaction
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
- **[`jwtutils`](#jwtutils-api)** — HS256/384/512 JSON Web Token signing, claims parsing, and verification

#### 7. Graphics, Color Theory, Events & Archives

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
- **[`diffutils`](#diffutils-api)** — Line-level programmatic diffing, operation trees, and unified diff formatting
- **[`eventutils`](#eventutils-api)** — In-memory publish-subscribe event dispatching and notification
- **[`graphutils`](#graphutils-api)** — Directed Acyclic Graphs (DAG), topological sorting, cycle detection, BFS and DFS
- **[`mockutils`](#mockutils-api)** — Synthetic mock data generator (users, emails, phones, IPv4, URLs, lorem)
  - [Mock Data Structures](#mockutils-data-structures)
  - [Mock Functions](#mockutils-functions)
- **[`tarutils`](#tarutils-api)** — In-memory and on-disk TAR archive creation, unpacking, directory archiving

#### 8. Advanced Extensions

- **[Advanced Additions & Enhancements](#advanced-additions--enhancements)** — System clipboard, symmetric AES-CBC, Bcrypt hashing, secure entropy, fast non-cryptographic hashes

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

<a id="bitutils"></a><a id="bitutils-api"></a>

# bitutils API

**Plain-language purpose:** Use `bitutils` when you need to store and manipulate on/off flags (such as user permissions or settings), pack millions of booleans into minimal memory, or perform fast low-level binary calculations.

Import statement:

```v
import bitutils
```

### Core Concepts

- **BitSet**: A dynamically-sized array of bits where each bit is either `0` (off/false) or `1` (on/true). Storing 1,000 booleans in a standard array takes 1,000 bytes; a `BitSet` stores them in only 125 bytes.
- **Bitmask Flags**: An integer where each individual bit represents a specific permission or option (e.g. read=1, write=2, execute=4). Multiple flags are combined with bitwise OR (`|`).

---

### Dynamic BitSet Operations

#### `new_bitset(size int) BitSet`

Creates a new `BitSet` with `size` individual bits initialized to `0`.

```v
import bitutils

mut bs := bitutils.new_bitset(64) // 64 bits available (indices 0 to 63)
println('Bitset size: ${bs.size()}') // 64
println('All clear: ${bs.none_set()}') // true
```

#### `set(index int)`, `clear(index int)`, `toggle(index int)`, `get(index int) bool`

Modifies and inspects individual bit values by their 0-based index.

```v
import bitutils

mut bs := bitutils.new_bitset(16)

bs.set(0)    // Turn on bit at index 0
bs.set(5)    // Turn on bit at index 5
println('Bit 5 is set: ${bs.get(5)}') // true
println('Bit 2 is set: ${bs.get(2)}') // false

bs.toggle(2) // Flip bit 2 from 0 to 1
println('Bit 2 after toggle: ${bs.get(2)}') // true

bs.clear(5)  // Turn off bit 5
println('Bit 5 after clear: ${bs.get(5)}') // false
```

#### `count_set() int`, `count_clear() int`, `all_set() bool`, `any() bool`

Queries the population of bits currently turned on or off.

```v
import bitutils

mut bs := bitutils.new_bitset(8)
bs.set(1)
bs.set(3)
bs.set(7)

println('Count set (1s): ${bs.count_set()}')     // 3
println('Count clear (0s): ${bs.count_clear()}') // 5
println('Any bits set: ${bs.any()}')             // true
println('All bits set: ${bs.all_set()}')         // false
```

#### `set_all()`, `clear_all()`, `set_range(start int, end int)`

Bulk updates across the entire bitset or a range of indices.

```v
import bitutils

mut bs := bitutils.new_bitset(16)

// Set bits from index 2 up to (exclusive) index 6 -> sets 2, 3, 4, 5
bs.set_range(2, 6)
println('Indices set: ${bs.set_indices()}') // [2, 3, 4, 5]

bs.clear_all()
println('Count after clear_all: ${bs.count_set()}') // 0

bs.set_all()
println('Count after set_all: ${bs.count_set()}')   // 16
```

#### `and_op(other BitSet)`, `or_op(other BitSet)`, `xor_op(other BitSet)`, `not_op()`

Performs boolean logic operations between two bitsets of equal size.

```v
import bitutils

mut a := bitutils.new_bitset(4)
a.set(0)
a.set(1) // 0011

mut b := bitutils.new_bitset(4)
b.set(1)
b.set(2) // 0110

and_res := a.and_op(b) // Only index 1 is set in both
println('AND indices: ${and_res.set_indices()}') // [1]

or_res := a.or_op(b)   // Indices 0, 1, 2 are set in either
println('OR indices: ${or_res.set_indices()}')   // [0, 1, 2]
```

---

### Bitmask Flag Manipulation

#### `has_flag(flags u64, flag u64) bool` & `set_flag`, `clear_flag`, `toggle_flag`

Conveniently manage permission masks and feature toggle integers without writing manual bitwise shifts.

```v
import bitutils

const perm_read    = u64(1 << 0) // 1 (0001)
const perm_write   = u64(1 << 1) // 2 (0010)
const perm_execute = u64(1 << 2) // 4 (0100)

mut user_perms := u64(0)

// Grant read and write permissions
user_perms = bitutils.set_flag(user_perms, perm_read)
user_perms = bitutils.set_flag(user_perms, perm_write)

println('Can read: ${bitutils.has_flag(user_perms, perm_read)}')       // true
println('Can write: ${bitutils.has_flag(user_perms, perm_write)}')     // true
println('Can execute: ${bitutils.has_flag(user_perms, perm_execute)}') // false

// Revoke write permission
user_perms = bitutils.clear_flag(user_perms, perm_write)
println('Can write after revoke: ${bitutils.has_flag(user_perms, perm_write)}') // false
```

---

### Low-Level Binary & Integer Utilities

#### `popcount(n u64) int` & `to_binary(n u64, min_bits int) string`

Counts set bits (Hamming weight) and formats numbers as binary text.

```v
import bitutils

// Count how many bits are 1
println(bitutils.popcount(7)) // 3 (binary 111 has three 1s)
println(bitutils.popcount(16)) // 1 (binary 10000 has one 1)

// Convert integer to binary string with minimum width padding
println(bitutils.to_binary(5, 8)) // "00000101"
println(bitutils.to_binary(255, 8)) // "11111111"

// Parse binary string back to integer
num := bitutils.from_binary('1010')!
println('Parsed from binary: ${num}') // 10
```

#### `is_power_of_two(n u64) bool`, `next_power_of_two(n u64) u64`

Fast power-of-two validation and buffer sizing.

```v
import bitutils

println(bitutils.is_power_of_two(16)) // true
println(bitutils.is_power_of_two(18)) // false

// Find next power of two (great for buffer allocations)
println(bitutils.next_power_of_two(17)) // 32
println(bitutils.next_power_of_two(60)) // 64
```

#### `hamming_distance(a u64, b u64) int`

Measures the number of bit positions in which two integers differ (error detection / perceptual hashing).

```v
import bitutils

// 0b1010 vs 0b1001 differ at bits 0 and 1 -> distance = 2
dist := bitutils.hamming_distance(0b1010, 0b1001)
println('Hamming distance: ${dist}') // 2
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
println(help_text)
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
println('Lighter: ${lighter}, Darker: ${darker}')
```

---

### `invert(c RGB) RGB`

Computes the inverted / photographic negative of an RGB color.

```v
import colorutils

white := colorutils.RGB{255, 255, 255}
black := colorutils.invert(white)
println(black) // RGB{0, 0, 0}
```

---

### `blend(c1 RGB, c2 RGB, factor f64) RGB`

Linearly interpolates between two colors with a factor from `0.0` (`c1`) to `1.0` (`c2`).

```v
import colorutils

red := colorutils.RGB{255, 0, 0}
blue := colorutils.RGB{0, 0, 255}
purple := colorutils.blend(red, blue, 0.5)
println(purple) // Halfway blend
```

---

### `grayscale(c RGB) RGB`

Converts an RGB color to perceptually weighted grayscale using ITU-R BT.601 luminance coefficients.

```v
import colorutils

c := colorutils.RGB{255, 200, 50}
gray := colorutils.grayscale(c)
println(gray)
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

---

### 5. High Dynamic Range (HDR / EDR) Colors

#### `new_hdr_color(r f64, g f64, b f64, a f64) HDRColor`

Represents colors in extended dynamic range (EDR) on HDR-capable displays (such as modern Apple Liquid Retina XDR screens), where red/green/blue channels can exceed standard 1.0 peak white luminance.

```v
import colorutils

// Create standard HDR color with extended headroom
hdr := colorutils.new_hdr_color(1.5, 0.8, 0.2, 1.0)
println('Is HDR:       ${hdr.is_hdr()}')      // true
println('Luminance:    ${hdr.luminance():.2f}') // extended luminance

// Clamp back to standard SDR sRGB [0..255] for standard monitors
sdr_rgb := hdr.clamp_to_sdr()
println('SDR Fallback: R=${sdr_rgb.r}, G=${sdr_rgb.g}, B=${sdr_rgb.b}')

// Boost standard SDR color by +1.5 stops of exposure
boosted := colorutils.hdr_color_from_exposure(colorutils.RGB{255, 200, 50}, 1.5)
println('Boosted Headroom: ${boosted.headroom:.2f}x')
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="compressutils"></a><a id="compressutils-api"></a>

# compressutils API

**Plain-language purpose:** Use `compressutils` to shrink data (strings, bytes, files) for network transmission or disk storage, and decompress it back to its original state using standard algorithms (Gzip, Zlib, Deflate, and Zstandard).

Import statement:

```v
import compressutils
```

### Supported Compression Formats

- **Gzip**: Standard format used for HTTP web traffic, `.tar.gz` archives, and general file compression.
- **Zlib / Deflate**: Lightweight RFC 1950/1951 stream compression commonly used in PNG images and network protocols.
- **Zstandard (Zstd)**: High-performance modern algorithm created by Meta offering extreme compression ratios and fast decompression.

---

### String Compression & Decompression

#### `gzip_compress_string(text string) ![]u8` & `gzip_decompress_string(data []u8) !string`

Compresses human-readable text into a Gzip byte array, and restores it.

```v
import compressutils

payload := 'V is an open-source, statically-typed, fast, safe compiled language designed for building maintainable software.'

// Compress to Gzip bytes
compressed := compressutils.gzip_compress_string(payload)!
println('Original size: ${payload.len} bytes, Compressed: ${compressed.len} bytes')

// Calculate space savings
ratio := compressutils.compression_ratio(payload.len, compressed.len)
println('Space reduction: ${ratio:.1f}%')

// Decompress back to string
restored := compressutils.gzip_decompress_string(compressed)!
println('Restored matches original: ${restored == payload}') // true
```

#### `zstd_compress_string(text string) ![]u8` & `zstd_decompress_string(data []u8) !string`

High-speed compression using the modern Zstandard engine.

```v
import compressutils

raw_json := '{"event":"click","user_id":12345,"timestamp":"2026-10-10T12:00:00Z","metadata":{"ip":"127.0.0.1"}}'

// Compress using Zstd
compressed := compressutils.zstd_compress_string(raw_json)!
println('Zstd compressed size: ${compressed.len} bytes')

// Decompress using Zstd
decompressed := compressutils.zstd_decompress_string(compressed)!
println('Restored JSON: ${decompressed}')
```

#### `zlib_compress_string` & `deflate_compress_string`

```v
import compressutils

text := 'Short repeating string: ABCABCABCABCABC'

// Zlib (with header & Adler32 checksum)
zlib_bytes := compressutils.zlib_compress_string(text)!
restored_zlib := compressutils.zlib_decompress_string(zlib_bytes)!

// Raw Deflate (headerless)
deflate_bytes := compressutils.deflate_compress_string(text)!
restored_deflate := compressutils.deflate_decompress_string(deflate_bytes)!

println('Zlib restored: ${restored_zlib}')
println('Deflate restored: ${restored_deflate}')
```

---

### Format Auto-Detection & General Buffers

#### `detect_algorithm(data []u8) ?CompressionAlgorithm` & `decompress_auto(data []u8) ![]u8`

Inspects magic bytes at the beginning of an unknown compressed buffer and automatically unpacks it without guessing.

```v
import compressutils

data := 'Important document contents'.bytes()
compressed := compressutils.gzip_compress(data)!

// Detect algorithm from magic header bytes
if algo := compressutils.detect_algorithm(compressed) {
    println('Detected algorithm: ${algo}') // CompressionAlgorithm.gzip
}

// Automatically unpack regardless of whether it is Gzip, Zlib, or Zstd
unpacked := compressutils.decompress_auto(compressed)!
println('Auto-decompressed text: ${unpacked.bytestr()}')
```

---

### File Compression Helpers

#### `compress_file(algo CompressionAlgorithm, src string, dst string) !` & `decompress_file`

Streams and compresses a file directly on disk.

```v
import compressutils
import os

// Write sample log file
os.write_file('app.log', '2026-10-10 INFO Startup complete
2026-10-10 INFO Ready')!

// Compress directly to app.log.gz
compressutils.compress_file(.gzip, 'app.log', 'app.log.gz')!
println('Created compressed file. Exists: ${os.exists("app.log.gz")}')

// Decompress to app_restored.log (with max 10MB safety limit)
compressutils.decompress_file(.gzip, 'app.log.gz', 'app_restored.log', 10 * 1024 * 1024)!
println('Restored file content: ${os.read_file("app_restored.log")!}')

// Clean up
os.rm('app.log') or {}
os.rm('app.log.gz') or {}
os.rm('app_restored.log') or {}
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="cronutils"></a><a id="cronutils-api"></a>

# cronutils API

**Plain-language purpose:** Use `cronutils` to schedule recurring background tasks (like nightly database backups or hourly health checks) using standard 5-field cron syntax or convenient human macros (`@daily`, `@hourly`).

Import statement:

```v
import cronutils
import time
```

### Cron Syntax Format

Cron expressions specify 5 fields separated by spaces:
```
┌───────────── minute (0 - 59)
│ ┌─────────── hour (0 - 23)
│ │ ┌───────── day of the month (1 - 31)
│ │ │ ┌─────── month (1 - 12 or JAN - DEC)
│ │ │ │ ┌───── day of the week (0 - 6, 0=Sun, or SUN - SAT)
│ │ │ │ │
* * * * *
```

Special symbols:
- `*`: Any value (runs every minute, hour, day, etc.)
- `,`: Value list (e.g. `1,15,30`)
- `-`: Range of values (e.g. `9-17` for 9 AM to 5 PM)
- `/`: Step values (e.g. `*/10` for every 10 minutes)
- Predefined macros: `@yearly`, `@monthly`, `@weekly`, `@daily`, `@midnight`, `@hourly`

---

### Parsing & Scheduling Tasks

#### `parse_cron(expr string) !CronSchedule`

Parses and validates a cron expression or macro, returning a `CronSchedule` object ready to calculate execution times.

```v
import cronutils
import time

// Parse standard 5-field cron: Every 15 minutes during business hours (9am-5pm) Mon-Fri
sched := cronutils.parse_cron('*/15 9-17 * * 1-5')!
println('Expression: ${sched.expression}')

// Calculate the next upcoming execution time after right now
now := time.now()
next_run := sched.next_after(now)!
println('Current time: ${now}')
println('Next run at:  ${next_run}')

// Check if a specific time matches the schedule
matches_now := sched.matches(next_run)
println('Matches next execution time: ${matches_now}') // true
```

#### `next_n(t time.Time, n int) ![]time.Time`

Calculates a sequence of the next `n` future execution times (ideal for calendar views and upcoming job dashboards).

```v
import cronutils
import time

// Daily report schedule at 6:00 AM
sched := cronutils.parse_cron('0 6 * * *')!

// Get the next 5 days of scheduled runs
future_runs := sched.next_n(time.now(), 5)!
println('Upcoming 5 runs:')
for idx, run_time in future_runs {
    println('  ${idx + 1}. ${run_time.format_ss()}')
}
```

#### `cron_to_human(expr string) string`

Converts a cron expression into an intuitive, plain-English summary for end-user interfaces.

```v
import cronutils

println(cronutils.cron_to_human('0 0 * * *'))       // "Every day at midnight"
println(cronutils.cron_to_human('*/15 * * * *'))     // "Every 15 minutes"
println(cronutils.cron_to_human('0 9 * * 1-5'))     // "At 09:00 on weekdays"
println(cronutils.cron_to_human('@hourly'))         // "Every hour"
```

#### `is_valid_cron(expr string) bool`

Checks whether an input string is valid cron syntax without raising errors (ideal for validating web form inputs).

```v
import cronutils

println(cronutils.is_valid_cron('0 12 * * *'))   // true
println(cronutils.is_valid_cron('invalid-cron')) // false
println(cronutils.is_valid_cron('@daily'))       // true
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
hex_str := cryptoutils.to_hex(raw)
println(hex_str) // "deadbeef"
bytes := cryptoutils.from_hex('deadbeef')!
println(bytes)
```

---

### `hmac_sha256(key string, data string) string`

Computes HMAC-SHA256 digest in hex.

```v
mac := cryptoutils.hmac_sha256('my-secret-key', 'message payload')
println(mac)
```

---

### `base64_encode(s string) string` & `base64_decode(s string) !string`

Standard Base64 encoding and decoding.

```v
encoded := cryptoutils.base64_encode('Hello V')
decoded := cryptoutils.base64_decode(encoded)!
println(decoded)
```

---

### `base64_url_encode(s string) string` & `base64_url_decode(s string) !string`

URL-safe Base64 encoding and decoding without padding.

```v
url_safe := cryptoutils.base64_url_encode('Hello V')
println(url_safe)
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
token := cryptoutils.secure_token(32)
println(token) // 64 hex characters
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="diffutils"></a><a id="diffutils-api"></a>

# diffutils API

**Plain-language purpose:** Use `diffutils` to compare two texts, generate standard git-style unified diffs, compute fuzzy text similarity percentages, and apply patches programmatically.

Import statement:

```v
import diffutils
```

### Core Operations

- **Unified Diff**: The universal standard format used by git and patch tools to represent added, removed, and modified lines.
- **Similarity**: Measures the Levenshtein-based similarity between two strings as a ratio from `0.0` (completely different) to `1.0` (identical).

---

### Unified Diff Generation

#### `unified_diff(old_text string, new_text string, filename string) string`

Produces a standard unified diff string showing changes with line headers (`@@ -1,2 +1,2 @@`).

```v
import diffutils

old_config := 'server_name=app.test
port=8080
debug=true
'
new_config := 'server_name=app.test
port=9000
debug=false
workers=4
'

diff := diffutils.unified_diff(old_config, new_config, 'config.env')
println(diff)
/*
--- a/config.env
+++ b/config.env
@@ -1,3 +1,4 @@
 server_name=app.test
-port=8080
-debug=true
+port=9000
+debug=false
+workers=4
*/
```

---

### Granular Line, Word & Character Diffs

#### `diff_lines`, `diff_words`, `diff_chars`

Breaks differences down into individual operation tokens (`DiffOp.equal`, `DiffOp.insert`, `DiffOp.delete`).

```v
import diffutils

ops := diffutils.diff_lines('apple
banana
', 'apple
cherry
')

for op in ops {
    match op.tag {
        .equal  { println('  [UNCHANGED] ${op.text}') }
        .delete { println('- [REMOVED]   ${op.text}') }
        .insert { println('+ [ADDED]     ${op.text}') }
    }
}
```

#### `diff_stats(ops []DiffOp) DiffStats`

Provides statistical counts of additions, deletions, and unchanged elements.

```v
import diffutils

ops := diffutils.diff_lines('line1
line2
', 'line1
modified line2
line3
')
stats := diffutils.diff_stats(ops)

println('Added: ${stats.additions}, Deleted: ${stats.deletions}, Unchanged: ${stats.unchanged}')
```

---

### Similarity & Patch Application

#### `similarity(old_text string, new_text string) f64`

Calculates fuzzy text similarity on a scale of `0.0` to `1.0`.

```v
import diffutils

score1 := diffutils.similarity('Hello World', 'Hello World!')
score2 := diffutils.similarity('Apple', 'Banana')

println('Score 1: ${score1:.2f}') // e.g. 0.92
println('Score 2: ${score2:.2f}') // e.g. 0.18
```

#### `apply_patch(old_text string, patch string) !string`

Applies a standard unified patch to the original text, returning the newly updated content.

```v
import diffutils

original := 'Alpha
Beta
Gamma
'
patch := '--- a/file.txt
+++ b/file.txt
@@ -1,3 +1,3 @@
 Alpha
-Beta
+Delta
 Gamma
'

updated := diffutils.apply_patch(original, patch)!
println('Updated text:
${updated}')
// Output: Alpha
Delta
Gamma

```

#### `render_ansi(ops []DiffOp) string`

Formats diff operations with green (`+`) and red (`-`) ANSI colors for clean terminal printing.

```v
import diffutils

ops := diffutils.diff_lines('one
two', 'one
three')
ansi_output := diffutils.render_ansi(ops)
println(ansi_output)
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
println(host)
```

---

### `get_int(key string, default_val int) int`

Gets environment variable parsed as integer, or fallback if unset or invalid.

```v
port := envutils.get_int('PORT', 8080)
println(port)
```

---

### `get_i64(key string, default_val i64) i64`

Gets environment variable parsed as a 64-bit integer, or fallback if unset or invalid. Ideal for timestamps and large byte limits.

```v
max_bytes := envutils.get_i64('MAX_UPLOAD_BYTES', 10737418240)
println(max_bytes)
```

---

### `get_bool(key string, default_val bool) bool`

Interprets `'true'`, `'1'`, `'yes'`, `'on'` as `true`, and `'false'`, `'0'`, `'no'`, `'off'` as `false`.

```v
debug := envutils.get_bool('DEBUG', false)
println(debug)
```

---

### `get_f64(key string, default_val f64) f64`

Gets environment variable parsed as float, or fallback if unset or invalid.

```v
scale := envutils.get_f64('SCALE_FACTOR', 1.0)
println(scale)
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
println(secret)
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

<a id="eventutils"></a><a id="eventutils-api"></a>

# eventutils API

**Plain-language purpose:** Use `eventutils` to connect decoupled parts of your application via events (Observer / Pub-Sub pattern). When something happens (like a user logging in or a file download finishing), emit an event and let listeners react automatically.

Import statement:

```v
import eventutils
```

### Core Concepts

- **EventEmitter**: Manages named events (`string`) with string or JSON payloads.
- **TypedEmitter[T]**: Type-safe generic event emitter that passes strongly-typed V structs without serialization overhead.
- **Subscription ID**: An integer returned when subscribing, allowing specific listeners to unsubscribe safely.

---

### String-Based EventEmitter

#### `new_emitter() &EventEmitter`

Creates a new event broker.

```v
import eventutils

mut em := eventutils.new_emitter()
```

#### `on(event string, handler fn(string))` & `emit(event string, payload string)`

Registers permanent event listeners and broadcasts notifications.

```v
import eventutils

mut em := eventutils.new_emitter()

// Register listener for user log in
em.on('user_login', fn (username string) {
    println('Welcome back, ${username}!')
})

// Trigger event
em.emit('user_login', 'alice')
em.emit('user_login', 'bob')
// Output:
// Welcome back, alice!
// Welcome back, bob!
```

#### `once(event string, handler fn(string))`

Registers a one-time listener that automatically unregisters itself after firing once.

```v
import eventutils

mut em := eventutils.new_emitter()

em.once('app_init', fn (status string) {
    println('Application initialized: ${status}')
})

em.emit('app_init', 'ready') // Prints: Application initialized: ready
em.emit('app_init', 'ready') // Does nothing (listener was removed)
```

#### `subscribe(event string, handler fn(string)) int` & `unsubscribe(id int) bool`

Subscribe with an ID so you can cleanly remove the listener later when a component unmounts.

```v
import eventutils

mut em := eventutils.new_emitter()

// Subscribe and get subscription ID
sub_id := em.subscribe('heartbeat', fn (ts string) {
    println('Heartbeat tick: ${ts}')
})

em.emit('heartbeat', '10:00:00') // Prints tick

// Unsubscribe by ID
em.unsubscribe(sub_id)
em.emit('heartbeat', '10:00:05') // No listeners fired
```

#### `on_any(handler fn(string, string)) int`

Wildcard listener that intercepts every event emitted across the entire system (great for debug loggers and analytics).

```v
import eventutils

mut em := eventutils.new_emitter()

// Catch-all logger
em.on_any(fn (event string, payload string) {
    println('[EVENT LOG] Event: ${event}, Payload: ${payload}')
})

em.emit('order_placed', 'Order #101')
em.emit('payment_received', '$49.99')
```

---

### Type-Safe Generic Emitter (`TypedEmitter[T]`)

#### `new_typed_emitter[T]() &TypedEmitter[T]`

Emits strongly-typed structs directly to listeners with compile-time type safety.

```v
import eventutils

struct OrderEvent {
    order_id int
    total    f64
    customer string
}

mut order_bus := eventutils.new_typed_emitter[OrderEvent]()

// Subscribe to typed events
order_bus.subscribe(fn (ev OrderEvent) {
    println('Processing Order #${ev.order_id} for ${ev.customer} (Total: $${ev.total:.2f})')
})

// Emit struct instance directly
order_bus.emit(OrderEvent{
    order_id: 42
    total: 99.50
    customer: 'Sarah'
})
```

[▲ Back to Table of Contents](#table-of-contents)

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
println('Found ${configs.len} config files')
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
ext := fileutils.file_extension('image.png')
println(ext) // "png"
```

---

### `file_stem(path string) string`

Returns the base filename without extension or directory prefix.

```v
stem := fileutils.file_stem('/var/logs/app.conf')
println(stem) // "app"
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

### `parse_csv(content string, delimiter rune) [][]string`

Parses in-memory CSV or TSV content into a 2D slice of strings according to RFC 4180. Delimiter defaults to `,` if `0` is passed. Skips comment lines starting with `#`.

```v
csv_text := 'id,name,role\n1,Alice,admin\n2,Bob,user'
rows := fileutils.parse_csv(csv_text, `,`)
assert rows.len == 3
assert rows[1][1] == 'Alice'
```

---

### `parse_csv_with(content string, opts CsvOptions) [][]string`

Parses CSV or TSV content with configurable options (`delimiter`, `comment` rune, `trim` boolean). Supports complex RFC 4180 multi-line quoted fields, escaped quotes (`""`), and comment line skipping.

```v
content := '# Exported user directory\nid, name ,notes\n1, Alice ,"Hello, ""world"""\n# Inactive accounts\n2, Bob ,"two\nlines"'
rows := fileutils.parse_csv_with(content,
	delimiter: `,`
	comment: `#`
	trim: true
)
assert rows.len == 3
assert rows[1][1] == 'Alice'
assert rows[1][2] == 'Hello, "world"'
assert rows[2][2] == 'two\nlines'
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

<a id="graphutils"></a><a id="graphutils-api"></a>

# graphutils API

**Plain-language purpose:** Use `graphutils` to model relationships between items, resolve dependencies in the correct order (topological sorting), detect circular dependency bugs, and find the shortest or cheapest path between points.

Import statement:

```v
import graphutils
```

### Core Data Structures

- **`Graph[T]`**: Unweighted directed graph. Ideal for task dependencies, package build orders, and state transitions.
- **`WeightedGraph[T]`**: Directed or undirected graph with edge weights/costs. Ideal for route navigation (Dijkstra/A*), logistics, and network cable routing.
- **`UnionFind`**: Disjoint-set data structure for fast connectivity checks between elements.

---

### Directed Graphs & Topological Sorting (Build Pipelines)

#### `new_graph[T]() Graph[T]`, `add_edge(from T, to T)`, `topological_sort() ![]T`

Solves task execution orders where earlier tasks must complete before downstream tasks can start.

```v
import graphutils

mut pipeline := graphutils.new_graph[string]()

// Add dependency edges: add_edge(prerequisite, dependent)
pipeline.add_edge('fetch_code', 'compile')
pipeline.add_edge('compile', 'run_tests')
pipeline.add_edge('run_tests', 'package')
pipeline.add_edge('package', 'deploy')

// Compute valid execution order
order := pipeline.topological_sort()!
println('Build order: ${order}')
// Output: ['fetch_code', 'compile', 'run_tests', 'package', 'deploy']
```

#### `has_cycle() bool` & `find_cycle() ?[]T`

Detects deadlocks and circular dependencies (e.g. A depends on B, B depends on A).

```v
import graphutils

mut g := graphutils.new_graph[string]()
g.add_edge('ServiceA', 'ServiceB')
g.add_edge('ServiceB', 'ServiceC')
g.add_edge('ServiceC', 'ServiceA') // Circular loop!

println('Has cycle: ${g.has_cycle()}') // true

if cycle := g.find_cycle() {
    println('Detected circular loop: ${cycle}') // ['ServiceA', 'ServiceB', 'ServiceC', 'ServiceA']
}
```

#### Traversals: `bfs(start T) []T` & `dfs(start T) []T`

```v
import graphutils

mut tree := graphutils.new_graph[string]()
tree.add_edge('root', 'child_1')
tree.add_edge('root', 'child_2')
tree.add_edge('child_1', 'leaf_a')

println('Breadth-First: ${tree.bfs("root")}') // Visits level-by-level
println('Depth-First:   ${tree.dfs("root")}') // Explores full branches first
```

---

### Weighted Graphs & Shortest Paths (Dijkstra & A*)

#### `new_weighted_graph[T](directed bool) WeightedGraph[T]` & `dijkstra(from T, to T)`

Finds the path with the lowest total cost/distance.

```v
import graphutils

// Undirected roadmap (false = two-way streets)
mut roadmap := graphutils.new_weighted_graph[string](false)

roadmap.add_edge('CityA', 'CityB', 10.0)!
roadmap.add_edge('CityA', 'CityC', 3.0)!
roadmap.add_edge('CityC', 'CityB', 4.0)! // A -> C -> B is cost 3 + 4 = 7.0 (shorter than 10.0!)

if path := roadmap.dijkstra('CityA', 'CityB') {
    println('Cheapest path: ${path.nodes}') // ['CityA', 'CityC', 'CityB']
    println('Total distance: ${path.cost}')  // 7.0
}
```

#### `minimum_spanning_tree() []Edge[T]`

Computes the Minimum Spanning Tree (MST) using Kruskal's algorithm, connecting all nodes with minimum total edge weight (minimal cost network cabling).

```v
import graphutils

mut net := graphutils.new_weighted_graph[string](false)
net.add_edge('Office1', 'Office2', 5.0)!
net.add_edge('Office2', 'Office3', 7.0)!
net.add_edge('Office1', 'Office3', 12.0)!

mst_edges := net.minimum_spanning_tree()
println('MST connections needed: ${mst_edges.len}')
```

---

### Disjoint-Set / Union-Find

#### `new_union_find(n int) UnionFind`

Fast near O(1) connectivity queries.

```v
import graphutils

mut uf := graphutils.new_union_find(10) // 10 elements (0 to 9)

uf.union(0, 1) // Connect 0 and 1
uf.union(1, 2) // Connect 1 and 2

println('0 and 2 are connected: ${uf.connected(0, 2)}') // true
println('0 and 5 are connected: ${uf.connected(0, 5)}') // false
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="htmlutils"></a><a id="htmlutils-api"></a>

# htmlutils API

**Plain-language purpose:** Use `htmlutils` to parse and extract data from HTML web pages, query elements by ID, tag, or class, sanitize untrusted user input against Cross-Site Scripting (XSS), and convert HTML markup into clean plain text.

Import statement:

```v
import htmlutils
```

### Parsing & DOM Queries

#### `parse(content string) HtmlDoc` & `parse_file(path string) !HtmlDoc`

Parses an HTML document string or file into an inspectable DOM tree.

```v
import htmlutils

html := '
<!DOCTYPE html>
<html>
  <head><title>Product Catalog</title></head>
  <body>
    <h1 id="header">Store Items</h1>
    <div class="card"><p class="price">$19.99</p></div>
    <div class="card"><p class="price">$29.99</p></div>
    <a href="/checkout" id="buy-btn">Checkout</a>
  </body>
</html>'

mut doc := htmlutils.parse(html)

// Get document title
println('Page title: ${doc.title()}') // "Product Catalog"

// Find element by unique ID
if btn := doc.get_element_by_id('buy-btn') {
    println('Button label: ${btn.text}')        // "Checkout"
    println('Target link:  ${btn.attributes["href"]}') // "/checkout"
}

// Find all elements by tag or class
cards := doc.get_elements_by_class('card')
println('Found ${cards.len} product cards')

paragraphs := doc.get_elements_by_tag('p')
for p in paragraphs {
    println('Paragraph text: ${p.text}')
}
```

---

### Security: XSS Sanitization & Escaping

#### `sanitize_html(input string, allowed []string) string`

Filters untrusted user input, stripping all tags and dangerous attributes (`<script>`, `onload=`, `javascript:`) except for explicitly allowed formatting tags (like `b`, `i`, `p`, `a`).

```v
import htmlutils

untrusted_comment := '<p>Hello <b>World</b>!<script>alert("XSS stolen cookies!")</script><img src="x" onerror="evil()"></p>'

// Allow only safe formatting tags: 'b', 'i', 'p'
safe_html := htmlutils.sanitize_html(untrusted_comment, ['b', 'i', 'p'])
println(safe_html)
// Output: <p>Hello <b>World</b>!</p>
```

#### `escape_html(s string) string` & `unescape_html(s string) string`

Replaces HTML special characters (`&`, `<`, `>`, `"`, `'`) with safe HTML entities.

```v
import htmlutils

unsafe_str := '<script>alert("Attack & exploit")</script>'
escaped := htmlutils.escape_html(unsafe_str)
println(escaped)
// &lt;script&gt;alert(&quot;Attack &amp; exploit&quot;)&lt;/script&gt;

restored := htmlutils.unescape_html(escaped)
println('Restored: ${restored}')
```

---

### Plain-Text Extraction

#### `html_to_text(html string) string` & `strip_tags(s string) string`

Removes all HTML tags and collapses whitespace, converting formatted HTML into clean, human-readable plain text (perfect for search indexing and email previews).

```v
import htmlutils

raw_html := '<div><h1>Order #101</h1><p>Your item has <b>shipped</b>!</p><ul><li>Tracking: 12345</li></ul></div>'

plain := htmlutils.html_to_text(raw_html)
println('Extracted text:
${plain}')
// Output:
// Order #101
// Your item has shipped!
// Tracking: 12345
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
qs := httputils.build_query_string({ 'page': '1', 'search': 'vlang' })
println(qs) // "page=1&search=vlang"
```

---

### `parse_query_string(query string) map[string]string`

Parses query string into key-value map.

```v
params := httputils.parse_query_string('?page=1&search=vlang')
println(params)
```

---

### `get_text(url string, headers map[string]string) !string`

Fetches a URL and returns text body.

```v
body := httputils.get_text('https://httpbin.org/get', {})!
println(body)
```

---

### `post_text(url string, body string, headers map[string]string) !string`

Sends an HTTP POST request with raw text payload and returns the response body.

```v
res := httputils.post_text('https://httpbin.org/post', 'hello world', {
    'Content-Type': 'text/plain'
})!
println(res.body)
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
println(user.name)
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
println(user_res.name)
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
println(res.body)
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="jsonutils"></a><a id="jsonutils-api"></a>

# jsonutils API

**Plain-language purpose:** Use `jsonutils` for advanced JSON manipulation: navigating deeply nested JSON using RFC 6901 JSON Pointers without writing complex nested map lookups, applying partial updates with RFC 7386 Merge Patch, computing structural diffs, and formatting canonical JSON for cryptographic hashing.

Import statement:

```v
import jsonutils
import json2
```

### Core Standards

- **RFC 6901 (JSON Pointer)**: String syntax for identifying a specific value within a JSON document (e.g. `/users/0/email` or `/settings/theme`).
- **RFC 7386 (JSON Merge Patch)**: Standard for applying partial updates to JSON documents (setting a key to `null` deletes it).
- **RFC 8785 (Canonical JSON)**: Deterministic encoding with sorted keys and minimal whitespace, essential for digital signatures and cache keys.

---

### JSON Pointer Navigation (`pointer_get` & `pointer_set`)

#### `pointer_get(doc json2.Any, ptr string) !json2.Any`

Quickly extract nested data from deep JSON hierarchies without unmarshaling into specific structs.

```v
import jsonutils

json_str := '
{
  "store": {
    "name": "Downtown Books",
    "inventory": [
      { "id": 1, "title": "The V Programming Language", "price": 29.99 },
      { "id": 2, "title": "Rapid Application Dev", "price": 34.50 }
    ]
  }
}'

doc := jsonutils.parse(json_str)!

// Retrieve the store name
store_name := jsonutils.pointer_get(doc, '/store/name')!
println('Store: ${store_name.str()}') // "Downtown Books"

// Retrieve the second book title (index 1)
second_title := jsonutils.pointer_get(doc, '/store/inventory/1/title')!
println('Second book: ${second_title.str()}') // "Rapid Application Dev"
```

#### `pointer_set(doc json2.Any, ptr string, val json2.Any) !json2.Any`

Updates, replaces, or inserts values at a specific JSON pointer path.

```v
import jsonutils
import json2

doc := jsonutils.parse('{"user": { "name": "Alice" }}')!

// Add a new email field
updated := jsonutils.pointer_set(doc, '/user/email', json2.Any('alice@example.com'))!
println('Updated JSON: ${updated.str()}')
// {"user":{"name":"Alice","email":"alice@example.com"}}
```

---

### RFC 7386 JSON Merge Patch

#### `merge_patch_str(target string, patch string) !string`

Applies partial updates to a JSON string. Matching fields are replaced, new fields are added, and fields with `null` values are removed.

```v
import jsonutils

original := '{"theme":"dark","volume":80,"notifications":true}'
patch    := '{"volume":95,"notifications":null,"font":"Inter"}'

// Apply merge patch
updated := jsonutils.merge_patch_str(original, patch)!
println(updated)
// Output: {"theme":"dark","volume":95,"font":"Inter"}
// (notifications was deleted because its patch value was null)
```

---

### Structural Diffs & Flattening

#### `diff(a json2.Any, b json2.Any) []Change`

Computes a list of exact structural differences between two JSON trees.

```v
import jsonutils

doc_a := jsonutils.parse('{"status": "pending", "items": [1, 2]}')!
doc_b := jsonutils.parse('{"status": "shipped", "items": [1, 2, 3]}')!

changes := jsonutils.diff(doc_a, doc_b)
for change in changes {
    println('Op: ${change.op}, Path: ${change.path}, Value: ${change.value}')
}
// Op: replace, Path: /status, Value: "shipped"
// Op: add, Path: /items/2, Value: 3
```

#### `flatten(a json2.Any) map[string]string`

Flattens deep nested JSON structures into dot-delimited single-level key-value maps.

```v
import jsonutils

doc := jsonutils.parse('{"app":{"database":{"host":"localhost","port":5432}}}')!
flat := jsonutils.flatten(doc)

for k, v in flat {
    println('${k} = ${v}')
}
// app.database.host = localhost
// app.database.port = 5432
```

---

### Canonical Formatting, Pretty Printing & Minification

```v
import jsonutils

messy_json := '{
  "b": 2,  "a": 1  
}'

// RFC 8785 Canonical JSON (keys are sorted alphabetically: "a", then "b")
canonical_json := jsonutils.canonical(messy_json)!
println(canonical_json) // '{"a":1,"b":2}'

// Format with clean 2-space indentation
pretty_json := jsonutils.pretty(canonical_json)!
println(pretty_json)

// Strip all unnecessary whitespace
minified := jsonutils.minify(pretty_json)!
println(minified) // '{"a":1,"b":2}'
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="jwtutils"></a><a id="jwtutils-api"></a>

# jwtutils API

**Plain-language purpose:** Use `jwtutils` to issue and verify tamper-proof JSON Web Tokens (JWT) for user authentication, API sessions, and inter-service authorization using secure HMAC algorithms (HS256, HS384, HS512).

Import statement:

```v
import jwtutils
```

### Core Security Principles

- **Algorithm Pinning**: Strict enforcement of the expected algorithm to prevent algorithm substitution attacks (`alg=none`).
- **Constant-Time Comparison**: Cryptographic signatures are verified in constant time to eliminate timing side-channel attacks.
- **Clock Skew Tolerance**: Configurable leeway seconds to tolerate minor clock drift between distributed servers.

---

### Quick Tokens (Simple Authentication)

#### `sign_simple_token(sub string, secret string, ttl_seconds i64) !string` & `verify_jwt`

Issues a lightweight token containing the subject ID (`sub`) with an automatic expiration timestamp (`exp`).

```v
import jwtutils

secret := 'super-secure-production-secret-key-32chars'

// Issue a token for user ID "usr_9981" valid for 1 hour (3600 seconds)
token := jwtutils.sign_simple_token('usr_9981', secret, 3600)!
println('Bearer token:
${token}')

// Verify incoming token
claims := jwtutils.verify_jwt(token, secret)!
println('Authenticated User: ${claims.sub}')
println('Token Issued At:     ${claims.iat}')
println('Token Expires At:    ${claims.exp}')
```

---

### Advanced Tokens with Registered Claims & Options

#### `sign_jwt_with` & `verify_jwt_with(token string, secret string, opts VerifyOptions) !JWTClaims`

Full control over algorithm choice, issuer, audience, and validation leeway.

```v
import jwtutils
import time

secret := 'my-secret-signing-key-for-jwt-tokens'

// 1. Create custom registered claims
now := time.now().unix()
claims := jwtutils.JWTClaims{
    sub: 'user_42'
    iss: 'https://auth.myapp.com'
    aud: 'https://api.myapp.com'
    iat: now
    exp: now + 1800 // 30 minutes
}

// 2. Sign token with SHA-512 HMAC
token := jwtutils.sign_jwt_with(claims, secret, .hs512)!

// 3. Verify with strict policy enforcement
verified_claims := jwtutils.verify_jwt_with(token, secret, jwtutils.VerifyOptions{
    algorithm:       .hs512
    issuer:          'https://auth.myapp.com'
    audience:        'https://api.myapp.com'
    require_exp:     true
    leeway_seconds:  30 // Allow up to 30s clock drift
})!

println('Successfully verified token for: ${verified_claims.sub}')
```

---

### Token Refresh & Unverified Inspection

#### `refresh_jwt(token string, secret string, ttl_seconds i64, opts VerifyOptions) !string`

Verifies an existing valid token and generates a new token with an updated expiration window.

```v
import jwtutils

secret := 'my-secret-key'
old_token := jwtutils.sign_simple_token('user_10', secret, 300)!

// Refresh for another 1 hour (3600s)
new_token := jwtutils.refresh_jwt(old_token, secret, 3600, jwtutils.VerifyOptions{})!
println('Refreshed token: ${new_token}')
```

#### `decode_jwt_unverified(token string) !JWTClaims`

Parses claims without verifying the cryptographic signature (use *only* for unauthenticated routing or log inspection; never use unverified claims for authorization).

```v
import jwtutils

token := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.do_not_trust_signature'
claims := jwtutils.decode_jwt_unverified(token)!
println('Subject identifier: ${claims.sub}')
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="logutils"></a><a id="logutils-api"></a>

# logutils API

**Plain-language purpose:** Use `logutils` for production-grade logging. Print colorized logs to the terminal, write structured logs to disk, format output as standard key-value (`logfmt`) or JSON records for cloud log services, automatically redact sensitive passwords, and rotate large log files.

Import statement:

```v
import logutils
```

### Log Levels

- `.debug`: Verbose debugging information
- `.info`: Normal operational events
- `.warn`: Non-critical warnings
- `.error`: Recoverable errors and operation failures
- `.fatal`: Critical crashes (prints error and calls `exit(1)`)

---

### Standard Leveled Logging

#### `new_logger(cfg LoggerConfig) Logger`

Creates a logger with customized destination and minimum level filter.

```v
import logutils

// Create a logger outputting to terminal
mut logger := logutils.new_logger(
    level:          .debug
    output:         .stdout // .stdout, .stderr, .file, or .both
    show_timestamp: true
    colored:        true
)

logger.debug('Connecting to database on port 5432...')
logger.info('Database connection established')
logger.warn('Disk space usage is at 82%')
logger.error('Failed to load profile photo: file not found')
```

#### File Logging & Dynamic Level Changes

```v
import logutils

mut logger := logutils.new_logger(
    level:     .info
    output:    .file
    file_path: 'app.log'
)

logger.info('Writing logs directly to file')

// Dynamically change logging level at runtime
logger.set_level(.warn)
logger.info('This will be ignored (below .warn)')
logger.warn('This warning will be written to app.log')
```

---

### Structured Logging (Logfmt & JSON)

#### `log_kv(level LogLevel, msg string, fields map[string]string)`

Outputs in clean `logfmt` key-value format (popular in Heroku, Grafana Loki, and modern DevOps tooling).

```v
import logutils

mut logger := logutils.new_logger(level: .info, output: .stdout)

logger.log_kv(.info, 'user_action', {
    'user_id': '42'
    'action':  'checkout'
    'amount':  '49.99'
})
// Output: [INFO] user_action action=checkout amount=49.99 user_id=42
```

#### `log_json(level LogLevel, msg string, fields map[string]string)`

Outputs newline-delimited JSON records (ideal for Datadog, AWS CloudWatch, and Elasticsearch).

```v
import logutils

mut logger := logutils.new_logger(level: .info, output: .stdout)

logger.log_json(.error, 'api_failure', {
    'endpoint': '/api/v1/users'
    'status':   '500'
    'ip':       '192.168.1.10'
})
// Output: {"ts":"2026-10-10T12:00:00Z","level":"error","msg":"api_failure","endpoint":"/api/v1/users","ip":"192.168.1.10","status":"500"}
```

---

### Security: Credential Redaction & Log Rotation

#### `redact_fields(fields map[string]string, secret_keys []string) map[string]string`

Automatically masks passwords, bearer tokens, and API secrets with `[REDACTED]`.

```v
import logutils

raw_fields := {
    'user':         'john_doe'
    'password':     'super_secret_pw'
    'api_key':      'sk_live_9981881'
    'access_token': 'ghp_xxxx'
}

// Built-in secret keys automatically mask password, secret, token, api_key, etc.
safe_fields := logutils.redact_fields(raw_fields, logutils.default_secret_keys)
println(safe_fields['password'])     // "[REDACTED]"
println(safe_fields['api_key'])      // "[REDACTED]"
println(safe_fields['access_token']) // "[REDACTED]"
println(safe_fields['user'])         // "john_doe" (preserved)
```

#### `rotate_file(path string, max_bytes i64, keep int) !bool`

Rotates a log file when it exceeds `max_bytes`, keeping up to `keep` archive copies (e.g. `app.log.1`, `app.log.2`).

```v
import logutils

// Rotate app.log if it exceeds 10 MB (10,485,760 bytes), keeping up to 5 backups
rotated := logutils.rotate_file('app.log', 10 * 1024 * 1024, 5)!
if rotated {
    println('Log file was rotated')
}
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="markdownutils"></a><a id="markdownutils-api"></a>

# markdownutils API

**Plain-language purpose:** Use `markdownutils` to convert Markdown text into clean, safe HTML (with support for GitHub tables, task lists, and syntax blocks), auto-generate clickable Tables of Contents, and extract plain-text previews.

Import statement:

```v
import markdownutils
```

### Features

- **Safe HTML**: JavaScript URLs (`javascript:`) and malicious handlers are neutralized by default.
- **GFM Extensions**: Tables with alignment, task checkboxes (`- [ ]`, `- [x]`), fenced code blocks, and blockquotes.
- **Navigation**: Generates slugified heading anchors (`#my-heading`) and clickable Table of Contents.

---

### Converting Markdown to HTML

#### `to_html(md string, opts Options) string`

Translates Markdown syntax into semantic HTML elements.

```v
import markdownutils

md := '
# Project Overview

Welcome to the **vlang_utils** toolkit!

### Features
- [x] Fast & compiled
- [ ] Needs documentation

| Feature | Status |
| :--- | :--- |
| SQLite | Supported |
| JSON | Supported |

```v
import strutils
println("Hello")
```
'

html := markdownutils.to_html(md, markdownutils.Options{
    heading_ids: true // Adds id="project-overview" to headings for anchor links
})
println(html)
```

---

### Generating Tables of Contents & Heading Slugs

#### `toc(md string, max_level int) string`

Generates an indented Markdown Table of Contents linking to heading anchors up to `max_level` (e.g. 1 to 3).

```v
import markdownutils

document := '
# Getting Started
## Installation
### From Binary
## Configuration
# Advanced Usage
'

toc_markdown := markdownutils.toc(document, 3)
println('Table of Contents:
${toc_markdown}')
/*
Output:
- [Getting Started](#getting-started)
  - [Installation](#installation)
    - [From Binary](#from-binary)
  - [Configuration](#configuration)
- [Advanced Usage](#advanced-usage)
*/
```

#### `slug(text string) string`

Converts any arbitrary heading text into a clean URL-friendly anchor ID.

```v
import markdownutils

println(markdownutils.slug('Getting Started with V!')) // "getting-started-with-v"
println(markdownutils.slug('Feature #1: SQLite & DB'))  // "feature-1-sqlite-db"
```

---

### Plain-Text Extraction (Previews & Excerpts)

#### `to_plain_text(md string) string`

Strips all Markdown formatting symbols, producing clean, human-readable text suitable for search snippets, push notifications, and blog previews.

```v
import markdownutils

markdown_summary := '## Update Available!

Please check **Settings** -> `System` to update.'
preview := markdownutils.to_plain_text(markdown_summary)
println(preview)
// Output: "Update Available! Please check Settings -> System to update."
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="mathutils"></a><a id="mathutils-api"></a>

# mathutils API

**Plain-language purpose:** Use `mathutils` for everyday numerical calculations, clamping and remapping values (like volume or UI sliders), 2D vector geometry, GPS distance calculation, and number theory functions (primes, GCD, LCM).

Import statement:

```v
import mathutils
```

### Clamping, Interpolation & Snapping

#### `clamp(v f64, min f64, max f64) f64` & `clamp_int(v int, min int, max int) int`

Restricts a numerical value within an allowed lower and upper bound.

```v
import mathutils

// Ensure sound volume is strictly between 0% and 100%
volume := mathutils.clamp(120.0, 0.0, 100.0)
println('Clamped volume: ${volume}') // 100.0

level := mathutils.clamp_int(-5, 0, 10)
println('Clamped level: ${level}')   // 0
```

#### `lerp(a f64, b f64, t f64) f64` & `inverse_lerp(a f64, b f64, v f64) f64`

Linear interpolation for animations, camera transitions, and UI easing. `t` ranges from `0.0` (start) to `1.0` (end).

```v
import mathutils

// At 0% progress (t=0.0) -> 10.0; at 50% (t=0.5) -> 30.0; at 100% (t=1.0) -> 50.0
pos := mathutils.lerp(10.0, 50.0, 0.5)
println('Midpoint: ${pos}') // 30.0

// Find where a value sits proportionally between two bounds
progress := mathutils.inverse_lerp(10.0, 50.0, 30.0)
println('Progress percentage: ${progress * 100}%') // 50%
```

#### `remap(v f64, in_min f64, in_max f64, out_min f64, out_max f64) f64`

Converts a number from one range into another proportional range (e.g. mapping a 0-100 sensor reading to a 0-255 RGB byte).

```v
import mathutils

// Map slider percentage (0 to 100) to RGB brightness (0 to 255)
brightness := mathutils.remap(50.0, 0.0, 100.0, 0.0, 255.0)
println('Brightness: ${brightness}') // 127.5
```

#### `round_to_step(v f64, step f64) f64` & `round_to(v f64, decimals int) f64`

Snaps a continuous number to a specific grid step or decimal precision.

```v
import mathutils

// Snap item position to 16-pixel tile grid
snapped := mathutils.round_to_step(35.2, 16.0)
println('Snapped to 16px: ${snapped}') // 32.0

// Round currency to 2 decimal places
rounded := mathutils.round_to(19.8765, 2)
println('Rounded: ${rounded}') // 19.88
```

---

### 2D Geometry & Spatial Distance

#### `Point2D[T]`, `distance[T](p1 Point2D[T], p2 Point2D[T]) f64`

Represents points in 2D coordinate space and measures Euclidean distances.

```v
import mathutils

p1 := mathutils.Point2D[f64]{ x: 0.0, y: 0.0 }
p2 := mathutils.Point2D[f64]{ x: 3.0, y: 4.0 }

dist := mathutils.distance(p1, p2)
println('Distance between points: ${dist}') // 5.0 (Pythagorean 3-4-5 triangle)
```

#### GPS Geographic Distance (`haversine_km`)

Calculates the great-circle distance between two GPS latitude/longitude coordinates on Earth in kilometers.

```v
import mathutils

// New York City (40.7128° N, 74.0060° W) to London (51.5074° N, 0.1278° W)
nyc_lat := 40.7128
nyc_lon := -74.0060
lon_lat := 51.5074
lon_lon := -0.1278

dist_km := mathutils.haversine_km(nyc_lat, nyc_lon, lon_lat, lon_lon)
println('Distance NYC to London: ${dist_km:.1f} km') // ~5570 km
```

#### 2D Vectors (`Vec2`)

Vector mathematics for game development, physics, and canvas rendering.

```v
import mathutils

v1 := mathutils.Vec2{ x: 2.0, y: 3.0 }
v2 := mathutils.Vec2{ x: 4.0, y: 1.0 }

sum := v1.add(v2)
scaled := v1.scale(2.0)
len := v1.length()
norm := v1.normalize()

println('Sum: (${sum.x}, ${sum.y})')       // (6.0, 4.0)
println('Scaled: (${scaled.x}, ${scaled.y})') // (4.0, 6.0)
println('Vector Length: ${len:.2f}')
```

---

### Number Theory & Prime Calculations

#### `is_prime(n u64) bool`, `primes_up_to(limit int) []int`

Miller-Rabin deterministic primality testing and Sieve of Eratosthenes.

```v
import mathutils

println('17 is prime: ${mathutils.is_prime(17)}') // true
println('18 is prime: ${mathutils.is_prime(18)}') // false

// Generate all prime numbers up to 30
primes := mathutils.primes_up_to(30)
println('Primes up to 30: ${primes}')
// [2, 3, 5, 7, 11, 13, 17, 19, 23, 29]
```

#### `gcd(a i64, b i64) i64` & `lcm(a i64, b i64) i64`

Greatest Common Divisor and Least Common Multiple.

```v
import mathutils

println('GCD of 48 and 18: ${mathutils.gcd(48, 18)}') // 6
println('LCM of 12 and 15: ${mathutils.lcm(12, 15)}') // 60
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
chunks := sliceutils.chunk([1, 2, 3, 4, 5], 2)
println(chunks) // [[1, 2], [3, 4], [5]]
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
idx := sliceutils.find_index([10, 20, 30], fn (x int) bool { return x > 15 })
println(idx) // 1
```

---

### `partition[T](arr []T, pred fn (item T) bool) ([]T, []T)`

Partitions elements into two slices: those matching the predicate and those that do not.

```v
evens, odds := sliceutils.partition([1, 2, 3, 4], fn (x int) bool { return x % 2 == 0 })
println(evens) // [2, 4]
println(odds)  // [1, 3]
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
println(picks)
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
min_val := sliceutils.min_int(nums) or { 0 }
max_val := sliceutils.max_int(nums) or { 0 }
println('min: ${min_val}, max: ${max_val}') // min: 3, max: 88
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
min_f := sliceutils.min_f64(floats) or { 0.0 }
max_f := sliceutils.max_f64(floats) or { 0.0 }
println('min: ${min_f}, max: ${max_f}') // min: -2.5, max: 8.2
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
println(safe_table)
assert sqliteutils.is_valid_identifier('users') == true
assert sqliteutils.is_valid_identifier('users; DROP TABLE users;') == false
```

#### `escape_string(s string) string`

Doubles single quotes according to SQL-92 standards (`'` -> `''`). Parameterized queries should always be favored over string interpolation.

```v
safe_literal := sqliteutils.escape_string("O'Connor")
println(safe_literal) // "O''Connor"
```

#### `sanitize_sql_type(sql_type string) !string`

Validates that a SQL column type definition (e.g. `TEXT`, `INTEGER NOT NULL`, `VARCHAR(255)`) contains only safe characters, balanced delimiters, no comment injection (`--`, `/*`), and no statement separators (`;`).

```v
safe_type := sqliteutils.sanitize_sql_type('VARCHAR(255) NOT NULL')!
println(safe_type)
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
println('App data dir: ${data_dir}, config dir: ${config_dir}')
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

#### SQLite Direct Functions

Save and load application structs directly to and from SQLite database files:

- `save_app_state_sqlite[T](app_name string, filename string, state T) !`
- `load_app_state_sqlite[T](app_name string, filename string) !T`
- `load_app_state_sqlite_or[T](app_name string, filename string, default_val T) T`
- `app_state_sqlite_exists(app_name string, filename string) bool`
- `delete_app_state_sqlite(app_name string, filename string) !`
- `save_app_state_with_backend[T](app_name string, filename string, state T, backend StateBackend) !`
- `load_app_state_with_backend[T](app_name string, filename string, backend StateBackend) !T`
- `load_app_state_with_backend_or[T](app_name string, filename string, default_val T, backend StateBackend) T`

```v
import stateutils

struct UserPrefs {
    theme string
    sound bool
}

// Persist struct to SQLite database (state.db)
stateutils.save_app_state_sqlite('my_app', 'prefs.db', UserPrefs{ theme: 'dark', sound: true })!

// Load struct from SQLite database
prefs := stateutils.load_app_state_sqlite[UserPrefs]('my_app', 'prefs.db')!
println('Loaded SQLite theme: ${prefs.theme}')

// Unified backend switching
stateutils.save_app_state_with_backend('my_app', 'prefs.db', prefs, .sqlite)!
```

---

### `AppStateStore[T]` - Managed Generic Store

Manages in-memory state, disk/database persistence, auto-saving, backups, and rollback. Backed by either **JSON** or **SQLite database**.

- `new_app_state[T](app_name string, default_data T) AppStateStore[T]` (JSON default)
- `new_app_state_with_file[T](app_name string, filename string, default_data T, loc StateLocation) AppStateStore[T]`
- `new_app_state_with_backend[T](app_name string, default_data T, backend StateBackend) AppStateStore[T]`
- `new_app_state_with_config[T](app_name string, default_data T, cfg StateStoreConfig) AppStateStore[T]`
- `new_sqlite_app_state[T](app_name string, default_data T) AppStateStore[T]` (SQLite database)
- `new_sqlite_app_state_with_file[T](app_name string, filename string, default_data T, loc StateLocation) AppStateStore[T]`
- `new_sqlite_app_state_with_table[T](app_name string, filename string, table_name string, default_data T, loc StateLocation) AppStateStore[T]`

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

// SQLite-backed state store (state.db in OS data dir)
mut sqlite_store := stateutils.new_sqlite_app_state[Settings]('my_app', Settings{
    window_w: 1920
    window_h: 1080
    theme:    'nord'
})
sqlite_store.save()!

// Custom SQLite filename and table:
mut custom_sqlite := stateutils.new_sqlite_app_state_with_table[Settings](
    'my_app', 'workspace.db', 'window_settings', Settings{}, .data
)

// Access current state
println('Window width: ${store.get().window_w}')

// Modify state via updater callback
store.update(fn (mut s Settings) {
    s.window_w = 1920
    s.theme = 'dracula'
    s.recent_files << 'main.v'
})!
store.save()! // persists atomically

// Backup & Rollback (supports both JSON and SQLite)
bak_file := store.backup()! // saves ${path}.bak
println('Backup saved: ${bak_file}')
store.set(Settings{ window_w: 800, window_h: 600, theme: 'light' })!
store.rollback()! // reverts from .bak

// Auto-save mode (automatically persists whenever state changes)
store.auto_save = true
store.update(fn (mut s Settings) {
    s.theme = 'solarized'
})! // automatically saved to disk/db
```

#### Struct Evolution & Dynamic Expansion

When an application needs to store more data than originally created:
- **Default Field Values**: Newly added fields in your struct should declare sensible default values (e.g. `recent_files []string = []`, `zoom f64 = 1.0`). When loading existing state files created by earlier versions, existing fields retain their values and new fields automatically take their defaults.
- **Dynamic Extension Map (`extra map[string]string`)**: Embed a string map in your struct to hold arbitrary runtime keys and metadata without modifying the struct schema.

```v
struct AppConfigV2 {
pub mut:
    // Original V1 fields
    title        string
    width        int
    // Newly added V2 fields with defaults:
    height       int               = 600
    dark_mode    bool              = true
    recent_files []string          = []
    // Open-ended dynamic runtime extension:
    extra        map[string]string = map[string]string{}
}

mut v2_store := stateutils.new_app_state[AppConfigV2]('my_app', AppConfigV2{})
v2_store.update(fn (mut s AppConfigV2) {
    s.recent_files << '/path/to/project'
    s.extra['custom_key'] = 'custom_value'
})!
v2_store.save()!
```

---

### `KeyValueState` - Dynamic App State

For apps that need schema-free configuration and preferences. Supports both **JSON** and **SQLite database** backends.

- `new_kv_state(app_name string) KeyValueState` (JSON default)
- `new_kv_state_with_file(app_name string, filename string, loc StateLocation) KeyValueState`
- `new_kv_state_with_backend(app_name string, backend StateBackend) KeyValueState`
- `new_kv_state_with_config(app_name string, cfg StateStoreConfig) KeyValueState`
- `new_sqlite_kv_state(app_name string) KeyValueState` (SQLite database)
- `new_sqlite_kv_state_with_file(app_name string, filename string, loc StateLocation) KeyValueState`
- `new_sqlite_kv_state_with_table(app_name string, filename string, table_name string, loc StateLocation) KeyValueState`

```v
import stateutils

// JSON-backed key-value store
mut kv := stateutils.new_kv_state('my_app')
kv.auto_save = true

// SQLite-backed key-value store
mut sqlite_kv := stateutils.new_sqlite_kv_state('my_app')
sqlite_kv.auto_save = true

// Typed setters & getters with fallbacks (works identically on JSON and SQLite)
sqlite_kv.set_str('current_profile', 'guest')!
sqlite_kv.set_int('volume', 85)!
sqlite_kv.set_bool('notifications', true)!
sqlite_kv.set_f64('scale', 1.5)!
sqlite_kv.set_strings('tags', ['alpha', 'beta', 'release'])!

profile := sqlite_kv.get_str('current_profile', 'default')
volume  := sqlite_kv.get_int('volume', 100)
notify  := sqlite_kv.get_bool('notifications', false)
scale   := sqlite_kv.get_f64('scale', 1.0)
tags    := sqlite_kv.get_strings('tags', [])
println('${profile}, vol=${volume}, notify=${notify}, scale=${scale}, tags=${tags}')

// Management
println('Has volume: ${sqlite_kv.has("volume")}')
sqlite_kv.delete('scale')!
keys := sqlite_kv.keys()
all_data := sqlite_kv.all()
println('All data: ${all_data}')

// Backup and rollback
bak := sqlite_kv.backup()!
sqlite_kv.rollback()!

sqlite_kv.clear()!
sqlite_kv.reset()! // clears memory and deletes state database from disk
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

println('sum=${total}, mean=${mean}, median=${median}, mode=${mode}')
println('geom=${geom_mean}, harm=${harm_mean}, rms=${rms}, weighted=${w_mean}, trimmed=${t_mean}')
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

println('min=${min_val}, max=${max_val}, span=${span}')
println('variance: pop=${pop_var}, sample=${sample_var}; std_dev: pop=${pop_std}, sample=${sample_std}')
println('sem=${sem}, p50=${p50}, p95=${p95}, quartiles=(${q1}, ${q2}, ${q3}), iqr=${iqr}')
println('cov=${cov}, mad=${mad}')
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

println('Skewness: ${skew}, Kurtosis: ${kurt}')
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

println('Cov: ${cov}, Sample Cov: ${sample_cov}, Pearson: ${pearson_r}, Spearman: ${spearman_r}')

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

println('PDF: ${pdf}, CDF: ${cdf}, Z: ${single_z}')
println('Standardized: ${standardized_data}, Normalized: ${normalized}')
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
println('SMA: ${sma}')
println('EMA: ${ema}')
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

<a id="structutils"></a><a id="structutils-api"></a>

# structutils API

**Plain-language purpose:** Use `structutils` when you need classic, high-performance data structures beyond basic arrays and maps: Stacks (undo/redo), Queues (job processing), Circular Ring Buffers (audio/logging), Priority Queues, Double-ended Deques, Prefix Trees (Trie autocomplete), Bloom Filters (membership checking without disk IO), and HyperLogLog (counting millions of unique users in tiny memory).

Import statement:

```v
import structutils
```

### 1. Generic Stack (LIFO - Last In, First Out)

Ideal for undo/redo history, syntax expression parsing, and backtracking.

```v
import structutils

mut stack := structutils.new_stack[string]()

stack.push('Page 1')
stack.push('Page 2')
stack.push('Page 3')

println('Current top: ${stack.peek() or { "" }}') // "Page 3"
println('Popped:      ${stack.pop() or { "" }}')  // "Page 3"
println('Remaining:   ${stack.len()}')            // 2
```

---

### 2. Generic Queue (FIFO - First In, First Out)

Ideal for background job pipelines, task schedulers, and breadth-first search queues.

```v
import structutils

mut queue := structutils.new_queue[string]()

queue.push('Task A')
queue.push('Task B')
queue.push('Task C')

println('Next to process: ${queue.peek() or { "" }}') // "Task A"
println('Processed:       ${queue.pop() or { "" }}')  // "Task A"
println('Remaining jobs:  ${queue.len()}')            // 2
```

---

### 3. Circular Ring Buffer (Fixed Capacity)

A memory-efficient fixed-size buffer that automatically wraps around without reallocating memory. Great for maintaining the last N log entries or streaming audio samples.

```v
import structutils

// Create a ring buffer with maximum capacity of 3 items
mut ring := structutils.new_ring_buffer[string](3)

ring.push('log_1')
ring.push('log_2')
ring.push('log_3')
println('Buffer full: ${ring.is_full()}') // true

// Pushing a 4th item overwrites the oldest item ('log_1')
ring.push('log_4')

println('Current items: ${ring.to_array()}') // ['log_2', 'log_3', 'log_4']
```

---

### 4. Generic Set (`GenericSet[T]`)

Stores unique elements with fast O(1) membership checks and deduplication.

```v
import structutils

mut active_users := structutils.new_set[string]()

active_users.add('alice')
active_users.add('bob')
active_users.add('alice') // Duplicate is ignored

println('Unique users: ${active_users.size()}') // 2
println('Has alice:    ${active_users.contains("alice")}') // true
println('Has charlie:  ${active_users.contains("charlie")}') // false

active_users.remove('bob')
println('After removal: ${active_users.to_array()}') // ['alice']
```

---

### 5. Priority Queue (`PriorityQueue[T]`)

Extracts elements ordered by priority (min or max) using a heap.

```v
import structutils

struct Job {
    name     string
    priority int // Lower number = higher priority
}

// Create priority queue where job with lowest priority number comes out first
mut pq := structutils.new_priority_queue[Job](fn (a Job, b Job) bool {
    return a.priority < b.priority
})

pq.push(Job{ name: 'Low Priority Clean Up', priority: 10 })
pq.push(Job{ name: 'Critical Bug Fix',      priority: 1 })
pq.push(Job{ name: 'Feature Implementation', priority: 5 })

// Highest priority (lowest number) pops first
first := pq.pop() or { panic('empty') }
println('First job: ${first.name}') // "Critical Bug Fix"
```

---

### 6. Double-Ended Queue (`Deque[T]`)

Allows efficient O(1) insertions and deletions at both the beginning and the end.

```v
import structutils

mut deque := structutils.new_deque[string]()

deque.push_back('Middle')
deque.push_front('First')
deque.push_back('Last')

println('Deque items: ${deque.to_array()}') // ['First', 'Middle', 'Last']
println('Pop front:   ${deque.pop_front() or { "" }}') // 'First'
println('Pop back:    ${deque.pop_back() or { "" }}')  // 'Last'
```

---

### 7. Prefix Tree (`Trie`) for Search Autocompletion

Stores words in a tree structure to quickly search for all words matching a typed prefix.

```v
import structutils

mut trie := structutils.new_trie()

// Insert dictionary words
trie.insert('apple')
trie.insert('application')
trie.insert('apply')
trie.insert('banana')

// Autocomplete suggestions for prefix "app" (up to 5 results)
suggestions := trie.with_prefix('app', 5)
println('Suggestions for "app": ${suggestions}')
// ['apple', 'application', 'apply']
```

---

### 8. Bloom Filter (Fast Probabilistic Membership)

Checks if an element is definitely not present or possibly present, without querying slow databases or disks.

```v
import structutils

// Expecting ~1,000 items with a 1% (0.01) false positive rate
mut bloom := structutils.new_optimal_bloom(1000, 0.01)!

bloom.add('https://spammy-site.com')
bloom.add('https://phishing-link.org')

println('Blocked: ${bloom.contains("https://spammy-site.com")}') // true
println('Safe:    ${bloom.contains("https://google.com")}')      // false
```

---

### 9. HyperLogLog (Massive Cardinality Counting)

Estimates the count of unique items (e.g. unique website visitors) using only a few kilobytes of RAM for billions of items.

```v
import structutils

// Precision parameter 12 uses ~4 KB of memory
mut hll := structutils.new_hyperloglog(12)!

// Add millions of events (duplicates are automatically handled)
hll.add('visitor_ip_1')
hll.add('visitor_ip_2')
hll.add('visitor_ip_1') // duplicate
hll.add('visitor_ip_3')

println('Estimated unique visitors: ${hll.count()}') // ~3
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
println(custom_code)
```

---

### `random_alphanumeric(len int) string`

Generates a random string containing letters (A-Z, a-z) and digits (0-9).

```v
token := strutils.random_alphanumeric(16)
println(token)
```

---

### `random_hex(len int) string`

Generates a random lowercase hexadecimal string of length `len`.

```v
hex_token := strutils.random_hex(32)
println(hex_token)
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
println(wrapped)
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
score := strutils.similarity('hello', 'hallo')
println(score) // ~0.8
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
println('Swap: ${used_swap / (1024 * 1024)} MB / ${total_swap / (1024 * 1024)} MB (${swap_pct:.1f}%)')
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
println('${safe_arg}, ${safe_path}, ${clean_name}')
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
println('Process running: ${running}')
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
println('Data dir: ${data_dir}, Config file path: ${cfg_file}')
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
println('Clipboard: ${clip}')

// Desktop notification & speech
sysutils.notify('Build Complete', 'All 15 modules compiled successfully!')
sysutils.say('Build finished successfully') or {}
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="tarutils"></a><a id="tarutils-api"></a>

# tarutils API

**Plain-language purpose:** Use `tarutils` to create and extract standard Unix `.tar` and `.tar.gz` archive bundles, package complete directory trees with relative paths, inspect archive headers without disk writes, and read files directly from inside archives.

Import statement:

```v
import tarutils
```

### Core Formats

- **`.tar`**: Uncompressed tape archive packaging multiple files into one sequential container.
- **`.tar.gz` / `.tgz`**: Gzip-compressed tar archive commonly used for software distribution and Linux backups.

---

### Creating & Extracting Tar Archives

#### `create_tar(tar_path string, file_paths []string) !bool`

Bundles a list of files into a `.tar` archive file.

```v
import tarutils

files := ['src/main.v', 'v.mod', 'README.md']
tarutils.create_tar('dist/bundle.tar', files)!
println('Archive bundle created successfully!')
```

#### `create_tar_from_dir(tar_path string, src_dir string) !int`

Recursively bundles an entire folder tree into a `.tar` archive. Returns the total count of files packaged.

```v
import tarutils

count := tarutils.create_tar_from_dir('backup/assets.tar', 'assets/')!
println('Archived ${count} files from assets folder')
```

#### `extract_tar(tar_path string, dest_dir string) !bool`

Unpacks all files from a `.tar` archive into the target destination directory (with built-in path-traversal safety protection against `../` malicious paths).

```v
import tarutils

tarutils.extract_tar('dist/bundle.tar', 'extracted_files/')!
println('Extracted all files to extracted_files/')
```

---

### Compressed `.tar.gz` Archives

#### `create_tar_gz_from_dir` & `extract_tar_gz`

Directly bundles and compresses directory trees in a single step.

```v
import tarutils

// Pack and compress directory into release.tar.gz
count := tarutils.create_tar_gz_from_dir('release.tar.gz', 'build/')!
println('Compressed ${count} files into release.tar.gz')

// Extract compressed archive
tarutils.extract_tar_gz('release.tar.gz', 'unpacked_release/')!
```

---

### In-Memory Inspection & Direct File Reading

#### `list_tar_entries(tar_path string) ![]TarEntry`

Inspects archive contents without unpacking anything to the filesystem.

```v
import tarutils

entries := tarutils.list_tar_entries('dist/bundle.tar')!

for entry in entries {
    println('File: ${entry.name:20} Size: ${entry.size} bytes')
}
```

#### `read_tar_file(tar_path string, filename string) !string`

Reads the contents of a specific file directly from inside an archive into memory.

```v
import tarutils

// Read README.md without extracting the entire archive
readme_text := tarutils.read_tar_file('dist/bundle.tar', 'README.md')!
println('README contents:
${readme_text}')
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="templateutils"></a><a id="templateutils-api"></a>

# templateutils API

**Plain-language purpose:** Use `templateutils` for text formatting and templating: simple placeholder substitution (`{{key}}`), dynamic callback replacement, and full logic-less Mustache templates (loops, conditionals, and HTML escaping).

Import statement:

```v
import templateutils
```

### Simple String Interpolation

#### `render_template(template string, vars map[string]string) string`

Replaces `{{key}}` tokens with matching values from a dictionary. Unmatched tokens remain untouched.

```v
import templateutils

tpl := 'Hello, {{name}}! You have {{count}} unread messages in {{folder}}.'
vars := {
    'name':   'Alex'
    'count':  '5'
    'folder': 'Inbox'
}

rendered := templateutils.render_template(tpl, vars)
println(rendered)
// Output: Hello, Alex! You have 5 unread messages in Inbox.
```

#### `render_template_fn(template string, resolver fn(string) ?string) string`

Dynamically resolves placeholders using a custom lookup function (great for database queries or environment variable expansion).

```v
import templateutils
import os

tpl := 'Running on host: {{HOSTNAME}}, home directory: {{HOME}}'

rendered := templateutils.render_template_fn(tpl, fn (key string) ?string {
    val := os.getenv(key)
    return if val != '' { val } else { none }
})
println(rendered)
```

---

### Logic-Less Mustache Templates (`render_mustache`)

#### `render_mustache(template string, data map[string]Value) !string`

Full Mustache templating supporting variable tags, conditional sections, loops, and raw unescaped values.

```v
import templateutils

// Template demonstrating variables, conditionals, and loops
tpl := '
<h1>{{title}}</h1>
{{#has_items}}
<ul>
  {{#items}}
  <li>{{name}} - \${{price}}</li>
  {{/items}}
</ul>
{{/has_items}}
{{^has_items}}
<p>No items found in stock.</p>
{{/has_items}}
'

// Prepare template data
data := {
    'title':     templateutils.str_val('Store Catalog')
    'has_items': templateutils.bool_val(true)
    'items':     templateutils.list_val([
        templateutils.map_val({
            'name':  templateutils.str_val('Mechanical Keyboard')
            'price': templateutils.str_val('89.99')
        }),
        templateutils.map_val({
            'name':  templateutils.str_val('Wireless Mouse')
            'price': templateutils.str_val('49.50')
        })
    ])
}

output := templateutils.render_mustache(tpl, data)!
println(output)
```

---

### Terminal Markdown Rendering

#### `render_markdown_ansi(markdown string) string`

Renders basic Markdown headers, bold, and bullet points directly to terminal ANSI color codes.

```v
import templateutils

md := '# Important Notice
**All servers** will restart at midnight.'
colored_terminal_text := templateutils.render_markdown_ansi(md)
println(colored_terminal_text)
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
println(parsed)
```

---

### `start_of_day(t time.Time) time.Time` & `end_of_day(t time.Time) time.Time`

Returns 00:00:00.000 or 23:59:59.999 for the given date.

```v
today_start := timeutils.start_of_day(time.now())
println(today_start)
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

<a id="tomlutils"></a><a id="tomlutils-api"></a>

# tomlutils API

**Plain-language purpose:** Use `tomlutils` to parse and load configuration files (`config.toml`, `v.mod`), read typed configuration parameters with safe defaults, and encode/decode V structs directly to and from TOML.

Import statement:

```v
import tomlutils
```

### Parsing TOML Documents

#### `parse(text string) !TomlDoc` & `parse_file(path string) !TomlDoc`

Parses TOML text or files into an easy-to-query `TomlDoc` object.

```v
import tomlutils

toml_content := '
[server]
host = "127.0.0.1"
port = 8080
enable_ssl = false
timeout_seconds = 30.5

[database]
name = "production_db"
max_connections = 50

[features]
flags = ["auth", "billing", "metrics"]
'

doc := tomlutils.parse(toml_content)!
```

---

### Typed Getters with Defaults (Zero Guesswork)

Extract values safely. If a key is missing or formatted incorrectly, the provided default is returned automatically without crashing.

```v
import tomlutils

doc := tomlutils.parse('
app_name = "Dashboard"
port = 3000
debug = true
rates = [1.2, 3.4, 5.6]
')!

// Strings
app := doc.get_string('app_name', 'DefaultApp') // "Dashboard"
missing := doc.get_string('missing_key', 'fallback') // "fallback"

// Numbers & Booleans
port := doc.get_int('port', 8080)   // 3000
debug := doc.get_bool('debug', false) // true

// String and Float Arrays
tags := doc.get_strings('tags')     // [] (if missing)
rates := doc.get_f64s('rates')      // [1.2, 3.4, 5.6]

// Check key existence
if doc.has('port') {
    println('Port is configured')
}
```

---

### Struct Decoding & Encoding

#### `decode[T](text string) !T` & `encode[T](value T) string`

Directly deserialize TOML configurations into strongly-typed V structs and serialize them back.

```v
import tomlutils

struct ServerConfig {
pub:
    host string
    port int
    ssl  bool
}

raw_toml := '
host = "0.0.0.0"
port = 9000
ssl = true
'

// Parse into struct
cfg := tomlutils.decode[ServerConfig](raw_toml)!
println('Server listening on ${cfg.host}:${cfg.port} (SSL: ${cfg.ssl})')

// Serialize struct back to TOML
encoded := tomlutils.encode(cfg)
println('Serialized TOML:
${encoded}')
```

#### `to_json() string`

Converts a loaded TOML configuration into a standard JSON string.

```v
import tomlutils

doc := tomlutils.parse('title = "App Config"
version = 2')!
json_str := doc.to_json()
println('Converted JSON: ${json_str}') // {"title":"App Config","version":2}
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="urlutils"></a><a id="urlutils-api"></a>

# urlutils API

**Plain-language purpose:** Use `urlutils` to parse, construct, and normalize web URLs, inspect query parameters, resolve relative links against a base address (RFC 3986), check CORS same-origin policies, and sanitize credentials from log outputs.

Import statement:

```v
import urlutils
```

### Parsing & URL Inspection

#### `parse_url(raw_url string) !URL`

Breaks a URL down into its standard components (`scheme`, `host`, `port`, `path`, `query`, `fragment`).

```v
import urlutils

u := urlutils.parse_url('https://admin:secret@api.example.com:8443/v1/users?role=admin&sort=asc#results')!

println('Scheme:   ${u.scheme}')             // "https"
println('Host:     ${u.host}')               // "api.example.com"
println('Port:     ${u.port}')               // 8443
println('Path:     ${u.path}')               // "/v1/users"
println('Query:    ${u.query}')              // "role=admin&sort=asc"
println('Fragment: ${u.fragment}')           // "results"
println('Origin:   ${u.origin()}')           // "https://api.example.com:8443"
println('Segments: ${u.path_segments()}')    // ['v1', 'users']
```

---

### Query Parameter Manipulation

#### `set_query_param`, `delete_query_param`, `encode_query`

Build and modify query strings cleanly without string concatenation errors.

```v
import urlutils

mut u := urlutils.parse_url('https://example.com/search')!

// Add query parameters
u.set_query_param('q', 'vlang tutorials')
u.set_query_param('page', '1')
u.set_query_param('filter', 'recent')

println('Updated URL: ${u.str()}')
// https://example.com/search?filter=recent&page=1&q=vlang+tutorials

// Remove parameter
u.delete_query_param('filter')
println('After removal: ${u.str()}')

// Encode standalone parameter map
query_string := urlutils.encode_query({
    'category': 'books'
    'limit':    '25'
})
println('Query string: ${query_string}') // category=books&limit=25
```

---

### RFC 3986 Relative URL Resolution

#### `resolve_reference(base string, ref string) !string`

Resolves relative paths, links, and dot segments against a base URL (exactly how web browsers handle `<a href="...">` links).

```v
import urlutils

base := 'https://example.com/docs/api/v1/'

// Relative link in same directory
link1 := urlutils.resolve_reference(base, 'users.html')!
println(link1) // "https://example.com/docs/api/v1/users.html"

// Relative link going up one directory
link2 := urlutils.resolve_reference(base, '../overview.html')!
println(link2) // "https://example.com/docs/overview.html"

// Absolute root path
link3 := urlutils.resolve_reference(base, '/contact')!
println(link3) // "https://example.com/contact"
```

---

### Security & Normalization Helpers

#### `redact_credentials(raw_url string) string`

Masks embedded usernames and passwords in database connection strings and HTTP URLs before writing them to logs.

```v
import urlutils

db_url := 'postgres://app_user:ultra_secret_pw@db.internal.net:5432/main'
safe_url := urlutils.redact_credentials(db_url)
println(safe_url)
// Output: postgres://app_user:***@db.internal.net:5432/main
```

#### `is_same_origin(a string, b string) bool`

Checks if two URLs share the exact same scheme, host, and port (CORS origin validation).

```v
import urlutils

println(urlutils.is_same_origin('https://myapp.com', 'https://myapp.com/api')) // true
println(urlutils.is_same_origin('http://myapp.com', 'https://myapp.com'))      // false (http vs https)
println(urlutils.is_same_origin('https://myapp.com', 'https://api.myapp.com')) // false (subdomain)
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="validutils"></a><a id="validutils-api"></a>

# validutils API

**Plain-language purpose:** Use `validutils` to validate user input across web forms, APIs, and CLI tools: check emails, URLs, IP addresses, phone numbers, credit card numbers, UUIDs, and passwords, or chain multiple checks using a fluent `Validator` with clear error messages.

Import statement:

```v
import validutils
```

### Standalone Validation Functions (Zero Guesswork)

#### Network & Web Addresses

```v
import validutils

// Email validation
println(validutils.validate_email('user@example.com')) // true
println(validutils.validate_email('invalid-email@'))   // false

// Web URLs
println(validutils.validate_url('https://vlang.io'))    // true
println(validutils.validate_url('not-a-valid-url'))     // false

// IP Addresses (IPv4, IPv6, CIDR blocks, Ports)
println(validutils.validate_ip('192.168.1.1'))          // true
println(validutils.validate_ipv6('2001:db8::1'))        // true
println(validutils.validate_cidr('10.0.0.0/24'))        // true
println(validutils.validate_port('8080'))               // true (1 to 65535)
println(validutils.validate_port('99999'))              // false
```

#### Financial & Identification

```v
import validutils

// Credit card Luhn algorithm check and card brand detection
card := '4532015000000000'
if validutils.validate_credit_card(card) {
    brand := validutils.card_brand(card)
    println('Valid card: ${brand}') // "Visa", "Mastercard", "Amex", etc.
}

// International Bank Account Number (IBAN) & Book ISBN
println(validutils.validate_iban('GB82WEST12345698765432')) // true
println(validutils.validate_isbn('978-0-13-110362-7'))       // true (C Programming Language)
```

#### Formats & Identifiers

```v
import validutils

// UUID & ULID identifiers
println(validutils.validate_uuid('123e4567-e89b-12d3-a456-426614174000')) // true
println(validutils.validate_ulid('01ARZ3NDEKTSV4RRFFQ69G5FAV'))           // true

// Phone numbers (General & E.164 international)
println(validutils.validate_phone('+1 (555) 123-4567')) // true
println(validutils.validate_e164('+15551234567'))       // true

// CSS Hex colors & URL Slugs
println(validutils.validate_hex_color('#007acc'))       // true
println(validutils.validate_slug('my-first-post-2026')) // true

// Dates (YYYY-MM-DD) & JSON Strings
println(validutils.validate_date('2026-10-10'))         // true
println(validutils.validate_json('{"status":"ok"}'))    // true
```

---

### Password Strength Analysis

#### `password_strength(pw string) PasswordReport`

Audits user passwords for length, entropy, character variety, common patterns, and gives concrete recommendations.

```v
import validutils

report := validutils.password_strength('p@ssw0rd123!')
println('Strength score (0 to 4): ${report.score}')
println('Entropy bits:            ${report.entropy:.1f}')
println('Is strong enough:        ${report.is_strong}')
println('Feedback / suggestions:  ${report.feedback}')
```

---

### Fluent Form Validator (`Validator`)

Chain multiple field validation checks together and collect all validation errors in one structured pass.

```v
import validutils

// Sample form submission data
username := 'al'             // Too short (< 3 chars)
email    := 'bad-email'      // Invalid format
age      := 16.0             // Under 18
role     := 'superadmin'     // Not in allowed list

mut v := validutils.Validator{}

v.required('username', username)
 .min_len('username', username, 3)
 .email('email', email)
 .range('age', age, 18.0, 120.0)
 .one_of('role', role, ['guest', 'user', 'admin'])

if !v.is_valid() {
    println('Form contains validation errors:')
    for msg in v.error_messages() {
        println('  • ${msg}')
    }
}
/*
Output:
Form contains validation errors:
  • username must be at least 3 characters
  • email must be a valid email address
  • age must be between 18 and 120
  • role must be one of: guest, user, admin
*/
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="webutils"></a><a id="webutils-api"></a>

# webutils API

**Plain-language purpose:** Use `webutils` to build modern web applications and REST APIs in V with zero third-party dependencies. It includes an Express-style routing system, request body parsers, cookie sessions, CSRF protection, CORS headers, security headers (on by default), template rendering, and in-process HTTP testing.

Import statement:

```v
import webutils
import json2
```

### Quick Start Example

```v
import webutils

fn main() {
    mut app := webutils.new_app(
        secret: 'change-me-to-a-secure-random-secret-in-production'
        debug:  true
    )

    // Basic GET endpoint
    app.get('/', fn (mut c webutils.Context) ! {
        return c.text('Hello from vlang_utils webutils!')
    })

    // Dynamic Route Parameters (e.g. /users/42)
    app.get('/users/:id', fn (mut c webutils.Context) ! {
        user_id := c.param('id')
        return c.json({
            'user_id': user_id
            'status':  'active'
        })
    })

    // Start server on port 8080 (in a real app, call app.listen(8080))
}
```

---

### Request Handling & Responses

Inside every route handler `fn (mut c webutils.Context) !`, the `c` context provides convenient methods to read inputs and send responses:

#### Reading Request Inputs

```v
import webutils
import json2

struct CreateUserPayload {
    name  string
    email string
}

fn handle_signup(mut c webutils.Context) ! {
    // 1. Path parameters (/profile/:username)
    username := c.param('username')

    // 2. Query string parameters (/search?page=2&sort=desc)
    page := c.query_int('page', 1)
    sort := c.query_or('sort', 'asc')

    // 3. Request headers
    auth_header := c.header('Authorization')

    // 4. JSON Request Body
    body_json := c.body()
    user := json2.decode[CreateUserPayload](body_json)!

    println('Creating user: ${user.name} (page: ${page}, sort: ${sort})')
    return c.text('User created')
}
```

#### Sending Responses

```v
import webutils

fn handle_responses(mut c webutils.Context) ! {
    // Plain text response
    return c.text('Operation succeeded')

    // JSON response (maps or structs)
    return c.json({ 'success': 'true', 'code': '200' })

    // HTML response
    return c.html('<h1>Welcome to our site!</h1>')

    // Custom HTTP status code
    c.status(404)
    return c.text('Resource not found')

    // Redirect
    return c.redirect('/login', 302)
}
```

---

### Route Groups & Middleware

Organize endpoints into logical prefixes (e.g. `/api/v1`) and apply authentication or logging middleware.

```v
import webutils

fn main() {
    mut app := webutils.new_app(secret: 'my-secret')

    // 1. Global Middleware (runs on every request)
    app.use(fn (mut c webutils.Context) ! {
        println('[REQUEST] ${c.req.method} ${c.req.url}')
        c.next()! // Proceed to next handler in chain
    })

    // 2. API Route Group with prefix
    mut api := app.group('/api/v1')

    api.get('/health', fn (mut c webutils.Context) ! {
        return c.json({ 'status': 'healthy', 'version': '2.0.0' })
    })

    api.get('/items', fn (mut c webutils.Context) ! {
        return c.json(['laptop', 'keyboard', 'mouse'])
    })
}
```

---

### In-Process Unit Testing (`app.request`)

Test your web endpoints directly in memory without binding network ports or running background servers.

```v
import webutils

fn test_api_endpoints() {
    mut app := webutils.new_app(secret: 'test-secret')

    app.get('/api/ping', fn (mut c webutils.Context) ! {
        return c.text('pong')
    })

    // Simulate an in-process HTTP GET request
    res := app.request(webutils.TestRequest{
        method: 'GET'
        path:   '/api/ping'
    })

    assert res.status_code == 200
    assert res.body == 'pong'
    println('API test passed!')
}
```

[▲ Back to Table of Contents](#table-of-contents)

---

<a id="advanced-additions--enhancements"></a>

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

println('Decrypted raw len: ${raw_dec.len}, decrypted text: ${decrypted}')

// Password hashing with Bcrypt
hash := cryptoutils.bcrypt_hash('user_password') or { panic(err) }
ok := cryptoutils.bcrypt_verify('user_password', hash)
println('Password ok: ${ok}')

// Secure Entropy
random_hex := cryptoutils.secure_random_hex(16) or { '' }
println('Random hex: ${random_hex}')

// Fast non-cryptographic hashes
fnv32 := cryptoutils.fnv1a_32('string to hash')
c32 := cryptoutils.crc32_hash('string to hash')
println('FNV32: ${fnv32}, CRC32: ${c32}')

// Asymmetric Ed25519 digital signatures
pub_k, priv_k := cryptoutils.generate_ed25519_keypair() or { panic(err) }
sig := cryptoutils.ed25519_sign(priv_k, 'message'.bytes()) or { panic(err) }
valid := cryptoutils.ed25519_verify(pub_k, 'message'.bytes(), sig)
println('Ed25519 signature valid: ${valid}')
```

### `netutils` Framed TCP & UDP

```v
import netutils
import net

// Framed TCP messages (4-byte length prefix to prevent fragmentation)
mut conn := net.dial_tcp('127.0.0.1:9000') or { panic(err) }
netutils.send_framed_msg(mut conn, 'Framed Payload'.bytes()) or { panic(err) }
reply := netutils.read_framed_msg(mut conn, 8192) or { panic(err) }
println('Received reply len: ${reply.len}')

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
println('s_arr size: ${s_arr.size()}, has_val: ${has_val}, arr: ${arr}, var_set size: ${var_set.size()}')

// BloomFilter
mut bf := structutils.new_bloom_filter(64, 3) or { panic(err) }
bf.add('item1')
exists := bf.contains('item1')
var_bf := structutils.BloomFilter{}
println('exists: ${exists}, var_bf: ${var_bf}')

// BinarySearchTree[T]
mut bst := structutils.new_bstree[int]()
bst.insert(10)
bst.insert(5)
bst.insert(15)
sorted_order := bst.in_order()
smallest := bst.min()
largest := bst.max()
var_bst := structutils.BinarySearchTree[int]{}
println('sorted: ${sorted_order}, min: ${smallest}, max: ${largest}, var_bst empty: ${var_bst.is_empty()}')

// SinglyLinkedList[T]
mut ll := structutils.new_linked_list[int]()
ll.push(10)
item := ll.pop()
first_item := ll.shift()
var_ll := structutils.SinglyLinkedList[int]{}
println('item: ${item}, first: ${first_item}, var_ll len: ${var_ll.len()}')

// DoublyLinkedList[T]
mut dll := structutils.new_doubly_linked_list[string]()
dll.push_back('tail')
dll.push_front('head')
popped_tail := dll.pop_back()
popped_head := dll.pop_front()
var_dll := structutils.DoublyLinkedList[string]{}
println('popped tail: ${popped_tail}, popped head: ${popped_head}, var_dll len: ${var_dll.len()}')
```

### `sysutils` Runtime Info (`RuntimeInfo`) & Shell Piping

```v
import sysutils

info := sysutils.runtime_system_info()
println('OS: ${info.os_name}, Arch: ${info.arch}, CPUs: ${info.num_cpus}, 64bit: ${info.is_64bit}')
var_rt := sysutils.RuntimeInfo{ os_name: 'macos', arch: 'arm64' }
println('Runtime info: ${var_rt.os_name}')

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
println('Benchmark result: ${var_bm.name}')
```

---

<a id="recent-enhancements-api"></a>
## Extended Enhancements to Existing Modules

### `fileutils`
- `write_file_atomic(path string, content string) !`: Crash-safe atomic writing via temporary file + atomic OS rename.
- `mime_type(path string) string`: Automatic MIME detection from file extension and type signature.
- `file_hash_sha256(path string) !string`: Hexadecimal SHA-256 checksum calculation for any file.

### `strutils`
- `format_int_commas(n i64) string`: Format integers with comma separators (e.g. `1,234,567`).
- `format_number_commas(n f64, decimals int) string`: Format floating point numbers with comma grouping.
- `ordinal(n int) string`: Ordinal suffixes (`1st`, `2nd`, `3rd`, `4th`, `11th`, `21st`).
- `truncate_middle(s string, max_len int, ellipsis string) string`: Truncate strings in the middle (`0123...def`).
- `strip_ansi(s string) string`: Remove ANSI terminal styling codes.

### `sliceutils`
- `zip[T, U](a []T, b []U) []Pair[T, U]`: Combine two slices into pairs.
- `frequency[T](items []T) map[T]int`: Count occurrences of distinct elements.
- `group_by[T, K](items []T, key_fn fn (T) K) map[K][]T`: Group slice items by key.
- `window[T](items []T, size int, step int) [][]T`: Sliding window partitioner.
- `binary_search[T](sorted_items []T, target T) int`: Fast $O(\log n)$ search on sorted slices.

### `cryptoutils`
- `secure_compare(a string, b string) bool`: Constant-time string comparison to prevent timing attacks.
- `generate_ulid() string`: 26-character sortable unique identifier.
- `generate_totp(secret string, counter u64, digits int) !string`: RFC 6238 Time-based One-Time Passwords.

### `httputils`
- `bearer_auth_header(token string) map[string]string`: Generate Bearer authorization map.
- `basic_auth_header(user string, pass string) map[string]string`: Generate Basic authentication map.
- `merge_headers(maps ...map[string]string) map[string]string`: Combine multiple HTTP header sets.
- `is_success_status`, `is_redirect_status`, `is_client_error`, `is_server_error`: Fast status code inspection.

### `cliutils`
- `Spinner`: Terminal loading spinner with `new_spinner(msg)`, `step()`, `update(msg)`.
- `confirm(prompt string, default_yes bool) bool`: Interactive Yes/No prompt.

### `sqliteutils`
- `transaction(mut db sqlite.DB, action fn (mut db sqlite.DB) !) !`: Safe transaction runner with auto-rollback.
- `insert_many(mut db sqlite.DB, table string, rows []map[string]string) !int`: High-throughput atomic batch insert.

### `timeutils`
- `parse_duration(s string) !time.Duration`: Parse human duration strings (`"1h 30m"`, `"500ms"`, `"45s"`).
- `add_business_days(start time.Time, days int) time.Time`: Skip weekend days.
- `TimeRange`: Struct with `contains`, `overlaps`, and `duration()`.

### `flowutils`
- `SlidingWindowRateLimiter`: Enforce request limits across moving time windows.

---

[▲ Back to Table of Contents](#table-of-contents)

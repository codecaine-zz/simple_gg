# SimpleGUI Applications Suite

Native macOS GUI applications built with **SimpleGUI** for V, providing high-performance graphical workstations for media, security, data engineering, developer utilities, and mathematical computing tools installed via Homebrew or macOS subsystems.

---

## 📦 Automatic Homebrew Dependencies Installation

To inspect your system and automatically install any missing CLI tools used across the 44 applications:

```bash
# Scan and inspect dependencies health (dry run)
./install_dependencies.vsh --check

# Inspect and interactively prompt to install missing packages
./install_dependencies.vsh

# Automatically install all missing Homebrew formulas non-interactively
./install_dependencies.vsh -y

# Include optional cross-compiler toolchains (zig, mingw-w64)
./install_dependencies.vsh --all -y
```

---

# 📸 Visual Showcase of Applications (44 Workstations)

### Featured Workstations

<p align="center">
  <img src="../snapshots/apps/app_bundler_studio.png" width="48%" alt="App Bundler Studio Pro" />
  <img src="../snapshots/apps/media_studio_hub.png" width="48%" alt="Media & Data Studio Hub" />
</p>
<p align="center">
  <img src="../snapshots/apps/text_editor.png" width="48%" alt="Text Editor Pro" />
  <img src="../snapshots/apps/task_manager.png" width="48%" alt="Task Manager Pro" />
</p>
<p align="center">
  <img src="../snapshots/apps/programmer_calculator.png" width="48%" alt="Programmer Calculator Pro" />
  <img src="../snapshots/apps/jq_studio.png" width="48%" alt="JQ Studio Pro" />
</p>

---

### Data Engineering, Parsing & Stream Processing

<p align="center">
  <img src="../snapshots/apps/dataconvert_studio.png" width="48%" alt="Format Converter Studio Pro" />
  <img src="../snapshots/apps/sqlite_studio.png" width="48%" alt="SQLite Studio Pro" />
</p>
<p align="center">
  <img src="../snapshots/apps/regex_studio.png" width="48%" alt="Regex Studio Pro" />
  <img src="../snapshots/apps/gawk_studio.png" width="48%" alt="GAWK Studio Pro" />
</p>
<p align="center">
  <img src="../snapshots/apps/sed_studio.png" width="48%" alt="Sed Studio Pro" />
  <img src="../snapshots/apps/sd_studio.png" width="48%" alt="SD Studio Pro" />
</p>
<p align="center">
  <img src="../snapshots/apps/cut_studio.png" width="48%" alt="Cut Studio Pro" />
  <img src="../snapshots/apps/tr_studio.png" width="48%" alt="TR Studio Pro" />
</p>

---

### Security, Network Intelligence & Cloud DevOps

<p align="center">
  <img src="../snapshots/apps/api_studio.png" width="48%" alt="API Studio Pro" />
  <img src="../snapshots/apps/nmap_studio.png" width="48%" alt="Nmap Studio Pro" />
</p>
<p align="center">
  <img src="../snapshots/apps/dns_studio.png" width="48%" alt="DNS & SSL Studio Pro" />
  <img src="../snapshots/apps/recon_studio.png" width="48%" alt="Recon Studio Pro" />
</p>
<p align="center">
  <img src="../snapshots/apps/subfinder_studio.png" width="48%" alt="Subfinder Studio Pro" />
  <img src="../snapshots/apps/crypto_studio.png" width="48%" alt="Crypto & Hash Studio Pro" />
</p>
<p align="center">
  <img src="../snapshots/apps/docker_studio.png" width="48%" alt="Docker Studio Pro" />
</p>

---

### Media Engineering, Graphics, Audio & Documents

<p align="center">
  <img src="../snapshots/apps/ffmpeg_studio.png" width="48%" alt="FFmpeg Studio Pro" />
  <img src="../snapshots/apps/imagemagick_studio.png" width="48%" alt="ImageMagick Studio Pro" />
</p>
<p align="center">
  <img src="../snapshots/apps/yt_dlp_studio.png" width="48%" alt="yt-dlp Studio Pro" />
  <img src="../snapshots/apps/audiotag_studio.png" width="48%" alt="Audio Tag Studio Pro" />
</p>
<p align="center">
  <img src="../snapshots/apps/exif_studio.png" width="48%" alt="ExifTool Studio Pro" />
  <img src="../snapshots/apps/ocr_studio.png" width="48%" alt="Tesseract OCR Studio Pro" />
</p>
<p align="center">
  <img src="../snapshots/apps/dot_studio.png" width="48%" alt="Graphviz Studio Pro" />
  <img src="../snapshots/apps/pandoc_studio.png" width="48%" alt="Pandoc Studio Pro" />
</p>
<p align="center">
  <img src="../snapshots/apps/say_studio.png" width="48%" alt="Say Studio Pro" />
  <img src="../snapshots/apps/wget2_studio.png" width="48%" alt="Wget2 Studio Pro" />
</p>

---

### System Administration, Search & File Management

<p align="center">
  <img src="../snapshots/apps/brew_studio.png" width="48%" alt="Homebrew Studio Pro" />
  <img src="../snapshots/apps/disk_studio.png" width="48%" alt="Disk Space Studio Pro" />
</p>
<p align="center">
  <img src="../snapshots/apps/launchd_studio.png" width="48%" alt="Launchd & Cron Studio Pro" />
  <img src="../snapshots/apps/ouch_studio.png" width="48%" alt="Ouch Studio Pro" />
</p>
<p align="center">
  <img src="../snapshots/apps/rg_studio.png" width="48%" alt="RG Studio Pro" />
  <img src="../snapshots/apps/fd_studio.png" width="48%" alt="FD Studio Pro" />
</p>
<p align="center">
  <img src="../snapshots/apps/find_studio.png" width="48%" alt="Find Studio Pro" />
</p>

---

### Mathematics, Scientific Computing & Statistics

<p align="center">
  <img src="../snapshots/apps/qalc_studio.png" width="48%" alt="Qalc Studio Pro" />
  <img src="../snapshots/apps/numbat_studio.png" width="48%" alt="Numbat Studio Pro" />
</p>
<p align="center">
  <img src="../snapshots/apps/kalker_studio.png" width="48%" alt="Kalker Studio Pro" />
  <img src="../snapshots/apps/statistics_studio.png" width="48%" alt="Statistics Studio Pro" />
</p>
<p align="center">
  <img src="../snapshots/apps/graph_studio.png" width="48%" alt="Graph Studio Pro" />
</p>

---

# Complete Applications Suite (44 Workstations)

| Application | Source File | Snapshot | Description |
| :--- | :--- | :--- | :--- |
| **JQ Studio Pro** | [`jq_studio.v`](jq_studio.v) | [Screenshot](../snapshots/apps/jq_studio.png) | Interactive JSON query, formatting & filter workbench powered by `jq`: live query evaluations, 12 built-in transformation recipes, key/path inspection, minifier/prettifier, and error diagnostics. |
| **API Studio Pro** | [`api_studio.v`](api_studio.v) | [Screenshot](../snapshots/apps/api_studio.png) | Full-featured REST API testing client powered by `curl`: HTTP method selector (GET, POST, PUT, PATCH, DELETE, HEAD), request headers/body editors, latency telemetry (DNS/TLS/TTFB), and 1-click `curl` command exporter. |
| **Nmap Studio Pro** | [`nmap_studio.v`](nmap_studio.v) | [Screenshot](../snapshots/apps/nmap_studio.png) | High-speed port scanner & network discovery workbench powered by `nmap`: quick scan (-F), service versioning (-sV), OS detection (-O), aggressive timing (-T4), vulnerability scripts, and open port reports. |
| **DNS & SSL Studio Pro** | [`dns_studio.v`](dns_studio.v) | [Screenshot](../snapshots/apps/dns_studio.png) | Dual DNS resolution & TLS certificate analyzer powered by `dig` and `openssl`: multi-record lookups (A, AAAA, CNAME, MX, TXT, NS, SOA, CAA), certificate chain & expiry inspector, and SPF/DKIM/DMARC email security auditor. |
| **Recon Studio Pro** | [`recon_studio.v`](recon_studio.v) | [Screenshot](../snapshots/apps/recon_studio.png) | OSINT footprinting & asset mapping workbench powered by `whois`, public CT logs (crt.sh), IPInfo geolocation/ASN lookup, security headers inspector, and robots.txt crawler. |
| **Format Converter Pro** | [`dataconvert_studio.v`](dataconvert_studio.v) | [Screenshot](../snapshots/apps/dataconvert_studio.png) | Universal data interchange transformer: bidirectional live translation across **JSON ⇄ YAML ⇄ TOML ⇄ CSV ⇄ XML ⇄ SQLite**, schema validation, field extractors, and file export. |
| **SQLite Studio Pro** | [`sqlite_studio.v`](sqlite_studio.v) | [Screenshot](../snapshots/apps/sqlite_studio.png) | Embedded SQL database workbench powered by `sqlite3`: database browser, table/column/index schema explorer, SQL query scratchpad, formatted grid table/JSON/CSV views, and query plan analyzer. |
| **Regex Studio Pro** | [`regex_studio.v`](regex_studio.v) | [Screenshot](../snapshots/apps/regex_studio.png) | Interactive regular expression workbench: live match highlighter, capture group breakdown table (`$1, $2`), flags (case-insensitive, multiline, dotall), find-and-replace engine, and 9 built-in regex recipes. |
| **ExifTool Studio Pro** | [`exif_studio.v`](exif_studio.v) | [Screenshot](../snapshots/apps/exif_studio.png) | Image & video metadata investigator powered by `exiftool`: camera/lens specs, EXIF/IPTC/XMP tag explorer, 1-click GPS launch in Apple Maps, batch privacy PII metadata stripper, and tag writer. |
| **Tesseract OCR Pro** | [`ocr_studio.v`](ocr_studio.v) | [Screenshot](../snapshots/apps/ocr_studio.png) | Optical character recognition & document scanner powered by `tesseract`: multi-language packs (eng, spa, fra, deu, chi, jpn...), page segmentation modes (PSM), text post-processing, and searchable PDF generator. |
| **Audio Tag Studio Pro** | [`audiotag_studio.v`](audiotag_studio.v) | [Screenshot](../snapshots/apps/audiotag_studio.png) | Audio metadata & lossless tagging studio powered by `ffmpeg` and `ffprobe`: track title, artist, album, genre, year, track #, comment, cover art extractor, tag stripper, and live macOS `afplay` playback. |
| **Graphviz Studio Pro** | [`dot_studio.v`](dot_studio.v) | [Screenshot](../snapshots/apps/dot_studio.png) | Code-to-diagram visual workbench powered by `graphviz` (`dot`): DOT source editor, live SVG/PNG compilation, 7 architecture/state/tree diagram templates, and layout engine selector (`dot`, `neato`, `fdp`, `circo`, `twopi`). |
| **Homebrew Studio Pro** | [`brew_studio.v`](brew_studio.v) | [Screenshot](../snapshots/apps/brew_studio.png) | Visual package manager & service controller for macOS powered by `brew`: formula & cask search, package info inspector, 1-click bulk updates/upgrades, background services manager (`brew services`), and disk cache cleaner. |
| **Docker Studio Pro** | [`docker_studio.v`](docker_studio.v) | [Screenshot](../snapshots/apps/docker_studio.png) | Container & microservice workbench powered by `docker`/`podman`: active container status table, start/stop/restart/logs lifecycle controls, local image repository manager, volume/network explorer, and system prune. |
| **Disk Space Studio Pro** | [`disk_studio.v`](disk_studio.v) | [Screenshot](../snapshots/apps/disk_studio.png) | macOS storage analyzer & developer junk cleaner powered by `du` and `df`: directory size breakdown, top 30 largest files finder, APFS volume monitor, and developer cache scrubber (`node_modules`, Xcode `DerivedData`, `.cache`). |
| **Launchd & Cron Pro** | [`launchd_studio.v`](launchd_studio.v) | [Screenshot](../snapshots/apps/launchd_studio.png) | macOS daemon & task scheduler workbench powered by `launchctl` and `crontab`: active system/user daemon explorer, user LaunchAgents inspector, visual cron expression generator, and `.plist` builder. |
| **Crypto & Hash Studio** | [`crypto_studio.v`](crypto_studio.v) | [Screenshot](../snapshots/apps/crypto_studio.png) | Cryptographic & checksum verification utility: multi-algorithm hash generator (MD5, SHA-1, SHA-224, SHA-256, SHA-384, SHA-512), target hash verifier, HMAC generator, JWT token claims decoder, and password entropy generator. |
| **TR Studio Pro** | [`tr_studio.v`](tr_studio.v) | [Screenshot](../snapshots/apps/tr_studio.png) | Character translation & stream cleansing workbench powered by `tr`: character mapping, deletion (`-d`), squeeze repeats (`-s`), delete & squeeze (`-ds`), complement inversion (`-c`), 10 built-in recipes, and dual-pane editor. |
| **Cut Studio Pro** | [`cut_studio.v`](cut_studio.v) | [Screenshot](../snapshots/apps/cut_studio.png) | Fast stream & column slicing workbench powered by `cut`: field extraction (`-f`), delimiter modes, character columns (`-c`), byte slices (`-b`), only delimited lines (`-s`), 9 built-in recipes, and file exporters. |
| **RG Studio Pro** | [`rg_studio.v`](rg_studio.v) | [Screenshot](../snapshots/apps/rg_studio.png) | High-speed code & content search workbench powered by `ripgrep` (`rg`): regex search, fixed-strings (`-F`), whole-word matching (`-w`), case-modes (`-s`/`-S`), inverted match (`-v`), file-type selectors, glob filters, and context lines. |
| **FD Studio Pro** | [`fd_studio.v`](fd_studio.v) | [Screenshot](../snapshots/apps/fd_studio.png) | Ultra-fast file finder & filesystem workbench powered by `fd`: regex/glob search, multi-extension filters, large file detection (>100MB), recent modification filters, and type filters. |
| **SD Studio Pro** | [`sd_studio.v`](sd_studio.v) | [Screenshot](../snapshots/apps/sd_studio.png) | Ultra-fast regex search and replace workbench powered by `sd`: dual-pane editor, captured group transforms (`$1, $2`), code refactoring, text cleansing, PII redaction, and in-place multi-file batch processor. |
| **GAWK Studio Pro** | [`gawk_studio.v`](gawk_studio.v) | [Screenshot](../snapshots/apps/gawk_studio.png) | Interactive data stream & log processing workbench: real-time dual-pane editor, CSV/TSV/Log parser, built-in library of **40+ classic & modern AWK one-liners**, and direct multi-gigabyte disk file streamer. |
| **Pandoc Studio Pro** | [`pandoc_studio.v`](pandoc_studio.v) | [Screenshot](../snapshots/apps/pandoc_studio.png) | Universal document converter & publishing studio: Markdown, HTML5, LaTeX, Typst, MS Word (.docx), EPUB eBooks, Slide decks (PPTX, Reveal.js, Beamer), syntax themes, math rendering (MathJax), and direct PDF compiler. |
| **Wget2 Studio Pro** | [`wget2_studio.v`](wget2_studio.v) | [Screenshot](../snapshots/apps/wget2_studio.png) | High-speed multi-threaded download accelerator & website mirror powered by GNU `wget2`: parallel chunking (up to 16 threads), offline site crawling (`--mirror`), extension scrapers, automatic resume (`-c`), and browser emulation. |
| **yt-dlp Studio Pro** | [`yt_dlp_studio.v`](yt_dlp_studio.v) | [Screenshot](../snapshots/apps/yt_dlp_studio.png) | High-performance media downloader & stream archiver: 4K UHD / 1080p / 720p presets, audio extractors (MP3 320k, FLAC, AAC, Opus, WAV), subtitle & metadata embedding, browser cookie support, and stream inspector (`-F`). |
| **FFmpeg Studio Pro** | [`ffmpeg_studio.v`](ffmpeg_studio.v) | [Screenshot](../snapshots/apps/ffmpeg_studio.png) | Full-featured video & audio engineering studio: transcode engine, social media & Discord limits, EBU R128 audio loudnorm & denoise, lossless trimmer, 9:16 vertical crop, frame extraction, and 2-pass HD GIF maker. |
| **ImageMagick Studio Pro** | [`imagemagick_studio.v`](imagemagick_studio.v) | [Screenshot](../snapshots/apps/imagemagick_studio.png) | Complete graphic manipulation workstation: modern WebP/AVIF compression, multi-size favicon generator, magic background color removal (transparency), social presets, floating drop shadows, and bulk processing. |
| **Subfinder Studio Pro** | [`subfinder_studio.v`](subfinder_studio.v) | [Screenshot](../snapshots/apps/subfinder_studio.png) | High-speed passive subdomain discovery & asset mapping workbench powered by `subfinder`: multi-source passive OSINT enumeration, active DNS validation, rate-limiting, and custom resolvers. |
| **Say Studio Pro** | [`say_studio.v`](say_studio.v) | [Screenshot](../snapshots/apps/say_studio.png) | Native macOS speech synthesizer & voiceover generator powered by `say`: real-time text-to-speech, system voice browser (Samantha, Alex, Daniel, Fred, Victoria, Zarvox...), rate tuner, and audio exporter (.m4a, .aiff, .wav). |
| **Find Studio Pro** | [`find_studio.v`](find_studio.v) | [Screenshot](../snapshots/apps/find_studio.png) | Advanced filesystem explorer & inode search workbench powered by POSIX/BSD `find`: glob/regex matching, multi-pattern names, entry type filters, size filters, age filters, and permission auditors. |
| **Text Editor Pro** | [`text_editor.v`](text_editor.v) | [Screenshot](../snapshots/apps/text_editor.png) | Ultimate native code editor & workspace: multi-buffer scratchpads, live WebKit Markdown HTML preview, integrated code runner (V, Python, Node, Bash, Ruby), unified diff comparison, regex search/replace, and telemetry. |
| **Task Manager Pro** | [`task_manager.v`](task_manager.v) | [Screenshot](../snapshots/apps/task_manager.png) | macOS process manager & hardware telemetry monitor: real-time process data grid (PID, Name, CPU %, Memory RSS, State), hardware stats cards, filtering scopes, process signals (SIGKILL, SIGTERM), and `lsof` socket inspector. |
| **Ouch Studio Pro** | [`ouch_studio.v`](ouch_studio.v) | [Screenshot](../snapshots/apps/ouch_studio.png) | Ultra-fast universal archive & compression workbench powered by `ouch`: lossless/high-density packaging across `.tar.zst`, `.tar.gz`, `.zip`, `.7z`, `.tar.xz`, `.tar.bz2`, compression tuning, and tree hierarchy explorer. |
| **Sed Studio Pro** | [`sed_studio.v`](sed_studio.v) | [Screenshot](../snapshots/apps/sed_studio.png) | POSIX/BSD `sed` stream editor & regex transformation workbench: dual-pane live scratchpad, in-place disk file editing (`-i ''`), character/line counters, backup preservation, and 15 built-in recipes. |
| **IFConfig Studio Pro** | [`ifconfig_studio.v`](ifconfig_studio.v) | — | Comprehensive native macOS IP intelligence & network diagnostics studio: Public IPv4 & IPv6 detection, rich geolocation (City, Country, GPS, ASN, ISP), 1-click Maps launcher, local interface scanner, and DNS latency ping. |
| **Qalc Studio Pro** | [`qalc_studio.v`](qalc_studio.v) | [Screenshot](../snapshots/apps/qalc_studio.png) | Advanced symbolic mathematics & universal unit converter powered by `qalc` (`libqalculate`): arbitrary precision (up to 100 digits), symbolic equation solver, calculus derivatives/integrals, and 30+ formula presets. |
| **Numbat Studio Pro** | [`numbat_studio.v`](numbat_studio.v) | [Screenshot](../snapshots/apps/numbat_studio.png) | Scientific & physical dimensional analysis studio powered by `numbat`: statically-typed physical expressions, automatic dimension validation, multi-line physics IDE, and fundamental physical constants database. |
| **Kalker Studio Pro** | [`kalker_studio.v`](kalker_studio.v) | [Screenshot](../snapshots/apps/kalker_studio.png) | Pure mathematics, natural calculus syntax & complex analysis studio powered by `kalker`: natural calculus syntax (∫, √, f'(x)), complex arithmetic, polar conversions, and matrix/vector algebra. |
| **Statistics Studio Pro** | [`statistics_studio.v`](statistics_studio.v) | [Screenshot](../snapshots/apps/statistics_studio.png) | Comprehensive scientific data science workbench in pure V: descriptive statistics, normality tests, hypothesis testing (Student's t-test, ANOVA), OLS linear regression, and ASCII histograms. |
| **Graph Studio Pro** | [`graph_studio.v`](graph_studio.v) | [Screenshot](../snapshots/apps/graph_studio.png) | High-precision scientific plotting & visualization studio in pure V: 2D continuous function grapher, multi-series data visualizer, bar charts, scatter plots, and network topology graph visualizer. |
| **Programmer Calculator** | [`programmer_calculator.v`](programmer_calculator.v) | [Screenshot](../snapshots/apps/programmer_calculator.png) | Advanced multi-radix computer science calculator in pure V: simultaneous Hex, Dec, Oct, Bin displays, interactive 64-bit grid, IEEE-754 floating point inspector, Endianness converters, and bitwise logic. |
| **App Bundler Studio Pro** | [`app_bundler_studio.v`](app_bundler_studio.v) | [Screenshot](../snapshots/apps/app_bundler_studio.png) | macOS Application (.app) Packager & Icon Generator: bundles Mach-O/CLI binaries into notarization-ready macOS bundles with Info.plist, multi-resolution Retina .icns iconset generator, ad-hoc codesigning, and quarantine stripper. |
| **Media & Data Studio Hub** | [`media_studio_hub.v`](media_studio_hub.v) | [Screenshot](../snapshots/apps/media_studio_hub.png) | Master workstation with system environment diagnostics, instant one-click quick tools (Discord <10MB, TikTok 9:16, Loudnorm, Favicon, Remove White BG, 2-Pass GIF, WebP), and sub-app launchers. |

---

# Theme Engine & Persistence (Save State)

- **Default Theme**: **GitHub Dark** (`#22272e` canvas, `#adbac7` text, `#539bf5` GitHub Blue accent).
- **Persistent State Across Apps**: When you select any theme in any application, your choice is instantly saved to `~/.config/simplegui/theme.txt`. All studio applications automatically load and apply your saved theme upon launch!

# Available 18 Curated Themes

| Theme Name | Background | Text Color | Accent | Signature Personality |
| :--- | :--- | :--- | :--- | :--- |
| **GitHub Dark** | `#22272e` | `#adbac7` | `#539bf5` | Official GitHub Dark Dimmed developer canvas (Default) |
| **Apple Light** | `#f6f6f7` | `#1d1d1f` | `#0071e3` | Clean Apple macOS Aqua studio interface |
| **Apple Dark** | `#1c1c1e` | `#f5f5f7` | `#0a84ff` | Refined Apple macOS Pro Dark Titanium surface |
| **Deep Space OLED** | `#090a0f` | `#e2e8f0` | `#6366f1` | Ultra-deep pitch OLED dark theme with electric indigo |
| **Tokyo Night** | `#1a1b26` | `#c0caf5` | `#7aa2f7` | Iconic Japanese twilight deep indigo theme |
| **Nord Arctic** | `#2e3440` | `#eceff4` | `#88c0d0` | Arctic polar night slate with frosty cyan contrast |
| **Dracula Vampire** | `#282a36` | `#f8f8f2` | `#bd93f9` | High-contrast gothic slate purple developer theme |
| **Cyberpunk Neon** | `#120e24` | `#00f0ff` | `#ff007f` | Electric midnight purple with hot cyan & neon pink |
| **Catppuccin Mocha** | `#1e1e2e` | `#cdd6f4` | `#f5c2e7` | Soothing modern lavender pastel dark mode |
| **Monokai Pro** | `#2d2a2e` | `#fcfcfa` | `#ffd866` | Warm dark charcoal with radiant gold accents |
| **Gruvbox Dark** | `#282828` | `#ebdbb2` | `#fe8019` | Warm retro earthy dark canvas with burnt orange |
| **Cobalt Blue** | `#0a192f` | `#ccd6f6` | `#64ffda` | Deep submarine oceanic navy with glowing aqua teal |
| **Emerald Forest** | `#062319` | `#ecfdf5` | `#10b981` | Deep evergreen botanical pine with vivid emerald |
| **Sunset Dusk** | `#231123` | `#fff1f2` | `#f43f5e` | Rich twilight velvet plum with warm sunset coral |
| **GitHub Light** | `#ffffff` | `#1f2328` | `#0969da` | Crisp high-contrast GitHub light interface |
| **Solarized Dark** | `#002b36` | `#93a1a1` | `#268bd2` | Precision engineered scientific teal dark theme |
| **Solarized Light** | `#fdf6e3` | `#586e75` | `#b58900` | Warm linen parchment precision light palette |
| **Warm Paper & Ink** | `#fbf8f2` | `#18181b` | `#78716c` | Tactile Japanese fine washi paper with sumi ink text |

---

# Prerequisites & Homebrew Installation

Ensure all underlying CLI engines and utilities are installed on macOS via [Homebrew](https://brew.sh):

```bash
brew install ripgrep fd sd gawk ouch ffmpeg imagemagick pandoc wget2 yt-dlp subfinder jq libqalculate numbat kalker nmap exiftool tesseract graphviz
```

---

# Running the Applications

Run any workstation directly with `v run`:

```bash
# Data & Structure
v run applications/jq_studio.v
v run applications/dataconvert_studio.v
v run applications/sqlite_studio.v
v run applications/regex_studio.v
v run applications/gawk_studio.v
v run applications/sed_studio.v
v run applications/cut_studio.v
v run applications/tr_studio.v

# Security, Network & OSINT
v run applications/api_studio.v
v run applications/nmap_studio.v
v run applications/dns_studio.v
v run applications/recon_studio.v
v run applications/subfinder_studio.v
v run applications/ifconfig_studio.v

# Media, Graphics & OCR
v run applications/ffmpeg_studio.v
v run applications/imagemagick_studio.v
v run applications/yt_dlp_studio.v
v run applications/exif_studio.v
v run applications/ocr_studio.v
v run applications/audiotag_studio.v
v run applications/dot_studio.v
v run applications/pandoc_studio.v
v run applications/say_studio.v
v run applications/media_studio_hub.v

# System & DevOps
v run applications/brew_studio.v
v run applications/docker_studio.v
v run applications/disk_studio.v
v run applications/launchd_studio.v
v run applications/task_manager.v
v run applications/rg_studio.v
v run applications/fd_studio.v
v run applications/find_studio.v
v run applications/ouch_studio.v
v run applications/app_bundler_studio.v

# Mathematics, Science & Cryptography
v run applications/crypto_studio.v
v run applications/qalc_studio.v
v run applications/numbat_studio.v
v run applications/kalker_studio.v
v run applications/statistics_studio.v
v run applications/graph_studio.v
v run applications/programmer_calculator.v
v run applications/text_editor.v
```

---

## 🔨 Batch Compiling Applications (macOS .app Bundles, Linux & Windows)

You can compile all 44 applications into standalone macOS `.app` bundles with native icons, or cross-compile for Linux and Windows binaries using the multi-threaded V script `compile_apps.vsh`:

```bash
# macOS Native (.app bundles with high-resolution .icns icons)
./compile_apps.vsh
# or: v run compile_apps.vsh

# Production optimized build (-prod -gc none)
./compile_apps.vsh -prod

# Compile / Cross-compile for Linux (ELF binaries in bin/)
./compile_apps.vsh --linux

# Compile / Cross-compile for Windows (.exe binaries in bin/)
./compile_apps.vsh --windows
# or with Zig cross-compiler:
./compile_apps.vsh --windows -cc zig

# Windows Subsystem for Linux (WSL / WSLg)
./compile_apps.vsh --wsl
./compile_apps.vsh --wsl --c-only

# Target CPU architectures (ARM64 / Apple Silicon or x86_64 / Intel)
./compile_apps.vsh --arm64
./compile_apps.vsh --x86_64

# Export standalone C source files (.c) for compiling anywhere without V
./compile_apps.vsh --linux --c-only
./compile_apps.vsh --windows --c-only

# Compile raw CLI binaries on macOS (without .app wrapper)
./compile_apps.vsh --raw

# Compile a specific application target
./compile_apps.vsh app_bundler_studio

# Custom concurrency (e.g. 8 parallel jobs) and custom output folder
./compile_apps.vsh -j 8 -o dist/
```

### Running Graphical Applications on WSL2 / WSLg
Windows 11 and Windows 10 (WSL2) natively support graphical Linux applications out-of-the-box via **WSLg**.

1. Inside your WSL terminal (e.g. Ubuntu), install the development packages:
```bash
sudo apt update && sudo apt install -y libx11-dev libxi-dev libxcursor-dev libgl-dev libegl1-mesa-dev libasound2-dev
```

2. Compile and run any application directly inside WSL:
```bash
./compile_apps.vsh --wsl
./bin/wsl_x86_64/crypto_studio
```

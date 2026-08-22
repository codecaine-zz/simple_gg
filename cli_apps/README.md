# Production Console Applications Suite

This directory contains standalone, production-ready console applications, client utilities, and automation tools built with **`SimpleCLI`** for V, designed for DevOps, cloud operations, security, API benchmarking, data processing, multimedia, and workspace management.

---

## 🛠️ Complete Applications Catalog (48 Console Utilities)

### 1. DevOps, Infrastructure & Automation
| Application | File | Description | Run Command |
| :--- | :--- | :--- | :--- |
| **DevOps Sentinel** | [`devops_sentinel.v`](devops_sentinel.v) | System health guardian & TCP port monitor | `v run cli_apps/devops_sentinel.v --interactive` |
| **Vault Backup Manager** | [`vault_backup_manager.v`](vault_backup_manager.v) | AES-256 encrypted directory backup vault | `v run cli_apps/vault_backup_manager.v -h` |
| **API Stress Bench** | [`api_stress_bench.v`](api_stress_bench.v) | HTTP API throughput & latency benchmarker | `v run cli_apps/api_stress_bench.v --url https://httpbin.org/get` |
| **Git Workspace Pilot** | [`multirepo_git_pilot.v`](multirepo_git_pilot.v) | Multi-repository Git orchestrator & stash manager | `v run cli_apps/multirepo_git_pilot.v --path .` |
| **Docker Studio CLI** | [`docker_cli.v`](docker_cli.v) | Docker container/image manager & log viewer | `v run cli_apps/docker_cli.v --interactive` |
| **Homebrew Studio CLI** | [`brew_cli.v`](brew_cli.v) | Package search, info, updates & services | `v run cli_apps/brew_cli.v --interactive` |
| **Launchd & Cron CLI** | [`launchd_cli.v`](launchd_cli.v) | macOS daemons, agents & crontab inspector | `v run cli_apps/launchd_cli.v --interactive` |
| **Task Manager CLI** | [`task_manager_cli.v`](task_manager_cli.v) | Real-time process monitor with CPU/RAM tables | `v run cli_apps/task_manager_cli.v --interactive` |
| **Disk Space CLI** | [`disk_cli.v`](disk_cli.v) | Storage capacity, mounts & large file scanner | `v run cli_apps/disk_cli.v --interactive` |
| **App Bundler CLI** | [`app_bundler_cli.v`](app_bundler_cli.v) | macOS native .app bundler & packager | `v run cli_apps/app_bundler_cli.v --interactive` |

---

### 2. Security, Network Intelligence & API Tools
| Application | File | Description | Run Command |
| :--- | :--- | :--- | :--- |
| **API Studio CLI** | [`api_studio_cli.v`](api_studio_cli.v) | REST API client & HTTP request builder | `v run cli_apps/api_studio_cli.v --interactive` |
| **Nmap Port Scanner CLI** | [`nmap_cli.v`](nmap_cli.v) | Fast TCP port scanner & service prober | `v run cli_apps/nmap_cli.v --host 127.0.0.1` |
| **DNS & SSL Studio CLI** | [`dns_cli.v`](dns_cli.v) | DNS record resolver (A/MX/TXT) & TLS certs | `v run cli_apps/dns_cli.v --domain vlang.io` |
| **Recon Studio CLI** | [`recon_cli.v`](recon_cli.v) | WHOIS lookup, HTTP headers & host OSINT | `v run cli_apps/recon_cli.v --target vlang.io` |
| **Subfinder Studio CLI** | [`subfinder_cli.v`](subfinder_cli.v) | Certificate Transparency subdomain finder | `v run cli_apps/subfinder_cli.v --domain vlang.io` |
| **IFConfig Studio CLI** | [`ifconfig_cli.v`](ifconfig_cli.v) | Network adapters, Wi-Fi SSID & IP diagnostics | `v run cli_apps/ifconfig_cli.v --interactive` |
| **Crypto Studio CLI** | [`crypto_cli.v`](crypto_cli.v) | Hashes (SHA256/512/MD5), AES-256 & BCrypt | `v run cli_apps/crypto_cli.v --interactive` |

---

### 3. Data Engineering & Databases
| Application | File | Description | Run Command |
| :--- | :--- | :--- | :--- |
| **JQ Studio CLI** | [`jq_cli.v`](jq_cli.v) | JQ JSON query engine & transformation REPL | `v run cli_apps/jq_cli.v --interactive` |
| **Data Convert CLI** | [`dataconvert_cli.v`](dataconvert_cli.v) | Tabular CSV/TSV to JSON/TOML converter | `v run cli_apps/dataconvert_cli.v --interactive` |
| **SQLite Studio CLI** | [`sqlite_cli.v`](sqlite_cli.v) | Database schema explorer & SQL query REPL | `v run cli_apps/sqlite_cli.v --interactive` |

---

### 4. Text Processing, Stream Editing & Search
| Application | File | Description | Run Command |
| :--- | :--- | :--- | :--- |
| **GAWK Studio CLI** | [`gawk_cli.v`](gawk_cli.v) | AWK pattern scanner & column aggregator | `v run cli_apps/gawk_cli.v --interactive` |
| **Sed Studio CLI** | [`sed_cli.v`](sed_cli.v) | Stream editor & find-and-replace engine | `v run cli_apps/sed_cli.v --interactive` |
| **SD Studio CLI** | [`sd_cli.v`](sd_cli.v) | Fast string & regex token replacement | `v run cli_apps/sd_cli.v --interactive` |
| **Cut Studio CLI** | [`cut_cli.v`](cut_cli.v) | Column delimiter & field extraction utility | `v run cli_apps/cut_cli.v --interactive` |
| **TR Studio CLI** | [`tr_cli.v`](tr_cli.v) | Character translation, case shifting & deletion | `v run cli_apps/tr_cli.v --interactive` |
| **Regex Studio CLI** | [`regex_cli.v`](regex_cli.v) | Regular expression validator & matcher | `v run cli_apps/regex_cli.v --interactive` |
| **Ripgrep Studio CLI** | [`rg_cli.v`](rg_cli.v) | Fast codebase text & pattern search | `v run cli_apps/rg_cli.v --interactive` |
| **FD Studio CLI** | [`fd_cli.v`](fd_cli.v) | Directory traversal & regex file finder | `v run cli_apps/fd_cli.v --interactive` |
| **Find Studio CLI** | [`find_cli.v`](find_cli.v) | POSIX hierarchy search & filter wrapper | `v run cli_apps/find_cli.v --interactive` |
| **Text Editor CLI** | [`text_editor_cli.v`](text_editor_cli.v) | Line-numbered code/text viewer & stats | `v run cli_apps/text_editor_cli.v --interactive` |

---

### 5. Media, Graphics, Vision & Audio
| Application | File | Description | Run Command |
| :--- | :--- | :--- | :--- |
| **FFmpeg Media CLI** | [`ffmpeg_cli.v`](ffmpeg_cli.v) | Video/Audio transcoder, scaler & metadata probe | `v run cli_apps/ffmpeg_cli.v --interactive` |
| **ImageMagick CLI** | [`imagemagick_cli.v`](imagemagick_cli.v) | Image resizing, WebP conversion & thumbnails | `v run cli_apps/imagemagick_cli.v --interactive` |
| **yt-dlp Studio CLI** | [`yt_dlp_cli.v`](yt_dlp_cli.v) | Web stream, video & audio track downloader | `v run cli_apps/yt_dlp_cli.v --interactive` |
| **Audio Tag Studio CLI** | [`audiotag_cli.v`](audiotag_cli.v) | ID3 / FLAC metadata tag inspector | `v run cli_apps/audiotag_cli.v --interactive` |
| **ExifTool Studio CLI** | [`exif_cli.v`](exif_cli.v) | Image EXIF metadata reader & privacy stripper | `v run cli_apps/exif_cli.v --interactive` |
| **Tesseract OCR CLI** | [`ocr_cli.v`](ocr_cli.v) | Optical Character Recognition on image documents | `v run cli_apps/ocr_cli.v --interactive` |
| **Say Speech CLI** | [`say_cli.v`](say_cli.v) | Text-to-Speech synthesizer & voiceover exporter | `v run cli_apps/say_cli.v --interactive` |
| **Media Studio Hub CLI** | [`media_studio_cli.v`](media_studio_cli.v) | Unified audio/video/image master console | `v run cli_apps/media_studio_cli.v --interactive` |
| **Graphviz DOT CLI** | [`dot_cli.v`](dot_cli.v) | DOT graph diagram renderer (PNG, SVG, PDF) | `v run cli_apps/dot_cli.v --interactive` |

---

### 6. Math, Calculators & Scientific Tools
| Application | File | Description | Run Command |
| :--- | :--- | :--- | :--- |
| **Numbat Units CLI** | [`numbat_cli.v`](numbat_cli.v) | Physical units & dimensional analysis solver | `v run cli_apps/numbat_cli.v --interactive` |
| **Kalker Math CLI** | [`kalker_cli.v`](kalker_cli.v) | High-precision scientific math expression evaluator | `v run cli_apps/kalker_cli.v --interactive` |
| **Qalc Studio CLI** | [`qalc_cli.v`](qalc_cli.v) | Qalculate! power calculator & unit converter | `v run cli_apps/qalc_cli.v --interactive` |
| **Programmer Calc CLI**| [`calc_cli.v`](calc_cli.v) | HEX/DEC/OCT/BIN bitwise operations & endian | `v run cli_apps/calc_cli.v --interactive` |
| **Statistics Studio CLI**| [`statistics_cli.v`](statistics_cli.v) | Central tendency, dispersion, RMS, std dev | `v run cli_apps/statistics_cli.v --interactive` |
| **Graph Studio CLI** | [`graph_cli.v`](graph_cli.v) | Terminal ASCII bar & distribution visualizer | `v run cli_apps/graph_cli.v --interactive` |

---

### 7. Document, Archive & Transfer Utilities
| Application | File | Description | Run Command |
| :--- | :--- | :--- | :--- |
| **Pandoc Studio CLI** | [`pandoc_cli.v`](pandoc_cli.v) | Markdown, HTML, PDF, Docx document converter | `v run cli_apps/pandoc_cli.v --interactive` |
| **Ouch Archive CLI** | [`ouch_cli.v`](ouch_cli.v) | ZIP, TAR, GZ, 7Z, ZSTD compressor/extractor | `v run cli_apps/ouch_cli.v --interactive` |
| **Wget2 Downloader CLI**| [`wget2_cli.v`](wget2_cli.v) | Fast HTTP/HTTPS file download manager | `v run cli_apps/wget2_cli.v --interactive` |

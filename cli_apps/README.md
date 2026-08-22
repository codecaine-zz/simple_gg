# Production Console Applications Suite

This directory contains standalone, production-ready console applications and automation tools built with **`SimpleCLI`** for V, designed for DevOps, cloud operations, security, API benchmarking, and workspace management.

---

## 🛠️ Applications Overview

| Application | File | Description | Key Features |
| :--- | :--- | :--- | :--- |
| **DevOps Sentinel** | [`devops_sentinel.v`](devops_sentinel.v) | System health guardian & infrastructure monitor | TCP port probes (PostgreSQL, Redis, MySQL, HTTP), CPU/RAM/Swap telemetry, disk load thresholds, desktop notifications, JSON report export. |
| **Vault Backup Manager** | [`vault_backup_manager.v`](vault_backup_manager.v) | Enterprise encrypted archive & backup vault | Recursive directory backup, AES-256-CTR encryption, SHA-256 integrity verification, checksum manifests, and safe restoration. |
| **API Stress Bench** | [`api_stress_bench.v`](api_stress_bench.v) | High-performance HTTP latency & load benchmarker | Multi-threaded worker pool, throughput (req/s), latency distributions (Mean, Median, StdDev, RMS, Min, Max), HTTP status breakdown, JSON export. |
| **Git Workspace Pilot** | [`multirepo_git_pilot.v`](multirepo_git_pilot.v) | Multi-repository workspace synchronizer | Multi-repo discovery, parallel `fetch`/`pull`, dirty worktree detection, branch overview tables, and interactive batch stashing. |

---

## 1. DevOps Sentinel (`devops_sentinel.v`)

```bash
# Run a one-time comprehensive health check
v run cli_apps/devops_sentinel.v

# Run with automated desktop notifications and audio alert on high load
v run cli_apps/devops_sentinel.v --alert

# Export health metrics snapshot to JSON
v run cli_apps/devops_sentinel.v --export health_report.json

# Stream continuous structured logs to file
v run cli_apps/devops_sentinel.v --log /var/log/sentinel.log

# Launch interactive setup & socket diagnosis wizard
v run cli_apps/devops_sentinel.v --interactive
```

---

## 2. Vault Backup Manager (`vault_backup_manager.v`)

```bash
# Create an encrypted AES-256 archive of a folder
v run cli_apps/vault_backup_manager.v --backup --src ./my_data --dest ./backup.vault

# Backup with passphrase supplied via CLI flag
v run cli_apps/vault_backup_manager.v --backup --src ./my_data --dest ./backup.vault --key "secret123"

# Verify cryptographic SHA-256 integrity of all archived files
v run cli_apps/vault_backup_manager.v --verify --src ./backup.vault --key "secret123"

# Decrypt and restore the entire archive
v run cli_apps/vault_backup_manager.v --restore --src ./backup.vault --dest ./restored_data --key "secret123"
```

---

## 3. API Stress Bench (`api_stress_bench.v`)

```bash
# Run a 50-request benchmark with 4 concurrent worker threads
v run cli_apps/api_stress_bench.v --url https://httpbin.org/get --requests 50 --concurrency 4

# Benchmark a POST endpoint with JSON body
v run cli_apps/api_stress_bench.v --url https://httpbin.org/post --method POST --body '{"user":"test"}' --requests 100 --concurrency 8

# Export benchmark statistical latency report to JSON
v run cli_apps/api_stress_bench.v --url https://httpbin.org/get --requests 20 --export bench_results.json
```

---

## 4. Git Workspace Pilot (`multirepo_git_pilot.v`)

```bash
# Inspect all Git repositories in current directory
v run cli_apps/multirepo_git_pilot.v --path .

# Scan workspace and run parallel git fetch across all repositories
v run cli_apps/multirepo_git_pilot.v --path ~/projects --fetch

# Filter and only show repositories with dirty/uncommitted working trees
v run cli_apps/multirepo_git_pilot.v --path ~/projects --dirty-only

# Launch interactive batch stash/review wizard
v run cli_apps/multirepo_git_pilot.v --path ~/projects --interactive
```

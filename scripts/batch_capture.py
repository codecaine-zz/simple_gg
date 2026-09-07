import subprocess
import os
import sys
import time

apps_to_update = [
    "api_studio.v",
    "audiotag_studio.v",
    "brew_studio.v",
    "crypto_studio.v",
    "cut_studio.v",
    "disk_studio.v",
    "dns_studio.v",
    "docker_studio.v",
    "dot_studio.v",
    "exif_studio.v",
    "fd_studio.v",
    "ffmpeg_studio.v",
    "gawk_studio.v",
    "graph_studio.v",
    "imagemagick_studio.v",
    "jq_studio.v",
    "kalker_studio.v",
    "launchd_studio.v",
    "media_studio_hub.v",
    "nmap_studio.v",
    "numbat_studio.v",
    "ocr_studio.v",
    "pandoc_studio.v",
    "programmer_calculator.v",
    "qalc_studio.v",
    "recon_studio.v",
    "regex_studio.v",
    "rg_studio.v",
    "sd_studio.v",
    "sed_studio.v",
    "sqlite_studio.v",
    "statistics_studio.v",
    "subfinder_studio.v",
    "task_manager.v",
    "text_editor.v",
    "tr_studio.v",
    "wget2_studio.v",
    "yt_dlp_studio.v",
]

total = len(apps_to_update)
print(f"Starting batch capture of {total} applications...")

for idx, app in enumerate(apps_to_update, 1):
    app_path = os.path.join("applications", app)
    print(f"\n[{idx}/{total}] Processing {app}...")
    start_t = time.time()
    res = subprocess.run(["/tmp/capture_single.sh", app_path], capture_output=True, text=True)
    dur = time.time() - start_t
    if res.returncode != 0:
        print(f"FAILED {app} in {dur:.1f}s:\nSTDOUT: {res.stdout}\nSTDERR: {res.stderr}")
    else:
        print(f"SUCCESS {app} in {dur:.1f}s")

print("\nBatch capture complete!")

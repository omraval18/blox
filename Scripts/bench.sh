#!/usr/bin/env bash
# Measures the running Blox app: memory, CPU and threads, idle and after a burst of IPC requests.
# Usage: Scripts/bench.sh [seconds-to-sample-idle, default 10]
set -euo pipefail
seconds=${1:-10}
pid=$(pgrep -f "Blox.app/Contents/MacOS/Blox" | head -1 || true)
[[ -n "$pid" ]] || { echo "Blox is not running"; exit 1; }

footprint_mb() { footprint "$pid" 2>/dev/null | awk '/Footprint:/ {print $(NF-1), $NF; exit}'; }
rss_mb() { ps -o rss= -p "$pid" | awk '{printf "%.1f MB", $1/1024}'; }
threads() { ps -M -p "$pid" | tail -n +2 | wc -l | tr -d ' '; }
cpu() { top -l 2 -pid "$pid" -stats cpu -s "$seconds" | awk 'NF && $1 ~ /^[0-9.]+$/ {v=$1} END {print v "%"}'; }

echo "Blox pid $pid, binary $(stat -f %z /Applications/Blox.app/Contents/MacOS/Blox) bytes"
echo "idle  footprint: $(footprint_mb)   rss: $(rss_mb)   threads: $(threads)"
echo "idle  cpu over ${seconds}s: $(cpu)"

for _ in $(seq 1 300); do blox status >/dev/null; done
echo "after 300 IPC requests  footprint: $(footprint_mb)   rss: $(rss_mb)   threads: $(threads)"

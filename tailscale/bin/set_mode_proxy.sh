#!/bin/sh

BIN=/mnt/us/extensions/tailscale/bin
LOG=$BIN/autostart_log.txt
MODE_FILE=$BIN/autostart.mode

eips_log() {
    echo "[$(date)] $1" >> "$LOG"
    eips 0 22 "$(printf '%-50s' "$1")" 2>/dev/null
}

echo "proxy" > "$MODE_FILE"
eips_log "Autostart mode set to: proxy"

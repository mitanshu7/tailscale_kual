#!/bin/sh

BIN=/mnt/us/extensions/tailscale/bin
LOG=$BIN/tailscale_stop_log.txt

eips_log() {
    echo "$1" >> "$LOG"
    eips 0 22 "$(printf '%-50s' "$1")" 2>/dev/null
}

echo "[$(date)] Stopping Tailscale..." > "$LOG"

. "$BIN/lock.sh"
if ! acquire_lock; then
    eips_log "Another operation in progress, try again"
    exit 1
fi
trap release_lock EXIT

eips_log "Stopping Tailscale..."

if "$BIN/tailscale" down >> "$LOG" 2>&1; then
    eips_log "Tailscale stopped"
else
    eips_log "tailscale down failed - check log"
fi

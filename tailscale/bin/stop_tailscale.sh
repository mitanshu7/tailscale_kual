#!/bin/sh

BIN=/mnt/us/extensions/tailscale/bin
LOG=$BIN/tailscale_stop_log.txt

eips_log() {
    echo "$1" >> "$LOG"
    if [ "${TAILSCALE_SCRIPTLET:-0}" = "1" ]; then
        printf '%s\n' "$1"
    else
        eips 0 22 "$(printf '%-50s' "$1")" 2>/dev/null || true
    fi
}

echo "[$(date)] Stopping Tailscale..." > "$LOG"
eips_log "Stopping Tailscale..."

if "$BIN/tailscale" down >> "$LOG" 2>&1; then
    eips_log "Tailscale stopped"
else
    eips_log "tailscale down failed - check log"
fi

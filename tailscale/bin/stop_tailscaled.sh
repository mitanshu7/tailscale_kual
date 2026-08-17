#!/bin/sh

BIN=/mnt/us/extensions/tailscale/bin
LOG=$BIN/tailscaled_stop_log.txt

eips_log() {
    echo "$1" >> "$LOG"
    if [ "${TAILSCALE_SCRIPTLET:-0}" = "1" ]; then
        printf '%s\n' "$1"
    else
        eips 0 22 "$(printf '%-50s' "$1")" 2>/dev/null || true
    fi
}

echo "[$(date)] Stopping tailscaled..." > "$LOG"
eips_log "Stopping tailscaled..."

# Kill the running daemon first so the socket is released before cleanup.
# pkill returns non-zero if nothing was running, which is fine.
pkill tailscaled >> "$LOG" 2>&1 || true
sleep 3

# Remove stale socket in case pkill didn't fully release it in time.
rm -f /var/run/tailscale/tailscaled.sock

"$BIN/tailscaled" -cleanup >> "$LOG" 2>&1
EXIT=$?

# Remove socket one more time in case cleanup re-created it.
rm -f /var/run/tailscale/tailscaled.sock

if [ $EXIT -eq 0 ]; then
    eips_log "tailscaled stopped"
else
    eips_log "tailscaled cleanup failed - check log"
fi

#!/bin/sh

BIN=/mnt/us/extensions/tailscale/bin
LOG=$BIN/tailscaled_stop_log.txt

eips_log() {
    echo "$1" >> "$LOG"
    eips 0 22 "$(printf '%-50s' "$1")" 2>/dev/null
}

echo "[$(date)] Stopping tailscaled..." > "$LOG"

. "$BIN/lock.sh"
if ! acquire_lock; then
    eips_log "Another operation in progress, try again"
    exit 1
fi
trap release_lock EXIT

eips_log "Stopping tailscaled..."

# Gracefully disconnect before killing the daemon so tailscale can notify
# peers and clean up. Failure is non-fatal (daemon may not be connected).
if pgrep tailscaled > /dev/null 2>&1 && [ -x "$BIN/tailscale" ]; then
    eips_log "Disconnecting client first..."
    "$BIN/tailscale" down >> "$LOG" 2>&1 || true
    sleep 1
fi

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

if [ "$EXIT" -eq 0 ]; then
    eips_log "tailscaled stopped"
else
    eips_log "tailscaled cleanup failed - check log"
fi

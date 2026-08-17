#!/bin/sh
# Requires kernel TUN/TAP support. Not available on all Kindle firmware versions.

BIN=/mnt/us/extensions/tailscale/bin
LOG=$BIN/tailscaled_tun_start_log.txt

eips_log() {
    echo "$1" >> "$LOG"
    if [ "${TAILSCALE_SCRIPTLET:-0}" = "1" ]; then
        printf '%s\n' "$1"
    else
        eips 0 22 "$(printf '%-50s' "$1")" 2>/dev/null || true
    fi
}

echo "[$(date)] Starting tailscaled (kernel TUN)..." > "$LOG"

# Kill any existing instance and remove stale socket before starting.
# This makes it safe to switch modes without explicitly stopping first.
pkill tailscaled 2>/dev/null || true
sleep 2
rm -f /var/run/tailscale/tailscaled.sock

eips_log "Starting tailscaled (kernel TUN)..."

nohup "$BIN/tailscaled" --statedir="$BIN/" >> "$LOG" 2>&1 &
DAEMON_PID=$!

sleep 3
if kill -0 "$DAEMON_PID" 2>/dev/null; then
    eips_log "tailscaled started OK (kernel TUN)"
else
    eips_log "tailscaled failed - kernel TUN may not be supported"
fi

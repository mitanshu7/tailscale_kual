#!/bin/sh

BIN=/mnt/us/extensions/tailscale/bin
LOG=$BIN/tailscaled_start_log.txt

eips_log() {
    echo "$1" >> "$LOG"
    eips 0 22 "$(printf '%-50s' "$1")" 2>/dev/null
}

echo "[$(date)] Starting tailscaled..." > "$LOG"

. "$BIN/lock.sh"
if ! acquire_lock; then
    eips_log "Another operation in progress, try again"
    exit 1
fi
trap release_lock EXIT

# Kill any existing instance and remove stale socket before starting.
# This makes it safe to switch modes without explicitly stopping first.
pkill tailscaled 2>/dev/null || true
sleep 2
rm -f /var/run/tailscale/tailscaled.sock

eips_log "Starting tailscaled..."

nohup "$BIN/tailscaled" --statedir="$BIN/" -tun userspace-networking >> "$LOG" 2>&1 &
DAEMON_PID=$!

sleep 3
if kill -0 "$DAEMON_PID" 2>/dev/null; then
    eips_log "tailscaled started OK"
else
    eips_log "tailscaled failed to start - check log"
    exit 1
fi

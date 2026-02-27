#!/bin/sh

BIN=/mnt/us/extensions/tailscale/bin
TAILSCALE=$BIN/tailscale
AUTH_KEY=$BIN/auth.key
LOG=$BIN/tailscale_start_log.txt

eips_log() {
    echo "$1" >> "$LOG"
    eips 0 22 "$(printf '%-50s' "$1")" 2>/dev/null
}

echo "[$(date)] Starting Tailscale..." > "$LOG"

. "$BIN/lock.sh"
if ! acquire_lock; then
    eips_log "Another operation in progress, try again"
    exit 1
fi
trap release_lock EXIT

# Check that tailscaled is running before trying to connect
if ! pgrep tailscaled > /dev/null 2>&1; then
    eips_log "Error: tailscaled not running. Start it first"
    exit 1
fi

eips_log "Reconnecting to Tailscale..."

# Try reconnecting without re-authenticating first (works when the node is
# already registered and key expiry is disabled).  A timeout prevents hanging
# indefinitely: on a fresh/reset node tailscale up prints a login URL and
# waits forever rather than returning an error.
if timeout 15 "$TAILSCALE" up --ssh >> "$LOG" 2>&1; then
    eips_log "Tailscale connected!"
    exit 0
fi

eips_log "Reconnect failed, trying auth key..."

# Fall back to auth key for first-time registration or after a manual reset.
if [ -s "$AUTH_KEY" ]; then
    eips_log "Authenticating with auth key..."
    if "$TAILSCALE" up --ssh --auth-key="$(cat "$AUTH_KEY")" >> "$LOG" 2>&1; then
        eips_log "Tailscale connected!"
    else
        eips_log "Auth key login failed - check log"
        exit 1
    fi
else
    eips_log "Tailscale: fill in auth.key and retry"
    exit 1
fi


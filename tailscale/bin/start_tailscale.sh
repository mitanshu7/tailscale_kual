#!/bin/sh

TAILSCALE=/mnt/us/extensions/tailscale/bin/tailscale
AUTH_KEY=/mnt/us/extensions/tailscale/bin/auth.key
LOG=/mnt/us/extensions/tailscale/bin/tailscale_start_log.txt
UP_ARGS_FILE=/mnt/us/extensions/tailscale/bin/up.args

# Arguments passed verbatim to `tailscale up` from the up.args file
# (put all flags on a single line, e.g. "--ssh --accept-routes"; no comments).
UP_ARGS=""
if [ -f "$UP_ARGS_FILE" ]; then
    UP_ARGS=$(cat "$UP_ARGS_FILE")
fi

eips_log() {
    echo "$1" >> "$LOG"
    if [ "${TAILSCALE_SCRIPTLET:-0}" = "1" ]; then
        printf '%s\n' "$1"
    else
        eips 0 22 "$(printf '%-50s' "$1")" 2>/dev/null || true
    fi
}

echo "[$(date)] Starting Tailscale..." > "$LOG"
eips_log "Reconnecting to Tailscale..."

# Try reconnecting without re-authenticating first (works when the node is
# already registered and key expiry is disabled).  A timeout prevents hanging
# indefinitely: on a fresh/reset node tailscale up prints a login URL and
# waits forever rather than returning an error.
if timeout 15 "$TAILSCALE" up $UP_ARGS >> "$LOG" 2>&1; then
    eips_log "Tailscale connected!"
    exit 0
fi

eips_log "Reconnect failed, trying auth key..."

# Fall back to auth key for first-time registration or after a manual reset.
if [ -s "$AUTH_KEY" ]; then
    eips_log "Authenticating with auth key..."
    if "$TAILSCALE" up $UP_ARGS --auth-key="$(cat "$AUTH_KEY")" >> "$LOG" 2>&1; then
        eips_log "Tailscale connected!"
    else
        eips_log "Auth key login failed - check log"
        exit 1
    fi
else
    eips_log "Tailscale: fill in auth.key and retry"
    exit 1
fi

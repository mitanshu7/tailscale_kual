#!/bin/sh

BIN=/mnt/us/extensions/tailscale/bin
PROXY_ADDR_FILE=$BIN/proxy.address
LOG=$BIN/tailscaled_proxy_start_log.txt

eips_log() {
    echo "$1" >> "$LOG"
    eips 0 22 "$(printf '%-50s' "$1")" 2>/dev/null
}

echo "[$(date)] Starting tailscaled (proxy mode)..." > "$LOG"

. "$BIN/lock.sh"
if ! acquire_lock; then
    eips_log "Another operation in progress, try again"
    exit 1
fi
trap release_lock EXIT

# Read proxy address from config file, default to localhost:1055
if [ -s "$PROXY_ADDR_FILE" ]; then
    PROXY_ADDR=$(tr -d '[:space:]' < "$PROXY_ADDR_FILE")
else
    PROXY_ADDR=localhost:1055
fi

# Kill any existing instance and remove stale socket before starting.
# This makes it safe to switch modes without explicitly stopping first.
pkill tailscaled 2>/dev/null || true
sleep 2
rm -f /var/run/tailscale/tailscaled.sock

eips_log "Starting tailscaled (proxy: $PROXY_ADDR)..."

nohup "$BIN/tailscaled" --statedir="$BIN/" -tun userspace-networking \
    --socks5-server="$PROXY_ADDR" \
    --outbound-http-proxy-listen="$PROXY_ADDR" >> "$LOG" 2>&1 &
DAEMON_PID=$!

sleep 3
if kill -0 "$DAEMON_PID" 2>/dev/null; then
    eips_log "tailscaled started OK (proxy: $PROXY_ADDR)"
else
    eips_log "tailscaled failed to start - check log"
    exit 1
fi

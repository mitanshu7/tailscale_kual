#!/bin/sh

BIN=/mnt/us/extensions/tailscale/bin
LOG=$BIN/autostart_log.txt
MODE_FILE=$BIN/autostart.mode
AUTH_KEY=$BIN/auth.key
TAILSCALE=$BIN/tailscale
PROXY_ADDR_FILE=$BIN/proxy.address

log() {
    echo "[$(date)] $1" >> "$LOG"
}

# Read mode from config (default: standard)
MODE=standard
if [ -s "$MODE_FILE" ]; then
    MODE=$(tr -d '[:space:]' < "$MODE_FILE")
fi

log "=== Autostart begin (mode: $MODE) ==="

# Check if binaries exist
if [ ! -x "$BIN/tailscaled" ]; then
    log "tailscaled binary not found, aborting"
    exit 1
fi
if [ ! -x "$TAILSCALE" ]; then
    log "tailscale binary not found, aborting"
    exit 1
fi

# Wait for network (wlan0 to get an IP address)
TIMEOUT=120
ELAPSED=0
log "Waiting for network..."
while [ "$ELAPSED" -lt "$TIMEOUT" ]; do
    IP=$(ip addr show wlan0 2>/dev/null | grep 'inet ' | awk '{print $2}')
    if [ -n "$IP" ]; then
        log "Network ready: $IP"
        break
    fi
    sleep 5
    ELAPSED=$((ELAPSED + 5))
done

if [ "$ELAPSED" -ge "$TIMEOUT" ]; then
    log "Network not available after ${TIMEOUT}s, aborting"
    exit 1
fi

# Kill any existing tailscaled and clean up
pkill tailscaled 2>/dev/null || true
sleep 2
rm -f /var/run/tailscale/tailscaled.sock

# Start tailscaled based on configured mode
case "$MODE" in
    proxy)
        PROXY_ADDR=localhost:1055
        if [ -s "$PROXY_ADDR_FILE" ]; then
            PROXY_ADDR=$(tr -d '[:space:]' < "$PROXY_ADDR_FILE")
        fi
        log "Starting tailscaled (proxy: $PROXY_ADDR)"
        nohup "$BIN/tailscaled" --statedir="$BIN/" -tun userspace-networking \
            --socks5-server="$PROXY_ADDR" \
            --outbound-http-proxy-listen="$PROXY_ADDR" >> "$LOG" 2>&1 &
        ;;
    tun)
        log "Starting tailscaled (TUN mode)"
        nohup "$BIN/tailscaled" --statedir="$BIN/" >> "$LOG" 2>&1 &
        ;;
    *)
        log "Starting tailscaled (userspace networking)"
        nohup "$BIN/tailscaled" --statedir="$BIN/" -tun userspace-networking >> "$LOG" 2>&1 &
        ;;
esac

DAEMON_PID=$!
sleep 5

if ! kill -0 "$DAEMON_PID" 2>/dev/null; then
    log "tailscaled failed to start"
    exit 1
fi
log "tailscaled started (PID $DAEMON_PID)"

# Bring Tailscale up — try reconnect first, then auth key
log "Attempting reconnect..."
if timeout 15 "$TAILSCALE" up --ssh >> "$LOG" 2>&1; then
    log "Tailscale connected (reconnect)"
    exit 0
fi

log "Reconnect failed, trying auth key..."
if [ -s "$AUTH_KEY" ]; then
    if "$TAILSCALE" up --ssh --auth-key="$(cat "$AUTH_KEY")" >> "$LOG" 2>&1; then
        log "Tailscale connected (auth key)"
        exit 0
    else
        log "Auth key login failed"
        exit 1
    fi
fi

log "Reconnect failed and no auth key available"
exit 1

#!/bin/sh

BIN=/mnt/us/extensions/tailscale/bin
LOG=$BIN/status_log.txt
TAILSCALE=$BIN/tailscale
MODE_FILE=$BIN/autostart.mode

# Clear log for this run
echo "[$(date)] === Status check ===" > "$LOG"

eips_line() {
    ROW=$1
    MSG=$2
    echo "$MSG" >> "$LOG"
    eips 0 "$ROW" "$(printf '%-50s' "$MSG")" 2>/dev/null
}

# Clear display area (rows 17-22)
ROW=17
while [ "$ROW" -le 22 ]; do
    eips 0 "$ROW" "$(printf '%-50s' '')" 2>/dev/null
    ROW=$((ROW + 1))
done

# 1. Daemon status
if pgrep tailscaled > /dev/null 2>&1; then
    DAEMON="tailscaled: running"
else
    DAEMON="tailscaled: stopped"
fi
eips_line 17 "$DAEMON"

# 2. Connection status + IP
CONN="tailscale: disconnected"
TS_IP=""
if pgrep tailscaled > /dev/null 2>&1 && [ -x "$TAILSCALE" ]; then
    TS_IP=$("$TAILSCALE" ip -4 2>/dev/null)
    if [ -n "$TS_IP" ]; then
        CONN="tailscale: connected"
    else
        # No IP but daemon is running — check if tailscale is mid-connect
        STATUS_LINE=$("$TAILSCALE" status 2>&1 | head -1)
        case "$STATUS_LINE" in
            *"stopped"*)  CONN="tailscale: stopped" ;;
            *"NeedsLogin"*|*"authURL"*) CONN="tailscale: needs login" ;;
            *) CONN="tailscale: connecting..." ;;
        esac
    fi
fi
eips_line 18 "$CONN"

if [ -n "$TS_IP" ]; then
    eips_line 19 "IP: $TS_IP"
else
    eips_line 19 "IP: n/a"
fi

# 3. Autostart mode
MODE="standard"
if [ -s "$MODE_FILE" ]; then
    MODE=$(tr -d '[:space:]' < "$MODE_FILE")
fi
eips_line 20 "Autostart mode: $MODE"

# 4. Autostart enabled/disabled
AUTOSTART_TRIGGER=$BIN/autostart.enabled
if [ -f "$AUTOSTART_TRIGGER" ]; then
    eips_line 21 "Autostart: enabled"
else
    eips_line 21 "Autostart: disabled"
fi

eips_line 22 "--- status end ---"

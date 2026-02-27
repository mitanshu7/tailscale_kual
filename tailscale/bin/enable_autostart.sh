#!/bin/sh

BIN=/mnt/us/extensions/tailscale/bin
LOG=$BIN/autostart_log.txt
MODE_FILE=$BIN/autostart.mode
TRIGGER=$BIN/autostart.enabled
UPSTART_CONF=$BIN/tailscale-autostart.conf
UPSTART_DEST=/etc/upstart/tailscale-autostart.conf

eips_log() {
    echo "[$(date)] $1" >> "$LOG"
    eips 0 22 "$(printf '%-50s' "$1")" 2>/dev/null
}

# Create default mode file if it doesn't exist
if [ ! -s "$MODE_FILE" ]; then
    echo "standard" > "$MODE_FILE"
fi

MODE=$(tr -d '[:space:]' < "$MODE_FILE")

# Install upstart job if not already present
if [ ! -f "$UPSTART_DEST" ]; then
    if [ ! -f "$UPSTART_CONF" ]; then
        eips_log "Error: upstart conf missing from extension"
        exit 1
    fi

    mntroot rw 2>/dev/null
    cp -f "$UPSTART_CONF" "$UPSTART_DEST"
    mntroot ro 2>/dev/null

    if [ ! -f "$UPSTART_DEST" ]; then
        eips_log "Failed to install upstart job"
        exit 1
    fi
    eips_log "Installed upstart job"
fi

# Create the trigger file
touch "$TRIGGER"

if [ -f "$TRIGGER" ]; then
    eips_log "Autostart enabled (mode: $MODE)"
else
    eips_log "Failed to enable autostart"
    exit 1
fi

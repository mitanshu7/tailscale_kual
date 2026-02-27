#!/bin/sh

BIN=/mnt/us/extensions/tailscale/bin
LOG=$BIN/autostart_log.txt
TRIGGER=$BIN/autostart.enabled

eips_log() {
    echo "[$(date)] $1" >> "$LOG"
    eips 0 22 "$(printf '%-50s' "$1")" 2>/dev/null
}

# Check if already disabled
if [ ! -f "$TRIGGER" ]; then
    eips_log "Autostart already disabled"
    exit 0
fi

# Remove the trigger file — the upstart job stays installed but won't
# start tailscale without this file present.
rm -f "$TRIGGER"

if [ -f "$TRIGGER" ]; then
    eips_log "Failed to disable autostart"
    exit 1
else
    eips_log "Autostart disabled"
fi

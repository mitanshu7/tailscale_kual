#!/bin/sh
# Shared lock helpers for Tailscale KUAL scripts.
# Uses mkdir for atomic lock creation (portable to BusyBox/Kindle).
#
# Usage:
#   . "$BIN/lock.sh"
#   acquire_lock || exit 1
#   trap release_lock EXIT
#   ... rest of script ...

LOCKDIR=/var/run/tailscale/tailscale-kual.lock

acquire_lock() {
    ATTEMPTS=0
    while [ $ATTEMPTS -lt 5 ]; do
        if mkdir "$LOCKDIR" 2>/dev/null; then
            echo $$ > "$LOCKDIR/pid"
            return 0
        fi

        # Check if the holder is still alive (stale lock cleanup)
        if [ -f "$LOCKDIR/pid" ]; then
            HOLDER=$(cat "$LOCKDIR/pid" 2>/dev/null)
            if [ -n "$HOLDER" ] && ! kill -0 "$HOLDER" 2>/dev/null; then
                # Holder is dead — remove stale lock and retry immediately
                rm -rf "$LOCKDIR"
                continue
            fi
        fi

        ATTEMPTS=$((ATTEMPTS + 1))
        sleep 1
    done

    return 1
}

release_lock() {
    rm -rf "$LOCKDIR"
}

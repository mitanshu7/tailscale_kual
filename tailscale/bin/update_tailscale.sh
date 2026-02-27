#!/bin/sh

INSTALL_DIR=/mnt/us/extensions/tailscale/bin
TMP_DIR=/mnt/us/extensions/tailscale/tmp_update
LOG=$INSTALL_DIR/update_log.txt
ARCH=arm

# Print a message to the Kindle screen via eips and append to the log file.
# Text is padded to 50 chars so each call fully overwrites the previous line.
eips_print() {
    eips 0 22 "$(printf '%-50s' "$1")" 2>/dev/null
}

log() {
    echo "$1" >> "$LOG"
    eips_print "$1"
}

echo "[$(date)] Starting install/update..." > "$LOG"

. "$INSTALL_DIR/lock.sh"
if ! acquire_lock; then
    log "Another operation in progress, try again"
    exit 1
fi
trap release_lock EXIT

# Determine whether this is a fresh install or an upgrade
if [ -f "$INSTALL_DIR/tailscale" ]; then
    CURRENT=$("$INSTALL_DIR/tailscale" version 2>/dev/null | head -1)
else
    CURRENT="none"
fi
echo "Installed version : $CURRENT" >> "$LOG"

# Quick connectivity check before hitting the API
log "Checking internet connectivity..."
if ! curl -sf --max-time 10 --user-agent "tailscale-kual-updater/1.0" \
    -o /dev/null "https://api.github.com" 2>>"$LOG"; then
    log "ERROR: No internet. Connect to Wi-Fi first."
    exit 1
fi

# Resolve the latest release tag from the GitHub API
# curl is used instead of wget: BusyBox wget on this Kindle cannot complete
# TLS handshakes with github.com or pkgs.tailscale.com.
log "Checking latest Tailscale version..."
LATEST=$(curl -sf --max-time 15 --user-agent "tailscale-kual-updater/1.0" \
    "https://api.github.com/repos/tailscale/tailscale/releases/latest" 2>>"$LOG" \
    | grep '"tag_name"' | head -1 | sed 's/.*"v\([^"]*\)".*/\1/')

if [ -z "$LATEST" ]; then
    log "ERROR: Could not fetch version info. Try again."
    exit 1
fi
echo "Latest version    : $LATEST" >> "$LOG"

if [ "$CURRENT" = "$LATEST" ]; then
    log "Already up to date (v$LATEST). Nothing to do."
    exit 0
fi

if [ "$CURRENT" = "none" ]; then
    log "No binaries found. Installing v$LATEST..."
else
    log "Updating $CURRENT -> $LATEST..."
fi

# Download the tarball
mkdir -p "$TMP_DIR"
URL="https://pkgs.tailscale.com/stable/tailscale_${LATEST}_${ARCH}.tgz"
echo "Downloading $URL..." >> "$LOG"
log "Downloading tailscale v$LATEST (~31 MB). Please wait..."
curl -sL --user-agent "tailscale-kual-updater/1.0" -o "$TMP_DIR/ts.tgz" "$URL" 2>>"$LOG"

if [ $? -ne 0 ] || [ ! -s "$TMP_DIR/ts.tgz" ]; then
    log "ERROR: Download failed. Check Wi-Fi connectivity and try again."
    rm -rf "$TMP_DIR"
    exit 1
fi

# Extract
tar -xzf "$TMP_DIR/ts.tgz" -C "$TMP_DIR" 2>>"$LOG"

# Locate the binaries by name anywhere under the tmp dir (robust against
# tarballs that use a different top-level directory name or a flat layout)
TS_BIN=$(find "$TMP_DIR" -type f -name "tailscale"  | head -1)
TSD_BIN=$(find "$TMP_DIR" -type f -name "tailscaled" | head -1)

if [ -z "$TS_BIN" ] || [ -z "$TSD_BIN" ]; then
    log "ERROR: Could not find binaries in tarball."
    echo "tailscale  : ${TS_BIN:-not found}" >> "$LOG"
    echo "tailscaled : ${TSD_BIN:-not found}" >> "$LOG"
    rm -rf "$TMP_DIR"
    exit 1
fi

# Back up existing binaries before replacing (only when upgrading)
DAEMON_WAS_RUNNING=false
if [ "$CURRENT" != "none" ]; then
    [ -f "$INSTALL_DIR/tailscale" ]  && cp "$INSTALL_DIR/tailscale"  "$INSTALL_DIR/tailscale.bak"
    [ -f "$INSTALL_DIR/tailscaled" ] && cp "$INSTALL_DIR/tailscaled" "$INSTALL_DIR/tailscaled.bak"
    echo "Backed up existing binaries as *.bak" >> "$LOG"

    # Stop the running daemon to avoid version mismatch between the new CLI
    # and the old daemon.  We'll restart it after the update.
    if pgrep tailscaled > /dev/null 2>&1; then
        DAEMON_WAS_RUNNING=true
        log "Stopping running daemon for upgrade..."
        "$INSTALL_DIR/tailscale" down >> "$LOG" 2>&1 || true
        sleep 1
        pkill tailscaled >> "$LOG" 2>&1 || true
        sleep 2
        rm -f /var/run/tailscale/tailscaled.sock
    fi
fi

# Install binaries
cp "$TS_BIN"  "$INSTALL_DIR/tailscale"  && chmod +x "$INSTALL_DIR/tailscale"  || { log "ERROR: Failed to install tailscale.";  rm -rf "$TMP_DIR"; exit 1; }
cp "$TSD_BIN" "$INSTALL_DIR/tailscaled" && chmod +x "$INSTALL_DIR/tailscaled" || { log "ERROR: Failed to install tailscaled."; rm -rf "$TMP_DIR"; exit 1; }

rm -rf "$TMP_DIR"

# Create an empty auth.key placeholder on a fresh install
if [ ! -f "$INSTALL_DIR/auth.key" ]; then
    touch "$INSTALL_DIR/auth.key"
    echo "Created empty auth.key placeholder." >> "$LOG"
fi

if [ "$CURRENT" = "none" ]; then
    log "Install complete: v$LATEST. Fill in auth.key before starting Tailscale."
else
    log "Update complete: v$LATEST successfully installed."

    # Restart the daemon if it was running before the update so the user
    # doesn't have to manually re-start from the menu.
    if [ "$DAEMON_WAS_RUNNING" = true ]; then
        log "Restarting tailscaled..."
        MODE=standard
        if [ -s "$INSTALL_DIR/autostart.mode" ]; then
            MODE=$(tr -d '[:space:]' < "$INSTALL_DIR/autostart.mode")
        fi
        case "$MODE" in
            proxy)
                PROXY_ADDR=localhost:1055
                if [ -s "$INSTALL_DIR/proxy.address" ]; then
                    PROXY_ADDR=$(tr -d '[:space:]' < "$INSTALL_DIR/proxy.address")
                fi
                nohup "$INSTALL_DIR/tailscaled" --statedir="$INSTALL_DIR/" -tun userspace-networking \
                    --socks5-server="$PROXY_ADDR" \
                    --outbound-http-proxy-listen="$PROXY_ADDR" >> "$LOG" 2>&1 &
                ;;
            tun)
                nohup "$INSTALL_DIR/tailscaled" --statedir="$INSTALL_DIR/" >> "$LOG" 2>&1 &
                ;;
            *)
                nohup "$INSTALL_DIR/tailscaled" --statedir="$INSTALL_DIR/" -tun userspace-networking >> "$LOG" 2>&1 &
                ;;
        esac
        sleep 3
        if kill -0 "$!" 2>/dev/null; then
            log "Daemon restarted. Reconnecting..."
            if timeout 15 "$INSTALL_DIR/tailscale" up --ssh >> "$LOG" 2>&1; then
                log "Updated & reconnected (v$LATEST)"
            else
                log "Updated but reconnect failed - run Start Tailscale"
            fi
        else
            log "Updated but daemon failed to restart - check log"
        fi
    fi
fi

#!/bin/sh

INSTALL_DIR=/mnt/us/extensions/tailscale/bin
TMP_DIR=/mnt/us/extensions/tailscale/tmp_update
LOG=$INSTALL_DIR/update_log.txt
ARCH=arm
VERSIONS_TO_TRY=3

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

# Determine whether this is a fresh install or an upgrade
if [ -f "$INSTALL_DIR/tailscale" ]; then
    CURRENT=$("$INSTALL_DIR/tailscale" version 2>/dev/null | head -1)
else
    CURRENT="none"
fi
echo "Installed version : $CURRENT" >> "$LOG"

# Resolve the latest release tag from the GitHub API
# curl is used instead of wget: BusyBox wget on this Kindle cannot complete
# TLS handshakes with github.com or pkgs.tailscale.com.
log "Checking latest Tailscale version..."
LATEST_VERSIONS=$(curl -sf --user-agent "tailscale-kual-updater/1.0" \
    "https://api.github.com/repos/tailscale/tailscale/releases?per_page=${VERSIONS_TO_TRY}" 2>>"$LOG" \
    | sed -e 's/[{}]/''/g' | awk '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' \
    | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')

if [ -z "$LATEST_VERSIONS" ]; then
    log "ERROR: Could not determine latest versions. Check Wi-Fi connectivity."
    exit 1
fi

echo -e "Latest $VERSIONS_TO_TRY versions:\n$LATEST_VERSIONS" >> "$LOG"

# Iterated through release tags from GitHub API, until one with a 200 return code is found
for version in $LATEST_VERSIONS; do
    LATEST=$version
    echo "Checking $LATEST" >> "$LOG"
    URL="https://pkgs.tailscale.com/stable/tailscale_${LATEST}_${ARCH}.tgz"
    status=$(curl -s -o /dev/null -I -w "%{http_code}" ${URL})
    if [ "$status" = "200" ]; then
        echo "Using $LATEST" >> "$LOG"
        break
    else
        echo "Version $LATEST does not appear to have been built for ARM. Trying next version" >> "$LOG"
        continue
    fi
done

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
if [ "$CURRENT" != "none" ]; then
    [ -f "$INSTALL_DIR/tailscale" ]  && cp "$INSTALL_DIR/tailscale"  "$INSTALL_DIR/tailscale.bak"
    [ -f "$INSTALL_DIR/tailscaled" ] && cp "$INSTALL_DIR/tailscaled" "$INSTALL_DIR/tailscaled.bak"
    echo "Backed up existing binaries as *.bak" >> "$LOG"
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
fi

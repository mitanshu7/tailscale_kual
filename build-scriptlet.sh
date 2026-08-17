#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
VERSION=${VERSION:-0.4}
KTERM_URL=${KTERM_URL:-https://github.com/bfabiszewski/kterm/releases/download/v2.6/kterm-kindle-2.6.zip}
BUILD_DIR="$ROOT/build/tailscale-scriptlet-v$VERSION"
ARCHIVE="$ROOT/build/kterm-kindle-2.6.zip"
OUTPUT="$ROOT/build/tailscale-scriptlet-v$VERSION.zip"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/documents" "$BUILD_DIR/extensions"

if [ ! -s "$ARCHIVE" ]; then
    echo "Downloading kterm 2.6..."
    mkdir -p "$ROOT/build"
    curl -L --fail --output "$ARCHIVE" "$KTERM_URL"
fi

unzip -q "$ARCHIVE" -d "$BUILD_DIR/extensions"
cp -R "$ROOT/tailscale" "$BUILD_DIR/extensions/tailscale"
cp "$ROOT/scriptlet/bin/menu.sh" "$BUILD_DIR/extensions/tailscale-menu.sh"
cp "$ROOT/scriptlet/documents/Tailscale.sh" "$BUILD_DIR/documents/Tailscale.sh"
chmod +x "$BUILD_DIR/extensions/tailscale-menu.sh" "$BUILD_DIR/documents/Tailscale.sh" "$BUILD_DIR/extensions/tailscale/bin/"*.sh

rm -f "$OUTPUT"
(cd "$BUILD_DIR" && zip -qr "$OUTPUT" documents extensions)
echo "Created $OUTPUT"

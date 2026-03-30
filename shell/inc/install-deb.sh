#!/usr/bin/env bash
set -euo pipefail

# Variables
KEEP=false
DRY_RUN=false
URL=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --keep) KEEP=true ;;
    --dry-run) DRY_RUN=true ;;
    *) URL="$1" ;;
  esac
  shift
done

# Check if URL provided
if [ -z "$URL" ]; then
  echo "❌ Error: URL required"
  echo "Usage: $0 <url> [--keep] [--dry-run]"
  exit 1
fi

# Validate URL contains .deb (before query params or fragment)
if [[ ! "$URL" =~ \.deb(\?|#|$) ]]; then
  echo "❌ Error: URL must contain .deb file"
  exit 2
fi

# Check for wget or curl
if ! command -v wget >/dev/null 2>&1 && ! command -v curl >/dev/null 2>&1; then
  echo "❌ Error: Neither wget nor curl found"
  echo "Install with: sudo apt-get install wget curl"
  exit 5
fi

# Check for dpkg
if ! command -v dpkg >/dev/null 2>&1; then
  echo "❌ Error: dpkg not found"
  exit 5
fi

# Create temp directory
TEMP_DIR=$(mktemp -d)
# Strip query parameters and fragments from URL for filename
DEB_FILENAME=$(basename "$URL" | sed 's/?.*//' | sed 's/#.*//')
DEB_FILE="$TEMP_DIR/$DEB_FILENAME"

# Download (prefer wget, fallback to curl)
echo "📥 Downloading from: $URL"
if command -v wget >/dev/null 2>&1; then
  wget -q --show-progress -O "$DEB_FILE" "$URL" || { echo "❌ Download failed"; rm -rf "$TEMP_DIR"; exit 3; }
else
  curl -L -o "$DEB_FILE" "$URL" || { echo "❌ Download failed"; rm -rf "$TEMP_DIR"; exit 3; }
fi

echo "✅ Downloaded to: $DEB_FILE"

# Install with apt-get for dependency resolution
if [ "$DRY_RUN" = "true" ]; then
  echo "🔍 Dry-run: Would install: $DEB_FILE"
else
  echo "📦 Installing $DEB_FILE..."
  sudo apt-get install -y "$DEB_FILE" || { echo "❌ Installation failed"; echo "💡 Package kept at: $DEB_FILE"; exit 4; }
  echo "✅ Installation successful"
fi

# Remove .deb unless --keep flag
if [ "$KEEP" != "true" ]; then
  echo "🧹 Cleaning up..."
  rm -f "$DEB_FILE"
  rm -rf "$TEMP_DIR"
  echo "✅ Cleaned up"
else
  echo "💡 Package kept at: $DEB_FILE"
fi

exit 0

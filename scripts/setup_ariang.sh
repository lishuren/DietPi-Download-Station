#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LOCAL_DIR="$REPO_ROOT/downloads/ariang"
INSTALLER="$SCRIPT_DIR/install_ariang.sh"

# Auto-detect best source and run one-shot installer
# Priority: staged assets -> ZIP in /root -> versioned URL

has_local() {
  [ -f "$LOCAL_DIR/index.html" ] || [ -f "$LOCAL_DIR/dist/index.html" ] || \
  [ -n "$(find "$LOCAL_DIR" -type f -name index.html | head -n 1 || true)" ]
}

find_zip() {
  ls -1 /root/AriaNg-*.zip 2>/dev/null | head -n 1 || true
}

if has_local; then
  echo "Using staged assets at $LOCAL_DIR"
  "$INSTALLER"
  exit 0
fi

ZIP_PATH="$(find_zip)"
if [ -n "$ZIP_PATH" ] && [ -f "$ZIP_PATH" ]; then
  echo "Using local ZIP: $ZIP_PATH"
  "$INSTALLER" --zip "$ZIP_PATH"
  exit 0
fi

echo "Downloading from release URL"
"$INSTALLER" --url "https://github.com/mayswind/AriaNg/releases/download/1.3.12/AriaNg-1.3.12.zip"

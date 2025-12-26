#!/bin/bash
# update_mihomo.sh - Helper script to update config and restart service safely
# Usage: update_mihomo.sh <path_to_new_config>

set -e

NEW_CONFIG="$1"
TARGET_CONFIG="/etc/mihomo/config.yaml"

if [ -z "$NEW_CONFIG" ]; then
    echo "Error: No config file provided"
    exit 1
fi

if [ ! -f "$NEW_CONFIG" ]; then
    echo "Error: Config file not found: $NEW_CONFIG"
    exit 1
fi

# Basic validation
if [ ! -s "$NEW_CONFIG" ]; then
    echo "Error: Config file is empty"
    exit 1
fi

# Backup existing config
if [ -f "$TARGET_CONFIG" ]; then
    cp "$TARGET_CONFIG" "${TARGET_CONFIG}.bak"
fi

# Move new config to target
mv "$NEW_CONFIG" "$TARGET_CONFIG"
chmod 644 "$TARGET_CONFIG"

# Restart service
systemctl restart mihomo

echo "Config updated and service restarted successfully."

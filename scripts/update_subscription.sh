#!/bin/bash

# Script to update Clash/Mihomo subscription from a URL
# Usage: ./update_subscription.sh "YOUR_SUBSCRIPTION_URL"

CONFIG_DIR="/etc/mihomo"
CONFIG_FILE="$CONFIG_DIR/config.yaml"
BACKUP_FILE="$CONFIG_DIR/config.yaml.bak"

if [ -z "$1" ]; then
    echo "Error: No subscription URL provided."
    echo "Usage: $0 \"https://example.com/subscribe?token=...\""
    exit 1
fi

URL="$1"

echo "Updating subscription from: $URL"

# 1. Backup existing config
if [ -f "$CONFIG_FILE" ]; then
    echo "Backing up existing config..."
    cp "$CONFIG_FILE" "$BACKUP_FILE"
fi

# 2. Download new config
echo "Downloading new configuration..."
# We use -L to follow redirects, which is common for subscription links
curl -L -o "$CONFIG_FILE.tmp" "$URL"

if [ $? -ne 0 ]; then
    echo "Error: Download failed."
    exit 1
fi

# 3. Validate (Basic check)
if [ ! -s "$CONFIG_FILE.tmp" ]; then
    echo "Error: Downloaded file is empty."
    rm "$CONFIG_FILE.tmp"
    exit 1
fi

# 4. Apply new config
mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
echo "Configuration updated successfully."

# 5. Restart Service if running
if systemctl is-active --quiet mihomo; then
    echo "Restarting Mihomo service..."
    systemctl restart mihomo
    echo "Service restarted."
else
    echo "Mihomo service is not running. Start it with: ./toggle_vpn.sh on"
fi

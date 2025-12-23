#!/bin/bash

# Script to toggle VPN (Clash) for Aria2
# Usage: ./toggle_vpn.sh [on|off]

ARIA2_CONF="/etc/aria2/aria2.conf"
PROXY_URL="http://127.0.0.1:7890"

if [ "$1" == "on" ]; then
    echo "Turning VPN ON..."
    
    # 1. Start Clash Service
    systemctl start mihomo
    if systemctl is-active --quiet mihomo; then
        echo "Mihomo (Clash) service started."
    else
        echo "Error: Failed to start Mihomo service."
        exit 1
    fi

    # 2. Add Proxy to Aria2 Config
    # Check if all-proxy is already set
    if grep -q "^all-proxy=" "$ARIA2_CONF"; then
        sed -i "s|^all-proxy=.*|all-proxy=$PROXY_URL|" "$ARIA2_CONF"
    else
        echo "all-proxy=$PROXY_URL" >> "$ARIA2_CONF"
    fi
    echo "Updated Aria2 config with proxy."

    # 3. Restart Aria2
    systemctl restart aria2
    echo "Aria2 restarted. VPN is active."

elif [ "$1" == "off" ]; then
    echo "Turning VPN OFF..."

    # 1. Stop Clash Service
    systemctl stop mihomo
    echo "Mihomo (Clash) service stopped."

    # 2. Remove Proxy from Aria2 Config
    sed -i "/^all-proxy=/d" "$ARIA2_CONF"
    echo "Removed proxy from Aria2 config."

    # 3. Restart Aria2
    systemctl restart aria2
    echo "Aria2 restarted. VPN is disabled."

else
    echo "Usage: $0 [on|off]"
    exit 1
fi

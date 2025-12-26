#!/bin/bash

###############################################################################
# check_hardware.sh - Check disk and system info on Pi
# Usage: ./check_hardware.sh
###############################################################################

set -e

# Load configuration
if [ ! -f "pi.config" ]; then
    echo "Error: pi.config not found!"
    exit 1
fi

source pi.config

echo "=== Hardware Info for $REMOTE_HOST ==="

ssh -i "$PEM_FILE" "${REMOTE_USER}@${REMOTE_HOST}" << 'EOF'
    echo "--- Block Devices (lsblk) ---"
    lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT,UUID
    
    echo ""
    echo "--- Disk Usage (df -h) ---"
    df -h | grep -E '^Filesystem|/mnt|/dev/root'
    
    echo ""
    echo "--- Memory Usage ---"
    free -h
EOF

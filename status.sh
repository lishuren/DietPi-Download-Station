#!/usr/bin/env bash

[ -n "${BASH_VERSION:-}" ] || exec bash "$0" "$@"

###############################################################################
# status.sh - Check Pi status and view logs for debug
# Usage: ./status.sh [service_name]
#
# Examples:
#   ./status.sh          # Show all services
#   ./status.sh aria2    # Show only aria2 logs
#
# This script can be run periodically (via cron) for monitoring:
#   */5 * * * * cd /path/to/DietPi-NanoPi && ./status.sh > /tmp/dietpi-status.log 2>&1
###############################################################################

set -e

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/pi.config"

# Load configuration
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: pi.config not found!"
    echo "Copy pi.config.example to pi.config and update with your values."
    exit 1
fi

. "$CONFIG_FILE"

case "$PEM_FILE" in
    /*|[A-Za-z]:/*|[A-Za-z]:\\*) ;;
    *) PEM_FILE="$SCRIPT_DIR/$PEM_FILE" ;;
esac

SERVICE_FILTER="$1"
USB_DEVICE="/dev/sda1"
USB_MOUNT="/mnt/usb_data"

echo "=== Checking Status of $REMOTE_HOST ==="

ssh -i "$PEM_FILE" "${REMOTE_USER}@${REMOTE_HOST}" << EOF
    echo "=== System Status ==="
    uptime
    echo ""
    df -h / "$USB_MOUNT" /var/log 2>/dev/null || df -h /
    echo ""

    echo "=== USB Storage Status ==="
    if [ -b "$USB_DEVICE" ]; then
        echo "$USB_DEVICE detected"
        lsblk -o NAME,FSTYPE,SIZE,MOUNTPOINT "$USB_DEVICE" 2>/dev/null || echo "Unable to inspect $USB_DEVICE"
    else
        echo "ERROR: $USB_DEVICE not detected"
        echo "Aria2 will remain down until the USB device is visible again."
        lsblk -o NAME,FSTYPE,SIZE,MOUNTPOINT 2>/dev/null || echo "Unable to list block devices"
    fi
    echo ""

    echo "--- mnt-usb_data.mount ---"
    systemctl status mnt-usb_data.mount --no-pager -l 2>/dev/null || echo "mnt-usb_data.mount: not found or inactive"
    echo ""

    echo "=== Service Status ==="
    for service in aria2 mihomo nginx smbd nmbd; do
        if [ -z "$SERVICE_FILTER" ] || [ "$SERVICE_FILTER" == "\$service" ]; then
            echo "--- \$service ---"
            systemctl status \$service --no-pager -l 2>/dev/null || echo "\$service: not found or not running"
            echo ""
        fi
    done

    echo "=== Nginx Error Log (last 30 lines) ==="
    tail -n 30 /var/log/nginx/error.log 2>/dev/null || echo "No nginx error log found"
    echo ""

    echo "=== MetaCubeX Dashboard File Check ==="
    ls -l /var/www/html/metacubexd/index.html 2>/dev/null || echo "index.html not found"
    ls -ld /var/www/html/metacubexd 2>/dev/null || echo "metacubexd directory not found"
    echo ""

    echo "=== MetaCubeX Dashboard Permissions ==="
    namei -l /var/www/html/metacubexd/index.html 2>/dev/null || echo "Cannot check permissions"
    echo ""

        echo "=== /var/log tmpfs Status ==="
        if mount | grep '/var/log ' | grep -q tmpfs; then
            echo "/var/log is on tmpfs (RAM)"
        else
            echo "/var/log is NOT on tmpfs (likely on disk)"
        fi
        echo ""
        echo "--- RAW mount output for /var/log ---"
        mount | grep '/var/log' || echo '/var/log not mounted separately'
        echo ""
        echo "--- RAW df -hT output for /var/log ---"
        df -hT /var/log 2>/dev/null || echo 'df failed for /var/log'
        echo ""

    echo "=== USB Mount Path Check ==="
    ls -ld "$USB_MOUNT" 2>/dev/null || echo "$USB_MOUNT directory not present"
    df -h "$USB_MOUNT" 2>/dev/null || echo "$USB_MOUNT is not mounted"
    echo ""

    if [ -n "$SERVICE_FILTER" ]; then
        echo "=== Recent Logs for $SERVICE_FILTER ==="
        journalctl -u "$SERVICE_FILTER" -n 30 --no-pager 2>/dev/null || echo "No logs found"
    else
        echo "=== Recent Aria2 Logs ==="
        journalctl -u aria2 -n 20 --no-pager 2>/dev/null || echo "No aria2 logs"

        echo ""
        echo "=== Recent Mihomo Logs ==="
        journalctl -u mihomo -n 20 --no-pager 2>/dev/null || echo "No mihomo logs"
    fi
EOF

echo ""
echo "=== Status Check Complete ==="

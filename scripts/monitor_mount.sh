#!/bin/bash

# Watchdog script to ensure USB drive is mounted and Aria2 is running.
# Add this to cron: * * * * * /root/monitor_mount.sh

MOUNT_POINT="/mnt/usb_drive"
SERVICE="aria2"

# Check if mount point is a directory
if [ ! -d "$MOUNT_POINT" ]; then
    echo "Mount point does not exist."
    exit 1
fi

# Check if mounted
if ! mountpoint -q "$MOUNT_POINT"; then
    echo "Drive not mounted. Attempting to mount..."
    mount -a
    
    # Check again
    if mountpoint -q "$MOUNT_POINT"; then
        echo "Mount successful. Restarting Aria2..."
        systemctl restart "$SERVICE"
    else
        echo "Failed to mount drive."
        # Optional: Send alert (email/telegram) here
        exit 1
    fi
else
    # Drive is mounted, check if service is running
    if ! systemctl is-active --quiet "$SERVICE"; then
        echo "Service $SERVICE is down. Restarting..."
        systemctl start "$SERVICE"
    fi
fi

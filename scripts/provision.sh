#!/bin/bash

# Provision Script for NanoPi NEO Download Station
# Run this script on the NanoPi as root.

MOUNT_POINT="/mnt/usb_drive"
CONFIG_DIR="/etc/aria2"
USER="dietpi"
GROUP="dietpi"

# 1. Detect USB Drive
echo "Detecting USB drive..."
# We look for the first partition of the first USB disk (usually sda1)
USB_DEV=$(lsblk -rno NAME,TRAN | grep usb | head -n1 | cut -d' ' -f1)
if [ -z "$USB_DEV" ]; then
    echo "Error: No USB drive detected. Please plug in your drive."
    exit 1
fi
# Append partition number 1 if not present (simple assumption for single partition drives)
USB_PART="/dev/${USB_DEV}1"
if [ ! -b "$USB_PART" ]; then
    USB_PART="/dev/${USB_DEV}"
fi

echo "Found USB device: $USB_PART"

# 2. Get UUID
UUID=$(blkid -s UUID -o value "$USB_PART")
if [ -z "$UUID" ]; then
    echo "Error: Could not get UUID for $USB_PART"
    exit 1
fi
echo "UUID: $UUID"

# 3. Setup Mount Point
mkdir -p "$MOUNT_POINT"
chown -R $USER:$GROUP "$MOUNT_POINT"

# 4. Update fstab for Persistent Mount
if grep -q "$UUID" /etc/fstab; then
    echo "Entry for UUID $UUID already exists in fstab."
else
    echo "Adding entry to /etc/fstab..."
    # nofail: Boot continues even if drive is missing
    # x-systemd.device-timeout=5: Don't wait long for it
    echo "UUID=$UUID $MOUNT_POINT ext4 defaults,noatime,nofail,x-systemd.device-timeout=5 0 2" >> /etc/fstab
fi

# 5. Mount Now
mount -a
if mountpoint -q "$MOUNT_POINT"; then
    echo "Drive mounted successfully."
else
    echo "Error: Failed to mount drive."
    exit 1
fi

# 6. Setup Directory Structure on USB Drive
echo "Setting up USB drive directories..."
mkdir -p "$MOUNT_POINT/downloads"
mkdir -p "$MOUNT_POINT/aria2"
touch "$MOUNT_POINT/aria2/aria2.session"
chown -R $USER:$GROUP "$MOUNT_POINT"

# 7. Install Configuration
echo "Installing Aria2 configuration..."
mkdir -p "$CONFIG_DIR"
cp ../config/aria2.conf "$CONFIG_DIR/aria2.conf"
# Ensure the config points to the right place (sed replacement just in case)
sed -i "s|dir=.*|dir=$MOUNT_POINT/downloads|" "$CONFIG_DIR/aria2.conf"
sed -i "s|input-file=.*|input-file=$MOUNT_POINT/aria2/aria2.session|" "$CONFIG_DIR/aria2.conf"
sed -i "s|save-session=.*|save-session=$MOUNT_POINT/aria2/aria2.session|" "$CONFIG_DIR/aria2.conf"

# 8. Setup Systemd Service
echo "Configuring Systemd service..."
cat <<EOF > /etc/systemd/system/aria2.service
[Unit]
Description=Aria2 Download Manager
After=network.target mnt-usb_drive.mount
Requires=mnt-usb_drive.mount

[Service]
Type=simple
User=$USER
Group=$GROUP
ExecStart=/usr/bin/aria2c --conf-path=$CONFIG_DIR/aria2.conf
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable aria2
systemctl start aria2

# 9. Disable USB Power Saving (Prevent Drive Sleep)
echo "Disabling USB power saving features..."

# Install hdparm if missing
if ! command -v hdparm &> /dev/null; then
    apt-get update && apt-get install -y hdparm
fi

# Disable APM (Advanced Power Management) and Spindown
# -B 255: Disable APM
# -S 0: Disable spindown timer
hdparm -B 255 -S 0 "$USB_PART" || echo "Warning: Could not set hdparm for $USB_PART (Drive might not support it)"

# Disable USB Autosuspend via Kernel Parameter (Persistent)
# We append usbcore.autosuspend=-1 to /boot/cmdline.txt if not present
if ! grep -q "usbcore.autosuspend=-1" /boot/cmdline.txt; then
    sed -i 's/$/ usbcore.autosuspend=-1/' /boot/cmdline.txt
    echo "Added usbcore.autosuspend=-1 to /boot/cmdline.txt"
fi

# 10. Configure Samba Share
echo "Configuring Samba share..."
SMB_CONF="/etc/samba/smb.conf"

# Backup original config
if [ ! -f "$SMB_CONF.bak" ]; then
    cp "$SMB_CONF" "$SMB_CONF.bak"
fi

# Add 'downloads' share definition if not present
if ! grep -q "\[downloads\]" "$SMB_CONF"; then
    cat <<EOF >> "$SMB_CONF"

[downloads]
   comment = Aria2 Downloads
   path = $MOUNT_POINT/downloads
   browseable = yes
   create mask = 0664
   directory mask = 0775
   valid users = dietpi
   writeable = yes
EOF
    echo "Added [downloads] share to $SMB_CONF"
    systemctl restart smbd nmbd
else
    echo "Samba share [downloads] already exists."
fi

# 11. Install Clash (Mihomo)
echo "Installing Clash (Mihomo)..."
chmod +x ./install_clash.sh
./install_clash.sh

# 12. Install VPN Web Control
echo "Installing VPN Web Control..."
chmod +x ./install_vpn_web_ui.sh
./install_vpn_web_ui.sh

# 13. Install Watchdog (Monitor Mount)
echo "Installing Watchdog script..."
cp ./monitor_mount.sh /usr/local/bin/monitor_mount.sh
chmod +x /usr/local/bin/monitor_mount.sh

# Add to crontab if not exists (Run every minute)
CRON_JOB="* * * * * /usr/local/bin/monitor_mount.sh >> /var/log/monitor_mount.log 2>&1"
(crontab -l 2>/dev/null | grep -F "/usr/local/bin/monitor_mount.sh") || (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -

echo "Provisioning Complete! Aria2 is running."

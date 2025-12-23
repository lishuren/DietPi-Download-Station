#!/bin/bash

# Install Mihomo (Clash Meta) for ARMv7 (NanoPi NEO)
# We use Mihomo because it is the active fork of Clash and supports more protocols.

INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="/etc/mihomo"
SERVICE_FILE="/etc/systemd/system/mihomo.service"

# 1. Download Mihomo
# Note: Checking for latest version is better, but for stability we pin a known working version or use "latest" logic if possible.
# Here we use a fixed URL for stability. You can update this URL.
# Architecture: armv7
DOWNLOAD_URL="https://github.com/MetaCubeX/mihomo/releases/download/v1.18.1/mihomo-linux-armv7-v1.18.1.gz"

echo "Downloading Mihomo (Clash Meta)..."
curl -L -o mihomo.gz "$DOWNLOAD_URL"

if [ $? -ne 0 ]; then
    echo "Download failed!"
    exit 1
fi

# 2. Install Binary
echo "Installing binary..."
gzip -d mihomo.gz
chmod +x mihomo
mv mihomo "$INSTALL_DIR/mihomo"

# 3. Create Config Directory
mkdir -p "$CONFIG_DIR"
# We expect the user to provide a config.yaml, but we can copy a template if it exists in our repo
if [ -f "../config/clash_config.yaml" ]; then
    cp "../config/clash_config.yaml" "$CONFIG_DIR/config.yaml"
else
    touch "$CONFIG_DIR/config.yaml"
fi

# 4. Download Country MMDB (GeoIP)
echo "Downloading Country.mmdb..."
curl -L -o "$CONFIG_DIR/Country.mmdb" "https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/country.mmdb"
curl -L -o "$CONFIG_DIR/GeoSite.dat" "https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geosite.dat"

# 5. Create Systemd Service
echo "Creating Systemd service..."
cat <<EOF > "$SERVICE_FILE"
[Unit]
Description=Mihomo (Clash Meta) Daemon
After=network.target

[Service]
Type=simple
User=root
ExecStart=$INSTALL_DIR/mihomo -d $CONFIG_DIR
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
# We do NOT enable it by default. The user should enable it via the toggle script or manually.
# systemctl enable mihomo

echo "Mihomo installed. Use 'scripts/toggle_vpn.sh on' to start it."

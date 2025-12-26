#!/bin/bash

###############################################################################
# setup.sh - Install assets to NanoPi
# Usage: ./setup.sh
#
# This script:
# 1. Uploads binaries (mihomo) to /usr/local/bin
# 2. Uploads config files (country.mmdb, geosite.dat, config.yaml) to /etc/mihomo
# 3. Uploads web assets (vpn.php, index.html) to /var/www/html
###############################################################################

set -e

# Load configuration
if [ ! -f "pi.config" ]; then
    echo "Error: pi.config not found!"
    echo "Copy pi.config.example to pi.config and update with your values."
    exit 1
fi

source pi.config

echo "=== Installing Assets to $REMOTE_HOST ==="

# Check SSH connection
echo "Testing SSH connection..."
if ! ssh -i "$PEM_FILE" -o ConnectTimeout=5 "${REMOTE_USER}@${REMOTE_HOST}" "echo 'Connection successful'" > /dev/null 2>&1; then
    echo "Error: Cannot connect to ${REMOTE_HOST}"
    echo "Check your pi.config and SSH key permissions (chmod 600 ${PEM_FILE})"
    exit 1
fi

# 1. Upload binaries
echo "Uploading binaries..."
ssh -i "$PEM_FILE" "${REMOTE_USER}@${REMOTE_HOST}" "mkdir -p /usr/local/bin"
if [ -f "assets/binaries/mihomo" ]; then
    scp -i "$PEM_FILE" assets/binaries/mihomo "${REMOTE_USER}@${REMOTE_HOST}:/usr/local/bin/"
    ssh -i "$PEM_FILE" "${REMOTE_USER}@${REMOTE_HOST}" "chmod +x /usr/local/bin/mihomo"
else
    echo "Warning: assets/binaries/mihomo not found"
fi

# 2. Upload Mihomo Configs
echo "Uploading Mihomo configs..."
ssh -i "$PEM_FILE" "${REMOTE_USER}@${REMOTE_HOST}" "mkdir -p /etc/mihomo"

if [ -f "assets/binaries/country.mmdb" ]; then
    scp -i "$PEM_FILE" assets/binaries/country.mmdb "${REMOTE_USER}@${REMOTE_HOST}:/etc/mihomo/"
else
    echo "Warning: assets/binaries/country.mmdb not found"
fi

if [ -f "assets/binaries/geosite.dat" ]; then
    scp -i "$PEM_FILE" assets/binaries/geosite.dat "${REMOTE_USER}@${REMOTE_HOST}:/etc/mihomo/"
else
    echo "Warning: assets/binaries/geosite.dat not found"
fi

if [ -f "assets/templates/config.yaml" ]; then
    scp -i "$PEM_FILE" assets/templates/config.yaml "${REMOTE_USER}@${REMOTE_HOST}:/etc/mihomo/"
else
    echo "Warning: assets/templates/config.yaml not found"
fi

# 3. Upload Web Assets
echo "Uploading web assets..."
ssh -i "$PEM_FILE" "${REMOTE_USER}@${REMOTE_HOST}" "mkdir -p /var/www/html/api"

if [ -f "assets/web/index.html" ]; then
    scp -i "$PEM_FILE" assets/web/index.html "${REMOTE_USER}@${REMOTE_HOST}:/var/www/html/"
fi

if [ -f "assets/web/vpn.php" ]; then
    scp -i "$PEM_FILE" assets/web/vpn.php "${REMOTE_USER}@${REMOTE_HOST}:/var/www/html/"
fi

# Upload API files if they exist
if [ -d "assets/web/api" ]; then
    scp -i "$PEM_FILE" assets/web/api/*.php "${REMOTE_USER}@${REMOTE_HOST}:/var/www/html/api/" 2>/dev/null || true
fi

echo "=== Setup Complete ==="
echo "Next steps:"
echo "1. Edit local_configs/ files as needed"
echo "2. Run: ./deploy.sh to deploy configurations"
echo "3. Run: ./status.sh to check Pi status"

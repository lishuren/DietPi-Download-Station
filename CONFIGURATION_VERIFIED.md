# Configuration Verification Checklist

## ✓ LOCAL CONFIGS (local_configs/)
- **aria2.conf** - dir=/mnt/usb_data/downloads, save-session=/mnt/usb_data/aria2/aria2.session
- **aria2.service** - Systemd service for Aria2
- **smb.conf** - guest_account=downloads, force user=root, /mnt/usb_data path
- **nginx-default-site** - PHP-FPM enabled on port 9000
- **nginx.conf** - Main nginx configuration
- **index.html** - Portal homepage with API polling

## ✓ SHELL SCRIPTS
- **setup.sh** - Uploads assets/web/api/*.php to /var/www/html/api/
- **deploy.sh** - Deploys configs, creates /mnt/usb_data/downloads and /mnt/usb_data/aria2
- **download.sh** - Downloads configs from Pi to local_configs/
- **status.sh** - Checks /dev/sda1, /mnt/usb_data, and dependent services
- **update_configs.sh** - Template for programmatic config updates

## ✓ WEB ASSETS (assets/web/)
- **index.html** - Portal dashboard with stats

- **api/aria2.php** - Aria2 RPC statistics (via HTTP)
- **api/mount.php** - USB mount status and disk usage
- **api/services.php** - Service health check (systemctl status)
- **api/system.php** - CPU, memory, temperature stats

## ✓ DOCUMENTATION
- **RUNBOOK.md** - USB Drive Setup section with mount instructions
- **DEPLOYMENT_NOTES.md** - Updated with /mnt/usb_data paths
- **README.md** - Project overview and quick start

## ✓ PATH VERIFICATION
- **No /mnt/usb_drive references** - All paths changed to /mnt/usb_data
- **All configs use /mnt/usb_data/downloads** - For Aria2 and Samba
- **All configs use /mnt/usb_data/aria2** - For session files
- **All scripts reference correct paths** - No hardcoded /mnt/usb_drive

## ✓ STATUS ON PI (historical reference)
- USB mounted at /mnt/usb_data (exFAT format)
- /mnt/usb_data/downloads - 477GB available
- /mnt/usb_data/aria2/aria2.session - Aria2 session file
- All services running: aria2, nginx, php-fpm, smbd, nmbd
- Portal accessible at http://192.168.0.139/
- Samba share \\192.168.0.139\downloads as 'downloads' user

## ✓ DEPLOYMENT PROCESS
1. setup.sh - Uploads all assets and API files
2. deploy.sh - Deploys local_configs to /etc/ paths and creates directories
3. download.sh - Pulls current configs back from Pi for version control
4. status.sh - Monitors system health and services

All changes synchronized between local files and Pi.

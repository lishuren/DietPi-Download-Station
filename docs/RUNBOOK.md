# DietPi Download Station - Runbook

Complete setup and operations guide for the DietPi Download Station project.
*Originally designed for NanoPi NEO/NEO2, but applicable to most Single Board Computers (Raspberry Pi, Orange Pi, etc.) running DietPi.*

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Initial Setup](#initial-setup)
3. [SSH Key Configuration](#ssh-key-configuration)
4. [Asset Preparation](#asset-preparation)
5. [Deployment](#deployment)
6. [Verification](#verification)
7. [Daily Operations](#daily-operations)
8. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Hardware
- **NanoPi NEO/NEO2** or any **DietPi-supported SBC** (Raspberry Pi, Orange Pi, etc.)
- **TF card** (8GB minimum, 16GB+ recommended)
- **USB storage device** (formatted as ext4, exFAT, or NTFS)
- **Network connection** (Ethernet recommended)

### Software (PC Side)
- **Windows**: PowerShell with SSH client, or WSL/Git Bash
- **Mac/Linux**: Terminal with SSH client
- **SD Card Tool**: Etcher, Win32DiskImager, or dd

---

## Initial Setup

### Step 1: Download DietPi Image

1. Go to https://dietpi.com/downloads/images/
2. Find **NanoPi NEO** or **NanoPi NEO2** image
3. Download the image:
   - For NEO (ARMv7): `DietPi_NanoPiNEO-ARMv7-Bookworm.img.xz`
   - For NEO2 (ARMv8): `DietPi_NanoPiNEO2-ARMv8-Trixie.img.xz`

> **Note**: For other device models, please check [https://dietpi.com/#downloadinfo](https://dietpi.com/#downloadinfo) to find the correct image for your hardware.

**Important**: Do NOT commit this image to git. It's 200MB+ compressed.

### Step 2: Flash TF Card

#### Windows (using Etcher)
```powershell
# Download and install Etcher from balena.io
# Run Etcher, select image, select SD card, flash
```

#### Linux/Mac
```bash
# Extract image
xz -d DietPi_NanoPiNEO-ARMv7-Bookworm.img.xz

# Flash to SD card (replace /dev/sdX with your SD card)
sudo dd if=DietPi_NanoPiNEO-ARMv7-Bookworm.img of=/dev/sdX bs=4M status=progress
sync
```

### Step 3: GitHub IP Bypass (Optional)

If you are in a region where GitHub DNS is blocked, you can configure a pre-script to map GitHub IPs manually.

1.  **Create Pre-Setup Script**:
    On the boot partition of the SD card, create a file named `Automation_Custom_PreScript.sh` (ensure Unix LF line endings). You can use the template provided in the project root.
    ```bash
    #!/bin/bash
    # Manually map GitHub domains to known IP addresses
    echo "20.205.243.166  github.com" >> /etc/hosts
    echo "185.199.111.133 raw.githubusercontent.com" >> /etc/hosts
    ```

2.  **Enable in dietpi.txt**:
    Ensure `dietpi.txt` has:
    ```ini
    AUTO_SETUP_AUTOMATED=1
    AUTO_CustomScriptURL=0
    ```

3.  **Verify IPs**:
    Ping `github.com` and `raw.githubusercontent.com` on your PC to verify the IPs are current.

### Step 4: Configure dietpi.txt

1. Mount the boot partition of the TF card
2. Copy `dietpi.txt` from project root to the boot partition
3. **Optional**: Edit settings (timezone, password, etc.)

### Step 5: First Boot

1. Insert TF card into NanoPi
2. Connect Ethernet cable and USB storage
3. Power on
4. **Wait 5-10 minutes** for auto-installation to complete.
   - You can check your router's DHCP client list to find the Pi's IP address.
   - **Note**: Even if the device appears online in your router with a short uptime (e.g., 2 minutes), the automated installation script is likely still running. **Do not SSH in immediately.** Wait for the full 5-10 minutes to ensure all packages (Nginx, Samba, etc.) are fully installed.
5. Once the IP is confirmed and time has passed, proceed to SSH configuration.

---

## SSH Key Configuration

### Generate SSH Key Pair

```bash
cd /path/to/DietPi-NanoPi
ssh-keygen -t rsa -b 4096 -f dietpi.pem -C "dietpi-nanopi"
chmod 600 dietpi.pem  # Linux/Mac only
```

### Create Configuration File

```bash
cp pi.config.example pi.config
# Edit pi.config with your Pi's IP address
```

### Copy Public Key to Pi

```bash
# First time only - uses password "dietpi"
ssh-copy-id -i dietpi.pem.pub root@192.168.1.100
```

---

## Asset Preparation

Download required assets to the `assets/` folder:

### 1. Mihomo (Clash Meta)
- Visit: https://github.com/MetaCubeX/mihomo/releases
- Download:
  - For 32-bit (ARMv7, e.g., NanoPi NEO, Pi 2): `mihomo-linux-armv7-*.gz`
  - For 64-bit (ARMv8/AArch64, e.g., NanoPi NEO2, Pi 3/4/5): `mihomo-linux-arm64-*.gz`
- Extract and rename to: `assets/binaries/mihomo`

### 2. GeoIP Database
- Visit: https://github.com/Dreamacro/maxmind-geoip/releases
- Download: `Country.mmdb`
- Rename to: `assets/binaries/country.mmdb`

See [assets/README.md](../assets/README.md) for detailed download links.

---

## Deployment

### Initial Deployment

```bash
# 1. Install assets to Pi
./setup.sh

# 2. Deploy configurations
./deploy.sh

# 3. Check status
./status.sh
```

### USB Drive Setup

For advanced storage configuration, including **Hot-Swap support** and **minimizing SD card wear**, please refer to the [Storage & Services Configuration](#storage--services-configuration) section below.

### Development Workflow

```bash
# Edit configs locally
nano local_configs/aria2.conf

# Deploy changes
./deploy.sh

# Verify
./status.sh
```

---

## Verification

### Check Services

```bash
./status.sh
```

Expected output shows all services as `active (running)`.

### Test Web Access

- **Portal**: `http://<pi-ip>/`
- **AriaNg**: `http://<pi-ip>/ariang`
- **VPN Control**: `http://<pi-ip>/vpn.php`

### Test Samba Access

**Windows**: `Win+R → \\<pi-ip>\downloads`  
**Mac**: `Finder → Go → Connect to Server → smb://<pi-ip>/downloads`

---

## Daily Operations

### Edit Configurations

```bash
nano local_configs/aria2.conf
./deploy.sh
./status.sh
```

### Check Logs

```bash
./status.sh           # All services
./status.sh aria2     # Specific service
```

### Update Clash Subscription

Via Web UI: `http://<pi-ip>/vpn.php` → Paste URL → Update

Or edit `local_configs/clash_config.yaml` → `./deploy.sh`

---

## Storage & Services Configuration

### 1. Hot-Swap USB Support (Recommended)

To support changing USB disks without reconfiguration and ensure consistent mount points:

1.  **Install Drivers**:
    ```bash
    apt install exfatprogs ntfs-3g
    ```

2.  **Generic Auto-Mount**:
    Edit `/etc/fstab` to mount `/dev/sda1` to a fixed path:
    ```bash
    mkdir -p /mnt/usb_data
    nano /etc/fstab
    ```
    Add the following line:
    ```bash
    /dev/sda1 /mnt/usb_data auto nofail,x-systemd.automount,uid=dietpi,gid=dietpi,umask=000,rw 0 0
    ```
    *Note: `umask=000` ensures full access on exFAT.*

3.  **Update Apps**:
    - Aria2: `dir=/mnt/usb_data/downloads`
    - Samba: `path = /mnt/usb_data`

### 2. Aria2 Configuration (Minimize SD Card Wear)

To ensure Aria2 downloads to the external USB disk and minimizes SD card writes:

1.  **Configure Aria2**:
    Edit `aria2.conf` (or update via `local_configs/aria2.conf` and deploy):
    ```ini
    dir=/mnt/usb_data/downloads
    continue=true
    input-file=/mnt/usb_data/aria2/aria2.session
    save-session=/mnt/usb_data/aria2/aria2.session
    save-session-interval=60
    disk-cache=64M
    file-allocation=falloc
    ```

2.  **Move Swap**:
    Use `dietpi-drive_manager` to move Swapfile to USB.

### 3. Samba Setup

To allow Read/Write access on the external USB disk:

1.  **Install Samba**: (Already installed via dietpi.txt ID 96)
2.  **Configure Path**:
    Edit `smb.conf`:
    ```ini
    [dietpi]
    path = /mnt/usb_data
    writeable = yes
    ```
3.  **Permissions**:
    ```bash
    # For ext4 drives (exFAT handled by fstab umask)
    chown -R dietpi:dietpi /mnt/usb_data
    chmod -R 775 /mnt/usb_data
    ```
4.  **Restart**: `systemctl restart nmbd smbd`

---

## Troubleshooting

### GitHub Connectivity Blocked (China/GFW)

**Symptom:** DietPi first-run setup fails with "Failed to connect to raw.githubusercontent.com"

**Root Cause:** GitHub is blocked by the Great Firewall in China. DietPi's first-run setup always tries to check for updates from GitHub, regardless of CONFIG_CHECK_DIETPI_UPDATES setting (that only affects post-installation automated checks).

**Solution - Bypass DietPi Installation System:**

1. **Let first boot fail** (it will get stuck on update check dialog)

2. **SSH into the Pi** when the dialog appears:
   ```bash
   ssh -i dietpi.pem root@<pi-ip>
   ```

3. **Kill stuck processes and force direct APT installation:**
   ```bash
   # Kill the stuck dialog and dietpi-software loop
   pkill -9 whiptail
   pkill -9 dietpi-software
   pkill -9 dietpi-update
   
   # Set install stage to bypass first-run checks
   echo 1 > /boot/dietpi/.install_stage
   
   # Install packages directly with APT (bypasses DietPi's GitHub checks)
   apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
     openssh-server aria2 nginx-light samba php-fpm php-cli unzip > /tmp/install.log 2>&1 &
   ```

4. **Monitor installation progress:**
   ```bash
   # Check if apt is running (wait 10-15 minutes)
   ps aux | grep apt | grep -v grep
   
   # Check log
   tail -f /tmp/install.log
   ```

5. **Verify services after installation:**
   ```bash
   systemctl status nginx aria2 samba ssh
   # Nginx should show "active (running)"
   ```

6. **Create Aria2 service manually** (DietPi's automated setup was bypassed):
   ```bash
   # Will be covered in deployment section
   ```

**Why CONFIG_CHECK_DIETPI_UPDATES=0 doesn't help:**
- That setting only controls **automated daily checks** after installation
- **First-run setup** is hardcoded to check for updates regardless
- The only solution is to bypass dietpi-software and use direct APT installation

**After VPN is configured:** You can update DietPi through Mihomo VPN using the web portal's "Update System" button or manually: `dietpi-update`

---

### First-Run Installation Stuck or Hanging

If the Pi is stuck at a "First run setup failed" dialog or installation isn't progressing:

**Check if installation is still running:**
```bash
# Check for apt/dpkg processes
ssh -i dietpi.pem root@<pi-ip> "ps aux | grep -E 'apt|dpkg' | grep -v grep"

# If output shows apt-get running: WAIT 10-15 minutes, it's still installing
# If no output: Installation completed or stuck
```

**Check installation log:**
```bash
ssh -i dietpi.pem root@<pi-ip> "tail -20 /var/tmp/dietpi/logs/dietpi-firstrun-setup.log"

# Should show [OK] DietPi-Update | APT update or package installation messages
```

**If stuck on "DietPi-Update failed" dialog:**
```bash
# Kill the dialog and manually start software installation
ssh -i dietpi.pem root@<pi-ip> "pkill -f whiptail"
ssh -i dietpi.pem root@<pi-ip> "/boot/dietpi/dietpi-software install 105 132 85 96 89"

# Then monitor:
watch -n 5 'ssh -i dietpi.pem root@<pi-ip> "ps aux | grep -E apt"'
```

**Verify services after installation completes:**
```bash
# Check if services are running
ssh -i dietpi.pem root@<pi-ip> "systemctl status aria2 nginx samba ssh"

# If all show "active (running)", installation is complete
```

**Why this happens:**
- DietPi tries to check GitHub during first boot but network may not be ready
- The update check fails but APT (Debian repos) works fine
- Software still installs even if update check fails
- Solution: `dietpi.txt` now has `CONFIG_CHECK_DIETPI_UPDATES=2` to disable this check

---

### Cannot Connect via SSH

```bash
# Test connection
ping <pi-ip>

# Verify SSH key permissions
chmod 600 dietpi.pem
```

### Aria2 Not Starting

```bash
# Check logs
./status.sh aria2

# Verify USB mount
ssh -i dietpi.pem root@<pi-ip>
df -h /mnt
```

### Nginx Shows Default Page

```bash
# Deploy homepage
./deploy.sh

# Remove nginx default
ssh -i dietpi.pem root@<pi-ip>
rm -f /var/www/html/index.nginx-debian.html
```

### Services Not Responding

```bash
# Check status
./status.sh

# Restart services
./deploy.sh
```

---

## Security Best Practices

1. Never commit `dietpi.pem` or `pi.config` to git
2. Set SSH key permissions: `chmod 600 dietpi.pem`
3. Change default password: `ssh -i dietpi.pem root@<ip>` → `passwd`
4. Use Aria2 RPC secret in `local_configs/aria2.conf`

---

## Maintenance

### Update DietPi

```bash
ssh -i dietpi.pem root@<pi-ip>
dietpi-update
```

### Backup Configuration

```bash
./download.sh
git add local_configs/
git commit -m "Backup configs"
git push
```

---

**For more details:**
- [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md) - Architecture overview
- [../assets/README.md](../assets/README.md) - Asset download links
- [../local_configs/README.md](../local_configs/README.md) - Config management

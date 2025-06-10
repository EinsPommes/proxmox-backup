#!/bin/bash
set -euo pipefail

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root"
    exit 1
fi

# Default configuration
cat > /etc/proxmox-backup.conf << 'EOF'
# Proxmox Backup Configuration
BACKUP_DIR="/backups"
NAS_USER="backupuser"
NAS_HOST="192.168.1.100"
NAS_PATH="/volume1/proxmox-backups"
NAS_PASSWORD="V%k39elB"
TELEGRAM_TOKEN=""
TELEGRAM_CHAT_ID=""
RESTORE_STORAGE="local-lvm"
RETENTION_DAYS=7
VERIFY_TIMEOUT=60
EOF

# Install script
cp proxmox-backup.sh /usr/local/bin/proxmox-backup
chmod +x /usr/local/bin/proxmox-backup

# Create systemd service
cat > /etc/systemd/system/proxmox-backup.service << 'EOF'
[Unit]
Description=Proxmox Backup Service
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/proxmox-backup run
User=root

[Install]
WantedBy=multi-user.target
EOF

# Create systemd timer
cat > /etc/systemd/system/proxmox-backup.timer << 'EOF'
[Unit]
Description=Run Proxmox Backup Daily

[Timer]
OnCalendar=*-*-* 02:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

# Enable and start the timer
systemctl daemon-reload
systemctl enable proxmox-backup.timer
systemctl start proxmox-backup.timer

echo "Installation complete!"
echo "Please edit /etc/proxmox-backup.conf with your settings"
echo "The backup will run daily at 2:00 AM" 
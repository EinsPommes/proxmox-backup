# Proxmox Backup

A collection of backup scripts for Proxmox VE that create backups of running VMs and LXCs.

## Scripts

### 1. Simple Backup Script (Stable)
A lightweight script that creates backups and stores them locally.

#### Features
- Backup of running VMs and LXCs
- Automatic compression with zstd
- Automatic cleanup of old backups
- Detailed logging

#### Installation
1. Download the script:
```bash
wget https://raw.githubusercontent.com/EinsPommes/proxmox-backup/main/simple-backup.sh
```

2. Make the script executable:
```bash
chmod +x simple-backup.sh
```

3. Install the script:
```bash
sudo cp simple-backup.sh /usr/local/bin/proxmox-simple-backup
```

#### Usage
```bash
# Create backup
sudo proxmox-simple-backup run

# Clean old backups
sudo proxmox-simple-backup clean
```

### 2. Advanced Backup Script (Beta)
A comprehensive backup solution with additional features.

#### Features
- All features from the simple script
- Automatic verification through test restores
- NAS synchronization via rsync
- Telegram notifications
- Systemd timer for automated backups
- Lock file to prevent concurrent runs

#### Installation
1. Clone the repository:
```bash
git clone https://github.com/EinsPommes/proxmox-backup
cd proxmox-backup
```

2. Run the installation script:
```bash
sudo ./install.sh
```

3. Configure the backup:
```bash
sudo nano /etc/proxmox-backup.conf
```

#### Usage
```bash
# Create backup and sync to NAS
sudo proxmox-backup run

# Sync to NAS only
sudo proxmox-backup sync

# Clean old backups
sudo proxmox-backup clean
```

## Configuration

### Simple Script
Backups are stored in `/var/lib/vz/dump` by default. Old backups are automatically deleted after 7 days.

You can adjust these settings in the script:
- `BACKUP_DIR`: Directory for backups
- `RETENTION_DAYS`: Number of days to keep backups

### Advanced Script
The advanced script uses a configuration file at `/etc/proxmox-backup.conf` with the following options:
- `BACKUP_DIR`: Local backup directory
- `NAS_USER`: SSH user for NAS
- `NAS_HOST`: NAS IP address
- `NAS_PATH`: Remote backup path on NAS
- `TELEGRAM_TOKEN`: Your Telegram bot token
- `TELEGRAM_CHAT_ID`: Your Telegram chat ID
- `RESTORE_STORAGE`: Storage for test restores
- `RETENTION_DAYS`: Days to keep backups
- `VERIFY_TIMEOUT`: Seconds to wait for boot verification

## Logs

Logs are stored in `/var/log/proxmox-backup.log`.

## License

MIT License 
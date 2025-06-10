# Proxmox Backup System

A comprehensive backup solution for Proxmox VE that includes automatic verification, NAS synchronization, and Telegram notifications.

## Features

- Backs up running VMs and LXCs
- Automatic verification of backups through test restores
- Synchronization to Synology NAS via rsync
- Telegram notifications for success/failure
- Automatic cleanup of old backups
- Systemd timer for daily automated backups
- Lock file to prevent concurrent runs
- Detailed logging

## Requirements

- Proxmox VE
- SSH access to Synology NAS
- Telegram Bot Token and Chat ID
- Sufficient storage space for backups

## Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/EinsPommes/proxmox-backup
   cd proxmox-backup
   ```

2. Run the installation script as root:
   ```bash
   sudo ./install.sh
   ```

3. Edit the configuration file:
   ```bash
   sudo nano /etc/proxmox-backup.conf
   ```

   Configure the following settings:
   - `BACKUP_DIR`: Local backup directory
   - `NAS_USER`: SSH user for NAS
   - `NAS_HOST`: NAS IP address
   - `NAS_PATH`: Remote backup path on NAS
   - `TELEGRAM_TOKEN`: Your Telegram bot token
   - `TELEGRAM_CHAT_ID`: Your Telegram chat ID
   - `RESTORE_STORAGE`: Storage for test restores
   - `RETENTION_DAYS`: Days to keep backups
   - `VERIFY_TIMEOUT`: Seconds to wait for boot verification

## Usage

The backup system can be controlled in three ways:

1. Manual run:
   ```bash
   sudo proxmox-backup run
   ```

2. Manual sync to NAS:
   ```bash
   sudo proxmox-backup sync
   ```

3. Manual cleanup of old backups:
   ```bash
   sudo proxmox-backup clean
   ```

## Automated Schedule

By default, backups run daily at 2:00 AM. You can modify this by editing the systemd timer:

```bash
sudo systemctl edit proxmox-backup.timer
```

## Logs

Logs are written to `/var/log/proxmox-backup.log`. You can monitor the backup process with:

```bash
tail -f /var/log/proxmox-backup.log
```

## Security Considerations

1. The backup script runs as root to access Proxmox VE commands
2. SSH keys should be used for NAS authentication
3. Telegram bot token should be kept secure
4. Backup directory permissions should be restricted

## Troubleshooting

1. Check the log file for errors:
   ```bash
   cat /var/log/proxmox-backup.log
   ```

2. Verify systemd timer status:
   ```bash
   systemctl status proxmox-backup.timer
   ```

3. Check last backup run:
   ```bash
   systemctl status proxmox-backup.service
   ```

## License

MIT License - See LICENSE file for details 
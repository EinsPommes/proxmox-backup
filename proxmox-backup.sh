#!/bin/bash
set -euo pipefail

# Load configuration
if [ ! -f "/etc/proxmox-backup.conf" ]; then
    echo "Error: Configuration file /etc/proxmox-backup.conf not found"
    exit 1
fi
source /etc/proxmox-backup.conf

# Constants
readonly LOG="/var/log/proxmox-backup.log"
readonly LOCK_FILE="/var/run/proxmox-backup.lock"
readonly BACKUP_SOURCE="/var/lib/vz/dump"

# Ensure required directories exist
mkdir -p "$BACKUP_SOURCE"
touch "$LOG"

# Helper functions
log() {
    echo "$(date '+%F %T') - $1" | tee -a "$LOG"
}

send_telegram() {
    local message="$1"
    if ! curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
        -d "chat_id=${TELEGRAM_CHAT_ID}" \
        -d "text=${message}" \
        -d "parse_mode=HTML" > /dev/null; then
        log "Failed to send Telegram notification"
    fi
}

cleanup() {
    local exit_code=$?
    if [ -f "$LOCK_FILE" ]; then
        rm -f "$LOCK_FILE"
    fi
    exit $exit_code
}

trap cleanup EXIT INT TERM

# Verify backup function
verify_backup() {
    local id="$1"
    local type="$2"
    local dir="$3"
    local file
    local new_id="9${id}"
    local status

    file=$(find "$dir" -name "*.vma.zst" -o -name "*.tar.zst" | sort | tail -n1)
    if [ -z "$file" ]; then
        log "No backup found for ${type} ${id} - skipping verification"
        return 1
    fi

    log "Starting verification for ${type} ${id}"

    # Clean up any existing test instance
    if [ "$type" = "vm" ]; then
        qm stop "$new_id" >/dev/null 2>&1 || true
        qm destroy "$new_id" --purge >/dev/null 2>&1 || true
    else
        pct stop "$new_id" >/dev/null 2>&1 || true
        pct destroy "$new_id" >/dev/null 2>&1 || true
    fi

    # Restore backup
    if [ "$type" = "vm" ]; then
        if ! qmrestore "$file" "$new_id" --storage "$RESTORE_STORAGE" --unique >> "$LOG" 2>&1; then
            log "Failed to restore VM ${id}"
            return 1
        fi
        qm start "$new_id"
    else
        if ! pct restore "$new_id" "$file" --storage "$RESTORE_STORAGE" >> "$LOG" 2>&1; then
            log "Failed to restore LXC ${id}"
            return 1
        fi
        pct start "$new_id"
    fi

    # Wait for boot
    sleep "$VERIFY_TIMEOUT"

    # Check status
    if [ "$type" = "vm" ]; then
        status=$(qm status "$new_id" 2>/dev/null)
    else
        status=$(pct status "$new_id" 2>/dev/null)
    fi

    # Cleanup test instance
    if [ "$type" = "vm" ]; then
        qm stop "$new_id" >/dev/null 2>&1 || true
        qm destroy "$new_id" --purge >/dev/null 2>&1 || true
    else
        pct stop "$new_id" >/dev/null 2>&1 || true
        pct destroy "$new_id" >/dev/null 2>&1 || true
    fi

    if [[ "$status" == *"running"* ]]; then
        log "Verification successful for ${type} ${id}"
        return 0
    else
        log "Verification failed for ${type} ${id}"
        send_telegram "⚠️ Verification FAILED: ${type} ${id}"
        return 1
    fi
}

# Run backups
run_backups() {#!/bin/bash
set -euo pipefail

# Load configuration
if [ ! -f "/etc/proxmox-backup.conf" ]; then
    echo "Error: Configuration file /etc/proxmox-backup.conf not found"
    exit 1
fi
source /etc/proxmox-backup.conf

# Constants
readonly LOG="/var/log/proxmox-backup.log"
readonly LOCK_FILE="/var/run/proxmox-backup.lock"
readonly BACKUP_SOURCE="/var/lib/vz/dump"

# Ensure required directories exist
mkdir -p "$BACKUP_SOURCE"
touch "$LOG"

# Helper functions
log() {
    echo "$(date '+%F %T') - $1" | tee -a "$LOG"
}

send_telegram() {
    local message="$1"
    if ! curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
        -d "chat_id=${TELEGRAM_CHAT_ID}" \
        -d "text=${message}" \
        -d "parse_mode=HTML" > /dev/null; then
        log "Failed to send Telegram notification"
    fi
}

cleanup() {
    local exit_code=$?
    if [ -f "$LOCK_FILE" ]; then
        rm -f "$LOCK_FILE"
    fi
    exit $exit_code
}

trap cleanup EXIT INT TERM

# Verify backup function
verify_backup() {
    local id="$1"
    local type="$2"
    local dir="$3"
    local file
    local new_id="9${id}"
    local status

    file=$(find "$dir" -name "*.vma.zst" -o -name "*.tar.zst" | sort | tail -n1)
    if [ -z "$file" ]; then
        log "No backup found for ${type} ${id} - skipping verification"
        return 1
    fi

    log "Starting verification for ${type} ${id}"

    # Clean up any existing test instance
    if [ "$type" = "vm" ]; then
        qm stop "$new_id" >/dev/null 2>&1 || true
        qm destroy "$new_id" --purge >/dev/null 2>&1 || true
    else
        pct stop "$new_id" >/dev/null 2>&1 || true
        pct destroy "$new_id" >/dev/null 2>&1 || true
    fi

    # Restore backup
    if [ "$type" = "vm" ]; then
        if ! qmrestore "$file" "$new_id" --storage "$RESTORE_STORAGE" --unique >> "$LOG" 2>&1; then
            log "Failed to restore VM ${id}"
            return 1
        fi
        qm start "$new_id"
    else
        if ! pct restore "$new_id" "$file" --storage "$RESTORE_STORAGE" >> "$LOG" 2>&1; then
            log "Failed to restore LXC ${id}"
            return 1
        fi
        pct start "$new_id"
    fi

    # Wait for boot
    sleep "$VERIFY_TIMEOUT"

    # Check status
    if [ "$type" = "vm" ]; then
        status=$(qm status "$new_id" 2>/dev/null)
    else
        status=$(pct status "$new_id" 2>/dev/null)
    fi

    # Cleanup test instance
    if [ "$type" = "vm" ]; then
        qm stop "$new_id" >/dev/null 2>&1 || true
        qm destroy "$new_id" --purge >/dev/null 2>&1 || true
    else
        pct stop "$new_id" >/dev/null 2>&1 || true
        pct destroy "$new_id" >/dev/null 2>&1 || true
    fi

    if [[ "$status" == *"running"* ]]; then
        log "Verification successful for ${type} ${id}"
        return 0
    else
        log "Verification failed for ${type} ${id}"
        send_telegram "⚠️ Verification FAILED: ${type} ${id}"
        return 1
    fi
}

# Run backups
run_backups() {
    if [ -f "$LOCK_FILE" ]; then
        log "Backup already running"
        exit 1
    fi
    touch "$LOCK_FILE"

    log "Starting backup process..."
    local ids=()
    local failed_backups=0

    # Get running VMs and LXCs
    while IFS= read -r id; do
        ids+=("${id}:vm")
    done < <(qm list | awk '$2 == "running" {print $1}')

    while IFS= read -r id; do
        ids+=("${id}:lxc")
    done < <(pct list | awk '$3 == "running" {print $1}')

    if [ ${#ids[@]} -eq 0 ]; then
        log "No running VMs or LXCs found to backup"
        send_telegram "⚠️ No running VMs or LXCs found to backup"
        rm -f "$LOCK_FILE"
        exit 0
    fi

    for entry in "${ids[@]}"; do
        id="${entry%%:*}"
        type="${entry##*:}"
        outdir="${BACKUP_SOURCE}/${type}-${id}"
        mkdir -p "$outdir"

        log "Starting backup of ${type} ${id}"
        if ! vzdump "$id" --mode snapshot --compress zstd --dumpdir "$outdir" --quiet 1 >> "$LOG" 2>&1; then
            log "Backup failed for ${type} ${id}"
            send_telegram "❌ Backup failed for ${type} ${id}"
            ((failed_backups++))
            continue
        fi

        log "Backup completed for ${type} ${id}"
        if ! verify_backup "$id" "$type" "$outdir"; then
            ((failed_backups++))
        fi
    done

    if [ $failed_backups -eq 0 ]; then
        log "All backups completed successfully, starting NAS sync"
        sync_to_nas
        # Keep local backups, only clean up old ones
        delete_old_backups
        send_telegram "✅ Proxmox backup, verification & sync completed successfully at $(date)"
    else
        log "Backup completed with ${failed_backups} failures"
        send_telegram "⚠️ Proxmox backup completed with ${failed_backups} failures at $(date)"
    fi
}

# Sync to NAS
sync_to_nas() {
    log "Starting NAS sync..."
    log "Syncing from: $BACKUP_SOURCE/"
    log "Syncing to: ${NAS_USER}@${NAS_HOST}:~/Proxmox Pve2/"
    
    # Test SSH connection
    log "Testing SSH connection..."
    if ! ssh -i /root/.ssh/proxmox_backup_key "${NAS_USER}@${NAS_HOST}" "pwd" >> "$LOG" 2>&1; then
        log "Error: Could not establish SSH connection to NAS"
        send_telegram "❌ Could not establish SSH connection to NAS"
        return 1
    fi

    # List contents of backup directory
    log "Contents of backup directory:"
    ls -la "$BACKUP_SOURCE" >> "$LOG" 2>&1

    # Use rsync to sync backups
    log "Starting rsync..."
    if ! rsync -avz -e "ssh -i /root/.ssh/proxmox_backup_key" \
        "$BACKUP_SOURCE/" \
        "${NAS_USER}@${NAS_HOST}:~/Proxmox\ Pve2/" >> "$LOG" 2>&1; then
        log "NAS sync failed"
        send_telegram "❌ NAS sync failed"
        return 1
    fi
    log "NAS sync completed successfully"
}

# Delete old backups
delete_old_backups() {
    log "Deleting backups older than ${RETENTION_DAYS} days..."
    # Only delete files older than retention period
    find "$BACKUP_DIR" -type f -mtime +"$RETENTION_DAYS" -delete
    # Remove empty directories
    find "$BACKUP_DIR" -type d -empty -delete
    log "Old backups deleted"
}

# Main
case "${1:-}" in
    run)
        run_backups
        ;;
    sync)
        sync_to_nas
        ;;
    clean)
        delete_old_backups
        ;;
    *)
        echo "Usage: $0 {run|sync|clean}"
        exit 1
        ;;
esac 

    log "Starting backup process..."
    local ids=()
    local failed_backups=0

    # Get running VMs and LXCs
    while IFS= read -r id; do
        ids+=("${id}:vm")
    done < <(qm list | awk '$2 == "running" {print $1}')

    while IFS= read -r id; do
        ids+=("${id}:lxc")
    done < <(pct list | awk '$3 == "running" {print $1}')

    if [ ${#ids[@]} -eq 0 ]; then
        log "No running VMs or LXCs found to backup"
        send_telegram "⚠️ No running VMs or LXCs found to backup"
        rm -f "$LOCK_FILE"
        exit 0
    fi

    for entry in "${ids[@]}"; do
        id="${entry%%:*}"
        type="${entry##*:}"
        outdir="${BACKUP_SOURCE}/${type}-${id}"
        mkdir -p "$outdir"

        log "Starting backup of ${type} ${id}"
        if ! vzdump "$id" --mode snapshot --compress zstd --dumpdir "$outdir" --quiet 1 >> "$LOG" 2>&1; then
            log "Backup failed for ${type} ${id}"
            send_telegram "❌ Backup failed for ${type} ${id}"
            ((failed_backups++))
            continue
        fi

        log "Backup completed for ${type} ${id}"
        if ! verify_backup "$id" "$type" "$outdir"; then
            ((failed_backups++))
        fi
    done

    if [ $failed_backups -eq 0 ]; then
        log "All backups completed successfully, starting NAS sync"
        sync_to_nas
        # Keep local backups, only clean up old ones
        delete_old_backups
        send_telegram "✅ Proxmox backup, verification & sync completed successfully at $(date)"
    else
        log "Backup completed with ${failed_backups} failures"
        send_telegram "⚠️ Proxmox backup completed with ${failed_backups} failures at $(date)"
    fi
}

# Sync to NAS
sync_to_nas() {
    log "Starting NAS sync..."
    log "Syncing from: $BACKUP_SOURCE/"
    log "Syncing to: ${NAS_USER}@${NAS_HOST}:~/Proxmox Pve2/"
    
    # Test SSH connection
    log "Testing SSH connection..."
    if ! ssh -i /root/.ssh/proxmox_backup_key "${NAS_USER}@${NAS_HOST}" "pwd" >> "$LOG" 2>&1; then
        log "Error: Could not establish SSH connection to NAS"
        send_telegram "❌ Could not establish SSH connection to NAS"
        return 1
    fi

    # List contents of backup directory
    log "Contents of backup directory:"
    ls -la "$BACKUP_SOURCE" >> "$LOG" 2>&1

    # Use rsync to sync backups
    log "Starting rsync..."
    if ! rsync -avz -e "ssh -i /root/.ssh/proxmox_backup_key" \
        "$BACKUP_SOURCE/" \
        "${NAS_USER}@${NAS_HOST}:~/Proxmox\ Pve2/" >> "$LOG" 2>&1; then
        log "NAS sync failed"
        send_telegram "❌ NAS sync failed"
        return 1
    fi
    log "NAS sync completed successfully"
}

# Delete old backups
delete_old_backups() {
    log "Deleting backups older than ${RETENTION_DAYS} days..."
    # Only delete files older than retention period
    find "$BACKUP_SOURCE" -type f -mtime +"$RETENTION_DAYS" -delete
    # Remove empty directories
    find "$BACKUP_SOURCE" -type d -empty -delete
    log "Old backups deleted"
}

# Main
case "${1:-}" in
    run)
        run_backups
        ;;
    sync)
        sync_to_nas
        ;;
    clean)
        delete_old_backups
        ;;
    *)
        echo "Usage: $0 {run|sync|clean}"
        exit 1
        ;;
esac 
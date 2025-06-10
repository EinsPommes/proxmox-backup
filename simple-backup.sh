#!/bin/bash
set -euo pipefail

# Constants
readonly LOG="/var/log/proxmox-backup.log"
readonly BACKUP_DIR="/var/lib/vz/dump"
readonly RETENTION_DAYS=7

# Ensure required directories exist
mkdir -p "$BACKUP_DIR"
touch "$LOG"

# Helper functions
log() {
    echo "$(date '+%F %T') - $1" | tee -a "$LOG"
}

# Delete old backups
delete_old_backups() {
    log "Deleting backups older than ${RETENTION_DAYS} days..."
    find "$BACKUP_DIR" -type f -mtime +"$RETENTION_DAYS" -delete
    find "$BACKUP_DIR" -type d -empty -delete
    log "Old backups deleted"
}

# Main backup function
run_backup() {
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
        exit 0
    fi

    for entry in "${ids[@]}"; do
        id="${entry%%:*}"
        type="${entry##*:}"
        outdir="${BACKUP_DIR}/${type}-${id}"
        mkdir -p "$outdir"

        log "Starting backup of ${type} ${id}"
        if ! vzdump "$id" --mode snapshot --compress zstd --dumpdir "$outdir" --quiet 1 >> "$LOG" 2>&1; then
            log "Backup failed for ${type} ${id}"
            ((failed_backups++))
            continue
        fi
        log "Backup completed for ${type} ${id}"
    done

    if [ $failed_backups -eq 0 ]; then
        log "All backups completed successfully"
        delete_old_backups
    else
        log "Backup completed with ${failed_backups} failures"
    fi
}

# Main
case "${1:-}" in
    run)
        run_backup
        ;;
    clean)
        delete_old_backups
        ;;
    *)
        echo "Usage: $0 {run|clean}"
        exit 1
        ;;
esac 
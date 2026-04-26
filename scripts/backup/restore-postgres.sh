#!/usr/bin/env bash
set -Eeuo pipefail

BACKUP_DIR="${MAJARITE_BACKUP_DIR:-./backups/local/postgres}"

usage() {
  echo "Usage:"
  echo "  bash scripts/backup/restore-postgres.sh list"
  echo "  bash scripts/backup/restore-postgres.sh verify <backup.sql.gz>"
  echo "  bash scripts/backup/restore-postgres.sh plan <majorite|zammad> <backup.sql.gz>"
}

list_backups() {
  echo "Available PostgreSQL backups:"
  if ls "${BACKUP_DIR}"/*.sql.gz >/dev/null 2>&1; then
    ls -lh "${BACKUP_DIR}"/*.sql.gz
  else
    echo "No backups found in ${BACKUP_DIR}"
  fi
}

verify_backup() {
  local file="$1"

  if [ ! -f "$file" ]; then
    echo "ERROR: backup file not found: $file"
    exit 1
  fi

  gzip -t "$file"
  gunzip -c "$file" | head -40 >/tmp/majarite-restore-preview.sql

  if grep -q "PostgreSQL database dump" /tmp/majarite-restore-preview.sql; then
    echo "OK: valid PostgreSQL plain SQL dump: $file"
  else
    echo "ERROR: file does not look like PostgreSQL plain SQL dump: $file"
    exit 1
  fi
}

plan_restore() {
  local target="$1"
  local file="$2"

  verify_backup "$file"

  case "$target" in
    majorite)
      container="majarite-postgres-majorite"
      ;;
    zammad)
      container="majarite-postgres-zammad"
      ;;
    *)
      echo "ERROR: target must be majorite or zammad"
      exit 1
      ;;
  esac

  echo
  echo "Restore plan:"
  echo "Target: ${target}"
  echo "Container: ${container}"
  echo "Backup: ${file}"
  echo
  echo "This script is safe by default and does not restore automatically."
  echo "Manual restore command will be added only after restore runbook is reviewed."
}

if [ "$#" -lt 1 ]; then
  usage
  exit 1
fi

case "$1" in
  list)
    list_backups
    ;;
  verify)
    if [ "$#" -ne 2 ]; then usage; exit 1; fi
    verify_backup "$2"
    ;;
  plan)
    if [ "$#" -ne 3 ]; then usage; exit 1; fi
    plan_restore "$2" "$3"
    ;;
  *)
    usage
    exit 1
    ;;
esac

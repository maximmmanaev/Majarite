#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_NAME="${MAJARITE_PROJECT_NAME:-majarite}"
BACKUP_DIR="${MAJARITE_BACKUP_DIR:-./backups/local/postgres}"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

mkdir -p "${BACKUP_DIR}"

backup_db() {
  local container="$1"
  local label="$2"
  local output="${BACKUP_DIR}/${label}-${TIMESTAMP}.sql.gz"

  echo "Backing up ${label} from ${container}"
  docker exec "${container}" sh -lc 'pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB"' | gzip > "${output}"

  if [ ! -s "${output}" ]; then
    echo "ERROR: backup file is empty: ${output}"
    exit 1
  fi

  echo "OK: ${output}"
}

backup_db "${PROJECT_NAME}-postgres-majorite" "majorite"
backup_db "${PROJECT_NAME}-postgres-zammad" "zammad"

echo "PostgreSQL backup completed"

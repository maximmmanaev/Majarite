#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="${MAJARITE_ROOT_DIR:-$(pwd)}"
DATA_DIR="${MAJARITE_DATA_DIR:-${ROOT_DIR}/data}"
LOG_DIR="${MAJARITE_LOG_DIR:-${ROOT_DIR}/logs}"

echo "Creating Majarite runtime directories"
echo "ROOT_DIR=${ROOT_DIR}"
echo "DATA_DIR=${DATA_DIR}"
echo "LOG_DIR=${LOG_DIR}"

mkdir -p \
  "${DATA_DIR}/postgres-majorite" \
  "${DATA_DIR}/postgres-zammad" \
  "${DATA_DIR}/zammad-storage" \
  "${DATA_DIR}/zammad-redis" \
  "${DATA_DIR}/zammad-memcached" \
  "${DATA_DIR}/valkey" \
  "${DATA_DIR}/node-red" \
  "${DATA_DIR}/nginx/cache" \
  "${LOG_DIR}/nginx" \
  "${LOG_DIR}/node-red" \
  "${LOG_DIR}/zammad" \
  "${LOG_DIR}/postgres" \
  "${LOG_DIR}/valkey"

echo "Directory layout created successfully"

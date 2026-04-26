#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  echo "Usage:"
  echo "  bash scripts/deploy/rollback.sh plan --to <git-ref>"
  echo
  echo "Example:"
  echo "  bash scripts/deploy/rollback.sh plan --to HEAD"
}

if [ "$#" -ne 3 ]; then
  usage
  exit 1
fi

ACTION="$1"
FLAG="$2"
TARGET_REF="$3"

if [ "$ACTION" != "plan" ]; then
  echo "ERROR: only safe action is supported in Sprint 2: plan"
  exit 1
fi

if [ "$FLAG" != "--to" ]; then
  usage
  exit 1
fi

if ! git rev-parse --verify "$TARGET_REF" >/dev/null 2>&1; then
  echo "ERROR: git ref not found: $TARGET_REF"
  exit 1
fi

CURRENT_REF="$(git rev-parse --short HEAD)"
TARGET_SHA="$(git rev-parse --short "$TARGET_REF")"

echo "Rollback plan"
echo "Current ref: ${CURRENT_REF}"
echo "Target ref: ${TARGET_REF}"
echo "Target sha: ${TARGET_SHA}"
echo
echo "Sprint 2 rollback is safe-plan only."
echo "It does not stop containers."
echo "It does not restore database."
echo "It does not checkout target ref."
echo
echo "Manual rollback procedure will be added after backup and restore runbooks are reviewed."

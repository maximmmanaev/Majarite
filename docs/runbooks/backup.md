# Runbook — Backup

## Purpose

Backup сохраняет PostgreSQL базы Majarite и Zammad.

## Command

bash scripts/backup/backup-postgres.sh

## Output

Backups сохраняются в:

backups/local/postgres

## Files

- majorite-YYYYMMDD-HHMMSS.sql.gz
- zammad-YYYYMMDD-HHMMSS.sql.gz

## Verify

Проверить список backups:

bash scripts/backup/restore-postgres.sh list

Проверить конкретный backup:

bash scripts/backup/restore-postgres.sh verify backups/local/postgres/majorite-YYYYMMDD-HHMMSS.sql.gz

## Rules

- backups не коммитить в Git
- пустой backup считать ошибкой
- backup выполнять перед deploy

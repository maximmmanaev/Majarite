# Runbook — Restore

## Purpose

Restore описывает безопасную проверку PostgreSQL backups.

## Sprint 2 mode

В Sprint 2 restore работает только в safe mode.

Автоматическое восстановление базы запрещено.

## Commands

Показать backups:

bash scripts/backup/restore-postgres.sh list

Проверить backup:

bash scripts/backup/restore-postgres.sh verify backups/local/postgres/majorite-YYYYMMDD-HHMMSS.sql.gz

Показать restore plan:

bash scripts/backup/restore-postgres.sh plan majorite backups/local/postgres/majorite-YYYYMMDD-HHMMSS.sql.gz

## Rules

- destructive restore не выполнять без отдельного review
- сначала verify
- затем plan
- только потом отдельная ручная процедура восстановления

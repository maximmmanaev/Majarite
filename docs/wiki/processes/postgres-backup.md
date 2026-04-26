# Process — PostgreSQL Backup

## Назначение

Скрипт создает gzip-архивы PostgreSQL баз:

- Majorite event store
- Zammad database

## Команда

bash scripts/backup/backup-postgres.sh

## Куда сохраняется backup

По умолчанию:

backups/local/postgres

## Что создается

- majorite-YYYYMMDD-HHMMSS.sql.gz
- zammad-YYYYMMDD-HHMMSS.sql.gz

## Правила

- backups/ не коммитится в Git.
- backup должен выполняться перед deploy.
- пустой backup считается ошибкой.
- restore делается отдельным скриптом.

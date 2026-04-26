# Process — PostgreSQL Restore

## Назначение

restore-postgres.sh в Sprint 2 работает в безопасном режиме.

Он не перетирает базу автоматически.

## Команды

Показать backups:

bash scripts/backup/restore-postgres.sh list

Проверить backup:

bash scripts/backup/restore-postgres.sh verify backups/local/postgres/majorite-YYYYMMDD-HHMMSS.sql.gz

Показать restore plan:

bash scripts/backup/restore-postgres.sh plan majorite backups/local/postgres/majorite-YYYYMMDD-HHMMSS.sql.gz

или:

bash scripts/backup/restore-postgres.sh plan zammad backups/local/postgres/zammad-YYYYMMDD-HHMMSS.sql.gz

## Правила

- Автоматический destructive restore запрещен в Sprint 2.
- Сначала проверяется gzip.
- Потом проверяется, что файл похож на PostgreSQL dump.
- Реальный restore будет добавлен только после отдельного runbook review.

# Process — Makefile Core Runtime

## Назначение

Makefile скрывает длинные Docker Compose команды и задает единый способ управления Sprint 1 Core Runtime.

## Основные команды

### make prod-config

Проверяет итоговую Docker Compose конфигурацию.

### make prod-up-core

Создает runtime-директории и запускает core stack.

### make prod-down

Останавливает core stack.

### make prod-logs

Показывает логи core stack.

### make prod-health

Показывает состояние контейнеров и проверяет NGINX health endpoint.

## Важное правило

По умолчанию локальный запуск использует:

- env/dev/.env.example
- data/
- logs/

Для production нужно передавать другой ENV_FILE и абсолютные DATA_DIR/LOG_DIR.

Пример:

make prod-up-core ENV_FILE=/opt/majorite/env/prod/.env DATA_DIR=/opt/majorite/data LOG_DIR=/opt/majorite/logs

## Связанные файлы

- Makefile
- env/dev/.env.example
- env/prod/.env.example
- infra/compose/compose.base.yml
- infra/compose/compose.core.yml
- infra/compose/compose.prod.yml
- scripts/bootstrap/create-directories.sh

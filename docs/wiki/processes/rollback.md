# Process — Rollback

## Назначение

Rollback script в Sprint 2 работает только в safe-plan режиме.

Он не меняет файлы, контейнеры или базу.

## Команда

bash scripts/deploy/rollback.sh plan --to HEAD

## Что проверяется

- аргументы команды
- существование git ref
- текущий commit
- целевой commit

## Что запрещено в Sprint 2

- автоматический database restore
- автоматический checkout
- автоматическая остановка контейнеров
- destructive rollback

## Правило

Перед реальным rollback всегда должен быть backup.

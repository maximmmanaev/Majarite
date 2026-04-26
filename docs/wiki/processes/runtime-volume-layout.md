# Process — Runtime Volume Layout

## Назначение

Этот документ описывает runtime-директории Majarite Core Runtime.

## Основной принцип

Данные сервисов не должны жить внутри контейнеров. Контейнер можно удалить и пересоздать, данные должны сохраниться в volume directories.

## Runtime paths

По умолчанию локально:

- data/postgres-majorite
- data/postgres-zammad
- data/zammad-storage
- data/zammad-redis
- data/zammad-memcached
- data/valkey
- data/node-red
- data/nginx/cache
- logs/nginx
- logs/node-red
- logs/zammad
- logs/postgres
- logs/valkey

На production-сервере ожидаемый путь:

- /opt/majorite/data
- /opt/majorite/logs

## Правила

- data/ не коммитится в Git.
- logs/ не коммитится в Git.
- PostgreSQL и Valkey не публикуются наружу.
- Node-RED credentials не коммитятся в Git.
- Backup scripts должны работать поверх этих директорий.

## Связанные файлы

- scripts/bootstrap/create-directories.sh
- env/dev/.env.example
- env/prod/.env.example
- infra/compose/compose.base.yml
- infra/compose/compose.core.yml

# Process — Core Runtime Smoke Test

## Назначение

Smoke test проверяет, что Sprint 1 Core Runtime действительно живой после запуска.

## Команда

make smoke-test

## Что проверяется

- Docker containers существуют и запущены.
- NGINX `/health` возвращает `majarite-nginx-ok`.
- Zammad доступен через внешний NGINX.
- Node-RED доступен через внешний NGINX.
- Majorite PostgreSQL отвечает.
- Zammad PostgreSQL отвечает.
- Valkey отвечает `PONG`.
- Таблица `majorite_events` существует.
- PostgreSQL и Valkey не опубликованы наружу.

## Правило

После каждого изменения Compose, NGINX или bootstrap scripts нужно запускать:

make prod-config
make smoke-test

## Связанные файлы

- scripts/deploy/smoke-test.sh
- Makefile
- infra/compose/compose.base.yml
- infra/compose/compose.core.yml
- infra/nginx/conf.d/default.conf

# Process — Docker Compose Base

## Назначение

compose.base.yml задает общие Docker Compose primitives для Sprint 1 Core Runtime.

## Networks

### edge_net

Публичный edge-слой.

Используется для:

- NGINX
- публичных HTTP entrypoints

### core_net

Внутренний runtime-слой.

Используется для:

- Zammad runtime
- Node-RED
- Valkey
- internal service traffic

Сеть internal=true, чтобы сервисы не были доступны напрямую извне.

### data_net

Внутренний data-слой.

Используется для:

- PostgreSQL
- сервисов, которым нужен доступ к базе

Сеть internal=true.

## Logging

Все контейнеры должны использовать json-file logging с ограничением размера:

- max-size: 10m
- max-file: 5

## Restart policy

Для runtime-сервисов используется:

- unless-stopped

## Правила

- PostgreSQL не подключается к edge_net.
- Valkey не подключается к edge_net.
- Наружу публикуются только NGINX-порты.
- Новые сервисы должны явно подключаться только к нужным сетям.

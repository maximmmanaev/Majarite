# Process — Docker Compose Core

## Назначение

compose.core.yml описывает Sprint 1 Core Runtime.

## Core services

- nginx
- majorite-postgres
- valkey
- node-red
- zammad-postgres
- zammad-redis
- zammad-memcached
- zammad-railsserver
- zammad-scheduler
- zammad-websocket
- zammad-nginx

## Source of truth

- Zammad отвечает за тикеты.
- majorite-postgres отвечает за business events.
- Node-RED отвечает за orchestration.
- Valkey отвечает только за временные session state, dedupe и retries.

## Network rules

- PostgreSQL не публикуется наружу.
- Valkey не публикуется наружу.
- Zammad runtime сидит во внутренней сети.
- Наружу выходит только внешний nginx.

## Связанные файлы

- infra/compose/compose.base.yml
- infra/compose/compose.core.yml
- infra/postgres/init/001_majorite_event_store.sql
- env/dev/.env.example
- env/prod/.env.example

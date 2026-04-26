# Sprint 1 — Core Runtime Boot

## Цель

Поднять минимальное runtime-ядро Majarite на Docker Compose:

- NGINX
- Zammad
- PostgreSQL
- Valkey
- Node-RED

Sprint 1 не добавляет email, Telegram, MAX, AI, KB, аналитику или телефонию.

## Архитектурная опора

Смотреть файлы:

- docs/architecture/majorite-system-architecture.md
- docs/product/mvp-scope.md
- docs/product/roadmap.md
- docs/runbooks/deploy-production.md

## Scope

### Входит

- infra/compose/compose.base.yml
- infra/compose/compose.core.yml
- infra/compose/compose.prod.yml
- env/dev/.env.example
- env/prod/.env.example
- volume layout
- Docker networks
- healthchecks
- bootstrap scripts
- Makefile targets for core runtime

### Не входит

- Email intake
- Telegram intake
- MAX adapter
- AI extraction
- Knowledge base
- OpenSearch
- Superset
- Telephony
- Bug flow
- Weighted assignment

## Definition of Done

- docker compose config проходит без ошибок.
- make prod-up-core поднимает core stack.
- Zammad открывается.
- Node-RED открывается.
- PostgreSQL не опубликован наружу.
- Valkey не опубликован наружу.
- Есть базовые healthchecks.
- Есть документация процесса запуска.
- Реальные секреты не попадают в Git.

## Рабочий порядок

1. Добавить env examples.
2. Добавить compose base.
3. Добавить compose core.
4. Добавить compose prod override.
5. Добавить bootstrap scripts.
6. Добавить Makefile targets.
7. Проверить docker compose config.
8. Поднять stack.
9. Проверить health.
10. Обновить документацию.

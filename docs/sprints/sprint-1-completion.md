# Sprint 1 Completion — Core Runtime Boot

Status: completed and merged into develop.

PR: #2 — Sprint 1: Core Runtime Boot

Result:
- Core runtime поднят через Docker Compose.
- NGINX работает.
- Zammad доступен через внешний NGINX.
- Node-RED доступен через внешний NGINX.
- Majorite PostgreSQL работает.
- Zammad PostgreSQL работает.
- Valkey работает.
- Таблица majorite_events создана.
- PostgreSQL и Valkey не опубликованы наружу.

Verified commands:
- make prod-config
- make prod-up-core
- make smoke-test

Important rule:
Core runtime запускать только через Makefile.

Correct:
- make prod-up-core
- make prod-down
- make prod-health
- make smoke-test

Wrong:
- raw docker compose up

Reason:
raw docker compose может создать runtime data в infra/compose/data.

Correct runtime paths:
- data/
- logs/

Next sprint:
Sprint 2 — Event Store + Deploy Safety.

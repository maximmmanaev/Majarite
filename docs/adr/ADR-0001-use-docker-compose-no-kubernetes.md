# ADR-0001: Use Docker Compose, not Kubernetes, for MVP

## Status

Accepted

## Context

Majarite MVP is built by one person and must be deployable quickly on a single Ubuntu server.

The first release needs a simple and reproducible deployment model for:

- NGINX
- Zammad
- PostgreSQL
- Valkey
- Node-RED
- backup jobs
- smoke tests

Kubernetes would add operational complexity before the product proves value.

## Decision

Use Docker Compose as the primary deployment runtime for MVP and early production-capable releases.

Do not introduce Kubernetes until Docker Compose becomes a real operational bottleneck.

## Consequences

Positive:

- Faster first deployment
- Lower operational complexity
- Easier local development in WSL
- Easier debugging for a solo developer
- Simpler backup and restore flow

Negative:

- No built-in cluster orchestration
- No automatic horizontal scaling
- Manual discipline is required for deploy, rollback and monitoring

## Rules

- Compose files must live in `infra/compose`.
- Images must use pinned versions, not `latest`.
- Runtime secrets must not be committed.
- `docker compose config` must pass before deployment.
- Core services must survive AI/search/analytics failures.

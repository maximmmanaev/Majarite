# ADR-0002: Use GitHub monorepo

## Status

Accepted

## Context

Majarite needs one source of truth for:

- infrastructure
- Docker Compose files
- Node-RED flows
- service adapters
- scripts
- tests
- product docs
- architecture docs
- ADR
- runbooks
- release notes

The project is developed by one person with AI coding agents, so repository fragmentation would create unnecessary coordination overhead.

## Decision

Use one GitHub repository named `Majarite`.

## Consequences

Positive:

- One place for code, infra and docs
- Simpler agent context
- Easier release management
- Easier rollback by Git tag
- Easier GitHub Projects management

Negative:

- Repository can grow large over time
- Requires strict folder structure
- Requires discipline in commits and pull requests

## Rules

- `main` is the stable branch.
- `develop` is the integration branch.
- Feature work must happen in `feature/*` branches.
- Infrastructure, docs and app code must be versioned together.
- No real secrets may be committed.

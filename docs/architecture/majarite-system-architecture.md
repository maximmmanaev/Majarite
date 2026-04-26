# Majarite System Architecture

## Architecture Summary

Majarite MVP is a self-hosted text-first helpdesk platform.

The first release runs on one Ubuntu server with Docker Compose.

## Core Runtime

MVP core services:

- NGINX as edge reverse proxy
- Zammad as ticket source of truth
- PostgreSQL as business event store
- Valkey for temporary session state
- Node-RED as orchestration layer

## First Release Channels

- Email
- Telegram
- MAX later as isolated adapter

## Source of Truth

| Area | Source of Truth |
|---|---|
| Tickets | Zammad |
| Business events | PostgreSQL |
| Temporary sessions | Valkey |
| Automation flows | Git + Node-RED |
| Runtime config examples | Git |
| Real secrets | Server-local secrets, never Git |

## Out of First Release

- Telephony
- Asterisk
- FreePBX
- Mango Office
- faster-whisper
- BookStack
- OpenSearch
- Superset
- Full AI runtime
- Multi-server HA

## Deployment Rule

MVP must be deployable by one person from GitHub repo using:

- Docker Compose
- `.env.example`
- runbooks
- backup scripts
- smoke tests
- rollback scripts

# Majarite MVP Scope

## MVP Goal

Build a self-hosted text-first helpdesk hub that turns incoming support requests into structured tickets or drafts.

## MVP Core

Majarite MVP focuses on:

- Email intake
- Telegram intake
- MAX adapter later as isolated module
- Zammad as ticket source of truth
- Node-RED as orchestration layer
- PostgreSQL as business event store
- Valkey for temporary session state, dedupe and retries
- Draft/Open ticket lifecycle
- General Support queue
- Manual assignment
- Rule-based clarification with optional AI assist later
- Telegram notifications
- Docker Compose deployment

## In Scope

- GitHub monorepo
- Docker Compose core stack
- NGINX
- Zammad
- PostgreSQL
- Valkey
- Node-RED
- Basic backup scripts
- Basic restore runbook
- Basic rollback runbook
- Smoke tests
- Environment examples
- ADR documents

## Out of Scope for First Release

- Telephony
- Mango Office
- Asterisk
- FreePBX
- faster-whisper
- BookStack
- OpenSearch
- Superset
- Full Prometheus/Grafana stack
- Weighted assignment
- Complexity scoring
- Full bug workflow
- Autonomous AI answers
- Customer portal
- Multi-server HA

## Mandatory Fields Before Open

A ticket can become Open only when it has:

- Full name of the affected user
- Email or contact channel
- Contour / database
- Short problem description

If mandatory data is missing, the case must stay in Intake Pending or Draft.

## Main MVP Flow

1. User sends a request via email or Telegram.
2. System captures inbound event.
3. System creates or updates a Zammad ticket.
4. System checks mandatory fields.
5. If data is missing, clarification starts.
6. If data is still missing after the limit, ticket stays as Draft.
7. If data is complete, ticket becomes Open.
8. Ticket goes to General Support queue.
9. Telegram notification is sent.
10. Business event is written to PostgreSQL.

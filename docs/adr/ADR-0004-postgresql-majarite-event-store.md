# ADR-0004: PostgreSQL is Majarite business event store

## Status

Accepted

## Context

Majarite needs a reliable place for business events, correlation data, audit trail and future analytics.

Zammad owns tickets, but Majarite also needs to store:

- inbound channel events
- clarification events
- assignment decisions
- notification attempts
- integration errors
- export jobs
- correlation IDs
- operational metrics

Node-RED and Valkey are not suitable as long-term sources of truth.

## Decision

Use PostgreSQL as Majarite business event store.

## Consequences

Positive:

- Reliable relational storage
- Simple backup and restore
- Strong SQL analytics foundation
- Easy event correlation
- Works well in Docker Compose MVP

Negative:

- Requires schema discipline
- Requires migration management
- Requires consistency checks between Zammad and event store

## Rules

- PostgreSQL stores business events and correlation data.
- Zammad remains the ticket source of truth.
- Valkey stores only temporary state.
- Every important automation action must write an event.
- Events must include `event_type`, `entity_type`, `entity_id`, `correlation_id`, `actor_type`, `channel`, `payload_json`, `created_at`.

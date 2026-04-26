# ADR-0006: Valkey is for temporary state only

## Status

Accepted

## Context

Majarite needs fast temporary storage for:

- Telegram session state
- clarification progress
- webhook deduplication
- retry counters
- short-lived locks
- idempotency keys

This data must be fast to access but must not become the long-term source of truth.

## Decision

Use Valkey only for temporary runtime state.

## Consequences

Positive:

- Fast session access
- Simple dedupe and retry logic
- Low operational overhead
- Good fit for Docker Compose MVP

Negative:

- Data may be lost if not persisted correctly
- Not suitable for permanent analytics or audit trail
- Requires TTL discipline

## Rules

- Valkey must not store permanent ticket state.
- Valkey must not store permanent contact profiles.
- Valkey must not store analytics events.
- Long-term events must be written to PostgreSQL.
- Session and dedupe keys must have TTL.

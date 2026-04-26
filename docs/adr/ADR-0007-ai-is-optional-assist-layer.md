# ADR-0007: AI is optional assist layer

## Status

Accepted

## Context

Majarite may use AI later for:

- field extraction
- classification
- clarification question drafting
- KB suggestion
- ticket summary

However, MVP intake must work even when AI is unavailable.

AI must not become a blocking dependency for ticket creation.

## Decision

Use AI only as an optional assist layer.

Core intake, ticket creation and manual processing must work without AI.

## Consequences

Positive:

- More reliable MVP
- Easier debugging
- Lower launch risk
- Human control over risky actions
- Graceful degradation when AI fails

Negative:

- Less automation in first release
- More rule-based logic required
- Some manual work remains

## Rules

- AI must not close tickets automatically in MVP.
- AI must not send autonomous support answers in MVP.
- AI must not merge contacts automatically.
- AI failures must fall back to rules/manual handling.
- Any AI suggestion must be logged as a business event.
- `AI_ENABLED=false` must keep core intake operational.

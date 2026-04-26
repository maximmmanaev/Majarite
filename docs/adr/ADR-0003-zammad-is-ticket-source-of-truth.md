# ADR-0003: Zammad is ticket source of truth

## Status

Accepted

## Context

Majarite MVP needs a working support UI and a reliable ticket lifecycle without building a custom ticketing system.

The product must support:

- ticket creation
- ticket updates
- queues
- assignment
- statuses
- comments
- attachments
- operator workflow

Building this from scratch would delay MVP and add unnecessary risk.

## Decision

Use Zammad as the source of truth for tickets in Majarite MVP.

Node-RED, PostgreSQL and adapters may reference ticket IDs, but they must not replace Zammad as the canonical ticket system.

## Consequences

Positive:

- Faster MVP
- Existing support UI
- Built-in email intake capabilities
- Built-in operator workflow
- Less custom code

Negative:

- Majarite must follow Zammad data model constraints
- Some product behavior depends on Zammad API/features
- Custom lifecycle extensions may require careful mapping

## Rules

- Ticket canonical state lives in Zammad.
- PostgreSQL stores business events, correlation and analytics data.
- Node-RED orchestrates flows but does not own ticket state.
- Any external channel message linked to a ticket must store the Zammad ticket reference.
- If Zammad is unavailable, inbound events must be logged or retried where possible.

# ADR-0005: Node-RED is orchestration layer, not source of truth

## Status

Accepted

## Context

Majarite needs automation flows for:

- webhook intake
- channel routing
- clarification sessions
- Zammad API calls
- notification delivery
- retry logic
- fallback handling
- event writing

Node-RED is a good fit for orchestration, but it must not become the hidden database of the product.

## Decision

Use Node-RED as the orchestration layer.

Do not use Node-RED as a permanent source of truth.

## Consequences

Positive:

- Fast automation development
- Visual flow debugging
- Easy integration with external services
- Good fit for MVP workflows

Negative:

- Flows can become hard to maintain if not modularized
- Runtime state can be lost if stored only inside Node-RED
- Requires discipline to export flows into Git

## Rules

- Canonical ticket state lives in Zammad.
- Business events live in PostgreSQL.
- Temporary session state lives in Valkey.
- Node-RED flows must be exported and versioned in Git.
- Flow credentials must not be committed.
- Failed flows must write integration error events where possible.

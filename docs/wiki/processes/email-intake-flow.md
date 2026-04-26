# Process — Email Intake Flow

## Flow

1. Customer sends email to support mailbox.
2. Zammad receives email.
3. Zammad creates or updates ticket.
4. Zammad sends webhook to Majarite.
5. email-adapter normalizes payload.
6. email-adapter inserts channel_messages row.
7. email-adapter inserts majorite_events email_received event.

## Source of truth

- Zammad is source of truth for tickets.
- Majorite PostgreSQL is source of truth for events and correlation.

## Current Sprint 3 status

Implemented:

- email-adapter
- webhook endpoint
- payload normalization
- event store write
- smoke-test fixture

Not implemented:

- real mailbox connection
- production webhook token
- customer replies correlation beyond Zammad payload

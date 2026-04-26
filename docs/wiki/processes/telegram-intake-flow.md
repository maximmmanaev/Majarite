# Process — Telegram Intake Flow

## Flow

1. User sends message to Telegram bot.
2. Telegram sends webhook to Majarite.
3. telegram-adapter validates optional X-Majarite-Token.
4. telegram-adapter normalizes payload.
5. telegram-adapter inserts channel_messages row.
6. telegram-adapter inserts majorite_events telegram_message_received event.

## Source of truth

- Telegram is source of truth for raw chat message.
- Majarite PostgreSQL is source of truth for events and correlation.

## Current Sprint 4 status

Implemented:

- telegram-adapter
- webhook endpoint
- payload normalization
- event store write
- smoke-test fixture

Not implemented:

- real Telegram bot token
- production Telegram webhook setup
- auto-ticket creation in Zammad
- clarification flow

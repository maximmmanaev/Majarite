# Runbook — Ticket Creation Bridge

## Purpose

Ticket Creation Bridge связывает intake-события Email/Telegram с Zammad tickets.

## Flow

1. Email или Telegram webhook приходит в adapter.
2. Adapter нормализует payload.
3. Adapter пишет inbound record в channel_messages.
4. Adapter создает или находит Zammad customer.
5. Adapter создает Zammad ticket через API.
6. Adapter обновляет channel_messages.ticket_ref.
7. Adapter пишет ticket_created event в majorite_events.

## Required local env

Use:

env/dev/.env.local

Required values:

- ZAMMAD_API_BASE_URL
- ZAMMAD_API_TOKEN
- ZAMMAD_DEFAULT_GROUP
- ZAMMAD_DEFAULT_CUSTOMER_EMAIL
- ZAMMAD_TICKET_BRIDGE_ENABLED=true

## Security

Real Zammad API token must not be committed to Git.

## Local check

Run:

ENV_FILE=env/dev/.env.local make prod-up-core

Then:

ENV_FILE=env/dev/.env.local make smoke-test

## Acceptance

- email webhook creates linked Zammad ticket
- Telegram webhook creates linked Zammad ticket
- channel_messages.ticket_ref is not empty
- majorite_events contains ticket_created

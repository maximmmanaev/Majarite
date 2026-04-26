# Sprint 5 — Ticket Creation Bridge

Status: planned

## Goal

Связать intake-события Email/Telegram с Zammad tickets.

После входящего сообщения система должна не только писать событие в Majarite event store, но и создавать ticket в Zammad через единый bridge.

## In scope

- Zammad API client module
- Ticket creation bridge logic
- create ticket from email webhook
- create ticket from Telegram webhook
- update channel_messages.ticket_ref
- write ticket_created event
- smoke-test ticket creation path
- docs/wiki/runbook in Markdown

## Zammad ticket mapping

- title from subject/text
- customer from sender/contact_ref
- article body from message body/text
- group default support group
- channel email/telegram
- correlation_id from intake adapter

## Out of scope

- real mailbox setup
- real Telegram webhook setup
- AI classification
- clarification flow
- assignment routing
- SLA
- MAX adapter
- telephony
- GLPI migration

## Definition of Done

- make prod-config проходит
- make smoke-test проходит
- test email webhook creates/links Zammad ticket
- test Telegram webhook creates/links Zammad ticket
- channel_messages.ticket_ref заполняется
- majorite_events содержит ticket_created
- Zammad API token не попадает в Git

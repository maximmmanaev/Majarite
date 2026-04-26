# Sprint 4 — Telegram Intake MVP

Status: planned

## Goal

Добавить второй intake-канал: Telegram.

Telegram webhook должен принимать сообщение, нормализовать payload и писать событие в Majarite event store.

## In scope

- Telegram intake adapter
- Telegram webhook endpoint
- Telegram payload normalization
- telegram_message_received event
- channel_messages insert
- test fixture
- smoke-test Telegram path
- Markdown docs/wiki/runbook

## Normalized fields

- sender
- username
- chat_id
- message_id
- text
- attachments_count
- thread_id
- correlation_id

## Out of scope

- real bot token in Git
- production Telegram webhook setup
- AI classification
- clarification flow
- ticket auto-creation
- MAX adapter
- telephony

## Definition of Done

- make prod-config проходит
- make smoke-test проходит
- Telegram webhook health возвращает 200
- test Telegram webhook возвращает 200
- telegram_message_received пишется в majorite_events
- channel_messages получает запись channel=telegram
- реальные Telegram secrets не попадают в Git

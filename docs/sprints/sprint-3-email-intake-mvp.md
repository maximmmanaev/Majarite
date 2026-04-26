# Sprint 3 — Email Intake MVP

Status: planned

## Goal

Сделать первый полезный intake-канал: email.

Письмо должно попадать в Zammad как ticket, а событие о новом email/ticket должно нормализоваться и записываться в Majarite event store.

## In scope

- Zammad email intake runbook
- Zammad webhook runbook
- email webhook endpoint
- email payload normalization
- email_received event
- channel_messages insert
- smoke-test для email webhook
- docs/wiki в Markdown

## Normalized fields

- sender
- subject
- body
- attachments_count
- external_message_id
- thread_id
- ticket_ref
- correlation_id

## Out of scope

- Telegram intake
- MAX adapter
- AI classification
- mandatory fields engine
- clarification flow
- real Telegram alerts
- KB
- telephony

## Definition of Done

- make prod-config проходит
- make smoke-test проходит
- test email webhook возвращает 200
- email_received пишется в majorite_events
- channel_messages получает запись
- реальные email secrets не попадают в Git
- runbook описывает подключение почты в Zammad

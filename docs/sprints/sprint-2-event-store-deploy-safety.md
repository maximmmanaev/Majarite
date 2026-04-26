# Sprint 2 — Event Store + Deploy Safety

Status: planned

## Goal

Сделать Majarite Core Runtime управляемым и безопасным для дальнейшей разработки.

Sprint 2 не добавляет новые каналы intake. Он усиливает базу:
- event store
- backup
- restore
- rollback
- runbooks
- CI validation

## In scope

- расширить PostgreSQL event store
- добавить таблицы channel_messages, clarification_sessions, notification_log, integration_errors
- добавить test event запись в smoke test
- добавить backup-postgres.sh
- добавить restore-postgres.sh в безопасном режиме
- добавить rollback.sh skeleton
- добавить runbooks
- добавить CI checks

## Out of scope

- email intake
- Telegram intake
- MAX adapter
- AI
- KB
- OpenSearch
- Superset
- telephony
- bug flow
- production HA

## Definition of Done

- make prod-config проходит
- make smoke-test проходит
- test event можно записать в PostgreSQL
- backup script создает архив
- restore script умеет безопасно проверять backup
- rollback script запускается и валидирует аргументы
- runbooks описывают deploy, backup, restore, rollback
- CI проверяет compose config и shell syntax

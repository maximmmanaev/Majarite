# Process — Event Store Schema

## Назначение

PostgreSQL event store хранит бизнес-события и операционные записи Majarite.

## Sprint 2 tables

- majorite_events
- channel_messages
- clarification_sessions
- notification_log
- integration_errors

## Правила

- Zammad остается источником истины по тикетам.
- PostgreSQL event store хранит события, correlation и технические операционные записи.
- Node-RED не является permanent source of truth.
- Все inbound/outbound события должны иметь correlation_id.
- Ошибки интеграций пишутся в integration_errors.
- Уведомления пишутся в notification_log.

## Проверка

Команда:

make smoke-test

Также можно проверить таблицы напрямую:

docker exec majarite-postgres-majorite sh -lc 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "\dt"'

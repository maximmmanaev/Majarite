# Process — Email Intake Adapter

## Назначение

Email intake adapter принимает webhook от Zammad после создания или обновления email ticket.

## Endpoint

POST /webhooks/zammad/email

## Health

GET /health

## Что делает adapter

- принимает JSON payload
- нормализует email fields
- пишет запись в channel_messages
- пишет событие email_received в majorite_events

## Normalized fields

- sender
- subject
- body
- attachments_count
- external_message_id
- thread_id
- ticket_ref
- correlation_id

## Security

Webhook может быть защищен заголовком:

X-Majarite-Token

Реальный token не хранится в Git.

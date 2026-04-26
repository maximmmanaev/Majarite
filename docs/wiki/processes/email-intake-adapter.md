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

## Docker Compose

Service name:

email-adapter

Internal port:

8080

Public routes through external NGINX:

- GET /email-adapter/health
- POST /webhooks/zammad/email

## Runtime rule

email-adapter is internal-only. It is not published directly to the host.
Only NGINX exposes the webhook route.

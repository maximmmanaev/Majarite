# Process — Telegram Intake Adapter

## Назначение

Telegram intake adapter принимает webhook payload от Telegram Bot API.

## Endpoint

POST /webhooks/telegram

## Health

GET /health

## Что делает adapter

- принимает Telegram JSON payload
- нормализует message fields
- пишет запись в channel_messages
- пишет событие telegram_message_received в majorite_events

## Normalized fields

- sender
- username
- chat_id
- message_id
- text
- attachments_count
- thread_id
- correlation_id

## Security

Webhook может быть защищен заголовком:

X-Majarite-Token

Реальный token не хранится в Git.

## Docker Compose

Service name:

telegram-adapter

Internal port:

8080

Public routes through external NGINX:

- GET /telegram-adapter/health
- POST /webhooks/telegram

## Runtime rule

telegram-adapter is internal-only. It is not published directly to the host.
Only NGINX exposes the webhook route.

# Runbook — Telegram Intake Bot

## Purpose

Настроить Telegram bot как intake-канал Majarite.

## Result

Сообщение пользователя в Telegram должно приходить в Majarite через webhook.

## Required data

- Telegram bot token
- public HTTPS domain
- webhook secret token

## Security rule

Real Telegram bot token must not be committed to Git.

## Local test

Use fixture:

tests/fixtures/telegram/telegram-message-webhook.json

Command:

curl -i -X POST http://localhost:8080/webhooks/telegram -H "Content-Type: application/json" -H "X-Majarite-Token: change-me-dev-telegram-webhook-token" --data-binary @tests/fixtures/telegram/telegram-message-webhook.json

## Production setup

1. Create bot via BotFather.
2. Store bot token outside Git.
3. Configure TELEGRAM_WEBHOOK_TOKEN in server env.
4. Expose Majarite via HTTPS.
5. Set Telegram webhook to:
   https://YOUR_DOMAIN/webhooks/telegram
6. Send test message to bot.
7. Confirm telegram_message_received event exists.
8. Confirm channel_messages has channel=telegram.

## Acceptance

- Telegram webhook returns 200.
- majorite_events contains telegram_message_received.
- channel_messages contains telegram inbound record.

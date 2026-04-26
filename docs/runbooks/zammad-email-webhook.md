# Runbook — Zammad Email Webhook

## Purpose

Настроить webhook из Zammad в Majarite email adapter.

## Target endpoint

POST /webhooks/zammad/email

Local dev URL:

http://localhost:8080/webhooks/zammad/email

Production URL:

https://YOUR_DOMAIN/webhooks/zammad/email

## Required header

X-Majarite-Token: REAL_TOKEN_FROM_ENV

## Security rule

Real token must be stored only in environment file outside Git.

## Expected payload

Webhook payload should include ticket and article data.

Minimum useful fields:

- ticket.id
- ticket.number
- ticket.title
- article.id
- article.message_id
- article.from
- article.subject
- article.body
- article.attachments

## Local test

Use fixture:

tests/fixtures/email/zammad-email-webhook.json

Command:

curl -i -X POST http://localhost:8080/webhooks/zammad/email -H "Content-Type: application/json" -H "X-Majarite-Token: change-me-dev-email-webhook-token" --data-binary @tests/fixtures/email/zammad-email-webhook.json

## Acceptance

- webhook returns 200
- response contains status accepted
- majorite_events contains email_received
- channel_messages contains email inbound record

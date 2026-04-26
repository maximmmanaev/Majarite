# Process — Ticket Creation Bridge Flow

## Goal

Convert normalized intake messages into Zammad tickets.

## Email path

Email webhook:

- channel = email
- event = email_received
- customer = sender email
- ticket title = subject
- ticket article body = email body

## Telegram path

Telegram webhook:

- channel = telegram
- event = telegram_message_received
- customer email = telegram-{chat_id}@majarite.local
- ticket title = first 120 chars of message text
- ticket article body = message text

## Event store writes

For each created ticket:

- channel_messages.ticket_ref is updated with Zammad ticket number or id
- majorite_events receives ticket_created

## Current limitation

Bridge creates new tickets.

It does not yet:

- merge messages into existing ticket threads
- assign tickets by load
- classify requests
- ask clarification questions
- apply SLA

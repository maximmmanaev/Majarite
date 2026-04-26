# PRD — Majarite

## Product Overview

Majarite is a self-hosted helpdesk platform for technical support intake, ticketing and automation.

The first MVP is text-first and focuses on:

- Email intake
- Telegram intake
- MAX later as isolated adapter
- Zammad ticketing
- Node-RED automation
- PostgreSQL event store
- Valkey temporary session state
- Docker Compose deployment

## Problem

Support requests arrive through multiple channels and are processed manually.

Current pain points:

- requests are spread across channels
- specialists manually copy context into tickets
- mandatory data is often missing
- tickets are created inconsistently
- team leads lack clean operational visibility
- users repeat the same information several times

## MVP Goal

Turn each incoming text request into a structured Zammad ticket or draft with minimum required fields and traceable business events.

## Primary Users

- Support Specialist L1
- Team Lead Support
- System Administrator

## MVP Flow

1. User sends email or Telegram message.
2. Majarite captures inbound message.
3. Node-RED normalizes the event.
4. Zammad ticket or draft is created or updated.
5. PostgreSQL business event is written.
6. Mandatory fields are checked.
7. Missing fields trigger clarification.
8. Complete ticket becomes Open.
9. Ticket goes to General Support queue.
10. Telegram notification is sent.

## Mandatory Fields

A ticket can become Open only when it has:

- full name of affected user
- email or contact channel
- contour / database
- short problem description

## Non-Goals for First Release

- telephony
- voice transcription
- full AI support agent
- autonomous auto-answers
- full bug workflow
- knowledge base search
- advanced analytics UI
- weighted assignment
- multi-server HA
- Kubernetes

# Contact Resolution Runbook

## Purpose

Contact Resolution нужен, чтобы Majarite не спрашивал у пользователя одни и те же данные при каждом обращении.

Система должна:
- найти contact по channel identity;
- подставить уже известные данные;
- определить базу / контур ЦУПС;
- отдельно определить affected user;
- создать ticket context snapshot.

## Runtime Path

Email / Telegram webhook
↓
FastAPI adapter
↓
PostgreSQL event store
↓
Zammad ticket bridge
↓
Zammad ticket

## Source of Truth

- Zammad — ticket lifecycle.
- PostgreSQL — contacts, identities, databases, events.
- FastAPI adapters — текущая реализация intake.
- Node-RED — orchestration layer, не база истины.

## Core Entities

- Contact — кто обратился.
- Channel Identity — email / telegram / max / phone identity.
- Database — база или контур ЦУПС.
- Affected User — пользователь ЦУПС, у которого ошибка.
- Ticket Snapshot — исторический снимок данных обращения.

## Required Ticket Context

Ticket может стать Open только если есть:

- requester identity;
- reply path;
- database_name;
- affected_user_name;
- problem_summary.

## Rules

Если contact найден — не спрашивать ФИО и почту повторно.

Если у contact одна база — подставить ее.

Если баз несколько — спросить, в какой базе проблема.

Если affected user неясен — спросить:
"Ошибка у вас или у другого пользователя ЦУПС?"

## Events

Sprint 6 должен писать события:

- contact_lookup_started
- contact_lookup_matched
- contact_lookup_not_found
- contact_created
- contact_identity_linked
- database_auto_selected
- database_selection_required
- affected_user_required
- ticket_context_completed
- ticket_context_incomplete

## Debug

Check tables:

```bash
docker exec majarite-postgres-majorite sh -lc 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "\dt"'
Acceptance
contacts table exists.
contact_identities table exists.
cus_databases table exists.
contact_databases table exists.
ticket_context_snapshots table exists.
email identity can resolve contact.
telegram identity can resolve contact.
requester and affected user are separate fields.

# Sprint 6 Completion — Contact Resolution + Case Context Rules

Status: completed.

## Result

Sprint 6 added deterministic contact resolution and ticket context snapshots for Email and Telegram intake.

Majarite now separates:

- requester contact;
- channel identity;
- CUS database / contour;
- affected user;
- ticket context snapshot.

## Added

- Sprint 6 documentation.
- Contact Resolution runbook.
- PostgreSQL schema:
  - contacts
  - contact_identities
  - cus_databases
  - contact_databases
  - ticket_context_snapshots
- Fresh init SQL for new deployments.
- Migration SQL for existing deployments.
- Smoke-test checks for contact resolution tables.
- Email contact resolution:
  - lookup/create contact by email identity;
  - create verified email identity;
  - write ticket context snapshot;
  - write contact resolution events.
- Telegram contact resolution:
  - lookup/create contact by Telegram chat identity;
  - create verified Telegram identity;
  - write ticket context snapshot;
  - write contact resolution events.
- Smoke-test checks for Email and Telegram contact resolution.

## Verified commands

- python3 -m py_compile adapters/email/src/main.py
- python3 -m py_compile adapters/telegram/src/main.py
- make prod-config
- make smoke-test

## Verified runtime behavior

Email webhook now creates:

- contact
- email contact identity
- ticket context snapshot
- contact resolution events

Telegram webhook now creates:

- contact
- Telegram contact identity
- ticket context snapshot
- contact resolution events

## Event types verified

- contact_lookup_started
- contact_lookup_matched
- contact_lookup_not_found
- contact_created
- contact_identity_linked
- database_auto_selected
- database_selection_required
- ticket_context_completed
- ticket_context_incomplete
- affected_user_required

## Important behavior

Requester and affected user are separate fields.

The system does not treat requester name as affected user automatically.

If affected user is missing, ticket context remains incomplete and `affected_user_required` is logged.

## Current status

Sprint 6 creates the contact resolution foundation.

Email and Telegram intake can now attach normalized contact context to incoming messages before or alongside ticket creation.

## Not done yet

- real clarification dialogue
- Telegram buttons for database / affected user selection
- automatic Zammad custom field mapping
- manual contact merge
- MAX contact resolution
- Mango/phone contact resolution
- AI extraction of affected user and database from text

## Next sprint

Sprint 7 — Hybrid Clarification.

Sprint 7 should use Sprint 6 context snapshots and add deterministic clarification for missing fields.

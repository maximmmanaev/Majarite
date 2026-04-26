# Sprint 3 Completion — Email Intake MVP

Status: completed and merged into develop.

PR: #4 — Sprint 3: Email Intake MVP

Result:
- Email intake adapter added.
- Email adapter connected to Docker Compose core runtime.
- NGINX routes added:
  - GET /email-adapter/health
  - POST /webhooks/zammad/email
- Zammad webhook payload normalization implemented.
- Email webhook writes inbound record to channel_messages.
- Email webhook writes email_received event to majorite_events.
- Test fixture added.
- Smoke test now verifies email intake path.
- Zammad email intake runbook added.
- Zammad webhook runbook added.
- Email intake flow wiki added.
- CI validates email adapter syntax and fixture JSON.

Verified commands:
- python3 -m py_compile adapters/email/src/main.py
- python3 -m json.tool tests/fixtures/email/zammad-email-webhook.json
- make prod-config
- docker build -t majarite/email-adapter:0.1.0 adapters/email
- make prod-up-core
- make smoke-test

Important operational decision:
After make prod-up-core, NGINX is restarted automatically to refresh Docker DNS upstreams and avoid temporary 502 errors after adapter recreation.

Current status:
Email webhook technical path works.

Not done yet:
- real mailbox credentials are not configured
- real Zammad mailbox is not connected
- real Zammad webhook is not configured in UI
- Telegram intake is not implemented
- clarification flow is not implemented

Next sprint:
Sprint 4 — Telegram Intake MVP.

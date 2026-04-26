# Majarite Node-RED Flows

Node-RED is used only as orchestration layer.

## Responsibilities

- receive webhooks
- normalize channel events
- call Zammad API
- write business events to PostgreSQL
- manage clarification flow
- send Telegram notifications
- handle retries and integration errors

## Not Source of Truth

Node-RED must not store permanent business state.

Permanent state belongs to:

- Zammad for tickets
- PostgreSQL for business events
- Valkey for temporary sessions only

## Credentials

Do not commit real Node-RED credentials.

Allowed:

- flows.json
- flows_cred.example.json

Forbidden:

- flows_cred.json

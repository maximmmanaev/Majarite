# Runbook: Backup

## Goal

Create recoverable backups for Majarite MVP.

## Must Backup

- PostgreSQL databases
- Zammad attachments and volume data
- Node-RED flows
- Environment examples
- Runtime secrets through encrypted external backup only

## Rules

- Real secrets must not be committed to Git.
- Backups must be tested with restore drills.
- Pre-deploy backup is mandatory.

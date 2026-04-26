# Sprint 2 Completion — Event Store + Deploy Safety

Status: completed and merged into develop.

PR: #3 — Sprint 2: Event Store and Deploy Safety

Result:
- Operational event store tables added.
- Schema drift repaired with migration.
- Smoke test now verifies real event write.
- PostgreSQL backup script added.
- Safe PostgreSQL restore script added.
- Safe rollback plan script added.
- Deploy, backup, restore and rollback runbooks added.
- CI validates shell syntax, compose config and secret/runtime hygiene.

Verified commands:
- make prod-config
- make smoke-test
- bash scripts/backup/backup-postgres.sh
- bash scripts/backup/restore-postgres.sh list
- bash scripts/backup/restore-postgres.sh verify latest majorite backup
- bash scripts/deploy/rollback.sh plan --to HEAD

Important rule:
Restore and rollback are safe-plan only in Sprint 2.

They do not:
- overwrite databases
- stop containers
- checkout git refs automatically
- run destructive operations

Next sprint:
Sprint 3 — Email Intake MVP.

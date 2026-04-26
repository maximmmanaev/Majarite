# Runbook: Restore

## Goal

Restore Majarite MVP after failure or migration to a clean server.

## Restore Order

1. Prepare clean Ubuntu server.
2. Install Docker.
3. Clone repository.
4. Restore runtime env and secrets.
5. Restore PostgreSQL.
6. Restore volumes.
7. Start core stack.
8. Run smoke tests.
9. Verify sample tickets and events.

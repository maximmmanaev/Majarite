# Runbook: Production Rollback

## Goal

Return Majarite to previous known-good version.

## Preconditions

- Previous Git tag exists.
- Pre-deploy backup exists.
- Current failure is confirmed.

## Steps

1. Stop write-heavy services if needed.
2. Checkout previous Git tag.
3. Apply previous Docker Compose config.
4. Restore database only if migration broke data.
5. Start core stack.
6. Run smoke tests.
7. Confirm ticket intake is operational.

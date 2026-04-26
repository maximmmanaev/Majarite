# Runbook: Production Deploy

## Goal

Deploy Majarite production-capable MVP from GitHub repository to Ubuntu server.

## Preconditions

- Ubuntu server is prepared.
- Docker and Docker Compose are installed.
- Runtime `.env` exists outside Git.
- Secrets are stored outside Git.
- Backup has been created before deploy.

## Steps

1. Pull target Git tag or branch.
2. Validate Docker Compose config.
3. Run pre-deploy backup.
4. Start core stack.
5. Run smoke tests.
6. Check logs.
7. Confirm Zammad, Node-RED and PostgreSQL are healthy.

## Rollback

If smoke tests fail, use `docs/runbooks/rollback-production.md`.

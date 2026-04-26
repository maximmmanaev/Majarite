# Process — Local Env

## Purpose

Local env files are used for developer-only secrets.

## Rule

Never commit real local env files.

Ignored files:

- env/**/*.local
- env/**/*.secret

## Sprint 5 Zammad API token

Create local env file from full dev env:

cp env/dev/.env.example env/dev/.env.local

Append local secret template:

cat env/dev/local-env.example >> env/dev/.env.local

Edit local env:

nano env/dev/.env.local

Set:

- ZAMMAD_API_TOKEN
- ZAMMAD_API_BASE_URL
- ZAMMAD_DEFAULT_GROUP
- ZAMMAD_DEFAULT_CUSTOMER_EMAIL

## Running with local env

Use:

ENV_FILE=env/dev/.env.local make prod-up-core

and:

ENV_FILE=env/dev/.env.local make smoke-test

## Why not only local-env.example

Docker Compose needs all base variables from env/dev/.env.example.

Therefore env/dev/.env.local must be a full env file, not only a small override.

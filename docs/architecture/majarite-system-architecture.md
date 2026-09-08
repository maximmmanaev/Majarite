# QuoteFlow System Architecture

## Architecture Summary

QuoteFlow MVP is a self-hosted or cloud-ready service configuration and quoting platform.

The first release should remain deployable by one person with Docker Compose while keeping domain boundaries explicit enough for later integrations.

## Core Runtime

MVP core services:

- NGINX as edge reverse proxy
- QuoteFlow API as application/domain service
- PostgreSQL as primary system of record
- Background worker for asynchronous jobs such as email delivery and webhook retries
- Optional Valkey/Redis-compatible store for temporary locks, idempotency keys, and short-lived sessions

## Core Domain Modules

### Identity / Workspace

Owns:

- users
- workspace
- roles
- workspace settings

### Service Catalog

Owns:

- services
- service components
- component dependencies

### Questionnaire

Owns:

- questions
- options
- conditional visibility rules
- answer validation

### Rule Engine

Owns:

- configuration rules
- pricing rules
- rule priority
- rule versions
- deterministic evaluation results

### Configuration

Owns:

- client configuration
- answers
- selected components
- current lifecycle state

### Calculation

Owns:

- calculation runs
- pricing adjustments
- totals
- trace explaining how a result was produced

### Scope

Owns:

- in-scope items
- exclusions
- assumptions
- scope snapshot generation

### Quote

Owns:

- quote aggregate
- quote versions
- public access token
- acceptance/rejection lifecycle
- immutable snapshots for sent/accepted versions

### Change Request

Owns:

- post-baseline requested changes
- impact estimate
- approval status
- linkage to resulting quote version

### Audit / Events

Owns business event history and correlation metadata.

## Source of Truth

| Area | Source of Truth |
|---|---|
| Workspace/users | PostgreSQL |
| Service catalog | PostgreSQL |
| Questions/options | PostgreSQL |
| Rules and rule versions | PostgreSQL |
| Configurations/answers | PostgreSQL |
| Calculations | PostgreSQL |
| Quotes/versions | PostgreSQL |
| Change Requests | PostgreSQL |
| Business events/audit | PostgreSQL |
| Temporary idempotency/session state | Valkey/Redis-compatible store if enabled |
| Runtime config examples | Git |
| Real secrets | Environment/secret store, never Git |

## Main Synchronous Flow

1. Client or estimator submits an answer.
2. API validates the answer.
3. Configuration state is updated.
4. Applicable visibility/validation rules are evaluated.
5. When enough required data is present, calculation is requested.
6. Rule Engine evaluates deterministic business and pricing rules.
7. Calculation result and rule trace are persisted.
8. Scope is generated from selected components and rule outputs.
9. QuoteVersion can be created from immutable snapshots.

## Quote Publication Flow

1. Estimator creates QuoteVersion from the current calculated configuration.
2. System snapshots scope, price, assumptions, exclusions, and rule/calculation references.
3. Quote status becomes Ready.
4. User sends quote.
5. System generates or reuses a secure public token.
6. Email delivery runs asynchronously.
7. Client opens public quote page; Viewed event is written.
8. Client accepts or rejects.
9. Accepted version becomes baseline and must remain immutable.

## Change Request Flow

1. New requirement is received after baseline acceptance.
2. Change Request is created.
3. Analyst/estimator links affected scope and/or configuration answers.
4. Impact is calculated or manually estimated.
5. If commercial terms change, a new QuoteVersion is generated.
6. Previous accepted baseline remains available for comparison and audit.

## Integration Boundary

QuoteFlow should integrate rather than replicate adjacent products.

External systems may include:

- CRM
- email provider
- Telegram/messenger
- payment provider
- e-signature provider
- invoicing/accounting system

Integration adapters must not own QuoteFlow domain state.

## API Principles

- REST/JSON for MVP
- UUID identifiers for public domain entities
- idempotency for externally triggered write operations where needed
- explicit version field for mutable rule definitions
- immutable QuoteVersion snapshots after sending
- correlation_id propagated across business events and integration calls
- standard error envelope
- OpenAPI specification treated as a versioned artifact

## Reliability Rules

- A failed email send must not roll back a successfully created QuoteVersion.
- Duplicate client decisions must be handled idempotently.
- Recalculation must never mutate an already sent QuoteVersion snapshot.
- Rule evaluation failures must put the configuration into Requires Review rather than silently returning a partial price.
- External integration failures must be recorded as business/integration events and retried where appropriate.

## AI Boundary

AI is optional and outside the deterministic pricing authority.

AI may later assist with:

- extracting draft answers from free-form text
- suggesting clarification questions
- drafting descriptions
- detecting potentially missing scope

AI output must be treated as a suggestion until accepted by deterministic application logic or a human user.

## Deployment Rule

MVP must be deployable by one person using:

- Docker Compose
- `.env.example`
- database migrations
- backup/restore procedures
- smoke tests
- rollback procedure

## Out of First Release

- microservice decomposition
- Kubernetes
- event broker as mandatory infrastructure
- multi-region HA
- full CRM
- accounting
- payment processing
- enterprise IAM/SSO
- autonomous AI pricing

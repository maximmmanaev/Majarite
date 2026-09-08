# QuoteFlow MVP Scope

## MVP Goal

Build a narrow B2B service configuration engine that converts client answers into a traceable scope, estimate, and quote.

## MVP Core

QuoteFlow MVP focuses on:

- Service catalog
- Service components
- Dynamic questionnaire
- Deterministic rule engine
- Pricing rules
- Scope generation
- Quote creation
- Quote versioning
- Client approval/rejection
- Change Requests after approval
- Business event audit log
- REST API
- PostgreSQL
- Docker Compose deployment

## In Scope

### Workspace and users

- Single workspace per account in MVP
- Owner/admin role
- Estimator role

### Client

- Create and edit client
- Store name, company, email, optional phone

### Service model

- Create service
- Create reusable service components
- Fixed base price
- Optional effort estimate
- Active/inactive state
- Dependencies between components

### Questionnaire

- Create questions
- Supported types: text, number, boolean, single select, multi select
- Required/optional questions
- Conditional question visibility based on previous answers

### Rules

Rule structure must include:

- trigger condition
- action
- priority
- active/inactive state
- explanation

Supported MVP actions:

- add component
- remove component
- require component
- add fixed surcharge
- add percentage surcharge
- multiply price by coefficient
- add assumption
- add exclusion
- require manual review

### Configuration

Configuration lifecycle:

- Draft
- Collecting Answers
- Ready for Calculation
- Calculated
- Requires Review
- Quote Ready
- Closed

### Calculation

The system must store:

- selected components
- base amounts
- applied pricing rules
- manual adjustments
- final amount
- calculation timestamp
- rule versions used for the calculation

Recalculation must not destroy the previous calculation result if a quote version has already been created.

### Scope

Generate:

- In Scope
- Out of Scope
- Assumptions

### Quote

Quote statuses:

- Draft
- Ready
- Sent
- Viewed
- Accepted
- Rejected
- Expired
- Superseded

Quote must contain:

- client
- configuration reference
- scope snapshot
- estimate snapshot
- total price
- validity period
- version number

### Client decision

- Public secure quote link
- No client account required in MVP
- Accept
- Reject
- Record timestamp and decision

### Change Request

Available only after a quote is accepted.

Statuses:

- Draft
- Submitted
- Estimating
- Ready for Approval
- Approved
- Rejected
- Implemented

Approved Change Request may produce a new QuoteVersion.

### Audit / events

Store important business events in PostgreSQL.

Minimum event attributes:

- event_type
- entity_type
- entity_id
- correlation_id
- actor_type
- actor_id if available
- payload_json
- created_at

## Out of Scope for First Release

- CRM pipeline
- invoices
- payments
- accounting
- project/task management
- time tracking
- team resource planning
- e-signatures
- native mobile apps
- autonomous AI pricing
- multi-currency conversion
- taxes beyond a simple manual field
- complex enterprise approval matrix
- real-time collaborative editing

## MVP Example Scenario

A web studio offers website development.

Client answers:

- site type = e-commerce
- products = 1500
- CRM integration = yes
- deadline = 14 days

Rules produce:

- add E-commerce Base
- add Advanced Catalog because products > 1000
- add CRM Integration
- apply Rush +30% because requested deadline is below standard estimate
- add assumption: client CRM exposes supported API

System generates scope, estimate, and Quote v1.

If the client later asks for multi-language support after accepting Quote v1, QuoteFlow creates a Change Request instead of silently changing the accepted baseline.

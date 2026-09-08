# PRD — QuoteFlow

## Product Overview

QuoteFlow is a service configuration and quoting platform for small service businesses.

It helps turn an unclear client request into a structured configuration of services, scope, estimate, and commercial quote.

## Problem

Service businesses often price custom work manually. Client requests arrive as free-form messages or calls, requirements are incomplete, estimates depend on tacit knowledge, and scope is frequently ambiguous.

Current pain points:

- the same clarification questions are asked manually for every lead
- pricing rules live in spreadsheets or in the owner's head
- important dependencies between services are easy to miss
- two employees can estimate the same request differently
- assumptions and exclusions are not recorded consistently
- changes after approval lead to scope creep
- quotes are manually assembled from copied data
- there is little traceability explaining why a price was calculated

## Product Goal

Turn a client's initial need into a reproducible, explainable quote using configurable questions, service components, business rules, and pricing rules.

## Primary Users

- Solo service provider / freelancer
- Agency owner or sales manager
- Estimator / pre-sales specialist
- Client reviewing and approving a quote

## Core User Journey

1. Business owner configures services, questions, dependencies, and pricing rules.
2. A new client configuration is created.
3. Client or specialist answers a dynamic questionnaire.
4. QuoteFlow validates required data.
5. Rules select or exclude service components.
6. Pricing rules calculate estimate and adjustments.
7. Scope, assumptions, and exclusions are generated.
8. A quote version is created.
9. Client reviews and accepts, rejects, or asks for changes.
10. Approved quote becomes the baseline.
11. Later changes create a Change Request and a new quote version.
12. Important actions are recorded in an audit/business event log.

## MVP Capabilities

### Service Catalog

A workspace can define services and reusable service components.

Examples:

- Landing page
- UI/UX design
- Frontend development
- CMS setup
- CRM integration
- Copywriting

Each service component can contain:

- name
- description
- base price or rate
- estimated effort
- dependencies
- exclusions
- active/inactive state

### Dynamic Questionnaire

Questions may depend on previous answers.

Example:

- If `ecommerce = true`, ask `product_count`.
- If `crm_integration = true`, ask `crm_type`.

Supported MVP answer types:

- text
- number
- boolean
- single select
- multi select

### Rule Engine

Rules evaluate configuration answers and can:

- add a service component
- remove a service component
- require another component
- modify price
- modify effort
- add an assumption
- add an exclusion
- mark configuration as requiring manual review

MVP rules are deterministic and auditable. AI is not required for rule execution.

### Pricing

The estimate is composed from selected components and pricing adjustments.

Examples:

- base fixed price
- quantity multiplier
- rush coefficient
- percentage surcharge
- fixed surcharge
- manual adjustment with reason

Every calculated amount must be explainable by the rules that produced it.

### Scope Generation

QuoteFlow generates three separate sections:

- In Scope
- Out of Scope
- Assumptions

The generated result can be manually edited before sending a quote, but manual edits must be tracked.

### Quote Lifecycle

MVP quote statuses:

- Draft
- Ready
- Sent
- Viewed
- Accepted
- Rejected
- Expired
- Superseded

An accepted quote becomes the commercial baseline for the configuration.

### Quote Versioning

Any material change to price, scope, assumptions, or exclusions after a quote was sent creates a new quote version.

Previous versions remain immutable and accessible for audit.

### Change Request

After acceptance, new requirements must not silently mutate the baseline.

They create a Change Request with:

- description
- requested by
- affected scope
- estimate impact
- schedule impact if available
- decision status
- resulting quote version

### Audit / Business Events

Important actions must create business events, including:

- configuration created
- answer changed
- rule evaluated
- component added or removed
- estimate recalculated
- quote version created
- quote sent
- quote viewed
- quote accepted or rejected
- change request created

## Core Domain Entities

- Workspace
- User
- Client
- Service
- ServiceComponent
- Question
- QuestionOption
- Rule
- PricingRule
- Configuration
- Answer
- SelectedComponent
- Calculation
- ScopeItem
- Quote
- QuoteVersion
- ChangeRequest
- BusinessEvent

## Integrations

MVP architecture must allow external integrations without making them core dependencies.

Priority integrations:

- Email for quote delivery
- Webhooks / REST API

Later integrations:

- CRM
- Telegram
- payment provider
- e-signature
- accounting / invoicing

## AI Position

AI is an optional assist layer, not the pricing authority.

Potential later uses:

- extract requirements from free-form client text
- suggest clarification questions
- summarize a configuration
- draft quote descriptions
- suggest possible missing scope

All price and scope decisions in the MVP must remain deterministic and traceable.

## Non-Goals for First Release

- full CRM
- invoicing/accounting
- project management
- time tracking
- marketplace
- multi-level enterprise approval chains
- autonomous AI pricing
- AI-generated rules without human approval
- complex tax engine
- multi-currency conversion
- payment collection
- e-signature
- mobile native applications

## Success Criteria for MVP

The MVP is successful when a configured service can go through the full path:

`Client need -> Questionnaire -> Rules -> Scope -> Estimate -> Quote -> Client decision`

without manual spreadsheet calculations.

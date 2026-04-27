# Sprint 6 — Contact Resolution + Case Context Rules

Status: planned

## Goal

Сделать так, чтобы Majarite не спрашивал у пользователя ФИО, почту и базу данных при каждом обращении.

Система должна:
- находить контакт по channel identity;
- подставлять уже известные подтвержденные данные;
- учитывать, что один контакт может работать в нескольких базах ЦУПС;
- различать обратившегося человека и пользователя ЦУПС, у которого возникла ошибка;
- переводить тикет в `Open` только когда есть минимальный контекст обращения.

## Problem

До Sprint 6 система умеет принимать Email/Telegram intake и создавать ticket в Zammad.

Но без contact resolution появляется плохой UX:

- известного пользователя каждый раз просят назвать ФИО;
- почту спрашивают повторно;
- базу данных спрашивают даже если она уже известна;
- невозможно нормально обработать кейс, когда обращается один человек, а ошибка у другого пользователя ЦУПС;
- контактные данные из Telegram, Email, MAX и будущего Mango могут разъехаться.

Sprint 6 исправляет это через отдельную модель контактов и правил контекста обращения.

## Core Concepts

### Contact

Человек, который обратился в поддержку.

Примеры:
- Иванов Петр
- Петров Алексей
- представитель подрядчика
- специалист заказчика

Contact не всегда равен пользователю ЦУПС, у которого возникла ошибка.

### Channel Identity

Технический идентификатор контакта в конкретном канале.

Примеры:
- `telegram:123456`
- `email:ivanov@example.ru`
- `max:abc-123`
- `phone:+79991234567`

Один contact может иметь несколько channel identities.

### CUS Database / Contour

База данных или контур ЦУПС, где возникла проблема.

Один contact может быть связан с несколькими базами.

### Affected User

Пользователь ЦУПС, у которого возникла ошибка.

Affected user может совпадать с requester, а может быть другим человеком.

### Ticket Snapshot

В ticket нужно записывать snapshot данных обращения:

- кто обратился;
- через какой канал;
- как связаться;
- в какой базе проблема;
- у какого пользователя ЦУПС проблема;
- что случилось.

Snapshot нужен потому, что contact profile может измениться позже, а старый тикет должен сохранить исторически верные данные.

## In scope

- Contact lookup by channel identity:
  - Email `from`
  - Telegram `from.id`
  - MAX identity later
  - Phone later
- Contact model in PostgreSQL
- Contact identities model
- CUS databases model
- Contact to databases relation
- Case context contract
- Ticket completeness rules
- Draft/Open decision rules
- Event logging for contact resolution decisions
- Markdown documentation and runbook
- Basic tests for contact resolution rules

## Out of scope

- MAX adapter implementation
- Mango/telephony implementation
- automatic contact merge
- AI-based contact merge
- CRM replacement
- full Zammad customer synchronization
- KB search
- auto-answer
- weighted assignment
- SLA logic
- bug workflow

## Data Model

### contacts

Stores normalized support contact profile.

Fields:
- `contact_id`
- `display_name`
- `primary_email`
- `primary_phone`
- `notes`
- `created_at`
- `updated_at`

### contact_identities

Stores channel-specific identifiers.

Fields:
- `identity_id`
- `contact_id`
- `channel`
- `identity_value`
- `verified`
- `created_at`
- `updated_at`

Unique rule:
- one `channel + identity_value` pair must point to one contact.

Examples:
- `telegram + 123456`
- `email + ivanov@example.ru`
- `max + abc-123`
- `phone + +79991234567`

### cus_databases

Stores known ЦУПС databases / contours.

Fields:
- `database_id`
- `name`
- `external_code`
- `active`
- `created_at`
- `updated_at`

### contact_databases

Stores relation between contact and databases.

Fields:
- `contact_id`
- `database_id`
- `is_default`
- `role`
- `comment`
- `created_at`
- `updated_at`

Rules:
- contact can have zero, one or many databases;
- only one default database per contact is allowed;
- if contact has multiple databases, system should ask which database is affected.

## Ticket Context Contract

Every created ticket should receive these fields as snapshot where possible:

- `requester_contact_id`
- `requester_name`
- `requester_email`
- `requester_channel`
- `database_id`
- `database_name`
- `affected_user_name`
- `problem_summary`

## Completeness Rules

Ticket can become `Open` only when the system has:

- requester identity:
  - `requester_contact_id` or `requester_name`
- reply path:
  - `requester_email` or another known channel identity
- `database_name`
- `affected_user_name`
- `problem_summary`

If required context is missing, ticket must stay `Intake Pending` or `Draft`.

## Decision Rules

### Contact lookup

Incoming message:
1. Determine channel.
2. Extract channel identity.
3. Search `contact_identities`.
4. If identity exists, load contact.
5. If identity does not exist, create draft contact or ask for contact data.

### Database selection

If contact has:

- `0` databases → ask database name.
- `1` database → auto-fill database.
- `2+` databases → ask user to choose database.
- selected unknown database → store it as ticket snapshot and optionally create database record later.

### Affected user

If user clearly says that problem is for another person, store that person as `affected_user_name`.

If affected user is unclear:
- ask whether the error is under the requester account or another ЦУПС user;
- for Telegram later use buttons:
  - `Ошибка у меня`
  - `Ошибка у другого пользователя`

If user chooses `Ошибка у меня`:
- `affected_user_name = requester_name`

If user chooses `Ошибка у другого пользователя`:
- ask for affected user full name.

### Problem summary

Use message subject/body/text as initial `problem_summary`.

If message text is too short or empty:
- ask for a short description of the problem.

## Event Logging

Sprint 6 must write business events where implemented:

- `contact_lookup_started`
- `contact_lookup_matched`
- `contact_lookup_not_found`
- `contact_created`
- `contact_identity_linked`
- `database_auto_selected`
- `database_selection_required`
- `affected_user_required`
- `ticket_context_completed`
- `ticket_context_incomplete`

Every event should include:
- `correlation_id`
- `channel`
- `entity_type`
- `entity_id`
- `payload_json`

## UX Rules

### Never ask again if already verified

Do not ask repeatedly:

- requester full name;
- requester email;
- requester phone;
- Telegram ID;
- known channel identity.

### Ask per case if unclear

Ask when not clear:

- database / contour;
- affected user;
- problem summary.

Reason:
- database can change per case;
- affected user can differ from requester;
- problem is always new.

## Example: Known Telegram User, One Database

Input:
- Telegram ID known.
- Contact: Иванов Петр.
- Email: ivanov@example.ru.
- One database: РВК Самара.
- Message: `Не работает выгрузка`.

System:
- does not ask name;
- does not ask email;
- does not ask database;
- asks only affected user if unclear;
- creates ticket after affected user is known.

## Example: Known Telegram User, Multiple Databases

Input:
- Contact: Иванов Петр.
- Databases:
  - РВК Самара
  - РВК Тюмень
  - Демо-контур
- Message: `Не открывается КС-2`.

System asks:
- `В какой базе данных возникла проблема?`

After database is selected, system asks only missing fields.

## Example: Requester Reports Problem for Another User

Input:
- Requester: Петров Алексей.
- Message: `У директора Иванова И.И. не подписывается акт в базе РВК Самара`.

Ticket snapshot:
- requester_name: Петров Алексей
- affected_user_name: Иванов И.И.
- database_name: РВК Самара
- problem_summary: не подписывается акт

The system must not overwrite requester profile with affected user.

## Definition of Done

- Sprint 6 documentation exists in `docs/sprints`.
- Contact resolution runbook exists in `docs/runbooks`.
- PostgreSQL migration defines contact tables.
- Contact identity uniqueness is enforced.
- Contact can be linked to multiple databases.
- Ticket context contract is documented.
- Completeness rules are documented and testable.
- `requester` and `affected_user` are treated as different fields.
- Basic tests cover:
  - known contact with one database;
  - known contact with multiple databases;
  - new contact;
  - affected user differs from requester;
  - ticket cannot become `Open` without affected user.
- `make prod-config` passes.
- Existing smoke test still passes.

## Risks

### Contact duplication

Same person can appear through email and Telegram as two contacts.

Mitigation:
- do not auto-merge in MVP;
- store identities separately;
- merge later only with manual review.

### Wrong database auto-selection

Default database may be wrong for a specific case.

Mitigation:
- auto-select only when there is exactly one known database;
- ask user when there are multiple databases.

### Confusing requester and affected user

Support case can be created under wrong person.

Mitigation:
- keep separate fields;
- store ticket snapshot;
- ask affected user explicitly when unclear.

### Overcomplicated UX

Bot may ask too many questions.

Mitigation:
- ask only missing variable context;
- never repeat verified contact data.

## Next Sprint

Sprint 7 — Hybrid Clarification.

Sprint 7 should use Sprint 6 rules and add extraction/clarification automation on top of this deterministic model.

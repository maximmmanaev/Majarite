import json
import os
import uuid
import urllib.error
import urllib.request
import urllib.parse
from email.utils import parseaddr
from typing import Any

import psycopg
from fastapi import FastAPI, Header, HTTPException, Request

APP_NAME = "majarite-email-intake-adapter"

DATABASE_URL = os.getenv("MAJORITE_DATABASE_URL", "")
WEBHOOK_TOKEN = os.getenv("EMAIL_WEBHOOK_TOKEN", "")

ZAMMAD_API_BASE_URL = os.getenv("ZAMMAD_API_BASE_URL", "").rstrip("/")
ZAMMAD_API_TOKEN = os.getenv("ZAMMAD_API_TOKEN", "")
ZAMMAD_DEFAULT_GROUP = os.getenv("ZAMMAD_DEFAULT_GROUP", "Users")
ZAMMAD_DEFAULT_CUSTOMER_EMAIL = os.getenv(
    "ZAMMAD_DEFAULT_CUSTOMER_EMAIL",
    "majarite-local-customer@example.com",
)
ZAMMAD_TICKET_BRIDGE_ENABLED = os.getenv(
    "ZAMMAD_TICKET_BRIDGE_ENABLED",
    "false",
).lower() in {"1", "true", "yes", "on"}

app = FastAPI(title=APP_NAME)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok", "service": APP_NAME}


def _first_text(*values: Any) -> str | None:
    for value in values:
        if value is None:
            continue
        value = str(value).strip()
        if value:
            return value
    return None


def normalize_zammad_payload(payload: dict[str, Any]) -> dict[str, Any]:
    ticket = payload.get("ticket") or {}
    article = payload.get("article") or payload.get("message") or {}

    sender = _first_text(
        article.get("from"),
        article.get("sender"),
        payload.get("from"),
        payload.get("sender"),
        ticket.get("customer"),
        ticket.get("customer_email"),
    )

    subject = _first_text(
        article.get("subject"),
        payload.get("subject"),
        ticket.get("title"),
        payload.get("title"),
    )

    body = _first_text(
        article.get("body"),
        article.get("content"),
        payload.get("body"),
        payload.get("text"),
        payload.get("content"),
    )

    attachments = (
        article.get("attachments")
        or payload.get("attachments")
        or ticket.get("attachments")
        or []
    )

    if not isinstance(attachments, list):
        attachments = []

    external_message_id = _first_text(
        article.get("message_id"),
        article.get("id"),
        payload.get("message_id"),
        payload.get("id"),
    )

    ticket_ref = _first_text(
        ticket.get("number"),
        ticket.get("id"),
        payload.get("ticket_id"),
        payload.get("ticket_number"),
    )

    thread_id = _first_text(
        ticket.get("id"),
        ticket.get("number"),
        article.get("in_reply_to"),
        payload.get("thread_id"),
        external_message_id,
    )

    correlation_id = _first_text(
        payload.get("correlation_id"),
        ticket_ref,
        thread_id,
        external_message_id,
        str(uuid.uuid4()),
    )

    return {
        "sender": sender,
        "subject": subject,
        "body": body,
        "attachments_count": len(attachments),
        "external_message_id": external_message_id,
        "thread_id": thread_id,
        "ticket_ref": ticket_ref,
        "correlation_id": correlation_id,
    }


def zammad_ticket_bridge_enabled() -> bool:
    if not ZAMMAD_TICKET_BRIDGE_ENABLED:
        return False

    if not ZAMMAD_API_TOKEN:
        return False

    blocked_prefixes = ("change-me", "replace-in-real-server-env")
    return not ZAMMAD_API_TOKEN.startswith(blocked_prefixes)


def zammad_request(method: str, path: str, payload: dict[str, Any] | None = None) -> Any:
    if not ZAMMAD_API_BASE_URL or not ZAMMAD_API_TOKEN:
        raise RuntimeError("Zammad API is not configured")

    data = None
    headers = {
        "Authorization": f"Token token={ZAMMAD_API_TOKEN}",
        "Content-Type": "application/json",
    }

    if payload is not None:
        data = json.dumps(payload, ensure_ascii=False).encode("utf-8")

    request = urllib.request.Request(
        f"{ZAMMAD_API_BASE_URL}{path}",
        data=data,
        headers=headers,
        method=method,
    )

    try:
        with urllib.request.urlopen(request, timeout=10) as response:
            body = response.read().decode("utf-8")
            if not body:
                return {}
            return json.loads(body)
    except urllib.error.HTTPError as error:
        error_body = error.read().decode("utf-8", errors="replace")
        raise RuntimeError(
            f"Zammad API error {error.code} for {method} {path}: {error_body}"
        ) from error


def find_zammad_customer(email: str) -> dict[str, Any] | None:
    if not email:
        return None

    query = urllib.parse.quote(email)
    result = zammad_request("GET", f"/users/search?query={query}")

    if isinstance(result, list) and result:
        return result[0]

    return None


def create_zammad_customer(email: str, name: str | None = None) -> dict[str, Any]:
    safe_name = name or email or ZAMMAD_DEFAULT_CUSTOMER_EMAIL
    parts = safe_name.split(" ", 1)

    payload = {
        "firstname": parts[0] or "Majarite",
        "lastname": parts[1] if len(parts) > 1 else "Customer",
        "email": email,
        "login": email,
        "roles": ["Customer"],
    }

    return zammad_request("POST", "/users", payload)


def get_or_create_zammad_customer(email: str, name: str | None = None) -> dict[str, Any]:
    customer = find_zammad_customer(email)
    if customer:
        return customer

    return create_zammad_customer(email, name)


def normalize_email_identity(value: str | None) -> str | None:
    if not value:
        return None

    _, parsed_email = parseaddr(str(value))
    identity = (parsed_email or str(value)).strip().lower()

    if "@" not in identity:
        return None

    return identity


def display_name_from_sender(sender: str | None, fallback_email: str) -> str:
    if not sender:
        return fallback_email

    parsed_name, _ = parseaddr(str(sender))
    parsed_name = parsed_name.strip()

    return parsed_name or fallback_email


def write_contact_event(
    cur: Any,
    event_type: str,
    entity_type: str,
    entity_id: str,
    correlation_id: str,
    payload: dict[str, Any],
) -> None:
    cur.execute(
        """
        INSERT INTO majorite_events (
          event_type,
          entity_type,
          entity_id,
          correlation_id,
          actor_type,
          actor_id,
          channel,
          payload_json
        )
        VALUES (
          %(event_type)s,
          %(entity_type)s,
          %(entity_id)s,
          %(correlation_id)s,
          'system',
          'email-intake-adapter',
          'email',
          %(payload_json)s::jsonb
        );
        """,
        {
            "event_type": event_type,
            "entity_type": entity_type,
            "entity_id": entity_id,
            "correlation_id": correlation_id,
            "payload_json": json.dumps(payload, ensure_ascii=False),
        },
    )


def get_or_create_email_contact(
    cur: Any,
    sender: str | None,
    correlation_id: str,
) -> dict[str, Any] | None:
    email_identity = normalize_email_identity(sender)

    if not email_identity:
        write_contact_event(
            cur,
            "contact_lookup_not_found",
            "contact_identity",
            "email:unknown",
            correlation_id,
            {"reason": "sender_email_missing", "sender": sender},
        )
        return None

    write_contact_event(
        cur,
        "contact_lookup_started",
        "contact_identity",
        f"email:{email_identity}",
        correlation_id,
        {"channel": "email", "identity_value": email_identity},
    )

    cur.execute(
        """
        SELECT
          c.contact_id::text,
          c.display_name,
          c.primary_email
        FROM contact_identities ci
        JOIN contacts c ON c.contact_id = ci.contact_id
        WHERE ci.channel = 'email'
          AND ci.identity_value = %(identity_value)s
        LIMIT 1;
        """,
        {"identity_value": email_identity},
    )

    row = cur.fetchone()

    if row:
        contact = {
            "contact_id": row[0],
            "display_name": row[1],
            "primary_email": row[2],
            "identity_value": email_identity,
        }
        write_contact_event(
            cur,
            "contact_lookup_matched",
            "contact",
            contact["contact_id"],
            correlation_id,
            contact,
        )
        return contact

    display_name = display_name_from_sender(sender, email_identity)

    cur.execute(
        """
        INSERT INTO contacts (
          display_name,
          primary_email
        )
        VALUES (
          %(display_name)s,
          %(primary_email)s
        )
        RETURNING contact_id::text;
        """,
        {
            "display_name": display_name,
            "primary_email": email_identity,
        },
    )

    contact_id = cur.fetchone()[0]

    cur.execute(
        """
        INSERT INTO contact_identities (
          contact_id,
          channel,
          identity_value,
          verified
        )
        VALUES (
          %(contact_id)s::uuid,
          'email',
          %(identity_value)s,
          true
        )
        ON CONFLICT (channel, identity_value) DO NOTHING;
        """,
        {
            "contact_id": contact_id,
            "identity_value": email_identity,
        },
    )

    contact = {
        "contact_id": contact_id,
        "display_name": display_name,
        "primary_email": email_identity,
        "identity_value": email_identity,
    }

    write_contact_event(
        cur,
        "contact_created",
        "contact",
        contact_id,
        correlation_id,
        contact,
    )
    write_contact_event(
        cur,
        "contact_identity_linked",
        "contact",
        contact_id,
        correlation_id,
        {"channel": "email", "identity_value": email_identity},
    )

    return contact


def get_single_contact_database(
    cur: Any,
    contact_id: str | None,
    correlation_id: str,
) -> dict[str, Any] | None:
    if not contact_id:
        return None

    cur.execute(
        """
        SELECT
          d.database_id::text,
          d.name
        FROM contact_databases cd
        JOIN cus_databases d ON d.database_id = cd.database_id
        WHERE cd.contact_id = %(contact_id)s::uuid
          AND d.active = true
        ORDER BY cd.is_default DESC, d.name ASC;
        """,
        {"contact_id": contact_id},
    )

    rows = cur.fetchall()

    if len(rows) == 1:
        database = {"database_id": rows[0][0], "database_name": rows[0][1]}
        write_contact_event(
            cur,
            "database_auto_selected",
            "cus_database",
            database["database_id"],
            correlation_id,
            database,
        )
        return database

    if len(rows) > 1:
        write_contact_event(
            cur,
            "database_selection_required",
            "contact",
            contact_id,
            correlation_id,
            {"reason": "multiple_databases", "databases_count": len(rows)},
        )
    else:
        write_contact_event(
            cur,
            "database_selection_required",
            "contact",
            contact_id,
            correlation_id,
            {"reason": "no_database"},
        )

    return None


def build_email_ticket_context(
    normalized: dict[str, Any],
    contact: dict[str, Any] | None,
    database: dict[str, Any] | None,
) -> dict[str, Any]:
    problem_summary = _first_text(normalized.get("subject"), normalized.get("body"))

    context = {
        "requester_contact_id": contact.get("contact_id") if contact else None,
        "requester_name": contact.get("display_name") if contact else normalized.get("sender"),
        "requester_email": (
            contact.get("primary_email")
            if contact
            else normalize_email_identity(normalized.get("sender"))
        ),
        "requester_channel": "email",
        "database_id": database.get("database_id") if database else None,
        "database_name": database.get("database_name") if database else None,
        "affected_user_name": None,
        "problem_summary": problem_summary,
    }

    missing_fields = []

    if not (context["requester_contact_id"] or context["requester_name"]):
        missing_fields.append("requester")
    if not context["requester_email"]:
        missing_fields.append("reply_path")
    if not context["database_name"]:
        missing_fields.append("database_name")
    if not context["affected_user_name"]:
        missing_fields.append("affected_user_name")
    if not context["problem_summary"]:
        missing_fields.append("problem_summary")

    context["missing_fields"] = missing_fields
    context["completeness_status"] = "complete" if not missing_fields else "incomplete"

    return context


def write_email_ticket_context_snapshot(
    cur: Any,
    message_id: str,
    normalized: dict[str, Any],
    contact: dict[str, Any] | None,
    database: dict[str, Any] | None,
) -> dict[str, Any]:
    context = build_email_ticket_context(normalized, contact, database)

    cur.execute(
        """
        INSERT INTO ticket_context_snapshots (
          ticket_ref,
          channel_message_id,
          requester_contact_id,
          requester_name,
          requester_email,
          requester_channel,
          database_id,
          database_name,
          affected_user_name,
          problem_summary,
          completeness_status,
          missing_fields,
          correlation_id,
          payload_json
        )
        VALUES (
          %(ticket_ref)s,
          %(channel_message_id)s::uuid,
          %(requester_contact_id)s::uuid,
          %(requester_name)s,
          %(requester_email)s,
          %(requester_channel)s,
          %(database_id)s::uuid,
          %(database_name)s,
          %(affected_user_name)s,
          %(problem_summary)s,
          %(completeness_status)s,
          %(missing_fields)s::jsonb,
          %(correlation_id)s,
          %(payload_json)s::jsonb
        )
        RETURNING snapshot_id::text;
        """,
        {
            **context,
            "ticket_ref": normalized.get("ticket_ref"),
            "channel_message_id": message_id,
            "correlation_id": normalized["correlation_id"],
            "missing_fields": json.dumps(context["missing_fields"], ensure_ascii=False),
            "payload_json": json.dumps({"context": context}, ensure_ascii=False),
        },
    )

    snapshot_id = cur.fetchone()[0]
    context["snapshot_id"] = snapshot_id

    event_type = (
        "ticket_context_completed"
        if context["completeness_status"] == "complete"
        else "ticket_context_incomplete"
    )

    write_contact_event(
        cur,
        event_type,
        "ticket_context_snapshot",
        snapshot_id,
        normalized["correlation_id"],
        context,
    )

    if "affected_user_name" in context["missing_fields"]:
        write_contact_event(
            cur,
            "affected_user_required",
            "ticket_context_snapshot",
            snapshot_id,
            normalized["correlation_id"],
            {"reason": "affected_user_missing"},
        )

    return context


def create_zammad_ticket_from_email(normalized: dict[str, Any]) -> dict[str, Any]:
    sender = normalized.get("sender") or ZAMMAD_DEFAULT_CUSTOMER_EMAIL
    subject = normalized.get("subject") or "Email request"
    body = normalized.get("body") or normalized.get("body_text") or subject

    customer = get_or_create_zammad_customer(sender, sender)

    payload = {
        "title": subject,
        "group": ZAMMAD_DEFAULT_GROUP,
        "customer_id": customer["id"],
        "article": {
            "subject": subject,
            "body": body,
            "type": "note",
            "internal": False,
        },
    }

    return zammad_request("POST", "/tickets", payload)


def write_email_event(payload: dict[str, Any]) -> dict[str, Any]:
    if not DATABASE_URL:
        raise RuntimeError("MAJORITE_DATABASE_URL is not configured")

    normalized = normalize_zammad_payload(payload)

    with psycopg.connect(DATABASE_URL) as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO channel_messages (
                  channel,
                  direction,
                  external_message_id,
                  thread_id,
                  ticket_ref,
                  contact_ref,
                  body_text,
                  attachments_count,
                  correlation_id,
                  payload_json
                )
                VALUES (
                  'email',
                  'inbound',
                  %(external_message_id)s,
                  %(thread_id)s,
                  %(ticket_ref)s,
                  %(sender)s,
                  %(body)s,
                  %(attachments_count)s,
                  %(correlation_id)s,
                  %(payload_json)s::jsonb
                )
                RETURNING message_id::text;
                """,
                {
                    **normalized,
                    "payload_json": json.dumps(payload, ensure_ascii=False),
                },
            )

            message_id = cur.fetchone()[0]

            contact = get_or_create_email_contact(
                cur,
                normalized.get("sender"),
                normalized["correlation_id"],
            )
            database = get_single_contact_database(
                cur,
                contact.get("contact_id") if contact else None,
                normalized["correlation_id"],
            )
            ticket_context = write_email_ticket_context_snapshot(
                cur,
                message_id,
                normalized,
                contact,
                database,
            )

            cur.execute(
                """
                INSERT INTO majorite_events (
                  event_type,
                  entity_type,
                  entity_id,
                  correlation_id,
                  actor_type,
                  actor_id,
                  channel,
                  payload_json
                )
                VALUES (
                  'email_received',
                  'channel_message',
                  %(message_id)s,
                  %(correlation_id)s,
                  'system',
                  'email-intake-adapter',
                  'email',
                  %(payload_json)s::jsonb
                );
                """,
                {
                    "message_id": message_id,
                    "correlation_id": normalized["correlation_id"],
                    "payload_json": json.dumps(
                        {
                            "normalized": normalized,
                            "contact": contact,
                            "ticket_context": ticket_context,
                        },
                        ensure_ascii=False,
                    ),
                },
            )

            ticket = None

            if zammad_ticket_bridge_enabled():
                ticket = create_zammad_ticket_from_email(normalized)
                ticket_ref = str(ticket.get("number") or ticket.get("id") or "")

                cur.execute(
                    """
                    UPDATE channel_messages
                    SET ticket_ref = %(ticket_ref)s
                    WHERE message_id = %(message_id)s::uuid;
                    """,
                    {
                        "ticket_ref": ticket_ref,
                        "message_id": message_id,
                    },
                )

                cur.execute(
                    """
                    INSERT INTO majorite_events (
                      event_type,
                      entity_type,
                      entity_id,
                      correlation_id,
                      actor_type,
                      actor_id,
                      channel,
                      payload_json
                    )
                    VALUES (
                      'ticket_created',
                      'zammad_ticket',
                      %(ticket_ref)s,
                      %(correlation_id)s,
                      'system',
                      'email-intake-adapter',
                      'email',
                      %(payload_json)s::jsonb
                    );
                    """,
                    {
                        "ticket_ref": ticket_ref,
                        "correlation_id": normalized["correlation_id"],
                        "payload_json": json.dumps(
                            {
                                "source_message_id": message_id,
                                "ticket": ticket,
                                "normalized": normalized,
                            },
                            ensure_ascii=False,
                        ),
                    },
                )

        conn.commit()

    return {"message_id": message_id, "normalized": normalized, "ticket": ticket}


@app.post("/webhooks/zammad/email")
async def zammad_email_webhook(
    request: Request,
    x_majarite_token: str | None = Header(default=None),
) -> dict[str, Any]:
    if WEBHOOK_TOKEN and x_majarite_token != WEBHOOK_TOKEN:
        raise HTTPException(status_code=401, detail="invalid webhook token")

    payload = await request.json()
    result = write_email_event(payload)

    return {
        "status": "accepted",
        "message_id": result["message_id"],
        "correlation_id": result["normalized"]["correlation_id"],
    }

import json
import os
import uuid
import urllib.error
import urllib.request
import urllib.parse
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
                        {"normalized": normalized},
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

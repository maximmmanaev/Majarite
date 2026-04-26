import json
import os
import uuid
from typing import Any

import psycopg
from fastapi import FastAPI, Header, HTTPException, Request

APP_NAME = "majarite-email-intake-adapter"

DATABASE_URL = os.getenv("MAJORITE_DATABASE_URL", "")
WEBHOOK_TOKEN = os.getenv("EMAIL_WEBHOOK_TOKEN", "")

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

        conn.commit()

    return {"message_id": message_id, "normalized": normalized}


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

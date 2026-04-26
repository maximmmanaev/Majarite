import json
import os
import uuid
from typing import Any

import psycopg
from fastapi import FastAPI, Header, HTTPException, Request

APP_NAME = "majarite-telegram-intake-adapter"

DATABASE_URL = os.getenv("MAJORITE_DATABASE_URL", "")
WEBHOOK_TOKEN = os.getenv("TELEGRAM_WEBHOOK_TOKEN", "")

app = FastAPI(title=APP_NAME)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok", "service": APP_NAME}


def normalize_telegram_payload(payload: dict[str, Any]) -> dict[str, Any]:
    message = payload.get("message") or payload.get("edited_message") or {}
    chat = message.get("chat") or {}
    sender = message.get("from") or {}

    chat_id = str(chat.get("id") or "")
    message_id = str(message.get("message_id") or payload.get("update_id") or "")
    username = sender.get("username")
    first_name = sender.get("first_name")
    last_name = sender.get("last_name")

    sender_name = " ".join([x for x in [first_name, last_name] if x]).strip()
    sender_ref = username or sender_name or str(sender.get("id") or "")

    text = (
        message.get("text")
        or message.get("caption")
        or ""
    )

    attachments_count = 0
    for key in ["photo", "document", "audio", "video", "voice", "sticker"]:
        if key in message:
            value = message.get(key)
            if isinstance(value, list):
                attachments_count += len(value)
            elif value:
                attachments_count += 1

    correlation_id = chat_id + ":" + message_id if chat_id and message_id else str(uuid.uuid4())

    return {
        "sender": sender_ref,
        "username": username,
        "chat_id": chat_id,
        "message_id": message_id,
        "text": text,
        "attachments_count": attachments_count,
        "thread_id": chat_id,
        "correlation_id": correlation_id,
    }


def write_telegram_event(payload: dict[str, Any]) -> dict[str, Any]:
    if not DATABASE_URL:
        raise RuntimeError("MAJORITE_DATABASE_URL is not configured")

    normalized = normalize_telegram_payload(payload)

    with psycopg.connect(DATABASE_URL) as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO channel_messages (
                  channel,
                  direction,
                  external_message_id,
                  thread_id,
                  contact_ref,
                  body_text,
                  attachments_count,
                  correlation_id,
                  payload_json
                )
                VALUES (
                  'telegram',
                  'inbound',
                  %(message_id)s,
                  %(thread_id)s,
                  %(sender)s,
                  %(text)s,
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

            db_message_id = cur.fetchone()[0]

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
                  'telegram_message_received',
                  'channel_message',
                  %(db_message_id)s,
                  %(correlation_id)s,
                  'system',
                  'telegram-intake-adapter',
                  'telegram',
                  %(payload_json)s::jsonb
                );
                """,
                {
                    "db_message_id": db_message_id,
                    "correlation_id": normalized["correlation_id"],
                    "payload_json": json.dumps(
                        {"normalized": normalized},
                        ensure_ascii=False,
                    ),
                },
            )

        conn.commit()

    return {"message_id": db_message_id, "normalized": normalized}


@app.post("/webhooks/telegram")
async def telegram_webhook(
    request: Request,
    x_majarite_token: str | None = Header(default=None),
) -> dict[str, Any]:
    if WEBHOOK_TOKEN and x_majarite_token != WEBHOOK_TOKEN:
        raise HTTPException(status_code=401, detail="invalid webhook token")

    payload = await request.json()
    result = write_telegram_event(payload)

    return {
        "status": "accepted",
        "message_id": result["message_id"],
        "correlation_id": result["normalized"]["correlation_id"],
    }

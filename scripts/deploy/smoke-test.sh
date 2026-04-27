#!/usr/bin/env bash
set -Eeuo pipefail

BASE_URL="${MAJARITE_BASE_URL:-http://localhost:8080}"
PROJECT_NAME="${MAJARITE_PROJECT_NAME:-majarite}"

echo "Majarite smoke test"
echo "BASE_URL=${BASE_URL}"
echo "PROJECT_NAME=${PROJECT_NAME}"
echo

fail() {
  echo "FAIL: $1"
  exit 1
}

ok() {
  echo "OK: $1"
}

echo "== 1. Docker containers =="
docker ps --filter "name=${PROJECT_NAME}-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo
echo "== 2. NGINX health =="
curl -fsS "${BASE_URL}/health" | grep -q "majarite-nginx-ok" \
  && ok "NGINX health endpoint" \
  || fail "NGINX health endpoint"

echo
echo "== 3. Zammad HTTP =="
HTTP_CODE="$(curl -s -o /dev/null -w "%{http_code}" "${BASE_URL}/")"
case "$HTTP_CODE" in
  200|302)
    ok "Zammad HTTP returned ${HTTP_CODE}"
    ;;
  *)
    fail "Zammad HTTP returned ${HTTP_CODE}"
    ;;
esac

echo
echo "== 4. Node-RED HTTP =="
HTTP_CODE="$(curl -s -o /dev/null -w "%{http_code}" "${BASE_URL}/node-red/")"
case "$HTTP_CODE" in
  200|302)
    ok "Node-RED HTTP returned ${HTTP_CODE}"
    ;;
  *)
    fail "Node-RED HTTP returned ${HTTP_CODE}"
    ;;
esac

echo
echo "== 5. Majorite PostgreSQL =="
docker exec "${PROJECT_NAME}-postgres-majorite" sh -lc 'pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB"' >/dev/null \
  && ok "Majorite PostgreSQL is ready" \
  || fail "Majorite PostgreSQL is not ready"

echo
echo "== 6. Zammad PostgreSQL =="
docker exec "${PROJECT_NAME}-postgres-zammad" sh -lc 'pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB"' >/dev/null \
  && ok "Zammad PostgreSQL is ready" \
  || fail "Zammad PostgreSQL is not ready"

echo
echo "== 7. Valkey =="
docker exec "${PROJECT_NAME}-valkey" valkey-cli ping | grep -q "PONG" \
  && ok "Valkey responds PONG" \
  || fail "Valkey does not respond PONG"

echo
echo "== 8. Majorite event store table =="
docker exec "${PROJECT_NAME}-postgres-majorite" sh -lc 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tAc "SELECT to_regclass('\''public.majorite_events'\'');"' \
  | grep -q "majorite_events" \
  && ok "majorite_events table exists" \
  || fail "majorite_events table missing"

echo
echo "== 9. Operational event tables =="
for table in channel_messages clarification_sessions notification_log integration_errors; do
  docker exec "${PROJECT_NAME}-postgres-majorite" sh -lc "psql -U \"\$POSTGRES_USER\" -d \"\$POSTGRES_DB\" -tAc \"SELECT to_regclass('public.${table}');\"" \
    | grep -q "${table}" \
    && ok "${table} table exists" \
    || fail "${table} table missing"
done

echo
echo "== 10. Contact resolution tables =="
for table in contacts contact_identities cus_databases contact_databases ticket_context_snapshots; do
  docker exec "${PROJECT_NAME}-postgres-majorite" sh -lc "psql -U \"\$POSTGRES_USER\" -d \"\$POSTGRES_DB\" -tAc \"SELECT to_regclass('public.${table}');\"" \
    | grep -q "${table}" \
    && ok "${table} table exists" \
    || fail "${table} table missing"
done

echo
echo "== 11. Test event write =="
TEST_ENTITY_ID="smoke-$(date +%s)"

docker exec "${PROJECT_NAME}-postgres-majorite" sh -lc "psql -U \"\$POSTGRES_USER\" -d \"\$POSTGRES_DB\" -v ON_ERROR_STOP=1 -tAc \"
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
  'smoke.test',
  'system',
  '${TEST_ENTITY_ID}',
  '${TEST_ENTITY_ID}',
  'system',
  'smoke-test',
  'internal',
  jsonb_build_object('source','smoke-test')
);
SELECT entity_id FROM majorite_events WHERE entity_id = '${TEST_ENTITY_ID}';
\"" | grep -q "${TEST_ENTITY_ID}" \
  && ok "test event written to majorite_events" \
  || fail "test event write failed"

echo
echo "== 12. Email adapter health =="
HTTP_CODE="$(curl -s -o /dev/null -w "%{http_code}" "${BASE_URL}/email-adapter/health")"
case "$HTTP_CODE" in
  200)
    ok "Email adapter health returned ${HTTP_CODE}"
    ;;
  *)
    fail "Email adapter health returned ${HTTP_CODE}"
    ;;
esac

echo
echo "== 13. Email webhook POST =="
EMAIL_WEBHOOK_RESPONSE="$(curl -s -X POST "${BASE_URL}/webhooks/zammad/email" \
  -H "Content-Type: application/json" \
  -H "X-Majarite-Token: change-me-dev-email-webhook-token" \
  --data-binary @tests/fixtures/email/zammad-email-webhook.json)"

echo "${EMAIL_WEBHOOK_RESPONSE}" | grep -q '"status":"accepted"' \
  && ok "Email webhook accepted fixture" \
  || fail "Email webhook did not accept fixture"

echo
echo "== 14. Email received event exists =="
docker exec "${PROJECT_NAME}-postgres-majorite" sh -lc "psql -U \"\$POSTGRES_USER\" -d \"\$POSTGRES_DB\" -tAc \"
SELECT event_type
FROM majorite_events
WHERE event_type = 'email_received'
ORDER BY created_at DESC
LIMIT 1;
\"" | grep -q "email_received" \
  && ok "email_received event exists" \
  || fail "email_received event missing"

echo
echo "== 15. Email channel message exists =="
docker exec "${PROJECT_NAME}-postgres-majorite" sh -lc "psql -U \"\$POSTGRES_USER\" -d \"\$POSTGRES_DB\" -tAc \"
SELECT channel
FROM channel_messages
WHERE channel = 'email'
ORDER BY created_at DESC
LIMIT 1;
\"" | grep -q "email" \
  && ok "email channel message exists" \
  || fail "email channel message missing"


echo
echo "== 16. Email contact resolution =="
docker exec "${PROJECT_NAME}-postgres-majorite" sh -lc "psql -U \"\$POSTGRES_USER\" -d \"\$POSTGRES_DB\" -tAc \"
SELECT count(*)
FROM contact_identities
WHERE channel = 'email';
\"" | grep -Eq "^[1-9][0-9]*$" \
  && ok "email contact identity exists" \
  || fail "email contact identity missing"

docker exec "${PROJECT_NAME}-postgres-majorite" sh -lc "psql -U \"\$POSTGRES_USER\" -d \"\$POSTGRES_DB\" -tAc \"
SELECT count(*)
FROM ticket_context_snapshots
WHERE requester_channel = 'email';
\"" | grep -Eq "^[1-9][0-9]*$" \
  && ok "email ticket context snapshot exists" \
  || fail "email ticket context snapshot missing"

echo
echo "== 17. Telegram adapter health =="
HTTP_CODE="$(curl -s -o /dev/null -w "%{http_code}" "${BASE_URL}/telegram-adapter/health")"
case "$HTTP_CODE" in
  200)
    ok "Telegram adapter health returned ${HTTP_CODE}"
    ;;
  *)
    fail "Telegram adapter health returned ${HTTP_CODE}"
    ;;
esac

echo
echo "== 18. Telegram webhook POST =="
TELEGRAM_WEBHOOK_RESPONSE="$(curl -s -X POST "${BASE_URL}/webhooks/telegram" \
  -H "Content-Type: application/json" \
  -H "X-Majarite-Token: change-me-dev-telegram-webhook-token" \
  --data-binary @tests/fixtures/telegram/telegram-message-webhook.json)"

echo "${TELEGRAM_WEBHOOK_RESPONSE}" | grep -q '"status":"accepted"' \
  && ok "Telegram webhook accepted fixture" \
  || fail "Telegram webhook did not accept fixture"

echo
echo "== 19. Telegram received event exists =="
docker exec "${PROJECT_NAME}-postgres-majorite" sh -lc "psql -U \"\$POSTGRES_USER\" -d \"\$POSTGRES_DB\" -tAc \"
SELECT event_type
FROM majorite_events
WHERE event_type = 'telegram_message_received'
ORDER BY created_at DESC
LIMIT 1;
\"" | grep -q "telegram_message_received" \
  && ok "telegram_message_received event exists" \
  || fail "telegram_message_received event missing"

echo
echo "== 20. Telegram channel message exists =="
docker exec "${PROJECT_NAME}-postgres-majorite" sh -lc "psql -U \"\$POSTGRES_USER\" -d \"\$POSTGRES_DB\" -tAc \"
SELECT channel
FROM channel_messages
WHERE channel = 'telegram'
ORDER BY created_at DESC
LIMIT 1;
\"" | grep -q "telegram" \
  && ok "telegram channel message exists" \
  || fail "telegram channel message missing"

if [ "${ZAMMAD_TICKET_BRIDGE_ENABLED:-false}" = "true" ]; then
  echo
  echo "== 21. Ticket bridge check =="

  docker exec "${PROJECT_NAME}-postgres-majorite" sh -lc "psql -U \"\$POSTGRES_USER\" -d \"\$POSTGRES_DB\" -tAc \"
SELECT ticket_ref
FROM channel_messages
WHERE channel IN ('email', 'telegram')
  AND ticket_ref IS NOT NULL
  AND ticket_ref <> ''
ORDER BY created_at DESC
LIMIT 1;
\"" | grep -Eq "^[0-9]+" \
    && ok "ticket bridge created linked Zammad ticket" \
    || fail "ticket bridge did not create linked Zammad ticket"

  docker exec "${PROJECT_NAME}-postgres-majorite" sh -lc "psql -U \"\$POSTGRES_USER\" -d \"\$POSTGRES_DB\" -tAc \"
SELECT event_type
FROM majorite_events
WHERE event_type = 'ticket_created'
ORDER BY created_at DESC
LIMIT 1;
\"" | grep -q "ticket_created" \
    && ok "ticket_created event exists" \
    || fail "ticket_created event missing"
else
  echo
  echo "== 21. Ticket bridge check =="
  ok "ticket bridge check skipped because ZAMMAD_TICKET_BRIDGE_ENABLED is not true"
fi

echo
echo "== 22. Public port exposure check =="
docker ps --filter "name=${PROJECT_NAME}-" --format "{{.Names}} {{.Ports}}" | tee /tmp/majarite-ports-check.txt

if grep -E "${PROJECT_NAME}-postgres|${PROJECT_NAME}-valkey" /tmp/majarite-ports-check.txt | grep -qE "0.0.0.0|::"; then
  fail "PostgreSQL or Valkey is publicly exposed"
else
  ok "PostgreSQL and Valkey are not publicly exposed"
fi

echo
echo "== Smoke test passed =="

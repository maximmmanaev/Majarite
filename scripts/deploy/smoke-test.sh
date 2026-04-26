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
echo "== 10. Test event write =="
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
  '{\"source\":\"smoke-test\"}'::jsonb
);
SELECT entity_id FROM majorite_events WHERE entity_id = '${TEST_ENTITY_ID}';
\"" | grep -q "${TEST_ENTITY_ID}" \
  && ok "test event written to majorite_events" \
  || fail "test event write failed"

echo
echo "== 11. Public port exposure check =="
docker ps --filter "name=${PROJECT_NAME}-" --format "{{.Names}} {{.Ports}}" | tee /tmp/majarite-ports-check.txt

if grep -E "${PROJECT_NAME}-postgres|${PROJECT_NAME}-valkey" /tmp/majarite-ports-check.txt | grep -qE "0.0.0.0|::"; then
  fail "PostgreSQL or Valkey is publicly exposed"
else
  ok "PostgreSQL and Valkey are not publicly exposed"
fi

echo
echo "== Smoke test passed =="

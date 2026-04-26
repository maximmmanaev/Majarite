CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS majorite_events (
  event_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_type TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  correlation_id TEXT NOT NULL,
  actor_type TEXT NOT NULL,
  actor_id TEXT,
  channel TEXT,
  payload_json JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_majorite_events_type_created
ON majorite_events(event_type, created_at);

CREATE INDEX IF NOT EXISTS idx_majorite_events_correlation
ON majorite_events(correlation_id);

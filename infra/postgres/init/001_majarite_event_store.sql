CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS majarite_events (
  event_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_type TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  correlation_id TEXT NOT NULL,
  actor_type TEXT NOT NULL,
  actor_id TEXT,
  channel TEXT,
  payload_json JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_majarite_events_type_created
ON majarite_events(event_type, created_at);

CREATE INDEX IF NOT EXISTS idx_majarite_events_correlation
ON majarite_events(correlation_id);

CREATE TABLE IF NOT EXISTS channel_messages (
  message_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  channel TEXT NOT NULL,
  direction TEXT NOT NULL,
  external_message_id TEXT,
  external_thread_id TEXT,
  zammad_ticket_id TEXT,
  contact_ref TEXT,
  body_text TEXT,
  attachments_count INTEGER NOT NULL DEFAULT 0,
  payload_json JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_channel_messages_channel_created
ON channel_messages(channel, created_at);

CREATE INDEX IF NOT EXISTS idx_channel_messages_ticket
ON channel_messages(zammad_ticket_id);

CREATE TABLE IF NOT EXISTS clarification_sessions (
  session_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  channel TEXT NOT NULL,
  external_thread_id TEXT NOT NULL,
  zammad_ticket_id TEXT,
  status TEXT NOT NULL DEFAULT 'active',
  attempts_count INTEGER NOT NULL DEFAULT 0,
  collected_fields_json JSONB NOT NULL DEFAULT '{}',
  missing_fields_json JSONB NOT NULL DEFAULT '[]',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_clarification_sessions_thread
ON clarification_sessions(channel, external_thread_id);

CREATE TABLE IF NOT EXISTS notification_log (
  notification_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  type TEXT NOT NULL,
  channel TEXT NOT NULL,
  target_ref TEXT NOT NULL,
  related_entity_type TEXT,
  related_entity_id TEXT,
  title TEXT NOT NULL,
  body TEXT,
  delivery_status TEXT NOT NULL DEFAULT 'queued',
  dedupe_key TEXT,
  payload_json JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  sent_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_notification_log_status_created
ON notification_log(delivery_status, created_at);

CREATE UNIQUE INDEX IF NOT EXISTS idx_notification_log_dedupe_key
ON notification_log(dedupe_key)
WHERE dedupe_key IS NOT NULL;

CREATE TABLE IF NOT EXISTS integration_errors (
  error_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  integration_name TEXT NOT NULL,
  error_type TEXT NOT NULL,
  error_message TEXT NOT NULL,
  correlation_id TEXT,
  payload_json JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_integration_errors_created
ON integration_errors(created_at);

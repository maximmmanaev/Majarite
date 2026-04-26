CREATE TABLE IF NOT EXISTS channel_messages (
  message_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  channel TEXT NOT NULL,
  direction TEXT NOT NULL DEFAULT 'inbound',
  external_message_id TEXT,
  thread_id TEXT,
  contact_ref TEXT,
  ticket_ref TEXT,
  body_text TEXT,
  attachments_count INTEGER NOT NULL DEFAULT 0,
  correlation_id TEXT NOT NULL,
  payload_json JSONB NOT NULL DEFAULT '{}'::jsonb,
  received_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_channel_messages_channel_created
ON channel_messages(channel, created_at);

CREATE INDEX IF NOT EXISTS idx_channel_messages_correlation
ON channel_messages(correlation_id);

CREATE TABLE IF NOT EXISTS clarification_sessions (
  session_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  channel TEXT NOT NULL,
  external_session_id TEXT NOT NULL,
  ticket_ref TEXT,
  status TEXT NOT NULL DEFAULT 'active',
  required_fields JSONB NOT NULL DEFAULT '[]'::jsonb,
  collected_fields JSONB NOT NULL DEFAULT '{}'::jsonb,
  missing_fields JSONB NOT NULL DEFAULT '[]'::jsonb,
  attempts_count INTEGER NOT NULL DEFAULT 0,
  max_attempts INTEGER NOT NULL DEFAULT 3,
  correlation_id TEXT NOT NULL,
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  closed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_clarification_sessions_external
ON clarification_sessions(channel, external_session_id);

CREATE INDEX IF NOT EXISTS idx_clarification_sessions_status
ON clarification_sessions(status, updated_at);

CREATE TABLE IF NOT EXISTS notification_log (
  notification_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  type TEXT NOT NULL,
  channel TEXT NOT NULL,
  target_ref TEXT NOT NULL,
  related_entity_type TEXT,
  related_entity_id TEXT,
  title TEXT NOT NULL,
  body TEXT,
  dedupe_key TEXT,
  delivery_status TEXT NOT NULL DEFAULT 'queued',
  payload_json JSONB NOT NULL DEFAULT '{}'::jsonb,
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
  integration TEXT NOT NULL,
  operation TEXT NOT NULL,
  severity TEXT NOT NULL DEFAULT 'error',
  error_message TEXT NOT NULL,
  correlation_id TEXT,
  entity_type TEXT,
  entity_id TEXT,
  payload_json JSONB NOT NULL DEFAULT '{}'::jsonb,
  resolved BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  resolved_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_integration_errors_integration_created
ON integration_errors(integration, created_at);

CREATE INDEX IF NOT EXISTS idx_integration_errors_unresolved
ON integration_errors(resolved, created_at);

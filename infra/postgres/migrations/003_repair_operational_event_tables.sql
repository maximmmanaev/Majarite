ALTER TABLE channel_messages
  ADD COLUMN IF NOT EXISTS thread_id TEXT,
  ADD COLUMN IF NOT EXISTS ticket_ref TEXT,
  ADD COLUMN IF NOT EXISTS correlation_id TEXT,
  ADD COLUMN IF NOT EXISTS received_at TIMESTAMPTZ DEFAULT now();

UPDATE channel_messages
SET thread_id = COALESCE(thread_id, external_thread_id)
WHERE thread_id IS NULL AND external_thread_id IS NOT NULL;

UPDATE channel_messages
SET ticket_ref = COALESCE(ticket_ref, zammad_ticket_id)
WHERE ticket_ref IS NULL AND zammad_ticket_id IS NOT NULL;

UPDATE channel_messages
SET correlation_id = COALESCE(correlation_id, 'legacy-message-' || message_id::text)
WHERE correlation_id IS NULL;

ALTER TABLE channel_messages
  ALTER COLUMN correlation_id SET NOT NULL,
  ALTER COLUMN received_at SET NOT NULL;

CREATE INDEX IF NOT EXISTS idx_channel_messages_correlation
ON channel_messages(correlation_id);

CREATE TABLE IF NOT EXISTS clarification_sessions (
  session_id UUID PRIMARY KEY DEFAULT uuid_generate_v4()
);

ALTER TABLE clarification_sessions
  ADD COLUMN IF NOT EXISTS external_session_id TEXT,
  ADD COLUMN IF NOT EXISTS ticket_ref TEXT,
  ADD COLUMN IF NOT EXISTS required_fields JSONB DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS collected_fields JSONB DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS missing_fields JSONB DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS max_attempts INTEGER DEFAULT 3,
  ADD COLUMN IF NOT EXISTS correlation_id TEXT,
  ADD COLUMN IF NOT EXISTS started_at TIMESTAMPTZ DEFAULT now(),
  ADD COLUMN IF NOT EXISTS closed_at TIMESTAMPTZ;

UPDATE clarification_sessions
SET external_session_id = COALESCE(external_session_id, external_thread_id)
WHERE external_session_id IS NULL AND external_thread_id IS NOT NULL;

UPDATE clarification_sessions
SET ticket_ref = COALESCE(ticket_ref, zammad_ticket_id)
WHERE ticket_ref IS NULL AND zammad_ticket_id IS NOT NULL;

UPDATE clarification_sessions
SET collected_fields = COALESCE(collected_fields, collected_fields_json, '{}'::jsonb)
WHERE collected_fields IS NULL;

UPDATE clarification_sessions
SET missing_fields = COALESCE(missing_fields, missing_fields_json, '[]'::jsonb)
WHERE missing_fields IS NULL;

UPDATE clarification_sessions
SET required_fields = COALESCE(required_fields, '[]'::jsonb)
WHERE required_fields IS NULL;

UPDATE clarification_sessions
SET max_attempts = COALESCE(max_attempts, 3)
WHERE max_attempts IS NULL;

UPDATE clarification_sessions
SET started_at = COALESCE(started_at, created_at, now())
WHERE started_at IS NULL;

UPDATE clarification_sessions
SET external_session_id = COALESCE(external_session_id, 'legacy-session-' || session_id::text)
WHERE external_session_id IS NULL;

UPDATE clarification_sessions
SET correlation_id = COALESCE(correlation_id, 'legacy-clarification-' || session_id::text)
WHERE correlation_id IS NULL;

ALTER TABLE clarification_sessions
  ALTER COLUMN external_session_id SET NOT NULL,
  ALTER COLUMN required_fields SET NOT NULL,
  ALTER COLUMN collected_fields SET NOT NULL,
  ALTER COLUMN missing_fields SET NOT NULL,
  ALTER COLUMN max_attempts SET NOT NULL,
  ALTER COLUMN correlation_id SET NOT NULL,
  ALTER COLUMN started_at SET NOT NULL;

CREATE INDEX IF NOT EXISTS idx_clarification_sessions_external
ON clarification_sessions(channel, external_session_id);

CREATE INDEX IF NOT EXISTS idx_clarification_sessions_status
ON clarification_sessions(status, updated_at);

ALTER TABLE integration_errors
  ADD COLUMN IF NOT EXISTS integration TEXT,
  ADD COLUMN IF NOT EXISTS operation TEXT,
  ADD COLUMN IF NOT EXISTS severity TEXT DEFAULT 'error',
  ADD COLUMN IF NOT EXISTS entity_type TEXT,
  ADD COLUMN IF NOT EXISTS entity_id TEXT,
  ADD COLUMN IF NOT EXISTS resolved BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS resolved_at TIMESTAMPTZ;

UPDATE integration_errors
SET integration = COALESCE(integration, integration_name)
WHERE integration IS NULL AND integration_name IS NOT NULL;

UPDATE integration_errors
SET operation = COALESCE(operation, error_type)
WHERE operation IS NULL AND error_type IS NOT NULL;

UPDATE integration_errors
SET severity = COALESCE(severity, 'error')
WHERE severity IS NULL;

UPDATE integration_errors
SET resolved = COALESCE(resolved, false)
WHERE resolved IS NULL;

UPDATE integration_errors
SET integration = COALESCE(integration, 'unknown')
WHERE integration IS NULL;

UPDATE integration_errors
SET operation = COALESCE(operation, 'unknown')
WHERE operation IS NULL;

ALTER TABLE integration_errors
  ALTER COLUMN integration SET NOT NULL,
  ALTER COLUMN operation SET NOT NULL,
  ALTER COLUMN severity SET NOT NULL,
  ALTER COLUMN resolved SET NOT NULL;

CREATE INDEX IF NOT EXISTS idx_integration_errors_integration_created
ON integration_errors(integration, created_at);

CREATE INDEX IF NOT EXISTS idx_integration_errors_unresolved
ON integration_errors(resolved, created_at);

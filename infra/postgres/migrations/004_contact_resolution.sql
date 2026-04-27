CREATE TABLE IF NOT EXISTS contacts (
  contact_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  display_name TEXT,
  primary_email TEXT,
  primary_phone TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS contact_identities (
  identity_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  contact_id UUID NOT NULL REFERENCES contacts(contact_id) ON DELETE CASCADE,
  channel TEXT NOT NULL,
  identity_value TEXT NOT NULL,
  verified BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(channel, identity_value)
);

CREATE TABLE IF NOT EXISTS cus_databases (
  database_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  external_code TEXT,
  active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(name)
);

CREATE TABLE IF NOT EXISTS contact_databases (
  contact_id UUID NOT NULL REFERENCES contacts(contact_id) ON DELETE CASCADE,
  database_id UUID NOT NULL REFERENCES cus_databases(database_id) ON DELETE CASCADE,
  is_default BOOLEAN NOT NULL DEFAULT false,
  role TEXT,
  comment TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (contact_id, database_id)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_contact_databases_one_default
ON contact_databases(contact_id)
WHERE is_default = true;

CREATE TABLE IF NOT EXISTS ticket_context_snapshots (
  snapshot_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  ticket_ref TEXT,
  channel_message_id UUID REFERENCES channel_messages(message_id) ON DELETE SET NULL,
  requester_contact_id UUID REFERENCES contacts(contact_id) ON DELETE SET NULL,
  requester_name TEXT,
  requester_email TEXT,
  requester_channel TEXT NOT NULL,
  database_id UUID REFERENCES cus_databases(database_id) ON DELETE SET NULL,
  database_name TEXT,
  affected_user_name TEXT,
  problem_summary TEXT,
  completeness_status TEXT NOT NULL DEFAULT 'incomplete',
  missing_fields JSONB NOT NULL DEFAULT '[]'::jsonb,
  correlation_id TEXT NOT NULL,
  payload_json JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_contact_identities_contact
ON contact_identities(contact_id);

CREATE INDEX IF NOT EXISTS idx_ticket_context_snapshots_ticket
ON ticket_context_snapshots(ticket_ref);

CREATE INDEX IF NOT EXISTS idx_ticket_context_snapshots_correlation
ON ticket_context_snapshots(correlation_id);

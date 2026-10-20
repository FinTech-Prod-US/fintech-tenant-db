-- Public website chat. Applied by apply-postgres.py to ${DB_NAME_POSTGRES}.
-- Schema name comes from tenants/<tenant>/metadata.yaml → postgres_schemas.website_chat.
-- Role name is tenant-prefixed because Postgres roles are cluster-wide.
-- Copied from copilot-api/migrations/002_website_chat.sql (idempotent).
-- Password is set per environment via SOPS, not in this file:
--   ALTER ROLE ${PG_ROLE_WEBSITE_CHAT} LOGIN PASSWORD '<from secrets>';

CREATE SCHEMA IF NOT EXISTS ${SCHEMA_WEBSITE_CHAT};

CREATE TABLE IF NOT EXISTS ${SCHEMA_WEBSITE_CHAT}.product_docs (
  id          text         PRIMARY KEY,
  source      text         NOT NULL CHECK (source IN ('website', 'product_pdf')),
  section     text         NOT NULL,
  content     text         NOT NULL,
  embedding   vector(1024) NOT NULL,
  metadata    jsonb        NOT NULL DEFAULT '{}'::jsonb,
  created_at  timestamptz  NOT NULL DEFAULT now(),
  updated_at  timestamptz  NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS product_docs_embedding_hnsw
  ON ${SCHEMA_WEBSITE_CHAT}.product_docs USING hnsw (embedding vector_l2_ops);

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '${PG_ROLE_WEBSITE_CHAT}') THEN
    EXECUTE format(
      'CREATE ROLE %I NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOREPLICATION CONNECTION LIMIT 20',
      '${PG_ROLE_WEBSITE_CHAT}'
    );
  END IF;
END
$$;

DO $$
BEGIN
  EXECUTE format(
    'GRANT CONNECT ON DATABASE %I TO %I',
    current_database(),
    '${PG_ROLE_WEBSITE_CHAT}'
  );
END
$$;

DO $$
BEGIN
  EXECUTE format('GRANT USAGE ON SCHEMA %I TO %I', '${SCHEMA_WEBSITE_CHAT}', '${PG_ROLE_WEBSITE_CHAT}');
  EXECUTE format('GRANT SELECT ON %I.product_docs TO %I', '${SCHEMA_WEBSITE_CHAT}', '${PG_ROLE_WEBSITE_CHAT}');
  EXECUTE format('ALTER ROLE %I SET default_transaction_read_only = on', '${PG_ROLE_WEBSITE_CHAT}');
  EXECUTE format('ALTER ROLE %I SET statement_timeout = %L', '${PG_ROLE_WEBSITE_CHAT}', '3s');
  EXECUTE format('ALTER ROLE %I SET search_path = %I, public', '${PG_ROLE_WEBSITE_CHAT}', '${SCHEMA_WEBSITE_CHAT}');
END
$$;

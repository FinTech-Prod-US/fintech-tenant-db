-- ============================================================================
-- WEBSITE CHAT — public product knowledge for the marketing-page chatbot
-- Engine: PostgreSQL 15 + pgvector. NOT MySQL: tools/render-db.py and
--         tools/apply-db.py do not read this folder (see postgres/README.md).
-- Run against: the ClearPilot Postgres database (same DB as clearpilot.*)
--   psql "$PG_ADMIN_URL" -v ON_ERROR_STOP=1 -f postgres/clearpilot/02_website_chat.sql
--
-- Creates the website_chat schema and product_docs table read by the public
-- website chat service (copilot-api src/public), and website_chat_reader: a
-- role that can SELECT that one table and nothing else. Kept apart from
-- clearpilot.* on purpose, so the unauthenticated public service's database
-- user can never read the internal copilot's data. Rows are loaded by
-- copilot-api's `npm run rag:ingest-public`, never by this file.
--
-- The role is created NOLOGIN. Its password is NEVER in this repo: enable login
-- per environment out of band, with the password taken from
-- fintech-tenant-config secrets (SOPS), e.g.
--   psql "$PG_ADMIN_URL" -v ON_ERROR_STOP=1 -v pw="$WEBSITE_CHAT_READER_PASSWORD" \
--     -c "ALTER ROLE website_chat_reader LOGIN PASSWORD :'pw'"
--
-- Copied from copilot-api/migrations/002_website_chat.sql (copilot-api PR #9).
-- The service repo keeps its copy (applied by its `npm run db:migrate` runner,
-- checksum-tracked in clearpilot.schema_migrations) to upgrade existing
-- environments; this file is what new environments get at creation time. The
-- DDL below is identical to the service copy.
--
-- Idempotent on purpose: IF NOT EXISTS / existence checks throughout, and
-- GRANT and ALTER ROLE SET are safe to repeat, so it is a no-op on a database
-- that already ran the service migration.
--
-- Requires: 01_rag_documents.sql (CREATE EXTENSION vector) and an admin role
-- with CREATEROLE.
-- ============================================================================

CREATE SCHEMA IF NOT EXISTS website_chat;

CREATE TABLE IF NOT EXISTS website_chat.product_docs (
  id          text         PRIMARY KEY,                 -- e.g. product_pdf:is-accs-soc-2-certified
  source      text         NOT NULL CHECK (source IN ('website', 'product_pdf')),
  section     text         NOT NULL,                    -- the "## " heading in public-content/*.md
  content     text         NOT NULL,
  embedding   vector(1024) NOT NULL,                    -- amazon.titan-embed-text-v2:0, 1024 dims
  metadata    jsonb        NOT NULL DEFAULT '{}'::jsonb,
  created_at  timestamptz  NOT NULL DEFAULT now(),
  updated_at  timestamptz  NOT NULL DEFAULT now()
);

-- L2, same metric as clearpilot.rag_documents. No collection filter here, so no iterative_scan needed.
CREATE INDEX IF NOT EXISTS product_docs_embedding_hnsw
  ON website_chat.product_docs USING hnsw (embedding vector_l2_ops);

-- Read-only role for the public service (no password here — see header).
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'website_chat_reader') THEN
    CREATE ROLE website_chat_reader NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOREPLICATION
      CONNECTION LIMIT 20;
  END IF;
END
$$;

DO $$
BEGIN
  EXECUTE format('GRANT CONNECT ON DATABASE %I TO website_chat_reader', current_database());
END
$$;

GRANT USAGE ON SCHEMA website_chat TO website_chat_reader;
GRANT SELECT ON website_chat.product_docs TO website_chat_reader;

-- Belt and braces on top of the grants: every transaction is read-only and short.
ALTER ROLE website_chat_reader SET default_transaction_read_only = on;
ALTER ROLE website_chat_reader SET statement_timeout = '3s';
ALTER ROLE website_chat_reader SET search_path = website_chat, public;

-- ============================================================================
-- CLEARPILOT RAG STORE — clearpilot.rag_documents (pgvector)
-- Engine: PostgreSQL 15 + pgvector. NOT MySQL: tools/render-db.py and
--         tools/apply-db.py do not read this folder (see postgres/README.md).
-- Run against: the ClearPilot Postgres database
--   psql "$PG_ADMIN_URL" -v ON_ERROR_STOP=1 -f postgres/clearpilot/01_rag_documents.sql
--
-- RAG documents for the internal ClearPilot copilot (copilot-api), which reads
-- them by vector similarity. Replaced the ChromaDB collections accs_knowledge_v2
-- and accs_product_qa_v2. Rows are loaded by copilot-api's `npm run rag:ingest`,
-- never by this file.
--
-- Copied from copilot-api/migrations/001_rag_documents.sql. The service repo
-- keeps its copy (applied by its `npm run db:migrate` runner, which records a
-- checksum in clearpilot.schema_migrations) to upgrade existing environments;
-- this file is what new environments get at creation time. The DDL below is
-- identical to the service copy.
--
-- Idempotent on purpose: every statement is IF NOT EXISTS, so it is a no-op on
-- a database that already ran the service migration.
--
-- Requires: an admin role allowed to CREATE EXTENSION vector (the pgvector
-- package must be installed on the server).
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS vector;

CREATE SCHEMA IF NOT EXISTS clearpilot;

CREATE TABLE IF NOT EXISTS clearpilot.rag_documents (
  collection  text         NOT NULL,                 -- 'accs_knowledge' | 'accs_product_qa'
  id          text         NOT NULL,                 -- same IDs as Chroma: exc_001, product_qa_001, ...
  content     text         NOT NULL,
  embedding   vector(1024) NOT NULL,                 -- amazon.titan-embed-text-v2:0, 1024 dims
  metadata    jsonb        NOT NULL DEFAULT '{}'::jsonb,
  source      text         NOT NULL,                 -- file the document came from
  created_at  timestamptz  NOT NULL DEFAULT now(),
  updated_at  timestamptz  NOT NULL DEFAULT now(),
  PRIMARY KEY (collection, id)
);

-- L2 distance, same as the Chroma collections (hnsw:space = l2), so rankings match.
-- Queries filter by collection, so readers must set hnsw.iterative_scan (see
-- copilot-api src/config/vector-db.ts) or a filtered search can return fewer
-- than the requested number of rows.
CREATE INDEX IF NOT EXISTS rag_documents_embedding_hnsw
  ON clearpilot.rag_documents USING hnsw (embedding vector_l2_ops);

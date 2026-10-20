-- ClearPilot RAG store. Applied by apply-postgres.py to ${DB_NAME_POSTGRES}.
-- Copied from copilot-api/migrations/001_rag_documents.sql (idempotent).

CREATE EXTENSION IF NOT EXISTS vector;

CREATE SCHEMA IF NOT EXISTS clearpilot;

CREATE TABLE IF NOT EXISTS clearpilot.rag_documents (
  collection  text         NOT NULL,
  id          text         NOT NULL,
  content     text         NOT NULL,
  embedding   vector(1024) NOT NULL,
  metadata    jsonb        NOT NULL DEFAULT '{}'::jsonb,
  source      text         NOT NULL,
  created_at  timestamptz  NOT NULL DEFAULT now(),
  updated_at  timestamptz  NOT NULL DEFAULT now(),
  PRIMARY KEY (collection, id)
);

CREATE INDEX IF NOT EXISTS rag_documents_embedding_hnsw
  ON clearpilot.rag_documents USING hnsw (embedding vector_l2_ops);

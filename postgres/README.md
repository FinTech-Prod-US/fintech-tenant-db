# Postgres DDL

PostgreSQL (+ pgvector) schema for the ACCS AI services. Everything else in this
repo is MySQL; this folder is deliberately kept outside `schema/`.

```text
postgres/
└── clearpilot/                 # the ClearPilot Postgres database
    ├── 01_rag_documents.sql    # clearpilot.rag_documents — internal ClearPilot copilot RAG
    └── 02_website_chat.sql     # website_chat.product_docs + website_chat_reader role — public website chat
```

## Not part of render-db.py / apply-db.py

`tools/render-db.py` and `tools/apply-db.py` only read `schema/` and `tenants/`,
render `${DB_NAME_*}` placeholders, and execute the result against **MySQL**.
They never see this folder, which is why it lives here: a Postgres file under
`schema/` would be sent to MySQL and break every tenant's apply. These files use
no placeholders and are applied with `psql`.

## Applying

Run in order, as an admin role that can `CREATE EXTENSION` (pgvector must be
installed on the server) and `CREATE ROLE`. The admin connection string comes
from your secret store, never from this repo:

```bash
psql "$PG_ADMIN_URL" -v ON_ERROR_STOP=1 -f postgres/clearpilot/01_rag_documents.sql
psql "$PG_ADMIN_URL" -v ON_ERROR_STOP=1 -f postgres/clearpilot/02_website_chat.sql
```

Every file is idempotent (`IF NOT EXISTS`, existence checks, repeatable `GRANT`
and `ALTER ROLE ... SET`), so it is safe to run on a database that already has
the objects, including one migrated by copilot-api's own runner.

Then, per environment, enable login for the public chat service's read-only role
with a password from fintech-tenant-config (SOPS-encrypted secrets):

```bash
psql "$PG_ADMIN_URL" -v ON_ERROR_STOP=1 -v pw="$WEBSITE_CHAT_READER_PASSWORD" \
  -c "ALTER ROLE website_chat_reader LOGIN PASSWORD :'pw'"
```

Check the role from copilot-api: `npm run db:verify-public-reader` (it must be
able to read `website_chat.product_docs` and nothing else).

## Passwords and connection strings

Never in this repo. Database passwords and connection strings (`PG_URL`,
`PUBLIC_PG_URL`) live in **fintech-tenant-config**, SOPS-encrypted per tenant
and environment (e.g. `tenants/<tenant>/<env>/copilot-api/secrets.json`).

## Relationship with copilot-api

These files are copies of `copilot-api/migrations/*.sql`, with identical DDL.
copilot-api keeps its own copies and its `npm run db:migrate` runner (checksums
recorded in `clearpilot.schema_migrations`) to upgrade existing environments on
its deploy cycle; this folder is what new environments get at creation time,
following the same boundary as the MySQL files described in the top-level README.
When copilot-api adds a migration that new environments need, copy it here as
the next numbered file.

Data is not part of this repo: RAG rows are loaded by copilot-api
(`npm run rag:ingest`, `npm run rag:ingest-public`).

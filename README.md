# Fintech Tenant Database

Git-backed source of truth for per-tenant, per-database schema and seed data.

MySQL and Postgres are sibling trees so each apply tool only reads its own engine.
Database names are always tenant-prefixed (`mcb_check_payment_platform`, `mcb_clearpilot`).

## Repository layout

```text
fintech-tenant-db/
├── README.md
├── mysql/                         # MySQL schema + shared seed (applied by apply-db.py)
│   ├── primary/                   # was check_payment_platform
│   │   ├── 01_schema.sql
│   │   ├── 02_seed.sql
│   │   └── 03_master_seed.sql
│   ├── business_rules/
│   ├── dup_detect/
│   ├── accs/                      # accs-server database
│   └── shared/                    # users, grants, cross-db references
│       └── 01_users_seed.sql
├── postgres/                      # Postgres schema (applied by apply-postgres.py)
│   └── clearpilot/
│       ├── 01_rag_documents.sql
│       └── 02_website_chat.sql
├── tenants/
│   └── mcb/                       # tenant-specific seed/overrides
│       ├── metadata.yaml          # db_names including postgres: mcb_clearpilot
│       └── primary/
│           └── 01_tenant_seed.sql
└── tools/
    ├── render-db.py               # substitute ${DB_NAME_*} and ${PG_ROLE_*} placeholders
    ├── apply-db.py                # execute rendered mysql/ + tenant/ against MySQL
    ├── apply-postgres.py          # execute rendered postgres/ against Postgres
    └── migrate-from-services.py   # one-time import from service repos
```

## Database name placeholders

SQL files use placeholders that are substituted at render time:

| Placeholder | Logical DB | Example for `mcb` tenant |
|---|---|---|
| `${DB_NAME_PRIMARY}` | `check_payment_platform` | `mcb_check_payment_platform` |
| `${DB_NAME_BUSINESS_RULES}` | `business_rules` | `mcb_business_rules` |
| `${DB_NAME_DUP_DETECT}` | `dup_detect` | `mcb_dup_detect` |
| `${DB_NAME_ACCS}` | `accs` / cheque_clearing | `mcb_check_payment_platform` |
| `${DB_NAME_POSTGRES}` | ClearPilot / website chat | `mcb_clearpilot` |
| `${PG_ROLE_WEBSITE_CHAT}` | public-chat reader role | `mcb_website_chat_reader` |

## Workflow

### Render for a tenant

```bash
python tools/render-db.py --tenant mcb --output ./rendered/mcb
```

db_names are read from `tenants/<tenant>/metadata.yaml`. This produces
`rendered/mcb/mysql`, `rendered/mcb/postgres` (when `db_names.postgres` is set),
and `rendered/mcb/tenant`.

### Apply to MySQL

```bash
python tools/apply-db.py --rendered-dir ./rendered/mcb \
  --mysql-host localhost --mysql-user root --mysql-password password
```

### Apply to Postgres

```bash
python tools/apply-postgres.py --rendered-dir ./rendered/mcb \
  --pg-host localhost --pg-port 5432 \
  --pg-user postgres --pg-password password \
  --pg-database mcb_clearpilot
```

Onboard creates `mcb_clearpilot` if it is missing. copilot-api `PG_URL` must
point at that tenant-prefixed database, not the cluster default named `postgres`.

## Adding a new tenant

1. Copy `tenants/mcb` to `tenants/<new-tenant>`.
2. Update `tenants/<new-tenant>/metadata.yaml` so every `db_names` value uses the tenant prefix.
3. Add tenant-specific seed files under `tenants/<new-tenant>/{db}/`.
4. Run `render-db.py`, then `apply-db.py` and `apply-postgres.py`.

## Boundary with service runtime migrations

This repo owns **initial schema and reference seed data** for tenant onboarding.

Runtime schema migrations managed by Flyway/Liquibase inside each service repo
(e.g., `src/main/resources/db/migration/V1__*.sql`) are intentionally kept in
the service repos because they follow the service deployment lifecycle.

ClearPilot SQL here is copied from `copilot-api/migrations/` so Jenkins can
create the tenant-prefixed Postgres database without running npm.

If a migration is generic enough to be needed at tenant creation, it should be
copied here as a numbered file under `mysql/` or `postgres/`.

## Multi-tenant model

Shared MySQL host with prefixed databases:

```text
mcb_check_payment_platform
mcb_business_rules
mcb_dup_detect
```

Shared Postgres host with prefixed databases and roles:

```text
mcb_clearpilot
mcb_website_chat_reader
```

This matches the `DB_NAME_*` variables defined in `fintech-tenant-config`.

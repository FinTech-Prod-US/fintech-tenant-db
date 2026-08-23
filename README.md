# Fintech Tenant Database

Git-backed source of truth for per-tenant, per-database schema and seed data.

## Repository layout

```text
fintech-tenant-db/
├── README.md
├── schema/                        # canonical schema + shared seed
│   ├── primary/                   # was check_payment_platform
│   │   ├── 01_schema.sql
│   │   ├── 02_seed.sql
│   │   └── 03_master_seed.sql
│   ├── business_rules/
│   │   ├── 01_schema.sql
│   │   ├── 02_seed.sql
│   │   └── ...
│   ├── dup_detect/
│   │   ├── 01_schema.sql
│   │   └── 02_seed.sql
│   ├── accs/                      # accs-server database
│   └── shared/                    # users, grants, cross-db references
│       └── 01_users_seed.sql
├── tenants/
│   └── mcb/                       # tenant-specific seed/overrides
│       ├── metadata.yaml
│       └── primary/
│           └── 01_tenant_seed.sql
└── tools/
    ├── render-db.py               # substitute ${DB_NAME_*} placeholders
    ├── apply-db.py                # execute rendered SQL against MySQL
    └── migrate-from-services.py   # one-time import from service repos
```

## Database name placeholders

SQL files use placeholders that are substituted at render time:

| Placeholder | Logical DB | Example for `mcb` tenant |
|---|---|---|
| `${DB_NAME_PRIMARY}` | `check_payment_platform` | `mcb_check_payment_platform` |
| `${DB_NAME_BUSINESS_RULES}` | `business_rules` | `mcb_business_rules` |
| `${DB_NAME_DUP_DETECT}` | `dup_detect` | `mcb_dup_detect` |
| `${DB_NAME_ACCS}` | `accs` / cheque_clearing | `mcb_accs` |

## Workflow

### Render for a tenant

```bash
python tools/render-db.py --tenant mcb \
  --db-name-primary mcb_check_payment_platform \
  --db-name-business-rules mcb_business_rules \
  --db-name-dup-detect mcb_dup_detect \
  --output ./rendered/mcb
```

This produces a rendered tree under `rendered/mcb/` with all placeholders replaced.

### Apply to MySQL

```bash
python tools/apply-db.py --rendered-dir ./rendered/mcb \
  --mysql-host localhost --mysql-user root --mysql-password password
```

## Adding a new tenant

1. Copy `tenants/mcb` to `tenants/<new-tenant>`.
2. Update `tenants/<new-tenant>/metadata.yaml`.
3. Add tenant-specific seed files under `tenants/<new-tenant>/{db}/`.
4. Run `render-db.py` and `apply-db.py`.

## Boundary with service runtime migrations

This repo owns **initial schema and reference seed data** for tenant onboarding.

Runtime schema migrations managed by Flyway/Liquibase inside each service repo
(e.g., `src/main/resources/db/migration/V1__*.sql`) are intentionally kept in
the service repos because they follow the service deployment lifecycle.

If a migration is generic enough to be needed at tenant creation, it should be
copied here as a numbered schema file.

## Multi-tenant model

Shared MySQL host with prefixed schemas:

```text
mcb_check_payment_platform
mcb_business_rules
mcb_dup_detect
```

This matches the `DB_NAME_*` variables defined in `fintech-tenant-config`.

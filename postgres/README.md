# Postgres (ClearPilot)

SQL here is applied by `tools/apply-postgres.py` to the tenant-prefixed database in
`tenants/<tenant>/metadata.yaml` → `db_names.postgres` (example: `mcb_clearpilot`).

`tools/apply-db.py` never reads this directory. MySQL lives under `mysql/`.

Onboard creates the database if it is missing, then runs the files in order.
The public-chat reader role is `${TENANT}_website_chat_reader` (NOLOGIN until you
set a password from SOPS). copilot-api `PG_URL` must use `db_names.postgres`, not
the cluster's default `postgres` database.

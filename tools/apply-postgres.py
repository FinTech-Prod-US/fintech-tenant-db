#!/usr/bin/env python3
"""
Apply rendered Postgres SQL under postgres/ to a tenant-prefixed database.

Usage:
  python tools/apply-postgres.py --rendered-dir ./rendered/mcb \
    --pg-host localhost --pg-port 5432 \
    --pg-user accs_dev --pg-password password \
    --pg-database mcb_clearpilot \
    --pg-admin-user postgres --pg-admin-password password \
    --dry-run

Connects first to the maintenance database (postgres), creates --pg-database
if it does not exist, then CREATE EXTENSION vector (superuser — app users
have CREATEDB only), then applies postgres/**/*.sql in that database.
Never reads mysql/.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

try:
    import psycopg2
    from psycopg2 import sql
except ImportError:
    psycopg2 = None
    sql = None


def discover_sql_files(rendered_dir: Path) -> list[Path]:
    postgres_dir = rendered_dir / "postgres"
    if not postgres_dir.exists():
        return []
    return sorted(postgres_dir.rglob("*.sql"))


def _connect(host: str, port: int, user: str, password: str, dbname: str):
    return psycopg2.connect(
        host=host,
        port=port,
        user=user,
        password=password,
        dbname=dbname,
    )


def ensure_database(admin_conn, db_name: str, dry_run: bool) -> None:
    print(f"  {'[dry-run] ' if dry_run else ''}ensure database {db_name}")
    if dry_run:
        return
    admin_conn.autocommit = True
    with admin_conn.cursor() as cursor:
        cursor.execute("SELECT 1 FROM pg_database WHERE datname = %s", (db_name,))
        if cursor.fetchone():
            return
        cursor.execute(sql.SQL("CREATE DATABASE {}").format(sql.Identifier(db_name)))


def ensure_vector_extension(
    pg_host: str,
    pg_port: int,
    admin_user: str,
    admin_password: str,
    pg_database: str,
    dry_run: bool,
) -> None:
    print(f"  {'[dry-run] ' if dry_run else ''}ensure extension vector in {pg_database}")
    if dry_run:
        return
    conn = _connect(pg_host, pg_port, admin_user, admin_password, pg_database)
    conn.autocommit = True
    try:
        with conn.cursor() as cursor:
            cursor.execute("CREATE EXTENSION IF NOT EXISTS vector")
    except psycopg2.errors.InsufficientPrivilege:
        print(
            "CREATE EXTENSION vector requires a Postgres superuser. "
            "Pass --pg-admin-user / --pg-admin-password "
            "(Jenkins: postgres-<env>-admin-credentials).",
            file=sys.stderr,
        )
        raise
    finally:
        conn.close()


def execute_sql_file(connection, file_path: Path, dry_run: bool) -> None:
    print(f"  {'[dry-run] ' if dry_run else ''}{file_path}")
    if dry_run:
        return
    content = file_path.read_text(encoding="utf-8")
    if not content.strip():
        return
    with connection.cursor() as cursor:
        cursor.execute(content)
    connection.commit()


def apply(
    rendered_dir: Path,
    pg_host: str,
    pg_port: int,
    pg_user: str,
    pg_password: str,
    pg_database: str,
    dry_run: bool,
    pg_admin_user: str = "",
    pg_admin_password: str = "",
) -> int:
    files = discover_sql_files(rendered_dir)
    if not files:
        print("No postgres/*.sql files under rendered dir — skipping")
        return 0

    print(f"Postgres execution plan ({len(files)} files) database={pg_database}:")
    for f in files:
        print(f"  {'[dry-run] ' if dry_run else ''}{f}")

    if dry_run:
        print("  [dry-run] ensure extension vector")
        return 0

    if not psycopg2:
        print(
            "psycopg2 is required. Install it with: pip install psycopg2-binary",
            file=sys.stderr,
        )
        return 1

    admin = _connect(pg_host, pg_port, pg_user, pg_password, "postgres")
    try:
        ensure_database(admin, pg_database, dry_run=False)
    finally:
        admin.close()

    ext_user = pg_admin_user or pg_user
    ext_password = pg_admin_password if pg_admin_user else pg_password
    ensure_vector_extension(
        pg_host, pg_port, ext_user, ext_password, pg_database, dry_run=False
    )

    conn = _connect(pg_host, pg_port, pg_user, pg_password, pg_database)
    try:
        for file_path in files:
            execute_sql_file(conn, file_path, dry_run=False)
        print("All Postgres SQL files applied successfully")
    finally:
        conn.close()

    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Apply rendered SQL to Postgres")
    parser.add_argument("--rendered-dir", type=Path, required=True)
    parser.add_argument("--pg-host", default="localhost")
    parser.add_argument("--pg-port", type=int, default=5432)
    parser.add_argument("--pg-user", required=True)
    parser.add_argument("--pg-password", default="")
    parser.add_argument(
        "--pg-admin-user",
        default="",
        help="Superuser for CREATE EXTENSION vector (app users have CREATEDB only)",
    )
    parser.add_argument("--pg-admin-password", default="")
    parser.add_argument(
        "--pg-database",
        required=True,
        help="Tenant-prefixed database name (e.g. mcb_clearpilot)",
    )
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    if not args.rendered_dir.exists():
        print(f"Rendered directory not found: {args.rendered_dir}", file=sys.stderr)
        return 1

    return apply(
        args.rendered_dir,
        args.pg_host,
        args.pg_port,
        args.pg_user,
        args.pg_password,
        args.pg_database,
        args.dry_run,
        args.pg_admin_user,
        args.pg_admin_password,
    )


if __name__ == "__main__":
    raise SystemExit(main())

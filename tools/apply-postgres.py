#!/usr/bin/env python3
"""
Apply rendered Postgres SQL under postgres/ to a tenant-prefixed database.

Usage:
  python tools/apply-postgres.py --rendered-dir ./rendered/mcb \
    --pg-host localhost --pg-port 5432 \
    --pg-user postgres --pg-password password \
    --pg-database mcb_clearpilot \
    --dry-run

Connects first to the maintenance database (postgres), creates --pg-database
if it does not exist, then applies postgres/**/*.sql in that database.
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
) -> int:
    files = discover_sql_files(rendered_dir)
    if not files:
        print("No postgres/*.sql files under rendered dir — skipping")
        return 0

    print(f"Postgres execution plan ({len(files)} files) database={pg_database}:")
    for f in files:
        print(f"  {'[dry-run] ' if dry_run else ''}{f}")

    if dry_run:
        return 0

    if not psycopg2:
        print(
            "psycopg2 is required. Install it with: pip install psycopg2-binary",
            file=sys.stderr,
        )
        return 1

    admin = psycopg2.connect(
        host=pg_host,
        port=pg_port,
        user=pg_user,
        password=pg_password,
        dbname="postgres",
    )
    try:
        ensure_database(admin, pg_database, dry_run=False)
    finally:
        admin.close()

    conn = psycopg2.connect(
        host=pg_host,
        port=pg_port,
        user=pg_user,
        password=pg_password,
        dbname=pg_database,
    )
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
    )


if __name__ == "__main__":
    raise SystemExit(main())

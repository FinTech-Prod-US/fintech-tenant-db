#!/usr/bin/env python3
"""
Apply rendered SQL files to a MySQL server.

Usage:
  python tools/apply-db.py --rendered-dir ./rendered/mcb \
    --mysql-host localhost --mysql-port 3306 \
    --mysql-user root --mysql-password password \
    --dry-run

By default the script executes schema/ files first (in sorted order), then
tenant/ files. Use --dry-run to print the execution plan without running it.
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

try:
    import pymysql
    from pymysql.constants import CLIENT as MYSQL_CLIENT_FLAGS
except ImportError:
    pymysql = None
    MYSQL_CLIENT_FLAGS = None


def discover_sql_files(rendered_dir: Path) -> tuple[list[Path], list[Path]]:
    schema_files: list[Path] = []
    tenant_files: list[Path] = []

    schema_dir = rendered_dir / "schema"
    tenant_dir = rendered_dir / "tenant"

    if schema_dir.exists():
        schema_files = sorted(schema_dir.rglob("*.sql"))
    if tenant_dir.exists():
        tenant_files = sorted(tenant_dir.rglob("*.sql"))

    return schema_files, tenant_files


def extract_use_database(content: str) -> str | None:
    match = re.search(
        r"^USE\s+`?([^`\s;]+)`?\s*;",
        content,
        re.IGNORECASE | re.MULTILINE,
    )
    if match:
        return match.group(1).strip()
    return None


def ensure_databases_exist(connection, rendered_dir: Path) -> None:
    schema_dir = rendered_dir / "schema"
    tenant_dir = rendered_dir / "tenant"
    databases: set[str] = set()

    for source_dir in (schema_dir, tenant_dir):
        if not source_dir.exists():
            continue
        for sql_file in source_dir.rglob("*.sql"):
            content = sql_file.read_text(encoding="utf-8")
            db_name = extract_use_database(content)
            if db_name:
                databases.add(db_name)

    if not databases:
        return

    print(f"Ensuring databases exist: {', '.join(sorted(databases))}")
    with connection.cursor() as cursor:
        for db_name in sorted(databases):
            cursor.execute(
                f"CREATE DATABASE IF NOT EXISTS `{db_name}` "
                "CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
            )
    connection.commit()


def execute_sql_file(
    connection,
    file_path: Path,
    dry_run: bool,
) -> None:
    print(f"  {'[dry-run] ' if dry_run else ''}{file_path}")
    if dry_run:
        return

    content = file_path.read_text(encoding="utf-8")
    if not content.strip():
        return

    # The source schema/seed files may have foreign-key references to tables that
    # are created later in the same batch, and seed files may contain JSON strings
    # with semicolons. Disable FK checks and execute the whole file as one batch
    # so MySQL parses it correctly, just like the legacy setup script did.
    wrapped_content = (
        "SET FOREIGN_KEY_CHECKS=0;\n" + content + "\nSET FOREIGN_KEY_CHECKS=1;\n"
    )

    with connection.cursor() as cursor:
        cursor.execute(wrapped_content)
        # Drain any pending result sets so the connection stays clean.
        while cursor.nextset():
            pass
    connection.commit()


def apply(
    rendered_dir: Path,
    mysql_host: str,
    mysql_port: int,
    mysql_user: str,
    mysql_password: str,
    dry_run: bool,
) -> int:
    schema_files, tenant_files = discover_sql_files(rendered_dir)
    all_files = schema_files + tenant_files

    print(f"Execution plan ({len(all_files)} files):")
    for f in all_files:
        print(f"  {'[dry-run] ' if dry_run else ''}{f}")

    if dry_run:
        return 0

    if not pymysql:
        print(
            "pymysql is required to apply SQL. Install it with: pip install pymysql",
            file=sys.stderr,
        )
        return 1

    connection = pymysql.connect(
        host=mysql_host,
        port=mysql_port,
        user=mysql_user,
        password=mysql_password,
        charset="utf8mb4",
        autocommit=False,
        client_flag=MYSQL_CLIENT_FLAGS.MULTI_STATEMENTS,
    )

    try:
        ensure_databases_exist(connection, rendered_dir)
        for file_path in all_files:
            execute_sql_file(connection, file_path, dry_run)
        print("All SQL files applied successfully")
    finally:
        connection.close()

    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Apply rendered SQL to MySQL")
    parser.add_argument(
        "--rendered-dir",
        type=Path,
        required=True,
        help="Directory containing rendered SQL files",
    )
    parser.add_argument("--mysql-host", default="localhost", help="MySQL host")
    parser.add_argument("--mysql-port", type=int, default=3306, help="MySQL port")
    parser.add_argument("--mysql-user", required=True, help="MySQL user")
    parser.add_argument("--mysql-password", default="", help="MySQL password")
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print execution plan without applying",
    )
    args = parser.parse_args()

    if not args.rendered_dir.exists():
        print(f"Rendered directory not found: {args.rendered_dir}", file=sys.stderr)
        return 1

    return apply(
        args.rendered_dir,
        args.mysql_host,
        args.mysql_port,
        args.mysql_user,
        args.mysql_password,
        args.dry_run,
    )


if __name__ == "__main__":
    raise SystemExit(main())

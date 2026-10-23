#!/usr/bin/env python3
"""Enable login on the public-chat reader role.

The role is created NOLOGIN by postgres/clearpilot/02_website_chat.sql.
The password lives in copilot-api secrets.json as PUBLIC_PG_URL (SOPS).
This script reads that URL and runs ALTER ROLE ... LOGIN. It never prints
the URL or the password.

A new environment picks this up when onboard-tenant applies Postgres.
"""
from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
import urllib.parse
from pathlib import Path

try:
    import psycopg2
    from psycopg2 import sql
except ImportError:
    psycopg2 = None
    sql = None


def load_public_pg_url(secrets_file: Path) -> str:
    raw = json.loads(secrets_file.read_text(encoding="utf-8"))
    if "sops" in raw:
        sops_bin = shutil.which("sops")
        if not sops_bin:
            print("sops is required to read PUBLIC_PG_URL", file=sys.stderr)
            return ""
        result = subprocess.run(
            [sops_bin, "-d", str(secrets_file)],
            capture_output=True,
            text=True,
            check=False,
        )
        if result.returncode != 0:
            print(result.stderr.strip(), file=sys.stderr)
            return ""
        raw = json.loads(result.stdout)
    return str(raw.get("PUBLIC_PG_URL") or "")


def main() -> int:
    parser = argparse.ArgumentParser(description="Enable the public-chat reader login")
    parser.add_argument("--secrets-file", type=Path, required=True)
    parser.add_argument("--pg-host", required=True)
    parser.add_argument("--pg-port", type=int, default=5432)
    parser.add_argument("--pg-admin-user", required=True)
    parser.add_argument("--pg-admin-password", default="")
    parser.add_argument("--pg-database", required=True)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    if not args.secrets_file.exists():
        print(f"No secrets file at {args.secrets_file} — skipping website chat reader login")
        return 0

    url = load_public_pg_url(args.secrets_file)
    if not url:
        print("PUBLIC_PG_URL is not set — skipping website chat reader login")
        return 0

    parsed = urllib.parse.urlparse(url)
    role = parsed.username or ""
    password = urllib.parse.unquote(parsed.password or "")
    if not role or not password:
        print("PUBLIC_PG_URL is missing a user or password", file=sys.stderr)
        return 1

    print(
        f"{'[dry-run] ' if args.dry_run else ''}"
        f"enable login for role {role} on {args.pg_database}"
    )
    if args.dry_run:
        return 0
    if psycopg2 is None or sql is None:
        print("psycopg2 is required. Install it with: pip install psycopg2-binary", file=sys.stderr)
        return 1

    conn = psycopg2.connect(
        host=args.pg_host,
        port=args.pg_port,
        user=args.pg_admin_user,
        password=args.pg_admin_password,
        dbname=args.pg_database,
    )
    conn.autocommit = True
    try:
        with conn.cursor() as cursor:
            cursor.execute("SELECT 1 FROM pg_roles WHERE rolname = %s", (role,))
            if cursor.fetchone() is None:
                print(
                    f"Role {role} does not exist. Apply postgres SQL before enabling login.",
                    file=sys.stderr,
                )
                return 1
            cursor.execute(
                sql.SQL("ALTER ROLE {} WITH LOGIN PASSWORD {}").format(
                    sql.Identifier(role),
                    sql.Literal(password),
                )
            )
    finally:
        conn.close()

    print(f"Login enabled for role {role}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

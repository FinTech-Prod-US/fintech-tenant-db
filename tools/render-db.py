#!/usr/bin/env python3
"""
Render schema/seed SQL for a target tenant by substituting DB name placeholders.

Usage:
  python tools/render-db.py --tenant mcb \
    --db-name-primary mcb_check_payment_platform \
    --db-name-business-rules mcb_business_rules \
    --db-name-dup-detect mcb_dup_detect \
    --output ./rendered/mcb

This produces a directory tree under ./rendered/mcb that can be executed by
apply-db.py. The rendered SQL files have all ${DB_NAME_*} placeholders replaced
with the actual tenant-prefixed database names.
"""
from __future__ import annotations

import argparse
import re
import shutil
from pathlib import Path


PLACEHOLDERS = [
    ("${DB_NAME_PRIMARY}", "db_name_primary"),
    ("${DB_NAME_BUSINESS_RULES}", "db_name_business_rules"),
    ("${DB_NAME_DUP_DETECT}", "db_name_dup_detect"),
    ("${DB_NAME_ACCS}", "db_name_accs"),
]


def render_file(
    source: Path,
    target: Path,
    substitutions: dict[str, str],
) -> None:
    content = source.read_text(encoding="utf-8")
    for placeholder, value in substitutions.items():
        content = content.replace(placeholder, value)

    # Safety check: any remaining placeholder is an error
    remaining = re.findall(r"\$\{DB_NAME_[A-Z_]+\}", content)
    if remaining:
        raise ValueError(
            f"Unresolved placeholders in {source}: {set(remaining)}"
        )

    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(content, encoding="utf-8")


def render_tenant(
    repo_root: Path,
    tenant: str,
    db_names: dict[str, str],
    output_dir: Path,
) -> None:
    schema_dir = repo_root / "schema"
    tenant_dir = repo_root / "tenants" / tenant

    # Build substitution map for placeholders -> actual DB names
    substitutions: dict[str, str] = {}
    for placeholder, key in PLACEHOLDERS:
        value = db_names.get(key)
        if value:
            substitutions[placeholder] = value

    # Render canonical schema
    if schema_dir.exists():
        for source in sorted(schema_dir.rglob("*.sql")):
            relative = source.relative_to(schema_dir)
            target = output_dir / "schema" / relative
            render_file(source, target, substitutions)

    # Render tenant-specific overrides
    if tenant_dir.exists():
        for source in sorted(tenant_dir.rglob("*.sql")):
            relative = source.relative_to(tenant_dir)
            target = output_dir / "tenant" / relative
            render_file(source, target, substitutions)


def main() -> int:
    parser = argparse.ArgumentParser(description="Render SQL for a tenant")
    parser.add_argument("--tenant", required=True, help="Tenant name")
    parser.add_argument("--db-name-primary", help="Primary DB name")
    parser.add_argument("--db-name-business-rules", help="Business rules DB name")
    parser.add_argument("--db-name-dup-detect", help="Dup detect DB name")
    parser.add_argument("--db-name-accs", help="Accs DB name")
    parser.add_argument(
        "--output",
        type=Path,
        required=True,
        help="Output directory for rendered SQL",
    )
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=Path(__file__).resolve().parent.parent,
        help="Path to fintech-tenant-db repo root",
    )
    args = parser.parse_args()

    db_names = {
        "db_name_primary": args.db_name_primary,
        "db_name_business_rules": args.db_name_business_rules,
        "db_name_dup_detect": args.db_name_dup_detect,
        "db_name_accs": args.db_name_accs,
    }
    db_names = {k: v for k, v in db_names.items() if v}

    if not db_names:
        print("At least one --db-name-* argument is required", file=__import__("sys").stderr)
        return 1

    # Default DB_NAME_ACCS to primary if not provided
    if not args.db_name_accs and args.db_name_primary:
        db_names["db_name_accs"] = args.db_name_primary

    if args.output.exists():
        shutil.rmtree(args.output)
    args.output.mkdir(parents=True, exist_ok=True)

    render_tenant(args.repo_root, args.tenant, db_names, args.output)
    print(f"Rendered SQL for tenant {args.tenant} to {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

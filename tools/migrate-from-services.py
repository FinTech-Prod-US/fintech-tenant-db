#!/usr/bin/env python3
"""
One-time migration of DB schema/seed SQL from service repos into this repo.

Reads the legacy local-db-init scripts from ECS_UtilityScripts and produces:
  schema/primary/*.sql
  schema/business_rules/*.sql
  schema/dup_detect/*.sql
  schema/shared/*.sql

It replaces hardcoded DB names with placeholders:
  check_payment_platform -> ${DB_NAME_PRIMARY}
  business_rules         -> ${DB_NAME_BUSINESS_RULES}
  dup_detect             -> ${DB_NAME_DUP_DETECT}
"""
from __future__ import annotations

import argparse
import re
import shutil
from pathlib import Path

# Map logical DB name -> source folder name + placeholder
DB_MAP = {
    "primary": {
        "placeholder": "${DB_NAME_PRIMARY}",
        "legacy_names": {"check_payment_platform"},
    },
    "business_rules": {
        "placeholder": "${DB_NAME_BUSINESS_RULES}",
        "legacy_names": {"business_rules"},
    },
    "dup_detect": {
        "placeholder": "${DB_NAME_DUP_DETECT}",
        "legacy_names": {"dup_detect"},
    },
}

# Map source filename prefix -> (target_db, target_order)
SOURCE_FILES = {
    "check_payment_platform_schema.sql": ("primary", "01_schema.sql"),
    "check_payment_platform_seed.sql": ("primary", "02_seed.sql"),
    "check_payment_platform_master_seed.sql": ("primary", "03_master_seed.sql"),
    "business_rules_schema.sql": ("business_rules", "01_schema.sql"),
    "business_rules_seed.sql": ("business_rules", "02_seed.sql"),
    "business_rules_seed_bank_master.sql": ("business_rules", "03_seed_bank_master.sql"),
    "business_rules_seed_collection_type_master.sql": ("business_rules", "04_seed_collection_type_master.sql"),
    "business_rules_seed_endpoint_direction_rules.sql": ("business_rules", "05_seed_endpoint_direction_rules.sql"),
    "business_rules_seed_tae_eie.sql": ("business_rules", "06_seed_tae_eie.sql"),
    "business_rules_seed_workflow_inclff.sql": ("business_rules", "07_seed_workflow_inclff.sql"),
    "business_rules_seed_workflow_master.sql": ("business_rules", "08_seed_workflow_master.sql"),
    "business_rules_seed_workflow_outclfbr.sql": ("business_rules", "09_seed_workflow_outclfbr.sql"),
    "dup_detect_schema.sql": ("dup_detect", "01_schema.sql"),
    "dup_detect_seed.sql": ("dup_detect", "02_seed.sql"),
    "dup_detect_master_seed.sql": ("dup_detect", "03_master_seed.sql"),
    "eie_schema_and_seed.sql": ("primary", "04_eie_schema_and_seed.sql"),
    "tae_schema_and_seed.sql": ("primary", "05_tae_schema_and_seed.sql"),
    "users_seed.sql": ("shared", "01_users_seed.sql"),
    "alter_fraud_watch_ref_add_rt.sql": ("primary", "06_alter_fraud_watch_ref_add_rt.sql"),
}


def replace_db_names(content: str) -> str:
    for db_config in DB_MAP.values():
        for legacy_name in db_config["legacy_names"]:
            # Match backtick-quoted DB names
            content = re.sub(
                rf"`{re.escape(legacy_name)}`",
                db_config["placeholder"],
                content,
            )
            # Also match unquoted DB names in CREATE DATABASE / USE statements
            content = re.sub(
                rf"\b(USE|CREATE\s+DATABASE|DROP\s+DATABASE)\s+{re.escape(legacy_name)}\b",
                rf"\1 {db_config['placeholder']}",
                content,
                flags=re.IGNORECASE,
            )
    return content


def migrate(source_dir: Path, repo_root: Path) -> None:
    schema_dir = repo_root / "schema"
    schema_dir.mkdir(parents=True, exist_ok=True)

    for source_name, (target_db, target_name) in SOURCE_FILES.items():
        source_file = source_dir / source_name
        if not source_file.exists():
            print(f"SKIP: {source_file} not found")
            continue

        target_dir = schema_dir / target_db
        target_dir.mkdir(parents=True, exist_ok=True)
        target_file = target_dir / target_name

        content = source_file.read_text(encoding="utf-8")
        rendered = replace_db_names(content)
        target_file.write_text(rendered, encoding="utf-8")
        print(f"MIGRATED: {source_name} -> {target_file}")


def main() -> int:
    parser = argparse.ArgumentParser(description="Migrate local DB init SQL into tenant DB repo")
    parser.add_argument(
        "--source-dir",
        type=Path,
        default=Path(__file__).resolve().parent.parent.parent
        / "ECS_UtilityScripts"
        / "accs-dev-env-setup"
        / "local-db-init",
        help="Path to local-db-init directory",
    )
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=Path(__file__).resolve().parent.parent,
        help="Path to fintech-tenant-db repo root",
    )
    args = parser.parse_args()

    if not args.source_dir.exists():
        print(f"Source directory not found: {args.source_dir}", file=__import__("sys").stderr)
        return 1

    migrate(args.source_dir, args.repo_root)
    print("\nMigration complete. Review schema/ for placeholder correctness.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

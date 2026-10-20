#!/usr/bin/env python3
"""
Render schema/seed SQL for a target tenant by substituting DB name placeholders.

Simple usage — db_names read from tenants/<tenant>/metadata.yaml automatically:
  python tools/render-db.py --tenant mcb --output ./rendered/mcb

Override any db name on the command line (CLI wins over metadata.yaml):
  python tools/render-db.py --tenant mcb --db-name-primary custom_db --output ./rendered/mcb

This produces a directory tree under ./rendered/mcb that can be executed by
apply-db.py. The rendered SQL files have all ${DB_NAME_*} placeholders replaced
with the actual tenant-prefixed database names.
"""
from __future__ import annotations

import argparse
import re
import shutil
import sys
from pathlib import Path

try:
    import yaml
    _YAML_AVAILABLE = True
except ImportError:
    _YAML_AVAILABLE = False


PLACEHOLDERS = [
    ("${DB_NAME_PRIMARY}", "db_name_primary"),
    ("${DB_NAME_BUSINESS_RULES}", "db_name_business_rules"),
    ("${DB_NAME_DUP_DETECT}", "db_name_dup_detect"),
    ("${DB_NAME_ACCS}", "db_name_accs"),
    ("${DB_NAME_POSTGRES}", "db_name_postgres"),
    ("${SCHEMA_CLEARPILOT}", "schema_clearpilot"),
    ("${SCHEMA_WEBSITE_CHAT}", "schema_website_chat"),
]

# metadata.yaml db_names key -> db_names dict key
_METADATA_KEY_MAP = {
    "primary":        "db_name_primary",
    "business_rules": "db_name_business_rules",
    "dup_detect":     "db_name_dup_detect",
    "accs":           "db_name_accs",
    "postgres":       "db_name_postgres",
}

_SCHEMA_KEY_MAP = {
    "clearpilot":   "schema_clearpilot",
    "website_chat": "schema_website_chat",
}


def load_metadata(repo_root: Path, tenant: str) -> dict[str, str]:
    """Load db_names from tenants/<tenant>/metadata.yaml. Returns {} if absent."""
    metadata_path = repo_root / "tenants" / tenant / "metadata.yaml"
    if not metadata_path.exists():
        return {}

    if not _YAML_AVAILABLE:
        # Fallback: simple regex parse for the db_names block
        content = metadata_path.read_text(encoding="utf-8")
        result: dict[str, str] = {}
        current_map = None
        for line in content.splitlines():
            stripped = line.strip()
            if stripped == "db_names:":
                current_map = _METADATA_KEY_MAP
                continue
            if stripped == "postgres_schemas:":
                current_map = _SCHEMA_KEY_MAP
                continue
            if current_map is not None:
                if line.startswith(" ") or line.startswith("\t"):
                    m = re.match(r"\s+(\w+):\s*(.+)", line)
                    if m:
                        yaml_key, value = m.group(1).strip(), m.group(2).strip()
                        dict_key = current_map.get(yaml_key)
                        if dict_key:
                            result[dict_key] = value
                elif stripped and not stripped.startswith("#"):
                    current_map = None
        return result

    data = yaml.safe_load(metadata_path.read_text(encoding="utf-8")) or {}
    db_names_raw = data.get("db_names", {}) or {}
    result = {
        _METADATA_KEY_MAP[k]: v
        for k, v in db_names_raw.items()
        if k in _METADATA_KEY_MAP and v
    }
    schemas_raw = data.get("postgres_schemas", {}) or {}
    for yaml_key, dict_key in _SCHEMA_KEY_MAP.items():
        value = schemas_raw.get(yaml_key)
        if value:
            result[dict_key] = value
    return result


def render_file(
    source: Path,
    target: Path,
    substitutions: dict[str, str],
) -> None:
    content = source.read_text(encoding="utf-8")
    for placeholder, value in substitutions.items():
        content = content.replace(placeholder, value)

    remaining = re.findall(r"\$\{[A-Z][A-Z0-9_]+\}", content)
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
    mysql_dir = repo_root / "mysql"
    postgres_dir = repo_root / "postgres"
    tenant_dir = repo_root / "tenants" / tenant

    # Build substitution map for placeholders -> actual DB names
    substitutions: dict[str, str] = {
        "${TENANT}": tenant,
        "${PG_ROLE_WEBSITE_CHAT}": f"{tenant}_website_chat_reader",
    }
    for placeholder, key in PLACEHOLDERS:
        value = db_names.get(key)
        if value:
            substitutions[placeholder] = value

    if mysql_dir.exists():
        for source in sorted(mysql_dir.rglob("*.sql")):
            relative = source.relative_to(mysql_dir)
            target = output_dir / "mysql" / relative
            render_file(source, target, substitutions)

    if postgres_dir.exists() and db_names.get("db_name_postgres"):
        for source in sorted(postgres_dir.rglob("*.sql")):
            relative = source.relative_to(postgres_dir)
            target = output_dir / "postgres" / relative
            render_file(source, target, substitutions)

    if tenant_dir.exists():
        for source in sorted(tenant_dir.rglob("*.sql")):
            relative = source.relative_to(tenant_dir)
            target = output_dir / "tenant" / relative
            render_file(source, target, substitutions)


def main() -> int:
    parser = argparse.ArgumentParser(description="Render SQL for a tenant")
    parser.add_argument("--tenant", required=True, help="Tenant name (matches tenants/<name>/)")
    parser.add_argument("--db-name-primary", help="Primary DB name (overrides metadata.yaml)")
    parser.add_argument("--db-name-business-rules", help="Business rules DB name (overrides metadata.yaml)")
    parser.add_argument("--db-name-dup-detect", help="Dup detect DB name (overrides metadata.yaml)")
    parser.add_argument("--db-name-accs", help="Accs DB name (overrides metadata.yaml)")
    parser.add_argument("--db-name-postgres", help="Postgres DB name (overrides metadata.yaml)")
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

    # Start from metadata.yaml, then let CLI args override
    db_names = load_metadata(args.repo_root, args.tenant)

    cli_overrides = {
        "db_name_primary":        args.db_name_primary,
        "db_name_business_rules": args.db_name_business_rules,
        "db_name_dup_detect":     args.db_name_dup_detect,
        "db_name_accs":           args.db_name_accs,
        "db_name_postgres":       args.db_name_postgres,
    }
    for key, val in cli_overrides.items():
        if val:
            db_names[key] = val

    if not db_names:
        print(
            f"No db_names found for tenant '{args.tenant}'. Either add a "
            f"db_names section to tenants/{args.tenant}/metadata.yaml or "
            "pass --db-name-* arguments.",
            file=sys.stderr,
        )
        return 1

    # Default DB_NAME_ACCS to primary if not provided
    if "db_name_accs" not in db_names and "db_name_primary" in db_names:
        db_names["db_name_accs"] = db_names["db_name_primary"]
    db_names.setdefault("schema_clearpilot", "clearpilot")
    db_names.setdefault("schema_website_chat", "website_chat")

    print(f"Rendering tenant '{args.tenant}' with db_names:")
    for k, v in sorted(db_names.items()):
        print(f"  {k} = {v}")

    if args.output.exists():
        shutil.rmtree(args.output)
    args.output.mkdir(parents=True, exist_ok=True)

    render_tenant(args.repo_root, args.tenant, db_names, args.output)
    print(f"Rendered SQL for tenant {args.tenant} to {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

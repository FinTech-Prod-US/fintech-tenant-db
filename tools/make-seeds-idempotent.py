import re
from pathlib import Path

SCHEMA_DIR = Path(__file__).resolve().parent.parent / "schema"

seed_files = list(SCHEMA_DIR.rglob("*seed*.sql"))
print(f"Found {len(seed_files)} seed files")

for f in seed_files:
    text = f.read_text(encoding="utf-8")
    # Replace INSERT INTO (case-insensitive, allowing backticks) with INSERT IGNORE INTO
    # but avoid replacing INSERT IGNORE INTO again or other INSERT variants.
    new_text = re.sub(
        r"INSERT\s+(?!IGNORE\s+)INTO\s+",
        "INSERT IGNORE INTO ",
        text,
        flags=re.IGNORECASE,
    )
    if new_text != text:
        print(f"  idempotency update: {f}")
        f.write_text(new_text, encoding="utf-8")

print("Done")

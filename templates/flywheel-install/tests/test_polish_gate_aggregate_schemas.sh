#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

python3 - "$ROOT" <<'PY'
import json
import sys
from pathlib import Path

from jsonschema import Draft202012Validator
from jsonschema.exceptions import SchemaError

root = Path(sys.argv[1])
schema_dir = root / "polish-gate" / "v1"
manifest_path = root / "schema.json"

with manifest_path.open(encoding="utf-8") as handle:
    manifest = json.load(handle)

declared = sorted(manifest["polish_gate"]["schemas"])
schema_const = sorted(manifest["properties"]["polish_gate"]["properties"]["schemas"]["const"])
if declared != schema_const:
    print("top-level polish_gate.schemas does not match schema const", file=sys.stderr)
    print(f"  top_level={declared}", file=sys.stderr)
    print(f"  schema_const={schema_const}", file=sys.stderr)
    raise SystemExit(1)

on_disk = sorted(
    str(path.relative_to(root))
    for path in schema_dir.glob("*.schema.json")
)
missing_from_manifest = sorted(set(on_disk) - set(declared))
missing_on_disk = sorted(set(declared) - set(on_disk))
if missing_from_manifest or missing_on_disk:
    if missing_from_manifest:
        print("missing_from_manifest:", file=sys.stderr)
        for path in missing_from_manifest:
            print(f"  {path}", file=sys.stderr)
    if missing_on_disk:
        print("missing_on_disk:", file=sys.stderr)
        for path in missing_on_disk:
            print(f"  {path}", file=sys.stderr)
    raise SystemExit(1)

for rel in declared:
    path = root / rel
    try:
        with path.open(encoding="utf-8") as handle:
            schema = json.load(handle)
        if schema.get("$schema") != "https://json-schema.org/draft/2020-12/schema":
            raise AssertionError(
                f"expected $schema draft 2020-12, got {schema.get('$schema')!r}"
            )
        Draft202012Validator.check_schema(schema)
    except json.JSONDecodeError as exc:
        print(
            f"{rel}: invalid JSON at line {exc.lineno} column {exc.colno}: {exc.msg}",
            file=sys.stderr,
        )
        raise SystemExit(1) from exc
    except SchemaError as exc:
        print(f"{rel}: invalid JSON-Schema 2020-12: {exc.message}", file=sys.stderr)
        raise SystemExit(1) from exc
    except AssertionError as exc:
        print(f"{rel}: {exc}", file=sys.stderr)
        raise SystemExit(1) from exc

print(f"PASS: polish gate aggregate schemas ({len(declared)} schemas)")
PY

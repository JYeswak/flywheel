#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

python3 -c '
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
schema_dir = root / "polish-gate" / "v1"
manifest_path = root / "schema.json"

with manifest_path.open(encoding="utf-8") as handle:
    manifest = json.load(handle)

declared = sorted(manifest["polish_gate"]["schemas"])
schema_const = sorted(manifest["properties"]["polish_gate"]["properties"]["schemas"]["const"])
if declared != schema_const:
    print("top-level polish_gate.schemas does not match schema const", file=sys.stderr)
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

print(f"PASS: polish gate schema inventory parity ({len(on_disk)} schemas)")
' "$ROOT"

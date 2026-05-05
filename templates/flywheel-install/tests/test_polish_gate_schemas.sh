#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

python3 -c '
import copy
import json
import sys
from pathlib import Path

import jsonschema
from jsonschema import Draft202012Validator

root = Path(sys.argv[1])
schema_dir = root / "polish-gate" / "v1"
fixture_dir = root / "polish-gate" / "fixtures"

schema_paths = [
    schema_dir / "manifest.schema.json",
    schema_dir / "grade-receipt.schema.json",
    schema_dir / "latest-summary.schema.json",
]
schemas = {}

for path in schema_paths:
    with path.open(encoding="utf-8") as handle:
        schema = json.load(handle)
    Draft202012Validator.check_schema(schema)
    schemas[path.name] = schema

manifest_validator = Draft202012Validator(
    schemas["manifest.schema.json"],
    format_checker=Draft202012Validator.FORMAT_CHECKER,
)
fixture_paths = [
    fixture_dir / "bootstrap-mode.json",
    fixture_dir / "audit-only-mode.json",
    fixture_dir / "blocking-mode.json",
]

for path in fixture_paths:
    with path.open(encoding="utf-8") as handle:
        manifest_validator.validate(json.load(handle))

with fixture_paths[0].open(encoding="utf-8") as handle:
    malformed = json.load(handle)
del malformed["mode"]

try:
    manifest_validator.validate(malformed)
except jsonschema.ValidationError:
    pass
else:
    raise AssertionError("malformed polish-gate fixture without mode validated")

receipt_validator = Draft202012Validator(
    schemas["grade-receipt.schema.json"],
    format_checker=Draft202012Validator.FORMAT_CHECKER,
)
receipt_validator.validate({
    "schema_version": "polish-gate/grade-receipt/v1",
    "ts": "2026-05-05T00:00:00Z",
    "surface_path": ".flywheel/GOAL.md",
    "surface_name": "GOAL.md",
    "mode": "audit_only",
    "skills": {
        "ubs": 9.0,
        "simplify": 8.0,
        "extreme-opt": 8.5,
        "readme": 7.5,
        "canonical-cli": 9.5,
    },
    "composite": 8.5,
    "verdict": "AUDIT_ONLY",
    "evidence_paths": [".flywheel/polish-gate/evidence/goal.md.json"],
    "grader": "fixture-agent",
    "mission_anchor_hash": "sha256:fixture",
})

summary_validator = Draft202012Validator(
    schemas["latest-summary.schema.json"],
    format_checker=Draft202012Validator.FORMAT_CHECKER,
)
summary_validator.validate({
    "schema_version": "polish-gate/latest-summary/v1",
    "last_run_ts": "2026-05-05T00:00:00Z",
    "mode": "audit_only",
    "surfaces_graded": 3,
    "surfaces_passed": 2,
    "surfaces_failed": 1,
    "pending_waivers": 0,
    "composite_avg": 8.2,
    "min_composite": 7.0,
    "min_composite_surface": ".flywheel/STATE.md",
    "audit_summary_path": ".flywheel/polish-gate/latest-audit.md",
})

print("PASS: polish gate schemas and fixtures")
' "$ROOT"

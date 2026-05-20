#!/usr/bin/env python3
"""Validate the redacted ZestStream holding-company runway receipt."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator, FormatChecker


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SCHEMA = ROOT / ".flywheel/validation-schema/v1/holding-company-runway-receipt.schema.json"
DEFAULT_RECEIPT = ROOT / "state/holding-company-runway-current.json"
SECRETISH_RE = re.compile(r"(\$[0-9]|sk-[A-Za-z0-9]|AKIA[0-9A-Z]{16})")


def load_json(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def ref_exists(ref: str) -> bool:
    if "://" in ref or ref.startswith("urn:"):
        return True
    path = Path(ref)
    if not path.is_absolute():
        path = ROOT / path
    return path.exists()


def has_secretish_string(value: Any) -> bool:
    if isinstance(value, str):
        return bool(SECRETISH_RE.search(value))
    if isinstance(value, dict):
        return any(has_secretish_string(v) for v in value.values())
    if isinstance(value, list):
        return any(has_secretish_string(v) for v in value)
    return False


def validate_receipt(receipt: dict[str, Any], schema: dict[str, Any], *, check_paths: bool) -> dict[str, Any]:
    failures: list[dict[str, str]] = []
    try:
        Draft202012Validator.check_schema(schema)
        Draft202012Validator(schema, format_checker=FormatChecker()).validate(receipt)
    except Exception as exc:
        failures.append({"code": "schema_invalid", "detail": str(exc)})

    status = receipt.get("status")
    required_months = receipt.get("required_months")
    verified_months = receipt.get("verified_runway_months")
    launch_clear = status == "pass" and isinstance(verified_months, (int, float)) and verified_months >= required_months

    if status == "pass" and not launch_clear:
        failures.append({"code": "pass_status_below_required_months"})
    if status in {"not_provided", "blocked"} and verified_months is not None:
        failures.append({"code": "blocked_status_with_verified_months"})
    if status == "fail" and isinstance(verified_months, (int, float)) and verified_months >= required_months:
        failures.append({"code": "fail_status_meets_required_months"})
    if has_secretish_string(receipt):
        failures.append({"code": "secret_or_raw_amount_shape_detected"})

    if check_paths:
        for ref in receipt.get("evidence_refs", []):
            if isinstance(ref, str) and not ref_exists(ref):
                failures.append({"code": "evidence_ref_missing", "ref": ref})

    return {
        "schema_version": "zeststream.holding_company_runway_receipt.validation.v1",
        "status": "fail" if failures else "pass",
        "runway_gate_status": "clear" if launch_clear and not failures else "blocked",
        "launch_gate": receipt.get("launch_gate"),
        "required_months": required_months,
        "verified_runway_months": verified_months,
        "failures": failures,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--receipt", type=Path, default=DEFAULT_RECEIPT)
    parser.add_argument("--schema", type=Path, default=DEFAULT_SCHEMA)
    parser.add_argument("--check-paths", action="store_true")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    result = validate_receipt(load_json(args.receipt), load_json(args.schema), check_paths=args.check_paths)
    if args.json:
        print(json.dumps(result, indent=2, sort_keys=True))
    else:
        print(f"status={result['status']} runway_gate_status={result['runway_gate_status']} required_months={result['required_months']}")
        for failure in result["failures"]:
            print(f"FAIL {failure}")
    return 0 if result["status"] == "pass" else 1


if __name__ == "__main__":
    sys.exit(main())

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-02-conformance-fixtures.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-68-schema-executable-validator-pair.md`

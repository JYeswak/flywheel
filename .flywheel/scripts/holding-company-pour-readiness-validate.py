#!/usr/bin/env python3
"""Validate the ZestStream holding-company POUR launch-readiness ledger."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator, FormatChecker


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SCHEMA = ROOT / ".flywheel/validation-schema/v1/holding-company-pour-readiness.schema.json"
DEFAULT_LEDGER = ROOT / "state/holding-company-pour-readiness.json"
REQUIRED_CLEAR_REFS = [
    "brand_identity_ref",
    "repo_ref",
    "public_surface_ref",
    "first_paying_customer_receipt",
    "owner_operator_ref",
    "operating_control_handoff_ref",
]
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


def has_ref(value: Any) -> bool:
    return isinstance(value, str) and bool(value.strip())


def validate_ledger(ledger: dict[str, Any], schema: dict[str, Any], *, check_paths: bool) -> dict[str, Any]:
    failures: list[dict[str, Any]] = []
    try:
        Draft202012Validator.check_schema(schema)
        Draft202012Validator(schema, format_checker=FormatChecker()).validate(ledger)
    except Exception as exc:
        failures.append({"code": "schema_invalid", "detail": str(exc)})

    launch_results: list[dict[str, Any]] = []
    computed_clear_count = 0

    for launch in ledger.get("launches", []):
        if not isinstance(launch, dict):
            continue
        launch_id = launch.get("launch_id")
        status = launch.get("status")
        launch_failures: list[dict[str, Any]] = []
        missing_refs = [field for field in REQUIRED_CLEAR_REFS if not has_ref(launch.get(field))]
        clear = status in {"pour_clear", "launched"} and not missing_refs

        if status in {"pour_clear", "launched"} and missing_refs:
            launch_failures.append({"code": "clear_status_missing_pour_refs", "missing_refs": missing_refs})
        if has_secretish_string(launch):
            launch_failures.append({"code": "secret_or_raw_amount_shape_detected"})

        if check_paths:
            for field in REQUIRED_CLEAR_REFS:
                ref = launch.get(field)
                if isinstance(ref, str) and not ref_exists(ref):
                    launch_failures.append({"code": "required_ref_missing", "field": field, "ref": ref})
            for ref in launch.get("evidence_refs", []):
                if isinstance(ref, str) and not ref_exists(ref):
                    launch_failures.append({"code": "evidence_ref_missing", "ref": ref})

        if clear and not launch_failures:
            computed_clear_count += 1
        for failure in launch_failures:
            failures.append({"launch_id": launch_id, **failure})

        launch_results.append(
            {
                "launch_id": launch_id,
                "company_slug": launch.get("company_slug"),
                "sequence": launch.get("sequence"),
                "status": status,
                "missing_refs": missing_refs,
                "pour_gate_status": "clear" if clear and not launch_failures else "blocked",
                "failures": launch_failures,
            }
        )

    claimed_clear_count = ledger.get("clear_count")
    if claimed_clear_count != computed_clear_count:
        failures.append(
            {
                "code": "clear_count_mismatch",
                "claimed": claimed_clear_count,
                "computed": computed_clear_count,
            }
        )

    return {
        "schema_version": "zeststream.holding_company_pour_readiness.validation.v1",
        "status": "fail" if failures else "pass",
        "gate": ledger.get("gate"),
        "clear_count": computed_clear_count,
        "launch_count": len(launch_results),
        "launches": launch_results,
        "failures": failures,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ledger", type=Path, default=DEFAULT_LEDGER)
    parser.add_argument("--schema", type=Path, default=DEFAULT_SCHEMA)
    parser.add_argument("--check-paths", action="store_true")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    result = validate_ledger(load_json(args.ledger), load_json(args.schema), check_paths=args.check_paths)
    if args.json:
        print(json.dumps(result, indent=2, sort_keys=True))
    else:
        print("status={status} clear_count={clear_count} launch_count={launch_count}".format(**result))
        for failure in result["failures"]:
            print(f"FAIL {failure}")
    return 0 if result["status"] == "pass" else 1


if __name__ == "__main__":
    sys.exit(main())

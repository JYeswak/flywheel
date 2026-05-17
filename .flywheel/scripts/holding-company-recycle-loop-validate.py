#!/usr/bin/env python3
"""Validate the ZestStream holding-company RECYCLE friction ledger."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator, FormatChecker


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SCHEMA = ROOT / ".flywheel/validation-schema/v1/holding-company-recycle-loop.schema.json"
DEFAULT_LEDGER = ROOT / "state/holding-company-recycle-loop.json"
REQUIRED_REFS = [
    "friction_receipt_ref",
    "skillos_capability_ref",
    "package_or_substrate_ref",
    "portfolio_propagation_ref",
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

    max_window = ledger.get("required_max_propagation_window_days", 30)
    item_results: list[dict[str, Any]] = []
    computed_clear_count = 0

    for item in ledger.get("friction_items", []):
        if not isinstance(item, dict):
            continue
        friction_id = item.get("friction_id")
        status = item.get("status")
        window = item.get("propagation_window_days")
        missing_refs = [field for field in REQUIRED_REFS if not has_ref(item.get(field))]
        item_failures: list[dict[str, Any]] = []

        propagated = status == "propagated"
        window_ok = isinstance(window, int) and not isinstance(window, bool) and window <= max_window
        clear = propagated and not missing_refs and window_ok

        if propagated and missing_refs:
            item_failures.append({"code": "propagated_status_missing_refs", "missing_refs": missing_refs})
        if propagated and not window_ok:
            item_failures.append(
                {
                    "code": "propagation_window_missing_or_over_max",
                    "expected_max_days": max_window,
                    "actual_days": window,
                }
            )
        if status in {"capability_landed", "package_landed"} and not has_ref(item.get("friction_receipt_ref")):
            item_failures.append({"code": "landed_status_without_friction_receipt"})
        if status == "package_landed" and not has_ref(item.get("skillos_capability_ref")):
            item_failures.append({"code": "package_landed_without_skillos_capability"})
        if has_secretish_string(item):
            item_failures.append({"code": "secret_or_raw_amount_shape_detected"})

        if check_paths:
            for field in REQUIRED_REFS:
                ref = item.get(field)
                if isinstance(ref, str) and not ref_exists(ref):
                    item_failures.append({"code": "required_ref_missing", "field": field, "ref": ref})
            for ref in item.get("evidence_refs", []):
                if isinstance(ref, str) and not ref_exists(ref):
                    item_failures.append({"code": "evidence_ref_missing", "ref": ref})

        if clear and not item_failures:
            computed_clear_count += 1
        for failure in item_failures:
            failures.append({"friction_id": friction_id, **failure})

        item_results.append(
            {
                "friction_id": friction_id,
                "company_slug": item.get("company_slug"),
                "source_loop": item.get("source_loop"),
                "status": status,
                "missing_refs": missing_refs,
                "propagation_window_days": window,
                "recycle_gate_status": "clear" if clear and not item_failures else "blocked",
                "failures": item_failures,
            }
        )

    claimed_clear_count = ledger.get("clear_count")
    if claimed_clear_count != computed_clear_count:
        failures.append({"code": "clear_count_mismatch", "claimed": claimed_clear_count, "computed": computed_clear_count})

    return {
        "schema_version": "zeststream.holding_company_recycle_loop.validation.v1",
        "status": "fail" if failures else "pass",
        "gate": ledger.get("gate"),
        "required_max_propagation_window_days": max_window,
        "clear_count": computed_clear_count,
        "friction_item_count": len(item_results),
        "friction_items": item_results,
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
        print("status={status} clear_count={clear_count} friction_item_count={friction_item_count}".format(**result))
        for failure in result["failures"]:
            print(f"FAIL {failure}")
    return 0 if result["status"] == "pass" else 1


if __name__ == "__main__":
    sys.exit(main())

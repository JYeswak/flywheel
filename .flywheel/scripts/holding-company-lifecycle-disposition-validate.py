#!/usr/bin/env python3
"""Validate the ZestStream holding-company lifecycle disposition ledger."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator, FormatChecker


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SCHEMA = ROOT / ".flywheel/validation-schema/v1/holding-company-lifecycle-disposition.schema.json"
DEFAULT_LEDGER = ROOT / "state/holding-company-lifecycle-disposition.json"
REQUIRED_DISPOSITION_REFS = [
    "owner_operator_ref",
    "customer_obligation_disposition_ref",
    "financial_disposition_ref",
    "substrate_retention_ref",
    "brand_public_update_ref",
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

    computed_clear_count = 0
    disposition_results: list[dict[str, Any]] = []

    for disposition in ledger.get("dispositions", []):
        if not isinstance(disposition, dict):
            continue
        disposition_id = disposition.get("disposition_id")
        status = disposition.get("status")
        disposition_type = disposition.get("disposition_type")
        missing_refs = [field for field in REQUIRED_DISPOSITION_REFS if not has_ref(disposition.get(field))]
        disposition_failures: list[dict[str, Any]] = []

        if disposition_type == "graduated" and not has_ref(disposition.get("graduation_terms_ref")):
            missing_refs.append("graduation_terms_ref")
        if disposition_type == "pivot" and not has_ref(disposition.get("pivot_scope_ref")):
            missing_refs.append("pivot_scope_ref")

        disposition_clear = (
            status == "disposition_clear"
            and disposition_type in {"pivot", "closed", "graduated"}
            and not missing_refs
            and disposition.get("holding_plane_continues") is True
        )

        if status == "disposition_clear" and disposition_type == "active_tracking":
            disposition_failures.append({"code": "active_tracking_cannot_be_disposition_clear"})
        if status == "disposition_clear" and missing_refs:
            disposition_failures.append({"code": "disposition_clear_missing_refs", "missing_refs": missing_refs})
        if status == "disposition_clear" and disposition.get("holding_plane_continues") is not True:
            disposition_failures.append({"code": "disposition_clear_without_holding_plane_continuity"})
        if has_secretish_string(disposition):
            disposition_failures.append({"code": "secret_or_raw_value_shape_detected"})

        if check_paths:
            for field in REQUIRED_DISPOSITION_REFS + ["graduation_terms_ref", "pivot_scope_ref"]:
                ref = disposition.get(field)
                if isinstance(ref, str) and not ref_exists(ref):
                    disposition_failures.append({"code": "required_ref_missing", "field": field, "ref": ref})
            for ref in disposition.get("evidence_refs", []):
                if isinstance(ref, str) and not ref_exists(ref):
                    disposition_failures.append({"code": "evidence_ref_missing", "ref": ref})

        if disposition_clear and not disposition_failures:
            computed_clear_count += 1
        for failure in disposition_failures:
            failures.append({"disposition_id": disposition_id, **failure})

        disposition_results.append(
            {
                "disposition_id": disposition_id,
                "company_slug": disposition.get("company_slug"),
                "disposition_type": disposition_type,
                "status": status,
                "missing_refs": missing_refs,
                "holding_plane_continues": disposition.get("holding_plane_continues"),
                "lifecycle_disposition_gate_status": "clear" if disposition_clear and not disposition_failures else "blocked",
                "failures": disposition_failures,
            }
        )

    claimed_clear_count = ledger.get("clear_count")
    if claimed_clear_count != computed_clear_count:
        failures.append({"code": "clear_count_mismatch", "claimed": claimed_clear_count, "computed": computed_clear_count})

    return {
        "schema_version": "zeststream.holding_company_lifecycle_disposition.validation.v1",
        "status": "fail" if failures else "pass",
        "gate": ledger.get("gate"),
        "clear_count": computed_clear_count,
        "disposition_count": len(disposition_results),
        "dispositions": disposition_results,
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
        print("status={status} clear_count={clear_count} disposition_count={disposition_count}".format(**result))
        for failure in result["failures"]:
            print(f"FAIL {failure}")
    return 0 if result["status"] == "pass" else 1


if __name__ == "__main__":
    sys.exit(main())

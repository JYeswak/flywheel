#!/usr/bin/env python3
"""Validate the ZestStream holding-company brand naming provenance ledger."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator, FormatChecker


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SCHEMA = ROOT / ".flywheel/validation-schema/v1/holding-company-brand-naming.schema.json"
DEFAULT_LEDGER = ROOT / "state/holding-company-brand-naming.json"
CLEAR_STATUSES = {"name_clear", "launch_clear"}
REQUIRED_CLEAR_REFS = [
    "owner_operator_ref",
    "community_context_ref",
    "naming_decision_ref",
    "brand_identity_ref",
    "public_surface_ref",
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

    row_results: list[dict[str, Any]] = []
    computed_clear_count = 0

    for row in ledger.get("names", []):
        if not isinstance(row, dict):
            continue
        name_id = row.get("name_id")
        status = row.get("status")
        claims_clear = status in CLEAR_STATUSES
        missing_refs = [field for field in REQUIRED_CLEAR_REFS if not has_ref(row.get(field))]
        row_failures: list[dict[str, Any]] = []

        provenance_clear = (
            row.get("own_brand_name") is True
            and row.get("owner_involved_in_name") is True
            and row.get("community_context_in_name") is True
            and not missing_refs
            and row.get("prohibited_name_flags") == []
            and bool(row.get("evidence_refs"))
        )

        if claims_clear and row.get("own_brand_name") is not True:
            row_failures.append({"code": "brand_name_clear_without_own_brand"})
        if claims_clear and row.get("owner_involved_in_name") is not True:
            row_failures.append({"code": "brand_name_clear_without_owner_involvement"})
        if claims_clear and row.get("community_context_in_name") is not True:
            row_failures.append({"code": "brand_name_clear_without_community_context"})
        if claims_clear and missing_refs:
            row_failures.append({"code": "brand_name_clear_missing_refs", "missing_refs": missing_refs})
        if claims_clear and row.get("prohibited_name_flags") != []:
            row_failures.append({"code": "brand_name_clear_with_prohibited_flags", "prohibited_name_flags": row.get("prohibited_name_flags")})
        if claims_clear and not row.get("evidence_refs"):
            row_failures.append({"code": "brand_name_clear_without_evidence_refs"})
        if has_secretish_string(row):
            row_failures.append({"code": "secret_or_raw_value_shape_detected"})

        if check_paths:
            for field in REQUIRED_CLEAR_REFS:
                ref = row.get(field)
                if isinstance(ref, str) and not ref_exists(ref):
                    row_failures.append({"code": "required_ref_missing", "field": field, "ref": ref})
            for ref in row.get("evidence_refs", []):
                if isinstance(ref, str) and not ref_exists(ref):
                    row_failures.append({"code": "evidence_ref_missing", "ref": ref})

        if claims_clear and provenance_clear and not row_failures:
            computed_clear_count += 1
        for failure in row_failures:
            failures.append({"name_id": name_id, **failure})

        row_results.append(
            {
                "name_id": name_id,
                "company_slug": row.get("company_slug"),
                "status": status,
                "brand_name": row.get("brand_name"),
                "missing_refs": missing_refs,
                "own_brand_name": row.get("own_brand_name"),
                "owner_involved_in_name": row.get("owner_involved_in_name"),
                "community_context_in_name": row.get("community_context_in_name"),
                "brand_naming_gate_status": "clear" if claims_clear and provenance_clear and not row_failures else "blocked",
                "failures": row_failures,
            }
        )

    claimed_clear_count = ledger.get("clear_count")
    if claimed_clear_count != computed_clear_count:
        failures.append({"code": "brand_naming_clear_count_mismatch", "claimed": claimed_clear_count, "computed": computed_clear_count})

    return {
        "schema_version": "zeststream.holding_company_brand_naming.validation.v1",
        "status": "fail" if failures else "pass",
        "gate": ledger.get("gate"),
        "clear_count": computed_clear_count,
        "name_count": len(row_results),
        "names": row_results,
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
        print("status={status} clear_count={clear_count} name_count={name_count}".format(**result))
        for failure in result["failures"]:
            print(f"FAIL {failure}")
    return 0 if result["status"] == "pass" else 1


if __name__ == "__main__":
    sys.exit(main())

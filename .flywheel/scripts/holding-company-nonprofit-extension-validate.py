#!/usr/bin/env python3
"""Validate the ZestStream holding-company nonprofit extension ledger."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator, FormatChecker


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SCHEMA = ROOT / ".flywheel/validation-schema/v1/holding-company-nonprofit-extension.schema.json"
DEFAULT_LEDGER = ROOT / "state/holding-company-nonprofit-extension.json"
REQUIRED_REFS = [
    "social_cause_scope_ref",
    "nonprofit_legal_review_ref",
    "governance_model_ref",
    "operating_separation_ref",
    "funding_policy_ref",
    "public_story_ref",
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
    initiative_results: list[dict[str, Any]] = []

    for initiative in ledger.get("initiatives", []):
        if not isinstance(initiative, dict):
            continue
        initiative_id = initiative.get("initiative_id")
        status = initiative.get("status")
        missing_refs = [field for field in REQUIRED_REFS if not has_ref(initiative.get(field))]
        initiative_failures: list[dict[str, Any]] = []
        readiness_clear = (
            status in {"ready", "active"}
            and not missing_refs
            and initiative.get("portfolio_company_counting_excluded") is True
            and initiative.get("commingled_owner_economics_detected") is False
        )

        if status in {"ready", "active"} and missing_refs:
            initiative_failures.append({"code": "nonprofit_ready_missing_refs", "missing_refs": missing_refs})
        if status in {"ready", "active"} and initiative.get("portfolio_company_counting_excluded") is not True:
            initiative_failures.append({"code": "nonprofit_ready_counted_as_portfolio_company"})
        if status in {"ready", "active"} and initiative.get("commingled_owner_economics_detected") is not False:
            initiative_failures.append({"code": "nonprofit_ready_with_commingled_owner_economics"})
        if has_secretish_string(initiative):
            initiative_failures.append({"code": "secret_or_raw_value_shape_detected"})

        if check_paths:
            for field in REQUIRED_REFS:
                ref = initiative.get(field)
                if isinstance(ref, str) and not ref_exists(ref):
                    initiative_failures.append({"code": "required_ref_missing", "field": field, "ref": ref})
            for ref in initiative.get("evidence_refs", []):
                if isinstance(ref, str) and not ref_exists(ref):
                    initiative_failures.append({"code": "evidence_ref_missing", "ref": ref})

        if readiness_clear and not initiative_failures:
            computed_clear_count += 1
        for failure in initiative_failures:
            failures.append({"initiative_id": initiative_id, **failure})

        initiative_results.append(
            {
                "initiative_id": initiative_id,
                "status": status,
                "missing_refs": missing_refs,
                "portfolio_company_counting_excluded": initiative.get("portfolio_company_counting_excluded"),
                "commingled_owner_economics_detected": initiative.get("commingled_owner_economics_detected"),
                "nonprofit_extension_gate_status": "clear" if readiness_clear and not initiative_failures else "blocked",
                "failures": initiative_failures,
            }
        )

    claimed_clear_count = ledger.get("clear_count")
    if claimed_clear_count != computed_clear_count:
        failures.append({"code": "clear_count_mismatch", "claimed": claimed_clear_count, "computed": computed_clear_count})

    return {
        "schema_version": "zeststream.holding_company_nonprofit_extension.validation.v1",
        "status": "fail" if failures else "pass",
        "gate": ledger.get("gate"),
        "clear_count": computed_clear_count,
        "initiative_count": len(initiative_results),
        "initiatives": initiative_results,
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
        print("status={status} clear_count={clear_count} initiative_count={initiative_count}".format(**result))
        for failure in result["failures"]:
            print(f"FAIL {failure}")
    return 0 if result["status"] == "pass" else 1


if __name__ == "__main__":
    sys.exit(main())

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-02-conformance-fixtures.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-68-schema-executable-validator-pair.md`

#!/usr/bin/env python3
"""Validate the ZestStream holding-company NURTURE peer-coach ledger."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator, FormatChecker


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SCHEMA = ROOT / ".flywheel/validation-schema/v1/holding-company-peer-coach.schema.json"
DEFAULT_LEDGER = ROOT / "state/holding-company-peer-coach.json"
REQUIRED_REFS = [
    "sustainable_cash_position_ref",
    "operating_control_ref",
    "peer_coach_agreement_ref",
    "equity_grant_ref",
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

    min_tier = ledger.get("required_min_owner_tier", 2)
    required_equity = ledger.get("required_peer_coach_equity_percent", 5)
    coach_results: list[dict[str, Any]] = []
    computed_clear_count = 0

    for coach in ledger.get("peer_coaches", []):
        if not isinstance(coach, dict):
            continue
        coach_id = coach.get("coach_id")
        status = coach.get("status")
        owner_tier = coach.get("owner_tier")
        equity = coach.get("equity_grant_percent")
        missing_refs = [field for field in REQUIRED_REFS if not has_ref(coach.get(field))]
        tier_ok = isinstance(owner_tier, int) and owner_tier >= min_tier
        equity_ok = isinstance(equity, (int, float)) and not isinstance(equity, bool) and equity == required_equity
        clear = status in {"eligible", "active"} and tier_ok and equity_ok and not missing_refs
        coach_failures: list[dict[str, Any]] = []

        if status in {"eligible", "active"} and not tier_ok:
            coach_failures.append({"code": "peer_coach_status_without_tier_2_owner", "owner_tier": owner_tier})
        if status in {"eligible", "active"} and missing_refs:
            coach_failures.append({"code": "peer_coach_status_missing_refs", "missing_refs": missing_refs})
        if status in {"eligible", "active"} and not equity_ok:
            coach_failures.append({"code": "peer_coach_equity_percent_mismatch", "expected": required_equity, "actual": equity})
        if has_secretish_string(coach):
            coach_failures.append({"code": "secret_or_raw_amount_shape_detected"})

        if check_paths:
            for field in REQUIRED_REFS:
                ref = coach.get(field)
                if isinstance(ref, str) and not ref_exists(ref):
                    coach_failures.append({"code": "required_ref_missing", "field": field, "ref": ref})
            for ref in coach.get("evidence_refs", []):
                if isinstance(ref, str) and not ref_exists(ref):
                    coach_failures.append({"code": "evidence_ref_missing", "ref": ref})

        if clear and not coach_failures:
            computed_clear_count += 1
        for failure in coach_failures:
            failures.append({"coach_id": coach_id, **failure})

        coach_results.append(
            {
                "coach_id": coach_id,
                "owner_company_slug": coach.get("owner_company_slug"),
                "target_company_slug": coach.get("target_company_slug"),
                "status": status,
                "owner_tier": owner_tier,
                "equity_grant_percent": equity,
                "missing_refs": missing_refs,
                "peer_coach_gate_status": "clear" if clear and not coach_failures else "blocked",
                "failures": coach_failures,
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
        "schema_version": "zeststream.holding_company_peer_coach.validation.v1",
        "status": "fail" if failures else "pass",
        "gate": ledger.get("gate"),
        "required_min_owner_tier": min_tier,
        "required_peer_coach_equity_percent": required_equity,
        "clear_count": computed_clear_count,
        "peer_coach_count": len(coach_results),
        "peer_coaches": coach_results,
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
        print("status={status} clear_count={clear_count} peer_coach_count={peer_coach_count}".format(**result))
        for failure in result["failures"]:
            print(f"FAIL {failure}")
    return 0 if result["status"] == "pass" else 1


if __name__ == "__main__":
    sys.exit(main())

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-02-conformance-fixtures.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-68-schema-executable-validator-pair.md`

#!/usr/bin/env python3
"""Validate the ZestStream holding-company post-launch coach role ledger."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator, FormatChecker


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SCHEMA = ROOT / ".flywheel/validation-schema/v1/holding-company-coach-role.schema.json"
DEFAULT_LEDGER = ROOT / "state/holding-company-coach-role.json"
REQUIRED_REFS = [
    "owner_operator_ref",
    "operating_control_handoff_ref",
    "coach_role_agreement_ref",
    "majority_stake_ref",
    "owner_operating_control_ack_ref",
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

    required_min_stake = ledger.get("required_min_holding_stake_percent", 51)
    computed_clear_count = 0
    role_results: list[dict[str, Any]] = []

    for role in ledger.get("roles", []):
        if not isinstance(role, dict):
            continue
        role_id = role.get("role_id")
        status = role.get("status")
        stake = role.get("holding_stake_percent")
        missing_refs = [field for field in REQUIRED_REFS if not has_ref(role.get(field))]
        role_failures: list[dict[str, Any]] = []
        signed_or_active = status in {"coach_role_clear", "active"}
        stake_ok = isinstance(stake, (int, float)) and not isinstance(stake, bool) and stake >= required_min_stake

        if signed_or_active and missing_refs:
            role_failures.append({"code": "coach_role_clear_missing_refs", "missing_refs": missing_refs})
        if signed_or_active and not stake_ok:
            role_failures.append({"code": "holding_stake_below_majority", "required_min": required_min_stake, "actual": stake})
        if has_secretish_string(role):
            role_failures.append({"code": "secret_or_raw_value_shape_detected"})

        if check_paths:
            for field in REQUIRED_REFS:
                ref = role.get(field)
                if isinstance(ref, str) and not ref_exists(ref):
                    role_failures.append({"code": "required_ref_missing", "field": field, "ref": ref})
            for ref in role.get("evidence_refs", []):
                if isinstance(ref, str) and not ref_exists(ref):
                    role_failures.append({"code": "evidence_ref_missing", "ref": ref})

        clear = signed_or_active and not missing_refs and stake_ok
        if clear and not role_failures:
            computed_clear_count += 1
        for failure in role_failures:
            failures.append({"role_id": role_id, **failure})

        role_results.append(
            {
                "role_id": role_id,
                "company_slug": role.get("company_slug"),
                "status": status,
                "holding_stake_percent": stake,
                "missing_refs": missing_refs,
                "coach_role_gate_status": "clear" if clear and not role_failures else "blocked",
                "failures": role_failures,
            }
        )

    claimed_clear_count = ledger.get("clear_count")
    if claimed_clear_count != computed_clear_count:
        failures.append({"code": "clear_count_mismatch", "claimed": claimed_clear_count, "computed": computed_clear_count})

    return {
        "schema_version": "zeststream.holding_company_coach_role.validation.v1",
        "status": "fail" if failures else "pass",
        "gate": ledger.get("gate"),
        "required_min_holding_stake_percent": required_min_stake,
        "clear_count": computed_clear_count,
        "role_count": len(role_results),
        "roles": role_results,
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
        print("status={status} clear_count={clear_count} role_count={role_count}".format(**result))
        for failure in result["failures"]:
            print(f"FAIL {failure}")
    return 0 if result["status"] == "pass" else 1


if __name__ == "__main__":
    sys.exit(main())

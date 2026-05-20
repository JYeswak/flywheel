#!/usr/bin/env python3
"""Validate the ZestStream holding-company owner-economics ledger."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator, FormatChecker


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SCHEMA = ROOT / ".flywheel/validation-schema/v1/holding-company-owner-economics.schema.json"
DEFAULT_LEDGER = ROOT / "state/holding-company-owner-economics.json"
REQUIRED_REFS = [
    "signed_owner_operator_receipt",
    "cap_table_ref",
    "distribution_terms_ref",
    "legal_review_ref",
    "substrate_share_receipt",
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

    required_owner_equity = ledger.get("required_owner_equity_percent", 25)
    distribution_min = ledger.get("owner_distribution_min_percent", 45)
    distribution_max = ledger.get("owner_distribution_max_percent", 75)
    deal_results: list[dict[str, Any]] = []
    computed_clear_count = 0

    for deal in ledger.get("deals", []):
        if not isinstance(deal, dict):
            continue
        deal_id = deal.get("deal_id")
        status = deal.get("status")
        owner_equity = deal.get("owner_equity_percent")
        holding_equity = deal.get("holding_company_equity_percent")
        tiers = deal.get("profit_distribution_tiers", [])
        missing_refs = [field for field in REQUIRED_REFS if not has_ref(deal.get(field))]
        deal_failures: list[dict[str, Any]] = []

        owner_equity_ok = (
            isinstance(owner_equity, (int, float))
            and not isinstance(owner_equity, bool)
            and owner_equity == required_owner_equity
        )
        holding_equity_ok = (
            isinstance(holding_equity, (int, float))
            and not isinstance(holding_equity, bool)
            and owner_equity_ok
            and holding_equity + owner_equity == 100
        )

        distribution_values = [
            tier.get("owner_distribution_percent")
            for tier in tiers
            if isinstance(tier, dict)
        ]
        distribution_values = [
            value
            for value in distribution_values
            if isinstance(value, (int, float)) and not isinstance(value, bool)
        ]
        has_tiered_distribution = len(distribution_values) >= 2
        distribution_bounds_ok = (
            has_tiered_distribution
            and min(distribution_values) == distribution_min
            and max(distribution_values) == distribution_max
            and all(distribution_min <= value <= distribution_max for value in distribution_values)
        )
        missing_tier_basis_refs = [
            tier.get("tier_id")
            for tier in tiers
            if isinstance(tier, dict) and not has_ref(tier.get("basis_ref"))
        ]

        signed_or_active = status in {"signed", "active"}
        clear = (
            signed_or_active
            and owner_equity_ok
            and holding_equity_ok
            and distribution_bounds_ok
            and not missing_refs
            and not missing_tier_basis_refs
        )

        if signed_or_active and not has_ref(deal.get("owner_operator_slug")):
            deal_failures.append({"code": "signed_status_without_owner_operator"})
        if signed_or_active and not owner_equity_ok:
            deal_failures.append(
                {"code": "owner_equity_percent_mismatch", "expected": required_owner_equity, "actual": owner_equity}
            )
        if signed_or_active and not holding_equity_ok:
            deal_failures.append({"code": "holding_company_equity_percent_mismatch", "actual": holding_equity})
        if signed_or_active and missing_refs:
            deal_failures.append({"code": "owner_economics_status_missing_refs", "missing_refs": missing_refs})
        if signed_or_active and not has_tiered_distribution:
            deal_failures.append({"code": "profit_distribution_not_tiered", "tier_count": len(distribution_values)})
        if signed_or_active and has_tiered_distribution and not distribution_bounds_ok:
            deal_failures.append(
                {
                    "code": "profit_distribution_bounds_mismatch",
                    "expected_min": distribution_min,
                    "expected_max": distribution_max,
                    "actual_values": distribution_values,
                }
            )
        if signed_or_active and missing_tier_basis_refs:
            deal_failures.append({"code": "profit_distribution_tier_missing_basis_ref", "tier_ids": missing_tier_basis_refs})
        if has_secretish_string(deal):
            deal_failures.append({"code": "secret_or_raw_amount_shape_detected"})

        if check_paths:
            for field in REQUIRED_REFS:
                ref = deal.get(field)
                if isinstance(ref, str) and not ref_exists(ref):
                    deal_failures.append({"code": "required_ref_missing", "field": field, "ref": ref})
            for ref in deal.get("evidence_refs", []):
                if isinstance(ref, str) and not ref_exists(ref):
                    deal_failures.append({"code": "evidence_ref_missing", "ref": ref})

        if clear and not deal_failures:
            computed_clear_count += 1
        for failure in deal_failures:
            failures.append({"deal_id": deal_id, **failure})

        deal_results.append(
            {
                "deal_id": deal_id,
                "company_slug": deal.get("company_slug"),
                "status": status,
                "owner_operator_slug": deal.get("owner_operator_slug"),
                "owner_equity_percent": owner_equity,
                "holding_company_equity_percent": holding_equity,
                "profit_distribution_values": distribution_values,
                "missing_refs": missing_refs,
                "owner_economics_gate_status": "clear" if clear and not deal_failures else "blocked",
                "failures": deal_failures,
            }
        )

    claimed_clear_count = ledger.get("clear_count")
    if claimed_clear_count != computed_clear_count:
        failures.append({"code": "clear_count_mismatch", "claimed": claimed_clear_count, "computed": computed_clear_count})

    return {
        "schema_version": "zeststream.holding_company_owner_economics.validation.v1",
        "status": "fail" if failures else "pass",
        "gate": ledger.get("gate"),
        "required_owner_equity_percent": required_owner_equity,
        "owner_distribution_min_percent": distribution_min,
        "owner_distribution_max_percent": distribution_max,
        "clear_count": computed_clear_count,
        "deal_count": len(deal_results),
        "deals": deal_results,
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
        print("status={status} clear_count={clear_count} deal_count={deal_count}".format(**result))
        for failure in result["failures"]:
            print(f"FAIL {failure}")
    return 0 if result["status"] == "pass" else 1


if __name__ == "__main__":
    sys.exit(main())

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-02-conformance-fixtures.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-68-schema-executable-validator-pair.md`

#!/usr/bin/env python3
"""Validate the ZestStream holding-company operating-health ledger."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator, FormatChecker


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SCHEMA = ROOT / ".flywheel/validation-schema/v1/holding-company-operating-health.schema.json"
DEFAULT_LEDGER = ROOT / "state/holding-company-operating-health.json"
CLEAR_STATUSES = {"revenue_clear", "profit_clear"}
REQUIRED_REVENUE_REFS = [
    "first_paying_customer_receipt",
    "revenue_snapshot_ref",
    "owner_operator_report_ref",
    "operating_control_ref",
    "substrate_share_receipt",
]
REQUIRED_PROFIT_REFS = REQUIRED_REVENUE_REFS + [
    "positive_gross_profit_ref",
    "owner_distribution_ref",
]
SECRETISH_RE = re.compile(r"(\$[A-Za-z_][A-Za-z0-9_]*|sk-[A-Za-z0-9]|AKIA[0-9A-Z]{16})")
RAW_AMOUNT_RE = re.compile(r"(?<![A-Za-z0-9])(?:USD\s*)?\$\s?[0-9][0-9,]*(?:\.[0-9]{2})?\b|\b[0-9][0-9,]+\s?(?:USD|dollars)\b")


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


def has_raw_amount(value: Any) -> bool:
    if isinstance(value, str):
        return bool(RAW_AMOUNT_RE.search(value))
    if isinstance(value, dict):
        return any(has_raw_amount(v) for v in value.values())
    if isinstance(value, list):
        return any(has_raw_amount(v) for v in value)
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

    company_results: list[dict[str, Any]] = []
    computed_clear_count = 0

    for company in ledger.get("companies", []):
        if not isinstance(company, dict):
            continue
        health_id = company.get("health_id")
        status = company.get("status")
        claims_clear = status in CLEAR_STATUSES
        required_refs = REQUIRED_PROFIT_REFS if status == "profit_clear" else REQUIRED_REVENUE_REFS
        missing_refs = [field for field in required_refs if not has_ref(company.get(field))]
        company_failures: list[dict[str, Any]] = []

        clear = (
            claims_clear
            and not missing_refs
            and company.get("metrics_are_redacted") is True
            and company.get("raw_amounts_present") is False
            and bool(company.get("evidence_refs"))
        )

        if claims_clear and missing_refs:
            company_failures.append({"code": "operating_health_clear_missing_refs", "missing_refs": missing_refs})
        if claims_clear and company.get("metrics_are_redacted") is not True:
            company_failures.append({"code": "operating_health_clear_without_redacted_metrics"})
        if claims_clear and company.get("raw_amounts_present") is not False:
            company_failures.append({"code": "operating_health_clear_with_raw_amounts_flag"})
        if claims_clear and not company.get("evidence_refs"):
            company_failures.append({"code": "operating_health_clear_without_evidence_refs"})
        if has_raw_amount(company):
            company_failures.append({"code": "raw_amount_shape_detected"})
        if has_secretish_string(company):
            company_failures.append({"code": "secret_or_raw_value_shape_detected"})

        if check_paths:
            for field in set(REQUIRED_PROFIT_REFS):
                ref = company.get(field)
                if isinstance(ref, str) and not ref_exists(ref):
                    company_failures.append({"code": "required_ref_missing", "field": field, "ref": ref})
            for ref in company.get("evidence_refs", []):
                if isinstance(ref, str) and not ref_exists(ref):
                    company_failures.append({"code": "evidence_ref_missing", "ref": ref})

        if clear and not company_failures:
            computed_clear_count += 1
        for failure in company_failures:
            failures.append({"health_id": health_id, **failure})

        company_results.append(
            {
                "health_id": health_id,
                "company_slug": company.get("company_slug"),
                "status": status,
                "metrics_are_redacted": company.get("metrics_are_redacted"),
                "raw_amounts_present": company.get("raw_amounts_present"),
                "missing_refs": missing_refs,
                "operating_health_gate_status": "clear" if clear and not company_failures else "blocked",
                "failures": company_failures,
            }
        )

    claimed_clear_count = ledger.get("clear_count")
    if claimed_clear_count != computed_clear_count:
        failures.append({"code": "operating_health_clear_count_mismatch", "claimed": claimed_clear_count, "computed": computed_clear_count})

    return {
        "schema_version": "zeststream.holding_company_operating_health.validation.v1",
        "status": "fail" if failures else "pass",
        "gate": ledger.get("gate"),
        "clear_count": computed_clear_count,
        "company_count": len(company_results),
        "companies": company_results,
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
        print("status={status} clear_count={clear_count} company_count={company_count}".format(**result))
        for failure in result["failures"]:
            print(f"FAIL {failure}")
    return 0 if result["status"] == "pass" else 1


if __name__ == "__main__":
    sys.exit(main())

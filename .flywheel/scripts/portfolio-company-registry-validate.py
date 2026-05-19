#!/usr/bin/env python3
"""Validate the ZestStream portfolio-company registry gate."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator, FormatChecker


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_REGISTRY = ROOT / "state/zeststream-portfolio-company-registry.json"
DEFAULT_SCHEMA = ROOT / ".flywheel/validation-schema/v1/portfolio-company-registry.schema.json"
COUNTED_STATUSES = {"formed", "graduated", "pivoted", "closed"}
REQUIRED_RECEIPTS = [
    "signed_owner_operator_receipt",
    "equity_receipt",
    "first_paying_customer_receipt",
    "substrate_share_receipt",
]


def load_json(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def local_ref_exists(ref: str, base_dir: Path) -> bool:
    if "://" in ref or ref.startswith("urn:"):
        return True
    path = Path(ref)
    if not path.is_absolute():
        path = base_dir / ref
    return path.exists()


def validate_registry(registry: dict[str, Any], schema: dict[str, Any], *, check_paths: bool, base_dir: Path) -> dict[str, Any]:
    failures: list[dict[str, str]] = []
    rows: list[dict[str, Any]] = []

    try:
        Draft202012Validator.check_schema(schema)
        Draft202012Validator(schema, format_checker=FormatChecker()).validate(registry)
    except Exception as exc:  # jsonschema exceptions have useful messages.
        failures.append({"code": "schema_invalid", "detail": str(exc)})

    counted_rows = 0
    for company in registry.get("companies", []):
        if not isinstance(company, dict):
            continue
        slug = str(company.get("slug", "<missing>"))
        status = company.get("portfolio_company_status")
        counted = bool(company.get("counted_as_portfolio_company"))
        gate_evidence = company.get("gate_evidence") if isinstance(company.get("gate_evidence"), dict) else {}
        row_failures: list[str] = []

        if counted:
            counted_rows += 1
            if status not in COUNTED_STATUSES:
                row_failures.append("counted_status_not_formed")

        if status in COUNTED_STATUSES and not counted:
            row_failures.append("formed_status_not_counted")

        if counted or status in COUNTED_STATUSES:
            for field in REQUIRED_RECEIPTS:
                value = gate_evidence.get(field)
                if not isinstance(value, str) or not value.strip():
                    row_failures.append(f"missing_required_receipt:{field}")
                elif check_paths and not local_ref_exists(value, base_dir):
                    row_failures.append(f"receipt_path_missing:{field}")

        if check_paths:
            for ref in company.get("evidence_refs", []):
                if isinstance(ref, str) and not local_ref_exists(ref, base_dir):
                    row_failures.append(f"evidence_ref_missing:{ref}")

        for failure in row_failures:
            failures.append({"code": failure, "slug": slug})

        rows.append(
            {
                "slug": slug,
                "status": status,
                "counted_as_portfolio_company": counted,
                "row_status": "fail" if row_failures else "pass",
                "failures": row_failures,
            }
        )

    declared_count = registry.get("counted_portfolio_companies")
    if declared_count != counted_rows:
        failures.append(
            {
                "code": "counted_portfolio_company_total_mismatch",
                "detail": f"declared={declared_count} actual={counted_rows}",
            }
        )

    return {
        "schema_version": "zeststream.portfolio_company_registry.validation.v1",
        "registry": str(DEFAULT_REGISTRY if base_dir == ROOT else base_dir),
        "status": "fail" if failures else "pass",
        "counted_portfolio_companies": counted_rows,
        "declared_counted_portfolio_companies": declared_count,
        "check_paths": check_paths,
        "rows": rows,
        "failures": failures,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--registry", type=Path, default=DEFAULT_REGISTRY)
    parser.add_argument("--schema", type=Path, default=DEFAULT_SCHEMA)
    parser.add_argument("--check-paths", action="store_true")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    registry = load_json(args.registry)
    schema = load_json(args.schema)
    result = validate_registry(
        registry,
        schema,
        check_paths=args.check_paths,
        base_dir=ROOT,
    )

    if args.json:
        print(json.dumps(result, indent=2, sort_keys=True))
    else:
        print(f"status={result['status']} counted={result['counted_portfolio_companies']}")
        for failure in result["failures"]:
            print(f"FAIL {failure}")

    return 0 if result["status"] == "pass" else 1


if __name__ == "__main__":
    sys.exit(main())

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-02-conformance-fixtures.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-68-schema-executable-validator-pair.md`

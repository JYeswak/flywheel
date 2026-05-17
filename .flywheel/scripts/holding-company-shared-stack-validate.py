#!/usr/bin/env python3
"""Validate the ZestStream holding-company NURTURE shared-stack ledger."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator, FormatChecker


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SCHEMA = ROOT / ".flywheel/validation-schema/v1/holding-company-shared-stack.schema.json"
DEFAULT_LEDGER = ROOT / "state/holding-company-shared-stack.json"
REQUIRED_COMPONENTS = {"skillos", "flywheel", "jsm", "zeststream_packages", "brand_voice"}
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

    declared_components = set(ledger.get("required_components", []))
    if declared_components != REQUIRED_COMPONENTS:
        failures.append(
            {
                "code": "required_components_mismatch",
                "declared": sorted(declared_components),
                "expected": sorted(REQUIRED_COMPONENTS),
            }
        )

    company_results: list[dict[str, Any]] = []
    computed_clear_count = 0

    for company in ledger.get("companies", []):
        if not isinstance(company, dict):
            continue
        company_slug = company.get("company_slug")
        status = company.get("status")
        component_rows = [row for row in company.get("components", []) if isinstance(row, dict)]
        by_component = {row.get("component"): row for row in component_rows}
        missing_components = sorted(REQUIRED_COMPONENTS - set(by_component))
        duplicate_components = sorted(
            component
            for component in REQUIRED_COMPONENTS
            if sum(1 for row in component_rows if row.get("component") == component) > 1
        )
        component_failures: list[dict[str, Any]] = []
        component_statuses: dict[str, str | None] = {}

        for component in sorted(REQUIRED_COMPONENTS):
            row = by_component.get(component)
            if not row:
                continue
            component_statuses[component] = row.get("status")
            if status == "shared_stack_clear" and row.get("status") != "present":
                component_failures.append(
                    {"code": "shared_stack_clear_component_not_present", "component": component, "status": row.get("status")}
                )
            if status == "shared_stack_clear" and not has_ref(row.get("receipt_ref")):
                component_failures.append({"code": "shared_stack_clear_component_missing_receipt", "component": component})
            if has_secretish_string(row):
                component_failures.append({"code": "secret_or_raw_amount_shape_detected", "component": component})
            if check_paths:
                ref = row.get("receipt_ref")
                if isinstance(ref, str) and not ref_exists(ref):
                    component_failures.append({"code": "component_receipt_missing", "component": component, "ref": ref})
                for evidence_ref in row.get("evidence_refs", []):
                    if isinstance(evidence_ref, str) and not ref_exists(evidence_ref):
                        component_failures.append(
                            {"code": "component_evidence_ref_missing", "component": component, "ref": evidence_ref}
                        )

        if missing_components:
            component_failures.append({"code": "missing_required_components", "components": missing_components})
        if duplicate_components:
            component_failures.append({"code": "duplicate_required_components", "components": duplicate_components})
        if status == "shared_stack_clear" and missing_components:
            component_failures.append({"code": "shared_stack_clear_missing_components", "components": missing_components})

        if check_paths:
            for ref in company.get("evidence_refs", []):
                if isinstance(ref, str) and not ref_exists(ref):
                    component_failures.append({"code": "company_evidence_ref_missing", "ref": ref})

        all_present = (
            not missing_components
            and not duplicate_components
            and all(by_component[component].get("status") == "present" and has_ref(by_component[component].get("receipt_ref")) for component in REQUIRED_COMPONENTS)
        )
        clear = status == "shared_stack_clear" and all_present
        if clear and not component_failures:
            computed_clear_count += 1
        for failure in component_failures:
            failures.append({"company_slug": company_slug, **failure})

        company_results.append(
            {
                "company_slug": company_slug,
                "status": status,
                "component_statuses": component_statuses,
                "missing_components": missing_components,
                "shared_stack_gate_status": "clear" if clear and not component_failures else "blocked",
                "failures": component_failures,
            }
        )

    claimed_clear_count = ledger.get("clear_count")
    if claimed_clear_count != computed_clear_count:
        failures.append({"code": "clear_count_mismatch", "claimed": claimed_clear_count, "computed": computed_clear_count})

    return {
        "schema_version": "zeststream.holding_company_shared_stack.validation.v1",
        "status": "fail" if failures else "pass",
        "gate": ledger.get("gate"),
        "required_components": sorted(REQUIRED_COMPONENTS),
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

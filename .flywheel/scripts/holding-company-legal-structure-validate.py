#!/usr/bin/env python3
"""Validate the ZestStream holding-company legal-structure readiness ledger."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator, FormatChecker


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SCHEMA = ROOT / ".flywheel/validation-schema/v1/holding-company-legal-structure.schema.json"
DEFAULT_LEDGER = ROOT / "state/holding-company-legal-structure.json"
REQUIRED_BEFORE_SUB_2 = {
    "holding_company_operating_agreement",
    "peer_coach_equity_pathway",
    "annual_tier_review_process",
    "substrate_contributor_pool",
    "subsidiary_owner_operating_agreement",
    "intercompany_services_agreement",
}
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


def validate_ledger(ledger: dict[str, Any], schema: dict[str, Any], *, check_paths: bool) -> dict[str, Any]:
    failures: list[dict[str, Any]] = []
    try:
        Draft202012Validator.check_schema(schema)
        Draft202012Validator(schema, format_checker=FormatChecker()).validate(ledger)
    except Exception as exc:
        failures.append({"code": "schema_invalid", "detail": str(exc)})

    requirement_results: list[dict[str, Any]] = []
    computed_clear_count = 0
    seen_requirements: set[str] = set()

    for requirement in ledger.get("requirements", []):
        if not isinstance(requirement, dict):
            continue
        requirement_id = requirement.get("requirement_id")
        seen_requirements.add(requirement_id)
        status = requirement.get("status")
        binding_ref = requirement.get("binding_artifact_ref")
        attorney_ref = requirement.get("attorney_review_ref")
        cpa_ref = requirement.get("cpa_review_ref")
        requirement_failures: list[dict[str, Any]] = []

        has_binding = isinstance(binding_ref, str) and bool(binding_ref.strip())
        has_attorney = isinstance(attorney_ref, str) and bool(attorney_ref.strip())
        has_cpa = isinstance(cpa_ref, str) and bool(cpa_ref.strip())
        clear = status == "cleared" and has_binding and has_attorney and has_cpa

        if status == "cleared" and not clear:
            requirement_failures.append({"code": "cleared_status_without_binding_and_review_refs"})
        if status in {"attorney_reviewed", "cpa_reviewed"} and not has_binding:
            requirement_failures.append({"code": "review_status_without_binding_artifact_ref"})
        if has_secretish_string(requirement):
            requirement_failures.append({"code": "secret_or_raw_amount_shape_detected"})

        if check_paths:
            for field, ref in [
                ("binding_artifact_ref", binding_ref),
                ("attorney_review_ref", attorney_ref),
                ("cpa_review_ref", cpa_ref),
            ]:
                if isinstance(ref, str) and not ref_exists(ref):
                    requirement_failures.append({"code": "required_ref_missing", "field": field, "ref": ref})
            for ref in requirement.get("evidence_refs", []):
                if isinstance(ref, str) and not ref_exists(ref):
                    requirement_failures.append({"code": "evidence_ref_missing", "ref": ref})

        if clear and not requirement_failures:
            computed_clear_count += 1
        for failure in requirement_failures:
            failures.append({"requirement_id": requirement_id, **failure})

        requirement_results.append(
            {
                "requirement_id": requirement_id,
                "status": status,
                "blocks_before_sub_sequence": requirement.get("blocks_before_sub_sequence"),
                "legal_gate_status": "clear" if clear and not requirement_failures else "blocked",
                "failures": requirement_failures,
            }
        )

    missing = sorted(REQUIRED_BEFORE_SUB_2 - seen_requirements)
    for requirement_id in missing:
        failures.append({"code": "missing_required_legal_structure_requirement", "requirement_id": requirement_id})

    claimed_clear_count = ledger.get("clear_count")
    if claimed_clear_count != computed_clear_count:
        failures.append(
            {
                "code": "clear_count_mismatch",
                "claimed": claimed_clear_count,
                "computed": computed_clear_count,
            }
        )

    sub_2_gate_status = "clear" if not failures and computed_clear_count >= len(REQUIRED_BEFORE_SUB_2) else "blocked"
    return {
        "schema_version": "zeststream.holding_company_legal_structure.validation.v1",
        "status": "fail" if failures else "pass",
        "gate": ledger.get("gate"),
        "sub_2_owner_signing_gate_status": sub_2_gate_status,
        "clear_count": computed_clear_count,
        "required_count": len(REQUIRED_BEFORE_SUB_2),
        "requirements": requirement_results,
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
        print(
            "status={status} sub_2_owner_signing_gate_status={sub_2_owner_signing_gate_status} clear_count={clear_count}".format(
                **result
            )
        )
        for failure in result["failures"]:
            print(f"FAIL {failure}")
    return 0 if result["status"] == "pass" else 1


if __name__ == "__main__":
    sys.exit(main())

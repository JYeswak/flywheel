#!/usr/bin/env python3
"""Validate the ZestStream holding-company candidate-fit ledger."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator, FormatChecker


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SCHEMA = ROOT / ".flywheel/validation-schema/v1/holding-company-candidate-fit.schema.json"
DEFAULT_LEDGER = ROOT / "state/holding-company-candidate-fit.json"
CLEAR_STATUSES = {"candidate_clear", "press_clear", "formation_clear"}
FIT_CLASSIFICATIONS = {"sharpen_legacy_smb", "incubate_ai_first"}
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


def has_text(value: Any) -> bool:
    return isinstance(value, str) and bool(value.strip())


def problem_fit_clear(candidate: dict[str, Any]) -> bool:
    classification = candidate.get("classification")
    if classification == "sharpen_legacy_smb":
        return candidate.get("ai_transition_pain_present") is True
    if classification == "incubate_ai_first":
        return candidate.get("ai_first_opportunity_present") is True
    return False


def validate_ledger(ledger: dict[str, Any], schema: dict[str, Any], *, check_paths: bool) -> dict[str, Any]:
    failures: list[dict[str, Any]] = []
    try:
        Draft202012Validator.check_schema(schema)
        Draft202012Validator(schema, format_checker=FormatChecker()).validate(ledger)
    except Exception as exc:
        failures.append({"code": "schema_invalid", "detail": str(exc)})

    candidate_results: list[dict[str, Any]] = []
    computed_clear_count = 0

    for candidate in ledger.get("candidates", []):
        if not isinstance(candidate, dict):
            continue
        slug = candidate.get("candidate_slug")
        status = candidate.get("status")
        classification = candidate.get("classification")
        target_customer = candidate.get("target_customer")
        claims_clear = status in CLEAR_STATUSES

        classification_clear = classification in FIT_CLASSIFICATIONS and has_ref(candidate.get("classification_ref"))
        owner_operator_clear = (
            target_customer == "smb_owner_operator"
            and candidate.get("smb_owner_operator_fit") is True
            and has_ref(candidate.get("persona_ref"))
        )
        problem_clear = problem_fit_clear(candidate) and has_text(candidate.get("problem_statement")) and has_ref(candidate.get("problem_ref"))
        target_clear = candidate.get("target_drift_flags") == []
        evidence_clear = bool(candidate.get("evidence_refs"))
        fit_clear = classification_clear and owner_operator_clear and problem_clear and target_clear and evidence_clear

        row_failures: list[dict[str, Any]] = []
        if claims_clear and not classification_clear:
            row_failures.append(
                {
                    "code": "candidate_fit_clear_without_classification",
                    "classification": classification,
                    "allowed_classifications": sorted(FIT_CLASSIFICATIONS),
                }
            )
        if claims_clear and not owner_operator_clear:
            row_failures.append(
                {
                    "code": "candidate_fit_clear_without_smb_owner_operator",
                    "target_customer": target_customer,
                    "smb_owner_operator_fit": candidate.get("smb_owner_operator_fit"),
                }
            )
        if claims_clear and not problem_clear:
            row_failures.append(
                {
                    "code": "candidate_fit_clear_without_ai_problem_fit",
                    "classification": classification,
                    "ai_transition_pain_present": candidate.get("ai_transition_pain_present"),
                    "ai_first_opportunity_present": candidate.get("ai_first_opportunity_present"),
                }
            )
        if claims_clear and not target_clear:
            row_failures.append(
                {
                    "code": "candidate_fit_clear_with_target_drift",
                    "target_drift_flags": candidate.get("target_drift_flags"),
                }
            )
        if claims_clear and not evidence_clear:
            row_failures.append({"code": "candidate_fit_clear_without_evidence_refs"})
        if has_secretish_string(candidate):
            row_failures.append({"code": "secret_or_raw_value_shape_detected"})

        if check_paths:
            for key in ("classification_ref", "persona_ref", "problem_ref"):
                ref = candidate.get(key)
                if isinstance(ref, str) and not ref_exists(ref):
                    row_failures.append({"code": f"{key}_missing", "ref": ref})
            for ref in candidate.get("evidence_refs", []):
                if isinstance(ref, str) and not ref_exists(ref):
                    row_failures.append({"code": "evidence_ref_missing", "ref": ref})

        if claims_clear and fit_clear and not row_failures:
            computed_clear_count += 1
        for failure in row_failures:
            failures.append({"candidate_slug": slug, **failure})

        candidate_results.append(
            {
                "candidate_slug": slug,
                "status": status,
                "classification": classification,
                "target_customer": target_customer,
                "classification_status": "clear" if classification_clear else "blocked",
                "owner_operator_status": "clear" if owner_operator_clear else "blocked",
                "problem_fit_status": "clear" if problem_clear else "blocked",
                "target_drift_status": "clear" if target_clear else "blocked",
                "candidate_fit_gate_status": "clear" if claims_clear and fit_clear and not row_failures else "blocked",
                "failures": row_failures,
            }
        )

    claimed_clear_count = ledger.get("clear_count")
    if claimed_clear_count != computed_clear_count:
        failures.append(
            {
                "code": "candidate_fit_clear_count_mismatch",
                "claimed": claimed_clear_count,
                "computed": computed_clear_count,
            }
        )

    return {
        "schema_version": "zeststream.holding_company_candidate_fit.validation.v1",
        "status": "fail" if failures else "pass",
        "gate": ledger.get("gate"),
        "clear_count": computed_clear_count,
        "candidate_count": len(candidate_results),
        "candidates": candidate_results,
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
        print("status={status} clear_count={clear_count} candidate_count={candidate_count}".format(**result))
        for failure in result["failures"]:
            print(f"FAIL {failure}")
    return 0 if result["status"] == "pass" else 1


if __name__ == "__main__":
    sys.exit(main())

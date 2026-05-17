#!/usr/bin/env python3
"""Validate the ZestStream holding-company brand voice skill alignment ledger."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator, FormatChecker


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SCHEMA = ROOT / ".flywheel/validation-schema/v1/holding-company-brand-voice-skill.schema.json"
DEFAULT_LEDGER = ROOT / "state/holding-company-brand-voice-skill.json"
REQUIRED_POSITIONING = "sharpen_legacy_incubate_new_not_builder"
CLEAR_STATUSES = {"aligned", "clear"}
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


def has_ref(value: Any) -> bool:
    return isinstance(value, str) and bool(value.strip())


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

    if ledger.get("required_positioning") != REQUIRED_POSITIONING:
        failures.append(
            {
                "code": "required_positioning_mismatch",
                "declared": ledger.get("required_positioning"),
                "expected": REQUIRED_POSITIONING,
            }
        )

    skill_results: list[dict[str, Any]] = []
    computed_clear_count = 0

    for skill in ledger.get("skills", []):
        if not isinstance(skill, dict):
            continue
        skill_id = skill.get("skill_id")
        status = skill.get("status")
        clear_claim = status in CLEAR_STATUSES
        skill_failures: list[dict[str, Any]] = []

        if has_secretish_string(skill):
            skill_failures.append({"code": "secret_or_raw_value_shape_detected"})

        if clear_claim:
            if skill.get("jsm_managed") is not True:
                skill_failures.append({"code": "brand_voice_clear_without_jsm_management"})
            if skill.get("holding_company_canon_present") is not True:
                skill_failures.append({"code": "brand_voice_clear_without_holding_company_canon"})
            if skill.get("grounding_rules_present") is not True:
                skill_failures.append({"code": "brand_voice_clear_without_grounding_rules"})
            if skill.get("builder_frame_rejection_present") is not True:
                skill_failures.append({"code": "brand_voice_clear_without_builder_frame_rejection"})
            if not has_ref(skill.get("approved_update_receipt")):
                skill_failures.append({"code": "brand_voice_clear_without_jsm_receipt"})
            if skill.get("required_positioning") != REQUIRED_POSITIONING:
                skill_failures.append(
                    {
                        "code": "brand_voice_clear_required_positioning_mismatch",
                        "declared": skill.get("required_positioning"),
                        "expected": REQUIRED_POSITIONING,
                    }
                )

        if check_paths:
            skill_path = skill.get("skill_path")
            if isinstance(skill_path, str) and not ref_exists(skill_path):
                skill_failures.append({"code": "skill_path_missing", "ref": skill_path})
            receipt_ref = skill.get("approved_update_receipt")
            if isinstance(receipt_ref, str) and not ref_exists(receipt_ref):
                skill_failures.append({"code": "approved_update_receipt_missing", "ref": receipt_ref})
            for ref in skill.get("evidence_refs", []):
                if isinstance(ref, str) and not ref_exists(ref):
                    skill_failures.append({"code": "evidence_ref_missing", "ref": ref})

        aligned = (
            clear_claim
            and skill.get("jsm_managed") is True
            and skill.get("holding_company_canon_present") is True
            and skill.get("grounding_rules_present") is True
            and skill.get("builder_frame_rejection_present") is True
            and has_ref(skill.get("approved_update_receipt"))
            and skill.get("required_positioning") == REQUIRED_POSITIONING
        )
        if aligned and not skill_failures:
            computed_clear_count += 1
        for failure in skill_failures:
            failures.append({"skill_id": skill_id, **failure})

        skill_results.append(
            {
                "skill_id": skill_id,
                "status": status,
                "jsm_managed": skill.get("jsm_managed"),
                "holding_company_canon_present": skill.get("holding_company_canon_present"),
                "grounding_rules_present": skill.get("grounding_rules_present"),
                "builder_frame_rejection_present": skill.get("builder_frame_rejection_present"),
                "brand_voice_skill_gate_status": "clear" if aligned and not skill_failures else "blocked",
                "failures": skill_failures,
            }
        )

    claimed_clear_count = ledger.get("clear_count")
    if claimed_clear_count != computed_clear_count:
        failures.append(
            {
                "code": "brand_voice_clear_count_mismatch",
                "claimed": claimed_clear_count,
                "computed": computed_clear_count,
            }
        )

    return {
        "schema_version": "zeststream.holding_company_brand_voice_skill.validation.v1",
        "status": "fail" if failures else "pass",
        "gate": ledger.get("gate"),
        "required_positioning": REQUIRED_POSITIONING,
        "clear_count": computed_clear_count,
        "skill_count": len(skill_results),
        "skills": skill_results,
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
        print("status={status} clear_count={clear_count} skill_count={skill_count}".format(**result))
        for failure in result["failures"]:
            print(f"FAIL {failure}")
    return 0 if result["status"] == "pass" else 1


if __name__ == "__main__":
    sys.exit(main())

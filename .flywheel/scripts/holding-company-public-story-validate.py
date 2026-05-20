#!/usr/bin/env python3
"""Validate the ZestStream holding-company public story ledger."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator, FormatChecker


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SCHEMA = ROOT / ".flywheel/validation-schema/v1/holding-company-public-story.schema.json"
DEFAULT_LEDGER = ROOT / "state/holding-company-public-story.json"
SECRETISH_RE = re.compile(r"(\$[0-9]|sk-[A-Za-z0-9]|AKIA[0-9A-Z]{16})")
STALE_CLEAR_NEXT_ACTION_RE = re.compile(r"\bbefore\s+marking\b.*\bclear\b", re.IGNORECASE)


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


def stale_clear_next_action(value: Any) -> bool:
    return isinstance(value, str) and bool(STALE_CLEAR_NEXT_ACTION_RE.search(value))


def validate_ledger(ledger: dict[str, Any], schema: dict[str, Any], *, check_paths: bool) -> dict[str, Any]:
    failures: list[dict[str, Any]] = []
    try:
        Draft202012Validator.check_schema(schema)
        Draft202012Validator(schema, format_checker=FormatChecker()).validate(ledger)
    except Exception as exc:
        failures.append({"code": "schema_invalid", "detail": str(exc)})

    computed_clear_count = 0
    surface_results: list[dict[str, Any]] = []

    for surface in ledger.get("surfaces", []):
        if not isinstance(surface, dict):
            continue
        surface_id = surface.get("surface_id")
        status = surface.get("status")
        receipt_refs = surface.get("proof_or_receipt_refs", [])
        build_hits = surface.get("build_app_framing_hits", [])
        surface_failures: list[dict[str, Any]] = []

        story_clear = (
            status == "clear"
            and surface.get("receipt_story_present") is True
            and surface.get("holding_company_positioning_present") is True
            and bool(receipt_refs)
            and not build_hits
        )

        if status == "clear" and surface.get("receipt_story_present") is not True:
            surface_failures.append({"code": "public_story_clear_without_receipt_story"})
        if status == "clear" and surface.get("holding_company_positioning_present") is not True:
            surface_failures.append({"code": "public_story_clear_without_holding_company_positioning"})
        if status == "clear" and not receipt_refs:
            surface_failures.append({"code": "public_story_clear_missing_receipt_refs"})
        if status == "clear" and build_hits:
            surface_failures.append({"code": "public_story_clear_with_build_app_framing", "hit_count": len(build_hits)})
        if has_secretish_string(surface):
            surface_failures.append({"code": "secret_or_raw_value_shape_detected"})

        if check_paths:
            for ref in surface.get("evidence_refs", []):
                if isinstance(ref, str) and not ref_exists(ref):
                    surface_failures.append({"code": "evidence_ref_missing", "ref": ref})
            for ref in receipt_refs:
                if isinstance(ref, str) and not ref_exists(ref):
                    surface_failures.append({"code": "proof_or_receipt_ref_missing", "ref": ref})

        if story_clear and not surface_failures:
            computed_clear_count += 1
        for failure in surface_failures:
            failures.append({"surface_id": surface_id, **failure})

        surface_results.append(
            {
                "surface_id": surface_id,
                "status": status,
                "receipt_story_present": surface.get("receipt_story_present"),
                "holding_company_positioning_present": surface.get("holding_company_positioning_present"),
                "proof_or_receipt_ref_count": len(receipt_refs) if isinstance(receipt_refs, list) else 0,
                "build_app_framing_hit_count": len(build_hits) if isinstance(build_hits, list) else 0,
                "public_story_gate_status": "clear" if story_clear and not surface_failures else "blocked",
                "failures": surface_failures,
            }
        )

    claimed_clear_count = ledger.get("clear_count")
    if claimed_clear_count != computed_clear_count:
        failures.append({"code": "clear_count_mismatch", "claimed": claimed_clear_count, "computed": computed_clear_count})
    if computed_clear_count > 0 and stale_clear_next_action(ledger.get("next_action")):
        failures.append({"code": "stale_clear_next_action", "next_action": ledger.get("next_action")})

    return {
        "schema_version": "zeststream.holding_company_public_story.validation.v1",
        "status": "fail" if failures else "pass",
        "gate": ledger.get("gate"),
        "clear_count": computed_clear_count,
        "surface_count": len(surface_results),
        "surfaces": surface_results,
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
        print("status={status} clear_count={clear_count} surface_count={surface_count}".format(**result))
        for failure in result["failures"]:
            print(f"FAIL {failure}")
    return 0 if result["status"] == "pass" else 1


if __name__ == "__main__":
    sys.exit(main())

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-02-conformance-fixtures.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-68-schema-executable-validator-pair.md`

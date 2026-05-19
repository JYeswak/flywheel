#!/usr/bin/env python3
"""Validate the holding-company public-surface supersession receipt."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator, FormatChecker


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SCHEMA = ROOT / ".flywheel/validation-schema/v1/holding-company-public-surface-audit-supersession.schema.json"
DEFAULT_RECEIPT = ROOT / "state/holding-company-public-surface-audit-supersession-20260517T1004Z.json"
DEFAULT_COVERAGE = ROOT / "state/holding-company-objective-coverage.json"
SECRETISH_RE = re.compile(r"(\$[0-9]|sk-[A-Za-z0-9]|AKIA[0-9A-Z]{16})")
EXPECTED_SCHEMA_VERSION = "zeststream.holding_company_public_surface_audit_supersession.v1"
EXPECTED_SOURCE_GOAL = "ZestStream Holding Company Goal"
EXPECTED_SUPERSEDED_COUNT = 7
EXPECTED_ANTI_PITCH_RECEIPT_REFS = 3
EXPECTED_PUBLIC_STORY_RECEIPT_REFS = 3


def load_json(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def path_for_ref(ref: str) -> Path:
    path = Path(ref)
    if not path.is_absolute():
        path = ROOT / path
    return path


def has_secretish_string(value: Any) -> bool:
    if isinstance(value, str):
        return bool(SECRETISH_RE.search(value))
    if isinstance(value, dict):
        return any(has_secretish_string(v) for v in value.values())
    if isinstance(value, list):
        return any(has_secretish_string(v) for v in value)
    return False


def validate_receipt(
    receipt: dict[str, Any],
    schema: dict[str, Any],
    coverage: dict[str, Any],
    *,
    check_paths: bool,
) -> dict[str, Any]:
    failures: list[dict[str, Any]] = []

    try:
        Draft202012Validator.check_schema(schema)
        Draft202012Validator(schema, format_checker=FormatChecker()).validate(receipt)
    except Exception as exc:
        failures.append({"code": "schema_invalid", "detail": str(exc)})

    if has_secretish_string(receipt):
        failures.append({"code": "secret_or_raw_value_shape_detected"})

    if receipt.get("schema_version") != EXPECTED_SCHEMA_VERSION:
        failures.append({"code": "unexpected_schema_version", "claimed": receipt.get("schema_version")})
    if receipt.get("source_goal") != EXPECTED_SOURCE_GOAL:
        failures.append({"code": "unexpected_source_goal", "claimed": receipt.get("source_goal")})

    superseded_findings = [row for row in receipt.get("superseded_findings", []) if isinstance(row, dict)]
    if len(superseded_findings) != EXPECTED_SUPERSEDED_COUNT:
        failures.append(
            {
                "code": "superseded_findings_count_mismatch",
                "claimed": len(superseded_findings),
                "expected": EXPECTED_SUPERSEDED_COUNT,
            }
        )

    current_status = receipt.get("current_status", {})
    if current_status.get("anti_pitch_voice_surface_status") != "clear":
        failures.append({"code": "anti_pitch_voice_surface_not_clear"})
    if current_status.get("public_story_surface_status") != "clear":
        failures.append({"code": "public_story_surface_not_clear"})
    if current_status.get("objective_coverage_status") != "not_complete":
        failures.append({"code": "objective_coverage_not_marked_incomplete"})

    coverage_counts = coverage.get("summary_counts")
    receipt_counts = current_status.get("objective_counts_unchanged")
    if receipt_counts != coverage_counts:
        failures.append(
            {
                "code": "objective_counts_snapshot_mismatch",
                "receipt_counts": receipt_counts,
                "coverage_counts": coverage_counts,
            }
        )

    current_receipts = [ref for ref in receipt.get("current_receipts", []) if isinstance(ref, str)]
    anti_pitch_refs = [ref for ref in current_receipts if re.search(r"anti-pitch|historical-builder", ref)]
    public_story_refs = [ref for ref in current_receipts if re.search(r"public-story|objective-coverage", ref)]
    if len(anti_pitch_refs) != EXPECTED_ANTI_PITCH_RECEIPT_REFS:
        failures.append(
            {
                "code": "anti_pitch_supersession_evidence_ref_count_mismatch",
                "claimed": len(anti_pitch_refs),
                "expected": EXPECTED_ANTI_PITCH_RECEIPT_REFS,
            }
        )
    if len(public_story_refs) != EXPECTED_PUBLIC_STORY_RECEIPT_REFS:
        failures.append(
            {
                "code": "public_story_supersession_evidence_ref_count_mismatch",
                "claimed": len(public_story_refs),
                "expected": EXPECTED_PUBLIC_STORY_RECEIPT_REFS,
            }
        )

    notes = [note for note in receipt.get("notes", []) if isinstance(note, str)]
    if not any("does not rewrite the 06:46 audit" in note for note in notes):
        failures.append({"code": "historical_audit_preservation_note_missing"})

    if check_paths:
        supersedes_ref = receipt.get("supersedes_audit_ref")
        if isinstance(supersedes_ref, str) and not path_for_ref(supersedes_ref).is_file():
            failures.append({"code": "supersedes_audit_ref_missing", "ref": supersedes_ref})
        for ref in current_receipts:
            if not path_for_ref(ref).is_file():
                failures.append({"code": "current_receipt_ref_missing", "ref": ref})

    return {
        "schema_version": "zeststream.holding_company_public_surface_audit_supersession.validation.v1",
        "status": "fail" if failures else "pass",
        "source_goal": receipt.get("source_goal"),
        "public_surface_supersession_status": "clear_surfaces_objective_incomplete",
        "superseded_findings_count": len(superseded_findings),
        "current_receipt_count": len(current_receipts),
        "anti_pitch_receipt_ref_count": len(anti_pitch_refs),
        "public_story_receipt_ref_count": len(public_story_refs),
        "objective_counts_snapshot": receipt_counts,
        "coverage_summary_counts": coverage_counts,
        "failures": failures,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--receipt", type=Path, default=DEFAULT_RECEIPT)
    parser.add_argument("--schema", type=Path, default=DEFAULT_SCHEMA)
    parser.add_argument("--coverage", type=Path, default=DEFAULT_COVERAGE)
    parser.add_argument("--check-paths", action="store_true")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    result = validate_receipt(
        load_json(args.receipt),
        load_json(args.schema),
        load_json(args.coverage),
        check_paths=args.check_paths,
    )
    if args.json:
        print(json.dumps(result, indent=2, sort_keys=True))
    else:
        print(
            "status={status} public_surface_supersession_status={public_surface_supersession_status} "
            "superseded_findings={superseded_findings_count} current_receipts={current_receipt_count}".format(**result)
        )
        for failure in result["failures"]:
            print(f"FAIL {failure}")
    return 0 if result["status"] == "pass" else 1


if __name__ == "__main__":
    sys.exit(main())

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-20-cross-orch-handoff.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-63-phase-tick-bounded-action.md`

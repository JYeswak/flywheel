#!/usr/bin/env python3
"""Validate the ZestStream holding-company PEEL interview gate ledger."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator, FormatChecker


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SCHEMA = ROOT / ".flywheel/validation-schema/v1/holding-company-peel-interviews.schema.json"
DEFAULT_LEDGER = ROOT / "state/holding-company-peel-interviews.json"
QUALIFYING_URGENCY = {"medium", "strong"}
QUALIFYING_SOURCE_CHANNELS = {"client_talk", "community", "field_trip"}
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


def interview_qualifies(interview: dict[str, Any]) -> bool:
    signal = interview.get("buying_signal", {})
    return bool(
        signal.get("would_buy") is True
        and signal.get("urgency") in QUALIFYING_URGENCY
        and str(signal.get("price_point", "")).strip()
        and str(signal.get("evidence_ref", "")).strip()
        and str(interview.get("pain_point", "")).strip()
        and str(interview.get("current_alternative", "")).strip()
    )


def validate_ledger(ledger: dict[str, Any], schema: dict[str, Any], *, check_paths: bool) -> dict[str, Any]:
    failures: list[dict[str, Any]] = []
    try:
        Draft202012Validator.check_schema(schema)
        Draft202012Validator(schema, format_checker=FormatChecker()).validate(ledger)
    except Exception as exc:
        failures.append({"code": "schema_invalid", "detail": str(exc)})

    required = ledger.get("required_qualified_interviews", 5)
    candidate_results: list[dict[str, Any]] = []
    computed_clear_count = 0

    for candidate in ledger.get("candidates", []):
        if not isinstance(candidate, dict):
            continue
        slug = candidate.get("candidate_slug")
        status = candidate.get("formation_cash_status")
        source = candidate.get("candidate_source") if isinstance(candidate.get("candidate_source"), dict) else {}
        source_channel = source.get("source_channel")
        source_clear = (
            source_channel in QUALIFYING_SOURCE_CHANNELS
            and has_ref(source.get("source_ref"))
            and has_ref(source.get("evidence_ref"))
        )
        qualified_count = sum(1 for interview in candidate.get("interviews", []) if isinstance(interview, dict) and interview_qualifies(interview))
        gate_clear = qualified_count >= required
        cash_clear = status in {"clear", "committed"} and gate_clear and source_clear
        if cash_clear:
            computed_clear_count += 1

        candidate_failures: list[dict[str, Any]] = []
        if status in {"clear", "committed"} and not source_clear:
            candidate_failures.append(
                {
                    "code": "formation_cash_status_without_candidate_source",
                    "allowed_channels": sorted(QUALIFYING_SOURCE_CHANNELS),
                    "source_channel": source_channel,
                }
            )
        if status in {"clear", "committed"} and not gate_clear:
            candidate_failures.append(
                {
                    "code": "formation_cash_status_without_five_qualified_interviews",
                    "required": required,
                    "qualified_interviews": qualified_count,
                }
            )
        if status == "committed" and not gate_clear:
            candidate_failures.append({"code": "formation_cash_committed_without_clear_gate"})
        if has_secretish_string(candidate):
            candidate_failures.append({"code": "secret_or_raw_amount_shape_detected"})

        if check_paths:
            for ref in candidate.get("evidence_refs", []):
                if isinstance(ref, str) and not ref_exists(ref):
                    candidate_failures.append({"code": "evidence_ref_missing", "ref": ref})
            source_ref = source.get("evidence_ref")
            if isinstance(source_ref, str) and not ref_exists(source_ref):
                candidate_failures.append({"code": "candidate_source_evidence_ref_missing", "ref": source_ref})
            for interview in candidate.get("interviews", []):
                if not isinstance(interview, dict):
                    continue
                signal = interview.get("buying_signal", {})
                ref = signal.get("evidence_ref") if isinstance(signal, dict) else None
                if isinstance(ref, str) and not ref_exists(ref):
                    candidate_failures.append({"code": "interview_evidence_ref_missing", "ref": ref})

        for failure in candidate_failures:
            failures.append({"candidate_slug": slug, **failure})

        candidate_results.append(
            {
                "candidate_slug": slug,
                "formation_cash_status": status,
                "candidate_source_channel": source_channel,
                "candidate_source_status": "clear" if source_clear else "blocked",
                "qualified_interview_count": qualified_count,
                "interview_gate_status": "clear" if gate_clear else "blocked",
                "formation_cash_gate_status": "clear" if cash_clear else "blocked",
                "failures": candidate_failures,
            }
        )

    claimed_clear_count = ledger.get("formation_cash_clear_count")
    if claimed_clear_count != computed_clear_count:
        failures.append(
            {
                "code": "formation_cash_clear_count_mismatch",
                "claimed": claimed_clear_count,
                "computed": computed_clear_count,
            }
        )

    return {
        "schema_version": "zeststream.holding_company_peel_interviews.validation.v1",
        "status": "fail" if failures else "pass",
        "gate": ledger.get("gate"),
        "required_qualified_interviews": required,
        "formation_cash_clear_count": computed_clear_count,
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
        print(
            "status={status} formation_cash_clear_count={formation_cash_clear_count} candidate_count={candidate_count}".format(
                **result
            )
        )
        for failure in result["failures"]:
            print(f"FAIL {failure}")
    return 0 if result["status"] == "pass" else 1


if __name__ == "__main__":
    sys.exit(main())

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-02-conformance-fixtures.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-68-schema-executable-validator-pair.md`

#!/usr/bin/env python3
"""Validate the ZestStream holding-company progress velocity ledger."""

from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator, FormatChecker


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SCHEMA = ROOT / ".flywheel/validation-schema/v1/holding-company-progress-velocity.schema.json"
DEFAULT_LEDGER = ROOT / "state/holding-company-progress-velocity.json"
SECRETISH_RE = re.compile(r"(\$[0-9]|sk-[A-Za-z0-9]|AKIA[0-9A-Z]{16})")
FOUR_THOUSAND_OVERCLAIM_RE = re.compile(r"\b4,?000\+", re.IGNORECASE)


def load_json(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def parse_ts(value: str) -> datetime:
    return datetime.fromisoformat(value.replace("Z", "+00:00")).astimezone(timezone.utc)


def ref_exists(ref: str) -> bool:
    if ref.startswith("git ") or ref.startswith("for repo ") or "://" in ref or ref.startswith("urn:"):
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


def four_thousand_overclaim(value: Any) -> bool:
    return isinstance(value, str) and bool(FOUR_THOUSAND_OVERCLAIM_RE.search(value))


def validate_ledger(ledger: dict[str, Any], schema: dict[str, Any], *, check_paths: bool) -> dict[str, Any]:
    failures: list[dict[str, Any]] = []
    try:
        Draft202012Validator.check_schema(schema)
        Draft202012Validator(schema, format_checker=FormatChecker()).validate(ledger)
    except Exception as exc:
        failures.append({"code": "schema_invalid", "detail": str(exc)})

    surfaces = [surface for surface in ledger.get("surface_counts", []) if isinstance(surface, dict)]
    computed_total = sum(surface.get("commit_count", 0) for surface in surfaces if isinstance(surface.get("commit_count"), int))
    target_min_commits = ledger.get("target_min_commits")
    target_surface_count = ledger.get("target_surface_count")
    target_window_days = ledger.get("target_window_days")
    measured_total = ledger.get("measured_total_commit_count")
    status = ledger.get("status")
    exact_surface_set = ledger.get("exact_surface_set_established")

    try:
        window_days = (parse_ts(ledger["window_end"]) - parse_ts(ledger["window_start"])).total_seconds() / 86400
    except Exception as exc:
        failures.append({"code": "window_parse_failed", "detail": str(exc)})
        window_days = None

    if has_secretish_string(ledger):
        failures.append({"code": "secret_shape_detected"})
    if measured_total != computed_total:
        failures.append({"code": "commit_total_mismatch", "claimed": measured_total, "computed": computed_total})
    if len(surfaces) != target_surface_count:
        failures.append({"code": "surface_count_mismatch", "claimed": target_surface_count, "computed": len(surfaces)})
    if window_days is not None and abs(window_days - target_window_days) > 0.000001:
        failures.append({"code": "window_days_mismatch", "claimed": target_window_days, "computed": window_days})

    seen_surface_ids: set[str] = set()
    surface_results: list[dict[str, Any]] = []
    for surface in surfaces:
        surface_id = surface.get("surface_id")
        surface_failures: list[dict[str, Any]] = []
        if surface_id in seen_surface_ids:
            surface_failures.append({"code": "duplicate_surface_id"})
        if isinstance(surface_id, str):
            seen_surface_ids.add(surface_id)
        if check_paths:
            for field in ("repo_path", "evidence_ref"):
                ref = surface.get(field)
                if isinstance(ref, str) and not ref_exists(ref):
                    surface_failures.append({"code": "ref_missing", "field": field, "ref": ref})
        for failure in surface_failures:
            failures.append({"surface_id": surface_id, **failure})
        surface_results.append(
            {
                "surface_id": surface_id,
                "commit_count": surface.get("commit_count"),
                "surface_gate_status": "blocked" if surface_failures else "counted",
                "failures": surface_failures,
            }
        )

    if check_paths:
        for ref in ledger.get("evidence_refs", []):
            if isinstance(ref, str) and not ref_exists(ref):
                failures.append({"code": "evidence_ref_missing", "ref": ref})

    proven = (
        status == "proven"
        and exact_surface_set is True
        and isinstance(target_min_commits, int)
        and isinstance(target_surface_count, int)
        and isinstance(target_window_days, int)
        and computed_total >= target_min_commits
        and measured_total == computed_total
        and len(surfaces) == target_surface_count
        and window_days is not None
        and abs(window_days - target_window_days) <= 0.000001
        and all(surface.get("commit_count", 0) > 0 for surface in surfaces)
    )

    if status == "proven" and exact_surface_set is not True:
        failures.append({"code": "proven_without_exact_surface_set"})
    if status == "proven" and isinstance(target_min_commits, int) and computed_total < target_min_commits:
        failures.append({"code": "proven_below_target_commits", "target": target_min_commits, "computed": computed_total})
    if status == "proven" and any(surface.get("commit_count", 0) <= 0 for surface in surfaces):
        failures.append({"code": "proven_surface_zero_commits"})
    if status != "proven" and isinstance(target_min_commits, int) and computed_total < target_min_commits and four_thousand_overclaim(ledger.get("claim_text")):
        failures.append({"code": "claim_text_overstates_under_target_velocity", "target": target_min_commits, "computed": computed_total})

    return {
        "schema_version": "zeststream.holding_company_progress_velocity.validation.v1",
        "status": "fail" if failures else "pass",
        "gate": ledger.get("gate"),
        "progress_velocity_gate_status": "proven" if proven and not failures else "blocked",
        "target_min_commits": target_min_commits,
        "target_surface_count": target_surface_count,
        "target_window_days": target_window_days,
        "measured_total_commit_count": measured_total,
        "computed_total_commit_count": computed_total,
        "surface_count": len(surfaces),
        "exact_surface_set_established": exact_surface_set,
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
        print(
            "status={status} gate_status={progress_velocity_gate_status} total={computed_total_commit_count} surfaces={surface_count}".format(
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

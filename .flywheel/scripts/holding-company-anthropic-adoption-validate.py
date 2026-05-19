#!/usr/bin/env python3
"""Validate the ZestStream holding-company Anthropic SDK adoption ledger."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator, FormatChecker


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SCHEMA = ROOT / ".flywheel/validation-schema/v1/holding-company-anthropic-adoption.schema.json"
DEFAULT_LEDGER = ROOT / "state/holding-company-anthropic-adoption.json"
SECRETISH_RE = re.compile(r"(\$[0-9]|sk-[A-Za-z0-9]|AKIA[0-9A-Z]{16})")


def load_json(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def load_jsonl(path: Path) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    with path.open("r", encoding="utf-8") as handle:
        for line_no, line in enumerate(handle, start=1):
            if not line.strip():
                continue
            row = json.loads(line)
            if isinstance(row, dict):
                row["_line_no"] = line_no
                rows.append(row)
    return rows


def path_for_ref(ref: str) -> Path | None:
    if ref.startswith("urn:") or "://" in ref:
        return None
    path = Path(ref)
    if not path.is_absolute():
        path = ROOT / path
    return path


def ref_exists(ref: str) -> bool:
    path = path_for_ref(ref)
    return True if path is None else path.exists()


def has_secretish_string(value: Any) -> bool:
    if isinstance(value, str):
        return bool(SECRETISH_RE.search(value))
    if isinstance(value, dict):
        return any(has_secretish_string(v) for v in value.values())
    if isinstance(value, list):
        return any(has_secretish_string(v) for v in value)
    return False


def source_rows(events_ref: str, pack_name: str, expected_repos: list[str]) -> dict[str, list[dict[str, Any]]]:
    path = path_for_ref(events_ref)
    rows_by_target = {repo: [] for repo in expected_repos}
    if path is None or not path.exists():
        return rows_by_target
    for row in load_jsonl(path):
        if row.get("pack_name") != pack_name or row.get("lifecycle_transition") != "applied":
            continue
        target = row.get("target")
        if isinstance(target, str) and target in rows_by_target:
            rows_by_target[target].append(row)
    return rows_by_target


def is_real_consumer_target(target: str, row: dict[str, Any]) -> bool:
    if row.get("target_is_synthetic") is True or row.get("target_was_self") is True:
        return False
    if target.startswith("/private/tmp/") or target.startswith("/tmp/"):
        return False
    path = Path(target)
    return path.is_absolute() and path.exists() and path.is_dir()


def canonical_adoption_clause(path_ref: Any) -> dict[str, Any] | None:
    if not isinstance(path_ref, str):
        return None
    path = path_for_ref(path_ref)
    if path is None or not path.exists():
        return None
    data = load_json(path)
    try:
        clause = data["gate_2_consumer_adoption_compression"]["adoption_clause"]
    except (KeyError, TypeError):
        return None
    return clause if isinstance(clause, dict) else None


def validate_ledger(ledger: dict[str, Any], schema: dict[str, Any], *, check_paths: bool) -> dict[str, Any]:
    failures: list[dict[str, Any]] = []
    try:
        Draft202012Validator.check_schema(schema)
        Draft202012Validator(schema, format_checker=FormatChecker()).validate(ledger)
    except Exception as exc:
        failures.append({"code": "schema_invalid", "detail": str(exc)})

    pack_name = ledger.get("pack_name")
    expected_repos = [repo for repo in ledger.get("expected_consumer_repos", []) if isinstance(repo, str)]
    declared_events = [event for event in ledger.get("adoption_events", []) if isinstance(event, dict)]

    if has_secretish_string(ledger):
        failures.append({"code": "secret_or_raw_value_shape_detected"})

    if check_paths:
        for field in ("canonical_gates_status_ref", "pack_applied_events_ref"):
            ref = ledger.get(field)
            if isinstance(ref, str) and not ref_exists(ref):
                failures.append({"code": f"{field}_missing", "ref": ref})
        for ref in expected_repos:
            if not ref_exists(ref):
                failures.append({"code": "expected_repo_missing", "ref": ref})
        for ref in ledger.get("evidence_refs", []):
            if isinstance(ref, str) and not ref_exists(ref):
                failures.append({"code": "evidence_ref_missing", "ref": ref})

    clause = canonical_adoption_clause(ledger.get("canonical_gates_status_ref"))
    if clause:
        if clause.get("doctor_status") != ledger.get("doctor_status"):
            failures.append({"code": "canonical_doctor_status_mismatch", "claimed": ledger.get("doctor_status"), "canonical": clause.get("doctor_status")})
        if clause.get("distinct_target_count") != ledger.get("distinct_target_count"):
            failures.append(
                {
                    "code": "canonical_distinct_target_count_mismatch",
                    "claimed": ledger.get("distinct_target_count"),
                    "canonical": clause.get("distinct_target_count"),
                }
            )
        if clause.get("packages_phantom_fail") != ledger.get("packages_phantom_fail"):
            failures.append({"code": "canonical_phantom_fail_mismatch", "claimed": ledger.get("packages_phantom_fail"), "canonical": clause.get("packages_phantom_fail")})
        canonical_repos = set(clause.get("real_consumer_repos", []))
        missing_from_canonical = sorted(set(expected_repos) - canonical_repos)
        if missing_from_canonical:
            failures.append({"code": "expected_repo_missing_from_canonical_gate", "repos": missing_from_canonical})

    try:
        rows_by_target = source_rows(str(ledger.get("pack_applied_events_ref", "")), str(pack_name), expected_repos)
    except json.JSONDecodeError as exc:
        failures.append({"code": "pack_applied_events_parse_failed", "detail": str(exc)})
        rows_by_target = {repo: [] for repo in expected_repos}
    missing_event_targets = sorted(target for target, rows in rows_by_target.items() if not rows)
    computed_all_events_present = not missing_event_targets and bool(expected_repos)
    computed_real_targets = sorted(target for target, rows in rows_by_target.items() if rows and any(is_real_consumer_target(target, row) for row in rows))

    if ledger.get("all_expected_events_present") is not computed_all_events_present:
        failures.append(
            {
                "code": "all_expected_events_present_mismatch",
                "claimed": ledger.get("all_expected_events_present"),
                "computed": computed_all_events_present,
                "missing_targets": missing_event_targets,
            }
        )
    if ledger.get("real_consumer_repo_count") != len(computed_real_targets):
        failures.append({"code": "real_consumer_repo_count_mismatch", "claimed": ledger.get("real_consumer_repo_count"), "computed": len(computed_real_targets)})

    declared_targets = {event.get("target_repo") for event in declared_events}
    missing_declared_targets = sorted(set(expected_repos) - declared_targets)
    if missing_declared_targets:
        failures.append({"code": "declared_adoption_event_missing", "targets": missing_declared_targets})

    for event in declared_events:
        target = event.get("target_repo")
        if not isinstance(target, str):
            continue
        if event.get("target_is_synthetic") is True:
            failures.append({"code": "declared_event_synthetic_target", "target": target})
        if event.get("target_was_self") is True:
            failures.append({"code": "declared_event_self_target", "target": target})
        if target in rows_by_target:
            match = any(row.get("ts") == event.get("event_ts") for row in rows_by_target[target])
            if not match:
                failures.append({"code": "declared_event_not_found_in_source", "target": target, "event_ts": event.get("event_ts")})

    if ledger.get("all_expected_repos_present") is not all(ref_exists(repo) for repo in expected_repos):
        failures.append({"code": "all_expected_repos_present_mismatch", "claimed": ledger.get("all_expected_repos_present")})

    if ledger.get("status") == "proven":
        if ledger.get("doctor_status") != "OK":
            failures.append({"code": "proven_without_ok_doctor"})
        if ledger.get("distinct_target_count", 0) < ledger.get("min_real_consumer_repo_count", 0):
            failures.append({"code": "proven_below_min_target_count"})
        if ledger.get("target_repos_remaining_to_min_target_count") != 0:
            failures.append({"code": "proven_with_targets_remaining"})
        if ledger.get("packages_phantom_fail") != 0:
            failures.append({"code": "proven_with_phantom_failures"})
        if not computed_all_events_present:
            failures.append({"code": "proven_missing_expected_adoption_events", "targets": missing_event_targets})
        if len(computed_real_targets) < ledger.get("min_real_consumer_repo_count", 0):
            failures.append({"code": "proven_without_real_consumer_repos", "computed": len(computed_real_targets)})

    proven = (
        ledger.get("status") == "proven"
        and ledger.get("doctor_status") == "OK"
        and ledger.get("distinct_target_count", 0) >= ledger.get("min_real_consumer_repo_count", 0)
        and ledger.get("target_repos_remaining_to_min_target_count") == 0
        and ledger.get("packages_phantom_fail") == 0
        and computed_all_events_present
        and len(computed_real_targets) >= ledger.get("min_real_consumer_repo_count", 0)
    )

    return {
        "schema_version": "zeststream.holding_company_anthropic_adoption.validation.v1",
        "status": "fail" if failures else "pass",
        "gate": ledger.get("gate"),
        "anthropic_adoption_gate_status": "proven" if proven and not failures else "blocked",
        "pack_name": pack_name,
        "doctor_status": ledger.get("doctor_status"),
        "distinct_target_count": ledger.get("distinct_target_count"),
        "min_real_consumer_repo_count": ledger.get("min_real_consumer_repo_count"),
        "real_consumer_repo_count": len(computed_real_targets),
        "expected_consumer_repos": expected_repos,
        "missing_event_targets": missing_event_targets,
        "packages_phantom_fail": ledger.get("packages_phantom_fail"),
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
            "status={status} gate_status={anthropic_adoption_gate_status} pack={pack_name} real_repos={real_consumer_repo_count}".format(
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

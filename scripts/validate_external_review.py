#!/usr/bin/env python3
"""Validate the TP-015 external review gate."""

from __future__ import annotations

import argparse
import datetime as dt
import json
from pathlib import Path


DEFAULT_LOG = (
    Path(__file__).resolve().parents[1]
    / ".flywheel"
    / "PLANS"
    / "public-share-readiness-2026-05-12"
    / "review-log.jsonl"
)
VALID_VERDICTS = {"approved", "approved_with_followups"}
VALID_REVIEWER_KINDS = {"external_agent", "external_human", "external_agent_or_human"}
REQUIRED_SURFACES = {
    "README.md",
    "CHARTER.md",
    "docs/getting-started/first-run.md",
    "docs/evidence/publication-evidence.md",
    "docs/evidence/publication-blocker-coverage.md",
    "docs/runbooks/release-cutover-authorization.md",
    "docs/runbooks/public-release-runbook.md",
}
BLOCKED_REVIEWERS = {"joshua", "joshua-nowak", "flywheel:1", "flywheel-1", "bolddog"}
SCHEMA_VERSION = "flywheel.external_review.v0"


def read_rows(path: Path) -> tuple[list[dict[str, object]], list[dict[str, object]]]:
    rows: list[dict[str, object]] = []
    errors: list[dict[str, object]] = []
    if not path.exists():
        return rows, [{"code": "review_log_missing", "path": str(path)}]

    for line_no, raw in enumerate(path.read_text().splitlines(), start=1):
        if not raw.strip():
            continue
        try:
            row = json.loads(raw)
        except json.JSONDecodeError as exc:
            errors.append({"code": "invalid_json", "line": line_no, "detail": str(exc)})
            continue
        if not isinstance(row, dict):
            errors.append({"code": "row_not_object", "line": line_no})
            continue
        row["_line"] = line_no
        rows.append(row)
    return rows, errors


def normalize_reviewer(value: object) -> str:
    return str(value or "").strip().lower()


def valid_utc_timestamp(value: str) -> bool:
    if not value.endswith("Z"):
        return False
    try:
        dt.datetime.fromisoformat(value.removesuffix("Z") + "+00:00")
    except ValueError:
        return False
    return True


def validate(path: Path, release: bool) -> dict[str, object]:
    rows, errors = read_rows(path)
    valid_rows: list[dict[str, object]] = []
    reviewer_ids: set[str] = set()

    for row in rows:
        line = row.get("_line")
        reviewer_id = normalize_reviewer(row.get("reviewer_id"))
        reviewer_kind = str(row.get("reviewer_kind") or "").strip()
        reviewed_at = str(row.get("reviewed_at") or "").strip()
        verdict = str(row.get("verdict") or "").strip()
        surfaces = row.get("reviewed_surfaces")
        blocking_findings = row.get("blocking_findings")
        if row.get("schema_version") != SCHEMA_VERSION:
            errors.append({"code": "invalid_schema_version", "line": line, "expected": SCHEMA_VERSION})
        if not reviewer_id:
            errors.append({"code": "missing_reviewer_id", "line": line})
        elif reviewer_id in BLOCKED_REVIEWERS:
            errors.append({"code": "blocked_reviewer", "line": line, "reviewer_id": reviewer_id})
        if not reviewer_kind:
            errors.append({"code": "missing_reviewer_kind", "line": line})
        elif reviewer_kind not in VALID_REVIEWER_KINDS:
            errors.append(
                {
                    "code": "invalid_reviewer_kind",
                    "line": line,
                    "reviewer_kind": reviewer_kind,
                    "allowed": sorted(VALID_REVIEWER_KINDS),
                }
            )
        if not reviewed_at:
            errors.append({"code": "missing_reviewed_at", "line": line})
        elif not valid_utc_timestamp(reviewed_at):
            errors.append({"code": "invalid_reviewed_at", "line": line, "reviewed_at": reviewed_at})
        if verdict not in VALID_VERDICTS:
            errors.append({"code": "invalid_verdict", "line": line, "verdict": verdict})
        if not isinstance(blocking_findings, list):
            errors.append({"code": "missing_blocking_findings", "line": line})
        elif blocking_findings:
            errors.append({"code": "blocking_findings_present", "line": line})
        if not isinstance(surfaces, list) or not REQUIRED_SURFACES.issubset({str(item) for item in surfaces}):
            errors.append(
                {
                    "code": "missing_required_surface_review",
                    "line": line,
                    "required": sorted(REQUIRED_SURFACES),
                }
            )
        if (
            row.get("schema_version") == SCHEMA_VERSION
            and reviewer_id
            and reviewer_id not in BLOCKED_REVIEWERS
            and reviewer_kind in VALID_REVIEWER_KINDS
            and valid_utc_timestamp(reviewed_at)
            and verdict in VALID_VERDICTS
            and isinstance(blocking_findings, list)
            and not blocking_findings
            and isinstance(surfaces, list)
            and REQUIRED_SURFACES.issubset({str(item) for item in surfaces})
        ):
            valid_rows.append(row)
            reviewer_ids.add(reviewer_id)

    gate_errors: list[dict[str, object]] = []
    if len(valid_rows) != 2:
        gate_errors.append({"code": "wrong_valid_review_count", "expected": 2, "actual": len(valid_rows)})
    if len(reviewer_ids) != 2:
        gate_errors.append({"code": "reviewers_not_distinct", "expected": 2, "actual": len(reviewer_ids)})

    all_errors = errors + gate_errors
    status = "pass" if not all_errors else "blocked"
    payload = {
        "schema_version": "flywheel.external_review_gate.v0",
        "status": status,
        "mode": "release" if release else "normal",
        "log": str(path),
        "row_count": len(rows),
        "valid_review_count": len(valid_rows),
        "distinct_reviewer_count": len(reviewer_ids),
        "valid_verdicts": sorted(VALID_VERDICTS),
        "valid_reviewer_kinds": sorted(VALID_REVIEWER_KINDS),
        "required_surfaces": sorted(REQUIRED_SURFACES),
        "errors": all_errors,
    }
    return payload


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--log", default=str(DEFAULT_LOG))
    parser.add_argument("--release", action="store_true", help="exit non-zero when the gate is blocked")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    result = validate(Path(args.log), args.release)
    if args.json:
        print(json.dumps(result, separators=(",", ":")))
    else:
        print(
            f"{result['status']} rows={result['row_count']} "
            f"valid={result['valid_review_count']} distinct={result['distinct_reviewer_count']}"
        )

    if result["status"] == "pass":
        return 0
    return 1 if args.release else 20


if __name__ == "__main__":
    raise SystemExit(main())

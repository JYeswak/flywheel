#!/usr/bin/env python3
# Meta-pattern Adoption stance:
# Embodies MP-54-template-publish-gate.md and MP-69-registry-risk-ledger.md.
# Source: /Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/
"""Validate the true-publication release-blocker registry."""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path


DEFAULT_REGISTRY = (
    Path(__file__).resolve().parents[1]
    / "PLANS"
    / "public-share-readiness-2026-05-12"
    / "19-TRUE-PUBLICATION-RELEASE-BLOCKER-REGISTRY.md"
)
ID_RE = re.compile(r"^TP-\d{3}$")
VALID_SEVERITIES = {"P0", "P1", "P2", "P3"}
VALID_STATUSES = {"open", "in_progress", "closed", "deferred", "non_release"}
COVERAGE_HEADER = "| Readiness blocker code | Registry rows | Coverage status |"
READINESS_BLOCKER_ALIASES = {
    "remote_repo_unavailable": "remote_repo_private",
}
OPTIONAL_COVERAGE_CODES = {
    "install_proxy_checksum_mismatch",
    "remote_repo_private",
    "remote_green_runs_missing",
    "remote_workflows_missing",
}


def parse_rows(path: Path) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    for line_no, line in enumerate(path.read_text().splitlines(), start=1):
        if not line.startswith("| TP-"):
            continue
        cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
        if len(cells) != 7:
            rows.append({"line": str(line_no), "parse_error": f"expected 7 cells, got {len(cells)}"})
            continue
        row_id, klass, severity, status, owner, evidence, closure = cells
        rows.append(
            {
                "line": str(line_no),
                "id": row_id,
                "class": klass,
                "severity": severity,
                "status": status,
                "owner": owner,
                "evidence": evidence,
                "required_closure": closure,
            }
        )
    return rows


def clean_cell(value: str) -> str:
    return value.strip().strip("`")


def parse_blocker_coverage(path: Path) -> list[dict[str, str]]:
    coverage: list[dict[str, str]] = []
    in_table = False
    for line_no, line in enumerate(path.read_text().splitlines(), start=1):
        stripped = line.strip()
        if stripped == COVERAGE_HEADER:
            in_table = True
            continue
        if not in_table:
            continue
        if not stripped.startswith("|"):
            break
        cells = [cell.strip() for cell in stripped.strip("|").split("|")]
        if len(cells) != 3:
            coverage.append({"line": str(line_no), "parse_error": f"expected 3 cells, got {len(cells)}"})
            continue
        if set(cells[0].replace(":", "").strip()) <= {"-"}:
            continue
        code = clean_cell(cells[0])
        registry_rows = ",".join(clean_cell(part) for part in cells[1].split(",") if clean_cell(part))
        coverage.append(
            {
                "line": str(line_no),
                "code": code,
                "registry_rows": registry_rows,
                "status": clean_cell(cells[2]),
            }
        )
    return coverage


def validate(
    rows: list[dict[str, str]],
    coverage: list[dict[str, str]],
    expected_blockers: set[str],
    release: bool,
) -> tuple[list[dict], list[dict]]:
    errors: list[dict] = []
    warnings: list[dict] = []
    seen: dict[str, int] = {}

    for row in rows:
        line = row.get("line")
        if row.get("parse_error"):
            errors.append({"code": "row_parse_error", "line": line, "detail": row["parse_error"]})
            continue

        row_id = row["id"]
        if not ID_RE.match(row_id):
            errors.append({"code": "invalid_id", "line": line, "id": row_id})
        if row_id in seen:
            errors.append({"code": "duplicate_id", "line": line, "id": row_id, "first_line": seen[row_id]})
        else:
            seen[row_id] = int(line or 0)
        if row["severity"] not in VALID_SEVERITIES:
            errors.append({"code": "invalid_severity", "line": line, "id": row_id, "severity": row["severity"]})
        if row["status"] not in VALID_STATUSES:
            errors.append({"code": "invalid_status", "line": line, "id": row_id, "status": row["status"]})
        for field in ("class", "owner", "evidence", "required_closure"):
            if not row[field] or row[field] in {"-", "TBD", "TODO"}:
                errors.append({"code": "missing_required_field", "line": line, "id": row_id, "field": field})
        if row["status"] in {"open", "in_progress"}:
            warnings.append({"code": "open_registry_row", "line": line, "id": row_id, "severity": row["severity"]})
            if release:
                errors.append({"code": "release_blocked_open_row", "line": line, "id": row_id})

    if not rows:
        errors.append({"code": "registry_empty", "message": "no TP-* rows found"})

    row_by_id = {row["id"]: row for row in rows if row.get("id")}
    coverage_codes = {row.get("code", "") for row in coverage if row.get("code")}
    missing_coverage = sorted(expected_blockers - coverage_codes)
    unknown_coverage = sorted(coverage_codes - expected_blockers - OPTIONAL_COVERAGE_CODES)
    for code in missing_coverage:
        errors.append({"code": "missing_readiness_blocker_coverage", "blocker_code": code})
    for code in unknown_coverage:
        errors.append({"code": "unknown_readiness_blocker_coverage", "blocker_code": code})
    for coverage_row in coverage:
        line = coverage_row.get("line")
        if coverage_row.get("parse_error"):
            errors.append({"code": "coverage_parse_error", "line": line, "detail": coverage_row["parse_error"]})
            continue
        if not coverage_row.get("registry_rows"):
            errors.append({"code": "coverage_missing_registry_rows", "line": line, "blocker_code": coverage_row.get("code")})
            continue
        for row_id in coverage_row["registry_rows"].split(","):
            registry_row = row_by_id.get(row_id)
            if registry_row is None:
                errors.append(
                    {
                        "code": "coverage_unknown_registry_row",
                        "line": line,
                        "blocker_code": coverage_row.get("code"),
                        "registry_row": row_id,
                    }
                )
            elif coverage_row.get("status") in {"open", "in_progress"} and registry_row.get("status") not in {"open", "in_progress"}:
                errors.append(
                    {
                        "code": "coverage_row_not_open",
                        "line": line,
                        "blocker_code": coverage_row.get("code"),
                        "registry_row": row_id,
                        "registry_status": registry_row.get("status"),
                    }
                )
            elif coverage_row.get("status") == "closed" and registry_row.get("status") != "closed":
                errors.append(
                    {
                        "code": "coverage_row_not_closed",
                        "line": line,
                        "blocker_code": coverage_row.get("code"),
                        "registry_row": row_id,
                        "registry_status": registry_row.get("status"),
                    }
                )

    return errors, warnings


def live_readiness_blockers(repo: Path, script: Path) -> tuple[set[str], list[dict]]:
    if not script.exists():
        return set(), [{"code": "readiness_script_missing", "path": str(script)}]
    try:
        proc = subprocess.run(
            [sys.executable, str(script), "--repo", str(repo), "--json"],
            cwd=repo,
            text=True,
            capture_output=True,
            timeout=60,
            check=False,
        )
    except subprocess.TimeoutExpired:
        return set(), [{"code": "readiness_script_timeout", "path": str(script)}]

    try:
        payload = json.loads(proc.stdout)
    except json.JSONDecodeError as exc:
        return set(), [{"code": "readiness_script_invalid_json", "path": str(script), "detail": str(exc)}]

    blockers = payload.get("blockers")
    if not isinstance(blockers, list):
        return set(), [{"code": "readiness_script_missing_blockers", "path": str(script)}]
    codes = {
        READINESS_BLOCKER_ALIASES.get(code, code)
        for row in blockers
        if isinstance(row, dict) and row.get("code")
        for code in [str(row.get("code", "")).strip()]
    }
    return codes, []


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--registry", default=str(DEFAULT_REGISTRY))
    parser.add_argument("--repo", default=str(Path(__file__).resolve().parents[2]))
    parser.add_argument(
        "--readiness-script",
        default=str(Path(__file__).resolve().parents[2] / "scripts" / "publication_readiness.py"),
    )
    parser.add_argument("--release", action="store_true", help="fail if any registry row remains open")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    registry = Path(args.registry)
    if not registry.exists():
        payload = {
            "schema_version": "true-publication-registry/v1",
            "status": "fail",
            "registry": str(registry),
            "row_count": 0,
            "errors": [{"code": "registry_missing", "path": str(registry)}],
            "warnings": [],
        }
        print(json.dumps(payload, separators=(",", ":")) if args.json else "FAIL registry missing")
        return 1

    rows = parse_rows(registry)
    coverage = parse_blocker_coverage(registry)
    expected_blockers, readiness_errors = live_readiness_blockers(Path(args.repo).resolve(), Path(args.readiness_script).resolve())
    errors, warnings = validate(rows, coverage, expected_blockers, args.release)
    errors.extend(readiness_errors)
    open_rows = [row for row in rows if row.get("status") in {"open", "in_progress"}]
    payload = {
        "schema_version": "true-publication-registry/v1",
        "status": "fail" if errors else "pass",
        "mode": "release" if args.release else "normal",
        "registry": str(registry),
        "row_count": len(rows),
        "open_count": len(open_rows),
        "open_rows": open_rows,
        "expected_readiness_blockers": sorted(expected_blockers),
        "optional_coverage_codes": sorted(OPTIONAL_COVERAGE_CODES),
        "readiness_blocker_coverage": coverage,
        "ids": [row.get("id") for row in rows if row.get("id")],
        "errors": errors,
        "warnings": warnings,
    }
    if args.json:
        print(json.dumps(payload, separators=(",", ":")))
    else:
        print(f"{payload['status']} rows={len(rows)} open={len(open_rows)} errors={len(errors)}")
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-02-conformance-fixtures.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-68-schema-executable-validator-pair.md`

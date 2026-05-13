#!/usr/bin/env python3
"""Validate the true-publication release-blocker registry."""

from __future__ import annotations

import argparse
import json
import re
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


def validate(rows: list[dict[str, str]], release: bool) -> tuple[list[dict], list[dict]]:
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

    return errors, warnings


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--registry", default=str(DEFAULT_REGISTRY))
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
    errors, warnings = validate(rows, args.release)
    open_rows = [row for row in rows if row.get("status") in {"open", "in_progress"}]
    payload = {
        "schema_version": "true-publication-registry/v1",
        "status": "fail" if errors else "pass",
        "mode": "release" if args.release else "normal",
        "registry": str(registry),
        "row_count": len(rows),
        "open_count": len(open_rows),
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

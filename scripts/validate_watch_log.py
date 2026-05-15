#!/usr/bin/env python3
"""Validate watch-rolling-log.jsonl rows against the /goal-mode receipt schema.

Schema derived from the session-tested ACT/ACCRETE/STAND_DOWN regime
(`docs/evidence/operator-gated-cutover-decisions.md` + the rolling log
under `.flywheel/evidence/`):

  Common fields (every row):
    ts                  ISO-8601 UTC, ends with Z, no fractional seconds
                        beyond microseconds.
    cycle               One of: ACT | ACCRETE | STAND_DOWN.
    event               Short kebab-case identifier (a-z, 0-9, dash).
    detail              Non-empty string.

  Cycle-specific required fields:
    ACT          -> receipt (path or command, non-empty)
    ACCRETE      -> artifact (path), reusable_because (non-empty)
    STAND_DOWN   -> receipt (path or command, non-empty)

Unknown extra keys are allowed (forward-compat). Missing required keys,
wrong types, or invalid enums fail.

Exit codes:
  0  every row passes
  1  one or more rows fail
  2  file unreadable / not JSONL

Usage:
  scripts/validate_watch_log.py [--file PATH] [--json]
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

SCHEMA_VERSION = "flywheel.watch_rolling_log_row.v0"

CYCLE_ENUM = {"ACT", "ACCRETE", "STAND_DOWN"}

COMMON_REQUIRED = ("ts", "cycle", "event", "detail")

CYCLE_REQUIRED: dict[str, tuple[str, ...]] = {
    "ACT": ("receipt",),
    "ACCRETE": ("artifact", "reusable_because"),
    "STAND_DOWN": ("receipt",),
}

# ISO-8601 UTC: YYYY-MM-DDTHH:MM:SS[.ffffff]Z
TS_RE = re.compile(r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,6})?Z$")
EVENT_RE = re.compile(r"^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$")


def validate_row(row: dict[str, Any]) -> list[str]:
    errors: list[str] = []

    for key in COMMON_REQUIRED:
        if key not in row:
            errors.append(f"missing required key: {key}")
            continue
        if not isinstance(row[key], str) or not row[key].strip():
            errors.append(f"{key} must be a non-empty string")

    if "ts" in row and isinstance(row["ts"], str) and not TS_RE.match(row["ts"]):
        errors.append(f"ts not ISO-8601 UTC with Z: {row['ts']!r}")

    if "cycle" in row and row["cycle"] not in CYCLE_ENUM:
        errors.append(
            f"cycle not in enum {sorted(CYCLE_ENUM)}: {row.get('cycle')!r}"
        )

    if "event" in row and isinstance(row["event"], str) and not EVENT_RE.match(row["event"]):
        errors.append(f"event not kebab-case lower-alnum: {row['event']!r}")

    cycle = row.get("cycle")
    cycle_keys: tuple[str, ...] = CYCLE_REQUIRED.get(cycle, ()) if isinstance(cycle, str) else ()
    for key in cycle_keys:
        if key not in row:
            errors.append(f"{cycle} requires key: {key}")
        elif not isinstance(row[key], str) or not row[key].strip():
            errors.append(f"{cycle}.{key} must be a non-empty string")

    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--file",
        default=".flywheel/evidence/watch-rolling-log.jsonl",
        help="path to the rolling log JSONL (default: flywheel canonical)",
    )
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    path = Path(args.file)
    if not path.exists():
        print(f"file not found: {path}", file=sys.stderr)
        return 2

    rows: list[dict[str, Any]] = []
    parse_errors: list[dict[str, Any]] = []
    for line_no, raw in enumerate(path.read_text().splitlines(), start=1):
        if not raw.strip():
            continue
        try:
            rows.append(json.loads(raw))
        except json.JSONDecodeError as exc:
            parse_errors.append({"line": line_no, "error": str(exc)})

    findings: list[dict[str, Any]] = []
    for idx, row in enumerate(rows, start=1):
        errs = validate_row(row)
        if errs:
            findings.append(
                {
                    "row": idx,
                    "cycle": row.get("cycle"),
                    "event": row.get("event"),
                    "errors": errs,
                }
            )

    cycle_counts: dict[str, int] = {}
    for row in rows:
        c = row.get("cycle", "<missing>")
        cycle_counts[c] = cycle_counts.get(c, 0) + 1

    result = {
        "schema_version": SCHEMA_VERSION,
        "file": str(path),
        "total_rows": len(rows),
        "parse_errors": parse_errors,
        "valid_rows": len(rows) - len(findings) - len(parse_errors),
        "invalid_rows": len(findings),
        "cycle_counts": cycle_counts,
        "findings": findings,
        "status": "pass" if not findings and not parse_errors else "fail",
    }

    if args.json:
        print(json.dumps(result, indent=2))
    else:
        print(
            f"status={result['status']} rows={result['total_rows']} "
            f"valid={result['valid_rows']} invalid={result['invalid_rows']} "
            f"parse_errors={len(parse_errors)} "
            f"cycles={cycle_counts}"
        )
        for f in findings:
            print(f"  row {f['row']} ({f['cycle']}/{f['event']}):")
            for err in f["errors"]:
                print(f"    - {err}")

    return 0 if result["status"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Flywheel state schema_version coverage check.

Per `.flywheel/doctrine/jsm-meta-lessons-canonical.md` § MP-04.
Mirror of skillos sister-script adapted to flywheel layout.

Run: python3 .flywheel/scripts/test-state-schema-version-coverage.py
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
STATE_PATHS = [ROOT / "state", ROOT / ".flywheel"]

SKIP_DIR_NAMES = {".git", "__pycache__", "node_modules", "archive", "_archive"}
SKIP_NAME_FRAGMENTS = (".bak.", ".old.")


def should_skip(path: Path) -> bool:
    for part in path.parts:
        if part in SKIP_DIR_NAMES:
            return True
    for frag in SKIP_NAME_FRAGMENTS:
        if frag in path.name:
            return True
    try:
        if path.stat().st_size < 100:
            return True
    except OSError:
        return True
    return False


def cites_schema_version(path: Path) -> tuple[bool, str | None]:
    try:
        with path.open() as f:
            data = json.load(f)
    except (OSError, json.JSONDecodeError) as exc:
        return False, f"unreadable: {exc}"
    if not isinstance(data, dict):
        return True, "skip: non-object root"
    if "schema_version" in data or "schemaVersion" in data:
        return True, str(data.get("schema_version") or data.get("schemaVersion"))
    return False, "missing"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    candidates = []
    for base in STATE_PATHS:
        if not base.exists():
            continue
        for path in base.rglob("*.json"):
            if should_skip(path):
                continue
            candidates.append(path)

    missing, cited, catalog, unreadable = [], 0, 0, 0
    for path in candidates:
        ok, note = cites_schema_version(path)
        if ok:
            if note and "skip:" in note:
                catalog += 1
            else:
                cited += 1
        else:
            if "unreadable" in (note or ""):
                unreadable += 1
            else:
                missing.append(str(path.relative_to(ROOT)))

    summary = {
        "schema_version": "flywheel.state_schema_version_coverage.v1",
        "candidates_total": len(candidates),
        "cited_count": cited,
        "catalog_skipped": catalog,
        "unreadable": unreadable,
        "missing_count": len(missing),
        "missing": missing[:50],
    }

    if args.json:
        print(json.dumps(summary, indent=2))
    else:
        print(f"# flywheel state schema_version: {cited}/{len(candidates)} cite, {len(missing)} missing")

    if summary["candidates_total"] > 0 and len(missing) / summary["candidates_total"] > 0.5:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
# Meta-pattern Adoption stance:
# Embodies MP-04-receipt-callback-envelope.md and MP-74-assertion-control-evidence-chain.md.
# Source: /Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/
"""Flywheel callback evidence_path file-exists check.

Per `.flywheel/doctrine/jsm-meta-lessons-canonical.md` § MP-04.
Mirror of skillos sister-script.

Run: python3 .flywheel/scripts/test-callback-evidence-path-extant.py
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCAN_DIRS = [ROOT / "state", ROOT / ".flywheel"]

EVIDENCE_FIELDS = {
    "evidence_path", "evidence_receipt", "validation_receipt",
    "receipt", "receipt_path", "compliance_pack_path",
    "blocker_id_state_path",
}
SKIP_VALUES = {"none", "n/a", "", "no_bead"}


def is_path_like(value) -> bool:
    if not isinstance(value, str):
        return False
    if value.lower() in SKIP_VALUES:
        return False
    if value.startswith("inline_") or value.startswith("no_"):
        return False
    return ("/" in value) and (not value.startswith("http"))


def resolve_path(value: str) -> Path:
    p = Path(value)
    return p if p.is_absolute() else ROOT / p


def scan_record(record: dict, source: Path, line: int | None) -> list[dict]:
    misses = []
    for field, value in record.items():
        if field not in EVIDENCE_FIELDS:
            continue
        if not is_path_like(value):
            continue
        if not resolve_path(value).exists():
            misses.append({
                "source": str(source.relative_to(ROOT)),
                "line": line,
                "field": field,
                "value": value,
            })
    return misses


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    misses = []
    files_scanned = 0
    records_scanned = 0

    for base in SCAN_DIRS:
        if not base.exists():
            continue
        for jsonl in base.rglob("*.jsonl"):
            files_scanned += 1
            try:
                with jsonl.open() as f:
                    for i, line in enumerate(f, 1):
                        line = line.strip()
                        if not line:
                            continue
                        try:
                            record = json.loads(line)
                        except json.JSONDecodeError:
                            continue
                        if isinstance(record, dict):
                            records_scanned += 1
                            misses.extend(scan_record(record, jsonl, i))
            except OSError:
                continue
        for jsonf in base.rglob("*receipt*.json"):
            files_scanned += 1
            try:
                with jsonf.open() as f:
                    data = json.load(f)
            except (OSError, json.JSONDecodeError):
                continue
            if isinstance(data, dict):
                records_scanned += 1
                misses.extend(scan_record(data, jsonf, None))

    summary = {
        "schema_version": "flywheel.callback_evidence_path_extant.v1",
        "files_scanned": files_scanned,
        "records_scanned": records_scanned,
        "missing_evidence_count": len(misses),
        "missing": misses[:50],
    }

    if args.json:
        print(json.dumps(summary, indent=2))
    else:
        print(f"# flywheel callback evidence_path: {len(misses)} missing in {records_scanned} records")

    if records_scanned > 0 and len(misses) / records_scanned > 0.2:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-04-receipt-callback-envelope.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-88-content-addressed-evidence-pack.md`

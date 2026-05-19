#!/usr/bin/env python3
"""Validate the B6 leverage-ceiling evidence window for h17x/xhdg unblocking."""

from __future__ import annotations

import argparse
import json
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCHEMA_VERSION = "flywheel.leverage_evidence_gate.v1"
DEFAULT_LEDGER = Path.home() / ".local/state/flywheel/leverage-ceiling.jsonl"


def row_timestamp(row: dict[str, Any]) -> str | None:
    value = row.get("ts") or row.get("observed_at") or row.get("created_at") or row.get("timestamp")
    if not isinstance(value, str) or "T" not in value:
        return None
    return value


def read_rows(path: Path) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    if not path.exists():
        return rows
    with path.open("r", encoding="utf-8") as handle:
        for line_no, line in enumerate(handle, 1):
            text = line.strip()
            if not text:
                continue
            try:
                row = json.loads(text)
            except json.JSONDecodeError:
                rows.append({"_invalid": True, "_line": line_no})
                continue
            if isinstance(row, dict):
                rows.append(row)
            else:
                rows.append({"_invalid": True, "_line": line_no})
    return rows


def render_gate(path: Path, required_days: int, generated_at: str) -> dict[str, Any]:
    rows = read_rows(path)
    valid_rows = [
        row for row in rows
        if row.get("success") is True and row_timestamp(row) is not None
    ]
    days = sorted({str(row_timestamp(row)).split("T", 1)[0] for row in valid_rows})
    bindings = Counter(str(row.get("binding_constraint") or "unknown") for row in valid_rows)
    scores = [
        float(row["leverage_ceiling_score"])
        for row in valid_rows
        if isinstance(row.get("leverage_ceiling_score"), (int, float))
    ]
    ready = len(days) >= required_days
    return {
        "schema_version": SCHEMA_VERSION,
        "generated_at": generated_at,
        "ledger": str(path),
        "status": "ready" if ready else "waiting_for_evidence",
        "required_distinct_days": required_days,
        "distinct_day_count": len(days),
        "missing_distinct_days": max(0, required_days - len(days)),
        "distinct_days": days,
        "row_count": len(rows),
        "valid_success_row_count": len(valid_rows),
        "invalid_row_count": sum(1 for row in rows if row.get("_invalid") is True),
        "latest_timestamp": max((row_timestamp(row) for row in valid_rows), default=None),
        "binding_counts": dict(sorted(bindings.items())),
        "score_min": min(scores) if scores else None,
        "score_max": max(scores) if scores else None,
        "score_avg": round(sum(scores) / len(scores), 2) if scores else None,
        "next_action": (
            "author_h17x_axiom_and_then_xhdg_refill_rule"
            if ready
            else "continue_repaired_tick_driver_accrual"
        ),
        "unblocks": ["flywheel-h17x", "flywheel-xhdg"] if ready else [],
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ledger", type=Path, default=DEFAULT_LEDGER)
    parser.add_argument("--required-days", type=int, default=7)
    parser.add_argument("--generated-at", default=datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"))
    parser.add_argument("--out", type=Path)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    payload = render_gate(args.ledger.expanduser(), args.required_days, args.generated_at)
    text = json.dumps(payload, indent=2, sort_keys=True)
    if args.out:
        args.out.parent.mkdir(parents=True, exist_ok=True)
        args.out.write_text(text + "\n", encoding="utf-8")
    if args.json or not args.out:
        print(text)
    return 0 if payload["status"] == "ready" else 1


if __name__ == "__main__":
    raise SystemExit(main())

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`

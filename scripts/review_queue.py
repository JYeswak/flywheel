#!/usr/bin/env python3
"""Summarize and reduce Flywheel extraction manual-review queues."""

from __future__ import annotations

import argparse
import json
import sys
from collections import Counter
from pathlib import Path

SCHEMA_VERSION = "flywheel.review_queue.v0"
SAFE_SIGNOFFS = {
    "mode_a_codemod_sufficient": (
        "policy:codemod-and-staging-scan-clean",
        "codemodded_and_scan_clean",
    ),
}


def read_jsonl(path: Path) -> list[dict[str, object]]:
    rows: list[dict[str, object]] = []
    with path.open("r", encoding="utf-8") as handle:
        for line_no, line in enumerate(handle, start=1):
            if not line.strip():
                continue
            try:
                rows.append(json.loads(line))
            except json.JSONDecodeError as exc:
                raise ValueError(f"{path}:{line_no}: invalid JSON: {exc}") from exc
    return rows


def write_jsonl(path: Path, rows: list[dict[str, object]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as handle:
        for row in rows:
            handle.write(json.dumps(row, sort_keys=True, separators=(",", ":")) + "\n")


def signoff_for(
    row: dict[str, object], mode_b_evidence: str | None
) -> tuple[str, str, str | None] | None:
    reason = str(row.get("reason", ""))
    if reason.startswith("denylist:"):
        return (
            "policy:excluded-from-staging-by-denylist",
            "excluded_from_staging",
            None,
        )
    if reason == "mode_b_pattern_rewrite_required" and mode_b_evidence:
        return (
            "policy:mode-b-reviewed-with-clean-staging-scan",
            "mode_b_scan_evidence_accepted",
            mode_b_evidence,
        )
    signoff = SAFE_SIGNOFFS.get(reason)
    if signoff:
        return signoff[0], signoff[1], None
    return None


def apply_safe_signoffs(
    rows: list[dict[str, object]], mode_b_evidence: str | None
) -> tuple[list[dict[str, object]], int]:
    signed = 0
    updated: list[dict[str, object]] = []
    for row in rows:
        next_row = dict(row)
        if not next_row.get("signed_off_by"):
            signoff = signoff_for(next_row, mode_b_evidence)
            if signoff:
                signed_by, disposition, evidence = signoff
                next_row["signed_off_by"] = signed_by
                next_row["disposition"] = disposition
                if evidence:
                    next_row["evidence"] = evidence
                signed += 1
        updated.append(next_row)
    return updated, signed


def summarize(rows: list[dict[str, object]]) -> dict[str, object]:
    reason_counts = Counter(str(row.get("reason", "<missing>")) for row in rows)
    unsigned = [row for row in rows if not row.get("signed_off_by")]
    unsigned_reason_counts = Counter(str(row.get("reason", "<missing>")) for row in unsigned)
    return {
        "total_rows": len(rows),
        "signed_rows": len(rows) - len(unsigned),
        "unsigned_rows": len(unsigned),
        "reason_counts": dict(sorted(reason_counts.items())),
        "unsigned_reason_counts": dict(sorted(unsigned_reason_counts.items())),
    }


def emit(payload: dict[str, object], json_out: bool) -> None:
    if json_out:
        print(json.dumps(payload, sort_keys=True))
        return
    print(
        f"status={payload['status']} total={payload['total_rows']} "
        f"unsigned={payload['unsigned_rows']}"
    )


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--queue", required=True)
    parser.add_argument("--out")
    parser.add_argument("--sign-safe", action="store_true")
    parser.add_argument(
        "--mode-b-evidence",
        help="Evidence string required before policy-signing mode-B keyword rows.",
    )
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args(argv)

    try:
        rows = read_jsonl(Path(args.queue))
    except (OSError, ValueError) as exc:
        emit(
            {
                "schema_version": SCHEMA_VERSION,
                "status": "fail",
                "error": str(exc),
                "exit_code": 1,
            },
            args.json,
        )
        return 1

    safe_signed_rows = 0
    output_path = Path(args.out) if args.out else None
    if args.sign_safe:
        rows, safe_signed_rows = apply_safe_signoffs(rows, args.mode_b_evidence)
        if output_path:
            write_jsonl(output_path, rows)
    summary = summarize(rows)
    payload = {
        "schema_version": SCHEMA_VERSION,
        "status": "pass",
        "exit_code": 0,
        "queue": str(Path(args.queue)),
        "out": str(output_path) if output_path else None,
        "safe_signed_rows": safe_signed_rows,
        **summary,
    }
    emit(payload, args.json)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

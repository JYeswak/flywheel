#!/usr/bin/env python3
"""Daily Dicklesworthstone signal gate for /flywheel:tick Step 4m."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import subprocess
import sys
from pathlib import Path
from typing import Any


SCHEMA_VERSION = "dicklesworthstone-signal-gate/v1"
DEFAULT_STATE_DIR = Path.home() / ".local/state/dicklesworthstone-stack"
DEFAULT_LEDGER = DEFAULT_STATE_DIR / "signal-ledger.jsonl"
DEFAULT_OUTCOMES = DEFAULT_STATE_DIR / "signal-outcomes.jsonl"
DEFAULT_QUOTA_LEDGER = Path.home() / ".local/state/flywheel/dicklesworthstone-signal-gate.jsonl"
SEEN_STATES = {"seen", "noted"}
ADVANCED_STATES = {"noted", "strike-evidence", "extracted", "archived"}
EXTRACTED_VALUES = {"extracted", "extract"}


def parse_iso(value: Any) -> dt.datetime | None:
    if not isinstance(value, str) or not value:
        return None
    text = value.strip()
    if text.endswith("Z"):
        text = f"{text[:-1]}+00:00"
    try:
        parsed = dt.datetime.fromisoformat(text)
    except ValueError:
        return None
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=dt.timezone.utc)
    return parsed.astimezone(dt.timezone.utc)


def iso_now(value: str | None) -> dt.datetime:
    parsed = parse_iso(value) if value else None
    return parsed or dt.datetime.now(dt.timezone.utc)


def read_jsonl(path: Path) -> tuple[list[dict[str, Any]], int]:
    rows: list[dict[str, Any]] = []
    malformed = 0
    if not path.exists():
        return rows, malformed
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except json.JSONDecodeError:
            malformed += 1
            continue
        if isinstance(row, dict):
            rows.append(row)
        else:
            malformed += 1
    return rows, malformed


def append_jsonl(path: Path, row: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(row, sort_keys=True, separators=(",", ":")) + "\n")


def row_state(row: dict[str, Any]) -> str:
    for key in ("state", "status", "signal_state", "to_state"):
        value = row.get(key)
        if isinstance(value, str) and value:
            return value
    return "unknown"


def row_time(row: dict[str, Any]) -> dt.datetime | None:
    for key in ("ts", "ts_state_changed", "ts_seen", "created_at", "updated_at", "date"):
        parsed = parse_iso(row.get(key))
        if parsed:
            return parsed
    return None


def event_day(row: dict[str, Any]) -> str | None:
    parsed = row_time(row)
    return parsed.date().isoformat() if parsed else None


def is_advance(row: dict[str, Any]) -> bool:
    if row.get("advanced") is True:
        return True
    from_state = row.get("from_state")
    to_state = row.get("to_state")
    if isinstance(from_state, str) and isinstance(to_state, str) and from_state != to_state:
        return True
    state = row_state(row)
    action = str(row.get("action") or row.get("event") or "")
    return state in ADVANCED_STATES or action in {"note", "strike", "extract", "archive"}


def is_extraction(row: dict[str, Any]) -> bool:
    fields = [
        row.get("state"),
        row.get("to_state"),
        row.get("action"),
        row.get("event"),
        row.get("extracted_to"),
        row.get("extracted_ref"),
    ]
    return any(str(value).lower() in EXTRACTED_VALUES for value in fields if value is not None)


def ranked_signal(row: dict[str, Any]) -> dict[str, Any]:
    return {
        "id": row.get("id") or row.get("signal_id"),
        "state": row_state(row),
        "source": row.get("source"),
        "title": row.get("title") or row.get("summary") or row.get("name"),
        "ts_seen": row.get("ts_seen") or row.get("ts") or row.get("created_at"),
    }


def days_between(now: dt.datetime, then: dt.datetime | None) -> int | None:
    if not then:
        return None
    return max(0, (now.date() - then.date()).days)


def build_summary(args: argparse.Namespace) -> dict[str, Any]:
    now = iso_now(args.now)
    ledger_rows, ledger_malformed = read_jsonl(Path(args.ledger))
    outcome_rows, outcome_malformed = read_jsonl(Path(args.outcomes))
    quota_rows, quota_malformed = read_jsonl(Path(args.quota_ledger))

    seen_rows = [row for row in ledger_rows if row_state(row) in SEEN_STATES]
    exact_seen_rows = [row for row in ledger_rows if row_state(row) == "seen"]
    noted_rows = [row for row in ledger_rows if row_state(row) == "noted"]
    extracted_rows = [row for row in ledger_rows if row_state(row) == "extracted"]
    archived_rows = [row for row in ledger_rows if row_state(row) == "archived"]

    today = now.date().isoformat()
    advanced_today = [row for row in outcome_rows if event_day(row) == today and is_advance(row)]
    extraction_times = [row_time(row) for row in outcome_rows if is_extraction(row)]
    extraction_times.extend(row_time(row) for row in extracted_rows)
    extraction_times = [value for value in extraction_times if value is not None]
    last_extraction = max(extraction_times) if extraction_times else None
    oldest_active = min((row_time(row) for row in seen_rows if row_time(row)), default=None)
    days_since_extraction = days_between(now, last_extraction)
    oldest_active_age_days = days_between(now, oldest_active)

    quota_logged_today = any(
        event_day(row) == today
        and row.get("event") in {"daily_no_advance", "daily_advance_observed"}
        for row in quota_rows
    )
    ranked_recommended = len(seen_rows) > args.seen_threshold
    zero_extract_days = (
        days_since_extraction is not None and days_since_extraction >= args.zero_extraction_days
    ) or (
        last_extraction is None
        and oldest_active_age_days is not None
        and oldest_active_age_days >= args.zero_extraction_days
    )

    ranked_rows = sorted(
        seen_rows,
        key=lambda row: (
            row_state(row) != "noted",
            row_time(row) or dt.datetime.max.replace(tzinfo=dt.timezone.utc),
            str(row.get("source") or ""),
        ),
    )[:5]

    no_advance_reason = args.no_advance_reason
    if advanced_today:
        no_advance_reason = None

    return {
        "schema_version": SCHEMA_VERSION,
        "mode": "dry-run" if args.dry_run else "apply",
        "status": "ok",
        "now": now.strftime("%Y-%m-%dT%H:%M:%SZ"),
        "ledger": str(Path(args.ledger)),
        "outcomes": str(Path(args.outcomes)),
        "quota_ledger": str(Path(args.quota_ledger)),
        "counts": {
            "ledger_rows": len(ledger_rows),
            "seen_count": len(exact_seen_rows),
            "noted_count": len(noted_rows),
            "active_signal_count": len(seen_rows),
            "extracted_count": len(extracted_rows),
            "archived_count": len(archived_rows),
            "outcome_rows": len(outcome_rows),
            "advanced_today_count": len(advanced_today),
        },
        "malformed_rows": {
            "ledger": ledger_malformed,
            "outcomes": outcome_malformed,
            "quota_ledger": quota_malformed,
        },
        "daily_quota": {
            "date": today,
            "target_advance_count": 1,
            "advanced_today_count": len(advanced_today),
            "quota_logged_today": quota_logged_today,
            "no_advance_reason": no_advance_reason,
            "would_log_no_advance_reason": not advanced_today and not quota_logged_today,
            "no_advance_logged": False,
        },
        "ranked_promotion_bead": {
            "recommended": ranked_recommended,
            "threshold": args.seen_threshold,
            "priority": 2,
            "title": "[signal-gate] promote stale Dicklesworthstone signals",
            "top_signals": [ranked_signal(row) for row in ranked_rows],
            "filed_id": None,
        },
        "doctrine_drift_bead": {
            "recommended": zero_extract_days,
            "priority": 1,
            "title": "[signal-gate] doctrine drift: zero Dicklesworthstone extractions for 7d",
            "days_since_extraction": days_since_extraction,
            "oldest_active_age_days": oldest_active_age_days,
            "last_extraction_ts": last_extraction.strftime("%Y-%m-%dT%H:%M:%SZ")
            if last_extraction
            else None,
            "filed_id": None,
        },
        "beads_filed_count": 0,
    }


def create_bead(args: argparse.Namespace, title: str, priority: int, description: str) -> str:
    cmd = [
        args.br_bin,
        "create",
        title,
        "--type",
        "task",
        "--priority",
        str(priority),
        "--description",
        description,
        "--json",
    ]
    result = subprocess.run(
        cmd,
        cwd=args.repo,
        check=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    try:
        payload = json.loads(result.stdout)
    except json.JSONDecodeError:
        return result.stdout.strip()
    return str(payload.get("id") or payload.get("issue", {}).get("id") or "").strip()


def apply_actions(args: argparse.Namespace, summary: dict[str, Any]) -> None:
    quota = summary["daily_quota"]
    if quota["would_log_no_advance_reason"]:
        append_jsonl(
            Path(args.quota_ledger),
            {
                "schema_version": SCHEMA_VERSION,
                "event": "daily_no_advance",
                "date": quota["date"],
                "ts": summary["now"],
                "no_advance_reason": quota["no_advance_reason"],
                "active_signal_count": summary["counts"]["active_signal_count"],
                "seen_count": summary["counts"]["seen_count"],
                "noted_count": summary["counts"]["noted_count"],
            },
        )
        quota["no_advance_logged"] = True
        quota["quota_logged_today"] = True

    if not args.auto_file_beads:
        return

    filed_count = 0
    if summary["ranked_promotion_bead"]["recommended"]:
        description = (
            "Tick Step 4m found "
            f"{summary['counts']['active_signal_count']} seen/noted Dicklesworthstone signals. "
            "Rank and promote one extraction/archive decision from the signal gate."
        )
        issue_id = create_bead(
            args,
            summary["ranked_promotion_bead"]["title"],
            summary["ranked_promotion_bead"]["priority"],
            description,
        )
        summary["ranked_promotion_bead"]["filed_id"] = issue_id
        filed_count += 1

    if summary["doctrine_drift_bead"]["recommended"]:
        description = (
            "Tick Step 4m found zero Dicklesworthstone extractions past the "
            f"{args.zero_extraction_days}d doctrine-drift threshold. "
            "Restore daily extraction discipline or record a durable no-advance reason."
        )
        issue_id = create_bead(
            args,
            summary["doctrine_drift_bead"]["title"],
            summary["doctrine_drift_bead"]["priority"],
            description,
        )
        summary["doctrine_drift_bead"]["filed_id"] = issue_id
        filed_count += 1

    summary["beads_filed_count"] = filed_count


def print_human(summary: dict[str, Any]) -> None:
    counts = summary["counts"]
    quota = summary["daily_quota"]
    print("Dicklesworthstone signal gate")
    print(f"  active signals: {counts['active_signal_count']}")
    print(f"  advanced today: {quota['advanced_today_count']}/{quota['target_advance_count']}")
    print(f"  no advance reason: {quota['no_advance_reason'] or 'none'}")
    print(f"  ranked promotion bead: {summary['ranked_promotion_bead']['recommended']}")
    print(f"  doctrine drift bead: {summary['doctrine_drift_bead']['recommended']}")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Dicklesworthstone signal gate tick helper")
    parser.add_argument("command", nargs="?", default="tick")
    parser.add_argument("--repo", default="/Users/josh/Developer/flywheel")
    parser.add_argument("--ledger", default=str(DEFAULT_LEDGER))
    parser.add_argument("--outcomes", default=str(DEFAULT_OUTCOMES))
    parser.add_argument("--quota-ledger", default=str(DEFAULT_QUOTA_LEDGER))
    parser.add_argument("--seen-threshold", type=int, default=3)
    parser.add_argument("--zero-extraction-days", type=int, default=7)
    parser.add_argument("--no-advance-reason", default="no extract/archive decision made in this tick")
    parser.add_argument("--now")
    parser.add_argument("--br-bin", default=os.environ.get("BR_BIN", "br"))
    parser.add_argument("--auto-file-beads", action="store_true")
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--json", action="store_true")
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    command = args.command.replace("_", "-")
    if command in {"help"}:
        parser.print_help()
        return 0
    if command in {"schema", "info", "examples"}:
        payload = {
            "schema_version": SCHEMA_VERSION,
            "commands": ["tick", "doctor", "health", "schema", "info", "examples"],
            "default_ledger": str(DEFAULT_LEDGER),
            "default_outcomes": str(DEFAULT_OUTCOMES),
            "default_quota_ledger": str(DEFAULT_QUOTA_LEDGER),
        }
        print(json.dumps(payload, indent=2, sort_keys=True))
        return 0
    if command not in {"tick", "doctor", "health", "validate"}:
        parser.error(f"unknown command: {args.command}")

    args.dry_run = args.dry_run or not args.apply
    summary = build_summary(args)
    if not args.dry_run:
        apply_actions(args, summary)

    if args.json:
        print(json.dumps(summary, indent=2, sort_keys=True))
    else:
        print_human(summary)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

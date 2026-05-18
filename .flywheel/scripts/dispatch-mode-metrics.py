#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

VALID_MODES = {"loop", "goal", "manual", "watcher", "unknown"}
PULSE_EVENTS = {"dispatch_sent", "ntm_dispatch_sent", "idle_pane_auto_dispatch", "autoloop_dispatch_sent"}
CALLBACK_EVENTS = {"callback", "callback_received", "bead_callback_received", "worker_callback"}
CLOSE_EVENTS = {"close", "closed", "bead_close_verified"}


def parse_ts(value: Any) -> datetime | None:
    if not value:
        return None
    raw = str(value)
    for candidate in (raw, raw.replace("Z", "+00:00")):
        try:
            parsed = datetime.fromisoformat(candidate)
        except ValueError:
            continue
        if parsed.tzinfo is None:
            parsed = parsed.replace(tzinfo=timezone.utc)
        return parsed.astimezone(timezone.utc)
    return None


def read_jsonl(path: Path) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    if not path.exists():
        return rows
    for line in path.read_text().splitlines():
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except json.JSONDecodeError:
            continue
        if isinstance(row, dict):
            rows.append(row)
    return rows


def build_attribution(rows: list[dict[str, Any]]) -> dict[str, dict[str, Any]]:
    attribution: dict[str, dict[str, Any]] = {}
    for row in rows:
        task_id = row.get("task_id")
        if not isinstance(task_id, str) or not task_id:
            continue
        mode = row.get("mode")
        if not isinstance(mode, str) or mode not in VALID_MODES or mode == "unknown":
            continue
        attribution[task_id] = {
            "mode": mode,
            "origin_task_id": row.get("origin_task_id") or task_id,
            "goal_id": row.get("goal_id"),
            "sprint_id": row.get("sprint_id"),
            "tick_id": row.get("tick_id"),
        }
    return attribution


def normalized_mode(row: dict[str, Any], attribution: dict[str, dict[str, Any]]) -> str:
    mode = row.get("mode")
    if isinstance(mode, str) and mode in VALID_MODES:
        return mode
    task_id = row.get("task_id")
    if isinstance(task_id, str):
        attributed = attribution.get(task_id, {}).get("mode")
        if isinstance(attributed, str) and attributed in VALID_MODES:
            return attributed
    return "unknown"


def event_name(row: dict[str, Any]) -> str:
    return str(row.get("event") or row.get("status") or "")


def is_pulse(row: dict[str, Any]) -> bool:
    return event_name(row) in PULSE_EVENTS or row.get("dispatch_status") in {
        "generating_verified",
        "queued_for_send",
        "sent",
    }


def is_productive_callback(row: dict[str, Any]) -> bool:
    status = str(row.get("status") or row.get("callback_status") or "").lower()
    if "blocked" in status:
        return False
    return event_name(row) in CALLBACK_EVENTS or row.get("callback_received_at") not in (None, "", "null")


def is_close(row: dict[str, Any]) -> bool:
    return event_name(row) in CLOSE_EVENTS or str(row.get("status") or "").lower() == "closed"


def summarize(rows: list[dict[str, Any]], since: datetime | None, until: datetime | None) -> dict[str, Any]:
    attribution = build_attribution(rows)
    by_mode: dict[str, dict[str, Any]] = {
        mode: {
            "mode": mode,
            "pulse_count": 0,
            "productive_callback_count": 0,
            "close_count": 0,
            "first_ts": None,
            "last_ts": None,
            "productive_callback_per_pulse": 0.0,
            "bead_close_per_hour": 0.0,
            "active_span_hours": 0.0,
        }
        for mode in sorted(VALID_MODES)
    }
    considered = 0
    for row in rows:
        ts = parse_ts(row.get("ts") or row.get("timestamp") or row.get("created_at"))
        if ts is None or (since and ts < since) or (until and ts > until):
            continue
        considered += 1
        bucket = by_mode[normalized_mode(row, attribution)]
        if is_pulse(row):
            bucket["pulse_count"] += 1
        if is_productive_callback(row):
            bucket["productive_callback_count"] += 1
        if is_close(row):
            bucket["close_count"] += 1
        first = parse_ts(bucket["first_ts"])
        last = parse_ts(bucket["last_ts"])
        if first is None or ts < first:
            bucket["first_ts"] = ts.strftime("%Y-%m-%dT%H:%M:%SZ")
        if last is None or ts > last:
            bucket["last_ts"] = ts.strftime("%Y-%m-%dT%H:%M:%SZ")

    for bucket in by_mode.values():
        if bucket["pulse_count"]:
            bucket["productive_callback_per_pulse"] = round(
                bucket["productive_callback_count"] / bucket["pulse_count"], 6
            )
        first = parse_ts(bucket["first_ts"])
        last = parse_ts(bucket["last_ts"])
        if first and last and last > first:
            hours = (last - first).total_seconds() / 3600
            bucket["active_span_hours"] = round(hours, 6)
            bucket["bead_close_per_hour"] = round(bucket["close_count"] / hours, 6)

    return {
        "schema_version": "flywheel.dispatch_mode_metrics.v1",
        "since": since.strftime("%Y-%m-%dT%H:%M:%SZ") if since else None,
        "until": until.strftime("%Y-%m-%dT%H:%M:%SZ") if until else None,
        "rows_considered": considered,
        "modes": by_mode,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--log", default=".flywheel/dispatch-log.jsonl")
    parser.add_argument("--since")
    parser.add_argument("--until")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    report = summarize(read_jsonl(Path(args.log)), parse_ts(args.since), parse_ts(args.until))
    if args.json:
        print(json.dumps(report, sort_keys=True))
    else:
        for row in report["modes"].values():
            print(
                f"{row['mode']}: pulses={row['pulse_count']} "
                f"productive_callbacks={row['productive_callback_count']} "
                f"closes={row['close_count']} "
                f"callbacks_per_pulse={row['productive_callback_per_pulse']} "
                f"closes_per_hour={row['bead_close_per_hour']}"
            )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

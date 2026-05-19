#!/usr/bin/env python3
# Meta-pattern Adoption stance:
# Embodies MP-60-measured-performance-budget-loop.md and MP-40-outside-observer-goal-contract.md.
# Source: /Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/
from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

DEFAULT_MIN_LOOP_CLOSES_PER_HOUR = 3.5
DEFAULT_MIN_LOOP_TO_GOAL_RATIO = 0.5
DEFAULT_MIN_SINCE = "2026-06-01T00:00:00Z"
DEFAULT_MIN_WINDOW_HOURS = 336.0


def load_metrics(path: Path) -> dict[str, Any]:
    try:
        payload = json.loads(path.read_text())
    except FileNotFoundError:
        raise SystemExit(f"metrics file not found: {path}")
    except json.JSONDecodeError as exc:
        raise SystemExit(f"metrics file is not valid JSON: {exc}")
    if not isinstance(payload, dict):
        raise SystemExit("metrics file must contain a JSON object")
    return payload


def number(value: Any) -> float:
    if isinstance(value, (int, float)):
        return float(value)
    return 0.0


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


def mode(metrics: dict[str, Any], name: str) -> dict[str, Any]:
    candidate = (metrics.get("modes") or {}).get(name)
    return candidate if isinstance(candidate, dict) else {}


def evaluate(
    metrics: dict[str, Any],
    min_loop_closes_per_hour: float,
    min_loop_to_goal_ratio: float,
    min_since: datetime | None,
    min_window_hours: float,
) -> dict[str, Any]:
    loop = mode(metrics, "loop")
    goal = mode(metrics, "goal")
    since = parse_ts(metrics.get("since"))
    until = parse_ts(metrics.get("until"))
    loop_rate = number(loop.get("bead_close_per_hour"))
    goal_rate = number(goal.get("bead_close_per_hour"))
    ratio = loop_rate / goal_rate if goal_rate > 0 else 0.0
    window_hours = (until - since).total_seconds() / 3600 if since and until and until > since else 0.0
    seven_day_windows = metrics.get("seven_day_windows") if isinstance(metrics.get("seven_day_windows"), list) else []
    checks = {
        "bounded_window": bool(since and until),
        "post_soak_window": bool(since and min_since and since >= min_since),
        "window_duration": window_hours >= min_window_hours,
        "seven_day_mode_harmony": bool(seven_day_windows)
        and all(bool(window.get("loop_goal_harmony")) for window in seven_day_windows if isinstance(window, dict)),
        "loop_close_rate": loop_rate >= min_loop_closes_per_hour,
        "loop_goal_ratio": ratio >= min_loop_to_goal_ratio,
        "loop_dispatch_count": int(number(loop.get("pulse_count"))) > 0,
        "goal_dispatch_count": int(number(goal.get("pulse_count"))) > 0,
    }
    failure_codes = [name for name, passed in checks.items() if not passed]
    status = "pass" if not failure_codes else "fail"
    return {
        "schema_version": "flywheel.loop_contract_efficacy_gate.v1",
        "status": status,
        "phase5_required": status != "pass",
        "failure_codes": failure_codes,
        "thresholds": {
            "min_loop_closes_per_hour": min_loop_closes_per_hour,
            "min_loop_to_goal_ratio": min_loop_to_goal_ratio,
            "min_since": min_since.strftime("%Y-%m-%dT%H:%M:%SZ") if min_since else None,
            "min_window_hours": min_window_hours,
        },
        "window": {
            "since": metrics.get("since"),
            "until": metrics.get("until"),
            "window_hours": round(window_hours, 6),
            "rows_considered": metrics.get("rows_considered"),
            "seven_day_windows": seven_day_windows,
        },
        "observed": {
            "loop_bead_close_per_hour": loop_rate,
            "goal_bead_close_per_hour": goal_rate,
            "loop_to_goal_ratio": round(ratio, 6),
            "loop_pulse_count": int(number(loop.get("pulse_count"))),
            "goal_pulse_count": int(number(goal.get("pulse_count"))),
        },
        "checks": checks,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--metrics", required=True, help="dispatch-mode-metrics.py JSON output")
    parser.add_argument("--min-loop-closes-per-hour", type=float, default=DEFAULT_MIN_LOOP_CLOSES_PER_HOUR)
    parser.add_argument("--min-loop-to-goal-ratio", type=float, default=DEFAULT_MIN_LOOP_TO_GOAL_RATIO)
    parser.add_argument("--min-since", default=DEFAULT_MIN_SINCE)
    parser.add_argument("--min-window-hours", type=float, default=DEFAULT_MIN_WINDOW_HOURS)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    result = evaluate(
        load_metrics(Path(args.metrics)),
        args.min_loop_closes_per_hour,
        args.min_loop_to_goal_ratio,
        parse_ts(args.min_since),
        args.min_window_hours,
    )
    if args.json:
        print(json.dumps(result, sort_keys=True))
    else:
        print(f"{result['status']}: failures={','.join(result['failure_codes']) or 'none'}")
    return 0 if result["status"] == "pass" else 1


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except BrokenPipeError:
        sys.exit(1)

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`

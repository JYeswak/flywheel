#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

DEFAULT_MIN_LOOP_CLOSES_PER_HOUR = 3.5
DEFAULT_MIN_LOOP_TO_GOAL_RATIO = 0.5


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


def mode(metrics: dict[str, Any], name: str) -> dict[str, Any]:
    candidate = (metrics.get("modes") or {}).get(name)
    return candidate if isinstance(candidate, dict) else {}


def evaluate(
    metrics: dict[str, Any],
    min_loop_closes_per_hour: float,
    min_loop_to_goal_ratio: float,
) -> dict[str, Any]:
    loop = mode(metrics, "loop")
    goal = mode(metrics, "goal")
    loop_rate = number(loop.get("bead_close_per_hour"))
    goal_rate = number(goal.get("bead_close_per_hour"))
    ratio = loop_rate / goal_rate if goal_rate > 0 else 0.0
    checks = {
        "bounded_window": bool(metrics.get("since") and metrics.get("until")),
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
        },
        "window": {
            "since": metrics.get("since"),
            "until": metrics.get("until"),
            "rows_considered": metrics.get("rows_considered"),
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
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    result = evaluate(load_metrics(Path(args.metrics)), args.min_loop_closes_per_hour, args.min_loop_to_goal_ratio)
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

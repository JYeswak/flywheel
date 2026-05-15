#!/usr/bin/env python3
"""Simulate /goal-mode cycles from an event fixture.

Models the accretive-watch state machine:
  - If an event arrives (operator_input | new_commit | ci_change |
    worker_state | callback | finding), emit an ACT row.
  - Otherwise, increment the no-event streak; emit ACCRETE for streaks
    1..2 and STAND_DOWN for streak >=3 (anti-spin).
  - When STAND_DOWN holds, subsequent no-events emit STAND_DOWN (held).
  - A new event breaks the streak and emits ACT.

Inputs:
  --events FILE   JSONL fixture, one event per turn:
                  {"turn":N, "event":"<type>", "detail":"<text>"}
                  event type "none" means no wake fired.
  --out FILE      Write simulated rolling-log JSONL to this path
                  (default: stdout).
  --verify-anti-spin-at N
                  Assert the row at turn N has cycle=STAND_DOWN.
                  Useful for the canonical 3-no-event-fires-stand-down
                  fixture.
  --json          Emit summary as JSON.

Output rows match the schema enforced by scripts/validate_watch_log.py.
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import sys
from pathlib import Path
from typing import Any

WAKE_EVENTS = {
    "operator_input",
    "new_commit",
    "ci_change",
    "worker_state",
    "callback",
    "finding",
}

ANTI_SPIN_THRESHOLD = 3


def base_ts(turn: int) -> str:
    base = dt.datetime(2026, 5, 15, 0, 0, 0, tzinfo=dt.timezone.utc)
    return (base + dt.timedelta(seconds=turn)).strftime("%Y-%m-%dT%H:%M:%SZ")


def simulate(events: list[dict[str, Any]]) -> list[dict[str, Any]]:
    out: list[dict[str, Any]] = []
    no_event_streak = 0
    for ev in events:
        turn = int(ev.get("turn", len(out) + 1))
        kind = ev.get("event", "none")
        detail = ev.get("detail", "")
        ts = base_ts(turn)

        if kind in WAKE_EVENTS:
            no_event_streak = 0
            row = {
                "ts": ts,
                "cycle": "ACT",
                "event": kind.replace("_", "-"),
                "detail": detail or f"sim {kind} at turn {turn}",
                "receipt": f"sim:turn-{turn}",
            }
        elif kind == "none":
            no_event_streak += 1
            if no_event_streak >= ANTI_SPIN_THRESHOLD:
                row = {
                    "ts": ts,
                    "cycle": "STAND_DOWN",
                    "event": "anti-spin-hold" if no_event_streak == ANTI_SPIN_THRESHOLD else "stand-down-held",
                    "detail": detail or f"no-event streak={no_event_streak}, anti-spin fired",
                    "receipt": f"sim:turn-{turn}",
                }
            else:
                row = {
                    "ts": ts,
                    "cycle": "ACCRETE",
                    "event": "sim-accrete",
                    "detail": detail or f"no event; streak={no_event_streak}; simulated accretion",
                    "artifact": f"sim:artifact-turn-{turn}",
                    "reusable_because": "fixture-simulated accretion",
                }
        else:
            row = {
                "ts": ts,
                "cycle": "ACT",
                "event": "unknown-event-type",
                "detail": f"fixture event {kind!r} not recognised; treated as ACT for honesty",
                "receipt": f"sim:turn-{turn}",
            }
            no_event_streak = 0

        out.append(row)

    return out


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--events", required=True, help="event fixture JSONL")
    parser.add_argument("--out", help="output JSONL (default: stdout)")
    parser.add_argument(
        "--verify-anti-spin-at",
        type=int,
        help="assert simulated row at this turn is STAND_DOWN",
    )
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    events_path = Path(args.events)
    if not events_path.exists():
        print(f"events fixture not found: {events_path}", file=sys.stderr)
        return 2

    events: list[dict[str, Any]] = []
    for line in events_path.read_text().splitlines():
        if not line.strip():
            continue
        events.append(json.loads(line))

    rows = simulate(events)

    out_lines = [json.dumps(r) for r in rows]
    if args.out:
        Path(args.out).write_text("\n".join(out_lines) + "\n")

    verify_status: dict[str, Any] = {"checked": False}
    if args.verify_anti_spin_at is not None:
        target = args.verify_anti_spin_at
        match = next((r for r in rows if r.get("receipt") == f"sim:turn-{target}"), None)
        actual = match.get("cycle") if match else None
        ok = actual == "STAND_DOWN"
        verify_status = {
            "checked": True,
            "target_turn": target,
            "expected_cycle": "STAND_DOWN",
            "actual_cycle": actual,
            "pass": ok,
        }

    cycle_counts: dict[str, int] = {}
    for r in rows:
        c = r["cycle"]
        cycle_counts[c] = cycle_counts.get(c, 0) + 1

    summary = {
        "event_count": len(events),
        "row_count": len(rows),
        "cycle_counts": cycle_counts,
        "verify": verify_status,
        "out_path": args.out,
    }

    if args.json:
        print(json.dumps(summary, indent=2))
    else:
        if not args.out:
            for line in out_lines:
                print(line)
        else:
            print(
                f"events={summary['event_count']} rows={summary['row_count']} "
                f"cycles={cycle_counts} -> {args.out}"
            )
        if verify_status["checked"]:
            mark = "PASS" if verify_status["pass"] else "FAIL"
            print(
                f"{mark} anti-spin: turn={verify_status['target_turn']} "
                f"expected=STAND_DOWN actual={verify_status['actual_cycle']}",
                file=sys.stderr if not verify_status["pass"] else sys.stdout,
            )

    if verify_status["checked"] and not verify_status["pass"]:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

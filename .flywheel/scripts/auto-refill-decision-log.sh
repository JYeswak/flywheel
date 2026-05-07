#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"

python3 - "$ROOT" "$@" <<'PY'
import argparse
import json
import os
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(sys.argv[1])


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Decide and log hot-pane refill after callback reap."
    )
    parser.add_argument("--repo", default=str(ROOT))
    parser.add_argument("--session", default=os.environ.get("SESSION", "flywheel"))
    parser.add_argument("--pane", type=int)
    parser.add_argument("--role", default="")
    parser.add_argument("--callback-task-id", default="")
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--activity-file", default=os.environ.get("AUTO_REFILL_ACTIVITY_FILE", ""))
    parser.add_argument("--ready-file", default=os.environ.get("AUTO_REFILL_READY_FILE", ""))
    parser.add_argument("--capacity-file", default=os.environ.get("AUTO_REFILL_CAPACITY_FILE", ""))
    parser.add_argument("--dispatch-log", default=os.environ.get("AUTO_REFILL_DISPATCH_LOG", ""))
    parser.add_argument("--ledger", default=os.environ.get("AUTO_REFILL_LEDGER", ""))
    parser.add_argument("--now", default=os.environ.get("AUTO_REFILL_NOW", ""))
    parser.add_argument("--idle-window-metric", action="store_true")
    return parser.parse_args(sys.argv[2:])


def iso_now(explicit: str = "") -> str:
    if explicit:
        return explicit
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def parse_iso(value: str) -> datetime | None:
    if not value:
        return None
    text = value.replace("Z", "+00:00")
    try:
        dt = datetime.fromisoformat(text)
    except ValueError:
        return None
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)


def read_json(path: str, default):
    if path and Path(path).is_file():
        try:
            return json.loads(Path(path).read_text())
        except Exception:
            return default
    return default


def run_json(cmd: list[str], default):
    try:
        out = subprocess.check_output(cmd, stderr=subprocess.DEVNULL, text=True, timeout=15)
        return json.loads(out)
    except Exception:
        return default


def activity_json(args: argparse.Namespace):
    if args.activity_file:
        return read_json(args.activity_file, {"agents": []})
    ntm = os.environ.get("NTM_BIN", "/Users/josh/.local/bin/ntm")
    return run_json([ntm, f"--robot-activity={args.session}", "--activity-type=codex,claude"], {"agents": []})


def ready_json(args: argparse.Namespace):
    if args.ready_file:
        return read_json(args.ready_file, {"issues": []})
    br = os.environ.get("BR_BIN", "/Users/josh/.cargo/bin/br")
    try:
        out = subprocess.check_output([br, "ready", "--json"], cwd=args.repo, stderr=subprocess.DEVNULL, text=True, timeout=15)
        return json.loads(out)
    except Exception:
        return {"issues": []}


def object_rows(payload):
    if isinstance(payload, list):
        return [x for x in payload if isinstance(x, dict)]
    if not isinstance(payload, dict):
        return []
    rows = []
    for key in ("agents", "panes", "workers", "rows"):
        value = payload.get(key)
        if isinstance(value, list):
            rows.extend([x for x in value if isinstance(x, dict)])
    return rows


def pane_state(payload, pane: int | None) -> str:
    if pane is None:
        return "UNKNOWN"
    for row in object_rows(payload):
        row_pane = row.get("pane_idx", row.get("pane", row.get("index")))
        try:
            row_pane_int = int(row_pane)
        except Exception:
            continue
        if row_pane_int == pane:
            return str(row.get("state", row.get("robot_state", row.get("activity_state", "UNKNOWN")))).upper()
    return "UNKNOWN"


def ready_items(payload):
    if isinstance(payload, list):
        return [x for x in payload if isinstance(x, dict)]
    if not isinstance(payload, dict):
        return []
    for key in ("issues", "items", "ready", "beads", "rows"):
        value = payload.get(key)
        if isinstance(value, list):
            return [x for x in value if isinstance(x, dict)]
    return []


def role_matches(item: dict, role: str) -> bool:
    if not role:
        return True
    raw = [
        item.get("role"),
        item.get("capability"),
        item.get("agent_type"),
        item.get("worker_type"),
        item.get("assignee"),
    ]
    labels = item.get("labels", [])
    if isinstance(labels, list):
        raw.extend(labels)
    text = " ".join(str(x).lower() for x in raw if x is not None)
    return not text or role.lower() in text


def is_open(item: dict) -> bool:
    status = str(item.get("status", "open")).lower()
    return status in {"open", "ready", "todo", "new"}


def blocker_reason(item: dict) -> str | None:
    if item.get("true_joshua_blocker") is True:
        return "joshua_blocker_class_true"
    value = item.get("blocker_class") or item.get("blocked_by") or item.get("reason")
    if value and "josh" in str(value).lower():
        clean = "".join(ch if ch.isalnum() else "_" for ch in str(value).lower()).strip("_")
        return f"joshua_blocker_class_{clean or 'unknown'}"
    return None


def first_ready_for_role(payload, role: str):
    for item in ready_items(payload):
        if is_open(item) and role_matches(item, role):
            return item
    return None


def read_jsonl(path: Path) -> list[dict]:
    if not path.is_file():
        return []
    rows = []
    for line in path.read_text(errors="replace").splitlines():
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except Exception:
            continue
        if isinstance(row, dict):
            rows.append(row)
    return rows


def capacity(args: argparse.Namespace, dispatch_rows: list[dict]) -> dict:
    cap_path = Path(args.capacity_file) if args.capacity_file else Path.home() / ".local/state/flywheel/fleet-capacity.json"
    data = read_json(str(cap_path), {}) if cap_path.is_file() else {}
    max_in_flight = (
        data.get("max_in_flight_dispatches")
        or data.get("max_in_flight")
        or data.get("dispatch_budget")
        or data.get("target_in_flight")
        or data.get("budget", {}).get("max_in_flight_dispatches")
        or 4
    )
    try:
        max_in_flight = int(max_in_flight)
    except Exception:
        max_in_flight = 4
    override = data.get("current_in_flight_dispatches")
    if override is not None:
        try:
            current = int(override)
        except Exception:
            current = 0
    else:
        current = 0
        for row in dispatch_rows:
            event = str(row.get("event", ""))
            if event not in {"dispatch_sent", "auto_refill_after_reap", "idle_pane_auto_dispatch"}:
                continue
            if row.get("decision") == "skipped":
                continue
            if row.get("callback_received_at") or row.get("closed_at"):
                continue
            current += 1
    return {
        "capacity_file": str(cap_path),
        "capacity_file_present": cap_path.is_file(),
        "current_in_flight": current,
        "max_in_flight": max_in_flight,
        "passes": current < max_in_flight,
    }


def append_atomic(path: Path, row: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    payload = json.dumps(row, sort_keys=True, separators=(",", ":")) + "\n"
    existing = path.read_text() if path.exists() else ""
    fd, tmp_name = tempfile.mkstemp(prefix=path.name + ".", suffix=".tmp", dir=str(path.parent))
    with os.fdopen(fd, "w") as handle:
        handle.write(existing)
        handle.write(payload)
    os.replace(tmp_name, path)


def decision(args: argparse.Namespace) -> dict:
    repo = Path(args.repo)
    log_path = Path(args.dispatch_log) if args.dispatch_log else repo / ".flywheel/dispatch-log.jsonl"
    ledger_path = Path(args.ledger) if args.ledger else repo / ".flywheel/dispatch-log.jsonl"
    rows = read_jsonl(log_path)
    activity = activity_json(args)
    ready = ready_json(args)
    state = pane_state(activity, args.pane)
    cap = capacity(args, rows)
    next_item = first_ready_for_role(ready, args.role)
    reason = None
    next_bead = None
    decision_value = "skipped"

    if state != "WAITING":
        reason = "pane_busy_robot_activity_disagreed"
    elif not cap["passes"]:
        reason = "capacity_exceeded"
    elif next_item is None:
        reason = "no_ready_beads_for_role"
    else:
        blocker = blocker_reason(next_item)
        if blocker:
            reason = blocker
        else:
            decision_value = "dispatched"
            next_bead = str(next_item.get("id") or next_item.get("bead_id") or next_item.get("task_id") or "")

    row = {
        "schema_version": "auto-refill-decision/v1",
        "event": "auto_refill_after_reap",
        "ts": iso_now(args.now),
        "session": args.session,
        "pane": args.pane,
        "role": args.role or None,
        "callback_task_id": args.callback_task_id or None,
        "decision": decision_value,
        "reason": reason,
        "next_bead_id": next_bead,
        "pane_state": state,
        "capacity": cap,
        "ready_count": len([x for x in ready_items(ready) if is_open(x)]),
        "ledger_path": str(ledger_path),
        "dry_run": not args.apply,
        "ledger_written": False,
    }
    if args.apply:
        append_atomic(ledger_path, row)
        row["ledger_written"] = True
    return row


def is_callback(row: dict) -> bool:
    event = str(row.get("event", "")).lower()
    direction = str(row.get("direction", "")).lower()
    text = " ".join(str(row.get(k, "")) for k in ("message", "body", "callback_text")).lower()
    return (
        "callback_reap" in event
        or "callback_received" in event
        or direction == "callback"
        or " done " in f" {text} "
        or " blocked " in f" {text} "
    )


def is_dispatch(row: dict) -> bool:
    event = str(row.get("event", "")).lower()
    return event in {"dispatch_sent", "auto_refill_after_reap", "idle_pane_auto_dispatch"} and row.get("decision") != "skipped"


def row_pane(row: dict):
    pane = row.get("pane", row.get("target_pane", row.get("worker_pane")))
    try:
        return int(pane)
    except Exception:
        return None


def idle_window_metric(args: argparse.Namespace) -> dict:
    repo = Path(args.repo)
    log_path = Path(args.dispatch_log) if args.dispatch_log else repo / ".flywheel/dispatch-log.jsonl"
    rows = read_jsonl(log_path)
    ready = ready_json(args)
    open_ready = len([x for x in ready_items(ready) if is_open(x)])
    now = parse_iso(iso_now(args.now)) or datetime.now(timezone.utc)
    windows = []
    for i, row in enumerate(rows):
        if not is_callback(row):
            continue
        pane = row_pane(row)
        callback_ts = parse_iso(str(row.get("ts") or row.get("callback_received_at") or ""))
        if pane is None or callback_ts is None:
            continue
        next_dispatch_ts = None
        for later in rows[i + 1 :]:
            if row_pane(later) == pane and is_dispatch(later):
                next_dispatch_ts = parse_iso(str(later.get("ts") or ""))
                break
        end = next_dispatch_ts or now
        seconds = max(0, int((end - callback_ts).total_seconds()))
        windows.append(
            {
                "pane": pane,
                "callback_ts": callback_ts.strftime("%Y-%m-%dT%H:%M:%SZ"),
                "next_dispatch_ts": next_dispatch_ts.strftime("%Y-%m-%dT%H:%M:%SZ") if next_dispatch_ts else None,
                "window_seconds": seconds,
            }
        )
    over = [w for w in windows if w["window_seconds"] > 120]
    count = len(over) if open_ready > 0 else 0
    return {
        "schema_version": "auto-refill-idle-window/v1",
        "status": "WARN" if count else "PASS",
        "dispatch_log": str(log_path),
        "ready_count": open_ready,
        "idle_pane_windows_over_2min_count": count,
        "windows_over_2min": over,
        "soft_violation": "idle_pane_window_over_2min" if count else None,
    }


def main() -> int:
    args = parse_args()
    if args.idle_window_metric:
        result = idle_window_metric(args)
    else:
        if args.pane is None:
            print("ERR: --pane is required unless --idle-window-metric is set", file=sys.stderr)
            return 64
        result = decision(args)
    if args.json:
        print(json.dumps(result, sort_keys=True, separators=(",", ":")))
    else:
        if args.idle_window_metric:
            print(f"idle_pane_windows_over_2min_count={result['idle_pane_windows_over_2min_count']}")
        else:
            print(f"{result['decision']} pane={result['pane']} reason={result['reason']} next_bead_id={result['next_bead_id']}")
    return 1 if result.get("status") == "WARN" else 0


if __name__ == "__main__":
    raise SystemExit(main())
PY

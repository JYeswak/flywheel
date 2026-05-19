#!/usr/bin/env bash
set -euo pipefail

python3 - "$@" <<'PY'
import argparse
import hashlib
import json
import os
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

SCHEMA = "pane1-bridge-tailer/v1"
LEDGER_SCHEMA = "pane1-sprint-complete-bridge/v1"


def iso_now():
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def parse_ts(value):
    if not value:
        return None
    try:
        return datetime.fromisoformat(str(value).replace("Z", "+00:00"))
    except ValueError:
        return None


def repo_root():
    here = Path.cwd()
    for candidate in [here, *here.parents]:
        if (candidate / ".flywheel").is_dir():
            return candidate
    return here


def read_jsonl(path):
    if not path.exists():
        return []
    rows = []
    with path.open("r", encoding="utf-8") as handle:
        for line_no, raw in enumerate(handle, 1):
            raw = raw.rstrip("\n")
            if not raw.strip():
                continue
            try:
                rows.append((line_no, raw, json.loads(raw)))
            except json.JSONDecodeError:
                continue
    return rows


def read_seen_keys(ledger):
    seen = set()
    if not ledger.exists():
        return seen
    for _, _, row in read_jsonl(ledger):
        key = row.get("callback_key")
        if key:
            seen.add(str(key))
    return seen


def bridge_ledger_age_hours(ledger):
    latest = None
    for _, _, row in read_jsonl(ledger):
        ts = parse_ts(row.get("ts"))
        if ts and (latest is None or ts > latest):
            latest = ts
    if latest is None:
        return None
    return round((datetime.now(timezone.utc) - latest).total_seconds() / 3600, 6)


def callback_key(raw):
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()


def is_done_callback(row):
    status = str(row.get("status", "")).upper()
    return (
        row.get("schema_version") == "callback-envelope/v1"
        and row.get("event") == "worker_callback"
        and row.get("mode") == "goal"
        and status in {"DONE", "PASS", "PASSED"}
    )


def split_list(value):
    if isinstance(value, list):
        return ",".join(str(item) for item in value) if value else "none"
    if value in (None, ""):
        return "none"
    return str(value)


def sprint_message(row):
    sprint = row.get("sprint_id") or row.get("goal_id") or "unknown"
    task = row.get("task_id") or row.get("bead") or sprint
    return (
        f"SPRINT DONE: sprint={sprint} task={task} "
        f"picks_completed={row.get('picks_completed', 'unknown')} "
        f"beads_closed={split_list(row.get('beads_closed'))} "
        f"followups={split_list(row.get('followup_beads'))} "
        f"total_work_time={row.get('total_work_time', 'unknown')} "
        f"commit={row.get('commit', 'unknown')} "
        f"tests={row.get('tests', 'unknown')} "
        f"evidence={row.get('evidence', 'unknown')}"
    )


def append_ledger(ledger, entry):
    ledger.parent.mkdir(parents=True, exist_ok=True)
    with ledger.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(entry, sort_keys=True, separators=(",", ":")) + "\n")


def emit_send(args, row, raw, key):
    session = row.get("session") or args.session
    message = sprint_message(row)
    start = time.time()
    if args.record_only:
        return {
            "schema_version": LEDGER_SCHEMA,
            "event": "pane1_sprint_complete_bridge",
            "source": "pane1-bridge-tailer",
            "mode": "record_only",
            "ts": iso_now(),
            "callback_key": key,
            "dispatch_log": str(args.dispatch_log),
            "session": session,
            "pane": str(args.pane),
            "sprint_id": row.get("sprint_id"),
            "task_id": row.get("task_id"),
            "message": message,
            "status": "sent",
            "ntm_rc": 0,
            "stdout": "record_only: direct ntm send already executed",
            "stderr": "",
            "elapsed_seconds": round(time.time() - start, 3),
        }

    cmd = [str(args.ntm), "send", str(session), f"--pane={args.pane}", "--no-cass-check", message]
    proc = subprocess.run(cmd, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
    return {
        "schema_version": LEDGER_SCHEMA,
        "event": "pane1_sprint_complete_bridge",
        "source": "pane1-bridge-tailer",
        "ts": iso_now(),
        "callback_key": key,
        "dispatch_log": str(args.dispatch_log),
        "session": session,
        "pane": str(args.pane),
        "sprint_id": row.get("sprint_id"),
        "task_id": row.get("task_id"),
        "message": message,
        "status": "sent" if proc.returncode == 0 else "failed",
        "ntm_rc": proc.returncode,
        "stdout": proc.stdout.strip(),
        "stderr": proc.stderr.strip(),
        "elapsed_seconds": round(time.time() - start, 3),
    }


def eligible_rows(args, seen):
    since = parse_ts(args.since_ts)
    rows = []
    for line_no, raw, row in read_jsonl(args.dispatch_log):
        if not is_done_callback(row):
            continue
        key = callback_key(raw)
        if key in seen:
            continue
        if args.task_id and row.get("task_id") != args.task_id:
            continue
        row_ts = parse_ts(row.get("ts") or row.get("timestamp"))
        if since and row_ts and row_ts < since:
            continue
        rows.append((line_no, raw, row, key))
    return rows


def run_once(args, seen):
    sent = []
    failed = []
    rows = eligible_rows(args, seen)
    for _, raw, row, key in rows:
        entry = emit_send(args, row, raw, key)
        append_ledger(args.ledger, entry)
        seen.add(key)
        if entry["status"] == "sent":
            sent.append(entry)
        else:
            failed.append(entry)
        if args.max_sends and len(sent) + len(failed) >= args.max_sends:
            break
    return sent, failed, len(rows)


def main():
    root = repo_root()
    parser = argparse.ArgumentParser(description="Bridge goal worker callbacks in dispatch-log.jsonl to pane 1.")
    parser.add_argument("--repo", type=Path, default=root)
    parser.add_argument("--dispatch-log", type=Path)
    parser.add_argument("--ledger", type=Path)
    parser.add_argument("--ntm", type=Path, default=Path(os.environ.get("FLYWHEEL_PANE1_SPRINT_CALLBACK_NTM", os.environ.get("NTM", "/Users/josh/.local/bin/ntm"))))
    parser.add_argument("--session", default=os.environ.get("FLYWHEEL_PANE1_SPRINT_CALLBACK_SESSION", "flywheel"))
    parser.add_argument("--pane", default=os.environ.get("FLYWHEEL_PANE1_SPRINT_CALLBACK_PANE", "1"))
    parser.add_argument("--since-ts")
    parser.add_argument("--task-id")
    parser.add_argument("--once", action="store_true")
    parser.add_argument("--follow", action="store_true")
    parser.add_argument("--poll-seconds", type=float, default=2.0)
    parser.add_argument("--max-seconds", type=float, default=0.0)
    parser.add_argument("--max-sends", type=int, default=0)
    parser.add_argument("--record-only", action="store_true", help="write bridge ledger row without invoking ntm; use only after an explicit direct ntm send")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    args.repo = args.repo.expanduser().resolve()
    if args.dispatch_log is None:
        args.dispatch_log = Path(os.environ.get("FLYWHEEL_DISPATCH_LOG", str(args.repo / ".flywheel/dispatch-log.jsonl")))
    if args.ledger is None:
        args.ledger = Path(os.environ.get("FLYWHEEL_PANE1_SPRINT_CALLBACK_LEDGER", str(Path.home() / ".local/state/flywheel/pane1-sprint-complete-bridge.jsonl")))
    args.dispatch_log = args.dispatch_log.expanduser()
    args.ledger = args.ledger.expanduser()

    if not args.once and not args.follow:
        args.once = True

    seen = read_seen_keys(args.ledger)
    total_sent = []
    total_failed = []
    started = time.time()
    iterations = 0
    candidate_count = 0

    while True:
        iterations += 1
        sent, failed, candidates = run_once(args, seen)
        total_sent.extend(sent)
        total_failed.extend(failed)
        candidate_count += candidates
        if args.once:
            break
        if args.max_sends and len(total_sent) + len(total_failed) >= args.max_sends:
            break
        if args.max_seconds and time.time() - started >= args.max_seconds:
            break
        time.sleep(args.poll_seconds)

    summary = {
        "schema_version": SCHEMA,
        "status": "fail" if total_failed else "pass",
        "dispatch_log": str(args.dispatch_log),
        "ledger": str(args.ledger),
        "iterations": iterations,
        "candidate_count": candidate_count,
        "sent": len(total_sent),
        "failed": len(total_failed),
        "bridge_ledger_age_hours": bridge_ledger_age_hours(args.ledger),
        "last_sent": total_sent[-1] if total_sent else None,
        "failures": total_failed,
    }
    if args.json:
        print(json.dumps(summary, sort_keys=True))
    else:
        print(f"{summary['status']} sent={summary['sent']} failed={summary['failed']} ledger={summary['ledger']}")
    return 0 if not total_failed else 1


if __name__ == "__main__":
    raise SystemExit(main())
PY

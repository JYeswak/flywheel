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
        if key and row.get("status") == "sent":
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


TERMINAL_STATES = {"DONE", "BLOCKED", "DECLINED"}
DONE_ALIASES = {"DONE", "PASS", "PASSED"}
TRANSIENT_STATES = {"STARTED", "ACK", "IN_PROGRESS"}


def terminal_state(row):
    status = str(row.get("status", "")).upper()
    if status in DONE_ALIASES:
        return "DONE"
    if status in {"BLOCKED", "DECLINED"}:
        return status
    if status in TRANSIENT_STATES:
        return None
    return None


def is_terminal_callback(row):
    return (
        row.get("schema_version") == "callback-envelope/v1"
        and row.get("event") == "worker_callback"
        and row.get("mode") == "goal"
        and terminal_state(row) in TERMINAL_STATES
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
    state = terminal_state(row) or "DONE"
    evidence = row.get("evidence", "unknown")
    if state == "BLOCKED":
        stop_reason = (
            row.get("stop_reason")
            or row.get("reason")
            or row.get("blocker")
            or row.get("failure_class")
            or row.get("gaps")
            or "unknown"
        )
        return f"SPRINT BLOCKED: sprint={sprint} stop_reason={stop_reason} evidence={evidence} task={task}"
    if state == "DECLINED":
        declined_reason = row.get("declined_reason") or row.get("reason") or row.get("gaps") or "unknown"
        return f"SPRINT DECLINED: sprint={sprint} declined_reason={declined_reason} task={task}"
    return (
        f"SPRINT DONE: sprint={sprint} task={task} "
        f"picks_completed={row.get('picks_completed', 'unknown')} "
        f"beads_closed={split_list(row.get('beads_closed'))} "
        f"followups={split_list(row.get('followup_beads'))} "
        f"total_work_time={row.get('total_work_time', 'unknown')} "
        f"commit={row.get('commit', 'unknown')} "
        f"tests={row.get('tests', 'unknown')} "
        f"evidence={evidence}"
    )


def append_ledger(ledger, entry):
    ledger.parent.mkdir(parents=True, exist_ok=True)
    with ledger.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(entry, sort_keys=True, separators=(",", ":")) + "\n")


def escalation_count(path):
    return len(read_jsonl(path))


def write_failure_flag(path, count):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(str(count) + "\n", encoding="utf-8")


def pending_failure_count(path):
    if not path.exists():
        return 0
    try:
        return int(path.read_text(encoding="utf-8").strip() or "0")
    except ValueError:
        return 1


def append_escalation(args, row, key, last_entry, attempts, fallback_entry):
    queue = args.escalation_queue
    entry = {
        "schema_version": "bridge-escalation/v1",
        "event": "bridge_escalated",
        "source": "pane1-bridge-tailer",
        "sprint_id": row.get("sprint_id"),
        "task_id": row.get("task_id"),
        "callback_key": key,
        "last_error": last_entry.get("stderr") or last_entry.get("stdout") or f"ntm_rc={last_entry.get('ntm_rc')}",
        "attempts": attempts,
        "escalated_at": iso_now(),
        "dispatch_log": str(args.dispatch_log),
        "ledger": str(args.ledger),
        "fallback": fallback_entry,
    }
    append_ledger(queue, entry)
    count = escalation_count(queue)
    write_failure_flag(args.failure_flag, count)
    return entry


def run_ntm(args, session, message, fallback=False):
    cmd = [str(args.ntm), "send", str(session), f"--pane={args.pane}", "--no-cass-check"]
    if fallback:
        cmd.extend(["--timeout", str(args.fallback_timeout)])
    cmd.append(message)
    return subprocess.run(cmd, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)


def build_ledger_entry(args, row, key, message, proc, start, attempt_n, retry_reason, fallback=False):
    session = row.get("session") or args.session
    state = terminal_state(row)
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
        "callback_status": str(row.get("status", "")).upper(),
        "terminal_state": state,
        "message": message,
        "attempt_n": attempt_n,
        "retry_reason": retry_reason,
        "fallback": fallback,
        "status": "sent" if proc.returncode == 0 else "failed",
        "ntm_rc": proc.returncode,
        "stdout": proc.stdout.strip(),
        "stderr": proc.stderr.strip(),
        "elapsed_seconds": round(time.time() - start, 3),
    }


def emit_send(args, row, raw, key):
    session = row.get("session") or args.session
    message = sprint_message(row)
    state = terminal_state(row)
    start = time.time()
    if args.record_only:
        entry = {
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
            "callback_status": str(row.get("status", "")).upper(),
            "terminal_state": state,
            "message": message,
            "attempt_n": 1,
            "retry_reason": "record_only",
            "status": "sent",
            "ntm_rc": 0,
            "stdout": "record_only: direct ntm send already executed",
            "stderr": "",
            "elapsed_seconds": round(time.time() - start, 3),
        }
        append_ledger(args.ledger, entry)
        return {"status": "sent", "entries": [entry], "escalation": None}

    entries = []
    retry_reason = "initial_send"
    for attempt_n in range(1, args.max_attempts + 1):
        start = time.time()
        proc = run_ntm(args, session, message)
        entry = build_ledger_entry(args, row, key, message, proc, start, attempt_n, retry_reason)
        append_ledger(args.ledger, entry)
        entries.append(entry)
        if entry["status"] == "sent":
            return {"status": "sent", "entries": entries, "escalation": None}
        retry_reason = entry.get("stderr") or entry.get("stdout") or f"ntm_rc={entry.get('ntm_rc')}"
        delay = args.retry_delays[min(attempt_n - 1, len(args.retry_delays) - 1)]
        if delay > 0:
            time.sleep(delay)

    start = time.time()
    fallback_proc = run_ntm(args, session, message, fallback=True)
    fallback_entry = build_ledger_entry(
        args,
        row,
        key,
        message,
        fallback_proc,
        start,
        args.max_attempts + 1,
        "final_fallback_after_retries_exhausted",
        fallback=True,
    )
    append_ledger(args.ledger, fallback_entry)
    entries.append(fallback_entry)
    escalation = append_escalation(args, row, key, entries[-2], args.max_attempts, fallback_entry)
    if fallback_entry["status"] == "sent":
        return {"status": "sent", "entries": entries, "escalation": escalation}
    return {"status": "failed", "entries": entries, "escalation": escalation}


def eligible_rows(args, seen):
    since = parse_ts(args.since_ts)
    rows = []
    for line_no, raw, row in read_jsonl(args.dispatch_log):
        if not is_terminal_callback(row):
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
        result = emit_send(args, row, raw, key)
        if result["status"] == "sent":
            seen.add(key)
            sent.append(result)
        else:
            failed.append(result)
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
    parser.add_argument("--max-attempts", type=int, default=3)
    parser.add_argument("--retry-delays", default="2,4,8", help="comma-separated seconds to sleep after failed attempts")
    parser.add_argument("--fallback-timeout", default=os.environ.get("FLYWHEEL_PANE1_BRIDGE_FALLBACK_TIMEOUT", "60s"))
    parser.add_argument("--escalation-queue", type=Path)
    parser.add_argument("--failure-flag", type=Path)
    parser.add_argument("--status-dashboard", action="store_true", help="read-only dashboard summary of pending bridge escalations")
    parser.add_argument("--record-only", action="store_true", help="write bridge ledger row without invoking ntm; use only after an explicit direct ntm send")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    args.repo = args.repo.expanduser().resolve()
    if args.dispatch_log is None:
        args.dispatch_log = Path(os.environ.get("FLYWHEEL_DISPATCH_LOG", str(args.repo / ".flywheel/dispatch-log.jsonl")))
    if args.ledger is None:
        args.ledger = Path(os.environ.get("FLYWHEEL_PANE1_SPRINT_CALLBACK_LEDGER", str(Path.home() / ".local/state/flywheel/pane1-sprint-complete-bridge.jsonl")))
    if args.escalation_queue is None:
        args.escalation_queue = Path(os.environ.get("FLYWHEEL_PANE1_BRIDGE_ESCALATION_QUEUE", str(args.repo / ".flywheel/runtime/bridge-escalation-queue.jsonl")))
    if args.failure_flag is None:
        args.failure_flag = Path(os.environ.get("FLYWHEEL_PANE1_BRIDGE_FAILURE_FLAG", str(args.repo / ".flywheel/runtime/bridge-failure-pending.flag")))
    args.dispatch_log = args.dispatch_log.expanduser()
    args.ledger = args.ledger.expanduser()
    args.escalation_queue = args.escalation_queue.expanduser()
    args.failure_flag = args.failure_flag.expanduser()
    args.retry_delays = [float(item) for item in str(args.retry_delays).split(",") if item != ""]
    if not args.retry_delays:
        args.retry_delays = [0.0]

    if args.status_dashboard:
        pending = pending_failure_count(args.failure_flag)
        summary = {
            "schema_version": "pane1-bridge-dashboard/v1",
            "status": "warn" if pending else "pass",
            "bridge_failure_pending_count": pending,
            "bridge_failure_flag": str(args.failure_flag),
            "bridge_escalation_queue": str(args.escalation_queue),
            "bridge_ledger_age_hours": bridge_ledger_age_hours(args.ledger),
            "dashboard_line": f"Pane1 bridge failures pending: {pending}",
        }
        if args.json:
            print(json.dumps(summary, sort_keys=True))
        else:
            print(summary["dashboard_line"])
        return 0 if pending == 0 else 1

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
        "bridge_failure_pending_count": pending_failure_count(args.failure_flag),
        "bridge_failure_flag": str(args.failure_flag),
        "bridge_escalation_queue": str(args.escalation_queue),
        "dashboard_line": f"Pane1 bridge failures pending: {pending_failure_count(args.failure_flag)}",
        "last_sent": total_sent[-1] if total_sent else None,
        "failures": total_failed,
    }
    if args.json:
        print(json.dumps(summary, sort_keys=True))
    else:
        print(f"{summary['status']} sent={summary['sent']} failed={summary['failed']} bridge_failures_pending={summary['bridge_failure_pending_count']} ledger={summary['ledger']}")
    return 0 if not total_failed else 1


if __name__ == "__main__":
    raise SystemExit(main())
PY

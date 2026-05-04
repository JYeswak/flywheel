#!/usr/bin/env bash
set -euo pipefail

python3 - "$@" <<'PY'
import argparse
import fcntl
import json
import os
import sys
import time
from datetime import datetime, timedelta, timezone
from pathlib import Path

VERSION = "shared-surface-reservation/v1"
DEFAULT_LEDGER = Path.home() / ".local/state/flywheel/file-reservations.jsonl"
DEFAULT_FUCKUP_LOG = Path.home() / ".local/state/flywheel/fuckup-log.jsonl"


def iso_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def parse_ts(value):
    if not value:
        return None
    text = str(value)
    if text.endswith("Z"):
        text = text[:-1] + "+00:00"
    try:
        parsed = datetime.fromisoformat(text)
    except ValueError:
        return None
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=timezone.utc)
    return parsed.astimezone(timezone.utc)


def normalize_path(path: str, cwd: str | None = None) -> str:
    raw = Path(path).expanduser()
    if not raw.is_absolute():
        raw = Path(cwd or os.getcwd()) / raw
    return str(raw.resolve(strict=False))


def read_rows(path: Path):
    rows = []
    malformed = []
    if not path.exists():
        return rows, malformed
    with path.open(encoding="utf-8", errors="ignore") as handle:
        for line_no, line in enumerate(handle, 1):
            line = line.strip()
            if not line:
                continue
            try:
                row = json.loads(line)
            except Exception:
                malformed.append({"line": line_no, "raw": line[:160]})
                continue
            if not isinstance(row, dict):
                malformed.append({"line": line_no, "raw": line[:160]})
                continue
            row["__line"] = line_no
            rows.append(row)
    return rows, malformed


def current_holders(rows):
    state: dict[str, list[dict]] = {}
    for row in rows:
        action = row.get("action")
        path = row.get("path")
        pane = str(row.get("pane", ""))
        if not path or not pane:
            continue
        if action == "reserve":
            state.setdefault(path, [])
            if not any(str(item.get("pane")) == pane for item in state[path]):
                state[path].append(row)
        elif action == "release":
            state[path] = [item for item in state.get(path, []) if str(item.get("pane")) != pane]
    return {path: holders for path, holders in state.items() if holders}


def append_jsonl(path: Path, row: dict):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(row, sort_keys=True, separators=(",", ":")) + "\n")


def emit(payload: dict, json_mode: bool):
    if json_mode:
        print(json.dumps(payload, sort_keys=True))
    else:
        status = payload.get("status", "ok")
        detail = payload.get("detail") or payload.get("reason") or ""
        print(f"{status}{': ' + detail if detail else ''}")


def lock_ledger(ledger: Path):
    ledger.parent.mkdir(parents=True, exist_ok=True)
    lock_path = ledger.with_suffix(ledger.suffix + ".lock")
    lock_handle = lock_path.open("a+")
    fcntl.flock(lock_handle, fcntl.LOCK_EX)
    return lock_handle


def infer_pane(value):
    if value is not None:
        return str(value)
    for key in ("FLYWHEEL_PANE", "PANE", "NTM_PANE"):
        env = os.environ.get(key)
        if env:
            return str(env)
    return None


def log_collision(args, path, holders, checked_at):
    row = {
        "ts": checked_at,
        "session": args.session,
        "pane": args.pane,
        "agent": "shared-surface-reservation-check",
        "host": os.uname().nodename,
        "git_repo": str(Path.cwd()),
        "commit_sha": None,
        "trauma_class": "coordination-collision-detected",
        "severity": "medium",
        "what_happened": f"coordination-collision-detected: pane={args.pane} path={path}",
        "what_attempted": ["shared-surface-reservation-check --check"],
        "what_worked": [],
        "rule_violated_or_proven": "L107 shared-surface writes must reserve across panes",
        "evidence": [f"holder_panes={','.join(str(h.get('pane')) for h in holders)}", f"path={path}"],
        "should_become": "tool-patch",
        "processed_at": None,
        "processed_into": None,
    }
    append_jsonl(Path(args.fuckup_log), row)


def check_path(args, rows, malformed, checked_at):
    path = normalize_path(args.check, args.cwd)
    pane = infer_pane(args.pane)
    holders = current_holders(rows).get(path, [])
    blockers = [h for h in holders if pane is None or str(h.get("pane")) != str(pane)]
    payload = {
        "schema_version": VERSION,
        "status": "blocked" if blockers else "free",
        "path": path,
        "pane": pane,
        "holders": holders,
        "blocking_holders": blockers,
        "malformed_rows_count": len(malformed),
        "warnings": [{"code": "malformed_row_skipped", **m} for m in malformed[:5]],
    }
    if blockers:
        payload["detail"] = f"coordination-collision-detected: pane={blockers[0].get('pane')} path={path}"
        log_collision(args, path, blockers, checked_at)
        emit(payload, args.json)
        return 1
    emit(payload, args.json)
    return 0


def reserve_path(args, rows, malformed, checked_at):
    path = normalize_path(args.reserve, args.cwd)
    pane = infer_pane(args.pane)
    if pane is None:
        emit({"schema_version": VERSION, "status": "usage_error", "reason": "--pane is required for --reserve"}, args.json)
        return 2
    holders = current_holders(rows).get(path, [])
    blockers = [h for h in holders if str(h.get("pane")) != str(pane)]
    if blockers:
        log_collision(args, path, blockers, checked_at)
        emit({
            "schema_version": VERSION,
            "status": "blocked",
            "path": path,
            "pane": pane,
            "blocking_holders": blockers,
            "detail": f"coordination-collision-detected: pane={blockers[0].get('pane')} path={path}",
            "malformed_rows_count": len(malformed),
        }, args.json)
        return 1
    if not any(str(h.get("pane")) == str(pane) for h in holders):
        append_jsonl(Path(args.ledger), {
            "ts": checked_at,
            "session": args.session,
            "pane": pane,
            "task_id": args.task_id,
            "path": path,
            "action": "reserve",
        })
    emit({
        "schema_version": VERSION,
        "status": "reserved",
        "path": path,
        "pane": pane,
        "task_id": args.task_id,
        "malformed_rows_count": len(malformed),
    }, args.json)
    return 0


def release_path(args, rows, malformed, checked_at):
    path = normalize_path(args.release, args.cwd)
    pane = infer_pane(args.pane)
    if pane is None:
        emit({"schema_version": VERSION, "status": "usage_error", "reason": "--pane is required for --release"}, args.json)
        return 2
    append_jsonl(Path(args.ledger), {
        "ts": checked_at,
        "session": args.session,
        "pane": pane,
        "task_id": args.task_id,
        "path": path,
        "action": "release",
    })
    emit({
        "schema_version": VERSION,
        "status": "released",
        "path": path,
        "pane": pane,
        "malformed_rows_count": len(malformed),
    }, args.json)
    return 0


def list_current(args, rows, malformed):
    current = current_holders(rows)
    payload = {
        "schema_version": VERSION,
        "status": "ok",
        "ledger": args.ledger,
        "reservations": [{"path": path, "holders": holders} for path, holders in sorted(current.items())],
        "active_count": sum(len(v) for v in current.values()),
        "malformed_rows_count": len(malformed),
        "warnings": [{"code": "malformed_row_skipped", **m} for m in malformed[:5]],
    }
    emit(payload, args.json)
    return 0


def doctor(args, rows, malformed):
    since = datetime.now(timezone.utc) - timedelta(hours=24)
    collisions = 0
    fuckup_rows, fuckup_malformed = read_rows(Path(args.fuckup_log))
    for row in fuckup_rows:
        if row.get("trauma_class") != "coordination-collision-detected":
            continue
        ts = parse_ts(row.get("ts"))
        if ts and ts >= since:
            collisions += 1
    payload = {
        "schema_version": VERSION,
        "status": "pass" if collisions == 0 else "warn",
        "coordination_collision_count_24h": collisions,
        "active_reservation_count": sum(len(v) for v in current_holders(rows).values()),
        "malformed_rows_count": len(malformed),
        "fuckup_malformed_rows_count": len(fuckup_malformed),
        "ledger": args.ledger,
        "fuckup_log": args.fuckup_log,
    }
    emit(payload, args.json)
    return 0


def info(args):
    payload = {
        "schema_version": VERSION,
        "command": "shared-surface-reservation-check.sh",
        "purpose": "Block cross-pane git-add collisions on shared flywheel surfaces before staging.",
        "ledger": args.ledger,
        "fuckup_log": args.fuckup_log,
        "mutating_commands": ["--reserve", "--release"],
        "dry_run_default": False,
    }
    emit(payload, args.json)


def schema(args):
    payload = {
        "schema_version": VERSION,
        "ledger_row": {"ts": "ISO8601", "session": "string", "pane": "string", "task_id": "string", "path": "absolute path", "action": "reserve|release"},
        "commands": ["--check <path>", "--reserve <path> --pane=<N> --task-id=<id>", "--release <path> --pane=<N>", "--list", "--doctor"],
        "exit_codes": {"0": "free or mutation recorded", "1": "reserved by another pane", "2": "usage error"},
    }
    emit(payload, args.json)


def examples(args):
    lines = [
        "shared-surface-reservation-check.sh --reserve /Users/josh/.claude/skills/.flywheel/bin/flywheel-loop --pane=3 --task-id=shared-surface-reservation-patch",
        "shared-surface-reservation-check.sh --check /Users/josh/.claude/skills/.flywheel/bin/flywheel-loop --pane=3",
        "shared-surface-reservation-check.sh --release /Users/josh/.claude/skills/.flywheel/bin/flywheel-loop --pane=3",
        "shared-surface-reservation-check.sh --doctor --json",
    ]
    if args.json:
        print(json.dumps({"schema_version": VERSION, "examples": lines}, sort_keys=True))
    else:
        print("\n".join(lines))


def parse_args(argv):
    parser = argparse.ArgumentParser(description="Shared-surface reservation checker")
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--check")
    group.add_argument("--reserve")
    group.add_argument("--release")
    group.add_argument("--list", action="store_true")
    group.add_argument("--doctor", action="store_true")
    group.add_argument("--health", action="store_true")
    group.add_argument("--info", action="store_true")
    group.add_argument("--schema", action="store_true")
    group.add_argument("--examples", action="store_true")
    parser.add_argument("--pane")
    parser.add_argument("--session", default=os.environ.get("FLYWHEEL_SESSION", "flywheel"))
    parser.add_argument("--task-id", default=os.environ.get("FLYWHEEL_TASK_ID", "unknown"))
    parser.add_argument("--ledger", default=os.environ.get("FLYWHEEL_SHARED_SURFACE_RESERVATIONS", str(DEFAULT_LEDGER)))
    parser.add_argument("--fuckup-log", default=os.environ.get("FLYWHEEL_FUCKUP_LOG", str(DEFAULT_FUCKUP_LOG)))
    parser.add_argument("--cwd", default=os.getcwd())
    parser.add_argument("--json", action="store_true")
    return parser.parse_args(argv)


def main(argv):
    args = parse_args(argv)
    if args.info:
        info(args)
        return 0
    if args.schema:
        schema(args)
        return 0
    if args.examples:
        examples(args)
        return 0

    ledger = Path(args.ledger)
    checked_at = iso_now()
    with lock_ledger(ledger):
        rows, malformed = read_rows(ledger)
        if args.check:
            return check_path(args, rows, malformed, checked_at)
        if args.reserve:
            return reserve_path(args, rows, malformed, checked_at)
        if args.release:
            return release_path(args, rows, malformed, checked_at)
        if args.list:
            return list_current(args, rows, malformed)
        if args.doctor or args.health:
            return doctor(args, rows, malformed)
    emit({"schema_version": VERSION, "status": "usage_error", "reason": "choose one command"}, args.json)
    return 2


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
PY

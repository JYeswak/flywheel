#!/usr/bin/env bash
set -euo pipefail

python3 - "$@" <<'PY'
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from collections import Counter
from datetime import datetime, timedelta, timezone
from pathlib import Path

SCHEMA_VERSION = "bleed-ledger-watch/v1"
DEFAULT_LEDGER = Path.home() / ".local/state/flywheel/coordinator-cross-repo-bleed.jsonl"


def parse_ts(value: object) -> datetime | None:
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


def now_utc(value: str | None) -> datetime:
    return parse_ts(value) or datetime.now(timezone.utc)


def iso(value: datetime) -> str:
    return value.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")


def read_ledger(path: Path) -> tuple[list[dict], list[dict]]:
    rows: list[dict] = []
    warnings: list[dict] = []
    if not path.exists():
        return rows, [{"code": "ledger_missing", "path": str(path)}]
    for line_no, line in enumerate(path.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except json.JSONDecodeError as exc:
            warnings.append({"code": "malformed_row", "line": line_no, "message": str(exc)})
            continue
        if not isinstance(row, dict):
            warnings.append({"code": "non_object_row", "line": line_no})
            continue
        row["__line"] = line_no
        rows.append(row)
    return rows, warnings


def top(counter: Counter[str]) -> dict | None:
    if not counter:
        return None
    key, count = sorted(counter.items(), key=lambda item: (-item[1], item[0]))[0]
    return {"value": key, "count": count}


def doctor(args: argparse.Namespace) -> dict:
    ledger = Path(args.ledger).expanduser()
    checked_at = now_utc(args.now)
    cutoff = checked_at - timedelta(hours=24)
    rows, warnings = read_ledger(ledger)
    recent: list[dict] = []
    old_or_undated = 0
    for row in rows:
        ts = parse_ts(row.get("ts") or row.get("timestamp") or row.get("checked_at"))
        if ts is None:
            old_or_undated += 1
            continue
        if ts >= cutoff:
            recent.append(row)
    sessions = Counter(str(row.get("session") or "unknown") for row in recent)
    repos = Counter(str(row.get("repo_path") or row.get("repo") or "unknown") for row in recent)
    event_count = len(recent)
    status = "pass"
    if event_count:
        status = "fail"
    elif any(item.get("code") not in {"ledger_missing"} for item in warnings):
        status = "warn"
    return {
        "schema_version": SCHEMA_VERSION,
        "command": "doctor",
        "status": status,
        "checked_at": iso(checked_at),
        "ledger_path": str(ledger),
        "ledger_exists": ledger.exists(),
        "rows_observed": len(rows),
        "rows_older_or_undated": old_or_undated,
        "bleed_event_count_24h": event_count,
        "bleed_session_top": top(sessions),
        "bleed_repo_top": top(repos),
        "bleed_warnings": warnings,
        "consumer": "flywheel tick Step 4y",
        "fix_bead_required": event_count > 0,
    }


def create_fix_bead(args: argparse.Namespace, payload: dict) -> dict:
    if not payload["fix_bead_required"]:
        return {"action": "noop", "reason": "no_bleed_events"}
    repo = Path(args.repo).expanduser().resolve()
    title = "[auto-doctor:coordinator-cross-repo-bleed] investigate pinned coordinator bleed"
    description = f"""## Goal
Investigate and eliminate coordinator cross-repo bleed events.

## Context
`bleed-ledger-watch.sh` found {payload["bleed_event_count_24h"]} bleed event(s) in the last 24h.

## Evidence
- ledger: `{payload["ledger_path"]}`
- top session: `{payload["bleed_session_top"]}`
- top repo: `{payload["bleed_repo_top"]}`

## Acceptance Criteria
- Reproduce or explain the ledger rows.
- Patch the pinned coordinator or topology substrate so new bleed rows stop.
- Run `.flywheel/scripts/bleed-ledger-watch.sh --doctor --json` and confirm `bleed_event_count_24h == 0` after the fix window.
"""
    existing = subprocess.run(
        ["br", "list", "--json"],
        cwd=repo,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if existing.returncode == 0:
        try:
            issues = json.loads(existing.stdout).get("issues", [])
        except Exception:
            issues = []
        for issue in issues:
            if issue.get("title") == title and issue.get("status") not in {"closed", "done"}:
                return {"action": "existing", "bead_id": issue.get("id"), "title": title}
    if not args.apply:
        return {"action": "would_create", "title": title, "mode": "dry_run"}
    proc = subprocess.run(
        ["br", "create", title, "-t", "bug", "-p", "1", "-d", description],
        cwd=repo,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if proc.returncode != 0:
        return {"action": "failed", "exit_code": proc.returncode, "stderr": proc.stderr.strip()[:2000]}
    return {"action": "created", "title": title, "stdout": proc.stdout.strip()[:2000]}


def emit(payload: dict, json_mode: bool) -> None:
    if json_mode:
        print(json.dumps(payload, sort_keys=True, separators=(",", ":")))
    else:
        print(f"status={payload.get('status')} bleed_event_count_24h={payload.get('bleed_event_count_24h', 0)}")


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Watch the coordinator cross-repo bleed ledger.")
    parser.add_argument("command", nargs="?", default="doctor", choices=["doctor", "health", "repair", "validate", "schema", "info", "examples"])
    parser.add_argument("--doctor", action="store_true")
    parser.add_argument("--health", action="store_true")
    parser.add_argument("--repair", action="store_true")
    parser.add_argument("--validate", action="store_true")
    parser.add_argument("--schema", action="store_true")
    parser.add_argument("--info", action="store_true")
    parser.add_argument("--examples", action="store_true")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--ledger", default=os.environ.get("FLYWHEEL_BLEED_LEDGER", str(DEFAULT_LEDGER)))
    parser.add_argument("--repo", default=os.getcwd())
    parser.add_argument("--now")
    parser.add_argument("--dry-run", action="store_true", default=True)
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args(argv)
    if args.apply:
        args.dry_run = False
    command = args.command
    for flag, name in ((args.doctor, "doctor"), (args.health, "health"), (args.repair, "repair"), (args.validate, "validate"), (args.schema, "schema"), (args.info, "info"), (args.examples, "examples")):
        if flag:
            command = name
    if command == "schema":
        emit({"schema_version": SCHEMA_VERSION, "fields": ["bleed_event_count_24h", "bleed_session_top", "bleed_repo_top", "bleed_warnings"], "exit_codes": {"0": "pass or warn", "1": "bleed rows observed", "2": "usage"}}, args.json)
        return 0
    if command == "info":
        emit({"schema_version": SCHEMA_VERSION, "name": "bleed-ledger-watch.sh", "ledger_path": args.ledger, "commands": ["doctor", "health", "repair", "validate", "schema", "info", "examples"], "mutation": "repair --apply creates one fix bead when bleed rows exist"}, args.json)
        return 0
    if command == "examples":
        payload = {"schema_version": SCHEMA_VERSION, "examples": ["bleed-ledger-watch.sh --doctor --json", "bleed-ledger-watch.sh --doctor --json --ledger /tmp/ledger.jsonl", "bleed-ledger-watch.sh repair --apply --json"]}
        emit(payload, args.json)
        return 0
    payload = doctor(args)
    if command == "health":
        payload["command"] = "health"
    if command == "repair":
        payload["command"] = "repair"
    if command == "validate":
        payload["command"] = "validate"
        payload["valid"] = payload["status"] in {"pass", "warn", "fail"}
    payload["fix_bead_action"] = create_fix_bead(args, payload)
    emit(payload, args.json)
    return 1 if payload["bleed_event_count_24h"] else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
PY

#!/usr/bin/env bash
set -euo pipefail

VERSION="capacity-halt-pane-authorization.v1.0.0"
TOPOLOGY="${CAPACITY_HALT_AUTH_TOPOLOGY:-$HOME/.local/state/flywheel/session-topology.jsonl}"
NOW_EPOCH="${CAPACITY_HALT_AUTH_NOW_EPOCH:-}"
MAX_AGE_SECONDS="${CAPACITY_HALT_AUTH_MAX_AGE_SECONDS:-3600}"

python3 - "$VERSION" "$TOPOLOGY" "$NOW_EPOCH" "$MAX_AGE_SECONDS" "$@" <<'PY'
import argparse, json, os, re, sys, time
from datetime import datetime, timezone
from pathlib import Path

VERSION, TOPOLOGY, NOW_RAW, MAX_AGE_RAW = sys.argv[1:5]
PANE_RE = re.compile(r"^[0-9]+$")

def parse_args():
    p = argparse.ArgumentParser(description="Authorize capacity-halt auto-continue for worker panes only.")
    p.add_argument("--info", action="store_true")
    p.add_argument("--examples", action="store_true")
    p.add_argument("--json", action="store_true")
    p.add_argument("--session", default="")
    p.add_argument("--pane", default="")
    p.add_argument("--quiet", action="store_true")
    return p.parse_args(sys.argv[5:])

def now_epoch():
    return int(NOW_RAW or time.time())

def parse_ts(value):
    if not value:
        return None
    try:
        return datetime.fromisoformat(str(value).replace("Z", "+00:00")).timestamp()
    except ValueError:
        return None

def emit(args, payload, rc):
    if args.json:
        print(json.dumps(payload, sort_keys=True))
    elif not args.quiet:
        print(f"capacity-halt-pane-authorization status={payload.get('status')} session={payload.get('session', '')} pane={payload.get('pane', '')} role={payload.get('role', '')}")
    raise SystemExit(rc)

def read_rows(path):
    rows = []
    for idx, line in enumerate(Path(path).read_text().splitlines(), start=1):
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except json.JSONDecodeError as exc:
            raise ValueError(f"malformed_jsonl_line_{idx}:{exc}") from exc
        if isinstance(row, dict):
            rows.append(row)
    return rows

def latest_for_session(rows, session):
    candidates = [r for r in rows if str(r.get("session")) == session]
    if not candidates:
        return None
    return max(candidates, key=lambda r: str(r.get("effective_at") or r.get("ts") or ""))

def role_for_pane(row, pane):
    if str(row.get("orchestrator_pane")) == pane:
        return "orchestrator_pane"
    if str(row.get("human_pane")) == pane:
        return "human_pane"
    if str(row.get("callback_pane")) == pane:
        return "callback_pane"
    if pane in {str(p) for p in (row.get("worker_panes") or [])}:
        return "worker_pane"
    return "unknown"

def base(args, row=None, age=None):
    source_ts = (row or {}).get("effective_at") or (row or {}).get("ts")
    return {
        "schema_version": "capacity-halt-pane-authorization.result.v1",
        "version": VERSION,
        "session": args.session,
        "pane": args.pane,
        "topology_file": TOPOLOGY,
        "topology_source_ts": source_ts,
        "topology_age_sec": age,
        "read_only": True,
    }

def with_ledger(payload):
    payload["ledger_row"] = {
        "event": "capacity_halt_authorization",
        "session": payload.get("session"),
        "pane": int(payload["pane"]) if str(payload.get("pane", "")).isdigit() else payload.get("pane"),
        "authorized": payload.get("authorized"),
        "pane_role": payload.get("role"),
        "authorization_outcome": payload.get("authorization_outcome"),
        "topology_source_ts": payload.get("topology_source_ts"),
        "refusal_reason": payload.get("refusal_reason"),
    }
    return payload

def info(args):
    emit(args, {
        "schema_version": "capacity-halt-pane-authorization.info.v1",
        "name": "capacity-halt-pane-authorization",
        "version": VERSION,
        "topology_file": TOPOLOGY,
        "max_age_seconds": int(MAX_AGE_RAW),
        "verbs": ["--info", "--help", "--examples", "--json", "--session", "--pane", "--quiet"],
        "exit_codes": {"0": "authorized-worker-pane", "3": "malformed", "5": "protected-refusal", "6": "unknown-pane", "7": "topology-stale"},
    }, 0)

def examples(args):
    emit(args, {
        "schema_version": "capacity-halt-pane-authorization.examples.v1",
        "examples": [
            {"name": "worker", "command": "capacity-halt-pane-authorization.sh --session flywheel --pane 3 --json"},
            {"name": "quiet", "command": "capacity-halt-pane-authorization.sh --session flywheel --pane 1 --quiet"},
        ],
    }, 0)

def main():
    args = parse_args()
    if args.info:
        info(args)
    if args.examples:
        examples(args)
    if not args.session or not PANE_RE.match(args.pane):
        emit(args, dict(base(args), status="malformed", role="unknown", authorized=False, authorization_outcome="malformed", refusal_reason="session_and_numeric_pane_required"), 3)
    try:
        rows = read_rows(TOPOLOGY)
    except (OSError, ValueError) as exc:
        emit(args, dict(base(args), status="malformed", role="unknown", authorized=False, authorization_outcome="malformed", refusal_reason=str(exc)), 3)
    row = latest_for_session(rows, args.session)
    if row is None:
        emit(args, with_ledger(dict(base(args), status="unknown_pane", role="unknown", authorized=False, authorization_outcome="unknown_pane", refusal_reason="unknown_pane")), 6)
    source_ts = row.get("effective_at") or row.get("ts")
    source_epoch = parse_ts(source_ts)
    if source_epoch is None:
        emit(args, with_ledger(dict(base(args, row), status="malformed", role="unknown", authorized=False, authorization_outcome="malformed", refusal_reason="missing_or_invalid_effective_at")), 3)
    age = max(0, now_epoch() - int(source_epoch))
    if age > int(MAX_AGE_RAW):
        emit(args, with_ledger(dict(base(args, row, age), status="topology_stale", role="unknown", authorized=False, authorization_outcome="topology_stale", refusal_reason="topology_stale")), 7)
    role = role_for_pane(row, args.pane)
    if role == "worker_pane":
        emit(args, with_ledger(dict(base(args, row, age), status="authorized", role=role, authorized=True, authorization_outcome="authorized", refusal_reason=None)), 0)
    if role == "unknown":
        emit(args, with_ledger(dict(base(args, row, age), status="unknown_pane", role=role, authorized=False, authorization_outcome="unknown_pane", refusal_reason="unknown_pane")), 6)
    emit(args, with_ledger(dict(base(args, row, age), status="protected_refusal", role=role, authorized=False, authorization_outcome="protected_refusal", refusal_reason="protected")), 5)

if __name__ == "__main__":
    main()
PY

#!/usr/bin/env bash
set -euo pipefail

VERSION="capacity-halt-lease-primitive.v1.0.0"
LEDGER="${CAPACITY_HALT_LEASE_LEDGER:-$HOME/.local/state/flywheel/capacity-halt-lease.jsonl}"
NOW_EPOCH="${CAPACITY_HALT_LEASE_NOW_EPOCH:-}"

python3 - "$VERSION" "$LEDGER" "$NOW_EPOCH" "$@" <<'PY'
import argparse, hashlib, json, re, sys, time
from datetime import datetime, timezone
from pathlib import Path

VERSION, LEDGER_RAW, NOW_RAW = sys.argv[1:4]
SHA_RE = re.compile(r"^[0-9a-f]{64}$")

def now_epoch():
    return int(NOW_RAW or time.time())

def iso(epoch):
    return datetime.fromtimestamp(int(epoch), timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

def digest_from_file(path):
    lines = Path(path).read_text(errors="replace").splitlines()[-30:]
    return hashlib.sha256("\n".join(lines).encode()).hexdigest()

def rows(path):
    out = []
    try:
        for line in path.read_text().splitlines():
            if not line.strip():
                continue
            try:
                row = json.loads(line)
            except json.JSONDecodeError:
                continue
            if isinstance(row, dict):
                out.append(row)
    except FileNotFoundError:
        pass
    return out

def emit(args, payload, rc):
    if args.json:
        print(json.dumps(payload, sort_keys=True))
    else:
        print(f"capacity-halt-lease status={payload.get('status')} session={payload.get('session', '')} pane={payload.get('pane', '')}")
    raise SystemExit(rc)

def active_lease(all_rows, session, pane, digest, now):
    active = None
    for row in all_rows:
        if row.get("session") != session or str(row.get("pane")) != str(pane) or row.get("digest") != digest:
            continue
        if row.get("event") == "acquire" and int(row.get("expires_epoch") or 0) > now:
            active = row
        elif row.get("event") == "release" and active and int(row.get("epoch") or 0) >= int(active.get("epoch") or 0):
            active = None
    return active

def append_row(path, row):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(row, sort_keys=True) + "\n")

def examples(args):
    data = [
        {"name": "acquire", "command": "capacity-halt-lease-primitive.sh --acquire --session flywheel --pane 3 --digest <sha256> --ttl 90 --json"},
        {"name": "release", "command": "capacity-halt-lease-primitive.sh --release --session flywheel --pane 3 --digest <sha256> --result success --json"},
        {"name": "list", "command": "capacity-halt-lease-primitive.sh --list --json"},
    ]
    emit(args, {"schema_version": "capacity-halt-lease.examples.v1", "examples": data}, 0)

def main():
    p = argparse.ArgumentParser(description="Per-pane/digest capacity-halt idempotency lease.")
    mode = p.add_mutually_exclusive_group()
    mode.add_argument("--info", action="store_true")
    mode.add_argument("--examples", action="store_true")
    mode.add_argument("--list", action="store_true")
    mode.add_argument("--acquire", action="store_true")
    mode.add_argument("--release", action="store_true")
    p.add_argument("--json", action="store_true")
    p.add_argument("--ledger", default=LEDGER_RAW)
    p.add_argument("--session", default="")
    p.add_argument("--pane", default="")
    p.add_argument("--digest", default="")
    p.add_argument("--scrollback-file", default="")
    p.add_argument("--ttl", type=int, default=90)
    p.add_argument("--result", choices=["success", "failure", "skipped"], default="success")
    args = p.parse_args(sys.argv[4:])
    ledger = Path(args.ledger).expanduser()
    now = now_epoch()
    if args.examples:
        examples(args)
    if args.info:
        emit(args, {"schema_version": "capacity-halt-lease.info.v1", "name": "capacity-halt-lease-primitive", "version": VERSION, "ledger": str(ledger), "default_ttl_seconds": 90, "exit_codes": {"0": "acquired-or-query-ok", "1": "already-held", "2": "malformed", "3": "read-error"}, "verbs": ["--info", "--help", "--examples", "--json", "--acquire", "--release", "--list"]}, 0)
    if args.list:
        current = [r for r in rows(ledger) if r.get("event") == "acquire" and active_lease(rows(ledger), r.get("session"), str(r.get("pane")), r.get("digest"), now) == r]
        emit(args, {"schema_version": "capacity-halt-lease.list.v1", "status": "ok", "ledger": str(ledger), "active_count": len(current), "leases": current}, 0)
    try:
        digest = args.digest or (digest_from_file(args.scrollback_file) if args.scrollback_file else "")
    except OSError as exc:
        emit(args, {"schema_version": "capacity-halt-lease.result.v1", "status": "read_error", "ledger_written": False, "reason": str(exc)}, 3)
    if not args.session or not args.pane or not SHA_RE.match(digest) or args.ttl <= 0:
        emit(args, {"schema_version": "capacity-halt-lease.result.v1", "status": "malformed", "ledger_written": False, "reason": "session_pane_digest_ttl_required"}, 2)
    if args.acquire:
        all_rows = rows(ledger)
        active = active_lease(all_rows, args.session, args.pane, digest, now)
        if active:
            emit(args, {"schema_version": "capacity-halt-lease.result.v1", "status": "already_held", "session": args.session, "pane": args.pane, "digest": digest, "ledger_written": False, "active_until": active.get("expires_ts")}, 1)
        row = {"schema_version": "capacity-halt-lease.row.v1", "event": "acquire", "ts": iso(now), "epoch": now, "session": args.session, "pane": int(args.pane) if args.pane.isdigit() else args.pane, "digest": digest, "ttl_seconds": args.ttl, "expires_epoch": now + args.ttl, "expires_ts": iso(now + args.ttl), "source": "capacity-halt-lease-primitive"}
        append_row(ledger, row)
        emit(args, {"schema_version": "capacity-halt-lease.result.v1", "status": "acquired", "session": args.session, "pane": args.pane, "digest": digest, "ledger_written": True, "expires_ts": row["expires_ts"]}, 0)
    if args.release:
        row = {"schema_version": "capacity-halt-lease.row.v1", "event": "release", "ts": iso(now), "epoch": now, "session": args.session, "pane": int(args.pane) if args.pane.isdigit() else args.pane, "digest": digest, "result": args.result, "source": "capacity-halt-lease-primitive"}
        append_row(ledger, row)
        emit(args, {"schema_version": "capacity-halt-lease.result.v1", "status": "released", "session": args.session, "pane": args.pane, "digest": digest, "result": args.result, "ledger_written": True}, 0)
    p.print_help()

if __name__ == "__main__":
    main()
PY

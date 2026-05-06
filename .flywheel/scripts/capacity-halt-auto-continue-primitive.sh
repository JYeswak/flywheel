#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
VERSION="capacity-halt-auto-continue-primitive.v1.0.0"
LEASE_BIN="${CAPACITY_HALT_AUTO_CONTINUE_LEASE:-$SCRIPT_DIR/capacity-halt-lease-primitive.sh}"
NTM_BIN="${CAPACITY_HALT_AUTO_CONTINUE_NTM_BIN:-/Users/josh/.local/bin/ntm}"
SUCCESS_BIN="${CAPACITY_HALT_AUTO_CONTINUE_SUCCESS_MEASUREMENT:-$SCRIPT_DIR/capacity-halt-success-measurement.sh}"
AUTH_BIN="${CAPACITY_HALT_AUTO_CONTINUE_AUTHORIZATION:-$SCRIPT_DIR/capacity-halt-pane-authorization.sh}"
BUDGET_BIN="${CAPACITY_HALT_AUTO_CONTINUE_BUDGET:-$SCRIPT_DIR/capacity-halt-burst-budget.sh}"
NOTIFY_BIN="${CAPACITY_HALT_AUTO_CONTINUE_NOTIFY_BIN:-/Users/josh/.local/bin/notify}"; FALLBACK_LEDGER="${CAPACITY_HALT_AUTO_CONTINUE_FALLBACK_LEDGER:-$HOME/.local/state/flywheel/capacity-halt-budget-fallback.jsonl}"
TIMEOUT_SECONDS="${CAPACITY_HALT_AUTO_CONTINUE_TIMEOUT_SECONDS:-8}"
MEASUREMENT_DELAYS="${CAPACITY_HALT_AUTO_CONTINUE_SUCCESS_DELAYS:-3,6,10}"

python3 - "$VERSION" "$LEASE_BIN" "$NTM_BIN" "$SUCCESS_BIN" "$AUTH_BIN" "$BUDGET_BIN" "$NOTIFY_BIN" "$FALLBACK_LEDGER" "$TIMEOUT_SECONDS" "$MEASUREMENT_DELAYS" "$@" <<'PY'
import argparse, hashlib, json, os, re, subprocess, sys
from pathlib import Path

VERSION, LEASE_BIN, NTM_BIN, SUCCESS_BIN, AUTH_BIN, BUDGET_BIN, NOTIFY_BIN, FALLBACK_LEDGER, TIMEOUT_RAW, MEASUREMENT_DELAYS = sys.argv[1:11]
SHA_RE = re.compile(r"^[0-9a-f]{64}$")
PANE_RE = re.compile(r"^[0-9]+$")

def parse_args():
    p = argparse.ArgumentParser(description="Bounded capacity-halt auto-continue primitive.")
    p.add_argument("--info", action="store_true")
    p.add_argument("--examples", action="store_true")
    p.add_argument("--json", action="store_true")
    p.add_argument("--session", default="")
    p.add_argument("--pane", default="")
    p.add_argument("--digest", default="")
    p.add_argument("--scrollback-file", default="")
    p.add_argument("--ttl", type=int, default=90)
    p.add_argument("--timeout-seconds", type=int, default=int(TIMEOUT_RAW))
    p.add_argument("--lease-bin", default=LEASE_BIN)
    p.add_argument("--ntm-bin", default=NTM_BIN)
    p.add_argument("--success-bin", default=SUCCESS_BIN)
    p.add_argument("--auth-bin", default=AUTH_BIN)
    p.add_argument("--budget-bin", default=BUDGET_BIN); p.add_argument("--notify-bin", default=NOTIFY_BIN)
    p.add_argument("--fallback-ledger", default=FALLBACK_LEDGER)
    p.add_argument("--measurement-delays", default=MEASUREMENT_DELAYS)
    mode = p.add_mutually_exclusive_group()
    mode.add_argument("--dry-run", action="store_true")
    mode.add_argument("--apply", action="store_true")
    return p.parse_args(sys.argv[11:])

def emit(args, payload, rc):
    if args.json:
        print(json.dumps(payload, sort_keys=True))
    else:
        print(f"capacity-halt-auto-continue status={payload.get('status')} session={payload.get('session', '')} pane={payload.get('pane', '')}")
    raise SystemExit(rc)

def digest_from_file(path):
    lines = Path(path).read_text(errors="replace").splitlines()[-30:]
    return hashlib.sha256("\n".join(lines).encode()).hexdigest()

def resolve_digest(args):
    if args.digest:
        return args.digest
    if args.scrollback_file:
        return digest_from_file(args.scrollback_file)
    return ""

def lease_call(args, mode, digest, result="success"):
    cmd = [args.lease_bin, f"--{mode}", "--session", args.session, "--pane", args.pane, "--digest", digest, "--json"]
    if mode == "acquire":
        cmd.extend(["--ttl", str(args.ttl)])
    if mode == "release":
        cmd.extend(["--result", result])
    proc = subprocess.run(cmd, text=True, capture_output=True)
    try:
        payload = json.loads(proc.stdout)
    except json.JSONDecodeError:
        payload = {"status": "non_json", "stdout": proc.stdout[-500:], "stderr": proc.stderr[-500:]}
    return {"rc": proc.returncode, "payload": payload}

def lease_release(args, digest, result):
    release = lease_call(args, "release", digest, result)
    if result == "timeout" and release["rc"] != 0:
        fallback = lease_call(args, "release", digest, "failure")
        return {"requested_result": "timeout", "primary": release, "fallback": fallback}
    return {"requested_result": result, "primary": release}

def tail_text(value):
    if value is None:
        return ""
    if isinstance(value, bytes):
        return value.decode(errors="replace")[-500:]
    return str(value)[-500:]

def send_continue(args):
    return subprocess.run(
        [args.ntm_bin, "send", args.session, f"--pane={args.pane}", "--no-cass-check", "continue"],
        input="y\n",
        text=True,
        capture_output=True,
        timeout=args.timeout_seconds,
    )

def authorize(args):
    proc = subprocess.run([args.auth_bin, "--session", args.session, "--pane", args.pane, "--json"], text=True, capture_output=True)
    try:
        payload = json.loads(proc.stdout)
    except json.JSONDecodeError:
        payload = {"status": "non_json", "role": "unknown", "stdout": tail_text(proc.stdout), "stderr": tail_text(proc.stderr)}
    return {"rc": proc.returncode, "payload": payload}

def authorization_fields(auth):
    payload = auth.get("payload") or {}
    return {
        "authorization": auth,
        "pane_role": payload.get("role") or "unknown",
        "authorization_outcome": payload.get("authorization_outcome") or payload.get("status"),
        "topology_source_ts": payload.get("topology_source_ts"),
        "topology_age_sec": payload.get("topology_age_sec"),
    }

def budget_check(args):
    proc = subprocess.run([args.budget_bin, "--session", args.session, "--pane", args.pane, "--json"], text=True, capture_output=True)
    try: payload = json.loads(proc.stdout)
    except json.JSONDecodeError: payload = {"status": "non_json", "budget_outcome": "ledger_read_error", "stdout": tail_text(proc.stdout), "stderr": tail_text(proc.stderr)}
    return {"rc": proc.returncode, "payload": payload}

def budget_fields(budget):
    payload = budget.get("payload") or {}
    return {"budget": {**payload, "rc": budget.get("rc"), "payload": payload}, "per_pane_count_window": payload.get("per_pane_count_window"), "fleet_count_window": payload.get("fleet_count_window"), "budget_outcome": payload.get("budget_outcome") or payload.get("status")}

def fallback_signal(args, digest, budget, authz):
    payload = budget.get("payload") or {}
    row = {"ts": payload.get("checked_at"), "class": "capacity-halt-budget-exhausted", "session": args.session, "pane": int(args.pane), "digest": digest, "budget_rc": budget["rc"], "budget_outcome": payload.get("budget_outcome") or payload.get("status"), "per_pane_count_window": payload.get("per_pane_count_window"), "fleet_count_window": payload.get("fleet_count_window"), "pane_role": authz.get("pane_role")}
    path = Path(args.fallback_ledger); path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as handle: handle.write(json.dumps(row, sort_keys=True) + "\n")
    notify = subprocess.run([args.notify_bin, "Capacity halt budget exhausted", f"{args.session}:{args.pane} {row['budget_outcome']}"], text=True, capture_output=True)
    return {"ledger": str(path), "row": row, "notify": {"rc": notify.returncode, "stdout": tail_text(notify.stdout), "stderr": tail_text(notify.stderr)}}

def measure_success(args, digest):
    env = os.environ.copy()
    env["CAPACITY_HALT_SUCCESS_NTM_BIN"] = args.ntm_bin
    proc = subprocess.run(
        [args.success_bin, "--session", args.session, "--pane", args.pane, "--pre-digest", digest, "--sample-delays", args.measurement_delays, "--json"],
        text=True,
        capture_output=True,
        env=env,
    )
    try:
        payload = json.loads(proc.stdout)
    except json.JSONDecodeError:
        payload = {"status": "inconclusive", "verdict": "inconclusive", "stdout": tail_text(proc.stdout), "stderr": tail_text(proc.stderr)}
    return {"rc": proc.returncode, "payload": payload}

def info(args):
    emit(args, {
        "schema_version": "capacity-halt-auto-continue.info.v1",
        "name": "capacity-halt-auto-continue-primitive",
        "version": VERSION,
        "lease_bin": args.lease_bin,
        "ntm_bin": args.ntm_bin,
        "success_bin": args.success_bin,
        "auth_bin": args.auth_bin,
        "budget_bin": args.budget_bin,
        "notify_bin": args.notify_bin,
        "fallback_ledger": args.fallback_ledger,
        "default_timeout_seconds": int(TIMEOUT_RAW),
        "verbs": ["--info", "--help", "--examples", "--json", "--session", "--pane", "--dry-run", "--apply"],
        "exit_codes": {"0": "fired-success-or-dry-run-ok", "1": "fired-but-failed-recovery", "2": "lease-held-skipped", "3": "malformed", "4": "transport-timeout", "5": "protected-refusal", "6": "unknown-pane", "7": "topology-stale", "8": "budget-exhausted"},
    }, 0)

def examples(args):
    emit(args, {
        "schema_version": "capacity-halt-auto-continue.examples.v1",
        "examples": [
            {"name": "dry_run", "command": "capacity-halt-auto-continue-primitive.sh --session flywheel --pane 3 --digest <sha256> --dry-run --json"},
            {"name": "apply", "command": "capacity-halt-auto-continue-primitive.sh --session flywheel --pane 3 --digest <sha256> --apply --json"},
            {"name": "scrollback_file", "command": "capacity-halt-auto-continue-primitive.sh --session flywheel --pane 3 --scrollback-file /tmp/pane.txt --apply --json"},
        ],
    }, 0)

def main():
    args = parse_args()
    if args.info:
        info(args)
    if args.examples:
        examples(args)
    dry_run = not args.apply
    if not args.session or not PANE_RE.match(args.pane) or args.ttl <= 0 or args.timeout_seconds <= 0:
        emit(args, {"schema_version": "capacity-halt-auto-continue.result.v1", "status": "malformed", "session": args.session, "pane": args.pane, "reason": "session_numeric_pane_ttl_timeout_required", "fired": False}, 3)
    try:
        digest = resolve_digest(args)
    except OSError as exc:
        emit(args, {"schema_version": "capacity-halt-auto-continue.result.v1", "status": "malformed", "session": args.session, "pane": args.pane, "reason": str(exc), "fired": False}, 3)
    if dry_run:
        emit(args, {"schema_version": "capacity-halt-auto-continue.result.v1", "status": "dry_run", "session": args.session, "pane": args.pane, "would_send": True, "dry_run": True, "apply": False, "lease_required_for_apply": True, "transport_timeout_seconds": args.timeout_seconds}, 0)
    if not SHA_RE.match(digest):
        emit(args, {"schema_version": "capacity-halt-auto-continue.result.v1", "status": "malformed", "session": args.session, "pane": args.pane, "reason": "digest_or_scrollback_file_required_for_apply", "fired": False}, 3)
    auth = authorize(args)
    authz = authorization_fields(auth)
    if auth["rc"] != 0:
        emit(args, {"schema_version": "capacity-halt-auto-continue.result.v1", "status": authz.get("authorization_outcome") or "authorization_refused", "session": args.session, "pane": args.pane, "digest": digest, "dry_run": False, "apply": True, "fired": False, "attempted": False, "sent": False, "recovered": False, "reason": (auth.get("payload") or {}).get("refusal_reason"), **authz}, auth["rc"])
    budget = budget_check(args)
    budgetz = budget_fields(budget)
    if budget["rc"] != 0:
        signal = fallback_signal(args, digest, budget, authz)
        emit(args, {"schema_version": "capacity-halt-auto-continue.result.v1", "status": "budget_exhausted", "session": args.session, "pane": args.pane, "digest": digest, "dry_run": False, "apply": True, "fired": False, "attempted": False, "sent": False, "recovered": False, "reason": budgetz.get("budget_outcome"), "fallback_signal": signal, **authz, **budgetz}, 8)
    lease = lease_call(args, "acquire", digest)
    if lease["rc"] == 1:
        emit(args, {"schema_version": "capacity-halt-auto-continue.result.v1", "status": "lease_held_skipped", "session": args.session, "pane": args.pane, "digest": digest, "dry_run": False, "apply": True, "fired": False, "lease": lease, **authz, **budgetz}, 2)
    if lease["rc"] != 0:
        emit(args, {"schema_version": "capacity-halt-auto-continue.result.v1", "status": "malformed", "session": args.session, "pane": args.pane, "digest": digest, "reason": "lease_acquire_failed", "fired": False, "lease": lease, **authz, **budgetz}, 3)
    try:
        proc = send_continue(args)
    except subprocess.TimeoutExpired as exc:
        release = lease_release(args, digest, "timeout")
        emit(args, {"schema_version": "capacity-halt-auto-continue.result.v1", "status": "transport_timeout", "session": args.session, "pane": args.pane, "digest": digest, "dry_run": False, "apply": True, "fired": False, "attempted": True, "sent": True, "recovered": False, "transport_timeout_seconds": args.timeout_seconds, "stdout": tail_text(exc.stdout), "stderr": tail_text(exc.stderr), "lease": lease, "release": release, **authz, **budgetz}, 4)
    result = "success" if proc.returncode == 0 else "failure"
    measurement = None
    recovered = False
    if proc.returncode == 0:
        measurement = measure_success(args, digest)
        recovered = measurement["rc"] == 0 and measurement["payload"].get("verdict") == "success"
    release = lease_release(args, digest, "success" if recovered else "failure")
    status = "fired_success" if recovered else "fired_failed"
    emit(args, {"schema_version": "capacity-halt-auto-continue.result.v1", "status": status, "session": args.session, "pane": args.pane, "digest": digest, "dry_run": False, "apply": True, "fired": True, "attempted": True, "sent": proc.returncode == 0, "recovered": recovered, "transport_rc": proc.returncode, "transport_timeout_seconds": args.timeout_seconds, "stdout": tail_text(proc.stdout), "stderr": tail_text(proc.stderr), "lease": lease, "release": release, "success_measurement": measurement, **authz, **budgetz}, 0 if recovered else 1)

if __name__ == "__main__":
    main()
PY

#!/usr/bin/env bash
set -euo pipefail

VERSION="recovery-doctor-probe/v1"
LEDGER="${RECOVERY_DOCTOR_LEDGER:-$HOME/.local/state/flywheel/auto-respawn-attempts.jsonl}"
WINDOW_HOURS="${RECOVERY_DOCTOR_WINDOW_HOURS:-24}"
NOW_OVERRIDE="${RECOVERY_DOCTOR_NOW:-}"
JSON_OUT=0; QUIET=0; MODE="doctor"

usage() {
  cat <<'USAGE'
usage: recovery-doctor-probe.sh [--json] [--quiet] [--ledger PATH] [--window-hours N]
       recovery-doctor-probe.sh --info|--examples|--help
Expose 24h recovery-ledger counters for flywheel-loop doctor integration.
USAGE
}

examples_json() {
  jq -nc '{schema_version:"recovery-doctor-probe.examples/v1",examples:["recovery-doctor-probe.sh --json","recovery-doctor-probe.sh --ledger /tmp/recovery.jsonl --json","RECOVERY_DOCTOR_NOW=2026-05-06T13:00:00Z recovery-doctor-probe.sh --json"]}'
}

info_json() {
  jq -nc --arg version "$VERSION" --arg ledger "$LEDGER" --argjson window "$WINDOW_HOURS" '{schema_version:"recovery-doctor-probe.info/v1",name:"recovery-doctor-probe",version:$version,ledger:$ledger,window_hours:$window,canonical_cli_flags:["--help","--info","--examples","--json","--quiet","--ledger","--window-hours"],doctor_fields:["recovery_count_24h","recovery_success_pct_24h","recovery_attempted_24h_by_class","recovery_protected_refusals_24h","recovery_budget_exhausted_24h","recovery_transport_failure_pct_24h","top_failing_panes_24h"]}'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_OUT=1; shift ;;
    --quiet) QUIET=1; shift ;;
    --info) MODE="info"; shift ;;
    --examples) MODE="examples"; shift ;;
    --ledger) LEDGER="${2:?--ledger requires PATH}"; shift 2 ;;
    --ledger=*) LEDGER="${1#*=}"; shift ;;
    --window-hours) WINDOW_HOURS="${2:?--window-hours requires N}"; shift 2 ;;
    --window-hours=*) WINDOW_HOURS="${1#*=}"; shift ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'ERR unknown argument: %s\n' "$1" >&2; usage >&2; exit 64 ;;
  esac
done

case "$MODE" in
  info) info_json; exit 0 ;;
  examples) examples_json; exit 0 ;;
esac

python3 - "$VERSION" "$LEDGER" "$WINDOW_HOURS" "$NOW_OVERRIDE" "$JSON_OUT" "$QUIET" <<'PY'
import json, math, sys
from collections import Counter
from datetime import datetime, timedelta, timezone; from pathlib import Path

version, ledger_raw, window_raw, now_raw, json_raw, quiet_raw = sys.argv[1:]
ledger = Path(ledger_raw).expanduser()
window_hours = float(window_raw)
json_out = json_raw == "1"
quiet = quiet_raw == "1"

def parse_ts(value):
    if not value:
        return None
    try:
        return datetime.fromisoformat(str(value).replace("Z", "+00:00")).astimezone(timezone.utc)
    except Exception:
        return None

now = parse_ts(now_raw) if now_raw else datetime.now(timezone.utc)
cutoff = now - timedelta(hours=window_hours)

def as_int(value, default=0):
    try:
        return int(value)
    except Exception:
        return default

def read_rows(path):
    if not path.exists():
        return [], []
    rows, warnings = [], []
    for line_no, line in enumerate(path.read_text(encoding="utf-8", errors="replace").splitlines(), start=1):
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except Exception as exc:
            warnings.append(f"malformed_jsonl_line_{line_no}:{exc.__class__.__name__}")
            continue
        if isinstance(row, dict):
            rows.append((line_no, row))
    return rows, warnings

def row_time(row):
    ts = parse_ts(row.get("ts") or row.get("timestamp"))
    if ts:
        return ts
    epoch = row.get("epoch")
    try:
        return datetime.fromtimestamp(int(epoch), timezone.utc)
    except Exception:
        return None

def trauma_class(row):
    if row.get("trauma_class"):
        return str(row["trauma_class"])
    action = str(row.get("action") or "")
    recovery = str(row.get("recovery_attempted") or "")
    if "auto_continue" in action or recovery == "auto_continue" or row.get("class") == "capacity-halt-budget-exhausted":
        return "model_at_capacity_halt"
    if action == "respawn_attempt":
        return "frozen_pane"
    return "unknown"

def verdict(row):
    post = row.get("post_check") or {}
    if post.get("verdict"):
        return str(post["verdict"])
    if row.get("recovered") is True:
        return "success"
    if row.get("recovered") is False and row.get("sent") is True:
        return "failure"
    if str(row.get("action") or "").endswith(("refusal", "exhausted")):
        return "failure"
    return "inconclusive"

def failure_class(row, v):
    if v != "failure":
        return None
    if row.get("failure_class") is not None:
        return row.get("failure_class")
    return row.get("budget_outcome") or row.get("authorization_outcome") or row.get("reason") or "failure"

def pane_key(row):
    session = row.get("target_session") or row.get("session") or "unknown"
    pane = row.get("target_pane") if row.get("target_pane") is not None else row.get("pane", "unknown")
    return f"{session}:{pane}"

def budget_exhausted(row):
    budget = row.get("budget_state") or {}
    text = " ".join(str(row.get(k) or "") for k in ("failure_class", "budget_outcome", "reason", "action"))
    return (budget.get("authorized") is False and "budget" in text) or "budget_exhausted" in text or "exhausted" in text

def protected_refusal(row):
    budget = row.get("budget_state") or {}
    text = " ".join(str(row.get(k) or "") for k in ("failure_class", "authorization_outcome", "reason", "action"))
    return (budget.get("authorized") is False and ("refused" in text or "authorization" in text or "protected" in text)) or "worker_scope_only" in text

def transport_rc(row):
    transport = row.get("transport") or {}
    if "rc" in transport:
        return as_int(transport.get("rc"))
    return as_int(row.get("transport_rc"), 0)

rows, warnings = read_rows(ledger)
eligible = []
for line_no, row in rows:
    ts = row_time(row)
    if ts is None or ts < cutoff or ts > now + timedelta(seconds=1):
        continue
    row["_line_no"] = line_no
    eligible.append(row)

classes = Counter(trauma_class(row) for row in eligible)
verdicts = [verdict(row) for row in eligible]
success = sum(1 for v in verdicts if v == "success")
total = len(eligible)
failures = Counter()
failing_classes = {}
for row, v in zip(eligible, verdicts):
    fc = failure_class(row, v)
    if fc:
        key = pane_key(row)
        failures[key] += 1
        failing_classes.setdefault(key, Counter())[str(fc)] += 1

top = []
for key, count in failures.most_common(3):
    top.append({"pane": key, "failure_count": count, "failure_classes": dict(failing_classes[key])})

payload = {
    "schema_version": version,
    "success": True,
    "checked_at": now.replace(microsecond=0).isoformat().replace("+00:00", "Z"),
    "ledger": str(ledger),
    "window_hours": window_hours,
    "recovery_count_24h": total,
    "recovery_success_pct_24h": round((success / total) * 100, 3) if total else 0,
    "recovery_attempted_24h_by_class": dict(classes),
    "recovery_protected_refusals_24h": sum(1 for row in eligible if protected_refusal(row)),
    "recovery_budget_exhausted_24h": sum(1 for row in eligible if budget_exhausted(row)),
    "recovery_transport_failure_pct_24h": round((sum(1 for row in eligible if transport_rc(row) != 0) / total) * 100, 3) if total else 0,
    "top_failing_panes_24h": top,
    "malformed_rows_skipped": len(warnings),
    "warnings": warnings,
    "legacy_rows_counted_24h": sum(1 for row in eligible if not row.get("post_check")),
}
for warning in warnings:
    print(f"WARN {warning}", file=sys.stderr)
if json_out:
    print(json.dumps(payload, separators=(",", ":"), sort_keys=True))
elif not quiet:
    print(f"recovery-doctor-probe recovery_count_24h={total} recovery_success_pct_24h={payload['recovery_success_pct_24h']}")
PY
